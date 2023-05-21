Create Table Public."CovidDeath"(iso_code varchar(50),continent varchar(50),location varchar(50),date date,population_density float,total_cases float,new_cases float,new_cases_smoothed float,total_deaths float,new_deaths float,new_deaths_smoothed float,total_cases_per_million float,new_cases_per_million float,new_cases_smoothed_per_million float,total_deaths_per_million float,new_deaths_per_million float,new_deaths_smoothed_per_million float,reproduction_rate float,icu_patients float,icu_patients_per_million float,hosp_patients float,hosp_patients_per_million float,weekly_icu_admissions float,weekly_icu_admissions_per_million float,weekly_hosp_admissions float,weekly_hosp_admissions_per_million float)
select * from Public."CovidDeath"

COPY Public."CovidDeath" FROM 'D:\excel\CovidDeath.csv' DELIMITER ',' CSV HEADER ;

--SELECT DATA THAT WE ARE GOING TO USE
Select location, date, total_cases, new_cases, total_deaths, population_density
From Public."CovidDeath"
Order By 1,2
 
--Looking at total cases vs total deaths
--shows likelihood of dying in if contract covid in countries that ends with 'tan'
Select location, date, total_cases, total_deaths , (total_deaths/total_cases)*100 as death_percentage
From Public."CovidDeath"
Where location Like 'Uzbekistan'
Order By 1,2

--Looking at total cases and population density 
Select location, date, total_cases, population_density
From Public."CovidDeath"
Where location Like 'Uzbekistan'
Order By 1,2

--Looking at my country with highest infection rate compared to population 
Select dea.date, dea.location, population , MAX((total_cases/population)*100) as  HighestInfectionRate
From Public."CovidDeath" dea
Join Public."vaccination" vac
	ON dea.date=vac.date
 Where dea.location like '%Uzbekistan%'
Group by dea.location, dea.date, vac.population
order by HighestInfectionRate



--Showing countries with highest death count per population density
Select location, MAX(total_deaths) as TotalDeathCount
From Public."CovidDeath"
Where continent is not null
Group by location
order by TotalDeathCount desc

--Showing data by continents
Select continent,MAX(total_deaths) as TotalDeathCount
From Public."CovidDeath"
Where (continent, total_deaths) is not null
Group by continent
order by TotalDeathCount desc

--Global Numbers
Select date, Sum(new_cases) as total_cases, Sum(cast(new_deaths as int)) as total_deaths,COALESCE(Sum(cast(new_deaths as int)) /NULLIF(Sum(new_cases),0))*100 as percentage_death --total_cases, total_deaths , (total_deaths/total_cases)*100 as death_percentage
From Public."CovidDeath"
Where continent is not null
Group By date
Order By 1,2
 
--Updating null values to zero
UPDATE Public."CovidDeath" SET new_deaths=0 , new_cases=0 WHERE (new_cases,new_deaths) IS NULL


--Looking at Total population vs Total vaccination
Select dea.continent,dea.location, dea.date, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location Order By dea.location
, dea.date) as RollingPeopleVaccinated
From Public."CovidDeath" dea
Join Public."vaccination" vac
	On dea.location=vac.location and 
	dea.date=vac.date
where dea.continent is not null
order by 2,3

--USE CTE

with PopvsVac(continent, location, population_density, new_vaccinations, RollingPeopleVaccinated)
as 
(
Select dea.continent,dea.location,dea.population_density,  vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location Order By dea.location)
	as RollingPeopleVaccinated
From Public."CovidDeath" dea
Join Public."vaccination" vac
	On dea.location=vac.location and 
	dea.date=vac.date
where dea.continent is not null
)
--Ration of people vaccinated per area density
Select * , RollingPeopleVaccinated/population_density as RationOfVacinnaction
From PopvsVac

--Temp Table

Create temporary Table RatioPopulationVaccinated 
(
	Continent varchar(50),
	location varchar(50),
	population_density numeric,
	new_vaccinations numeric, 
	RollingPeopleVaccinated numeric
);
insert into RatioPopulationVaccinated (
Select dea.continent,dea.location,dea.population_density,  vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location Order By dea.location)
	as RollingPeopleVaccinated 
From Public."CovidDeath" dea
Join Public."vaccination" vac
	On dea.location=vac.location and 
	dea.date=vac.date
where dea.continent is not null)
;
--Ration of people vaccinated per area density
Select * , RollingPeopleVaccinated/population_density as RationOfVacinnaction
From RatioPopulationVaccinated


--Drop table RatioPopulationVaccinated

--Creating View to store data for later data visualization

Create View RatioPopulationVaccinatedView as
Select dea.continent,dea.location,dea.population_density,  vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location Order By dea.location)
	as RollingPeopleVaccinated 
From Public."CovidDeath" dea
Join Public."vaccination" vac
	On dea.location=vac.location and 
	dea.date=vac.date
where dea.continent is not null


Select * from Public."vaccination"

