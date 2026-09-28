WITH sales AS (
    SELECT * FROM {{ ref('prep_sales') }}
)
SELECT
    order_year,
    order_month,
    category_name,
    SUM(revenue) AS total_revenue,
    COUNT(DISTINCT order_id) AS total_orders,
    AVG(revenue) AS avg_revenue_per_order
FROM sales
GROUP BY 1, 2, 3
ORDER BY category_name, order_year, order_month