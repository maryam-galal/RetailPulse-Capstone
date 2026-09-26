from pyspark.sql import SparkSession
from pyspark.sql.types import (
    StructType,
    StructField,
    IntegerType,
    StringType,
    DecimalType
)
from pyspark.sql.functions import col, trim, lit

spark = SparkSession.builder \
    .appName("RetailPulse-Silver-Products") \
    .config("spark.ui.showConsoleProgress", "false") \
    .getOrCreate()

spark.sparkContext.setLogLevel("ERROR")

BRONZE_BASE = "/bronze/retail"
SILVER_BASE = "/silver/retail"
REJECTED_BASE = "/silver/rejected"

print("\n" + "=" * 60)
print("RETAILPULSE - SILVER LAYER - PRODUCTS")
print("=" * 60)

# ---------------------------------------------------------
# 1. Read Bronze
# ---------------------------------------------------------

print("\n[1] Reading Bronze: products")

products_schema = StructType([
    StructField("product_id", IntegerType(), False),
    StructField("sku", StringType(), False),
    StructField("product_name", StringType(), False),
    StructField("category", StringType(), False),
    StructField("unit_cost", DecimalType(18, 2), False),
    StructField("list_price", DecimalType(18, 2), False)
])

products_raw = spark.read \
    .option("header", "false") \
    .option("delimiter", ",") \
    .schema(products_schema) \
    .csv(BRONZE_BASE + "/products")

print("    Bronze records:", products_raw.count())


# ---------------------------------------------------------
# 2. Clean
# ---------------------------------------------------------

print("\n[2] Cleaning products")

products_clean = products_raw \
    .withColumn("sku", trim(col("sku"))) \
    .withColumn("product_name", trim(col("product_name"))) \
    .withColumn("category", trim(col("category"))) \
    .dropDuplicates()

print("    Records after cleaning:", products_clean.count())


# ---------------------------------------------------------
# 3. Validate
# ---------------------------------------------------------

print("\n[3] Data Quality Validation")

invalid_condition = (
    col("product_id").isNull() |
    col("sku").isNull() |
    (col("sku") == "") |
    col("product_name").isNull() |
    (col("product_name") == "") |
    col("category").isNull() |
    (col("category") == "") |
    col("unit_cost").isNull() |
    (col("unit_cost") < 0) |
    col("list_price").isNull() |
    (col("list_price") < 0)
)

products_rejected = products_clean \
    .filter(invalid_condition) \
    .withColumn(
        "reject_reason",
        lit("Missing or invalid required field")
    )

products_valid = products_clean.filter(~invalid_condition)

valid_count = products_valid.count()
rejected_count = products_rejected.count()

print("    Valid records:   ", valid_count)
print("    Rejected records:", rejected_count)


# ---------------------------------------------------------
# 4. Write Silver
# ---------------------------------------------------------

print("\n[4] Writing Silver")

products_valid.write \
    .mode("overwrite") \
    .parquet(SILVER_BASE + "/products")

print("    Silver path:")
print("    " + SILVER_BASE + "/products")


# ---------------------------------------------------------
# 5. Write rejected
# ---------------------------------------------------------

print("\n[5] Writing Rejected Records")

products_rejected.write \
    .mode("overwrite") \
    .parquet(REJECTED_BASE + "/products")

print("    Rejected path:")
print("    " + REJECTED_BASE + "/products")


# ---------------------------------------------------------
# 6. Sample
# ---------------------------------------------------------

print("\n[6] Silver Sample")

products_valid.show(5, truncate=False)

print("=" * 60)
print("PRODUCTS SILVER PROCESSING COMPLETED")
print("=" * 60)

spark.stop()
