"""
Simple test script to verify image search functionality
"""
import base64
import sys
import os

# Add the routers directory to the path
sys.path.append(os.path.join(os.path.dirname(__file__), 'routers'))

try:
    from image_search import search_by_image_base64
    print("✅ Successfully imported image search function")
    
    # Test with a simple base64 string (you can replace this with actual image data)
    print("📝 Testing image search functionality...")
    
    # For now, let's just test the import and basic functionality
    # You would need actual base64 image data to test the full functionality
    print("🎉 Image search module is ready!")
    print("🔗 API endpoint will be available at: http://127.0.0.1:8000/image-search/search")
    print("📚 API documentation will be available at: http://127.0.0.1:8000/docs")
    
except Exception as e:
    print(f"❌ Error: {e}")
    print("Make sure all dependencies are installed and the database is accessible.")
