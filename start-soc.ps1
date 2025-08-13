# Check if .env exists, if not create it from template
if (-not (Test-Path .\.env)) {
    Write-Host "Creating .env file from template..."
    Copy-Item -Path .\env.template -Destination .\.env -Force
    Write-Host "Please edit the .env file and set appropriate values before continuing."
    exit 1
}

# Load environment variables
$envFile = Get-Content .\.env -Raw
$envVars = @{}
$envFile -split "`n" | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.*)') {
        $envVars[$matches[1].Trim()] = $matches[2].Trim()
    }
}

# Set required environment variables
$requiredVars = @("ELASTIC_PASSWORD", "CASSANDRA_PASSWORD", "POSTGRES_PASSWORD", "LETSENCRYPT_EMAIL")
$missingVars = $requiredVars | Where-Object { -not $envVars.ContainsKey($_) -or [string]::IsNullOrWhiteSpace($envVars[$_]) }

if ($missingVars) {
    Write-Host "Error: The following required variables are missing or empty in .env file:"
    $missingVars | ForEach-Object { Write-Host "- $_" }
    Write-Host "Please update the .env file and try again."
    exit 1
}

# Create required directories
if (-not (Test-Path .\traefik\letsencrypt)) {
    New-Item -Path .\traefik\letsencrypt -ItemType Directory -Force | Out-Null
}

# Start the services
Write-Host "Starting SOC services..."
docker-compose up -d

# Check if services started successfully
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to start services. Check the logs with 'docker-compose logs'"
    exit 1
}

# Show service status
Write-Host "`nService Status:"
Write-Host "============="
docker ps --format "{{.Names}}: {{.Status}}" | Select-String "thehive|cassandra|elasticsearch|postgres"

# Show access information
Write-Host "`nAccess Information:"
Write-Host "=================="
Write-Host "TheHive: http://localhost:9000"
Write-Host "Traefik Dashboard: http://localhost:8080"
Write-Host "Elasticsearch: http://localhost:9200"

# Show TheHive logs
Write-Host "`nTailing TheHive logs (Ctrl+C to stop):"
Write-Host "===================================="
docker logs -f thehive
