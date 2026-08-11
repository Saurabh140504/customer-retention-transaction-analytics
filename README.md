# Customer Retention & Transaction Analytics — Excel Stage

> **Fresher-level Data Analyst portfolio project** focused on customer behavior, transaction performance, retention, and business insights using Microsoft Excel.

**Workflow:** Raw Data → Data Quality → Cleaning → Power Pivot Data Model → Customer Summary → KPIs → Retention → RFM → PivotTables → Charts

---

## Project Objective

The goal of this Excel stage is to understand:

- Customer purchase behavior
- Transaction and revenue performance
- One-time vs. repeat customers
- Customer activity and inactivity
- Product and category performance
- Payment-method performance
- Time-based revenue and transaction trends
- Customer Recency, Frequency, and Monetary value (RFM)

The analysis is designed to answer business questions rather than simply demonstrate Excel functions.

---

## Workbook Structure

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

### Dataset scale

- **Customers:** 7,000
- **Transactions:** 24,244
- **Products:** 50
- **Support tickets:** 6,035
- **Transaction period:** Jan 2024 – Dec 2025

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

<img width="1892" height="808" alt="Screenshot 2026-08-12 013454" src="https://github.com/user-attachments/assets/4504aded-d2ac-4dbd-92cb-4f1b74715ff1" />


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

Customer_Summary is a calculated/helper table, not a core dimension or fact table.

It is created from Transactions to analyze customer-level metrics like revenue, frequency, recency, and segments.

Connecting it to the Data Model could create duplicate/ambiguous relationships, so we keep it separate.

This keeps the Excel Data Model simpler and avoids unnecessary relationships.

---

## 3. Calculated Fields

Useful calculated fields were added only where they support analysis.

### Transaction

- `quantity_Status` → identifies `Bulk Order` vs `Standard`
- `Is Completed` → identifies completed transactions

### Customer

- `location_clean_city` → trims spaces, standardizes case, and uses `Unknown` for true blanks
- `acquisition_clean_channel` → uses `Unknown` for true blanks

### Ticket

- `related_order_value` → retrieves transaction value where a ticket is linked to an order
- `related_category` → retrieves the product category for order-linked tickets

### Customer Summary

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

An earlier version of the workbook used two slightly different definitions for the 180-day inactivity boundary.

This was corrected so the workbook uses one consistent rule:

> **Inactive = more than 180 days since the customer's last purchase.**

The Activity Segment is:

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

<img width="613" height="473" alt="Screenshot 2026-08-12 014848" src="https://github.com/user-attachments/assets/75b4c585-9f55-4270-a21b-c6b9bc9d79e9" />

---

## 6. Customer Analysis

### Customer Type

Customers are classified based on transaction frequency:

- **One-Time:** exactly 1 transaction
- **Repeat:** more than 1 transaction

Final split:

- **Repeat:** 3,907
- **One-Time:** 3,093
- **Total:** 7,000

### Customer Value Segment

The top 20% of customers by total revenue are classified as:

- `High-Value`
- `Standard`

This is a relative, data-driven segmentation rather than an arbitrary revenue threshold.

### Activity Segment

Activity is based on recency:

- Active
- At-Risk
- Inactive

The dataset's maximum transaction date is used as the reference date rather than `TODAY()`, so recency remains meaningful for the historical dataset.

---

## 7. Retention Analysis

The core retention findings are:

### Repeat Customer Rate

**55.8%** of customers made more than one purchase.

### Purchase Frequency

- Average transactions/customer: **3.463**
- Median transactions/customer: **2**
- Maximum observed transactions for a customer: **176**

The median is useful because purchase frequency is right-skewed.

### Inactive Customers

**1,394 customers** are classified as inactive using the consistent 180+ day definition.

---

## 8. RFM Analysis

RFM is performed on a separate `RFM` sheet.

| Dimension | Meaning | Scoring |
|---|---|---|
| **Recency** | Days since last purchase | Lower is better |
| **Frequency** | Number of transactions | Higher is better |
| **Monetary** | Total customer revenue | Higher is better |

Each dimension receives a **1–5 score** using quintile/percentile splits.

Example:

> `545` = strong recency, strong frequency, strong monetary value.

The scoring is intentionally simple and suitable for a fresher-level analytics project.

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

### PivotTable principle

Every PivotTable is designed to answer a **business question**, not simply demonstrate a feature.

Pivot #9 is the source of the Activity Segment distribution reported in Section 4.

<img width="1742" height="656" alt="Screenshot 2026-08-12 013224" src="https://github.com/user-attachments/assets/7e661800-9cbc-4a1f-bd3d-a04cc72b8c97" />

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

### Chart-selection principle

- Line → trends
- Column → comparisons
- Bar → rankings
- Donut → simple composition
- Stacked column → comparison across a second dimension

---

## 11. Validation

Important numbers were cross-checked across the workbook.

### Reconciliation checks

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

The Excel stage helps answer:

- How much revenue was generated?
- How much revenue came from completed orders?
- How is revenue changing over time?
- Which product categories perform best?
- Which products are top revenue contributors?
- Which cities generate the most revenue?
- Which payment methods are associated with revenue?
- How many customers are one-time vs repeat?
- What is the repeat customer rate?
- How many customers are inactive?
- Which customers are active, at-risk, or inactive?
- Which customers have high monetary value?
- How frequently do customers purchase?

---

### Excel checkpoint

**Excel stage completed and validated.**

The next project stage is **SQL**, where the same business questions will be reproduced using database tables and SQL queries.

---

## GitHub Repository Structure

Recommended structure:

```text
Customer-Retention-Transaction-Analytics/
│
├── README.md
│
├── Excel/
│   └── Customer_Analysis.xlsx
│
├── images/
│   ├── data-model-relationships.png
│   ├── pivot-table-summary.png
│   ├── pivot-charts-overview.png
│
├── SQL/
│   └── ...
│
├── Python/
│   └── ...
│
├── PowerBI/
│   └── ...
│
└── Report/
    └── ...
---

## Tools Used

- Microsoft Excel
- Excel Tables
- Power Pivot
- PivotTables
- Pivot Charts
- XLOOKUP
- COUNTIF / COUNTIFS
- SUMIF
- MINIFS / MAXIFS
- PERCENTILE.INC
- Customer segmentation
- RFM analysis

---

## Next Stage

**SQL — Database Design → Data Loading → Validation → Cleaning → Business Queries → Customer & Retention Analysis**
