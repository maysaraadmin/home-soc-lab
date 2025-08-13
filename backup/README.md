# 🔄 SOC Backup & Recovery

This directory contains the configuration and documentation for the SOC's backup and recovery solution, ensuring data protection and disaster recovery capabilities.

## 🛡️ Features

- **Incremental Backups**: Efficient storage usage with block-level deduplication
- **End-to-End Encryption**: AES-256 encryption for data at rest and in transit
- **Multi-Target Support**: Local, cloud, and offsite backup destinations
- **Point-in-Time Recovery**: Restore to any specific point in time
- **Automated Verification**: Regular integrity checks of backup data
- **Monitoring & Alerting**: Integration with monitoring systems
- **Retention Policies**: Configurable retention based on compliance requirements

## 🏗 Architecture

### Core Components
- **Restic**: Fast, secure, and efficient backup program
- **MinIO**: S3-compatible object storage for backup storage
- **Prometheus**: Backup job monitoring and metrics collection
- **Alertmanager**: Alerting for backup failures and issues

### Data Protection
- **Encryption**: All backups are encrypted before leaving the source
- **Immutable Backups**: Protection against ransomware and tampering
- **Air-Gapped Storage**: Optional support for offline/air-gapped backups
- **Geographic Distribution**: Multi-region backup storage

## 🚀 Quick Start

### Prerequisites
- Docker 20.10.0+
- Docker Compose 1.29.0+
- Sufficient storage for backups

### Initial Setup

1. **Configure Backup Storage**
   - Update `backup_config.json` with your storage configuration
   - Set up required environment variables in `.env`

2. **Initialize the Backup Repository**
   ```bash
   # Start the backup services
   docker-compose -f docker-compose.backup.yml up -d
   
   # Initialize the repository (first time only)
   docker exec restic-backup restic init
   ```

3. **Verify the Setup**
   ```bash
   # Check service status
   docker-compose -f docker-compose.backup.yml ps
   
   # View backup logs
   docker logs restic-backup
   ```

## 🔧 Configuration

### Backup Configuration (`backup_config.json`)

The main configuration file defines what to back up and how:

```json
{
  "version": "1.0",
  "backup_root": "/backups/soc",
  "retention_days": 30,
  "databases": {
    "elasticsearch": {
      "enabled": true,
      "type": "elasticsearch",
      "host": "elasticsearch",
      "port": 9200,
      "username": "elastic",
      "password_env": "ELASTIC_PASSWORD"
    }
  },
  "files": {
    "configs": {
      "enabled": true,
      "paths": ["/etc/soc", "/etc/elasticsearch"]
    }
  }
}
```

### Environment Variables (`.env`)

```ini
# Restic Configuration
RESTIC_PASSWORD=your_secure_password
RESTIC_REPOSITORY=s3:http://minio:9000/backups
AWS_ACCESS_KEY_ID=minioadmin
AWS_SECRET_ACCESS_KEY=minioadmin

# Notification Settings
ALERT_EMAIL=admin@example.com
SLACK_WEBHOOK_URL=

# Retention Policy
KEEP_LAST=7
KEEP_DAILY=7
KEEP_WEEKLY=4
KEEP_MONTHLY=12
KEEP_YEARLY=2
```

## 🛠 Usage

### Manual Operations

```bash
# Run a manual backup
./scripts/run_backup.sh

# List available backups
./scripts/list_backups.sh

# Restore from backup
./scripts/restore_backup.sh <backup_id>

# Check repository integrity
./scripts/check_integrity.sh

# Prune old backups
./scripts/prune_backups.sh
```

### Scheduled Backups

Backups are scheduled using cron jobs. The default schedule is:

```
# Daily incremental backups at 2 AM
0 2 * * * /app/scripts/run_backup.sh

# Weekly integrity check on Sundays at 3 AM
0 3 * * 0 /app/scripts/check_integrity.sh

# Monthly cleanup on the 1st at 4 AM
0 4 1 * * /app/scripts/prune_backups.sh
```

## 🔄 Restore Procedures

### Full System Restore

1. **Prepare the Recovery Environment**
   ```bash
   # Start a recovery container with access to backup storage
   docker run -it --rm \
     -v /recovery:/recovery \
     -e RESTIC_PASSWORD \
     -e AWS_ACCESS_KEY_ID \
     -e AWS_SECRET_ACCESS_KEY \
     restic/restic \
     -r s3:http://minio:9000/backups \
     restore latest --target /recovery
   ```

2. **Verify Restored Data**
   ```bash
   # Check the restored files
   ls -la /recovery
   
   # Verify database integrity
   ./scripts/verify_restore.sh
   ```

### File-Level Recovery

```bash
# List available snapshots
docker exec restic-backup restic snapshots

# Restore specific files
docker exec restic-backup restic restore <snapshot_id> --include /path/to/file --target /restore
```

## 🔒 Security Considerations

### Encryption
- All backups are encrypted using AES-256
- Encryption keys are never stored with the backup data
- Each backup has a unique encryption key

### Access Control
- Backup storage requires authentication
- Principle of least privilege for backup service accounts
- Regular rotation of access credentials

### Monitoring
- Backup success/failure notifications
- Storage capacity monitoring
- Regular test restores to verify backup integrity

## 📊 Monitoring & Alerting

### Metrics
Backup status and performance metrics are available at:
```
http://localhost:9090/targets  # Prometheus
http://localhost:3000          # Grafana (if enabled)
```

### Alerts
Configured alerts include:
- Backup failures
- Long-running backup jobs
- Storage capacity thresholds
- Integrity check failures
- Failed restores

## 🧹 Maintenance

### Pruning Old Backups
```bash
# Remove old backups according to retention policy
./scripts/prune_backups.sh

# Check repository size
restic stats
```

### Checking Repository Health
```bash
# Check repository integrity
./scripts/check_integrity.sh

# Check for errors in the repository
restic check --read-data
```

## 📚 Documentation

- [Backup Configuration Reference](./docs/configuration.md)
- [Disaster Recovery Plan](./docs/disaster_recovery.md)
- [Performance Tuning](./docs/performance.md)
- [Troubleshooting Guide](./docs/troubleshooting.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request
```

## Monitoring
- Alerts for failed/stale backups
- Daily integrity checks
- Webhook notifications (configure in `config/alert-webhook.txt`)

## Security
- All backups are encrypted at rest
- Secure password storage
- Network isolation with Docker networks
