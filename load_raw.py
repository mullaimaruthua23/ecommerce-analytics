import os
from pathlib import Path
from urllib.parse import quote_plus

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine

load_dotenv()
PASSWORD = quote_plus(os.getenv("MYSQL_PASSWORD"))
engine = create_engine(f"mysql+pymysql://root:{PASSWORD}@localhost:3306/olist")

RAW = Path("data/raw")
SKIP = {"olist_geolocation_dataset.csv"}  # 1M rows, not needed yet

for f in sorted(RAW.glob("*.csv")):
    if f.name in SKIP:
        continue
    name = "raw_" + f.stem.replace("olist_", "").replace("_dataset", "")
    df = pd.read_csv(f)
    df.to_sql(name, engine, if_exists="replace", index=False, chunksize=5000)
    print(name, len(df))