--Dataset: Covid data from Our World In Data in 2023
--Source: https://ourworldindata.org/explorers/coronavirus-data-explorer
--Queried using: SQL Server

--checking if tables imported correctly
SELECT *
FROM Covid..CovidDeath
ORDER BY 3, 4

--select the latest total cases and total deaths per million for each location
SELECT t1.location, t1.date, t1.total_cases_per_million, t1.total_deaths_per_million
FROM Covid..CovidDeath t1
INNER JOIN (
	SELECT location, MAX(date) as latest_date
	FROM Covid..CovidDeath
	GROUP BY location) t2
ON t1.location = t2.location AND t1.date = latest_date
ORDER BY 1, 2

--calculate the MAX death rate for Italy, Brazil, USA, India, and Mexico
SELECT location, MAX(CAST(total_deaths AS float)/CAST(total_cases AS float)*100) AS peak_death_rate
FROM Covid..CovidDeath
WHERE location IN ('Italy', 'Brazil', 'United States', 'India', 'Mexico')
GROUP BY location
ORDER BY 1

--calculate the MAX death rate for each location, order by highest death rate first
SELECT location, MAX(CAST(total_deaths AS float)/CAST(total_cases AS float)*100) AS peak_death_rate
FROM Covid..CovidDeath
GROUP BY location
ORDER BY 2 DESC
--found some interesting results where the death rate is abnormal (> 100)

--investigate why
SELECT location, date, total_deaths, total_cases, CAST(total_deaths AS float)/CAST(total_cases AS float)*100 AS peak_death_rate
FROM Covid..CovidDeath
WHERE location IN ('France', 'Mauritania', 'Zimbabwe', 'Germany')
ORDER BY peak_death_rate DESC
--suspect might be due to reporting errors

--examine death rate that are between 10% and 100%
SELECT location, date, max(total_deaths), Max(total_cases),
	MAX(CAST(total_deaths AS float)/CAST(total_cases AS float)*100) AS peak_death_rate
FROM Covid..CovidDeath
WHERE continent IS NOT NULL
GROUP BY location, date
HAVING MAX(CAST(total_deaths AS float)/CAST(total_cases AS float)*100) BETWEEN 11 AND 99
ORDER BY peak_death_rate DESC, date ASC

--create stored procedure for user to enter country name and get latest death rate
USE Covid
GO
CREATE PROCEDURE AddCountry
@country varchar(255)
AS
CREATE TABLE #DeathRateByCountry (
Country varchar(255),
Date date,
DeathRate float(24)
)

INSERT INTO #DeathRateByCountry
SELECT location, MAX(date), MAX(CAST(total_deaths AS float)/CAST(total_cases AS float)*100)
FROM Covid..CovidDeath
WHERE location = @country
GROUP BY location

SELECT *
FROM #DeathRateByCountry

--testing to see if it works
EXEC AddCountry
@country = 'New Zealand'

--selecting countries with death rate >= 20%
SELECT DISTINCT location
FROM Covid..CovidDeath
WHERE continent IS NOT NULL AND CAST(total_deaths AS float)/CAST(total_cases AS float)*100 >= 20
ORDER BY location

--group them into continents and make it into a view
USE Covid
GO
CREATE VIEW DeathRateOver20
AS
SELECT continent, COUNT(distinct location) AS country_count
FROM Covid..CovidDeath
WHERE continent IS NOT NULL AND CAST(total_deaths AS float)/CAST(total_cases AS float)*100 >= 20
GROUP BY continent

--finding out which of that one country is in Oceania
SELECT location
FROM Covid..CovidDeath
WHERE CAST(total_deaths AS float)/CAST(total_cases AS float)*100 >= 20 AND continent = 'Oceania'
--it is Northern Mariana Islands

--finding the latest population vaccination % for each location
WITH Vax (location, population, TotalVax) AS (
	SELECT d.location, d.population, 
		SUM(CONVERT(bigint, v.new_vaccinations)) AS TotalVax
	FROM Covid..CovidDeath d
	JOIN Covid..CovidVax v
	ON d.location = v.location AND d.date = v.date
	WHERE d.continent IS NOT NULL AND v.new_vaccinations IS NOT NULL
	GROUP BY d.location, d.population)
SELECT location, TotalVax/population*100 AS PercentPopVaxed
FROM Vax
ORDER BY 2 DESC
