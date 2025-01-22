-- Viewing the dataset --
Select * 
from PortfolioProject1..['Covid Deaths$']
where continent is not null
order by 3,4

Select * 
from PortfolioProject1..['Covid Vaccinations$']
order by 3,4


-- Selecting key columns for further analysis from Covid Deaths --

select Location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject1..['Covid Deaths$']
order by 1,2

--Analyzing total cases vs total deaths --
-- Calculates the death percentage to understand the severity of cases in each location

select Location, date, total_cases, cast(total_deaths as int) as TotalDeathInt, (cast (total_deaths as float)) / (cast(total_cases as float))*100 as DeathPercentage
from PortfolioProject1..['Covid Deaths$']
order by 1,2


-- Likelihood of dying from Covid in a country --
-- Filters for the United States and calculates death percentage to assess impact
SELECT
    Location,
    date,
    total_cases,
    total_deaths,
    CASE
        WHEN TRY_CAST(total_cases AS DECIMAL(18, 2)) = 0 THEN NULL  -- handle division by zero
        ELSE (TRY_CAST(total_deaths AS DECIMAL(18, 2)) / TRY_CAST(total_cases AS DECIMAL(18, 2))) * 100
    END AS DeathPercentage
FROM
    PortfolioProject1..['Covid Deaths$']
where location like '%states%'
ORDER BY
    1, 2;


-- Analyzing total cases vs population --
-- Looking at US

select 
	Location, 
	date, 
	population, 
	total_cases, 
	(total_cases/population)*100 as PercentPopulationInfection
from PortfolioProject1..['Covid Deaths$']
WHERE location LIKE '%state%'
order by 1,2


-- Finding the country with the highest infection rates relative to its population -- 
-- Groups by continent and displays the highest infection rates
select 
	continent, 
	population, 
	MAX(total_cases) as HighestInfectionCount, 
	MAX((total_cases/population))*100 as PercentPopulationInfected
from PortfolioProject1..['Covid Deaths$']
where continent is not null
group by continent, population
order by PercentPopulationInfected desc

-- Showing the continents with the highest death count --
-- Aggregates total deaths by continent 

select 
	continent, 
	MAX(CAST(total_deaths as int)) as TotalDeathCount
from PortfolioProject1..['Covid Deaths$']
where continent is not null
group by continent
order by TotalDeathCount desc


--NOW LETS BREAK THINGS DOWN BY CONTINENT --


-- Showing the continents with the highest death count
-- Aggregates total deaths by continent

select 
	continent, 
	MAX(CAST(total_deaths as int)) as TotalDeathCount
from PortfolioProject1..['Covid Deaths$']
where continent is not null
group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS --
-- Aggregate new cases and deaths globally by date to analyze trends over time

select 
	date, 
	sum(new_cases) as total_cases, 
	sum(cast(new_deaths as int)) as total_deaths, 
	sum(cast(new_deaths as float))/sum(cast(new_cases as float))*100 as DeathPercentage
from PortfolioProject1..['Covid Deaths$']
where continent is not null
group by date
order by 1,2



-- Aggregating whole population data for a summary
SELECT
    SUM(new_cases) as total_cases,
    SUM(CAST(new_deaths AS INT)) as total_deaths, 
    SUM(CAST(new_deaths AS FLOAT)) / NULLIF(SUM(CAST(new_cases AS FLOAT)), 0) * 100.0 as DeathPercentage
FROM
    PortfolioProject1..['Covid Deaths$']
WHERE
    continent IS NOT NULL
--GROUP BY date
ORDER BY 1, 2;



-- Analyzing global data by date
-- Aggregates new cases and deaths to study trends over time
SELECT
    date,
    SUM(new_cases) as total_cases,
    SUM(CAST(new_deaths AS INT)) as total_deaths, 
    SUM(CAST(new_deaths AS FLOAT)) / NULLIF(SUM(CAST(new_cases AS FLOAT)), 0) * 100.0 as DeathPercentage
FROM
    PortfolioProject1..['Covid Deaths$']
WHERE
    continent IS NOT NULL
GROUP BY
    date
ORDER BY
    1, 2;



-- Analyzing population vs vaccinations with rolling totals -- 
-- Joins Covid Deaths and Vaccinations tables to calculate cumulative vaccinations per location

select 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject1..['Covid Deaths$'] dea
join PortfolioProject1..['Covid Vaccinations$'] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3 



-- Using a CTE for rolling vaccination totals per continent -- 

with PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
select 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
from PortfolioProject1..['Covid Deaths$'] dea
join PortfolioProject1..['Covid Vaccinations$'] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

)
select *, (RollingPeopleVaccinated/Population)*100
from PopvsVac



-- Temporary table to analyze vaccination percentages -- 
-- Stores cumulative vaccination data temporarily for further analysis

drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

-- Inserting vaccination data into the temporary table
Insert into #PercentPopulationVaccinated
select 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	sum(convert(numeric,vac.new_vaccinations)) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from PortfolioProject1..['Covid Deaths$'] dea
join PortfolioProject1..['Covid Vaccinations$'] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3


-- Displaying vaccination percentages from the temporary table
select *, (RollingPeopleVaccinated/Population)*100 as PercentPopulationVaccinated
from #PercentPopulationVaccinated;


-- Creating a view to store vaccination data for visualization

DROP VIEW PortfolioProject.PercentPopulationVaccinated;

create view PercentPopulationVaccinated
 as
select 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	sum(convert(numeric,vac.new_vaccinations)) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
from PortfolioProject1..['Covid Deaths$'] dea
join PortfolioProject1..['Covid Vaccinations$'] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null


CREATE VIEW PortfolioProject1.PercentPopulationVaccinated
AS
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(numeric, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM
    PortfolioProject1..['Covid Deaths$'] dea
JOIN
    PortfolioProject1..['Covid Vaccinations$'] vac
ON
    dea.location = vac.location
    AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL;



select PortfolioProject1
from INFORMATION_SCHEMA.SCHEMATA
where PortfolioProject1 = 'PortfolioProject1';


-- Verifying schema existence
-- Ensures the specified schema exists in the database

SELECT schema_name
FROM INFORMATION_SCHEMA.SCHEMATA
WHERE schema_name = 'PortfolioProject1';



CREATE SCHEMA PortfolioProject1;



CREATE VIEW dbo.PercentPopulationVaccinated
AS
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(numeric, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM
    PortfolioProject1..['Covid Deaths$'] dea
JOIN
    PortfolioProject1..['Covid Vaccinations$'] vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL;



-- Selecting data from the view for analysis and visualization

select * 
from dbo.PercentPopulationVaccinated;