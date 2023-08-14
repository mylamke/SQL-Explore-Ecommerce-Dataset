# Explore-Ecommerce-Dataset
--Query 1-- calculate total visit, pageview, transaction, revenue for Jan, Feb, March 2017 
SELECT FORMAT_DATE('%Y%m', PARSE_DATE("%Y%m%d",date)) AS month,
        SUM(totals.visits) AS visits,
        SUM(totals.pageviews) AS pageviews,
        SUM(totals.transactions) AS transactions
 FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*` 
 WHERE _table_suffix BETWEEN '0101' AND '0331'
GROUP BY month
ORDER BY month;

--query 2--Bounce rate per traffic source in July 2017--

SELECT trafficSource.source
       ,COUNT(visitNumber) total_visits
       ,SUM(totals.bounces) total_no_of_bounces
       ,(SUM(totals.bounces)/COUNT(visitNumber))*100 bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
GROUP BY trafficSource.source
ORDER BY total_visits DESC;

--Query 3--Revenue by traffic source by week, by month in June 2017
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
GROUP BY time_type, time, source
ORDER BY revenue DESC
limit 4 ;

--Query 4-- Average number of pageviews by purchaser type
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
-- Query 5--Average number of transactions per user that made a purchase in July 2017

SELECT 
  FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
  SUM(CASE WHEN totals.transactions >= 1 THEN totals.transactions END) / COUNT(DISTINCT CASE WHEN totals.transactions >= 1 THEN fullVisitorId END) AS Avg_total_transactions_per_user
FROM 
  `bigquery-public-data.google_analytics_sample.ga_sessions_*`, 
  UNNEST(hits) AS hits, 
  UNNEST(hits.product) AS product
WHERE 
  _TABLE_SUFFIX BETWEEN '20170701' AND '20170731'
  AND product.productRevenue IS NOT NULL
GROUP BY 
  month; 

--Query 6--Average amount of money spent per session. Only include purchaser data in 2017

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

--Query 7--Other products purchased by customers who purchased product” Youtube Men’s Vintage Henley” in July 2017. 

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
        AND v2ProductName LIKE "YouTube Men's Vintage Henley"
        AND product.productRevenue IS NOT NULL )
  
  AND v2ProductName NOT LIKE "YouTube Men's Vintage Henley"
  AND product.productRevenue IS NOT NULL
GROUP BY 
  other_purchased_products
ORDER BY 
  quantity DESC
LIMIT 4;

-- Query 8--Calculate cohort map from product view to add_to_cart/number_product_view.
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
GROUP BY
    month, 
    num_product_view,
    num_addtocart,
    num_purchase

ORDER BY month;
