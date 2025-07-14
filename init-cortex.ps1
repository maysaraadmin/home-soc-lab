# Wait for Cortex to be ready
Write-Host "Waiting for Cortex to be ready..."
do {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:9001/api/status" -UseBasicParsing -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            $status = $response.Content | ConvertFrom-Json
            if ($status.versions -ne $null) {
                Write-Host "Cortex is ready!"
                break
            }
        }
    } catch {
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 5
    }
} while ($true)

# Create admin user
Write-Host "Creating admin user..."
$body = @{
    login = "admin@thehive.local"
    name = "Cortex Admin"
    roles = ["read", "write", "orgadmin"]
    password = "C0rt3xP@ssw0rd"
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri "http://localhost:9001/api/user" \
        -Method Post \
        -Body $body \
        -ContentType "application/json" \
        -UseBasicParsing
    
    Write-Host "Admin user created successfully!"
    Write-Host "Username: admin@thehive.local"
    Write-Host "Password: C0rt3xP@ssw0rd"
} catch {
    Write-Host "Failed to create admin user. It might already exist."
    Write-Host "Error: $_"
}

# Create API key
Write-Host "Creating API key..."
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin@thehive.local:C0rt3xP@ssw0rd"))
$headers = @{
    Authorization = "Basic $auth"
}

try {
    $response = Invoke-WebRequest -Uri "http://localhost:9001/api/user/admin@thehive.local/key/init" \
        -Method Post \
        -Headers $headers \
        -UseBasicParsing
    
    $apiKey = ($response.Content | ConvertFrom-Json).key
    Write-Host "API Key created successfully!"
    Write-Host "API Key: $apiKey"
    
    # Save API key to file
    $apiKey | Out-File -FilePath "cortex\cortex-api-key.txt" -Force
    Write-Host "API Key saved to cortex\cortex-api-key.txt"
} catch {
    Write-Host "Failed to create API key."
    Write-Host "Error: $_"
}

Write-Host "Cortex initialization complete!"
