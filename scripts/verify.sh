#!/bin/bash

echo "Verifying Pipeline Setup"
echo ""

# Check pods
echo "1. Checking pods..."
kubectl get pods -n ecommerce-pipeline

# Check secrets
echo ""
echo "2. Checking secrets..."
kubectl get secrets -n ecommerce-pipeline

# Query database
echo ""
echo "3. Checking raw data..."
POSTGRES_POD=$(kubectl get pod -n ecommerce-pipeline -l app=postgresql -o jsonpath="{.items[0].metadata.name}")

kubectl exec -n ecommerce-pipeline $POSTGRES_POD -- \
  psql -U ecommerceuser -d ecommerce_dw -c "
    SELECT 'products' as table, COUNT(*) as rows FROM raw.products
    UNION ALL
    SELECT 'users', COUNT(*) FROM raw.users
    UNION ALL
    SELECT 'carts', COUNT(*) FROM raw.carts;"

echo ""
echo "4. Checking analytics data..."
kubectl exec -n ecommerce-pipeline $POSTGRES_POD -- \
  psql -U ecommerceuser -d ecommerce_dw -c "
    SELECT 'dim_products' as table, COUNT(*) as rows FROM analytics.dim_products
    UNION ALL
    SELECT 'dim_users', COUNT(*) FROM analytics.dim_users
    UNION ALL
    SELECT 'fct_carts', COUNT(*) FROM analytics.fct_carts;"

echo ""
echo "5. Running data quality tests (sample)..."
echo "(Running subset for quick verification)"
./scripts/run-dbt.sh "test --select dim_products" 2>&1 | tail -3

echo ""
echo "✅ Verification complete!"
echo ""
echo "To run all 19 tests: ./scripts/run-tests.sh"