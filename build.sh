#!/usr/bin/env bash

# 让脚本在出错时退出
set -e

# 可以根据需要设置一些默认版本
#SCALA_VERSION=2.12.10
#SPARK_VERSION=3.3.2
#HADOOP_VERSION=3
#JUPYTERLAB_VERSION=3.0.0
#SCALA_KERNEL_VERSION=0.10.9
#HADOOP_VERSION="3.2"
SCALA_VERSION="2.12.10"
SCALA_KERNEL_VERSION="0.10.9"
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
DEBIAN_TAG=8-jre-slim
# 构建 base 镜像 over
docker build \
  --build-arg debian_buster_image_tag=${DEBIAN_TAG} \
  --build-arg scala_version=${SCALA_VERSION} \
  --build-arg build_date=${BUILD_DATE} \
  -t base \
  -f Dockerfile.base .

JUPYTERLAB_VERSION="3.6.3"
SCALA_VERSION="2.12.10"
SCALA_KERNEL_VERSION="0.10.9"
SPARK_VERSION="3.3.2"
SHARED_WORKSPACE="workspace/"
# 构建 jupyter 镜像 over
docker build \
  --build-arg build_date=${BUILD_DATE} \
  --build-arg spark_version=${SPARK_VERSION} \
  --build-arg jupyterlab_version=${JUPYTERLAB_VERSION} \
  --build-arg scala_kernel_version=${SCALA_KERNEL_VERSION} \
  --build-arg scala_version=${SCALA_VERSION} \
  -t spark-cluster-jupyter \
  -f Dockerfile.jupyter .


SPARK_VERSION="3.3.2"
# 构建 spark-base 镜像（安装 Spark、打开事件日志、ps、vim）
docker build \
  --build-arg build_date=${BUILD_DATE} \
  --build-arg spark_version=${SPARK_VERSION} \
  -t spark-cluster-base \
  -f Dockerfile.spark-base .

# 构建 spark-master 镜像（同时启动 Master + History Server）
docker build \
  --build-arg build_date=${BUILD_DATE} \
  --build-arg spark_version=${SPARK_VERSION} \
  -t spark-cluster-master \
  -f Dockerfile.spark-master .

# 构建 spark-worker 镜像（不重定向日志）
docker build \
  --build-arg build_date=${BUILD_DATE} \
  --build-arg spark_version=${SPARK_VERSION} \
  -t spark-cluster-worker \
  -f Dockerfile.spark-worker .
