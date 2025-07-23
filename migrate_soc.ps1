# SOC Migration Script
# Moves files to the new SOC structure

# 1. Docker files
if (Test-Path "docker-compose.yml") {
    if (-not (Test-Path "docker\compose")) { New-Item -ItemType Directory -Path "docker\compose" -Force }
    Move-Item -Path "docker-compose.yml" -Destination "docker\compose\" -Force
}

if (Test-Path "docker-compose.networks.yml") {
    if (-not (Test-Path "docker\compose")) { New-Item -ItemType Directory -Path "docker\compose" -Force }
    Move-Item -Path "docker-compose.networks.yml" -Destination "docker\compose\" -Force
}

# 2. Configs
if (Test-Path "configs") {
    if (-not (Test-Path "docker\configs")) { New-Item -ItemType Directory -Path "docker\configs" -Force }
    Get-ChildItem -Path "configs" | ForEach-Object {
        $dest = Join-Path "docker\configs" $_.Name
        if (-not (Test-Path $dest)) {
            Move-Item -Path $_.FullName -Destination $dest
        }
    }
}

# 3. Monitoring
if (Test-Path "ELK") {
    if (-not (Test-Path "monitoring\elk")) { New-Item -ItemType Directory -Path "monitoring\elk" -Force }
    Move-Item -Path "ELK\*" -Destination "monitoring\elk\" -Force
}

if (Test-Path "alerting") {
    if (-not (Test-Path "monitoring\alerting")) { New-Item -ItemType Directory -Path "monitoring\alerting" -Force }
    Get-ChildItem -Path "alerting" | ForEach-Object {
        $dest = Join-Path "monitoring\alerting" $_.Name
        if (-not (Test-Path $dest)) {
            Move-Item -Path $_.FullName -Destination $dest
        }
    }
}

# 4. IAM
if (Test-Path "auth") {
    if (-not (Test-Path "iam\auth")) { New-Item -ItemType Directory -Path "iam\auth" -Force }
    Get-ChildItem -Path "auth" | ForEach-Object {
        $dest = Join-Path "iam\auth" $_.Name
        if (-not (Test-Path $dest)) {
            Move-Item -Path $_.FullName -Destination $dest
        }
    }
}

# 5. Security tools
@("thehive", "cortex", "wazuh", "misp") | ForEach-Object {
    if (Test-Path $_) {
        if (-not (Test-Path "security\$_")) { New-Item -ItemType Directory -Path "security\$_" -Force }
        Move-Item -Path "$_\*" -Destination "security\$_\" -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Migration complete!" -ForegroundColor Green
