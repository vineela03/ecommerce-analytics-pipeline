import os
import json
import requests
import psycopg2
from minio import Minio
from io import BytesIO
from datetime import datetime

# Environment variables
POSTGRES_USER = os.getenv("POSTGRES_USER", "ecommerceuser")
POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD")
POSTGRES_HOST = os.getenv("POSTGRES_HOST", "postgresql-service.ecommerce-pipeline.svc.cluster.local")
POSTGRES_PORT = os.getenv("POSTGRES_PORT", "5432")
POSTGRES_DB = os.getenv("POSTGRES_DB", "ecommerce_dw")

MINIO_ENDPOINT = os.getenv("MINIO_ENDPOINT", "minio-service.ecommerce-pipeline.svc.cluster.local:9000")
MINIO_USER = os.getenv("MINIO_USER", "minioadmin")
MINIO_PASSWORD = os.getenv("MINIO_PASSWORD")
MINIO_RAW_BUCKET = "raw-zone"
MINIO_CURATED_BUCKET = "curated-zone"

API_BASE_URL = "https://fakestoreapi.com"

def validate_env_vars():
    """Validate required environment variables"""
    required_vars = {
        "POSTGRES_PASSWORD": POSTGRES_PASSWORD,
        "MINIO_PASSWORD": MINIO_PASSWORD
    }
    
    missing = [var for var, val in required_vars.items() if not val]
    if missing:
        raise ValueError(f"Missing required environment variables: {', '.join(missing)}")

def create_minio_client():
    """Create Minio client"""
    print(f"📦 Connecting to Minio at {MINIO_ENDPOINT}")
    return Minio(
        MINIO_ENDPOINT,
        access_key=MINIO_USER,
        secret_key=MINIO_PASSWORD,
        secure=False
    )

def ensure_buckets(minio_client):
    """Ensure Minio buckets exist"""
    for bucket in [MINIO_RAW_BUCKET, MINIO_CURATED_BUCKET]:
        if not minio_client.bucket_exists(bucket):
            minio_client.make_bucket(bucket)
            print(f"✅ Created bucket: {bucket}")
        else:
            print(f"✅ Bucket exists: {bucket}")

def fetch_api_data(endpoint):
    """Fetch data from API"""
    url = f"{API_BASE_URL}/{endpoint}"
    print(f"🌐 Fetching: {url}")
    response = requests.get(url, timeout=30)
    response.raise_for_status()
    data = response.json()
    print(f"✅ Fetched {len(data)} records from {endpoint}")
    return data

def upload_to_raw_zone(minio_client, name, data):
    """Upload JSON data to raw zone in Minio"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    object_name = f"{name}/{timestamp}.json"
    
    content = json.dumps(data, indent=2).encode('utf-8')
    content_stream = BytesIO(content)
    
    minio_client.put_object(
        MINIO_RAW_BUCKET,
        object_name,
        content_stream,
        len(content),
        content_type='application/json'
    )
    print(f"✅ Uploaded to raw zone: {MINIO_RAW_BUCKET}/{object_name}")

def create_postgres_connection():
    """Create PostgreSQL connection"""
    print(f"🐘 Connecting to PostgreSQL at {POSTGRES_HOST}")
    return psycopg2.connect(
        host=POSTGRES_HOST,
        port=POSTGRES_PORT,
        database=POSTGRES_DB,
        user=POSTGRES_USER,
        password=POSTGRES_PASSWORD
    )

def setup_database(conn):
    """Setup raw schema and tables"""
    cur = conn.cursor()
    
    # Create raw schema
    cur.execute("CREATE SCHEMA IF NOT EXISTS raw;")
    
    # Create products table
    cur.execute("""
        CREATE TABLE IF NOT EXISTS raw.products (
            id INTEGER PRIMARY KEY,
            title TEXT,
            price NUMERIC,
            description TEXT,
            category TEXT,
            image TEXT,
            rating JSONB,
            loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    """)
    
    # Create users table
    cur.execute("""
        CREATE TABLE IF NOT EXISTS raw.users (
            id INTEGER PRIMARY KEY,
            email TEXT,
            username TEXT,
            password TEXT,
            name JSONB,
            address JSONB,
            phone TEXT,
            loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    """)
    
    # Create carts table
    cur.execute("""
        CREATE TABLE IF NOT EXISTS raw.carts (
            id INTEGER PRIMARY KEY,
            userId INTEGER,
            date TIMESTAMP,
            products JSONB,
            loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    """)
    
    conn.commit()
    cur.close()
    print("✅ Database schema ready")

def load_data_to_staging(conn, table_name, data):
    """Load data from raw zone to staging (PostgreSQL raw schema)"""
    cur = conn.cursor()
    
    # Clear existing data
    cur.execute(f"TRUNCATE TABLE raw.{table_name};")
    
    if table_name == 'products':
        for item in data:
            cur.execute("""
                INSERT INTO raw.products (id, title, price, description, category, image, rating)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (
                item['id'],
                item['title'],
                item['price'],
                item['description'],
                item['category'],
                item['image'],
                json.dumps(item['rating'])
            ))
    
    elif table_name == 'users':
        for item in data:
            cur.execute("""
                INSERT INTO raw.users (id, email, username, password, name, address, phone)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (
                item['id'],
                item['email'],
                item['username'],
                item['password'],
                json.dumps(item['name']),
                json.dumps(item['address']),
                item['phone']
            ))
    
    elif table_name == 'carts':
        for item in data:
            cur.execute("""
                INSERT INTO raw.carts (id, userId, date, products)
                VALUES (%s, %s, %s, %s)
            """, (
                item['id'],
                item['userId'],
                item['date'],
                json.dumps(item['products'])
            ))
    
    conn.commit()
    cur.close()
    print(f"✅ Loaded {len(data)} records to raw.{table_name}")

def main():
    """Main ETL workflow"""
    print("=" * 60)
    print("🚀 Starting Data Lake ETL Workflow")
    print("=" * 60)
    
    # Validate environment
    validate_env_vars()
    
    # Initialize connections
    minio_client = create_minio_client()
    ensure_buckets(minio_client)
    
    # Phase 1: API → Raw Zone (Minio)
    print("\n📥 PHASE 1: API → Raw Zone (Minio)")
    print("-" * 60)
    
    endpoints = {
        'products': 'products',
        'users': 'users', 
        'carts': 'carts'
    }
    
    raw_data = {}
    for name, endpoint in endpoints.items():
        data = fetch_api_data(endpoint)
        upload_to_raw_zone(minio_client, name, data)
        raw_data[name] = data
    
    # Phase 2: Raw Zone → Staging (PostgreSQL)
    print("\n📥 PHASE 2: Raw Zone → Staging (PostgreSQL)")
    print("-" * 60)
    
    conn = create_postgres_connection()
    setup_database(conn)
    
    for table_name, data in raw_data.items():
        load_data_to_staging(conn, table_name, data)
    
    conn.close()
    
    print("\n" + "=" * 60)
    print("✅ ETL Workflow Complete!")
    print("=" * 60)
    print("\nNext steps:")
    print("1. Run dbt transformations: ./scripts/transform-data.sh")
    print("2. Run data quality tests: ./scripts/run-tests.sh")
    print("3. Export to curated zone: ./scripts/export-curated.sh")

if __name__ == "__main__":
    main()