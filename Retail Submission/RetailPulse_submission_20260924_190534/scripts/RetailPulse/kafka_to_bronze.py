from pyspark.sql import SparkSession
from pyspark.sql.functions import current_timestamp, to_date, col


# ============================================================
# RetailPulse - Kafka to Bronze
# ============================================================

KAFKA_BOOTSTRAP_SERVERS = "kafka:9092"
KAFKA_TOPIC = "retailpulse-events"

BRONZE_PATH = "hdfs://namenode:8020/bronze/retail/events"

CHECKPOINT_PATH = (
    "hdfs://namenode:8020/checkpoints/retailpulse/kafka_to_bronze"
)


# ============================================================
# 1. Create Spark Session
# ============================================================

spark = SparkSession.builder \
    .appName("RetailPulse Kafka to Bronze") \
    .getOrCreate()

spark.sparkContext.setLogLevel("WARN")


# ============================================================
# 2. Read Events from Kafka
# ============================================================

kafka_df = spark.readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", KAFKA_BOOTSTRAP_SERVERS) \
    .option("subscribe", KAFKA_TOPIC) \
    .option("startingOffsets", "earliest") \
    .load()


# ============================================================
# 3. Create Bronze DataFrame
# ============================================================
#
# Bronze preserves the original Kafka event exactly as received.
#
# raw_payload:
#   Original JSON event
#
# kafka_topic:
#   Kafka topic name
#
# kafka_partition:
#   Kafka partition
#
# kafka_offset:
#   Kafka offset
#
# kafka_timestamp:
#   Timestamp assigned by Kafka
#
# ingestion_timestamp:
#   Timestamp when Spark processes the record
#
# ingestion_date:
#   Used to partition Bronze data by ingestion date
# ============================================================

bronze_df = kafka_df.select(
    col("value").cast("string").alias("raw_payload"),
    col("topic").alias("kafka_topic"),
    col("partition").alias("kafka_partition"),
    col("offset").alias("kafka_offset"),
    col("timestamp").alias("kafka_timestamp"),
    current_timestamp().alias("ingestion_timestamp")
)


# ============================================================
# 4. Add Ingestion Date
# ============================================================

bronze_df = bronze_df.withColumn(
    "ingestion_date",
    to_date(col("ingestion_timestamp"))
)


# ============================================================
# 5. Write Bronze Data to HDFS
# ============================================================
#
# Format:
#   CSV
#
# Mode:
#   Append
#
# Partition:
#   ingestion_date
#
# Checkpoint:
#   Allows Spark to remember which Kafka offsets
#   have already been processed.
# ============================================================

query = bronze_df.writeStream \
    .format("csv") \
    .outputMode("append") \
    .option("path", BRONZE_PATH) \
    .option("checkpointLocation", CHECKPOINT_PATH) \
    .option("header", "true") \
    .option("quote", '"') \
    .option("escape", '"') \
    .partitionBy("ingestion_date") \
    .start()


# ============================================================
# 6. Keep Streaming Job Running
# ============================================================

query.awaitTermination()
