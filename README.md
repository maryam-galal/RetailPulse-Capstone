# 🛍️ RetailPulse — Retail Analytics Data Engineering Platform

> **End-to-End Big Data Engineering Capstone | National Telecommunication Institute (NTI)**

RetailPulse is an end-to-end **Big Data Engineering platform** designed to build a scalable and reliable data pipeline for a regional retailer operating across physical stores and digital channels.

The platform integrates **batch and real-time data sources**, processes data through a **Medallion Architecture**, and prepares trusted datasets for analytics and business intelligence.

---

## 📌 Project Overview

RetailPulse handles data generated from multiple retail operations, including:

* 👥 Customers
* 📦 Products
* 🛒 Orders
* 🧾 Order Items
* 💳 Payments
* 📊 Inventory Snapshots
* 🏪 Stores
* 🚚 Fulfillment Events
* 🌐 Real-time Customer Events

The platform follows a **Bronze → Silver → Gold** architecture:

```text
                    ┌──────────────────────┐
                    │     Data Sources     │
                    └──────────┬───────────┘
                               │
              ┌────────────────┴────────────────┐
              │                                 │
       Batch Data                         Streaming Data
              │                                 │
        Sqoop / Files                         Flume
              │                                 │
              │                              Kafka
              │                                 │
              │                         Spark Streaming
              │                                 │
              └───────────────┬─────────────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │   🥉 BRONZE       │
                    │                   │
                    │ HDFS + Hive       │
                    │ Raw Data          │
                    └─────────┬─────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │   🥈 SILVER       │
                    │                   │
                    │ Spark             │
                    │ Cleaning &        │
                    │ Transformation    │
                    └─────────┬─────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │    🥇 GOLD        │
                    │                   │
                    │ Business-ready    │
                    │ Analytical Data   │
                    └─────────┬─────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │    Analytics      │
                    │                   │
                    │ Presto / Metabase │
                    └───────────────────┘
```

---

# 🎯 Project Objectives

The main objectives of RetailPulse are to:

* Build a scalable distributed data platform.
* Integrate batch and streaming data pipelines.
* Store raw data reliably in HDFS.
* Implement a Medallion Architecture.
* Process and transform large datasets using Apache Spark.
* Provide SQL access through Hive and Presto.
* Prepare analytical datasets for business intelligence.
* Support both historical and real-time retail analytics.

---

# 🏗️ Architecture

RetailPulse uses a distributed Big Data architecture built around the Hadoop ecosystem.

### Data Flow

```text
Relational Database
        │
        │ Batch Ingestion
        ▼
      Sqoop
        │
        ▼
     HDFS
        │
        ▼
   Bronze Layer
        │
        ▼
     Spark
        │
        ▼
   Silver Layer
        │
        ▼
     Spark
        │
        ▼
    Gold Layer
        │
        ▼
   Presto / Hive
        │
        ▼
    Metabase
```

For real-time events:

```text
Retail Applications
        │
        ▼
      Flume
        │
        ▼
      Kafka
        │
        ▼
Spark Structured Streaming
        │
        ▼
      HDFS
        │
        ▼
Bronze Streaming Layer
        │
        ▼
     Silver
        │
        ▼
      Gold
```

---

# 🥉 Bronze Layer

The Bronze layer stores raw data with minimal transformation while maintaining the original structure and information.

All Bronze datasets are organized under:

```text
/bronze/retail/
```

### Batch Data

```text
/bronze/retail/
├── customers/
├── products/
├── orders/
├── order_items/
├── payments/
├── inventory_snapshots/
├── fulfillment_events/
├── stores/
└── _watermarks/
```

### Streaming Data

Real-time events are stored separately:

```text
/bronze/retail/events/
└── ingestion_date=YYYY-MM-DD/
```

The streaming Bronze table preserves the original event payload together with Kafka metadata.

---

# 🗄️ Hive Data Organization

The project uses a centralized Hive database:

```text
retailpulse
```

### Bronze Tables

| Table                        | Description               |
| ---------------------------- | ------------------------- |
| `customers_bronze`           | Customer information      |
| `products_bronze`            | Product catalog           |
| `orders_bronze`              | Customer orders           |
| `order_items_bronze`         | Items belonging to orders |
| `payments_bronze`            | Payment transactions      |
| `inventory_snapshots_bronze` | Inventory snapshots       |
| `fulfillment_events_bronze`  | Order fulfillment events  |
| `stores_bronze`              | Store information         |
| `bronze_retail_events`       | Raw streaming events      |

The Hive tables are implemented as **external tables**, allowing Hive metadata to reference the underlying HDFS data without owning the physical files.

---

# ⚡ Real-Time Streaming Pipeline

RetailPulse supports real-time event ingestion using:

```text
Application Events
        ↓
      Flume
        ↓
      Kafka
        ↓
Spark Structured Streaming
        ↓
      HDFS
        ↓
Hive Bronze
```

Streaming events contain information such as:

```json
{
  "event_id": "...",
  "event_type": "checkout_started",
  "event_timestamp": "2026-09-24T12:25:05.246033+00:00",
  "customer_id": 7686,
  "session_id": "session-56581",
  "order_id": null,
  "product_id": 9276,
  "store_id": 48,
  "channel": "web",
  "sequence": 1
}
```

The Bronze layer preserves the raw JSON payload and Kafka metadata for downstream processing.

---

# 🔄 Data Processing

Apache Spark is used for distributed processing and transformation.

Typical Silver-layer operations include:

* Data cleansing
* Schema enforcement
* Null handling
* Duplicate removal
* Data type normalization
* Timestamp standardization
* Data quality validation
* Joining related datasets
* Business-rule transformations

The resulting Silver datasets provide cleaner and more structured data for analytical processing.

---

# 📊 Analytics Layer

The Gold layer is designed to provide business-ready datasets for retail analytics.

Potential analytical areas include:

### Sales Analytics

* Revenue
* Order volume
* Average order value
* Discounts
* Product performance

### Customer Analytics

* Customer activity
* Purchasing behavior
* Customer segmentation
* Digital engagement

### Inventory Analytics

* Stock levels
* Inventory movement
* Product availability
* Store-level inventory

### Store Analytics

* Store performance
* Regional sales
* Product demand by store

### Real-Time Analytics

* Customer sessions
* Checkout activity
* Product interactions
* Digital channel behavior

---

# 🛠️ Technology Stack

| Category         | Technologies                   |
| ---------------- | ------------------------------ |
| Cloud            | **AWS EC2**                    |
| Containerization | **Docker**                     |
| Storage          | **Hadoop HDFS**                |
| Batch Ingestion  | **Apache Sqoop**               |
| Streaming        | **Apache Flume, Apache Kafka** |
| Processing       | **Apache Spark**               |
| Data Warehouse   | **Apache Hive**                |
| SQL Query Engine | **Presto**                     |
| Visualization    | **Metabase**                   |
| Programming      | **Python, SQL, Bash**          |
| Architecture     | **Medallion Architecture**     |

---

# 📁 Project Structure

```text
RetailPulse/
│
├── generator/
│   └── generate_retailpulse_events.py
│
├── sqoop/
│   └── batch_ingestion/
│
├── flume/
│   └── flume.conf
│
├── kafka/
│   └── streaming_configuration/
│
├── spark/
│   ├── kafka_to_bronze.py
│   ├── silver/
│   └── gold/
│
├── hive/
│   ├── bronze/
│   ├── silver/
│   └── gold/
│
├── notebooks/
│   └── analysis/
│
├── dashboards/
│
└── README.md
```

---

# 🚀 Environment

The project runs inside a containerized Big Data environment deployed on AWS EC2.

The main services include:

```text
HDFS NameNode
HDFS DataNode
Hive Metastore
HiveServer2
Presto
Apache Spark
Apache Kafka
Apache Flume
Apache Sqoop
Metabase
```

Docker provides isolated and reproducible environments for the different components of the platform.

---

# 🔍 Example Hive Queries

Switch to the RetailPulse database:

```sql
USE retailpulse;
```

List available tables:

```sql
SHOW TABLES;
```

Check customer records:

```sql
SELECT *
FROM customers_bronze
LIMIT 10;
```

Count orders:

```sql
SELECT COUNT(*)
FROM orders_bronze;
```

Check streaming events:

```sql
SELECT *
FROM bronze_retail_events
LIMIT 10;
```

---

# 📈 Data Volume

The Bronze layer contains multiple large-scale retail datasets, including:

| Dataset             |   Records |
| ------------------- | --------: |
| Customers           |    40,000 |
| Products            |    10,001 |
| Orders              |   100,000 |
| Order Items         |   299,621 |
| Payments            |   100,000 |
| Inventory Snapshots |   100,000 |
| Fulfillment Events  |   300,000 |
| Stores              |        51 |
| Streaming Events    | Real-time |

---

# 👥 Team Responsibilities

The project was developed collaboratively, with responsibilities distributed across different components of the data platform.

### Data Engineering

* Data ingestion
* HDFS data organization
* Bronze layer implementation
* Hive table creation
* Streaming pipeline
* Spark processing
* Silver and Gold transformations
* Data validation
* Analytics integration

---

# 🎓 Learning Outcomes

Through this project, the team gained practical experience with:

* Distributed storage using **HDFS**
* Batch data ingestion
* Real-time streaming architectures
* Kafka producers and consumers
* Spark Structured Streaming
* Hive external tables
* SQL-based data exploration
* Medallion data architecture
* Dockerized Big Data environments
* AWS EC2 deployment
* Distributed data processing
* Data pipeline troubleshooting and monitoring

---

# 🔮 Future Improvements

Potential extensions include:

* Implement automated data quality checks.
* Add Airflow for pipeline orchestration.
* Introduce automated schema management.
* Add data lineage and monitoring.
* Implement incremental Silver/Gold processing.
* Expand the Metabase dashboard layer.
* Add pipeline alerting and failure recovery.
* Optimize Spark jobs and partitioning strategies.

---

# 👩‍💻 Project Context

**RetailPulse** was developed as part of the **National Telecommunication Institute (NTI) Big Data Engineering Track**, focusing on practical implementation of modern Big Data technologies and end-to-end data engineering workflows.

---

## ⭐ Key Technologies

```text
Hadoop | HDFS | Hive | Spark | Kafka | Flume | Sqoop
AWS EC2 | Docker | Presto | Metabase | Python | SQL
```
