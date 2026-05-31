IF OBJECT_ID('dim_product', 'V') IS NOT NULL
    DROP VIEW dim_product;
GO

CREATE VIEW dim_product AS

WITH product_dedup AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.brand,
        p.price,
        p.rating,
        ROW_NUMBER() OVER (
            PARTITION BY p.product_id
            ORDER BY p.product_id
        ) AS rn
    FROM products p
    WHERE p.product_id IS NOT NULL
),

clean_product AS (
    SELECT
        product_id,
        product_name,
        category,
        brand,
        price,
        rating
    FROM product_dedup
    WHERE rn = 1
),

product_sales AS (
    SELECT
        fs.product_id,
        COUNT(DISTINCT fs.order_id) AS total_orders,
        ISNULL(SUM(fs.revenue), 0) AS total_sales,
        ISNULL(SUM(fs.quantity), 0) AS total_quantity,
        ISNULL(SUM(fs.profit), 0) AS total_profit,
        ISNULL(AVG(CASE 
            WHEN fs.quantity = 0 THEN NULL
            ELSE fs.revenue * 1.0 / fs.quantity
        END), 0) AS avg_selling_price
    FROM fact_sales fs
    GROUP BY fs.product_id
),

final_join AS (
    SELECT
        cp.product_id,
        cp.product_name,
        cp.category,
        cp.brand,
        cp.price,
        cp.rating,

        ISNULL(ps.total_orders, 0) AS total_orders,
        ISNULL(ps.total_sales, 0) AS total_sales,
        ISNULL(ps.total_quantity, 0) AS total_quantity,
        ISNULL(ps.total_profit, 0) AS total_profit,
        ISNULL(ps.avg_selling_price, 0) AS avg_selling_price

    FROM clean_product cp
    LEFT JOIN product_sales ps
        ON cp.product_id = ps.product_id
)

SELECT * FROM final_join;
GO

-- SELECT * FROM dim_product
