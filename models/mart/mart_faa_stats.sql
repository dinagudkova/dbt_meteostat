WITH departures_stats AS (
    SELECT
        origin AS faa,
        COUNT(*) AS total_departures_planned,
        COUNT(DISTINCT dest) AS unique_departure_connections,
        SUM(CASE WHEN cancelled = 1 THEN 1 ELSE 0 END) AS departures_cancelled,
        SUM(CASE WHEN diverted = 1 THEN 1 ELSE 0 END) AS departures_diverted,
        COUNT(DISTINCT tail_number) AS unique_planes_departing,
        COUNT(DISTINCT airline) AS unique_airlines_departing
    FROM {{ ref('prep_flights') }}
    GROUP BY origin
),
arrivals_stats AS (
    SELECT
        dest AS faa,
        COUNT(*) AS total_arrivals_planned,
        COUNT(DISTINCT origin) AS unique_arrival_connections,
        SUM(CASE WHEN cancelled = 1 THEN 1 ELSE 0 END) AS arrivals_cancelled,
        SUM(CASE WHEN diverted = 1 THEN 1 ELSE 0 END) AS arrivals_diverted,
        COUNT(DISTINCT tail_number) AS unique_planes_arriving,
        COUNT(DISTINCT airline) AS unique_airlines_arriving
    FROM {{ ref('prep_flights') }}
    GROUP BY dest
),
combined_stats AS (
    SELECT
        COALESCE(d.faa, a.faa) AS faa,
        COALESCE(d.total_departures_planned, 0) AS total_departures_planned,
        COALESCE(a.total_arrivals_planned, 0) AS total_arrivals_planned,
        COALESCE(d.total_departures_planned, 0) + COALESCE(a.total_arrivals_planned, 0) AS total_flights_planned,
        COALESCE(d.unique_departure_connections, 0) AS unique_departure_connections,
        COALESCE(a.unique_arrival_connections, 0) AS unique_arrival_connections,
        COALESCE(d.departures_cancelled, 0) + COALESCE(a.arrivals_cancelled, 0) AS total_cancelled,
        COALESCE(d.departures_diverted, 0) + COALESCE(a.arrivals_diverted, 0) AS total_diverted,
        (COALESCE(d.total_departures_planned, 0) + COALESCE(a.total_arrivals_planned, 0))
            - (COALESCE(d.departures_cancelled, 0) + COALESCE(a.arrivals_cancelled, 0)) AS total_flights_occurred,
        ROUND(
            (COALESCE(d.unique_planes_departing, 0) + COALESCE(a.unique_planes_arriving, 0)) / 2.0, 2
        ) AS avg_unique_planes,
        ROUND(
            (COALESCE(d.unique_airlines_departing, 0) + COALESCE(a.unique_airlines_arriving, 0)) / 2.0, 2
        ) AS avg_unique_airlines
    FROM departures_stats d
    FULL OUTER JOIN arrivals_stats a ON d.faa = a.faa
)
SELECT
    c.*,
    ap.name,
    ap.city,
    ap.country
FROM combined_stats c
LEFT JOIN {{ ref('prep_airports') }} ap ON c.faa = ap.faa
ORDER BY c.faa