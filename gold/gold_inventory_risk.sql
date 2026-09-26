USE retailpulse;

DROP TABLE IF EXISTS inventory_risk_gold;

CREATE TABLE inventory_risk_gold (
    inventory_snapshot_id STRING,
    product_id INT,
    store_id INT,
    stock_on_hand INT,
    snapshot_at TIMESTAMP,
    inventory_risk STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

INSERT INTO TABLE inventory_risk_gold
SELECT
    inventory_snapshot_id,
    CAST(product_id AS INT) AS product_id,
    CAST(store_id AS INT) AS store_id,
    CAST(stock_on_hand AS INT) AS stock_on_hand,

    CAST(
        FROM_UNIXTIME(
            UNIX_TIMESTAMP(
                snapshot_at,
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            )
        ) AS TIMESTAMP
    ) AS snapshot_at,

    CASE
        WHEN CAST(stock_on_hand AS INT) = 0
            THEN 'OUT_OF_STOCK'
        WHEN CAST(stock_on_hand AS INT) <= 10
            THEN 'LOW_STOCK'
        ELSE 'NORMAL'
    END AS inventory_risk

FROM inventory_snapshots_silver;