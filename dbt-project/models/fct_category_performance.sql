WITH product_stats AS (
    SELECT
        category,
        COUNT(DISTINCT product_id) as product_count,
        AVG(price) as avg_price,
        MIN(price) as min_price,
        MAX(price) as max_price,
        AVG(avg_rating) as avg_category_rating,
        SUM(rating_count) as total_ratings
    FROM {{ ref('dim_products') }}
    GROUP BY category
),

category_sales AS (
    SELECT
        p.category,
        COUNT(DISTINCT c.cart_id) as times_in_carts,
        COUNT(DISTINCT c.user_id) as unique_customers
    FROM {{ ref('dim_products') }} p
    CROSS JOIN {{ source('raw', 'carts') }} raw_carts
    INNER JOIN {{ ref('fct_carts') }} c ON c.cart_id = raw_carts.id
    WHERE raw_carts.products::TEXT LIKE '%"productId":' || p.product_id || '%'
    GROUP BY p.category
)

SELECT
    ps.category,
    ps.product_count,
    ROUND(ps.avg_price, 2) as avg_price,
    ROUND(ps.min_price, 2) as min_price,
    ROUND(ps.max_price, 2) as max_price,
    ROUND(ps.avg_category_rating, 2) as avg_rating,
    ps.total_ratings,
    COALESCE(cs.times_in_carts, 0) as times_in_carts,
    COALESCE(cs.unique_customers, 0) as unique_customers,
    CURRENT_TIMESTAMP as updated_at
FROM product_stats ps
LEFT JOIN category_sales cs ON ps.category = cs.category
ORDER BY times_in_carts DESC