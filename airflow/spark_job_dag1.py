import os
from datetime import datetime, timedelta

# 引入 Airflow 核心
from airflow import DAG

# 引入常见 Operator
from airflow.operators.python_operator import PythonOperator
from airflow.operators.bash_operator import BashOperator
from airflow.providers.ssh.operators.ssh import SSHOperator

# ------------------ 你可能要自定义的变量开始 ------------------
LOCAL_PYSPARK_FILE = "/opt/airflow/log/demo.py"  # 本地待上传的 PySpark 脚本
REMOTE_TMP_DIR = "/home/zyl"                         # 远程服务器临时存放目录
CONTAINER_NAME = "spark-master"
CONTAINER_WORKSPACE = "/opt/workspace"
SPARK_SUBMIT_PATH = "/usr/bin/spark-3.3.2-bin-hadoop3/bin/spark-submit"
SSH_CONN_ID = "ssh_spark_server"  # 在 Airflow Connections 中配置好的 SSH 连接
# ------------------ 你可能要自定义的变量结束 ------------------

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    # 这里示例一下开始时间
    'start_date': datetime(2023, 1, 1),
    'retries': 1,
    'retry_delay': timedelta(minutes=1),
}

dag = DAG(
    dag_id='spark_job_dag1',           # DAG 名
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

# --------------------------------------------------------------------
# 方式 A) 用 BashOperator + sshpass/scp (如原脚本).
# --------------------------------------------------------------------
# 这种方式，需要在 Airflow 机器安装 sshpass，命令里我们会用:
#   sshpass -p 'xxxxx' scp local_file user@remote:/path/filename
# 这里仅示例，不建议生产中明文写密码
# 如果已经配置好 Airflow SSH Connection(免密或key)，可以用 “方式 B)” (SFTPOperator/SSHOperator) 来上传
# --------------------------------------------------------------------

# SSH_PASSWORD = "123456"   # 示例演示，如果要明文写在脚本里，不安全，仅供演示
#
# scp_command = f"""
# sshpass -p '{SSH_PASSWORD}' scp {LOCAL_PYSPARK_FILE} zyl@192.168.116.129:{REMOTE_TMP_DIR}/`echo {{{{ ti.xcom_pull(task_ids='get_file_epoch') }}}}`-$(basename {LOCAL_PYSPARK_FILE})
# """
#
# scp_to_remote_task = BashOperator(
#     task_id='scp_to_remote',
#     bash_command=scp_command,
#     dag=dag
# )

# --------------------------------------------------------------------
# 方式 B) (可选) 若不想写明文密码 + sshpass，可以用 SFTPOperator 或 SSHOperator
# --------------------------------------------------------------------
# 例如，这里演示用 SSHOperator + sftp 命令：
#   sftp user@host:/path <<EOF
#       put local_file remote_file
#   EOF
# 也可以用 Airflow 的 SFTPOperator（注意要安装 `apache-airflow-providers-sftp`）
# --------------------------------------------------------------------
# 如果你不想用 "scp_to_remote_task" 方式，可以换成这个:
#   sftp_to_remote_task = SSHOperator(
#       task_id='sftp_to_remote',
#       ssh_conn_id=SSH_CONN_ID,
#       command="""
#         cd /home/zyl
#         put ???    # sftp subcommand 不是 bash 语法，需要脚本化处理
#         ...
#       """,
#       dag=dag
#   )
# --------------------------------------------------------------------
# 这里先保留最简单的 BashOperator + sshpass 示例.


scp_to_remote_task = SFTPOperator(
    task_id='scp_to_remote',
    ssh_conn_id=SSH_CONN_ID,  # 指向 Airflow Connections 中的 SSH 连接 ID
    local_filepath=LOCAL_PYSPARK_FILE,
    remote_filepath=f"{REMOTE_TMP_DIR}/{{{{ ti.xcom_pull(task_ids='get_file_epoch') }}}}-{os.path.basename(LOCAL_PYSPARK_FILE)}",
    operation='put',                  # put = 上传，get = 下载
    create_intermediate_dirs=True,    # 如果远程目录不存在，是否自动创建
    dag=dag
)


# --------------------------------------------------------------------
# docker_cp：将上一步上传到远程服务器的文件，复制到容器内部
# --------------------------------------------------------------------
docker_cp_command = """
docker cp {remote_tmp}/{file_epoch}-$(basename {local_file}) {container_name}:{container_workspace}/{file_epoch}-$(basename {local_file})
""".format(
    remote_tmp=REMOTE_TMP_DIR,
    file_epoch="{{ ti.xcom_pull(task_ids='get_file_epoch') }}",
    local_file=LOCAL_PYSPARK_FILE,
    container_name=CONTAINER_NAME,
    container_workspace=CONTAINER_WORKSPACE
)

docker_cp_task = SSHOperator(
    task_id='docker_cp',
    ssh_conn_id=SSH_CONN_ID,  # 远程服务器 SSH 连接
    command=docker_cp_command,
    dag=dag
)

# --------------------------------------------------------------------
# spark_submit_in_container：容器内执行 spark-submit
# --------------------------------------------------------------------
spark_submit_command = """
docker exec {container_name} {spark_submit} {workspace}/{file_epoch}-$(basename {local_file})
""".format(
    container_name=CONTAINER_NAME,
    spark_submit=SPARK_SUBMIT_PATH,
    workspace=CONTAINER_WORKSPACE,
    file_epoch="{{ ti.xcom_pull(task_ids='get_file_epoch') }}",
    local_file=LOCAL_PYSPARK_FILE
)

spark_submit_task = SSHOperator(
    task_id='spark_submit_in_container',
    ssh_conn_id=SSH_CONN_ID,
    command=spark_submit_command,
    dag=dag
)

# --------------------------------------------------------------------
# 依赖关系：先获取本地文件 epoch -> scp 上传 -> docker cp -> spark-submit
# --------------------------------------------------------------------
get_file_epoch_task >> scp_to_remote_task >> docker_cp_task >> spark_submit_task
