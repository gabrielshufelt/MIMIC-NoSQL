import os
import csv
import psycopg2

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
valid_icd_codes = set()

def load_and_filter(table, filename, filter_fn, process_fn):
    print(f"Loading {table} from {filename}")

    with open(filename, newline="") as f:
        reader = csv.DictReader(f)
        rows = []

        for row in reader:
            if filter_fn(row):
                process_fn(row)

                # Convert "" to None (NULL in PostgreSQL)
                cleaned = {}
                for k, v in row.items():
                    cleaned[k] = None if v == "" else v

                rows.append(cleaned)

    if not rows:
        print(f"WARNING: No valid rows found for table {table}.")
        return

    cols = rows[0].keys()
    col_list = ",".join(cols)
    values_template = ",".join(["%s"] * len(cols))
    insert_sql = f"INSERT INTO {table} ({col_list}) VALUES ({values_template})"

    for row in rows:
        cur.execute(insert_sql, list(row.values()))

    conn.commit()
    print(f"Loaded {len(rows)} rows into {table}\n")

def patients_filter(row):
    return True

def patients_process(row):
    valid_subject_ids.add(int(row["SUBJECT_ID"]))

load_and_filter(
    "patients",
    f"{MIMIC_PATH}/PATIENTS/PATIENTS_random.csv",
    patients_filter,
    patients_process,
)

def admissions_filter(row):
    return int(row["SUBJECT_ID"]) in valid_subject_ids

def admissions_process(row):
    valid_hadm_ids.add(int(row["HADM_ID"]))

load_and_filter(
    "admissions",
    f"{MIMIC_PATH}/ADMISSIONS/ADMISSIONS_random.csv",
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
    f"{MIMIC_PATH}/ICUSTAYS/ICUSTAYS_random.csv",
    icustays_filter,
    icustays_process,
)

def d_icd_filter(row):
    return True

def d_icd_process(row):
    valid_icd_codes.add(row["ICD_CODE"])

load_and_filter(
    "d_icd_diagnoses",
    f"{MIMIC_PATH}/D_ICD_DIAGNOSES/D_ICD_DIAGNOSES_random.csv",
    d_icd_filter,
    d_icd_process,
)

def diagnoses_icd_filter(row):
    return (
        int(row["SUBJECT_ID"]) in valid_subject_ids and
        int(row["HADM_ID"]) in valid_hadm_ids and
        row["ICD_CODE"] in valid_icd_codes
    )

def diagnoses_icd_process(row):
    pass

load_and_filter(
    "diagnoses_icd",
    f"{MIMIC_PATH}/DIAGNOSES_ICD/DIAGNOSES_ICD_random.csv",
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
    f"{MIMIC_PATH}/NOTEEVENTS/NOTEEVENTS_random.csv",
    noteevents_filter,
    noteevents_process,
)


cur.close()
conn.close()
print("Done!")