#!/usr/bin/env bash
set -e

function stop_airflow_services() {
    # 关闭 Airflow Webserver
    if pgrep -f "airflow webserver" > /dev/null; then
        echo "正在停止 Airflow webserver..."
        pkill -f "airflow webserver" || true
        echo "Airflow webserver 已停止。"
    else
        echo "Airflow webserver 未在运行，跳过。"
    fi

    # 关闭 Airflow Scheduler
    if pgrep -f "airflow scheduler" > /dev/null; then
        echo "正在停止 Airflow scheduler..."
        pkill -f "airflow scheduler" || true
        echo "Airflow scheduler 已停止。"
    else
        echo "Airflow scheduler 未在运行，跳过。"
    fi
}

echo ">>> 准备关闭 Airflow 所有进程..."
stop_airflow_services
echo ">>> Airflow 已全部停止。"
