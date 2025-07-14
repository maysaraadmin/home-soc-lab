import numpy as np
from pymilvus import connections, DataType, Collection, CollectionSchema, FieldSchema, utility
import time

def connect_to_milvus():
    """Connect to the Milvus server."""
    print("Connecting to Milvus...")
    connections.connect("default", host="localhost", port="19530")
    print("Successfully connected to Milvus!")

def create_collection(collection_name, dim):
    """Create a collection in Milvus."""
    if utility.has_collection(collection_name):
        print(f"Collection {collection_name} already exists. Dropping it...")
        utility.drop_collection(collection_name)
    
    # Define fields
    fields = [
        FieldSchema(name="id", dtype=DataType.INT64, is_primary=True, auto_id=True),
        FieldSchema(name="embedding", dtype=DataType.FLOAT_VECTOR, dim=dim),
        FieldSchema(name="text", dtype=DataType.VARCHAR, max_length=500)
    ]
    
    # Create schema
    schema = CollectionSchema(fields=fields, description="Test collection for FAISS")
    
    # Create collection
    collection = Collection(name=collection_name, schema=schema)
    
    # Create index
    index_params = {
        "index_type": "IVF_FLAT",
        "metric_type": "L2",
        "params": {"nlist": 128}
    }
    
    collection.create_index(field_name="embedding", index_params=index_params)
    print(f"Created collection {collection_name} with index")
    return collection

def insert_data(collection, vectors, texts):
    """Insert data into the collection."""
    entities = [
        vectors,  # embeddings
        texts     # text data
    ]
    
    insert_result = collection.insert(entities)
    collection.flush()
    print(f"Inserted {len(vectors)} vectors into the collection")
    return insert_result

def search_similar(collection, query_vector, top_k=5):
    """Search for similar vectors."""
    search_params = {
        "metric_type": "L2",
        "params": {"nprobe": 10}
    }
    
    # Load collection to memory
    collection.load()
    
    # Search
    results = collection.search(
        data=[query_vector],
        anns_field="embedding",
        param=search_params,
        limit=top_k,
        output_fields=["text"]
    )
    
    print("\nSearch Results:")
    for hits in results:
        for hit in hits:
            print(f"ID: {hit.id}, Distance: {hit.distance}, Text: {hit.entity.get('text')}")
    
    return results

def main():
    # Connect to Milvus
    connect_to_milvus()
    
    # Collection parameters
    collection_name = "test_collection"
    dim = 128  # Dimension of the vectors
    
    # Create collection
    collection = create_collection(collection_name, dim)
    
    # Generate some random data for testing
    num_vectors = 1000
    vectors = np.random.random((num_vectors, dim)).tolist()
    texts = [f"text_{i}" for i in range(num_vectors)]
    
    # Insert data
    insert_data(collection, vectors, texts)
    
    # Create a test query vector
    query_vector = np.random.random(dim).tolist()
    
    # Search for similar vectors
    search_similar(collection, query_vector)
    
    # Clean up
    utility.drop_collection(collection_name)
    print(f"\nDropped collection {collection_name}")

if __name__ == "__main__":
    main()
