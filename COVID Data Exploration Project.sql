/*
COVID 19 Data Explorations

Skills Used: Joins, Common Table Expressions (CTE's), Window Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT * 
FROM dbo.COVID_Deaths
WHERE continent IS NOT NULL
ORDER BY 3, 4;

-- Select beginning data to begin with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM dbo.COVID_Deaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

-- Comparing: Total Cases vs Total Deaths
-- Presents the likelihood of dying if you contract COVID in my country (Canada)

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS death_percentage
FROM dbo.COVID_Deaths
WHERE location = 'Canada'
ORDER BY 1, 2;

-- Comparing: Total Cases vs Population
-- Presents the percentage of the population that got COVID

SELECT location, date, population, total_cases, (total_cases/population) * 100 AS percent_population_infected
FROM dbo.COVID_Deaths
WHERE location = 'Canada'
ORDER BY 1, 2;

-- Countries with the highest Infection Rate vs Population

SELECT location, 
    population, 
    MAX(total_cases) AS highest_infection_count, 
    MAX((total_cases/population)) * 100 AS percent_population_infected
FROM dbo.COVID_Deaths
-- WHERE location = 'Canada'
GROUP BY location, population
ORDER BY percent_population_infected DESC;

-- Prsenting countries with the highest Death Count per Population

SELECT location,
    MAX(total_deaths) AS total_death_count
FROM dbo.COVID_Deaths
-- WHERE location = 'Canada'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;

-- BREAKING THINGS DOWN BY CONTINENT

-- Continents with the highest Death Count per Population

SELECT continent,
    MAX(CAST(total_deaths AS BIGINT)) AS total_death_count
FROM dbo.COVID_Deaths
-- WHERE location = 'Canada'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC;

-- GLOBAL NUMBERS

SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases) * 100 AS death_percentage
FROM dbo.COVID_Deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2;

-- Total Population vs Vaccinations
-- Presents percentage of Population that has received at least one COVID Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM dbo.COVID_Deaths AS dea
JOIN dbo.COVID_Vaccinations AS vac 
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

-- Using CTE to perform Calculation on Partition By in previous query

WITH Pop_vs_Vac (Continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS 
(
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
    FROM dbo.COVID_Deaths AS dea
    JOIN dbo.COVID_Vaccinations AS vac 
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
    -- ORDER BY 2,3
)
SELECT *, (rolling_people_vaccinated/population)*100
FROM Pop_vs_Vac;

-- Using Temp Table to perform calculations on Partition By in previous query

CREATE TABLE #PercentPopulationVaccinated
(
continent NVARCHAR(255),
location NVARCHAR(255),
date DATETIME,
population NUMERIC,
new_vaccinations NUMERIC,
rolling_people_vaccinated NUMERIC
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM dbo.COVID_Deaths AS dea
JOIN dbo.COVID_Vaccinations AS vac 
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY 2,3

SELECT *, (rolling_people_vaccinated/population)*100
FROM #PercentPopulationVaccinated

-- Creating view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM dbo.COVID_Deaths AS dea
JOIN dbo.COVID_Vaccinations AS vac 
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY 2,3