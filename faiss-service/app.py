from fastapi import FastAPI, Request, HTTPException, status, Depends, BackgroundTasks
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import faiss
import numpy as np
import os
import logging
import time
import json
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple
from pydantic import BaseModel, Field, validator
from functools import lru_cache
import hashlib

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

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
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
    vector: List[float] = Field(..., description="The query vector for similarity search")
    k: int = Field(5, ge=1, le=100, description="Number of similar vectors to return")
    min_score: Optional[float] = Field(None, ge=0, le=1, description="Minimum similarity score (0-1)")
    
    @validator('vector')
    def validate_vector_dimension(cls, v):
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
    """Initialize the FAISS index, loading from disk if available or creating a placeholder."""
    global state
    
    if state.lock:
        logger.warning("Index initialization already in progress")
        return
    
    state.lock = True
    
    try:
        # Try to load existing index
        if os.path.exists(INDEX_FILE):
            logger.info(f"Loading existing index from {INDEX_FILE}")
            state.index = faiss.read_index(INDEX_FILE)
            state.metadata = load_metadata()
            state.dimension = state.index.d
            state.initialized = True
            state.last_updated = time.time()
            logger.info(f"Loaded index with {state.index.ntotal} vectors")
        else:
            logger.warning("No existing index found, creating placeholder")
            state.index, state.metadata = create_placeholder_index()
            state.dimension = VECTOR_DIMENSION
            state.initialized = True
            state.last_updated = time.time()
            
            # Save the placeholder index and metadata
            faiss.write_index(state.index, INDEX_FILE)
            save_metadata(state.metadata)
            logger.info(f"Created placeholder index with {state.index.ntotal} vectors")
            
    except Exception as e:
        logger.error(f"Error initializing FAISS index: {str(e)}", exc_info=True)
        state.initialized = False
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to initialize FAISS index: {str(e)}"
        )
    finally:
        state.lock = False

# Initialize the index when the application starts
initialize_index()

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
