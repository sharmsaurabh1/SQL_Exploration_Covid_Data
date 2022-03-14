select * from SQL_Portfolio_Project.dbo.['Covid-Deaths$']
order by 3,4

-- Select Data that we are going to be using for reviewing purposes
select location, date, total_cases, new_cases, total_deaths, population
from SQL_Portfolio_Project..['Covid-Deaths$']
order by 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract Covid in Canada
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from SQL_Portfolio_Project..['Covid-Deaths$']
where location like 'Canada'
order by date

-- Looking at the Total Cases vs Population
-- shows likelihood of getting Covid in Canada
select location, date, total_cases, population, (total_cases/population)*100 as InfectionRate
from SQL_Portfolio_Project..['Covid-Deaths$']
where location like 'Canada'
order by date

-- Looking at countries with highest daily Infection Rate compared to Population
-- shows location with highest infection rate
select location, population, max(total_cases) as HighestInfectionCount, max((total_cases)/population)*100 as HighestInfectionRate
from SQL_Portfolio_Project..['Covid-Deaths$']
group by location, population
order by HighestInfectionRate desc

-- Looking at countries with highest death rates
select location, population, max((total_deaths)/population)*100 as HighestDeathRate
from SQL_Portfolio_Project..['Covid-Deaths$']
group by location, population
order by HighestDeathRate desc

-- Looking at countries with highest total death count
-- data type of total_deaths is 'nvarchar' which does not allow SUM to be performed. We have to make use of CAST.
-- we have to remove locations which appears to be continents instead as well
select location, max(cast(total_deaths as bigint)) as DeathCount
from SQL_Portfolio_Project..['Covid-Deaths$']
where continent is not NULL
group by location
order by DeathCount desc

-- Looking at number of new cases and deaths per day for the entire world
-- data type of new_deaths is 'nvarchar' which does not allow SUM to be performed. We have to make use of CAST.
select date, sum(new_cases) as DailyNewCases, sum(cast(new_deaths as bigint)) as DailyNewDeaths
from SQL_Portfolio_Project..['Covid-Deaths$']
group by date
order by date

-- Looking at number of people vaccinated in the countries' population
-- using windows SUM function to do a rolling sum of new vaccinations >> result is the same as total_vaccination column available in data
select continent, location, date, population, new_vaccinations, sum(cast(new_vaccinations as bigint)) OVER (PARTITION BY location ORDER BY location, date) as total_vaccination
from SQL_Portfolio_Project..['Covid-Vaccinations$']
where continent is not NULL

-- Use CTE to create table and then use the fields in the CTE table created for calculation
with PopvsVac (Continent, Location, Date, Population, New_Vaccinations, Total_Vaccinations)
as
(
select continent, location, date, population, new_vaccinations, sum(cast(new_vaccinations as bigint)) OVER (PARTITION BY location ORDER BY location, date) as total_vaccination
from SQL_Portfolio_Project..['Covid-Vaccinations$']
where continent is not NULL
)
select *, (Total_Vaccinations/Population)*100 as PercentageVaccinated
from PopvsVac

-- Use temp table (should return same result as using CTE from above)
-- have to specify data type
drop table if exists #PercentPopulationVaccinated -- this step makes it convenient to make alterations to the table
create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population bigint,
New_Vaccinations bigint,
Total_Vaccinations bigint
)

insert into #PercentPopulationVaccinated
select continent, location, date, population, new_vaccinations, sum(convert(bigint, new_vaccinations)) OVER (PARTITION BY location ORDER BY location, date) as total_vaccination
from SQL_Portfolio_Project..['Covid-Vaccinations$']
where continent is not NULL

select *,(Total_Vaccinations/Population)*100 as PercentageVaccinated
from #PercentPopulationVaccinated
Where location='Canada' 
Order by date desc 


-- Creating Views to store data for visualization later
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
select location, max(cast(total_deaths as bigint)) as DeathCount
from SQL_Portfolio_Project..['Covid-Deaths$']
where continent is not NULL
group by location

-- 6
Create view RollingVaccination as
select continent, location, date, population, new_vaccinations, sum(cast(new_vaccinations as bigint)) OVER (PARTITION BY location ORDER BY location, date) as total_vaccination
from SQL_Portfolio_Project..['Covid-Vaccinations$']
where continent is not NULL

-- 7
Create View PercentPopulationVaccinated as
with PopvsVac (Continent, Location, Date, Population, New_Vaccinations, Total_Vaccinations)
as
(
select continent, location, date, population, new_vaccinations, sum(cast(new_vaccinations as bigint)) OVER (PARTITION BY location ORDER BY location, date) as total_vaccination
from SQL_Portfolio_Project..['Covid-Vaccinations$']
where continent is not NULL
)
select *, (Total_Vaccinations/Population)*100 as PercentageVaccinated
from PopvsVac