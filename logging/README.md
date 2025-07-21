# SOC Centralized Logging Solution

This directory contains the configuration for the SOC's centralized logging solution using Fluentd, Elasticsearch, and Kibana (EFK stack).

## Architecture

- **Fluentd**: Log collector and aggregator
- **Elasticsearch**: Log storage and indexing
- **Kibana**: Log visualization and analysis
- **Logrotate**: Log rotation and management

## Prerequisites

- Docker and Docker Compose
- Ports 24224 (Fluentd), 9201 (Elasticsearch), and 5602 (Kibana) available

## Getting Started

1. **Start the Logging Stack**
   ```bash
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
