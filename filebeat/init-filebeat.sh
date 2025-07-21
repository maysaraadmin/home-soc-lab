#!/bin/bash

# Create necessary directories
mkdir -p ./filebeat/data

# Set proper permissions
chmod go-w ./filebeat.yml
chown root:root ./filebeat.yml
chmod -R go-w ./filebeat/data

# Create a network if it doesn't exist
docker network create soc_network 2>/dev/null || true

# Start Filebeat
echo "Starting Filebeat..."
docker-compose up -d

# Wait for Filebeat to start
echo "Waiting for Filebeat to initialize..."
sleep 10

# Check Filebeat status
echo "Checking Filebeat status..."
docker-compose exec -T filebeat filebeat test output

# Load Filebeat modules
echo "Enabling Filebeat modules..."
docker-compose exec -T filebeat filebeat modules enable system

echo """

=== Filebeat Setup Complete ===

Filebeat is now collecting and forwarding logs from all SOC components to Elasticsearch.

=== Next Steps ===

1. Verify logs are being received in the Wazuh Dashboard
2. Set up index patterns in Kibana for each log type:
   - wazuh-*
   - suricata-*
   - thehive-*
   - cortex-*
   - misp-*
   - system-*

3. Configure dashboards and visualizations for each component
4. Set up alerts based on log patterns
5. Configure log retention policies

=== Troubleshooting ===

View Filebeat logs:
  docker-compose logs -f filebeat

Test Filebeat connection to Elasticsearch:
  docker-compose exec filebeat filebeat test output

View enabled modules:
  docker-compose exec filebeat filebeat modules list

"""
