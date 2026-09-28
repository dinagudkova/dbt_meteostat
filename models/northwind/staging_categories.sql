WITH source_data AS (
    SELECT *
    FROM {{ source('northwind_data', 'categories') }}
)
SELECT
    category_id
    ,category_name
FROM source_data