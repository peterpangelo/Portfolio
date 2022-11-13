SELECT location
	,DATE
	,total_cases
	,new_cases
	,total_deaths
	,population
FROM Project1.dbo.CovidDeaths
ORDER BY 1
	,2

-- Looking at Total Cases vs Total Deaths
SELECT location
	,DATE
	,total_cases
	,total_deaths
	,(total_deaths / total_cases) * 100 AS DeathPercentage
FROM Project1.dbo.CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1
	,2

-- Looking at Total Cases vs Population
--Shows what percentage of population got Covid
SELECT location
	,DATE
	,population
	,total_cases
	,(total_cases / population) * 100 AS InfectionPercent
FROM Project1.dbo.CovidDeaths
--where location like '%states%'
ORDER BY 1
	,2

-- Looking at countries with highest infection rate to population
SELECT location
	,population
	,MAX(total_cases) AS HighestInfectionCount
	,MAX((total_cases / population)) * 100 AS PercentPopInfected
FROM Project1.dbo.CovidDeaths
--where location like '%states%'
--where population > 25000000
GROUP BY location
	,population
ORDER BY PercentPopInfected DESC

-- Showing countries with highest death count per population
SELECT location
	,Max(cast(total_deaths AS BIGINT)) AS TotalDeathCount
FROM Project1.dbo.CovidDeaths
--where location like '%states%'
--where population > 25000000
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

SELECT continent
	,Max(cast(total_deaths AS BIGINT)) AS TotalDeathCount
FROM Project1.dbo.CovidDeaths
--where location like '%states%'
--where population > 25000000
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Global numbers
SELECT SUM(new_cases) AS total_cases
	,SUM(cast(new_deaths AS INT)) AS total_deaths
	,SUM(cast(new_deaths AS INT)) / SUM(New_Cases) * 100 AS DeathPercentage
FROM Project1.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1
	,2
--Pulling in the vaccination table
WITH PopvsVac(continent, location, DATE, population, new_vaccinations, RollingPeopleVaccinated) AS --Use CTE (common table expression) to create a temp table to help with calculating a new column in the following query
	(
		SELECT dea.continent
			,dea.location
			,dea.DATE
			,dea.population
			,vac.new_vaccinations
			,sum(cast(vac.new_vaccinations AS FLOAT)) OVER (
				PARTITION BY dea.location ORDER BY dea.location
					,dea.DATE
				) AS RollingPeopleVaccinated --this creates a rolling function where the sum starts over per new location
			--, (RollingPeopleVaccinated/population)*100 
		FROM Project1.dbo.CovidDeaths dea
		JOIN Project1.dbo.CovidVaccinations vac ON dea.location = vac.location
			AND dea.DATE = vac.DATE
		WHERE dea.continent IS NOT NULL
		)

--order by 2,3
SELECT *
	,(RollingPeopleVaccinated / population) * 100
FROM PopvsVac

-- Temp table
DROP TABLE

IF EXISTS #PercentPopulationVaccinated
	CREATE TABLE #PercentPopulationVaccinated (
		Continent NVARCHAR(255)
		,Location NVARCHAR(255)
		,DATE DATETIME
		,Population NUMERIC
		,New_vaccinations FLOAT
		,RollingPeopleVaccinated FLOAT
		)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent
	,dea.location
	,dea.DATE
	,dea.population
	,vac.new_vaccinations
	,sum(cast(vac.new_vaccinations AS FLOAT)) OVER (
		PARTITION BY dea.location ORDER BY dea.location
			,dea.DATE
		) AS RollingPeopleVaccinated --this creates a rolling function where the sum starts over per new location
FROM Project1.dbo.CovidDeaths dea
JOIN Project1.dbo.CovidVaccinations vac ON dea.location = vac.location
	AND dea.DATE = vac.DATE

--where dea.continent is not null
SELECT *
	,(RollingPeopleVaccinated / Population) * 100
FROM #PercentPopulationVaccinated

-- Creating view to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated
AS
SELECT dea.continent
	,dea.location
	,dea.DATE
	,dea.population
	,vac.new_vaccinations
	,sum(cast(vac.new_vaccinations AS FLOAT)) OVER (
		PARTITION BY dea.location ORDER BY dea.location
			,dea.DATE
		) AS RollingPeopleVaccinated --this creates a rolling function where the sum starts over per new location
FROM Project1.dbo.CovidDeaths dea
JOIN Project1.dbo.CovidVaccinations vac ON dea.location = vac.location
	AND dea.DATE = vac.DATE
WHERE dea.continent IS NOT NULL

--DROP VIEW PercentPopulationVaccinated