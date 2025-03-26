#!/usr/bin/env bash
# 用法: push_master_submit.sh LOCAL_FILE

# 本地文件绝对/相对路径
LOCAL_FILE=$1

# 你的容器名字
CONTAINER_NAME="spark-master"

# 目标容器路径
TARGET_DIR="/opt/workspace"

# 如果需要, 这里可以写死 spark-submit 的绝对路径
SPARK_SUBMIT="/usr/bin/spark-3.3.2-bin-hadoop3/bin/spark-submit"

# -------------------------------------
# 1) 先检测一下有没有传参数
if [[ -z "$LOCAL_FILE" ]]; then
  echo "用法: $0 LOCAL_FILE"
  exit 1
fi

# 2) 获取本地文件名和时间戳
BASENAME=$(basename "$LOCAL_FILE")

# 如果你的系统是 GNU stat, 可以用 -c %Y 或者 -c %y
# -c %y 格式类似 "2025-03-26 10:30:45.000000000 +0800"
# 下面使用 -c %y 并用引号包住, 以防止空格/特殊字符分隔
TIME_STAMP=$(stat -c "%y" "$LOCAL_FILE")

# 3) 将本地文件复制到容器内
docker cp "$LOCAL_FILE" "$CONTAINER_NAME":"$TARGET_DIR"

# 4) 在容器内还原文件 mtime
docker exec "$CONTAINER_NAME" \
  bash -c "touch -m -d \"$TIME_STAMP\" \"$TARGET_DIR/$BASENAME\""

# 5) 在容器内执行 spark-submit
docker exec "$CONTAINER_NAME" \
  bash -c "$SPARK_SUBMIT $TARGET_DIR/$BASENAME"
