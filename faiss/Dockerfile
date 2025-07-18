FROM python:3.9-slim

WORKDIR /app

# Install system dependencies with cleanup in a single layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libopenblas-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user early to ensure proper permissions
RUN useradd -m appuser

# Install Python dependencies first for better layer caching
COPY --chown=appuser:appuser requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code with proper permissions
COPY --chown=appuser:appuser . .

# Create data directory with correct permissions
RUN mkdir -p /app/data && chown appuser:appuser /app/data

# Switch to non-root user
USER appuser

# Health check with proper path
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:7860/health || exit 1

# Expose the port the app runs on
EXPOSE 7860

# Command to run the application with auto-reload in development
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "7860", "--reload"]
