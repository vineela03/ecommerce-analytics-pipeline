-- Simplified version without incremental
WITH daily_carts AS (
    SELECT
        DATE(cart_date) as sale_date,
        COUNT(DISTINCT cart_id) as total_carts,
        COUNT(DISTINCT user_id) as unique_customers,
        SUM(total_items) as total_items_sold
    FROM {{ ref('fct_carts') }}
    GROUP BY DATE(cart_date)
)

SELECT
    sale_date,
    total_carts,
    unique_customers,
    total_items_sold,
    ROUND(total_items_sold::NUMERIC / NULLIF(total_carts, 0), 2) as avg_items_per_cart,
    ROUND(total_carts::NUMERIC / NULLIF(unique_customers, 0), 2) as avg_carts_per_customer,
    CURRENT_TIMESTAMP as updated_at
FROM daily_carts
ORDER BY sale_date DESC
