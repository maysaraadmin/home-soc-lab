# SOC Lab Environment

A comprehensive Security Operations Center (SOC) environment with TheHive, Cortex, MISP, Wazuh, and Shuffle, all containerized with Docker.

## Project Structure

```
.
├── configs/               # Configuration files for all services
│   ├── thehive/           # TheHive configuration
│   ├── cortex/            # Cortex configuration
│   └── wazuh/             # Wazuh configuration
│       ├── wazuh_indexer/ # Wazuh Indexer configs
│       └── wazuh_dashboard/ # Wazuh Dashboard configs
│
├── data/                  # Persistent data for all services
│   ├── cassandra/         # TheHive database
│   ├── elasticsearch/     # Main Elasticsearch data
│   ├── postgres/          # Cortex database
│   ├── mysql/             # MISP database
│   ├── redis/             # Redis data
│   └── wazuh/             # Wazuh data
│
├── scripts/               # Utility scripts
│   ├── backup/            # Backup scripts
│   ├── setup/             # Setup scripts
│   └── maintenance/       # Maintenance scripts
│
└── docs/                  # Documentation
    └── api/               # API documentation
```

## Prerequisites

- Docker 20.10.0+
- Docker Compose 1.29.0+
- Minimum 16GB RAM (32GB recommended)
- 100GB free disk space recommended

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/maysaraadmin/home-soc-lab.git
   cd home-soc-lab
   ```

2. Copy the example environment file and update with your configuration:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. Start the services:
   ```bash
   docker-compose up -d
   ```

4. Access the services:
   - TheHive: http://localhost:9000
   - Cortex: http://localhost:9001
   - MISP: http://localhost:8080
   - Wazuh Dashboard: https://localhost:5601
   - Shuffle: http://localhost:3001

## Services Overview

### TheHive
- **Port**: 9000
- **Purpose**: Incident response platform
- **Default Credentials**: admin@thehive.local / secret

### Cortex
- **Port**: 9001
- **Purpose**: Analysis engine
- **Default Credentials**: admin / cortex-password

### MISP
- **Port**: 8080
- **Purpose**: Threat intelligence platform
- **Default Credentials**: admin@admin.test / admin

### Wazuh
- **Dashboard**: https://localhost:5601
- **Manager Ports**: 1514, 1515, 514/udp, 55000
- **Purpose**: SIEM and XDR solution
- **Default Credentials**: admin / SecretPassword

### Shuffle
- **Port**: 3001 (HTTP), 3443 (HTTPS)
- **Purpose**: Security Orchestration, Automation and Response (SOAR)
- **Default Credentials**: admin / password

## Backup and Restore

Backup scripts are available in `scripts/backup/`:

```bash
# Create a backup
./scripts/backup/backup.sh

# Restore from backup
./scripts/backup/restore.sh <backup-file>
```

## Maintenance

- **Logs**: Check container logs with `docker-compose logs -f <service>`
- **Updates**: Update services by pulling new images and recreating containers
- **Monitoring**: Monitor resource usage with `docker stats`

## Security Considerations

1. Change all default passwords
2. Enable HTTPS for all services
3. Restrict access to management interfaces
4. Regularly update all components
5. Monitor logs for suspicious activities

## Troubleshooting

Common issues and solutions are documented in [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
