#!/bin/bash

echo "📊 Running Analytics Queries"
echo ""

POSTGRES_POD=$(kubectl get pod -n ecommerce-pipeline -l app=postgresql -o jsonpath="{.items[0].metadata.name}")

echo "1. User Segmentation Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl exec -n ecommerce-pipeline $POSTGRES_POD -- \
  psql -U ecommerceuser -d ecommerce_dw -c "
    SELECT 
      user_segment,
      COUNT(*) as user_count,
      ROUND(AVG(rfm_total_score), 2) as avg_score,
      ROUND(AVG(total_carts), 2) as avg_carts
    FROM analytics.dim_user_segments
    GROUP BY user_segment
    ORDER BY user_count DESC;
  "

echo ""
echo "2. Category Performance Rankings"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl exec -n ecommerce-pipeline $POSTGRES_POD -- \
  psql -U ecommerceuser -d ecommerce_dw -c "
    SELECT 
      category,
      product_count,
      avg_price,
      avg_rating,
      times_in_carts
    FROM analytics.fct_category_performance
    ORDER BY times_in_carts DESC;
  "

echo ""
echo "3. Top 10 Products by Rating"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl exec -n ecommerce-pipeline $POSTGRES_POD -- \
  psql -U ecommerceuser -d ecommerce_dw -c "
    SELECT 
      overall_rank_by_rating,
      product_name,
      category,
      price,
      avg_rating,
      rating_tier,
      price_tier
    FROM analytics.dim_product_rankings
    WHERE overall_rank_by_rating <= 10
    ORDER BY overall_rank_by_rating;
  "

echo ""
echo "4. Daily Sales Trends"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl exec -n ecommerce-pipeline $POSTGRES_POD -- \
  psql -U ecommerceuser -d ecommerce_dw -c "
    SELECT 
      sale_date,
      total_carts,
      unique_customers,
      total_items_sold,
      avg_items_per_cart
    FROM analytics.fct_daily_sales
    ORDER BY sale_date DESC
    LIMIT 7;
  "

echo ""
echo "✅ Analysis complete!"