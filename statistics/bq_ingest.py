import os
import sys
import json
from datetime import date, timedelta
from supabase import create_client
from google.cloud import bigquery
from google.oauth2 import service_account
from dotenv import load_dotenv
load_dotenv()

# --- Config ---
SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_KEY = os.environ["SUPABASE_SERVICE_KEY"]
BQ_PROJECT = "activity-tracker-statistics"
BQ_DATASET = "raw"
BQ_CREDENTIALS_JSON = os.environ["BQ_CREDENTIALS_JSON"]

yesterday = (date.today() - timedelta(days=1)).isoformat()
today = (date.today() + timedelta(days=0)).isoformat()
upload_all_users = "--upload-all-users" in sys.argv
upload_all_categories = "--upload-all-categories" in sys.argv

# --- Supabase ---
supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

entries = (
    supabase.table("entry")
    .select("id, created_at, category_id, start_time, end_time, user_id")
    .gte("created_at", f"{yesterday}T00:00:00+00:00")
    .lt("created_at", f"{today}T00:00:00+00:00")
    .execute()
    .data
)

if upload_all_users:
    users = supabase.table("user").select("id, created_at, name").execute().data
    print(f"Fetched all {len(users)} users")
else:
    users = (
        supabase.table("user")
        .select("id, created_at, name")
        .gte("created_at", f"{yesterday}T00:00:00+00:00")
        .lt("created_at", f"{today}T00:00:00+00:00")
        .execute()
        .data
    )

if upload_all_categories:
    categories = supabase.table("category").select("id, user_id, name, color, is_productive, is_sleep, created_at").execute().data
    print(f"Fetched all {len(categories)} categories")
else:
    categories = (
        supabase.table("category")
        .select("id, user_id, name, color, is_productive, is_sleep, created_at")
        .gte("created_at", f"{yesterday}T00:00:00+00:00")
        .lt("created_at", f"{today}T00:00:00+00:00")
        .execute()
        .data
    )

print(f"Fetched {len(entries)} entries, {len(users)} users, {len(categories)} categories for {yesterday}")

# --- BigQuery ---
credentials_info = json.loads(BQ_CREDENTIALS_JSON)
credentials = service_account.Credentials.from_service_account_info(credentials_info)
bq = bigquery.Client(project=BQ_PROJECT, credentials=credentials)

entries_schema = [
    bigquery.SchemaField("id", "STRING"),
    bigquery.SchemaField("created_at", "DATE"),
    bigquery.SchemaField("category_id", "STRING"),
    bigquery.SchemaField("start_time", "STRING"),
    bigquery.SchemaField("end_time", "STRING"),
    bigquery.SchemaField("user_id", "STRING"),
]

users_schema = [
    bigquery.SchemaField("id", "STRING"),
    bigquery.SchemaField("created_at", "DATE"),
    bigquery.SchemaField("name", "STRING"),
]

categories_schema = [
    bigquery.SchemaField("id", "STRING"),
    bigquery.SchemaField("user_id", "STRING"),
    bigquery.SchemaField("name", "STRING"),
    bigquery.SchemaField("color", "STRING"),
    bigquery.SchemaField("is_productive", "BOOL"),
    bigquery.SchemaField("is_sleep", "BOOL"),
    bigquery.SchemaField("created_at", "DATE"),
]

def normalize_dates(rows, date_fields):
    for row in rows:
        for field in date_fields:
            if row.get(field):
                row[field] = row[field][:10]
    return rows

entries = normalize_dates(entries, ["created_at"])
users = normalize_dates(users, ["created_at"])
categories = normalize_dates(categories, ["created_at"])

def upsert_simple(table_id, rows, schema, full_replace=False):
    if not rows:
        print(f"No rows to upload for {table_id}, skipping")
        return

    job_config = bigquery.LoadJobConfig(
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE if full_replace else bigquery.WriteDisposition.WRITE_APPEND,
        schema=schema,
    )

    job = bq.load_table_from_json(rows, table_id, job_config=job_config)
    job.result()
    print(f"{'Replaced all' if full_replace else 'Uploaded'} {len(rows)} rows to {table_id}")

def upsert_partition(table_id, rows, schema):
    if not rows:
        print(f"No rows to upload for {table_id}, skipping")
        return

    partition_decorator = f"{table_id}${yesterday.replace('-', '')}"
    job_config = bigquery.LoadJobConfig(
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        schema=schema,
        time_partitioning=bigquery.TimePartitioning(
            type_=bigquery.TimePartitioningType.DAY,
            field="created_at",
        ),
    )

    job = bq.load_table_from_json(rows, partition_decorator, job_config=job_config)
    job.result()
    print(f"Uploaded {len(rows)} rows to {partition_decorator}")

upsert_partition(f"{BQ_PROJECT}.{BQ_DATASET}.entries", entries, entries_schema)
upsert_simple(f"{BQ_PROJECT}.{BQ_DATASET}.users", users, users_schema, full_replace=upload_all_users)
upsert_simple(f"{BQ_PROJECT}.{BQ_DATASET}.categories", categories, categories_schema, full_replace=upload_all_categories)