SELECT
    id as user_id,
    email,
    username,
    name_firstname || ' ' || name_lastname as full_name,
    city
FROM {{ source('raw', 'users') }}