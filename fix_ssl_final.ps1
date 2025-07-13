# Stop any running containers
Write-Host "Stopping any running Wazuh containers..."
docker-compose down

# Create necessary directories
$indexerCertsDir = "d:\home-soc-lab\data\wazuh\indexer\certs"
$dashboardCertsDir = "d:\home-soc-lab\data\wazuh\dashboard\certs"

# Clean up old certificates
Remove-Item -Path $indexerCertsDir\* -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $dashboardCertsDir\* -Recurse -Force -ErrorAction SilentlyContinue

# Create directories if they don't exist
New-Item -ItemType Directory -Force -Path $indexerCertsDir | Out-Null
New-Item -ItemType Directory -Force -Path $dashboardCertsDir | Out-Null

# Set OpenSSL path
$openssl = "C:\Program Files\OpenSSL-Win64\bin\openssl.exe"
$opensslConfig = "d:\home-soc-lab\config\ssl\openssl.cnf"

# Check if OpenSSL is available
if (-not (Test-Path $openssl)) {
    Write-Host "OpenSSL not found at $openssl"
    Write-Host "Please install OpenSSL from: https://slproweb.com/products/Win32OpenSSL.html"
    Write-Host "Make sure to select 'Copy OpenSSL DLLs to /Windows/system32' during installation."
    exit 1
}

# Check if OpenSSL config exists
if (-not (Test-Path $opensslConfig)) {
    Write-Host "OpenSSL config not found at $opensslConfig"
    exit 1
}

$opensslVersion = & $openssl version 2>$null
Write-Host "Using OpenSSL: $opensslVersion"
Write-Host "Using OpenSSL config: $opensslConfig"

# Create a temporary directory for certificate generation
$tempDir = [System.IO.Path]::GetTempPath() + "wazuh-certs"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# Generate root CA
Write-Host "Generating root CA..."
& $openssl genrsa -out "$tempDir\rootCA.key" 4096
& $openssl req -x509 -new -nodes -key "$tempDir\rootCA.key" -sha256 -days 3650 -out "$tempDir\rootCA.pem" -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=Wazuh-Root-CA" -config "$opensslConfig"

# Generate indexer certificate
Write-Host "Generating indexer certificate..."
$indexerConfig = @"
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
"@

Set-Content -Path "$tempDir\indexer.ext" -Value $indexerConfig

& $openssl genrsa -out "$tempDir\wazuh.indexer.key" 2048
& $openssl req -new -key "$tempDir\wazuh.indexer.key" -out "$tempDir\wazuh.indexer.csr" -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=wazuh.indexer" -config "$opensslConfig"
& $openssl x509 -req -in "$tempDir\wazuh.indexer.csr" -CA "$tempDir\rootCA.pem" -CAkey "$tempDir\rootCA.key" -CAcreateserial -out "$tempDir\wazuh.indexer.pem" -days 3650 -sha256 -extfile "$opensslConfig" -extensions v3_req

# Generate dashboard certificate
Write-Host "Generating dashboard certificate..."
$dashboardConfig = @"
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
"@

Set-Content -Path "$tempDir\dashboard.ext" -Value $dashboardConfig

& $openssl genrsa -out "$tempDir\wazuh-dashboard.key" 2048
& $openssl req -new -key "$tempDir\wazuh-dashboard.key" -out "$tempDir\wazuh-dashboard.csr" -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=wazuh.dashboard" -config "$opensslConfig"
& $openssl x509 -req -in "$tempDir\wazuh-dashboard.csr" -CA "$tempDir\rootCA.pem" -CAkey "$tempDir\rootCA.key" -CAcreateserial -out "$tempDir\wazuh-dashboard.crt" -days 3650 -sha256 -extfile "$opensslConfig" -extensions v3_req

# Generate admin certificate
Write-Host "Generating admin certificate..."
$adminConfig = @"
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
"@

Set-Content -Path "$tempDir\admin.ext" -Value $adminConfig

& $openssl genrsa -out "$tempDir\admin.key" 2048
& $openssl req -new -key "$tempDir\admin.key" -out "$tempDir\admin.csr" -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=admin" -config "$opensslConfig"
& $openssl x509 -req -in "$tempDir\admin.csr" -CA "$tempDir\rootCA.pem" -CAkey "$tempDir\rootCA.key" -CAcreateserial -out "$tempDir\admin.crt" -days 3650 -sha256 -extfile "$opensslConfig" -extensions v3_req

# Create combined admin.pem
Get-Content "$tempDir\admin.crt", "$tempDir\admin.key" | Set-Content "$tempDir\admin.pem"

# Copy files to their destinations
Write-Host "Copying certificate files to their destinations..."

# For indexer
Copy-Item -Path "$tempDir\rootCA.pem" -Destination "$indexerCertsDir\root-ca.pem" -Force
Copy-Item -Path "$tempDir\wazuh.indexer.pem" -Destination "$indexerCertsDir\wazuh.indexer.pem" -Force
Copy-Item -Path "$tempDir\wazuh.indexer.key" -Destination "$indexerCertsDir\wazuh.indexer.key" -Force
Copy-Item -Path "$tempDir\admin.pem" -Destination "$indexerCertsDir\admin.pem" -Force

# For dashboard
New-Item -ItemType Directory -Force -Path "$dashboardCertsDir" | Out-Null
Copy-Item -Path "$tempDir\rootCA.pem" -Destination "$dashboardCertsDir\root-ca.pem" -Force
Copy-Item -Path "$tempDir\wazuh-dashboard.crt" -Destination "$dashboardCertsDir\wazuh-dashboard.crt" -Force
Copy-Item -Path "$tempDir\wazuh-dashboard.key" -Destination "$dashboardCertsDir\wazuh-dashboard.key" -Force
Copy-Item -Path "$tempDir\admin.pem" -Destination "$dashboardCertsDir\admin.pem" -Force

# Set file permissions (for Linux containers)
Write-Host "Setting file permissions..."
Get-ChildItem -Path $indexerCertsDir, $dashboardCertsDir -Recurse | ForEach-Object { $_.Attributes = "Normal" }

# Clean up temp files
Remove-Item -Path "$tempDir" -Recurse -Force -ErrorAction SilentlyContinue

# Start the services
Write-Host "Starting Wazuh services..."
docker-compose up -d

Write-Host ""
Write-Host "Wazuh services are starting with SSL enabled." -ForegroundColor Green
Write-Host "Access the dashboard at: https://localhost"
Write-Host "Note: You may need to accept the self-signed certificate warning in your browser."
Write-Host ""
Write-Host "Login credentials:"
Write-Host "  Username: admin"
Write-Host "  Password: SecretPassword"
Write-Host ""
Write-Host "If you encounter any issues, please check the logs with:"
Write-Host "docker-compose logs wazuh.dashboard" -ForegroundColor Cyan
