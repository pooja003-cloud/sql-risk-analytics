-- ============================================================
-- Query 6: Borrower Risk Deciles via NTILE()
-- ============================================================
-- Business question: If we bucket borrowers into 10 equal-sized
-- risk groups by FICO, does that segmentation actually separate
-- risk (i.e. does decile 1 default more than decile 10)?
--
-- NTILE(10) OVER (ORDER BY fico_score ASC) splits all borrowers
-- into 10 roughly-equal-sized buckets ordered by FICO ascending,
-- so decile 1 = worst FICO (highest risk), decile 10 = best FICO
-- (lowest risk). Validated by joining to loan outcomes and
-- checking each decile's actual default rate.
--
-- Result: default rate falls from ~16% in decile 1 to ~3-4% by
-- decile 8-10, confirming FICO is meaningfully predictive.
-- ============================================================

WITH borrower_deciles AS (
    SELECT
        b.borrower_id,
        b.fico_score,
        NTILE(10) OVER (ORDER BY b.fico_score ASC) AS risk_decile
    FROM borrowers b
),
borrower_loan_outcomes AS (
    SELECT
        bd.borrower_id,
        bd.fico_score,
        bd.risk_decile,
        l.loan_id,
        CASE WHEN l.loan_status = 'Charged Off' THEN 1 ELSE 0 END AS defaulted
    FROM borrower_deciles bd
    JOIN loans l ON l.borrower_id = bd.borrower_id
)
SELECT
    risk_decile,
    MIN(fico_score) AS min_fico_in_decile,
    MAX(fico_score) AS max_fico_in_decile,
    COUNT(DISTINCT borrower_id) AS num_borrowers,
    COUNT(*) AS num_loans,
    SUM(defaulted) AS num_defaults,
    ROUND(100.0 * SUM(defaulted) / COUNT(*), 2) AS default_rate_pct
FROM borrower_loan_outcomes
GROUP BY risk_decile
ORDER BY risk_decile;
