WITH source_data AS (
    SELECT *
    FROM {{ source('northwind_data', 'orders') }}
)
SELECT
    order_id
    ,customer_id
    ,employee_id
    ,order_date::DATE AS order_date
    ,required_date::DATE AS required_date
    ,shipped_date::DATE AS shipped_date
    ,ship_via
    ,ship_city
    ,ship_country
FROM source_data