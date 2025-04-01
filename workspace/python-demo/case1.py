from pyspark.sql import SparkSession

spark = SparkSession.\
        builder.\
        appName("RandomWorkerJob").\
        master("spark://spark-master:7077").\
        config("spark.executor.memory", "512m").\
        getOrCreate()
rdd = spark.sparkContext.parallelize(range(1, 1001))
total = rdd.reduce(lambda a, b: a + b)
print(f"Total Sum = {total}")

spark.stop()
