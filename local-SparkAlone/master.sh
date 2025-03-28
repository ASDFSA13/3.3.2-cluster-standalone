#!/usr/bin/env bash
set -e

sudo apt-get update -y
sudo apt-get install -y curl vim procps openjdk-8-jre-headless

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

# 创建日志目录
mkdir -p ~/log/spark-events

# 停止现有服务（判断服务是否存在）
if pgrep -f 'org.apache.spark.deploy.master.Master' > /dev/null; then
    ${SPARK_HOME}/sbin/stop-master.sh
fi

if pgrep -f 'org.apache.spark.deploy.history.HistoryServer' > /dev/null; then
    ${SPARK_HOME}/sbin/stop-history-server.sh
fi

# 覆盖配置文件（每次全新覆盖） 可以以项目目录里面的conf为准
cat > ${SPARK_HOME}/conf/spark-defaults.conf << EOF
spark.eventLog.enabled           true
spark.eventLog.dir               file://$HOME/log/spark-events
spark.history.provider           org.apache.spark.deploy.history.FsHistoryProvider
spark.history.fs.logDirectory    file://$HOME/log/spark-events
spark.history.ui.port            18080
EOF

# 启动服务
${SPARK_HOME}/sbin/start-master.sh
${SPARK_HOME}/sbin/start-history-server.sh

echo "Master URL: spark://$(hostname -I | awk '{print $1}'):7077"
echo "Spark Master Web UI: http://$(hostname -I | awk '{print $1}'):8080"
echo "History Server Web UI: http://$(hostname -I | awk '{print $1}'):18080"
