import asyncio
import asyncpg
import os

SUPABASE_URL = "postgresql://postgres.wnaqfhqvghulydvnpcsw:01769041694@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres?sslmode=require"

async def check_and_update_schema():
    """
    Check if the product table has all required fields and add them if missing.
    """
    try:
        conn = await asyncpg.connect(SUPABASE_URL)
        
        print("🔍 Checking current product table schema...")
        
        # Get current table schema
        result = await conn.fetch("""
            SELECT column_name, data_type, is_nullable 
            FROM information_schema.columns 
            WHERE table_name = 'product' AND table_schema = 'public'
            ORDER BY ordinal_position;
        """)
        
        print("Current product table columns:")
        existing_columns = set()
        for row in result:
            print(f"  - {row['column_name']}: {row['data_type']} ({'NULL' if row['is_nullable'] == 'YES' else 'NOT NULL'})")
            existing_columns.add(row['column_name'])
        
        # Define required additional columns
        required_columns = {
            'category': 'VARCHAR',
            'brand': 'VARCHAR',
            'stock_quantity': 'INTEGER',
            'condition': 'VARCHAR',
            'weight': 'FLOAT',
            'dimensions': 'VARCHAR',
            'in_stock': 'BOOLEAN',
            'featured_product': 'BOOLEAN',
        }
        
        # Check which columns need to be added
        missing_columns = []
        for col_name, col_type in required_columns.items():
            if col_name not in existing_columns:
                missing_columns.append((col_name, col_type))
        
        if missing_columns:
            print(f"\n📝 Adding {len(missing_columns)} missing columns...")
            
            for col_name, col_type in missing_columns:
                try:
                    if col_type == 'BOOLEAN':
                        await conn.execute(f"ALTER TABLE product ADD COLUMN {col_name} {col_type} DEFAULT FALSE;")
                    elif col_type == 'INTEGER':
                        await conn.execute(f"ALTER TABLE product ADD COLUMN {col_name} {col_type} DEFAULT 0;")
                    elif col_type == 'FLOAT':
                        await conn.execute(f"ALTER TABLE product ADD COLUMN {col_name} REAL;")
                    else:
                        await conn.execute(f"ALTER TABLE product ADD COLUMN {col_name} {col_type};")
                    
                    print(f"  ✅ Added column: {col_name} ({col_type})")
                except Exception as e:
                    print(f"  ❌ Failed to add column {col_name}: {e}")
        else:
            print("\n✅ All required columns already exist!")
        
        # Show final schema
        print("\n🔍 Final product table schema:")
        result = await conn.fetch("""
            SELECT column_name, data_type, is_nullable 
            FROM information_schema.columns 
            WHERE table_name = 'product' AND table_schema = 'public'
            ORDER BY ordinal_position;
        """)
        
        for row in result:
            print(f"  - {row['column_name']}: {row['data_type']} ({'NULL' if row['is_nullable'] == 'YES' else 'NOT NULL'})")
        
        await conn.close()
        print("\n✅ Schema check completed!")
        
    except Exception as e:
        print(f"❌ Error checking schema: {e}")

async def test_database_connection():
    """Test the database connection"""
    try:
        conn = await asyncpg.connect(SUPABASE_URL)
        result = await conn.fetchval("SELECT version();")
        print(f"✅ Database connected successfully!")
        print(f"PostgreSQL version: {result}")
        await conn.close()
        return True
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        return False

async def main():
    print("🚀 Database Schema Checker")
    print("=" * 50)
    
    # Test connection first
    if await test_database_connection():
        await check_and_update_schema()
    else:
        print("Cannot proceed without database connection.")

if __name__ == "__main__":
    asyncio.run(main())