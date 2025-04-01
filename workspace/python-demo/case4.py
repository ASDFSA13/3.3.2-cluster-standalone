from pyspark.sql import SparkSession

# 创建 SparkSession，配置资源
spark = SparkSession.builder \
    .appName("MySQLToHDFSJob") \
    .master("spark://192.168.116.129:7077") \
    .config("spark.executor.cores", "1") \
    .config("spark.executor.memory", "512m") \
    .getOrCreate()

# 1. 读取 MySQL 表数据
jdbc_url = "jdbc:mysql://rm-adadada4adadaadada.mysql.rds.aliyuncs.com:3306/erp_test2?useSSL=false"
table_name = "cacacascaxas"
properties = {
    "user": "cacsacascsa",
    "password": "dadadadfsadas",
    "driver": "com.mysql.cj.jdbc.Driver"
}


# 读取 MySQL 表
df = spark.read.jdbc(url=jdbc_url, table=table_name, properties=properties)

# 显示部分数据
df.show()

# 2. 写入 HDFS 的 /test 目录为 CSV
hdfs_output_path = "hdfs://172.17.0.1:9009/test/plm_product.csv"

# 写入 CSV 文件到 HDFS（可加 coalesce 合并分区）
df.coalesce(1).write \
    .option("header", "true") \
    .mode("overwrite") \
    .csv(hdfs_output_path)

print(f"MySQL 数据已写入 HDFS: {hdfs_output_path}")

spark.stop()
