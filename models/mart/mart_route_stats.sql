WITH route_stats AS (
    SELECT
        origin,
        dest,
        COUNT(*) AS total_flights,
        COUNT(DISTINCT tail_number) AS unique_planes,
        COUNT(DISTINCT airline) AS unique_airlines,
        ROUND(AVG(actual_elapsed_time), 2) AS avg_actual_elapsed_time,
        ROUND(AVG(arr_delay), 2) AS avg_arr_delay,
        MAX(arr_delay) AS max_arr_delay,
        MIN(arr_delay) AS min_arr_delay,
        SUM(cancelled) AS total_cancelled,
        SUM(diverted) AS total_diverted
    FROM {{ ref('prep_flights') }}
    GROUP BY origin, dest
)
SELECT
    r.origin,
    r.dest,
    r.total_flights,
    r.unique_planes,
    r.unique_airlines,
    r.avg_actual_elapsed_time,
    r.avg_arr_delay,
    r.max_arr_delay,
    r.min_arr_delay,
    r.total_cancelled,
    r.total_diverted,
    origin_ap.name AS origin_name,
    origin_ap.city AS origin_city,
    origin_ap.country AS origin_country,
    dest_ap.name AS dest_name,
    dest_ap.city AS dest_city,
    dest_ap.country AS dest_country
FROM route_stats r
LEFT JOIN {{ ref('prep_airports') }} origin_ap ON r.origin = origin_ap.faa
LEFT JOIN {{ ref('prep_airports') }} dest_ap ON r.dest = dest_ap.faa
ORDER BY r.total_flights DESC