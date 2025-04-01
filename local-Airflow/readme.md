chmod +x start-airflow.sh
chmod +x stop-airflow.sh


将上述内容分别保存为 start-airflow.sh 与 stop-airflow.sh，并赋予执行权限：
chmod +x start-airflow.sh
chmod +x stop-airflow.sh
启动 Airflow：

sudo ./start-airflow.sh
脚本会自动安装系统依赖、下载并解压 JDK 8、安装 Python 包并初始化 Airflow 数据库，然后在后台启动 Webserver 与 Scheduler。

启动成功后，可访问 http://<主机IP>:8080，使用 admin / admin 登录。

关闭 Airflow：

./stop-airflow.sh
脚本会自动检测运行中的 Webserver 和 Scheduler 进程，依次停止。