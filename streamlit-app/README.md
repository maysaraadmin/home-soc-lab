# SOC Dashboard with Streamlit

A modern, interactive Security Operations Center (SOC) dashboard built with Streamlit.

## Features

- Real-time alert monitoring
- Incident management
- Analyzers performance tracking
- Responders efficiency metrics
- Interactive charts and visualizations
- Filterable data tables

## Prerequisites

- Docker and Docker Compose
- Python 3.9+ (for local development)

## Getting Started

### Using Docker (Recommended)

1. **Build and start the container**:
   ```bash
   docker-compose -f docker-compose.streamlit.yml up -d --build
   ```

2. **Access the dashboard**:
   Open your browser and navigate to:
   ```
   http://localhost:8501
   ```

### Local Development

1. **Create a virtual environment**:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Run the application**:
   ```bash
   streamlit run app.py
   ```

4. **Access the dashboard**:
   Open your browser and navigate to:
   ```
   http://localhost:8501
   ```

## Project Structure

```
streamlit-app/
├── app.py                # Main Streamlit application
├── pages/                # Additional pages for the app
├── static/               # Static files (images, CSS, etc.)
├── data/                 # Data files
├── requirements.txt      # Python dependencies
└── Dockerfile            # Docker configuration
```

## Customization

### Adding New Pages

1. Create a new Python file in the `pages` directory (e.g., `pages/2_analytics.py`)
2. The page will be automatically discovered by Streamlit

### Updating Visualizations

Edit the `app.py` file to modify or add new visualizations using Plotly or other supported libraries.

## Deployment

### Docker Compose

The provided `docker-compose.streamlit.yml` file can be used to deploy the application in a containerized environment.

### Cloud Deployment

The application can be deployed to various cloud platforms that support Docker containers, such as:
- AWS ECS/EKS
- Google Cloud Run
- Azure Container Instances
- Heroku with Docker

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
