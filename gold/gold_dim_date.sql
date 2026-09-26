USE retailpulse;

DROP TABLE IF EXISTS dim_date_gold;

CREATE TABLE dim_date_gold (
    date_key INT,
    full_date DATE,
    day INT,
    day_name STRING,
    week INT,
    month INT,
    month_name STRING,
    quarter INT,
    year INT,
    is_weekend BOOLEAN
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

INSERT INTO TABLE dim_date_gold
SELECT DISTINCT
    CAST(
        date_format(
            FROM_UNIXTIME(
                UNIX_TIMESTAMP(
                    order_timestamp,
                    "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                )
            ),
            'yyyyMMdd'
        ) AS INT
    ) AS date_key,

    TO_DATE(
        FROM_UNIXTIME(
            UNIX_TIMESTAMP(
                order_timestamp,
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            )
        )
    ) AS full_date,

    DAY(
        FROM_UNIXTIME(
            UNIX_TIMESTAMP(
                order_timestamp,
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            )
        )
    ) AS day,

    FROM_UNIXTIME(
        UNIX_TIMESTAMP(
            order_timestamp,
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        ),
        'EEEE'
    ) AS day_name,

    WEEKOFYEAR(
        FROM_UNIXTIME(
            UNIX_TIMESTAMP(
                order_timestamp,
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            )
        )
    ) AS week,

    MONTH(
        FROM_UNIXTIME(
            UNIX_TIMESTAMP(
                order_timestamp,
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            )
        )
    ) AS month,

    FROM_UNIXTIME(
        UNIX_TIMESTAMP(
            order_timestamp,
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        ),
        'MMMM'
    ) AS month_name,

    QUARTER(
        FROM_UNIXTIME(
            UNIX_TIMESTAMP(
                order_timestamp,
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            )
        )
    ) AS quarter,

    YEAR(
        FROM_UNIXTIME(
            UNIX_TIMESTAMP(
                order_timestamp,
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            )
        )
    ) AS year,

    CASE
        WHEN DAYOFWEEK(
            FROM_UNIXTIME(
                UNIX_TIMESTAMP(
                    order_timestamp,
                    "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                )
            )
        ) IN (1,7)
        THEN TRUE
        ELSE FALSE
    END AS is_weekend

FROM orders_silver;