# SOC Management GUI

A comprehensive web-based interface for managing and monitoring your Security Operations Center (SOC) tools including Wazuh, TheHive, Cortex, Shuffle, FAISS, and Streamlit.

## Features

- **Dashboard**: Overview of all services with status indicators
- **Service Management**: Start, stop, and monitor services
- **Configuration**: View and edit service configurations
- **Logs**: View service logs (placeholder for future implementation)
- **System Metrics**: Monitor system resources (placeholder for future implementation)

## Prerequisites

- Python 3.8+
- pip (Python package manager)

## Installation

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd soc-management-gui
   ```

2. Create a virtual environment (recommended):
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: .\\venv\\Scripts\\activate
   ```

3. Install the required packages:
   ```bash
   pip install -r requirements.txt
   ```

## Configuration

1. Copy the example environment file and update it with your configuration:
   ```bash
   cp .env.example .env
   ```

2. Edit the `.env` file with your service URLs, API keys, and other settings.

## Usage

1. Start the Streamlit server:
   ```bash
   streamlit run app.py
   ```

2. Open your web browser and navigate to:
   ```
   http://localhost:8501
   ```

## Service Integration

### Wazuh
- Configure Wazuh API URL and credentials in the `.env` file
- Ensure the Wazuh manager is running and accessible

### TheHive
- Configure TheHive URL and API key in the `.env` file
- Ensure TheHive service is running and accessible

### Cortex
- Configure Cortex URL and API key in the `.env` file
- Ensure Cortex service is running and accessible

### Shuffle
- Configure Shuffle URL and API key in the `.env` file
- Ensure Shuffle is running and accessible

### FAISS
- Ensure FAISS is installed and configured
- Update the FAISS index path in the `.env` file if needed

## Security Considerations

- Never commit sensitive information (API keys, passwords) to version control
- Use strong passwords and API keys
- Restrict access to the management interface using a reverse proxy with authentication
- Regularly update all dependencies to patch security vulnerabilities

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
