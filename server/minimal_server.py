"""
Minimal FastAPI server for testing basic connectivity
This will help isolate if the issue is with our main app or with basic networking
"""

from fastapi import FastAPI, File, UploadFile, Form
from fastapi.middleware.cors import CORSMiddleware
from typing import List
import uvicorn

# Create minimal app
app = FastAPI(title="Minimal Test Server")

# Add CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "Minimal server is working!"}

@app.get("/test")
async def test():
    return {"status": "success", "message": "Test endpoint working"}

@app.post("/test-upload")
async def test_upload(
    product_name: str = Form(...),
    description: str = Form(...),
    price: float = Form(...),
    images: List[UploadFile] = File(...)
):
    """Minimal version of the product upload endpoint"""
    
    image_info = []
    for image in images:
        content = await image.read()
        image_info.append({
            "filename": image.filename,
            "content_type": image.content_type,
            "size": len(content)
        })
    
    return {
        "success": True,
        "product_name": product_name,
        "description": description,
        "price": price,
        "images_received": len(images),
        "image_info": image_info
    }

@app.get("/health")
async def health():
    return {"status": "healthy", "server": "minimal test server"}

if __name__ == "__main__":
    print("🚀 Starting minimal test server...")
    print("📱 Android emulator: http://10.0.2.2:8000")
    print("🖥️  Desktop: http://127.0.0.1:8000")
    print("📚 Endpoints:")
    print("   GET  /")
    print("   GET  /test")
    print("   POST /test-upload")
    print("   GET  /health")
    print("=" * 50)
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="debug",
        access_log=True
    )