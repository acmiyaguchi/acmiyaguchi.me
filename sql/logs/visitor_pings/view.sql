WITH
  extracted AS (
  SELECT
    TIMESTAMP_MICROS(time_micros) AS timestamp,
    farm_fingerprint(c_ip) visitor_id,
    RTRIM(SPLIT(cs_referer, "acmiyaguchi.me")[
    OFFSET
      (1)], "/") AS path
  FROM
    `acmiyaguchi.logs.acmiyaguchi_usage`
  WHERE
    cs_referer LIKE "https://acmiyaguchi.me%"
  ORDER BY
    time_micros DESC )
SELECT
  timestamp,
  visitor_id,
IF
  (LENGTH(path)=0,
    "/",
    path) AS path
FROM
  extracted
WHERE
  NOT REGEXP_CONTAINS(path, r"%20")
