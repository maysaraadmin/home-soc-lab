#!/bin/bash

# Create necessary directories
mkdir -p ./rules
mkdir -p ./logs

# Set proper permissions
chmod -R 777 ./rules
chmod -R 777 ./logs

# Pull the latest Suricata image
docker-compose pull

# Initialize Suricata rules
echo "Updating Suricata rules..."
docker-compose up -d suricata-update

# Wait for rules to be downloaded
sleep 10

# Start Suricata
echo "Starting Suricata..."
docker-compose up -d suricata

# Start Filebeat
echo "Starting Filebeat..."
docker-compose up -d filebeat-suricata

echo "Suricata setup complete!"
echo "View logs with: docker-compose logs -f suricata"
