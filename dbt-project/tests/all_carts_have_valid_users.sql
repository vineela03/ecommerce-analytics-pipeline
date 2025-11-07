-- Test that all carts belong to existing users
-- Ensures referential integrity

SELECT
    c.cart_id,
    c.user_id
FROM {{ ref('fct_carts') }} c
LEFT JOIN {{ ref('dim_users') }} u ON c.user_id = u.user_id
WHERE u.user_id IS NULL