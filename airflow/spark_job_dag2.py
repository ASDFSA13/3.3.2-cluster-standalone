from airflow import DAG
from airflow.operators.bash_operator import BashOperator
from datetime import datetime, timedelta
import os

# 默认参数配置
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
    schedule_interval='0 2 * * *',  # 每天凌晨2点执行
    catchup=False
)

# 假设 push_and_submit_remote.sh 和 demo.py 都放在 /opt/airflow/scripts/ 目录
# 或者你自行指定路径
BASE_DIR = "/opt/airflow/scripts"
SCRIPT_PATH = os.path.join(BASE_DIR, "push_and_submit_remote.sh")
PYSPARK_FILE = os.path.join(BASE_DIR, "demo.py")

run_spark_via_bash = BashOperator(
    task_id='run_spark_via_bash',
    bash_command=f"{SCRIPT_PATH} {PYSPARK_FILE}",  # 调用脚本，传入本地的 pyspark 文件
    dag=dag
)
