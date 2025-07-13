# Create root CA certificate
$rootCADir = "$PSScriptRoot\certs"
if (-not (Test-Path -Path $rootCADir)) {
    New-Item -ItemType Directory -Path $rootCADir | Out-Null
}

# Generate root CA private key
openssl genrsa -out "$rootCADir\root-ca-key.pem" 2048

# Generate root CA certificate
openssl req -new -x509 -sha256 -days 3650 -subj "/C=US/ST=CA/L=SanFrancisco/O=Wazuh/OU=Wazuh/CN=RootCA" \
    -key "$rootCADir\root-ca-key.pem" -out "$rootCADir\root-ca.pem"

# Generate node certificate
openssl genrsa -out "$rootCADir\node1-key.pem" 2048

# Create certificate signing request
openssl req -new -subj "/C=US/ST=CA/L=SanFrancisco/O=Wazuh/OU=Wazuh/CN=node1" \
    -key "$rootCADir\node1-key.pem" -out "$rootCADir\node1.csr"

echo "authorityKeyIdentifier=keyid,issuer" > "$rootCADir\node1.ext"
echo "basicConstraints=CA:FALSE" >> "$rootCADir\node1.ext"
echo "keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment" >> "$rootCADir\node1.ext"
echo "subjectAltName = @alt_names" >> "$rootCADir\node1.ext"
echo "[alt_names]" >> "$rootCADir\node1.ext"
echo "DNS.1 = node1" >> "$rootCADir\node1.ext"

# Sign the node certificate
openssl x509 -req -in "$rootCADir\node1.csr" -CA "$rootCADir\root-ca.pem" -CAkey "$rootCADir\root-ca-key.pem" \
    -CAcreateserial -sha256 -days 3650 -extfile "$rootCADir\node1.ext" -out "$rootCADir\node1.pem"

# Clean up
Remove-Item "$rootCADir\node1.csr" -Force
Remove-Item "$rootCADir\node1.ext" -Force

# Set proper permissions (optional on Windows, but good practice)
$acl = Get-Acl "$rootCADir\root-ca-key.pem"
$acl.SetAccessRuleProtection($true, $false)
$acl | Set-Acl "$rootCADir\root-ca-key.pem"

$acl = Get-Acl "$rootCADir\node1-key.pem"
$acl.SetAccessRuleProtection($true, $false)
$acl | Set-Acl "$rootCADir\node1-key.pem"

Write-Host "Certificates generated successfully in $rootCADir"
