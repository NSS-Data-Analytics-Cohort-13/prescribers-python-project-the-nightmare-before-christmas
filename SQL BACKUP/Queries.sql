#2
SELECT prescriber.npi
	  ,CONCAT(prescriber.nppes_provider_first_name,' ',prescriber.nppes_provider_last_org_name) AS full_name
	  ,COUNT(drug.opioid_drug_flag) AS total_opioids
FROM prescriber
	INNER JOIN prescription
		USING(npi)
	INNER JOIN drug
		USING(drug_name)
WHERE drug.opioid_drug_flag ILIKE 'Y'
	AND prescriber.nppes_provider_state ILIKE 'TN'
GROUP BY prescriber.npi
	,prescriber.nppes_provider_first_name
	,prescriber.nppes_provider_last_org_name
order by total_opioids DESC
LIMIT 20;

#2 comparisson
SELECT prescriber.npi
	  ,CONCAT(prescriber.nppes_provider_first_name,' ',prescriber.nppes_provider_last_org_name) AS full_name
	  ,COUNT(drug.opioid_drug_flag) AS total_opioids
	  ,SUM(prescription.total_claim_count) as total_claim
	  ,nppes_provider_city
	  ,specialty_description
	  FROM prescriber
	INNER JOIN prescription
		USING(npi)
	INNER JOIN drug
		USING(drug_name)
WHERE drug.opioid_drug_flag ILIKE 'Y'
	GROUP BY prescriber.npi
	,prescriber.nppes_provider_first_name
	,prescriber.nppes_provider_last_org_name
	,nppes_provider_city
	,specialty_description
	order by total_claim DESC
LIMIT 20;



-- #3 done 
-- SELECT 
--     od.year,
--     SUM(od.overdose_deaths) AS total_overdose_deaths
-- FROM 
--     overdose_deaths AS od
-- INNER JOIN 
--     fips_county AS fc
-- ON 
--     od.fipscounty = fc.fipscounty::integer
-- WHERE 
--     fc.state ILIKE 'TN' 
-- 	AND
--     od.year BETWEEN 2015 AND 2018 
-- GROUP BY 
--     od.year
-- ORDER BY 
--     od.year;


-- #3 
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


#5
SELECT 
    d.drug_name,
	d.generic_name,
    SUM(od.overdose_deaths) AS total_overdose_deaths,
    SUM(p.total_claim_count) AS total_opioid_prescriptions
FROM 
    prescription as p
INNER JOIN 
    prescriber as pr 
	ON p.npi = pr.npi
INNER JOIN 
    zip_fips as zf
	ON pr.nppes_provider_zip5 = zf.zip
INNER JOIN 
    overdose_deaths as od 
	ON zf.fipscounty::integer = od.fipscounty
INNER JOIN 
    drug as d 
	ON p.drug_name = d.drug_name
WHERE 
    d.opioid_drug_flag = 'Y'
GROUP BY 
    d.drug_name,
	d.generic_name
ORDER BY 
    total_overdose_deaths DESC,
	d.generic_name;

SELECT *, ROW_NUMBER() OVER(PARTITION BY generic_name ORDER BY generic_name) opiod_Type_count
FROM drug WHERE opioid_drug_flag = 'Y'

#1
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
, total_claims AS (
	SELECT fips_county.county
		, SUM(prescription.total_claim_count) AS total_claims
	FROM fips_county
		INNER JOIN population
			USING(fipscounty)
		INNER JOIN sort_fips
			USING (fipscounty)
		INNER JOIN prescriber
			ON sort_fips.zip = prescriber.nppes_provider_zip5
		INNER JOIN prescription
			USING (npi)
		INNER JOIN drug
			USING (drug_name)
	WHERE fips_county.state ILIKE 'TN'
	GROUP BY fips_county.county
)
SELECT fips_county.county
	, population.population
	, SUM(prescription.total_claim_count) AS total_opioids
	, (SUM(prescription.total_claim_count)/total_claims.total_claims)*100 AS opioid_pct
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
	INNER JOIN total_claims
		USING (county)
WHERE drug.opioid_drug_flag ILIKE 'Y'
	AND fips_county.state ILIKE 'TN'
GROUP BY fips_county.county
	, population.population
	, total_claims.total_claims
ORDER BY total_opioids DESC
