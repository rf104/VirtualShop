import requests
import json
import os

def test_comprehensive_product_api():
    """Test the comprehensive product API endpoint"""
    
    # API endpoint
    url = "http://127.0.0.1:8000/comprehensive-product/"
    
    # Test data
    product_data = {
        'product_name': 'Test Product',
        'description': 'This is a test product description',
        'price': '99.99',
        'category': 'Electronics',
        'stock_quantity': '10',
        'condition': 'New',
        'brand': 'Test Brand',
        'weight': '1.5',
        'dimensions': '20 x 15 x 10',
        'is_refurbished': 'false',
        'in_stock': 'true',
        'featured_product': 'false',
        'seller_id': '1',
        'category_id': '1',
    }
    
    # Test image (create a small test image file)
    test_image_path = 'test_image.jpg'
    
    # Create a simple test image if it doesn't exist
    if not os.path.exists(test_image_path):
        from PIL import Image
        import io
        
        # Create a simple 100x100 red image
        img = Image.new('RGB', (100, 100), color='red')
        img.save(test_image_path, 'JPEG')
    
    try:
        # Prepare files
        with open(test_image_path, 'rb') as f:
            files = {'images': f}
            
            # Make the request
            response = requests.post(url, data=product_data, files=files)
            
            print(f"Status Code: {response.status_code}")
            print(f"Response: {json.dumps(response.json(), indent=2)}")
            
            if response.status_code == 200:
                print("✅ Product created successfully!")
            else:
                print("❌ Failed to create product")
                
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Clean up test image
    if os.path.exists(test_image_path):
        os.remove(test_image_path)

def test_get_products():
    """Test getting all products"""
    url = "http://127.0.0.1:8000/comprehensive-product/"
    
    try:
        response = requests.get(url)
        print(f"Get Products Status Code: {response.status_code}")
        
        if response.status_code == 200:
            products = response.json()
            print(f"✅ Found {len(products)} products")
            if products:
                print("First product:", json.dumps(products[0], indent=2))
        else:
            print("❌ Failed to get products")
            print(response.text)
            
    except Exception as e:
        print(f"❌ Error getting products: {e}")

if __name__ == "__main__":
    print("🔍 Testing Comprehensive Product API...")
    print("=" * 50)
    
    print("\n1. Testing Product Creation:")
    test_comprehensive_product_api()
    
    print("\n2. Testing Get All Products:")
    test_get_products()
    
    print("\n" + "=" * 50)
    print("✅ Test completed!")