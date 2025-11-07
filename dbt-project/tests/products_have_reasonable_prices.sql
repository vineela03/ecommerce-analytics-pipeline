-- Test that products have prices within reasonable ranges
-- Helps catch API data issues

SELECT
    product_id,
    product_name,
    price,
    category
FROM {{ ref('dim_products') }}
WHERE 
    -- Electronics shouldn't be over $5000
    (category = 'electronics' AND price > 5000)
    OR
    -- Clothing shouldn't be over $500
    (category IN ('men''s clothing', 'women''s clothing') AND price > 500)
    OR
    -- Jewelry shouldn't be over $2000
    (category = 'jewelery' AND price > 2000)