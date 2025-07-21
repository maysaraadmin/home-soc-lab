# Container Security for SOC

This directory contains configurations and tools for container security in the SOC environment, including vulnerability scanning and runtime protection.

## Components

1. **Trivy** - Container vulnerability scanner
2. **Falco** - Runtime security monitoring
3. **Custom Scripts** - Automated scanning and monitoring

## Prerequisites

- Docker Engine 19.03+
- Docker Compose 1.28+
- Linux kernel headers (for Falco)
- Root privileges (for Falco)

## Quick Start

### 1. Start Trivy Server

```bash
docker-compose -f docker-compose.trivy.yml up -d
```

### 2. Start Falco Runtime Security

```bash
docker-compose -f docker-compose.falco.yml up -d
```

### 3. Run a Vulnerability Scan

```bash
# Make the script executable
chmod +x scripts/scan-vulnerabilities.sh

# Scan all running containers
./scripts/scan-vulnerabilities.sh

# Scan a specific container
./scripts/scan-vulnerabilities.sh container <container_id>
```

## Configuration

### Trivy

- Configuration: `trivy/trivy.yaml`
- Cache directory: `/root/.cache/trivy`
- Reports directory: `/reports`

### Falco

- Main configuration: `falco/config/falco.yaml`
- Custom rules: `falco/rules/`
- Logs: `falco/logs/`

## Custom Rules

### Falco Rules

Custom Falco rules are located in `falco/rules/`:

- `soc-container-rules.yaml`: Rules for detecting suspicious container activities

To add new rules:
1. Create a new `.yaml` file in `falco/rules/`
2. Add your custom rules following the Falco rule syntax
3. Restart Falco:
   ```bash
   docker-compose -f docker-compose.falco.yml restart falco
   ```

## Monitoring and Alerts

### Falco Webhook

Falco can send alerts to a webhook. Configure the webhook URL in `docker-compose.falco.yml`:

```yaml
environment:
  - FALCO_WEBHOOK_URL=http://your-webhook-server:8080
```

### Logs

- Trivy logs: `docker logs trivy-server`
- Falco logs: `docker logs falco`
- Scan logs: `/var/log/container-scans/`

## Scheduled Scans

To schedule regular scans, add a cron job:

```bash
# Edit crontab
crontab -e

# Add this line to run daily at 2 AM
0 2 * * * /path/to/container-security/scripts/scan-vulnerabilities.sh
```

## Security Considerations

1. **Secrets Management**
   - Never store sensitive information in plaintext
   - Use Docker secrets or environment variables for sensitive data

2. **Access Control**
   - Restrict access to the container-security directory
   - Use least privilege principle for service accounts

3. **Updates**
   - Regularly update Trivy and Falco to the latest versions
   - Update vulnerability databases before running scans

4. **Monitoring**
   - Monitor Falco alerts in real-time
   - Set up log rotation for scan logs

## Troubleshooting

### Common Issues

1. **Falco Kernel Module**
   If Falco fails to start, ensure kernel headers are installed:
   ```bash
   # For Ubuntu/Debian
   apt-get update && apt-get install -y linux-headers-$(uname -r)
   
   # For RHEL/CentOS
   yum install -y kernel-devel-$(uname -r)
   ```

2. **Trivy Connection Issues**
   If Trivy server is unreachable:
   - Check if the server is running: `docker ps | grep trivy`
   - Check logs: `docker logs trivy-server`
   - Verify network connectivity between containers

3. **Permission Denied**
   If you see permission errors:
   - Ensure Docker socket is accessible: `chmod 666 /var/run/docker.sock`
   - Run containers with appropriate user privileges

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
