#!/bin/bash

# Exit on error
set -e

echo "Waiting for OpenLDAP to be ready..."
sleep 10  # Wait for OpenLDAP to initialize

# Add initial LDAP structure
echo "Adding initial LDAP structure..."
ldapadd -x -H ldap://localhost:389 -D "cn=admin,dc=soc,dc=local" -w "ChangeThisAdminPassword123!" -f /ldap/ldif/01-soc-structure.ldif

echo "LDAP initialization complete!"

echo "You can now access phpLDAPadmin at http://localhost:8080"
echo "Login DN: cn=admin,dc=soc,dc=local"
echo "Password: ChangeThisAdminPassword123!"
