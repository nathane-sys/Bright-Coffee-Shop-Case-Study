select *
from `workspace`.`default`.`Bright_coffee_shop_analysis_case_study_1`
limit 100;


-- =========================================
-- 1. DATA UNDERSTANDING
-- =========================================

-- Preview raw data
SELECT *
FROM `workspace`.`default`.`Bright_coffee_shop_analysis_case_study_1`
LIMIT 10;

-- Count records
SELECT COUNT(*) AS total_rows
FROM `workspace`.`default`.`Bright_coffee_shop_analysis_case_study_1`;

--Check date range
SELECT MIN(transaction_date) AS min_date,
       MAX(transaction_date) AS max_date
FROM `workspace`.`default`.`Bright_coffee_shop_analysis_case_study_1`;

--Check distinct categories and stores
SELECT DISTINCT store_location
FROM `workspace`.`default`.`Bright_coffee_shop_analysis_case_study_1`
ORDER BY store_location;

---
SELECT DISTINCT product_category
FROM `workspace`.`default`.`Bright_coffee_shop_analysis_case_study_1`
ORDER BY product_category;


-- =========================================
-- 2. DATA VALIDATION
-- =========================================

-- Check nulls
SELECT
    SUM(CASE WHEN transaction_id IS NULL THEN 1 ELSE 0 END) AS null_transaction_id,
    SUM(CASE WHEN transaction_date IS NULL THEN 1 ELSE 0 END) AS null_transaction_date,
    SUM(CASE WHEN transaction_time IS NULL THEN 1 ELSE 0 END) AS null_transaction_time,
    SUM(CASE WHEN transaction_qty IS NULL THEN 1 ELSE 0 END) AS null_transaction_qty,
    SUM(CASE WHEN store_location IS NULL THEN 1 ELSE 0 END) AS null_store_location,
    SUM(CASE WHEN unit_price IS NULL THEN 1 ELSE 0 END) AS null_unit_price,
    SUM(CASE WHEN product_category IS NULL THEN 1 ELSE 0 END) AS null_product_category,
    SUM(CASE WHEN product_type IS NULL THEN 1 ELSE 0 END) AS null_product_type,
    SUM(CASE WHEN product_detail IS NULL THEN 1 ELSE 0 END) AS null_product_detail
FROM `workspace`.`default`.`Bright_coffee_shop_analysis_case_study_1`

-- Check duplicates
SELECT transaction_id,
       COUNT(*) AS duplicate_count
FROM `workspace`.`default`.`Bright_coffee_shop_analysis_case_study_1`
GROUP BY transaction_id
HAVING COUNT(*) > 1;

-- Check numeric ranges
SELECT *
FROM `workspace`.`default`.`Bright_coffee_shop_analysis_case_study_1`
WHERE transaction_qty <= 0
   OR unit_price IS NULL;

-- =========================================
-- 3. TRANSFORMED ANALYTICS TABLE
-- =========================================
-- 3. Cleaning and standardization
-- Create total_amount
CREATE OR REPLACE TABLE bright_coffee_shop_sales_analytics AS
SELECT
    transaction_id,
    transaction_date,
    transaction_time,
    transaction_qty,
    store_location,
    unit_price,
    product_category,
    product_type,
    product_detail,

    -- Required metric
    unit_price * transaction_qty AS total_amount,

    -- Date features
    YEAR(transaction_date) AS sales_year,
    MONTH(transaction_date) AS sales_month,
    DATE_FORMAT(transaction_date, 'MMMM') AS month_name,
    DAYOFWEEK(transaction_date) AS day_of_week_num,
    DATE_FORMAT(transaction_date, 'EEEE') AS day_name,

    -- Time features
    HOUR(transaction_time) AS transaction_hour,
    MINUTE(transaction_time) AS transaction_minute,

    -- 30-minute time bucket
    CASE
        WHEN MINUTE(transaction_time) < 30
            THEN CONCAT(LPAD(HOUR(transaction_time), 2, '0'), ':00')
        ELSE CONCAT(LPAD(HOUR(transaction_time), 2, '0'), ':30')
    END AS transaction_time_bucket,

    -- Time-of-day grouping
    CASE
        WHEN HOUR(transaction_time) BETWEEN 6 AND 11 THEN 'Morning'
        WHEN HOUR(transaction_time) BETWEEN 12 AND 16 THEN 'Afternoon'
        ELSE 'Evening'
    END AS time_of_day,

    -- Day type grouping
    CASE
        WHEN DATE_FORMAT(transaction_date, 'EEEE') IN ('Saturday', 'Sunday') THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type

FROM `workspace`.`default`.`Bright_coffee_shop_analysis_case_study_1`;

-- =========================================
-- 4. VALIDATION OF TRANSFORMED TABLE
-- =========================================

-- Preview transformed data
SELECT *
FROM bright_coffee_shop_sales_analytics
LIMIT 10;

SELECT *
FROM `workspace`.`default`.`Bright_coffee_shop_analysis_case_study_1`;

-- Check totals
SELECT
    COUNT(*) AS total_rows,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    MIN(transaction_date) AS start_date,
    MAX(transaction_date) AS end_date
FROM bright_coffee_shop_sales_analytics;

-- Check new derived columns
SELECT DISTINCT transaction_time_bucket
FROM bright_coffee_shop_sales_analytics
ORDER BY transaction_time_bucket;

--
SELECT DISTINCT time_of_day
FROM `workspace`.`default`.`Bright_coffee_shop_analysis_case_study_1`;
-- =========================================
-- 5. BUSINESS ANALYSIS
-- =========================================

-- Revenue by category
SELECT product_category,
       ROUND(SUM(total_amount), 2) AS total_revenue
FROM bright_coffee_shop_sales_analytics
GROUP BY product_category
ORDER BY total_revenue DESC;

-- Revenue by product type
SELECT product_type,
       ROUND(SUM(total_amount), 2) AS total_revenue
FROM bright_coffee_shop_sales_analytics
GROUP BY product_type
ORDER BY total_revenue DESC;

-- Top products
SELECT product_detail,
       ROUND(SUM(total_amount), 2) AS total_revenue,
       SUM(transaction_qty) AS total_units_sold
FROM bright_coffee_shop_sales_analytics
GROUP BY product_detail
ORDER BY total_revenue DESC
LIMIT 10;

-- Time bucket performance
SELECT transaction_time_bucket,
       ROUND(SUM(total_amount), 2) AS total_revenue,
       COUNT(*) AS total_transactions
FROM bright_coffee_shop_sales_analytics
GROUP BY transaction_time_bucket
ORDER BY total_revenue DESC;

-- Morning vs afternoon vs evening
SELECT time_of_day,
       ROUND(SUM(total_amount), 2) AS total_revenue,
       COUNT(*) AS total_transactions
FROM bright_coffee_shop_sales_analytics
GROUP BY time_of_day
ORDER BY total_revenue DESC;

-- Monthly trend
SELECT sales_year,
       sales_month,
       month_name,
       ROUND(SUM(total_amount), 2) AS total_revenue
FROM bright_coffee_shop_sales_analytics
GROUP BY sales_year, sales_month, month_name
ORDER BY sales_year, sales_month;

---Daily Pattern
SELECT day_name,
       ROUND(SUM(total_amount), 2) AS total_revenue,
       COUNT(*) AS total_transactions
FROM bright_coffee_shop_sales_analytics
GROUP BY day_name
ORDER BY total_revenue DESC;

--- Weekday vs Weekend
SELECT day_type,
       ROUND(SUM(total_amount), 2) AS total_revenue,
       COUNT(*) AS total_transactions
FROM bright_coffee_shop_sales_analytics
GROUP BY day_type
ORDER BY total_revenue DESC;

-- Store performance
SELECT store_location,
       ROUND(SUM(total_amount), 2) AS total_revenue,
       COUNT(*) AS total_transactions
FROM bright_coffee_shop_sales_analytics
GROUP BY store_location
ORDER BY total_revenue DESC;

-- =========================================
-- 6. ADVANCED ANALYSIS
-- =========================================

--- HAVING
-- Product types above revenue threshold
SELECT product_type,
       ROUND(SUM(total_amount), 2) AS total_revenue
FROM bright_coffee_shop_sales_analytics
GROUP BY product_type
HAVING SUM(total_amount) > 50000
ORDER BY total_revenue DESC;

--Time buckets with high volume
SELECT transaction_time_bucket,
       SUM(transaction_qty) AS total_units_sold
FROM bright_coffee_shop_sales_analytics
GROUP BY transaction_time_bucket
HAVING SUM(transaction_qty) > 5000
ORDER BY total_units_sold DESC;

-- CASE- Performance classification
SELECT product_type,
       ROUND(SUM(total_amount), 2) AS total_revenue,
       CASE
            WHEN SUM(total_amount) >= 70000 THEN 'High Performing'
            WHEN SUM(total_amount) >= 30000 THEN 'Moderate Performing'
       ELSE 'Low Performing'
       END AS performance_band
FROM bright_coffee_shop_sales_analytics
GROUP BY product_type
ORDER BY total_revenue DESC;

-- Avg transaction value by store
SELECT store_location,
       ROUND(AVG(total_amount), 2) AS avg_transaction_value
FROM bright_coffee_shop_sales_analytics
GROUP BY store_location
ORDER BY avg_transaction_value DESC;

-- Lowest performers
SELECT product_detail,
       ROUND(SUM(total_amount), 2) AS total_revenue,
       SUM(transaction_qty) AS total_units_sold
FROM bright_coffee_shop_sales_analytics
GROUP BY product_detail
ORDER BY total_revenue ASC
LIMIT 10;
-------------------------------------------
I Love SQL
-------------------------------------------
