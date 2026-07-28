import os
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()
url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_KEY")
client = create_client(url, key)

try:
    print("Testing active orders...")
    res_active = client.table('orders').select('*').eq('tailor_id', '00000000-0000-0000-0000-000000000000').neq('status', 'completed').neq('status', 'cancelled').execute()
    print("Success:", res_active.data)
except Exception as e:
    print("Error 1:", e)

try:
    print("Testing recent orders...")
    res_recent = client.table('orders').select('*, customer:customers(*)').eq('tailor_id', '00000000-0000-0000-0000-000000000000').order('created_at', desc=True).limit(5).execute()
    print("Success:", res_recent.data)
except Exception as e:
    print("Error 2:", type(e).__name__, getattr(e, 'message', str(e)), getattr(e, 'details', ''))
