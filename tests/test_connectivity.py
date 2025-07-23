"""
SOC Environment Connectivity Tests

This module contains tests to verify the basic connectivity and health
of the SOC environment components.
"""
import os
import pytest
import requests
from typing import Dict, List

# Get test configuration from environment variables
BASE_URL = os.getenv('API_URL', 'http://localhost')
TIMEOUT = int(os.getenv('TEST_TIMEOUT', '10'))

# Service endpoints to test
SERVICES = [
    {
        'name': 'TheHive',
        'endpoint': '/api/v1/status',
        'port': 9000,
        'auth_required': True
    },
    {
        'name': 'Cortex',
        'endpoint': '/api/status',
        'port': 9001,
        'auth_required': True
    },
    {
        'name': 'MISP',
        'endpoint': '/servers/getVersion.json',
        'port': 80,
        'auth_required': True
    },
    {
        'name': 'Wazuh API',
        'endpoint': '/',
        'port': 55000,
        'auth_required': True
    },
    {
        'name': 'Elasticsearch',
        'endpoint': '/_cluster/health',
        'port': 9200,
        'auth_required': False
    },
    {
        'name': 'Kibana',
        'endpoint': '/api/status',
        'port': 5601,
        'auth_required': False
    }
]


def get_service_url(service: Dict) -> str:
    """Construct the full URL for a service endpoint."""
    return f"{BASE_URL}:{service['port']}{service['endpoint']}"


@pytest.mark.parametrize("service", [s for s in SERVICES])
def test_service_connectivity(service: Dict):
    """Test connectivity to SOC services."""
    url = get_service_url(service)
    
    try:
        response = requests.get(
            url,
            timeout=TIMEOUT,
            verify=False,  # Disable SSL verification for testing
            headers={'Content-Type': 'application/json'},
            auth=('test', 'test') if service.get('auth_required') else None
        )
        
        # Check if the response status code is in the 2xx range
        assert response.status_code in (200, 201, 202), \
            f"{service['name']} returned status code {response.status_code}"
            
        # For services that return JSON, verify the response is valid JSON
        if 'application/json' in response.headers.get('Content-Type', ''):
            assert response.json() is not None, \
                f"{service['name']} returned invalid JSON"
                
    except requests.exceptions.RequestException as e:
        pytest.fail(f"Failed to connect to {service['name']} at {url}: {str(e)}")


def test_elasticsearch_health():
    """Test Elasticsearch cluster health."""
    es_service = next(s for s in SERVICES if s['name'] == 'Elasticsearch')
    url = f"{get_service_url(es_service)}?pretty"
    
    try:
        response = requests.get(url, timeout=TIMEOUT, verify=False)
        assert response.status_code == 200, \
            f"Elasticsearch health check failed: {response.status_code}"
            
        health = response.json()
        assert health['status'] in ('green', 'yellow'), \
            f"Elasticsearch cluster status is {health['status']}"
            
    except requests.exceptions.RequestException as e:
        pytest.fail(f"Failed to check Elasticsearch health: {str(e)}")


if __name__ == "__main__":
    # This allows running the tests directly with: python -m tests.test_connectivity
    pytest.main(["-v", "--tb=short", __file__])
