## Phase 1 - Implementing the Relational DB
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
pip3 install pandas sqlalchemy psycopg2
```
5. Create the db
```
createdb mimic
```
6. Apply the schema to the db
```
psql mimic < schema.sql
```
If this doesn't work, try `psql -U <your_pc_username> postgres mimic < schema.sql`