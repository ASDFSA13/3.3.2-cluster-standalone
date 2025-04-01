from pyspark.sql import SparkSession

spark = SparkSession.\
        builder.\
        appName("pyspark-notebook").\
        master("spark://spark-master:7077").\
        config("spark.executor.memory", "512m").\
        getOrCreate()



data = spark.read.csv(path="/opt/workspace/data/uk-macroeconomic-data.csv", sep=",", header=True)

data.count()

len(data.columns)
data.printSchema()

unemployment = data.select(["Description", "Population (GB+NI)", "Unemployment rate"])
unemployment.show(n=10)

cols_description = unemployment.filter(unemployment['Description'] == 'Units')
cols_description.show()

unemployment = unemployment.join(other=cols_description, on=['Description'], how='left_anti')
unemployment.show(n=10)
unemployment = unemployment.dropna()
unemployment = unemployment.\
               withColumnRenamed("Description", 'year').\
               withColumnRenamed("Population (GB+NI)", "population").\
               withColumnRenamed("Unemployment rate", "unemployment_rate")

unemployment.show(n=10)
unemployment.repartition(1).write.csv(path="/opt/workspace/data/uk-macroeconomic-unemployment-data.csv", sep=",", header=True, mode="overwrite")