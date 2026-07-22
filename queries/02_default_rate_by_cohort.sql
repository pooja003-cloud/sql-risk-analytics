-- ============================================================
-- Query 2: Default Rate by Origination Cohort
-- ============================================================
-- Business question: What % of each vintage month's loans
-- ultimately charged off?
--
-- Uses conditional aggregation (SUM(CASE WHEN ...)) to count a
-- subset of rows (charged-off loans) in the same pass as counting
-- all rows, without a subquery.
--
-- Caveat: recent vintages (e.g. late 2023-2024) haven't had time
-- to season yet, so their default rate will look artificially low.
-- This is a known limitation of raw cohort default rate -- see
-- Query 5 (vintage curves) for the age-controlled version.
-- ============================================================

SELECT
    DATE_TRUNC('month', l.origination_date) AS vintage_month,
    COUNT(*)                                 AS num_loans,
    SUM(CASE WHEN l.loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS num_charged_off,
    ROUND(
        100.0 * SUM(CASE WHEN l.loan_status = 'Charged Off' THEN 1 ELSE 0 END)
        / COUNT(*), 2
    ) AS default_rate_pct
FROM loans l
GROUP BY DATE_TRUNC('month', l.origination_date)
ORDER BY vintage_month;
