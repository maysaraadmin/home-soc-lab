import streamlit as st
import requests
import os
import json
import time
import logging
from datetime import datetime
from typing import Dict, Any, Optional, Tuple, List
from dotenv import load_dotenv
from urllib.parse import urljoin

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Set page config
st.set_page_config(
    page_title="Home SOC Analyst Dashboard",
    page_icon="🔍",
    layout="wide",
    initial_sidebar_state="expanded"
)

def load_config() -> Dict[str, Any]:
    """Load and validate configuration from environment variables."""
    load_dotenv()
    
    config = {
        "THEHIVE_URL": os.getenv("THEHIVE_URL", "http://thehive:9000").rstrip('/'),
        "THEHIVE_API_KEY": os.getenv("THEHIVE_API_KEY"),
        "FAISS_SERVICE_URL": os.getenv("FAISS_SERVICE_URL", "http://faiss-service:7860").rstrip('/'),
        "REQUEST_TIMEOUT": int(os.getenv("REQUEST_TIMEOUT", "10")),
        "MAX_RETRIES": int(os.getenv("MAX_RETRIES", "3")),
        "CACHE_TTL": int(os.getenv("CACHE_TTL", "300"))  # 5 minutes
    }
    
    # Validate required configurations
    if not config["THEHIVE_API_KEY"]:
        st.error("❌ THEHIVE_API_KEY is not set in the environment variables")
        st.stop()
        
    return config

# Load configuration
config = load_config()

# Initialize session state
if 'alert_data' not in st.session_state:
    st.session_state.alert_data = None
    st.session_state.faiss_results = None
    st.session_state.last_updated = None
    st.session_state.error = None
    st.session_state.loading = False

# Custom CSS for better UI
st.markdown("""
    <style>
        .alert-high { background-color: #ffebee; padding: 1rem; border-radius: 0.5rem; border-left: 5px solid #f44336; }
        .alert-medium { background-color: #fff8e1; padding: 1rem; border-radius: 0.5rem; border-left: 5px solid #ffc107; }
        .alert-low { background-color: #e8f5e9; padding: 1rem; border-radius: 0.5rem; border-left: 5px solid #4caf50; }
        .metric-card { padding: 1rem; border-radius: 0.5rem; background-color: #f5f5f5; margin-bottom: 1rem; }
        .similar-incident { padding: 0.75rem; margin: 0.5rem 0; border-radius: 0.5rem; border: 1px solid #e0e0e0; }
        .similar-incident:hover { background-color: #f5f5f5; }
    </style>
""", unsafe_allow_html=True)

def fetch_alert(alert_id: str) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    """
    Fetch alert data from TheHive with retry logic and error handling.
    
    Args:
        alert_id: The ID of the alert to fetch
        
    Returns:
        Tuple of (alert_data, error_message)
    """
    if not alert_id or not alert_id.strip():
        return None, "Alert ID cannot be empty"
    
    headers = {
        "Authorization": f"Bearer {config['THEHIVE_API_KEY']}",
        "Content-Type": "application/json"
    }
    
    url = urljoin(f"{config['THEHIVE_URL']}/api/alert/", alert_id.strip())
    
    for attempt in range(config["MAX_RETRIES"]):
        try:
            response = requests.get(
                url,
                headers=headers,
                timeout=config["REQUEST_TIMEOUT"]
            )
            response.raise_for_status()
            return response.json(), None
            
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 404:
                return None, f"Alert with ID '{alert_id}' not found"
            elif e.response.status_code == 401:
                return None, "Authentication failed. Please check your API key."
            elif e.response.status_code >= 500:
                logger.error(f"Server error: {e}")
                if attempt < config["MAX_RETRIES"] - 1:
                    time.sleep(1 * (attempt + 1))  # Exponential backoff
                    continue
                return None, f"Server error: {str(e)}"
            return None, f"HTTP error: {str(e)}"
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Request failed: {e}")
            if attempt < config["MAX_RETRIES"] - 1:
                time.sleep(1 * (attempt + 1))  # Exponential backoff
                continue
            return None, f"Failed to connect to TheHive: {str(e)}"
    
    return None, "Max retries exceeded. Please try again later."

def analyze_with_faiss(alert_data: Dict[str, Any]) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    """
    Send alert data to FAISS service for similarity search.
    
    Args:
        alert_data: The alert data containing the vector to search with
        
    Returns:
        Tuple of (faiss_results, error_message)
    """
    if not alert_data or 'vector' not in alert_data or not alert_data['vector']:
        return None, "No vector data available for analysis"
    
    vector = alert_data.get('vector', [])
    if not isinstance(vector, list) or not all(isinstance(x, (int, float)) for x in vector):
        return None, "Invalid vector format. Expected a list of numbers."
    
    url = f"{config['FAISS_SERVICE_URL']}/search"
    
    for attempt in range(config["MAX_RETRIES"]):
        try:
            # First check if FAISS service is healthy
            health_url = f"{config['FAISS_SERVICE_URL']}/health"
            health_resp = requests.get(health_url, timeout=config["REQUEST_TIMEOUT"])
            
            if health_resp.status_code != 200:
                return None, f"FAISS service is not healthy: {health_resp.text}"
            
            # If healthy, proceed with the search
            response = requests.post(
                url,
                json={
                    "vector": vector,
                    "k": 5,  # Get top 5 similar items
                    "min_score": 0.5  # Minimum similarity score (0-1)
                },
                timeout=config["REQUEST_TIMEOUT"]
            )
            response.raise_for_status()
            return response.json(), None
            
        except requests.exceptions.HTTPError as e:
            if e.response.status_code >= 500 and attempt < config["MAX_RETRIES"] - 1:
                time.sleep(1 * (attempt + 1))  # Exponential backoff
                continue
            return None, f"FAISS service error: {str(e)}"
            
        except requests.exceptions.RequestException as e:
            logger.error(f"FAISS request failed: {e}")
            if attempt < config["MAX_RETRIES"] - 1:
                time.sleep(1 * (attempt + 1))  # Exponential backoff
                continue
            return None, f"Failed to connect to FAISS service: {str(e)}"
    
    return None, "Max retries exceeded. Please try again later."

def format_timestamp(timestamp: Optional[int]) -> str:
    """Format a Unix timestamp to a readable string."""
    if not timestamp:
        return "N/A"
    try:
        return datetime.fromtimestamp(timestamp / 1000).strftime("%Y-%m-%d %H:%M:%S")
    except (TypeError, ValueError):
        return str(timestamp)

def display_alert_metrics(alert_data: Dict[str, Any]) -> None:
    """Display key metrics about the alert."""
    severity = alert_data.get('severity', 0)
    status = alert_data.get('status', 'Unknown').lower()
    
    # Set alert style based on severity
    if severity >= 3:
        alert_style = "alert-high"
        severity_text = f"🔴 High ({severity})"
    elif severity == 2:
        alert_style = "alert-medium"
        severity_text = f"🟠 Medium ({severity})"
    else:
        alert_style = "alert-low"
        severity_text = f"🟢 Low ({severity})"
    
    # Display alert header
    st.markdown(f"""
        <div class="{alert_style}">
            <h3>{alert_data.get('title', 'Untitled Alert')}</h3>
            <div style="display: flex; gap: 2rem; margin-top: 1rem;">
                <div><strong>Severity:</strong> {severity_text}</div>
                <div><strong>Status:</strong> {status.capitalize()}</div>
                <div><strong>Date:</strong> {format_timestamp(alert_data.get('date'))}</div>
            </div>
        </div>
    """, unsafe_allow_html=True)
    
    # Display key metrics in columns
    col1, col2, col3 = st.columns(3)
    
    with col1:
        st.markdown("<div class='metric-card'><h4>Source</h4><p>{}</p></div>".format(
            alert_data.get('source', 'Unknown')), unsafe_allow_html=True)
    
    with col2:
        st.markdown("<div class='metric-card'><h4>Type</h4><p>{}</p></div>".format(
            alert_data.get('type', 'Unknown')), unsafe_allow_html=True)
    
    with col3:
        st.markdown("<div class='metric-card'><h4>Tags</h4><p>{}</p></div>".format(
            ", ".join(alert_data.get('tags', [])) or "None"), unsafe_allow_html=True)

def display_similar_incidents(faiss_results: Dict[str, Any]) -> None:
    """Display similar incidents from FAISS search results."""
    if not faiss_results or 'results' not in faiss_results or not faiss_results['results']:
        st.info("No similar incidents found.")
        return
    
    st.subheader("🔍 Similar Incidents")
    
    for i, result in enumerate(faiss_results['results'], 1):
        with st.expander(f"{i}. {result.get('title', 'Untitled Incident')} (Score: {result.get('score', 0):.2f})"):
            cols = st.columns([1, 3])
            with cols[0]:
                st.metric("Similarity", f"{result.get('score', 0) * 100:.1f}%")
            with cols[1]:
                st.write(result.get('description', 'No description available'))
            
            # Display additional metadata if available
            if 'mitre_tactic' in result or 'mitre_technique_id' in result:
                st.markdown("**MITRE ATT&CK:**")
                tactic = result.get('mitre_tactic', 'Unknown')
                technique = result.get('mitre_technique_id', 'Unknown')
                st.code(f"{tactic} | {technique}")

def display_recommended_actions(alert_data: Dict[str, Any]) -> None:
    """Display recommended actions based on alert severity and type."""
    severity = alert_data.get('severity', 0)
    alert_type = alert_data.get('type', '').lower()
    
    st.subheader("🚀 Recommended Actions")
    
    # General recommendations based on severity
    if severity >= 3:  # High severity
        st.error("### 🔴 High Severity Alert - Immediate Action Required")
        st.markdown("""
        - 🛑 **Isolate** affected endpoints from the network
        - 🔒 **Block** suspicious IPs in firewall/IDS/IPS
        - 🚨 **Initiate** incident response procedures
        - 📞 **Escalate** to the security team immediately
        - 📝 **Document** all actions taken for post-incident review
        """)
    elif severity == 2:  # Medium severity
        st.warning("### 🟠 Medium Severity Alert - Review Required")
        st.markdown("""
        - 🔍 **Investigate** the alert details thoroughly
        - 🔗 **Check** for related indicators of compromise (IoCs)
        - 📊 **Assess** potential impact and business risk
        - ⏳ **Monitor** for any escalation in severity
        - 🛡️ **Update** detection rules if needed
        """)
    else:  # Low severity
        st.info("### 🟢 Low Severity Alert - Review")
        st.markdown("""
        - 📋 **Review** the alert details
        - 🔄 **Check** if this is a false positive
        - 🏷️ **Tag** the alert appropriately
        - 📈 **Look** for patterns with other alerts
        - 📝 **Document** any findings
        """)
    
    # Type-specific recommendations
    if 'brute force' in alert_type:
        st.markdown("""
        ### 🔐 Brute Force Specific Actions
        - 🔒 **Enforce** account lockout policies
        - 🔑 **Require** MFA for all user accounts
        - 📊 **Review** authentication logs for suspicious patterns
        """)
    elif 'malware' in alert_type:
        st.markdown("""
        ### 🦠 Malware Specific Actions
        - 🔍 **Scan** affected systems with updated antivirus
        - 🌐 **Check** for C2 communications in network logs
        - 🛡️ **Update** all security software and patches
        """)

def display_alert_details(alert_data: Dict[str, Any]) -> None:
    """Display detailed alert information in an expandable section."""
    with st.expander("📋 View Full Alert Details", expanded=False):
        st.json(alert_data)

def display_recommendations(alert_data: Dict[str, Any], faiss_results: Optional[Dict[str, Any]] = None) -> None:
    """Display analysis results and recommendations."""
    # Display alert metrics and header
    display_alert_metrics(alert_data)
    
    # Display similar incidents if available
    if faiss_results:
        display_similar_incidents(faiss_results)
    
    # Display recommended actions
    display_recommended_actions(alert_data)
    
    # Display full alert details in an expandable section
    display_alert_details(alert_data)

def main():
    """Main application function."""
    # Sidebar with app info and controls
    with st.sidebar:
        st.title("🔍 Home SOC Dashboard")
        st.markdown("""
            Analyze security alerts and get AI-powered recommendations.
            
            ### How to use:
            1. Enter an alert ID from TheHive
            2. Click 'Analyze Alert'
            3. Review the analysis and recommendations
            
            ### Quick Actions:
            - View recent alerts
            - Check system status
            - Access documentation
        """)
        
        # System status
        st.markdown("### System Status")
        col1, col2 = st.columns(2)
        with col1:
            try:
                # Check TheHive status
                health_url = f"{config['THEHIVE_URL']}/api/status"
                response = requests.get(health_url, timeout=5)
                if response.status_code == 200:
                    st.success("TheHive: Online")
                else:
                    st.error("TheHive: Error")
            except:
                st.error("TheHive: Offline")
        
        with col2:
            try:
                # Check FAISS service status
                health_url = f"{config['FAISS_SERVICE_URL']}/health"
                response = requests.get(health_url, timeout=5)
                if response.status_code == 200:
                    st.success("FAISS: Online")
                else:
                    st.error("FAISS: Error")
            except:
                st.error("FAISS: Offline")
        
        st.markdown("---")
        st.markdown("### About")
        st.markdown("""
            **Home SOC Lab**  
            Version 1.0.0  
            
            [Documentation](https://github.com/yourusername/home-soc-lab) | 
            [Report Issues](https://github.com/yourusername/home-soc-lab/issues)
        """)
    
    # Main content area
    st.title("🔍 Security Alert Analysis")
    
    # Alert ID input
    with st.form("alert_form"):
        alert_id = st.text_input(
            "Enter Alert ID",
            placeholder="e.g., ~1234567890",
            help="Enter the alert ID from TheHive"
        )
        
        col1, col2 = st.columns([1, 3])
        with col1:
            submit_btn = st.form_submit_button("🔍 Analyze Alert")
        with col2:
            if st.form_submit_button("🔄 Clear Results"):
                st.session_state.alert_data = None
                st.session_state.faiss_results = None
                st.session_state.error = None
                st.experimental_rerun()
    
    # Display error if any
    if st.session_state.get('error'):
        st.error(f"❌ {st.session_state.error}")
    
    # Handle form submission
    if submit_btn and alert_id:
        st.session_state.loading = True
        st.session_state.error = None
        
        with st.spinner("🔍 Fetching alert data..."):
            # Fetch alert data
            alert_data, error = fetch_alert(alert_id)
            
            if error:
                st.session_state.error = error
                st.session_state.loading = False
                st.experimental_rerun()
            
            st.session_state.alert_data = alert_data
            
            # Get FAISS analysis if alert has vector data
            if 'vector' in alert_data and alert_data['vector']:
                with st.spinner("🤖 Analyzing with AI..."):
                    faiss_results, error = analyze_with_faiss(alert_data)
                    if error:
                        st.warning(f"⚠️ {error}")
                    st.session_state.faiss_results = faiss_results
            else:
                st.warning("ℹ️ No vector data available for AI analysis")
                st.session_state.faiss_results = None
            
            st.session_state.last_updated = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            st.session_state.loading = False
            st.experimental_rerun()
    
    # Display results if available
    if st.session_state.alert_data and not st.session_state.loading:
        display_recommendations(
            st.session_state.alert_data,
            st.session_state.get('faiss_results')
        )
        
        # Display last updated time
        if st.session_state.last_updated:
            st.caption(f"Last updated: {st.session_state.last_updated}")
    
    # Display welcome/help message when no alert is loaded
    elif not st.session_state.alert_data and not st.session_state.loading:
        st.markdown("""
            ## Welcome to Home SOC Dashboard
            
            Get started by entering an alert ID from TheHive to analyze security alerts
            and receive AI-powered recommendations.
            
            ### Quick Tips:
            - Use the sidebar to check system status
            - Click on any section to expand/collapse details
            - Hover over buttons and icons for more information
            
            ### Need Help?
            - Check the [documentation](https://github.com/yourusername/home-soc-lab)
            - Visit our [community forum](https://github.com/yourusername/home-soc-lab/discussions)
            - [Report an issue](https://github.com/yourusername/home-soc-lab/issues)
        """)

if __name__ == "__main__":
    main()
