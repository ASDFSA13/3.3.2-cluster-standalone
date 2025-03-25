#!/usr/bin/env bash

# 让脚本在出错时退出
set -e

# 可以根据需要设置一些默认版本
SCALA_VERSION=2.12.10
SPARK_VERSION=3.3.2
HADOOP_VERSION=3
JUPYTERLAB_VERSION=3.0.0
SCALA_KERNEL_VERSION=0.10.9
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
DEBIAN_TAG=8-jre-slim

# 构建 base 镜像
docker build \
  --build-arg debian_buster_image_tag=${DEBIAN_TAG} \
  --build-arg scala_version=${SCALA_VERSION} \
  --build-arg build_date=${BUILD_DATE} \
  -t base:latest \
  -f Dockerfile.base .

# 构建 jupyter 镜像
docker build \
  --build-arg build_date=${BUILD_DATE} \
  --build-arg spark_version=${SPARK_VERSION} \
  --build-arg jupyterlab_version=${JUPYTERLAB_VERSION} \
  --build-arg scala_kernel_version=${SCALA_KERNEL_VERSION} \
  --build-arg scala_version=${SCALA_VERSION} \
  -t spark-cluster-jupyter:latest \
  -f Dockerfile.jupyter .

# 构建 spark-base 镜像（安装 Spark、打开事件日志）
docker build \
  --build-arg build_date=${BUILD_DATE} \
  --build-arg spark_version=${SPARK_VERSION} \
  --build-arg hadoop_version=${HADOOP_VERSION} \
  -t spark-cluster-spark-base:latest \
  -f Dockerfile.spark-base .

# 构建 spark-master 镜像（同时启动 Master + History Server）
docker build \
  --build-arg build_date=${BUILD_DATE} \
  --build-arg spark_version=${SPARK_VERSION} \
  -t spark-cluster-spark-master:latest \
  -f Dockerfile.spark-master .

# 构建 spark-worker 镜像（不重定向日志）
docker build \
  --build-arg build_date=${BUILD_DATE} \
  --build-arg spark_version=${SPARK_VERSION} \
  -t spark-cluster-spark-worker:latest \
  -f Dockerfile.spark-worker .
