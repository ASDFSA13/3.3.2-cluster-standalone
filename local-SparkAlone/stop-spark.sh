#!/usr/bin/env bash
set -e

SPARK_VERSION=3.3.2
HADOOP_VERSION=3
SPARK_HOME=/usr/local/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}

echo "正在停止Spark服务..."

if pgrep -f 'org.apache.spark.deploy.history.HistoryServer' > /dev/null; then
    ${SPARK_HOME}/sbin/stop-history-server.sh
fi

if pgrep -f 'org.apache.spark.deploy.master.Master' > /dev/null; then
    ${SPARK_HOME}/sbin/stop-master.sh
fi

if pgrep -f 'org.apache.spark.deploy.worker.Worker' > /dev/null; then
    ${SPARK_HOME}/sbin/stop-worker.sh
fi

# 确保所有Spark进程都结束
sleep 2
pkill -f org.apache.spark || true

echo "所有Spark服务已停止！"
