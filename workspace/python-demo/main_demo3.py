# -*- coding: utf-8 -*-
import os
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, when
import webbrowser
import time

# 显式指定 PySpark 使用的 Python 路径
os.environ["PYSPARK_PYTHON"] = "C:/ProgramData/Anaconda3/python.exe"
os.environ["PYSPARK_DRIVER_PYTHON"] = "C:/ProgramData/Anaconda3/python.exe"

# 获取 CSV 文件绝对路径，避免路径错误
csv_input_path = os.path.abspath("./people.csv")
csv_output_path = os.path.abspath("./people_updated.csv")

# 启动 Spark，设置本地模式和 UI 端口
spark = SparkSession.builder \
    .appName("CSV_CURD") \
    .master("local[*]") \
    .config("spark.ui.port", "4050") \
    .getOrCreate()

# -----------------------------
# 读取 CSV 文件
# -----------------------------
# header=True 自动读取表头
# inferSchema=True 自动推断数据类型
df = spark.read.csv(csv_input_path, header=True, inferSchema=True)

print("原始数据：")
df.show()

# -----------------------------
# C = Create（新增数据）
# -----------------------------
# 构造新增 DataFrame，确保列名和数据类型匹配
new_data = [("David", 35), ("Eva", 22)]
new_df = spark.createDataFrame(new_data, schema=["name", "age"])

# 合并数据
df_created = df.unionByName(new_df)  # 使用 unionByName 更安全

print("新增数据后的结果：")
df_created.show()

# -----------------------------
# R = Read（查询数据）
# -----------------------------
print("查询年龄 > 25 的用户：")
df_created.filter(col("age") > 25).show()

# -----------------------------
# U = Update（修改数据）
# -----------------------------
# Spark 不支持原地 UPDATE，只能创建新列覆盖
df_updated = df_created.withColumn(
    "age",
    when(col("name") == "Bob", 40).otherwise(col("age"))
)

print("修改 Bob 年龄后的结果：")
df_updated.show()

# -----------------------------
# D = Delete（删除数据）
# -----------------------------
df_deleted = df_updated.filter(col("age") >= 30)

print("删除年龄 < 30 后的结果：")
df_deleted.show()

# -----------------------------
# 写回 CSV 文件
# -----------------------------
# 注意：overwrite 会清空已有目录，谨慎操作！
df_deleted.write.csv(csv_output_path, header=True, mode="overwrite")

webbrowser.open("http://localhost:4050")
try:
    while True:
        time.sleep(10)
except KeyboardInterrupt:
    print("检测到退出信号，正在关闭 Spark...")
    spark.stop()

print(f"数据写入 {csv_output_path} 成功")
# 停止 Spark
spark.stop()
