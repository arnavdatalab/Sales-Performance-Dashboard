-- ============================================ 
-- SALES PERFORMANCE — POSTGRESQL BUSINESS ANALYSIS
-- ============================================

-- =================
-- A. OVERALL KPIs
-- ================

-- A1. Total revenue, profit, orders, avg order value, overall margin %

SELECT
    COUNT(*) AS total_orders,
    SUM(total_sales) AS total_revenue,
    SUM(profit) AS total_profit,
    ROUND(AVG(total_sales), 2) AS avg_order_value,
    ROUND(100.0 * SUM(profit) / SUM(total_sales), 2) AS overall_margin_pct
FROM salesperformance;

-- A2. KPIs excluding cancelled orders (realized / "net" business)

SELECT
    COUNT(*) AS delivered_pending_orders,
    SUM(total_sales) AS realized_revenue,
    SUM(profit) AS realized_profit
FROM salesperformance
WHERE order_status <> 'Cancelled';


-- =========================================================
-- B. REGIONAL PERFORMANCE
-- =========================================================

-- B1. Revenue, profit, margin by region, ranked

SELECT
    region,
    COUNT(*) AS orders,
    SUM(total_sales) AS revenue,
    SUM(profit) AS profit,
    ROUND(100.0 * SUM(profit) / SUM(total_sales), 2) AS margin_pct,
    RANK() OVER (ORDER BY SUM(total_sales) DESC) AS revenue_rank
FROM salesperformance
GROUP BY region
ORDER BY revenue DESC;

-- B2. Each region's % contribution to total company revenue

SELECT
    region,
    SUM(total_sales) AS revenue,
    ROUND(100.0 * SUM(total_sales) / SUM(SUM(total_sales)) OVER (), 2) AS pct_of_total_revenue
FROM salesperformance
GROUP BY region
ORDER BY revenue DESC;

-- B3. Best-selling category within each region

SELECT region, category, revenue
FROM (
    SELECT
        region, category,
        SUM(total_sales) AS revenue,
        RANK() OVER (PARTITION BY region ORDER BY SUM(total_sales) DESC) AS rnk
    FROM salesperformance
    GROUP BY region, category
) t
WHERE rnk = 1
ORDER BY revenue DESC;


-- =========================================================
-- C. PRODUCT & CATEGORY PERFORMANCE
-- =========================================================

-- C1. Revenue & profit margin by category

SELECT
    category,
    SUM(total_sales) AS revenue,
    SUM(profit) AS profit,
    ROUND(100.0 * SUM(profit) / SUM(total_sales), 2) AS margin_pct
FROM salesperformance
GROUP BY category
ORDER BY revenue DESC;

-- C2. Top 5 products by revenue

SELECT product, category, SUM(total_sales) AS revenue, SUM(quantity) AS units_sold
FROM salesperformance
GROUP BY product, category
ORDER BY revenue DESC
LIMIT 5;

-- C3. Top 5 products by units sold

SELECT product, SUM(quantity) AS units_sold
FROM salesperformance
GROUP BY product
ORDER BY units_sold DESC
LIMIT 5;

-- C4. Top 3 products within EACH category by revenue (window function)

SELECT category, product, revenue, rnk
FROM (
    SELECT
        category, product,
        SUM(total_sales) AS revenue,
        DENSE_RANK() OVER (PARTITION BY category ORDER BY SUM(total_sales) DESC) AS rnk
    FROM salesperformance
    GROUP BY category, product
) t
WHERE rnk <= 3
ORDER BY category, rnk;

-- C5. Products with below-average profit margin (underperformers)

SELECT product, margin_pct
FROM (
    SELECT product, ROUND(100.0 * SUM(profit) / SUM(total_sales), 2) AS margin_pct
    FROM salesperformance
    GROUP BY product
) p
WHERE margin_pct < (SELECT ROUND(100.0 * SUM(profit) / SUM(total_sales), 2) FROM salesperformance)
ORDER BY margin_pct;


-- =========================================================
-- D. SALESPERSON PERFORMANCE
-- =========================================================

-- D1. Revenue, orders, margin by salesperson, ranked

SELECT
    sales_person,
    COUNT(*) AS orders,
    SUM(total_sales) AS revenue,
    ROUND(AVG(total_sales), 2) AS avg_order_value,
    ROUND(100.0 * SUM(profit) / SUM(total_sales), 2) AS margin_pct,
    RANK() OVER (ORDER BY SUM(total_sales) DESC) AS revenue_rank
FROM salesperformance
GROUP BY sales_person
ORDER BY revenue DESC;

-- D2. Salespeople performing above the company's average revenue-per-person (CTE)
WITH per_person AS (
    SELECT sales_person, SUM(total_sales) AS revenue
    FROM salesperformance
    GROUP BY sales_person
)
SELECT sales_person, revenue
FROM per_person
WHERE revenue > (SELECT AVG(revenue) FROM per_person)
ORDER BY revenue DESC;

-- D3. Cancellation rate by salesperson (a "quality of sale" metric)
SELECT
    sales_person,
    COUNT(*) FILTER (WHERE order_status = 'Cancelled') AS cancelled_orders,
    COUNT(*) AS total_orders,
    ROUND(100.0 * COUNT(*) FILTER (WHERE order_status = 'Cancelled') / COUNT(*), 2) AS cancel_rate_pct
FROM salesperformance
GROUP BY sales_person
ORDER BY cancel_rate_pct DESC;


-- =========================================================
-- E. TIME TREND ANALYSIS
-- =========================================================

-- E1. Monthly revenue & profit trend
SELECT
    DATE_TRUNC('month', order_date::date) AS month,
    SUM(total_sales) AS revenue,
    SUM(profit) AS profit
FROM salesperformance
GROUP BY 1
ORDER BY 1;

-- E2. Month-over-month revenue growth % (LAG window function)
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date::date) AS month, SUM(total_sales) AS revenue
    FROM salesperformance
    GROUP BY 1
)
SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS prev_month_revenue,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month)) / LAG(revenue) OVER (ORDER BY month), 2) AS mom_growth_pct
FROM monthly
ORDER BY month;

-- E3. Quarter-wise performance 

SELECT
    EXTRACT(QUARTER FROM TO_DATE(order_date, 'DD/MM/YYYY')) AS quarter,
    SUM(total_sales) AS revenue,
    SUM(profit) AS profit,
    COUNT(*) AS orders
FROM salesperformance
GROUP BY 1
ORDER BY 1;

-- E4. Running (cumulative) monthly revenue total across the year

WITH monthly AS (
    SELECT DATE_TRUNC('month', TO_DATE(order_date, 'DD/MM/YYYY'))::date AS month, SUM(total_sales) AS revenue
    FROM salesperformance
    GROUP BY 1
)
SELECT
    month,
    revenue,
    SUM(revenue) OVER (ORDER BY month) AS running_total_revenue
FROM monthly
ORDER BY month;

-- E5. 3-month moving average of revenue (smoothed trend line)

WITH monthly AS (
    SELECT 
        DATE_TRUNC('month', TO_DATE(order_date, 'DD/MM/YYYY'))::date AS month, 
        SUM(total_sales) AS revenue
    FROM salesperformance
    GROUP BY 1
)
SELECT
    month,
    revenue,
    ROUND(AVG(revenue) OVER (
        ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_3mo
FROM monthly
ORDER BY month;


-- =========================================================
-- F. CUSTOMER ANALYSIS
-- =========================================================

-- F1. Top 10 customers by total spend

SELECT customer_name, COUNT(*) AS orders, SUM(total_sales) AS total_spend
FROM salesperformance
GROUP BY customer_name
ORDER BY total_spend DESC
LIMIT 10;

-- F2. Repeat customers (more than one order)

SELECT customer_name, COUNT(*) AS orders, SUM(total_sales) AS total_spend
FROM salesperformance
GROUP BY customer_name
HAVING COUNT(*) > 1
ORDER BY orders DESC, total_spend DESC;


-- =========================================================
-- G. ORDER STATUS & PAYMENT MODE
-- =========================================================

-- G1. Order status breakdown + revenue at risk from cancellations

SELECT
    order_status,
    COUNT(*) AS orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_orders,
    SUM(total_sales) AS revenue
FROM salesperformance
GROUP BY order_status
ORDER BY orders DESC;

-- G2. Revenue by payment mode

SELECT payment_mode, COUNT(*) AS orders, SUM(total_sales) AS revenue
FROM salesperformance
GROUP BY payment_mode
ORDER BY revenue DESC;

-- G3. Most popular payment mode per region

SELECT region, payment_mode, orders
FROM (
    SELECT region, payment_mode, COUNT(*) AS orders,
           RANK() OVER (PARTITION BY region ORDER BY COUNT(*) DESC) AS rnk
    FROM salesperformance
    GROUP BY region, payment_mode
) t
WHERE rnk = 1;


-- =========================================================
-- H. ADVANCED ANALYSIS (Pareto, JOINs)
-- =========================================================

-- H1. Pareto (80/20) analysis — which products drive 80% of revenue

WITH product_revenue AS (
    SELECT product, SUM(total_sales) AS revenue
    FROM salesperformance
    GROUP BY product
),
ranked AS (
    SELECT
        product,
        revenue,
        SUM(revenue) OVER (ORDER BY revenue DESC) AS running_revenue,
        SUM(revenue) OVER () AS total_revenue
    FROM product_revenue
)
SELECT
    product,
    revenue,
    ROUND(100.0 * running_revenue / total_revenue, 2) AS cumulative_pct
FROM ranked
ORDER BY revenue DESC;

-- H2. High-volume, low-margin products (possible over-discounting)

SELECT
    product,
    SUM(quantity) AS units_sold,
    ROUND(100.0 * SUM(profit) / SUM(total_sales), 2) AS margin_pct
FROM salesperformance
GROUP BY product
HAVING SUM(quantity) > (SELECT AVG(q) FROM (SELECT SUM(quantity) q FROM salesperformance GROUP BY product) x)
ORDER BY margin_pct ASC
LIMIT 5;

-- H3. Actual vs target revenue by region & quarter 
SELECT
    s.region,
    s.quarter,
    s.actual_revenue,
    t.target_revenue,
    ROUND(100.0 * s.actual_revenue / t.target_revenue, 2) AS pct_of_target,
    CASE WHEN s.actual_revenue >= t.target_revenue
         THEN 'Target Met' ELSE 'Below Target' END AS status
FROM (
    SELECT 
        region, 
        EXTRACT(QUARTER FROM TO_DATE(order_date, 'DD/MM/YYYY'))::int AS quarter,
        SUM(total_sales) AS actual_revenue
    FROM salesperformance
    GROUP BY region, EXTRACT(QUARTER FROM TO_DATE(order_date, 'DD/MM/YYYY'))
) s
JOIN region_targets t
    ON s.region = t.region AND s.quarter = t.quarter
ORDER BY s.region, s.quarter;

