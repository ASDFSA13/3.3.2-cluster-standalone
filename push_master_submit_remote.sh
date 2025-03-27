#!/usr/bin/env bash
#
# 作用：
#   1) SCP 推送本地脚本到远程服务器
#   2) SSH 到远程服务器后，脚本放入指定归档位置, 执行
#   3) 使用 spark-submit 执行脚本
#
# 用法：
#   ./push_and_submit_remote.sh MAIN.py
#   ./push_and_submit_remote.sh MAIN.jar MAIN_CLASS


# ---------- 配置开始 ----------
SSH_USER="zyl"
SSH_HOST="192.168.116.129"
REMOTE_TMP_DIR="/home"
CONTAINER_NAME="spark-master"
CONTAINER_WORKSPACE="/opt/workspace"
SPARK_SUBMIT_PATH="/usr/bin/spark-3.3.2-bin-hadoop3/bin/spark-submit"
SPARK_MASTER_URL="spark://spark-master:7077"

# ---------- 配置结束 ----------

LOCAL_FILE=$1
MAIN_CLASS=$2

if [[ -z "$LOCAL_FILE" ]]; then
  echo "用法: $0 <本地文件路径> [MainClass(仅jar必填)]"
  exit 1
fi

if [[ ! -f "$LOCAL_FILE" ]]; then
  echo "文件不存在: $LOCAL_FILE"
  exit 1
fi

BASENAME=$(basename "$LOCAL_FILE")
EXTENSION="${BASENAME##*.}"
FILE_EPOCH=$(stat -c '%Y' "$LOCAL_FILE")
REMOTE_FILENAME="${FILE_EPOCH}-${BASENAME}"

# 提前构造 spark-submit 命令
if [[ "$EXTENSION" == "py" ]]; then
  SPARK_SUBMIT_CMD="${SPARK_SUBMIT_PATH} --master ${SPARK_MASTER_URL} ${CONTAINER_WORKSPACE}/${REMOTE_FILENAME}"
elif [[ "$EXTENSION" == "jar" ]]; then
  if [[ -z "$MAIN_CLASS" ]]; then
    echo "提交jar时必须指定MainClass！"
    exit 1
  fi
  SPARK_SUBMIT_CMD="${SPARK_SUBMIT_PATH} --class ${MAIN_CLASS} --master ${SPARK_MASTER_URL} ${CONTAINER_WORKSPACE}/${REMOTE_FILENAME}"
else
  echo "不支持的文件类型: $EXTENSION，仅支持 .py 或 .jar"
  exit 1
fi

echo "===> 1) SCP文件到远程服务器"
scp "$LOCAL_FILE" "${SSH_USER}@${SSH_HOST}:${REMOTE_TMP_DIR}/${REMOTE_FILENAME}"
if [[ $? -ne 0 ]]; then
  echo "SCP失败!"
  exit 1
fi

echo "===> 2) SSH远程执行: docker cp并运行spark-submit"
ssh "${SSH_USER}@${SSH_HOST}" <<EOF
  docker cp "${REMOTE_TMP_DIR}/${REMOTE_FILENAME}" "${CONTAINER_NAME}:${CONTAINER_WORKSPACE}/${REMOTE_FILENAME}" && \
  if [[ \$? -ne 0 ]]; then
    echo "docker cp 失败"
    exit 1
  fi

  docker exec "${CONTAINER_NAME}" ${SPARK_SUBMIT_CMD}
EOF

echo "===> 完成!"
