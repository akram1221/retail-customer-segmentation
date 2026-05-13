# Retail Customer Segmentation & RFM Analysis

End-to-end cloud data analytics project: customer segmentation on 1M+ retail transactions using Snowflake, SQL, and Tableau.

🔗 **[View Live Dashboard](https://public.tableau.com/views/retail_segmentation/RetailDashboard)**

![Dashboard Preview](Screenshots/dashboard.png)

---

## Headline Findings

- **22% of customers (Champions) drive 68% of revenue** — textbook Pareto distribution validated across 5,862 customers
- **£1M in protectable revenue** identified in the "At Risk" segment (224 customers, £4,595 average value) — second-highest priority for retention campaigns
- **Two distinct business models** uncovered geographically: UK domestic retail (5,336 customers, £2,740 avg) vs international wholesale (EIRE: 5 customers averaging £120K each)

---

## Tech Stack

| Layer | Technology |
|---|---|
| Data Warehouse | Snowflake (Standard Edition) |
| Modelling | SQL — medallion architecture (bronze/silver/gold) |
| Transformations | CTEs, NTILE window functions, dimensional modelling |
| Visualisation | Tableau Public |
| Source Data | UCI Online Retail II (peer-reviewed academic dataset) |

---

## Architecture

The pipeline flows through three layers:

**Bronze (Raw)** — CSV files loaded into `RAW.RAW_TRANSACTIONS` (1.07M rows, untouched)

**Silver (Staging)** — Cleaned and conformed in `STAGING.STG_TRANSACTIONS` (821K rows), then split into `STG_PURCHASES` (802K positive sales) and `STG_RETURNS` (18K refunds and cancellations)

**Gold (Analytics)** — Star schema with `DIM_DATE`, `DIM_CUSTOMER` (pre-computed RFM segments), `DIM_PRODUCT`, and `FACT_SALES` at order-line grain

**Visualisation** — Tableau Public dashboard fed from CSV exports of the gold layer

---

## Repository Structure

- `SQL/01_setup_foundation.sql` — Warehouse, database, schemas
- `SQL/02_load_raw_data.sql` — Raw table DDL + upload notes
- `SQL/03_staging_transform.sql` — Cleaning & conformance logic
- `SQL/04_star_schema.sql` — Dimensional model + RFM scoring
- `SQL/05_tableau_exports.sql` — Tableau-ready export queries
- `Screenshots/dashboard.png` — Tableau dashboard preview
- `Docs/data_quality_findings.md` — Full data quality report
- `README.md` — This file

---

## Key Technical Decisions

- **Medallion architecture (bronze/silver/gold)**: Industry-standard pattern separating raw, cleaned, and analytics layers — supports reprocessing and auditability
- **RFM with NTILE(5) quintiles**: Statistical bucketing rather than fixed thresholds — robust to data skew and adapts to dataset distribution
- **Pre-computed segment labels in dimension table**: Trades storage for query speed — Tableau queries hit a denormalised table without recomputing segments on every refresh
- **Separated returns from purchases**: Returns analysed independently rather than netted out — preserves the business signal in cancellation behaviour

---

## Data Quality Findings

The raw dataset required substantial cleaning. See [Docs/data_quality_findings.md](Docs/data_quality_findings.md) for the full breakdown. 

Summary:

- 22.8% of rows lacked customer ID (guest checkouts)
- 2.2% were returns/refunds (negative quantity)
- 75% of raw rows retained after cleaning

---

## How to Reproduce

1. Sign up for a Snowflake free trial (30 days, $400 credit) at https://signup.snowflake.com
2. Download the UCI Online Retail II dataset from https://archive.ics.uci.edu/dataset/502/online+retail+ii
3. Run the SQL files in order (01 → 05)
4. Export the analytics tables and load into Tableau

---

## About

Built by **Akram Ahmed** as part of a Cloud Data Analytics portfolio. Designed to demonstrate end-to-end pipeline construction, dimensional modelling, and business-facing analytics.

🔗 [Live dashboard](https://public.tableau.com/views/retail_segmentation/RetailDashboard)
