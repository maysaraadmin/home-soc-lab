# Shuffle SOAR Platform

Shuffle is an open-source Security Orchestration, Automation, and Response (SOAR) platform that helps automate security operations and integrate various security tools.

## Features

- **Workflow Automation**: Create and manage security workflows
- **App Integration**: Connect with 1000+ security tools and services
- **Case Management**: Manage security incidents and investigations
- **Threat Intelligence**: Enrich alerts with threat intelligence
- **Collaboration**: Share and collaborate on security workflows

## Prerequisites

- Docker and Docker Compose
- At least 8GB RAM (16GB recommended)
- At least 20GB free disk space

## Getting Started

### 1. Start Shuffle

```bash
# Navigate to the shuffle directory
cd d:\home-soc-lab\shuffle

# Start Shuffle services
docker-compose -f docker-compose.shuffle.yml up -d
```

### 2. Access Shuffle

- **Web Interface**: http://localhost:3000
- **Default Credentials**:
  - Username: `admin@shuffler.io`
  - Password: `shuffle`

### 3. Initial Setup

1. Log in with the default credentials
2. Change the default password when prompted
3. Configure your organization details
4. Start creating or importing workflows

## Integration with Other Tools

### TheHive Integration

1. In Shuffle, go to "Apps" and search for "TheHive"
2. Click "Configure" and enter your TheHive URL and API key
3. Save the configuration
4. Create workflows that interact with TheHive cases and alerts

### Wazuh Integration

1. In Shuffle, go to "Apps" and search for "Wazuh"
2. Configure the Wazuh API connection details
3. Create workflows to process Wazuh alerts

### Cortex Integration

1. In Shuffle, go to "Apps" and search for "Cortex"
2. Configure the Cortex API connection details
3. Create workflows to run Cortex analyzers and responders

## Creating a Simple Workflow

1. Click on "Workflows" in the sidebar
2. Click "Create Workflow"
3. Give your workflow a name and description
4. Drag and drop apps from the right sidebar
5. Connect the apps to create a workflow
6. Configure each app with the required parameters
7. Save and execute the workflow

## Example Workflow: Process TheHive Alert

1. **Trigger**: New alert in TheHive
2. **Action**: Get alert details
3. **Action**: Enrich IP with threat intelligence
4. **Condition**: If malicious, create case in TheHive
5. **Action**: Send notification to Slack
6. **Action**: Add comment to TheHive case

## Troubleshooting

### Common Issues

1. **Containers not starting**:
   - Check available disk space: `docker system df`
   - Check container logs: `docker logs <container_name>`

2. **Can't access the web interface**:
   - Check if containers are running: `docker ps`
   - Check for port conflicts: `netstat -ano | findstr :3000`

3. **Authentication issues**:
   - Reset the admin password:
     ```
     docker exec -it shuffle-backend python3 /src/backend/reset_password.py admin@shuffler.io newpassword
     ```

### Viewing Logs

```bash
# View all container logs
docker-compose -f docker-compose.shuffle.yml logs -f

# View logs for a specific container
docker logs shuffle-backend
```

## Backup and Restore

### Backup

```bash
# Create a backup of the database
docker exec -t shuffle-db pg_dump -U shuffle -d shuffle > shuffle_backup.sql
```

### Restore

```bash
# Stop Shuffle services
docker-compose -f docker-compose.shuffle.yml down

# Restore the database
docker exec -i shuffle-db psql -U shuffle -d shuffle < shuffle_backup.sql

# Start Shuffle services
docker-compose -f docker-compose.shuffle.yml up -d
```

## Upgrading

1. Stop the current services:
   ```bash
   docker-compose -f docker-compose.shuffle.yml down
   ```

2. Backup your data

3. Pull the latest images:
   ```bash
   docker-compose -f docker-compose.shuffle.yml pull
   ```

4. Start the services:
   ```bash
   docker-compose -f docker-compose.shuffle.yml up -d
   ```

## Security Considerations

- Change the default admin password immediately after first login
- Use strong passwords for all service accounts
- Regularly update to the latest version of Shuffle
- Configure HTTPS for production use
- Set up proper network segmentation
- Regularly backup your data

## Support

- [GitHub Issues](https://github.com/Shuffle/Shuffle/issues)
- [Documentation](https://shuffler.io/docs)
- [Community Forum](https://github.com/Shuffle/Shuffle/discussions)
