# Create necessary directories
New-Item -ItemType Directory -Force -Path ".\data\wazuh\indexer\certs" | Out-Null
New-Item -ItemType Directory -Force -Path ".\data\wazuh\dashboard\certs" | Out-Null

# Create a temporary directory for certificate generation
$tempDir = ".\temp_certs"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# Create the root CA configuration
@'
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
'@ | Out-File -FilePath "$tempDir\rootCA.cnf" -Encoding ascii

# Generate root CA private key and self-signed certificate
Write-Host "Generating root CA..."
openssl genrsa -out "$tempDir\rootCA.key" 4096
openssl req -x509 -new -nodes -key "$tempDir\rootCA.key" -sha256 -days 3650 -out "$tempDir\rootCA.pem" -config "$tempDir\rootCA.cnf"

# Create server certificate configuration
@'
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
'@ | Out-File -FilePath "$tempDir\server.cnf" -Encoding ascii

# Generate server certificate
Write-Host "Generating server certificate..."
openssl genrsa -out "$tempDir\wazuh.indexer.key" 2048
openssl req -new -key "$tempDir\wazuh.indexer.key" -out "$tempDir\wazuh.indexer.csr" -config "$tempDir\server.cnf"
openssl x509 -req -in "$tempDir\wazuh.indexer.csr" -CA "$tempDir\rootCA.pem" -CAkey "$tempDir\rootCA.key" -CAcreateserial -out "$tempDir\wazuh.indexer.pem" -days 3650 -sha256 -extfile "$tempDir\server.cnf" -extensions v3_req

# Create admin certificate configuration
@'
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
'@ | Out-File -FilePath "$tempDir\admin.cnf" -Encoding ascii

# Generate admin certificate
Write-Host "Generating admin certificate..."
openssl genrsa -out "$tempDir\admin.key" 2048
openssl req -new -key "$tempDir\admin.key" -out "$tempDir\admin.csr" -config "$tempDir\admin.cnf"
openssl x509 -req -in "$tempDir\admin.csr" -CA "$tempDir\rootCA.pem" -CAkey "$tempDir\rootCA.key" -CAcreateserial -out "$tempDir\admin.crt" -days 3650 -sha256 -extfile "$tempDir\admin.cnf" -extensions v3_req

# Create dashboard certificate configuration
@'
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
'@ | Out-File -FilePath "$tempDir\dashboard.cnf" -Encoding ascii

# Generate dashboard certificate
Write-Host "Generating dashboard certificate..."
openssl genrsa -out "$tempDir\wazuh-dashboard.key" 2048
openssl req -new -key "$tempDir\wazuh-dashboard.key" -out "$tempDir\wazuh-dashboard.csr" -config "$tempDir\dashboard.cnf"
openssl x509 -req -in "$tempDir\wazuh-dashboard.csr" -CA "$tempDir\rootCA.pem" -CAkey "$tempDir\rootCA.key" -CAcreateserial -out "$tempDir\wazuh-dashboard.crt" -days 3650 -sha256 -extfile "$tempDir\dashboard.cnf" -extensions v3_req

# Create combined PEM files
Write-Host "Creating combined PEM files..."
Get-Content "$tempDir\wazuh.indexer.pem", "$tempDir\wazuh.indexer.key" | Set-Content -Path "$tempDir\wazuh.indexer.combined.pem"
Get-Content "$tempDir\admin.crt", "$tempDir\admin.key" | Set-Content -Path "$tempDir\admin.pem"

# Copy certificates to the appropriate locations
Write-Host "Copying certificates..."
# For indexer
Copy-Item -Path "$tempDir\rootCA.pem" -Destination ".\data\wazuh\indexer\certs\"
Copy-Item -Path "$tempDir\wazuh.indexer.pem" -Destination ".\data\wazuh\indexer\certs\"
Copy-Item -Path "$tempDir\wazuh.indexer.key" -Destination ".\data\wazuh\indexer\certs\"
Copy-Item -Path "$tempDir\admin.pem" -Destination ".\data\wazuh\indexer\certs\"

# For dashboard
Copy-Item -Path "$tempDir\rootCA.pem" -Destination ".\data\wazuh\dashboard\certs\"
Copy-Item -Path "$tempDir\wazuh-dashboard.crt" -Destination ".\data\wazuh\dashboard\certs\"
Copy-Item -Path "$tempDir\wazuh-dashboard.key" -Destination ".\data\wazuh\dashboard\certs\"
Copy-Item -Path "$tempDir\admin.pem" -Destination ".\data\wazuh\dashboard\certs\"

# Set proper permissions (on Windows, this is mostly for consistency)
Write-Host "Setting permissions..."
Get-ChildItem -Path ".\data\wazuh\indexer\certs\*" | ForEach-Object { $_.Attributes = 'Normal' }
Get-ChildItem -Path ".\data\wazuh\dashboard\certs\*" | ForEach-Object { $_.Attributes = 'Normal' }

# Clean up temporary files
Write-Host "Cleaning up..."
Remove-Item -Recurse -Force $tempDir

Write-Host "Certificate generation complete!" -ForegroundColor Green
