-- basic queries
select * from walmart;
select count(*) from walmart;
select payment_method, count(*) from walmart group by payment_method;
select count(distinct branch) from walmart;
select max (quantity) from walmart;

-- Business Problems --
-- Q1) Find the payment method and number of transactions, number of quantity sold.
select payment_method, count(*) as no_of_payments, sum(quantity) as no_of_qty_sold from walmart group by payment_method;

-- Q2) Identify the highest rated category in each branch, displaying the branch, category and the avg rating
select branch, category, avg(rating) as avg_rating from walmart group by category,branch order by avg_rating desc;select * from (select branch, category, avg(rating)as avg_rating, rank() over(partition by branch order by avg(rating) desc) as rank from walmart group by 1,2 order by 1,3 desc) where rank = 1;

-- Q3) Identify the busiest day for each branch based on the number of transactions
select * from (select branch, to_char(to_date(date, 'DD/MM/YY'), 'DAY')  as day_name, count(*) as no_transactions, rank() over(partition by branch order by count(*) desc) as rank from walmart group by 1,2) where rank=1;
-- select branch, date, count(rating) as tot_trans from walmart group by 1,2 order by 3;

-- Q4) Calculate the total quantity of items sold per payment method. List payment_method and total_quantity.
select payment_method, sum(quantity) as total_quantity from walmart group by payment_method;

-- Q5) Determine the average, minimum, and maximum rating of products for each city. List the city, avg_rating, max & min
select city, category, max(rating) as max_rating, min(rating) as min_rating, avg(rating) as avg_rating from walmart group by 1,2;

-- Q6) Calculate the total profit for each category by considering total_profit as (unit_price * qty * profit_margin). List category and tot_profit, ordered from highest to lowest profit
select category, sum(total) as total_revenue, sum(total*profit_margin) as total_profit from walmart group by 1;

-- Q7) Determine the most common payment method for each branch, display branch and the pref_paym_method
select * from (select branch, payment_method, count(*) as total_trans, rank() over(partition by branch order by count(*) desc) as rank from walmart group by 1,2) where rank=1;
-- or same we can do
with cte as (select branch, payment_method, count(*) as total_trans, rank() over(partition by branch order by count(*) desc) as rank from walmart group by 1,2) select * from cte where rank = 1;

-- Q8) Categorize sales into 3 groups Morning, Afternoon. Evening. Find out each of the shift and number of invoices.
-- converting time from text to time data type -> time::time
-- select *, time::time from walmart;
-- new column for mor, aft, eve
-- select *,
-- case 
-- 	when extract (hour from(time::time)) <12 then 'Morning'
-- 	when extract (hour from(time::time)) between 12 and 17 then 'Afternoon'
-- 	else 'Evening'
-- end day_time
-- from walmart;

select branch,
case 
	when extract (hour from(time::time)) <12 then 'Morning'
	when extract (hour from(time::time)) between 12 and 17 then 'Afternoon'
	else 'Evening'
end day_time, count(*)
from walmart group by 1,2 order by 1,3 desc;

-- Q9) Identify 5 branch with highest decrease ratio in revenue compare to last year(current year 2023 and last year 2022)
-- rev_decr_ratio = last_yr_rev - curr_year_rev * 100

with revenue_2022 AS
(
select branch, sum(total) as revenue from walmart 
where extract (year from to_date(date, 'DD/MM/YY')) = 2022 
group by 1
),
revenue_2023 as
(
select branch, sum(total) as revenue from walmart 
where extract (year from to_date(date, 'DD/MM/YY')) = 2023 
-- mysql = where year (to_date(date, 'DD/MM/YY')) = 2023
group by 1
)
select lys.branch, lys.revenue as last_yr_revenue,
       cys.branch, cys.revenue as curr_yr_revenue,
	   round((lys.revenue-cys.revenue)::numeric/lys.revenue::numeric*100, 2) as rev_decr_ratio
from revenue_2022 as lys
JOIN
revenue_2023 as cys
on lys.branch = cys.branch
where lys.revenue > cys.revenue
order by 5 desc LIMIT 5;