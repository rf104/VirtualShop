"""
Test script to verify server connectivity from Android emulator perspective
"""
import requests
import json
import time
import sys

def test_server_connectivity():
    """Test if the server is accessible from both localhost and emulator addresses"""
    
    test_urls = [
        ("http://127.0.0.1:8000", "Desktop/iOS/Web"),
        ("http://10.0.2.2:8000", "Android Emulator"), 
        ("http://0.0.0.0:8000", "All Interfaces"),
        ("http://localhost:8000", "Localhost")
    ]
    
    print("🔍 Testing server connectivity...")
    print("=" * 60)
    
    server_accessible = False
    
    for url, description in test_urls:
        try:
            print(f"Testing {description}: {url}")
            
            # Test basic connectivity
            response = requests.get(f"{url}/docs", timeout=5)
            if response.status_code == 200:
                print(f"✅ {description} - Server accessible")
                server_accessible = True
                
                # Test the comprehensive-product endpoint
                try:
                    api_response = requests.get(f"{url}/comprehensive-product/", timeout=5)
                    if api_response.status_code == 200:
                        products = api_response.json()
                        print(f"   📦 API endpoint working - {len(products)} products found")
                    else:
                        print(f"   ⚠️  API endpoint returned status {api_response.status_code}")
                except Exception as e:
                    print(f"   ❌ API endpoint error: {e}")
                    
            else:
                print(f"❌ {description} - Server returned status {response.status_code}")
                
        except requests.exceptions.ConnectionError:
            print(f"❌ {description} - Connection refused")
        except requests.exceptions.Timeout:
            print(f"❌ {description} - Request timeout")
        except Exception as e:
            print(f"❌ {description} - Error: {e}")
        
        print()
    
    print("=" * 60)
    
    if server_accessible:
        print("🎉 Server is accessible! You can now test the Flutter app.")
        print()
        print("Next steps:")
        print("1. Make sure the Flutter app is running in Android emulator")
        print("2. Navigate to the 'Add Product' page")
        print("3. Fill in all required fields")
        print("4. Select some images")
        print("5. Click 'Add Product'")
        print()
        print("The app should connect to http://10.0.2.2:8000")
    else:
        print("❌ Server is not accessible from any address!")
        print()
        print("Troubleshooting steps:")
        print("1. Make sure the server is running: python start_server.py")
        print("2. Check if port 8000 is available")
        print("3. Verify firewall settings")
        print("4. Try restarting the server")
    
    return server_accessible

def test_emulator_specific():
    """Test specific emulator connectivity issues"""
    print("\n🤖 Testing Android emulator specific connectivity...")
    
    try:
        # Test if we can reach the emulator gateway
        response = requests.get("http://10.0.2.2:8000/docs", timeout=10)
        if response.status_code == 200:
            print("✅ Android emulator can reach the server!")
            return True
        else:
            print(f"❌ Server responded with status {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print("❌ Android emulator cannot reach the server")
        print("   This usually means:")
        print("   - Server is not running")
        print("   - Server is not bound to 0.0.0.0 (should be 0.0.0.0, not 127.0.0.1)")
        print("   - Port 8000 is blocked")
        return False
    except Exception as e:
        print(f"❌ Emulator connectivity error: {e}")
        return False

if __name__ == "__main__":
    if test_server_connectivity():
        test_emulator_specific()
    else:
        print("\n⚠️  Please start the server first:")
        print("   cd server")
        print("   python start_server.py")