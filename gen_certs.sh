#!/bin/bash

# Create a new directory for the CA
mkdir -p /tmp/newcerts/ca
cd /tmp/newcerts/ca

# Generate a private key for the CA
openssl genrsa -out rootCA.key 4096

# Create a self-signed root CA certificate
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.pem \
  -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=Wazuh Root CA"

# Create a directory for the indexer certificates
mkdir -p /tmp/newcerts/indexer
cd /tmp/newcerts/indexer

# Generate a private key for the indexer
openssl genrsa -out wazuh.indexer.key 2048

# Create a certificate signing request (CSR) for the indexer
openssl req -new -key wazuh.indexer.key -out wazuh.indexer.csr \
  -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=wazuh.indexer"

# Create a configuration file for the indexer certificate
echo "
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req

[req_distinguished_name]
C = US
ST = California
L = San Francisco
O = Wazuh
OU = Wazuh
CN = wazuh.indexer

[v3_req]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
IP.1 = 127.0.0.1
IP.2 = 0.0.0.0
" > wazuh.indexer.cnf

# Sign the indexer certificate with the CA
openssl x509 -req -in wazuh.indexer.csr -CA ../ca/rootCA.pem -CAkey ../ca/rootCA.key -CAcreateserial \
  -out wazuh.indexer.pem -days 3650 -sha256 -extfile wazuh.indexer.cnf -extensions v3_req

# Create a directory for the admin certificates
mkdir -p /tmp/newcerts/admin
cd /tmp/newcerts/admin

# Generate a private key for the admin
openssl genrsa -out admin.key 2048

# Create a certificate signing request (CSR) for the admin
openssl req -new -key admin.key -out admin.csr \
  -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=admin"

# Create a configuration file for the admin certificate
echo "
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req

[req_distinguished_name]
C = US
ST = California
L = San Francisco
O = Wazuh
OU = Wazuh
CN = admin

[v3_req]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
" > admin.cnf

# Sign the admin certificate with the CA
openssl x509 -req -in admin.csr -CA ../ca/rootCA.pem -CAkey ../ca/rootCA.key -CAcreateserial \
  -out admin.pem -days 3650 -sha256 -extfile admin.cnf -extensions v3_req

# Set proper permissions
chmod 600 /tmp/newcerts/**/*.key
chmod 644 /tmp/newcerts/**/*.pem

# Copy certificates to the correct location
mkdir -p /usr/share/wazuh-indexer/certs
cp /tmp/newcerts/ca/rootCA.pem /usr/share/wazuh-indexer/certs/root-ca.pem
cp /tmp/newcerts/indexer/wazuh.indexer.pem /usr/share/wazuh-indexer/certs/wazuh.indexer.pem
cp /tmp/newcerts/indexer/wazuh.indexer.key /usr/share/wazuh-indexer/certs/wazuh.indexer.key
cp /tmp/newcerts/admin/admin.pem /usr/share/wazuh-indexer/certs/admin.pem
cp /tmp/newcerts/admin/admin.key /usr/share/wazuh-indexer/certs/admin-key.pem

# Set ownership and permissions
chown -R wazuh-indexer:wazuh-indexer /usr/share/wazuh-indexer/certs
chmod 755 /usr/share/wazuh-indexer/certs
chmod 644 /usr/share/wazuh-indexer/certs/*.pem
chmod 600 /usr/share/wazuh-indexer/certs/*.key
