import numpy as np
import pandas as pd
from datetime import date
import random

np.random.seed(42)
random.seed(42)

N_BORROWERS = 2000
N_LOANS = 3000
VINTAGES = pd.date_range("2021-01-01", "2024-06-01", freq="MS")
TODAY = date(2026, 7, 1)

# --- Borrowers ---
borrowers = pd.DataFrame({
    "borrower_id": range(1, N_BORROWERS + 1),
    "fico_score": np.clip(np.random.normal(680, 60, N_BORROWERS).astype(int), 300, 850),
    "annual_income": np.round(np.random.lognormal(10.8, 0.4, N_BORROWERS), 2),
    "state": np.random.choice(["CA","TX","NY","FL","IL","OH","GA","NC","MI","PA"], N_BORROWERS),
    "dti_ratio": np.round(np.clip(np.random.normal(28, 10, N_BORROWERS), 5, 60), 2),
})

def vintage_shock(origination_date):
    # Simulated macro shock: loans originated in this window default ~1.8x more
    if date(2022, 6, 1) <= origination_date <= date(2022, 12, 1):
        return 1.8
    return 1.0

def default_probability(fico, shock):
    # Worse FICO -> higher lifetime default probability
    base = 0.03 + max(0, (700 - fico)) * 0.0009
    return min(base * shock, 0.65)

# --- Loans: decide default outcome directly, then when it happens ---
loan_rows = []
for loan_id in range(1, N_LOANS + 1):
    borrower = borrowers.sample(1).iloc[0]
    origination = random.choice(VINTAGES).date()
    term = random.choice([36, 60])
    amount = round(np.random.uniform(3000, 40000), 2)
    rate = round(np.random.uniform(6, 24), 3)
    shock = vintage_shock(origination)
    p_default = default_probability(borrower.fico_score, shock)
    will_default = np.random.random() < p_default

    months_elapsed = (TODAY.year - origination.year) * 12 + (TODAY.month - origination.month)
    max_mob = min(term, months_elapsed)  # can't season past today or past term

    default_mob = None
    if will_default and max_mob >= 4:
        # Defaults cluster mid-life: peak around month 8-14, roughly triangular
        candidate = int(np.random.triangular(4, 10, max(max_mob, 11)))
        if candidate <= max_mob:
            default_mob = candidate

    loan_rows.append({
        "loan_id": loan_id, "borrower_id": borrower.borrower_id,
        "origination_date": origination, "loan_amount": amount,
        "term_months": term, "interest_rate": rate,
        "_max_mob": max_mob, "_default_mob": default_mob,
    })
loans = pd.DataFrame(loan_rows)

# --- Payments + delinquency snapshots, built from the default decision ---
payment_rows, delinq_rows = [], []
payment_id = snapshot_id = 1

for _, loan in loans.iterrows():
    default_mob = loan._default_mob
    max_mob = loan._max_mob
    sched = round(loan.loan_amount / loan.term_months, 2)

    for mob in range(1, max_mob + 1):
        pay_date = (pd.Timestamp(loan.origination_date) + pd.DateOffset(months=mob)).date()

        if pd.isna(default_mob) or mob < default_mob - 2:
            dpd, paid, bucket = 0, sched, "Current"
        elif pd.notna(default_mob) and default_mob - 2 <= mob < default_mob:
            # roll through delinquency in the 2 months before charge-off
            dpd = 30 if mob == default_mob - 2 else 60
            paid, bucket = 0, f"{dpd}DPD"
        elif pd.notna(default_mob) and mob == default_mob:
            dpd, paid, bucket = 120, 0, "Charged Off"
        else:
            # already charged off in a prior month -> loan stops appearing
            break

        payment_rows.append({
            "payment_id": payment_id, "loan_id": loan.loan_id, "payment_date": pay_date,
            "scheduled_amount": sched, "amount_paid": paid, "days_past_due": dpd,
        })
        payment_id += 1
        delinq_rows.append({
            "snapshot_id": snapshot_id, "loan_id": loan.loan_id, "snapshot_date": pay_date,
            "months_on_book": mob, "delinquency_bucket": bucket,
        })
        snapshot_id += 1

    if pd.notna(default_mob):
        loans.loc[loans.loan_id == loan.loan_id, "loan_status"] = "Charged Off"
    elif max_mob >= loan.term_months:
        loans.loc[loans.loan_id == loan.loan_id, "loan_status"] = "Fully Paid"
    else:
        loans.loc[loans.loan_id == loan.loan_id, "loan_status"] = "Current"

loans = loans.drop(columns=["_max_mob", "_default_mob"])
payments = pd.DataFrame(payment_rows)
delinquency_history = pd.DataFrame(delinq_rows)

borrowers.to_csv("borrowers.csv", index=False)
loans.to_csv("loans.csv", index=False)
payments.to_csv("payments.csv", index=False)
delinquency_history.to_csv("delinquency_history.csv", index=False)
print("Done:", len(borrowers), "borrowers |", len(loans), "loans |",
      len(payments), "payments |", len(delinquency_history), "snapshots")
print("Status breakdown:\n", loans.loan_status.value_counts())
