"""
database.py — Supabase client for TailorSystem backend.

Replaces the old mysql.connector setup.
Uses the Supabase Python SDK (supabase-py) with the SERVICE_ROLE key
so the Flask backend can bypass RLS and do anything.

Install:  pip install supabase
"""
import os

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

from supabase import create_client, Client as SupabaseClient

SUPABASE_URL = os.environ.get('SUPABASE_URL', '')
SUPABASE_SERVICE_KEY = os.environ.get('SUPABASE_SERVICE_KEY', '')

# Singleton client — created once, reused for all requests
_client: SupabaseClient | None = None


def get_client() -> SupabaseClient:
    """Return the shared Supabase service-role client."""
    global _client
    if _client is None:
        if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
            raise RuntimeError(
                'SUPABASE_URL and SUPABASE_SERVICE_KEY must be set in your .env file.'
            )
        _client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
    return _client

_anon_client: SupabaseClient | None = None
def get_anon_client() -> SupabaseClient:
    """Return an anon client for authentication to avoid mutating the service role client."""
    global _anon_client
    if _anon_client is None:
        anon_key = os.environ.get('SUPABASE_ANON_KEY', '')
        _anon_client = create_client(SUPABASE_URL, anon_key)
    return _anon_client


def sb_select(table: str, filters: dict | None = None, select: str = '*') -> list:
    """
    SELECT rows from a Supabase table.
    filters: {column: value, ...} — all applied as equality (eq) filters.
    Returns a list of dicts (one per row), or [] on error.
    """
    try:
        q = get_client().table(table).select(select)
        if filters:
            for col, val in filters.items():
                q = q.eq(col, val)
        result = q.execute()
        return result.data or []
    except Exception as e:
        print(f'[Supabase SELECT error] table={table} filters={filters}: {e}')
        return []


def sb_insert(table: str, data: dict) -> dict:
    """
    INSERT a row and return the inserted row as a dict.
    Returns {} on error.
    """
    try:
        result = get_client().table(table).insert(data).execute()
        return result.data[0] if result.data else {}
    except Exception as e:
        print(f'[Supabase INSERT error] table={table}: {e}')
        return {}


def sb_update(table: str, data: dict, filters: dict) -> dict:
    """
    UPDATE rows matching filters and return the first updated row.
    Returns {} on error.
    """
    try:
        q = get_client().table(table).update(data)
        for col, val in filters.items():
            q = q.eq(col, val)
        result = q.execute()
        return result.data[0] if result.data else {}
    except Exception as e:
        print(f'[Supabase UPDATE error] table={table}: {e}')
        return {}


def sb_delete(table: str, filters: dict) -> bool:
    """
    DELETE rows matching filters.
    Returns True on success, False on error.
    """
    try:
        q = get_client().table(table).delete()
        for col, val in filters.items():
            q = q.eq(col, val)
        q.execute()
        return True
    except Exception as e:
        print(f'[Supabase DELETE error] table={table}: {e}')
        return False


def sb_auth_sign_up(email: str, password: str, metadata: dict | None = None):
    """
    Register a new user via Supabase Auth.
    Supabase will send a verification email automatically.
    Returns the Supabase AuthResponse.
    """
    client = get_anon_client()
    return client.auth.sign_up({
        'email': email,
        'password': password,
        'options': {'data': metadata or {}},
    })


def sb_auth_sign_in(email: str, password: str):
    """
    Log in an existing user via Supabase Auth.
    Returns the Supabase AuthResponse (contains session + user).
    """
    client = get_anon_client()
    return client.auth.sign_in_with_password({'email': email, 'password': password})


def sb_auth_get_user(jwt: str):
    """
    Verify a JWT and return the Supabase User object.
    Used to authenticate requests from the Flutter app.
    """
    client = get_anon_client()
    return client.auth.get_user(jwt)
