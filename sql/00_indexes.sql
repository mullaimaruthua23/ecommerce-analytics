-- ============================================================
-- 00_indexes.sql  (run ONCE, then never again)
-- Raw ids were loaded as TEXT, so joins are slow without indexes.
-- Ids are 32 characters, so a 32-character prefix is enough.
-- If you re-run load_raw.py or build_master.py, the tables are
-- replaced and these indexes must be created again.
-- "Duplicate key name" means the index already exists: skip it.
-- ============================================================

CREATE INDEX idx_raw_orders_order_id      ON raw_orders (order_id(32));
CREATE INDEX idx_raw_orders_customer_id   ON raw_orders (customer_id(32));
CREATE INDEX idx_raw_items_order_id       ON raw_order_items (order_id(32));
CREATE INDEX idx_raw_items_product_id     ON raw_order_items (product_id(32));
CREATE INDEX idx_raw_items_seller_id      ON raw_order_items (seller_id(32));
CREATE INDEX idx_raw_reviews_order_id     ON raw_order_reviews (order_id(32));
CREATE INDEX idx_raw_payments_order_id    ON raw_order_payments (order_id(32));
CREATE INDEX idx_raw_customers_customer   ON raw_customers (customer_id(32));
CREATE INDEX idx_raw_products_product_id  ON raw_products (product_id(32));
CREATE INDEX idx_raw_sellers_seller_id    ON raw_sellers (seller_id(32));
CREATE INDEX idx_fact_orders_order_id     ON fact_orders (order_id(32));
CREATE INDEX idx_fact_items_order_id      ON fact_items (order_id(32));
CREATE INDEX idx_rfm_customer_unique_id   ON rfm (customer_unique_id(32));
