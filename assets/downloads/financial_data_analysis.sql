-- ============================================================================
-- Financial Data Analysis Using SQL  |  Bijesh BJ, CMA (USA)
-- Illustrative company: Meridian Technology Services (synthetic data)
-- Dialect: SQLite 3 (window functions, julianday). Tested: all 14 queries run cleanly.
--
-- TABLES
--   sales_transactions(invoice_id, client_id, client_name, business_unit, region,
--                      invoice_date, due_date, paid_date, invoice_amount, direct_cost,
--                      payment_terms_days, fiscal_year)      -- 1,785 invoices, FY24-FY26
--   bu_monthly_pl(FY, Quarter, Month, BU, Region, Revenue_Budget, Revenue_Actual,
--                 DirectCost_Budget, DirectCost_Actual, Opex_Budget, Opex_Actual, Headcount) -- 1,080 rows
-- Fiscal year = April-March. Receivables are measured as at 31-Mar-2026.
-- Open invoice = paid_date IS NULL.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Q01. Data reconciliation: invoices vs FP&A pack
-- Business question: Does the billing register tie to the revenue in the FP&A workbook? (control query)
-- Result insight   : Difference is 0 across all years - the register ties exactly to the FP&A pack.
-- ---------------------------------------------------------------------------
SELECT s.fiscal_year,
       SUM(s.invoice_amount)                      AS billed_revenue,
       (SELECT SUM(p.Revenue_Actual) FROM bu_monthly_pl p WHERE p.FY = s.fiscal_year) AS fpa_revenue,
       SUM(s.invoice_amount) - (SELECT SUM(p.Revenue_Actual) FROM bu_monthly_pl p WHERE p.FY = s.fiscal_year) AS difference
FROM sales_transactions s
GROUP BY s.fiscal_year ORDER BY s.fiscal_year;

-- ---------------------------------------------------------------------------
-- Q02. Revenue, gross margin and YoY growth by fiscal year
-- Business question: How fast are we growing and is margin holding?
-- Result insight   : Revenue grew 7.4% in FY26 while gross margin moved from 39.5% to 38.5%.
-- ---------------------------------------------------------------------------
WITH fy AS (
  SELECT fiscal_year, SUM(invoice_amount) AS revenue, SUM(direct_cost) AS direct_cost, COUNT(*) AS invoices
  FROM sales_transactions GROUP BY fiscal_year)
SELECT fiscal_year, revenue, direct_cost, revenue-direct_cost AS gross_profit,
       ROUND(100.0*(revenue-direct_cost)/revenue,1) AS gross_margin_pct, invoices,
       ROUND(100.0*(revenue*1.0/LAG(revenue) OVER (ORDER BY fiscal_year)-1),1) AS yoy_growth_pct
FROM fy ORDER BY fiscal_year;

-- ---------------------------------------------------------------------------
-- Q03. Monthly revenue with 3-month moving average
-- Business question: What is the underlying trend after smoothing seasonality?
-- Result insight   : Latest 3-month moving average is $14.7M per month; peak month was 2026-03.
-- ---------------------------------------------------------------------------
WITH m AS (
  SELECT substr(invoice_date,1,7) AS month, SUM(invoice_amount) AS revenue
  FROM sales_transactions GROUP BY 1)
SELECT month, revenue,
       ROUND(AVG(revenue) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),0) AS moving_avg_3m,
       ROUND(100.0*(revenue*1.0/LAG(revenue,12) OVER (ORDER BY month)-1),1) AS yoy_pct
FROM m ORDER BY month;

-- ---------------------------------------------------------------------------
-- Q04. Business-unit profitability
-- Business question: Which business units earn the best gross margin and how has it moved?
-- Result insight   : Highest FY26 gross margin: Healthcare & Life Sciences at 44.6%; lowest: Manufacturing & Logistics at 29.3%.
-- ---------------------------------------------------------------------------
SELECT business_unit, fiscal_year,
       SUM(invoice_amount) AS revenue,
       SUM(invoice_amount-direct_cost) AS gross_profit,
       ROUND(100.0*SUM(invoice_amount-direct_cost)/SUM(invoice_amount),1) AS gross_margin_pct,
       ROUND(100.0*SUM(invoice_amount)/SUM(SUM(invoice_amount)) OVER (PARTITION BY fiscal_year),1) AS revenue_mix_pct
FROM sales_transactions
GROUP BY business_unit, fiscal_year ORDER BY fiscal_year DESC, gross_margin_pct DESC;

-- ---------------------------------------------------------------------------
-- Q05. Regional ranking (current year)
-- Business question: Which regions contribute most revenue and margin in FY26?
-- Result insight   : UAE is the largest region ($41.5M); lowest margin region: KSA (36.4%).
-- ---------------------------------------------------------------------------
SELECT RANK() OVER (ORDER BY SUM(invoice_amount) DESC) AS revenue_rank,
       region, SUM(invoice_amount) AS revenue,
       ROUND(100.0*SUM(invoice_amount-direct_cost)/SUM(invoice_amount),1) AS gross_margin_pct,
       COUNT(DISTINCT client_id) AS active_clients
FROM sales_transactions WHERE fiscal_year='FY26'
GROUP BY region ORDER BY revenue_rank;

-- ---------------------------------------------------------------------------
-- Q06. Client concentration - top 10
-- Business question: How dependent are we on a few clients?
-- Result insight   : Top client = 4.6% of FY26 revenue; top 10 = 35.0%.
-- ---------------------------------------------------------------------------
WITH c AS (
  SELECT client_name, business_unit, region, SUM(invoice_amount) AS revenue
  FROM sales_transactions WHERE fiscal_year='FY26' GROUP BY client_id)
SELECT ROW_NUMBER() OVER (ORDER BY revenue DESC) AS rank, client_name, business_unit, region, revenue,
       ROUND(100.0*revenue/SUM(revenue) OVER (),1) AS share_pct,
       ROUND(100.0*SUM(revenue) OVER (ORDER BY revenue DESC ROWS UNBOUNDED PRECEDING)/SUM(revenue) OVER (),1) AS cumulative_share_pct
FROM c ORDER BY revenue DESC LIMIT 10;

-- ---------------------------------------------------------------------------
-- Q07. Pareto: revenue by client decile
-- Business question: Do 20% of clients drive 80% of revenue?
-- Result insight   : The top quintile of clients generates 44.5% of FY26 revenue.
-- ---------------------------------------------------------------------------
WITH c AS (
  SELECT client_id, SUM(invoice_amount) AS revenue FROM sales_transactions WHERE fiscal_year='FY26' GROUP BY client_id),
t AS (SELECT client_id, revenue, NTILE(5) OVER (ORDER BY revenue DESC) AS quintile FROM c)
SELECT quintile, COUNT(*) AS clients, SUM(revenue) AS revenue,
       ROUND(100.0*SUM(revenue)/(SELECT SUM(revenue) FROM c),1) AS share_pct
FROM t GROUP BY quintile ORDER BY quintile;

-- ---------------------------------------------------------------------------
-- Q08. Accounts-receivable ageing at 31-Mar-2026
-- Business question: How much cash is outstanding and how overdue is it?
-- Result insight   : Open receivables total $26.4M; 6.9% is more than 60 days overdue.
-- ---------------------------------------------------------------------------
SELECT CASE WHEN julianday('2026-03-31')-julianday(due_date) <= 0  THEN '1. Not yet due'
            WHEN julianday('2026-03-31')-julianday(due_date) <= 30 THEN '2. 1-30 days overdue'
            WHEN julianday('2026-03-31')-julianday(due_date) <= 60 THEN '3. 31-60 days overdue'
            WHEN julianday('2026-03-31')-julianday(due_date) <= 90 THEN '4. 61-90 days overdue'
            ELSE '5. Over 90 days overdue' END AS ageing_bucket,
       COUNT(*) AS open_invoices, SUM(invoice_amount) AS open_amount,
       ROUND(100.0*SUM(invoice_amount)/SUM(SUM(invoice_amount)) OVER (),1) AS pct_of_ar
FROM sales_transactions WHERE paid_date IS NULL
GROUP BY ageing_bucket ORDER BY ageing_bucket;

-- ---------------------------------------------------------------------------
-- Q09. DSO and collection performance by fiscal year
-- Business question: How quickly do we collect, and how much is paid on time?
-- Result insight   : Value-weighted days-to-collect is 47.2 days in FY26; 36.5% of paid invoices cleared by due date.
-- ---------------------------------------------------------------------------
SELECT fiscal_year,
       COUNT(*) AS paid_invoices,
       ROUND(AVG(julianday(paid_date)-julianday(invoice_date)),1) AS avg_days_to_collect,
       ROUND(AVG(julianday(paid_date)-julianday(due_date)),1)     AS avg_days_past_due,
       ROUND(100.0*SUM(CASE WHEN paid_date<=due_date THEN 1 ELSE 0 END)/COUNT(*),1) AS paid_on_time_pct,
       ROUND(SUM(invoice_amount*(julianday(paid_date)-julianday(invoice_date)))/SUM(invoice_amount),1) AS value_weighted_dso
FROM sales_transactions WHERE paid_date IS NOT NULL
GROUP BY fiscal_year ORDER BY fiscal_year;

-- ---------------------------------------------------------------------------
-- Q10. Slow-paying clients
-- Business question: Which clients consistently pay late?
-- Result insight   : Slowest payer averages 44.8 days past due (Delta Capital Bank).
-- ---------------------------------------------------------------------------
SELECT client_name, business_unit, region, payment_terms_days, COUNT(*) AS paid_invoices,
       ROUND(AVG(julianday(paid_date)-julianday(due_date)),1) AS avg_days_late,
       ROUND(100.0*SUM(CASE WHEN paid_date>due_date THEN 1 ELSE 0 END)/COUNT(*),0) AS pct_paid_late,
       SUM(invoice_amount) AS billed
FROM sales_transactions WHERE paid_date IS NOT NULL
GROUP BY client_id HAVING COUNT(*) >= 8
ORDER BY avg_days_late DESC LIMIT 10;

-- ---------------------------------------------------------------------------
-- Q11. High-risk open exposure
-- Business question: Which clients carry the largest overdue balances?
-- Result insight   : Top 10 overdue exposures total $4.1M (15.6% of open AR).
-- ---------------------------------------------------------------------------
SELECT client_name, business_unit, region, COUNT(*) AS open_invoices,
       SUM(invoice_amount) AS open_amount,
       MAX(CAST(julianday('2026-03-31')-julianday(due_date) AS INTEGER)) AS max_days_overdue,
       ROUND(100.0*SUM(invoice_amount)/(SELECT SUM(invoice_amount) FROM sales_transactions WHERE paid_date IS NULL),1) AS pct_of_total_ar
FROM sales_transactions WHERE paid_date IS NULL AND julianday('2026-03-31')-julianday(due_date) > 0
GROUP BY client_id ORDER BY open_amount DESC LIMIT 10;

-- ---------------------------------------------------------------------------
-- Q12. Budget vs actual by business unit
-- Business question: Where are we missing budget on revenue and operating income?
-- Result insight   : Biggest operating-income miss: Manufacturing & Logistics (-23.6% vs budget).
-- ---------------------------------------------------------------------------
SELECT BU AS business_unit, FY AS fiscal_year,
       SUM(Revenue_Actual) AS revenue_actual, SUM(Revenue_Budget) AS revenue_budget,
       ROUND(100.0*(SUM(Revenue_Actual)-SUM(Revenue_Budget))/SUM(Revenue_Budget),1) AS revenue_var_pct,
       SUM(Revenue_Actual-DirectCost_Actual-Opex_Actual) AS op_income_actual,
       SUM(Revenue_Budget-DirectCost_Budget-Opex_Budget) AS op_income_budget,
       ROUND(100.0*(SUM(Revenue_Actual-DirectCost_Actual-Opex_Actual)*1.0/SUM(Revenue_Budget-DirectCost_Budget-Opex_Budget)-1),1) AS op_income_var_pct
FROM bu_monthly_pl WHERE FY='FY26' GROUP BY BU, FY ORDER BY op_income_var_pct;

-- ---------------------------------------------------------------------------
-- Q13. Weakest BU-region cells (margin)
-- Business question: Which BU/region combinations are dragging operating margin?
-- Result insight   : Largest margin gap vs budget: Manufacturing & Logistics in KSA (-6.2 pp).
-- ---------------------------------------------------------------------------
SELECT BU AS business_unit, Region AS region,
       SUM(Revenue_Actual) AS revenue,
       ROUND(100.0*SUM(Revenue_Actual-DirectCost_Actual-Opex_Actual)/SUM(Revenue_Actual),1) AS op_margin_pct,
       ROUND(100.0*SUM(Revenue_Budget-DirectCost_Budget-Opex_Budget)/SUM(Revenue_Budget),1) AS budget_margin_pct,
       ROUND(100.0*SUM(Revenue_Actual-DirectCost_Actual-Opex_Actual)/SUM(Revenue_Actual) - 100.0*SUM(Revenue_Budget-DirectCost_Budget-Opex_Budget)/SUM(Revenue_Budget),1) AS margin_gap_pp
FROM bu_monthly_pl WHERE FY='FY26' GROUP BY BU, Region ORDER BY margin_gap_pp LIMIT 8;

-- ---------------------------------------------------------------------------
-- Q14. Invoice-size distribution
-- Business question: Is revenue driven by a few very large invoices?
-- Result insight   : The largest band ('$250K-$500K') carries 40.5% of revenue.
-- ---------------------------------------------------------------------------
SELECT CASE WHEN invoice_amount < 100000 THEN 'a. Under $100K'
            WHEN invoice_amount < 250000 THEN 'b. $100K-$250K'
            WHEN invoice_amount < 500000 THEN 'c. $250K-$500K'
            WHEN invoice_amount < 1000000 THEN 'd. $500K-$1M'
            ELSE 'e. Over $1M' END AS size_band,
       COUNT(*) AS invoices, SUM(invoice_amount) AS revenue,
       ROUND(100.0*SUM(invoice_amount)/SUM(SUM(invoice_amount)) OVER (),1) AS pct_of_revenue,
       ROUND(AVG(julianday(paid_date)-julianday(invoice_date)),1) AS avg_days_to_collect
FROM sales_transactions GROUP BY size_band ORDER BY size_band;
