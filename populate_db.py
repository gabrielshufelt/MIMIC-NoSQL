import os
import pandas as pd
from sqlalchemy import create_engine

MIMIC_PATH = os.path.expanduser("~/Downloads/mimic-iii")

# create connection to 'mimic' db
engine = create_engine("postgresql://postgres:postgres@localhost/mimic")

tables = ["PATIENTS", "ADMISSIONS", "ICUSTAYS", "NOTEEVENTS", "D_ICD_DIAGNOSES", "DIAGNOSES_ICD"]

for folder in tables:
    folder_path = os.path.join(MIMIC_PATH, folder)
    if not os.path.isdir(folder_path):
        continue

    csv_files = [f for f in os.listdir(folder_path) if (f.endswith("_random.csv") or f.endswith(".csv"))]
    if not csv_files:
        continue

    csv_path = os.path.join(folder_path, csv_files[0])
    print(f"Loading {csv_path} → table {folder}")

    df = pd.read_csv(csv_path, low_memory=False)
    df.to_sql(folder, engine, if_exists="append", index=False)

print("Done!")
