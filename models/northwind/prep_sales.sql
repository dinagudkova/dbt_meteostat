WITH orders AS (
    SELECT * FROM {{ ref('staging_orders') }}
),
order_details AS (
    SELECT * FROM {{ ref('staging_order_details') }}
),
products AS (
    SELECT * FROM {{ ref('staging_products') }}
),
categories AS (
    SELECT * FROM {{ ref('staging_categories') }}
),
joined AS (
    SELECT
        o.order_id,
        o.customer_id,
        p.product_name,
        c.category_name,
        od.unit_price,
        od.quantity,
        od.discount,
        (od.unit_price * od.quantity * (1 - od.discount)) AS revenue,
        EXTRACT(year FROM o.order_date) AS order_year,
        EXTRACT(month FROM o.order_date) AS order_month
    FROM orders o
    JOIN order_details od USING (order_id)
    JOIN products p USING (product_id)
    LEFT JOIN categories c USING (category_id)
)
SELECT * FROM joined