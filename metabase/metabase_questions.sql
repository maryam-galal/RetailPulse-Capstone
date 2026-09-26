-- ============================================================
-- RetailPulse - Metabase Saved Questions
-- Database: retailpulse
-- ============================================================


-- ============================================================
-- 1. Daily Net Revenue, Orders & AOV
-- ============================================================

SELECT
    d.full_date AS order_date,
    SUM(f.net_amount) AS net_revenue,
    COUNT(DISTINCT f.order_id) AS order_count,
    ROUND(
        SUM(f.net_amount) / COUNT(DISTINCT f.order_id),
        2
    ) AS average_order_value
FROM retailpulse.fact_orders_gold f
JOIN retailpulse.dim_date_gold d
    ON f.date_key = d.date_key
WHERE f.order_status <> 'cancelled'
GROUP BY d.full_date
ORDER BY d.full_date;


-- ============================================================
-- 2. Revenue by Store
-- ============================================================

SELECT
    s.store_name AS store,
    SUM(f.net_amount) AS net_revenue,
    COUNT(DISTINCT f.order_id) AS order_count
FROM retailpulse.fact_orders_gold f
JOIN retailpulse.dim_store_gold s
    ON f.store_key = s.store_key
WHERE f.order_status <> 'cancelled'
GROUP BY s.store_name
ORDER BY net_revenue DESC;


-- ============================================================
-- 3. Revenue by Product Category
-- ============================================================

SELECT
    p.category,
    SUM(f.net_amount) AS net_revenue,
    COUNT(DISTINCT f.order_id) AS order_count
FROM retailpulse.fact_orders_gold f
JOIN retailpulse.dim_product_gold p
    ON f.product_key = p.product_key
WHERE f.order_status <> 'cancelled'
GROUP BY p.category
ORDER BY net_revenue DESC;


-- ============================================================
-- 4. Order & Delivery Lifecycle
-- ============================================================

SELECT
    event_type AS lifecycle_stage,
    COUNT(DISTINCT order_id) AS orders
FROM retailpulse.fact_fulfillment_gold
GROUP BY event_type
ORDER BY CASE event_type
    WHEN 'packed' THEN 1
    WHEN 'shipped' THEN 2
    WHEN 'delivered' THEN 3
    ELSE 4
END;


-- ============================================================
-- 5. Delivery SLA Summary
-- ============================================================

SELECT
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(
        DISTINCT CASE
            WHEN is_late = true THEN order_id
        END
    ) AS sla_misses,
    ROUND(
        AVG(delivery_duration_hours),
        2
    ) AS avg_delivery_hours
FROM retailpulse.fact_fulfillment_gold
WHERE event_type = 'delivered';


-- ============================================================
-- 6. Products at Inventory Risk
-- ============================================================

SELECT
    x.product_id,
    p.product_name,
    p.category,
    x.store_id,
    s.store_name,
    x.stock_on_hand,
    x.inventory_risk
FROM (
    SELECT
        i.*,
        ROW_NUMBER() OVER (
            PARTITION BY product_id, store_id
            ORDER BY snapshot_at DESC
        ) AS rn
    FROM retailpulse.inventory_risk_gold i
) x
JOIN retailpulse.dim_product_gold p
    ON x.product_id = p.product_id
JOIN retailpulse.dim_store_gold s
    ON x.store_id = s.store_id
WHERE x.rn = 1
  AND x.inventory_risk IN ('LOW_STOCK', 'OUT_OF_STOCK')
ORDER BY
    CASE x.inventory_risk
        WHEN 'OUT_OF_STOCK' THEN 1
        WHEN 'LOW_STOCK' THEN 2
        ELSE 3
    END,
    x.stock_on_hand;


-- ============================================================
-- 7. Stores with Inventory Risk
-- ============================================================

SELECT
    s.store_name AS store,
    SUM(
        CASE
            WHEN x.inventory_risk = 'OUT_OF_STOCK'
            THEN 1
            ELSE 0
        END
    ) AS out_of_stock_products,
    SUM(
        CASE
            WHEN x.inventory_risk = 'LOW_STOCK'
            THEN 1
            ELSE 0
        END
    ) AS low_stock_products,
    SUM(x.stock_on_hand) AS stock_on_hand
FROM (
    SELECT
        i.*,
        ROW_NUMBER() OVER (
            PARTITION BY product_id, store_id
            ORDER BY snapshot_at DESC
        ) AS rn
    FROM retailpulse.inventory_risk_gold i
) x
JOIN retailpulse.dim_store_gold s
    ON x.store_id = s.store_id
WHERE x.rn = 1
GROUP BY s.store_name
ORDER BY
    out_of_stock_products DESC,
    low_stock_products DESC;


-- ============================================================
-- 8. Digital Funnel
-- ============================================================

SELECT
    channel,
    SUM(product_views) AS product_views,
    SUM(cart_starts) AS cart_starts,
    SUM(checkout_starts) AS checkout_starts,
    SUM(confirmed_orders) AS confirmed_orders
FROM retailpulse.digital_funnel_gold
WHERE event_date IS NOT NULL
  AND channel IS NOT NULL
GROUP BY channel
ORDER BY channel;


-- ============================================================
-- 9. Data Quality Status
-- ============================================================

SELECT
    table_name,
    total_records,
    valid_records,
    rejected_records,
    duplicate_records,
    dq_status
FROM retailpulse.data_quality_gold
ORDER BY table_name;