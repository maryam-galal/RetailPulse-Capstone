# RetailPulse — EC2 / Hive / HDFS / Docker Commands

This file contains the terminal commands used during the RetailPulse Capstone work.

It does not contain the SQL used to create/populate the Gold tables. Those are documented separately.

---

# 1. Connect to EC2

## SSH from Windows PowerShell

```powershell
ssh -i "D:\NTI\BigData\UseCase\nti-vm.pem" ec2-user@34.229.240.0
```

## EC2 prompt

```text
ec2-user@ip-172-31-42-52
```

---

# 2. Check Running Docker Containers

```bash
docker ps
```

Used to verify containers such as:

```text
metabase
02-03-hive-server
```

## Check all containers

```bash
docker ps -a
```

---

# 3. Inspect Docker Containers

## Inspect Metabase container

```bash
docker inspect metabase
```

## Check Metabase volume mounts

```bash
docker inspect metabase --format '{{range .Mounts}}{{.Type}} {{.Source}} -> {{.Destination}}{{println}}'
```

---

# 4. Docker Networks

## List Docker networks

```bash
docker network ls
```

## Inspect a Docker network

```bash
docker network inspect docker-bigdata-tools_net
```

> The network name can change depending on the Docker Compose project/container setup, so it should be checked with `docker network ls` rather than assumed.

---

# 5. Start / Stop / Restart Containers

## Restart a container

```bash
docker restart metabase
```

## Restart Hive Server

```bash
docker restart 02-03-hive-server
```

## Stop a container

```bash
docker stop metabase
```

## Start a container

```bash
docker start metabase
```

---

# 6. Metabase Container

## Create Metabase container

The initial standalone Metabase container was created with:

```bash
docker run -d \
  --name metabase \
  --network docker-bigdata-tools_net \
  -p 3000:3000 \
  metabase/metabase:latest
```

## Check Metabase logs

```bash
docker logs metabase
```

## Follow Metabase logs

```bash
docker logs -f metabase
```

---

# 7. Enter the Hive Server Container

```bash
docker exec -it 02-03-hive-server bash
```

## Run a command inside Hive Server without opening an interactive shell

Example:

```bash
docker exec 02-03-hive-server bash -c "hdfs dfs -ls /user/hive/warehouse/retailpulse.db"
```

---

# 8. Hive

## Open Hive CLI

Inside the Hive Server container:

```bash
hive
```

## Show databases

```sql
SHOW DATABASES;
```

## Use RetailPulse database

```sql
USE retailpulse;
```

## Show tables

```sql
SHOW TABLES;
```

## Show tables specifically from RetailPulse

```sql
SHOW TABLES IN retailpulse;
```

Expected Gold tables included:

```text
data_quality_gold
digital_funnel_gold
dim_customer_gold
dim_date_gold
dim_product_gold
dim_store_gold
fact_fulfillment_gold
fact_orders_gold
inventory_risk_gold
```

---

# 9. Hive Table Inspection

## Describe a table

```sql
DESCRIBE retailpulse.dim_customer_gold;
```

```sql
DESCRIBE retailpulse.dim_product_gold;
```

```sql
DESCRIBE retailpulse.dim_store_gold;
```

```sql
DESCRIBE retailpulse.dim_date_gold;
```

```sql
DESCRIBE retailpulse.fact_orders_gold;
```

```sql
DESCRIBE retailpulse.fact_fulfillment_gold;
```

```sql
DESCRIBE retailpulse.inventory_risk_gold;
```

```sql
DESCRIBE retailpulse.digital_funnel_gold;
```

```sql
DESCRIBE retailpulse.data_quality_gold;
```

---

# 10. Hive Table Row Counts

The Gold tables were checked using `COUNT(*)` statements from the Hive terminal.

```sql
SELECT COUNT(*) FROM retailpulse.dim_customer_gold;
```

```sql
SELECT COUNT(*) FROM retailpulse.dim_product_gold;
```

```sql
SELECT COUNT(*) FROM retailpulse.dim_store_gold;
```

```sql
SELECT COUNT(*) FROM retailpulse.dim_date_gold;
```

```sql
SELECT COUNT(*) FROM retailpulse.fact_orders_gold;
```

```sql
SELECT COUNT(*) FROM retailpulse.fact_fulfillment_gold;
```

```sql
SELECT COUNT(*) FROM retailpulse.inventory_risk_gold;
```

```sql
SELECT COUNT(*) FROM retailpulse.digital_funnel_gold;
```

```sql
SELECT COUNT(*) FROM retailpulse.data_quality_gold;
```

---

# 11. Hive Validation

## Check customer Gold table

```sql
SELECT
    COUNT(*) AS total_records,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS missing_customer_id,
    SUM(CASE WHEN signup_at IS NULL THEN 1 ELSE 0 END) AS missing_signup_at,
    SUM(CASE WHEN updated_at IS NULL THEN 1 ELSE 0 END) AS missing_updated_at
FROM retailpulse.dim_customer_gold;
```

The result was:

```text
40000  0  0  0
```

---

# 12. Validate Fact Orders

The fact table was checked against the Silver order-items count.

```sql
SELECT COUNT(*) FROM retailpulse.order_items_silver;
```

```sql
SELECT COUNT(*) FROM retailpulse.fact_orders_gold;
```

The Gold fact contained:

```text
298755
```

rows.

Null foreign-key / date validation was also performed on:

```text
customer_key
product_key
store_key
date_key
order_timestamp
```

---

# 13. Validate Fulfillment

## Check fulfillment row count

```sql
SELECT COUNT(*) FROM retailpulse.fulfillment_events_silver;
```

```sql
SELECT COUNT(*) FROM retailpulse.fact_fulfillment_gold;
```

Both contained:

```text
300000
```

records.

## Check fulfillment event types

```sql
SELECT event_type, COUNT(*)
FROM retailpulse.fulfillment_events_silver
GROUP BY event_type;
```

The event types were:

```text
delivered
packed
shipped
```

with:

```text
100000
```

records for each event type.

---

# 14. Fulfillment SLA Fix

The fulfillment Gold table was updated so that the SLA was 48 hours and late deliveries were calculated from delivery duration.

```sql
INSERT OVERWRITE TABLE retailpulse.fact_fulfillment_gold
SELECT
    fulfillment_key,
    order_id,
    customer_key,
    store_key,
    date_key,
    warehouse_code,
    fulfillment_status,
    event_type,
    event_timestamp,
    shipped_at,
    delivered_at,
    delivery_duration_hours,
    48 AS sla_hours,
    CASE
        WHEN delivery_duration_hours > 48 THEN true
        ELSE false
    END AS is_late
FROM retailpulse.fact_fulfillment_gold;
```

---

# 15. Validate Fulfillment SLA

The resulting fulfillment table was checked for:

```text
total records
delivered records
records with SLA
records with NULL SLA
records with is_late
```

The final validation showed:

```text
300000  300000  300000  0  300000
```

---

# 16. Check Fulfillment SLA Distribution

```sql
SELECT
    sla_hours,
    is_late,
    COUNT(*)
FROM retailpulse.fact_fulfillment_gold
GROUP BY sla_hours, is_late;
```

Final result:

```text
48    false    300000
```

---

# 17. Check Fulfillment Status

```sql
SELECT
    fulfillment_status,
    COUNT(*)
FROM retailpulse.fact_fulfillment_gold
GROUP BY fulfillment_status;
```

The statuses observed were:

```text
cancelled
completed
shipped
```

---

# 18. Inventory Risk Validation

## Check inventory Gold count

```sql
SELECT COUNT(*)
FROM retailpulse.inventory_risk_gold;
```

Result:

```text
100000
```

## Check inventory risk distribution

```sql
SELECT
    inventory_risk,
    COUNT(*)
FROM retailpulse.inventory_risk_gold
GROUP BY inventory_risk;
```

Observed classifications:

```text
NORMAL
LOW_STOCK
OUT_OF_STOCK
```

Final distribution:

```text
NORMAL          64374
OUT_OF_STOCK    33414
LOW_STOCK        2212
```

---

# 19. Digital Funnel Validation

## Check event types in Bronze

```sql
SELECT
    event_type,
    COUNT(*)
FROM retailpulse.bronze_retail_events
GROUP BY event_type;
```

Observed:

```text
NULL                  296
cart_updated         5881
checkout_started     3646
fulfillment_update   2299
order_confirmed      2829
product_viewed      15049
```

---

# 20. Digital Funnel Validation

The Digital Funnel Gold table was checked with:

```sql
SELECT *
FROM retailpulse.digital_funnel_gold;
```

The dashboard query excludes malformed/null event rows with:

```sql
WHERE event_date IS NOT NULL
  AND channel IS NOT NULL
```

---

# 21. Data Quality Validation

The Data Quality Gold table was checked with:

```sql
SELECT *
FROM retailpulse.data_quality_gold;
```

The final table contained eight Silver sources:

```text
customers_silver
products_silver
stores_silver
orders_silver
order_items_silver
payments_silver
fulfillment_events_silver
inventory_snapshots_silver
```

All eight were marked:

```text
PASS
```

---

# 22. Check Silver Table Counts

```sql
SELECT COUNT(*) FROM retailpulse.customers_silver;
```

```sql
SELECT COUNT(*) FROM retailpulse.products_silver;
```

```sql
SELECT COUNT(*) FROM retailpulse.stores_silver;
```

```sql
SELECT COUNT(*) FROM retailpulse.orders_silver;
```

```sql
SELECT COUNT(*) FROM retailpulse.order_items_silver;
```

```sql
SELECT COUNT(*) FROM retailpulse.payments_silver;
```

```sql
SELECT COUNT(*) FROM retailpulse.fulfillment_events_silver;
```

```sql
SELECT COUNT(*) FROM retailpulse.inventory_snapshots_silver;
```

---

# 23. Check HDFS Gold Tables

From the EC2 terminal:

```bash
docker exec 02-03-hive-server bash -c "hdfs dfs -ls /user/hive/warehouse/retailpulse.db"
```

This verified the Gold table directories stored in HDFS.

Expected Gold directories:

```text
data_quality_gold
digital_funnel_gold
dim_customer_gold
dim_date_gold
dim_product_gold
dim_store_gold
fact_fulfillment_gold
fact_orders_gold
inventory_risk_gold
```

---

# 24. HDFS Warehouse Check

Inside the Hive Server container, the RetailPulse warehouse directory was checked using:

```bash
hdfs dfs -ls /user/hive/warehouse/retailpulse.db
```

---

# 25. Check HDFS Contents

For an individual table directory:

```bash
hdfs dfs -ls /user/hive/warehouse/retailpulse.db/<table_name>
```

Example:

```bash
hdfs dfs -ls /user/hive/warehouse/retailpulse.db/fact_orders_gold
```

---

# 26. Docker Compose Project

The Big Data Docker project was located under:

```bash
cd ~/Docker-BigData-Tools
```

## List project files

```bash
ls
```

## List project contents recursively

```bash
find . -maxdepth 2 -type f
```

---

# 27. RetailPulse Project

The Capstone project directory was:

```bash
cd ~/Capstone_RetailPulse
```

## List files

```bash
ls
```

## Check Spark scripts

```bash
ls ~/Capstone_RetailPulse/spark
```

---

# 28. RetailPulse GitHub Directory

```bash
cd ~/RetailPulse-GitHub
```

## List files

```bash
ls
```

## Check Git status

```bash
git status
```

---

# 29. Check Git Repository

```bash
cd ~/RetailPulse-GitHub
git status
```

---

# 30. Sqoop Script

The Sqoop import script was located at:

```text
~/RetailPulse-GitHub/sqoop/full_imports.sh
```

## Enter Sqoop directory

```bash
cd ~/RetailPulse-GitHub/sqoop
```

## List files

```bash
ls
```

## Make script executable

```bash
chmod +x full_imports.sh
```

## Run the Sqoop import script

```bash
./full_imports.sh
```

The script prompts for the PostgreSQL password because the imports use:

```text
-P
```

---

# 31. Check Sqoop Script

```bash
cat ~/RetailPulse-GitHub/sqoop/full_imports.sh
```

---

# 32. Spark Scripts

Spark scripts were located under:

```text
~/Capstone_RetailPulse/spark
```

Files included:

```text
bronze_events_backfill.py
check_kafka.py
kafka_to_bronze.py
silver_batch.py
silver_customers.py
silver_fulfillment_events.py
silver_inventory_snapshots.py
silver_order_items.py
silver_orders.py
silver_payments.py
silver_products.py
silver_stores.py
```

## List Spark files

```bash
ls ~/Capstone_RetailPulse/spark
```

---

# 33. Docker Container Logs

## Hive Server logs

```bash
docker logs 02-03-hive-server
```

## Metabase logs

```bash
docker logs metabase
```

## Follow logs

```bash
docker logs -f 02-03-hive-server
```

```bash
docker logs -f metabase
```

---

# 34. Docker Images

## List Docker images

```bash
docker images
```

## Find the Metabase backup image

```bash
docker images | grep retailpulse-metabase-backup
```

---

# 35. Metabase Backup

A Docker image backup was created after configuring Metabase.

## Create Docker image from Metabase container

```bash
docker commit metabase retailpulse-metabase-backup
```

## Verify backup image

```bash
docker images | grep retailpulse-metabase-backup
```

## Save image to a TAR file

```bash
docker save -o ~/retailpulse-metabase-backup.tar retailpulse-metabase-backup:latest
```

## Check backup file

```bash
ls -lh ~/retailpulse-metabase-backup.tar
```

Backup location:

```text
/home/ec2-user/retailpulse-metabase-backup.tar
```

---

# 36. Check EC2 Home Directory

```bash
ls ~
```

Relevant project files/directories included:

```text
Capstone_RetailPulse/
Docker-BigData-Tools/
RetailPulse-GitHub/
retailpulse-metabase-backup.tar
```

---

# 37. Windows → EC2 / EC2 → Windows File Transfer

## Download the RetailPulse project from EC2

From Windows PowerShell:

```powershell
scp -i "D:\NTI\BigData\UseCase\nti-vm.pem" -r ec2-user@34.229.240.0:/home/ec2-user/Capstone_RetailPulse "D:\NTI\BigData\UseCase\RetailPulse\"
```

---

# 38. Download Metabase Backup

From Windows PowerShell:

```powershell
scp -i "D:\NTI\BigData\UseCase\nti-vm.pem" ec2-user@34.229.240.0:/home/ec2-user/retailpulse-metabase-backup.tar "D:\NTI\BigData\UseCase\RetailPulse\"
```

---

# 39. SSH Key Permissions on Windows

The EC2 key file:

```text
D:\NTI\BigData\UseCase\nti-vm.pem
```

was secured with:

```powershell
icacls "D:\NTI\BigData\UseCase\nti-vm.pem" /inheritance:r
```

Then access was granted to the Windows user:

```powershell
icacls "D:\NTI\BigData\UseCase\nti-vm.pem" /grant "rawan:R"
```

---

# 40. Verify Local Project Directory

From Windows PowerShell:

```powershell
cd "D:\NTI\BigData\UseCase"
```

```powershell
dir
```

The local project directory:

```text
D:\NTI\BigData\UseCase\RetailPulse
```

---

# 41. Check Current Windows Directory

```powershell
pwd
```

---

# 42. Docker Container Status After Restart

After restarting the project containers:

```bash
docker ps
```

was used to verify that the required containers were running.

---

# 43. Hive Query Execution

Hive commands were executed from:

```bash
docker exec -it 02-03-hive-server bash
```

followed by:

```bash
hive
```

Then database/table commands were executed from the Hive prompt.

To leave Hive:

```sql
exit;
```

To leave the container shell:

```bash
exit
```

---

# 44. EC2 Shell Navigation

Useful navigation commands used during the project:

```bash
pwd
```

```bash
ls
```

```bash
cd ~
```

```bash
cd ~/Capstone_RetailPulse
```

```bash
cd ~/RetailPulse-GitHub
```

```bash
cd ~/Docker-BigData-Tools
```

```bash
cd ~/RetailPulse-GitHub/sqoop
```

---

# 45. File Inspection

## Display a file

```bash
cat <filename>
```

Example:

```bash
cat ~/RetailPulse-GitHub/sqoop/full_imports.sh
```

## List file details

```bash
ls -lh
```

## List a specific file

```bash
ls -lh ~/retailpulse-metabase-backup.tar
```

---