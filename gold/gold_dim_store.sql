USE retailpulse;

DROP TABLE IF EXISTS dim_store_gold;

CREATE TABLE dim_store_gold (
    store_key INT,
    store_id INT,
    store_name STRING,
    city STRING,
    country_code STRING,
    opened_at TIMESTAMP
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

INSERT INTO TABLE dim_store_gold
SELECT
    CAST(store_id AS INT) AS store_key,
    CAST(store_id AS INT) AS store_id,
    store_name,
    city,
    country_code,
    CAST(opened_at AS TIMESTAMP) AS opened_at

FROM stores_silver;