from fastapi import FastAPI, Request
import faiss
import numpy as np

app = FastAPI()

# Load your FAISS index here
index = faiss.read_index("attack_index.faiss")
id_to_data = {...}  # Dict mapping IDs to TTPs or incident summaries

@app.post("/search")
async def search_vector(req: Request):
    data = await req.json()
    query_vector = np.array(data["vector"]).astype("float32").reshape(1, -1)
    D, I = index.search(query_vector, k=5)
    results = [id_to_data[i] for i in I[0]]
    return {"results": results}
