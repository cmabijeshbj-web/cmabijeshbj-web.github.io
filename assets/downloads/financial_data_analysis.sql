/* ============================================================================
   Financial Data Analysis Using SQL
   Demonstration / training project — synthetic invoice data (1,202 rows),
   24 months (Jan 2024 – Dec 2025) across 5 business units, 15 clients, 5 regions.
   Dialect: SQLite (uses strftime() for date formatting — swap for DATE_FORMAT() in MySQL
   or TO_CHAR() in PostgreSQL if porting). All 8 queries executed and verified with zero errors.
   ============================================================================ */

-- ----------------------------------------------------------------------------
-- 1. SCHEMA
-- ----------------------------------------------------------------------------
CREATE TABLE sales_transactions (
    InvoiceID       TEXT PRIMARY KEY,
    InvoiceDate     DATE NOT NULL,
    Client          TEXT NOT NULL,
    BusinessUnit    TEXT NOT NULL,
    Region          TEXT NOT NULL,
    Revenue         DECIMAL(12,2) NOT NULL,
    COGS            DECIMAL(12,2) NOT NULL,
    GrossMargin     DECIMAL(12,2) NOT NULL,
    PaymentStatus   TEXT NOT NULL CHECK (PaymentStatus IN ('Paid','Outstanding','Overdue'))
);

-- Load data: sales_transactions.csv (1,202 rows) via your tool's CSV import,
-- e.g. in SQLite:  .import sales_transactions.csv sales_transactions --csv --skip 1


-- ----------------------------------------------------------------------------
-- 2. MONTHLY REVENUE & MARGIN TREND
-- ----------------------------------------------------------------------------
SELECT
    strftime('%Y-%m', InvoiceDate)                AS Month,
    SUM(Revenue)                                   AS TotalRevenue,
    SUM(COGS)                                      AS TotalCOGS,
    SUM(GrossMargin)                                AS TotalGrossMargin,
    ROUND(100.0 * SUM(GrossMargin) / SUM(Revenue), 2) AS GrossMarginPct,
    COUNT(*)                                        AS InvoiceCount
FROM sales_transactions
GROUP BY Month
ORDER BY Month;


-- ----------------------------------------------------------------------------
-- 3. REVENUE & MARGIN BY BUSINESS UNIT (with month-over-month growth)
-- ----------------------------------------------------------------------------
WITH monthly_bu AS (
    SELECT
        BusinessUnit,
        strftime('%Y-%m', InvoiceDate) AS Month,
        SUM(Revenue) AS Revenue
    FROM sales_transactions
    GROUP BY BusinessUnit, Month
)
SELECT
    BusinessUnit,
    Month,
    Revenue,
    LAG(Revenue) OVER (PARTITION BY BusinessUnit ORDER BY Month) AS PriorMonthRevenue,
    ROUND(100.0 * (Revenue - LAG(Revenue) OVER (PARTITION BY BusinessUnit ORDER BY Month))
          / NULLIF(LAG(Revenue) OVER (PARTITION BY BusinessUnit ORDER BY Month), 0), 2) AS MoM_Growth_Pct
FROM monthly_bu
ORDER BY BusinessUnit, Month;


-- ----------------------------------------------------------------------------
-- 4. TOP 10 CLIENTS BY REVENUE (with rank and % of total)
-- ----------------------------------------------------------------------------
SELECT
    Client,
    SUM(Revenue) AS TotalRevenue,
    RANK() OVER (ORDER BY SUM(Revenue) DESC) AS RevenueRank,
    ROUND(100.0 * SUM(Revenue) / (SELECT SUM(Revenue) FROM sales_transactions), 2) AS PctOfTotalRevenue
FROM sales_transactions
GROUP BY Client
ORDER BY TotalRevenue DESC
LIMIT 10;


-- ----------------------------------------------------------------------------
-- 5. AR RISK: OVERDUE / OUTSTANDING EXPOSURE BY CLIENT
-- ----------------------------------------------------------------------------
SELECT
    Client,
    PaymentStatus,
    COUNT(*)      AS InvoiceCount,
    SUM(Revenue)  AS ExposureAmount
FROM sales_transactions
WHERE PaymentStatus IN ('Outstanding', 'Overdue')
GROUP BY Client, PaymentStatus
ORDER BY ExposureAmount DESC;


-- ----------------------------------------------------------------------------
-- 6. GROSS MARGIN % BY REGION AND BUSINESS UNIT (pivot-style)
-- ----------------------------------------------------------------------------
SELECT
    Region,
    BusinessUnit,
    SUM(Revenue)                                       AS Revenue,
    SUM(GrossMargin)                                     AS GrossMargin,
    ROUND(100.0 * SUM(GrossMargin) / SUM(Revenue), 2)   AS GrossMarginPct
FROM sales_transactions
GROUP BY Region, BusinessUnit
ORDER BY Region, GrossMarginPct DESC;


-- ----------------------------------------------------------------------------
-- 7. QUARTER-OVER-QUARTER KPI SUMMARY (Revenue, Margin, Avg Deal Size)
-- ----------------------------------------------------------------------------
SELECT
    (CASE WHEN CAST(strftime('%m', InvoiceDate) AS INTEGER) BETWEEN 1 AND 3 THEN 'Q1'
          WHEN CAST(strftime('%m', InvoiceDate) AS INTEGER) BETWEEN 4 AND 6 THEN 'Q2'
          WHEN CAST(strftime('%m', InvoiceDate) AS INTEGER) BETWEEN 7 AND 9 THEN 'Q3'
          ELSE 'Q4' END) || ' ' || strftime('%Y', InvoiceDate) AS Quarter,
    COUNT(*)                                           AS Deals,
    SUM(Revenue)                                        AS TotalRevenue,
    ROUND(AVG(Revenue), 2)                              AS AvgDealSize,
    ROUND(100.0 * SUM(GrossMargin) / SUM(Revenue), 2)  AS GrossMarginPct
FROM sales_transactions
GROUP BY Quarter
ORDER BY MIN(InvoiceDate);


-- ----------------------------------------------------------------------------
-- 8. CLIENTS WHOSE GROSS MARGIN % IS BELOW COMPANY AVERAGE (subquery + HAVING)
-- ----------------------------------------------------------------------------
SELECT
    Client,
    SUM(Revenue)                                       AS TotalRevenue,
    ROUND(100.0 * SUM(GrossMargin) / SUM(Revenue), 2)  AS ClientMarginPct
FROM sales_transactions
GROUP BY Client
HAVING ClientMarginPct < (
    SELECT 100.0 * SUM(GrossMargin) / SUM(Revenue) FROM sales_transactions
)
ORDER BY ClientMarginPct ASC;


-- ----------------------------------------------------------------------------
-- 9. RUNNING (CUMULATIVE) REVENUE TOTAL BY MONTH — for a YTD chart
-- ----------------------------------------------------------------------------
SELECT
    Month,
    MonthlyRevenue,
    SUM(MonthlyRevenue) OVER (ORDER BY Month) AS CumulativeRevenue
FROM (
    SELECT strftime('%Y-%m', InvoiceDate) AS Month, SUM(Revenue) AS MonthlyRevenue
    FROM sales_transactions
    GROUP BY Month
)
ORDER BY Month;
