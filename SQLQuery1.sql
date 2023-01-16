SELECT * 
FROM PortfolioProject..['Cowid deaths$'] 
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT * FROM PortfolioProject..['Cowid vaccination$'] ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..['Cowid deaths$']
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at total cases vs Total Deaths
-- Shows likelihood of dying if you have covid in India

SELECT location, date, total_cases, total_deaths,Round((total_deaths/total_cases)*100,2) as Death_Percentage
FROM PortfolioProject..['Cowid deaths$']
WHERE location like 'India'
ORDER BY 1,2

-- Looking at total cases vs Population
-- Shows what % of population got covid

SELECT location, date, total_cases, population,Round((total_cases/population)*100,2) as cases_per_population_Percentage
FROM PortfolioProject..['Cowid deaths$']
WHERE location like 'India'
ORDER BY 1,2

-- Countries with Highest Infection Rate compared to Population

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount,  ROUND(MAX((total_cases/population))*100,2) AS PercentPopulationInfected
FROM PortfolioProject..['Cowid deaths$']
WHERE continent IS NOT NULL
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

-- Countries with Highest Death Count

SELECT Location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..['Cowid deaths$']
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- Analysis for different continents

SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..['Cowid deaths$']
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


-- GLOBAL NUMBERS

-- Total Death percentage

SELECT
	SUM(new_cases) AS Total_Cases,
	SUM(cast(new_deaths as int)) AS Total_Deaths,
	ROUND(SUM(cast(new_deaths as int))/ SUM(new_cases)*100,2) AS Death_Percentage
FROM PortfolioProject..['Cowid deaths$']
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Total death percentage in each date

SELECT date,
	SUM(new_cases) AS Total_Cases,
	SUM(cast(new_deaths as int)) AS Total_Deaths,
	ROUND(SUM(cast(new_deaths as int))/ SUM(new_cases)*100,2) AS Death_Percentage
FROM PortfolioProject..['Cowid deaths$']
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT d.continent,d.location, d.date, d.population, v.new_vaccinations,
	SUM(CONVERT(bigint,v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location,d.date) AS People_Vaccinated_till_date
FROM PortfolioProject..['Cowid deaths$'] AS d
JOIN PortfolioProject..['Cowid vaccination$'] AS V
	ON d.location=v.location AND d.date=v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3

-- Use of Temporary Table for storing Max of people vaccinated

WITH Pop_vs_Vac( continent, location, date, population, new_vaccinations, People_Vaccinated_till_date)
AS
(
	SELECT d.continent,d.location, d.date, d.population, v.new_vaccinations,
		SUM(CONVERT(bigint,v.new_vaccinations)) 
			OVER (PARTITION BY d.location ORDER BY d.location,d.date) AS People_Vaccinated_till_date
	FROM PortfolioProject..['Cowid deaths$'] AS d
	JOIN PortfolioProject..['Cowid vaccination$'] AS V
		ON d.location=v.location AND d.date=v.date
	WHERE d.continent IS NOT NULL
)
SELECT *,
	ROUND((People_Vaccinated_till_date/population)*100,2) AS PercentageVaccinated
FROM Pop_vs_Vac


-- Create Table Approach to make a temporary Table

DROP TABLE IF EXISTS #PercentPopVaccinated
CREATE TABLE #PercentPopVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
People_Vaccinated_till_date float
)
INSERT INTO #PercentPopVaccinated
	SELECT d.continent,d.location, d.date, d.population, v.new_vaccinations,
		SUM(CONVERT(bigint,v.new_vaccinations)) 
			OVER (PARTITION BY d.location ORDER BY d.location,d.date) AS People_Vaccinated_till_date
	FROM PortfolioProject..['Cowid deaths$'] AS d
	JOIN PortfolioProject..['Cowid vaccination$'] AS V
		ON d.location=v.location AND d.date=v.date

SELECT *,
	ROUND((People_Vaccinated_till_date/population)*100,2) AS PercentageVaccinated
FROM #PercentPopVaccinated 
ORDER  BY Location,Date


-- Creating View to store data for later visualizations


CREATE VIEW PercentPopulationVaccinated AS
	SELECT d.continent,d.location, d.date, d.population, v.new_vaccinations,
		SUM(CONVERT(bigint,v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location,d.date) AS People_Vaccinated_till_date
	FROM PortfolioProject..['Cowid deaths$'] AS d
	JOIN PortfolioProject..['Cowid vaccination$'] AS V
		ON d.location=v.location AND d.date=v.date
	WHERE d.continent IS NOT NULL


--Tableau visualizations
-- 1
SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(CAST(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM PortfolioProject..['Cowid deaths$']
WHERE continent is not null 
ORDER BY 1,2

--2
SELECT continent, SUM(CAST(new_deaths as int)) as total_deaths
FROM PortfolioProject..['Cowid deaths$']
WHERE continent is not null 
GROUP BY continent
ORDER BY 2 DESC

--3
SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount,  ROUND(MAX((total_cases/population))*100,2) AS PercentPopulationInfected
FROM PortfolioProject..['Cowid deaths$']
WHERE continent IS NOT NULL
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

--4
SELECT Location, Population, Date, MAX(total_cases) AS HighestInfectionCount,  ROUND(MAX((total_cases/population))*100,2) AS PercentPopulationInfected
FROM PortfolioProject..['Cowid deaths$']
WHERE continent IS NOT NULL
GROUP BY Location, Population,date
ORDER BY PercentPopulationInfected DESC