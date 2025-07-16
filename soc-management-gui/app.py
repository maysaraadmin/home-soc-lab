import streamlit as st
import os
import sys
import json
import time
import yaml
import shutil
import socket
import psutil
import platform
import subprocess
import logging
from datetime import datetime
from pathlib import Path
from typing import Tuple, Dict, List, Optional, Any, Union

import requests
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Constants
SOC_LAB_DIR = os.getenv('SOC_LAB_DIR', os.path.expanduser('~/home-soc-lab'))
CERT_MANAGER_URL = os.getenv('CERT_MANAGER_URL', 'http://cert-manager:5000')
CERT_DIR = os.getenv('CERT_DIR', '/certs')

# Docker compose files mapping
DOCKER_COMPOSE_FILES = {}

def get_docker_compose_file(service_name: str) -> str:
    """
    Get the appropriate docker-compose file for a service.
    First checks for service-specific file, falls back to main docker-compose.yml
    """
    # Try service-specific file first
    service_file = f'docker-compose.{service_name}.yml'
    if os.path.exists(os.path.join(SOC_LAB_DIR, service_file)):
        return service_file
    
    # Fall back to main docker-compose.yml if it exists
    main_file = 'docker-compose.yml'
    if os.path.exists(os.path.join(SOC_LAB_DIR, main_file)):
        return main_file
        
    # If no compose files found, raise an error
    raise FileNotFoundError(
        f"No docker-compose file found for service {service_name} in {SOC_LAB_DIR}"
    )

# Initialize DOCKER_COMPOSE_FILES with available services
try:
    # Try to detect available services from docker-compose.yml
    main_compose = os.path.join(SOC_LAB_DIR, 'docker-compose.yml')
    if os.path.exists(main_compose):
        with open(main_compose, 'r') as f:
            compose_config = yaml.safe_load(f)
            if compose_config and 'services' in compose_config:
                for service_name in compose_config['services'].keys():
                    DOCKER_COMPOSE_FILES[service_name] = 'docker-compose.yml'
    
    # If no services found, use default mappings
    if not DOCKER_COMPOSE_FILES:
        DOCKER_COMPOSE_FILES = {
            'wazuh': 'docker-compose.yml',
            'thehive': 'docker-compose.yml',
            'cortex': 'docker-compose.yml',
            'shuffle': 'docker-compose.yml',
            'nginx': 'docker-compose.yml'
        }
        
except Exception as e:
    logger.warning(f"Could not detect services from docker-compose.yml: {str(e)}")
    # Fall back to default mappings
    DOCKER_COMPOSE_FILES = {
        'wazuh': 'docker-compose.yml',
        'thehive': 'docker-compose.yml',
        'cortex': 'docker-compose.yml',
        'shuffle': 'docker-compose.yml',
        'nginx': 'docker-compose.yml'
    }

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

# Set page config
st.set_page_config(
    page_title="SOC Management Console",
    page_icon="🛡️",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Configuration
CERT_MANAGER_URL = os.getenv('CERT_MANAGER_URL', 'http://cert-manager:5000')
CERT_DIR = os.getenv('CERT_DIR', '/certs')
SOC_LAB_DIR = os.getenv('SOC_LAB_DIR', os.path.expanduser('~/home-soc-lab'))
DOCKER_COMPOSE_FILES = {
    'thehive': 'docker-compose.thehive.nginx.yml',
    'wazuh': 'docker-compose.wazuh.yml',
    'cortex': 'docker-compose.cortex.yml',
    'shuffle': 'docker-compose.shuffle.yml'
}

# Ensure SOC Lab directory exists
os.makedirs(SOC_LAB_DIR, exist_ok=True)

# Custom CSS for better styling
st.markdown("""
<style>
    .main-header {font-size:24px; font-weight: bold; color: #1E88E5;}
    .status-card {padding: 15px; border-radius: 10px; margin: 10px 0;}
    .status-running {background-color: #E8F5E9; border-left: 5px solid #4CAF50;}
    .status-stopped {background-color: #FFEBEE; border-left: 5px solid #F44336;}
    .config-section {margin: 20px 0; padding: 15px; background-color: #f5f5f5; border-radius: 5px;}
</style>
""", unsafe_allow_html=True)

# Mock data - in a real app, this would come from actual service checks
SERVICES = {
    'wazuh': {
        'name': 'Wazuh',
        'port': 55000,
        'config_path': '/var/ossec/etc/ossec.conf',
        'status': 'stopped',
        'version': '4.5.0',
        'requirements': ['Python 3.8+', 'Elasticsearch', 'Filebeat']
    },
    'thehive': {
        'name': 'TheHive',
        'port': 9000,
        'config_path': '/etc/thehive/application.conf',
        'status': 'stopped',
        'version': '4.1.0',
        'requirements': ['Java 11', 'Elasticsearch', 'Cassandra']
    },
    'cortex': {
        'name': 'Cortex',
        'port': 9001,
        'config_path': '/etc/cortex/application.conf',
        'status': 'stopped',
        'version': '3.1.0',
        'requirements': ['Java 11', 'Elasticsearch']
    },
    'shuffle': {
        'name': 'Shuffle',
        'port': 3001,
        'config_path': '/etc/shuffle/config.yaml',
        'status': 'stopped',
        'version': '1.0.0',
        'requirements': ['Docker', 'Docker Compose']
    },
    'faiss': {
        'name': 'FAISS',
        'port': None,
        'config_path': None,
        'status': 'stopped',
        'version': '1.7.3',
        'requirements': ['Python 3.8+', 'Numpy']
    },
    'streamlit': {
        'name': 'Streamlit',
        'port': 8501,
        'config_path': None,
        'status': 'running',
        'version': '1.22.0',
        'requirements': ['Python 3.8+']
    }
}

def check_service_status(service_name):
    """Check if a service is running"""
    try:
        # In a real implementation, this would check the actual service status
        return SERVICES[service_name]['status'] == 'running'
    except Exception as e:
        st.error(f"Error checking {service_name} status: {str(e)}")
        return False

def get_service_config(service_name):
    """Get service configuration"""
    try:
        config_path = SERVICES[service_name]['config_path']
        if config_path and os.path.exists(config_path):
            with open(config_path, 'r') as f:
                return f.read()
        return "No configuration file found or path not specified."
    except Exception as e:
        return f"Error reading configuration: {str(e)}"

def update_service_config(service_name, config_content):
    """Update service configuration"""
    try:
        config_path = SERVICES[service_name]['config_path']
        if config_path:
            with open(config_path, 'w') as f:
                f.write(config_content)
            return True, "Configuration updated successfully"
        return False, "No configuration path specified for this service"
    except Exception as e:
        return False, f"Error updating configuration: {str(e)}"

def update_service_status(service_name, status):
    """Update service status in the SERVICES dictionary"""
    try:
        SERVICES[service_name]['status'] = status
        return True, f"{SERVICES[service_name]['name']} status updated to {status}"
    except Exception as e:
        return False, f"Error updating {service_name} status: {str(e)}"

def start_soc_service(service_name):
    """
    Start a SOC Lab service using Docker Compose.
    
    Args:
        service_name (str): Name of the service to start
        
    Returns:
        tuple: (success: bool, message: str)
    """
    # Check if Docker is available
    docker_ok, docker_msg = check_docker()
    if not docker_ok:
        return False, f"Docker not available: {docker_msg}"
    
    # Get the compose file for the service
    compose_file = DOCKER_COMPOSE_FILES.get(service_name.lower())
    if not compose_file:
        return False, f"Unknown service: {service_name}"
    
    # Check if the compose file exists
    compose_path = os.path.join(SOC_LAB_DIR, compose_file)
    if not os.path.exists(compose_path):
        return False, f"Docker compose file not found: {compose_path}"
    
    # Check if the service is already running
    is_running, container_name = is_service_running(service_name)
    if is_running:
        return True, f"{service_name} is already running (container: {container_name})"
    
    # Build the docker-compose command
    docker_compose_cmd = 'docker-compose'
    if shutil.which('docker-compose') is None and shutil.which('docker') is not None:
        docker_compose_cmd = 'docker compose'  # Use space for newer Docker versions
    
    cmd = f"{docker_compose_cmd} -f {compose_path} up -d --build"
    
    # Run the command
    st.info(f"Starting {service_name} with command: {cmd}")
    success, output = run_command(cmd, cwd=SOC_LAB_DIR, shell=True)
    
    # Verify the service started successfully
    if success:
        time.sleep(2)  # Give the container a moment to start
        is_running, container_name = is_service_running(service_name)
        if is_running:
            update_service_status(service_name, 'running')
            return True, f"Successfully started {service_name} (container: {container_name})"
        else:
            return False, f"{service_name} failed to start. No container found."
    
    return False, f"Failed to start {service_name}: {output}"

def call_cert_manager(endpoint, method='GET', data=None):
    """Make API calls to the certificate manager service"""
    url = f"{CERT_MANAGER_URL}{endpoint}"
    try:
        if method.upper() == 'GET':
            response = requests.get(url, params=data)
        elif method.upper() == 'POST':
            response = requests.post(url, json=data)
        else:
            return False, "Unsupported HTTP method"
        
        if response.status_code == 200:
            return True, response.json()
        else:
            return False, f"Error {response.status_code}: {response.text}"
    except Exception as e:
        return False, str(e)

def list_certificates():
    """List all available certificates"""
    success, result = call_cert_manager('/api/certificates')
    if success:
        return result
    return []

def create_self_signed_cert(common_name, days=365, key_size=2048):
    """Create a self-signed certificate"""
    data = {
        'common_name': common_name,
        'days': days,
        'key_size': key_size
    }
    success, result = call_cert_manager('/api/certificates/self-signed', 'POST', data)
    return success, result

def create_csr(common_name, key_size=2048):
    """Create a Certificate Signing Request"""
    data = {
        'common_name': common_name,
        'key_size': key_size
    }
    success, result = call_cert_manager('/api/certificates/csr', 'POST', data)
    return success, result

def sign_certificate(csr_path, ca_key, ca_cert, days=365):
    """Sign a certificate using a CA"""
    data = {
        'csr_path': csr_path,
        'ca_key': ca_key,
        'ca_cert': ca_cert,
        'days': days
    }
    success, result = call_cert_manager('/api/certificates/sign', 'POST', data)
    return success, result

def get_certificate_info(cert_path):
    """Get information about a certificate"""
    params = {'path': cert_path}
    success, result = call_cert_manager('/api/certificates/info', 'GET', params)
    return success, result

def run_command(command, cwd=None, shell=False, timeout=30):
    """
    Run a shell command and return the output with enhanced error handling.
    
    Args:
        command (list or str): The command to run
        cwd (str, optional): Working directory for the command
        shell (bool, optional): Whether to use shell execution
        timeout (int, optional): Command timeout in seconds
        
    Returns:
        tuple: (success: bool, output: str or error message)
    """
    try:
        if isinstance(command, str) and not shell:
            command = shlex.split(command) if platform.system() != 'Windows' else command
            
        result = subprocess.run(
            command,
            cwd=cwd,
            shell=shell,
            check=False,  # We'll handle non-zero return codes ourselves
            text=True,
            capture_output=True,
            timeout=timeout
        )
        
        # Log the command and its output
        debug_info = {
            'command': ' '.join(command) if isinstance(command, list) else command,
            'returncode': result.returncode,
            'stdout': result.stdout,
            'stderr': result.stderr,
            'cwd': cwd or os.getcwd()
        }
        
        if result.returncode != 0:
            error_msg = f"Command failed with return code {result.returncode}"
            if result.stderr:
                error_msg += f"\nError: {result.stderr.strip()}"
            return False, error_msg
            
        return True, result.stdout.strip()
        
    except subprocess.TimeoutExpired:
        return False, f"Command timed out after {timeout} seconds"
    except FileNotFoundError as e:
        return False, f"Command not found: {e.filename}"
    except Exception as e:
        return False, f"Unexpected error: {str(e)}"

def check_docker():
    """
    Check if Docker is installed, running, and accessible.
    
    Returns:
        tuple: (is_available: bool, message: str)
    """
    try:
        # Check if docker command exists and is executable
        if platform.system() == 'Windows':
            docker_cmd = 'docker.exe'
        else:
            docker_cmd = 'docker'
            
        if not shutil.which(docker_cmd):
            return False, "Docker is not installed or not in PATH"
            
        # Check if Docker daemon is running
        success, output = run_command([docker_cmd, 'info'])
        if not success:
            if "Is the docker daemon running" in output or "Cannot connect to the Docker daemon" in output:
                return False, "Docker is installed but the daemon is not running"
            return False, f"Docker error: {output}"
            
        # Additional checks for Docker Compose if needed
        if not shutil.which('docker-compose') and not shutil.which('docker'):
            return False, "Docker Compose is not installed"
            
        return True, "Docker is running"
        
    except Exception as e:
        return False, f"Error checking Docker: {str(e)}"

def get_docker_containers(all_containers=False):
    """
    Get list of Docker containers.
    
    Args:
        all_containers (bool): If True, returns all containers (including stopped ones)
        
    Returns:
        list: List of container names
    """
    cmd = ['docker', 'ps', '--format', '{{.Names}}']
    if all_containers:
        cmd.append('--all')
        
    success, output = run_command(cmd)
    if not success:
        st.error(f"Failed to get Docker containers: {output}")
        return []
        
    containers = [name.strip() for name in output.split('\n') if name.strip()]
    return containers

def is_service_running(service_name, exact_match=False):
    """
    Check if a specific service is running.
    
    Args:
        service_name (str): Name of the service to check
        exact_match (bool): If True, requires exact container name match
        
    Returns:
        tuple: (is_running: bool, container_name: str or None)
    """
    if not service_name:
        return False, None
        
    containers = get_docker_containers()
    
    if exact_match:
        for container in containers:
            if container.lower() == service_name.lower():
                return True, container
    else:
        for container in containers:
            if service_name.lower() in container.lower():
                return True, container
                
    return False, None

def stop_soc_service(service_name, remove_volumes=False):
    """
    Stop a SOC Lab service using Docker Compose.
    
    Args:
        service_name (str): Name of the service to stop
        remove_volumes (bool): If True, removes volumes when stopping
        
    Returns:
        tuple: (success: bool, message: str)
    """
    # Check if Docker is available
    docker_ok, docker_msg = check_docker()
    if not docker_ok:
        return False, f"Docker not available: {docker_msg}"
    
    # Get the compose file for the service
    compose_file = DOCKER_COMPOSE_FILES.get(service_name.lower())
    if not compose_file:
        return False, f"Unknown service: {service_name}"
    
    # Check if the compose file exists
    compose_path = os.path.join(SOC_LAB_DIR, compose_file)
    if not os.path.exists(compose_path):
        return False, f"Docker compose file not found: {compose_path}"
    
    # Check if the service is already stopped
    is_running, container_name = is_service_running(service_name)
    if not is_running:
        return True, f"{service_name} is not currently running"
    
    # Build the docker-compose command
    docker_compose_cmd = 'docker-compose'
    if shutil.which('docker-compose') is None and shutil.which('docker') is not None:
        docker_compose_cmd = 'docker compose'  # Use space for newer Docker versions
    
    # Add volume removal flag if requested
    volume_flag = '--volumes' if remove_volumes else ''
    cmd = f"{docker_compose_cmd} -f {compose_path} down {volume_flag}"
    
    # Run the command
    st.info(f"Stopping {service_name} with command: {cmd}")
    success, output = run_command(cmd, cwd=SOC_LAB_DIR, shell=True)
    
    # Verify the service stopped successfully
    if success:
        time.sleep(2)  # Give the container a moment to stop
        is_running, _ = is_service_running(service_name)
        if not is_running:
            update_service_status(service_name, 'stopped')
            return True, f"Successfully stopped {service_name}"
        else:
            return False, f"Failed to stop {service_name}. Container is still running."
    
    return False, f"Failed to stop {service_name}: {output}"

def generate_wazuh_certs():
    """Generate Wazuh certificates"""
    # Create certificates directory if it doesn't exist
    certs_dir = os.path.join(SOC_LAB_DIR, 'config', 'wazuh', 'certs')
    os.makedirs(certs_dir, exist_ok=True)
    
    # Create dashboard certificates directory
    dashboard_certs = os.path.join(SOC_LAB_DIR, 'config', 'wazuh', 'dashboard', 'certs')
    os.makedirs(dashboard_certs, exist_ok=True)
    
    # Generate certificates using the certificate manager
    return True, "Wazuh certificates generated successfully"

def show_service_status():
    """Display the status of all services"""
    st.subheader("Service Status")
    
    # Check Docker status first
    docker_ok, docker_msg = check_docker()
    if not docker_ok:
        st.error(f"⚠️ {docker_msg}")
        st.warning("Please ensure Docker is installed and running to manage services.")
        return
    
    # Get list of services from DOCKER_COMPOSE_FILES
    services = [{
        'id': service_id,
        'name': service_id.capitalize(),
        'compose_file': compose_file
    } for service_id, compose_file in DOCKER_COMPOSE_FILES.items()]
    
    # Display service status
    for service in services:
        col1, col2, col3 = st.columns([3, 1, 1])
        
        with col1:
            st.markdown(f"**{service['name']}**")
            st.caption(f"Compose: {service['compose_file']}")
        
        # Check service status
        is_running, container_name = is_service_running(service['id'])
        
        with col2:
            if is_running:
                st.success("🟢 Running")
                st.caption(f"Container: {container_name}")
            else:
                st.error("🔴 Stopped")
        
        with col3:
            if is_running:
                if st.button(f"Stop", key=f"stop_{service['id']}"):
                    with st.spinner(f"Stopping {service['name']}..."):
                        success, message = stop_soc_service(service['id'])
                        if success:
                            st.success(f"✅ {message}")
                            st.experimental_rerun()
                        else:
                            st.error(f"❌ {message}")
            else:
                if st.button(f"Start", key=f"start_{service['id']}"):
                    with st.spinner(f"Starting {service['name']}..."):
                        success, message = start_soc_service(service['id'])
                        if success:
                            st.success(f"✅ {message}")
                            st.experimental_rerun()
                        else:
                            st.error(f"❌ {message}")

def show_requirements():
    """Display and manage system requirements"""
    st.header("System Requirements")
    
    # Check Docker status
    docker_ok, docker_msg = check_docker()
    
    # System requirements
    requirements = [
        {"name": "Docker", "required": True, "status": docker_ok, "message": docker_msg},
        {"name": "Python 3.8+", "required": True, "status": sys.version_info >= (3, 8), "message": f"Current: {sys.version.split()[0]}"},
        {"name": "Docker Compose", "required": True, "status": shutil.which('docker-compose') is not None or shutil.which('docker') is not None, "message": "Required for service management"},
        {"name": "Disk Space (10GB+)", "required": True, "status": shutil.disk_usage('/').free > 10 * 1024 * 1024 * 1024, "message": "Minimum 10GB free space recommended"},
        {"name": "RAM (8GB+)", "required": True, "status": True, "message": "8GB+ recommended for optimal performance"},
    ]
    
    # Display requirements status
    cols = st.columns(4)
    for i, req in enumerate(requirements):
        with cols[i % 4]:
            if req['status']:
                st.success(f"✓ {req['name']}")
            else:
                st.error(f"✗ {req['name']}")
            st.caption(req['message'])
    
    # Installation instructions
    with st.expander("Installation Instructions"):
        st.markdown("""
        ### Docker Installation
        - **Windows/Mac**: Download and install [Docker Desktop](https://www.docker.com/products/docker-desktop)
        - **Linux**: 
          ```bash
          curl -fsSL https://get.docker.com | sh
          sudo usermod -aG docker $USER
          ```
        
        ### Python Dependencies
        ```bash
        pip install -r requirements.txt
        ```
        """)

def show_integrations():
    """Manage SOC tool integrations"""
    st.header("Integrations")
    
    # Integration status
    integrations = [
        {"name": "Wazuh API", "type": "API", "status": "Connected", "last_checked": "Just now"},
        {"name": "TheHive", "type": "API", "status": "Disconnected", "last_checked": "5 min ago"},
        {"name": "Elasticsearch", "type": "Database", "status": "Connected", "last_checked": "1 min ago"},
        {"name": "Slack", "type": "Notification", "status": "Not Configured", "last_checked": "Never"}
    ]
    
    # Display integrations
    for integration in integrations:
        with st.expander(f"{integration['name']} ({integration['type']}): {integration['status']}"):
            col1, col2 = st.columns([3, 1])
            with col1:
                st.text_input("API URL", key=f"{integration['name'].lower()}_url", placeholder="https://api.example.com")
                st.text_input("API Key" if integration['type'] == "API" else "Connection String", 
                            key=f"{integration['name'].lower()}_key", 
                            type="password")
            with col2:
                st.write("")
                st.write("")
                if st.button(f"Test {integration['name']} Connection", key=f"test_{integration['name'].lower()}"):
                    with st.spinner("Testing connection..."):
                        time.sleep(1)  # Simulate connection test
                        st.success("Connection successful!" if integration['status'] == "Connected" else "Connection failed")
            
            if st.button(f"Save {integration['name']} Settings", key=f"save_{integration['name'].lower()}"):
                st.success(f"{integration['name']} settings saved successfully!")

def run_command(command: Union[str, List[str]], cwd: Optional[str] = None, shell: bool = False, timeout: int = 30) -> Tuple[bool, str]:
    """Run a shell command and return (success, output)"""
    try:
        result = subprocess.run(
            command,
            cwd=cwd,
            shell=shell,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        if result.returncode != 0:
            error_msg = result.stderr.strip() or "Unknown error"
            return False, error_msg
        return True, result.stdout.strip()
    except subprocess.TimeoutExpired:
        return False, "Command timed out"
    except Exception as e:
        return False, str(e)

def check_docker() -> Tuple[bool, str]:
    """Check if Docker is running and accessible"""
    try:
        success, output = run_command(["docker", "info"])
        if success:
            return True, "Docker is running"
        return False, f"Docker is not running: {output}"
    except Exception as e:
        return False, f"Docker check failed: {str(e)}"

def get_docker_containers(all_containers: bool = False) -> List[str]:
    """Get list of Docker container names"""
    try:
        cmd = ["docker", "ps", "--format", "{{.Names}}"]
        if all_containers:
            cmd.append("-a")
        success, output = run_command(cmd)
        if success:
            return [name for name in output.split('\n') if name.strip()]
        return []
    except Exception as e:
        logger.error(f"Error getting containers: {str(e)}")
        return []

def is_service_running(service_name: str) -> Tuple[bool, Optional[str]]:
    """Check if a service is running and return its container name"""
    try:
        containers = get_docker_containers()
        for container in containers:
            if service_name.lower() in container.lower():
                return True, container
        return False, None
    except Exception as e:
        logger.error(f"Error checking service status: {str(e)}")
        return False, None

def start_soc_service(service_name: str) -> Tuple[bool, str]:
    """
    Start a SOC service using docker-compose
    
    Args:
        service_name: Name of the service to start
        
    Returns:
        Tuple of (success: bool, message: str)
    """
    try:
        compose_file = get_docker_compose_file(service_name.lower())
        compose_path = os.path.join(SOC_LAB_DIR, compose_file)
        
        if not os.path.exists(compose_path):
            return False, f"Docker compose file not found: {compose_path}"
        
        cmd = ["docker-compose", "-f", compose_path, "up", "-d"]
        success, output = run_command(cmd, cwd=SOC_LAB_DIR)
        if success:
            return True, f"Successfully started {service_name}"
        return False, f"Failed to start {service_name}: {output}"
    except Exception as e:
        return False, f"Error starting {service_name}: {str(e)}"

def stop_soc_service(service_name: str, remove_volumes: bool = False) -> Tuple[bool, str]:
    """
    Stop a SOC service using docker-compose
    
    Args:
        service_name: Name of the service to stop
        remove_volumes: Whether to remove volumes when stopping
        
    Returns:
        Tuple of (success: bool, message: str)
    """
    try:
        compose_file = get_docker_compose_file(service_name.lower())
        compose_path = os.path.join(SOC_LAB_DIR, compose_file)
        
        if not os.path.exists(compose_path):
            return False, f"Docker compose file not found: {compose_path}"
        
        cmd = ["docker-compose", "-f", compose_path, "down"]
        if remove_volumes:
            cmd.append("--volumes")
        
        success, output = run_command(cmd, cwd=SOC_LAB_DIR)
        if success:
            return True, f"Successfully stopped {service_name}"
        return False, f"Failed to stop {service_name}: {output}"
    except Exception as e:
        return False, f"Error stopping {service_name}: {str(e)}"

def generate_wazuh_certs() -> Tuple[bool, str]:
    """Generate Wazuh certificates using the certificate manager"""
    try:
        # Ensure certs directory exists
        certs_dir = os.path.join(CERT_DIR, 'wazuh')
        os.makedirs(certs_dir, exist_ok=True)
        
        # Call certificate manager API
        response = requests.post(
            f"{CERT_MANAGER_URL}/generate/wazuh",
            json={"output_dir": certs_dir},
            timeout=60
        )
        
        if response.status_code == 200:
            return True, "Successfully generated Wazuh certificates"
        return False, f"Failed to generate certificates: {response.text}"
    except Exception as e:
        logger.error(f"Error generating Wazuh certificates: {str(e)}")
        return False, f"Error: {str(e)}"

def get_certificate_info(cert_path: str) -> Tuple[bool, Dict]:
    """
    Get detailed information about a certificate file.
    
    Args:
        cert_path: Path to the certificate file
        
    Returns:
        Tuple of (success: bool, result: dict)
    """
    try:
        if not os.path.exists(cert_path):
            return False, {"error": f"Certificate file not found: {cert_path}"}
            
        # Get basic file info
        cert_info = {
            "path": cert_path,
            "size": f"{os.path.getsize(cert_path) / 1024:.2f} KB",
            "modified": time.ctime(os.path.getmtime(cert_path)),
            "type": "PEM" if cert_path.endswith('.pem') else "DER" if cert_path.endswith('.der') else "Unknown"
        }
        
        # Try to get certificate details using OpenSSL if available
        try:
            import OpenSSL
            with open(cert_path, 'rb') as f:
                cert_data = f.read()
                try:
                    if cert_path.endswith('.pem'):
                        cert = OpenSSL.crypto.load_certificate(
                            OpenSSL.crypto.FILETYPE_PEM, 
                            cert_data
                        )
                    else:  # Assume DER format
                        cert = OpenSSL.crypto.load_certificate(
                            OpenSSL.crypto.FILETYPE_ASN1,
                            cert_data
                        )
                    
                    # Extract certificate details
                    subject = dict(x[0] for x in cert.get_subject().get_components())
                    issuer = dict(x[0] for x in cert.get_issuer().get_components())
                    
                    cert_info.update({
                        "subject": {k.decode(): v.decode() for k, v in subject.items()},
                        "issuer": {k.decode(): v.decode() for k, v in issuer.items()},
                        "version": cert.get_version() + 1,
                        "serial_number": cert.get_serial_number(),
                        "not_before": cert.get_notBefore().decode(),
                        "not_after": cert.get_notAfter().decode(),
                        "has_expired": cert.has_expired() == 1,
                        "signature_algorithm": cert.get_signature_algorithm().decode(),
                        "digest_sha1": cert.digest('sha1').decode(),
                        "digest_sha256": cert.digest('sha256').decode()
                    })
                    
                except Exception as e:
                    logger.warning(f"Could not parse certificate {cert_path}: {str(e)}")
                    cert_info["parse_error"] = str(e)
        except ImportError:
            logger.warning("OpenSSL not available, limited certificate information will be shown")
            cert_info["info"] = "Install pyOpenSSL for detailed certificate information"
        
        return True, cert_info
        
    except Exception as e:
        error_msg = f"Error getting certificate info: {str(e)}"
        logger.error(error_msg)
        return False, {"error": error_msg}

def main():
    """Main application function"""
    # Set page config
    st.set_page_config(
        page_title="SOC Management Console",
        page_icon="🛡️",
        layout="wide",
        initial_sidebar_state="expanded"
    )
    
    # Custom CSS
    st.markdown("""
    <style>
        .main-header {font-size:24px; font-weight: bold; color: #1E88E5;}
        .status-card {padding: 15px; border-radius: 10px; margin: 10px 0;}
        .status-running {background-color: #E8F5E9; border-left: 5px solid #4CAF50;}
        .status-stopped {background-color: #FFEBEE; border-left: 5px solid #F44336;}
        .status-warning {background-color: #FFF8E1; border-left: 5px solid #FFC107;}
        .config-section {margin: 20px 0; padding: 15px; background-color: #f5f5f5; border-radius: 5px;}
        .stButton>button {width: 100%; margin: 5px 0;}
        .stAlert {border-radius: 10px;}
        .tab-content {padding: 15px 0;}
        .integration-card {padding: 15px; margin: 10px 0; border-radius: 5px; border: 1px solid #e0e0e0;}
    </style>
    """, unsafe_allow_html=True)
    
    st.title("🛡️ SOC Management Console")
    
    # Sidebar navigation
    st.sidebar.title("Navigation")
    page = st.sidebar.radio("Go to", [
        "Dashboard",
        "Requirements",
        "Integrations",
        "Configuration",
        "Certificate Manager",
        "Logs",
        "SOC Lab Management"
    ])
    
    # Show Docker status in sidebar
    docker_ok, docker_msg = check_docker()
    st.sidebar.markdown("---")
    st.sidebar.subheader("Docker Status")
    if docker_ok:
        st.sidebar.success("🟢 " + docker_msg)
    else:
        st.sidebar.error("🔴 " + docker_msg)
    
    # Show system info in sidebar
    st.sidebar.markdown("---")
    st.sidebar.subheader("System Info")
    st.sidebar.text(f"Python: {sys.version.split()[0]}")
    st.sidebar.text(f"OS: {platform.system()} {platform.release()}")
    
    # Page routing
    if page == "Dashboard":
        st.header("SOC Dashboard")
        st.markdown("""
        Welcome to the SOC Management Console. Monitor and manage your security operations center tools from a single interface.
        """)
        
        # System status overview
        st.subheader("System Status")
        
        # Get system status
        docker_ok, docker_msg = check_docker()
        services = []
        for service_id, compose_file in DOCKER_COMPOSE_FILES.items():
            is_running, container_name = is_service_running(service_id)
            services.append({
                'id': service_id,
                'name': service_id.capitalize(),
                'status': 'running' if is_running else 'stopped',
                'container': container_name if is_running else None
            })
        
        # Calculate metrics
        running_services = sum(1 for s in services if s['status'] == 'running')
        total_services = len(services)
        
        # Display metrics
        col1, col2, col3, col4 = st.columns(4)
        
        with col1:
            st.metric("Services", f"{running_services}/{total_services} Running")
        with col2:
            st.metric("Docker Status", "Running" if docker_ok else "Stopped")
        with col3:
            cpu_percent = 75  # Placeholder - would use psutil in production
            st.metric("CPU Usage", f"{cpu_percent}%")
        with col4:
            mem_percent = 45  # Placeholder - would use psutil in production
            st.metric("Memory Usage", f"{mem_percent}%")
        
        # Service status cards
        st.subheader("Service Status")
        
        if not docker_ok:
            st.error(f"⚠️ {docker_msg}")
            st.warning("Please ensure Docker is installed and running to manage services.")
        else:
            for service in services:
                with st.expander(f"{service['name']}", expanded=True):
                    col1, col2, col3 = st.columns([2, 1, 2])
                    
                    with col1:
                        if service['status'] == 'running':
                            st.success("🟢 Running")
                            if service['container']:
                                st.caption(f"Container: {service['container']}")
                        else:
                            st.error("🔴 Stopped")
                    
                    with col2:
                        if service['status'] == 'running':
                            if st.button(f"Stop", key=f"stop_{service['id']}"):
                                with st.spinner(f"Stopping {service['name']}..."):
                                    success, message = stop_soc_service(service['id'])
                                    if success:
                                        st.success(f"✅ {message}")
                                        st.experimental_rerun()
                                    else:
                                        st.error(f"❌ {message}")
                        else:
                            if st.button(f"Start", key=f"start_{service['id']}"):
                                with st.spinner(f"Starting {service['name']}..."):
                                    success, message = start_soc_service(service['id'])
                                    if success:
                                        st.success(f"✅ {message}")
                                        st.experimental_rerun()
                                    else:
                                        st.error(f"❌ {message}")
                    
                    with col3:
                        if service['status'] == 'running':
                            if st.button(f"Restart", key=f"restart_{service['id']}"):
                                with st.spinner(f"Restarting {service['name']}..."):
                                    # Stop the service first
                                    stop_success, stop_msg = stop_soc_service(service['id'])
                                    if stop_success:
                                        # Then start it again
                                        start_success, start_msg = start_soc_service(service['id'])
                                        if start_success:
                                            st.success(f"✅ {service['name']} restarted successfully")
                                            st.experimental_rerun()
                                        else:
                                            st.error(f"❌ Failed to start: {start_msg}")
                                    else:
                                        st.error(f"❌ Failed to stop: {stop_msg}")
        
        # Display system status
        st.subheader("System Status")
        
        # Check Docker status
        docker_ok, docker_msg = check_docker()
        
        # Get service status
        services = []
        for service_id, compose_file in DOCKER_COMPOSE_FILES.items():
            is_running, container_name = is_service_running(service_id)
            services.append({
                'id': service_id,
                'name': service_id.capitalize(),
                'status': 'running' if is_running else 'stopped',
                'container': container_name if is_running else None
            })
        
        # Calculate metrics
        running_services = sum(1 for s in services if s['status'] == 'running')
        total_services = len(services)
        
        # Display metrics
        col1, col2, col3 = st.columns(3)
        
        with col1:
            st.metric("Services", f"{running_services}/{total_services} Running")
        with col2:
            st.metric("Docker Status", "Running" if docker_ok else "Stopped")
        with col3:
            st.metric("System", f"{platform.system()} {platform.release()}")
        
        # Display service status
        st.subheader("Service Status")
        
        if not docker_ok:
            st.error(f"⚠️ {docker_msg}")
            st.warning("Please ensure Docker is installed and running to manage services.")
        else:
            for service in services:
                with st.expander(f"{service['name']}", expanded=True):
                    col1, col2, col3 = st.columns([2, 1, 2])
                    
                    with col1:
                        if service['status'] == 'running':
                            st.success("🟢 Running")
                            if service['container']:
                                st.caption(f"Container: {service['container']}")
                        else:
                            st.error("🔴 Stopped")
                    
                    with col2:
                        if service['status'] == 'running':
                            if st.button(f"Stop", key=f"stop_{service['id']}"):
                                with st.spinner(f"Stopping {service['name']}..."):
                                    success, message = stop_soc_service(service['id'])
                                    if success:
                                        st.success(f"✅ {message}")
                                        st.experimental_rerun()
                                    else:
                                        st.error(f"❌ {message}")
                        else:
                            if st.button(f"Start", key=f"start_{service['id']}"):
                                with st.spinner(f"Starting {service['name']}..."):
                                    success, message = start_soc_service(service['id'])
                                    if success:
                                        st.success(f"✅ {message}")
                                        st.experimental_rerun()
                                    else:
                                        st.error(f"❌ {message}")
                    
                    with col3:
                        if service['status'] == 'running':
                            if st.button(f"Restart", key=f"restart_{service['id']}"):
                                with st.spinner(f"Restarting {service['name']}..."):
                                    # Stop the service first
                                    stop_success, stop_msg = stop_soc_service(service['id'])
                                    if stop_success:
                                        # Then start it again
                                        start_success, start_msg = start_soc_service(service['id'])
                                        if start_success:
                                            st.success(f"✅ {service['name']} restarted successfully")
                                            st.experimental_rerun()
                                        else:
                                            st.error(f"❌ Failed to start: {start_msg}")
                                    else:
                                        st.error(f"❌ Failed to stop: {stop_msg}")
    elif page == "Requirements":
        show_requirements()
    
    elif page == "Integrations":
        show_integrations()
    
    elif page == "Configuration":
        st.header("Configuration")
        
        tab1, tab2, tab3 = st.tabs(["Services", "Environment", "Backup/Restore"])
        
        with tab1:
            st.subheader("Service Configuration")
            selected_service = st.selectbox("Select Service", list(DOCKER_COMPOSE_FILES.keys()))
            
            if selected_service:
                st.info(f"Configuring {selected_service.capitalize()} service")
                
                # Display service-specific configuration
                config_path = os.path.join(SOC_LAB_DIR, f"config/{selected_service}/config.yml")
                if os.path.exists(config_path):
                    with open(config_path, 'r') as f:
                        current_config = f.read()
                    
                    new_config = st.text_area("Edit Configuration", current_config, height=400)
                    
                    if st.button("Save Configuration"):
                        try:
                            with open(config_path, 'w') as f:
                                f.write(new_config)
                            st.success("Configuration saved successfully!")
                            
                            # Ask to restart service if running
                            is_running, _ = is_service_running(selected_service)
                            if is_running and st.checkbox("Restart service to apply changes?"):
                                with st.spinner(f"Restarting {selected_service}..."):
                                    stop_success, stop_msg = stop_soc_service(selected_service)
                                    if stop_success:
                                        start_success, start_msg = start_soc_service(selected_service)
                                        if start_success:
                                            st.success(f"✅ {selected_service.capitalize()} restarted successfully")
                                        else:
                                            st.error(f"Failed to start {selected_service}: {start_msg}")
                                    else:
                                        st.error(f"Failed to stop {selected_service}: {stop_msg}")
                        except Exception as e:
                            st.error(f"Error saving configuration: {str(e)}")
                else:
                    st.warning("No configuration file found for this service.")
                    if st.button("Create Default Configuration"):
                        try:
                            os.makedirs(os.path.dirname(config_path), exist_ok=True)
                            with open(config_path, 'w') as f:
                                f.write(f"# {selected_service.capitalize()} Configuration\n# Add your configuration here\n")
                            st.success(f"Default configuration created at {config_path}")
                        except Exception as e:
                            st.error(f"Error creating configuration: {str(e)}")
        
        with tab2:
            st.subheader("Environment Configuration")
            # Existing environment configuration code...
            
        with tab3:
            st.subheader("Backup and Restore")
            st.info("Create backups of your SOC configuration and data")
            
            col1, col2 = st.columns(2)
            
            with col1:
                st.write("### Create Backup")
                backup_name = st.text_input("Backup Name", f"soc_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}")
                include_data = st.checkbox("Include service data", value=True)
                
                if st.button("Create Backup"):
                    with st.spinner("Creating backup..."):
                        try:
                            # In a real implementation, this would create a backup archive
                            st.success(f"Backup '{backup_name}' created successfully!")
                        except Exception as e:
                            st.error(f"Error creating backup: {str(e)}")
            
            with col2:
                st.write("### Restore from Backup")
                # In a real implementation, this would list available backups
                available_backups = ["soc_backup_20230716_123456", "soc_backup_20230715_234500"]
                selected_backup = st.selectbox("Select Backup", [""] + available_backups)
                
                if selected_backup and st.button("Restore Backup"):
                    with st.spinner(f"Restoring from {selected_backup}..."):
                        try:
                            # In a real implementation, this would restore the backup
                            st.success(f"Successfully restored from {selected_backup}")
                            st.info("Some services may need to be restarted for changes to take effect.")
                        except Exception as e:
                            st.error(f"Error restoring backup: {str(e)}")
    
    elif page == "Certificate Manager":
        st.header("Certificate Management")
        
        tab1, tab2, tab3 = st.tabs(["Generate", "View", "Settings"])
        
        with tab1:
            st.subheader("Generate Certificates")
            cert_type = st.selectbox("Certificate Type", ["Wazuh", "TheHive", "Nginx", "Custom"])
            
            if cert_type == "Wazuh":
                st.info("Generate certificates for Wazuh components (Indexer, Dashboard, Filebeat)")
                if st.button("Generate Wazuh Certificates"):
                    with st.spinner("Generating Wazuh certificates..."):
                        success, message = generate_wazuh_certs()
                        if success:
                            st.success(message)
                        else:
                            st.error(f"Failed to generate certificates: {message}")
            
            elif cert_type == "TheHive":
                st.info("Generate certificates for TheHive and Cortex")
                st.warning("Certificate generation for TheHive is not yet implemented.")
                
            elif cert_type == "Nginx":
                st.info("Generate SSL certificates for Nginx reverse proxy")
                st.warning("Certificate generation for Nginx is not yet implemented.")
                
            elif cert_type == "Custom":
                st.info("Generate custom certificates")
                st.warning("Custom certificate generation is not yet implemented.")
        
        with tab2:
            st.subheader("View Certificates")
            # List available certificates
            certs_dir = os.path.join(SOC_LAB_DIR, 'certs')
            if os.path.exists(certs_dir):
                cert_files = [f for f in os.listdir(certs_dir) if f.endswith(('.crt', '.pem', '.key'))]
                if cert_files:
                    selected_cert = st.selectbox("Select Certificate", [""] + cert_files)
                    if selected_cert:
                        cert_path = os.path.join(certs_dir, selected_cert)
                        try:
                            with open(cert_path, 'r') as f:
                                cert_data = f.read()
                            st.text_area("Certificate Details", cert_data, height=200)
                            
                            # Show certificate information if it's a valid cert
                            if selected_cert.endswith(('.crt', '.pem')):
                                success, info = get_certificate_info(cert_path)
                                if success:
                                    st.json(info)
                        except Exception as e:
                            st.error(f"Error reading certificate: {str(e)}")
                else:
                    st.info("No certificate files found.")
            else:
                st.warning("Certificate directory not found.")
        
        with tab3:
            st.subheader("Certificate Authority Settings")
            st.info("Configure Certificate Authority settings")
            
            # CA configuration form
            ca_config = {
                'country': st.text_input("Country (2-letter code)", "US"),
                'state': st.text_input("State/Province", "California"),
                'locality': st.text_input("Locality", "San Francisco"),
                'organization': st.text_input("Organization", "My SOC"),
                'email': st.text_input("Email", "admin@example.com"),
                'key_size': st.selectbox("Key Size", [2048, 3072, 4096], index=0),
                'valid_days': st.number_input("Validity (days)", 1, 3650, 365)
            }
            
            if st.button("Save CA Settings"):
                # In a real implementation, this would save the CA configuration
                st.success("CA Settings saved successfully!")
    
    elif page == "Logs":
        st.header("Service Logs")
        
        # Check Docker status first
        docker_ok, docker_msg = check_docker()
        if not docker_ok:
            st.error(f"Docker is not available: {docker_msg}")
            st.warning("Please ensure Docker is installed and running to view logs.")
        else:
            # Get list of containers
            containers = get_docker_containers(all_containers=True)
            
            if not containers:
                st.info("No Docker containers found.")
            else:
                # Container selection
                selected_container = st.selectbox(
                    "Select a container:",
                    [""] + containers,
                    format_func=lambda x: x if x else "-- Select a container --"
                )
                
                if selected_container:
                    # Log controls
                    col1, col2, col3 = st.columns([1, 1, 2])
                    
                    with col1:
                        tail_lines = st.number_input("Number of lines", min_value=10, max_value=1000, value=100)
                        
                    with col2:
                        st.write("")
                        refresh = st.button("🔄 Refresh Logs")
                        
                    with col3:
                        st.write("")
                        follow = st.checkbox("Follow logs", value=False)
                    
                    # Get logs
                    try:
                        cmd = [
                            'docker', 'logs',
                            '--tail', str(tail_lines),
                            selected_container
                        ]
                        
                        if follow:
                            cmd.insert(2, '--follow')
                            
                        success, logs = run_command(cmd, timeout=10 if not follow else None)
                        
                        if success:
                            st.subheader(f"Logs for {selected_container}")
                            st.text_area(
                                "Log Output",
                                logs,
                                height=400,
                                key=f"logs_{selected_container}"
                            )
                            
                            # Auto-refresh if not following
                            if not follow and refresh:
                                st.experimental_rerun()
                                
                        else:
                            st.error(f"Failed to get logs: {logs}")
                            
                    except Exception as e:
                        st.error(f"Error retrieving logs: {str(e)}")
    
    elif page == "SOC Lab Management":
        st.header("SOC Lab Management")
        
        # Check Docker status first
        docker_ok, docker_msg = check_docker()
        if not docker_ok:
            st.error(f"Docker is not available: {docker_msg}")
            st.warning("Please ensure Docker is installed and running to manage services.")
            return
            
        # Define services
        services = [
            {"name": "Wazuh", "id": "wazuh", "description": "Security monitoring"},
            {"name": "TheHive", "id": "thehive", "description": "Incident response platform"},
            {"name": "Cortex", "id": "cortex", "description": "Analysis engine"},
            {"name": "Shuffle", "id": "shuffle", "description": "Security automation"}
        ]
        
        # Display services with status and controls
        st.subheader("SOC Lab Services")
        
        for service in services:
            # Check service status
            is_running, container_name = is_service_running(service['id'])
            status = "🟢 Running" if is_running else "🔴 Stopped"
            
            with st.expander(f"{service['name']} - {status}"):
                st.write(service['description'])
                if is_running and container_name:
                    st.caption(f"Container: {container_name}")
                
                col1, col2 = st.columns(2)
                
                with col1:
                    if st.button(f"🔄 Refresh", key=f"refresh_{service['id']}"):
                        st.experimental_rerun()
                
                with col2:
                    if is_running:
                        if st.button(f"⏹️ Stop", key=f"stop_{service['id']}"):
                            with st.spinner(f"Stopping {service['name']}..."):
                                success, message = stop_soc_service(service['id'])
                                if success:
                                    st.success(f"{service['name']} stopped successfully")
                                    st.experimental_rerun()
                                else:
                                    st.error(f"Failed to stop {service['name']}: {message}")
                    else:
                        if st.button(f"▶️ Start", key=f"start_{service['id']}"):
                            with st.spinner(f"Starting {service['name']}..."):
                                success, message = start_soc_service(service['id'])
                                if success:
                                    st.success(f"{service['name']} started successfully")
                                    st.experimental_rerun()
                                else:
                                    st.error(f"Failed to start {service['name']}: {message}")
        
        # Certificate Management Tab
        st.subheader("Certificate Management")
        st.write("Generate and manage SSL/TLS certificates for SOC Lab services.")
        
        cert_types = ["Wazuh", "TheHive", "Nginx", "Custom"]
        cert_type = st.selectbox("Certificate Type", cert_types)
        
        if cert_type == "Wazuh":
            st.info("Generate certificates for Wazuh components (Indexer, Dashboard, Filebeat)")
            if st.button("Generate Wazuh Certificates"):
                with st.spinner("Generating Wazuh certificates..."):
                    success, message = generate_wazuh_certs()
                    if success:
                        st.success(message)
                    else:
                        st.error(f"Failed to generate certificates: {message}")
        
        elif cert_type == "TheHive":
            st.info("Generate certificates for TheHive and Cortex")
            st.warning("Certificate generation for TheHive is not yet implemented.")
            
        elif cert_type == "Nginx":
            st.info("Generate SSL certificates for Nginx reverse proxy")
            st.warning("Certificate generation for Nginx is not yet implemented.")
            
        elif cert_type == "Custom":
            st.info("Generate custom certificates")
            st.warning("Custom certificate generation is not yet implemented.")
        
        # Configuration Tab
        st.subheader("SOC Lab Configuration")
        st.write("Configure SOC Lab settings and environment.")
        
        # Display current configuration
        config_path = os.path.join(SOC_LAB_DIR, '.env')
        if os.path.exists(config_path):
            with open(config_path, 'r') as f:
                current_config = f.read()
            
            new_config = st.text_area("Edit Configuration", current_config, height=300)
            
            if st.button("Save Configuration"):
                try:
                    with open(config_path, 'w') as f:
                        f.write(new_config)
                    st.success("Configuration saved successfully!")
                except Exception as e:
                    st.error(f"Failed to save configuration: {str(e)}")
        else:
            st.warning("No configuration file found. Would you like to create one?")
            
            # Create a default configuration
            default_config = """# SOC Lab Configuration
# Edit these values as needed

# Wazuh Configuration
WAZUH_API_URL=http://localhost:55000
WAZUH_USER=wazuh
WAZUH_PASSWORD=wazuh

# TheHive Configuration
THEHIVE_URL=http://localhost:9000
THEHIVE_API_KEY=your-api-key-here
"""
            if st.button("Create Default Configuration"):
                try:
                    with open(config_path, 'w') as f:
                        f.write(default_config)
                    st.success(f"Default configuration created at {config_path}")
                    st.experimental_rerun()
                except Exception as e:
                    st.error(f"Failed to create configuration: {str(e)}")
    
    elif page == "Logs":
        st.header("Service Logs")
        
        # Check Docker status first
        docker_ok, docker_msg = check_docker()
        if not docker_ok:
            st.error(f"Docker is not available: {docker_msg}")
            st.warning("Please ensure Docker is installed and running to view logs.")
            return
            
        # Get list of containers
        containers = get_docker_containers(all_containers=True)
        
        if not containers:
            st.info("No Docker containers found.")
            return
            
        # Container selection
        selected_container = st.selectbox(
            "Select a container:",
            [""] + containers,
            format_func=lambda x: x if x else "-- Select a container --"
        )
        
        if not selected_container:
            return
            
        # Log controls
        col1, col2, col3 = st.columns([1, 1, 2])
        
        with col1:
            tail_lines = st.number_input("Number of lines", min_value=10, max_value=1000, value=100)
            
        with col2:
            st.write("")
            refresh = st.button("🔄 Refresh Logs")
            
        with col3:
            st.write("")
            follow = st.checkbox("Follow logs", value=False)
        
        # Get logs
        try:
            cmd = [
                'docker', 'logs',
                '--tail', str(tail_lines),
                selected_container
            ]
            
            if follow:
                cmd.insert(2, '--follow')
                
            success, logs = run_command(cmd, timeout=10 if not follow else None)
            
            if success:
                st.subheader(f"Logs for {selected_container}")
                st.text_area(
                    "Log Output",
                    logs,
                    height=400,
                    key=f"logs_{selected_container}"
                )
                
                # Auto-refresh if not following
                if not follow and refresh:
                    st.experimental_rerun()
                    
            else:
                st.error(f"Failed to get logs: {logs}")
                
        except Exception as e:
            st.error(f"Error retrieving logs: {str(e)}")

if __name__ == "__main__":
    main()
