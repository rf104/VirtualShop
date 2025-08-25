"""
Startup script for the E-Commerce API server
"""
import uvicorn
import asyncio
import sys
import os

# Add the current directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

async def run_schema_checker():
    """Run the schema checker before starting the server"""
    print("🔧 Checking database schema...")
    try:
        from schema_checker import check_and_update_schema, test_database_connection
        
        if await test_database_connection():
            await check_and_update_schema()
            print("✅ Schema check completed!")
            return True
        else:
            print("❌ Database connection failed!")
            return False
    except Exception as e:
        print(f"❌ Schema check failed: {e}")
        return False

def main():
    """Main function to start the server"""
    print("🚀 Starting E-Commerce API Server...")
    print("=" * 50)
    
    # Run schema checker
    if asyncio.run(run_schema_checker()):
        print("\n🌐 Starting FastAPI server...")
        print("   - Host: 0.0.0.0 (accepts connections from Android emulator)")
        print("   - Port: 8000")
        print("   - Reload: enabled")
        print()
        print("📱 Android emulator will connect to: http://10.0.2.2:8000")
        print("🖥️  Desktop/iOS will connect to: http://127.0.0.1:8000")
        print("🌐 API docs available at: http://127.0.0.1:8000/docs")
        print()
        print("Press Ctrl+C to stop the server")
        print("=" * 60)
        
        uvicorn.run(
            "main:app",
            host="0.0.0.0",  # Changed from 127.0.0.1 to accept emulator connections
            port=8000,
            reload=True,
            log_level="info"
        )
    else:
        print("❌ Cannot start server due to database issues.")
        sys.exit(1)

if __name__ == "__main__":
    main()