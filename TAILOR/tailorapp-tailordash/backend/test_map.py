import os
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()
url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_KEY")
client = create_client(url, key)

try:
    print("Testing map tailors...")
    res = client.table('tailors').select('*').execute()
    print("Success:", len(res.data))
except Exception as e:
    print("Error:", type(e).__name__, getattr(e, 'message', str(e)), getattr(e, 'details', ''))
