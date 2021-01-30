SELECT
  DATE(timestamp) AS date,
  path,
  COUNT(*) AS total_visits,
  COUNT(DISTINCT visitor_id) AS unique_visits
FROM
  logs.visitor_pings
GROUP BY
  1,
  2
ORDER BY
  date,
  total_visits DESC