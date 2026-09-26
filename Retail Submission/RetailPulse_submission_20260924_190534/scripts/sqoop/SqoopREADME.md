# RetailPulse — Sqoop & Bronze Ingestion

## Overview

This directory contains the Sqoop ingestion scripts for the RetailPulse Capstone.

The Sqoop component is responsible for extracting relational data from the AWS RDS PostgreSQL database and loading it into the HDFS Bronze layer.

### Data Flow

```text
AWS RDS PostgreSQL
        │
        │ Sqoop
        ▼
HDFS Bronze
        │
        ▼
Hive Bronze Tables
        │
        ▼
Downstream Silver / Gold Processing
```

---

## Source Database

| Property | Value                                               |
| -------- | --------------------------------------------------- |
| Database | `NTI`                                               |
| Schema   | `capstone_retail`                                   |
| Host     | `nti-labs.cih6ce2ewr0r.us-east-1.rds.amazonaws.com` |
| Port     | `5432`                                              |
| Tool     | Apache Sqoop 1.4.7                                  |

Credentials are not stored in this repository.

The RDS connection uses SSL verification with the AWS RDS CA certificate.

---

## Source Tables

The following tables are ingested from PostgreSQL:

| Table                 | Primary Key             | Mappers |
| --------------------- | ----------------------- | ------: |
| `stores`              | `store_id`              |       1 |
| `products`            | `product_id`            |       2 |
| `customers`           | `customer_id`           |       2 |
| `orders`              | `order_id`              |       4 |
| `order_items`         | `order_item_id`         |       4 |
| `payments`            | `payment_id`            |       4 |
| `fulfillment_events`  | `fulfillment_event_id`  |       4 |
| `inventory_snapshots` | `inventory_snapshot_id` |       4 |

Mapper counts were selected based on table size and expected parallelism.

---

## Bronze HDFS Location

All Sqoop data is stored under:

```text
/bronze/retail/
```

Structure:

```text
/bronze/retail/
├── stores/
├── products/
├── customers/
├── orders/
├── order_items/
├── payments/
├── fulfillment_events/
├── inventory_snapshots/
└── _watermarks/
    └── watermarks.csv
```

The Bronze data is stored as **CSV/TEXTFILE**.

---

## Full Ingestion

The full ingestion script is:

```text
full_imports.sh
```

It imports all eight PostgreSQL tables into the corresponding HDFS Bronze directories.

Example:

```bash
./full_imports.sh
```

The script requires the Sqoop environment and PostgreSQL credentials to be available.

The password is entered interactively using:

```bash
-P
```

No database password is stored in the script.

---

## Incremental Ingestion

Incremental ingestion strategy:

| Table                 | Method         | Check Column |
| --------------------- | -------------- | ------------ |
| `stores`              | `append`       | `store_id`   |
| `products`            | `lastmodified` | `updated_at` |
| `customers`           | `lastmodified` | `updated_at` |
| `orders`              | `lastmodified` | `updated_at` |
| `order_items`         | `lastmodified` | `updated_at` |
| `payments`            | `lastmodified` | `updated_at` |
| `fulfillment_events`  | `lastmodified` | `updated_at` |
| `inventory_snapshots` | `lastmodified` | `updated_at` |

### Stores

`stores` does not have an `updated_at` column, so new records are detected using the primary key:

```text
--incremental append
--check-column store_id
```

This detects newly inserted stores but does not detect updates to existing stores.

### Other tables

Tables containing `updated_at` use:

```text
--incremental lastmodified
```

This allows newly inserted and modified records to be ingested.

Because the Bronze layer uses `--append`, an updated record can appear as a new version in Bronze. Downstream Silver processing should handle deduplication/current-state logic.

---

## Watermarks

Incremental ingestion watermarks are maintained in:

```text
/bronze/retail/_watermarks/watermarks.csv
```

Format:

```csv
table_name,watermark_column,watermark_value
stores,store_id,51
products,updated_at,2026-09-23 13:30:00
customers,updated_at,2026-07-28 07:51:00
orders,updated_at,2026-10-05 20:02:00
order_items,updated_at,2026-10-05 18:40:00
payments,updated_at,2026-10-05 18:40:00
fulfillment_events,updated_at,2026-10-08 06:40:00
inventory_snapshots,updated_at,2026-01-10 00:00:00
```

---

## Initial Source Row Counts

| Table                 |    Rows |
| --------------------- | ------: |
| `stores`              |      50 |
| `products`            |  10,000 |
| `customers`           |  40,000 |
| `orders`              | 100,000 |
| `order_items`         | 299,621 |
| `payments`            | 100,000 |
| `fulfillment_events`  | 300,000 |
| `inventory_snapshots` | 100,000 |

After the incremental demonstrations:

| Table                 | Bronze Rows |
| --------------------- | ----------: |
| `stores`              |          51 |
| `products`            |      10,001 |
| `customers`           |      40,000 |
| `orders`              |     100,000 |
| `order_items`         |     299,621 |
| `payments`            |     100,000 |
| `fulfillment_events`  |     300,000 |
| `inventory_snapshots` |     100,000 |

The `products` count is 10,001 because one modified product was appended as a new Bronze version.

---

## Bronze Validation

To check Bronze row counts:

```bash
for table in stores products customers orders order_items payments fulfillment_events inventory_snapshots; do
    echo -n "$table: "
    hdfs dfs -cat /bronze/retail/$table/part-* 2>/dev/null | wc -l
done
```

To inspect a specific table:

```bash
hdfs dfs -ls /bronze/retail/products
```

To view the actual records:

```bash
hdfs dfs -cat /bronze/retail/products/part-* | head
```

---

## Hive Bronze Layer

Hive external tables are created over the HDFS Bronze directories.

Example:

```sql
CREATE EXTERNAL TABLE stores_bronze (
    store_id INT,
    store_name STRING,
    city STRING,
    country_code STRING,
    opened_at DATE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/bronze/retail/stores';
```

The same approach is used for the other source tables.

---

## Important Notes

* Bronze data is stored as CSV/TEXTFILE.
* No Parquet files are used in this Bronze implementation.
* HDFS contains the actual ingested data.
* Hive provides SQL access to the Bronze data through external tables.
* Incremental ingestion can create multiple versions of modified records.
* Downstream Silver processing is responsible for deduplication/current-state logic.
* Database credentials must never be committed to Git.
* RDS certificates and other secrets are excluded from the repository.
* Docker runtime data under `base/` is not part of the Sqoop deliverable.

---

## Useful Commands

### Enter Sqoop container

```bash
docker exec -it 06-01-sqoop bash
```

### Enter Hive

```bash
docker exec -it 02-03-hive-server bash
hive
```

### List Bronze directories

```bash
hdfs dfs -ls /bronze/retail/
```

### List files for a table

```bash
hdfs dfs -ls /bronze/retail/products
```

### Preview records

```bash
hdfs dfs -cat /bronze/retail/products/part-* | head
```

### Check a table's row count

```bash
hdfs dfs -cat /bronze/retail/products/part-* | wc -l
```

---

## Ownership

**Sqoop / Bronze responsibility**

* PostgreSQL connectivity
* Full ingestion
* Incremental ingestion
* Mapper configuration
* HDFS Bronze organization
* Row-count validation
* Watermark management
* Hive Bronze external tables

Downstream Flume, Kafka, Spark Silver/Gold, and visualization components are handled by their respective project owners.
