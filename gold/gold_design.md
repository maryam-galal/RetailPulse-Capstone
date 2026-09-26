# RetailPulse Gold Layer Design

## Overview

The Gold layer is the business-oriented analytical layer of the RetailPulse pipeline.

It is implemented using Apache Hive on HDFS and provides business-ready data for analytics and Metabase dashboards.

## Architecture

PostgreSQL
    ↓
Apache Sqoop
    ↓
Bronze
    ↓
Silver
    ↓
Gold
    ↓
Metabase

## Gold Tables

### 1. dim_customer_gold

Customer dimension containing customer identity and customer profile attributes.

Key fields:
- customer_key
- customer_id
- full_name
- email
- phone
- country_code
- signup_at
- updated_at

### 2. dim_product_gold

Product dimension containing product information, category and pricing.

Key fields:
- product_key
- product_id
- sku
- product_name
- category
- unit_cost
- list_price
- updated_at

### 3. dim_store_gold

Store dimension containing store identity and location information.

Key fields:
- store_key
- store_id
- store_name
- city
- country_code
- opened_at

### 4. dim_date_gold

Date dimension used for time-based analysis.

Key fields:
- date_key
- full_date
- day_of_month
- day_name
- week_of_year
- month_number
- month_name
- quarter_number
- year
- is_weekend

### 5. fact_orders_gold

Atomic sales fact at order-line level.

Each record represents an order item and contains:
- Order information
- Customer key
- Product key
- Store key
- Date key
- Quantity
- Unit price
- Discount
- Gross amount
- Net amount

### 6. fact_fulfillment_gold

Fulfillment lifecycle and SLA analytics.

Lifecycle events:
- packed
- shipped
- delivered

The delivery SLA is 48 hours.

A delivery is considered late when:

delivery_duration_hours > 48

### 7. inventory_risk_gold

Inventory-risk mart containing the latest inventory snapshot information for products and stores.

Risk classifications:
- NORMAL
- LOW_STOCK
- OUT_OF_STOCK

### 8. digital_funnel_gold

Digital funnel analytics aggregated by event date and channel.

Metrics:
- Product views
- Cart starts
- Checkout starts
- Confirmed orders

### 9. data_quality_gold

Data-quality summary for the Silver layer.

Metrics:
- Total records
- Valid records
- Rejected records
- Duplicate records
- Data-quality status

## Business Metrics

### Net Revenue

Sum of line-level net amounts for non-cancelled orders.

### Order Count

Number of distinct non-cancelled orders.

### Average Order Value

AOV = Net Revenue / Distinct Order Count

### Delivery Duration

Time from shipment to delivery, measured in hours.

### Late Delivery

A delivery taking more than the 48-hour SLA.

### Inventory Risk

Inventory is classified as NORMAL, LOW_STOCK or OUT_OF_STOCK.

### Data Quality Status

PASS indicates that no rejected or duplicate records were found under the implemented checks.

## Gold Layer Scale

- 40,000 customers
- 10,000 products
- 51 stores
- 278 dates
- 298,755 order-line records
- 300,000 fulfillment events
- 100,000 inventory snapshots
- 9 digital funnel rows
- 8 data-quality summary rows

## Metabase

The Gold layer is connected to Metabase for business analytics.

The dashboard includes:

1. Daily Net Revenue, Orders & AOV
2. Revenue by Store
3. Revenue by Product Category
4. Order & Delivery Lifecycle
5. Delivery SLA Summary
6. Products at Inventory Risk
7. Stores with Inventory Risk
8. Digital Funnel
9. Data Quality Status