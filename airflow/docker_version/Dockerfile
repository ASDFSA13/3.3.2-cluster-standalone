FROM apache/airflow:2.9.3

USER airflow

RUN pip install --no-cache-dir -i https://pypi.tuna.tsinghua.edu.cn/simple \
    apache-airflow-providers-apache-spark==5.0.1 \
    pyspark>=3.1.3 \
    grpcio-status>=1.59.0
