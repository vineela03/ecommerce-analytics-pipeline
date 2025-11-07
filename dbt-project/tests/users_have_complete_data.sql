-- Test that users have all required fields populated
-- Ensures data completeness

SELECT
    user_id,
    email,
    username,
    full_name,
    city
FROM {{ ref('dim_users') }}
WHERE
    email IS NULL
    OR username IS NULL
    OR full_name IS NULL
    OR city IS NULL
    OR TRIM(email) = ''
    OR TRIM(username) = ''
    OR TRIM(full_name) = ''
    OR TRIM(city) = ''