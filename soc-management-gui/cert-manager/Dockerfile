FROM python:3.9-slim

# Install required packages
RUN apt-get update && apt-get install -y \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /app

# Copy certificate management scripts
COPY cert_utils.py .
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Create directory for certificates
RUN mkdir -p /certs

# Expose port for the certificate management API
EXPOSE 5000

# Command to run the certificate management API
CMD ["python", "cert_utils.py"]
