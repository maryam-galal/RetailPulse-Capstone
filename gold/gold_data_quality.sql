USE retailpulse;

DROP TABLE IF EXISTS data_quality_gold;

CREATE TABLE data_quality_gold (
    dq_date DATE,
    table_name STRING,
    total_records BIGINT,
    valid_records BIGINT,
    rejected_records BIGINT,
    duplicate_records BIGINT,
    dq_status STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

INSERT INTO TABLE data_quality_gold
SELECT
    CURRENT_DATE AS dq_date,
    'customers_silver' AS table_name,
    COUNT(*) AS total_records,
    COUNT(*) AS valid_records,
    0 AS rejected_records,
    COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_records,

    CASE
        WHEN COUNT(*) = COUNT(DISTINCT customer_id)
        THEN 'PASS'
        ELSE 'CHECK'
    END AS dq_status

FROM customers_silver;