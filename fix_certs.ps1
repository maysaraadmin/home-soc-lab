# Stop any running containers
Write-Host "Stopping any running containers..."
docker-compose down

# Remove old certificates
Write-Host "Removing old certificates..."
Remove-Item -Recurse -Force data\wazuh\indexer\certs\* -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force data\wazuh\dashboard\certs\* -ErrorAction SilentlyContinue

# Create necessary directories
New-Item -ItemType Directory -Force -Path data\wazuh\indexer\certs | Out-Null
New-Item -ItemType Directory -Force -Path data\wazuh\dashboard\certs | Out-Null

# Set OpenSSL path
$openssl = "C:\Program Files\OpenSSL-Win64\bin\openssl.exe"
$opensslConfig = "d:\home-soc-lab\config\ssl\openssl.cnf"

# Generate root CA
Write-Host "Generating root CA..."
& $openssl genrsa -out data\wazuh\indexer\certs\root-ca.key 4096
& $openssl req -x509 -new -nodes -key data\wazuh\indexer\certs\root-ca.key -sha256 -days 3650 -out data\wazuh\indexer\certs\root-ca.pem -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=Wazuh-Root-CA" -config $opensslConfig

# Generate admin certificate
Write-Host "Generating admin certificate..."
& $openssl genrsa -out data\wazuh\indexer\certs\admin-key-temp.pem 2048
& $openssl pkcs8 -in data\wazuh\indexer\certs\admin-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out data\wazuh\indexer\certs\admin-key.pem
& $openssl req -new -key data\wazuh\indexer\certs\admin-key.pem -out data\wazuh\indexer\certs\admin.csr -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=admin" -config $opensslConfig
& $openssl x509 -req -in data\wazuh\indexer\certs\admin.csr -CA data\wazuh\indexer\certs\root-ca.pem -CAkey data\wazuh\indexer\certs\root-ca.key -CAcreateserial -sha256 -out data\wazuh\indexer\certs\admin.pem

# Generate indexer certificate
Write-Host "Generating indexer certificate..."
& $openssl genrsa -out data\wazuh\indexer\certs\wazuh.indexer.key 2048
& $openssl req -new -key data\wazuh\indexer\certs\wazuh.indexer.key -out data\wazuh\indexer\certs\wazuh.indexer.csr -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=wazuh.indexer" -config $opensslConfig

# Create extension file for indexer
@"
[ v3_ca ]
subjectAltName = DNS:wazuh.indexer,IP:127.0.0.1
"@ | Out-File -FilePath data\wazuh\indexer\certs\indexer.ext -Encoding ASCII

& $openssl x509 -req -in data\wazuh\indexer\certs\wazuh.indexer.csr -CA data\wazuh\indexer\certs\root-ca.pem -CAkey data\wazuh\indexer\certs\root-ca.key -CAcreateserial -sha256 -out data\wazuh\indexer\certs\wazuh.indexer.pem -extfile data\wazuh\indexer\certs\indexer.ext -extensions v3_ca

# Generate dashboard certificate
Write-Host "Generating dashboard certificate..."
& $openssl genrsa -out data\wazuh\dashboard\certs\wazuh-dashboard.key 2048
& $openssl req -new -key data\wazuh\dashboard\certs\wazuh-dashboard.key -out data\wazuh\dashboard\certs\wazuh-dashboard.csr -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=wazuh.dashboard" -config $opensslConfig

# Create extension file for dashboard
@"
[ v3_ca ]
subjectAltName = DNS:wazuh.dashboard,IP:127.0.0.1
"@ | Out-File -FilePath data\wazuh\dashboard\certs\dashboard.ext -Encoding ASCII

& $openssl x509 -req -in data\wazuh\dashboard\certs\wazuh-dashboard.csr -CA data\wazuh\indexer\certs\root-ca.pem -CAkey data\wazuh\indexer\certs\root-ca.key -CAcreateserial -sha256 -out data\wazuh\dashboard\certs\wazuh-dashboard.pem -extfile data\wazuh\dashboard\certs\dashboard.ext -extensions v3_ca

# Copy root CA to dashboard
Copy-Item -Path data\wazuh\indexer\certs\root-ca.pem -Destination data\wazuh\dashboard\certs\root-ca.pem -Force

# Start the services
Write-Host "Starting Wazuh services..."
docker-compose up -d

# Wait for services to start
Write-Host "Waiting for services to start..."
Start-Sleep -Seconds 30

# Create init script inside the container
$initScript = @'
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
'@

# Save init script to a file
$initScript | Out-File -FilePath init_security.sh -Encoding ASCII

# Copy and execute the init script
Write-Host "Initializing security..."
docker cp init_security.sh home-soc-lab-wazuh.indexer-1:/tmp/
docker exec home-soc-lab-wazuh.indexer-1 chmod +x /tmp/init_security.sh
docker exec -e JAVA_HOME=/usr/share/wazuh-indexer/jdk home-soc-lab-wazuh.indexer-1 /tmp/init_security.sh

Write-Host "Setup complete! Try accessing the dashboard at https://localhost"
