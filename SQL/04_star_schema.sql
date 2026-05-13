-- ============================================================
-- PROJECT 2: RETAIL & MARKETING ANALYTICS
-- File: 04_star_schema.sql
-- Purpose: Build the gold-layer star schema with dimensional
--          modelling and RFM customer segmentation.
-- Pattern: Kimball-style star schema
--          - DIM_DATE, DIM_CUSTOMER, DIM_PRODUCT
--          - FACT_SALES at order-line grain
-- ============================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE RETAIL_WH;
USE DATABASE RETAIL_ANALYTICS;
USE SCHEMA ANALYTICS;

-- ----------------------------------------------------------------
-- 1. DATE DIMENSION
-- One row per calendar date in the analysis period.
-- Pre-computed date attributes for fast time-series filtering.
-- ----------------------------------------------------------------
CREATE OR REPLACE TABLE DIM_DATE AS
WITH date_spine AS (
    SELECT DATEADD(DAY, SEQ4(), '2009-12-01'::DATE) AS calendar_date
    FROM TABLE(GENERATOR(ROWCOUNT => 800))
)
SELECT
    calendar_date                                    AS date_key,
    EXTRACT(YEAR FROM calendar_date)                 AS year,
    EXTRACT(QUARTER FROM calendar_date)              AS quarter,
    EXTRACT(MONTH FROM calendar_date)                AS month,
    MONTHNAME(calendar_date)                         AS month_name,
    EXTRACT(WEEK FROM calendar_date)                 AS week_of_year,
    EXTRACT(DAYOFWEEK FROM calendar_date)            AS day_of_week,
    DAYNAME(calendar_date)                           AS day_name,
    CASE WHEN EXTRACT(DAYOFWEEK FROM calendar_date) IN (0, 6)
         THEN TRUE ELSE FALSE END                    AS is_weekend,
    EXTRACT(MONTH FROM calendar_date) IN (11, 12)    AS is_holiday_season
FROM date_spine
WHERE calendar_date <= '2011-12-31';

-- ----------------------------------------------------------------
-- 2. CUSTOMER DIMENSION WITH RFM SCORING
-- RFM = Recency, Frequency, Monetary
-- NTILE(5) buckets each metric into quintiles (5 = best, 1 = worst)
-- Pre-computed segment labels enable fast dashboard queries.
-- ----------------------------------------------------------------
CREATE OR REPLACE TABLE DIM_CUSTOMER AS
WITH customer_aggregates AS (
    SELECT
        customer_id,
        MAX(country)                                       AS primary_country,
        MIN(invoice_date)                                  AS first_purchase_date,
        MAX(invoice_date)                                  AS last_purchase_date,
        COUNT(DISTINCT invoice_id)                         AS total_orders,
        SUM(quantity)                                      AS total_units,
        ROUND(SUM(line_revenue), 2)                        AS total_revenue,
        ROUND(AVG(line_revenue), 2)                        AS avg_line_value,
        DATEDIFF(DAY, MAX(invoice_date), '2011-12-09')     AS recency_days,
        DATEDIFF(DAY, MIN(invoice_date), MAX(invoice_date)) AS tenure_days
    FROM STAGING.STG_PURCHASES
    GROUP BY customer_id
),
rfm_scored AS (
    SELECT
        customer_id,
        primary_country,
        first_purchase_date,
        last_purchase_date,
        tenure_days,
        recency_days,
        total_orders,
        total_units,
        total_revenue,
        avg_line_value,
        -- Recency: lower days = more recent = higher score
        NTILE(5) OVER (ORDER BY recency_days DESC)        AS r_score,
        -- Frequency: more orders = higher score
        NTILE(5) OVER (ORDER BY total_orders ASC)         AS f_score,
        -- Monetary: more revenue = higher score
        NTILE(5) OVER (ORDER BY total_revenue ASC)        AS m_score
    FROM customer_aggregates
)
SELECT
    customer_id,
    primary_country,
    first_purchase_date,
    last_purchase_date,
    tenure_days,
    recency_days,
    total_orders,
    total_units,
    total_revenue,
    avg_line_value,
    r_score,
    f_score,
    m_score,
    (r_score + f_score + m_score)                          AS rfm_total,
    CONCAT(r_score, f_score, m_score)                      AS rfm_code,
    -- Business-friendly segment labels based on RFM combinations
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 4 AND m_score >= 4 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2                  THEN 'New Customers'
        WHEN r_score >= 3 AND f_score >= 2 AND m_score >= 3 THEN 'Potential Loyalists'
        WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score >= 3                  THEN 'Cant Lose Them'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Lost'
        WHEN r_score = 3                                    THEN 'Need Attention'
        ELSE 'Other'
    END                                                    AS segment_label
FROM rfm_scored;

-- ----------------------------------------------------------------
-- 3. PRODUCT DIMENSION
-- ----------------------------------------------------------------
CREATE OR REPLACE TABLE DIM_PRODUCT AS
SELECT
    stock_code,
    MAX(product_description)         AS product_description,
    COUNT(DISTINCT invoice_id)       AS times_purchased,
    SUM(quantity)                    AS total_units_sold,
    ROUND(SUM(line_revenue), 2)      AS total_revenue,
    ROUND(AVG(unit_price), 2)        AS avg_unit_price
FROM STAGING.STG_PURCHASES
GROUP BY stock_code;

-- ----------------------------------------------------------------
-- 4. FACT TABLE — ORDER LINE GRAIN
-- One row per product per invoice
-- ----------------------------------------------------------------
CREATE OR REPLACE TABLE FACT_SALES AS
SELECT
    invoice_id,
    customer_id,
    stock_code,
    invoice_date            AS date_key,
    invoice_ts,
    quantity,
    unit_price,
    line_revenue,
    country
FROM STAGING.STG_PURCHASES;

-- ----------------------------------------------------------------
-- 5. VERIFICATION
-- ----------------------------------------------------------------
SELECT 'DIM_DATE' AS table_name, COUNT(*) AS row_count FROM DIM_DATE
UNION ALL
SELECT 'DIM_CUSTOMER' AS table_name, COUNT(*) AS row_count FROM DIM_CUSTOMER
UNION ALL
SELECT 'DIM_PRODUCT' AS table_name, COUNT(*) AS row_count FROM DIM_PRODUCT
UNION ALL
SELECT 'FACT_SALES' AS table_name, COUNT(*) AS row_count FROM FACT_SALES;

-- Customer segment breakdown
SELECT
    segment_label,
    COUNT(*)                          AS customers,
    ROUND(SUM(total_revenue), 0)      AS segment_revenue,
    ROUND(AVG(total_revenue), 0)      AS avg_customer_value
FROM DIM_CUSTOMER
GROUP BY segment_label
ORDER BY segment_revenue DESC;

-- Observed segment results:
--   Champions:            1,288 customers, £11.9M (68% of revenue)
--   Loyal Customers:        432 customers, £1.7M
--   Potential Loyalists:    801 customers, £1.2M
--   At Risk:                224 customers, £1.0M
--   Cant Lose Them:         625 customers, £631K
--   Other:                  385 customers, £352K
--   Lost:                 1,267 customers, £323K
--   New Customers:          428 customers, £222K
--   Need Attention:         412 customers, £159K