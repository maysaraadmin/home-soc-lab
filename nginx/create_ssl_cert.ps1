# Create directory if it doesn't exist
$sslDir = "d:\home-soc-lab\nginx\ssl\thehive"
if (-not (Test-Path -Path $sslDir)) {
    New-Item -ItemType Directory -Path $sslDir -Force | Out-Null
}

# Create a self-signed certificate
$cert = New-SelfSignedCertificate -DnsName "localhost" -CertStoreLocation "cert:\LocalMachine\My" -KeyExportPolicy Exportable -KeySpec Signature -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256

# Export the certificate with private key to PFX
$password = ConvertTo-SecureString -String "thehive" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath "$sslDir\cert.pfx" -Password $password

# Export the certificate to PEM format
$certPath = "cert:\LocalMachine\My\" + $cert.Thumbprint
Export-Certificate -Cert $certPath -FilePath "$sslDir\cert.pem" -Type CERT

# Export private key to separate .key file
$privateKeyBytes = $cert.PrivateKey.ExportPkcs8PrivateKey()
[System.IO.File]::WriteAllBytes("$sslDir\privkey.pem", $privateKeyBytes)

# Set proper permissions
$acl = Get-Acl -Path "$sslDir"
$acl.SetAccessRuleProtection($true, $false)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.AddAccessRule($rule)
Set-Acl -Path "$sslDir" -AclObject $acl
