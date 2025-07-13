#!/bin/bash

set -e

# Create certs directory if it doesn't exist
mkdir -p certs
cd certs

# Generate CA private key and self-signed certificate
echo "Generating CA private key and self-signed certificate..."
openssl genrsa -out rootCA.key 4096
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.pem \
  -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=Wazuh-Root-CA"

# Generate server certificate with both serverAuth and clientAuth EKUs
cat > server.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = wazuh.indexer
DNS.2 = localhost
IP.1 = 127.0.0.1
IP.2 = 172.18.0.3
EOF

echo "Generating server private key and CSR..."
openssl genrsa -out wazuh.indexer.key 2048
openssl req -new -key wazuh.indexer.key -out wazuh.indexer.csr \
  -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=wazuh.indexer"

echo "Signing server certificate with CA..."
openssl x509 -req -in wazuh.indexer.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial \
  -out wazuh.indexer.pem -days 3650 -sha256 -extfile server.ext

# Generate admin certificate with both serverAuth and clientAuth EKUs
cat > admin.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
EOF

echo "Generating admin private key and CSR..."
openssl genrsa -out admin.key 2048
openssl req -new -key admin.key -out admin.csr \
  -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=admin"

echo "Signing admin certificate with CA..."
openssl x509 -req -in admin.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial \
  -out admin.crt -days 3650 -sha256 -extfile admin.ext

# Create wazuh-dashboard certificate (needed for the dashboard)
cat > dashboard.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = wazuh.dashboard
DNS.2 = localhost
IP.1 = 127.0.0.1
IP.2 = 172.18.0.2
EOF

echo "Generating dashboard private key and CSR..."
openssl genrsa -out wazuh-dashboard.key 2048
openssl req -new -key wazuh-dashboard.key -out wazuh-dashboard.csr \
  -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=wazuh.dashboard"

echo "Signing dashboard certificate with CA..."
openssl x509 -req -in wazuh-dashboard.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial \
  -out wazuh-dashboard.crt -days 3650 -sha256 -extfile dashboard.ext

# Create combined PEM files for Wazuh
echo "Creating combined PEM files..."
cat wazuh.indexer.pem wazuh.indexer.key > wazuh.indexer.combined.pem
cat admin.crt admin.key > admin.pem

# Copy certificates to the appropriate locations for Docker volumes
echo "Copying certificates..."
# For indexer
mkdir -p ../data/wazuh/indexer/certs
cp rootCA.pem wazuh.indexer.pem wazuh.indexer.key admin.pem ../data/wazuh/indexer/certs/

# For dashboard
mkdir -p ../data/wazuh/dashboard/certs
cp rootCA.pem wazuh-dashboard.crt wazuh-dashboard.key admin.pem ../data/wazuh/dashboard/certs/

# Set proper permissions
echo "Setting permissions..."
chmod 644 ../data/wazuh/indexer/certs/*
chmod 600 ../data/wazuh/indexer/certs/*.key
chmod 644 ../data/wazuh/dashboard/certs/*
chmod 600 ../data/wazuh/dashboard/certs/*.key

echo "Certificate generation complete!"
