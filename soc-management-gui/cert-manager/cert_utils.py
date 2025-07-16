import os
import subprocess
import json
from datetime import datetime, timedelta
from flask import Flask, request, jsonify
from pathlib import Path

app = Flask(__name__)

# Configuration
CERT_DIR = os.getenv('CERT_DIR', '/certs')
DEFAULT_DAYS = 365
DEFAULT_KEY_SIZE = 2048
DEFAULT_DIGEST = 'sha256'

# Ensure certificate directory exists
os.makedirs(CERT_DIR, exist_ok=True)

def generate_private_key(key_path, key_size=DEFAULT_KEY_SIZE):
    """Generate a private key"""
    cmd = [
        'openssl', 'genrsa',
        '-out', key_path,
        str(key_size)
    ]
    try:
        subprocess.run(cmd, check=True, capture_output=True)
        return True, None
    except subprocess.CalledProcessError as e:
        return False, str(e.stderr)

def generate_csr(key_path, csr_path, subject, digest=DEFAULT_DIGEST):
    """Generate a Certificate Signing Request"""
    cmd = [
        'openssl', 'req', '-new',
        '-key', key_path,
        '-out', csr_path,
        '-subj', f'/CN={subject}',
        f'-{digest}'
    ]
    try:
        subprocess.run(cmd, check=True, capture_output=True)
        return True, None
    except subprocess.CalledProcessError as e:
        return False, str(e.stderr)

def generate_self_signed_cert(key_path, cert_path, subject, days=DEFAULT_DAYS, digest=DEFAULT_DIGEST):
    """Generate a self-signed certificate"""
    cmd = [
        'openssl', 'req', '-x509', '-new',
        '-key', key_path,
        '-out', cert_path,
        '-days', str(days),
        '-subj', f'/CN={subject}',
        f'-{digest}'
    ]
    try:
        subprocess.run(cmd, check=True, capture_output=True)
        return True, None
    except subprocess.CalledProcessError as e:
        return False, str(e.stderr)

def sign_csr(csr_path, ca_key, ca_cert, cert_path, days=DEFAULT_DAYS, digest=DEFAULT_DIGEST):
    """Sign a CSR with a CA certificate"""
    cmd = [
        'openssl', 'x509', '-req',
        '-in', csr_path,
        '-CA', ca_cert,
        '-CAkey', ca_key,
        '-CAcreateserial',
        '-out', cert_path,
        '-days', str(days),
        f'-{digest}'
    ]
    try:
        subprocess.run(cmd, check=True, capture_output=True)
        return True, None
    except subprocess.CalledProcessError as e:
        return False, str(e.stderr)

def get_cert_info(cert_path):
    """Get information about a certificate"""
    cmd = ['openssl', 'x509', '-in', cert_path, '-noout', '-text']
    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        return True, result.stdout
    except subprocess.CalledProcessError as e:
        return False, str(e.stderr)

# API Endpoints
@app.route('/api/certificates', methods=['GET'])
def list_certificates():
    """List all certificates in the certificate directory"""
    certs = []
    for f in os.listdir(CERT_DIR):
        if f.endswith(('.crt', '.pem')):
            cert_path = os.path.join(CERT_DIR, f)
            cert_info = {
                'name': f,
                'path': cert_path,
                'size': os.path.getsize(cert_path),
                'modified': os.path.getmtime(cert_path)
            }
            certs.append(cert_info)
    return jsonify(certs)

@app.route('/api/certificates/self-signed', methods=['POST'])
def create_self_signed():
    """Create a self-signed certificate"""
    data = request.json
    common_name = data.get('common_name')
    days = data.get('days', DEFAULT_DAYS)
    key_size = data.get('key_size', DEFAULT_KEY_SIZE)
    
    if not common_name:
        return jsonify({'error': 'common_name is required'}), 400
    
    # Generate filenames
    key_file = os.path.join(CERT_DIR, f'{common_name}.key')
    cert_file = os.path.join(CERT_DIR, f'{common_name}.crt')
    
    # Generate private key
    success, error = generate_private_key(key_file, key_size)
    if not success:
        return jsonify({'error': f'Failed to generate private key: {error}'}), 500
    
    # Generate self-signed certificate
    success, error = generate_self_signed_cert(key_file, cert_file, common_name, days)
    if not success:
        return jsonify({'error': f'Failed to generate certificate: {error}'}), 500
    
    return jsonify({
        'message': 'Self-signed certificate created',
        'key_file': key_file,
        'cert_file': cert_file
    })

@app.route('/api/certificates/csr', methods=['POST'])
def create_csr():
    """Create a Certificate Signing Request"""
    data = request.json
    common_name = data.get('common_name')
    key_size = data.get('key_size', DEFAULT_KEY_SIZE)
    
    if not common_name:
        return jsonify({'error': 'common_name is required'}), 400
    
    # Generate filenames
    key_file = os.path.join(CERT_DIR, f'{common_name}.key')
    csr_file = os.path.join(CERT_DIR, f'{common_name}.csr')
    
    # Generate private key
    success, error = generate_private_key(key_file, key_size)
    if not success:
        return jsonify({'error': f'Failed to generate private key: {error}'}), 500
    
    # Generate CSR
    success, error = generate_csr(key_file, csr_file, common_name)
    if not success:
        return jsonify({'error': f'Failed to generate CSR: {error}'}), 500
    
    return jsonify({
        'message': 'CSR created',
        'key_file': key_file,
        'csr_file': csr_file
    })

@app.route('/api/certificates/sign', methods=['POST'])
def sign_certificate():
    """Sign a certificate using a CA"""
    data = request.json
    csr_path = data.get('csr_path')
    ca_key = data.get('ca_key')
    ca_cert = data.get('ca_cert')
    days = data.get('days', DEFAULT_DAYS)
    
    if not all([csr_path, ca_key, ca_cert]):
        return jsonify({'error': 'csr_path, ca_key, and ca_cert are required'}), 400
    
    # Generate output filename
    cert_file = os.path.join(CERT_DIR, f'signed_{os.path.basename(csr_path)}.crt')
    
    # Sign the certificate
    success, error = sign_csr(csr_path, ca_key, ca_cert, cert_file, days)
    if not success:
        return jsonify({'error': f'Failed to sign certificate: {error}'}), 500
    
    return jsonify({
        'message': 'Certificate signed',
        'cert_file': cert_file
    })

@app.route('/api/certificates/info', methods=['GET'])
def certificate_info():
    """Get information about a certificate"""
    cert_path = request.args.get('path')
    if not cert_path:
        return jsonify({'error': 'path parameter is required'}), 400
    
    if not os.path.exists(cert_path):
        return jsonify({'error': 'Certificate not found'}), 404
    
    success, result = get_cert_info(cert_path)
    if not success:
        return jsonify({'error': f'Failed to get certificate info: {result}'}), 500
    
    return jsonify({
        'path': cert_path,
        'info': result
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
