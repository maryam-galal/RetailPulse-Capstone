#!/bin/bash

SQOOP="sqoop"
CONNECT="jdbc:postgresql://nti-labs.cih6ce2ewr0r.us-east-1.rds.amazonaws.com:5432/NTI?currentSchema=capstone_retail&sslmode=verify-full&sslrootcert=/opt/sqoop-work/global-bundle.pem"
USER="postgres"

# Stores
$SQOOP import \
--connect "$CONNECT" \
--username "$USER" \
-P \
--table stores \
--target-dir /bronze/retail/stores \
--split-by store_id \
--num-mappers 1 \
--as-textfile \
--fields-terminated-by ',' \
--lines-terminated-by '\n'

# Products
$SQOOP import \
--connect "$CONNECT" \
--username "$USER" \
-P \
--table products \
--target-dir /bronze/retail/products \
--split-by product_id \
--num-mappers 2 \
--as-textfile \
--fields-terminated-by ',' \
--lines-terminated-by '\n'

# Customers
$SQOOP import \
--connect "$CONNECT" \
--username "$USER" \
-P \
--table customers \
--target-dir /bronze/retail/customers \
--split-by customer_id \
--num-mappers 2 \
--as-textfile \
--fields-terminated-by ',' \
--lines-terminated-by '\n'

# Orders
$SQOOP import \
--connect "$CONNECT" \
--username "$USER" \
-P \
--table orders \
--target-dir /bronze/retail/orders \
--split-by order_id \
--num-mappers 4 \
--as-textfile \
--fields-terminated-by ',' \
--lines-terminated-by '\n'

# Order Items
$SQOOP import \
--connect "$CONNECT" \
--username "$USER" \
-P \
--table order_items \
--target-dir /bronze/retail/order_items \
--split-by order_item_id \
--num-mappers 4 \
--as-textfile \
--fields-terminated-by ',' \
--lines-terminated-by '\n'

# Payments
$SQOOP import \
--connect "$CONNECT" \
--username "$USER" \
-P \
--table payments \
--target-dir /bronze/retail/payments \
--split-by payment_id \
--num-mappers 4 \
--as-textfile \
--fields-terminated-by ',' \
--lines-terminated-by '\n'

# Fulfillment Events
$SQOOP import \
--connect "$CONNECT" \
--username "$USER" \
-P \
--table fulfillment_events \
--target-dir /bronze/retail/fulfillment_events \
--split-by fulfillment_event_id \
--num-mappers 4 \
--as-textfile \
--fields-terminated-by ',' \
--lines-terminated-by '\n'

# Inventory Snapshots
$SQOOP import \
--connect "$CONNECT" \
--username "$USER" \
-P \
--table inventory_snapshots \
--target-dir /bronze/retail/inventory_snapshots \
--split-by inventory_snapshot_id \
--num-mappers 4 \
--as-textfile \
--fields-terminated-by ',' \
--lines-terminated-by '\n'
