import os

# Get environment variables with clear error messages
def get_env(name, required=True):
    value = os.getenv(name)
    if required and not value:
        raise ValueError(f"Missing required environment variable: {name}")
    return value

# API Configuration
API_URL = "https://fakestoreapi.com"

# Minio Configuration
MINIO_HOST = get_env("MINIO_HOST", required=False) or "minio-service.ecommerce-pipeline.svc.cluster.local:9000"
MINIO_USER = get_env("MINIO_USER")
MINIO_PASSWORD = get_env("MINIO_PASSWORD")
MINIO_BUCKET = "ecommerce-raw"

# PostgreSQL Configuration
POSTGRES_HOST = get_env("POSTGRES_HOST", required=False) or "postgresql-service.ecommerce-pipeline.svc.cluster.local"
POSTGRES_USER = get_env("POSTGRES_USER")
POSTGRES_PASSWORD = get_env("POSTGRES_PASSWORD")
POSTGRES_DB = get_env("POSTGRES_DB")