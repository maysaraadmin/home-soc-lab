#!/bin/bash

# Wait for OpenSearch to start
until curl -s http://localhost:9200; do
  echo "Waiting for OpenSearch to be ready..."
  sleep 5
done

# Initialize the security index
/usr/share/opensearch/plugins/opensearch-security/tools/securityadmin.sh \
  -cd /usr/share/opensearch/plugins/opensearch-security/securityconfig/ \
  -icl -nhnv \
  -cacert /usr/share/opensearch/config/root-ca.pem \
  -cert /usr/share/opensearch/config/kirk.pem \
  -key /usr/share/opensearch/config/kirk-key.pem

echo "Security index initialized!"
