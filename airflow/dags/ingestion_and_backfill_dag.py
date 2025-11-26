# Airflow DAG template
from airflow import DAG
from datetime import datetime, timedelta

default_args = {"owner": "airflow", "retries": 1, "retry_delay": timedelta(minutes=5)}

with DAG("ingestion_and_backfill", start_date=datetime(2024,1,1), schedule="@hourly", default_args=default_args, catchup=False) as dag:
    pass
