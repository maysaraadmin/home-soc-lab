# 📊 SOC Centralized Logging & Auditing

This directory contains the configuration and documentation for the SOC's centralized logging and auditing solution, built on the EFK (Elasticsearch, Fluentd, Kibana) stack with additional security and compliance features.

## 🏗 Architecture

### Core Components
- **Fluentd**: High-performance log collector and aggregator with 200+ plugins
- **Elasticsearch**: Scalable log storage and indexing with role-based access control
- **Kibana**: Advanced visualization and analysis with custom dashboards
- **Logrotate**: Automated log rotation and retention management

### Security & Compliance
- **Audit Logging**: Comprehensive tracking of all security-relevant events
- **Log Encryption**: TLS for log transmission and encryption at rest
- **Access Control**: Role-based access to logs and audit trails
- **Retention Policies**: Configurable retention based on log type and compliance requirements

## 🚀 Features

### Log Collection
- **Container Logs**: Automatic collection from all Docker containers
- **System Logs**: Collection from hosts and virtual machines
- **Application Logs**: Structured logging from SOC applications
- **Network Device Logs**: Collection from firewalls, switches, and routers

### Processing & Enrichment
- **Log Parsing**: Automatic parsing of common log formats
- **Field Extraction**: Structured fields from unstructured logs
- **GeoIP**: IP address geolocation
- **Threat Intel**: Enrichment with threat intelligence feeds

### Alerting & Monitoring
- **Anomaly Detection**: Machine learning-based anomaly detection
- **Alert Rules**: Custom alerting based on log patterns
- **Integration**: Alerts to SIEM, email, and incident management systems

## 📋 Prerequisites

- Docker 20.10.0+
- Docker Compose 1.29.0+
- Minimum 8GB RAM (16GB recommended for production)
- Ports:
  - 24224: Fluentd (log forwarding)
  - 9201: Elasticsearch HTTP API
  - 9300: Elasticsearch transport
  - 5602: Kibana web interface

## 🛠 Configuration

### Environment Variables
Create a `.env` file in the logging directory:

```ini
# Elasticsearch
ELASTICSEARCH_HEAP_SIZE=4g
ES_JAVA_OPTS=-Xms4g -Xmx4g

# Fluentd
FLUENTD_CONF=fluentd/conf/fluent.conf
FLUENTD_LOG_LEVEL=info

# Kibana
KIBANA_SERVER_HOST=0.0.0.0
KIBANA_SERVER_PORT=5602

# Log retention (in days)
LOG_RETENTION_DAYS=30
AUDIT_LOG_RETENTION_DAYS=365
```

### Directory Structure

```
logging/
├── docker-compose.yml       # EFK stack definition
├── fluentd/                # Fluentd configuration
│   ├── conf/               # Configuration files
│   ├── patterns/           # Log parsing patterns
│   └── plugins/            # Custom Fluentd plugins
├── elasticsearch/          # Elasticsearch configuration
│   ├── config/
│   └── data/
├── kibana/                 # Kibana configuration
│   ├── config/
│   └── dashboards/        # Pre-built Kibana dashboards
└── scripts/               # Maintenance and setup scripts
```

## 🚀 Getting Started

1. **Start the Logging Stack**
   ```bash
   # Navigate to the logging directory
   cd logging
   
   # Start the EFK stack
   docker-compose up -d
   ```

2. **Verify the Installation**
   - Kibana: http://localhost:5602
   - Elasticsearch: http://localhost:9201
   - Check container status: `docker-compose ps`

3. **Configure Log Sources**
   - Configure your applications to send logs to Fluentd on port 24224
   - Use the provided log forwarder configurations in `fluentd/conf/`

## 🔒 Security Considerations

### Authentication
- Enable X-Pack security for Elasticsearch and Kibana
- Use strong passwords and API keys
- Implement TLS for all communications

### Data Protection
- Encrypt sensitive fields before indexing
- Implement field-level security
- Regular backups of the Elasticsearch indices

### Compliance
- Regular audit of log access
- Document retention policies
- Regular security assessments

## 🔄 Maintenance

### Backup & Restore
```bash
# Backup Elasticsearch indices
./scripts/backup_es.sh

# Restore from backup
./scripts/restore_es.sh <backup_file>
```

### Monitoring
- Monitor disk space for log storage
- Set up alerts for log processing failures
- Regularly review log retention policies

## 📚 Documentation

- [Logging Standards](./docs/logging_standards.md)
- [Alert Configuration](./docs/alerting.md)
- [Troubleshooting Guide](./docs/troubleshooting.md)
- [Performance Tuning](./docs/performance.md)

## 📊 Example Dashboards

1. **Security Dashboard**
   - Authentication failures
   - Brute force attempts
   - Suspicious activities

2. **System Health**
   - Resource usage
   - Service status
   - Log volume trends

3. **Compliance**
   - Audit trails
   - Access patterns
   - Policy violations
   docker-compose -f docker-compose.logging.yml up -d
   ```

2. **Access Kibana**
   - URL: http://localhost:5602
   - Index pattern: `soc-logs-*`
   - Time field: `@timestamp`

## Configuring Log Sources

### Docker Containers
Add the following to your service's `docker-compose.yml`:

```yaml
logging:
  driver: "fluentd"
  options:
    fluentd-address: localhost:24224
    tag: "service_name"
```

### Application Logs
For applications, configure them to output logs in JSON format and send to Fluentd:

- **HTTP**: POST to `http://fluentd:9880/service_name`
- **TCP/UDP**: Send to `fluentd:24224` with tag `service_name`

## Log Rotation

Log rotation is configured for:
- SOC component logs (30 days retention)
- Wazuh logs (7 days retention)
- Suricata logs (7 days retention)
- Docker container logs (7 days retention, 100MB max size)

## Backup and Restore

### Backup Elasticsearch Data
```bash
docker exec logging-elasticsearch bash -c 'curl -X PUT "localhost:9200/_snapshot/soc_logs_backup" -H "Content-Type: application/json" -d"{\"type\":\"fs\",\"settings\":{\"location\":\"/usr/share/elasticsearch/backup\"}}"'
docker exec logging-elasticsearch curl -X PUT "localhost:9200/_snapshot/soc_logs_backup/snapshot_$(date +%Y%m%d_%H%M%S)?wait_for_completion=true"
```

### Restore from Backup
```bash
docker exec logging-elasticsearch curl -X POST "localhost:9200/_snapshot/soc_logs_backup/snapshot_20230721_1200/_restore?wait_for_completion=true"
```

## Monitoring and Maintenance

### Check Log Collection Status
```bash
docker logs -f fluentd
```

### Check Elasticsearch Health
```bash
curl http://localhost:9201/_cluster/health?pretty
```

### Disk Space Management
Elasticsearch has a 30GB disk limit by default. To check disk usage:
```bash
curl -XGET 'http://localhost:9201/_cat/allocation?v'
```

## Security Considerations

- **TLS**: Enable TLS for all communications in production
- **Authentication**: Set up authentication for Elasticsearch and Kibana
- **Access Control**: Restrict access to the logging stack
- **Sensitive Data**: Ensure sensitive information is not logged

## Troubleshooting

### Fluentd Not Collecting Logs
1. Check container logs: `docker logs fluentd`
2. Verify network connectivity between services
3. Check Fluentd configuration: `docker exec -it fluentd bash -c 'fluentd --dry-run -c /fluentd/etc/conf.d/fluent.conf'`

### Elasticsearch Disk Space
To delete old indices:
```bash
# List indices
curl -X GET "localhost:9201/_cat/indices?v"

# Delete old index (replace index_name)
curl -X DELETE "localhost:9201/index_name"
```

## Integration with Other SOC Components

### Wazuh
Configure Wazuh to send logs to Fluentd by updating the Wazuh manager configuration:

```xml
<ossec_config>
  <global>
    <jsonout_output>yes</jsonout_output>
    <logall>yes</logall>
  </global>
  <remote>
    <connection>secure</connection>
    <port>1514</port>
    <protocol>tcp</protocol>
    <allowed-ips>fluentd</allowed-ips>
  </remote>
</ossec_config>
```

### Suricata
Configure Suricata to output logs in JSON format and send to Fluentd:

```yaml
# In suricata.yaml
outputs:
  - eve-log:
      enabled: yes
      filetype: regular
      filename: eve-${HOSTNAME}.json
      types:
        - alert
        - http
        - dns
        - tls
        - files
        - smtp
      xff:
        enabled: yes
        mode: extra-data
        deployment: reverse
        header: X-Forwarded-For
```

### TheHive
Configure TheHive to output logs in JSON format:

```
# In application.conf
logger.application = DEBUG
logger.play = INFO
logger.root = INFO
logger.org.threeten.bp = WARN

appender.fluentd = {
  type = fluentd
  host = "fluentd"
  port = 24224
  tag = "thehive"
  formatter = json
}

rootLogger.appenders = [fluentd]
```
