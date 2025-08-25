"""
Simple connection test to diagnose the specific network issue
"""

import socket
import requests
import time

def test_raw_socket_connection():
    """Test raw socket connection to identify the exact issue"""
    print("🔍 Testing raw socket connections...")
    
    addresses_to_test = [
        ("127.0.0.1", 8000, "Localhost"),
        ("10.0.2.2", 8000, "Android Emulator Gateway"),
        ("0.0.0.0", 8000, "All Interfaces (bind test)")
    ]
    
    for host, port, description in addresses_to_test:
        print(f"\nTesting {description}: {host}:{port}")
        
        try:
            # Test TCP connection
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            result = sock.connect_ex((host, port))
            
            if result == 0:
                print(f"✅ TCP connection successful")
                sock.close()
                
                # Test HTTP request
                try:
                    response = requests.get(f"http://{host}:{port}/docs", timeout=5)
                    print(f"✅ HTTP request successful - Status: {response.status_code}")
                except Exception as e:
                    print(f"❌ HTTP request failed: {e}")
                    
            else:
                print(f"❌ TCP connection failed - Error code: {result}")
                sock.close()
                
        except Exception as e:
            print(f"❌ Socket test failed: {e}")

def test_server_endpoints():
    """Test specific server endpoints"""
    print("\n🔍 Testing server endpoints...")
    
    base_urls = ["http://127.0.0.1:8000", "http://10.0.2.2:8000"]
    endpoints = ["/docs", "/", "/comprehensive-product/"]
    
    for base_url in base_urls:
        print(f"\nTesting {base_url}:")
        for endpoint in endpoints:
            url = base_url + endpoint
            try:
                response = requests.get(url, timeout=5)
                print(f"  ✅ {endpoint} - Status: {response.status_code}")
            except requests.exceptions.ConnectionError:
                print(f"  ❌ {endpoint} - Connection refused")
            except requests.exceptions.Timeout:
                print(f"  ❌ {endpoint} - Timeout")
            except Exception as e:
                print(f"  ❌ {endpoint} - Error: {e}")

def simulate_flutter_request():
    """Simulate the exact request Flutter is making"""
    print("\n🔍 Simulating Flutter's multipart request...")
    
    try:
        import io
        from requests_toolbelt.multipart.encoder import MultipartEncoder
        
        # Create test data similar to Flutter request
        test_data = {
            'product_name': 'good soul',
            'description': 'test', 
            'price': '28.0',
            'category': 'Electronics',
            'stock_quantity': '2',
            'condition': 'New',
            'is_refurbished': 'false',
            'in_stock': 'true',
            'featured_product': 'true',
            'seller_id': '1',
            'category_id': '1',
            'brand': 'adibas',
            'weight': '5.0',
            'dimensions': '20*15*5'
        }
        
        # Create a dummy image
        dummy_image = io.BytesIO(b"fake image data for testing")
        
        multipart_data = MultipartEncoder(
            fields={
                **test_data,
                'images': ('test.jpg', dummy_image, 'image/jpeg')
            }
        )
        
        url = "http://10.0.2.2:8000/comprehensive-product/"
        headers = {'Content-Type': multipart_data.content_type}
        
        print(f"Making POST request to: {url}")
        print(f"Content-Type: {multipart_data.content_type}")
        
        response = requests.post(url, data=multipart_data, headers=headers, timeout=10)
        
        print(f"✅ Request successful - Status: {response.status_code}")
        print(f"Response: {response.text[:200]}...")
        
    except ImportError:
        print("⚠️  requests-toolbelt not available, using basic POST test")
        
        # Basic POST test
        url = "http://10.0.2.2:8000/comprehensive-product/"
        data = {'test': 'data'}
        
        try:
            response = requests.post(url, data=data, timeout=5)
            print(f"✅ Basic POST successful - Status: {response.status_code}")
        except Exception as e:
            print(f"❌ Basic POST failed: {e}")
            
    except Exception as e:
        print(f"❌ Simulated request failed: {e}")

def main():
    print("🔍 Network Connection Diagnostic Tool")
    print("=" * 50)
    
    test_raw_socket_connection()
    test_server_endpoints() 
    simulate_flutter_request()
    
    print("\n" + "=" * 50)
    print("📋 DIAGNOSTIC SUMMARY:")
    print("If all tests pass: Server is working, issue is in Flutter app")
    print("If socket tests fail: Server is not running or not accessible")
    print("If HTTP tests fail: Server is running but not responding properly")
    print("If multipart test fails: Server has issues with file uploads")

if __name__ == "__main__":
    main()