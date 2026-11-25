WITH parsed AS (
  SELECT
    TRIM(Transaction_ID) AS transaction_id,
    COALESCE(
      SAFE_CAST(Donation_Date AS TIMESTAMP),
      SAFE.PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%E*S UTC', Donation_Date),
      SAFE.PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%E*SZ', Donation_Date),
      SAFE.PARSE_TIMESTAMP('%m/%d/%Y %H:%M:%S', Donation_Date),
      SAFE.PARSE_TIMESTAMP('%d/%m/%Y %H:%M:%S', Donation_Date),
      TIMESTAMP(SAFE.PARSE_DATE('%m/%d/%Y', Donation_Date)),
      TIMESTAMP(SAFE.PARSE_DATE('%d/%m/%Y', Donation_Date)),
      TIMESTAMP(SAFE.PARSE_DATE('%Y-%m-%d', Donation_Date))
    ) AS donation_date,
    COALESCE(
      SAFE_CAST(Disbursement_Date AS TIMESTAMP),
      SAFE.PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%E*S UTC', Disbursement_Date),
      SAFE.PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%E*SZ', Disbursement_Date),
      SAFE.PARSE_TIMESTAMP('%m/%d/%Y %H:%M:%S', Disbursement_Date),
      SAFE.PARSE_TIMESTAMP('%d/%m/%Y %H:%M:%S', Disbursement_Date),
      TIMESTAMP(SAFE.PARSE_DATE('%m/%d/%Y', Disbursement_Date)),
      TIMESTAMP(SAFE.PARSE_DATE('%d/%m/%Y', Disbursement_Date)),
      TIMESTAMP(SAFE.PARSE_DATE('%Y-%m-%d', Disbursement_Date))
    ) AS disbursed_at,
    SAFE_CAST(REGEXP_REPLACE(TRIM(Donation_Amount), r'[^0-9.\-]', '') AS FLOAT64) AS amount_raw,
    COALESCE(SAFE_CAST(REGEXP_REPLACE(TRIM(Match_Amount), r'[^0-9.\-]', '') AS FLOAT64), 0) AS match_raw,
    COALESCE(SAFE_CAST(REGEXP_REPLACE(TRIM(Cause_Support_Fee), r'[^0-9.\-]', '') AS FLOAT64), 0) AS cause_support_fee,
    COALESCE(SAFE_CAST(REGEXP_REPLACE(TRIM(Merchant_Fee), r'[^0-9.\-]', '') AS FLOAT64), 0) AS merchant_fee,
    COALESCE(SAFE_CAST(REGEXP_REPLACE(TRIM(Check_Fee), r'[^0-9.\-]', '') AS FLOAT64), 0) AS check_fee,
    SAFE_CAST(REGEXP_REPLACE(TRIM(Foreign_Exchange_Rate), r'[^0-9.\-]', '') AS FLOAT64) AS foreign_exchange_rate,
    Disbursement_ID AS disbursement_id_raw,
    Disbursement_From_Grantor AS grantor_raw,
    Project_Name AS project_name_raw,
    Donation_Method AS donation_method_raw,
    Donation_Currency AS currency_raw,
    Company_Name AS company_raw,
    Donor_First_Name AS first_name_raw,
    Donor_Last_Name AS last_name_raw,
    Donor_Email AS email_raw,
    Donor_Address AS address_raw,
    Donor_City AS city_raw,
    Donor_State_Province AS state_raw,
    Donor_Zip_Postal_Code AS postal_raw,
    Donor_Country AS country_raw,
    Donation_Frequency AS frequency_raw,
    Payment_Method AS payment_method_raw
  FROM weighty-flag-290219.raw_sources.raw_benevity
  WHERE Transaction_ID IS NOT NULL
    AND TRIM(Transaction_ID) != ''
  LIMIT 800
),
deduped AS (
  SELECT *
  FROM parsed
  WHERE donation_date IS NOT NULL
    AND amount_raw IS NOT NULL
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY transaction_id
    ORDER BY donation_date DESC
  ) = 1
),
normalized AS (
  SELECT
    transaction_id,
    donation_date,
    disbursed_at,
    amount_raw,
    match_raw,
    cause_support_fee,
    merchant_fee,
    check_fee,
    cause_support_fee + merchant_fee + check_fee AS fee_raw,
    foreign_exchange_rate,
    CASE
      WHEN currency_raw IS NULL OR LOWER(TRIM(currency_raw)) IN (
        '', 'n/a', 'na', 'null', 'none', 'not available', 'not shared by donor', '-', '--'
      ) THEN 'N/A'
      ELSE UPPER(TRIM(currency_raw))
    END AS amount_currency,
    CASE
      WHEN company_raw IS NULL OR LOWER(TRIM(company_raw)) IN (
        '', 'n/a', 'na', 'null', 'none', 'not available', 'not shared by donor', '-', '--'
      ) THEN 'N/A'
      ELSE TRIM(company_raw)
    END AS chapter,
    CASE
      WHEN first_name_raw IS NULL OR LOWER(TRIM(first_name_raw)) IN (
        '', 'n/a', 'na', 'null', 'none', 'not available', 'not shared by donor', '-', '--'
      ) THEN 'N/A'
      ELSE TRIM(first_name_raw)
    END AS first_name,
    CASE
      WHEN last_name_raw IS NULL OR LOWER(TRIM(last_name_raw)) IN (
        '', 'n/a', 'na', 'null', 'none', 'not available', 'not shared by donor', '-', '--'
      ) THEN 'N/A'
      ELSE TRIM(last_name_raw)
    END AS last_name,
    CASE
      WHEN email_raw IS NULL OR LOWER(TRIM(email_raw)) IN (
        '', 'n/a', 'na', 'null', 'none', 'not available', 'not shared by donor', '-', '--'
      ) THEN 'N/A'
      ELSE LOWER(TRIM(email_raw))
    END AS email,
    CASE
      WHEN address_raw IS NULL OR LOWER(TRIM(address_raw)) IN (
        '', 'n/a', 'na', 'null', 'none', 'not available', 'not shared by donor', '-', '--'
      ) THEN 'N/A'
      ELSE TRIM(address_raw)
    END AS billing_address,
    CASE
      WHEN city_raw IS NULL OR LOWER(TRIM(city_raw)) IN (
        '', 'n/a', 'na', 'null', 'none', 'not available', 'not shared by donor', '-', '--'
      ) THEN 'N/A'
      ELSE TRIM(city_raw)
    END AS billing_city,
    CASE
      WHEN state_raw IS NULL OR LOWER(TRIM(state_raw)) IN (
        '', 'n/a', 'na', 'null', 'none', 'not available', 'not shared by donor', '-', '--'
      ) THEN 'N/A'
      ELSE TRIM(state_raw)
    END AS billing_state,
    CASE
      WHEN postal_raw IS NULL OR LOWER(TRIM(postal_raw)) IN (
        '', 'n/a', 'na', 'null', 'none', 'not available', 'not shared by donor', '-', '--'
      ) THEN 'N/A'
      ELSE TRIM(postal_raw)
    END AS billing_postal_code,
    CASE
      WHEN country_raw IS NULL OR LOWER(TRIM(country_raw)) IN (
        '', 'n/a', 'na', 'null', 'none', 'not available', 'not shared by donor', '-', '--'
      ) THEN 'N/A'
      ELSE TRIM(country_raw)
    END AS billing_country,
    CASE
      WHEN frequency_raw IS NULL OR LOWER(TRIM(frequency_raw)) IN (
        '', 'n/a', 'na', 'null', 'none', 'not available', 'not shared by donor', '-', '--'
      ) THEN 'N/A'
      WHEN LOWER(TRIM(frequency_raw)) IN ('one-time', 'one time', 'onetime') THEN 'One-time'
      WHEN LOWER(TRIM(frequency_raw)) = 'recurring' THEN 'Recurring'
      ELSE TRIM(frequency_raw)
    END AS donation_frequency,
    CASE
      WHEN payment_method_raw IS NULL OR LOWER(TRIM(payment_method_raw)) IN (
        '', 'n/a', 'na', 'null', 'none', 'not available', 'not shared by donor', '-', '--'
      ) THEN 'N/A'
      ELSE TRIM(payment_method_raw)
    END AS payment_method,
    CASE
      WHEN disbursement_id_raw IS NULL OR LOWER(TRIM(disbursement_id_raw)) IN (
        '', 'n/a', 'na', 'null', 'none', 'not available', 'not shared by donor', '-', '--'
      ) THEN 'N/A'
      ELSE TRIM(disbursement_id_raw)
    END AS disbursement_id,
    CASE
      WHEN grantor_raw IS NULL OR LOWER(TRIM(grantor_raw)) IN (
        '', 'n/a', 'na', 'null', 'none', 'not available', 'not shared by donor', '-', '--'
      ) THEN 'N/A'
      ELSE TRIM(grantor_raw)
    END AS disbursement_from_grantor,
    CASE
      WHEN project_name_raw IS NULL OR LOWER(TRIM(project_name_raw)) IN (
        '', 'n/a', 'na', 'null', 'none', 'not available', 'not shared by donor', '-', '--'
      ) THEN 'N/A'
      ELSE TRIM(project_name_raw)
    END AS project_name,
    CASE
      WHEN donation_method_raw IS NULL OR LOWER(TRIM(donation_method_raw)) IN (
        '', 'n/a', 'na', 'null', 'none', 'not available', 'not shared by donor', '-', '--'
      ) THEN 'N/A'
      ELSE TRIM(donation_method_raw)
    END AS donation_method
  FROM deduped
),
priced AS (
  SELECT
    n.*,
    fx.exchange_rate AS usd_per_unit
  FROM normalized AS n
  LEFT JOIN `weighty-flag-290219.silver_reports.currency_conversion` AS fx
    ON fx.currency_code = n.amount_currency
   AND fx.rate_date = DATE(n.donation_date)
)

SELECT
  transaction_id AS source_transaction_id,
  'Benevity' AS source_platform,
  'N/A' AS source_donor_id,
  'N/A' AS partner_id,
  'N/A' AS source_portfolio_id,
  'N/A' AS portfolio,
  donation_date,
  CONCAT(
    'AY',
    FORMAT_DATE(
      '%y',
      DATE_ADD(DATE(donation_date), INTERVAL IF(EXTRACT(MONTH FROM donation_date) < 7, 0, 1) YEAR)
    )
  ) AS AY,
  amount_raw AS donation_amount,
  amount_currency AS currency,
  CASE
    WHEN amount_currency = 'USD' THEN amount_raw
    WHEN usd_per_unit IS NOT NULL THEN amount_raw * usd_per_unit
    ELSE NULL
  END AS amount_usd,
  CASE
    WHEN match_raw = 0 THEN 0
    WHEN amount_currency = 'USD' THEN match_raw
    WHEN usd_per_unit IS NOT NULL THEN match_raw * usd_per_unit
    ELSE NULL
  END AS match_amount_usd,
  match_raw AS match_amount,
  fee_raw AS fee_amount,
  CASE
    WHEN fee_raw = 0 THEN 0
    WHEN amount_currency = 'USD' THEN fee_raw
    WHEN usd_per_unit IS NOT NULL THEN fee_raw * usd_per_unit
    ELSE NULL
  END AS fee_amount_usd,
  first_name AS donor_first_name,
  last_name AS donor_last_name,
  CASE
    WHEN first_name = 'N/A' AND last_name = 'N/A' THEN 'N/A'
    WHEN last_name = 'N/A' THEN first_name
    WHEN first_name = 'N/A' THEN last_name
    ELSE CONCAT(first_name, ' ', last_name)
  END AS donor_name,
  email AS donor_email,
  billing_address AS donor_address_1,
  'N/A' AS donor_address_2,
  billing_city AS donor_city,
  billing_state AS donor_state_province,
  billing_postal_code AS donor_postal_code,
  billing_country AS donor_country,
  'N/A' AS donor_phone,
  chapter,
  chapter AS donor_employer,
  donation_frequency AS contribution_frequency,
  payment_method,
  payment_method AS disbursement_payment_method,
  donation_date AS created_at,
  CAST(NULL AS TIMESTAMP) AS paid_at,
  'N/A' AS payment_status,
  'N/A' AS payment_reference,
  disbursement_id,
  disbursed_at,
  disbursement_from_grantor,
  project_name,
  donation_method,
  donation_method AS contribution_method,
  foreign_exchange_rate,
  cause_support_fee,
  merchant_fee,
  check_fee,
  amount_raw + match_raw AS gross_amount,
  amount_raw + match_raw - cause_support_fee - merchant_fee - check_fee AS net_amount
FROM priced