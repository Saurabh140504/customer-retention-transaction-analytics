# Customer Retention & Transaction Analytics — Excel & SQL Stages

> **Fresher-level Data Analyst portfolio project** — customer behavior, transaction performance, and retention analysis, built end-to-end across Excel and MySQL, with results cross-validated between the two.

This document combines the two completed stages of the project. Each stage builds on the same 5-table schema and reaches the same headline numbers, verified independently in each tool.

---

## Table of Contents

- [Dataset Scale](#dataset-scale)
  
- [Part 1 — Excel Stage](#part-1--excel-stage)
  - [1. Data Quality & Cleaning](#1-data-quality--cleaning)
  - [2. Power Pivot Data Model](#2-power-pivot-data-model)
  - [3. Calculated Fields](#3-calculated-fields)
  - [4. Activity Segment](#4-activity-segment)
  - [5. KPI Summary](#5-kpi-summary)
  - [6. Customer Analysis](#6-customer-analysis)
  - [7. Retention Analysis](#7-retention-analysis)
  - [8. RFM Analysis](#8-rfm-analysis)
  - [9. PivotTables](#9-pivottables)
  - [10. Pivot Charts](#10-pivot-charts)
  - [11. Validation](#11-validation)
  - [12. Key Business Questions Answered](#12-key-business-questions-answered)
    
- [Part 2 — SQL Stage](#part-2--sql-stage)
  - [1. Database Design & Schema](#1-database-design--schema)
  - [2. Staging Tables — Why They Were Needed](#2-staging-tables--why-they-were-needed)
  - [3. Data Import Process](#3-data-import-process)
  - [4. Data Cleaning During Import](#4-data-cleaning-during-import)
  - [5. Foreign Key Relationships](#5-foreign-key-relationships)
  - [6. Referential Integrity Validation](#6-referential-integrity-validation)
  - [7. Row Count Validation](#7-row-count-validation)
  - [8. 30 Core Business Queries](#8-30-core-business-queries)
  - [9. Cross-Tool Validation — SQL vs. Excel](#9-cross-tool-validation--sql-vs-excel)
  - [10. SQL Stage Status](#10-sql-stage-status)
- [Repository Structure](#repository-structure)
- [Next Stage](#next-stage)

---

## Dataset Scale

- **Customers:** 7,000
- **Products:** 50
- **Calendar days:** 1,156
- **Transactions:** 24,244
- **Support tickets:** 6,035
- **Transaction period:** Jan 2024 – Dec 2025

---

# Part 1 — Excel Stage

**Workflow:** Raw Data → Data Quality → Cleaning → Power Pivot Data Model → Customer Summary → KPIs → Retention → RFM → PivotTables → Charts

### Project Objective

The goal of this stage is to understand:

- Customer purchase behavior
- Transaction and revenue performance
- One-time vs. repeat customers
- Customer activity and inactivity
- Product and category performance
- Payment-method performance
- Time-based revenue and transaction trends
- Customer Recency, Frequency, and Monetary value (RFM)

The analysis is designed to answer business questions rather than simply demonstrate Excel functions.

### Workbook Structure

| Sheet | Purpose |
|---|---|
| `Date` | Calendar/date dimension |
| `Customer` | Customer dimension and cleaned customer attributes |
| `Product` | Product dimension |
| `Transcation` | Transaction fact table |
| `Ticket` | Customer support ticket fact table |
| `Customer_Summary` | One row per customer with purchase and activity metrics |
| `RFM` | Recency, Frequency, Monetary scoring |
| `KPI` | Headline business KPIs |
| `Pivot Tables` | Core business-analysis PivotTables |
| `Pivot Charts` | Visual summaries of the PivotTables |

---

## 1. Data Quality & Cleaning

The data was assessed before analysis. The objective was to **measure issues first and only fix issues that were genuinely broken**.

| Issue | Finding | Treatment |
|---|---:|---|
| Duplicate transaction IDs | 0 | No removal required |
| Duplicate ticket IDs | 0 | No removal required |
| Blank customer city | 278 | Converted to `Unknown` |
| Blank acquisition channel | 375 | Converted to `Unknown` |
| City case/space inconsistency | Multiple variants | Standardized with `TRIM` + `PROPER` |
| Quantity > 10 | 452 rows | Flagged as `Bulk Order`; not deleted |
| Ticket satisfaction/resolution blanks | 1,609 | Kept blank because they correspond to unresolved/open tickets |
| Ticket transaction ID blanks | 700 | Kept blank because these are valid general inquiries |

**No transaction or ticket rows were silently deleted during cleaning.**

### Key data-quality principle

A blank value does not automatically mean an error.

For example, an unresolved support ticket may legitimately have no satisfaction score yet. Filling that value with `0` or an average would create a value that was never observed.

---

## 2. Power Pivot Data Model

The workbook uses a Power Pivot Data Model instead of repeatedly copying dimension attributes into the transaction table.

<img width="1892" height="808" alt="Data Model Relationships" src="https://github.com/user-attachments/assets/4504aded-d2ac-4dbd-92cb-4f1b74715ff1" />

### Relationships

```text
Date      → Transcation
Product   → Transcation
Customer  → Transcation
Date      → Ticket
Customer  → Ticket
```

### Why `Transcation ↔ Ticket` is not directly connected

The two fact tables already share dimensions through `Customer` and `Date`. Adding another direct relationship between the two fact tables would introduce an ambiguous/closed filter path.

Therefore, at the Excel stage:

- `Ticket[related_order_value]` is populated with an `XLOOKUP`
- `Ticket[related_category]` is populated through `Transcation → Product`
- The Ticket analysis does not require a direct fact-to-fact relationship

### Why no relationship with Customer_Summary?

`Customer_Summary` is a calculated/helper table, not a core dimension or fact table.

It is created from `Transcation` to analyze customer-level metrics like revenue, frequency, recency, and segments.

Connecting it to the Data Model could create duplicate/ambiguous relationships, so it's kept separate. This keeps the Data Model simpler and avoids unnecessary relationships.

---

## 3. Calculated Fields

Useful calculated fields were added only where they support analysis.

**Transaction**
- `quantity_Status` → identifies `Bulk Order` vs `Standard`
- `Is Completed` → identifies completed transactions

**Customer**
- `location_clean_city` → trims spaces, standardizes case, and uses `Unknown` for true blanks
- `acquisition_clean_channel` → uses `Unknown` for true blanks

**Ticket**
- `related_order_value` → retrieves transaction value where a ticket is linked to an order
- `related_category` → retrieves the product category for order-linked tickets

**Customer Summary**
- Total Transactions
- Total Revenue
- First Purchase Date
- Last Purchase Date
- Days Since Last Purchase
- Repeat Customer Flag
- Customer Type
- Customer Value Segment
- Activity Segment

---

## 4. Activity Segment

An earlier version of the workbook used two slightly different definitions for the 180-day inactivity boundary. This was corrected so the workbook uses one consistent rule:

> **Inactive = more than 180 days since the customer's last purchase.**

| Days Since Last Purchase | Segment |
|---:|---|
| 0–90 | Active |
| 91–179 | At-Risk |
| 180+ | Inactive |

### Final validated distribution

| Activity Segment | Customers |
|---|---:|
| Active | 4,042 |
| At-Risk | 1,564 |
| Inactive | 1,394 |
| **Total** | **7,000** |

---

## 5. KPI Summary

| KPI | Result |
|---|---:|
| Total Customers | 7,000 |
| Total Transactions | 24,244 |
| Total Revenue | ₹4,17,33,140.75 |
| Total Revenue — Completed | ₹3,31,33,954.30 |
| Average Transaction Value | ₹1,721.38 |
| Revenue per Customer | ₹5,961.88 |
| Transactions per Customer | 3.463 |
| Repeat Customers | 3,907 |
| One-Time Customers | 3,093 |
| Repeat Customer Rate | 55.8% |
| Inactive Customers | 1,394 |
| Inactive Customer Rate | 19.9% |
| Median Transactions per Customer | 2 |

<img width="613" height="473" alt="KPI Pivot Summary" src="https://github.com/user-attachments/assets/75b4c585-9f55-4270-a21b-c6b9bc9d79e9" />

---

## 6. Customer Analysis

**Customer Type** — classified by transaction frequency:
- **One-Time:** exactly 1 transaction
- **Repeat:** more than 1 transaction
- Final split: **Repeat 3,907** / **One-Time 3,093** / **Total 7,000**

**Customer Value Segment** — top 20% of customers by total revenue are `High-Value`, the rest `Standard`. A relative, data-driven segmentation rather than an arbitrary threshold.

**Activity Segment** — based on recency (Active / At-Risk / Inactive). The dataset's maximum transaction date is used as the reference point rather than `TODAY()`, so recency stays meaningful for this historical dataset.

---

## 7. Retention Analysis

**Repeat Customer Rate:** **55.8%** of customers made more than one purchase.

**Purchase Frequency:**
- Average transactions/customer: **3.463**
- Median transactions/customer: **2**
- Maximum observed transactions for a customer: **176**

The median is used alongside the average because purchase frequency is right-skewed.

**Inactive Customers:** **1,394 customers** are classified as inactive using the consistent 180+ day definition.

---

## 8. RFM Analysis

Performed on a separate `RFM` sheet.

| Dimension | Meaning | Scoring |
|---|---|---|
| **Recency** | Days since last purchase | Lower is better |
| **Frequency** | Number of transactions | Higher is better |
| **Monetary** | Total customer revenue | Higher is better |

Each dimension receives a **1–5 score** using quintile/percentile splits. Example: `545` = strong recency, strong frequency, strong monetary value. The scoring is intentionally simple and suitable for a fresher-level analytics project.

---

## 9. PivotTables

The workbook contains **9 core PivotTables**, each built from the Power Pivot Data Model.

| # | PivotTable | Business Question |
|---:|---|---|
| 1 | Revenue by Year + Month | How is revenue changing over time? |
| 2 | Transactions by Year + Month | How is transaction volume changing? |
| 3 | Revenue by Product Category | Which categories generate the most revenue? |
| 4 | Top 10 Products by Revenue | Which products perform best? |
| 5 | Revenue by City | Which cities generate the most revenue? |
| 6 | Revenue by Payment Method | Which payment methods contribute to revenue? |
| 7 | Customer Count by Type (One-Time vs. Repeat) | How many customers are repeat vs. one-time buyers? |
| 8 | Revenue by Order Status | How much revenue is associated with each order status? |
| 9 | Customer Count by Activity Segment | How many customers are Active, At-Risk, or Inactive? |

Every PivotTable is designed to answer a **business question**, not simply demonstrate a feature. Pivot #9 is the source of the Activity Segment distribution reported in Section 4.

<img width="1742" height="656" alt="Pivot Analysis Overview" src="https://github.com/user-attachments/assets/7e661800-9cbc-4a1f-bd3d-a04cc72b8c97" />

---

## 10. Pivot Charts

The workbook contains **8 charts**, each built directly from a PivotTable above.

| # | Chart | Chart Type | Based On |
|---:|---|---|---|
| 1 | Revenue By Date | Line | Pivot #1 |
| 2 | Transaction Count by Date | Line | Pivot #2 |
| 3 | Category Wise Revenue | Column | Pivot #3 |
| 4 | Top 10 Product Name | Bar | Pivot #4 |
| 5 | City Wise Revenue | Column | Pivot #5 |
| 6 | Revenue by Mode | Column | Pivot #6 |
| 7 | Status by Revenue | Column | Pivot #8 |
| 8 | Customer by Segment | Column | Pivot #9 |

**Chart-selection principle:** Line → trends · Column → comparisons · Bar → rankings · Donut → simple composition · Stacked column → comparison across a second dimension.

---

## 11. Validation

- Total customers = **7,000**
- Total transactions = **24,244**
- Total revenue = **₹4,17,33,140.75**
- Repeat + One-Time customers = **7,000**
- Active + At-Risk + Inactive = **7,000**
- Inactive count consistently = **1,394**
- Completed revenue = **₹3,31,33,954.30**

The goal of validation is to ensure that cleaning, formulas, PivotTables, and charts do not silently produce conflicting results.

---

## 12. Key Business Questions Answered

- How much revenue was generated, and how much came from completed orders?
- How is revenue changing over time?
- Which product categories and products perform best?
- Which cities and payment methods generate the most revenue?
- How many customers are one-time vs. repeat, and what's the repeat customer rate?
- How many customers are inactive, and which are active, at-risk, or high-value?
- How frequently do customers purchase?

**Excel checkpoint: stage completed and validated.**

---

# Part 2 — SQL Stage

> Reproducing the Excel-stage business questions in a real relational database, using MySQL.

**Workflow:** Database Design → Table Creation → Staging Tables → Data Import → Data Cleaning → Foreign Keys → Validation → Business Queries

### Project Objective

- Rebuild the Excel Data Model as a real relational database with enforced relationships
- Reproduce the same KPIs and business questions from the Excel stage in SQL, and confirm the numbers match
- Handle real import problems (date formats, blank numeric fields) the way they'd be handled on the job — with staging tables and explicit conversion, not by editing the raw source data
- Apply joins, CTEs, and window functions to answer deeper business questions than Excel could easily support

### Database Structure

**Database name:** `RT`

| Table | Type | Purpose |
|---|---|---|
| `Customers` | Dimension | One row per customer |
| `Products` | Dimension | One row per product |
| `Date_Table` | Dimension | One row per calendar day |
| `Transactions` | Fact | One row per order line |
| `Customers_Support` | Fact | One row per support ticket |
| `Date_Table_Staging` | Temporary | Used only during import, then dropped |
| `Customers_Support_Staging` | Temporary | Used only during import, then dropped |

---

## 1. Database Design & Schema

The schema mirrors the Excel Power Pivot Data Model exactly — same 5 core tables, same relationships, same reasoning for what's connected and what isn't.

```text
Customers   → Transactions        (customer_id)
Products    → Transactions        (product_id)
Date_Table  → Transactions        (transaction_date ↔ date_key)
Customers   → Customers_Support   (customer_id)
Date_Table  → Customers_Support   (ticket_date ↔ date_key)
```

### Why `Transactions ↔ Customers_Support` is not directly connected

Both fact tables already connect indirectly through `Customers` and `Date_Table`. Adding a third, direct relationship between them would create a closed loop across the same three tables — an ambiguous path that both MySQL's constraint model and Power BI's relationship engine can't cleanly resolve. This is the same design decision made in the Excel stage.

`Customers_Support.transaction_id` still exists as a column and is used for lookups (`related_order_value`, `related_category`), just without an enforced foreign key.

---

## 2. Staging Tables — Why They Were Needed

Two of the five source files couldn't be imported directly into their final, strictly-typed tables:

| Table | Problem | Fix |
|---|---|---|
| `Date_Table` | `date_key` is a strict `DATE PRIMARY KEY`. Rows with a date format MySQL couldn't parse were silently rejected, producing "0 rows imported" with no error. | Load into `Date_Table_Staging` (`date_key` as `VARCHAR`) first, then convert with `STR_TO_DATE()` into the final table. |
| `Customers_Support` | `resolution_hours`, `satisfaction_score`, and `related_order_value` are legitimately blank for open tickets. A `DECIMAL` column rejects an empty string — it needs a true `NULL`. | Load into `Customers_Support_Staging` (numeric columns as `VARCHAR`) first, then convert blanks to `NULL` with `NULLIF(TRIM(x), '')` into the final table. |

`Customers`, `Products`, and `Transactions` had no such issues and were imported directly.

---

## 3. Data Import Process

1. Create all 5 final tables + 2 staging tables.
2. Enable local file loading: `SET GLOBAL local_infile = 1;` (required on both client and server sides in MySQL Workbench).
3. Import each CSV into its correct destination via the **Table Data Import Wizard**:

| CSV file | Imported into |
|---|---|
| `customers.csv` | `Customers` (direct) |
| `products.csv` | `Products` (direct) |
| `transactions.csv` | `Transactions` (direct) |
| `date_table.csv` | `Date_Table_Staging` |
| `customers_support.csv` | `Customers_Support_Staging` |

4. Run the conversion `INSERT ... SELECT` statements to move `Date_Table_Staging` → `Date_Table` and `Customers_Support_Staging` → `Customers_Support`.
5. Drop both staging tables once row counts are confirmed.

---

## 4. Data Cleaning During Import

| Issue | Handling |
|---|---|
| Non-standard date format in `date_table.csv` | Converted with `STR_TO_DATE(date_key, '%Y-%m-%d')` |
| `is_weekend` stored as text (`TRUE`/`FALSE`/etc.) | Normalized with a `CASE` expression into `1`/`0` |
| Blank `resolution_hours`, `satisfaction_score`, `related_order_value` for open tickets | Converted to true `NULL` with `NULLIF(TRIM(x), '')`, never treated as an error |
| Extra `quantity_Status` column present in the raw transactions export | Discarded on import — it's a derived Bulk/Standard flag, recomputed with `CASE WHEN quantity > 10` in queries instead of stored redundantly |

No rows were deleted at any point in this process.

---

## 5. Foreign Key Relationships

Added only after all data was loaded and validated — enforcing them upfront makes import failures much harder to debug.

```sql
Transactions.customer_id       → Customers.customer_id
Transactions.product_id        → Products.product_id
Transactions.transaction_date  → Date_Table.date_key
Customers_Support.customer_id  → Customers.customer_id
Customers_Support.ticket_date  → Date_Table.date_key
```

**5 relationships**, confirmed via:
```sql
SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'rt'
  AND REFERENCED_TABLE_NAME IS NOT NULL;
```

---

## 6. Referential Integrity Validation

Run before adding foreign keys, to catch orphaned records with a readable result instead of a blunt constraint-violation error:

- Orphan `customer_id` in `Transactions` — 0 rows
- Orphan `product_id` in `Transactions` — 0 rows
- Orphan `transaction_date` in `Transactions` — 0 rows
- Orphan `customer_id` in `Customers_Support` — 0 rows
- Orphan `transaction_id` in `Customers_Support` (excluding legitimate NULLs) — 0 rows
- Orphan `ticket_date` in `Customers_Support` — 0 rows

All six checks passed with zero orphaned rows.

---

## 7. Row Count Validation

| Table | Expected | Confirmed |
|---|---:|:---:|
| `Customers` | 7,000 | ✅ |
| `Products` | 50 | ✅ |
| `Date_Table` | 1,156 | ✅ |
| `Transactions` | 24,244 | ✅ |
| `Customers_Support` | 6,035 | ✅ |

---

## 8. 30 Core Business Queries

All 30 queries are organized into 6 sections, matching the Excel-stage business questions one-for-one where possible, so results can be cross-checked between tools:

1. **Checking the data is trustworthy** — row counts, duplicates, nulls, orphan checks
2. **Getting a feel for the basics** — payment methods, top orders, order status breakdown, bulk vs. standard
3. **Bringing the tables together** — revenue by category/city/month, ticket counts per customer
4. **Understanding each customer's story** — full customer summary, one-time vs. repeat split, 180-day inactivity, support-ticket impact on spend
5. **Ranking and tracking trends over time** — purchase sequence, top 20 customers, month-over-month change, running revenue total, top product per category
6. **Answering the bigger business questions** — above-average spenders, top 10 products, payment method revenue, weekday vs. weekend, support resolution/satisfaction by category, acquisition channel performance

Check the top 30 core business queries: https://github.com/Saurabh140504/customer-retention-transaction-analytics/tree/51c027935adb8b5535477aa1ad8f22bd6e024d04/SQL

---

## 9. Cross-Tool Validation — SQL vs. Excel

| Metric | Excel | SQL |
|---|---:|---:|
| Total Customers | 7,000 | 7,000 |
| Total Transactions | 24,244 | 24,244 |
| Repeat Customer Rate | 55.8% | 55.8% |
| Inactive Customers (180+ days) | 1,394 | 1,394 |

The 180-day inactivity query exists specifically to reproduce and confirm the Excel `Activity Segment` figure — the same metric whose boundary-condition mismatch was found and fixed during the Excel stage.

---

## 10. SQL Stage Status

| Area | Status |
|---|---|
| Database & schema design | ✅ Complete |
| Staging tables | ✅ Complete |
| Data import | ✅ Complete |
| Data cleaning during import | ✅ Complete |
| Foreign key relationships | ✅ 5 relationships, validated |
| Referential integrity checks | ✅ All 6 checks passed |
| Row count validation | ✅ Complete |
| 30 core business queries | ✅ Complete |
| Cross-tool validation vs. Excel | ✅ Complete |

**SQL checkpoint: stage completed and validated.**

---

## Repository Structure

```text
Customer-Retention-Transaction-Analytics/
│
├── README.md
│
├── excel/
│   ├── Customer_Analysis.xlsx
│   └── images/
│       ├── data-model-relationships.png
│       ├── pivot-table-summary.png
│       └── pivot-charts-overview.png
│
├── sql/
│   ├── Customer Retention & Transaction Analysis Updated
│
├── python/
│   └── ...
│
├── powerbi/
│   └── ...
│
└── report/
    └── ...
```

**Tools used — Excel stage:** Microsoft Excel · Excel Tables · Power Pivot · PivotTables · Pivot Charts · XLOOKUP · COUNTIF/COUNTIFS · SUMIF · MINIFS/MAXIFS · PERCENTILE.INC · Customer segmentation · RFM analysis

**Tools used — SQL stage:** MySQL / MySQL Workbench · Table Data Import Wizard · Staging tables + `STR_TO_DATE()`/`NULLIF()` conversion · Joins (`INNER`, `LEFT`) · CTEs (`WITH`) · Window functions (`ROW_NUMBER`, `RANK`, `LAG`, `SUM() OVER`) · Foreign key constraints · `information_schema` relationship auditing

---

## Next Stage

**Python — Data Loading → EDA → Statistical Summary → Outlier Investigation → Customer & Trend Analysis → Visualizations**
