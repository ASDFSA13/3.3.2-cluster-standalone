import os
from datetime import datetime, timedelta
#import pdb;pdb.set_trace();
# Airflow DAG & Operator 引用
from airflow import DAG
from airflow.operators.python_operator import PythonOperator
from airflow.providers.sftp.operators.sftp import SFTPOperator  # <-- 用于SFTP上传
from airflow.providers.ssh.operators.ssh import SSHOperator     # <-- 用于远程SSH操作

# ------------------ 可根据自己需要自定义的变量 ------------------
LOCAL_PYSPARK_FILE = "/opt/airflow/logs/demo.py"  # 本地待上传的 PySpark 脚本
REMOTE_TMP_DIR = "/home/zyl"                     # 远程服务器临时存放目录
CONTAINER_NAME = "spark-master"
CONTAINER_WORKSPACE = "/opt/workspace"
SPARK_SUBMIT_PATH = "/usr/bin/spark-3.3.2-bin-hadoop3/bin/spark-submit"
TOKEN=""
# 在 Airflow Connections 中配置好的 SSH 连接
SSH_CONN_ID = "ssh_spark_server"

# ------------------ 默认参数 ------------------
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2023, 1, 1),
    'retries': 1,
    'retry_delay': timedelta(minutes=1),
}

# ------------------ 定义 DAG ------------------
dag = DAG(
    dag_id='spark_job_dag1_ssh-docker',
    default_args=default_args,
    schedule_interval='0 2 * * *',  # 每天凌晨2点执行
    catchup=False
)

def get_file_epoch(**context):
    """
    读取本地文件的修改时间戳（秒数），返回并通过 XCom 让下一个 Task 获取。
    """
    if not os.path.isfile(LOCAL_PYSPARK_FILE):
        raise FileNotFoundError(f"Local file not found: {LOCAL_PYSPARK_FILE}")

    epoch = int(os.path.getmtime(LOCAL_PYSPARK_FILE))
    # XCom push
    return epoch


get_file_epoch_task = PythonOperator(
    task_id='get_file_epoch',
    python_callable=get_file_epoch,
    dag=dag
)

# ------------------ 第1步：上传文件到远程服务器 (SFTPOperator) ------------------
scp_to_remote_task = SFTPOperator(
    task_id='scp_to_remote',
    ssh_conn_id=SSH_CONN_ID,  # 指向 Airflow Connections 中配置的 SSH
    local_filepath=LOCAL_PYSPARK_FILE,
    remote_filepath=(
        f"{REMOTE_TMP_DIR}/{{{{ ti.xcom_pull(task_ids='get_file_epoch') }}}}"
        f"-{os.path.basename(LOCAL_PYSPARK_FILE)}"
    ),
    operation='put',                  # put = 上传， get = 下载
    create_intermediate_dirs=True,    # 如果远程目录不存在，是否自动创建
    dag=dag
)

# ------------------ 第2步：远程执行 docker cp 拷贝文件到容器 ------------------
docker_cp_command = """
docker cp {remote_tmp}/{file_epoch}-$(basename {local_file}) \
{container_name}:{container_workspace}/{file_epoch}-$(basename {local_file})
""".format(
    remote_tmp=REMOTE_TMP_DIR,
    file_epoch="{{ ti.xcom_pull(task_ids='get_file_epoch') }}",
    local_file=LOCAL_PYSPARK_FILE,
    container_name=CONTAINER_NAME,
    container_workspace=CONTAINER_WORKSPACE
)

docker_cp_task = SSHOperator(
    task_id='docker_cp',
    ssh_conn_id=SSH_CONN_ID,
    command=docker_cp_command,
    get_pty=True,
    dag=dag
)

# ------------------ 第3步：容器内执行 spark-submit ------------------
spark_submit_command=""
if (TOKEN!=""){
spark_submit_command = """
docker exec {container_name} {spark_submit} {workspace}/{file_epoch}-$(basename {local_file}) --conf spark.authenticate.secret={authenticate_secret}
""".format(
    container_name=CONTAINER_NAME,
    spark_submit=SPARK_SUBMIT_PATH,
    workspace=CONTAINER_WORKSPACE,
    file_epoch="{{ ti.xcom_pull(task_ids='get_file_epoch') }}",
    local_file=LOCAL_PYSPARK_FILE,
    authenticate_secret=TOKEN
)
}else{
spark_submit_command = """
docker exec {container_name} {spark_submit} {workspace}/{file_epoch}-$(basename {local_file})
""".format(
    container_name=CONTAINER_NAME,
    spark_submit=SPARK_SUBMIT_PATH,
    workspace=CONTAINER_WORKSPACE,
    file_epoch="{{ ti.xcom_pull(task_ids='get_file_epoch') }}",
    local_file=LOCAL_PYSPARK_FILE
)
}


spark_submit_task = SSHOperator(
    task_id='spark_submit_in_container',
    ssh_conn_id=SSH_CONN_ID,
    command=spark_submit_command,
    get_pty=True,
    dag=dag
)

# ------------------ 设置任务依赖关系 ------------------
get_file_epoch_task >> scp_to_remote_task >> docker_cp_task >> spark_submit_task