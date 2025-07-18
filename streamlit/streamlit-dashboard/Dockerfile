FROM python:3.9-slim

WORKDIR /app

# Install system dependencies with cleanup in a single layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user early to ensure proper permissions
RUN useradd -m appuser

# Install Python dependencies first for better layer caching
COPY --chown=appuser:appuser requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && \
    # Cleanup pip cache
    rm -rf /root/.cache/pip/*

# Copy application code with proper permissions
COPY --chown=appuser:appuser . .

# Switch to non-root user
USER appuser

# Health check with proper path
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8501/_stcore/health || exit 1

# Expose the port the app runs on
EXPOSE 8501

# Set environment variables for Streamlit
ENV STREAMLIT_SERVER_HEADLESS=true \
    STREAMLIT_SERVER_PORT=8501 \
    STREAMLIT_SERVER_ADDRESS=0.0.0.0 \
    PYTHONUNBUFFERED=1

# Command to run the application
ENTRYPOINT ["streamlit", "run", "app.py"]
