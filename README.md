<div align="center">

# 📊 Sales Performance Dashboard
### End-to-End Analytics Portfolio Project

*Analyzing 500 sales transactions (Jan–Dec 2025) across regions, product categories, payment modes, and a 10-person sales team — from raw data to boardroom-ready insight.*

[![Python](https://img.shields.io/badge/Python-Pandas%20%7C%20SQLAlchemy-3776AB?style=flat-square&logo=python&logoColor=white)](#)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Advanced%20SQL-4169E1?style=flat-square&logo=postgresql&logoColor=white)](#)
[![Power BI](https://img.shields.io/badge/Power%20BI-DAX%20%7C%20Data%20Modeling-F2C811?style=flat-square&logo=powerbi&logoColor=black)](#)
[![Excel](https://img.shields.io/badge/Excel-PivotTables-217346?style=flat-square&logo=microsoftexcel&logoColor=white)](#)
[![License](https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square)](#)

**[Dashboard Preview](#dashboard-preview) • [Key Insights](#key-business-insights) • [Tech Stack](#tech-stack--workflow) • [How to Run](#how-to-run-this-project) • [Contact](#connect-with-me)**

</div>

---

## 📌 Project Overview

Most sales dashboards stop at top-line revenue. This project goes several steps further, taking the **same dataset through three tools** to demonstrate range across the analytics stack:

| Goal | Approach |
|---|---|
| **Booked vs. Realised Revenue** | Separated pending/cancelled orders to quantify true business leakage |
| **Cross-Tool Validation** | Same dataset in Excel (exploration), Python + PostgreSQL (pipeline & querying), and Power BI (modeling & visualization) |
| **Stakeholder-Driven Design** | Every visual answers a specific question about profitability, fulfillment risk, or product concentration |

---

## Dashboard Preview

<div align="center">
<img src="sales_dashboard.png" width="800" alt="Sales Performance Dashboard Preview" />
</div>

---

## Key Business Insights

| Insight | Detail |
|---|---|
| 📦 **Revenue Concentration** | Laptops alone drive **~29%** of total revenue; 6 of 20 products generate **~80%** of revenue |
| 📈 **Seasonality** | Sales peaked in **October at ₹30.7L** — over 3× May's low of ₹8.1L |
| 💸 **Revenue Leakage** | **9.6%** of orders are cancelled, amounting to **₹22.7L** in lost revenue |
| 🌍 **Regional Bottleneck** | The **West region** accounts for over half of all cancelled-order revenue (₹11.6L) |
| 👥 **Team Consistency** | Every salesperson holds a profit margin between **21–25%**, reflecting uniform execution across the 10-person team |

---

## Tech Stack & Workflow

| Stage | Tool | What it did |
|---|---|---|
| 1️⃣ | **Python** (Pandas, SQLAlchemy) | Cleaned raw transactional data and built a direct ingestion pipeline into PostgreSQL |
| 2️⃣ | **Microsoft Excel** | Initial validation, sanity checks, exploratory PivotTables |
| 3️⃣ | **PostgreSQL** | 27 analytical scripts using window functions (`RANK`, `LAG`), CTEs, running totals, and joins |
| 4️⃣ | **Power BI Desktop / Power Query** | Data modeling, custom Date dimension table, interactive report layout |
| 5️⃣ | **DAX** | 15+ custom measures — profit margins, MoM growth, cancellation rates |

---

## 🧹 Data Preparation & Python Pipeline

Standardized column headers for SQL compatibility and automated ingestion into PostgreSQL:

```python
from sqlalchemy import create_engine

engine = create_engine("postgresql+psycopg2://postgres:12345@localhost:5432/retail_analytics")
df.columns = df.columns.str.lower().str.replace(' ', '_')
df.to_sql("salesperformance", engine, if_exists="replace", index=False)
```

---

## 🗄️ PostgreSQL Analysis Layer

Power BI handles the visual exploration; PostgreSQL powers the deep-dive quantitative analysis — **27 queries** in total.

**Sample: Month-over-Month Growth**

```sql
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::date AS month,
           SUM(total_sales) AS revenue
    FROM salesperformance
    GROUP BY 1
)
SELECT
    month,
    revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
        / LAG(revenue) OVER (ORDER BY month), 2
    ) AS mom_growth_pct
FROM monthly
ORDER BY month;
```

<details>
<summary>📄 Full script (all 27 queries)</summary>

See [`sql/queries.sql`](sql/queries.sql) for the complete set, covering revenue ranking, cohort-style breakdowns, cancellation analysis, and running totals.

</details>

---

## 📈 Power BI Modeling & Core DAX Measures

Built on a **star schema** with a custom Date dimension table for robust time intelligence.

```dax
Total Sales        = SUM(salesperformance[total_sales])
Total Profit       = SUM(salesperformance[profit])
Profit Margin %    = DIVIDE([Total Profit], [Total Sales])
Cancellation Rate  = DIVIDE(
                          CALCULATE([Total Orders], salesperformance[order_status] = "Cancelled"),
                          [Total Orders]
                      )
MoM Sales Growth % = DIVIDE(
                          [Total Sales] - CALCULATE([Total Sales], DATEADD('Date'[Date], -1, MONTH)),
                          CALCULATE([Total Sales], DATEADD('Date'[Date], -1, MONTH))
                      )
```

---

## 🗂️ Repository Structure

```
sales-performance-dashboard/
├── README.md                           ← Project documentation
├── SalesPerformanceDashboard.pbix      ← Power BI interactive dashboard file
├── analysis.ipynb                      ← Python EDA, cleaning, and DB loading script
├── sales_dashboard.png                 ← Overview screenshot of the Power BI dashboard
├── data/
│   └── Dashboard_SalesPerformance.xlsx ← Raw and explored source dataset
├── sql/
│   ├── schema.sql                      ← PostgreSQL table definitions & indexing
│   ├── queries.sql                     ← All 27 analytical SQL queries
│   └── sales_performance.csv           ← Cleaned CSV ready for SQL import
└── theme/
    └── Sales_Dashboard_Theme.json      ← Custom Power BI professional styling theme
```

---

## How to Run This Project

1. **Clone the repository**
   ```bash
   git clone https://github.com/Arnav051/-Sales-Performance-Dashboard-Power-BI.git
   ```
2. **Explore the Python pipeline** — open `analysis.ipynb` in Jupyter Notebook to review data cleaning and the database connection steps.
3. **Run the SQL layer** — load `sql/schema.sql` into PostgreSQL, import `sql/sales_performance.csv`, then run the queries in `sql/queries.sql`.
4. **View the dashboard** — open `SalesPerformanceDashboard.pbix` in Power BI Desktop to interact with filters, slicers, and DAX measures.

---

## Connect with Me

<div align="center">

[![LinkedIn](https://img.shields.io/badge/LinkedIn-krarnv-0A66C2?style=flat-square&logo=linkedin&logoColor=white)](https://linkedin.com/in/krarnv)
[![GitHub](https://img.shields.io/badge/GitHub-arnavdatalab-181717?style=flat-square&logo=github&logoColor=white)](https://github.com/arnavdatalab)
[![Email](https://img.shields.io/badge/Email-work.arnavkumar%40gmail.com-D14836?style=flat-square&logo=gmail&logoColor=white)](mailto:work.arnavkumar@gmail.com)

⭐ *If this project was useful or interesting, a star on the repo is appreciated!*

</div>
