-- ============================================================
-- PROJECT 2: RETAIL & MARKETING ANALYTICS
-- File: 02_load_raw_data.sql
-- Purpose: Define the raw transactions table for the
--          UCI Online Retail II dataset.
-- Note:    The CSV data was uploaded via Snowsight's UI
--          loader (Home → Upload local files) targeting this table.
-- ============================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE RETAIL_WH;
USE DATABASE RETAIL_ANALYTICS;
USE SCHEMA RAW;

-- ----------------------------------------------------------------
-- CREATE RAW TRANSACTIONS TABLE
-- Schema matches CSV exactly — UCI Online Retail II dataset
-- Source: https://archive.ics.uci.edu/dataset/502/online+retail+ii
-- Two CSVs were loaded:
--   - retail_2009_2010.csv (~525K rows)
--   - retail_2010_2011.csv (~542K rows)
-- ----------------------------------------------------------------
DROP TABLE IF EXISTS RAW_TRANSACTIONS;

CREATE TABLE RAW_TRANSACTIONS (
    INVOICE         VARCHAR(20),
    STOCKCODE       VARCHAR(20),
    DESCRIPTION     VARCHAR(500),
    QUANTITY        INTEGER,
    INVOICEDATE     TIMESTAMP_NTZ,
    PRICE           NUMBER(10, 2),
    CUSTOMER_ID     VARCHAR(20),
    COUNTRY         VARCHAR(100)
);

-- ----------------------------------------------------------------
-- VERIFICATION QUERIES (run after CSV upload via Snowsight UI)
-- ----------------------------------------------------------------

-- Total row count (expect ~1,067,371)
SELECT COUNT(*) AS total_rows FROM RAW_TRANSACTIONS;

-- Date range and uniqueness checks
SELECT
    MIN(INVOICEDATE) AS earliest_date,
    MAX(INVOICEDATE) AS latest_date,
    COUNT(DISTINCT CUSTOMER_ID) AS unique_customers,
    COUNT(DISTINCT INVOICE) AS unique_invoices,
    COUNT(DISTINCT COUNTRY) AS countries
FROM RAW_TRANSACTIONS;

-- Data quality profiling
SELECT
    COUNT(*) AS total,
    SUM(CASE WHEN CUSTOMER_ID IS NULL OR CUSTOMER_ID = '' THEN 1 ELSE 0 END) AS missing_customer_id,
    SUM(CASE WHEN QUANTITY < 0 THEN 1 ELSE 0 END) AS negative_quantity,
    SUM(CASE WHEN PRICE <= 0 THEN 1 ELSE 0 END) AS zero_or_negative_price,
    SUM(CASE WHEN DESCRIPTION IS NULL OR DESCRIPTION = '' THEN 1 ELSE 0 END) AS missing_description
FROM RAW_TRANSACTIONS;

-- Observed profiling results:
--   total:                  1,067,371
--   missing_customer_id:    243,007  (22.8%)
--   negative_quantity:      22,950   (2.2%)
--   zero_or_negative_price: 6,225    (0.6%)
--   missing_description:    4,382    (0.4%)