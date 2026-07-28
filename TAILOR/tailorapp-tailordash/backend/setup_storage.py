import os
import json
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv()

url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_KEY") or os.environ.get("SUPABASE_KEY")

if not url or not key:
    print("Error: SUPABASE_URL and SUPABASE_KEY/SUPABASE_SERVICE_KEY must be set in .env")
    exit(1)

supabase: Client = create_client(url, key)

bucket_name = 'tailor-images'

def setup_bucket():
    try:
        # Check if bucket already exists
        buckets = supabase.storage.list_buckets()
        bucket_exists = any(b.name == bucket_name for b in buckets)
        
        if not bucket_exists:
            import urllib.request
            import urllib.error
            
            req = urllib.request.Request(
                f"{url}/storage/v1/bucket",
                data=json.dumps({
                    "id": bucket_name,
                    "name": bucket_name,
                    "public": True
                }).encode('utf-8'),
                headers={
                    "apikey": key,
                    "Authorization": f"Bearer {key}",
                    "Content-Type": "application/json"
                },
                method="POST"
            )
            try:
                urllib.request.urlopen(req)
                print(f"Bucket '{bucket_name}' created successfully.")
            except urllib.error.HTTPError as e:
                print(f"Error creating bucket: {e.read().decode('utf-8')}")
        else:
            print(f"Bucket '{bucket_name}' already exists. Skipping creation.")
    except Exception as e:
        print(f"Error checking/creating bucket: {e}")

if __name__ == "__main__":
    setup_bucket()
