@echo off
setlocal enabledelayedexpansion

REM Create certs directory if it doesn't exist
if not exist "certs" mkdir certs
cd certs

echo Generating CA private key and self-signed certificate...
openssl genrsa -out rootCA.key 4096
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.pem ^
  -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=Wazuh-Root-CA"

REM Create server certificate configuration
echo [req] > server.cnf
echo distinguished_name = req_distinguished_name >> server.cnf
echo req_extensions = v3_req >> server.cnf
echo [req_distinguished_name] >> server.cnf
echo C = US >> server.cnf
echo ST = California >> server.cnf
echo L = San Francisco >> server.cnf
echo O = Wazuh >> server.cnf
echo OU = Wazuh >> server.cnf
echo CN = wazuh.indexer >> server.cnf
echo [v3_req] >> server.cnf
echo basicConstraints = CA:FALSE >> server.cnf
echo keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment >> server.cnf
echo extendedKeyUsage = serverAuth, clientAuth >> server.cnf
echo subjectAltName = @alt_names >> server.cnf
echo [alt_names] >> server.cnf
echo DNS.1 = wazuh.indexer >> server.cnf
echo DNS.2 = localhost >> server.cnf
echo IP.1 = 127.0.0.1 >> server.cnf
echo IP.2 = 172.18.0.3 >> server.cnf

echo Generating server private key and CSR...
openssl genrsa -out wazuh.indexer.key 2048
openssl req -new -key wazuh.indexer.key -out wazuh.indexer.csr -config server.cnf

echo Signing server certificate with CA...
openssl x509 -req -in wazuh.indexer.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial ^
  -out wazuh.indexer.pem -days 3650 -sha256 -extfile server.cnf -extensions v3_req

REM Create admin certificate configuration
echo [req] > admin.cnf
echo distinguished_name = req_distinguished_name >> admin.cnf
echo req_extensions = v3_req >> admin.cnf
echo [req_distinguished_name] >> admin.cnf
echo C = US >> admin.cnf
echo ST = California >> admin.cnf
echo L = San Francisco >> admin.cnf
echo O = Wazuh >> admin.cnf
echo OU = Wazuh >> admin.cnf
echo CN = admin >> admin.cnf
echo [v3_req] >> admin.cnf
echo basicConstraints = CA:FALSE >> admin.cnf
echo keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment >> admin.cnf
echo extendedKeyUsage = serverAuth, clientAuth >> admin.cnf

echo Generating admin private key and CSR...
openssl genrsa -out admin.key 2048
openssl req -new -key admin.key -out admin.csr -config admin.cnf

echo Signing admin certificate with CA...
openssl x509 -req -in admin.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial ^
  -out admin.crt -days 3650 -sha256 -extfile admin.cnf -extensions v3_req

REM Create dashboard certificate configuration
echo [req] > dashboard.cnf
echo distinguished_name = req_distinguished_name >> dashboard.cnf
echo req_extensions = v3_req >> dashboard.cnf
echo [req_distinguished_name] >> dashboard.cnf
echo C = US >> dashboard.cnf
echo ST = California >> dashboard.cnf
echo L = San Francisco >> dashboard.cnf
echo O = Wazuh >> dashboard.cnf
echo OU = Wazuh >> dashboard.cnf
echo CN = wazuh.dashboard >> dashboard.cnf
echo [v3_req] >> dashboard.cnf
echo basicConstraints = CA:FALSE >> dashboard.cnf
echo keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment >> dashboard.cnf
echo extendedKeyUsage = serverAuth, clientAuth >> dashboard.cnf
echo subjectAltName = @alt_names >> dashboard.cnf
echo [alt_names] >> dashboard.cnf
echo DNS.1 = wazuh.dashboard >> dashboard.cnf
echo DNS.2 = localhost >> dashboard.cnf
echo IP.1 = 127.0.0.1 >> dashboard.cnf
echo IP.2 = 172.18.0.2 >> dashboard.cnf

echo Generating dashboard private key and CSR...
openssl genrsa -out wazuh-dashboard.key 2048
openssl req -new -key wazuh-dashboard.key -out wazuh-dashboard.csr -config dashboard.cnf

echo Signing dashboard certificate with CA...
openssl x509 -req -in wazuh-dashboard.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial ^
  -out wazuh-dashboard.crt -days 3650 -sha256 -extfile dashboard.cnf -extensions v3_req

echo Creating combined PEM files...
type wazuh.indexer.pem wazuh.indexer.key > wazuh.indexer.combined.pem
type admin.crt admin.key > admin.pem

echo Creating certificate directories...
if not exist "..\data\wazuh\indexer\certs" mkdir "..\data\wazuh\indexer\certs"
if not exist "..\data\wazuh\dashboard\certs" mkdir "..\data\wazuh\dashboard\certs"

echo Copying certificates...
copy rootCA.pem ..\data\wazuh\indexer\certs\
copy wazuh.indexer.pem ..\data\wazuh\indexer\certs\
copy wazuh.indexer.key ..\data\wazuh\indexer\certs\
copy admin.pem ..\data\wazuh\indexer\certs\

copy rootCA.pem ..\data\wazuh\dashboard\certs\
copy wazuh-dashboard.crt ..\data\wazuh\dashboard\certs\
copy wazuh-dashboard.key ..\data\wazuh\dashboard\certs\
copy admin.pem ..\data\wazuh\dashboard\certs\

echo Certificate generation complete!
pause
