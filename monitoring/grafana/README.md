# Grafana for SOC Environment

This directory contains the configuration and setup files for Grafana in the SOC environment.

## Features

- Pre-configured data sources for Elasticsearch, Wazuh, and other SOC tools
- Pre-loaded dashboards for Wazuh, Suricata, TheHive, and more
- Secure configuration with authentication
- Docker Compose for easy deployment

## Directory Structure

```
grafana/
├── dashboards/           # Grafana dashboard JSON files
│   ├── wazuh/           # Wazuh dashboards
│   ├── suricata/        # Suricata dashboards
│   ├── thehive/         # TheHive dashboards
│   ├── cortex/          # Cortex dashboards
│   ├── misp/            # MISP dashboards
│   └── system/          # System and SOC overview dashboards
├── provisioning/        # Grafana provisioning files
│   ├── dashboards/      # Dashboard provisioning
│   └── datasources/     # Data source provisioning
├── data/                # Grafana data directory
├── plugins/             # Grafana plugins
├── docker-compose.yml   # Docker Compose configuration
├── init-grafana.sh      # Initialization script
└── README.md            # This file
```

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Elasticsearch running (for data sources)
- Network access to required services

### Installation

1. **Clone the repository** (if not already done):
   ```bash
   git clone <repository-url>
   cd home-soc-lab/grafana
   ```

2. **Set up the environment**:
   ```bash
   # Make the initialization script executable
   chmod +x init-grafana.sh
   
   # Run the initialization script
   ./init-grafana.sh
   ```

3. **Start Grafana**:
   ```bash
   docker-compose up -d
   ```

4. **Access Grafana**:
   - URL: http://localhost:3000
   - Username: admin
   - Password: YourSecureGrafanaPassword123!

## Configuration

### Data Sources

Pre-configured data sources include:

1. **Elasticsearch** - Main data source for SOC logs and metrics
   - URL: http://elasticsearch-soc:9200
   - Index pattern: `[wazuh-]YYYY.MM.DD`

2. **Wazuh** - Dedicated Wazuh data source
   - URL: http://wazuh.indexer:9200
   - Index pattern: `wazuh-alerts-*`

3. **Prometheus** - For metrics collection
   - URL: http://prometheus:9090

### Dashboards

Pre-loaded dashboards:

- **SOC Overview**: High-level view of security events and alerts
- **Wazuh**: Security monitoring and alerting
- **Suricata**: Network intrusion detection
- **TheHive**: Incident response and case management
- **Cortex**: Security automation and analysis
- **MISP**: Threat intelligence sharing

## Customization

### Adding New Dashboards

1. Export the dashboard JSON from the Grafana UI or create a new JSON file
2. Place it in the appropriate directory under `dashboards/`
3. The dashboard will be automatically loaded on the next Grafana startup

### Adding New Data Sources

1. Edit `provisioning/datasources/datasources.yml`
2. Add a new data source configuration
3. Restart the Grafana container

## Security

- Default authentication is enabled with a strong password
- HTTPS is recommended for production use
- Update default credentials before deploying to production
- Restrict network access to Grafana's web interface

## Troubleshooting

### Common Issues

1. **Dashboards not loading**:
   - Verify that the data sources are correctly configured and accessible
   - Check the Grafana logs: `docker-compose logs grafana`

2. **Authentication issues**:
   - Verify the admin credentials in `docker-compose.yml`
   - Check the Grafana logs for authentication errors

3. **Data not appearing**:
   - Verify that the data sources are correctly configured
   - Check that the time range in the dashboard is correct
   - Verify that the index patterns match your data

### Logs

View Grafana logs:
```bash
docker-compose logs -f grafana
```

## Backup and Restore

### Backup

1. **Backup dashboards**:
   ```bash
   cp -r dashboards/ /path/to/backup/
   ```

2. **Backup configuration**:
   ```bash
   cp -r provisioning/ /path/to/backup/
   cp docker-compose.yml /path/to/backup/
   ```

### Restore

1. **Restore from backup**:
   ```bash
   cp -r /path/to/backup/dashboards/ ./
   cp -r /path/to/backup/provisioning/ ./
   cp /path/to/backup/docker-compose.yml ./
   ```

2. **Restart Grafana**:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
