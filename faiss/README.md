# FAISS Service for SOC Lab

This service provides efficient similarity search capabilities using FAISS through Milvus.

## Prerequisites

- Docker and Docker Compose
- Python 3.7+

## Getting Started

1. **Start the FAISS service**:
   ```bash
   docker-compose -f docker-compose.faiss.yml up -d
   ```

2. **Access the Web UI**:
   - Open `http://localhost:3001` in your browser
   - Default credentials:
     - Username: `minioadmin`
     - Password: `minioadmin`

3. **Test the Service**:
   ```bash
   # Install Python dependencies
   pip install -r requirements.txt
   
   # Run the test script
   python test_faiss.py
   ```

## API Endpoints

- **gRPC**: `localhost:19530`
- **HTTP**: `http://localhost:19121`
- **MinIO Console**: `http://localhost:9001`

## Stopping the Service

```bash
docker-compose -f docker-compose.faiss.yml down
```

## Integration with TheHive

To integrate FAISS with TheHive for similarity search of observables:

1. Create a custom analyzer in TheHive that sends data to your FAISS service
2. Use the FAISS service to find similar IOCs or observables
3. Enrich your alerts with similarity scores from FAISS

## Troubleshooting

- If you encounter connection issues, ensure all containers are running:
  ```bash
  docker-compose -f docker-compose.faiss.yml ps
  ```

- Check the logs:
  ```bash
  docker-compose -f docker-compose.faiss.yml logs -f
  ```
