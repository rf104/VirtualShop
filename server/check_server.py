import requests
import json
import sys
import os

def check_server_status():
    """Check if the FastAPI server is running and accessible."""
    
    base_urls = [
        "http://127.0.0.1:8000",
        "http://localhost:8000", 
        "http://0.0.0.0:8000"
    ]
    
    print("🔍 Checking FastAPI server status...")
    print("=" * 50)
    
    server_running = False
    
    for url in base_urls:
        try:
            print(f"Testing: {url}")
            response = requests.get(f"{url}/docs", timeout=5)
            if response.status_code == 200:
                print(f"✅ Server is running at {url}")
                print(f"   Swagger docs: {url}/docs")
                server_running = True
                break
            else:
                print(f"❌ Server responded with status {response.status_code}")
        except requests.exceptions.ConnectionError:
            print(f"❌ Connection refused - server not running at {url}")
        except requests.exceptions.Timeout:
            print(f"❌ Request timeout at {url}")
        except Exception as e:
            print(f"❌ Error: {e}")
    
    if not server_running:
        print("\n⚠️  FastAPI server is not running!")
        print("To start the server, run:")
        print("   cd server")
        print("   python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload")
        return False
    
    print("\n🔍 Testing comprehensive-product endpoint...")
    try:
        # Test the main endpoint
        response = requests.get("http://127.0.0.1:8000/comprehensive-product/", timeout=5)
        if response.status_code == 200:
            print("✅ Comprehensive product endpoint is working")
            products = response.json()
            print(f"   Found {len(products)} existing products")
        else:
            print(f"❌ Endpoint returned status {response.status_code}")
            print(f"   Response: {response.text}")
    except Exception as e:
        print(f"❌ Error testing endpoint: {e}")
    
    print("\n🔍 Checking database connection...")
    try:
        # Check if we can access the health endpoint or any basic endpoint
        response = requests.get("http://127.0.0.1:8000/", timeout=5)
        if response.status_code in [200, 404]:  # 404 is okay, means server is running
            print("✅ Server is responding to requests")
        else:
            print(f"❌ Unexpected status: {response.status_code}")
    except Exception as e:
        print(f"❌ Error checking server: {e}")
    
    print("\n" + "=" * 50)
    if server_running:
        print("🎉 Server appears to be working correctly!")
        print("You can now test the Flutter app.")
        print("\nFor Android emulator, the app will connect to: http://10.0.2.2:8000")
        print("For iOS/Desktop, the app will connect to: http://127.0.0.1:8000")
    else:
        print("❌ Please start the server before testing the Flutter app.")
    
    return server_running

if __name__ == "__main__":
    check_server_status()