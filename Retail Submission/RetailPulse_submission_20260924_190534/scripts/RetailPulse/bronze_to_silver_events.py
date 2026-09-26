from pyspark.sql import SparkSession
from pyspark.sql.functions import col, from_json, to_timestamp, to_date
from pyspark.sql.types import StructType, StructField, StringType, LongType

BRONZE_PATH = "hdfs://namenode:8020/bronze/retail/events"
SILVER_PATH = "hdfs://namenode:8020/silver/retail/events"
QUARANTINE_PATH = "hdfs://namenode:8020/quarantine/retail/events"
CHECKPOINT_PATH = "hdfs://namenode:8020/checkpoints/retailpulse/bronze_to_silver_events"

spark = SparkSession.builder.appName("RetailPulse Bronze to Silver Events").getOrCreate()
spark.sparkContext.setLogLevel("WARN")

event_schema = StructType([
    StructField("event_id", StringType(), True),
    StructField("event_type", StringType(), True),
    StructField("event_timestamp", StringType(), True),
    StructField("customer_id", LongType(), True),
    StructField("session_id", StringType(), True),
    StructField("order_id", LongType(), True),
    StructField("product_id", LongType(), True),
    StructField("store_id", LongType(), True),
    StructField("channel", StringType(), True),
    StructField("sequence", LongType(), True)
])

bronze_schema = StructType([
    StructField("raw_payload", StringType(), True),
    StructField("kafka_topic", StringType(), True),
    StructField("kafka_partition", LongType(), True),
    StructField("kafka_offset", LongType(), True),
    StructField("kafka_timestamp", StringType(), True),
    StructField("ingestion_timestamp", StringType(), True)
])

bronze_df = spark.readStream     .format("csv")     .option("header", "true")     .option("quote", "\"")     .option("escape", "\"")     .schema(bronze_schema)     .load(BRONZE_PATH)

parsed_df = bronze_df.withColumn(
    "event",
    from_json(col("raw_payload"), event_schema)
)

valid_df = parsed_df.filter(
    col("event").isNotNull()
).select(
    col("event.event_id").alias("event_id"),
    col("event.event_type").alias("event_type"),
    to_timestamp(col("event.event_timestamp")).alias("event_timestamp"),
    col("event.customer_id").alias("customer_id"),
    col("event.session_id").alias("session_id"),
    col("event.order_id").alias("order_id"),
    col("event.product_id").alias("product_id"),
    col("event.store_id").alias("store_id"),
    col("event.channel").alias("channel"),
    col("event.sequence").alias("sequence"),
    col("kafka_topic"),
    col("kafka_partition"),
    col("kafka_offset"),
    col("raw_payload")
).withColumn(
    "event_date",
    to_date(col("event_timestamp"))
)

invalid_df = parsed_df.filter(
    col("event").isNull()
).select(
    col("raw_payload"),
    col("kafka_topic"),
    col("kafka_partition"),
    col("kafka_offset"),
    col("kafka_timestamp")
)

silver_query = valid_df.writeStream     .format("csv")     .outputMode("append")     .option("path", SILVER_PATH)     .option("checkpointLocation", CHECKPOINT_PATH + "/silver")     .option("header", "true")     .option("quote", "\"")     .option("escape", "\"")     .partitionBy("event_date")     .start()

quarantine_query = invalid_df.writeStream     .format("csv")     .outputMode("append")     .option("path", QUARANTINE_PATH)     .option("checkpointLocation", CHECKPOINT_PATH + "/quarantine")     .option("header", "true")     .option("quote", "\"")     .option("escape", "\"")     .start()

spark.streams.awaitAnyTermination()
