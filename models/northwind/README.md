# Northwind Sales Insights (dbt)

## Business problem

Northwind's analysts worked with messy raw tables, wrote long manual joins for every
dashboard, and each of them calculated "revenue" differently. This project builds a
small dbt pipeline (staging -> prep -> mart) that cleans the data once, defines revenue
in one place, and provides a ready-to-use table for reporting.

## Models

| Model                      | Layer   | What it does                                                                                                                                  |
| -------------------------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `staging_orders`         | staging | Selects the needed order columns and casts dates to`DATE`                                                                                   |
| `staging_order_details`  | staging | Order lines with`unit_price`, `quantity`, `discount` cast to numeric types                                                              |
| `staging_products`       | staging | Product id, name, category and price; unused columns removed                                                                                  |
| `staging_categories`     | staging | Category id and name (the binary`picture` column is dropped)                                                                                |
| `prep_sales`             | prep    | Joins orders, order lines, products and categories; adds`revenue = unit_price * quantity * (1 - discount)`, `order_year`, `order_month` |
| `mart_sales_performance` | mart    | Total revenue, number of orders and average revenue per order by year, month and category                                                     |

`schema.yml` adds descriptions and `not_null` tests for the mart columns.

## Insights the mart can provide

* **Category performance:** Beverages (21% of total revenue) and Dairy Products (18.5%)
  together generate about 40% of all revenue. Grains/Cereals is the weakest category
  (7.6%).
* **Trend over time:** the data covers July-December 1996, all of 1997 and January-May
  1998, so yearly totals are not comparable. Average monthly revenue grows every year
  (about 34.7k in 1996, 51.4k in 1997 and 88.1k in 1998). Comparing the same months
  (January-May) gives a fairer view: 245.1k in 1997 vs 440.6k in 1998, an increase of
  about 80%.
* **Single source of truth:** revenue is defined once in `prep_sales`, so every dashboard
  built on `mart_sales_performance` shows the same numbers.

## Biggest learning moment

Checking the data after each step. The row count of `prep_sales` matched `order_details`
(2155 = 2155), which showed that the joins did not duplicate or lose rows. Later, a
naive comparison of yearly revenue suggested a decline in 1998, but the data showed that
1998 has only 5 months, so I compared average monthly revenue and the same months of
each year instead. I also learned to check the real column names in the database before
copying code from the instructions.
