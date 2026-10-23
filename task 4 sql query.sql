CREATE TABLE air_quality (
    station_id  VARCHAR(10),
    obs_date    DATE,
    pm25        NUMERIC(8,2),
    pm10        NUMERIC(8,2),
    no_gas      NUMERIC(8,2),
    no2         NUMERIC(8,2),
    nox         NUMERIC(8,2),
    nh3         NUMERIC(8,2),
    co          NUMERIC(8,2),
    so2         NUMERIC(8,2),
    o3          NUMERIC(8,2),
    benzene     NUMERIC(8,2),
    toluene     NUMERIC(8,2),
    aqi         NUMERIC(6,1),
    aqi_bucket  VARCHAR(15),
    obs_year    INT,
    obs_month   INT,
    season      VARCHAR(15),
    state       VARCHAR(5)
);

SELECT COUNT(*) FROM air_quality;

SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT station_id) AS stations,
       MIN(obs_date) AS first_date,
       MAX(obs_date) AS last_date
FROM air_quality;

--Q2

SELECT state, ROUND(AVG(aqi),1) AS avg_aqi, COUNT(*) AS readings
FROM air_quality
GROUP BY state
ORDER BY avg_aqi DESC;



--Top 10 most polluted stations (at least 365 readings)

SELECT station_id, ROUND(AVG(aqi),1) AS avg_aqi, COUNT(*) AS readings
FROM air_quality
GROUP BY station_id
HAVING COUNT(*) >= 365
ORDER BY avg_aqi DESC
LIMIT 10;


--Share of days in each AQI bucket (window function)
SELECT aqi_bucket,
       COUNT(*) AS days,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM air_quality
GROUP BY aqi_bucket
ORDER BY days DESC;

--Season-wise average AQI
SELECT season, ROUND(AVG(aqi),1) AS avg_aqi
FROM air_quality
GROUP BY season
ORDER BY avg_aqi DESC;

--Year-over-year change in AQI (CTE and LAG)
WITH yearly AS (
    SELECT obs_year, ROUND(AVG(aqi),1) AS avg_aqi
    FROM air_quality
    WHERE obs_year < 2020
    GROUP BY obs_year
)
SELECT obs_year,
       avg_aqi,
       LAG(avg_aqi) OVER (ORDER BY obs_year) AS previous_year,
       avg_aqi - LAG(avg_aqi) OVER (ORDER BY obs_year) AS change
FROM yearly
ORDER BY obs_year;

--Rank stations inside each state (CTE and RANK)
WITH station_avg AS (
    SELECT state, station_id, ROUND(AVG(aqi),1) AS avg_aqi
    FROM air_quality
    GROUP BY state, station_id
    HAVING COUNT(*) >= 365
)
SELECT state, station_id, avg_aqi,
       RANK() OVER (PARTITION BY state ORDER BY avg_aqi DESC) AS rank_in_state
FROM station_avg
ORDER BY state, rank_in_state;

---Worst month of each year (CTE and RANK)
WITH monthly AS (
    SELECT obs_year, obs_month, ROUND(AVG(aqi),1) AS avg_aqi
    FROM air_quality
    WHERE obs_year < 2020
    GROUP BY obs_year, obs_month
),
ranked AS (
    SELECT *, RANK() OVER (PARTITION BY obs_year ORDER BY avg_aqi DESC) AS rnk
    FROM monthly
)
SELECT obs_year, obs_month, avg_aqi
FROM ranked
WHERE rnk = 1
ORDER BY obs_year;


---. 7-day moving average for one station (window frame)
SELECT obs_date, aqi,
       ROUND(AVG(aqi) OVER (ORDER BY obs_date
             ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 1) AS moving_avg_7d
FROM air_quality
WHERE station_id = 'DL007'
ORDER BY obs_date
LIMIT 30;

