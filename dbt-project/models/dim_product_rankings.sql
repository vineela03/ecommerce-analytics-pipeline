WITH product_metrics AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.price,
        p.avg_rating,
        p.rating_count,
        p.price * p.rating_count as revenue_potential,
        AVG(p.price) OVER (PARTITION BY p.category) as category_avg_price,
        AVG(p.avg_rating) OVER (PARTITION BY p.category) as category_avg_rating
    FROM {{ ref('dim_products') }} p
),

rankings AS (
    SELECT
        product_id,
        product_name,
        category,
        price,
        avg_rating,
        rating_count,
        revenue_potential,
        -- Price positioning
        CASE
            WHEN price > category_avg_price THEN 'Premium'
            WHEN price < category_avg_price THEN 'Budget'
            ELSE 'Average'
        END as price_tier,
        -- Rating classification
        CASE
            WHEN avg_rating >= 4.5 THEN 'Excellent'
            WHEN avg_rating >= 4.0 THEN 'Good'
            WHEN avg_rating >= 3.5 THEN 'Average'
            ELSE 'Below Average'
        END as rating_tier,
        -- Rankings within category
        ROW_NUMBER() OVER (
            PARTITION BY category 
            ORDER BY avg_rating DESC, rating_count DESC
        ) as category_rank_by_rating,
        ROW_NUMBER() OVER (
            PARTITION BY category 
            ORDER BY price DESC
        ) as category_rank_by_price,
        -- Overall ranking
        ROW_NUMBER() OVER (
            ORDER BY avg_rating DESC, rating_count DESC
        ) as overall_rank_by_rating,
        ROUND((price - category_avg_price) / NULLIF(category_avg_price, 0) * 100, 2) as price_diff_pct
    FROM product_metrics
)

SELECT
    product_id,
    product_name,
    category,
    price,
    avg_rating,
    rating_count,
    price_tier,
    rating_tier,
    category_rank_by_rating,
    category_rank_by_price,
    overall_rank_by_rating,
    price_diff_pct,
    ROUND(revenue_potential, 2) as revenue_potential,
    CURRENT_TIMESTAMP as updated_at
FROM rankings
ORDER BY overall_rank_by_rating