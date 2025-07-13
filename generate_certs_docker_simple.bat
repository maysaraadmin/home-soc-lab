@echo off
setlocal enabledelayedexpansion

REM Create directories if they don't exist
if not exist "data\wazuh\indexer\certs" mkdir "data\wazuh\indexer\certs"
if not exist "data\wazuh\dashboard\certs" mkdir "data\wazuh\dashboard\certs"

echo Creating a temporary directory for certificate generation...
set temp_dir=%TEMP%\wazuh-certs
if exist "%temp_dir%" rmdir /s /q "%temp_dir%"
mkdir "%temp_dir%"

(
echo #!/bin/sh
set -e

# Install OpenSSL
apk add --no-cache openssl

# Create directories
mkdir -p /certs/indexer /certs/dashboard

# Generate root CA
echo "Generating root CA..."
openssl genrsa -out /certs/rootCA.key 4096
openssl req -x509 -new -nodes -key /certs/rootCA.key -sha256 -days 3650 -out /certs/rootCA.pem \
  -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=Wazuh-Root-CA"

# Generate indexer certificate
echo "Generating indexer certificate..."
cat > /certs/indexer.ext <<EOL
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
EOL

openssl genrsa -out /certs/wazuh.indexer.key 2048
openssl req -new -key /certs/wazuh.indexer.key -out /certs/wazuh.indexer.csr \
  -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=wazuh.indexer"
openssl x509 -req -in /certs/wazuh.indexer.csr -CA /certs/rootCA.pem -CAkey /certs/rootCA.key -CAcreateserial \
  -out /certs/wazuh.indexer.pem -days 3650 -sha256 -extfile /certs/indexer.ext -extensions v3_req

# Generate dashboard certificate
echo "Generating dashboard certificate..."
cat > /certs/dashboard.ext <<EOL
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
EOL

openssl genrsa -out /certs/wazuh-dashboard.key 2048
openssl req -new -key /certs/wazuh-dashboard.key -out /certs/wazuh-dashboard.csr \
  -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=wazuh.dashboard"
openssl x509 -req -in /certs/wazuh-dashboard.csr -CA /certs/rootCA.pem -CAkey /certs/rootCA.key -CAcreateserial \
  -out /certs/wazuh-dashboard.crt -days 3650 -sha256 -extfile /certs/dashboard.ext -extensions v3_req

# Generate admin certificate
echo "Generating admin certificate..."
cat > /certs/admin.ext <<EOL
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
EOL

openssl genrsa -out /certs/admin.key 2048
openssl req -new -key /certs/admin.key -out /certs/admin.csr \
  -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=admin"
openssl x509 -req -in /certs/admin.csr -CA /certs/rootCA.pem -CAkey /certs/rootCA.key -CAcreateserial \
  -out /certs/admin.crt -days 3650 -sha256 -extfile /certs/admin.ext -extensions v3_req

# Create combined admin.pem
cat /certs/admin.crt /certs/admin.key > /certs/admin.pem

# Set permissions
echo "Setting permissions..."
chmod 644 /certs/*

# Copy files to the correct locations
echo "Copying files..."
cp /certs/rootCA.pem /certs/indexer/root-ca.pem
cp /certs/wazuh.indexer.pem /certs/indexer/wazuh.indexer.pem
cp /certs/wazuh.indexer.key /certs/indexer/wazuh.indexer.key
cp /certs/admin.pem /certs/indexer/admin.pem

cp /certs/rootCA.pem /certs/dashboard/root-ca.pem
cp /certs/wazuh-dashboard.crt /certs/dashboard/wazuh-dashboard.crt
cp /certs/wazuh-dashboard.key /certs/dashboard/wazuh-dashboard.key
cp /certs/admin.pem /certs/dashboard/admin.pem

echo "Certificate generation complete!"
) > "%temp_dir%\generate_certs.sh"

echo Running certificate generation in Docker container...
docker run --rm -v "%temp%\wazuh-certs:/certs" -v "%CD%\data\wazuh\indexer\certs:/certs/indexer" -v "%CD%\data\wazuh\dashboard\certs:/certs/dashboard" alpine:3.16 sh -c "cat /certs/generate_certs.sh | sh"

if %ERRORLEVEL% NEQ 0 (
    echo Error generating certificates. Please check the output above for details.
    exit /b 1
)

echo.
echo Certificates have been generated successfully!
echo.

echo Cleaning up temporary files...
rmdir /s /q "%temp_dir%"

echo Done!
