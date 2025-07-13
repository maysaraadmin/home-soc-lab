@echo off
setlocal enabledelayedexpansion

REM Create directories if they don't exist
if not exist "data\wazuh\indexer\certs" mkdir "data\wazuh\indexer\certs"
if not exist "data\wazuh\dashboard\certs" mkdir "data\wazuh\dashboard\certs"

echo Certificate directories have been created.
echo.
echo Please follow these steps to set up certificates manually:
echo 1. Install OpenSSL for Windows from: https://slproweb.com/products/Win32OpenSSL.html
echo 2. Add OpenSSL to your system PATH
echo 3. Run the following commands in a new command prompt:
echo.
echo For root CA:
echo openssl genrsa -out data\wazuh\indexer\certs\rootCA.key 4096
echo openssl req -x509 -new -nodes -key data\wazuh\indexer\certs\rootCA.key -sha256 -days 3650 -out data\wazuh\indexer\certs\rootCA.pem -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=Wazuh-Root-CA"
echo copy data\wazuh\indexer\certs\rootCA.pem data\wazuh\dashboard\certs\
echo.
echo For indexer certificate:
echo openssl genrsa -out data\wazuh\indexer\certs\wazuh.indexer.key 2048
echo openssl req -new -key data\wazuh\indexer\certs\wazuh.indexer.key -out data\wazuh\indexer\certs\wazuh.indexer.csr -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=wazuh.indexer"
echo Create a file named 'indexer.ext' with the following content:
echo.
echo authorityKeyIdentifier=keyid,issuer
echo basicConstraints=CA:FALSE
echo keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
echo extendedKeyUsage = serverAuth, clientAuth
echo subjectAltName = @alt_names
echo [alt_names]
echo DNS.1 = wazuh.indexer
echo DNS.2 = localhost
echo IP.1 = 127.0.0.1
echo IP.2 = 172.18.0.3
echo.
echo Then run:
echo openssl x509 -req -in data\wazuh\indexer\certs\wazuh.indexer.csr -CA data\wazuh\indexer\certs\rootCA.pem -CAkey data\wazuh\indexer\certs\rootCA.key -CAcreateserial -out data\wazuh\indexer\certs\wazuh.indexer.pem -days 3650 -sha256 -extfile indexer.ext
echo.
echo For dashboard certificate:
echo openssl genrsa -out data\wazuh\dashboard\certs\wazuh-dashboard.key 2048
echo openssl req -new -key data\wazuh\dashboard\certs\wazuh-dashboard.key -out data\wazuh\dashboard\certs\wazuh-dashboard.csr -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=wazuh.dashboard"
echo Create a file named 'dashboard.ext' with the following content:
echo.
echo authorityKeyIdentifier=keyid,issuer
echo basicConstraints=CA:FALSE
echo keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
echo extendedKeyUsage = serverAuth, clientAuth
echo subjectAltName = @alt_names
echo [alt_names]
echo DNS.1 = wazuh.dashboard
echo DNS.2 = localhost
echo IP.1 = 127.0.0.1
echo IP.2 = 172.18.0.2
echo.
echo Then run:
echo openssl x509 -req -in data\wazuh\dashboard\certs\wazuh-dashboard.csr -CA data\wazuh\dashboard\certs\rootCA.pem -CAkey data\wazuh\indexer\certs\rootCA.key -CAcreateserial -out data\wazuh\dashboard\certs\wazuh-dashboard.crt -days 3650 -sha256 -extfile dashboard.ext
echo.
echo For admin certificate:
echo openssl genrsa -out data\wazuh\indexer\certs\admin.key 2048
echo openssl req -new -key data\wazuh\indexer\certs\admin.key -out data\wazuh\indexer\certs\admin.csr -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=admin"
echo Create a file named 'admin.ext' with the following content:
echo.
echo authorityKeyIdentifier=keyid,issuer
echo basicConstraints=CA:FALSE
echo keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
echo extendedKeyUsage = serverAuth, clientAuth
echo.
echo Then run:
echo openssl x509 -req -in data\wazuh\indexer\certs\admin.csr -CA data\wazuh\indexer\certs\rootCA.pem -CAkey data\wazuh\indexer\certs\rootCA.key -CAcreateserial -out data\wazuh\indexer\certs\admin.crt -days 3650 -sha256 -extfile admin.ext
echo.
echo Create combined admin.pem:
echo type data\wazuh\indexer\certs\admin.crt data\wazuh\indexer\certs\admin.key > data\wazuh\indexer\certs\admin.pem
echo copy data\wazuh\indexer\certs\admin.pem data\wazuh\dashboard\certs\
echo.
echo Clean up temporary files:
echo del data\wazuh\indexer\certs\*.csr data\wazuh\dashboard\certs\*.csr data\wazuh\indexer\certs\admin.crt data\wazuh\indexer\certs\admin.key indexer.ext dashboard.ext admin.ext
echo.
pause
