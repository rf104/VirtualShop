from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import base64
import io
from PIL import Image
from sentence_transformers import SentenceTransformer
import vecs
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

router = APIRouter()

# Get database connection from environment variable
DB_CONNECTION = os.getenv('SUPABASE_DB_URL')
if not DB_CONNECTION:
    raise ValueError("SUPABASE_DB_URL environment variable is not set. Please check your .env file.")

class ImageSearchRequest(BaseModel):
    base64_image: str
    limit: Optional[int] = 3

class ImageSearchResponse(BaseModel):
    image_ids: List[str]
    message: str

def base64_to_image(base64_string: str) -> Image.Image:
    """Convert base64 string to PIL Image"""
    try:
        # Remove data:image/jpeg;base64, prefix if present
        if base64_string.startswith('data:image'):
            base64_string = base64_string.split(',')[1]
        
        # Decode base64
        image_data = base64.b64decode(base64_string)
        image = Image.open(io.BytesIO(image_data))
        return image
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid base64 image: {str(e)}")

def search_by_image_base64(base64_image: str, limit: int = 3) -> List[str]:
    """
    Search for similar images using a base64 encoded image
    
    Args:
        base64_image: Base64 encoded image string
        limit: Number of results to return
        
    Returns:
        List of image IDs (filenames without extension)
    """
    try:
        # Create vector store client
        vx = vecs.create_client(DB_CONNECTION)
        images = vx.get_or_create_collection(name="image_vectors", dimension=512)

        # Load CLIP model
        model = SentenceTransformer('clip-ViT-B-32')
        
        # Convert base64 to image
        query_img = base64_to_image(base64_image)
        
        # Encode the query image
        query_emb = model.encode(query_img)

        # Query the collection
        results = images.query(
            data=query_emb,                     # required
            limit=limit,                        # number of records to return
            filters={"type": {"$eq": "jpg"}},   # metadata filters
        )
        
        if results:
            # Extract image IDs (remove .jpg extension)
            image_ids = []
            for result in results:
                filename = result[0] if isinstance(result, (tuple, list)) else str(result)
                # Remove file extension to get ID
                image_id = filename.replace('.jpg', '').replace('.jpeg', '').replace('.png', '')
                image_ids.append(image_id)
            
            return image_ids
        else:
            return []
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Search failed: {str(e)}")

@router.post("/search", response_model=ImageSearchResponse)
async def search_similar_images(request: ImageSearchRequest):
    """
    Search for similar images using base64 encoded image
    
    - **base64_image**: Base64 encoded image string (with or without data URI prefix)
    - **limit**: Maximum number of results to return (default: 3, max: 10)
    """
    # Validate limit
    if request.limit > 10:
        raise HTTPException(status_code=400, detail="Limit cannot exceed 10")
    
    if request.limit < 1:
        raise HTTPException(status_code=400, detail="Limit must be at least 1")
    
    try:
        # Search for similar images
        image_ids = search_by_image_base64(request.base64_image, request.limit)
        
        if image_ids:
            return ImageSearchResponse(
                image_ids=image_ids,
                message=f"Found {len(image_ids)} similar images"
            )
        else:
            return ImageSearchResponse(
                image_ids=[],
                message="No similar images found"
            )
            
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.get("/health")
async def health_check():
    """Health check endpoint for image search service"""
    try:
        # Test database connection
        vx = vecs.create_client(DB_CONNECTION)
        images = vx.get_or_create_collection(name="image_vectors", dimension=512)
        return {
            "status": "healthy",
            "message": "Image search service is running",
            "database": "connected"
        }
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Service unavailable: {str(e)}")
