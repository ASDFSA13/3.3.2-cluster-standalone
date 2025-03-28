FROM apache/airflow:2.9.3

USER root

RUN apt-get update && \
    apt-get install -y openjdk-11-jdk ant && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64/
ENV PATH="$JAVA_HOME/bin:$PATH"

USER airflow

COPY ./requirements.txt /
RUN pip install -r /requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple

COPY --chown=airflow:root ./dags /opt/airflow/dags
