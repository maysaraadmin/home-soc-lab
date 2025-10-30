# Create necessary directories if they don't exist
$kibanaDir = ".\kibana"
$configDir = "$kibanaDir\config"
$dataDir = "$kibanaDir\data"
$pluginsDir = "$kibanaDir\plugins"

# Create directories if they don't exist
@($kibanaDir, $configDir, $dataDir, $pluginsDir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ | Out-Null
    }
}

# Set permissions to allow the container to write to these directories
icacls $kibanaDir /grant "Everyone:(OI)(CI)F" /T

# Make sure the kibana.yml file exists with the right content
$kibanaConfig = @"
# Default Kibana configuration
server.host: "0.0.0.0"
server.shutdownTimeout: "5s"
elasticsearch.hosts: [ "http://elasticsearch:9200" ]
monitoring.ui.container.elasticsearch.enabled: true

# Security
xpack.security.enabled: false
xpack.monitoring.enabled: false

# Logging
logging.verbose: true
logging.dest: /usr/share/kibana/logs/kibana.log

# Allow connections from any origin
server.cors.enabled: true
server.cors.origin: ["*"]

# Set the default app
kibana.defaultAppId: "home"
"@

# Write the config file
$kibanaConfig | Out-File -FilePath "$configDir\kibana.yml" -Encoding utf8 -Force

# Set permissions on the config file
icacls "$configDir\kibana.yml" /grant "Everyone:(F)"

Write-Host "Kibana directories and configuration have been set up successfully."
