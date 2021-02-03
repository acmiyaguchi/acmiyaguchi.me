SELECT
  DATE(timestamp, "-08") AS date,
  path,
  COUNT(*) AS total_visits,
  COUNT(DISTINCT visitor_id) AS unique_visits
FROM
  logs.visitor_pings
WHERE
  DATE(timestamp, "-08") >= DATE_SUB(CURRENT_DATE("-08"), INTERVAL 7 day)
GROUP BY
  1,
  2
ORDER BY
  date,
  total_visits DESC