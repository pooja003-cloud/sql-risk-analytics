-- ============================================================
-- Query 3: Rolling 3-Month Average Bad Rate (Window Function)
-- ============================================================
-- Business question: What's the smoothed trend in default rate
-- over time, controlling for month-to-month noise?
--
-- Step 1 (CTE monthly_rates): compute each month's own bad rate.
-- Step 2: AVG() OVER (... ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
--   averages the current row and the 2 rows before it -- a trailing
--   3-month rolling average. The first two rows in the series will
--   average over fewer than 3 months since no prior data exists.
-- ============================================================

WITH monthly_rates AS (
    SELECT
        DATE_TRUNC('month', l.origination_date) AS vintage_month,
        COUNT(*) AS num_loans,
        SUM(CASE WHEN l.loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS num_charged_off,
        100.0 * SUM(CASE WHEN l.loan_status = 'Charged Off' THEN 1 ELSE 0 END)
            / COUNT(*) AS bad_rate_pct
    FROM loans l
    GROUP BY DATE_TRUNC('month', l.origination_date)
)
SELECT
    vintage_month,
    num_loans,
    ROUND(bad_rate_pct, 2) AS bad_rate_pct,
    ROUND(
        AVG(bad_rate_pct) OVER (
            ORDER BY vintage_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    ) AS rolling_3mo_avg_bad_rate_pct
FROM monthly_rates
ORDER BY vintage_month;
