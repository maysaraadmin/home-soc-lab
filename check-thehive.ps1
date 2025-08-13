# Check if Docker is running
try {
    $dockerInfo = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Docker is not running or not installed. Please start Docker Desktop and try again."
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Function to check container status
function Get-ContainerStatus {
    param (
        [string]$containerName
    )
    
    $container = docker ps -a --filter "name=^${containerName}$" --format '{{.Names}}|{{.Status}}|{{.State}}|{{.Ports}}' 2>&1
    
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($container)) {
        return @{
            Exists = $false
            Status = "Not found"
            State = "Not running"
            Ports = "N/A"
        }
    }
    
    $parts = $container -split '\|'
    
    return @{
        Exists = $true
        Status = $parts[1]
        State = $parts[2]
        Ports = $parts[3]
    }
}

# Check required containers
$containers = @("thehive", "cassandra", "elasticsearch", "postgres")

Write-Host "`nContainer Status:"
Write-Host "================"

$allRunning = $true

foreach ($container in $containers) {
    $status = Get-ContainerStatus -containerName $container
    
    $statusColor = if ($status.State -eq "running") { "Green" } else { "Red" }
    $statusText = if ($status.Exists) { $status.State } else { "Not found" }
    
    Write-Host "$($container):" -NoNewline
    Write-Host " $statusText" -ForegroundColor $statusColor -NoNewline
    Write-Host " (Ports: $($status.Ports))"
    
    if ($status.State -ne "running") {
        $allRunning = $false
    }
}

# Check if all required containers are running
if ($allRunning) {
    Write-Host "`nAll required containers are running!" -ForegroundColor Green
    
    # Check TheHive health
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:9000/api/status" -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            $status = $response.Content | ConvertFrom-Json
            Write-Host "`nTheHive Status:"
            Write-Host "==============="
            Write-Host "Version: $($status.versions.TheHive)"
            Write-Host "Status: $($status.status)"
            Write-Host "Database: $($status.database)"
            Write-Host "Indexing: $($status.indexing)"
        }
    } catch {
        Write-Host "`nWarning: Could not connect to TheHive API. The service might still be starting up." -ForegroundColor Yellow
    }
    
    # Show TheHive logs
    Write-Host "`nTheHive Logs (last 20 lines):"
    Write-Host "============================"
    docker logs --tail 20 thehive 2>&1
    
    Write-Host "`nAccess TheHive at: http://localhost:9000"
} else {
    Write-Host "`nSome containers are not running. Here's what you can do:" -ForegroundColor Yellow
    Write-Host "1. Make sure you've run 'start-soc.ps1' first"
    Write-Host "2. Check the logs with 'docker-compose logs'"
    Write-Host "3. Make sure all required ports are available"
    
    # Show how to start the services
    Write-Host "`nTo start all services, run:"
    Write-Host "  .\start-soc.ps1"
    
    # Show how to view logs
    Write-Host "`nTo view logs for a specific service, run:"
    Write-Host "  docker-compose logs -f thehive"
    Write-Host "  docker-compose logs -f cassandra"
    Write-Host "  docker-compose logs -f elasticsearch"
}
