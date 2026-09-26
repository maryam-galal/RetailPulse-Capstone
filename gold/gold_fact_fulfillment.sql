USE retailpulse;

DROP TABLE IF EXISTS fact_fulfillment_gold;

CREATE TABLE fact_fulfillment_gold (
    fulfillment_key INT,
    order_id INT,
    customer_key INT,
    store_key INT,
    date_key INT,
    warehouse_code STRING,
    fulfillment_status STRING,
    event_type STRING,
    event_timestamp TIMESTAMP,
    shipped_at TIMESTAMP,
    delivered_at TIMESTAMP,
    delivery_duration_hours INT,
    sla_hours INT,
    is_late BOOLEAN
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

INSERT INTO TABLE fact_fulfillment_gold
SELECT
    CAST(fe.fulfillment_event_id AS INT) AS fulfillment_key,

    CAST(fe.order_id AS INT) AS order_id,

    CAST(o.customer_id AS INT) AS customer_key,
    CAST(o.store_id AS INT) AS store_key,

    CAST(
        date_format(
            FROM_UNIXTIME(
                UNIX_TIMESTAMP(
                    fe.event_timestamp,
                    "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                )
            ),
            'yyyyMMdd'
        ) AS INT
    ) AS date_key,

    fe.warehouse_code,

    CASE
        WHEN fe.event_type = 'delivered' THEN 'completed'
        WHEN fe.event_type = 'shipped' THEN 'shipped'
        WHEN fe.event_type = 'packed' THEN 'packed'
        ELSE fe.event_type
    END AS fulfillment_status,

    fe.event_type,

    CAST(
        FROM_UNIXTIME(
            UNIX_TIMESTAMP(
                fe.event_timestamp,
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            )
        ) AS TIMESTAMP
    ) AS event_timestamp,

    CAST(
        FROM_UNIXTIME(
            UNIX_TIMESTAMP(
                (
                    SELECT MIN(fe2.event_timestamp)
                    FROM fulfillment_events_silver fe2
                    WHERE fe2.order_id = fe.order_id
                      AND fe2.event_type = 'shipped'
                ),
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            )
        ) AS TIMESTAMP
    ) AS shipped_at,

    CAST(
        FROM_UNIXTIME(
            UNIX_TIMESTAMP(
                (
                    SELECT MIN(fe3.event_timestamp)
                    FROM fulfillment_events_silver fe3
                    WHERE fe3.order_id = fe.order_id
                      AND fe3.event_type = 'delivered'
                ),
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            )
        ) AS TIMESTAMP
    ) AS delivered_at,

    48 AS delivery_duration_hours,

    NULL AS sla_hours,
    NULL AS is_late

FROM fulfillment_events_silver fe

JOIN orders_silver o
    ON CAST(fe.order_id AS INT) = CAST(o.order_id AS INT);