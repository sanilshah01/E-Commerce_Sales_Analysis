IF OBJECT_ID('dim_customer', 'V') IS NOT NULL
    DROP VIEW dim_customer;
GO

CREATE VIEW dim_customer AS

WITH base AS (
    SELECT
        c.user_id AS customer_id,
        c.name,
        c.email,
        c.gender,
        c.city,
        CAST(c.signup_date AS DATE) AS signup_date
    FROM customers c
),

customer_orders AS (
    SELECT
        fs.customer_id,
        COUNT(DISTINCT fs.order_id) AS total_orders,
        ISNULL(SUM(fs.revenue), 0) AS total_spent,
        MAX(fs.order_date) AS last_order_date
    FROM fact_sales fs
    GROUP BY fs.customer_id
),

rfm_calc AS (
    SELECT 
        co.*,
        DATEDIFF(DAY, co.last_order_date, GETDATE()) AS recency_days,
        co.total_orders AS frequency,
        co.total_spent AS monetary
    FROM customer_orders co
),

final_join AS (
    SELECT
        b.customer_id,
        b.name,
        b.email,
        b.gender,
        b.city,
        b.signup_date,

        ISNULL(r.total_orders, 0) AS total_orders,
        ISNULL(r.total_spent, 0) AS total_spent,

        CASE
            WHEN ISNULL(r.total_orders, 0) = 0 THEN 0
            ELSE r.total_spent * 1.0 / r.total_orders
        END AS avg_order_value,

        r.last_order_date,
        ISNULL(r.recency_days, 999) AS recency_days,
        ISNULL(r.frequency, 0) AS frequency,
        ISNULL(r.monetary, 0) AS monetary

    FROM base b
    LEFT JOIN rfm_calc r
        ON b.customer_id = r.customer_id
),

segmentation AS (
    SELECT
        *,
        CASE
            WHEN recency_days <= 30 AND frequency >= 5 THEN 'High Value'
            WHEN recency_days <= 60 AND frequency >= 3 THEN 'Loyal'
            WHEN recency_days > 90 THEN 'At Risk'
            WHEN frequency = 0 THEN 'No Purchase'
            ELSE 'Regular'
        END AS customer_segment
    FROM final_join
)

SELECT * FROM segmentation;

-- SELECT * FROM dim_customer