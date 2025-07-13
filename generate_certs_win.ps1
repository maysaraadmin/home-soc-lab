# Create necessary directories
New-Item -ItemType Directory -Force -Path ".\data\wazuh\indexer\certs" | Out-Null
New-Item -ItemType Directory -Force -Path ".\data\wazuh\dashboard\certs" | Out-Null

# Generate a self-signed root CA certificate
$rootCA = New-SelfSignedCertificate -Type Custom -KeySpec Signature \
    -Subject "CN=Wazuh Root CA, O=Wazuh, C=US, S=California, L=San Francisco" \
    -KeyExportPolicy Exportable -HashAlgorithm sha256 -KeyLength 4096 \
    -CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign

# Export the root CA certificate
Export-Certificate -Cert $rootCA -FilePath ".\data\wazuh\indexer\certs\rootCA.pem" -Type CERT -Force
Export-Certificate -Cert $rootCA -FilePath ".\data\wazuh\dashboard\certs\rootCA.pem" -Type CERT -Force

# Create a certificate for the indexer
$indexerCert = New-SelfSignedCertificate -Type Custom -DnsName @("wazuh.indexer", "localhost") \
    -KeySpec Signature -Subject "CN=wazuh.indexer, O=Wazuh, C=US, S=California, L=San Francisco" \
    -KeyExportPolicy Exportable -HashAlgorithm sha256 -KeyLength 2048 \
    -CertStoreLocation "Cert:\CurrentUser\My" -Signer $rootCA -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.1,1.3.6.1.5.5.7.3.2")

# Export the indexer certificate and private key
$indexerPwd = ConvertTo-SecureString -String "wazuh" -Force -AsPlainText
Export-PfxCertificate -Cert $indexerCert -FilePath ".\data\wazuh\indexer\certs\wazuh.indexer.pfx" -Password $indexerPwd -Force | Out-Null

# Convert PFX to separate cert and key for indexer
& 'C:\Program Files\Git\usr\bin\openssl.exe' pkcs12 -in ".\data\wazuh\indexer\certs\wazuh.indexer.pfx" -out ".\data\wazuh\indexer\certs\wazuh.indexer.pem" -nodes -password pass:wazuh
& 'C:\Program Files\Git\usr\bin\openssl.exe' rsa -in ".\data\wazuh\indexer\certs\wazuh.indexer.pem" -out ".\data\wazuh\indexer\certs\wazuh.indexer.key"

# Create a certificate for the dashboard
$dashboardCert = New-SelfSignedCertificate -Type Custom -DnsName @("wazuh.dashboard", "localhost") \
    -KeySpec Signature -Subject "CN=wazuh.dashboard, O=Wazuh, C=US, S=California, L=San Francisco" \
    -KeyExportPolicy Exportable -HashAlgorithm sha256 -KeyLength 2048 \
    -CertStoreLocation "Cert:\CurrentUser\My" -Signer $rootCA -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.1,1.3.6.1.5.5.7.3.2")

# Export the dashboard certificate and private key
$dashboardPwd = ConvertTo-SecureString -String "wazuh" -Force -AsPlainText
Export-PfxCertificate -Cert $dashboardCert -FilePath ".\data\wazuh\dashboard\certs\wazuh-dashboard.pfx" -Password $dashboardPwd -Force | Out-Null

# Convert PFX to separate cert and key for dashboard
& 'C:\Program Files\Git\usr\bin\openssl.exe' pkcs12 -in ".\data\wazuh\dashboard\certs\wazuh-dashboard.pfx" -out ".\data\wazuh\dashboard\certs\wazuh-dashboard.pem" -nodes -password pass:wazuh
& 'C:\Program Files\Git\usr\bin\openssl.exe' rsa -in ".\data\wazuh\dashboard\certs\wazuh-dashboard.pem" -out ".\data\wazuh\dashboard\certs\wazuh-dashboard.key"

# Create admin certificate
$adminCert = New-SelfSignedCertificate -Type Custom -DnsName @("admin") \
    -KeySpec Signature -Subject "CN=admin, O=Wazuh, C=US, S=California, L=San Francisco" \
    -KeyExportPolicy Exportable -HashAlgorithm sha256 -KeyLength 2048 \
    -CertStoreLocation "Cert:\CurrentUser\My" -Signer $rootCA -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.1,1.3.6.1.5.5.7.3.2")

# Export admin certificate and private key
$adminPwd = ConvertTo-SecureString -String "wazuh" -Force -AsPlainText
Export-PfxCertificate -Cert $adminCert -FilePath ".\data\wazuh\indexer\certs\admin.pfx" -Password $adminPwd -Force | Out-Null

# Convert PFX to separate cert and key for admin
& 'C:\Program Files\Git\usr\bin\openssl.exe' pkcs12 -in ".\data\wazuh\indexer\certs\admin.pfx" -out ".\data\wazuh\indexer\certs\admin.pem" -nodes -password pass:wazuh

# Copy admin cert to dashboard
Copy-Item -Path ".\data\wazuh\indexer\certs\admin.pem" -Destination ".\data\wazuh\dashboard\certs\" -Force

# Clean up temporary files
Remove-Item -Path ".\data\wazuh\indexer\certs\*.pfx" -Force
Remove-Item -Path ".\data\wazuh\dashboard\certs\*.pfx" -Force

Write-Host "Certificates have been generated successfully!" -ForegroundColor Green
