# Create directories if they don't exist
$certsDir = "d:\home-soc-lab\wazuh\config\wazuh_indexer_ssl_certs"
if (-not (Test-Path $certsDir)) {
    New-Item -ItemType Directory -Path $certsDir | Out-Null
}

# Generate root CA
openssl genrsa -out "$certsDir\root-ca.key" 2048
openssl req -x509 -new -nodes -key "$certsDir\root-ca.key" -sha256 -days 3650 -out "$certsDir\root-ca.pem" -subj "/C=US/ST=CA/L=San Francisco/O=Wazuh/CN=Wazuh Root CA"

# Generate admin certificate
openssl genrsa -out "$certsDir\admin-key-temp.pem" 2048
openssl pkcs8 -inform PEM -outform PEM -in "$certsDir\admin-key-temp.pem" -topk8 -nocrypt -v1 PBE-SHA1-3DES -out "$certsDir\admin-key.pem"
openssl req -new -key "$certsDir\admin-key.pem" -out "$certsDir\admin.csr" -subj "/C=US/ST=CA/L=San Francisco/O=Wazuh/CN=admin"
openssl x509 -req -in "$certsDir\admin.csr" -CA "$certsDir\root-ca.pem" -CAkey "$certsDir\root-ca.key" -CAcreateserial -sha256 -out "$certsDir\admin.pem" -days 3650

# Generate dashboard certificate
openssl genrsa -out "$certsDir\dashboard-key-temp.pem" 2048
openssl pkcs8 -inform PEM -outform PEM -in "$certsDir\dashboard-key-temp.pem" -topk8 -nocrypt -v1 PBE-SHA1-3DES -out "$certsDir\wazuh.dashboard-key.pem"
openssl req -new -key "$certsDir\wazuh.dashboard-key.pem" -out "$certsDir\dashboard.csr" -subj "/C=US/ST=CA/L=San Francisco/O=Wazuh/CN=wazuh.dashboard"
openssl x509 -req -in "$certsDir\dashboard.csr" -CA "$certsDir\root-ca.pem" -CAkey "$certsDir\root-ca.key" -CAcreateserial -sha256 -out "$certsDir\wazuh.dashboard.pem" -days 3650

# Generate indexer certificate
openssl genrsa -out "$certsDir\indexer-key-temp.pem" 2048
openssl pkcs8 -inform PEM -outform PEM -in "$certsDir\indexer-key-temp.pem" -topk8 -nocrypt -v1 PBE-SHA1-3DES -out "$certsDir\wazuh.indexer-key.pem"
openssl req -new -key "$certsDir\wazuh.indexer-key.pem" -out "$certsDir\indexer.csr" -subj "/C=US/ST=CA/L=San Francisco/O=Wazuh/CN=wazuh.indexer"
openssl x509 -req -in "$certsDir\indexer.csr" -CA "$certsDir\root-ca.pem" -CAkey "$certsDir\root-ca.key" -CAcreateserial -sha256 -out "$certsDir\wazuh.indexer.pem" -days 3650

# Generate manager certificate
openssl genrsa -out "$certsDir\manager-key-temp.pem" 2048
openssl pkcs8 -inform PEM -outform PEM -in "$certsDir\manager-key-temp.pem" -topk8 -nocrypt -v1 PBE-SHA1-3DES -out "$certsDir\wazuh.manager-key.pem"
openssl req -new -key "$certsDir\wazuh.manager-key.pem" -out "$certsDir\manager.csr" -subj "/C=US/ST=CA/L=San Francisco/O=Wazuh/CN=wazuh.manager"
openssl x509 -req -in "$certsDir\manager.csr" -CA "$certsDir\root-ca.pem" -CAkey "$certsDir\root-ca.key" -CAcreateserial -sha256 -out "$certsDir\wazuh.manager.pem" -days 3650

# Clean up temporary files
Remove-Item "$certsDir\*-temp.pem" -ErrorAction SilentlyContinue
Remove-Item "$certsDir\*.csr" -ErrorAction SilentlyContinue
Remove-Item "$certsDir\*.srl" -ErrorAction SilentlyContinue

Write-Host "Certificates generated successfully in $certsDir"
