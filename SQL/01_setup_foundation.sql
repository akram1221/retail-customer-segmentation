-- ============================================================
-- PROJECT : RETAIL & MARKETING ANALYTICS
-- File: 01_setup_foundation.sql
-- Purpose: Create the compute warehouse, database, and schemas
--          following medallion architecture (bronze/silver/gold).
-- ============================================================

USE ROLE ACCOUNTADMIN;

-- ----------------------------------------------------------------
-- 1. CREATE A COMPUTE WAREHOUSE
-- X-SMALL with auto-suspend keeps costs minimal during development
-- ----------------------------------------------------------------
CREATE WAREHOUSE IF NOT EXISTS RETAIL_WH
  WITH WAREHOUSE_SIZE = 'XSMALL'
       AUTO_SUSPEND = 60
       AUTO_RESUME = TRUE
       INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Compute warehouse for retail analytics project';

-- ----------------------------------------------------------------
-- 2. CREATE THE DATABASE
-- ----------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS RETAIL_ANALYTICS
  COMMENT = 'Retail customer segmentation & conversion analytics';

-- ----------------------------------------------------------------
-- 3. CREATE THREE SCHEMAS — MEDALLION ARCHITECTURE
-- Bronze: raw, untouched data
-- Silver: cleaned and conformed
-- Gold:   dimensional models & business-ready analytics
-- ----------------------------------------------------------------
USE DATABASE RETAIL_ANALYTICS;

CREATE SCHEMA IF NOT EXISTS RAW
  COMMENT = 'Bronze layer: raw uploaded data, untouched';

CREATE SCHEMA IF NOT EXISTS STAGING
  COMMENT = 'Silver layer: cleaned and conformed data';

CREATE SCHEMA IF NOT EXISTS ANALYTICS
  COMMENT = 'Gold layer: dimensional models, RFM scores, segments';

-- ----------------------------------------------------------------
-- 4. SET DEFAULT CONTEXT
-- ----------------------------------------------------------------
USE WAREHOUSE RETAIL_WH;
USE DATABASE RETAIL_ANALYTICS;
USE SCHEMA RAW;

-- ----------------------------------------------------------------
-- 5. VERIFY
-- ----------------------------------------------------------------
SHOW WAREHOUSES LIKE 'RETAIL_WH';
SHOW DATABASES LIKE 'RETAIL_ANALYTICS';
SHOW SCHEMAS IN DATABASE RETAIL_ANALYTICS;