# Customer Retention & Transaction Analytics — My Project Report

Hi! This is my end-to-end Data Analyst project. I built the same analysis four times — in Excel, SQL, Python, and Power BI — and made sure every number matched across all four before calling it done. Below is a simple, honest summary of what I did, what I found, and what actually went wrong along the way.

---

## What This Project Is About

I had five tables of data for an online retail business: customers, products, a calendar table, transactions, and customer support tickets. My goal was to answer a simple business question:

> **How can this business understand its customers better, keep more of them, and make smarter decisions?**

The data covers **7,000 customers**, **24,244 transactions**, **50 products**, and **6,035 support tickets**, from January 2024 to December 2025.

---

## What I Did, Step by Step

### 1. Excel
I started by cleaning the data — fixing messy city names (like "mumbai" vs "Mumbai"), flagging blanks as "Unknown" instead of guessing, and flagging unusually large orders instead of deleting them. I built a proper data model (not just one big flat table), calculated all the main KPIs, built 9 PivotTables and 8 charts, and did a simple RFM (Recency, Frequency, Monetary) analysis.

### 2. SQL
I rebuilt the same 5 tables in a real MySQL database, with proper primary keys and relationships. Two tables gave me real trouble during import (more on that below), so I had to use staging tables to fix the data before loading it into the final tables. I wrote 30 core SQL queries covering everything from basic checks to window functions.

### 3. Python
I connected to my SQL database and rebuilt the same customer numbers a third time, using pandas. I also did some proper statistics — checking for outliers with the IQR method, and comparing that to my simpler "Bulk Order" business rule. I built the RFM scoring again here too, using a cleaner method than in Excel.

### 4. Power BI
Finally, I brought everything into a 5-page interactive dashboard: Executive Overview, Customer Analysis, Retention & RFM Analysis, Product & Transaction Analysis, and Support & Service Analysis. Every chart is different — nothing is repeated across pages.

---

## What I Found

**Revenue & Orders**
- Total Revenue: **₹4,17,33,140.75** (~₹41.73M)
- Revenue from Completed orders only: **₹3,31,33,954.30** (~₹33.13M)
- Average order value: ₹1,721.38
- 24,244 total transactions

**Customers**
- 7,000 total customers
- **55.8%** are repeat buyers (3,907), and 44.2% bought only once (3,093)
- **1,394 customers (19.9%)** haven't bought anything in 180+ days — that's a big chunk of "at-risk" revenue
- 4,042 are Active, 1,564 are At-Risk, 1,394 are Inactive

**Products & Orders**
- Electronics, Home, and Apparel bring in most of the revenue — Beauty and Sports lag behind
- 457 orders (1.89%) are "Bulk Orders" (quantity over 10 units) — small in number, but worth investigating separately
- UPI is the most-used and highest-revenue payment method
- Weekday sales (₹28.85M) are much higher than weekend sales (₹12.89M)

**Support Tickets**
- Average resolution time: 25.96 hours
- Average satisfaction score: 2.83 out of 5
- "Defective Item" tickets have the worst satisfaction score (1.30) — even worse than slow-resolution categories
- Customers who raised a ticket account for about 73.5% of ticket-linked revenue — but I'm not saying tickets *cause* this. It could just be that more active customers naturally run into more issues.

---

## Problems I Actually Faced (and Fixed)

I think this part matters more than a clean summary, so I'm keeping it honest:

- **My own counting mistake**: early on, I reported 452 "Bulk Orders" in my notes. When I rebuilt the same check in Python later, it came out to **457**. I went back and confirmed 457 is correct in Excel, SQL, and the raw data — my first count was just wrong, and I had to go fix it everywhere I'd already written it down.
- **Import errors in SQL**: my date column kept importing as "0 rows" with no error message. Turns out MySQL couldn't read the date format from my Excel export. I had to load it into a temporary "staging" table first, then convert the dates properly before moving it into the real table.
- **A logic bug in my dashboard**: one of my RFM tables in Power BI was showing "CUST-0001" as a "Total," instead of a real number. Turns out I'd accidentally set the field to show the "First" customer ID instead of "Count" of customers — an easy mistake to make, but it would've made my whole RFM section wrong if I hadn't caught it.
- **Inconsistent definitions**: at one point, my "Inactive Customer" count didn't match between two parts of my Excel file — one said 1,394, the other said 1,398. I found the exact formula difference causing it (a `>` vs `>=`) and fixed it so both agree now.

I'm including these because I think showing that I found and fixed my own mistakes is more useful than pretending everything worked perfectly the first time.

---

## What I'd Recommend to the Business

1. **Target the 1,394 inactive customers** with a win-back offer — they've already bought before, so they're cheaper to win back than finding brand-new customers.
2. **Look closer at "Defective Item" support tickets** — they have the lowest satisfaction score in the whole dataset, worse than categories that take longer to resolve.
3. **Check who's placing the 457 Bulk Orders** — they might be a different type of customer (maybe small businesses) who could be offered a different pricing plan.
4. **Don't assume support tickets are hurting sales** — the data shows a difference, but I don't have enough information to say it's the ticket's fault. This needs more digging before acting on it.

---

## What I Learned

- Cleaning data properly the first time saves a lot of pain later.
- Checking your own numbers in a second tool is genuinely useful — I caught two real mistakes doing this, not zero.
- A blank value isn't always a mistake — sometimes it just means "not applicable yet" (like an open support ticket with no resolution time).
- It's better to say "I don't know why this happened" honestly than to guess a reason that sounds good but isn't backed by the data.

---

## Tools I Used

Excel (Power Pivot, PivotTables) · MySQL (Workbench) · Python (pandas, matplotlib, seaborn) · Power BI (DAX, data modeling)

---

## Project Files

```
excel/     → Excel workbook + documentation
sql/       → Database script + 30 queries + explanations
python/    → Jupyter notebook
powerbi/   → Power BI dashboard file
report/    → Project Report
```

Thanks for reading — happy to explain any part of this in more detail.
