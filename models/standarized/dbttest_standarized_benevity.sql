
SELECT
  Transaction_ID AS source_transaction_id,
  LOWER(Donor_Email) AS donor_email,
  Donor_First_Name AS donor_first_name,
  Donor_Last_Name AS donor_last_name,
  Project_Name AS portfolio,
  UPPER(Donation_Currency) AS currency,
  SAFE_CAST(Foreign_Exchange_Rate AS NUMERIC) AS foreign_exchange_rate,
  SAFE_CAST(Donation_Amount AS NUMERIC) + COALESCE(SAFE_CAST(Match_Amount AS NUMERIC), 0) AS gross_amount,
  COALESCE(SAFE_CAST(Cause_Support_Fee AS NUMERIC), 0)
    + COALESCE(SAFE_CAST(Merchant_Fee AS NUMERIC), 0)
    + COALESCE(SAFE_CAST(Check_Fee AS NUMERIC), 0) AS fee_amount,
  SAFE_CAST(Donation_Amount AS NUMERIC) + COALESCE(SAFE_CAST(Match_Amount AS NUMERIC), 0)
    - COALESCE(SAFE_CAST(Cause_Support_Fee AS NUMERIC), 0)
    - COALESCE(SAFE_CAST(Merchant_Fee AS NUMERIC), 0)
    - COALESCE(SAFE_CAST(Check_Fee AS NUMERIC), 0) AS net_amount,
  Donation_Frequency AS donation_frequency,
  Company_Name AS company_name,
  Payment_Method AS disbursement_payment_method,
  Bank_Reference_ID AS bank_reference_id,
  Disbursement_ID AS disbursement_id,
  Donor_Address AS donor_address_1,
  REGEXP_REPLACE(Donor_City, r'\s+', ' ') AS donor_city,
  Donor_Zip_Postal_Code AS donor_postal_code,
  Donor_State_Province AS donor_state_province,
  Donor_Country AS donor_country,
  'Benevity' AS source_platform,
  account_id,
  SAFE.PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%SZ', Disbursement_Date) AS disbursed_at,
  SAFE.PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%SZ', Donation_Date) AS donated_at,
  _ingested_at AS ingested_at
FROM `weighty-flag-290219.raw_sources.raw_benevity`
LIMIT 2000;