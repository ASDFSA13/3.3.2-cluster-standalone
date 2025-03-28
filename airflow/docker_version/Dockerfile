FROM apache/airflow:2.9.3

USER root

RUN rm -f /etc/apt/sources.list.d/debian.sources && \
    echo "deb https://mirrors.aliyun.com/debian bookworm main contrib non-free" > /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian bookworm-updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian-security bookworm-security main contrib non-free" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y openjdk-17-jdk ant sudo wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64/
ENV PATH="$JAVA_HOME/bin:$PATH"

# 创建用户 demo，密码为123456
RUN useradd -ms /bin/bash demo && \
    echo "demo:123456" | chpasswd && \
    usermod -aG sudo demo

USER airflow

COPY ./requirements.txt /
RUN pip install -r /requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple

COPY --chown=airflow:root ./dags /opt/airflow/dags
