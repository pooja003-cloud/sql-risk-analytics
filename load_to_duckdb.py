"""
Loads the 4 generated CSVs into a persistent DuckDB database file
(risk.duckdb). Run this after generate_data.py.
"""

import duckdb

con = duckdb.connect("risk.duckdb")

tables = ["borrowers", "loans", "payments", "delinquency_history"]

for t in tables:
    con.execute(f"DROP TABLE IF EXISTS {t}")
    con.execute(f"CREATE TABLE {t} AS SELECT * FROM read_csv_auto('{t}.csv')")
    count = con.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0]
    print(f"{t}: {count} rows loaded")

con.close()
print("\nDone. Data is in risk.duckdb")
