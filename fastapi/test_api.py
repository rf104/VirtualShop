"""
Test the image search API endpoint
"""
import requests
import json
import base64

def test_image_search_api():
    """Test the image search API with a sample request"""
    
    # API endpoint
    url = "http://127.0.0.1:8000/image-search/search"
    
    # Sample base64 image (1x1 pixel PNG - for testing only)
    # In real usage, you would use actual base64 encoded images
    sample_base64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
    
    # Request payload
    payload = {
        "base64_image": f"data:image/png;base64,{sample_base64}",
        "limit": 3
    }
    
    try:
        # Make the request
        response = requests.post(url, json=payload)
        
        if response.status_code == 200:
            result = response.json()
            print("✅ API Request Successful!")
            print(f"📝 Response: {json.dumps(result, indent=2)}")
        else:
            print(f"❌ API Request Failed: {response.status_code}")
            print(f"📝 Error: {response.text}")
            
    except requests.exceptions.ConnectionError:
        print("❌ Connection Error: Make sure the FastAPI server is running on http://127.0.0.1:8000")
    except Exception as e:
        print(f"❌ Error: {e}")

def test_health_endpoint():
    """Test the health check endpoint"""
    url = "http://127.0.0.1:8000/image-search/health"
    
    try:
        response = requests.get(url)
        if response.status_code == 200:
            result = response.json()
            print("✅ Health Check Successful!")
            print(f"📝 Response: {json.dumps(result, indent=2)}")
        else:
            print(f"❌ Health Check Failed: {response.status_code}")
            print(f"📝 Error: {response.text}")
            
    except requests.exceptions.ConnectionError:
        print("❌ Connection Error: Make sure the FastAPI server is running")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    print("🔍 Testing Image Search API...")
    print("=" * 50)
    
    print("\n1. Testing Health Endpoint:")
    test_health_endpoint()
    
    print("\n2. Testing Image Search Endpoint:")
    test_image_search_api()
    
    print("\n" + "=" * 50)
    print("✅ Test completed!")
    print("📚 Visit http://127.0.0.1:8000/docs for interactive API documentation")
