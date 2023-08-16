

--Query 1--
SELECT FORMAT_DATE('%Y%m', PARSE_DATE("%Y%m%d",date)) AS month,
        SUM(totals.visits) AS visits,
        SUM(totals.pageviews) AS pageviews,
        SUM(totals.transactions) AS transactions
 FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*` 
 WHERE _table_suffix BETWEEN '0101' AND '0331'
GROUP BY 1
ORDER BY 1;


--query 2--
SELECT FORMAT_DATE('%Y%m', PARSE_DATE("%Y%m%d",date)) AS month,
        SUM(totals.visits) AS visits,
        SUM(totals.pageviews) AS pageviews,
        SUM(totals.transactions) AS transactions
 FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*` 
 WHERE _table_suffix BETWEEN '0101' AND '0331'
GROUP BY month
ORDER BY month;

--Query 3--
WITH all_data AS (
  SELECT 
    'Week' AS time_type,
    FORMAT_DATE('%Y%W', PARSE_DATE('%Y%m%d', date)) AS time,
    trafficSource.source AS source,
    ROUND(SUM(product.productRevenue)/1000000,4) AS revenue
  FROM 
    `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`, 
    UNNEST(hits) AS hits, 
    UNNEST(hits.product) AS product
  WHERE 
    product.productRevenue IS NOT NULL
  GROUP BY 
    time_type, time, source
  
  UNION ALL
  
  SELECT 
    'Month' AS time_type,
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS time,
    trafficSource.source AS source,
    ROUND(SUM(product.productRevenue)/1000000,4) AS revenue
  FROM 
    `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`, 
    UNNEST(hits) AS hits, 
    UNNEST(hits.product) AS product
  WHERE 
    product.productRevenue IS NOT NULL 
  GROUP BY 
    time_type, time, source
)

SELECT time_type, time, source, SUM(revenue) AS revenue
FROM all_data
GROUP BY 1,2,3
ORDER BY 4 DESC
limit 4 ;

--Query 4--
WITH full_data AS (
  SELECT
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    fullVisitorId AS unique_user,
    totals.transactions AS total_transactions,
    product.productRevenue AS product_revenue,
    totals.pageviews AS total_pageview
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST (hits) hits,
    UNNEST(hits.product) product
  WHERE
    _TABLE_SUFFIX BETWEEN '0601' AND '0731'),

Purchase AS (
  SELECT
    month,
    SUM(total_pageview) / COUNT(DISTINCT unique_user) AS avg_pageviews_purchase
  FROM
    full_data
  WHERE
    total_transactions >= 1 
    AND  product_revenue IS NOT NULL
  GROUP BY month
  ORDER BY month),

Nonpurchase AS (
  SELECT
    month,
    SUM(total_pageview) / COUNT(DISTINCT unique_user) AS avg_pageviews_non_purchase
  FROM
    full_data
  WHERE
    total_transactions IS NULL 
    AND product_revenue IS NULL
  GROUP BY month
  ORDER BY month)

SELECT *
FROM Purchase
LEFT JOIN Nonpurchase
USING(month)
ORDER BY month;


-- Query 5--

SELECT
    format_date("%Y%m",parse_date("%Y%m%d",date)) as month,
    sum(totals.transactions)/count(distinct fullvisitorid) as Avg_total_transactions_per_user
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
    ,unnest (hits) hits,
    unnest(product) product
WHERE  totals.transactions>=1
AND totals.totalTransactionRevenue is not null
AND product.productRevenue is not null
GROUP BY month;

--Query 6--

SELECT 
  FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
  ROUND((SUM(product.productRevenue) / SUM(totals.visits))/1000000,2) AS Avg_revenue_by_user_per_visit
FROM 
  `bigquery-public-data.google_analytics_sample.ga_sessions_*`, 
  UNNEST(hits) AS hits, 
  UNNEST(hits.product) AS product
WHERE 
  _TABLE_SUFFIX BETWEEN '20170701' AND '20170731'
  AND product.productRevenue IS NOT NULL
  AND totals.transactions IS NOT NULL
GROUP BY month;



--Query 7--

SELECT 
  v2ProductName AS other_purchased_products, 
  SUM(productQuantity) AS quantity
FROM 
  `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
  UNNEST(hits) AS hits, 
  UNNEST(hits.product) AS product
WHERE 
  hits.transaction.transactionId IN (
    SELECT hits.transaction.transactionId
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
        UNNEST(hits) AS hits, 
        UNNEST(hits.product) AS product
    WHERE _TABLE_SUFFIX BETWEEN '20170701' AND '20170731'
        AND v2ProductName = "YouTube Men's Vintage Henley"
        AND product.productRevenue IS NOT NULL )
  
  AND v2ProductName != "YouTube Men's Vintage Henley"
  AND product.productRevenue IS NOT NULL
GROUP BY 
  other_purchased_products
ORDER BY 
  quantity DESC;
LIMIT 4;



-- Query 8--
WITH NumProductView AS (
  SELECT
    FORMAT_DATE('%Y%m', PARSE_DATE ('%Y%m%d', date )) AS month,
    COUNT(product.v2ProductName) AS num_product_view
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST (hits) hit,
    UNNEST (product) product
  WHERE ecommerceaction.action_type = '2'
    AND _TABLE_SUFFIX BETWEEN '0101' AND '0331'
  GROUP BY month
  ORDER BY month),

NumAddToCart AS (
  SELECT
    FORMAT_DATE('%Y%m', PARSE_DATE ('%Y%m%d', date )) AS month,
    COUNT(product.v2ProductName) AS num_addtocart
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST (hits) hit,
    UNNEST (product) product
  WHERE ecommerceaction.action_type = '3'
    AND _TABLE_SUFFIX BETWEEN '0101' AND '0331'
  GROUP BY month
  ORDER BY month),

NumPurchase AS (
  SELECT
    FORMAT_DATE('%Y%m', PARSE_DATE ('%Y%m%d', date )) AS month,
    COUNT(product.v2ProductName) AS num_purchase
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST (hits) hit,
    UNNEST (product) product
  WHERE ecommerceaction.action_type = '6'
    AND _TABLE_SUFFIX BETWEEN '0101' AND '0331' 
    AND product.productRevenue IS NOT NULL
  GROUP BY month
  ORDER BY month)

SELECT
  month,
  num_product_view,
  num_addtocart,
  num_purchase,
  ROUND(SUM(num_addtocart)/SUM(num_product_view)*100,2) AS add_to_cart_rate,
  ROUND(SUM(num_purchase)/SUM(num_product_view)*100,2) AS purchase_rate
FROM NumProductView
LEFT JOIN NumAddToCart
USING (month)
LEFT JOIN NumPurchase
USING (month)
GROUP BY 1,2,3,4
ORDER BY month;


                                                   