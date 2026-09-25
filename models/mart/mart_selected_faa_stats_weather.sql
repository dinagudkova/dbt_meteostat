WITH departures_daily AS (
    SELECT
        origin AS faa,
        flight_date,
        COUNT(*) AS total_departures_planned,
        COUNT(DISTINCT dest) AS unique_departure_connections,
        SUM(cancelled) AS departures_cancelled,
        SUM(diverted) AS departures_diverted,
        COUNT(DISTINCT tail_number) AS unique_planes_departing,
        COUNT(DISTINCT airline) AS unique_airlines_departing
    FROM {{ ref('prep_flights') }}
    GROUP BY origin, flight_date
),
arrivals_daily AS (
    SELECT
        dest AS faa,
        flight_date,
        COUNT(*) AS total_arrivals_planned,
        COUNT(DISTINCT origin) AS unique_arrival_connections,
        SUM(cancelled) AS arrivals_cancelled,
        SUM(diverted) AS arrivals_diverted,
        COUNT(DISTINCT tail_number) AS unique_planes_arriving,
        COUNT(DISTINCT airline) AS unique_airlines_arriving
    FROM {{ ref('prep_flights') }}
    GROUP BY dest, flight_date
),
combined_daily AS (
    SELECT
        COALESCE(d.faa, a.faa) AS faa,
        COALESCE(d.flight_date, a.flight_date) AS flight_date,
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
    FROM departures_daily d
    FULL OUTER JOIN arrivals_daily a
        ON d.faa = a.faa AND d.flight_date = a.flight_date
)
SELECT
    c.faa,
    c.flight_date,
    c.total_flights_planned,
    c.unique_departure_connections,
    c.unique_arrival_connections,
    c.total_cancelled,
    c.total_diverted,
    c.total_flights_occurred,
    c.avg_unique_planes,
    c.avg_unique_airlines,
    ap.name,
    ap.city,
    ap.country,
    w.min_temp_c,
    w.max_temp_c,
    w.precipitation_mm,
    w.max_snow_mm,
    w.avg_wind_direction,
    w.avg_wind_speed_kmh,
    w.wind_peakgust_kmh
FROM combined_daily c
INNER JOIN {{ ref('prep_weather_daily') }} w
    ON c.faa = w.airport_code AND c.flight_date = w.reading_date
LEFT JOIN {{ ref('prep_airports') }} ap ON c.faa = ap.faa
ORDER BY c.faa, c.flight_date