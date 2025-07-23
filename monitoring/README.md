# 📊 SOC Monitoring Stack

This directory contains the monitoring and alerting infrastructure for the SOC environment, providing visibility into system performance, security events, and operational status.

## 🛠 Components

### 1. ELK Stack (Elasticsearch, Logstash, Kibana)
- **Purpose**: Centralized logging and analytics
- **Features**:
  - Log aggregation from all SOC components
  - Real-time log analysis and visualization
  - Custom dashboards for security monitoring
  - Long-term log retention and archiving

### 2. Prometheus & Alertmanager
- **Purpose**: Metrics collection and alerting
- **Features**:
  - Time-series metrics collection
  - Alert routing and deduplication
  - Integration with various notification channels
  - Pre-configured alert rules for SOC components

### 3. Grafana
- **Purpose**: Visualization and dashboards
- **Features**:
  - Pre-built dashboards for SOC metrics
  - Custom visualization options
  - Alerting and annotations

## 📋 Configuration

### Environment Variables
Update the `.env` file in the root directory with the following monitoring-specific variables:

```ini
# Elasticsearch
ELASTICSEARCH_HEAP_SIZE=2g

# Kibana
KIBANA_PORT=5601

# Prometheus
PROMETHEUS_RETENTION=30d

# Alertmanager
ALERTMANAGER_CONFIG=./monitoring/alerting/alertmanager/config.yml
```

## 🚀 Getting Started

1. Start the monitoring stack:
   ```bash
   docker-compose -f docker/compose/docker-compose.yml up -d
   ```

2. Access the monitoring dashboards:
   - Kibana: http://localhost:5601
   - Grafana: http://localhost:3000
   - Prometheus: http://localhost:9090
   - Alertmanager: http://localhost:9093

## 🛠 Maintenance

### Backups
Regularly back up the following:
- Elasticsearch indices
- Grafana dashboards
- Alertmanager configurations

### Monitoring
Monitor the following metrics:
- Disk usage for log storage
- System resource usage (CPU, memory, network)
- Alert volume and patterns

## 🔒 Security Considerations

- Ensure all monitoring endpoints are secured with authentication
- Encrypt all communications with TLS
- Regularly rotate credentials and API keys
- Monitor access to monitoring systems
