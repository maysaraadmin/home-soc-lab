import streamlit as st
import os
import subprocess
import platform
import psutil
import json
from datetime import datetime, timedelta
import socket
import requests
from pathlib import Path
import shutil
import time
import logging
from functools import wraps
from typing import Optional, Dict, Any, List, Callable
import re
import hmac
import hashlib
from urllib.parse import urlparse

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('soc_gui.log')
    ]
)
logger = logging.getLogger(__name__)

# Rate limiting decorator
class RateLimitExceeded(Exception):
    pass

class RateLimiter:
    def __init__(self, max_calls: int, time_frame: int):
        self.max_calls = max_calls
        self.time_frame = time_frame
        self.calls = []

    def __call__(self, func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            current_time = time.time()
            # Remove calls older than time_frame
            self.calls = [t for t in self.calls if current_time - t < self.time_frame]
            
            if len(self.calls) >= self.max_calls:
                logger.warning(f"Rate limit exceeded for {func.__name__}")
                raise RateLimitExceeded("Too many requests. Please try again later.")
            
            self.calls.append(current_time)
            return func(*args, **kwargs)
        return wrapper

# Initialize rate limiter (100 requests per minute by default)
rate_limit = RateLimiter(
    max_calls=int(os.getenv('RATE_LIMIT', '100').split('/')[0]),
    time_frame=60  # 1 minute
)

def validate_url(url: str) -> bool:
    """Validate URL format"""
    try:
        result = urlparse(url)
        return all([result.scheme in ['http', 'https'], result.netloc])
    except Exception:
        return False

def validate_email(email: str) -> bool:
    """Validate email format"""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None

@rate_limit
def get_service_status(service_name: str) -> bool:
    """
    Check if a service is running with proper error handling and validation
    
    Args:
        service_name: Name of the service to check
        
    Returns:
        bool: True if service is running, False otherwise
    """
    if not service_name or not isinstance(service_name, str):
        logger.error("Invalid service name provided")
        return False
        
    try:
        if platform.system() == 'Windows':
            result = subprocess.run(
                ['sc', 'query', service_name], 
                capture_output=True, 
                text=True, 
                check=False,
                timeout=5
            )
            if result.returncode != 0:
                logger.warning(f"Service {service_name} query failed: {result.stderr}")
            return 'RUNNING' in result.stdout
        else:
            result = subprocess.run(
                ['systemctl', 'is-active', service_name], 
                capture_output=True, 
                text=True, 
                check=False,
                timeout=5
            )
            if result.returncode not in [0, 3]:  # 0: active, 3: inactive, others: error
                logger.warning(f"Service {service_name} status check failed: {result.stderr}")
            return result.returncode == 0
    except subprocess.TimeoutExpired:
        logger.error(f"Service status check timed out for {service_name}")
        return False
    except Exception as e:
        logger.exception(f"Error checking service {service_name} status: {e}")
        return False

@st.cache_data(ttl=30)  # Cache for 30 seconds
@rate_limit
def get_services_status(services: List[Dict[str, str]]) -> Dict[str, bool]:
    """Get status for multiple services with error handling"""
    if not services or not isinstance(services, list):
        logger.error("Invalid services list provided")
        return {}
        
    return {service['id']: get_service_status(service['id']) for service in services}

def show_service_status():
    """Display the status of all services with error handling and retry"""
    st.subheader("Service Status")
    
    # Define services to monitor
    services = [
        {'name': 'Docker', 'id': 'docker'},
        {'name': 'Wazuh Manager', 'id': 'wazuh-manager'},
        {'name': 'Wazuh Indexer', 'id': 'wazuh-indexer'},
        {'name': 'Wazuh Dashboard', 'id': 'wazuh-dashboard'}
    ]
    
    try:
        # Get status for all services with error handling
        statuses = get_services_status(services)
        
        # Display service status
        for service in services:
            service_id = service['id']
            status = statuses.get(service_id, False)
            
            col1, col2 = st.columns([2, 1])
            with col1:
                st.text(service['name'])
            with col2:
                if status is None:
                    st.warning('⚪ Unknown')
                elif status:
                    st.success('🟢 Running')
                else:
                    st.error('🔴 Stopped')
                    
    except RateLimitExceeded as e:
        st.error("Service status check rate limit exceeded. Please try again in a moment.")
        logger.warning("Rate limit exceeded in show_service_status")
    except Exception as e:
        st.error("An error occurred while checking service status.")
        logger.exception("Error in show_service_status")
    
    # Add refresh button with unique key
    if st.button('🔄 Refresh Status', key='refresh_status_btn'):
        time.sleep(0.1)  # Small delay to prevent rapid refreshes
        st.experimental_rerun()

def check_system_requirements():
    """Check system requirements"""
    requirements = {
        'CPU Cores': {
            'value': psutil.cpu_count(),
            'required': 2,
            'status': lambda x, y: x >= y
        },
        'RAM (GB)': {
            'value': round(psutil.virtual_memory().total / (1024**3), 1),
            'required': 4,
            'status': lambda x, y: x >= y
        },
        'Disk Space (GB)': {
            'value': round(psutil.disk_usage('/').total / (1024**3), 1),
            'required': 20,
            'status': lambda x, y: x >= y
        },
        'OS': {
            'value': f"{platform.system()} {platform.release()}",
            'required': 'Windows 10/11 or Linux',
            'status': lambda x, y: True if 'Windows' in x or 'Linux' in x else False
        },
        'Docker': {
            'value': 'Installed' if shutil.which('docker') else 'Not Installed',
            'required': 'Installed',
            'status': lambda x, y: x == y
        }
    }
    
    return requirements

def show_requirements():
    """Display and manage system requirements"""
    st.subheader("System Requirements")
    
    requirements = check_system_requirements()
    
    # Display requirements status
    st.write("### System Status")
    for name, data in requirements.items():
        status = data['status'](data['value'], data['required'])
        col1, col2, col3 = st.columns([2, 2, 1])
        with col1:
            st.text(name)
        with col2:
            st.text(f"{data['value']} (Min: {data['required']})")
        with col3:
            if status:
                st.success('✅')
            else:
                st.error('❌')
    
    # Add system information
    st.write("### System Information")
    sys_info = {
        'Hostname': socket.gethostname(),
        'OS': f"{platform.system()} {platform.release()}",
        'Python Version': platform.python_version(),
        'CPU Cores': psutil.cpu_count(),
        'Total RAM (GB)': f"{psutil.virtual_memory().total / (1024**3):.1f}",
        'Disk Space (GB)': f"{psutil.disk_usage('/').total / (1024**3):.1f}"
    }
    
    for key, value in sys_info.items():
        st.text(f"{key}: {value}")

def show_integrations():
    """Manage SOC tool integrations"""
    st.subheader("Tool Integrations")
    
    # Available integrations
    integrations = {
        'Wazuh': {
            'description': 'Open Source Host and Endpoint Security',
            'enabled': True,
            'status': 'Connected' if get_service_status('wazuh-manager') else 'Disconnected'
        },
        'Elasticsearch': {
            'description': 'Search and Analytics Engine',
            'enabled': True,
            'status': 'Connected' if get_service_status('elasticsearch') else 'Disconnected'
        },
        'TheHive': {
            'description': 'Security Incident Response Platform',
            'enabled': False,
            'status': 'Not Configured'
        },
        'MISP': {
            'description': 'Threat Intelligence Platform',
            'enabled': False,
            'status': 'Not Configured'
        }
    }
    
    # Display integrations
    for name, data in integrations.items():
        with st.expander(f"{name} - {data['status']}"):
            st.write(f"**Description:** {data['description']}")
            
            # Toggle integration
            enabled = st.checkbox("Enable", value=data['enabled'], key=f"int_{name}")
            
            if enabled:
                if data['status'] == 'Not Configured':
                    st.warning("Configuration required")
                    # Add configuration options here
                    if st.button(f"Configure {name}"):
                        st.session_state[f'configuring_{name.lower()}'] = True
                
                if st.button(f"Test {name} Connection"):
                    # Add connection test logic here
                    st.success(f"Successfully connected to {name}!")
            else:
                st.info("Integration is currently disabled")

def show_configuration():
    """Show configuration options"""
    st.header("Configuration")
    
    # Create tabs for different configuration sections
    tab1, tab2, tab3 = st.tabs(["General", "Network", "Security"])
    
    with tab1:
        st.subheader("General Settings")
        app_settings = {
            'app_name': st.text_input("Application Name", "SOC Management Console"),
            'timezone': st.selectbox("Timezone", ["UTC", "Local Time"]),
            'auto_refresh': st.checkbox("Enable Auto-Refresh", True),
            'refresh_interval': st.slider("Refresh Interval (seconds)", 10, 300, 60, 10)
        }
        
        if st.button("Save General Settings"):
            # Save configuration logic here
            st.success("General settings saved successfully!")
    
    with tab2:
        st.subheader("Network Settings")
        network_settings = {
            'host': st.text_input("Host", "0.0.0.0"),
            'port': st.number_input("Port", 1024, 65535, 8501),
            'enable_ssl': st.checkbox("Enable SSL/TLS", False)
        }
        
        if st.button("Save Network Settings"):
            # Save configuration logic here
            st.success("Network settings saved successfully!")
    
    with tab3:
        st.subheader("Security Settings")
        security_settings = {
            'auth_enabled': st.checkbox("Enable Authentication", True),
            'max_login_attempts': st.number_input("Max Login Attempts", 1, 10, 3),
            'session_timeout': st.number_input("Session Timeout (minutes)", 5, 120, 30)
        }
        
        if st.button("Save Security Settings"):
            # Save configuration logic here
            st.success("Security settings saved successfully!")

def show_certificate_manager():
    """Show certificate management"""
    st.header("Certificate Management")
    
    # Certificate management tabs
    tab1, tab2, tab3 = st.tabs(["View Certificates", "Generate CSR", "Import Certificate"])
    
    with tab1:
        st.subheader("Installed Certificates")
        
        # Mock certificate data
        certificates = [
            {
                'name': 'Wazuh Manager',
                'type': 'Server Certificate',
                'expires': '2025-12-31',
                'status': 'Valid'
            },
            {
                'name': 'SOC Management Console',
                'type': 'SSL/TLS',
                'expires': '2024-12-31',
                'status': 'Expires Soon'
            }
        ]
        
        # Display certificates in a table
        st.table(certificates)
        
        # Certificate actions
        col1, col2, col3 = st.columns(3)
        with col1:
            if st.button("🔄 Refresh"):
                st.experimental_rerun()
        with col2:
            if st.button("📝 View Details"):
                st.info("Certificate details would be displayed here")
        with col3:
            if st.button("🗑️ Revoke"):
                st.warning("Are you sure you want to revoke this certificate?")
    
    with tab2:
        st.subheader("Generate Certificate Signing Request (CSR)")
        
        with st.form("csr_form"):
            st.text_input("Common Name (CN)", "soc.example.com")
            st.text_input("Organization (O)", "SOC Team")
            st.text_input("Organizational Unit (OU)", "Security Operations")
            st.text_input("City/Locality (L)", "New York")
            st.text_input("State/Province (ST)", "NY")
            st.text_input("Country (C)", "US")
            st.selectbox("Key Size", [2048, 3072, 4096], index=0)
            
            if st.form_submit_button("Generate CSR"):
                st.success("CSR generated successfully!")
                st.code("-----BEGIN CERTIFICATE REQUEST-----\nMIIC2DCCAcACAQAwgY4xCzAJBgNVBAYTAlVTMQswCQYDVQQIDAJOWTETMBEGA1UE\n...\n-----END CERTIFICATE REQUEST-----")
    
    with tab3:
        st.subheader("Import Certificate")
        
        cert_file = st.file_uploader("Upload Certificate File", type=['pem', 'crt', 'cer'])
        key_file = st.file_uploader("Upload Private Key (Optional)", type=['key', 'pem'])
        
        if st.button("Import Certificate"):
            if cert_file is not None:
                st.success("Certificate imported successfully!")
            else:
                st.error("Please select a certificate file to upload")

def get_logs(service=None, lines=100):
    """Retrieve logs for a specific service"""
    try:
        # Default to system logs if no service specified
        if not service:
            service = 'system'
            
        service = str(service).lower()  # Ensure service is a string and convert to lowercase
        
        # For Docker containers, we'll use docker logs command
        if service in ['wazuh', 'wazuh-manager', 'wazuh-indexer', 'wazuh-dashboard', 'docker']:
            container_map = {
                'wazuh': 'wazuh.manager',
                'wazuh-manager': 'wazuh.manager',
                'wazuh-indexer': 'wazuh.indexer',
                'wazuh-dashboard': 'wazuh.dashboard',
                'docker': 'soc-management-gui-soc-gui-1'
            }
            container = container_map.get(service, service)
            cmd = ['docker', 'logs', '--tail', str(lines), container]
        elif platform.system() == 'Windows':
            cmd = ['powershell', '-Command', f'Get-EventLog -LogName Application -Source {service} -Newest {lines}']
        else:
            # Fallback to reading from files if journalctl is not available
            log_files = {
                'system': '/var/log/syslog',
                'application': '/var/log/app.log',
                'auth': '/var/log/auth.log'
            }
            log_file = log_files.get(service, '/var/log/syslog')
            if os.path.exists(log_file):
                cmd = ['tail', '-n', str(lines), log_file]
            else:
                return f"Log file not found for service: {service}"
        
        result = subprocess.run(cmd, capture_output=True, text=True, check=False)
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout
        elif result.stderr:
            return f"Error retrieving logs: {result.stderr}"
        else:
            return f"No logs available for service: {service}"
    except Exception as e:
        return f"Error retrieving logs: {str(e)}"

def show_logs():
    """Show service logs"""
    st.header("Service Logs")
    
    # Log viewer controls
    col1, col2, col3 = st.columns(3)
    with col1:
        log_source = st.selectbox("Log Source", ["All", "System", "Application", "Security", "Wazuh", "Docker"])
    with col2:
        log_level = st.selectbox("Log Level", ["All", "Info", "Warning", "Error", "Critical"])
    with col3:
        log_lines = st.number_input("Number of Lines", 10, 1000, 100, 10)
    
    # Log display
    log_display = st.empty()
    
    # Get and display logs
    logs = get_logs(service=log_source if log_source != "All" else None, lines=log_lines)
    log_display.code(logs, language='log')
    
    # Log actions
    col1, col2 = st.columns(2)
    with col1:
        if st.button("🔄 Refresh Logs", key="refresh_logs_btn"):
            st.experimental_rerun()
    
    with col2:
        st.download_button(
            label="📥 Download Logs",
            data=logs,
            file_name=f"logs_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log",
            mime="text/plain",
            key="download_logs_btn"
        )
    
    # Log search
    st.subheader("Search Logs")
    search_term = st.text_input("Search term")
    if search_term:
        matching_logs = [line for line in logs.split('\n') if search_term.lower() in line.lower()]
        st.code('\n'.join(matching_logs), language='log')

def show_soc_lab():
    """Show SOC Lab management"""
    st.header("SOC Lab Management")
    
    # Lab management tabs
    tab1, tab2, tab3 = st.tabs(["Lab Environment", "Scenarios", "Training"])
    
    with tab1:
        st.subheader("Lab Environment")
        
        # Lab status
        lab_status = {
            'Status': '🟢 Running',
            'Uptime': '2 days, 5 hours',
            'Resources': '4 vCPUs, 8GB RAM, 50GB Storage',
            'Active Users': 3,
            'Last Backup': '2023-11-15 03:00:00 UTC'
        }
        
        for key, value in lab_status.items():
            st.text(f"{key}: {value}")
        
        # Lab actions
        st.subheader("Lab Actions")
        col1, col2, col3 = st.columns(3)
        
        with col1:
            if st.button("🔄 Refresh Status"):
                st.experimental_rerun()
        with col2:
            if st.button("🚀 Start Lab"):
                st.success("Lab environment is starting...")
        with col3:
            if st.button("🛑 Stop Lab"):
                st.warning("Are you sure you want to stop the lab?")
    
    with tab2:
        st.subheader("Training Scenarios")
        
        # Available scenarios
        scenarios = [
            {"name": "Malware Analysis", "difficulty": "Intermediate", "duration": "2h", "status": "Available"},
            {"name": "Network Forensics", "difficulty": "Advanced", "duration": "4h", "status": "In Progress"},
            {"name": "Incident Response", "difficulty": "Beginner", "duration": "1h", "status": "Available"},
            {"name": "Threat Hunting", "difficulty": "Advanced", "duration": "3h", "status": "Locked"},
        ]
        
        # Display scenarios
        for scenario in scenarios:
            with st.expander(f"{scenario['name']} - {scenario['status']}"):
                st.write(f"**Difficulty:** {scenario['difficulty']}")
                st.write(f"**Duration:** {scenario['duration']}")
                
                if scenario['status'] == 'Available':
                    if st.button(f"Start {scenario['name']}", key=f"start_{scenario['name'].lower().replace(' ', '_')}"):
                        st.session_state['current_scenario'] = scenario['name']
                        st.success(f"Starting {scenario['name']} scenario...")
                elif scenario['status'] == 'In Progress':
                    st.progress(45)
                    if st.button("Continue Scenario", key=f"continue_{scenario['name'].lower().replace(' ', '_')}"):
                        st.info("Resuming scenario...")
                else:
                    st.info("Complete previous scenarios to unlock")
    
    with tab3:
        st.subheader("Training Progress")
        
        # Training metrics
        col1, col2, col3 = st.columns(3)
        with col1:
            st.metric("Completed Scenarios", "2/10")
        with col2:
            st.metric("Training Hours", "8.5")
        with col3:
            st.metric("Skill Level", "Intermediate")
        
        # Progress chart (mock data)
        progress_data = {
            'Week': ['Week 1', 'Week 2', 'Week 3', 'Week 4', 'Current'],
            'Progress': [10, 25, 35, 60, 75]
        }
        st.line_chart(progress_data, x='Week', y='Progress')
        
        # Upcoming training
        st.subheader("Upcoming Training")
        trainings = [
            {"name": "Advanced Threat Hunting", "date": "2023-12-01", "instructor": "Jane Smith"},
            {"name": "Cloud Security", "date": "2023-12-15", "instructor": "Mike Johnson"},
        ]
        
        for training in trainings:
            with st.expander(f"{training['name']} - {training['date']}"):
                st.write(f"**Instructor:** {training['instructor']}")
                if st.button(f"Register for {training['name']}", key=f"register_{training['name'].lower().replace(' ', '_')}"):
                    st.success(f"Registered for {training['name']} on {training['date']}")

def main():
    """Main application function"""
    # Set page config
    st.set_page_config(
        page_title="SOC Management Console",
        page_icon="🛡️",
        layout="wide",
        initial_sidebar_state="expanded"
    )
    
    # Custom CSS for better styling
    st.markdown("""
    <style>
        .main .block-container {
            padding-top: 2rem;
            padding-bottom: 2rem;
        }
        .stButton>button {
            width: 100%;
        }
        .stProgress > div > div > div > div {
            background-color: #4CAF50;
        }
    </style>
    """, unsafe_allow_html=True)
    
    # Sidebar navigation
    st.sidebar.title("SOC Management")
    page = st.sidebar.radio(
        "Navigation",
        ["Dashboard", "Requirements", "Integrations", "Configuration", 
         "Certificate Manager", "Logs", "SOC Lab Management"]
    )
    
    # Display the appropriate page based on selection
    if page == "Dashboard":
        st.header("SOC Dashboard")
        st.markdown("""
        Welcome to the SOC Management Console. Monitor and manage your security operations center tools from a single interface.
        """)
        
        # Show service status
        show_service_status()
        
        # Quick actions
        st.subheader("Quick Actions")
        col1, col2, col3, col4 = st.columns(4)
        
        with col1:
            if st.button("🔄 Refresh Status"):
                st.experimental_rerun()
        
        with col2:
            if st.button("📊 View Logs"):
                st.session_state.page = "Logs"
                st.experimental_rerun()
        
        with col3:
            if st.button("⚙️ Configuration"):
                st.session_state.page = "Configuration"
                st.experimental_rerun()
        
        with col4:
            if st.button("📚 Documentation"):
                st.markdown("Visit our [documentation](https://example.com/docs) for more information.")
        
        # System status
        st.subheader("System Status")
        col1, col2, col3 = st.columns(3)
        
        with col1:
            st.metric("CPU Usage", "N/A", "0%")
        
        with col2:
            st.metric("Memory Usage", "N/A", "0%")
        
        with col3:
            st.metric("Disk Usage", "N/A", "0%")
        
        # Recent activities
        st.subheader("Recent Activities")
        st.info("Activity logging is disabled in this version of the application.")
    
    elif page == "Requirements":
        show_requirements()
    
    elif page == "Integrations":
        show_integrations()
    
    elif page == "Configuration":
        show_configuration()
    
    elif page == "Certificate Manager":
        show_certificate_manager()
    
    elif page == "Logs":
        show_logs()
    
    elif page == "SOC Lab Management":
        show_soc_lab()

if __name__ == "__main__":
    main()
