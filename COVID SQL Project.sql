SELECT * 
FROM dbo.COVID_Deaths
WHERE continent IS NOT NULL
ORDER BY 3, 4;

-- SELECT * 
-- FROM dbo.COVID_Vaccinations 
-- ORDER BY 3, 4;

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM dbo.COVID_Deaths
ORDER BY 1, 2;

-- Looking at Total Cases vs Total Deaths
-- Presents the likelihood of dying if you contract COVID in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS death_percentage
FROM dbo.COVID_Deaths
WHERE location = 'Canada'
ORDER BY 1, 2;

-- Looking at Total Cases vs Population
-- Presents the percentage of population got COVID

SELECT location, date, population, total_cases, (total_cases/population) * 100 AS percent_population_infected
FROM dbo.COVID_Deaths
WHERE location = 'Canada'
ORDER BY 1, 2;

-- Looking at countries with the highest infection rate vs population

SELECT location, 
    population, 
    MAX(total_cases) AS highest_infection_count, 
    MAX((total_cases/population)) * 100 AS percent_population_infected
FROM dbo.COVID_Deaths
-- WHERE location = 'Canada'
GROUP BY location, population
ORDER BY percent_population_infected DESC;

-- Prsenting countries with the highest death count per population

SELECT location,
    MAX(total_deaths) AS total_death_count
FROM dbo.COVID_Deaths
-- WHERE location = 'Canada'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;

-- LET'S BREAK THINGS DOWN BY CONTINENT
-- Showing continents with the highest death count per populations

SELECT continent,
    MAX(CAST(total_deaths AS BIGINT)) AS total_death_count
FROM dbo.COVID_Deaths
-- WHERE location = 'Canada'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC;

--Global Numbers

SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases) * 100 AS death_percentage
FROM dbo.COVID_Deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2;

-- Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM dbo.COVID_Deaths AS dea
JOIN dbo.COVID_Vaccinations AS vac 
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

-- USE CTE

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

--Temp Table

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

-- Create view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM dbo.COVID_Deaths AS dea
JOIN dbo.COVID_Vaccinations AS vac 
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated