# RetailPulse-Capstone

End-to-end retail Big Data pipeline using Sqoop, HDFS, Hive, Flume, Kafka, Spark, and Metabase, with final deployment on AWS.

## Project Overview

RetailPulse is a Big Data pipeline for processing retail events and analyzing customer and transaction data.

The project uses different Big Data technologies for data ingestion, streaming, processing, storage, and visualization.

## Streaming Pipeline

The streaming part of the project uses a Python event generator, Apache Flume, and Apache Kafka.

```text
Python Event Generator
        ↓
JSON Event Files
        ↓
Apache Flume - SpoolDir Source
        ↓
Memory Channel
        ↓
Kafka Sink
        ↓
Kafka Topic: retailpulse-events
        ↓
AWS Processing Pipeline