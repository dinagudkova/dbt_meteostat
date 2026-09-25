WITH hourly_data AS (
    SELECT *
    FROM {{ ref('prep_weather_hourly') }}
),
hourly_features AS (
    SELECT
        *,
        -- Beaufort wind scale, standard km/h thresholds
        CASE
            WHEN wind_speed_kmh < 1 THEN 'Calm'
            WHEN wind_speed_kmh < 6 THEN 'Light air'
            WHEN wind_speed_kmh < 12 THEN 'Light breeze'
            WHEN wind_speed_kmh < 20 THEN 'Gentle breeze'
            WHEN wind_speed_kmh < 29 THEN 'Moderate breeze'
            WHEN wind_speed_kmh < 39 THEN 'Fresh breeze'
            WHEN wind_speed_kmh < 50 THEN 'Strong breeze'
            WHEN wind_speed_kmh < 62 THEN 'Near gale'
            WHEN wind_speed_kmh < 75 THEN 'Gale'
            WHEN wind_speed_kmh < 89 THEN 'Strong gale'
            WHEN wind_speed_kmh < 103 THEN 'Storm'
            WHEN wind_speed_kmh < 118 THEN 'Violent storm'
            ELSE 'Hurricane'
        END AS beaufort_scale,
        -- Heat index (metric adaptation of the Rothfusz regression), only meaningful when warm and humid
        CASE WHEN temp_c >= 27 AND humidity_perc IS NOT NULL THEN
            ROUND((
                -8.784695
                + 1.61139411 * temp_c
                + 2.338549 * humidity_perc
                - 0.14611605 * temp_c * humidity_perc
                - 0.012308094 * POWER(temp_c, 2)
                - 0.016424828 * POWER(humidity_perc, 2)
                + 0.002211732 * POWER(temp_c, 2) * humidity_perc
                + 0.00072546 * temp_c * POWER(humidity_perc, 2)
                - 0.000003582 * POWER(temp_c, 2) * POWER(humidity_perc, 2)
            )::NUMERIC, 1)
        END AS heat_index_c,
        -- Wind chill, only valid when cold and windy enough to matter
        CASE WHEN temp_c <= 10 AND wind_speed_kmh > 4.8 THEN
            ROUND((
                13.12 + 0.6215 * temp_c - 11.37 * POWER(wind_speed_kmh, 0.16)
                + 0.3965 * temp_c * POWER(wind_speed_kmh, 0.16)
            )::NUMERIC, 1)
        END AS wind_chill_c
    FROM hourly_data
),
hourly_comfort AS (
    SELECT
        *,
        -- thermal comfort ("feels like"): heat index when hot, wind chill when cold, else actual temp
        COALESCE(heat_index_c, wind_chill_c, temp_c) AS feels_like_c
    FROM hourly_features
)
SELECT
    h.airport_code,
    h.date,
    COUNT(*) AS hours_recorded,
    ROUND(AVG(CASE WHEN h.day_part = 'day' THEN h.temp_c END), 2) AS avg_day_temp_c,
    ROUND(AVG(CASE WHEN h.day_part = 'night' THEN h.temp_c END), 2) AS avg_night_temp_c,
    ROUND(AVG(CASE WHEN h.day_part = 'day' THEN h.humidity_perc END), 2) AS avg_day_humidity_perc,
    ROUND(AVG(CASE WHEN h.day_part = 'night' THEN h.humidity_perc END), 2) AS avg_night_humidity_perc,
    ROUND(AVG(CASE WHEN h.day_part = 'day' THEN h.wind_speed_kmh END), 2) AS avg_day_wind_speed_kmh,
    ROUND(AVG(CASE WHEN h.day_part = 'night' THEN h.wind_speed_kmh END), 2) AS avg_night_wind_speed_kmh,
    MODE() WITHIN GROUP (ORDER BY h.beaufort_scale) AS most_common_wind_strength,
    ROUND(AVG(h.heat_index_c), 2) AS avg_heat_index_c,
    MAX(h.heat_index_c) AS max_heat_index_c,
    ROUND(AVG(h.feels_like_c), 2) AS avg_feels_like_c,
    COUNT(*) FILTER (WHERE cc.is_clear = 1) AS sunny_hours,
    COUNT(*) FILTER (WHERE h.precipitation_mm > 0) AS rainy_hours,
    COUNT(*) FILTER (WHERE h.snow_mm > 0) AS snowy_hours,
    MODE() WITHIN GROUP (ORDER BY cc.condition_name) AS most_common_condition
FROM hourly_comfort h
LEFT JOIN {{ ref('weather_condition_codes') }} cc ON cc.condition_code = h.condition_code
GROUP BY h.airport_code, h.date
ORDER BY h.airport_code, h.date
