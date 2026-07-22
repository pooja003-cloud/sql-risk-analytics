-- ============================================================
-- Query 5: Vintage Curves (Cumulative Default by Months-on-Book)
-- ============================================================
-- Business question: Controlling for loan age, which vintages
-- are performing worse than others? This is the standard way to
-- fairly compare cohorts of different observed lengths (a young
-- vintage hasn't had time to season -- see Query 2's caveat).
--
-- Step 1 (loan_base): one row per loan with its vintage month and,
--   if charged off, the MOB at which that happened (NULL otherwise).
-- Step 2 (vintage_mob_grid): cross join every vintage with every
--   possible MOB (1-36), producing the full grid needed to plot a
--   complete curve per vintage.
-- Step 3: for each (vintage, MOB) pair, count how many loans in
--   that vintage had ALREADY defaulted by that MOB or earlier
--   (cumulative), divided by total loans in the vintage.
--
-- Result: at MOB 24, the 2022-07 vintage (hit by a simulated macro
-- shock) shows ~15% cumulative default vs ~5.6% for 2021-07 at the
-- same age -- a controlled, apples-to-apples comparison.
-- ============================================================

WITH loan_base AS (
    SELECT
        loan_id,
        DATE_TRUNC('month', origination_date) AS vintage_month,
        CASE WHEN loan_status = 'Charged Off'
             THEN (SELECT MAX(months_on_book) FROM delinquency_history dh
                   WHERE dh.loan_id = loans.loan_id AND dh.delinquency_bucket = 'Charged Off')
             ELSE NULL
        END AS default_mob
    FROM loans
),
vintage_mob_grid AS (
    SELECT DISTINCT
        lb.vintage_month,
        gs.mob
    FROM loan_base lb
    CROSS JOIN (SELECT UNNEST(RANGE(1, 37)) AS mob) gs
),
vintage_totals AS (
    SELECT vintage_month, COUNT(*) AS total_loans
    FROM loan_base
    GROUP BY vintage_month
)
SELECT
    g.vintage_month,
    g.mob,
    vt.total_loans,
    SUM(CASE WHEN lb.default_mob IS NOT NULL AND lb.default_mob <= g.mob THEN 1 ELSE 0 END)
        AS cumulative_defaults,
    ROUND(
        100.0 * SUM(CASE WHEN lb.default_mob IS NOT NULL AND lb.default_mob <= g.mob THEN 1 ELSE 0 END)
        / vt.total_loans, 2
    ) AS cumulative_default_rate_pct
FROM vintage_mob_grid g
JOIN loan_base lb ON lb.vintage_month = g.vintage_month
JOIN vintage_totals vt ON vt.vintage_month = g.vintage_month
GROUP BY g.vintage_month, g.mob, vt.total_loans
ORDER BY g.vintage_month, g.mob;
