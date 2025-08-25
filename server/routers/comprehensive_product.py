from fastapi import APIRouter, HTTPException, Depends, UploadFile, File, Form
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import asyncpg
import uuid
import os
import asyncio
from db import get_db_pool
from services.embedding_service import embedding_service

router = APIRouter()

# Pydantic models for comprehensive product
class ComprehensiveProduct(BaseModel):
    product_id: int
    created_at: datetime
    seller_id: Optional[int]
    category_id: Optional[int]
    product_name: Optional[str]
    description: Optional[str]
    price: Optional[float]
    is_refurbished: Optional[bool]
    category: Optional[str]
    brand: Optional[str]
    stock_quantity: Optional[int]
    condition: Optional[str]
    weight: Optional[float]
    dimensions: Optional[str]
    in_stock: Optional[bool]
    featured_product: Optional[bool]
    image_urls: Optional[List[str]]

class ComprehensiveProductCreate(BaseModel):
    seller_id: Optional[int] = 1  # Default seller ID for testing
    category_id: Optional[int] = 1  # Default category ID
    product_name: str
    description: str
    price: float
    is_refurbished: Optional[bool] = False
    category: str
    brand: Optional[str]
    stock_quantity: int
    condition: str
    weight: Optional[float]
    dimensions: Optional[str]
    in_stock: Optional[bool] = True
    featured_product: Optional[bool] = False

async def save_image_to_storage(image_data: bytes, filename: str) -> str:
    """
    Save image to local storage and return the URL.
    In production, this would upload to Supabase Storage.
    """
    # Create uploads directory if it doesn't exist
    upload_dir = "uploads/products"
    os.makedirs(upload_dir, exist_ok=True)
    
    # Generate unique filename
    unique_filename = f"{uuid.uuid4()}_{filename}"
    file_path = os.path.join(upload_dir, unique_filename)
    
    # Save the image
    with open(file_path, "wb") as f:
        f.write(image_data)
    
    # Return the URL (in production, this would be Supabase Storage URL)
    return f"/uploads/products/{unique_filename}"

async def generate_and_store_embedding(image_data: bytes, product_id: int, image_url: str):
    """
    Generate embedding for the image and store it in the vector database.
    """
    return await embedding_service.generate_and_store_embedding(image_data, product_id, image_url)

@router.post("/", response_model=ComprehensiveProduct)
async def create_comprehensive_product(
    # Product data
    product_name: str = Form(...),
    description: str = Form(...),
    price: float = Form(...),
    category: str = Form(...),
    stock_quantity: int = Form(...),
    condition: str = Form(...),
    brand: Optional[str] = Form(None),
    weight: Optional[float] = Form(None),
    dimensions: Optional[str] = Form(None),
    is_refurbished: Optional[bool] = Form(False),
    in_stock: Optional[bool] = Form(True),
    featured_product: Optional[bool] = Form(False),
    seller_id: Optional[int] = Form(1),
    category_id: Optional[int] = Form(1),
    # Images
    images: List[UploadFile] = File(...),
    pool: asyncpg.Pool = Depends(get_db_pool)
):
    """
    Create a comprehensive product with all fields and multiple images.
    Generates embeddings for all product images.
    """
    
    # Validate images
    if not images or len(images) == 0:
        raise HTTPException(status_code=400, detail="At least one product image is required")
    
    if len(images) > 5:
        raise HTTPException(status_code=400, detail="Maximum 5 images allowed")
    
    # Check if required fields are provided
    if not product_name or not description:
        raise HTTPException(status_code=400, detail="Product name and description are required")
    
    async with pool.acquire() as conn:
        try:
            # Start a transaction
            async with conn.transaction():
                # Insert product into database
                product_result = await conn.fetchrow(
                    """
                    INSERT INTO product (
                        seller_id, category_id, product_name, description, price, is_refurbished
                    ) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *
                    """,
                    seller_id, category_id, product_name, description, price, is_refurbished
                )
                
                product_id = product_result['product_id']
                
                # Process and save images
                image_urls = []
                
                for idx, image in enumerate(images):
                    # Read image data
                    image_data = await image.read()
                    
                    # Validate image type
                    if not image.content_type or not image.content_type.startswith('image/'):
                        raise HTTPException(status_code=400, detail=f"File {image.filename} is not a valid image")
                    
                    # Save image to storage
                    image_url = await save_image_to_storage(image_data, image.filename or f"image_{idx}.jpg")
                    image_urls.append(image_url)
                    
                    # Insert image record into product_img table
                    await conn.execute(
                        """
                        INSERT INTO product_img (product_id, img_url, type)
                        VALUES ($1, $2, $3)
                        """,
                        product_id, image_url, "product_image"
                    )
                    
                    # Generate embedding asynchronously (don't wait for it to complete)
                    # Pass image_data as bytes to the embedding service
                    asyncio.create_task(generate_and_store_embedding(image_data, product_id, image_url))
                
                # Return the comprehensive product data
                return ComprehensiveProduct(
                    product_id=product_result['product_id'],
                    created_at=product_result['created_at'],
                    seller_id=product_result['seller_id'],
                    category_id=product_result['category_id'],
                    product_name=product_result['product_name'],
                    description=product_result['description'],
                    price=product_result['price'],
                    is_refurbished=product_result['is_refurbished'],
                    category=category,
                    brand=brand,
                    stock_quantity=stock_quantity,
                    condition=condition,
                    weight=weight,
                    dimensions=dimensions,
                    in_stock=in_stock,
                    featured_product=featured_product,
                    image_urls=image_urls
                )
                
        except asyncpg.exceptions.ForeignKeyViolationError:
            raise HTTPException(status_code=400, detail="Invalid seller_id or category_id")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to create product: {str(e)}")

@router.get("/", response_model=List[ComprehensiveProduct])
async def get_all_comprehensive_products(pool: asyncpg.Pool = Depends(get_db_pool)):
    """
    Get all comprehensive products with their images.
    """
    async with pool.acquire() as conn:
        try:
            # Get all products with their images
            products_with_images = await conn.fetch("""
                SELECT 
                    p.*,
                    COALESCE(
                        array_agg(pi.img_url) FILTER (WHERE pi.img_url IS NOT NULL), 
                        ARRAY[]::text[]
                    ) as image_urls
                FROM product p
                LEFT JOIN product_img pi ON p.product_id = pi.product_id
                GROUP BY p.product_id, p.created_at, p.seller_id, p.category_id, 
                         p.product_name, p.description, p.price, p.is_refurbished
                ORDER BY p.created_at DESC
            """)
            
            result = []
            for row in products_with_images:
                result.append(ComprehensiveProduct(
                    product_id=row['product_id'],
                    created_at=row['created_at'],
                    seller_id=row['seller_id'],
                    category_id=row['category_id'],
                    product_name=row['product_name'],
                    description=row['description'],
                    price=row['price'],
                    is_refurbished=row['is_refurbished'],
                    category="",  # These fields aren't in the current DB schema
                    brand="",
                    stock_quantity=0,
                    condition="",
                    weight=None,
                    dimensions=None,
                    in_stock=True,
                    featured_product=False,
                    image_urls=list(row['image_urls']) if row['image_urls'] else []
                ))
            
            return result
            
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to fetch products: {str(e)}")

@router.get("/{product_id}", response_model=ComprehensiveProduct)
async def get_comprehensive_product_by_id(product_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    """
    Get a specific comprehensive product by ID with its images.
    """
    async with pool.acquire() as conn:
        try:
            # Get product with images
            product_with_images = await conn.fetchrow("""
                SELECT 
                    p.*,
                    COALESCE(
                        array_agg(pi.img_url) FILTER (WHERE pi.img_url IS NOT NULL), 
                        ARRAY[]::text[]
                    ) as image_urls
                FROM product p
                LEFT JOIN product_img pi ON p.product_id = pi.product_id
                WHERE p.product_id = $1
                GROUP BY p.product_id, p.created_at, p.seller_id, p.category_id, 
                         p.product_name, p.description, p.price, p.is_refurbished
            """, product_id)
            
            if not product_with_images:
                raise HTTPException(status_code=404, detail="Product not found")
            
            return ComprehensiveProduct(
                product_id=product_with_images['product_id'],
                created_at=product_with_images['created_at'],
                seller_id=product_with_images['seller_id'],
                category_id=product_with_images['category_id'],
                product_name=product_with_images['product_name'],
                description=product_with_images['description'],
                price=product_with_images['price'],
                is_refurbished=product_with_images['is_refurbished'],
                category="",  # These fields aren't in the current DB schema
                brand="",
                stock_quantity=0,
                condition="",
                weight=None,
                dimensions=None,
                in_stock=True,
                featured_product=False,
                image_urls=list(product_with_images['image_urls']) if product_with_images['image_urls'] else []
            )
            
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to fetch product: {str(e)}")