WITH weekly_weather AS (
    SELECT
        airport_code,
        date_year,
        cw AS calendar_week,
        MODE() WITHIN GROUP (ORDER BY season) AS season,
        ROUND(AVG(avg_temp_c), 2) AS avg_temp_c,
        MIN(min_temp_c) AS min_temp_c,
        MAX(max_temp_c) AS max_temp_c,
        SUM(precipitation_mm) AS total_precipitation_mm,
        SUM(max_snow_mm) AS total_snow_mm,
        ROUND(AVG(avg_wind_direction), 0) AS avg_wind_direction,
        ROUND(AVG(avg_wind_speed_kmh), 2) AS avg_wind_speed_kmh,
        MAX(wind_peakgust_kmh) AS max_wind_peakgust_kmh,
        ROUND(AVG(avg_pressure_hpa), 2) AS avg_pressure_hpa,
        SUM(sun_minutes) AS total_sun_minutes
    FROM {{ ref('prep_weather_daily') }}
    GROUP BY airport_code, date_year, cw
)
SELECT *
FROM weekly_weather
ORDER BY airport_code, date_year, calendar_week