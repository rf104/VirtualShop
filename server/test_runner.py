"""
Simple test runner for the product upload system
"""
import asyncio
import sys
import os

# Add current directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

async def main():
    print("🧪 Running Product Upload System Tests")
    print("=" * 50)
    
    try:
        # Test 1: Database connection and schema
        print("\n1. Testing database connection and schema...")
        from schema_checker import test_database_connection, check_and_update_schema
        
        if await test_database_connection():
            print("✅ Database connection successful")
            await check_and_update_schema()
            print("✅ Schema check completed")
        else:
            print("❌ Database connection failed")
            return False
        
        # Test 2: Import all modules to check for errors
        print("\n2. Testing module imports...")
        try:
            from main import app
            print("✅ Main app module imported successfully")
            
            from routers.comprehensive_product import router
            print("✅ Comprehensive product router imported successfully")
            
            from services.embedding_service import embedding_service
            print("✅ Embedding service imported successfully")
            
        except Exception as e:
            print(f"❌ Module import failed: {e}")
            return False
        
        print("\n✅ All tests passed! The system is ready to use.")
        print("\nNext steps:")
        print("1. Start the server: python start_server.py")
        print("2. Test API: python test_comprehensive_product.py")
        print("3. Run Flutter app and test product creation")
        
        return True
        
    except Exception as e:
        print(f"❌ Test failed: {e}")
        return False

if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)