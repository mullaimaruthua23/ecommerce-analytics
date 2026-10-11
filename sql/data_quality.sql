-- ============================================================
-- OLIST E-COMMERCE ANALYTICS
-- PHASE 1: DATA QUALITY AUDIT  (Q9 to Q36)
-- analysis.sql keeps Q1 to Q8. This file holds the whole audit.
-- Raw tables are raw_*. Pipeline output tables are fact_orders,
-- fact_items and rfm.
-- Run 00_indexes.sql once before this file.
-- ============================================================


-- ============================================================
-- SECTION 0. ORDER STATUS, DROPPED ROWS, DUPLICATES
-- ============================================================

-- Q9: How many orders are in each status, and what share is that?
SELECT
    order_status,
    COUNT(*) AS orders,
    ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM raw_orders
GROUP BY order_status
ORDER BY orders DESC;


-- Q10: Which delivered orders have no delivery date? (dropped by the pipeline)
SELECT
    order_id,
    order_purchase_timestamp,
    order_delivered_customer_date
FROM raw_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;


-- Q11: How many delivered orders were dropped for a missing delivery date?
SELECT COUNT(*) AS delivered_without_date
FROM raw_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;


-- Q12: Does any order_id appear more than once in raw_orders?
SELECT
    order_id,
    COUNT(*) AS duplicate_count
FROM raw_orders
GROUP BY order_id
HAVING COUNT(*) > 1;


-- Q13: Does any order_id have more than one review in raw_order_reviews?
SELECT
    order_id,
    COUNT(*) AS review_count
FROM raw_order_reviews
GROUP BY order_id
HAVING COUNT(*) > 1;


-- ============================================================
-- SECTION A. REVIEWS: THE DUPLICATE-ROW TRAP
-- ============================================================

-- Q14: How many orders have 1, 2, 3 ... reviews?
WITH reviews_per_order AS (
    SELECT order_id, COUNT(*) AS review_count
    FROM raw_order_reviews
    GROUP BY order_id
)
SELECT review_count, COUNT(*) AS orders
FROM reviews_per_order
GROUP BY review_count
ORDER BY review_count;


-- Q15: How many extra rows would a careless orders-to-reviews join create?
SELECT
    a.n AS raw_orders_rows,
    b.n AS rows_after_join,
    b.n - a.n AS extra_rows_from_join
FROM (SELECT COUNT(*) AS n FROM raw_orders) a
CROSS JOIN (
    SELECT COUNT(*) AS n
    FROM raw_orders o
    LEFT JOIN raw_order_reviews r ON r.order_id = o.order_id
) b;


-- ============================================================
-- SECTION B. ROW COUNTS AND THE ORDER RECONCILIATION
-- ============================================================

-- Q16: How many rows does each table hold?
SELECT 'raw_orders' AS table_name, COUNT(*) AS row_count FROM raw_orders
UNION ALL SELECT 'raw_customers', COUNT(*) FROM raw_customers
UNION ALL SELECT 'raw_order_items', COUNT(*) FROM raw_order_items
UNION ALL SELECT 'raw_order_payments', COUNT(*) FROM raw_order_payments
UNION ALL SELECT 'raw_order_reviews', COUNT(*) FROM raw_order_reviews
UNION ALL SELECT 'raw_products', COUNT(*) FROM raw_products
UNION ALL SELECT 'raw_sellers', COUNT(*) FROM raw_sellers
UNION ALL SELECT 'raw_product_category_name_translation', COUNT(*) FROM raw_product_category_name_translation
UNION ALL SELECT 'fact_orders', COUNT(*) FROM fact_orders
UNION ALL SELECT 'fact_items', COUNT(*) FROM fact_items
UNION ALL SELECT 'rfm', COUNT(*) FROM rfm;


-- Q17: Order waterfall: from all raw orders down to the pipeline output
SELECT 1 AS step_no, 'All orders in raw_orders' AS step, COUNT(*) AS orders
FROM raw_orders
UNION ALL
SELECT 2, 'Status = delivered', COUNT(*)
FROM raw_orders
WHERE order_status = 'delivered'
UNION ALL
SELECT 3, 'Delivered and has a delivery date', COUNT(*)
FROM raw_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
UNION ALL
SELECT 4, 'Delivered, has a delivery date and at least one item', COUNT(*)
FROM raw_orders o
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND EXISTS (SELECT 1 FROM raw_order_items i WHERE i.order_id = o.order_id)
UNION ALL
SELECT 5, 'Orders in fact_orders (pipeline output)', COUNT(*)
FROM fact_orders
ORDER BY step_no;


-- Q18: Which orders have no items at all, by status?
SELECT o.order_status, COUNT(*) AS orders_without_items
FROM raw_orders o
LEFT JOIN raw_order_items i ON i.order_id = o.order_id
WHERE i.order_id IS NULL
GROUP BY o.order_status
ORDER BY orders_without_items DESC;


-- ============================================================
-- SECTION C. MISSING VALUES
-- ============================================================

-- Q19: Which timestamps are missing, by order status?
SELECT
    order_status,
    COUNT(*) AS orders,
    SUM(order_approved_at IS NULL) AS no_approved_date,
    SUM(order_delivered_carrier_date IS NULL) AS no_carrier_date,
    SUM(order_delivered_customer_date IS NULL) AS no_delivery_date
FROM raw_orders
GROUP BY order_status
ORDER BY orders DESC;


-- Q20: Which product attributes are missing or zero?
SELECT
    COUNT(*) AS products,
    SUM(product_category_name IS NULL) AS no_category,
    SUM(product_weight_g IS NULL) AS no_weight,
    SUM(product_length_cm IS NULL) AS no_length,
    SUM(product_height_cm IS NULL) AS no_height,
    SUM(product_width_cm IS NULL) AS no_width,
    SUM(product_weight_g = 0) AS zero_weight
FROM raw_products;


-- Q21: Which product categories have no English translation?
SELECT p.product_category_name, COUNT(*) AS products
FROM raw_products p
LEFT JOIN raw_product_category_name_translation t
       ON t.product_category_name = p.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL
GROUP BY p.product_category_name;


-- ============================================================
-- SECTION D. IMPOSSIBLE VALUES AND OUTLIERS
-- ============================================================

-- Q22: How many orders have impossible date sequences?
SELECT
    SUM(CAST(order_delivered_customer_date AS DATETIME) < CAST(order_purchase_timestamp AS DATETIME)) AS delivered_before_purchase,
    SUM(CAST(order_delivered_carrier_date AS DATETIME) < CAST(order_purchase_timestamp AS DATETIME)) AS carrier_pickup_before_purchase,
    SUM(CAST(order_delivered_customer_date AS DATETIME) < CAST(order_delivered_carrier_date AS DATETIME)) AS delivered_before_carrier_pickup,
    SUM(CAST(order_estimated_delivery_date AS DATETIME) < CAST(order_purchase_timestamp AS DATETIME)) AS estimate_before_purchase
FROM raw_orders;


-- Q23: How long do deliveries take, and how extreme are the slowest?
SELECT
    COUNT(*) AS delivered_orders,
    MIN(days) AS min_days,
    ROUND(AVG(days), 1) AS avg_days,
    MAX(days) AS max_days,
    SUM(days > 60) AS over_60_days,
    SUM(days > 100) AS over_100_days
FROM (
    SELECT DATEDIFF(
               CAST(order_delivered_customer_date AS DATETIME),
               CAST(order_purchase_timestamp AS DATETIME)
           ) AS days
    FROM raw_orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
) d;


-- Q24: What does the price and freight distribution look like?
SELECT
    COUNT(*) AS item_rows,
    MIN(price) AS min_price,
    ROUND(AVG(price), 2) AS avg_price,
    MAX(price) AS max_price,
    SUM(price <= 0) AS non_positive_price,
    SUM(freight_value = 0) AS zero_freight,
    MAX(freight_value) AS max_freight,
    SUM(freight_value > price) AS freight_above_price
FROM raw_order_items;


-- Q25: Which 10 items have the highest prices? (outlier review)
SELECT order_id, product_id, price, freight_value
FROM raw_order_items
ORDER BY price DESC
LIMIT 10;


-- Q26: What are the review score values? (valid range is 1 to 5)
SELECT review_score, COUNT(*) AS reviews
FROM raw_order_reviews
GROUP BY review_score
ORDER BY review_score;


-- ============================================================
-- SECTION E. PAYMENTS AND KEYS
-- ============================================================

-- Q27: Do payments match items + freight per order?
-- Both sides are summed per order first, to avoid a join fan-out.
WITH items AS (
    SELECT order_id, SUM(price + freight_value) AS items_total
    FROM raw_order_items
    GROUP BY order_id
),
pay AS (
    SELECT order_id, SUM(payment_value) AS paid_total
    FROM raw_order_payments
    GROUP BY order_id
)
SELECT
    COUNT(*) AS orders_compared,
    SUM(ABS(i.items_total - p.paid_total) > 0.01) AS mismatched_orders,
    ROUND(SUM(p.paid_total - i.items_total), 2) AS net_difference
FROM items i
JOIN pay p ON p.order_id = i.order_id;


-- Q28: How are payment types used, and are there zero-value payments?
SELECT
    payment_type,
    COUNT(*) AS payments,
    SUM(payment_value = 0) AS zero_value_payments,
    ROUND(SUM(payment_value), 2) AS total_paid
FROM raw_order_payments
GROUP BY payment_type
ORDER BY payments DESC;


-- Q29: Is (order_id, order_item_id) unique in raw_order_items?
SELECT order_id, order_item_id, COUNT(*) AS duplicate_count
FROM raw_order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;


-- Q30: Are there orphan keys? (rows pointing to something that does not exist)
SELECT 'items without an order' AS issue, COUNT(*) AS rows_affected
FROM raw_order_items i
LEFT JOIN raw_orders o ON o.order_id = i.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'orders without a customer', COUNT(*)
FROM raw_orders o
LEFT JOIN raw_customers c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL
UNION ALL
SELECT 'items without a product', COUNT(*)
FROM raw_order_items i
LEFT JOIN raw_products p ON p.product_id = i.product_id
WHERE p.product_id IS NULL
UNION ALL
SELECT 'items without a seller', COUNT(*)
FROM raw_order_items i
LEFT JOIN raw_sellers s ON s.seller_id = i.seller_id
WHERE s.seller_id IS NULL
UNION ALL
SELECT 'reviews without an order', COUNT(*)
FROM raw_order_reviews r
LEFT JOIN raw_orders o ON o.order_id = r.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'payments without an order', COUNT(*)
FROM raw_order_payments p
LEFT JOIN raw_orders o ON o.order_id = p.order_id
WHERE o.order_id IS NULL;


-- Q31: customer_id vs customer_unique_id: which one identifies a real person?
SELECT
    COUNT(*) AS customer_rows,
    COUNT(DISTINCT customer_id) AS distinct_customer_id,
    COUNT(DISTINCT customer_unique_id) AS distinct_real_customers
FROM raw_customers;


-- ============================================================
-- SECTION F. PIPELINE OUTPUT CHECKS
-- ============================================================

-- Q32: Does revenue agree across every layer?
-- All four numbers must be identical (13220248.93).
SELECT
    (SELECT ROUND(SUM(revenue), 2) FROM fact_orders) AS fact_orders_revenue,
    (SELECT ROUND(SUM(price), 2) FROM fact_items) AS fact_items_revenue,
    (SELECT ROUND(SUM(monetary), 2) FROM rfm) AS rfm_revenue,
    (SELECT ROUND(SUM(i.price), 2)
       FROM raw_order_items i
       JOIN raw_orders o ON o.order_id = i.order_id
      WHERE o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL) AS rebuilt_from_raw_revenue;


-- Q33: Do order and customer counts agree across layers?
SELECT
    (SELECT COUNT(*) FROM fact_orders) AS fact_orders_rows,
    (SELECT COUNT(DISTINCT order_id) FROM fact_orders) AS fact_orders_distinct_orders,
    (SELECT COUNT(DISTINCT order_id) FROM fact_items) AS fact_items_distinct_orders,
    (SELECT COUNT(DISTINCT customer_unique_id) FROM fact_orders) AS customers_in_fact_orders,
    (SELECT COUNT(*) FROM rfm) AS customers_in_rfm;


-- Q34: How many orders in fact_orders have no review score?
SELECT
    COUNT(*) AS orders,
    SUM(review_score IS NULL) AS orders_without_review,
    ROUND(100 * AVG(review_score IS NULL), 2) AS pct_without_review
FROM fact_orders;


-- Q35: How much revenue sits in the 'unknown' category?
-- 'unknown' covers both missing categories and untranslated ones (see Q21).
SELECT
    COUNT(*) AS item_rows,
    SUM(category = 'unknown') AS unknown_items,
    ROUND(100 * AVG(category = 'unknown'), 2) AS pct_items_unknown,
    ROUND(SUM(CASE WHEN category = 'unknown' THEN price END), 2) AS unknown_revenue
FROM fact_items;


-- ============================================================
-- SECTION G. DETAIL DRILL-DOWN
-- ============================================================

-- Q36: Which orders have an impossible delivery chronology? (detail for Q22)
-- Shows the first 50 rows only.
SELECT
    order_id,
    order_purchase_timestamp,
    order_delivered_carrier_date,
    order_delivered_customer_date
FROM raw_orders
WHERE
    (
        order_delivered_carrier_date IS NOT NULL
        AND CAST(order_delivered_carrier_date AS DATETIME) < CAST(order_purchase_timestamp AS DATETIME)
    )
    OR
    (
        order_delivered_customer_date IS NOT NULL
        AND CAST(order_delivered_customer_date AS DATETIME) < CAST(order_purchase_timestamp AS DATETIME)
    )
LIMIT 50;
