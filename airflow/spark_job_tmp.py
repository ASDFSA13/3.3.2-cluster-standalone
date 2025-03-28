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
    dag_id='spark_job_dag3',
    default_args=default_args,
    schedule_interval='0 2 * * *',  # 每天凌晨2点
    catchup=False
)

# PySpark任务示例
pyspark_task = SparkSubmitOperator(
    task_id='submit_pyspark_job',
    conn_id='spark_default',
    application='/opt/airflow/logs/demo.py',
    master='spark://spark-master:7077',
    executor_cores=1,
    executor_memory='512m',
    conf={'spark.executor.memory': '512m'},
    name='PySpark_RandomWorkerJob',
    dag=dag
)

# Java/Scala Jar任务示例
jar_task = SparkSubmitOperator(
    task_id='submit_jar_job',
    conn_id='spark_default',
    application='/opt/airflow/logs/spark-job-1.0-SNAPSHOT.jar',
    java_class='com.airscholar.spark.WordCountJob',
    master='spark://spark-master:7077',
    executor_cores=1,
    executor_memory='1g',
    conf={'spark.executor.memory': '1g'},
    deploy_mode='cluster',  # 👈 加上这个！
    name='Jar_WordCountJob',
    dag=dag
)
