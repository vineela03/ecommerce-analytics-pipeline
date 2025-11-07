SELECT
    id as product_id,
    title as product_name,
    price,
    category,
    rating_rate as avg_rating,
    rating_count
FROM {{ source('raw', 'products') }}