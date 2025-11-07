import os
import json
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
MINIO_CURATED_BUCKET = "curated-zone"

def create_minio_client():
    """Create Minio client"""
    print(f"📦 Connecting to Minio at {MINIO_ENDPOINT}")
    return Minio(
        MINIO_ENDPOINT,
        access_key=MINIO_USER,
        secret_key=MINIO_PASSWORD,
        secure=False
    )

def ensure_bucket(minio_client):
    """Ensure curated bucket exists"""
    if not minio_client.bucket_exists(MINIO_CURATED_BUCKET):
        minio_client.make_bucket(MINIO_CURATED_BUCKET)
        print(f"✅ Created bucket: {MINIO_CURATED_BUCKET}")
    else:
        print(f"✅ Bucket exists: {MINIO_CURATED_BUCKET}")

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

def export_table(minio_client, conn, table_name, query):
    """Export analytics table to curated zone"""
    cur = conn.cursor()
    
    try:
        cur.execute(query)
        columns = [desc[0] for desc in cur.description]
        data = [dict(zip(columns, row)) for row in cur.fetchall()]
        
        if data:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            content = json.dumps(data, indent=2, default=str).encode('utf-8')
            content_stream = BytesIO(content)
            
            object_name = f"{table_name}/{timestamp}.json"
            minio_client.put_object(
                MINIO_CURATED_BUCKET,
                object_name,
                content_stream,
                len(content),
                content_type='application/json'
            )
            print(f"✅ Exported {len(data)} records to {MINIO_CURATED_BUCKET}/{object_name}")
            return len(data)
        else:
            print(f"⚠️  No data found in {table_name}")
            return 0
    except Exception as e:
        print(f"⚠️  Could not export {table_name}: {e}")
        return 0
    finally:
        cur.close()

def main():
    """Export curated data workflow"""
    print("=" * 60)
    print("📤 Starting Curated Zone Export")
    print("=" * 60)
    
    # Initialize connections
    minio_client = create_minio_client()
    ensure_bucket(minio_client)
    conn = create_postgres_connection()
    
    # Export tables
    exports = {
        'dim_products': """
            SELECT 
                product_id, product_name, category, price, description,
                avg_rating, rating_count, updated_at
            FROM analytics.dim_products
        """,
        'dim_users': """
            SELECT 
                user_id, full_name, email, city, username, updated_at
            FROM analytics.dim_users
        """,
        'dim_user_segments': """
            SELECT 
                user_id, full_name, city, email, user_segment,
                rfm_total_score, recency_score, frequency_score, monetary_score,
                total_carts, total_items_purchased, days_since_last_cart, updated_at
            FROM analytics.dim_user_segments
        """,
        'fct_carts': """
            SELECT 
                cart_id, user_id, cart_date, total_items, updated_at
            FROM analytics.fct_carts
        """,
        'fct_daily_sales': """
            SELECT 
                sale_date, total_carts, unique_customers, total_items_sold,
                avg_items_per_cart, avg_carts_per_customer, updated_at
            FROM analytics.fct_daily_sales
            ORDER BY sale_date DESC
        """,
        'fct_category_performance': """
            SELECT 
                category, product_count, avg_price, min_price, max_price,
                avg_rating, total_ratings, times_in_carts, unique_customers, updated_at
            FROM analytics.fct_category_performance
        """,
        'dim_product_rankings': """
            SELECT 
                product_id, product_name, category, price, avg_rating, rating_count,
                price_tier, rating_tier, category_rank_by_rating,
                overall_rank_by_rating, price_diff_pct, revenue_potential, updated_at
            FROM analytics.dim_product_rankings
        """
    }
    
    print("\n📤 Exporting Analytics Tables to Curated Zone")
    print("-" * 60)
    
    total_records = 0
    for table_name, query in exports.items():
        count = export_table(minio_client, conn, table_name, query)
        total_records += count
    
    conn.close()
    
    print("\n" + "=" * 60)
    print(f"✅ Export Complete! {total_records} total records exported")
    print("=" * 60)

if __name__ == "__main__":
    main()