# 🔒 SOC Security Hardening

This directory contains security configurations, tools, and documentation for hardening the SOC environment. It implements defense-in-depth strategies to protect the SOC infrastructure and data.

## 🛡️ Security Components

### 1. Reverse Proxy (Traefik)
- **Purpose**: Secure ingress/egress point for all SOC services
- **Features**:
  - SSL/TLS termination with automatic certificate management (Let's Encrypt)
  - Request routing and load balancing
  - Security headers injection
  - Rate limiting and request throttling
  - Basic authentication for admin interfaces
  - IP whitelisting/blacklisting

### 2. Web Application Firewall (ModSecurity)
- **Purpose**: Protect web applications from common attacks
- **Features**:
  - OWASP Core Rule Set (CRS) v3.3.2
  - Real-time attack detection and prevention
  - Custom rule support for SOC-specific requirements
  - Detailed logging of security events

### 3. Intrusion Prevention (Fail2Ban)
- **Purpose**: Protect against brute force and automated attacks
- **Features**:
  - Real-time monitoring of authentication logs
  - Automatic IP blocking for suspicious activities
  - Custom filter support for different services
  - Email notifications for critical events

### 4. Security Monitoring
- **Purpose**: Continuous monitoring of security events
- **Components**:
  - File integrity monitoring
  - Log analysis for security events
  - Suspicious activity alerts

## ⚙️ Configuration

### Environment Variables
Create a `.env` file with:
```
DOMAIN=yourdomain.com
TRAEFIK_AUTH_CREDENTIALS=admin:$apr1$ruca84Hq$mbjdMxzA7.K/RmCu3UONX0
ADMIN_USER=admin
ADMIN_PASSWORD_HASH=hashed_password_here
```

### Starting Services
```bash
docker-compose -f docker-compose.security.yml up -d
```

## Security Headers

Enabled headers include:
- Content-Security-Policy
- X-Content-Type-Options
- X-Frame-Options
- X-XSS-Protection
- Strict-Transport-Security
- Referrer-Policy
- Permissions-Policy

## Rate Limiting

- Global: 100 req/s with 50 burst
- API: 60 req/min with 30 burst
- Auth: 10 req/min with 5 burst

## WAF Rules

Custom rules can be added to:
- `waf/rules/` - Custom WAF rules
- `waf/modsecurity.conf` - Main configuration

## Monitoring

View logs with:
```bash
docker logs traefik
docker logs modsecurity
docker logs fail2ban
```

## Updating Rules

1. Update CRS rules in `waf/rules/`
2. Restart services:
   ```bash
   docker-compose -f docker-compose.security.yml restart
   ```

## Testing

Verify security headers:
```bash
curl -I https://yourdomain.com
```

Test rate limiting:
```bash
for i in {1..110}; do curl -I https://yourdomain.com; done
```
