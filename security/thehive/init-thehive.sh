#!/bin/bash

# Create necessary directories
mkdir -p ./vol/cassandra
mkdir -p ./vol/elasticsearch
mkdir -p ./vol/thehive
mkdir -p ./vol/cortex

# Set proper permissions
chmod -R 777 ./vol

# Create a network if it doesn't exist
docker network create soc_network 2>/dev/null || true

# Start the services
echo "Starting TheHive with Cortex and dependencies..."
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 30

# Initialize TheHive
echo "Initializing TheHive..."
docker-compose exec thehive /opt/thehive/bin/thehive-db-init

# Create an admin user
echo "Creating admin user..."
ADMIN_PASSWORD=$(openssl rand -base64 32)
docker-compose exec thehive /opt/thehive/bin/thehive-create-admin --password "$ADMIN_PASSWORD"

echo """

=== TheHive Setup Complete ===

Access TheHive at: http://localhost:9000
Username: admin@thehive.local
Password: $ADMIN_PASSWORD

=== Cortex Setup ===

1. Access Cortex at: http://localhost:9001
2. Log in with the default credentials:
   Username: admin@thehive.local
   Password: password
3. Change the default password immediately
4. Add analyzers and responders from the Cortex UI

=== Next Steps ===

1. Configure MISP integration in TheHive settings
2. Set up authentication providers
3. Configure email notifications
4. Import report templates
5. Set up backup procedures

"""

echo "TheHive and Cortex are now running. Don't forget to save the admin password!"
