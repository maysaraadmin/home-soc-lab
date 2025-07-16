@echo off
echo Starting SOC Management GUI...

:: Check if Python is installed
python --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Python is not installed or not in PATH. Please install Python 3.8 or higher.
    pause
    exit /b 1
)

:: Check if virtual environment exists, create if not
if not exist "venv\" (
    echo Creating virtual environment...
    python -m venv venv
    if %ERRORLEVEL% neq 0 (
        echo Failed to create virtual environment.
        pause
        exit /b 1
    )
)

:: Activate virtual environment and install requirements
call venv\Scripts\activate
pip install -r requirements.txt
if %ERRORLEVEL% neq 0 (
    echo Failed to install requirements.
    pause
    exit /b 1
)

:: Copy .env.example to .env if .env doesn't exist
if not exist ".env" (
    echo Creating .env file from .env.example...
    copy .env.example .env
    echo Please edit the .env file with your configuration before continuing.
    pause
)

:: Start the Streamlit app
echo Starting SOC Management GUI...
streamlit run app.py

pause
