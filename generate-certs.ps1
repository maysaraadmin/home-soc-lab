# Create a temporary directory for certificate generation
$tempDir = "wazuh-certs-temp"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# Create the certificate authority (CA)
openssl genrsa -out "$tempDir\root-ca.key" 4096
openssl req -new -x509 -days 3650 -nodes -key "$tempDir\root-ca.key" -sha256 -out "$tempDir\root-ca.crt" -subj "/C=US/ST=CA/L=San Francisco/O=Wazuh/OU=Wazuh/CN=Wazuh"

# Create the indexer certificate
openssl genrsa -out "$tempDir\indexer.key" 2048
openssl req -new -key "$tempDir\indexer.key" -out "$tempDir\indexer.csr" -subj "/C=US/ST=CA/L=San Francisco/O=Wazuh/OU=Wazuh/CN=wazuh.indexer"

# Sign the indexer certificate
$extFile = "$tempDir\indexer.ext"
@"
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = wazuh.indexer
IP.1 = 127.0.0.1
"@ | Out-File -FilePath $extFile -Encoding ascii

openssl x509 -req -in "$tempDir\indexer.csr" -CA "$tempDir\root-ca.crt" -CAkey "$tempDir\root-ca.key" -CAcreateserial -out "$tempDir\indexer.crt" -days 1095 -sha256 -extfile $extFile

# Copy certificates to the correct locations
Copy-Item -Path "$tempDir\indexer.key" -Destination "data\wazuh\indexer\certs\" -Force
Copy-Item -Path "$tempDir\indexer.crt" -Destination "data\wazuh\indexer\certs\" -Force
Copy-Item -Path "$tempDir\root-ca.crt" -Destination "data\wazuh\indexer\certs\" -Force

# Clean up
try { Remove-Item -Path $tempDir -Recurse -Force -ErrorAction Stop } catch {}

Write-Host "Certificates have been generated and copied to the correct locations."
