@echo off
echo Building and starting SOC Management GUI with Certificate Manager...

:: Check if Docker is installed
docker --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Docker is not installed or not in PATH. Please install Docker Desktop.
    pause
    exit /b 1
)

:: Build and start the containers
echo Building Docker images...
docker-compose build
if %ERRORLEVEL% neq 0 (
    echo Failed to build Docker images.
    pause
    exit /b 1
)

echo Starting services...
docker-compose up -d
if %ERRORLEVEL% neq 0 (
    echo Failed to start services.
    pause
    exit /b 1
)

echo.
echo ============================================
echo SOC Management GUI is starting...
echo.
echo Open your browser and navigate to:
echo http://localhost:8501
echo.
echo To stop the services, run: docker-compose down
echo ============================================
echo.

pause
