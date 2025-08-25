import os
from functools import lru_cache

from supabase import Client, create_client
from dotenv import load_dotenv


class SupabaseNotConfigured(Exception):
    pass


@lru_cache(maxsize=1)
def get_supabase() -> Client:
    # load .env if present (no-op on hosts without it)
    here = os.path.dirname(__file__)
    env_path = os.path.join(here, ".env")
    load_dotenv(env_path)
    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or os.environ.get(
        "SUPABASE_ANON_KEY")
    if not url or not key:
        raise SupabaseNotConfigured(
            "Missing SUPABASE_URL and/or SUPABASE_SERVICE_ROLE_KEY/ SUPABASE_ANON_KEY"
        )
    return create_client(url, key)
