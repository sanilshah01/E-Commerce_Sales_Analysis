-- orders
SELECT 
    COUNT(*) AS total,
    SUM(CASE WHEN order_id IS  NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN user_id IS  NULL THEN 1 ELSE 0 END) AS null_user
FROM orders;


-- order_items
SELECT 
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product
FROM order_items;

-- orders duplicates

SELECT order_id ,count(*)
FROM orders
GROUP BY order_id
HAVING count(*) >1

-- items duplicate
SELECT order_item_id, COUNT(*)
FROM order_items
GROUP BY order_item_id
HAVING COUNT(*) > 1;

-- orphan items (bad join risk)
SELECT COUNT(*)
FROM order_items oi
LEFT JOIN orders o
ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

--total_item_revenue
SELECT 
    SUM(item_total) AS total_item_revenue
FROM order_items;

SELECT 
    SUM(total_amount) 
FROM orders;

SELECT user_id, COUNT(*) AS cnt
FROM customers
GROUP BY user_id
HAVING COUNT(*) > 1;

SELECT 
    COUNT(*) AS total,
    COUNT(user_id) AS not_null
FROM customers;
