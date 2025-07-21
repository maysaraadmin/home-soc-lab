#!/bin/bash

# Create directories
mkdir -p certs

# Generate CA certificate
openssl genrsa -out certs/elastic-stack-ca.key 2048
openssl req -new -x509 -sha256 -days 3650 -key certs/elastic-stack-ca.key -out certs/elastic-stack-ca.crt -subj "/C=US/ST=California/L=San Francisco/O=Security/CN=Elastic Stack CA"

# Generate certificate for Elasticsearch
openssl genrsa -out certs/elasticsearch.key 2048
openssl req -new -key certs/elasticsearch.key -out certs/elasticsearch.csr -subj "/C=US/ST=California/L=San Francisco/O=Security/CN=elasticsearch-soc"
echo "subjectAltName=DNS:elasticsearch-soc,DNS:localhost,IP:127.0.0.1" > certs/elasticsearch.ext
openssl x509 -req -in certs/elasticsearch.csr -CA certs/elastic-stack-ca.crt -CAkey certs/elastic-stack-ca.key -CAcreateserial -out certs/elasticsearch.crt -days 3650 -sha256 -extfile certs/elasticsearch.ext

# Generate PKCS#12 keystore for Elasticsearch
openssl pkcs12 -export -in certs/elasticsearch.crt -inkey certs/elasticsearch.key -out certs/elastic-certificates.p12 -passout pass:

# Set proper permissions
chmod 400 certs/*

# Create CA directory and copy CA certificate
mkdir -p /usr/local/share/ca-certificates/elasticsearch
cp certs/elastic-stack-ca.crt /usr/local/share/ca-certificates/elasticsearch/
update-ca-certificates

echo "Certificates generated successfully!"
echo "CA Certificate: certs/elastic-stack-ca.crt"
echo "Elasticsearch Certificate: certs/elasticsearch.crt"
echo "Elasticsearch Key: certs/elasticsearch.key"
echo "PKCS#12 Keystore: certs/elastic-certificates.p12"
