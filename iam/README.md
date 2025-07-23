# 🔐 Identity and Access Management (IAM)

This directory contains configurations and documentation for managing identities, authentication, and authorization across the SOC environment.

## 🧩 Components

### 1. Authentication Services
- **Purpose**: Secure user authentication
- **Features**:
  - LDAP/Active Directory integration
  - Multi-factor authentication (MFA)
  - Single Sign-On (SSO) support
  - OAuth2/OIDC providers

### 2. Authorization Framework
- **Purpose**: Fine-grained access control
- **Features**:
  - Role-based access control (RBAC)
  - Attribute-based access control (ABAC)
  - Policy definitions and enforcement
  - Audit logging

### 3. Secrets Management
- **Purpose**: Secure storage of sensitive data
- **Features**:
  - Centralized secrets storage
  - Automatic secrets rotation
  - Access auditing
  - Encryption at rest and in transit

## ⚙️ Configuration

### Environment Variables
```ini
# Authentication
AUTH_TYPE=ldap  # or 'oidc', 'saml', 'local'
LDAP_URL=ldap://ldap.example.com:389
LDAP_BASE_DN=dc=example,dc=com

# Authorization
RBAC_ENABLED=true
DEFAULT_ROLE=readonly

# Secrets
VAULT_ADDR=http://vault:8200
VAULT_TOKEN=s.xxxxxxxxxxxxxxxx
```

## 🚀 Getting Started

### 1. Configure Authentication
Edit the authentication configuration:
```bash
cp auth/config.example.yml auth/config.yml
# Edit auth/config.yml with your settings
```

### 2. Set Up Roles and Permissions
Define roles in `configs/roles.yml`:
```yaml
roles:
  soc_analyst:
    permissions:
      - logs:read
      - alerts:read
      - cases:read
      - cases:write

  soc_admin:
    inherits: [soc_analyst]
    permissions:
      - users:manage
      - system:configure
```

### 3. Initialize Secrets Management
```bash
# Initialize Vault
vault operator init

# Unseal Vault
vault operator unseal
```

## 🔒 Security Best Practices

1. **Least Privilege**
   - Assign minimum necessary permissions
   - Regularly review and audit access rights

2. **Secrets Management**
   - Never store secrets in version control
   - Rotate credentials regularly
   - Use short-lived tokens where possible

3. **Monitoring and Auditing**
   - Log all authentication attempts
   - Monitor for suspicious activities
   - Regular access reviews

## 🛠 Maintenance

### User Management
```bash
# Add a new user
./scripts/add-user.sh username@example.com "SOC Analyst"

# Reset password
./scripts/reset-password.sh username@example.com
```

### Audit Logs
View authentication and authorization logs:
```bash
tail -f logs/auth.log
```

## 📚 Documentation

- [Authentication Setup Guide](./docs/authentication.md)
- [Role Management](./docs/roles.md)
- [Secrets Management](./docs/secrets.md)
- [Troubleshooting](./docs/troubleshooting.md)

## 🔄 Integration

### With Monitoring
- Forward authentication events to SIEM
- Set up alerts for failed login attempts

### With Automation
- Use service accounts with limited privileges
- Rotate automation tokens regularly
