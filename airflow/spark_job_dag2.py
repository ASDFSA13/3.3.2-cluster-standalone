from airflow import DAG
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2023, 1, 1),
    'retries': 1,
    'retry_delay': timedelta(minutes=1),
}

dag = DAG(
    dag_id='spark_job_dag2',
    default_args=default_args,
    schedule_interval='0 2 * * *',  # 每天凌晨2点
    catchup=False
)

spark_job = SparkSubmitOperator(
    task_id='spark_submit_job',
    # 这里的 conn_id 要与 Airflow Connection 中的 spark_default (或你自定义的名称) 对应
    conn_id='spark_default',

    # 你的 PySpark 程序本地路径
    application='/opt/airflow/logs/demo.py',

    # 若你没在 conn extra 里配置 master，可以在这里指定
    master='spark://spark-master:7077',

    # 也可以额外加参数，比如:
    conf={'spark.executor.memory': '512m'},
#     total_executor_cores=2,
    executor_cores=1,
    executor_memory='512m',
    name='RandomWorkerJob',

    dag=dag
)
