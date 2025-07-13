#!/bin/bash

# Stop any running containers
docker-compose down

# Remove old certificates
rm -rf data/wazuh/indexer/certs/*
rm -rf data/wazuh/dashboard/certs/*

# Create necessary directories
mkdir -p data/wazuh/indexer/certs
mkdir -p data/wazuh/dashboard/certs

# Generate root CA
openssl genrsa -out data/wazuh/indexer/certs/root-ca.key 4096
openssl req -x509 -new -nodes -key data/wazuh/indexer/certs/root-ca.key -sha256 -days 3650 -out data/wazuh/indexer/certs/root-ca.pem -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=Wazuh-Root-CA"

# Generate admin certificate
openssl genrsa -out data/wazuh/indexer/certs/admin-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in data/wazuh/indexer/certs/admin-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out data/wazuh/indexer/certs/admin-key.pem
openssl req -new -key data/wazuh/indexer/certs/admin-key.pem -out data/wazuh/indexer/certs/admin.csr -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=admin"
openssl x509 -req -in data/wazuh/indexer/certs/admin.csr -CA data/wazuh/indexer/certs/root-ca.pem -CAkey data/wazuh/indexer/certs/root-ca.key -CAcreateserial -sha256 -out data/wazuh/indexer/certs/admin.pem

# Generate indexer certificate
openssl genrsa -out data/wazuh/indexer/certs/wazuh.indexer.key 2048
openssl req -new -key data/wazuh/indexer/certs/wazuh.indexer.key -out data/wazuh/indexer/certs/wazuh.indexer.csr -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=wazuh.indexer"

echo "[ v3_ca ]
subjectAltName = DNS:wazuh.indexer,IP:127.0.0.1" > data/wazuh/indexer/certs/indexer.ext

openssl x509 -req -in data/wazuh/indexer/certs/wazuh.indexer.csr -CA data/wazuh/indexer/certs/root-ca.pem -CAkey data/wazuh/indexer/certs/root-ca.key -CAcreateserial -sha256 -out data/wazuh/indexer/certs/wazuh.indexer.pem -extfile data/wazuh/indexer/certs/indexer.ext -extensions v3_ca

# Generate dashboard certificate
openssl genrsa -out data/wazuh/dashboard/certs/wazuh-dashboard.key 2048
openssl req -new -key data/wazuh/dashboard/certs/wazuh-dashboard.key -out data/wazuh/dashboard/certs/wazuh-dashboard.csr -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=wazuh.dashboard"

echo "[ v3_ca ]
subjectAltName = DNS:wazuh.dashboard,IP:127.0.0.1" > data/wazuh/dashboard/certs/dashboard.ext

openssl x509 -req -in data/wazuh/dashboard/certs/wazuh-dashboard.csr -CA data/wazuh/indexer/certs/root-ca.pem -CAkey data/wazuh/indexer/certs/root-ca.key -CAcreateserial -sha256 -out data/wazuh/dashboard/certs/wazuh-dashboard.pem -extfile data/wazuh/dashboard/certs/dashboard.ext -extensions v3_ca

# Copy root CA to dashboard
cp data/wazuh/indexer/certs/root-ca.pem data/wazuh/dashboard/certs/root-ca.pem

# Set proper permissions
chmod 400 data/wazuh/indexer/certs/*
chmod 400 data/wazuh/dashboard/certs/*

# Start the services
docker-compose up -d

# Wait for services to start
echo "Waiting for services to start..."
sleep 30

# Initialize security
cat > init_security.sh << 'EOF'
#!/bin/bash

# Wait for OpenSearch to be ready
until curl -k -s https://localhost:9200 -u admin:admin; do
    echo "Waiting for OpenSearch to be ready..."
    sleep 5
done

# Initialize the security plugin
/usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh \
    -cd /usr/share/wazuh-indexer/opensearch-security/ \
    -icl -nhnv \
    -cacert /usr/share/wazuh-indexer/certs/root-ca.pem \
    -cert /usr/share/wazuh-indexer/certs/admin.pem \
    -key /usr/share/wazuh-indexer/certs/admin-key.pem
EOF

chmod +x init_security.sh
docker cp init_security.sh home-soc-lab-wazuh.indexer-1:/tmp/
docker exec home-soc-lab-wazuh.indexer-1 chmod +x /tmp/init_security.sh
docker exec -e JAVA_HOME=/usr/share/wazuh-indexer/jdk home-soc-lab-wazuh.indexer-1 /tmp/init_security.sh

echo "Setup complete! Try accessing the dashboard at https://localhost"
