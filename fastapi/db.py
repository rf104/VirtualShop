import asyncpg
import logging

# --- Logging Setup ---
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# --- Global Pool ---
pool = None

# --- Supabase Connection Details ---
SUPABASE_URL = "postgresql://postgres.wnaqfhqvghulydvnpcsw:01769041694@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres?sslmode=require"

async def get_db_connection_pool():
    """
    Initializes the global asyncpg connection pool to Supabase.
    """
    global pool
    try:
        pool = await asyncpg.create_pool(
            SUPABASE_URL,
            statement_cache_size=0  # 👈 Fix for pgbouncer conflict
        )
        logger.info("✅ Supabase connection pool created successfully.")
    except Exception as e:
        logger.error(f"❌ Failed to create Supabase connection pool: {e}")
        raise

async def get_db_pool():
    """
    Returns the global connection pool.
    """
    return pool
