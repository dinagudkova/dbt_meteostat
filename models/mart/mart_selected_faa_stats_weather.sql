WITH weather_airports AS (
    SELECT DISTINCT airport_code
    FROM {{ ref('prep_weather_daily') }}
),
departures AS (
    SELECT
        origin AS faa,
        flight_date,
        COUNT(DISTINCT dest) AS unique_departure_connections,
        COUNT(*) AS planned_departures,
        COUNT(*) FILTER (WHERE cancelled = 1) AS cancelled_departures,
        COUNT(*) FILTER (WHERE diverted = 1) AS diverted_departures,
        COUNT(*) FILTER (WHERE cancelled = 0) AS occurred_departures,
        COUNT(DISTINCT tail_number) AS unique_airplanes_departures,
        COUNT(DISTINCT airline) AS unique_airlines_departures
    FROM {{ ref('prep_flights') }}
    WHERE origin IN (SELECT airport_code FROM weather_airports)
    GROUP BY origin, flight_date
),
arrivals AS (
    SELECT
        dest AS faa,
        flight_date,
        COUNT(DISTINCT origin) AS unique_arrival_connections,
        COUNT(*) AS planned_arrivals,
        COUNT(*) FILTER (WHERE cancelled = 1) AS cancelled_arrivals,
        COUNT(*) FILTER (WHERE diverted = 1) AS diverted_arrivals,
        COUNT(*) FILTER (WHERE cancelled = 0) AS occurred_arrivals,
        COUNT(DISTINCT tail_number) AS unique_airplanes_arrivals,
        COUNT(DISTINCT airline) AS unique_airlines_arrivals
    FROM {{ ref('prep_flights') }}
    WHERE dest IN (SELECT airport_code FROM weather_airports)
    GROUP BY dest, flight_date
),
flight_stats AS (
    SELECT
        COALESCE(d.faa, a.faa) AS faa,
        COALESCE(d.flight_date, a.flight_date) AS flight_date,
        COALESCE(d.unique_departure_connections, 0) AS unique_departure_connections,
        COALESCE(a.unique_arrival_connections, 0) AS unique_arrival_connections,
        COALESCE(d.planned_departures, 0) + COALESCE(a.planned_arrivals, 0) AS total_flights_planned,
        COALESCE(d.cancelled_departures, 0) + COALESCE(a.cancelled_arrivals, 0) AS total_flights_cancelled,
        COALESCE(d.diverted_departures, 0) + COALESCE(a.diverted_arrivals, 0) AS total_flights_diverted,
        COALESCE(d.occurred_departures, 0) + COALESCE(a.occurred_arrivals, 0) AS total_flights_occurred,
        ROUND((COALESCE(d.unique_airplanes_departures, 0) + COALESCE(a.unique_airplanes_arrivals, 0)) / 2.0, 2) AS avg_unique_airplanes,
        ROUND((COALESCE(d.unique_airlines_departures, 0) + COALESCE(a.unique_airlines_arrivals, 0)) / 2.0, 2) AS avg_unique_airlines
    FROM departures d
    FULL OUTER JOIN arrivals a ON d.faa = a.faa AND d.flight_date = a.flight_date
)
SELECT
    w.airport_code AS faa,
    ap.name,
    ap.city,
    ap.country,
    w.reading_date,
    COALESCE(fs.unique_departure_connections, 0) AS unique_departure_connections,
    COALESCE(fs.unique_arrival_connections, 0) AS unique_arrival_connections,
    COALESCE(fs.total_flights_planned, 0) AS total_flights_planned,
    COALESCE(fs.total_flights_cancelled, 0) AS total_flights_cancelled,
    COALESCE(fs.total_flights_diverted, 0) AS total_flights_diverted,
    COALESCE(fs.total_flights_occurred, 0) AS total_flights_occurred,
    fs.avg_unique_airplanes,
    fs.avg_unique_airlines,
    w.min_temp_c,
    w.max_temp_c,
    w.precipitation_mm,
    w.max_snow_mm AS snowfall_mm,
    w.avg_wind_direction,
    w.avg_wind_speed_kmh,
    w.wind_peakgust_kmh
FROM {{ ref('prep_weather_daily') }} w
LEFT JOIN {{ ref('prep_airports') }} ap ON ap.faa = w.airport_code
LEFT JOIN flight_stats fs ON fs.faa = w.airport_code AND fs.flight_date = w.reading_date
ORDER BY w.airport_code, w.reading_date
