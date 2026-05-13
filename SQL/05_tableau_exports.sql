-- ============================================================
-- PROJECT 2: RETAIL & MARKETING ANALYTICS
-- File: 05_tableau_exports.sql
-- Purpose: Export queries for Tableau Public dashboard.
--          Tableau Public can't connect live to Snowflake, so
--          these queries produce CSVs that are downloaded via
--          Snowsight and loaded into Tableau.
-- ============================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE RETAIL_WH;
USE DATABASE RETAIL_ANALYTICS;
USE SCHEMA ANALYTICS;

-- ----------------------------------------------------------------
-- EXPORT 1: dim_customer.csv
-- Customer dimension with RFM segments — drives most dashboard charts
-- ----------------------------------------------------------------
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
    rfm_total,
    rfm_code,
    segment_label
FROM DIM_CUSTOMER
ORDER BY total_revenue DESC;

-- ----------------------------------------------------------------
-- EXPORT 2: segment_summary.csv
-- Pre-aggregated segment summary for the headline Pareto chart
-- ----------------------------------------------------------------
SELECT
    segment_label,
    COUNT(*)                          AS customer_count,
    ROUND(SUM(total_revenue), 0)      AS total_revenue,
    ROUND(AVG(total_revenue), 0)      AS avg_customer_value,
    ROUND(AVG(total_orders), 1)       AS avg_orders_per_customer,
    ROUND(AVG(recency_days), 0)       AS avg_recency_days
FROM DIM_CUSTOMER
GROUP BY segment_label
ORDER BY total_revenue DESC;

-- ----------------------------------------------------------------
-- EXPORT 3: fact_sales.csv
-- Fact sales joined with customer segments for time-series analysis
-- Note: ~800K rows, ~80MB CSV
-- ----------------------------------------------------------------
SELECT
    f.invoice_id,
    f.customer_id,
    f.stock_code,
    f.date_key                       AS invoice_date,
    f.quantity,
    f.unit_price,
    f.line_revenue,
    f.country,
    c.segment_label,
    c.r_score,
    c.f_score,
    c.m_score
FROM FACT_SALES f
LEFT JOIN DIM_CUSTOMER c ON f.customer_id = c.customer_id;