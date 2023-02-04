--1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT prescriber.npi, SUM(total_claim_count) as total_claims
FROM prescriber
INNER JOIN prescription 
USING(npi)
GROUP BY prescriber.npi
ORDER BY total_claims DESC
LIMIT 1;

-- Prescriber 1881634483 had the highest total number of claims at 99707.
    
--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
	
SELECT 
	nppes_provider_first_name, 
	nppes_provider_last_org_name, 
	specialty_description, 
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription 
USING(npi)
GROUP BY nppes_provider_first_name, nppes_provider_last_org_name, specialty_description
ORDER BY total_claims DESC
LIMIT 1;

-- BRUCE PENDLEY, Family Practice, 99707

-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT DISTINCT(specialty_description), SUM(total_claim_count) as total_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
GROUP BY specialty_description
ORDER BY total_claims DESC
LIMIT 1;

-- Family Practice was the specialty with the highest total number of claims at 9,752,347.


--     b. Which specialty had the most total number of claims for opioids?

SELECT DISTINCT(specialty_description), 
				opioid_drug_flag, 
				SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING(drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description, opioid_drug_flag
ORDER BY total_claims DESC
LIMIT 1;

-- Nurse Practitioner had the highest number of claim for opioids at 900,845.

--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

SELECT specialty_description
FROM prescriber
WHERE specialty_description NOT IN (SELECT specialty_description 
							        FROM prescription 
							        INNER JOIN prescriber 
							        USING(npi))
GROUP BY specialty_description;

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

SELECT 
	specialty_description, 
    ROUND(COALESCE(100.0 * SUM(CASE WHEN opioid_drug_flag = 'Y'
                               THEN total_claim_count ELSE 0 END) / SUM(total_claim_count), 0), 1) 
					           AS percentage_of_opioids
FROM prescriber
LEFT JOIN prescription 
USING(npi)
LEFT JOIN drug  
USING(drug_name)
GROUP BY specialty_description
ORDER BY percentage_of_opioids DESC
LIMIT 10;

-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?

SELECT CAST(SUM(total_drug_cost) AS MONEY) 
			AS total_cost, 
			generic_name
FROM drug
INNER JOIN prescription
USING(drug_name)
GROUP BY generic_name
ORDER BY total_cost DESC
LIMIT 1;

-- INSULIN GLARGINE,HUM.REC.ANLOG had the highest total drug cost at $104,264,066.35

--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT generic_name, ROUND(SUM(total_drug_cost) / SUM(total_day_supply), 2) AS cost_per_day
FROM drug
INNER JOIN prescription
USING(drug_name)
GROUP BY generic_name
ORDER BY cost_per_day DESC
LIMIT 1;

-- C1 ESTERASE INHIBITOR has highest cost per day at $3495.22

-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

SELECT drug_name,
CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
ELSE 'neither'
END AS drug_type
FROM drug
ORDER BY drug_type;

--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT drug_type, CAST(SUM(total_drug_cost) AS MONEY) AS total_cost
FROM (
SELECT drug_name, total_drug_cost, 
CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
     WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
     ELSE 'neither'
     END AS drug_type
FROM prescription
INNER JOIN drug
USING(drug_name)
) AS d
GROUP BY drug_type
ORDER BY total_cost DESC;

-- More money was spent on opioids ($105,080,626.37) than antibiotics ($38,435,121.26).

-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT cbsa, COUNT(cbsa), cbsaname
FROM cbsa
WHERE cbsaname LIKE '%TN%'
GROUP BY cbsa, cbsaname;

-- There are 10 distinct CBSAs

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT cbsaname, SUM(population) AS total_population
FROM cbsa
INNER JOIN population
USING(fipscounty)
GROUP BY cbsaname
ORDER BY total_population DESC;

-- Nashville-Davidson--Murfreesboro--Franklin, TN has largest combined population (1,830,410) while Morristown, TN has the smallest with 116,352.


--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT *
FROM fips_county
INNER JOIN population
USING(fipscounty)
FULL JOIN cbsa
USING(fipscounty)
WHERE state = 'TN' AND cbsa IS NULL
ORDER BY population DESC
LIMIT 1;

-- Sevier County had the largest population (95,523) without a CBSA.

-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;

-- 9 drugs total

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT drug_name, total_claim_count,
	  (CASE WHEN opioid_drug_flag = 'Y' THEN 'Yes' ELSE 'No'
	   END) as opioid
FROM prescription
INNER JOIN drug
USING(drug_name)
WHERE total_claim_count >= 3000
ORDER BY opioid DESC;

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT nppes_provider_last_org_name, 
	   nppes_provider_first_name, 
	   drug_name, 
	   total_claim_count, 
	   (CASE WHEN opioid_drug_flag = 'Y' THEN 'Yes' ELSE 'No'
	   END) as opioid
FROM prescription
INNER JOIN drug
USING(drug_name)
INNER JOIN prescriber
USING(npi)
WHERE total_claim_count >= 3000;

-- David Coffey

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT npi, drug.drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
AND nppes_provider_city = 'NASHVILLE'
AND drug.opioid_drug_flag = 'Y';

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT p.npi, 
	   d.drug_name,
       COALESCE(SUM(p2.total_claim_count), 0) AS claims_per_drug
FROM prescriber AS p
CROSS JOIN drug AS d
LEFT JOIN prescription AS p2
USING(npi, drug_name)
WHERE specialty_description = 'Pain Management'
  AND nppes_provider_city = 'NASHVILLE'
  AND opioid_drug_flag = 'Y'
GROUP BY p.npi, d.drug_name
ORDER BY claims_per_drug DESC;
    
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT p.npi, 
	   d.drug_name,
       COALESCE(SUM(p2.total_claim_count), 0) AS claims_per_drug
FROM prescriber AS p
CROSS JOIN drug AS d
LEFT JOIN prescription AS p2
USING(npi, drug_name)
WHERE specialty_description = 'Pain Management'
  AND nppes_provider_city = 'NASHVILLE'
  AND opioid_drug_flag = 'Y'
GROUP BY p.npi, d.drug_name
ORDER BY claims_per_drug DESC;

-- 1. How many npi numbers appear in the prescriber table but not in the prescription table?

SELECT COUNT(DISTINCT prescriber.npi)
FROM prescriber
LEFT JOIN prescription
USING(npi)
WHERE prescription.npi IS NULL;
							        
-- 2.
--     a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT generic_name, SUM(total_claim_count) AS top_five
FROM drug
INNER JOIN prescription
USING(drug_name)
INNER JOIN prescriber
USING(npi)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY top_five DESC
LIMIT 5;

--     b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT generic_name, SUM(total_claim_count) AS top_five
FROM drug
INNER JOIN prescription
USING(drug_name)
INNER JOIN prescriber
USING(npi)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY top_five DESC
LIMIT 5;

--     c. Which drugs appear in the top five prescribed for both Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.

SELECT generic_name
FROM (
SELECT generic_name
FROM drug
INNER JOIN prescription
USING(drug_name)
INNER JOIN prescriber
USING(npi)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY SUM(total_claim_count) DESC
LIMIT 5
) AS family_practice

INTERSECT

SELECT generic_name
FROM (
SELECT generic_name
FROM drug
INNER JOIN prescription
USING(drug_name)
INNER JOIN prescriber
USING(npi)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY SUM(total_claim_count) DESC
LIMIT 5
) AS cardiology;

-- "ATORVASTATIN CALCIUM" and "AMLODIPINE BESYLATE" appear in both top five queries.

-- 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
--     a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
--     b. Now, report the same for Memphis.
--     c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

-- 4. Find all counties which had an above-average (for the state) number of overdose deaths in 2017. Report the county name and number of overdose deaths.

-- 5.
--     a. Write a query that finds the total population of Tennessee.
--     b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.