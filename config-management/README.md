# SOC Configuration Management

This directory contains tools and configurations for managing the SOC infrastructure as code.

## Structure

```
config-management/
├── ansible/                    # Ansible playbooks and roles
│   ├── group_vars/            # Group variables
│   │   └── all/               # All hosts variables
│   │       ├── vars.yml       # Non-sensitive variables
│   │       └── vault.yml      # Encrypted sensitive variables
│   └── site.yml               # Main playbook
├── scripts/                   # Utility scripts
└── validation/                # Configuration validation
    └── validate_configs.py    # Config validation script
```

## Prerequisites

- Python 3.6+
- Ansible 2.9+
- Docker (optional, for container validation)
- pip install -r requirements.txt

## Usage

### Configuration Validation

```bash
# Validate all YAML/JSON files in a directory
python validation/validate_configs.py /path/to/configs

# Validate a specific file
python validation/validate_configs.py path/to/file.yml
```

### Ansible Playbooks

1. Edit variables in `ansible/group_vars/all/vars.yml`
2. Encrypt sensitive data:
   ```bash
   ansible-vault encrypt ansible/group_vars/all/vault.yml
   ```
3. Run the playbook:
   ```bash
   ansible-playbook -i inventory.ini ansible/site.yml --ask-vault-pass
   ```

## Best Practices

1. **Version Control**
   - All configurations should be in version control
   - Use `.gitignore` to exclude sensitive files
   - Commit frequently with meaningful messages

2. **Secrets Management**
   - Never commit plaintext secrets
   - Use Ansible Vault for encryption
   - Rotate secrets regularly

3. **Validation**
   - Validate all configs before committing
   - Run validation in CI/CD pipelines
   - Test in staging before production

4. **Documentation**
   - Document all configuration options
   - Keep READMEs up to date
   - Include examples

## Security Considerations

- Restrict access to configuration repositories
- Use principle of least privilege
- Audit configuration changes
- Monitor for unauthorized modifications

## Troubleshooting

### Common Issues

1. **YAML Syntax Errors**
   - Check indentation
   - Ensure consistent use of quotes
   - Validate with `yamllint`

2. **Variable Substitution**
   - Check variable scoping
   - Verify variable precedence
   - Use `ansible-playbook --syntax-check`

3. **Permission Issues**
   - Check file permissions
   - Verify SSH access
   - Check sudo privileges

For additional help, see the [Ansible Documentation](https://docs.ansible.com/).
