@echo off
setlocal enabledelayedexpansion

REM Create directories if they don't exist
if not exist "data\wazuh\indexer\certs" mkdir "data\wazuh\indexer\certs"
if not exist "data\wazuh\dashboard\certs" mkdir "data\wazuh\dashboard\certs"

REM Create a temporary directory for certificate generation
set temp_dir=%TEMP%\wazuh-certs
if exist "%temp_dir%" rmdir /s /q "%temp_dir%"
mkdir "%temp_dir%"

REM Generate root CA
(
echo [Version]
echo Signature= "$Windows NT$"
echo [NewRequest]
echo Subject = "CN=Wazuh-Root-CA, O=Wazuh, OU=Wazuh, L=San Francisco, S=California, C=US"
echo Exportable = TRUE
) > "%temp_dir%\rootCA.inf"

certreq -new "%temp_dir%\rootCA.inf" "%temp_dir%\rootCA.cer"
certutil -f -p "" -importpfx -p "" "%temp_dir%\rootCA.cer"

REM Export root CA to PEM format
certutil -f -p "" -exportpfx -p "" -privatekey "Wazuh-Root-CA" "%temp_dir%\rootCA.pfx" NoChain
certutil -f -p "" -exportpfx -p "" "Wazuh-Root-CA" "%temp_dir%\rootCA.pem" NoChain

REM Generate indexer certificate
(
echo [Version]
echo Signature= "$Windows NT$"
echo [NewRequest]
echo Subject = "CN=wazuh.indexer, O=Wazuh, OU=Wazuh, L=San Francisco, S=California, C=US"
echo Exportable = TRUE
) > "%temp_dir%\indexer.inf"

certreq -new "%temp_dir%\indexer.inf" "%temp_dir%\indexer.cer"

REM Export indexer certificate to PFX and then to PEM
certutil -f -p "" -exportpfx -p "" -privatekey "wazuh.indexer" "%temp_dir%\wazuh.indexer.pfx" NoChain
certutil -f -p "" -exportpfx -p "" "wazuh.indexer" "%temp_dir%\wazuh.indexer.pem" NoChain

REM Generate dashboard certificate
(
echo [Version]
echo Signature= "$Windows NT$"
echo [NewRequest]
echo Subject = "CN=wazuh.dashboard, O=Wazuh, OU=Wazuh, L=San Francisco, S=California, C=US"
echo Exportable = TRUE
) > "%temp_dir%\dashboard.inf"

certreq -new "%temp_dir%\dashboard.inf" "%temp_dir%\dashboard.cer"

REM Export dashboard certificate to PFX and then to PEM
certutil -f -p "" -exportpfx -p "" -privatekey "wazuh.dashboard" "%temp_dir%\wazuh-dashboard.pfx" NoChain
certutil -f -p "" -exportpfx -p "" "wazuh.dashboard" "%temp_dir%\wazuh-dashboard.pem" NoChain

REM Generate admin certificate
(
echo [Version]
echo Signature= "$Windows NT$"
echo [NewRequest]
echo Subject = "CN=admin, O=Wazuh, OU=Wazuh, L=San Francisco, S=California, C=US"
echo Exportable = TRUE
) > "%temp_dir%\admin.inf"

certreq -new "%temp_dir%\admin.inf" "%temp_dir%\admin.cer"

REM Export admin certificate to PFX and then to PEM
certutil -f -p "" -exportpfx -p "" -privatekey "admin" "%temp_dir%\admin.pfx" NoChain
certutil -f -p "" -exportpfx -p "" "admin" "%temp_dir%\admin.pem" NoChain

REM Copy files to their destinations
copy /Y "%temp_dir%\rootCA.pem" "data\wazuh\indexer\certs\root-ca.pem"
copy /Y "%temp_dir%\wazuh.indexer.pem" "data\wazuh\indexer\certs\wazuh.indexer.pem"
copy /Y "%temp_dir%\wazuh.indexer.pfx" "data\wazuh\indexer\certs\wazuh.indexer.pfx"
copy /Y "%temp_dir%\admin.pem" "data\wazuh\indexer\certs\admin.pem"

copy /Y "%temp_dir%\rootCA.pem" "data\wazuh\dashboard\certs\root-ca.pem"
copy /Y "%temp_dir%\wazuh-dashboard.pem" "data\wazuh\dashboard\certs\wazuh-dashboard.crt"
copy /Y "%temp_dir%\wazuh-dashboard.pfx" "data\wazuh\dashboard\certs\wazuh-dashboard.pfx"
copy /Y "%temp_dir%\admin.pem" "data\wazuh\dashboard\certs\admin.pem"

REM Clean up temp files
rmdir /s /q "%temp_dir%"

echo.
echo Certificates have been generated successfully!
echo.
