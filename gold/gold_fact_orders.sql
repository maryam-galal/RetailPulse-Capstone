USE retailpulse;

DROP TABLE IF EXISTS fact_orders_gold;

CREATE TABLE fact_orders_gold (
    order_line_key INT,
    order_id INT,
    order_item_id INT,
    customer_key INT,
    product_key INT,
    store_key INT,
    date_key INT,
    order_timestamp TIMESTAMP,
    order_status STRING,
    quantity INT,
    unit_price DECIMAL(18,2),
    line_discount DECIMAL(18,2),
    gross_amount DECIMAL(18,2),
    net_amount DECIMAL(18,2)
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

INSERT INTO TABLE fact_orders_gold
SELECT
    CAST(oi.order_item_id AS INT) AS order_line_key,
    CAST(oi.order_id AS INT) AS order_id,
    CAST(oi.order_item_id AS INT) AS order_item_id,

    CAST(o.customer_id AS INT) AS customer_key,
    CAST(oi.product_id AS INT) AS product_key,
    CAST(o.store_id AS INT) AS store_key,

    CAST(
        date_format(
            FROM_UNIXTIME(
                UNIX_TIMESTAMP(
                    o.order_timestamp,
                    "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                )
            ),
            'yyyyMMdd'
        ) AS INT
    ) AS date_key,

    CAST(
        FROM_UNIXTIME(
            UNIX_TIMESTAMP(
                o.order_timestamp,
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            )
        ) AS TIMESTAMP
    ) AS order_timestamp,

    o.order_status,

    CAST(oi.quantity AS INT) AS quantity,
    CAST(oi.unit_price AS DECIMAL(18,2)) AS unit_price,
    CAST(oi.line_discount AS DECIMAL(18,2)) AS line_discount,

    CAST(oi.quantity AS INT)
        * CAST(oi.unit_price AS DECIMAL(18,2))
        AS gross_amount,

    (
        CAST(oi.quantity AS INT)
        * CAST(oi.unit_price AS DECIMAL(18,2))
    )
    - CAST(oi.line_discount AS DECIMAL(18,2))
    AS net_amount

FROM order_items_silver oi
JOIN orders_silver o
    ON CAST(oi.order_id AS INT) = CAST(o.order_id AS INT);