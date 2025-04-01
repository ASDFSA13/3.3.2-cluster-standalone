#!/usr/bin/env bash
set -e

sudo apt-get update -y
sudo apt-get install -y curl vim procps openjdk-8-jre-headless
DNS=192.168.116.130

export SPARK_WORKER_WEBUI_HOST=$DNS
export SPARK_PUBLIC_DNS=$DNS

export SPARK_MASTER=spark://$DNS:7077
export SPARK_MASTER_HOST=$DNS
export SPARK_MASTER_PORT=7077

MASTER_IP=$DNS
SPARK_VERSION=3.3.2
HADOOP_VERSION=3
SPARK_HOME=/usr/local/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}

# 下载并解压Spark（若未安装）
if [ ! -d "$SPARK_HOME" ]; then
    echo "正在下载和安装Spark..."
    curl https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -o spark.tgz
    sudo tar -xf spark.tgz -C /usr/local/
    rm spark.tgz
else
    echo "Spark已安装，跳过安装步骤。"
fi

# 配置环境变量（避免重复追加）
grep -qxF "export SPARK_HOME=${SPARK_HOME}" ~/.bashrc || echo "export SPARK_HOME=${SPARK_HOME}" >> ~/.bashrc
grep -qxF "export PATH=\$PATH:${SPARK_HOME}/bin:${SPARK_HOME}/sbin" ~/.bashrc || echo "export PATH=\$PATH:${SPARK_HOME}/bin:${SPARK_HOME}/sbin" >> ~/.bashrc
source ~/.bashrc

# 停止现有Worker服务（判断是否存在）
if pgrep -f 'org.apache.spark.deploy.worker.Worker' > /dev/null; then
    ${SPARK_HOME}/sbin/stop-worker.sh
fi

# 启动Worker节点
${SPARK_HOME}/sbin/start-worker.sh spark://${MASTER_IP}:7077

echo "Worker connected to spark://${MASTER_IP}:7077"
echo "Worker Web UI: http://$(hostname -I | awk '{print $1}'):8081"
