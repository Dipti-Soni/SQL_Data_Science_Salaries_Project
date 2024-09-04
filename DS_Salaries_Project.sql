create database if not exists ds_salaries;
use ds_salaries;

/*1.You're a Compensation analyst employed by a multinational corporation. 
Your Assignment is to Pinpoint Countries who give work 100% remotely, for the title
 'managers’ Paying salaries Exceeding $90,000 USD*/
select distinct(company_location) from salaries
where remote_ratio = 100 and job_title like '%Manager%' and salary_in_usd > 90000;

/*2.As a remote work advocate working for a progressive HR tech startup who place their freshers’ in large tech firms. 
You're tasked WITH Identifying top 5 Countries having greatest count of large(company size) number of companies.*/
select company_location, count(*) from salaries
where experience_level = 'EN' and company_size = 'L'
group by company_location order by count(*) desc limit 5;

/*3. Picture yourself AS a data scientist Working for a workforce management platform. 
Your objective is to calculate the percentage of employees who enjoy full remote roles WITH salaries 
Exceeding $100,000 USD, Shedding light ON the attractiveness of high-paying remote positions IN today's job market.*/
set @wfh = (select count(*) from salaries where remote_ratio = 100 and salary_in_usd > 100000);
set @total_work_force = (select count(*) from salaries);
set @percent = round(((select @wfh)/(select @total_work_force))*100,2);
select @percent as 'Percentage_of_remote_positions';

/*4. Imagine you're a data analyst Working for a global recruitment agency. Your Task is to identify the Locations 
where entry-level average salaries exceed the average salary for that job title in market for entry level, 
helping your agency guide candidates towards lucrative countries.*/
select company_location, job_title, avg(salary) from salaries s1
where experience_level = 'EN' and 
salary > (select avg(salary) from salaries s2 where experience_level = 'EN' and s2.job_title = s1.job_title)
group by company_location, job_title
order by company_location;

/*5. You've been hired by a big HR Consultancy to look at how many people get paid IN different Countries. 
Your job is to Find out for each job title which Country pays the maximum average salary. 
This helps you to place your candidates IN those countries.*/
with cte as 
(select job_title, company_location, avg(salary) as 'avg_sal' from salaries
group by job_title, company_location
order by job_title)
select * from (select * ,dense_rank() over(partition by job_title order by avg_sal desc) as 'rnk' from cte) t 
where t.rnk = 1;

/*6. AS a data-driven Business consultant, you've been hired by a multinational corporation to analyze salary trends 
across different company Locations. Your goal is to Pinpoint Locations WHERE the average salary Has consistently Increased 
over the Past few years (Countries WHERE data is available for 3 years Only(this and past two years) 
providing Insights into Locations experiencing Sustained salary growth*/

with cte as 
(
	select * from salaries where company_location in
	(
		select company_location from 
		(
		select company_location, avg(salary) , count(distinct work_year) as 'no_of_years' from salaries 
		where work_year >= (year(current_date())-2)
		group by company_location having no_of_years = 3
		order by company_location
		) t
	)
)
-- select company_location, work_year, avg(salary) as 'avg_sal' from cte group by company_location, work_year order by company_location;

select company_location,
max(case when work_year = 2022 then avg end) as avg_2022,
max(case when work_year = 2023 then avg end) as avg_2023,
max(case when work_year = 2024 then avg end) as avg_2024
from (select company_location, work_year, avg(salary) as 'avg' from cte
		group by company_location, work_year
		order by company_location)t group by company_location having avg_2024 > avg_2023 and avg_2023 > avg_2022; 
     
     
/*7. Picture yourself as a workforce strategist employed by a global HR tech startup. Your mission is to determine the percentage
of fully remote work for each experience level in 2021 and compare it with the corresponding figures for 2024, highlighting 
any significant increase or decrease in remote work adoption over the years.*/
set @wfh_2021 = (select count(*) from salaries where remote_ratio = 100 and work_year = 2021);
set @total_2021 = (select count(*) from salaries where work_year = 2021);
set @percent_2021 = (select @wfh_2021*100/@total_2021);

set @wfh_2024 = (select count(*) from salaries where remote_ratio = 100 and work_year = 2024);
set @total_2024 = (select count(*) from salaries where work_year = 2024);
set @percent_2024 = (select @wfh_2024*100/@total_2024);

select @percent_2021, @percent_2024,
case 
	when @percent_2021 > @percent_2024 then 'decrease'
	else 'increase'
end as 'change';
-- -----------------------
select t1.experience_level, total_2021, wfh_2021, wfh_2021/total_2021*100 as 'percent_2021', 
total_2024, wfh_2024, wfh_2024/total_2024*100 as 'percent_2024' from 
(select experience_level, count(*) as 'total_2021' from salaries where work_year = 2021 
group by experience_level order by experience_level)t1
join
(select experience_level, count(*) as 'wfh_2021' from salaries where remote_ratio = 100 and work_year = 2021 
group by experience_level order by experience_level)t2
on t1.experience_level = t2.experience_level
join
(select experience_level, count(*) as 'total_2024' from salaries where work_year = 2024 
group by experience_level order by experience_level)t3
on t1.experience_level = t3.experience_level
join 
(select experience_level, count(*) as 'wfh_2024' from salaries where remote_ratio = 100 and work_year = 2024 
group by experience_level order by experience_level)t4
on t1.experience_level = t4.experience_level;

/* 8. As a compensation specialist at a Fortune 500 company, you're tasked with analyzing salary trends over time. Your objective 
is to calculate the average salary increase percentage for each experience level and job title between the years 2023 and 2024, 
helping the company stay competitive in the talent market.*/

select t1.experience_level, t1.job_title, avg_sal_2023, avg_sal_2024, (avg_sal_2024 - avg_sal_2023)*100/avg_sal_2023 as 'percent_change' from 
			(select experience_level, job_title, avg(salary) as 'avg_sal_2023' from salaries where work_year = 2023
			group by experience_level, job_title
			order by experience_level, job_title) t1
			join
			(select experience_level, job_title, avg(salary) as 'avg_sal_2024' from salaries where work_year = 2024
			group by experience_level, job_title
			order by experience_level, job_title) t2
			on t1.experience_level = t2.experience_level and t1.job_title = t2.job_title;

/* 9. You're a database administrator tasked with role-based access control for a company's employee database. Your goal is to 
implement a security measure where employees in different experience level (e.g.Entry Level, Senior level etc.) can only access 
details relevant to their respective experience_level, ensuring data confidentiality and minimizing the risk of unauthorized access.*/
create user 'Entry_level'@'%' identified by 'EN';
create view entry_level as 
(
	select * from salaries where experience_level = 'EN'
);

show privileges;
grant select on ds_salaries.entry_level to 'Entry_level'@'%';

/* 10. You are working with an consultancy firm, your client comes to you with certain data and preferences such as 
( their year of experience , their employment type, company location and company size ) and want to make a transition into different domain in data industry
(like  a person is working as a data analyst and want to move to some other domain such as data science or data engineering etc.)
your work is to  guide them to which domain they should switch to based on the input they provided, so that they can now update their knowledge as per the suggestion.
The Suggestion should be based on average salary.*/

DELIMITER //
create PROCEDURE GetAverageSalary(IN exp_lev VARCHAR(2), IN emp_type VARCHAR(3), IN comp_loc VARCHAR(2), IN comp_size VARCHAR(2))
BEGIN
    SELECT job_title, experience_level, company_location, company_size, employment_type, ROUND(AVG(salary), 2) AS avg_salary 
    FROM salaries 
    WHERE experience_level = exp_lev AND company_location = comp_loc AND company_size = comp_size AND employment_type = emp_type 
    GROUP BY experience_level, employment_type, company_location, company_size, job_title order by avg_salary desc ;
END//
DELIMITER ;
-- Deliminator  By doing this, you're telling MySQL that statements within the block should be parsed as a single unit until the custom delimiter is encountered.

call GetAverageSalary('EN','FT','AU','M');

-- drop procedure Getaveragesalary


/*1.As a market researcher, your job is to Investigate the job market for a company that analyzes workforce data. Your Task is to know how many people were
 employed in different types of companies as per their size in 2021.*/
select company_size, count(*), avg(salary) from salaries where work_year = 2021 
group by company_size;

/*2.Imagine you are a talent Acquisition specialist Working for an International recruitment agency. Your Task is to identify the top 3 job titles that 
command the highest average salary Among part-time Positions IN the year 2023.*/
select job_title, avg(salary) from salaries where work_year = 2023 and employment_type = 'PT'
group by job_title order by avg(salary) desc limit 3;

/*3.As a database analyst you have been assigned the task to Select Countries where average mid-level salary is higher than overall mid-level salary for the year 2023.*/
select company_location, avg(salary) from salaries where work_year = 2023 and experience_level = 'MI'
group by company_location having avg(salary) > (select avg(salary) from salaries where work_year = 2023 and experience_level = 'MI');

/*4.As a database analyst you have been assigned the task to Identify the company locations with the highest and lowest average salary for 
senior-level (SE) employees in 2023.*/
(select company_location, avg(salary) from salaries where work_year = 2023 and experience_level = 'SE' group by company_location order by avg(salary) limit 1)
UNION
(select company_location, avg(salary) from salaries where work_year = 2023 and experience_level = 'SE' group by company_location order by avg(salary) desc limit 1);

/*5. You're a Financial analyst Working for a leading HR Consultancy, and your Task is to Assess the annual salary growth rate for various job titles. 
By Calculating the percentage Increase IN salary FROM previous year to this year, you aim to provide valuable Insights Into salary trends WITHIN different job roles.*/
select *, lag(avg_sal) over() as 'percent_change' from 
(
	select job_title, work_year, avg(salary) as 'avg_sal' from salaries group by job_title, work_year order by job_title
)t;






















