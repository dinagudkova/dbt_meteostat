WITH source_data AS (
    SELECT *
    FROM {{ source('northwind_data', 'order_details') }}
)
SELECT
    order_id
    ,product_id
    ,unit_price::NUMERIC AS unit_price
    ,quantity::INT AS quantity
    ,discount::NUMERIC AS discount
FROM source_data