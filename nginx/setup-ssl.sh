#!/bin/bash

# Create directories if they don't exist
mkdir -p ./nginx/ssl/thehive
mkdir -p ./nginx/logs
mkdir -p ./nginx/html
mkdir -p ./nginx/acme

# Generate a self-signed certificate (for development only)
# In production, replace this with a proper certificate from Let's Encrypt
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ./nginx/ssl/thehive/privkey.pem \
  -out ./nginx/ssl/thehive/cert.pem \
  -subj "/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"

# Set proper permissions
chmod -R 755 ./nginx/ssl
chmod 644 ./nginx/ssl/thehive/*.pem

echo "SSL certificates have been generated in ./nginx/ssl/thehive/"
echo "For production, please replace these with valid certificates from a trusted CA."
