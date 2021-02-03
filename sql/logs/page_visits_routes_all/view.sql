WITH
  per_route AS (
  SELECT
    path,
    COUNT(*) AS total_visits,
    COUNT(DISTINCT visitor_id) AS unique_visits
  FROM
    logs.visitor_pings
  GROUP BY
    path ),
  total AS (
  SELECT
    "" AS path,
    COUNT(*) AS total_visits,
    COUNT(DISTINCT visitor_id) AS unique_visits
  FROM
    logs.visitor_pings),
  overall AS (
  SELECT
    *
  FROM
    per_route
  UNION ALL
  SELECT
    *
  FROM
    total )
SELECT
  *
FROM 
  overall
ORDER BY
  total_visits desc