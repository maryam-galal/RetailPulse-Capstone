USE retailpulse;

DROP TABLE IF EXISTS digital_funnel_gold;

CREATE TABLE digital_funnel_gold (
    event_date DATE,
    channel STRING,
    product_views INT,
    cart_starts INT,
    checkout_starts INT,
    confirmed_orders INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

INSERT INTO TABLE digital_funnel_gold
SELECT
    TO_DATE(
        FROM_UNIXTIME(
            UNIX_TIMESTAMP(
                get_json_object(raw_payload, '$.event_timestamp'),
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXX"
            )
        )
    ) AS event_date,

    get_json_object(raw_payload, '$.channel') AS channel,

    SUM(
        CASE
            WHEN get_json_object(raw_payload, '$.event_type') = 'product_viewed'
            THEN 1
            ELSE 0
        END
    ) AS product_views,

    SUM(
        CASE
            WHEN get_json_object(raw_payload, '$.event_type') = 'cart_started'
            THEN 1
            ELSE 0
        END
    ) AS cart_starts,

    SUM(
        CASE
            WHEN get_json_object(raw_payload, '$.event_type') = 'checkout_started'
            THEN 1
            ELSE 0
        END
    ) AS checkout_starts,

    SUM(
        CASE
            WHEN get_json_object(raw_payload, '$.event_type') = 'order_confirmed'
            THEN 1
            ELSE 0
        END
    ) AS confirmed_orders

FROM bronze_retail_events

GROUP BY
    TO_DATE(
        FROM_UNIXTIME(
            UNIX_TIMESTAMP(
                get_json_object(raw_payload, '$.event_timestamp'),
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXX"
            )
        )
    ),
    get_json_object(raw_payload, '$.channel');