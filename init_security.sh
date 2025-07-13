#!/bin/bash

# Wait for OpenSearch to be ready
until curl -k -s https://localhost:9200 -u admin:admin; do
    echo "Waiting for OpenSearch to be ready..."
    sleep 5
done

# Initialize the security plugin
/usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh \
    -cd /usr/share/wazuh-indexer/opensearch-security/ \
    -icl -nhnv \
    -cacert /usr/share/wazuh-indexer/certs/root-ca.pem \
    -cert /usr/share/wazuh-indexer/certs/admin.pem \
    -key /usr/share/wazuh-indexer/certs/admin-key.pem
