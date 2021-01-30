SELECT
  timestamp_micros(time_micros) as timestamp,
  farm_fingerprint(c_ip) visitor_id,
  split(cs_referer, "acmiyaguchi.me")[offset(1)] as path
FROM
  `acmiyaguchi.logs.acmiyaguchi_usage`
WHERE
  cs_referer LIKE "https://acmiyaguchi.me%"
ORDER BY
  time_micros desc
  