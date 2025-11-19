import os
import csv
import psycopg2
from psycopg2.errors import UniqueViolation

MIMIC_PATH = os.path.expanduser("~/Downloads/mimic-iii")

# ---- Local PostgreSQL connection ----
conn = psycopg2.connect(
    dbname="mimic",
    user="postgres",
    password="postgres",
    host="localhost",
)
cur = conn.cursor()

# Track valid foreign keys as we load tables
valid_subject_ids = set()
valid_hadm_ids = set()
valid_icustay_ids = set()
valid_icd9_codes = set()

def sanitize_value(val):
    if isinstance(val, int) or val is None:
        return val

    if isinstance(val, float):
        if val.is_integer():
            return int(val)
        return val  # keep real floats as floats

    if isinstance(val, str):
        stripped = val.strip()

        try:
            f = float(stripped)
            if f.is_integer():
                return int(f)
            return f
        except ValueError:
            return val

    return val

def load_and_filter(table, filename, filter_fn, process_fn):
    print(f"Loading {table} from {filename}")

    with open(filename, newline="") as f:
        reader = csv.DictReader(f)
        rows = []

        for row in reader:
            if filter_fn(row):
                process_fn(row)

                # Convert "" to None (NULL in PostgreSQL)
                cleaned = {k: (None if v == "" else v) for k, v in row.items()}
                rows.append(cleaned)

    if not rows:
        print(f"WARNING: No valid rows found for table {table}.")
        return

    cols = rows[0].keys()
    col_list = ",".join(cols)
    values_template = ",".join(["%s"] * len(cols))
    insert_sql = f"INSERT INTO {table} ({col_list}) VALUES ({values_template})"

    inserted = 0
    skipped = 0

    for row in rows:
        try:
            cleaned_values = [sanitize_value(v) for v in row.values()]
            cur.execute(insert_sql, cleaned_values)
            inserted += 1
        except UniqueViolation:
            conn.rollback()   # reset failed transaction
            skipped += 1      # skip the duplicate row

    conn.commit()
    print(f"Inserted {inserted} rows into {table} ({skipped} duplicates skipped)\n")

def patients_filter(row):
    return True

def patients_process(row):
    valid_subject_ids.add(int(row["SUBJECT_ID"]))

load_and_filter(
    "patients",
    f"{MIMIC_PATH}/PATIENTS/PATIENTS_sorted.csv",
    patients_filter,
    patients_process,
)

def admissions_filter(row):
    return int(row["SUBJECT_ID"]) in valid_subject_ids

def admissions_process(row):
    valid_hadm_ids.add(int(row["HADM_ID"]))

load_and_filter(
    "admissions",
    f"{MIMIC_PATH}/ADMISSIONS/ADMISSIONS_sorted.csv",
    admissions_filter,
    admissions_process,
)

def icustays_filter(row):
    return (
        int(row["SUBJECT_ID"]) in valid_subject_ids and
        int(row["HADM_ID"]) in valid_hadm_ids
    )

def icustays_process(row):
    valid_icustay_ids.add(int(row["ICUSTAY_ID"]))

load_and_filter(
    "icustays",
    f"{MIMIC_PATH}/ICUSTAYS/ICUSTAYS_sorted.csv",
    icustays_filter,
    icustays_process,
)

def d_icd_filter(row):
    return True

def d_icd_process(row):
    valid_icd9_codes.add(row["ICD9_CODE"])

load_and_filter(
    "d_icd_diagnoses",
    f"{MIMIC_PATH}/D_ICD_DIAGNOSES/D_ICD_DIAGNOSES.csv",
    d_icd_filter,
    d_icd_process,
)

def diagnoses_icd_filter(row):
    return (
        int(row["SUBJECT_ID"]) in valid_subject_ids and
        int(row["HADM_ID"]) in valid_hadm_ids and
        row["ICD9_CODE"] in valid_icd_codes
    )

def diagnoses_icd_process(row):
    pass

load_and_filter(
    "diagnoses_icd",
    f"{MIMIC_PATH}/DIAGNOSES_ICD/DIAGNOSES_ICD_sorted.csv",
    diagnoses_icd_filter,
    diagnoses_icd_process,
)

def noteevents_filter(row):
    return (
        int(row["SUBJECT_ID"]) in valid_subject_ids and
        int(row["HADM_ID"]) in valid_hadm_ids
    )

def noteevents_process(row):
    pass

load_and_filter(
    "noteevents",
    f"{MIMIC_PATH}/NOTEEVENTS/NOTEEVENTS_sorted.csv",
    noteevents_filter,
    noteevents_process,
)


cur.close()
conn.close()
print("Done!")