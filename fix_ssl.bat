@echo off
echo Cleaning up old certificates...
rmdir /s /q data\wazuh\indexer\certs
rmdir /s /q data\wazuh\dashboard\certs

mkdir data\wazuh\indexer\certs
mkdir data\wazuh\dashboard\certs

echo Generating new certificates...
powershell -ExecutionPolicy Bypass -File .\generate_certs_simple.ps1

echo Starting Wazuh services...
docker-compose down
docker-compose up -d

echo.
echo Wazuh services are starting with SSL enabled.
echo Access the dashboard at: https://localhost
echo Note: You may need to accept the self-signed certificate warning in your browser.
