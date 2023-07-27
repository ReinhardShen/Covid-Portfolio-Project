SELECT *
FROM PortfolioProject..CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY 3,4

SELECT *
FROM PortfolioProject..CovidVaccinations
ORDER BY 3,4



--Select Data that I am Going to Use
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2



--Looking at Total Cases vs Total Deaths
--The Total Cases and Total Deaths' data types are wrong so they need to be converted first
--Shows the likelihood of dying if you was infected by Covid 19 in Indonesia
SELECT 
	Location, 
	date, 
	total_cases, 
	total_deaths, 
	(CAST(total_deaths AS FLOAT)/CAST(total_cases AS FLOAT))*100 AS DeathPercentage
FROM 
	PortfolioProject..CovidDeaths
WHERE 
	Location like '%Indonesia%'
ORDER BY 1,2



--Looking at TotalCases vs Population
--Shows what percentage of population got Covid 19
SELECT 
	Location, 
	date, 
	Population, 
	total_cases, 
	(CAST(total_deaths AS FLOAT)/CAST(population AS FLOAT))*100 AS PercentPopulationInfected
FROM 
	PortfolioProject..CovidDeaths
--WHERE 
--	Location like '%Indonesia%'
ORDER BY 1,2



--Looking at Countries with Highest Infection Rate Compared to Population
SELECT 
	Location, 
	Population, 
	MAX(total_cases) AS HighestInfectionCount, 
	MAX((CAST(total_cases AS FLOAT)/CAST(population AS FLOAT))*100) AS PercentPopulationInfected
FROM 
	PortfolioProject..CovidDeaths
--WHERE 
--	Location like '%Indonesia%'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC



--Showing Countries with Highest Death Count per Population
SELECT 
	Location, 
	MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM 
	PortfolioProject..CovidDeaths
WHERE
	Continent IS NOT NULL --to avoid including continent data inside the table as there are continents data along with the countries
--	Location like '%Indonesia%'
GROUP BY Location
ORDER BY TotalDeathCount DESC



--Grouping by Continent
--Showing Continent with The Highest Death Count
SELECT 
	Continent, 
	MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM 
	PortfolioProject..CovidDeaths
WHERE
	Continent IS NOT NULL --to avoid including continent data inside the table as there are continents data along with the countries
--	Location like '%Indonesia%'
GROUP BY Continent
ORDER BY TotalDeathCount DESC



--Global Numbers
SELECT  
	SUM(new_cases) AS Cases, --instead of using total cases per day which we can't sum, we use sum of new cases instead to know sum of global total cases each day
	SUM(CAST(new_deaths AS INT)) AS Deaths,
	ISNULL(SUM(CAST(new_deaths AS INT))/NULLIF(SUM(new_cases),0),0) AS DeathPercentage --SQL can't divide 0 by something
FROM 
	PortfolioProject..CovidDeaths
WHERE 
	Continent IS NOT NULL
--	Location like '%Indonesia%'
ORDER BY 1,2



--Looking at Total Population vs Vaccinations
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.Location, dea.date) AS RollingPeopleVaccinated
--	(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3



--Use CTE
WITH 
	PopvsVac(Continent, Location, Date, Population, New_Vaccinatations, RollingPeopleVaccinated) 
AS
(
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.Location, dea.date) AS RollingPeopleVaccinated
--	(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac



--Timetable
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.Location, dea.date) AS RollingPeopleVaccinated
--	(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated



--Creating View to Store Data for Later Visualizations
CREATE VIEW PercentPopulationVaccinated AS 
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.Location, dea.date) AS RollingPeopleVaccinated
--	(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3



SELECT *
FROM PercentPopulationVaccinated
