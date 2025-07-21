# High Availability Setup for SOC

This directory contains the configuration for setting up high availability (HA) for the SOC infrastructure.

## Components

1. **HAProxy** - Load balancer and reverse proxy
2. **Keepalived** - IP failover and VRRP implementation
3. **Consul** - Service discovery and health checking
4. **Registrator** - Automatic service registration with Consul

## Prerequisites

- Docker Swarm mode enabled
- At least 3 manager nodes for Consul quorum
- Shared storage for Consul data (if persisting)
- Network connectivity between all nodes

## Configuration

### Environment Variables
Create a `.env` file with:

```
# Basic settings
DOMAIN=yourdomain.com
ADMIN_EMAIL=admin@yourdomain.com
VIRTUAL_IP=192.168.1.100

# HAProxy stats
STATS_USER=admin
STATS_PASSWORD=ChangeThisPassword

# Keepalived
KEEPALIVED_PRIORITY=100  # Higher = more likely to be master
KEEPALIVED_PASSWORD=ChangeThisPassword
KEEPALIVED_PEERS=["192.168.1.101","192.168.1.102"]
```

## Deployment

1. Initialize Docker Swarm (if not already done):
   ```bash
   docker swarm init --advertise-addr <node-ip>
   ```

2. Add worker nodes (on each worker):
   ```bash
   docker swarm join --token <token> <manager-ip>:2377
   ```

3. Deploy the stack:
   ```bash
   docker stack deploy -c docker-compose.ha.yml soc-ha
   ```

## Verifying the Setup

1. Check service status:
   ```bash
   docker service ls
   ```

2. View HAProxy stats:
   - URL: http://yourdomain.com:8404/stats
   - User: admin
   - Password: (from STATS_PASSWORD)

3. Check Consul UI:
   - URL: http://yourdomain.com:8500

## Failover Testing

1. On the current master node:
   ```bash
   # Stop the keepalived container
   docker stop keepalived
   ```

2. Verify failover:
   - The virtual IP should move to the backup node
   - Services should remain available

## Maintenance

### Adding a New Service
1. Add the service to your application's docker-compose file
2. Add appropriate labels for Consul service discovery
3. Deploy the updated stack

### Updating Configuration
1. Update the configuration files
2. Reload the affected services:
   ```bash
   docker service update --force <service_name>
   ```

## Monitoring

### HAProxy
- Stats page: http://yourdomain.com:8404/stats
- Logs: `docker logs haproxy`

### Keepalived
- Logs: `docker logs keepalived`
- Check IP: `ip addr show eth0`

### Consul
- UI: http://yourdomain.com:8500
- Health checks: `curl http://localhost:8500/v1/health/state/any`

## Troubleshooting

### Common Issues

1. **IP not failing over**
   - Check VRRP advertisements: `tcpdump -i eth0 vrrp`
   - Verify firewall rules allow VRRP (IP protocol 112)

2. **Services not registering**
   - Check Registrator logs: `docker logs registrator`
   - Verify Consul is healthy: `curl http://consul:8500/v1/status/leader`

3. **HAProxy not starting**
   - Check config: `haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg`
   - View logs: `docker logs haproxy`

## Security Considerations

1. Change all default passwords
2. Restrict access to management interfaces
3. Enable TLS for all communications
4. Regularly update all components
5. Monitor system logs for suspicious activity
