-- CUSTOMER RETENTION & TRANSACTION ANALYTICS --

CREATE DATABASE RT;
USE RT;

-- 1. CUSTOMERS
CREATE TABLE Customers (
    customer_id                VARCHAR(10) PRIMARY KEY,
    signup_date                 DATE,
    location_clean_city          VARCHAR(50),
    acquisition_clean_channel     VARCHAR(20)
);

-- 2. PRODUCTS
CREATE TABLE Products (
    product_id                 VARCHAR(10) PRIMARY KEY,
    product_name                 VARCHAR(100),
    product_category              VARCHAR(30),
    unit_cost                    DECIMAL(10,2),
    retail_price                 DECIMAL(10,2)
);

-- 3. DATE TABLE
CREATE TABLE Date_Table (
    date_key                   DATE PRIMARY KEY,
    year                       INT,
    quarter                     INT,
    month                       INT,
    month_name                   VARCHAR(15),
    day_of_month                  INT,
    day_of_week                   VARCHAR(15),
    is_weekend                   BOOLEAN
);

-- 4. TRANSACTIONS
CREATE TABLE Transactions (
    transaction_id              VARCHAR(12) PRIMARY KEY,
    customer_id                 VARCHAR(10),
    product_id                  VARCHAR(10),
    transaction_date              DATE,
    transaction_time              TIME,
    quantity                    INT,
    unit_price                   DECIMAL(10,2),
    discount_amount               DECIMAL(10,2),
    total_amount                  DECIMAL(10,2),
    payment_method                VARCHAR(20),
    order_status                  VARCHAR(20)
);

SET GLOBAL local_infile = 1;

-- 5. CUSTOMER SUPPORT
CREATE TABLE Customers_Support (
    ticket_id                   VARCHAR(10) PRIMARY KEY,
    customer_id                  VARCHAR(10),
    transaction_id                VARCHAR(12),
    ticket_date                   DATE,
    issue_category                 VARCHAR(30),
    ticket_status                  VARCHAR(20),
    resolution_hours                DECIMAL(6,2),
    satisfaction_score               DECIMAL(2,1),
    related_order_value              DECIMAL(10,2),
    related_category                VARCHAR(30)
);

-- 6. DATE TABLE STAGING — dates loaded as text to avoid silent failure
CREATE TABLE Date_Table_Staging (
    date_key                    VARCHAR(20),
    year                        INT,
    quarter                      INT,
    month                        INT,
    month_name                    VARCHAR(15),
    day_of_month                   INT,
    day_of_week                    VARCHAR(15),
    is_weekend                    VARCHAR(10)
);

-- 7. CUSTOMER SUPPORT STAGING — numeric fields loaded as text
--    because resolution_hours / satisfaction_score / related_order_value
--    are blank for open tickets, and DECIMAL columns reject blank strings
CREATE TABLE Customers_Support_Staging (
    ticket_id                    VARCHAR(10),
    customer_id                   VARCHAR(10),
    transaction_id                 VARCHAR(12),
    ticket_date                    DATE,
    issue_category                  VARCHAR(30),
    ticket_status                   VARCHAR(20),
    resolution_hours                 VARCHAR(20),
    satisfaction_score                VARCHAR(20),
    related_order_value               VARCHAR(30),
    related_category                 VARCHAR(30)
);

-- 8. DATE TABLE: convert text date_key into a real DATE
INSERT INTO Date_Table (
    date_key,
    year,
    quarter,
    month,
    month_name,
    day_of_month,
    day_of_week,
    is_weekend
)
SELECT
    STR_TO_DATE(date_key, '%Y-%m-%d'),
    year,quarter,month,month_name,day_of_month,day_of_week,
    CASE
        WHEN UPPER(TRIM(is_weekend)) IN ('TRUE', '1', 'YES')
        THEN 1
        ELSE 0
    END
FROM Date_Table_Staging;

-- 9. CUSTOMER SUPPORT: convert blank strings to true NULLs before casting
INSERT INTO Customers_Support (
    ticket_id, customer_id, transaction_id, ticket_date,
    issue_category, ticket_status, resolution_hours,
    satisfaction_score, related_order_value, related_category
)
SELECT
    ticket_id, customer_id, transaction_id, ticket_date,
    issue_category, ticket_status,
    NULLIF(TRIM(resolution_hours), ''),
    NULLIF(TRIM(satisfaction_score), ''),
    NULLIF(TRIM(related_order_value), ''),
    NULLIF(TRIM(related_category), '')
FROM Customers_Support_Staging;

-- REFERENTIAL INTEGRITY CHECK

-- Orphan customer_id in Transactions
SELECT DISTINCT t.customer_id
FROM Transactions t
LEFT JOIN Customers c ON t.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Orphan product_id in Transactions
SELECT DISTINCT t.product_id
FROM Transactions t
LEFT JOIN Products p ON t.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Orphan transaction_date in Transactions (not present in Date_Table)
SELECT DISTINCT t.transaction_date
FROM Transactions t
LEFT JOIN Date_Table d ON t.transaction_date = d.date_key
WHERE d.date_key IS NULL;

-- Orphan customer_id in Customers_Support
SELECT DISTINCT cs.customer_id
FROM Customers_Support cs
LEFT JOIN Customers c ON cs.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Orphan transaction_id in Customers_Support 
SELECT DISTINCT cs.transaction_id
FROM Customers_Support cs
LEFT JOIN Transactions t ON cs.transaction_id = t.transaction_id
WHERE cs.transaction_id IS NOT NULL AND t.transaction_id IS NULL;

-- Orphan ticket_date in Customers_Support
SELECT DISTINCT cs.ticket_date
FROM Customers_Support cs
LEFT JOIN Date_Table d ON cs.ticket_date = d.date_key
WHERE d.date_key IS NULL;

--  ADD FOREIGN KEY RELATIONSHIPS

-- Transactions → Customers
ALTER TABLE Transactions
ADD CONSTRAINT fk_transactions_customer
FOREIGN KEY (customer_id) REFERENCES Customers(customer_id);

-- Transactions → Products
ALTER TABLE Transactions
ADD CONSTRAINT fk_transactions_product
FOREIGN KEY (product_id) REFERENCES Products(product_id);

-- Transactions → Date_Table
ALTER TABLE Transactions
ADD CONSTRAINT fk_transactions_date
FOREIGN KEY (transaction_date) REFERENCES Date_Table(date_key);

-- Customers_Support → Customers
ALTER TABLE Customers_Support
ADD CONSTRAINT fk_support_customer
FOREIGN KEY (customer_id) REFERENCES Customers(customer_id);

-- Customers_Support → Date_Table
ALTER TABLE Customers_Support
ADD CONSTRAINT fk_support_date
FOREIGN KEY (ticket_date) REFERENCES Date_Table(date_key);

-- CONFIRM RELATIONSHIPS EXIST
SELECT
    TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'rt'
  AND REFERENCED_TABLE_NAME IS NOT NULL;  -- Should return exactly 5 rows, matching the 5 relationships above.

USE RT;

-- How many rows does each table have, and does that match what we expect?
SELECT 'Customers' AS table_name, COUNT(*) AS row_count
FROM Customers
UNION ALL
SELECT 'Products', COUNT(*)
FROM Products
UNION ALL
SELECT 'Date_Table', COUNT(*)
FROM Date_Table
UNION ALL
SELECT 'Transactions', COUNT(*)
FROM Transactions
UNION ALL
SELECT 'Customers_Support', COUNT(*)
FROM Customers_Support;

-- Did any transaction get saved twice by mistake?
SELECT
    transaction_id,
    COUNT(*) AS duplicate_count
FROM Transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1;

-- Are any transactions missing a customer, a product, or an amount?
SELECT
    customer_id,
    product_id,
    total_amount
FROM Transactions
WHERE customer_id IS NULL
   OR product_id IS NULL
   OR total_amount IS NULL;

-- Does every transaction belong to a customer we actually have on record?
SELECT
    t.customer_id
FROM Transactions t
LEFT JOIN Customers c
    ON t.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- If resolution time or satisfaction score is blank, is it just because that ticket is still open?
SELECT
    ticket_status,
    COUNT(*) AS missing_records
FROM Customers_Support
WHERE ticket_status IN ('Pending', 'Escalated')
  AND (
      resolution_hours IS NULL
      OR satisfaction_score IS NULL
  )
GROUP BY ticket_status;

-- What are all the payment methods customers used?
SELECT DISTINCT payment_method
FROM Transactions;

-- Which 10 orders had the highest amount?
SELECT
    transaction_id,
    total_amount
FROM Transactions
ORDER BY total_amount DESC
LIMIT 10;

-- How much money and how many orders came from each order status?
SELECT
    order_status,
    COUNT(transaction_id) AS total_transactions,
    SUM(total_amount) AS total_revenue
FROM Transactions
GROUP BY order_status;

-- Which customers bought more than 10 times?
SELECT
    customer_id,
    COUNT(transaction_id) AS total_transactions
FROM Transactions
GROUP BY customer_id
HAVING COUNT(transaction_id) > 10;

-- How many orders were big bulk buys versus normal-sized orders?
SELECT
    CASE
        WHEN quantity > 10 THEN 'Bulk Order'
        ELSE 'Standard Order'
    END AS order_type,
    COUNT(*) AS transaction_count
FROM Transactions
GROUP BY
    CASE
        WHEN quantity > 10 THEN 'Bulk Order'
        ELSE 'Standard Order'
    END;

-- Which product category made the most money?
SELECT
    p.product_category,
    SUM(t.total_amount) AS total_revenue
FROM Transactions t
JOIN Products p
    ON p.product_id = t.product_id
GROUP BY p.product_category;

-- Which city made the most money?
SELECT
    c.location_clean_city,
    SUM(t.total_amount) AS total_revenue
FROM Transactions t
JOIN Customers c
    ON c.customer_id = t.customer_id
GROUP BY c.location_clean_city;

-- How does revenue look when we split it by city and category together?
SELECT
    c.location_clean_city,
    p.product_category,
    SUM(t.total_amount) AS total_revenue
FROM Transactions t
JOIN Customers c
    ON c.customer_id = t.customer_id
JOIN Products p
    ON p.product_id = t.product_id
GROUP BY
    c.location_clean_city,
    p.product_category;

-- How many tickets has each customer raised, including customers who never raised one?
SELECT
    c.customer_id,
    COUNT(cs.ticket_id) AS total_tickets
FROM Customers c
LEFT JOIN Customers_Support cs
    ON c.customer_id = cs.customer_id
GROUP BY c.customer_id;

-- How did revenue change month by month?
SELECT
    d.year,
    d.month,
    d.month_name,
    SUM(t.total_amount) AS monthly_revenue
FROM Transactions t
JOIN Date_Table d
    ON d.date_key = t.transaction_date
GROUP BY
    d.year,
    d.month,
    d.month_name
ORDER BY
    d.year,
    d.month;

-- For each customer, how many times did they buy, how much did they spend, and when was their first and last purchase?
WITH Customer_Summary AS (
    SELECT
        c.customer_id,
        COUNT(t.transaction_id) AS total_transaction,
        SUM(t.total_amount) AS total_revenue,
        MIN(t.transaction_date) AS first_purchase_date,
        MAX(t.transaction_date) AS last_purchase_date
    FROM Customers c
    LEFT JOIN Transactions t
        ON c.customer_id = t.customer_id
    GROUP BY c.customer_id
)
SELECT * FROM Customer_Summary;

-- What percent of customers bought only once, and what percent came back?
WITH Customer_Purchases AS (
    SELECT
        c.customer_id,
        COUNT(t.transaction_id) AS total_transactions
    FROM Customers c
    LEFT JOIN Transactions t
        ON c.customer_id = t.customer_id
    GROUP BY c.customer_id
),
Buyer_Type AS (
    SELECT
        customer_id,
        CASE
            WHEN total_transactions = 1 THEN 'One-Time Buyer'
            WHEN total_transactions > 1 THEN 'Repeat Buyer'
        END AS buyer_type
    FROM Customer_Purchases
    WHERE total_transactions > 0
)
SELECT
    buyer_type,
    COUNT(*) AS customer_count,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM Buyer_Type
GROUP BY buyer_type;

-- Which customers haven't bought anything in 180 days or more?
WITH Customer_Last_Purchase AS (
    SELECT
        customer_id,
        MAX(transaction_date) AS last_purchase_date
    FROM Transactions
    GROUP BY customer_id
),
Latest_Date AS (
    SELECT
        MAX(transaction_date) AS latest_transaction_date
    FROM Transactions
)
SELECT
    c.customer_id,
    c.last_purchase_date,
    DATEDIFF(l.latest_transaction_date, c.last_purchase_date) AS days_since_purchase
FROM Customer_Last_Purchase c
CROSS JOIN Latest_Date l
WHERE DATEDIFF(l.latest_transaction_date, c.last_purchase_date) >= 180
ORDER BY days_since_purchase DESC;

-- Do customers who raised a support ticket spend or buy differently than customers who never raised one?
WITH Customer_Summary AS (
    SELECT
        c.customer_id,
        COUNT(DISTINCT t.transaction_id) AS transaction_count,
        COALESCE(SUM(t.total_amount), 0) AS total_revenue,
        CASE
            WHEN COUNT(DISTINCT cs.ticket_id) > 0
                THEN 'Raised Ticket'
            ELSE 'No Ticket'
        END AS support_status
    FROM Customers c
    LEFT JOIN Transactions t
        ON c.customer_id = t.customer_id
    LEFT JOIN Customers_Support cs
        ON c.customer_id = cs.customer_id
    GROUP BY c.customer_id
)
SELECT
    support_status,
    ROUND(AVG(total_revenue), 2) AS average_revenue,
    ROUND(AVG(transaction_count), 2) AS average_transaction_count
FROM Customer_Summary
GROUP BY support_status;

-- For each customer, what order did their purchases happen in — 1st, 2nd, 3rd, and so on?
SELECT
    transaction_id,
    customer_id,
    transaction_date,
    total_amount,
    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date, transaction_id
    ) AS purchase_number
FROM Transactions
ORDER BY customer_id, purchase_number;

-- Who are the top 20 customers by total spend?
WITH Customer_Revenue AS (
    SELECT
        customer_id,
        SUM(total_amount) AS total_revenue
    FROM Transactions
    GROUP BY customer_id
)
SELECT
    customer_id,
    total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM Customer_Revenue
ORDER BY total_revenue DESC
LIMIT 20;

-- How does each month's revenue compare to the month before it?
WITH Monthly_Revenue AS (
    SELECT
        d.year,
        d.month,
        d.month_name,
        SUM(t.total_amount) AS monthly_revenue
    FROM Transactions t
    JOIN Date_Table d
        ON d.date_key = t.transaction_date
    GROUP BY d.year, d.month, d.month_name
),
Monthly_Comparison AS (
    SELECT
        year,
        month,
        month_name,
        monthly_revenue,
        LAG(monthly_revenue) OVER (
            ORDER BY year, month
        ) AS previous_month_revenue
    FROM Monthly_Revenue
)
SELECT
    year,
    month,
    month_name,
    monthly_revenue,
    previous_month_revenue,
    monthly_revenue - previous_month_revenue AS revenue_change
FROM Monthly_Comparison
ORDER BY year, month;

-- What does the total revenue look like as it adds up day by day?
WITH Daily_Revenue AS (
    SELECT
        transaction_date,
        SUM(total_amount) AS daily_revenue
    FROM Transactions
    GROUP BY transaction_date
)
SELECT
    transaction_date,
    daily_revenue,
    SUM(daily_revenue) OVER (
        ORDER BY transaction_date
    ) AS cumulative_revenue
FROM Daily_Revenue
ORDER BY transaction_date;

-- In each category, which one product made the most money?
WITH Product_Revenue AS (
    SELECT
        p.product_category,
        p.product_id,
        p.product_name,
        SUM(t.total_amount) AS total_revenue
    FROM Products p
    JOIN Transactions t
        ON p.product_id = t.product_id
    GROUP BY
        p.product_category,
        p.product_id,
        p.product_name
),
Product_Ranking AS (
    SELECT
        product_category,
        product_id,
        product_name,
        total_revenue,
        RANK() OVER (
            PARTITION BY product_category
            ORDER BY total_revenue DESC
        ) AS category_rank
    FROM Product_Revenue
)
SELECT
    product_category,
    product_id,
    product_name,
    total_revenue
FROM Product_Ranking
WHERE category_rank = 1
ORDER BY product_category;

-- What's the average order size per customer, and who spends above average?
WITH Customer_ATV AS (
    SELECT
        customer_id,
        AVG(total_amount) AS average_transaction_value
    FROM Transactions
    GROUP BY customer_id
),
Overall_ATV AS (
    SELECT
        AVG(total_amount) AS overall_average_transaction_value
    FROM Transactions
)
SELECT
    c.customer_id,
    ROUND(c.average_transaction_value, 2) AS average_transaction_value
FROM Customer_ATV c
CROSS JOIN Overall_ATV o
WHERE c.average_transaction_value > o.overall_average_transaction_value
ORDER BY c.average_transaction_value DESC;

-- Which 10 products made the most money overall?
SELECT
    p.product_id,
    p.product_name,
    SUM(t.total_amount) AS total_revenue
FROM Products p
JOIN Transactions t
    ON p.product_id = t.product_id
GROUP BY
    p.product_id,
    p.product_name
ORDER BY total_revenue DESC
LIMIT 10;

-- Which payment method brought in the most revenue?
SELECT
    payment_method,
    COUNT(transaction_id) AS total_transactions,
    SUM(total_amount) AS total_revenue
FROM Transactions
GROUP BY payment_method
ORDER BY total_revenue DESC;

-- Do people buy differently on weekdays versus weekends?
SELECT
    CASE
        WHEN d.is_weekend = 1 THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    COUNT(t.transaction_id) AS total_transactions,
    SUM(t.total_amount) AS total_revenue
FROM Transactions t
JOIN Date_Table d
    ON d.date_key = t.transaction_date
GROUP BY
    CASE
        WHEN d.is_weekend = 1 THEN 'Weekend'
        ELSE 'Weekday'
    END;

-- For each support issue type, how long does it usually take to fix, and how happy are customers with it?
SELECT
    issue_category,
    ROUND(AVG(resolution_hours), 2) AS average_resolution_hours,
    ROUND(AVG(satisfaction_score), 2) AS average_satisfaction_score
FROM Customers_Support
GROUP BY issue_category
ORDER BY issue_category;

-- Which acquisition channel brings in the most customers and the most money?
SELECT
    c.acquisition_clean_channel AS acquisition_channel,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    SUM(t.total_amount) AS total_revenue
FROM Customers c
JOIN Transactions t
    ON c.customer_id = t.customer_id
GROUP BY c.acquisition_clean_channel
ORDER BY total_revenue DESC;