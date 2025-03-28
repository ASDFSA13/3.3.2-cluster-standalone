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

# --conf spark.authenticate.secret=XXXXX 使用安全令牌进行提交  这里需要在airflow配置conn_id的连接信息中包含令牌

# spark_job = SparkSubmitOperator(
#     task_id='spark_submit_job',
#     # 这里的 conn_id 要与 Airflow Connection 中的 spark_default (或你自定义的名称) 对应
#     conn_id='spark_default',
#
#     # 你的 PySpark 程序本地路径
#     application='/opt/airflow/logs/demo.py',
#
#     # 若你没在 conn extra 里配置 master，可以在这里指定
#     master='spark://spark-master:7077',
#
#     # 也可以额外加参数，比如:
#     conf={'spark.executor.memory': '512m'},
# #     total_executor_cores=2,
#     executor_cores=1,
#     executor_memory='512m',
#     name='RandomWorkerJob',
#
# #     deploy_mode='cluster',  # 使用standalone的方式进行集群提交 但是python不支持
#
#
#     dag=dag
# )


# Java/Scala Jar任务示例
jar_task = SparkSubmitOperator(
    task_id='submit_jar_job',
    conn_id='spark_default',
    application='/opt/airflow/logs/spark-job-1.0-SNAPSHOT.jar',
    java_class='com.airscholar.spark.WordCountJob',
    master='spark://spark-master:7077',
    executor_cores=1,
    executor_memory='512m',
    conf={'spark.executor.memory': '512m'},
    deploy_mode='cluster',   # 集群模式提交
    name='Jar_WordCountJob',
    dag=dag
)