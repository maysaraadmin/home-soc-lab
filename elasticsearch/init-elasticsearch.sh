#!/bin/bash

# Create necessary directories
mkdir -p certs snapshots curator

# Generate certificates if they don't exist
if [ ! -f "certs/elastic-certificates.p12" ]; then
    echo "Generating SSL certificates..."
    chmod +x generate-certs.sh
    ./generate-certs.sh
fi

# Set proper permissions
chmod -R 770 certs snapshots curator
chown -R 1000:1000 certs snapshots curator

# Create a network if it doesn't exist
docker network create soc_network 2>/dev/null || true

# Start Elasticsearch and Kibana
echo "Starting Elasticsearch and Kibana..."
docker-compose up -d

# Wait for Elasticsearch to be ready
echo "Waiting for Elasticsearch to be ready..."
until curl -s http://localhost:9200/_cluster/health | grep -q '"status":"yellow"'; do
    sleep 5
done

# Set up index templates and ILM policies
echo "Configuring index templates and ILM policies..."

# Create ILM policy for SOC indices
curl -X PUT "http://localhost:9200/_ilm/policy/soc-policy" \
  -H 'Content-Type: application/json' \
  -u elastic:YourSecurePassword123! \
  -d '{
    "policy": {
      "phases": {
        "hot": {
          "min_age": "0ms",
          "actions": {
            "rollover": {
              "max_size": "50GB",
              "max_age": "7d"
            },
            "set_priority": {
              "priority": 100
            }
          }
        },
        "warm": {
          "min_age": "7d",
          "actions": {
            "set_priority": {
              "priority": 50
            },
            "forcemerge": {
              "max_num_segments": 1
            },
            "shrink": {
              "number_of_shards": 1
            }
          }
        },
        "delete": {
          "min_age": "30d",
          "actions": {
            "delete": {}
          }
        }
      }
    }
  }'

# Create component template for SOC indices
curl -X PUT "http://localhost:9200/_component_template/soc-settings" \
  -H 'Content-Type: application/json' \
  -u elastic:YourSecurePassword123! \
  -d '{
    "template": {
      "settings": {
        "number_of_shards": 1,
        "number_of_replicas": 0,
        "index.lifecycle.name": "soc-policy",
        "index.refresh_interval": "30s",
        "index.codec": "best_compression"
      },
      "mappings": {
        "_source": {
          "enabled": true
        },
        "dynamic_templates": [
          {
            "strings_as_keyword": {
              "match_mapping_type": "string",
              "mapping": {
                "type": "keyword",
                "ignore_above": 1024
              }
            }
          }
        ]
      }
    }
  }'

# Create index template for SOC components
curl -X PUT "http://localhost:9200/_index_template/soc-indices" \
  -H 'Content-Type: application/json' \
  -u elastic:YourSecurePassword123! \
  -d '{
    "index_patterns": ["wazuh-*", "suricata-*", "thehive-*", "cortex-*", "misp-*", "system-*"],
    "composed_of": ["soc-settings"],
    "priority": 200
  }'

# Create snapshot repository for backups
curl -X PUT "http://localhost:9200/_snapshot/soc_backups" \
  -H 'Content-Type: application/json' \
  -u elastic:YourSecurePassword123! \
  -d '{
    "type": "fs",
    "settings": {
      "location": "/mnt/backups",
      "compress": true
    }
  }'

# Create initial snapshot
curl -X PUT "http://localhost:9200/_snapshot/soc_backups/initial_backup?wait_for_completion=true" \
  -H 'Content-Type: application/json' \
  -u elastic:YourSecurePassword123! \
  -d '{
    "indices": "*,-.*",
    "ignore_unavailable": true,
    "include_global_state": false
  }'

echo """

=== Elasticsearch Setup Complete ===

Access Elasticsearch:
  URL: https://localhost:9200
  Username: elastic
  Password: YourSecurePassword123!

Access Kibana:
  URL: http://localhost:5601
  Username: elastic
  Password: YourSecurePassword123!

=== Next Steps ===

1. Change the default password:
   curl -X POST "http://localhost:9200/_security/user/elastic/_password" \
     -H "Content-Type: application/json" \
     -u elastic:YourSecurePassword123! \
     -d '{"password": "YourNewSecurePassword"}'

2. Set up index patterns in Kibana for:
   - wazuh-*
   - suricata-*
   - thehive-*
   - cortex-*
   - misp-*
   - system-*

3. Configure alerts and dashboards in Kibana
4. Set up automated snapshots for backup
5. Monitor cluster health and performance

=== Troubleshooting ===

View Elasticsearch logs:
  docker-compose logs -f elasticsearch

View Kibana logs:
  docker-compose logs -f kibana

Check cluster health:
  curl -u elastic:YourSecurePassword123! http://localhost:9200/_cluster/health?pretty

"""
