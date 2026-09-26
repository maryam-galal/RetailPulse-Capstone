USE retailpulse;

DROP TABLE IF EXISTS dim_customer_gold;

CREATE TABLE dim_customer_gold (
    customer_key INT,
    customer_id INT,
    full_name STRING,
    email STRING,
    phone STRING,
    country_code STRING,
    signup_at TIMESTAMP,
    updated_at TIMESTAMP
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

INSERT INTO TABLE dim_customer_gold
SELECT
    CAST(customer_id AS INT) AS customer_key,
    CAST(customer_id AS INT) AS customer_id,
    full_name,
    email,
    phone,
    country_code,

    CAST(
        FROM_UNIXTIME(
            UNIX_TIMESTAMP(
                signup_at,
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            )
        ) AS TIMESTAMP
    ) AS signup_at,

    CAST(
        FROM_UNIXTIME(
            UNIX_TIMESTAMP(
                updated_at,
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            )
        ) AS TIMESTAMP
    ) AS updated_at

FROM customers_silver;