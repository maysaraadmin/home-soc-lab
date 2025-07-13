@echo off
setlocal enabledelayedexpansion

REM Create directories if they don't exist
if not exist "data\wazuh\indexer\certs" mkdir "data\wazuh\indexer\certs"
if not exist "data\wazuh\dashboard\certs" mkdir "data\wazuh\dashboard\certs"

REM Check if OpenSSL is available
where openssl >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo OpenSSL is not installed or not in PATH. Please install OpenSSL and try again.
    exit /b 1
)

echo Generating root CA...
openssl genrsa -out data\wazuh\indexer\certs\rootCA.key 4096
openssl req -x509 -new -nodes -key data\wazuh\indexer\certs\rootCA.key -sha256 -days 3650 -out data\wazuh\indexer\certs\rootCA.pem ^
  -subj "/C=US/ST=California/L=San Francisco/O=Wazuh/OU=Wazuh/CN=Wazuh-Root-CA"

REM Copy root CA to dashboard certs
copy data\wazuh\indexer\certs\rootCA.pem data\wazuh\dashboard\certs\ >nul

echo Generating indexer certificate...
(
echo [req]
echo distinguished_name = req_distinguished_name
echo req_extensions = v3_req
echo prompt = no
echo.
echo [req_distinguished_name]
echo C = US
echo ST = California
echo L = San Francisco
echo O = Wazuh
echo OU = Wazuh
echo CN = wazuh.indexer
echo.
echo [v3_req]
echo basicConstraints = CA:FALSE
echo keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
echo extendedKeyUsage = serverAuth, clientAuth
echo subjectAltName = @alt_names
echo.
echo [alt_names]
echo DNS.1 = wazuh.indexer
echo DNS.2 = localhost
echo IP.1 = 127.0.0.1
echo IP.2 = 172.18.0.3
) > indexer.cnf

openssl genrsa -out data\wazuh\indexer\certs\wazuh.indexer.key 2048
openssl req -new -key data\wazuh\indexer\certs\wazuh.indexer.key -out data\wazuh\indexer\certs\wazuh.indexer.csr -config indexer.cnf
openssl x509 -req -in data\wazuh\indexer\certs\wazuh.indexer.csr -CA data\wazuh\indexer\certs\rootCA.pem -CAkey data\wazuh\indexer\certs\rootCA.key ^
  -CAcreateserial -out data\wazuh\indexer\certs\wazuh.indexer.pem -days 3650 -sha256 -extfile indexer.cnf -extensions v3_req

echo Generating dashboard certificate...
(
echo [req]
echo distinguished_name = req_distinguished_name
echo req_extensions = v3_req
echo prompt = no
echo.
echo [req_distinguished_name]
echo C = US
echo ST = California
echo L = San Francisco
echo O = Wazuh
echo OU = Wazuh
echo CN = wazuh.dashboard
echo.
echo [v3_req]
echo basicConstraints = CA:FALSE
echo keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
echo extendedKeyUsage = serverAuth, clientAuth
echo subjectAltName = @alt_names
echo.
echo [alt_names]
echo DNS.1 = wazuh.dashboard
echo DNS.2 = localhost
echo IP.1 = 127.0.0.1
echo IP.2 = 172.18.0.2
) > dashboard.cnf

openssl genrsa -out data\wazuh\dashboard\certs\wazuh-dashboard.key 2048
openssl req -new -key data\wazuh\dashboard\certs\wazuh-dashboard.key -out data\wazuh\dashboard\certs\wazuh-dashboard.csr -config dashboard.cnf
openssl x509 -req -in data\wazuh\dashboard\certs\wazuh-dashboard.csr -CA data\wazuh\dashboard\certs\rootCA.pem -CAkey data\wazuh\indexer\certs\rootCA.key ^
  -CAcreateserial -out data\wazuh\dashboard\certs\wazuh-dashboard.crt -days 3650 -sha256 -extfile dashboard.cnf -extensions v3_req

echo Generating admin certificate...
(
echo [req]
echo distinguished_name = req_distinguished_name
echo req_extensions = v3_req
echo prompt = no
echo.
echo [req_distinguished_name]
echo C = US
echo ST = California
echo L = San Francisco
echo O = Wazuh
echo OU = Wazuh
echo CN = admin
echo.
echo [v3_req]
echo basicConstraints = CA:FALSE
echo keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
echo extendedKeyUsage = serverAuth, clientAuth
) > admin.cnf

openssl genrsa -out data\wazuh\indexer\certs\admin.key 2048
openssl req -new -key data\wazuh\indexer\certs\admin.key -out data\wazuh\indexer\certs\admin.csr -config admin.cnf
openssl x509 -req -in data\wazuh\indexer\certs\admin.csr -CA data\wazuh\indexer\certs\rootCA.pem -CAkey data\wazuh\indexer\certs\rootCA.key ^
  -CAcreateserial -out data\wazuh\indexer\certs\admin.crt -days 3650 -sha256 -extfile admin.cnf -extensions v3_req

echo Creating combined PEM files...
type data\wazuh\indexer\certs\admin.crt data\wazuh\indexer\certs\admin.key > data\wazuh\indexer\certs\admin.pem
copy data\wazuh\indexer\certs\admin.pem data\wazuh\dashboard\certs\ >nul

REM Clean up temporary files
del indexer.cnf dashboard.cnf admin.cnf data\wazuh\indexer\certs\*.csr data\wazuh\dashboard\certs\*.csr data\wazuh\indexer\certs\admin.crt data\wazuh\indexer\certs\admin.key

echo Certificates have been generated successfully!
