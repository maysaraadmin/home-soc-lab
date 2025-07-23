# SOC Centralized Authentication Service

This directory contains the configuration for the SOC's centralized authentication service using OpenLDAP and phpLDAPadmin.

## Prerequisites

- Docker and Docker Compose
- Ports 389 (LDAP) and 8080 (phpLDAPadmin) available

## Getting Started

1. **Update Passwords**
   - Edit `docker-compose.ldap.yml` and change all default passwords
   - Change `LDAP_ADMIN_PASSWORD`, `LDAP_CONFIG_PASSWORD`, and `LDAP_READONLY_USER_PASSWORD`

2. **Start the Services**
   ```bash
   docker-compose -f docker-compose.ldap.yml up -d
   ```

3. **Initialize LDAP Structure**
   ```bash
   docker exec -it openldap /bin/bash /ldap/init-ldap.sh
   ```

## Accessing phpLDAPadmin

- URL: http://localhost:8080
- Login DN: `cn=admin,dc=soc,dc=local`
- Password: (The one you set as LDAP_ADMIN_PASSWORD)

## Managing Users and Groups

### Adding a New User

1. Log in to phpLDAPadmin
2. Navigate to `dc=soc,dc=local` > `ou=users`
3. Click "Create a child entry"
4. Select "Generic: User Account"
5. Fill in the user details
6. Set a password for the user
7. Add the user to appropriate groups (e.g., `soc_admins`, `soc_analysts`, `soc_viewers`)

### Adding a User to a Group

1. Navigate to the group (e.g., `cn=soc_admins,ou=groups,dc=soc,dc=local`)
2. Go to the "Members" tab
3. Add the user's DN (e.g., `uid=johndoe,ou=users,dc=soc,dc=local`)

## Security Notes

- **Important**: Change all default passwords before deploying to production
- Enable TLS in production by setting `LDAP_TLS=true` and providing proper certificates
- Restrict access to phpLDAPadmin to trusted IPs only
- Regularly back up the LDAP database

## Backing Up LDAP Data

```bash
docker exec openldap slapcat -l backup.ldif
```

## Restoring from Backup

```bash
docker cp backup.ldif openldap:/tmp/backup.ldif
docker exec openldap ldapadd -x -D "cn=admin,dc=soc,dc=local" -w "your_admin_password" -f /tmp/backup.ldif
```

## Integrating with SOC Components

### Grafana

1. In Grafana, go to Configuration > Authentication > LDAP
2. Enable LDAP authentication
3. Configure the LDAP settings to point to your OpenLDAP server
4. Set up group mappings for different access levels

### Wazuh

1. Configure Wazuh API to use LDAP authentication
2. Update the Wazuh manager configuration to allow LDAP authentication

### TheHive

1. Configure TheHive to use LDAP authentication
2. Map LDAP groups to TheHive roles
