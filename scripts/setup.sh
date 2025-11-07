#!/bin/bash
set -e

echo "🚀 Setting up E-Commerce Pipeline"
echo ""

# Create cluster
echo "1. Creating k3d cluster..."
k3d cluster create pipeline --agents 2 2>/dev/null || echo "   Cluster already exists"

# Apply namespace
echo "2. Creating namespace..."
kubectl apply -f kubernetes/namespace.yaml

# Create secrets
echo "3. Creating secrets..."
kubectl create secret generic postgres-secret \
  --from-literal=user=ecommerceuser \
  --from-literal=password=SecurePass123 \
  --from-literal=database=ecommerce_dw \
  -n ecommerce-pipeline \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic minio-secret \
  --from-literal=user=minioadmin \
  --from-literal=password=MinioPass123 \
  -n ecommerce-pipeline \
  --dry-run=client -o yaml | kubectl apply -f -

# Deploy infrastructure
echo "4. Deploying Minio..."
kubectl apply -f kubernetes/minio.yaml

echo "5. Deploying PostgreSQL..."
kubectl apply -f kubernetes/postgresql.yaml

# Wait for pods
echo "6. Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=minio -n ecommerce-pipeline --timeout=120s
kubectl wait --for=condition=ready pod -l app=postgresql -n ecommerce-pipeline --timeout=120s

# Build images
echo "7. Building data-export image..."
docker build -t data-export:latest data-export/ -q

echo "8. Building dbt image..."
docker build -t dbt:latest dbt-project/ -q

# Import to k3d
echo "9. Importing images to k3d..."
k3d image import data-export:latest -c pipeline
k3d image import dbt:latest -c pipeline

echo ""
echo "✅ Setup Complete!"
echo ""
echo "Next steps:"
echo "  ./scripts/load-data.sh      # Load data"
echo "  ./scripts/transform-data.sh # Transform with dbt"