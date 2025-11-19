from sqlalchemy import create_engine, inspect, text
from pymongo import MongoClient

engine = create_engine("postgresql://postgres:postgres@localhost/mimic")
inspector = inspect(engine)

tables = inspector.get_table_names()

mongo_client = MongoClient("mongodb://localhost:27017/")
mongo_db = mongo_client["mimic_nosql"]

print("Migrating tables:", tables)

for table in tables:
    print(f"\n=== Processing table: {table} ===")

    # Get primary key column(s)
    pk_info = inspector.get_pk_constraint(table)
    primary_keys = pk_info.get("constrained_columns", [])

    if not primary_keys:
        print(f"WARNING: Table {table} has no primary key — skipping.")
        continue

    if len(primary_keys) > 1:
        print(f"WARNING: Composite primary key in {table}, using concatenated PK.")

    pk = primary_keys[0]  # Assume single-column PK

    # Create Mongo collection
    collection = mongo_db[table]

    # Query all rows from table
    with engine.connect() as conn:
        rows = conn.execute(text(f"SELECT * FROM {table}")).mappings()

        batch = []
        for row in rows:
            row = dict(row)

            # Extract PK value
            pk_value = row[pk]

            # Build document without the PK
            value_doc = {k: v for k, v in row.items() if k != pk}

            # OPTIONAL: build a "value string" with all non-PK attributes
            value_string = " | ".join(f"{k}={v}" for k, v in value_doc.items())

            doc = {
                "_id": pk_value,
                "data": value_doc,
                "value_string": value_string  # remove this if you don't want it
            }

            batch.append(doc)

            # Insert in batches for performance
            if len(batch) >= 1000:
                collection.insert_many(batch, ordered=False)
                batch = []

        # Insert remaining
        if batch:
            collection.insert_many(batch, ordered=False)

    print(f"✔ Inserted documents for {table}")
