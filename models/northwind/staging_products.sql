WITH source_data AS (
    SELECT *
    FROM {{ source('northwind_data', 'products') }}
)
SELECT
    product_id
    ,product_name
    ,supplier_id
    ,category_id
    ,unit_price::NUMERIC AS unit_price
FROM source_data