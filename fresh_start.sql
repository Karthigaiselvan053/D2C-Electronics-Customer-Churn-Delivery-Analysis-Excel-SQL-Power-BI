/* ============================================================
   D2C ELECTRONICS E-COMMERCE PROJECT 
   ============================================================ */

-- ---------- 1. CREATE FRESH DATABASE ----------
CREATE DATABASE D2C_Analytics;

USE D2C_Analytics;


/* ============================================================
   STEP 1: IMPORT RAW CSVs
   >>> STOP HERE AND DO THIS MANUALLY BEFORE CONTINUING <<<
   Right-click D2C_Analytics > Tasks > Import Flat File
   Import all 6 CSVs, naming the tables exactly:
     stg_customers, stg_products, stg_orders,
     stg_delivery, stg_support, stg_marketing
   On "Modify Columns", set every column to NVARCHAR.
   Once all 6 are imported, come back and run the rest below.
   ============================================================ */


/* ============================================================
   STEP 2: FINAL TYPED TABLES
   ============================================================ */

CREATE TABLE customers (
    customer_id     VARCHAR(20) PRIMARY KEY,
    name            VARCHAR(200),
    email           VARCHAR(200),
    city            VARCHAR(100),
    signup_date     DATE,
    gender          VARCHAR(20),
    age             INT,
    referral_source VARCHAR(100)
);

CREATE TABLE products (
    product_id      VARCHAR(20) PRIMARY KEY,
    product_name    VARCHAR(200),
    category        VARCHAR(100),
    price           DECIMAL(10,2),
    cost            DECIMAL(10,2)
);

CREATE TABLE orders (
    order_id        VARCHAR(20) PRIMARY KEY,
    customer_id     VARCHAR(20) REFERENCES customers(customer_id),
    order_date      DATE,
    product_id      VARCHAR(20) REFERENCES products(product_id),
    quantity        INT,
    order_value     DECIMAL(10,2),
    payment_method  VARCHAR(50),
    order_status    VARCHAR(50)
);

CREATE TABLE delivery_performance (
    order_id                VARCHAR(20) REFERENCES orders(order_id),
    promised_delivery_date  DATE,
    actual_delivery_date    DATE NULL,
    delivery_partner        VARCHAR(50),
    delivery_status         VARCHAR(50)
);

CREATE TABLE support_tickets (
    ticket_id               VARCHAR(20) PRIMARY KEY,
    customer_id             VARCHAR(20),
    order_id                VARCHAR(20),
    issue_type              VARCHAR(100),
    ticket_date             DATE,
    resolution_time_hours   DECIMAL(6,1),
    satisfaction_score      INT NULL
);

CREATE TABLE marketing_spend (
    [date]       DATE,
    channel      VARCHAR(50),
    spend        DECIMAL(10,2),
    impressions  INT,
    clicks       INT
);

/* ============================================================
   STEP 3: CLEAN + LOAD INTO FINAL TABLES
   ============================================================ */

-- ---------- customers ----------
INSERT INTO customers (customer_id, name, email, city, signup_date, gender, age, referral_source)
SELECT customer_id, name, email, city, signup_date, gender, age, referral_source
FROM (
    SELECT
        customer_id,
        name,
        NULLIF(LTRIM(RTRIM(email)), '') AS email,
        UPPER(LEFT(LTRIM(RTRIM(city)),1)) + LOWER(SUBSTRING(LTRIM(RTRIM(city)),2,100)) AS city,
        COALESCE(
            TRY_CONVERT(DATE, signup_date, 23),
            TRY_CONVERT(DATE, signup_date, 103)
        ) AS signup_date,
        NULLIF(gender, '') AS gender,
        TRY_CAST(age AS INT) AS age,
        referral_source,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY (SELECT NULL)) AS rn
    FROM stg_customers
    WHERE customer_id IS NOT NULL
) t
WHERE rn = 1;

-- ---------- products ----------
INSERT INTO products (product_id, product_name, category, price, cost)
SELECT product_id, product_name, category, price, cost
FROM (
    SELECT
        product_id, product_name, category,
        TRY_CAST(price AS DECIMAL(10,2)) AS price,
        TRY_CAST(cost AS DECIMAL(10,2)) AS cost,
        ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY (SELECT NULL)) AS rn
    FROM stg_products
    WHERE product_id IS NOT NULL
) t
WHERE rn = 1;
select * from products

-- ---------- orders ----------
INSERT INTO orders (order_id, customer_id, order_date, product_id, quantity, order_value, payment_method, order_status)
SELECT order_id, customer_id, order_date, product_id, quantity, order_value, payment_method, order_status
FROM (
    SELECT
        s.order_id,
        s.customer_id,
        TRY_CONVERT(DATE, s.order_date, 23) AS order_date,
        s.product_id,
        TRY_CAST(s.quantity AS INT) AS quantity,
        COALESCE(
            TRY_CAST(s.order_value AS DECIMAL(10,2)),
            p.price * TRY_CAST(s.quantity AS INT)
        ) AS order_value,
        s.payment_method,
        s.order_status,
        ROW_NUMBER() OVER (PARTITION BY s.order_id ORDER BY (SELECT NULL)) AS rn
    FROM stg_orders s
    LEFT JOIN products p ON s.product_id = p.product_id
    WHERE s.order_id IS NOT NULL
) t
WHERE rn = 1;

-- ---------- delivery ----------
INSERT INTO delivery_performance (order_id, promised_delivery_date, actual_delivery_date, delivery_partner, delivery_status)
SELECT order_id, promised_delivery_date, actual_delivery_date, delivery_partner, delivery_status
FROM (
    SELECT
        order_id,
        TRY_CONVERT(DATE, promised_delivery_date, 23) AS promised_delivery_date,
        TRY_CONVERT(DATE, actual_delivery_date, 23) AS actual_delivery_date,
        delivery_partner,
        delivery_status,
        ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY (SELECT NULL)) AS rn
    FROM stg_delivery
    WHERE order_id IS NOT NULL
) t
WHERE rn = 1;

-- ---------- support tickets ----------
INSERT INTO support_tickets (ticket_id, customer_id, order_id, issue_type, ticket_date, resolution_time_hours, satisfaction_score)
SELECT ticket_id, customer_id, order_id, issue_type, ticket_date, resolution_time_hours, satisfaction_score
FROM (
    SELECT
        ticket_id, customer_id, order_id, issue_type,
        TRY_CONVERT(DATE, ticket_date, 23) AS ticket_date,
        TRY_CAST(resolution_time_hours AS DECIMAL(6,1)) AS resolution_time_hours,
        TRY_CAST(satisfaction_score AS INT) AS satisfaction_score,
        ROW_NUMBER() OVER (PARTITION BY ticket_id ORDER BY (SELECT NULL)) AS rn
    FROM stg_support
    WHERE ticket_id IS NOT NULL
) t
WHERE rn = 1;

-- ---------- marketing spend ----------
INSERT INTO marketing_spend ([date], channel, spend, impressions, clicks)
SELECT DISTINCT
    TRY_CONVERT(DATE, [date], 23),
    channel,
    TRY_CAST(spend AS DECIMAL(10,2)),
    TRY_CAST(impressions AS INT),
    TRY_CAST(clicks AS INT)
FROM stg_marketing;

/* ============================================================
   STEP 4: SANITY CHECKS
   ============================================================ */
SELECT COUNT(*) AS customers_loaded FROM customers;
SELECT COUNT(*) AS products_loaded FROM products;
SELECT COUNT(*) AS orders_loaded FROM orders;
SELECT COUNT(*) AS delivery_loaded FROM delivery_performance;
SELECT COUNT(*) AS support_loaded FROM support_tickets;
SELECT COUNT(*) AS marketing_loaded FROM marketing_spend;

SELECT COUNT(*) AS orders_missing_value FROM orders WHERE order_value IS NULL;
SELECT COUNT(*) AS customers_bad_dates FROM customers WHERE signup_date IS NULL;

SELECT MIN(order_date) AS earliest_date,
       MAX(order_date) AS latest_date,
       COUNT(DISTINCT order_date) AS distinct_dates
FROM orders;

/* ============================================================
   STEP 5: ANALYSIS QUERIES
   ============================================================ */

-- Q1: Does late delivery correlate with churn?
DECLARE @dataset_today DATE = (SELECT MAX(order_date) FROM orders);

WITH order_delay AS (
    SELECT o.customer_id, o.order_id,
           DATEDIFF(day, d.promised_delivery_date, d.actual_delivery_date) AS delay_days
    FROM orders o
    JOIN delivery_performance d ON o.order_id = d.order_id
    WHERE d.actual_delivery_date IS NOT NULL
),
customer_status AS (
    SELECT customer_id,
           MAX(order_date) AS last_order_date,
           DATEDIFF(day, MAX(order_date), @dataset_today) AS days_since_last_order
    FROM orders
    GROUP BY customer_id
)
SELECT
    CASE WHEN od.delay_days > 2 THEN 'Late' ELSE 'On Time' END AS delivery_bucket,
    COUNT(DISTINCT cs.customer_id) AS customers,
    CAST(COUNT(DISTINCT CASE WHEN cs.days_since_last_order > 90 THEN cs.customer_id END) AS FLOAT)
        / COUNT(DISTINCT cs.customer_id) AS churn_rate
FROM order_delay od
JOIN customer_status cs ON od.customer_id = cs.customer_id
GROUP BY CASE WHEN od.delay_days > 2 THEN 'Late' ELSE 'On Time' END;

-- Q2: Which delivery partner has the worst on-time performance?
SELECT
    delivery_partner,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN actual_delivery_date > promised_delivery_date THEN 1 ELSE 0 END) AS late_orders,
    ROUND(100.0 * SUM(CASE WHEN actual_delivery_date > promised_delivery_date THEN 1 ELSE 0 END) / COUNT(*), 1) AS late_pct
FROM delivery_performance
WHERE actual_delivery_date IS NOT NULL
GROUP BY delivery_partner
ORDER BY late_pct DESC;

-- Q3: CAC vs revenue by acquisition channel
WITH revenue_by_channel AS (
    SELECT c.referral_source, SUM(o.order_value) AS total_revenue, COUNT(DISTINCT c.customer_id) AS customers
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.referral_source
),
spend_by_channel AS (
    SELECT channel, SUM(spend) AS total_spend
    FROM marketing_spend
    GROUP BY channel
)
SELECT r.referral_source, r.total_revenue, r.customers, s.total_spend,
       ROUND(s.total_spend / NULLIF(r.customers,0), 2) AS cac,
       ROUND(r.total_revenue / NULLIF(r.customers,0), 2) AS revenue_per_customer
FROM revenue_by_channel r
JOIN spend_by_channel s ON r.referral_source = s.channel
ORDER BY revenue_per_customer DESC;

-- Q4: Support resolution time vs repeat purchase
SELECT
    CASE WHEN st.resolution_time_hours <= 24 THEN 'Fast (<24h)' ELSE 'Slow (>24h)' END AS resolution_bucket,
    AVG(CAST(order_counts.num_orders AS FLOAT)) AS avg_orders_per_customer
FROM support_tickets st
JOIN (
    SELECT customer_id, COUNT(*) AS num_orders
    FROM orders
    GROUP BY customer_id
) order_counts ON st.customer_id = order_counts.customer_id
GROUP BY CASE WHEN st.resolution_time_hours <= 24 THEN 'Fast (<24h)' ELSE 'Slow (>24h)' END;




UPDATE c
SET c.age = TRY_CAST(TRY_CAST(s.age AS FLOAT) AS INT)
FROM customers c
JOIN stg_customers s ON c.customer_id = s.customer_id;

SELECT
    COUNT(*) AS total_customers,
    COUNT(age) AS age_present,
    ROUND(100.0 * (COUNT(*) - COUNT(age)) / COUNT(*), 1) AS pct_missing
FROM customers;

SELECT TOP 10 satisfaction_score FROM stg_support;

UPDATE t
SET t.satisfaction_score = TRY_CAST(TRY_CAST(s.satisfaction_score AS FLOAT) AS INT)
FROM support_tickets t
JOIN stg_support s ON t.ticket_id = s.ticket_id;

SELECT
    COUNT(*) AS total_tickets,
    COUNT(satisfaction_score) AS score_present,
    ROUND(100.0 * (COUNT(*) - COUNT(satisfaction_score)) / COUNT(*), 1) AS pct_missing
FROM support_tickets;

