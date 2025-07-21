# SOC Component Integration Guide

## Architecture Overview

```
+----------------+     +----------------+     +----------------+
|   Wazuh Agent |---->|  Wazuh Manager |---->| Wazuh Indexer  |
+----------------+     +--------+-------+     +--------+-------+
                               |                      |
                               v                      v
+----------------+     +--------+-------+    +--------+-------+
|  Suricata NIDS |---->|   Filebeat     |--->|  Elasticsearch  |
+--------+-------+     +--------+-------+    +--------+-------+
         |                      |                     |
         |                      |                     |
         v                      v                     v
+----------------+     +--------+-------+    +--------+-------+
|   TheHive      |<--->|    Cortex      |<---|   Grafana      |
+--------+-------+     +----------------+    +--------+-------+
         |                                          |
         |                                          |
         v                                          v
+----------------+                         +------------------+
|   MISP         |<------------------------|  Alerting System |
+----------------+                         +------------------+
```

## Component Integration Matrix

| Component      | Integrates With | Protocol | Port(s) | Authentication |
|----------------|-----------------|----------|---------|----------------|
| Wazuh Agent   | Wazuh Manager   | TCP      | 1514    | Pre-shared Key |
| Wazuh Manager | Wazuh Indexer   | HTTP     | 9200    | Basic Auth     |
| Filebeat      | Elasticsearch   | HTTP     | 9200    | Basic Auth     |
| Suricata      | Filebeat        | Syslog   | 514     | N/A            |
| TheHive       | Cortex          | HTTP     | 9001    | API Key        |
| Grafana       | Elasticsearch   | HTTP     | 9200    | Basic Auth     |

## Data Flow

1. **Collection**:
   - Wazuh Agents → Wazuh Manager
   - Suricata → Filebeat → Elasticsearch
   - System logs → Filebeat → Elasticsearch

2. **Processing**:
   - Wazuh Manager processes agent data → Wazuh Indexer
   - Filebeat processes logs → Elasticsearch

3. **Storage**:
   - Elasticsearch stores all security events and logs
   - Daily indices (e.g., `wazuh-alerts-*`, `suricata-*`)

4. **Visualization**:
   - Grafana connects to Elasticsearch for dashboards
   - Custom dashboards for security monitoring

5. **Response**:
   - TheHive creates cases from alerts
   - Cortex performs automated analysis
   - MISP enriches with threat intel

## Key Ports

- **1514**: Wazuh Agent communication
- **514**: Syslog collection
- **9001**: TheHive web interface
- **9002**: Cortex web interface
- **3000**: Grafana web interface
- **9200**: Elasticsearch API
- **55000**: Wazuh API

## Authentication

- **Wazuh**: Pre-shared keys for agents, Basic Auth for API
- **Elasticsearch**: X-Pack security with RBAC
- **TheHive/Cortex**: API key authentication
- **Grafana**: Local users or LDAP/AD

## Troubleshooting

1. **Wazuh Agent Issues**:
   - Check network connectivity
   - Verify authentication key
   - Check Wazuh Manager service

2. **Elasticsearch Connection**:
   - Verify service is running
   - Check credentials
   - Review logs

3. **Grafana Dashboards**:
   - Verify data source configs
   - Check index patterns
   - Review user permissions

## Security Best Practices

1. Enable TLS for all communications
2. Implement network segmentation
3. Regular security updates
4. Principle of least privilege
5. Centralized logging and monitoring

## Maintenance

1. **Backups**:
   - Regular Elasticsearch snapshots
   - TheHive database dumps
   - Configuration backups

2. **Updates**:
   - Regular security patches
   - Test in staging first
   - Document changes

3. **Monitoring**:
   - System resources
   - Service health
   - Performance metrics
