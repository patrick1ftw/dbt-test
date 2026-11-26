-- Timestamps are converted to UTC.

SELECT
  Order_ID AS source_transaction_id,
  LOWER(Email) AS donor_email,
  Billing_First_Name AS donor_first_name,
  Billing_Last_Name AS donor_last_name,
  Billing_Name AS donor_name,
  Billing_Phone AS donor_phone,
  UPPER(Currency) AS currency,
  SAFE_CAST(Total AS NUMERIC) AS gross_amount,
  SAFE_CAST(Estimated_Fee AS NUMERIC) AS fee_amount,
  SAFE_CAST(Net_Total AS NUMERIC) AS net_amount,
  Portfolio AS portfolio,
  Financial_Status AS payment_status,
  Payment_Method AS payment_method,
  Payment_Reference AS payment_reference,
  Billing_Address1 AS donor_address_1,
  Billing_Address2 AS donor_address_2,
  REGEXP_REPLACE(Billing_City, r'\s+', ' ') AS donor_city,
  Billing_Province AS donor_state_province,
  Billing_Zip AS donor_postal_code,
  Billing_Country AS donor_country,
  Channel_Name AS source_platform,
  SAFE.PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%E*S %z', Paid_at) AS donated_at,
  _ingested_at AS ingested_at
FROM `weighty-flag-290219.raw_sources.raw_squarespace`;