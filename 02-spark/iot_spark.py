"""Procesamiento distribuido de lecturas IoT con PySpark.
Lee CSV desde Cloud Storage (equivalente a HDFS), agrega por región y día y detecta anomalías."""
import sys
from pyspark.sql import SparkSession, functions as F

entrada, salida = sys.argv[1], sys.argv[2]
spark = SparkSession.builder.appName("iot-agregacion").getOrCreate()
df = (spark.read.option("header", True).option("inferSchema", True).csv(entrada)
      .withColumn("dia", F.to_date("timestamp")))
print("Particiones de entrada:", df.rdd.getNumPartitions())

resumen = (df.groupBy("region", "dia")
           .agg(F.count("*").alias("lecturas"), F.round(F.avg("temperatura"), 2).alias("temp_media"),
                F.round(F.max("temperatura"), 2).alias("temp_max"), F.round(F.avg("humedad"), 1).alias("humedad_media")))
umbral = df.select((F.avg("temperatura") + 3 * F.stddev("temperatura")).alias("u")).first()["u"]
anomalias = df.filter(F.col("temperatura") > umbral)

resumen.write.mode("overwrite").partitionBy("region").parquet(f"{salida}/resumen_diario")
anomalias.write.mode("overwrite").option("header", True).csv(f"{salida}/anomalias")

print(f"Umbral de anomalía (media + 3σ): {umbral:.2f} °C")
print("Anomalías detectadas:", anomalias.count())
resumen.groupBy("region").agg(F.sum("lecturas").alias("lecturas"), F.round(F.avg("temp_media"), 2).alias("temp_media")) \
       .orderBy("region").show()
spark.stop()
