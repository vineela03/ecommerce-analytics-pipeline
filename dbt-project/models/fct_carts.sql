SELECT
    id as cart_id,
    user_id,
    date::timestamp as cart_date,
    jsonb_array_length(products) as total_items
FROM {{ source('raw', 'carts') }}