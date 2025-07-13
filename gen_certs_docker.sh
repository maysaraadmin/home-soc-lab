#!/bin/bash

# Create a temporary directory for certificate generation
mkdir -p temp_certs
cd temp_certs

# Create the root CA configuration
cat > rootCA.cnf << 'EOL'
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_ca
prompt = no

[req_distinguished_name]
C = US
ST = California
L = San Francisco
O = Wazuh
OU = Wazuh
CN = Wazuh Root CA

[v3_ca]
basicConstraints = critical, CA:TRUE
keyUsage = keyCertSign, cRLSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
EOL

# Create server certificate configuration
cat > server.cnf << 'EOL'
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = California
L = San Francisco
O = Wazuh
OU = Wazuh
CN = wazuh.indexer

[v3_req]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = wazuh.indexer
DNS.2 = localhost
IP.1 = 127.0.0.1
IP.2 = 172.18.0.3
EOL

# Create admin certificate configuration
cat > admin.cnf << 'EOL'
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = California
L = San Francisco
O = Wazuh
OU = Wazuh
CN = admin

[v3_req]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
EOL

# Create dashboard certificate configuration
cat > dashboard.cnf << 'EOL'
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = California
L = San Francisco
O = Wazuh
OU = Wazuh
CN = wazuh.dashboard

[v3_req]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = wazuh.dashboard
DNS.2 = localhost
IP.1 = 127.0.0.1
IP.2 = 172.18.0.2
EOL

# Generate root CA private key and self-signed certificate
echo "Generating root CA..."
openssl genrsa -out rootCA.key 4096
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.pem -config rootCA.cnf

# Generate server certificate
echo "Generating server certificate..."
openssl genrsa -out wazuh.indexer.key 2048
openssl req -new -key wazuh.indexer.key -out wazuh.indexer.csr -config server.cnf
openssl x509 -req -in wazuh.indexer.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out wazuh.indexer.pem -days 3650 -sha256 -extfile server.cnf -extensions v3_req

# Generate admin certificate
echo "Generating admin certificate..."
openssl genrsa -out admin.key 2048
openssl req -new -key admin.key -out admin.csr -config admin.cnf
openssl x509 -req -in admin.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out admin.crt -days 3650 -sha256 -extfile admin.cnf -extensions v3_req

# Generate dashboard certificate
echo "Generating dashboard certificate..."
openssl genrsa -out wazuh-dashboard.key 2048
openssl req -new -key wazuh-dashboard.key -out wazuh-dashboard.csr -config dashboard.cnf
openssl x509 -req -in wazuh-dashboard.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out wazuh-dashboard.crt -days 3650 -sha256 -extfile dashboard.cnf -extensions v3_req

# Create combined PEM files
echo "Creating combined PEM files..."
cat wazuh.indexer.pem wazuh.indexer.key > wazuh.indexer.combined.pem
cat admin.crt admin.key > admin.pem

# Copy certificates to the appropriate locations
echo "Copying certificates..."
# For indexer
cp rootCA.pem wazuh.indexer.pem wazuh.indexer.key admin.pem ../../data/wazuh/indexer/certs/

# For dashboard
cp rootCA.pem wazuh-dashboard.crt wazuh-dashboard.key admin.pem ../../data/wazuh/dashboard/certs/

# Set proper permissions
echo "Setting permissions..."
chmod 644 ../../data/wazuh/indexer/certs/*.pem ../../data/wazuh/dashboard/certs/*.pem ../../data/wazuh/dashboard/certs/*.crt
chmod 600 ../../data/wazuh/indexer/certs/*.key ../../data/wazuh/dashboard/certs/*.key

# Clean up
echo "Cleaning up..."
cd ..
rm -rf temp_certs

echo "Certificate generation complete!"
