SELECT *
FROM covid_vaccinations_csv
LIMIT 5;

SELECT *
FROM covid_deaths_csv
LIMIT 50;

UPDATE covid_deaths_csv 
SET `date` = str_to_date(`date`, '%m/%d/%Y')

UPDATE covid_vaccinations_csv 
SET `date` = str_to_date(`date`, '%m/%d/%Y')

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths_csv
ORDER BY 1,2 ;

-- Looking at the total cases vs the total deaths
-- Shows the likelihood of dying if you contract Covid-19 in the United States over time
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as 'Death Percentage'
FROM covid_deaths_csv
WHERE location = 'United States'
ORDER BY 1,2;

-- Looking at the total cases vs the population for the United States
SELECT location, date, total_cases, population, (total_cases/population)*100 as 'Percent of Pop infected'
FROM covid_deaths_csv
-- WHERE location = 'United States'
ORDER BY 1,2;

-- Which countries have the highest infection rates compared to their population 
SELECT location, population, MAX(total_cases) AS 'Total Infections', (MAX(total_cases)/population)*100 as 'Percent of Pop infected'
FROM covid_deaths_csv
GROUP BY location, population
ORDER BY 4 DESC

-- Showing the countries with the highest death count per population 
SELECT location, population, MAX(total_deaths) AS 'Total Deaths', (MAX(total_deaths)/population)*100 as 'Percent of Population dead from Covid'
FROM covid_deaths_csv
WHERE continent <> ''
GROUP BY location, population
ORDER BY 4 DESC

-- Let's break things down by Continent
SELECT continent, SUM(new_deaths) AS 'Total Deaths'
FROM covid_deaths_csv
WHERE continent <> ''
GROUP BY continent
ORDER BY 2 DESC


-- Global Numbers
SELECT SUM(new_cases) AS 'Total Cases', SUM(new_deaths) AS 'Total Deaths', (SUM(new_deaths)/SUM(new_cases))*100 AS 'Death Percentage if Tested Positive'
FROM covid_deaths_csv
WHERE continent <> ''
ORDER BY 1,2;

-- Lets now join the covid vaccinations table
-- Looking at the total population vs vaccinations
CREATE INDEX index1
ON covid_deaths_csv (location, date);

CREATE INDEX index2
ON covid_vaccinations_csv (location, date);


-- Looking at the Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition BY location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated 
FROM covid_deaths_csv dea
JOIN covid_vaccinations_csv vac 
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent <> ''
ORDER BY 2,3;

-- Use CTE
with PopvsVac as
(SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition BY location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated 
FROM covid_deaths_csv dea
JOIN covid_vaccinations_csv vac 
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent <> ''
ORDER BY 2,3)

SELECT continent, location, date, population, RollingPeopleVaccinated, (RollingPeopleVaccinated/Population)*100 AS 'Percent of Population Vaccinated'
FROM PopvsVac;


-- Use Temp Table
CREATE TEMPORARY TABLE PercentPopVaccinated(
Continent varchar(255),
Location varchar(255),
Date datetime,
Population bigint,
New_vaccinations int,
RollingPeopleVaccinated bigint);

INSERT INTO PercentPopVaccinated
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition BY location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated 
FROM covid_deaths_csv dea
JOIN covid_vaccinations_csv vac 
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent <> ''


SELECT *, (RollingPeopleVaccinated/population)*100 as 'Percent of the Population Vaccinated'
FROM PercentPopVaccinated;

-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated as 
(SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition BY location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated 
FROM covid_deaths_csv dea
JOIN covid_vaccinations_csv vac 
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent <> ''
ORDER BY 2,3);

SELECT location, date, RollingPeopleVaccinated
FROM percentpopulationvaccinated;
