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

--calculate the death rate for each location
SELECT location, CAST(total_deaths AS float)/CAST(total_cases AS float)*100 AS death_rate
FROM Covid..CovidDeath
ORDER BY 1

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
GROUP BY location, date
HAVING MAX(CAST(total_deaths AS float)/CAST(total_cases AS float)*100) BETWEEN 10 AND 100 
ORDER BY peak_death_rate DESC, date ASC

--selecting countries with death rate >= 20%
SELECT DISTINCT location
FROM Covid..CovidDeath
WHERE continent IS NOT NULL AND CAST(total_deaths AS float)/CAST(total_cases AS float)*100 >= 20
ORDER BY location

--group them into continents
SELECT continent, COUNT(distinct location)
FROM Covid..CovidDeath
WHERE continent IS NOT NULL AND CAST(total_deaths AS float)/CAST(total_cases AS float)*100 >= 20
GROUP BY continent
ORDER BY continent

--finding out which of that one country is in Oceania
SELECT location
FROM Covid..CovidDeath
WHERE CAST(total_deaths AS float)/CAST(total_cases AS float)*100 >= 20 AND continent = 'Oceania'
--it is Northern Mariana Islands
