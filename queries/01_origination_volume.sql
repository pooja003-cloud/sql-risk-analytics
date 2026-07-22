-- ============================================================
-- Query 1: Monthly Origination Volume & Average FICO
-- ============================================================
-- Business question: How much did we lend each month, and what
-- was the credit quality (FICO) of borrowers in that cohort?
--
-- Groups loans by origination month, counts them, sums dollar
-- volume, and averages the borrower's FICO score (joined in from
-- borrowers) for that cohort.
-- ============================================================

SELECT
    DATE_TRUNC('month', l.origination_date) AS origination_month,
    COUNT(*)                                 AS num_loans,
    SUM(l.loan_amount)                       AS total_origination_volume,
    ROUND(AVG(b.fico_score), 1)              AS avg_fico
FROM loans l
JOIN borrowers b ON l.borrower_id = b.borrower_id
GROUP BY DATE_TRUNC('month', l.origination_date)
ORDER BY origination_month;
