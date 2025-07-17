# SSL Setup for SOC Management GUI

This guide explains how to set up SSL/TLS for the SOC Management GUI using Traefik as a reverse proxy with Let's Encrypt for automatic certificate management.

## Prerequisites

1. A domain name (e.g., `soc-gui.yourdomain.com`)
2. Ports 80 and 443 open on your server
3. Docker and Docker Compose installed

## Configuration Steps

### 1. Update docker-compose.yml

Edit the following values in `docker-compose.yml`:

1. Replace `your-email@example.com` with your email address for Let's Encrypt notifications
2. Update the domain names in the Traefik labels:
   - `traefik.http.routers.traefik.rule=Host(\`traefik.yourdomain.com\`)`
   - `traefik.http.routers.soc-gui.rule=Host(\`soc-gui.yourdomain.com\`)`
3. Change the default admin credentials for the Traefik dashboard (optional but recommended)

### 2. Create Required Directories

```bash
mkdir -p traefik/letsencrypt
chmod 600 traefik/letsencrypt
```

### 3. Start the Services

```bash
docker-compose up -d
```

### 4. Verify the Setup

1. Access your SOC Management GUI at: `https://soc-gui.yourdomain.com`
2. Access the Traefik dashboard at: `https://traefik.yourdomain.com` (with the credentials you set)

## Troubleshooting

### Check Container Logs

```bash
docker-compose logs -f
```

### Verify Certificate Generation

```bash
ls -la traefik/letsencrypt/acme.json
```

### Check Traefik Configuration

```bash
docker exec -it soc-gui-traefik traefik debug --log.level=DEBUG
```

## Security Considerations

1. Always use strong passwords for the Traefik dashboard
2. Keep your Docker and Traefik versions up to date
3. Consider setting up a firewall to restrict access to the management interfaces
4. Monitor your Let's Encrypt rate limits (https://letsencrypt.org/docs/rate-limits/)

## Backup and Restore

### Backup Certificates

```bash
cp -r traefik/letsencrypt /path/to/backup/
```

### Restore Certificates

```bash
cp -r /path/to/backup/letsencrypt traefik/
chmod 600 traefik/letsencrypt/acme.json
```

## Renewal

Let's Encrypt certificates are automatically renewed by Traefik. The default renewal period is 30 days before expiration.
