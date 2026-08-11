# Data Dictionary

This file explains what every column in every table actually means — in plain words, so anyone opening this repo (including a recruiter with no data background) can understand the data immediately.

---

## 1. Date Table (1,156 rows)
**In simple words:** One row = one calendar day. It exists so we can group and filter transactions by year, month, or day without recalculating dates every time.

| Column | Meaning |
|---|---|
| date_key | The calendar date itself — used to connect this table to Transactions and Customers_Support |
| year | The year that date falls in |
| quarter | Which quarter of the year (1–4) |
| month | The month number (1–12) |
| month_name | The month spelled out (January, February...) |
| day_of_month | The day number within the month (1–31) |
| day_of_week | The day spelled out (Monday, Tuesday...) |
| is_weekend | TRUE if that day is a Saturday or Sunday, FALSE otherwise |

---

## 2. Customers (7,000 rows)
**In simple words:** One row = one customer.

| Column | Meaning |
|---|---|
| customer_id | A unique ID given to each customer (like an ID card number) |
| signup_date | The date this customer created an account |
| location_city | Which city the customer lives in (Mumbai, Delhi, Bangalore, Chennai, Kolkata, or Pune) |
| acquisition_channel | How the customer found the business: Organic, Social, Paid Ads, or Referral |

---

## 3. Products (50 rows)
**In simple words:** One row = one product the store sells.

| Column | Meaning |
|---|---|
| product_id | A unique ID given to each product |
| product_name | The name of the product |
| product_category | What type of product it is: Electronics, Apparel, Home, Beauty, or Sports |
| unit_cost | What it costs the business to make/buy one unit of this product |
| retail_price | What the customer pays for one unit of this product |

---

## 4. Transactions (24,244 rows)
**In simple words:** One row = one product bought in one order (like one line on a receipt). This table tells you WHO bought, WHAT they bought, WHEN, and HOW MUCH it came to.

| Column | Meaning |
|---|---|
| transaction_id | A unique ID given to each order line |
| customer_id | Which customer placed this order (matches customer_id in Customers) |
| product_id | Which product was bought (matches product_id in Products) |
| transaction_date | The date the order was placed |
| transaction_time | The time of day the order was placed |
| quantity | How many units of that product were bought |
| unit_price | Price of ONE unit of that product at the time of sale |
| discount_amount | How much was knocked off the price for this order line |
| total_amount | The final amount charged = (unit_price × quantity) − discount_amount |
| payment_method | How the customer paid: UPI, Credit Card, Net Banking, or Cash |
| order_status | What happened to the order: Completed, Returned, Cancelled, or Refunded |

**Important thing to know:** Each row is only ONE product. If a customer bought 3 different products in a single order, that creates 3 separate transaction_id rows — there's no single "order" that groups multiple products together in this data.

---

## 5. Customers_Support (6,035 rows)
**In simple words:** One row = one support ticket a customer raised. Some tickets are about a specific order; others are general questions with no order attached.

| Column | Meaning |
|---|---|
| ticket_id | A unique ID given to each support ticket |
| customer_id | Which customer raised this ticket (matches customer_id in Customers) |
| transaction_id | Which order this ticket is about — **can be blank** if it's a general inquiry not tied to a specific order (matches transaction_id in Transactions) |
| ticket_date | The date the ticket was raised |
| issue_category | What the ticket is about: Late Delivery, Defective Item, Billing, or Poor Service |
| ticket_status | Where the ticket stands: Resolved, Pending, or Escalated |
| resolution_hours | How many hours it took to resolve the ticket — **blank if the ticket is still open** |
| satisfaction_score | Customer's rating of the resolution, 1 (worst) to 5 (best) — **blank if the ticket is still open** |

**Important thing to know:** `resolution_hours` and `satisfaction_score` being blank is normal, not an error — it simply means that ticket hasn't been closed yet.

---

## How the 5 tables connect to each other (the relationships)

Think of it like this — each arrow means "look this ID up in that other table":

```
Transactions        → Customers          (using customer_id)
Transactions        → Products           (using product_id)
Transactions        → Date Table         (using transaction_date ↔ date_key)
Customers_Support    → Customers          (using customer_id)
Customers_Support    → Date Table         (using ticket_date ↔ date_key)
```

**Simple way to remember it:** Facts you can count or add up (quantity, unit_price, total_amount, resolution_hours) live in Transactions and Customers_Support. Labels you use to group things (city, category, channel, payment method) live in the other 3 tables, and you connect them using the ID columns above.

**One extra connection worth knowing:** `Customers_Support.transaction_id` *can* be matched to `Transactions.transaction_id` to see which specific order a ticket relates to — but this isn't set up as a direct relationship in the data model, since both tables already connect through `Customers` and `Date Table`, and adding a third link would create a loop. Instead, this connection is made with a lookup formula where needed.
