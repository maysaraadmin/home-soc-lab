# Troubleshooting Guide

This guide provides solutions to common issues you might encounter when working with the SOC Lab environment.

## General Issues

### 1. Services Not Starting

**Symptoms**:
- Containers fail to start
- Error messages about port conflicts
- Containers restarting in a loop

**Solutions**:
1. Check for port conflicts:
   ```bash
   netstat -ano | findstr "<port>"
   ```
   Replace `<port>` with the port number you're having issues with.

2. Check container logs:
   ```bash
   docker-compose logs <service_name>
   ```

3. Verify available resources:
   ```bash
   docker system df
   docker system prune -a
   ```

### 2. Connectivity Issues Between Services

**Symptoms**:
- Services can't communicate with each other
- Connection timeouts
- API errors

**Solutions**:
1. Verify all services are on the same Docker network:
   ```bash
   docker network ls
   docker network inspect soc_network
   ```

2. Check service discovery:
   ```bash
   docker exec -it <container_name> ping <service_name>
   ```

## Service-Specific Issues

### TheHive

**Issue**: TheHive fails to connect to Cassandra

**Solution**:
```bash
docker-compose logs cassandra
docker-compose logs thehive
# Ensure CASSANDRA_SEED_HOSTS is correctly set in the environment
```

### Cortex

**Issue**: Analyzers not working

**Solution**:
1. Check analyzer logs:
   ```bash
   docker-compose logs cortex | grep -i analyzer
   ```
2. Verify API keys and permissions
3. Check network connectivity to external services

### Wazuh

**Issue**: Agents not connecting to Wazuh Manager

**Solution**:
1. Check agent registration:
   ```bash
   docker-compose exec wazuh.manager /var/ossec/bin/agent_control -l
   ```
2. Verify network connectivity
3. Check firewall rules

## Monitoring Issues

### Prometheus Not Scraping Targets

1. Check target status:
   ```bash
   curl http://localhost:9090/targets
   ```
2. Verify service discovery
3. Check network policies

### Grafana Dashboards Not Loading

1. Verify data source connections
2. Check dashboard JSON definitions
3. Verify time range settings

## Performance Issues

### High Resource Usage

1. Identify resource hogs:
   ```bash
   docker stats
   ```
2. Adjust resource limits in `docker-compose.yml`
3. Consider scaling services

## Backup and Recovery

### Backup Failed

1. Check available disk space
2. Verify write permissions
3. Check backup script logs

### Restore Failed

1. Verify backup file integrity
2. Check restore script logs
3. Ensure services are stopped during restore

## Common Error Messages

### "Connection Refused"
- Service not running
- Wrong port
- Network issues

### "Permission Denied"
- Volume permissions
- File ownership
- SELinux/AppArmor policies

### "No Route to Host"
- Network configuration
- Firewall rules
- Service discovery issues

## Getting Help

1. Check the service documentation
2. Review logs in `/var/log/` inside containers
3. Check GitHub issues for the respective projects
4. Contact support with relevant logs and details
