/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

Select *
From SQL_Portfolio_Project..['Covid-Deaths$']
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From SQL_Portfolio_Project..['Covid-Deaths$']
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From SQL_Portfolio_Project..['Covid-Deaths$']
Where location like 'Canada'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From SQL_Portfolio_Project..['Covid-Deaths$']
--Where location like 'Canada'
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From SQL_Portfolio_Project..['Covid-Deaths$']
--Where location like 'Canada'
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as bigint)) as TotalDeathCount
From SQL_Portfolio_Project..['Covid-Deaths$']
--Where location like 'Canada'
Where continent is not null 
Group by Location
order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contbigintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as bigint)) as TotalDeathCount
From SQL_Portfolio_Project..['Covid-Deaths$']
--Where location like 'Canada'
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as bigint)) as total_deaths, SUM(cast(new_deaths as bigint))/SUM(New_Cases)*100 as DeathPercentage
From SQL_Portfolio_Project..['Covid-Deaths$']
--Where location like 'Canada'
where continent is not null 
--Group By date
order by 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From SQL_Portfolio_Project..['Covid-Deaths$'] dea
Join SQL_Portfolio_Project..['Covid-Vaccinations$'] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From SQL_Portfolio_Project..['Covid-Deaths$'] dea
Join SQL_Portfolio_Project..['Covid-Vaccinations$'] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From SQL_Portfolio_Project..['Covid-Deaths$'] dea
Join SQL_Portfolio_Project..['Covid-Vaccinations$'] vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated
Where location ='Canada'
Order by Date


-- Creating View to store data for later visualizations
-- 1
create view DeathPercentageSG as
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from SQL_Portfolio_Project..['Covid-Deaths$']
where location like 'Canada'

-- 2
create view InfectionRateSG as
select location, date, total_cases, population, (total_cases/population)*100 as InfectionRate
from SQL_Portfolio_Project..['Covid-Deaths$']
where location like 'Canada'

-- 3
create view GlobalInfectionRate as
select location, population, max(total_cases) as HighestInfectionCount, max((total_cases)/population)*100 as HighestInfectionRate
from SQL_Portfolio_Project..['Covid-Deaths$']
group by location, population

-- 4
create view GlobalDeathRate as
select location, population, max((total_deaths)/population)*100 as HighestDeathRate
from SQL_Portfolio_Project..['Covid-Deaths$']
group by location, population

-- 5 
create view GlobalDeathCount as
select location, max(cast(total_deaths as bigbigint)) as DeathCount
from SQL_Portfolio_Project..['Covid-Deaths$']
where continent is not NULL
group by location

-- 6
Create view RollingVaccination as
select continent, location, date, population, new_vaccinations, sum(cast(new_vaccinations as bigbigint)) OVER (PARTITION BY location ORDER BY location, date) as total_vaccination
from SQL_Portfolio_Project..['Covid-Vaccinations$']
where continent is not NULL

-- 7
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From SQL_Portfolio_Project..['Covid-Deaths$'] dea
Join SQL_Portfolio_Project..['Covid-Vaccinations$'] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 


--Dropping view  PercentPopulationVaccinated
DROP View PercentPopulationVaccinated
