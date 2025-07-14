import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime, timedelta
import random
import numpy as np
import os
from pathlib import Path

# Set page configuration
st.set_page_config(
    page_title="SOC Dashboard",
    page_icon="🛡️",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS for better styling
st.markdown("""
    <style>
    .main-header {font-size:24px; color: #1f77b4;}
    .metric-card {background-color: #f8f9fa; padding: 15px; border-radius: 10px; margin: 10px 0;}
    .stAlert {padding: 20px; border-radius: 10px;}
    .stProgress > div > div > div > div {background-color: #1f77b4;}
    </style>
""", unsafe_allow_html=True)

# Initialize session state
if 'alerts_data' not in st.session_state:
    st.session_state.alerts_data = []
    st.session_state.incidents_data = []
    st.session_state.analyzers_data = []
    st.session_state.responders_data = []

# Generate sample data
def generate_sample_data():
    # Generate sample alerts
    alert_types = ['Malware', 'Phishing', 'DDoS', 'Brute Force', 'Data Exfiltration']
    severities = ['Low', 'Medium', 'High', 'Critical']
    statuses = ['New', 'In Progress', 'Closed', 'False Positive']
    
    alerts = []
    for i in range(50):
        alert_time = datetime.now() - timedelta(hours=random.randint(0, 72))
        alerts.append({
            'id': f'ALERT-{1000 + i}',
            'type': random.choice(alert_types),
            'severity': random.choice(severities),
            'status': random.choice(statuses),
            'source': f'SIEM-{random.randint(1,5)}',
            'timestamp': alert_time,
            'description': f'Sample alert {i+1} description',
            'count': random.randint(1, 10)
        })
    
    # Generate sample incidents
    incidents = []
    for i in range(10):
        create_time = datetime.now() - timedelta(days=random.randint(1, 30))
        incidents.append({
            'id': f'INC-{2000 + i}',
            'title': f'Security Incident {i+1}',
            'status': random.choice(['Open', 'In Progress', 'Closed']),
            'severity': random.choice(severities),
            'created_at': create_time,
            'updated_at': create_time + timedelta(hours=random.randint(1, 72)),
            'assigned_to': f'analyst{random.randint(1, 5)}@soc.local'
        })
    
    # Generate analyzer results
    analyzers = [
        {'name': 'VirusTotal', 'type': 'File', 'success_rate': 95, 'avg_time': 2.5},
        {'name': 'AbuseIPDB', 'type': 'IP', 'success_rate': 92, 'avg_time': 1.8},
        {'name': 'URLScan', 'type': 'URL', 'success_rate': 88, 'avg_time': 3.2},
        {'name': 'Hybrid Analysis', 'type': 'File', 'success_rate': 90, 'avg_time': 4.1},
        {'name': 'Shodan', 'type': 'IP', 'success_rate': 85, 'avg_time': 2.9},
    ]
    
    # Generate responder results
    responders = [
        {'name': 'Block IP', 'type': 'IP', 'success_rate': 98, 'avg_time': 1.2},
        {'name': 'Quarantine Device', 'type': 'Endpoint', 'success_rate': 95, 'avg_time': 5.5},
        {'name': 'Reset Password', 'type': 'User', 'success_rate': 99, 'avg_time': 0.8},
        {'name': 'Disable Account', 'type': 'User', 'success_rate': 100, 'avg_time': 0.5},
        {'name': 'Update Firewall Rule', 'type': 'Network', 'success_rate': 92, 'avg_time': 3.2},
    ]
    
    return alerts, incidents, analyzers, responders

# Load or generate data
def load_data():
    if not st.session_state.alerts_data:
        alerts, incidents, analyzers, responders = generate_sample_data()
        st.session_state.alerts_data = alerts
        st.session_state.incidents_data = incidents
        st.session_state.analyzers_data = analyzers
        st.session_state.responders_data = responders
    
    return (
        pd.DataFrame(st.session_state.alerts_data),
        pd.DataFrame(st.session_state.incidents_data),
        pd.DataFrame(st.session_state.analyzers_data),
        pd.DataFrame(st.session_state.responders_data)
    )

# Dashboard Layout
def main():
    st.sidebar.title("SOC Dashboard")
    st.sidebar.markdown("---")
    
    # Date range filter
    st.sidebar.subheader("Date Range")
    today = datetime.now()
    week_ago = today - timedelta(days=7)
    date_range = st.sidebar.date_input(
        "Select Date Range",
        value=(week_ago, today),
        min_value=today - timedelta(days=365),
        max_value=today
    )
    
    # Severity filter
    st.sidebar.subheader("Severity Filter")
    severities = st.sidebar.multiselect(
        "Select Severities",
        options=['Low', 'Medium', 'High', 'Critical'],
        default=['Low', 'Medium', 'High', 'Critical']
    )
    
    # Load data
    alerts_df, incidents_df, analyzers_df, responders_df = load_data()
    
    # Apply filters
    if len(date_range) == 2:
        start_date, end_date = date_range
        alerts_df = alerts_df[
            (pd.to_datetime(alerts_df['timestamp']).dt.date >= start_date) & 
            (pd.to_datetime(alerts_df['timestamp']).dt.date <= end_date)
        ]
        
        incidents_df = incidents_df[
            (pd.to_datetime(incidents_df['created_at']).dt.date >= start_date) & 
            (pd.to_datetime(incidents_df['created_at']).dt.date <= end_date)
        ]
    
    if severities:
        alerts_df = alerts_df[alerts_df['severity'].isin(severities)]
        incidents_df = incidents_df[incidents_df['severity'].isin(severities)]
    
    # Main dashboard
    st.title("🛡️ SOC Dashboard")
    
    # Metrics Row 1
    col1, col2, col3, col4 = st.columns(4)
    
    with col1:
        st.metric("Total Alerts", len(alerts_df))
    with col2:
        st.metric("Open Incidents", len(incidents_df[incidents_df['status'] != 'Closed']))
    with col3:
        critical_alerts = len(alerts_df[alerts_df['severity'] == 'Critical'])
        st.metric("Critical Alerts", critical_alerts, 
                 delta=f"{int((critical_alerts / len(alerts_df)) * 100)}% of total" if not alerts_df.empty else "0%")
    with col4:
        avg_response_time = incidents_df['updated_at'] - incidents_df['created_at']
        avg_hours = avg_response_time.mean().total_seconds() / 3600 if not avg_response_time.empty else 0
        st.metric("Avg. Response Time", f"{avg_hours:.1f} hours")
    
    # Charts Row 1
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("Alerts by Type")
        if not alerts_df.empty:
            fig = px.pie(
                alerts_df, 
                names='type', 
                hole=0.4,
                color_discrete_sequence=px.colors.sequential.Blues_r
            )
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("No alert data available for the selected filters.")
    
    with col2:
        st.subheader("Incidents by Status")
        if not incidents_df.empty:
            fig = px.bar(
                incidents_df['status'].value_counts().reset_index(),
                x='status',
                y='count',
                labels={'status': 'Status', 'count': 'Count'},
                color='status',
                color_discrete_sequence=px.colors.qualitative.Set2
            )
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("No incident data available for the selected filters.")
    
    # Charts Row 2
    st.subheader("Alerts Timeline")
    if not alerts_df.empty:
        alerts_df['date'] = pd.to_datetime(alerts_df['timestamp']).dt.date
        timeline_df = alerts_df.groupby(['date', 'severity']).size().reset_index(name='count')
        
        fig = px.line(
            timeline_df, 
            x='date', 
            y='count', 
            color='severity',
            title='Alerts Over Time by Severity',
            labels={'date': 'Date', 'count': 'Alert Count', 'severity': 'Severity'}
        )
        st.plotly_chart(fig, use_container_width=True)
    else:
        st.info("No alert data available for the timeline.")
    
    # Analyzers and Responders
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("Analyzers Performance")
        if not analyzers_df.empty:
            fig = px.bar(
                analyzers_df.sort_values('success_rate', ascending=False),
                x='name',
                y='success_rate',
                color='type',
                labels={'name': 'Analyzer', 'success_rate': 'Success Rate (%)', 'type': 'Type'},
                title='Success Rate by Analyzer',
                text='success_rate'
            )
            fig.update_traces(texttemplate='%{text:.1f}%', textposition='outside')
            st.plotly_chart(fig, use_container_width=True)
    
    with col2:
        st.subheader("Responders Performance")
        if not responders_df.empty:
            fig = px.bar(
                responders_df.sort_values('success_rate', ascending=False),
                x='name',
                y='avg_time',
                color='type',
                labels={'name': 'Responder', 'avg_time': 'Avg. Time (s)', 'type': 'Type'},
                title='Average Response Time by Responder',
                text='avg_time'
            )
            fig.update_traces(texttemplate='%{text:.1f}s', textposition='outside')
            st.plotly_chart(fig, use_container_width=True)
    
    # Raw Data Tabs
    st.subheader("Raw Data")
    tab1, tab2 = st.tabs(["Alerts", "Incidents"])
    
    with tab1:
        st.dataframe(alerts_df.sort_values('timestamp', ascending=False), use_container_width=True)
    
    with tab2:
        st.dataframe(incidents_df.sort_values('created_at', ascending=False), use_container_width=True)

if __name__ == "__main__":
    main()
