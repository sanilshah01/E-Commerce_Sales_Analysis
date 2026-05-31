IF OBJECT_ID('fact_sales', 'V') IS NOT NULL
    DROP VIEW fact_sales;
GO

CREATE VIEW fact_sales AS

WITH

-- Orders Clean
orders_dedup AS (
    SELECT
        o.order_id,
        o.user_id AS customer_id,
        CAST(o.order_date AS DATE) AS order_date,
        o.order_status,
        o.total_amount,
        ROW_NUMBER() OVER (PARTITION BY o.order_id ORDER BY o.order_date DESC) AS rn
    FROM orders o
    WHERE o.order_id IS NOT NULL
      AND o.user_id IS NOT NULL
      AND o.order_date IS NOT NULL
),
clean_orders AS (
    SELECT * FROM orders_dedup WHERE rn = 1
),

-- Order Items Clean
items_dedup AS (
    SELECT
        oi.order_item_id,
        oi.order_id,
        oi.product_id,
        oi.quantity,
        oi.item_price,
        oi.item_total,
        ROW_NUMBER() OVER (PARTITION BY oi.order_item_id ORDER BY oi.order_id) AS rn
    FROM order_items oi
    WHERE oi.order_id IS NOT NULL
      AND oi.product_id IS NOT NULL
      AND oi.quantity > 0
),
clean_items AS (
    SELECT * FROM items_dedup WHERE rn = 1
),

-- Products Clean
products_dedup AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.brand,
        p.price,
        (p.price * 0.7) AS cost_price,
        ROW_NUMBER() OVER (PARTITION BY p.product_id ORDER BY p.product_id) AS rn
    FROM products p
    WHERE p.product_id IS NOT NULL
),
clean_products AS (
    SELECT * FROM products_dedup WHERE rn = 1
),

-- Payments Clean
payments_ranked AS (
    SELECT
        pay.order_id,
        pay.payment_method,
        ROW_NUMBER() OVER (PARTITION BY pay.order_id ORDER BY pay.payment_id DESC) AS rn
    FROM payments pay
    WHERE pay.order_id IS NOT NULL
),
clean_payments AS (
    SELECT order_id, payment_method
    FROM payments_ranked
    WHERE rn = 1
),

-- Shipping Clean
shipping_ranked AS (
    SELECT
        s.order_id,
        CAST(s.shipping_date AS DATE)  AS shipping_date,
        CAST(s.delivery_date AS DATE)  AS delivery_date,
        s.delivery_status,
        s.delivery_days,
        ROW_NUMBER() OVER (PARTITION BY s.order_id ORDER BY s.delivery_date DESC) AS rn
    FROM shipping s
    WHERE s.order_id IS NOT NULL
),
clean_shipping AS (
    SELECT
        order_id,
        shipping_date,
        delivery_date,
        delivery_status,
        delivery_days
    FROM shipping_ranked
    WHERE rn = 1
),

-- FINAL JOIN
joined AS (
    SELECT
        o.order_id,
        o.customer_id,
        i.product_id,

        -- time
        o.order_date,
        YEAR(o.order_date) AS order_year,
        MONTH(o.order_date) AS order_month,

        -- metrics
        i.quantity,
        i.item_total AS revenue,
        (cp.cost_price * i.quantity) AS cost,
        (i.item_total - (cp.cost_price * i.quantity)) AS profit,

        CASE
            WHEN i.item_total = 0 THEN 0
            ELSE (i.item_total - (cp.cost_price * i.quantity)) / i.item_total
        END AS margin_pct,

        -- business fields
        o.order_status,
        pay.payment_method,
        ship.delivery_days,
        ship.delivery_status,

        -- product info
        cp.category,
        cp.brand,
        CASE 
             WHEN ship.delivery_days > 5 THEN 1 
             ELSE 0 
        END AS delayed

    FROM clean_orders o
    JOIN clean_items i ON o.order_id = i.order_id
    LEFT JOIN clean_products cp ON i.product_id = cp.product_id
    LEFT JOIN clean_payments pay ON o.order_id = pay.order_id
    LEFT JOIN clean_shipping ship ON o.order_id = ship.order_id
)

SELECT * FROM joined;

-- SELECT * FROM fact_sales
