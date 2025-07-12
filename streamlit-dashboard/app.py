import streamlit as st
import requests

st.title("Home SOC Analyst Dashboard")

alert_id = st.text_input("Enter Alert ID to Analyze")

if st.button("Fetch and Analyze"):
    # Fetch data from TheHive using its REST API
    alert_data = requests.get(f"http://thehive:9000/api/alert/{alert_id}").json()
    st.json(alert_data)

    # Example: send IoCs for enrichment
    st.write("Enriching using Cortex...")
    # Call Cortex analyzers, FAISS service, and MITRE ATT&CK locally

    st.write("Displaying Recommendations:")
    st.write("- Isolate endpoint if necessary")
    st.write("- Block suspicious IPs")
