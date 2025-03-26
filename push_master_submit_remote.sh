#!/usr/bin/env bash
#
# 作用：
#   1) SCP 推送本地脚本到远程服务器
#   2) SSH 到远程服务器后，用 docker cp 把脚本放到容器 /opt/workspace
#   3) 还原脚本修改时间
#   4) 使用 spark-submit 执行脚本
#
# 用法：
#   ./push_and_submit_remote.sh <本地文件路径>
#
# 备注：
#   - 脚本默认用 root/root 做容器内路径和容器名称，仅作示例
#   - 如果脚本里出现权限问题，可以酌情修改
#   - 如果容器 spark-submit 路径和版本不同，请自行修改 SPARK_SUBMIT_PATH

# ---------- 你可能要修改的自定义变量开始 ----------
SSH_USER="zyl"             # 远程服务器的 SSH 用户名
SSH_HOST="192.168.116.129"          # 远程服务器的 IP 或主机名
REMOTE_TMP_DIR="/home/zyl/"       # 远程服务器临时存放文件的目录
CONTAINER_NAME="spark-master"  # 目标容器名称/ID
CONTAINER_WORKSPACE="/opt/workspace"  # 容器内要放文件的目录
SPARK_SUBMIT_PATH="/usr/bin/spark-3.3.2-bin-hadoop3/bin/spark-submit"
# ---------- 你可能要修改的自定义变量结束  ----------

# 获取传入的本地文件
LOCAL_FILE=$1

# 校验参数
if [[ -z "$LOCAL_FILE" ]]; then
  echo "用法: $0 <本地文件路径>"
  exit 1
fi

# 确保文件存在
if [[ ! -f "$LOCAL_FILE" ]]; then
  echo "文件不存在: $LOCAL_FILE"
  exit 1
fi

# 获取文件名 (不带路径)
BASENAME=$(basename "$LOCAL_FILE")

# 取本地文件的 mtime（采用 epoch 秒数，避免空格转义问题）
# -c '%Y' 返回自 Epoch (1970-01-01 00:00:00 UTC) 以来的秒数
FILE_EPOCH=$(stat -c '%Y' "$LOCAL_FILE")

echo "===> 1) 把本地 [$LOCAL_FILE] SCP 到 [$SSH_HOST:$REMOTE_TMP_DIR/$BASENAME] ..."
scp "$LOCAL_FILE" "${SSH_USER}@${SSH_HOST}:${REMOTE_TMP_DIR}/$BASENAME"
if [[ $? -ne 0 ]]; then
  echo "SCP 失败，请检查网络/权限"
  exit 1
fi

echo "===> 2) SSH 远程执行: 把文件用 docker cp 推到容器 [$CONTAINER_NAME] ..."
ssh "${SSH_USER}@${SSH_HOST}" <<EOF
  docker cp "${REMOTE_TMP_DIR}/$BASENAME" "${CONTAINER_NAME}:${CONTAINER_WORKSPACE}/$BASENAME"
  if [[ \$? -ne 0 ]]; then
    echo "docker cp 失败"
    exit 1
  fi

  echo "===> 3) 还原容器内文件修改时间 -> [\$FILE_EPOCH=$FILE_EPOCH]"
  # 注意：touch 的 -d 参数接受形如 @1679839232 的 EPOCH 时间
  docker exec "$CONTAINER_NAME" touch -m -d "@$FILE_EPOCH" "${CONTAINER_WORKSPACE}/$BASENAME"
  if [[ \$? -ne 0 ]]; then
    echo "touch 修正时间失败"
    exit 1
  fi

  echo "===> 4) 在容器内执行 spark-submit 运行脚本..."
  docker exec "$CONTAINER_NAME" "$SPARK_SUBMIT_PATH" "${CONTAINER_WORKSPACE}/$BASENAME"
EOF

echo "===> 完成！"
