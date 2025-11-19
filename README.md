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

### Manual Setup

If you prefer to set up manually, follow these steps:

1. Download the MIMIC-III dataset into your downloads folder via curl.
```
#!/bin/bash
curl -L -o ~/Downloads/mimic-iii-10k.zip\
  https://www.kaggle.com/api/v1/datasets/download/bilal1907/mimic-iii-10k
```
Alternatively, download the dataset as zip from https://www.kaggle.com/datasets/bilal1907/mimic-iii-10k.

Once downloaded, make sure to unpack the zip file and rename the root folder to 'mimic-iii'.

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
pip3 install pandas sqlalchemy psycopg2-binary pymongo
```

5. Create the db
```
createdb mimic
```

6. Apply the schema to the db
```
psql -U postgres mimic < schema.sql
```

7. Populate the database
```
python3 populate_db.py
```

## Phase 2 - Migrating to a NoSQL DB
1. Install MongoDB.
```
brew tap mongodb/brew
brew install mongodb-community
brew services start mongodb-community
```
You can also download it from https://www.mongodb.com/try/download/community.
2. 