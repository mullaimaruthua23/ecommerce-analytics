"""
run_audit.py
Runs every query in a .sql file and saves ALL results into one markdown file.
A query starts at a comment line like:  -- Q14: Some question?

Usage (from the project folder):
    python run_audit.py sql/data_quality.sql docs/audit_results.md

Needs .env with MYSQL_PASSWORD, same as build_master.py.
"""
import os
import re
import sys
from pathlib import Path
from urllib.parse import quote_plus

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

MAX_ROWS = 25  # rows kept per query (long lists are cut)


def get_engine():
    """Connect to MySQL using the password from .env. AUDIT_DB_URL overrides it (for testing)."""
    load_dotenv()
    url = os.getenv("AUDIT_DB_URL")
    if url:
        return create_engine(url)
    password = quote_plus(os.getenv("MYSQL_PASSWORD"))
    return create_engine(f"mysql+pymysql://root:{password}@localhost:3306/olist")


def split_queries(sql_text):
    """Return a list of (name, title, query) from the text of a .sql file."""
    blocks = re.split(r"(?m)^(?=--\s*Q\d+:)", sql_text)
    queries = []
    for block in blocks:
        match = re.match(r"--\s*(Q\d+):\s*(.*)", block)
        if not match:
            continue  # file header, before the first query
        name, title = match.group(1), match.group(2).strip()
        body = "\n".join(
            line for line in block.splitlines() if not line.strip().startswith("--")
        )
        query = body.split(";")[0].strip()
        if query:
            queries.append((name, title, query))
    return queries


def run_query(engine, query):
    """Run one query. Returns (dataframe, has_more_rows)."""
    with engine.connect() as conn:
        result = conn.execute(text(query))
        rows = result.fetchmany(MAX_ROWS + 1)
        columns = list(result.keys())
    df = pd.DataFrame(rows, columns=columns)
    return df.head(MAX_ROWS), len(rows) > MAX_ROWS


def main():
    if len(sys.argv) != 3:
        print("Usage: python run_audit.py <input.sql> <output.md>")
        sys.exit(1)

    sql_path, out_path = Path(sys.argv[1]), Path(sys.argv[2])
    queries = split_queries(sql_path.read_text(encoding="utf-8"))
    engine = get_engine()

    out = [
        "# Audit results",
        "",
        f"Source: `{sql_path.name}`. At most {MAX_ROWS} rows are kept per query.",
        "",
    ]
    for name, title, query in queries:
        out += [f"## {name}: {title}", ""]
        try:
            df, more = run_query(engine, query)
            if df.empty:
                out += ["No rows.", ""]
                print(f"{name}: no rows")
            else:
                out += ["```", df.to_string(index=False), "```", ""]
                if more:
                    out += [f"(first {MAX_ROWS} rows shown, more exist)", ""]
                print(f"{name}: {len(df)} rows")
        except Exception as exc:  # keep going, show the error in the file
            out += [f"ERROR: {exc}", ""]
            print(f"{name}: ERROR {str(exc)[:80]}")

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(out), encoding="utf-8")
    print(f"\nSaved {len(queries)} query results to {out_path}")


if __name__ == "__main__":
    main()
