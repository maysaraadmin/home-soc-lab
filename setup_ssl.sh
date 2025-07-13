#!/bin/bash

# Create directories if they don't exist
mkdir -p ./data/wazuh/indexer/certs
mkdir -p ./data/wazuh/dashboard/certs

# Set proper permissions
chmod 755 ./data/wazuh/indexer/certs
chmod 755 ./data/wazuh/dashboard/certs

# Generate certificates
pwsh -File "./generate_certs_final.ps1"

# Set proper ownership for certificates (adjust UID/GID if needed)
chown -R 1000:1000 ./data/wazuh/indexer/certs
chown -R 1000:1000 ./data/wazuh/dashboard/certs

# Set restrictive permissions on certificate files
chmod 644 ./data/wazuh/indexer/certs/*
chmod 644 ./data/wazuh/dashboard/certs/*

# Make private keys read-only by owner
chmod 600 ./data/wazuh/indexer/certs/*.key
chmod 600 ./data/wazuh/dashboard/certs/*.key
