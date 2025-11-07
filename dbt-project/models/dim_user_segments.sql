-- Uses macros: calculate_rfm_score(), generate_timestamp_column()

WITH user_activity AS (
    SELECT
        u.user_id,
        u.full_name,
        u.city,
        u.email,
        COUNT(c.cart_id) as total_carts,
        MAX(c.cart_date) as last_cart_date,
        MIN(c.cart_date) as first_cart_date,
        SUM(c.total_items) as total_items_purchased,
        CURRENT_DATE - MAX(DATE(c.cart_date)) as days_since_last_cart
    FROM {{ ref('dim_users') }} u
    LEFT JOIN {{ ref('fct_carts') }} c ON u.user_id = c.user_id
    GROUP BY u.user_id, u.full_name, u.city, u.email
),

rfm_scores AS (
    SELECT
        user_id,
        full_name,
        city,
        email,
        total_carts,
        last_cart_date,
        first_cart_date,
        total_items_purchased,
        days_since_last_cart,
        
        -- Using macro for recency score (DRY principle)
        {{ calculate_rfm_score('days_since_last_cart', [(7, 5), (30, 4), (90, 3), (180, 2)], 'recency_score') }},
        
        -- Using macro for frequency score
        {{ calculate_rfm_score('total_carts', [(5, 5), (4, 4), (3, 3), (2, 2)], 'frequency_score') }},
        
        -- Using macro for monetary score
        {{ calculate_rfm_score('total_items_purchased', [(20, 5), (15, 4), (10, 3), (5, 2)], 'monetary_score') }}
        
    FROM user_activity
)

SELECT
    user_id,
    full_name,
    city,
    email,
    total_carts,
    last_cart_date,
    first_cart_date,
    total_items_purchased,
    days_since_last_cart,
    recency_score,
    frequency_score,
    monetary_score,
    recency_score + frequency_score + monetary_score as rfm_total_score,
    
    -- Customer segment classification
    CASE
        WHEN recency_score >= 4 AND frequency_score >= 4 THEN 'Champions'
        WHEN recency_score >= 4 AND frequency_score >= 2 THEN 'Loyal Customers'
        WHEN recency_score >= 3 AND frequency_score >= 3 THEN 'Potential Loyalists'
        WHEN recency_score >= 4 AND frequency_score = 1 THEN 'New Customers'
        WHEN recency_score >= 3 AND frequency_score = 1 THEN 'Promising'
        WHEN recency_score = 2 THEN 'At Risk'
        WHEN recency_score = 1 AND frequency_score >= 3 THEN 'Cant Lose Them'
        WHEN recency_score = 1 AND frequency_score >= 2 THEN 'Hibernating'
        ELSE 'Lost'
    END as user_segment,
    
    -- Using macro for timestamp (consistent across all models)
    {{ generate_timestamp_column() }}
    
FROM rfm_scores
ORDER BY rfm_total_score DESC, last_cart_date DESC