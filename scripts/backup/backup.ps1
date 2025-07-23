# Backup script for SOC Lab Environment
# This script creates a backup of all persistent data

param (
    [string]$backupDir = "$PSScriptRoot\\..\\..\\backups"
)

# Create backup directory with timestamp
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupPath = Join-Path -Path $backupDir -ChildPath $timestamp

Write-Host "Creating backup in: $backupPath"

# Create backup directory structure
$directories = @(
    "data/cassandra",
    "data/elasticsearch",
    "data/postgres",
    "data/mysql",
    "data/redis",
    "data/wazuh",
    "configs"
)

# Create backup directories
foreach ($dir in $directories) {
    $targetDir = Join-Path -Path $backupPath -ChildPath (Split-Path -Path $dir -Parent)
    if (-not (Test-Path -Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
}

# Stop all containers
Write-Host "Stopping containers..."
docker-compose stop

# Create backup of each directory
foreach ($dir in $directories) {
    $source = Join-Path -Path $PSScriptRoot -ChildPath "..\\..\\$dir"
    $destination = Join-Path -Path $backupPath -ChildPath $dir
    
    if (Test-Path -Path $source) {
        Write-Host "Backing up $dir..."
        Copy-Item -Path "$source\\*" -Destination $destination -Recurse -Force
    }
}

# Start all containers
Write-Host "Starting containers..."
docker-compose start

# Create a compressed archive
$archivePath = "$backupPath.zip"
Write-Host "Creating archive: $archivePath"
Compress-Archive -Path "$backupPath\\*" -DestinationPath $archivePath -Force

# Clean up temporary files
Remove-Item -Path $backupPath -Recurse -Force

Write-Host "Backup completed successfully: $archivePath"
