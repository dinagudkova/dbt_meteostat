WITH route_stats AS (
    SELECT
        origin,
        dest,
        COUNT(*) AS total_flights,
        COUNT(DISTINCT tail_number) AS unique_airplanes,
        COUNT(DISTINCT airline) AS unique_airlines,
        ROUND(AVG(actual_elapsed_time), 2) AS avg_actual_elapsed_time,
        ROUND(AVG(arr_delay), 2) AS avg_arrival_delay,
        MAX(arr_delay) AS max_arrival_delay,
        MIN(arr_delay) AS min_arrival_delay,
        COUNT(*) FILTER (WHERE cancelled = 1) AS total_cancelled,
        COUNT(*) FILTER (WHERE diverted = 1) AS total_diverted
    FROM {{ ref('prep_flights') }}
    GROUP BY origin, dest
)
SELECT
    rs.origin,
    origin_airport.name AS origin_name,
    origin_airport.city AS origin_city,
    origin_airport.country AS origin_country,
    rs.dest,
    dest_airport.name AS dest_name,
    dest_airport.city AS dest_city,
    dest_airport.country AS dest_country,
    rs.total_flights,
    rs.unique_airplanes,
    rs.unique_airlines,
    rs.avg_actual_elapsed_time,
    rs.avg_arrival_delay,
    rs.max_arrival_delay,
    rs.min_arrival_delay,
    rs.total_cancelled,
    rs.total_diverted
FROM route_stats rs
LEFT JOIN {{ ref('prep_airports') }} origin_airport ON origin_airport.faa = rs.origin
LEFT JOIN {{ ref('prep_airports') }} dest_airport ON dest_airport.faa = rs.dest
ORDER BY rs.origin, rs.dest
