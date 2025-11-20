## Phase 1 - Implementing the Relational DB

### Automated Setup (Recommended)

We provide setup scripts that automate all the steps below:

**Mac/Linux:**
```bash
chmod +x setup_db.sh
./setup_db.sh
```

**Windows (PowerShell):**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\setup_db.ps1
```

The setup scripts will:
- Guide you through downloading the MIMIC-III dataset
- Install PostgreSQL and Python (on Mac)
- Install Python dependencies
- Create and configure the database
- Apply the schema
- Optionally populate the database

### Manual Setup (MacOS/Linux)

If you prefer to set up manually, follow these steps:

1. Download the MIMIC-III dataset into your downloads folder via curl.
```
#!/bin/bash
curl -L -o ~/Downloads/mimic-iii-10k.zip\
  https://www.kaggle.com/api/v1/datasets/download/bilal1907/mimic-iii-10k
```
Alternatively, download the dataset as zip from https://www.kaggle.com/datasets/bilal1907/mimic-iii-10k.

Once downloaded, make sure to unpack the zip file.

2. Install last version of postgresql with homebrew.
```
brew install postgresql@17
```
Once installed, make sure it's running with `brew services start postgresql@17`.

3. Download and install latest version of Python
```
brew install python
```

4. Install python dependencies
```
pip3 install sqlalchemy psycopg2-binary pymongo
```

5. Create the db
```
createdb mimic
```

6. Apply the schema to the db
```
psql -U postgres mimic < schema.sql
```

7. Go to `populate_db.py` line 6, and change *MIMIC_PATH* to point to the dataset folder you downloaded in step 1.

8. Populate the database
```
python3 populate_db.py
```

### Manual Setup (Windows)
1. Download the MIMIC-III dataset as zip from https://www.kaggle.com/api/v1/datasets/download/bilal1907/mimic-iii-10k. Once downloaded, make sure to unpack the zip file.

2. Download the PostgreSQL installer for Windows from https://www.postgresql.org/download/.

**Very important:** a) When prompted, make sure to set *postgres* as the root user password. b) Once the installation is complete, make sure to add "C:\Program Files\PostgreSQL\<version number>\bin" to your *PATH* system environment variable.

3. Download the latest version of Python from https://www.python.org/downloads/. Run the installer and check all the default options.

**Very important:** During the installation, select the 'Add python.exe to PATH' checkbox when prompted.

4. Install the python dependencies
```
pip install sqlalchemy psycopg2-binary pymongo
```

5. Create the db
```
psql -U postgres -c "CREATE DATABASE mimic;"
```

6. Apply the schema
```
psql -U postgres -d mimic -f schema.sql
```

7. Go to `populate_db.py` line 6, and change *MIMIC_PATH* to point to the dataset folder you downloaded in step 1.
8. Populate the database
```
python populate_db.py
```

## Phase 2 - Migrating to a NoSQL DB
### 1. Install MongoDB Community Server.

**For MacOS:**
```
brew tap mongodb/brew
brew install mongodb-community
brew services start mongodb-community
```

**For Windows**, you can download it from https://www.mongodb.com/try/download/community. After installation, make sure the MongoDB service is running:
![img.png](img.png)

### 2. Download and install MongoDB Shell

**For MacOS:**
```
brew tap mongodb/brew
brew install mongosh
```

**For Windows**, download it from https://www.mongodb.com/try/download/shell. Extract the zip, and add it 'C:\Users\<your user>\Downloads\mongosh-2.5.9-win32-x64\mongosh-2.5.9-win32-x64\bin' to your _PATH_ system environment variable.

### 3. Run the migration script
```
python migrate_db.py
```

## Using the NoSQL Database
We are using MongoDB as our NoSQL key-value database. To start exploring the data, try the following commands:

### 1. Connect to the database via the MongoDB shell
```
mongosh
use mimic_nosql
```

### 2. Basic Database Operations

**View all collections:**
```
show collections
```

**Count documents in a collection:**
```
db.patients.countDocuments()
db.admissions.countDocuments()
```

### 3. Querying Data

**Find a specific patient by ID:**
```
db.patients.findOne({_id: 10006})
```

**Find all female patients:**
```
db.patients.find({value_string: /gender=F/})
```

**Find patients who have died:**
```
db.patients.find({value_string: /expire_flag=1/})
```

**Find admissions by patient ID:**
```
db.admissions.find({value_string: /subject_id=10006/})
```

**Find ICU stays with length of stay greater than 5 days:**
```
db.icustays.find({value_string: /LOS=[6-9]|LOS=[1-9][0-9]/})
```

**Search clinical notes by keyword:**
```
db.noteevents.find({value_string: /pneumonia/i})
```

**Find diagnosis codes and their descriptions:**
```
db.d_icd_diagnoses.findOne({_id: 1})
```

**List all diagnoses for a specific patient:**
```
db.diagnoses_icd.find({value_string: /subject_id=10006/})
```

### 4. Advanced Queries

**Limit and sort results:**
```
db.patients.find().limit(10)
db.admissions.find().sort({_id: -1}).limit(5)
```

## TODO
1. Compare query performance, for example the time it takes retrieving a record by its id, relational vs. NoSQL.