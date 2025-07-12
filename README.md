# Home SOC Lab

A comprehensive home security operations center (SOC) lab with Wazuh, TheHive, Cortex, and custom analytics.

## 🚀 Features

- **Wazuh**: Security monitoring and intrusion detection
- **TheHive**: Security incident response platform
- **Cortex**: Powerful observability and analysis
- **FAISS Service**: Vector similarity search for security events
- **Streamlit Dashboard**: Interactive dashboard for SOC analysts

## 🛠 Prerequisites

- Docker 20.10.0+
- Docker Compose 2.0.0+
- 8GB+ RAM (16GB recommended)
- 4 CPU cores (8 recommended)
- 50GB+ free disk space

## 🚀 Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/home-soc-lab.git
   cd home-soc-lab
   ```

2. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit the .env file with your configuration
   nano .env
   ```

3. **Make the start script executable** (Linux/Mac)
   ```bash
   chmod +x start-soc-lab.sh
   ```

4. **Start the services**
   ```bash
   ./start-soc-lab.sh
   ```
   On Windows, you can use Git Bash or WSL to run the script.

## 🔧 Accessing Services

Once started, you can access the following services:

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| Wazuh Dashboard | http://localhost:5601 | `admin:admin` |
| TheHive | http://localhost:9000 | `admin@thehive.local:secret` |
| Cortex | http://localhost:9001 | `admin@thehive.local:secret` |
| Streamlit Dashboard | http://localhost:8501 | - |
| FAISS Service | http://localhost:7860 | - |

## 🧩 Components

### FAISS Service
- Provides vector similarity search capabilities
- Auto-creates a sample index if none exists
- REST API for searching and managing vectors

### Streamlit Dashboard
- Interactive dashboard for SOC analysts
- Real-time alert monitoring
- Integration with TheHive and FAISS service

## 🛡 Security Notes

- Change all default credentials before deploying to production
- Use strong passwords for all services
- Expose services to the internet only with proper authentication and TLS
- Regularly update all containers to the latest versions

## 🔄 Updating

To update the services to their latest versions:

```bash
docker-compose pull
docker-compose up -d --build
```

## 🚨 Troubleshooting

### Common Issues

1. **Port conflicts**
   - Check if any services are already using the required ports (5601, 9000, 9001, 8501, 7860)
   - Update the ports in `docker-compose.yml` if needed

2. **Insufficient resources**
   - Increase Docker's allocated resources (Docker Desktop -> Preferences -> Resources)
   - Stop unnecessary containers and services

3. **Permission issues**
   - Ensure the `./faiss-service/data` directory is writable
   - Run `chmod -R 755 ./faiss-service/data` if needed

### Viewing Logs

View logs for all services:
```bash
docker-compose logs -f
```

View logs for a specific service:
```bash
docker-compose logs -f service_name
```

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Wazuh](https://wazuh.com/)
- [TheHive Project](https://thehive-project.org/)
- [Cortex](https://github.com/TheHive-Project/Cortex)
- [FAISS](https://github.com/facebookresearch/faiss)
- [Streamlit](https://streamlit.io/)

## Features

- **Wazuh**: Security monitoring and intrusion detection
- **TheHive**: Security incident response platform
- **Cortex**: Powerful observability and analysis
- **FAISS Service**: Vector similarity search for security events
- **Streamlit Dashboard**: Interactive dashboard for SOC analysts

## Prerequisites

- Docker and Docker Compose
- Python 3.8+

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/home-soc-lab.git
   cd home-soc-lab
   ```

2. Copy the example environment file and update with your configuration:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. Start the services:
   ```bash
   docker-compose up -d
   ```

4. Access the services:
   - Wazuh Dashboard: http://localhost:5601
   - TheHive: http://localhost:9000
   - Cortex: http://localhost:9001
   - Streamlit Dashboard: http://localhost:8501
   - FAISS Service: http://localhost:7860

## Project Structure

- `faiss-service/`: FAISS vector similarity service
- `streamlit-dashboard/`: Interactive SOC dashboard
- `docker-compose.yml`: Docker Compose configuration
- `.env.example`: Example environment configuration

## Development

### FAISS Service

To develop the FAISS service:

```bash
cd faiss-service
python -m venv venv
source venv/bin/activate  # On Windows: .\venv\Scripts\activate
pip install -r requirements.txt
uvicorn app:app --reload --host 0.0.0.0 --port 7860
```

### Streamlit Dashboard

To develop the Streamlit dashboard:

```bash
cd streamlit-dashboard
python -m venv venv
source venv/bin/activate  # On Windows: .\venv\Scripts\activate
pip install -r requirements.txt
streamlit run app.py
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
