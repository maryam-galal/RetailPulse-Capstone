USE retailpulse;

DROP TABLE IF EXISTS dim_product_gold;

CREATE TABLE dim_product_gold (
    product_key INT,
    product_id INT,
    sku STRING,
    product_name STRING,
    category STRING,
    unit_cost DECIMAL(18,2),
    list_price DECIMAL(18,2),
    updated_at TIMESTAMP
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

INSERT INTO TABLE dim_product_gold
SELECT
    CAST(product_id AS INT) AS product_key,
    CAST(product_id AS INT) AS product_id,
    sku,
    product_name,
    category,
    CAST(unit_cost AS DECIMAL(18,2)) AS unit_cost,
    CAST(list_price AS DECIMAL(18,2)) AS list_price,

    CAST(
        FROM_UNIXTIME(
            UNIX_TIMESTAMP(
                updated_at,
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            )
        ) AS TIMESTAMP
    ) AS updated_at

FROM products_silver;