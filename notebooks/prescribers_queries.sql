-- # Tennessee's Opioid Crisis

-- Opioids are a class of drugs including prescription pain relievers such as oxycodone and hydrocodone, the synthetic opioid fentanyl, and the illegal drug heroin. These drugs produce euphoria in addition to pain relief, which can lead to dependence, addiction, overdose, and death. 

-- In the late 1990s, opioids began to be prescribed at high rates, which led to widespread misuse and ultimately created a serious national health crisis. In 2019, more than 130 people per day died from opioid-related drug overdoses in the United States. Tennessee has been one of the hardest-hit states in the opioid epidemic, with more than 1300 overdose deaths in 2018.

-- In this project, you will be working with a database created from the 2017 Medicare Part D Prescriber Public Use File to answer the following questions:  
-- * Which Tennessee counties had a disproportionately high number of opioid prescriptions?
-- * Who are the top opioid prescibers for the state of Tennessee?
-- * What did the trend in overdose deaths due to opioids look like in Tennessee from 2015 to 2018?
-- * Is there an association between rates of opioid prescriptions and overdose deaths by county?
-- * Is there any association between a particular type of opioid and number of overdose deaths?

-- Note that some zip codes will be associated with multiple fipscounty values in the zip_fips table. To resolve this, use the fipscounty with the highest tot_ratio for each zipcode.

-- Feel free to include any additional data sets, but it is not a requirement.

-- With your group, create a 10 minute presentation addressing these questions.

-- Question 1: Which Tennessee counties had a disproportionately high number of opioid prescriptions?
-- WITH max_zips AS (
-- 	SELECT DISTINCT zip
-- 		, MAX(tot_ratio) as max_ratio
-- 	FROM zip_fips
-- 	GROUP BY zip
-- )
-- , sort_fips AS (	
-- 	SELECT zip_fips.zip
-- 		, zip_fips.fipscounty
-- 		, zip_fips.tot_ratio
-- 	FROM zip_fips
-- 		INNER JOIN max_zips
-- 			ON zip_fips.zip = max_zips.zip
-- 			AND zip_fips.tot_ratio = max_zips.max_ratio
-- )
-- , total_claims AS (
-- 	SELECT fips_county.county
-- 		, SUM(prescription.total_claim_count) AS total_claims
-- 	FROM fips_county
-- 		INNER JOIN population
-- 			USING(fipscounty)
-- 		INNER JOIN sort_fips
-- 			USING (fipscounty)
-- 		INNER JOIN prescriber
-- 			ON sort_fips.zip = prescriber.nppes_provider_zip5
-- 		INNER JOIN prescription
-- 			USING (npi)
-- 		INNER JOIN drug
-- 			USING (drug_name)
-- 	WHERE fips_county.state ILIKE 'TN'
-- 	GROUP BY fips_county.county
-- )
-- SELECT fips_county.county
-- 	, population.population
-- 	, SUM(prescription.total_claim_count) AS total_opioids
-- 	, (SUM(prescription.total_claim_count)/total_claims.total_claims)*100 AS opioid_pct
-- FROM fips_county
-- 	INNER JOIN population
-- 		USING (fipscounty)
-- 	INNER JOIN sort_fips
-- 		USING (fipscounty)
-- 	INNER JOIN prescriber
-- 		ON sort_fips.zip = prescriber.nppes_provider_zip5
-- 	INNER JOIN prescription
-- 		USING (npi)
-- 	INNER JOIN drug
-- 		USING (drug_name)
-- 	INNER JOIN total_claims
-- 		USING (county)
-- WHERE drug.opioid_drug_flag ILIKE 'Y'
-- 	AND fips_county.state ILIKE 'TN'
-- GROUP BY fips_county.county
-- 	, population.population
-- 	, total_claims.total_claims
-- ORDER BY total_opioids DESC

-- --Question 2: Who are the top opioid prescibers for the state of Tennessee?
-- SELECT prescriber.npi
-- 	, CONCAT(prescriber.nppes_provider_first_name,' ',prescriber.nppes_provider_last_org_name) as full_name
-- 	, SUM(prescription.total_claim_count) AS total_opioids
-- FROM prescriber
-- 	INNER JOIN prescription
-- 		USING(npi)
-- 	INNER JOIN drug
-- 		USING(drug_name)
-- WHERE drug.opioid_drug_flag ILIKE 'Y'
-- 	AND prescriber.nppes_provider_state ILIKE 'TN'
-- GROUP BY prescriber.npi
-- 	, prescriber.nppes_provider_first_name
-- 	, prescriber.nppes_provider_last_org_name
-- ORDER BY total_opioids DESC;

-- Question 3: What did the trend in overdose deaths due to opioids look like in Tennessee from 2015 to 2018?
-- WITH overdose_fixed AS (
-- 	SELECT overdose_deaths
-- 		, year
-- 		, fipscounty::varchar
-- 	FROM overdose_deaths
-- )
-- SELECT overdose_fixed.year
-- 	, SUM(overdose_fixed.overdose_deaths)
-- FROM overdose_fixed
-- 	INNER JOIN fips_county
-- 		USING(fipscounty)
-- WHERE fips_county.state LIKE 'TN'
-- GROUP BY overdose_fixed.year
-- ORDER BY overdose_fixed.year

--Question 4: Is there an association between rates of opioid prescriptions and overdose deaths by county?
-- WITH overdose_fixed AS (
-- 	SELECT overdose_deaths
-- 		, year
-- 		, fipscounty::varchar
-- 	FROM overdose_deaths
-- )
-- SELECT fips_county.county
-- 	, fips_county.fipscounty
-- 	, SUM(overdose_fixed.overdose_deaths) AS total_deaths
-- FROM overdose_fixed
-- 	INNER JOIN fips_county
-- 		USING(fipscounty)
-- WHERE fips_county.state ILIKE 'TN'
-- GROUP BY fips_county.county
-- 	, fips_county.fipscounty

-- Question 5: Is there any association between a particular type of opioid and number of overdose deaths?
WITH max_zips AS (
	SELECT DISTINCT zip
		, MAX(tot_ratio) as max_ratio
	FROM zip_fips
	GROUP BY zip
)
, sort_fips AS (	
	SELECT zip_fips.zip
		, zip_fips.fipscounty
		, zip_fips.tot_ratio
	FROM zip_fips
		INNER JOIN max_zips
			ON zip_fips.zip = max_zips.zip
			AND zip_fips.tot_ratio = max_zips.max_ratio
)
, drug_flag AS (
	SELECT drug_name
		, generic_name
		, CASE WHEN generic_name ILIKE '%FENTANYL%' THEN 'Y'
			ELSE NULL
			END AS fent_flag
		, CASE WHEN generic_name ILIKE '%HYDROCODONE%' THEN 'Y'
			ELSE NULL
			END AS hydroc_flag
		, CASE WHEN generic_name ILIKE '%CODEINE%' THEN 'Y'
			ELSE NULL
			END AS codeine_flag
		, CASE WHEN generic_name ILIKE '%MORPHINE%' THEN 'Y'
			ELSE NULL
			END AS morph_flag
		, CASE WHEN generic_name ILIKE '%METHADONE%' THEN 'Y'
			ELSE NULL
			END AS methadone_flag
		, CASE WHEN generic_name ILIKE '%OXYCODONE%' THEN 'Y'
			ELSE NULL
			END AS oxy_flag
		, CASE WHEN generic_name ILIKE '%HYDROMORPHONE%' THEN 'Y'
			ELSE NULL
			END AS hydrom_flag
		, CASE WHEN generic_name ILIKE '%TRAMADOL%' THEN 'Y'
			ELSE NULL
			END AS tram_flag
	FROM drug
	WHERE opioid_drug_flag ILIKE 'Y'
)
SELECT fips_county.county
	, COUNT(drug_flag.fent_flag) AS fent_count
	, COUNT(drug_flag.hydroc_flag) AS hydroc_count
	, COUNT(drug_flag.codeine_flag) AS codeine_count
	, COUNT(drug_flag.morph_flag) AS morph_count
	, COUNT(drug_flag.methadone_flag) AS methadone_count
	, COUNT(drug_flag.oxy_flag) AS oxy_count
	, COUNT(drug_flag.hydrom_flag) AS hydrom_count
	, COUNT(drug_flag.tram_flag) AS tram_count
FROM fips_county
	INNER JOIN population
		USING (fipscounty)
	INNER JOIN sort_fips
		USING (fipscounty)
	INNER JOIN prescriber
		ON sort_fips.zip = prescriber.nppes_provider_zip5
	INNER JOIN prescription
		USING (npi)
	INNER JOIN drug
		USING (drug_name)
	INNER JOIN drug_flag
		USING(drug_name , generic_name)
WHERE drug.opioid_drug_flag ILIKE 'Y'
	AND fips_county.state ILIKE 'TN'
GROUP BY fips_county.county

-- SELECT *, ROW_NUMBER() OVER(PARTITION BY generic_name ORDER BY generic_name) opiod_Type_count
-- FROM drug WHERE opioid_drug_flag = 'Y'

SELECT * from prescription ORDER BY npi,drug_name








