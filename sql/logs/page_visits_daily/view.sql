SELECT
  DATE(timestamp, "-08") AS date,
  COUNT(*) AS total_visits,
  COUNT(DISTINCT visitor_id) AS unique_visits
FROM
  logs.visitor_pings
GROUP BY
  1
ORDER BY
  date