# Script to update Docker Compose paths for the new SOC structure

# Path to the docker-compose file
$composeFile = "docker\compose\docker-compose.yml"

# Check if the file exists
if (-not (Test-Path $composeFile)) {
    Write-Host "Docker Compose file not found at $composeFile" -ForegroundColor Red
    exit 1
}

# Read the content of the docker-compose file
$content = Get-Content -Path $composeFile -Raw

# Define path mappings to update
$pathMappings = @{
    # Update volume paths to use the new structure
    "- \./thehive/application.conf:/etc/thehive/application.conf" = "- ..\configs\thehive\application.conf:/etc/thehive/application.conf"
    "- \./cortex/application.conf:/etc/cortex/application.conf" = "- ..\configs\cortex\application.conf:/etc/cortex/application.conf"
    "- \./postgres-init:/docker-entrypoint-initdb.d/" = "- ..\configs\postgres-init:/docker-entrypoint-initdb.d/"
    
    # Update any other paths as needed
}

# Apply the path mappings
foreach ($mapping in $pathMappings.GetEnumerator()) {
    $content = $content -replace [regex]::Escape($mapping.Key), $mapping.Value
}

# Save the updated content back to the file
$content | Set-Content -Path $composeFile -Force

Write-Host "Docker Compose file has been updated with new paths." -ForegroundColor Green
