from airflow import DAG
from datetime import datetime

with DAG("identity_resolution", start_date=datetime(2024,1,1), schedule="@daily", catchup=False) as dag:
    pass
