# Customer Retention & Transaction Analytics

> An end-to-end Data Analyst portfolio project — the same analysis built independently in Excel, MySQL, Python, and Power BI, with every core number cross-checked across all four tools before being called final.

---

## Business Problem

This project is built around a retail/e-commerce business that sells across five product categories — Electronics, Apparel, Home, Beauty, and Sports — to customers in six Indian cities. The business has plenty of data: transaction records, customer details, and support-ticket history. What it doesn't have is a clear, trustworthy answer to some basic but important questions:

- How many customers actually come back and buy again, versus buying once and disappearing?
- Which customers have gone quiet, and are they worth trying to win back?
- Are certain product categories, cities, or payment methods carrying most of the revenue while others barely contribute?
- Do customers who raise a support ticket behave differently afterward — and if so, is that something the business should actually worry about, or just a side effect of being a more active customer in the first place?

The goal of this project was to turn the raw data into real, defensible answers to these questions — not a single one-off report, but the **same analysis rebuilt independently four separate times**, once in each tool, so that no number is trusted just because it came out of a spreadsheet once. If Excel, SQL, Python, and Power BI all land on the exact same repeat-customer rate and the exact same inactive-customer count, that's a number a manager can genuinely act on.

I also treated this project the way I'd want to be judged in a real job — not just the polished final output, but the actual process. Along the way I found and fixed real mistakes: a wrong count that I'd repeated across multiple documents, a database password that ended up hardcoded in a notebook, a chart that was silently aggregating the wrong way, and an inconsistent business rule that gave two different answers for the same metric. Each of those is documented here, not hidden, because catching your own mistakes is part of doing this work properly.

### Objectives

- Build one consistent, validated definition of "repeat customer," "inactive customer," and "high-value customer," and use it everywhere
- Identify which customers are at risk of churning, and roughly how large that group is
- Understand which products, categories, cities, and payment methods actually drive the business
- Test whether support-ticket history relates to customer spending, without overclaiming cause and effect
- Reproduce every KPI in four different tools, so the final numbers are provably consistent, not just plausible

### Who This Would Matter To (Stakeholders)

- **Retention / CRM Manager** — wants to know who's at risk of leaving and where to focus win-back efforts
- **Marketing Manager** — wants to know which acquisition channels and categories are actually working
- **Customer Support Manager** — wants to know if certain issue types are hurting customer satisfaction more than others
- **Finance / Senior Management** — wants a trustworthy, validated set of numbers to make decisions from

---

## Table of Contents

- [Dataset Overview](#dataset-overview)
- [Part 1 — Excel](#part-1--excel)
- [Part 2 — SQL](#part-2--sql)
- [Part 3 — Python](#part-3--python)
- [Part 4 — Power BI](#part-4--power-bi)
- [Cross-Tool Validation](#cross-tool-validation)
- [Key Insights & Recommendations](#key-insights--recommendations)
- [Repository Structure](#repository-structure)
- [Tools Used](#tools-used)
- [Limitations](#limitations)

---

## Dataset Overview

| Table | Rows | What one row means |
|---|---:|---|
| `Customers` | 7,000 | One customer |
| `Products` | 50 | One product |
| `Date_Table` | 1,156 | One calendar day |
| `Transactions` | 24,244 | One product bought in one order |
| `Customers_Support` | 6,035 | One support ticket |

**Period covered:** January 2024 – December 2025

This is a proper star schema — two fact tables (`Transactions`, `Customers_Support`) sharing three dimension tables (`Customers`, `Products`, `Date_Table`) — not just one big flat spreadsheet. That structure is what made it possible to rebuild the same logic cleanly across all four tools.

---

# Part 1 — Excel

**Flow:** Clean the data → Build a proper data model → Calculate KPIs → Segment customers → RFM scoring → PivotTables & Charts

### Data Cleaning

The rule I followed: check for problems first, and only fix what's genuinely broken. A blank value isn't automatically an error — an unresolved support ticket, for example, legitimately has no satisfaction score yet, and filling it with a 0 or an average would invent a number that was never actually observed.

| Issue | Finding | What I did |
|---|---:|---|
| Duplicate transaction or ticket IDs | 0 | Nothing to fix |
| Blank customer city | 278 | Labeled "Unknown," not guessed |
| Blank acquisition channel | 375 | Labeled "Unknown," not guessed |
| City name inconsistency (e.g. "mumbai" vs "Mumbai") | Multiple variants | Standardized with TRIM + PROPER |
| Orders with quantity over 10 | 457 rows | Flagged as "Bulk Order," kept in the data |
| Blank ticket resolution time / satisfaction score | 1,609 | Left blank — these are still-open tickets, not missing data |
| Blank transaction ID on a ticket | 700 | Left blank — these are general inquiries with no linked order |

No rows were ever silently deleted during cleaning.

### Data Model

Rather than copying date and category fields into every single transaction row, I built a real Power Pivot Data Model with proper relationships:

```text
Date      → Transaction
Product   → Transaction
Customer  → Transaction
Date      → Ticket
Customer  → Ticket
```

**Why Transaction and Ticket aren't directly linked:** they already connect indirectly through Customer and Date. Adding a third, direct link between them would create an ambiguous filter path — Excel wouldn't know which route to trust when filtering. Instead, I used lookup formulas (`related_order_value`, `related_category`) to pull transaction detail onto the Ticket table where needed, without adding a conflicting relationship.

### Calculated Fields

- **On Transaction:** `quantity_Status` (Bulk Order vs. Standard), `Is Completed`
- **On Customer:** `location_clean_city`, `acquisition_clean_channel`
- **On Ticket:** `related_order_value`, `related_category`
- **On Customer Summary:** Total Transactions, Total Revenue, First/Last Purchase Date, Days Since Last Purchase, Customer Type, Value Segment, Activity Segment

### Key KPIs

| KPI | Result |
|---|---:|
| Total Revenue | ₹4,17,33,140.75 (~₹41.73M)|
| Total Revenue — Completed only | ₹3,31,33,954.30  (~₹33.13M)|
| Total Transactions | 24,244 |
| Average Transaction Value | ₹1,721.38 |
| Revenue per Customer | ₹5,961.88 |
| Repeat Customers | 3,907 |
| One-Time Customers | 3,093 |
| Repeat Customer Rate | 55.8% |
| Inactive Customers (180+ days) | 1,394 (19.9%) |
| Active / At-Risk / Inactive | 4,042 / 1,564 / 1,394 |

### Data Model Relationships 
<img width="1892" height="808" alt="Data Model Relationships" src="https://github.com/user-attachments/assets/4504aded-d2ac-4dbd-92cb-4f1b74715ff1" />

### Pivot Overview
<img width="1742" height="656" alt="Pivot Overview" src="https://github.com/user-attachments/assets/7e661800-9cbc-4a1f-bd3d-a04cc72b8c97" />

### KPI Summary
<img width="613" height="473" alt="KPI Summary" src="https://github.com/user-attachments/assets/75b4c585-9f55-4270-a21b-c6b9bc9d79e9" />

### Customer Segmentation

- **Customer Type:** One-Time (exactly 1 purchase) vs. Repeat (2+ purchases)
- **Value Segment:** Top 20% of customers by total revenue are "High-Value," the rest "Standard" — a relative, data-driven cutoff rather than an arbitrary number
- **Activity Segment:** Active (0–90 days since last purchase), At-Risk (91–179 days), Inactive (180+ days) — measured against the dataset's own latest date, not `TODAY()`, since the data itself ends in December 2025

**A real bug I found and fixed here:** an earlier version of the workbook used two slightly different rules for the 180-day cutoff, and they disagreed by a few customers. I tracked it down to a `>` vs `>=` difference and made both consistent.

### RFM Analysis

Each customer scored 1–5 on Recency (days since last purchase), Frequency (number of orders), and Monetary (total spend), combined into a 3-digit score — e.g. `545` means very recent, very frequent, and a high spender.

### PivotTables & Charts

**9 PivotTables**, each built to answer one specific business question — revenue trend by month, revenue by category, revenue by city, one-time vs. repeat split, activity segment split, and more. **8 charts** built directly from those pivots, using the chart type that actually fits the question (line for trends, bar for rankings, column for comparisons, donut for simple composition).

##### Excel Analysis File :[View Financial Data](Excel)

✅ **Excel stage complete and validated** — every KPI checked twice before moving to SQL.

---

# Part 2 — SQL

**Flow:** Design the schema → Load the data → Fix two real import problems → Add relationships → Validate → Write 30 business queries

### Database Structure

Database name: **`RT`**, in MySQL. Same 5-table structure as Excel: `Customers`, `Products`, `Date_Table`, `Transactions`, `Customers_Support`.

```text
Customer   → Transaction        (customer_id)
Product    → Transaction        (product_id)
Date_Table → Transaction        (transaction_date ↔ date_key)
Customer   → Customers_Support  (customer_id)
Date_Table → Customers_Support  (ticket_date ↔ date_key)
```

Same reasoning as Excel: `Transactions` and `Customers_Support` are **not** directly linked in the model, since they already connect through Customer and Date, and a third link would create the same ambiguous-filter problem in SQL and Power BI as it would in Excel.

### Two Real Problems I Hit During Import

**Dates silently failed.** MySQL's strict `DATE` column type couldn't parse the date format coming out of Excel, and instead of throwing a clear error, the import just loaded **0 rows** with no explanation. I fixed this by loading the date column into a temporary "staging" table as plain text first, then converting it properly with `STR_TO_DATE()` before moving it into the real table.

**Blank numbers broke the import.** Open support tickets legitimately have no resolution time or satisfaction score yet — but a `DECIMAL` column can't accept an empty string, only a real number or a true `NULL`. Same fix: load into a staging table as text, convert blanks to actual `NULL` with `NULLIF(TRIM(x), '')`, then move the clean data into the final table.

`Customers`, `Products`, and `Transactions` had no such issues and loaded directly.

### Relationships & Validation

The 5 foreign keys were added only *after* all data was loaded and checked — enforcing them upfront would have made the import errors above much harder to debug. Before adding them, I ran 6 checks specifically looking for "orphan" records (e.g., a transaction pointing to a customer_id that doesn't actually exist) — all 6 came back with **zero** orphaned rows.

| Table | Expected Rows | Confirmed |
|---|---:|:---:|
| Customers | 7,000 | ✅ |
| Products | 50 | ✅ |
| Date_Table | 1,156 | ✅ |
| Transactions | 24,244 | ✅ |
| Customers_Support | 6,035 | ✅ |

### 30 Core Business Queries

Grouped into 6 simple sections: checking the data is trustworthy, getting a feel for the basics, joining the tables together, understanding each customer's story, ranking and tracking trends over time, and answering the bigger business questions (top products, payment methods, weekday vs. weekend, support performance, acquisition channel).

##### Full SQL Queries: [`sql/30_core_queries.sql`](SQL)

✅ **SQL matches Excel exactly** on every core number — Total Revenue, Repeat Rate, Inactive Count, all identical.

---

# Part 3 — Python

**Flow:** Load the data → Confirm the cleaning (don't redo it) → Explore → Real statistics → Rebuild customer segments a third time → RFM → Charts → Written insights

### Why Python, After Excel and SQL Already Did the Analysis

Python's job here wasn't to repeat the cleaning — that was already done and checked twice. It was to go a level deeper than Excel or SQL could easily do:

- **Real outlier testing.** I ran the IQR statistical method on order quantity and got **1,601** statistically unusual orders — much higher than the **457** flagged by the simple "over 10 units" business rule used in Excel and SQL. Both numbers are legitimate; they're just answering different questions. The business rule identifies a specific, deliberate buyer behavior (probably bulk/wholesale-style purchases); the statistical method just flags anything unusually large relative to the rest of the data.
- **Proper RFM scoring**, using rank-based quintiles so the Recency, Frequency, and Monetary scores are all built the same consistent way.
- **A third independent rebuild** of the Customer Summary — same logic as Excel and SQL, written from scratch in pandas.

### A Security Mistake I Fixed

My first draft of this notebook had my actual MySQL password typed directly into the connection code. Before this went anywhere near GitHub, I replaced it with a secure runtime prompt (`getpass()`) so the password is never stored in the file, and I changed my real password since it had already been exposed once.

### Result

| Metric | Excel | SQL | Python |
|---|---:|---:|---:|
| Repeat Customers | 3,907 | 3,907 | 3,907 |
| One-Time Customers | 3,093 | 3,093 | 3,093 |
| Inactive Customers | 1,394 | 1,394 | 1,394 |

All three tools agree exactly — this is the checkpoint that matters most in the whole project.

**Notebook:** [`python/Customer_Retention_Transaction_Analytics.ipynb`](Python)

✅ **Python matches Excel and SQL exactly.**

---

# Part 4 — Power BI

**Flow:** Connect the data → Build the data model → Write DAX measures → Build 5 report pages → Add filters and interactivity → Validate everything one last time

### Data Model

Same 5 tables as Excel and SQL, plus the `RFM` table built during the Python stage. The `Transactions ↔ Customers_Support` relationship exists in the model here too — but it's kept **inactive** by default, for the same reason as before, and switched on only for one specific chart (ticket count by product category) using `USERELATIONSHIP()`. This is genuinely the correct way to handle this situation in a real BI tool, rather than a workaround.

### The 5 Pages — No Chart Repeated Anywhere

**1. Executive Overview** — headline revenue, transactions, customers, repeat rate, monthly trend, revenue by order status.

<img width="1317" height="751" alt="Executive Overview" src="https://github.com/user-attachments/assets/e762b81b-2ee0-4aa5-a877-bf83239247bc" />


**2. Customer Analysis** — repeat vs. one-time split, top 10 customers by revenue, value segments, revenue by acquisition channel.

<img width="1316" height="742" alt="Customer Analysis" src="https://github.com/user-attachments/assets/f3502ecf-cf9d-45b3-9238-42db7c8bd2ce" />


**3. Retention & RFM Analysis** — Active/At-Risk/Inactive breakdown, RFM segment split, and revenue/transactions compared for customers with vs. without a support ticket.

<img width="1321" height="745" alt="Retention & RFM Analysis" src="https://github.com/user-attachments/assets/32cc5efc-545d-4744-b3ee-1ea2f7be3bdc" />


**4. Product & Transaction Analysis** — category and product revenue, bulk vs. standard order split, payment method, weekday vs. weekend patterns.

<img width="1327" height="751" alt="Product & Transaction Analysis" src="https://github.com/user-attachments/assets/b9959b2e-24c2-4dea-b8d1-261a627caea1" />


**5. Support & Service Analysis** — ticket volume by issue category and status, resolution time and satisfaction by issue type, and tickets by product category.

<img width="1322" height="743" alt="Support & Service Analysis" src="https://github.com/user-attachments/assets/418092ee-4de1-4fa7-9498-e7f4b5897f18" />

The last chart on Page 5 closes a gap that had been sitting open since the Excel stage — the underlying lookup data existed early in the project but was never actually turned into a chart until this report.

### A Chart Bug I Found and Fixed

An early version of one RFM table showed "CUST-0001" as the grand "Total" — which made no sense for a total. It turned out I'd left the field set to aggregate by "First" value instead of "Count," so instead of counting customers, it was just showing whichever customer ID happened to appear first in the table. Fixed by switching it to a proper `DISTINCTCOUNT` measure.

##### Power BI File: [Download the .pbix](Power%20BI/Customer%20Retention%20%26%20Transaction%20Analysis.pbix)
✅ **Power BI matches Excel, SQL, and Python** on every headline number.

---

## Cross-Tool Validation

This table is really the whole point of the project — the same numbers, four independent ways:

| Metric | Excel | SQL | Python | Power BI |
|---|---:|---:|---:|---:|
| Total Revenue | ₹4,17,33,140.75 | ✅ | — | ₹41.73M ✅ |
| Total Transactions | 24,244 | ✅ | ✅ | 24.24K ✅ |
| Total Customers | 7,000 | ✅ | ✅ | 7K ✅ |
| Repeat Customers | 3,907 | 3,907 | 3,907 | 3.9K ✅ |
| One-Time Customers | 3,093 | 3,093 | 3,093 | 3.1K ✅ |
| Repeat Customer Rate | 55.8% | 55.8% | 55.8% | 55.8% ✅ |
| Inactive Customers (180+ days) | 1,394 | 1,394 | 1,394 | 1.4K ✅ |
| Active / At-Risk / Inactive | 4,042 / 1,564 / 1,394 | — | — | ✅ |
| Bulk Orders (quantity > 10) | 457 | 457 | 457 | 457 ✅ |
| Completed Revenue | ₹3,31,33,954.30 | — | — | ₹33.13M ✅ |

---

## Key Insights & Recommendations

**1. Nearly 1 in 5 customers has gone quiet.** 1,394 customers (19.9%) haven't purchased in 180+ days. Since they've already bought before, winning them back is cheaper than finding new customers. → Worth a targeted win-back campaign, prioritized by how much they used to spend.

**2. "Bulk Orders" are a small but distinct group, not a data problem.** 457 orders have unusually high quantity, but the amounts stay internally consistent — nothing looks broken. → Worth checking if these are wholesale-style buyers who'd respond to a different pricing plan.

**3. Revenue is concentrated in a few categories.** Electronics, Home, and Apparel do most of the work; Beauty and Sports lag behind. → Worth a review of whether the underperforming categories need more marketing support or a smaller footprint.

**4. Customers with a support ticket look different from those without one — but I'm not claiming why.** There's a real difference in average revenue between the two groups, but this dataset can't tell you if a bad support experience *causes* people to spend less, or if more active customers simply run into more issues in the first place. → Needs a proper before/after study, not a quick assumption.

**5. Not all support issues are equal.** "Defective Item" tickets have the worst satisfaction score in the whole dataset (1.30 out of 5) — even worse than categories that take longer to resolve. → Worth fixing this specific issue type first, rather than a blanket "resolve tickets faster" policy.

---

## Repository Structure

```text
Customer-Retention-Transaction-Analytics/
│
├── README.md
│
├── excel/
│   ├── Customer_Retention_Transaction_Analytics.xlsx
│   └── images/
│       ├── data-model-relationships.png
│       ├── pivot-table-summary.png
│       └── pivot-charts-overview.png
│
├── sql/
│   ├── Customer Retention & Transaction Analysis Updated.sql
│
├── python/
│   └── Customer_Retention_Transaction_Analytics.ipynb
│
├── powerbi/
│   ├── Customer Retention & Transaction Analysis.pbix
│   └── screenshots/
│       ├── executive-overview.png
│       ├── customer-analysis.png
│       ├── retention-rfm-analysis.png
│       ├── product-transaction-analysis.png
│       └── support-service-analysis.png
│
└── report/
    └── Final_Report.md
```

---

## Tools Used

| Stage | Tools & Techniques |
|---|---|
| Excel | Power Pivot, Data Model relationships, PivotTables, Pivot Charts, XLOOKUP, COUNTIF/COUNTIFS, SUMIF, MINIFS/MAXIFS, PERCENTILE.INC, RFM scoring |
| SQL | MySQL / MySQL Workbench, staging tables, `STR_TO_DATE()`, `NULLIF()`, joins, CTEs, window functions (`ROW_NUMBER`, `RANK`, `LAG`), foreign keys |
| Python | pandas, numpy, matplotlib, seaborn, mysql-connector-python, Jupyter Notebook, `getpass` |
| Power BI | Power Query, star-schema data modeling, DAX (`CALCULATE`, `FILTER`, `DISTINCTCOUNT`, `USERELATIONSHIP`, `DATEDIFF`, `SWITCH`), slicers, bookmarks |

---

## Limitations

- Only one product per transaction row — no multi-item baskets, so market-basket/cross-sell analysis wasn't possible
- `unit_price` never differs from the product's listed retail price — no historical pricing changes to analyze
- No marketing spend data by acquisition channel — I can see channel revenue, but not channel ROI
- Only about 2 years of history, which limits year-over-year comparison to a single cycle
- No account-type flag to directly confirm whether "Bulk Order" customers are genuinely wholesale buyers
- This dataset shows signs of being synthetically generated (perfectly clean referential integrity, no customers with zero purchases) — worth saying plainly rather than presenting it as messy real-world production data

---
Thanks for reading this far. Happy to walk through any part of this in more detail.

**Connect with me:** [LinkedIn](https://www.linkedin.com/in/saurabh-chaudhari-ds/)
