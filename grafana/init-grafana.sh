#!/bin/bash

# Create directories for dashboards
mkdir -p dashboards/{wazuh,suricata,thehive,cortex,misp,system}

# Download Wazuh dashboards
wget -O dashboards/wazuh/wazuh-overview.json https://raw.githubusercontent.com/wazuh/wazuh/v4.4.0/extensions/grafana/7/wazuh-elastic7-overview.json
wget -O dashboards/wazuh/wazuh-threats.json https://raw.githubusercontent.com/wazuh/wazuh/v4.4.0/extensions/grafana/7/wazuh-elastic7-threats.json

# Download Suricata dashboard
wget -O dashboards/suricata/suricata-dashboard.json https://raw.githubusercontent.com/suricata-org/suricata/master/grafana/dashboard.json

# Create a default SOC overview dashboard
cat > dashboards/system/soc-overview.json << 'EOL'
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": "-- Grafana --",
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "target": {
          "limit": 100,
          "matchAny": false,
          "tags": [],
          "type": "dashboard"
        },
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 0,
  "id": 1,
  "links": [],
  "liveNow": false,
  "panels": [
    {
      "datasource": {
        "type": "elasticsearch",
        "uid": "${DS_ELASTICSEARCH}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "short"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 0
      },
      "id": 2,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "auto",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "textMode": "auto"
      },
      "pluginVersion": "9.0.0",
      "targets": [
        {
          "alias": "Alerts",
          "bucketAggs": [
            {
              "field": "@timestamp",
              "id": "2",
              "settings": {
                "interval": "auto",
                "min_doc_count": "0",
                "trimEdges": "0"
              },
              "type": "date_histogram"
            }
          ],
          "metrics": [
            {
              "field": "select field",
              "id": "1",
              "type": "count"
            }
          ],
          "query": "*",
          "refId": "A",
          "timeField": "@timestamp"
        }
      ],
      "title": "Alerts Over Time",
      "type": "stat"
    }
  ],
  "refresh": "5s",
  "schemaVersion": 37,
  "style": "dark",
  "tags": ["soc", "overview"],
  "templating": {
    "list": [
      {
        "current": {
          "selected": false,
          "text": "1h",
          "value": "1h"
        },
        "hide": 0,
        "name": "time_range",
        "options": [
          {
            "selected": true,
            "text": "1h",
            "value": "1h"
          },
          {
            "selected": false,
            "text": "6h",
            "value": "6h"
          },
          {
            "selected": false,
            "text": "12h",
            "value": "12h"
          },
          {
            "selected": false,
            "text": "24h",
            "value": "24h"
          },
          {
            "selected": false,
            "text": "7d",
            "value": "7d"
          },
          {
            "selected": false,
            "text": "30d",
            "value": "30d"
          }
        ],
        "query": "1h,6h,12h,24h,7d,30d",
        "queryValue": "",
        "skipUrlSync": false,
        "type": "interval"
      }
    ]
  },
  "time": {
    "from": "now-6h",
    "to": "now"
  },
  "timepicker": {
    "refresh_intervals": [
      "5s",
      "10s",
      "30s",
      "1m",
      "5m",
      "15m",
      "30m",
      "1h",
      "2h",
      "1d"
    ]
  },
  "timezone": "browser",
  "title": "SOC Overview",
  "version": 1,
  "weekStart": ""
}
EOL

echo "Grafana initialization complete!"
echo "To start Grafana, run: docker-compose up -d"
echo "Access Grafana at: http://localhost:3000"
echo "Default credentials: admin / YourSecureGrafanaPassword123!"
