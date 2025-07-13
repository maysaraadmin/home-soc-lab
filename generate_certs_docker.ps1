# Create necessary directories
New-Item -ItemType Directory -Force -Path ".\data\wazuh\indexer\certs" | Out-Null
New-Item -ItemType Directory -Force -Path ".\data\wazuh\dashboard\certs" | Out-Null

# Run a temporary container to generate the certificates
$dockerRunCmd = @"
docker run --rm -it \
  -v "${PWD}/data/wazuh/indexer/certs:/indexer-certs" \
  -v "${PWD}/data/wazuh/dashboard/certs:/dashboard-certs" \
  alpine:3.16 sh -c '
    apk add --no-cache openssl && \
    mkdir -p /certs && cd /certs && \
    
    # Generate root CA
    openssl genrsa -out rootCA.key 4096 && \
    openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.pem \
      -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=Wazuh-Root-CA" && \
    
    # Generate indexer certificate
    cat > indexer.cnf << EOF
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
EOF

    openssl genrsa -out wazuh.indexer.key 2048 && \
    openssl req -new -key wazuh.indexer.key -out wazuh.indexer.csr -config indexer.cnf && \
    openssl x509 -req -in wazuh.indexer.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial \
      -out wazuh.indexer.pem -days 3650 -sha256 -extfile indexer.cnf -extensions v3_req && \
    
    # Generate admin certificate
    cat > admin.cnf << EOF
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
EOF

    openssl genrsa -out admin.key 2048 && \
    openssl req -new -key admin.key -out admin.csr -config admin.cnf && \
    openssl x509 -req -in admin.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial \
      -out admin.crt -days 3650 -sha256 -extfile admin.cnf -extensions v3_req && \
    cat admin.crt admin.key > admin.pem && \
    
    # Generate dashboard certificate
    cat > dashboard.cnf << EOF
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
EOF

    openssl genrsa -out wazuh-dashboard.key 2048 && \
    openssl req -new -key wazuh-dashboard.key -out wazuh-dashboard.csr -config dashboard.cnf && \
    openssl x509 -req -in wazuh-dashboard.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial \
      -out wazuh-dashboard.crt -days 3650 -sha256 -extfile dashboard.cnf -extensions v3_req && \
    
    # Copy certificates to the right locations
    cp rootCA.pem /indexer-certs/ && \
    cp wazuh.indexer.pem /indexer-certs/ && \
    cp wazuh.indexer.key /indexer-certs/ && \
    cp admin.pem /indexer-certs/ && \
    
    cp rootCA.pem /dashboard-certs/ && \
    cp wazuh-dashboard.crt /dashboard-certs/ && \
    cp wazuh-dashboard.key /dashboard-certs/ && \
    cp admin.pem /dashboard-certs/ && \
    
    # Set proper permissions
    chmod 644 /indexer-certs/*.pem /indexer-certs/*.crt /dashboard-certs/*.pem /dashboard-certs/*.crt && \
    chmod 600 /indexer-certs/*.key /dashboard-certs/*.key
'
"@

# Execute the Docker command
Invoke-Expression $dockerRunCmd

Write-Host "Certificates have been generated successfully!" -ForegroundColor Green
