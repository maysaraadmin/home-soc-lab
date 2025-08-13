# Generate secure random passwords
$elasticPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})
$cassandraPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})
$postgresPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})

# Update .env file with secure values
$envContent = @"
# ========== Database Credentials ==========
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$postgresPassword
POSTGRES_DB=cortex

# ========== Elasticsearch ==========
ELASTIC_PASSWORD=$elasticPassword

# ========== Cassandra ==========
CASSANDRA_PASSWORD=$cassandraPassword

# ========== Let's Encrypt ==========
LETSENCRYPT_EMAIL=admin@example.com

# ========== Application Secrets ==========
JWT_SECRET=$(-join ((65..90) + (97..122) + (48..57) | Get-Random -Count 64 | ForEach-Object {[char]$_}))
SECRET_KEY=$(-join ((65..90) + (97..122) + (48..57) | Get-Random -Count 64 | ForEach-Object {[char]$_}))

# ========== Service Credentials ==========
THEHIVE_ADMIN_PASSWORD=$(-join ((65..90) + (97..122) + (48..57) + (35, 36, 37, 42, 63, 64, 94, 38) | Get-Random -Count 16 | ForEach-Object {[char]$_}))
CORTEX_API_KEY=$(-join ((65..90) + (97..122) + (48..57) | Get-Random -Count 64 | ForEach-Object {[char]$_}))
MISP_API_KEY=$(-join ((65..90) + (97..122) + (48..57) | Get-Random -Count 64 | ForEach-Object {[char]$_}))
"@

# Write to .env file
[System.IO.File]::WriteAllText("$PWD\.env", $envContent)

Write-Host ".env file has been updated with secure random values." -ForegroundColor Green
Write-Host "Make sure to update the LETSENCRYPT_EMAIL and other values as needed." -ForegroundColor Yellow
