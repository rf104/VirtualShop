"""
Embedding service for generating and storing image embeddings
"""
import os
import io
import uuid
from PIL import Image
from sentence_transformers import SentenceTransformer
import vecs
import asyncio

class EmbeddingService:
    def __init__(self):
        self._model = None
        self._db_connection = os.getenv('SUPABASE_DB_URL', 
            "postgresql://postgres.wnaqfhqvghulydvnpcsw:01769041694@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres?sslmode=require")
    
    def get_clip_model(self):
        """Lazy load the CLIP model"""
        if self._model is None:
            self._model = SentenceTransformer('clip-ViT-B-32')
        return self._model
    
    async def generate_and_store_embedding(self, image_data: bytes, product_id: int, image_url: str):
        """
        Generate embedding for the image and store it in the vector database.
        """
        try:
            # Load the image
            image = Image.open(io.BytesIO(image_data))
            
            # Convert to RGB if necessary
            if image.mode != 'RGB':
                image = image.convert('RGB')
            
            # Get CLIP model
            model = self.get_clip_model()
            
            # Generate embedding
            embedding = model.encode(image)
            
            # Connect to vector database
            vx = vecs.create_client(self._db_connection)
            
            # Get or create collection
            images = vx.get_or_create_collection(name="product_images", dimension=512)
            
            # Store embedding with metadata
            unique_id = f"product_{product_id}_{uuid.uuid4()}"
            images.upsert(
                records=[(
                    unique_id,  # unique identifier
                    embedding.tolist(),  # the vector as list
                    {
                        "product_id": product_id,
                        "image_url": image_url,
                        "type": "product_image"
                    }  # metadata
                )]
            )
            
            # Create index if needed (ignore errors if already exists)
            try:
                images.create_index()
            except Exception:
                pass  # Index might already exist
            
            print(f"✅ Successfully stored embedding for product {product_id}")
            return True
            
        except Exception as e:
            print(f"❌ Error generating embedding for product {product_id}: {e}")
            return False
    
    def search_similar_images(self, query_image_data: bytes, limit: int = 5):
        """
        Search for similar product images
        """
        try:
            # Load the query image
            image = Image.open(io.BytesIO(query_image_data))
            
            # Convert to RGB if necessary
            if image.mode != 'RGB':
                image = image.convert('RGB')
            
            # Get CLIP model
            model = self.get_clip_model()
            
            # Generate embedding for query image
            query_embedding = model.encode(image)
            
            # Connect to vector database
            vx = vecs.create_client(self._db_connection)
            images = vx.get_or_create_collection(name="product_images", dimension=512)
            
            # Search for similar images
            results = images.query(
                data=query_embedding.tolist(),
                limit=limit,
                filters={"type": {"$eq": "product_image"}},
            )
            
            return [
                {
                    "product_id": result[2]["product_id"],
                    "image_url": result[2]["image_url"],
                    "similarity_score": result[1] if len(result) > 1 else None
                }
                for result in results
            ]
            
        except Exception as e:
            print(f"❌ Error searching similar images: {e}")
            return []

# Global instance
embedding_service = EmbeddingService()