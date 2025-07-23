# SOC Lab Project Structure

This document outlines the structure and organization of the SOC Lab project, which integrates multiple security tools into a cohesive Security Operations Center environment.

## Overview

The project follows a modular structure to ensure maintainability, scalability, and ease of deployment. The main components are organized into logical directories, each serving a specific purpose in the SOC infrastructure.

## Directory Structure

```
.
├── .github/                  # GitHub workflows and templates
│   └── workflows/            # CI/CD and automation workflows
│       ├── ci-cd.yml         # Main CI/CD pipeline
│       └── security-scan.yml # Security scanning workflows
│
├── configs/                  # Configuration files
│   ├── thehive/             # TheHive configuration
│   ├── cortex/              # Cortex configuration
│   └── wazuh/               # Wazuh configuration
│
├── data/                     # Persistent data volumes
│   ├── thehive-data/        # TheHive data
│   ├── cortex-data/         # Cortex data
│   └── wazuh-data/          # Wazuh data
│
├── monitoring/               # Monitoring stack configuration
│   ├── grafana/             # Grafana dashboards and configs
│   ├── prometheus/          # Prometheus configuration
│   ├── loki/                # Loki log aggregation
│   └── promtail/            # Log collection
│
├── scripts/                  # Utility scripts
│   ├── backup/              # Backup and restore scripts
│   ├── deploy/              # Deployment scripts
│   └── maintenance/         # Maintenance utilities
│
└── docs/                    # Documentation
    ├── architecture/        # System architecture
    ├── setup/              # Setup guides
    └── api/                # API documentation
```

## Key Components

### 1. Monitoring Stack

The monitoring stack provides visibility into the SOC environment:

- **Prometheus**: Collects and stores metrics
- **Grafana**: Visualizes metrics and logs
- **Loki**: Aggregates logs from all services
- **Promtail**: Collects and forwards logs to Loki

### 2. Core Security Tools

- **TheHive**: Incident response platform
- **Cortex**: Analysis engine for observables
- **MISP**: Threat intelligence sharing platform
- **Wazuh**: Security information and event management
- **Shuffle**: Security orchestration and automation

### 3. Automation

- **CI/CD Pipeline**: Automated testing and deployment
- **Security Scans**: Regular vulnerability assessments
- **Backup/Restore**: Data protection utilities

## Setup Instructions

### Prerequisites

- Docker 20.10.0+
- Docker Compose 1.29.0+
- 16GB+ RAM (32GB recommended)
- 100GB+ free disk space

### Quick Start

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd soc-lab
   ```

2. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```
   Edit the `.env` file with your configuration.

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
   - Grafana: http://localhost:3000

## Maintenance

### Backups

Run the backup script to create a backup of all persistent data:

```bash
./scripts/backup/backup.ps1
```

### Updates

To update the services:

1. Pull the latest changes:
   ```bash
   git pull
   ```

2. Rebuild and restart the services:
   ```bash
   docker-compose pull
   docker-compose up -d --build
   ```

### Monitoring

Access the monitoring dashboard at http://localhost:3000 (Grafana). Default credentials:
- Username: admin
- Password: admin (change on first login)

## Security Considerations

1. Change all default credentials
2. Enable HTTPS for all services
3. Regularly update all components
4. Monitor logs for suspicious activities
5. Restrict access to management interfaces

## Troubleshooting

Common issues and solutions are documented in [TROUBLESHOOTING.md](troubleshooting.md).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
