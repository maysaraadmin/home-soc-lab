#!/bin/bash

# Exit on error
set -e

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose is not installed. Please install Docker Compose v2 or later."
    exit 1
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    echo "Please edit the .env file with your configuration and run this script again."
    exit 1
fi

# Check if the user has updated the default credentials
grep -q 'change-me' .env
if [ $? -eq 0 ]; then
    echo "WARNING: You are using default credentials in the .env file."
    echo "Please update them with secure values before deploying to production."
    read -p "Do you want to continue with default credentials? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Please update the .env file and run this script again."
        exit 1
    fi
fi

# Create required directories
echo "Creating required directories..."
mkdir -p ./faiss-service/data

# Set proper permissions
echo "Setting up permissions..."
chmod -R 755 ./faiss-service/data

# Build and start the services
echo "Starting SOC Lab services..."
docker-compose up -d --build

echo ""
echo "========================================"
echo "SOC Lab is starting up!"
echo ""
echo "Services will be available at:"
echo "- Wazuh Dashboard: http://localhost:5601"
echo "- TheHive: http://localhost:9000"
echo "- Cortex: http://localhost:9001"
echo "- Streamlit Dashboard: http://localhost:8501"
echo "- FAISS Service: http://localhost:7860"
echo ""
echo "To view logs, run: docker-compose logs -f"
echo "To stop the services, run: docker-compose down"
echo "========================================"
echo ""

# Show initial logs
echo "Showing initial logs (press Ctrl+C to exit)..."
docker-compose logs -f --tail=50
