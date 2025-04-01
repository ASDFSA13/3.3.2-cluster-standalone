from pyspark.sql import SparkSession
import os


os.environ["PYSPARK_PYTHON"] = "C:/ProgramData/Anaconda3/python.exe"
os.environ["PYSPARK_DRIVER_PYTHON"] = "C:/ProgramData/Anaconda3/python.exe"


with open("submit_output.log", "w") as f:
    f.write(">>> 脚本开始执行\n")

    spark = SparkSession.builder.appName("SubmitFix").master("local[*]").getOrCreate()
    f.write(">>> SparkSession 启动\n")

    df = spark.range(1, 4).toDF("num")
    rows = df.collect()
    for row in rows:
        f.write(str(row) + "\n")

    spark.stop()
    f.write(">>> Spark停止\n")
