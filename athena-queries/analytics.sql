-- Create table for CloudFront logs
CREATE EXTERNAL TABLE IF NOT EXISTS website_analytics.cloudfront_logs (
  `date` DATE,
  time STRING,
  x_edge_location STRING,
  sc_bytes BIGINT,
  c_ip STRING,
  cs_method STRING,
  cs_host STRING,
  cs_uri_stem STRING,
  sc_status INT,
  cs_referrer STRING,
  cs_user_agent STRING,
  cs_uri_query STRING,
  cs_cookie STRING,
  x_edge_result_type STRING,
  x_edge_request_id STRING,
  x_host_header STRING,
  cs_protocol STRING,
  cs_bytes BIGINT,
  time_taken FLOAT,
  x_forwarded_for STRING,
  ssl_protocol STRING,
  ssl_cipher STRING,
  x_edge_response_result_type STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe'
WITH SERDEPROPERTIES (
  'serialization.format' = '\\t',
  'field.delim' = '\\t'
)
LOCATION 's3://cf-logs-xxxxxx/cloudfront/';

-- Daily visitors count
SELECT 
  COUNT(DISTINCT c_ip) as unique_visitors,
  COUNT(*) as total_requests,
  DATE_TRUNC('day', date) as day
FROM website_analytics.cloudfront_logs
WHERE sc_status = 200
GROUP BY DATE_TRUNC('day', date)
ORDER BY day DESC
LIMIT 30;

-- Most popular pages
SELECT 
  cs_uri_stem as page,
  COUNT(*) as views
FROM website_analytics.cloudfront_logs
WHERE sc_status = 200
GROUP BY cs_uri_stem
ORDER BY views DESC
LIMIT 10;