#!/bin/bash

# Create directories if they don't exist
mkdir -p ./data/wazuh/indexer/certs

# Generate root CA
openssl genrsa -out ./data/wazuh/indexer/certs/root-ca.key 4096
openssl req -x509 -new -nodes -key ./data/wazuh/indexer/certs/root-ca.key -sha256 -days 3650 -out ./data/wazuh/indexer/certs/root-ca.pem -subj "/C=US/ST=CA/L=San Francisco/O=Wazuh/OU=Docu/CN=Root CA"

# Generate admin certificate
openssl genrsa -out ./data/wazuh/indexer/certs/admin-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in ./data/wazuh/indexer/certs/admin-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out ./data/wazuh/indexer/certs/admin-key.pem
openssl req -new -key ./data/wazuh/indexer/certs/admin-key.pem -out ./data/wazuh/indexer/certs/admin.csr -subj "/C=US/ST=CA/L=San Francisco/O=Wazuh/OU=Docu/CN=admin"
openssl x509 -req -in ./data/wazuh/indexer/certs/admin.csr -CA ./data/wazuh/indexer/certs/root-ca.pem -CAkey ./data/wazuh/indexer/certs/root-ca.key -CAcreateserial -sha256 -out ./data/wazuh/indexer/certs/admin.pem -days 3650

# Generate node certificate
openssl genrsa -out ./data/wazuh/indexer/certs/indexer-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in ./data/wazuh/indexer/certs/indexer-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out ./data/wazuh/indexer/certs/indexer-key.pem
openssl req -new -key ./data/wazuh/indexer/certs/indexer-key.pem -out ./data/wazuh/indexer/certs/indexer.csr -subj "/C=US/ST=CA/L=San Francisco/O=Wazuh/OU=Docu/CN=wazuh.indexer"
echo "subjectAltName=DNS:wazuh.indexer,DNS:localhost,IP:127.0.0.1,IP:0.0.0.0" > ./data/wazuh/indexer/certs/indexer.ext
openssl x509 -req -in ./data/wazuh/indexer/certs/indexer.csr -CA ./data/wazuh/indexer/certs/root-ca.pem -CAkey ./data/wazuh/indexer/certs/root-ca.key -CAcreateserial -sha256 -out ./data/wazuh/indexer/certs/indexer.pem -days 3650 -extfile ./data/wazuh/indexer/certs/indexer.ext

# Generate dashboard certificate
openssl genrsa -out ./data/wazuh/indexer/certs/dashboard-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in ./data/wazuh/indexer/certs/dashboard-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out ./data/wazuh/indexer/certs/dashboard-key.pem
openssl req -new -key ./data/wazuh/indexer/certs/dashboard-key.pem -out ./data/wazuh/indexer/certs/dashboard.csr -subj "/C=US/ST=CA/L=San Francisco/O=Wazuh/OU=Docu/CN=wazuh.dashboard"
echo "subjectAltName=DNS:wazuh.dashboard,DNS:localhost,IP:127.0.0.1,IP:0.0.0.0" > ./data/wazuh/indexer/certs/dashboard.ext
openssl x509 -req -in ./data/wazuh/indexer/certs/dashboard.csr -CA ./data/wazuh/indexer/certs/root-ca.pem -CAkey ./data/wazuh/indexer/certs/root-ca.key -CAcreateserial -sha256 -out ./data/wazuh/indexer/certs/dashboard.pem -days 3650 -extfile ./data/wazuh/indexer/certs/dashboard.ext

# Clean up temporary files
rm -f ./data/wazuh/indexer/certs/*-temp.pem
rm -f ./data/wazuh/indexer/certs/*.csr
rm -f ./data/wazuh/indexer/certs/*.ext
rm -f ./data/wazuh/indexer/certs/*.srl

# Set proper permissions
chmod 400 ./data/wazuh/indexer/certs/*.key
chmod 444 ./data/wazuh/indexer/certs/*.pem

echo "Certificates generated in ./data/wazuh/indexer/certs/"
