@echo off
setlocal enabledelayedexpansion

:: Set up paths
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
set "DOT_ENV=%ROOT_DIR%\dot.env"

:: List of services
set "SERVICES=wazuh graylog agents grafana velociraptor shuffle thehive-cortex"
set "NETWORK_STACK=siem-stack shuffle thehive-cortex"

:: Process command line arguments
set "DOCKER_ARGS="
:process_args
if not "%1"=="" (
    set "DOCKER_ARGS=!DOCKER_ARGS! %1"
    shift
    goto :process_args
)

:: Setup environment
for %%s in (%SERVICES%) do (
    if exist "%ROOT_DIR%\%%s\setup.bat" (
        echo [INFO] Found setup.bat script in %%s
        call "%ROOT_DIR%\%%s\setup.bat"
        if !errorlevel! equ 0 (
            echo [SUCCESS] Successfully set up the environment for %%s
        ) else (
            echo [WARNING] Setup failed for %%s
        )
    )
)

echo [INFO] Generating unified .env -> %DOT_ENV%
echo. > "%DOT_ENV%"

if exist "%ROOT_DIR%\versions.env" (
    findstr /v "^#" "%ROOT_DIR%\versions.env" | findstr /v "^$" >> "%DOT_ENV%"
    echo. >> "%DOT_ENV%"
) else (
    echo [WARNING] versions.env not found!
)

:: Merge all .env files
for %%s in (%SERVICES%) do (
    set "ENV_FILE=%ROOT_DIR%\%%s\.env"
    if exist "!ENV_FILE!" (
        echo [INFO] Merging from !ENV_FILE! to %DOT_ENV%
        if "%%s"=="shuffle" (
            for /f "usebackq tokens=*" %%a in ("!ENV_FILE!") do (
                set "line=%%a"
                if not "!line:~0,1!"=="#" if not "!line!"=="" (
                    set "line=!line:./=%ROOT_DIR%\shuffle!"
                    echo !line!>> "%DOT_ENV%"
                )
            )
        ) else (
            findstr /v "^#" "!ENV_FILE!" | findstr /v "^$" >> "%DOT_ENV%"
            echo. >> "%DOT_ENV%"
        )
    ) else (
        echo [WARNING] Env file !ENV_FILE! not found, skipping...
    )
)

:: Create Docker networks if they don't exist
for %%n in (%NETWORK_STACK%) do (
    docker network ls --format "{{.Name}}" | findstr /C:"%%n" >nul
    if !errorlevel! 1 (
        echo [WARNING] Docker network '%%n' already exists. skipping
    ) else (
        echo [INFO] Creating Docker network '%%n'...
        docker network create --driver bridge "%%n"
        if !errorlevel! 0 (
            echo [SUCCESS] Created Docker network '%%n'
        )
    )
)

echo [INFO] Starting the containers...

:: Build docker-compose command
set "COMPOSE_FILES="
set "STARTED_SERVICES="

for %%s in (%SERVICES%) do (
    if not "%%s"=="shuffle" (
        if exist "%ROOT_DIR%\%%s\docker-compose.yml" (
            set "COMPOSE_FILES=!COMPOSE_FILES! -f "%ROOT_DIR%\%%s\docker-compose.yml""
            set "STARTED_SERVICES=!STARTED_SERVICES! %%s"
        )
    )
)

echo [SUCCESS] Starting the containers: %STARTED_SERVICES%
docker-compose %COMPOSE_FILES% --env-file "%DOT_ENV%" up %DOCKER_ARGS%

endlocal
