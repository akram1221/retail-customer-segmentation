-- ============================================================
-- PROJECT 2: RETAIL & MARKETING ANALYTICS
-- File: 03_staging_transform.sql
-- Purpose: Clean and conform raw transactions into the silver
--          (STAGING) layer. Split into purchases vs returns.
-- ============================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE RETAIL_WH;
USE DATABASE RETAIL_ANALYTICS;
USE SCHEMA STAGING;

-- ----------------------------------------------------------------
-- 1. CLEANED TRANSACTIONS TABLE
-- Filters: requires customer ID, valid price, valid description,
--          excludes non-product stock codes.
-- Adds:    derived date components and boolean flags for analysis.
-- ----------------------------------------------------------------
CREATE OR REPLACE TABLE STG_TRANSACTIONS AS
SELECT
    -- Identifiers
    INVOICE                                            AS invoice_id,
    CAST(CUSTOMER_ID AS VARCHAR(20))                   AS customer_id,
    STOCKCODE                                          AS stock_code,
    TRIM(DESCRIPTION)                                  AS product_description,

    -- Dates (split for easier analysis)
    INVOICEDATE                                        AS invoice_ts,
    CAST(INVOICEDATE AS DATE)                          AS invoice_date,
    EXTRACT(YEAR FROM INVOICEDATE)                     AS invoice_year,
    EXTRACT(MONTH FROM INVOICEDATE)                    AS invoice_month,
    EXTRACT(DAY FROM INVOICEDATE)                      AS invoice_day,
    EXTRACT(DAYOFWEEK FROM INVOICEDATE)                AS invoice_dayofweek,
    EXTRACT(HOUR FROM INVOICEDATE)                     AS invoice_hour,

    -- Quantities & money
    QUANTITY                                           AS quantity,
    PRICE                                              AS unit_price,
    ROUND(QUANTITY * PRICE, 2)                         AS line_revenue,

    -- Geographic
    COUNTRY                                            AS country,

    -- Derived flags for analysis
    CASE WHEN INVOICE LIKE 'C%' THEN TRUE ELSE FALSE END  AS is_cancellation,
    CASE WHEN QUANTITY < 0 THEN TRUE ELSE FALSE END       AS is_return,
    CASE WHEN CUSTOMER_ID IS NULL
              OR TRIM(CUSTOMER_ID) = '' THEN TRUE
         ELSE FALSE END                                AS is_guest_checkout

FROM RAW.RAW_TRANSACTIONS
WHERE
    CUSTOMER_ID IS NOT NULL
    AND TRIM(CUSTOMER_ID) <> ''
    AND PRICE > 0
    AND DESCRIPTION IS NOT NULL
    AND TRIM(DESCRIPTION) <> ''
    -- Exclude non-product stock codes (admin entries, charges)
    AND STOCKCODE NOT IN ('POST', 'DOT', 'M', 'BANK CHARGES', 'CRUK', 'PADS', 'AMAZONFEE');

-- ----------------------------------------------------------------
-- 2. RETURNS / CANCELLATIONS (analysed separately from purchases)
-- ----------------------------------------------------------------
CREATE OR REPLACE TABLE STG_RETURNS AS
SELECT *
FROM STG_TRANSACTIONS
WHERE is_return = TRUE OR is_cancellation = TRUE;

-- ----------------------------------------------------------------
-- 3. POSITIVE PURCHASES (drives RFM analysis downstream)
-- ----------------------------------------------------------------
CREATE OR REPLACE TABLE STG_PURCHASES AS
SELECT *
FROM STG_TRANSACTIONS
WHERE is_return = FALSE
  AND is_cancellation = FALSE
  AND quantity > 0;

-- ----------------------------------------------------------------
-- 4. VERIFICATION
-- ----------------------------------------------------------------
SELECT 'RAW.RAW_TRANSACTIONS' AS table_name, COUNT(*) AS row_count FROM RAW.RAW_TRANSACTIONS
UNION ALL
SELECT 'STAGING.STG_TRANSACTIONS' AS table_name, COUNT(*) AS row_count FROM STG_TRANSACTIONS
UNION ALL
SELECT 'STAGING.STG_PURCHASES' AS table_name, COUNT(*) AS row_count FROM STG_PURCHASES
UNION ALL
SELECT 'STAGING.STG_RETURNS' AS table_name, COUNT(*) AS row_count FROM STG_RETURNS;

-- Observed results:
--   RAW.RAW_TRANSACTIONS:     1,067,371
--   STAGING.STG_TRANSACTIONS:   821,078
--   STAGING.STG_PURCHASES:      802,937
--   STAGING.STG_RETURNS:         18,141

-- Customer-level summary
SELECT
    COUNT(DISTINCT customer_id) AS analysable_customers,
    COUNT(DISTINCT invoice_id)  AS purchase_invoices,
    ROUND(SUM(line_revenue), 2) AS total_revenue,
    MIN(invoice_date)           AS first_purchase,
    MAX(invoice_date)           AS last_purchase
FROM STG_PURCHASES;

-- Observed results:
--   analysable_customers: 5,862
--   purchase_invoices:    36,650
--   total_revenue:        £17,452,154.19
--   first_purchase:       2009-12-01
--   last_purchase:        2011-12-09