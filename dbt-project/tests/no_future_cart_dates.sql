-- Test that cart dates are not in the future
-- Prevents data quality issues from API errors

SELECT
    cart_id,
    cart_date,
    CURRENT_TIMESTAMP as now
FROM {{ ref('fct_carts') }}
WHERE cart_date > CURRENT_TIMESTAMP