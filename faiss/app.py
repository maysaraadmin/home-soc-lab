from fastapi import FastAPI, Request, HTTPException, status, Depends, BackgroundTasks
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.httpsredirect import HTTPSRedirectMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
import faiss
import numpy as np
import os
import logging
import time
import json
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple
from pydantic import BaseModel, Field, validator, conlist
from functools import lru_cache
import hashlib
import json_logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configuration
VECTOR_DIMENSION = int(os.getenv("VECTOR_DIMENSION", 128))
INDEX_FILE = os.getenv("FAISS_INDEX_PATH", "/app/data/faiss_index") + "/attack_index.faiss"
METADATA_FILE = os.path.splitext(INDEX_FILE)[0] + ".json"

# Ensure the data directory exists
os.makedirs(os.path.dirname(INDEX_FILE), exist_ok=True)

app = FastAPI(
    title="FAISS Vector Search Service",
    description="Service for similarity search using FAISS",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Configure security middleware
app.add_middleware(HTTPSRedirectMiddleware)
app.add_middleware(TrustedHostMiddleware, allowed_hosts=["localhost", "yourdomain.com"])

# Add CORS middleware with proper restrictions
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:8501", "https://yourdomain.com"],
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Authorization"],
    expose_headers=["Content-Length"],
    max_age=600,
)

# Global state
class FAISSState:
    def __init__(self):
        self.index = None
        self.dimension = VECTOR_DIMENSION
        self.metadata = {}
        self.last_updated = None
        self.initialized = False
        self.lock = False

state = FAISSState()

class SearchRequest(BaseModel):
    vector: conlist(float, min_items=1, max_items=1024) = Field(
        ...,
        description="The query vector for similarity search. Must match VECTOR_DIMENSION",
        example=[0.1, 0.2, 0.3]  # Example with 3 elements, actual should match VECTOR_DIMENSION
    )
    k: int = Field(
        5,
        ge=1,
        le=100,
        description="Number of similar vectors to return (1-100)"
    )
    min_score: Optional[float] = Field(
        None,
        ge=0,
        le=1,
        description="Minimum similarity score (0-1)"
    )
    
    @validator('vector')
    def validate_vector_values(cls, v):
        if not all(isinstance(x, (int, float)) for x in v):
            raise ValueError("All vector elements must be numbers")
        if len(v) != VECTOR_DIMENSION:
            raise ValueError(f"Vector dimension must be {VECTOR_DIMENSION}, got {len(v)}")
        return v

class SearchResult(BaseModel):
    results: List[Dict[str, Any]]

# Initialize empty index and data mapping
index = None
id_to_data: Dict[int, Dict[str, Any]] = {}

def load_metadata() -> Dict[int, Dict[str, Any]]:
    """Load metadata from JSON file if it exists."""
    if not os.path.exists(METADATA_FILE):
        return {}
    try:
        with open(METADATA_FILE, 'r') as f:
            return json.load(f)
    except Exception as e:
        logger.error(f"Error loading metadata: {str(e)}")
        return {}

def save_metadata(metadata: Dict[int, Dict[str, Any]]) -> None:
    """Save metadata to JSON file."""
    try:
        with open(METADATA_FILE, 'w') as f:
            json.dump(metadata, f, indent=2)
    except Exception as e:
        logger.error(f"Error saving metadata: {str(e)}")
        raise

def create_placeholder_index() -> Tuple[faiss.Index, Dict[int, Dict[str, Any]]]:
    """Create a placeholder FAISS index with random data."""
    logger.warning(f"Creating placeholder index with dimension {VECTOR_DIMENSION}")
    
    # Create a new index
    index = faiss.IndexFlatL2(VECTOR_DIMENSION)
    
    # Generate some random vectors
    rng = np.random.RandomState(42)
    num_vectors = 100
    xb = rng.random((num_vectors, VECTOR_DIMENSION)).astype('float32')
    
    # Add vectors to index
    index.add(xb)
    
    # Create metadata for each vector
    metadata = {}
    for i in range(num_vectors):
        metadata[i] = {
            "id": i,
            "title": f"Placeholder TTP {i}",
            "description": "This is a placeholder entry. Train the model with real data.",
            "mitre_tactic": "placeholder",
            "mitre_technique_id": f"T{1000 + i}",
            "created_at": time.time(),
            "is_placeholder": True
        }
    
    return index, metadata

def initialize_index() -> None:
    """
    Initialize the FAISS index, loading from disk if available or creating a placeholder.
    
    Raises:
        RuntimeError: If there's an error initializing the index
        HTTPException: If there's a service initialization error
    """
    global state
    
    if state.lock:
        logger.warning("Index initialization already in progress")
        return
    
    state.lock = True
    
    try:
        # Try to load existing index
        if os.path.exists(INDEX_FILE):
            logger.info(f"Loading existing index from {INDEX_FILE}")
            try:
                state.index = faiss.read_index(INDEX_FILE)
                state.metadata = load_metadata()
                state.dimension = state.index.d
                
                # Validate metadata consistency
                if len(state.metadata) != state.index.ntotal:
                    logger.warning(
                        f"Metadata count ({len(state.metadata)}) doesn't match "
                        f"index size ({state.index.ntotal}). Rebuilding metadata."
                    )
                    state.metadata = {}
                
                state.initialized = True
                state.last_updated = time.time()
                logger.info(f"Successfully loaded index with {state.index.ntotal} vectors")
                
            except faiss.FaissException as e:
                logger.error(f"FAISS error loading index: {str(e)}")
                logger.info("Attempting to create a new index due to loading error")
                try:
                    _create_new_index()
                except Exception as create_error:
                    logger.error(f"Failed to create new index: {str(create_error)}")
                    raise HTTPException(
                        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                        detail="Failed to initialize FAISS index"
                    ) from create_error
                
        else:
            logger.info("No existing index found, creating new index")
            try:
                _create_new_index()
            except Exception as create_error:
                logger.error(f"Failed to create new index: {str(create_error)}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Failed to initialize FAISS index"
                ) from create_error
                
    except HTTPException:
        raise
    except Exception as e:
        error_msg = f"Failed to initialize FAISS index: {str(e)}"
        logger.error(error_msg, exc_info=True)
        state.initialized = False
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error during initialization"
        ) from e
    finally:
        state.lock = False

def _create_new_index() -> None:
    """Helper function to create a new FAISS index and metadata."""
    try:
        state.index, state.metadata = create_placeholder_index()
        state.dimension = VECTOR_DIMENSION
        
        # Ensure the directory exists before writing
        os.makedirs(os.path.dirname(INDEX_FILE), exist_ok=True)
        
        # Save the new index and metadata
        faiss.write_index(state.index, INDEX_FILE)
        save_metadata(state.metadata)
        
        state.initialized = True
        state.last_updated = time.time()
        logger.info(f"Successfully created new index with {state.index.ntotal} vectors")
        
    except Exception as e:
        error_msg = f"Failed to create new FAISS index: {str(e)}"
        logger.error(error_msg, exc_info=True)
        raise RuntimeError(error_msg) from e
            
    except Exception as e:
        logger.error(f"Error initializing FAISS index: {str(e)}", exc_info=True)
        state.initialized = False
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to initialize FAISS index: {str(e)}"
        )
    finally:
        state.lock = False

# Configure structured logging
json_logging.init_console()
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# Add request logging middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    request_id = hashlib.md5(f"{time.time()}".encode()).hexdigest()
    logger.info(f"Request {request_id} - {request.method} {request.url}")
    
    start_time = time.time()
    try:
        response = await call_next(request)
        process_time = (time.time() - start_time) * 1000
        logger.info(
            f"Request {request_id} completed - "
            f"Status: {response.status_code}, "
            f"Time: {process_time:.2f}ms"
        )
        return response
    except Exception as e:
        logger.error(f"Request {request_id} failed: {str(e)}", exc_info=True)
        raise

# Initialize the index when the application starts
try:
    logger.info("Initializing FAISS service...")
    initialize_index()
    logger.info("FAISS service initialized successfully")
except Exception as e:
    logger.critical(f"Failed to initialize FAISS service: {str(e)}", exc_info=True)
    raise SystemExit(1)

# API endpoints
@app.get("/status", status_code=status.HTTP_200_OK)
async def get_status():
    """Get the status of the FAISS service."""
    return {
        "status": "initialized" if state.initialized else "initializing",
        "index_size": state.index.ntotal if state.initialized else 0,
        "dimension": state.dimension,
        "last_updated": state.last_updated,
        "has_placeholder_data": any(v.get("is_placeholder", False) for v in state.metadata.values())
    }

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Handle uncaught exceptions globally."""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "detail": "Internal server error",
            "error": str(exc),
            "type": exc.__class__.__name__
        },
    )

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    if not state.initialized or state.index is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="FAISS index not initialized"
        )
    
    # Basic health check - verify the index is accessible
    try:
        # Try a small operation on the index
        if state.index.ntotal > 0:
            dummy_vec = np.zeros((1, state.dimension), dtype='float32')
            state.index.search(dummy_vec, 1)
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"FAISS index error: {str(e)}"
        )
    
    return {
        "status": "healthy",
        "index_size": state.index.ntotal,
        "dimension": state.dimension,
        "has_placeholder_data": any(v.get("is_placeholder", False) for v in state.metadata.values())
    }

@app.post("/search", response_model=SearchResult, status_code=status.HTTP_200_OK)
async def search_vector(request: SearchRequest):
    """
    Search for similar vectors in the FAISS index.
    
    Args:
        request: SearchRequest containing the query vector and search parameters
        
    Returns:
        Search results with similar vectors and their metadata
    """
    if not state.initialized or state.index is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="FAISS index not initialized"
        )
        
    if state.index.ntotal == 0:
        return {"results": []}
    
    try:
        # Validate input vector
        if not request.vector:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid vector dimension: expected {state.dimension}, got {query_vector.shape[1]}"
            )
        
        # Determine how many results to return
        k = min(max(1, request.k), 100)  # Ensure k is between 1 and 100
        k = min(k, state.index.ntotal)  # Don't ask for more vectors than exist
        
        # Search the index
        distances, indices = state.index.search(query_vector, k)
        
        # Get the metadata for the results
        results = []
        for i, (dist, idx) in enumerate(zip(distances[0], indices[0])):
            if idx < 0:  # Skip invalid indices
                continue
                
            # Convert distance to similarity score (0-1)
            # Using exponential decay: e^(-distance) for better score distribution
            score = float(np.exp(-dist))
            
            # Apply minimum score filter if provided
            if request.min_score is not None and score < request.min_score:
                continue
            
            # Get metadata for this result
            metadata = state.metadata.get(int(idx), {
                "id": int(idx),
                "title": f"Result {i+1}",
                "description": "No description available",
                "score": score,
                "distance": float(dist)
            })
            
            # Add the score and distance to the result
            result = {
                **metadata,
                "score": score,
                "distance": float(dist)
            }
            
            results.append(result)
        
        # Sort results by score (descending)
        results.sort(key=lambda x: x["score"], reverse=True)
        
        # Log the search
        logger.info(
            f"Search completed: found {len(results)} results "
            f"(query_dim={state.dimension}, k={k}, min_score={request.min_score}, "
            f"took={(time.time() - start_time)*1000:.2f}ms)"
        )
        
        return {"results": results}
        
    except HTTPException:
        raise  # Re-raise HTTP exceptions
    except Exception as e:
        logger.error(f"Error during vector search: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error during search: {str(e)}"
        )

# Add a simple root endpoint
@app.get("/")
async def root():
    """Root endpoint with basic information."""
    return {
        "service": "FAISS Vector Search Service",
        "status": "operational" if index is not None else "initializing",
        "index_size": index.ntotal if index is not None else 0,
        "endpoints": [
            {"path": "/search", "method": "POST", "description": "Search for similar vectors"},
            {"path": "/health", "method": "GET", "description": "Service health check"}
        ]
    }
