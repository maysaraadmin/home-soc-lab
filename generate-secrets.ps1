# Generate secure random values for all secrets
$secretsPath = "docker/secrets"

# Create the secrets directory if it doesn't exist
if (-not (Test-Path -Path $secretsPath)) {
    New-Item -ItemType Directory -Path $secretsPath -Force | Out-Null
}

# Function to generate a secure random string
function New-SecureRandomString {
    param (
        [int]$Length = 32
    )
    $bytes = New-Object byte[] (($Length * 3) / 4)
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($bytes)
    [Convert]::ToBase64String($bytes).Substring(0, $Length)
}

# Generate secrets
@(
    "elastic_password",
    "elastic_username",
    "postgres_password",
    "postgres_user",
    "cassandra_password",
    "cassandra_user",
    "cortex_secret",
    "thehive_secret",
    "jwt_secret",
    "session_secret"
) | ForEach-Object {
    $secretFile = Join-Path $secretsPath $_
    $secretValue = if ($_ -match "username") {
        if ($_ -match "elastic") { "elastic" } 
        elseif ($_ -match "postgres") { "postgres" }
        else { "cassandra" }
    } else {
        New-SecureRandomString -Length 32
    }
    
    $secretValue | Out-File -FilePath $secretFile -Encoding utf8 -NoNewline
    Write-Host "Generated secret: $secretFile"
    
    # Set file permissions (Windows)
    $acl = Get-Acl $secretFile
    $acl.SetAccessRuleProtection($true, $false)
    $acl | Set-Acl $secretFile
}

Write-Host "All secrets have been generated in the $secretsPath directory"
