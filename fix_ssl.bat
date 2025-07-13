@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Wazuh SSL Certificate Setup Script
echo ========================================
echo.

echo [*] Checking for required tools...
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PowerShell is not installed or not in PATH
    exit /b 1
)

where docker-compose >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] docker-compose is not installed or not in PATH
    exit /b 1
)

echo [*] Stopping any running Wazuh containers...
docker-compose down
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Failed to stop containers. Continuing anyway...
)

echo [*] Cleaning up old certificates...
if exist "data\wazuh\indexer\certs" rmdir /s /q "data\wazuh\indexer\certs"
if exist "data\wazuh\dashboard\certs" rmdir /s /q "data\wazuh\dashboard\certs"

mkdir "data\wazuh\indexer\certs" 2>nul
mkdir "data\wazuh\dashboard\certs" 2>nul

echo [*] Generating new SSL certificates...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0fix_ssl_final.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to generate SSL certificates
    exit /b 1
)

echo [*] Starting Wazuh services...
docker-compose up -d
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to start Wazuh services
    exit /b 1
)

echo.
echo ========================================
echo Wazuh SSL Setup Completed Successfully!
echo ========================================
echo.
echo [*] Dashboard URL: https://localhost
echo [*] Default credentials:
echo     - Username: admin
echo     - Password: SecretPassword
echo.
echo Note: You may need to accept the self-signed certificate warning in your browser.
echo.

pause
