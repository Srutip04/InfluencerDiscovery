from airflow import DAG
from datetime import datetime

with DAG("monitoring_alerts", start_date=datetime(2024,1,1), schedule="*/30 * * * *", catchup=False) as dag:
    pass
