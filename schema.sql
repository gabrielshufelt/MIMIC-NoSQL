CREATE TABLE PATIENTS (
    subject_id INTEGER PRIMARY KEY,
    gender TEXT,
    dob DATE,
    dod DATE
);

CREATE TABLE ADMISSIONS (
    hadm_id INTEGER PRIMARY KEY,
    subject_id INTEGER REFERENCES PATIENTS(subject_id),
    admittime TIMESTAMP,
    dischtime TIMESTAMP,
    deathtime TIMESTAMP,
    admission_type TEXT CHECK (admission_type IN ('emergency', 'elective', 'urgent', 'newborn')),
    admission_location TEXT,
    discharge_location TEXT,
    insurance TEXT
);

CREATE TABLE ICUSTAYS (
    icustay_id INTEGER PRIMARY KEY,
    subject_id INTEGER REFERENCES PATIENTS(subject_id),
    hadm_id INTEGER REFERENCES ADMISSIONS(hadm_id),
    intime TIMESTAMP,
    outtime TIMESTAMP,
    source TEXT,
    ward_id INTEGER,
    first_careunit TEXT,
    last_careunit TEXT
);


CREATE TABLE NOTEEVENTS (
    row_id INTEGER PRIMARY KEY,
    subject_id INTEGER REFERENCES PATIENTS(subject_id),
    hadm_id INTEGER REFERENCES ADMISSIONS(hadm_id),
    charttime TIMESTAMP,
    category TEXT CHECK (category IN ('discharge_summary', 'radiology_report', 'progress_note', 'other')),
    description TEXT,
    text TEXT
);

CREATE TABLE D_ICD_DIAGNOSIS (
    icd_code TEXT PRIMARY KEY,
    short_title TEXT,
    long_title TEXT
);

CREATE TABLE DIAGNOSIS_ICD (
    row_id INTEGER PRIMARY KEY,
    subject_id INTEGER REFERENCES PATIENTS(subject_id),
    hadm_id INTEGER REFERENCES ADMISSIONS(hadm_id),
    icd_code TEXT REFERENCES D_ICD_DIAGNOSIS(icd_code)
);
