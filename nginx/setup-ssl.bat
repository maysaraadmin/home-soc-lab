@echo off
setlocal enabledelayedexpansion

REM Create directories if they don't exist
if not exist ".\nginx\ssl\thehive" mkdir ".\nginx\ssl\thehive"
if not exist ".\nginx\logs" mkdir ".\nginx\logs"
if not exist ".\nginx\html" mkdir ".\nginx\html"
if not exist ".\nginx\acme" mkdir ".\nginx\acme"

REM Check if OpenSSL is installed
where openssl >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo OpenSSL is not installed or not in PATH. Please install OpenSSL and try again.
    exit /b 1
)

REM Generate a self-signed certificate (for development only)
REM In production, replace this with a proper certificate from Let's Encrypt
echo Generating self-signed certificate...
openssl req -x509 -nodes -days 365 -newkey rsa:2048 ^
  -keyout .\nginx\ssl\thehive\privkey.pem ^
  -out .\nginx\ssl\thehive\cert.pem ^
  -subj "/CN=localhost" ^
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"

if %ERRORLEVEL% NEQ 0 (
    echo Failed to generate SSL certificate.
    exit /b 1
)

echo.
echo SSL certificates have been generated in .\nginx\ssl\thehive\
echo For production, please replace these with valid certificates from a trusted CA.
echo.
pause
