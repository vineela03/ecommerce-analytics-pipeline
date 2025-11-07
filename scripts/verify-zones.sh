#!/bin/bash

echo "🔍 Verifying Data Lake Zones"
echo ""

POSTGRES_POD=$(kubectl get pod -n ecommerce-pipeline -l app=postgresql -o jsonpath="{.items[0].metadata.name}")

echo "1. Staging Zone (PostgreSQL raw schema)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl exec -n ecommerce-pipeline $POSTGRES_POD -- \
  psql -U ecommerceuser -d ecommerce_dw -c "
    SELECT 
      'raw.products' as table,
      COUNT(*) as records
    FROM raw.products
    UNION ALL
    SELECT 'raw.users', COUNT(*) FROM raw.users
    UNION ALL
    SELECT 'raw.carts', COUNT(*) FROM raw.carts;
  "

echo ""
echo "2. Analytics Zone (PostgreSQL analytics schema)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl exec -n ecommerce-pipeline $POSTGRES_POD -- \
  psql -U ecommerceuser -d ecommerce_dw -c "
    SELECT 
      'analytics.dim_products' as table,
      COUNT(*) as records
    FROM analytics.dim_products
    UNION ALL
    SELECT 'analytics.dim_users', COUNT(*) FROM analytics.dim_users
    UNION ALL
    SELECT 'analytics.fct_carts', COUNT(*) FROM analytics.fct_carts
    UNION ALL
    SELECT 'analytics.fct_daily_sales', COUNT(*) FROM analytics.fct_daily_sales
    UNION ALL
    SELECT 'analytics.dim_user_segments', COUNT(*) FROM analytics.dim_user_segments
    UNION ALL
    SELECT 'analytics.fct_category_performance', COUNT(*) FROM analytics.fct_category_performance
    UNION ALL
    SELECT 'analytics.dim_product_rankings', COUNT(*) FROM analytics.dim_product_rankings;
  "

echo ""
echo "3. Minio Buckets"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
MINIO_POD=$(kubectl get pod -n ecommerce-pipeline -l app=minio -o jsonpath="{.items[0].metadata.name}")

echo "Raw Zone:"
kubectl exec -n ecommerce-pipeline $MINIO_POD -- \
  sh -c 'mc alias set local http://localhost:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD 2>/dev/null && mc ls local/raw-zone/ --recursive' || echo "  (bucket empty or not configured)"

echo ""
echo "Curated Zone:"
kubectl exec -n ecommerce-pipeline $MINIO_POD -- \
  sh -c 'mc alias set local http://localhost:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD 2>/dev/null && mc ls local/curated-zone/ --recursive' || echo "  (bucket empty or not configured)"

echo ""
echo "✅ Verification Complete!"