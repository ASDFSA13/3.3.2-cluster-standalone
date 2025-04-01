from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("MySQLReadJob") \
    .master("spark://spark-master:7077") \
    .config("spark.executor.cores", "1") \
    .config("spark.executor.memory", "512m") \
    .getOrCreate()

jdbc_url = "jdbc:mysql://rm-adadadasxcsacasysql.rds.aliyuncs.com:3306/erp_test2?useSSL=false"
table_name = "plm_product"
properties = {
    "user": "xaxsxsaxas",
    "password": "casxsaxasxas",
    "driver": "com.mysql.cj.jdbc.Driver"
}

# 读取MySQL表
df = spark.read.jdbc(url=jdbc_url, table=table_name, properties=properties)
df.show()

spark.stop()