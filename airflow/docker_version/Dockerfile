FROM apache/airflow:2.9.3

USER root

RUN rm -f /etc/apt/sources.list.d/debian.sources && \
    echo "deb https://mirrors.aliyun.com/debian bookworm main contrib non-free" > /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian bookworm-updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian-security bookworm-security main contrib non-free" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y ant sudo wget curl tar && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


# 下载并安装 Adoptium JDK 8（Temurin）
ENV JAVA_VERSION=8u442-b06
ENV JAVA_URL=https://mirrors.tuna.tsinghua.edu.cn/Adoptium/8/jdk/x64/linux/OpenJDK8U-jdk_x64_linux_hotspot_8u442b06.tar.gz

RUN mkdir -p /opt/java && \
    curl -L ${JAVA_URL} | tar -xz -C /opt/java

ENV JAVA_HOME=/opt/java/jdk8u442-b06
ENV PATH="$PATH:$JAVA_HOME/bin"

RUN cp /opt/java/jdk8u442-b06/bin/java /usr/bin/java && \
    cp /opt/java/jdk8u442-b06/bin/javac /usr/bin/javac

#
#ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64/
#ENV PATH="$JAVA_HOME/bin:$PATH"

# 创建用户 demo，密码为123456
RUN useradd -ms /bin/bash demo && \
    echo "demo:123456" | chpasswd && \
    usermod -aG sudo demo

USER airflow

COPY ./requirements.txt /
RUN pip install -r /requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple

COPY --chown=airflow:root ./dags /opt/airflow/dags
