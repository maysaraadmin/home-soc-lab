# SOC Backup Solution

## Features
- Incremental, encrypted backups with Restic
- Automated verification and monitoring
- Configurable retention policies

## Quick Start
1. Update `config/restic-repo.txt` with your storage location
2. Change password in `config/restic-password.txt`
3. Start services: `docker-compose -f docker-compose.backup.yml up -d`

## Usage
- **Manual Backup**: `docker exec restic-backup /scripts/entrypoint.sh`
- **Check Logs**: `docker logs restic-backup`
- **List Snapshots**: `docker exec restic-backup restic snapshots`

## Restore
```bash
docker run --rm -v /backup:/data restic/restic -r /data restore latest --target /restore
```

## Monitoring
- Alerts for failed/stale backups
- Daily integrity checks
- Webhook notifications (configure in `config/alert-webhook.txt`)

## Security
- All backups are encrypted at rest
- Secure password storage
- Network isolation with Docker networks
