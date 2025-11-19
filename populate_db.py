import os
from sqlalchemy import create_engine, text

MIMIC_PATH = os.path.expanduser("~/Downloads/mimic-iii")

# create connection to 'mimic' db
engine = create_engine("postgresql://postgres:postgres@localhost/mimic")

table_files = {
    "PATIENTS": "PATIENTS/PATIENTS_sorted.csv",
    "ADMISSIONS": "ADMISSIONS/ADMISSIONS_sorted.csv",
    "ICUSTAYS": "ICUSTAYS/ICUSTAYS_sorted.csv",
    "D_ICD_DIAGNOSES": "D_ICD_DIAGNOSES/D_ICD_DIAGNOSES.csv",
    "DIAGNOSES_ICD": "DIAGNOSES_ICD/DIAGNOSES_ICD_sorted.csv",
    "NOTEEVENTS": "NOTEEVENTS/NOTEEVENTS_sorted.csv"
}

for table, rel_path in table_files.items():
    path = os.path.join(MIMIC_PATH, rel_path)
    if not os.path.exists(path):
        print(f"Missing file for {table}: {path}")
        continue

    print(f"Loading {table} from: {path}")

    # COPY FROM is extremely fast
    with engine.connect() as conn:
        conn.execute(text(f"TRUNCATE {table} CASCADE;"))
        copy_sql = f"COPY {table} FROM STDIN WITH CSV HEADER;"

        raw = conn.connection
        with raw.cursor() as cur, open(path, "r") as f:
            cur.copy_expert(copy_sql, f)

print("Done!")
