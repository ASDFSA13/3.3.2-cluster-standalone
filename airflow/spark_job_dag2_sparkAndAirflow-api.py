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
    dag_id='spark_job_dag2_sparkAndAirflow-api',
    default_args=default_args,
    schedule_interval='0 2 * * *',  # 每天凌晨2点
    catchup=False
)


target_conf={
# "spark.driver.host": "192.168.116.130",  # Airflow容器的宿主机IP or 映射IP
# "spark.driver.port": "46888",            # 手动指定 Driver 端口
# "spark.blockManager.port": "46889",      # 手动指定 BlockManager 端口（建议也加）
# "spark.driver.bindAddress": "0.0.0.0",    # 让 Driver 绑定所有网卡
'spark.executor.memory': '512m'
}

# Java/Scala Jar任务示例
jar_task = SparkSubmitOperator(
    task_id='submit_jar_job',
    conn_id='spark_default',
    application='/opt/airflow/logs/spark-job-1.0-SNAPSHOT.jar',
    java_class='com.airscholar.spark.WordCountJob',
    executor_cores=1,
    executor_memory='512m',
    conf=target_conf,
    deploy_mode='cluster',   # 集群模式提交
    name='Jar_WordCountJob',
    dag=dag
)