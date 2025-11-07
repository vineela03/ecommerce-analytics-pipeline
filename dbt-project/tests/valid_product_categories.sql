-- Test that all products have valid categories
-- Returns rows that FAIL the test (invalid categories)

SELECT
    product_id,
    product_name,
    category
FROM {{ ref('dim_products') }}
WHERE category NOT IN (
    'electronics',
    'jewelery',
    'men''s clothing',
    'women''s clothing'
)