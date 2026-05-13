# Data Quality Findings

## Raw Layer
The UCI Online Retail II dataset contains **1,067,371 transactions** spanning Dec 2009 – Dec 2011 across 40+ countries. Initial profiling revealed four data quality issues requiring treatment before downstream analysis:

| Issue | Count | % of total | Treatment |
|---|---|---|---|
| Missing customer ID | 243,007 | 22.8% | Excluded from RFM (guest checkouts) — flagged as marketing opportunity |
| Negative quantity | 22,950 | 2.2% | Treated as returns/refunds — separated into `STG_RETURNS` |
| Zero or negative price | 6,225 | 0.6% | Administrative entries — removed |
| Missing description | 4,382 | 0.4% | Non-revenue records — removed |

After cleaning, the analytical dataset contained **802,937 transactions** from **5,862 identified customers** — approximately 75% of raw rows retained.

## Customer Segmentation Findings

Applying RFM scoring (Recency, Frequency, Monetary) with NTILE(5) quintiles across 5,862 customers revealed a classic Pareto distribution:

| Segment | Customers | Revenue | Avg Customer Value |
|---|---|---|---|
| Champions | 1,288 (22%) | £11.9M (68%) | £9,254 |
| At Risk | 224 (4%) | £1.0M | £4,595 |
| Loyal Customers | 432 | £1.7M | £3,825 |
| Lost | 1,267 | £323K | £255 |

**Key insights:**
- **22% of customers (Champions) generated 68% of revenue** — textbook Pareto distribution
- **At Risk segment represents £1M in protectable revenue** — only 224 customers, but second-highest average value (£4,595). Priority for retention campaigns.
- **Geographic split shows two business models**: 84% of revenue from UK retail (5,336 customers averaging £2,740), while international markets show wholesale patterns (EIRE: 5 customers averaging £120K each).

## Recommended Actions

1. **Champions retention**: VIP programme for top 1,288 customers protecting £11.9M
2. **At Risk recapture**: Targeted campaign for 224 high-value customers — even at 20% conversion, ROI is overwhelming at £15-30 acquisition cost vs £4,595 customer value
3. **Onboarding optimisation**: New Customers (428 customers, £518 average) — second highest opportunity for lifetime value uplift through onboarding flow
4. **Geographic strategy**: Separate UK retail and international wholesale customer journeys — different acquisition costs, retention strategies, and pricing models warranted