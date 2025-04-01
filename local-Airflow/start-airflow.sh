#!/usr/bin/env bash
set -e

####################################
#           全局变量配置
####################################
# apt 源配置（以 Debian Bookworm 为例）
# 如果你的系统不是 Debian/Ubuntu 系，请根据自身需求自行修改
MIRROR_SOURCE="deb https://mirrors.aliyun.com/debian bookworm main contrib non-free
deb https://mirrors.aliyun.com/debian bookworm-updates main contrib non-free
deb https://mirrors.aliyun.com/debian-security bookworm-security main contrib non-free"

# OpenJDK 8（Temurin）相关信息
JAVA_VERSION="8u442-b06"
JAVA_URL="https://mirrors.tuna.tsinghua.edu.cn/Adoptium/8/jdk/x64/linux/OpenJDK8U-jdk_x64_linux_hotspot_8u442b06.tar.gz"
JAVA_INSTALL_DIR="/opt/java"         # 安装目录
JAVA_HOME_DIR="${JAVA_INSTALL_DIR}/jdk8u442-b06"

# Airflow及其依赖
AIRFLOW_VERSION="2.9.3"
PIP_PKG_LIST=(
  "apache-airflow==${AIRFLOW_VERSION}"
  "lxml"
  "pyspark==3.3.2"
  "python-decouple"
  "apache-airflow-providers-apache-spark==2.1.0"
  "requests"
  "pandas"
)

# 是否以“demo”用户运行（参考Dockerfile）
# 如果不需要创建demo用户，可视情况修改或删除相关逻辑
DEMO_USER="demo"
DEMO_PASS="123456"

####################################
#          函数/流程封装
####################################

function check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "错误：请使用 root 权限运行此脚本。"
        exit 1
    fi
}

function configure_apt_source() {
    echo ">>> [1/7] 配置 apt 源为阿里云镜像..."

    # 备份原 /etc/apt/sources.list
    if [ -f /etc/apt/sources.list ]; then
        cp /etc/apt/sources.list /etc/apt/sources.list.bak.$(date +%Y%m%d%H%M%S)
    fi

    # 写入新的 sources.list
    echo "${MIRROR_SOURCE}" > /etc/apt/sources.list
    apt-get update
    echo "已完成 apt 源配置并更新索引。"
}

function install_sys_packages() {
    echo ">>> [2/7] 安装必要的系统包..."
    # 参考 Dockerfile 中的包
    apt-get install -y ant sudo wget curl tar procps vim
    echo "系统依赖安装完成。"
}

function setup_java() {
    echo ">>> [3/7] 安装(或检查) OpenJDK 8 (Temurin)..."

    # 若已存在对应版本则跳过下载
    if [ ! -d "${JAVA_HOME_DIR}" ]; then
        mkdir -p "${JAVA_INSTALL_DIR}"
        echo "正在下载并解压 JDK 到 ${JAVA_INSTALL_DIR}..."
        curl -L "${JAVA_URL}" -o /tmp/openjdk.tar.gz
        tar -xzf /tmp/openjdk.tar.gz -C "${JAVA_INSTALL_DIR}"
        rm -f /tmp/openjdk.tar.gz
        echo "JDK 安装完成。"
    else
        echo "检测到 JDK 已安装，跳过下载。"
    fi

    # 配置环境变量（避免重复添加）
    grep -qxF "export JAVA_HOME=${JAVA_HOME_DIR}" /etc/profile || echo "export JAVA_HOME=${JAVA_HOME_DIR}" >> /etc/profile
    grep -qxF 'export PATH=$PATH:$JAVA_HOME/bin' /etc/profile || echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /etc/profile

    # 让当前 Shell 生效
    source /etc/profile
    echo "JAVA_HOME 已配置。"
}

function create_demo_user() {
    echo ">>> [4/7] 创建(或检查) demo 用户..."
    id -u "${DEMO_USER}" &>/dev/null || useradd -ms /bin/bash "${DEMO_USER}"
    echo "${DEMO_USER}:${DEMO_PASS}" | chpasswd
    usermod -aG sudo "${DEMO_USER}"
    echo "demo 用户已就绪 (密码: ${DEMO_PASS})。"
}

function install_python_packages() {
    echo ">>> [5/7] 安装 Python 依赖..."
    # 如果机器上 Python 指令是 python3，这里要改为 python3 / pip3
    # 这里假设系统中 “pip” 指向 Python3
    for pkg in "${PIP_PKG_LIST[@]}"; do
        pip show "$pkg" &>/dev/null || pip install "$pkg" -i https://pypi.tuna.tsinghua.edu.cn/simple
    done
    echo "Python 依赖安装完成。"
}

function init_airflow() {
    echo ">>> [6/7] 初始化 Airflow..."
    # 初始化数据库
    airflow db init || true

    # （可选）创建一个管理员账户，用于登录 Airflow Web UI
    # 如果重复执行，会提示已存在，故用 || true 忽略报错
    airflow users create \
        --username admin \
        --password admin \
        --firstname Admin \
        --lastname User \
        --role Admin \
        --email admin@example.com || true

    echo "Airflow 初始化完成。"
}

function start_airflow_services() {
    echo ">>> [7/7] 启动 Airflow Webserver 与 Scheduler..."

    # 先检查是否已经在运行 (pgrep -f "airflow webserver")
    if pgrep -f "airflow webserver" >/dev/null; then
        echo "检测到 Airflow webserver 已在运行，跳过启动。"
    else
        # 后台启动 Webserver
        nohup airflow webserver -p 8080 >/tmp/airflow_webserver.log 2>&1 &
        echo "Airflow webserver 已后台启动，日志在 /tmp/airflow_webserver.log"
    fi

    # Scheduler
    if pgrep -f "airflow scheduler" >/dev/null; then
        echo "检测到 Airflow scheduler 已在运行，跳过启动。"
    else
        nohup airflow scheduler >/tmp/airflow_scheduler.log 2>&1 &
        echo "Airflow scheduler 已后台启动，日志在 /tmp/airflow_scheduler.log"
    fi

    echo "Airflow 已成功启动，可访问 http://<当前主机IP>:8080"
}

####################################
#           主执行流程
####################################
check_root
configure_apt_source
install_sys_packages
setup_java
create_demo_user
install_python_packages
init_airflow
start_airflow_services
