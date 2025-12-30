CREATE DATABASE human_resources;
USE human_resources;

select * from hr; -- review data to clean (contains mixed bdate/hire_date formats since originally all datatypes are text)

set sql_safe_updates = 0; -- allows us to update without where clause, need to change once data is cleaned 

-- will update dates to first be in the format mm-dd-yy to then convert to datatype date
-- the date format will be YY-MM-DD

UPDATE hr set birthdate = CASE 
	When birthdate like '%/%' then date_format(str_to_date(birthdate,'%m/%d/%Y'), '%Y-%m-%d')
	When birthdate like '%-%' then date_format(str_to_date(birthdate,'%m-%d-%Y'), '%Y-%m-%d')
	else NULL
end;

-- our birthdates are now in date format but the datatype of the column is still text so need to change that
Alter table hr 
Modify column birthdate Date;

-- now we are doig the same process for the hiredates to et them in the date format
UPDATE hr set hire_date = CASE 
	When hire_date like '%/%' then date_format(str_to_date(hire_date,'%m/%d/%Y'), '%Y-%m-%d')
	When hire_date like '%-%' then date_format(str_to_date(hire_date,'%m-%d-%Y'), '%Y-%m-%d')
	else NULL
end;
-- our hire_dates are now in date format but the datatype of the column is still text so need to change that
Alter table hr 
Modify column hire_date Date;
-- the termdate contains a time stamp but is in correct date format we just need to remove the timestamp 
UPDATE hr set termdate = if(termdate is not NULL and termdate != '', date(str_to_date(termdate,'%Y-%m-%d %H:%i:%s UTC')), '0000-00-00');
-- now update data type
SET sql_mode = 'ALLOW_INVALID_DATES'; -- allow the 0000-00-00 dates allowed in order to set as date datatype
Alter table hr 
Modify column termdate Date;

-- will add an age col for simplicity
Alter table hr Add column age int;
update hr set age = timestampdiff(YEAR,birthdate,curdate());
-- NOTE: some employee ages are <0 or under 18 which is not useful therefore we need to exclude those in the analysis 

-- ANALYSIS QUESTIONS -- 
-- 1. What is the gender breakdown of employees in the company? (keyword: breakdown so count)
Select gender, count(*) as count
from hr where age >= 18 and termdate like '0000-00-00'
group by gender;

-- 2. What is the race/ethnicity breakdown of employees in the company?
select race, count(*) as count
from hr where age >= 18 and termdate like '0000-00-00'
group by race order by count(*) DESC;

-- 3. What is the age distribution of employees in the company? (keyword: distribution so range)
-- select min(age) as 'youngest', max(age) as 'oldest'
-- from hr where age >= 18 and termdate like '0000-00-00';

select 
	case 
    when age >= 18 and age <= 24 then '18-24'
    when age >= 25 and age <= 34 then '25-34'
    when age >= 35 and age <= 44 then '35-44'
    when age >= 45 and age <= 54 then '45-54'
    when age >= 55 and age <= 64 then '55-64'
    else '65+'
    end as 'age_group', count(*) as 'count' 
    from hr where age >= 18 and termdate like '0000-00-00'
    group by `age_group` order by `age_group`;
    
select 
	case 
    when age >= 18 and age <= 24 then '18-24'
    when age >= 25 and age <= 34 then '25-34'
    when age >= 35 and age <= 44 then '35-44'
    when age >= 45 and age <= 54 then '45-54'
    when age >= 55 and age <= 64 then '55-64'
    else '65+'
    end as 'age_group',gender, count(*) as 'count' 
    from hr where age >= 18 and termdate like '0000-00-00'
    group by `age_group`,gender order by `age_group`,gender;    

-- 4. How many employees work at headquarters versus remote locations?
select location, count(*)
from hr where age >= 18 and termdate like '0000-00-00'
group by location;

-- 5. What is the average length of employment for employees who have been terminated?
select round(avg(datediff(termdate,hire_date))/365,0) as 'avg emp. length'
from hr where age >= 18 and termdate not like '0000-00-00' and termdate <= curdate();

-- 6. How does the gender distribution vary across departments?
select department, gender, count(*) from hr 
where age >= 18 and termdate like '0000-00-00'
group by department, gender
order by department;

-- 7. What is the distribution of job titles across the company?
select jobtitle, count(*) from hr 
where age >= 18 and termdate like '0000-00-00'
group by jobtitle order by jobtitle;

-- 8. Which department has the highest turnover rate? (rate at which employees leave company)
Select department, `total_count`, `terminated_count`, terminated_count/total_count as 'termination rate'
from (
select department, count(*) as 'total_count',
sum(case when termdate not like '0000-00-00' and termdate <= curdate() then 1 else 0 end) as 'terminated_count'
from hr where age >= 18
group by department) as sub
order by `termination rate` desc;


-- 9. What is the distribution of employees across locations by state?
select location_state, count(*) from hr
where age >= 18 and termdate like '0000-00-00' 
group by location_state
order by count(*) desc;


-- 10. How has the company's employee count changed over time based on hire and term dates?
select `year`, `hires`, `terminations`, `hires`- `terminations` as 'net_change',
round((`hires`- `terminations`)/ `hires` * 100,2) as 'emp_count_change'
from (
select year(hire_date) as 'year', count(*) as 'hires',
sum(case when termdate not like '0000-00-00' and termdate <= curdate() then 1 else 0 end) as 'terminations'
from hr where age >= 18 group by `year`) as sub
order by `year` ASC;


-- 11. What is the tenure distribution for each department?
select department, round(avg(datediff(termdate, hire_date)/365), 0) as 'avg_tenure'
from hr where age >= 18 and termdate <= curdate() and termdate not like '0000-00-00'
group by department;
















