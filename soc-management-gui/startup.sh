#!/bin/bash
set -e

# Check for required environment variables
for var in REQUIRED_ENV_VARS; do
    if [ -z "${!var}" ]; then
        echo "Error: $var is not set. Please set all required environment variables."
        exit 1
    fi
done

# Wait for any dependent services
if [ -n "$WAIT_FOR_HOST" ] && [ -n "$WAIT_FOR_PORT" ]; then
    echo "Waiting for $WAIT_FOR_HOST:$WAIT_FOR_PORT..."
    while ! nc -z $WAIT_FOR_HOST $WAIT_FOR_PORT; do
        sleep 1
    done
    echo "$WAIT_FOR_HOST:$WAIT_FOR_PORT is available!"
fi

# Run migrations or other setup commands
python -c "import os; print(f'Starting SOC Management GUI with environment: {os.environ.get(\"ENVIRONMENT\", \"development\")}')"

# Start the application
exec streamlit run app.py --server.address=0.0.0.0 --server.port=8501 "$@"
