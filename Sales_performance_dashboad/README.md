📊 Sales Performance Dashboard — Power BI & SQL

An interactive Power BI dashboard, backed by a PostgreSQL analysis layer, examining 500 sales transactions across regions, products, payment modes, and a 10-person sales team — built to answer where revenue is concentrated, where it's leaking, and which levers actually move profit.

🖼️ Dashboard Preview

<img width="549" height="431" alt="{8EA63D8E-2CA8-4567-82C8-C345EAF99850}" src="https://github.com/user-attachments/assets/8e41a700-adf1-4504-891c-ebae5594c890" />


📌 Project Overview

•	Most "sales dashboards" stop at showing revenue. This one is built to go one step further — every visual maps to a specific business question (see below), and the KPI layer distinguishes booked revenue from realized revenue, since a meaningful share of orders in this dataset are still pending or cancelled.

•	The same dataset was analyzed end-to-end across three tools — Excel PivotTables for first-pass exploration, Power BI for the interactive dashboard, and PostgreSQL for deeper, query-driven analysis (window functions, CTEs, joins) — so the project demonstrates the full range from spreadsheet analysis to SQL.

🧹 Data Preparation
•	Before building the Power BI model, the raw data was first cleaned and explored in Excel using 
PivotTables — quick cross-tabs by region, product category, payment mode, and salesperson to validate totals, check for outliers, and confirm there were no blank or duplicate records. This exploratory pass shaped which fields and relationships mattered most once the dataset moved into Power BI for the full interactive build.

📁 Dataset

•	500 order-level records, January – December 2025

•	Fields: Order ID, Order Date, Customer Name, Product, Category, Region, Salesperson, Quantity, Unit Price, Total Sales, Cost Price, Profit, Payment Mode, Order Status

•	Clean source data — no missing values, no duplicate Order IDs

•	20 products across 4 categories, 4 regions, 10 salespeople, 50 customers

🛠️ Tools & Techniques

•	Microsoft Excel — initial data cleaning and exploratory PivotTables, used to sanity-check totals by region, category, payment mode, and salesperson before building the interactive model

•	Power BI Desktop — data modeling, DAX, report design

•	Power Query — data type validation and further cleaning

•	DAX — 15+ custom measures, plus a dedicated Date dimension table for time intelligence (month-over-month growth, proper calendar sorting)

•	PostgreSQL — 27 SQL queries covering KPI summaries, regional/product/salesperson performance, time-trend analysis, customer analysis, and Pareto analysis, using aggregations, window functions (RANK, DENSE_RANK, LAG, running totals), CTEs, subqueries, and joins

🗄️ SQL Analysis (PostgreSQL)

•	Beyond the dashboard, the dataset was loaded into a PostgreSQL table and queried directly to answer the same business questions at a more granular, ad-hoc level — the kind of analysis a dashboard's fixed visuals can't always surface on their own (e.g. cumulative revenue concentration, month-over-month growth as a precise %, actual-vs-target by region/quarter via a JOIN).

•	Full query set, schema, and data live in `/sql`. A couple of representative examples:

```sql
-- Month-over-month revenue growth %
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::date AS month, SUM(total_sales) AS revenue
    FROM sales GROUP BY 1
)
SELECT month, revenue,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
          / LAG(revenue) OVER (ORDER BY month), 2) AS mom_growth_pct
FROM monthly ORDER BY month;
```

```sql
-- Pareto analysis: which products drive 80% of revenue
WITH product_revenue AS (
    SELECT product, SUM(total_sales) AS revenue FROM sales GROUP BY product
)
SELECT product, revenue,
    ROUND(100.0 * SUM(revenue) OVER (ORDER BY revenue DESC)
          / SUM(revenue) OVER (), 2) AS cumulative_pct
FROM product_revenue ORDER BY revenue DESC;
```

🎯 Business Questions Answered

•	What's the total sales, profit, and overall margin — and how does it trend month to month?

•	Which region and which product category drive the most revenue and profit?

•	What are the top-selling products by revenue, and how concentrated is that revenue?

•	Which salesperson generates the most profit — not just the most sales?

•	What share of orders are Delivered vs. Pending vs. Cancelled, and how much revenue does that represent?

•	Which region has the highest cancellation rate, and what's the revenue impact?

•	Which payment mode is used most, and does it correlate with order cancellations?

•	Who are the top customers by revenue, and how much of total sales do they represent?

•	(SQL) Do a small number of products account for a disproportionate share of revenue — and exactly how much? (Pareto / 80-20 analysis)

•	(SQL) How does actual quarterly revenue compare against a target, by region? (JOIN across a targets table)

🔑 Key Insights

•	October peaked at ₹30.7L in sales — more than 3× May's ₹8.1L low, the clearest seasonal swing in the year.

•	Laptops alone drive ~29% of total revenue — a single product carrying nearly a third of the topline, a concentration risk worth flagging.

•	Just 6 of the 20 products account for ~80% of total revenue (Laptop, Bed, Sofa, Monitor, Office Desk, Office Chair) — a textbook Pareto split, confirmed via cumulative-distribution SQL analysis.

•	West region accounts for over half of all cancelled-order revenue (₹11.6L of ₹22.7L total) — disproportionate to its share of orders, and a clear fulfilment issue to investigate.

•	Every salesperson holds a margin between 21–25% — consistent performance across the team rather than one standout or one laggard.

•	Top 10 of 50 customers generate ~39% of total revenue — meaningful customer concentration.

•	9.6% of all orders are cancelled, representing ₹22.7L in lost revenue; another 23% of booked revenue is still pending.

📈 Dashboard Features

•	KPI cards: Total Sales, Total Profit, Profit Margin %, Total Orders, Avg Order Value

•	Monthly trend: Total Sales vs. Total Profit, Jan–Dec

•	Product-wise sales ranking (horizontal bar)

•	Regional sales breakdown (donut)

•	Salesperson performance table — sales, profit, and margin per rep, sorted and totaled

•	Interactive slicers: Region, Product, Payment Mode, Salesperson

•	One-line insight captions under each chart, so the dashboard reads as a story rather than a wall of numbers

🧮 Core DAX Measures

DAX

•	Total Sales        = SUM(Sales_Dashboard[Total Sales])

•	Total Profit        = SUM(Sales_Dashboard[Profit])

•	Profit Margin %     = DIVIDE([Total Profit], [Total Sales])

•	Total Orders        = DISTINCTCOUNT(Sales_Dashboard[Order ID])

•	Avg Order Value     = DIVIDE([Total Sales], [Total Orders])

•	Cancellation Rate % = DIVIDE(CALCULATE([Total Orders], Sales_Dashboard[Order Status]="Cancelled")[Total Orders])

•	MoM Sales Growth %  = DIVIDE([Total Sales] - CALCULATE([Total Sales],DATEADD('Date'[Date], -1, MONTH)),CALCULATE([Total Sales], DATEADD('Date'[Date], -1, MONTH)))

🗂️ Repository Structure

sales-performance-dashboard-powerbi/

├── README.md

├── SalesPerformanceDashboard.pbix       ← the Power BI file

├── data/

│   └── Dashboard_SalesPerformance.xlsx ← source dataset (includes a Pivot sheet from the Excel cleaning/exploration step)

├── sql/

│   ├── schema.sql        ← table + index definitions

│   ├── queries.sql       ← all 27 PostgreSQL analysis queries

│   └── sales_performance.csv ← cleaned data, ready to load

├── theme/

│   └── Sales_Dashboard_Professional_Theme.json

└── screenshots/

    └── dashboard-overview.png

🚀 How to Use

•	Download or clone this repository.

•	Open SalesPerformanceDashboard.pbix in Power BI Desktop (free to install from Microsoft).

•	Optional — apply the included theme yourself: View tab → Themes → Browse for themes → select theme/Sales_Dashboard_Professional_Theme.json.

•	Use the slicers on the left to filter by Region, Product, Payment Mode, or Salesperson.

•	To explore the SQL layer: load `sql/schema.sql` into PostgreSQL, import `sql/sales_performance.csv` into the resulting `sales` table, then run `sql/queries.sql`.

🧠 Skills Demonstrated

•	Data cleaning and exploratory analysis with Excel PivotTables

•	Data cleaning and validation in Power Query

•	Data modelling with a proper Date dimension and relationships

•	DAX measures, including time intelligence

•	SQL querying and analysis in PostgreSQL — aggregations, window functions (RANK, DENSE_RANK, LAG), CTEs, subqueries, and joins

•	Dashboard UX/UI: KPI hierarchy, consistent colour theory, alignment, and interaction design

•	Translating raw transactional data into business questions and decision-ready insights, across spreadsheet, BI, and SQL tooling

📬 Connect

•	LinkedIn : www.linkedin.com/in/krarnv

•	Gmail : karnav513@gmail.com

📄 License

•	This project uses a synthetic/practice dataset and is shared for portfolio purposes. Feel free to fork and adapt.
