# Risk Memo: Consumer Loan Portfolio Review

**Prepared using:** SQL analysis of loan-level and payment-level data (Jan 2021 - Jun 2024 originations)
**Purpose:** Summarize portfolio performance trends and flag a cohort requiring attention

---

## Executive Summary

Overall portfolio default performance has been broadly stable across
2021-2024, with one notable exception: **loans originated between
July and December 2022 are defaulting at roughly 2-3x the rate of
surrounding vintages**, even after controlling for how long each
cohort has had to season. This memo walks through the evidence and
recommends this window be reviewed for underwriting or macro
drivers.

## 1. Portfolio Overview

The book spans 3,000 loans originated monthly from January 2021
through June 2024, averaging ~70 loans and ~$1.5M in volume per
month, with average borrower FICO holding steady in the 670-693
range throughout — origination volume and credit quality do not
explain the pattern below on their own (see `sample_outputs/01_*`).

## 2. The Problem: Elevated Defaults in H2 2022

Raw monthly default rates are noisy at this cohort size (~50-90
loans/month), making single-month spikes hard to distinguish from
normal variation (`sample_outputs/02_*`). Smoothing with a rolling
3-month average clarifies the picture: the rolling bad rate climbs
to **10-14%** across July-December 2022, against a **5-7% baseline**
in the surrounding periods (`sample_outputs/03_*`).

## 3. Controlling for Loan Age: The Vintage Curve

A cohort observed for longer will naturally show a higher
*cumulative* default rate than a younger one, simply because it's
had more time to season — so raw comparisons across vintages can be
misleading. Building a full vintage curve (cumulative default % by
months-on-book, per vintage) removes this bias by comparing cohorts
at the *same age*.

**At 24 months on book:**
- 2021-07 vintage: 5.63% cumulative default
- 2022-07 vintage: 15.15% cumulative default

See `sample_outputs/vintage_curves_chart.png` — the shocked H2 2022
vintages (red) sit clearly and consistently above the baseline
vintages (blue) at every age, not just at one point in time. This
rules out "it just had more time to default" as an explanation.

## 4. Is This a Credit Quality Issue?

Segmenting all borrowers into FICO-based risk deciles confirms FICO
is a meaningfully predictive signal in this portfolio: default rate
falls from **16.27%** in the lowest-FICO decile to **~3-4%** in the
top decile (`sample_outputs/06_*`). This means underwriting
generally works as intended — which makes the H2 2022 spike more
notable, since it isn't explained by a broad drop in average FICO
during that period (avg FICO for H2 2022 originations stayed in the
same 670-690 range as every other period).

**Working hypothesis:** the H2 2022 elevation looks more consistent
with a macro or timing effect (e.g. a rate environment shift
affecting borrower repayment capacity after origination) than with
an underwriting quality lapse, since the borrower risk profile
(FICO) going in wasn't measurably different.

## 5. Recommendations

1. **Investigate H2 2022 originations specifically** — cross-check
   against any known underwriting policy changes, interest rate
   resets, or macro events in that window.
2. **Monitor the 2023-2024 vintages closely as they continue to
   season** — several are not yet old enough (24+ MOB) to fully
   confirm whether the shock was contained to H2 2022 or is part of
   a broader trend.
3. **Continue using vintage-curve (age-controlled) comparisons**
   rather than raw monthly default rates for cohort performance
   reviews — Section 2 vs Section 3 above shows how much the raw
   view can obscure or exaggerate a trend.

---

*Note: this analysis is based on a synthetic dataset built for SQL
skill demonstration purposes, with a deliberately injected default-
rate shock in the 2022-06 to 2022-12 vintage window to give the
analysis something real to detect. The queries, methodology, and
reasoning shown here mirror how this analysis would be performed on
real portfolio data.*
