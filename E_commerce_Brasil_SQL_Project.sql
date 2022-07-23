create database ecommerce_sales_analysis

use ecommerce_sales_analysis

select * from olist_customers_dataset
select * from olist_orders_dataset


--> a.1] total sales over each state for each year

select b.customer_state, year(a.order_delivered_customer_date)as Year_of_sales , sum(c.price) as total_sales
from olist_orders_dataset as a
left join olist_customers_dataset as b
on a.customer_id = b.customer_id
left join olist_order_items_dataset as c
on a.order_id = c.order_id
where year(a.order_delivered_customer_date) is not null
group by year(a.order_delivered_customer_date), b.customer_state
order by 1 , 2 desc

-->a.2] total customer acquistion over each state for each year

select b.customer_state, year(a.order_delivered_customer_date)as Year_of_sales , count(distinct(b.customer_unique_id)) as total_customers_acquired
from olist_orders_dataset as a
left join olist_customers_dataset as b
on a.customer_id = b.customer_id
where year(a.order_delivered_customer_date) is not null
group by year(a.order_delivered_customer_date), b.customer_state
order by 1 , 2 desc

--> a.3] total no. of orders each year state wise

select b.customer_state, year(a.order_delivered_customer_date)as Year_of_sales , count(distinct(a.order_id)) as total_no_of_orders
from olist_orders_dataset as a
left join olist_customers_dataset as b
on a.customer_id = b.customer_id
where year(a.order_delivered_customer_date) is not null
group by year(a.order_delivered_customer_date), b.customer_state
order by 1 , 2 desc

--> they all show similar trends
--> b]

create table trends(
customer_states varchar(50),
year_of_sales int,
orders datetime2,
)

  
insert into trends  
select b.customer_state, year(a.order_delivered_customer_date)as Year_of_sales , a.order_approved_at as orders
from olist_orders_dataset as a
left join olist_customers_dataset as b
on a.customer_id = b.customer_id
where year(a.order_delivered_customer_date) is not null
group by year(a.order_delivered_customer_date), b.customer_state, a.order_approved_at
order by 1 , 2 desc

select * from trends


create table trends2(
customer_states varchar(50),
_2018 int,
_2017 int,
_2016 int
)

insert into trends2
select * from (
select customer_states, year_of_sales as years, orders
from trends
) t
pivot( 
count (orders)
for years in(
[2018],
[2017],
[2016])
)as pivot_table

select * from trends2

--> b.1] declining trends over the years
select top 2 customer_states,_2018,_2017,_2016, (_2018 - _2017) as change_in_2018, (_2017 - _2016) as change_in_2017 from trends2
group by customer_states, _2018,_2017,_2016
order by 5 asc, 6asc


--> b.2] increasing trends over the years
select top 2 customer_states,_2018,_2017,_2016, (_2018 - _2017) as change_in_2018, (_2017 - _2016) as change_in_2017 from trends2
group by customer_states, _2018,_2017,_2016
order by 5 desc,6 desc    


--> c.1] Category level sales and orders placed
select * from olist_products_dataset
select * from product_category_name_translation
select * from olist_order_items_dataset

--> c.1.a] for declining trend
select c.column2 as category_name, e.customer_state, sum(a.price) as total_price ,sum(f.payment_value) as price_paid,
count(distinct(d.order_id)) as total_orders, (sum(f.payment_value) - sum(a.price)) as extra_amount_paid
from olist_order_items_dataset as a
left join olist_products_dataset as b
on a.product_id = b.product_id
join product_category_name_translation as c
on b.product_category_name = c.column1
left join olist_orders_dataset as d
on a.order_id = d.order_id
left join olist_customers_dataset as e
on d.customer_id = e.customer_id
left join olist_order_payments_dataset as f
on a.order_id = f.order_id
where e.customer_state = 'AC'
or e.customer_state = 'RO'
group by c.column2, e.customer_state
order by 2 asc, 3 desc, 4 desc, 5 desc

-->c.1.b] for increasing trend
select c.column2 as category_name, e.customer_state, sum(a.price) as total_price ,
sum(f.payment_value) as price_paid, count(distinct(d.order_id)) as total_orders, 
(sum(f.payment_value) - sum(a.price)) as extra_amount_paid
from olist_order_items_dataset as a
left join olist_products_dataset as b
on a.product_id = b.product_id
join product_category_name_translation as c
on b.product_category_name = c.column1
left join olist_orders_dataset as d
on a.order_id = d.order_id
left join olist_customers_dataset as e
on d.customer_id = e.customer_id
left join olist_order_payments_dataset as f
on a.order_id = f.order_id
where e.customer_state = 'SP'
or e.customer_state = 'RJ'
group by c.column2, e.customer_state
order by 2 asc, 3 desc, 4 desc, 5 desc

-->c.2]post order review
--> for declining and increasing trends

select * from olist_order_reviews_dataset


create table post_order_decline(
customer_state varchar(50),
_5star float,
_4star float,
_3star float,
_2star float,
_1star float)

insert into post_order_decline
select c.customer_state, sum(case when b.review_score = 5 then 1
else 0
end) as _5star ,
sum(case when b.review_score = 4 then 1
else 0
end) as _4star ,
sum(case when b.review_score = 3 then 1
else 0
end) as _3star ,
sum(case when b.review_score = 2 then 1
else 0
end) as _2star ,
sum(case when b.review_score = 1 then 1
else 0
end) as _1star 
from olist_orders_dataset as a
left join olist_order_reviews_dataset as b
on a.order_id = b.order_id
left join olist_customers_dataset as c
on a.customer_id = c.customer_id
where c.customer_state in ('SP','RJ','AC','RO')
group by c.customer_state


select a.*, ((a._5star+a._4star) /  (a._5star+a._4star+a._3star+a._2star+a._1star))*100 as percent_of_positive_reviews, 
(100 -((a._5star+a._4star) /  (a._5star+a._4star+a._3star+a._2star+a._1star))*100 ) as percent_of_negeative_reciews,
avg(datediff(day,d.review_creation_date,d.review_answer_timestamp)) as avg_days_to_answer_reviews
from post_order_decline as a
left join olist_customers_dataset as b
on a.customer_state = b.customer_state
left join olist_orders_dataset as c
on b.customer_id = c.customer_id
left join olist_order_reviews_dataset as d
on c.order_id = d.order_id
group by a.customer_state,a._5star,a._4star,a._3star,a._2star,a._1star
order by 2,3


select * from post_order_decline


--> c.3]seller performance in terms of deliveries
select * from olist_sellers_dataset
select * from olist_orders_dataset

-->c.3.a] declining states sellers performance
select distinct(a.seller_id), a.seller_state, d.customer_state,
DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) as days_to_deliver, 
datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date) as expected_days,
case when ( DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) - datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date)) <0 then 'good'
when ( DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) - datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date)) >=0 then 'poor' 
end as performance
from olist_sellers_dataset as a
left join olist_order_items_dataset as b
on a.seller_id = b.seller_id
left join olist_orders_dataset as c
on b.order_id = c.order_id
left join olist_customers_dataset as d
on c.customer_id = d.customer_id
where a.seller_state in('AC','RO')
or d.customer_state in ('AC','RO')
and DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) is not null
order by 3 asc, 4 desc

-->c.3.b] increasing states sellers performance
select distinct(a.seller_id), a.seller_state, d.customer_state, 
DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) as days_to_deliver, datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date) as expected_days,case when ( DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) - datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date)) <0 then 'good'
when ( DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) - datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date)) >=0 then 'poor' 
end as performance
from olist_sellers_dataset as a
left join olist_order_items_dataset as b
on a.seller_id = b.seller_id
left join olist_orders_dataset as c
on b.order_id = c.order_id
left join olist_customers_dataset as d
on c.customer_id = d.customer_id
where a.seller_state in('SP','RJ')
or d.customer_state in ('SP','RJ')
and DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) is not null
order by 3 asc, 4 desc

--> c.4]  product level sales and orders placed
--> c.4.a] for declining trends states (AC)
select * from olist_products_dataset

select top 1 c.column2 as category_name, e.customer_state, count(distinct(d.order_id)) as total_orders
from olist_order_items_dataset as a
left join olist_products_dataset as b
on a.product_id = b.product_id
join product_category_name_translation as c
on b.product_category_name = c.column1
left join olist_orders_dataset as d
on a.order_id = d.order_id
left join olist_customers_dataset as e
on d.customer_id = e.customer_id
left join olist_order_payments_dataset as f
on a.order_id = f.order_id
where e.customer_state = 'AC'
group by c.column2, e.customer_state
order by 2 asc , 3 desc

select  a.product_id, sum(c.price) as total_price, sum(d.payment_value) as price_paid, count(d.order_id) as total_orders,(sum(d.payment_value) - sum(c.price)) as extra_amount_paid 
from olist_products_dataset as a
join product_category_name_translation as b
on a.product_category_name = b.column1
left join olist_order_items_dataset as c
on a.product_id = c.product_id
left join olist_order_payments_dataset as d
on c.order_id = d.order_id
left join olist_orders_dataset as e 
on c.order_id =e.order_id
left join olist_customers_dataset as f
on e.customer_id = f.customer_id
where b.column2 = 'Sports_leisure'
and f.customer_state = 'AC'
group by  a.product_id
order by 4 desc

-->c.4.b] for declining trends (RO)

select top 1 c.column2 as category_name, e.customer_state, count(distinct(d.order_id)) as total_orders
from olist_order_items_dataset as a
left join olist_products_dataset as b
on a.product_id = b.product_id
join product_category_name_translation as c
on b.product_category_name = c.column1
left join olist_orders_dataset as d
on a.order_id = d.order_id
left join olist_customers_dataset as e
on d.customer_id = e.customer_id
left join olist_order_payments_dataset as f
on a.order_id = f.order_id
where e.customer_state = 'RO'
group by c.column2, e.customer_state
order by 2 asc , 3 desc

select  a.product_id, sum(c.price) as total_price, sum(d.payment_value) as price_paid, count(d.order_id) as total_orders,(sum(d.payment_value) - sum(c.price)) as extra_amount_paid 
from olist_products_dataset as a
join product_category_name_translation as b
on a.product_category_name = b.column1
left join olist_order_items_dataset as c
on a.product_id = c.product_id
left join olist_order_payments_dataset as d
on c.order_id = d.order_id
left join olist_orders_dataset as e 
on c.order_id =e.order_id
left join olist_customers_dataset as f
on e.customer_id = f.customer_id
where b.column2 = 'health_beauty'
and f.customer_state = 'RO'
group by  a.product_id
order by 4 desc

-->c.4.c] for increasing trends (SP)
select top 1 c.column2 as category_name, e.customer_state, count(distinct(d.order_id)) as total_orders
from olist_order_items_dataset as a
left join olist_products_dataset as b
on a.product_id = b.product_id
join product_category_name_translation as c
on b.product_category_name = c.column1
left join olist_orders_dataset as d
on a.order_id = d.order_id
left join olist_customers_dataset as e
on d.customer_id = e.customer_id
left join olist_order_payments_dataset as f
on a.order_id = f.order_id
where e.customer_state = 'SP'
group by c.column2, e.customer_state
order by 2 asc , 3 desc

select  a.product_id, sum(c.price) as total_price, sum(d.payment_value) as price_paid, count(d.order_id) as total_orders,(sum(d.payment_value) - sum(c.price)) as extra_amount_paid 
from olist_products_dataset as a
join product_category_name_translation as b
on a.product_category_name = b.column1
left join olist_order_items_dataset as c
on a.product_id = c.product_id
left join olist_order_payments_dataset as d
on c.order_id = d.order_id
left join olist_orders_dataset as e 
on c.order_id =e.order_id
left join olist_customers_dataset as f
on e.customer_id = f.customer_id
where b.column2 = 'bed_bath_table'
and f.customer_state = 'SP'
group by  a.product_id
order by 4 desc

-->c.4.d] for increasing trend (RJ)

select top 1 c.column2 as category_name, e.customer_state, count(distinct(d.order_id)) as total_orders
from olist_order_items_dataset as a
left join olist_products_dataset as b
on a.product_id = b.product_id
join product_category_name_translation as c
on b.product_category_name = c.column1
left join olist_orders_dataset as d
on a.order_id = d.order_id
left join olist_customers_dataset as e
on d.customer_id = e.customer_id
left join olist_order_payments_dataset as f
on a.order_id = f.order_id
where e.customer_state = 'RJ'
group by c.column2, e.customer_state
order by 2 asc , 3 desc

select  a.product_id, sum(c.price) as total_price, sum(d.payment_value) as price_paid, count(d.order_id) as total_orders,(sum(d.payment_value) - sum(c.price)) as extra_amount_paid 
from olist_products_dataset as a
join product_category_name_translation as b
on a.product_category_name = b.column1
left join olist_order_items_dataset as c
on a.product_id = c.product_id
left join olist_order_payments_dataset as d
on c.order_id = d.order_id
left join olist_orders_dataset as e 
on c.order_id =e.order_id
left join olist_customers_dataset as f
on e.customer_id = f.customer_id
where b.column2 = 'bed_bath_table'
and f.customer_state = 'RJ'
group by  a.product_id
order by 4 desc


-->c.5] % of order delivered earlier than expected date
--> c.5.a] for decling states
create table perf_decline_earlier (
seller_id varchar(50),
seller_state varchar(50),
customer_state varchar(40),
days_to_deliver int,
expected_days int,
performance int
)

insert into perf_decline_earlier
select  distinct(a.seller_id), a.seller_state, d.customer_state, DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) as days_to_deliver, datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date) as expected_days,case when ( DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) - datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date)) <0 then 1
when ( DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) - datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date)) >=0 then 0 
end as performance
from olist_sellers_dataset as a
left join olist_order_items_dataset as b
on a.seller_id = b.seller_id
left join olist_orders_dataset as c
on b.order_id = c.order_id
left join olist_customers_dataset as d
on c.customer_id = d.customer_id
where a.seller_state in('AC','RO')
or d.customer_state in ('AC','RO')
and DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) is not null
order by 3 asc, 4 desc

select * from perf_decline_earlier
alter table perf_decline_earlier
alter column performance float

select (sum(case when performance = 1 then 1
else 0
end)*100)/ (select (cast (count(performance) as float)) from perf_decline_earlier) as percent_of_order_before_date
from perf_decline_earlier
where customer_state in ('AC','RO')



-->c.5.b]  for increasing states
create table perf_increase_earlier (
seller_id varchar(50),
seller_state varchar(50),
customer_state varchar(40),
days_to_deliver int,
expected_days int,
performance int
)

insert into perf_increase_earlier
select  distinct(a.seller_id), a.seller_state, d.customer_state, DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) as days_to_deliver, datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date) as expected_days,case when ( DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) - datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date)) <0 then 1
when ( DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) - datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date)) >=0 then 0 
end as performance
from olist_sellers_dataset as a
left join olist_order_items_dataset as b
on a.seller_id = b.seller_id
left join olist_orders_dataset as c
on b.order_id = c.order_id
left join olist_customers_dataset as d
on c.customer_id = d.customer_id
where a.seller_state in('SP','RJ')
or d.customer_state in ('SP','RJ')
and DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) is not null
order by 3 asc, 4 desc

select * from perf_increase_earlier
alter table perf_increase_earlier
alter column performance float

select (sum(case when performance = 1 then 1
else 0
end)*100)/ (select (cast (count(performance) as float)) from perf_increase_earlier) as percent_of_order_before_date
from perf_increase_earlier
where customer_state in ('SP','RJ')

-->c.6] % of orders delivered later than expected date
-->c.6.a] for declining trends
select * from perf_decline_earlier
alter table perf_decline_earlier
alter column performance float

select (100 -(sum(case when performance = 1 then 1
else 0
end)*100)/ (select (cast (count(performance) as float)) from perf_decline_earlier) )as percent_of_order_after_date
from perf_decline_earlier 
where customer_state in ('AC','RO')

-->c.6.b] for increasing trends
select * from perf_increase_earlier
alter table perf_increase_earlier
alter column performance float

select (100 - (sum(case when performance = 1 then 1
else 0
end)*100)/ (select (cast (count(performance) as float)) from perf_increase_earlier) )as percent_of_order_after_date
from perf_increase_earlier
where customer_state in ('SP','RJ')

-->c.7] analysis over location
select a.seller_state, count(a.seller_id)
from olist_sellers_dataset as a
group by a.seller_state
order by 2 desc

select customer_state , count(customer_id)
from olist_customers_dataset
group by customer_state
order by 2 desc

-->d] top 2 cities


create table trends_city(
customer_city varchar(50),
year_of_sales int,
orders datetime2,
)

  
insert into trends_city  
select b.customer_city, year(a.order_delivered_customer_date)as Year_of_sales , a.order_approved_at as orders
from olist_orders_dataset as a
left join olist_customers_dataset as b
on a.customer_id = b.customer_id
where year(a.order_delivered_customer_date) is not null
group by year(a.order_delivered_customer_date), b.customer_city, a.order_approved_at
order by 1 , 2 desc

select * from trends_city


create table trends2_city(
customer_city varchar(50),
_2018 int,
_2017 int,
_2016 int
)

insert into trends2_city
select * from (
select customer_city, year_of_sales as years, orders
from trends_city
) t
pivot( 
count (orders)
for years in(
[2018],
[2017],
[2016])
)as pivot_table

select * from trends2_city

--> d.1] for declining trend in AC
select top 2 a.customer_city,a._2018,a._2017,a._2016, (a._2018 - a._2017) as change_in_2018, (a._2017 - a._2016) as change_in_2017 
from trends2_city as a
left join olist_customers_dataset as b
on a.customer_city = b.customer_city
where b.customer_state = 'AC'
group by a.customer_city, a._2018,a._2017,a._2016
order by 5 asc, 6asc

-->d.2] for declining trend in RO
select top 2 a.customer_city,a._2018,a._2017,a._2016, (a._2018 - a._2017) as change_in_2018, (a._2017 - a._2016) as change_in_2017 
from trends2_city as a
left join olist_customers_dataset as b
on a.customer_city = b.customer_city
where b.customer_state = 'RO'
group by a.customer_city, a._2018,a._2017,a._2016
order by 5 asc, 6asc

-->d.3] for increasing trend in SP
select top 2 a.customer_city,a._2018,a._2017,a._2016, (a._2018 - a._2017) as change_in_2018, (a._2017 - a._2016) as change_in_2017 
from trends2_city as a
left join olist_customers_dataset as b
on a.customer_city = b.customer_city
where b.customer_state = 'SP'
group by a.customer_city, a._2018,a._2017,a._2016
order by 5 desc, 6desc

-->d.4] for increasing trend in RJ
select top 2 a.customer_city,a._2018,a._2017,a._2016, (a._2018 - a._2017) as change_in_2018, (a._2017 - a._2016) as change_in_2017 
from trends2_city as a
left join olist_customers_dataset as b
on a.customer_city = b.customer_city
where b.customer_state = 'RJ'
group by a.customer_city, a._2018,a._2017,a._2016
order by 5 desc, 6desc

--> for declining trend 

--> in state AC
--c.3]
select distinct(a.seller_id), a.seller_city, d.customer_city,
DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) as days_to_deliver, 
datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date) as expected_days,
case when ( DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) - datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date)) <0 then 'good'
when ( DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) - datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date)) >=0 then 'poor' 
end as performance
from olist_sellers_dataset as a
left join olist_order_items_dataset as b
on a.seller_id = b.seller_id
left join olist_orders_dataset as c
on b.order_id = c.order_id
left join olist_customers_dataset as d
on c.customer_id = d.customer_id
where (a.seller_state = 'AC'
or d.customer_state = 'AC')
and (a.seller_city in ('brasileia' ,'rio branco')
or d.customer_city in ('brasileia' ,'rio branco'))
and DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) is not null
order by 3 asc, 4 desc

--> for city rio_branco
-->c.1]
select c.column2 as category_name, e.customer_state,e.customer_city, sum(a.price) as total_price ,sum(f.payment_value) as price_paid,
count(distinct(d.order_id)) as total_orders, (sum(f.payment_value) - sum(a.price)) as extra_amount_paid
from olist_order_items_dataset as a
left join olist_products_dataset as b
on a.product_id = b.product_id
join product_category_name_translation as c
on b.product_category_name = c.column1
left join olist_orders_dataset as d
on a.order_id = d.order_id
left join olist_customers_dataset as e
on d.customer_id = e.customer_id
left join olist_order_payments_dataset as f
on a.order_id = f.order_id
where e.customer_state = 'AC'
and e.customer_city = 'rio branco' 
group by c.column2, e.customer_state, e.customer_city
order by 2 asc, 3 desc, 4 desc, 5 desc

--> c.4]
select top 1 c.column2 as category_name, e.customer_state,e.customer_city, count(distinct(d.order_id)) as total_orders
from olist_order_items_dataset as a
left join olist_products_dataset as b
on a.product_id = b.product_id
join product_category_name_translation as c
on b.product_category_name = c.column1
left join olist_orders_dataset as d
on a.order_id = d.order_id
left join olist_customers_dataset as e
on d.customer_id = e.customer_id
left join olist_order_payments_dataset as f
on a.order_id = f.order_id
where e.customer_state = 'AC'
and e.customer_city = 'rio branco'
group by c.column2, e.customer_state, e.customer_city
order by 2 asc , 4 desc

select  a.product_id, sum(c.price) as total_price, sum(d.payment_value) as price_paid, count(d.order_id) as total_orders,(sum(d.payment_value) - sum(c.price)) as extra_amount_paid 
from olist_products_dataset as a
join product_category_name_translation as b
on a.product_category_name = b.column1
left join olist_order_items_dataset as c
on a.product_id = c.product_id
left join olist_order_payments_dataset as d
on c.order_id = d.order_id
left join olist_orders_dataset as e 
on c.order_id =e.order_id
left join olist_customers_dataset as f
on e.customer_id = f.customer_id
where b.column2 = 'furniture_decor'
and f.customer_state = 'AC'
and f.customer_city = 'rio branco'
group by  a.product_id
order by 4 desc

--> for city brasileia
--c.1]
select c.column2 as category_name, e.customer_state,e.customer_city, sum(a.price) as total_price ,sum(f.payment_value) as price_paid,
count(distinct(d.order_id)) as total_orders, (sum(f.payment_value) - sum(a.price)) as extra_amount_paid
from olist_order_items_dataset as a
left join olist_products_dataset as b
on a.product_id = b.product_id
join product_category_name_translation as c
on b.product_category_name = c.column1
left join olist_orders_dataset as d
on a.order_id = d.order_id
left join olist_customers_dataset as e
on d.customer_id = e.customer_id
left join olist_order_payments_dataset as f
on a.order_id = f.order_id
where e.customer_state = 'AC'
and e.customer_city = 'brasileia' 
group by c.column2, e.customer_state, e.customer_city
order by 2 asc, 3 desc, 4 desc, 5 desc

-->c.4]
select  c.column2 as category_name, e.customer_state,e.customer_city, count(distinct(d.order_id)) as total_orders
from olist_order_items_dataset as a
left join olist_products_dataset as b
on a.product_id = b.product_id
join product_category_name_translation as c
on b.product_category_name = c.column1
left join olist_orders_dataset as d
on a.order_id = d.order_id
left join olist_customers_dataset as e
on d.customer_id = e.customer_id
left join olist_order_payments_dataset as f
on a.order_id = f.order_id
where e.customer_state = 'AC'
and e.customer_city = 'brasileia' 
group by c.column2, e.customer_state, e.customer_city
order by 2 asc , 4 desc

select  a.product_id, sum(c.price) as total_price, sum(d.payment_value) as price_paid, count(d.order_id) as total_orders,(sum(d.payment_value) - sum(c.price)) as extra_amount_paid 
from olist_products_dataset as a
join product_category_name_translation as b
on a.product_category_name = b.column1
left join olist_order_items_dataset as c
on a.product_id = c.product_id
left join olist_order_payments_dataset as d
on c.order_id = d.order_id
left join olist_orders_dataset as e 
on c.order_id =e.order_id
left join olist_customers_dataset as f
on e.customer_id = f.customer_id
where b.column2 = 'computers_accessories'
and f.customer_state = 'AC'
and f.customer_city = 'brasileia' 
group by  a.product_id
order by 4 desc

--> in state RO
-->c.3]
select distinct(a.seller_id), a.seller_city, d.customer_city,
DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) as days_to_deliver, 
datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date) as expected_days,
case when ( DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) - datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date)) <0 then 'good'
when ( DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) - datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date)) >=0 then 'poor' 
end as performance
from olist_sellers_dataset as a
left join olist_order_items_dataset as b
on a.seller_id = b.seller_id
left join olist_orders_dataset as c
on b.order_id = c.order_id
left join olist_customers_dataset as d
on c.customer_id = d.customer_id
where (a.seller_state = 'RO'
or d.customer_state = 'RO')
and (a.seller_city in ('ariquemes' ,'vilhena')
or d.customer_city in ('ariquemes' ,'vilhena'))
and DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) is not null
order by 3 asc, 4 desc

--> for city ariquemes
-->c.1]
select c.column2 as category_name, e.customer_state,e.customer_city, sum(a.price) as total_price ,sum(f.payment_value) as price_paid,
count(distinct(d.order_id)) as total_orders, (sum(f.payment_value) - sum(a.price)) as extra_amount_paid
from olist_order_items_dataset as a
left join olist_products_dataset as b
on a.product_id = b.product_id
join product_category_name_translation as c
on b.product_category_name = c.column1
left join olist_orders_dataset as d
on a.order_id = d.order_id
left join olist_customers_dataset as e
on d.customer_id = e.customer_id
left join olist_order_payments_dataset as f
on a.order_id = f.order_id
where e.customer_state = 'RO'
and e.customer_city = 'ariquemes' 
group by c.column2, e.customer_state, e.customer_city
order by 2 asc, 3 desc, 4 desc, 5 desc

-->c.4]
select top 1 c.column2 as category_name, e.customer_state,e.customer_city, count(distinct(d.order_id)) as total_orders
from olist_order_items_dataset as a
left join olist_products_dataset as b
on a.product_id = b.product_id
join product_category_name_translation as c
on b.product_category_name = c.column1
left join olist_orders_dataset as d
on a.order_id = d.order_id
left join olist_customers_dataset as e
on d.customer_id = e.customer_id
left join olist_order_payments_dataset as f
on a.order_id = f.order_id
where e.customer_state = 'RO'
and e.customer_city = 'ariquemes' 
group by c.column2, e.customer_state, e.customer_city
order by 2 asc , 4 desc

select  a.product_id, sum(c.price) as total_price, sum(d.payment_value) as price_paid, count(d.order_id) as total_orders,(sum(d.payment_value) - sum(c.price)) as extra_amount_paid 
from olist_products_dataset as a
join product_category_name_translation as b
on a.product_category_name = b.column1
left join olist_order_items_dataset as c
on a.product_id = c.product_id
left join olist_order_payments_dataset as d
on c.order_id = d.order_id
left join olist_orders_dataset as e 
on c.order_id =e.order_id
left join olist_customers_dataset as f
on e.customer_id = f.customer_id
where b.column2 = 'health_beauty'
and f.customer_state = 'RO'
and f.customer_city = 'ariquemes' 
group by  a.product_id
order by 4 desc

--> for city vilhena
-->c.1]
select c.column2 as category_name, e.customer_state,e.customer_city, sum(a.price) as total_price ,sum(f.payment_value) as price_paid,
count(distinct(d.order_id)) as total_orders, (sum(f.payment_value) - sum(a.price)) as extra_amount_paid
from olist_order_items_dataset as a
left join olist_products_dataset as b
on a.product_id = b.product_id
join product_category_name_translation as c
on b.product_category_name = c.column1
left join olist_orders_dataset as d
on a.order_id = d.order_id
left join olist_customers_dataset as e
on d.customer_id = e.customer_id
left join olist_order_payments_dataset as f
on a.order_id = f.order_id
where e.customer_state = 'RO'
and e.customer_city = 'vilhena' 
group by c.column2, e.customer_state, e.customer_city
order by 2 asc, 3 desc, 4 desc, 5 desc

-->c.4]
select top 1 c.column2 as category_name, e.customer_state,e.customer_city, count(distinct(d.order_id)) as total_orders
from olist_order_items_dataset as a
left join olist_products_dataset as b
on a.product_id = b.product_id
join product_category_name_translation as c
on b.product_category_name = c.column1
left join olist_orders_dataset as d
on a.order_id = d.order_id
left join olist_customers_dataset as e
on d.customer_id = e.customer_id
left join olist_order_payments_dataset as f
on a.order_id = f.order_id
where e.customer_state = 'RO'
and e.customer_city = 'vilhena'
group by c.column2, e.customer_state, e.customer_city
order by 2 asc , 4 desc

select  a.product_id, sum(c.price) as total_price, sum(d.payment_value) as price_paid, count(d.order_id) as total_orders,(sum(d.payment_value) - sum(c.price)) as extra_amount_paid 
from olist_products_dataset as a
join product_category_name_translation as b
on a.product_category_name = b.column1
left join olist_order_items_dataset as c
on a.product_id = c.product_id
left join olist_order_payments_dataset as d
on c.order_id = d.order_id
left join olist_orders_dataset as e 
on c.order_id =e.order_id
left join olist_customers_dataset as f
on e.customer_id = f.customer_id
where b.column2 = 'bed_bath_table'
and f.customer_state = 'RO'
and f.customer_city = 'vilhena'
group by  a.product_id
order by 4 desc


--> for incresing trend 

--> in state SP
--> c.3]

select distinct(a.seller_id), a.seller_city, d.customer_city,
DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) as days_to_deliver, 
datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date) as expected_days,
case when ( DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) - datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date)) <0 then 'good'
when ( DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) - datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date)) >=0 then 'poor' 
end as performance
from olist_sellers_dataset as a
left join olist_order_items_dataset as b
on a.seller_id = b.seller_id
left join olist_orders_dataset as c
on b.order_id = c.order_id
left join olist_customers_dataset as d
on c.customer_id = d.customer_id
where (a.seller_state = 'SP'
or d.customer_state = 'SP')
and (a.seller_city in ('sao paulo' ,'campinas')
or d.customer_city in ('sao paulo' ,'campinas'))
and DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) is not null
order by 3 asc, 4 desc

--> for city sao paulo
-->c.1]
select c.column2 as category_name, e.customer_state,e.customer_city, sum(a.price) as total_price ,sum(f.payment_value) as price_paid,
count(distinct(d.order_id)) as total_orders, (sum(f.payment_value) - sum(a.price)) as extra_amount_paid
from olist_order_items_dataset as a
left join olist_products_dataset as b
on a.product_id = b.product_id
join product_category_name_translation as c
on b.product_category_name = c.column1
left join olist_orders_dataset as d
on a.order_id = d.order_id
left join olist_customers_dataset as e
on d.customer_id = e.customer_id
left join olist_order_payments_dataset as f
on a.order_id = f.order_id
where e.customer_state = 'SP'
and e.customer_city = 'sao paulo' 
group by c.column2, e.customer_state, e.customer_city
order by 2 asc, 3 desc, 4 desc, 5 desc

--> c.4]
select top 1 c.column2 as category_name, e.customer_state,e.customer_city, count(distinct(d.order_id)) as total_orders
from olist_order_items_dataset as a
left join olist_products_dataset as b
on a.product_id = b.product_id
join product_category_name_translation as c
on b.product_category_name = c.column1
left join olist_orders_dataset as d
on a.order_id = d.order_id
left join olist_customers_dataset as e
on d.customer_id = e.customer_id
left join olist_order_payments_dataset as f
on a.order_id = f.order_id
where e.customer_state = 'SP'
and e.customer_city = 'sao paulo'
group by c.column2, e.customer_state, e.customer_city
order by 2 asc , 4 desc

select  a.product_id, sum(c.price) as total_price, sum(d.payment_value) as price_paid, count(d.order_id) as total_orders,(sum(d.payment_value) - sum(c.price)) as extra_amount_paid 
from olist_products_dataset as a
join product_category_name_translation as b
on a.product_category_name = b.column1
left join olist_order_items_dataset as c
on a.product_id = c.product_id
left join olist_order_payments_dataset as d
on c.order_id = d.order_id
left join olist_orders_dataset as e 
on c.order_id =e.order_id
left join olist_customers_dataset as f
on e.customer_id = f.customer_id
where b.column2 = 'bed_bath_table'
and f.customer_state = 'SP'
and f.customer_city = 'sao paulo'
group by  a.product_id
order by 4 desc

--> for city campinas
--> c.1]
select c.column2 as category_name, e.customer_state,e.customer_city, sum(a.price) as total_price ,sum(f.payment_value) as price_paid,
count(distinct(d.order_id)) as total_orders, (sum(f.payment_value) - sum(a.price)) as extra_amount_paid
from olist_order_items_dataset as a
left join olist_products_dataset as b
on a.product_id = b.product_id
join product_category_name_translation as c
on b.product_category_name = c.column1
left join olist_orders_dataset as d
on a.order_id = d.order_id
left join olist_customers_dataset as e
on d.customer_id = e.customer_id
left join olist_order_payments_dataset as f
on a.order_id = f.order_id
where e.customer_state = 'SP'
and e.customer_city = 'campinas' 
group by c.column2, e.customer_state, e.customer_city
order by 2 asc, 3 desc, 4 desc, 5 desc

-->c.4]
select top 1 c.column2 as category_name, e.customer_state,e.customer_city, count(distinct(d.order_id)) as total_orders
from olist_order_items_dataset as a
left join olist_products_dataset as b
on a.product_id = b.product_id
join product_category_name_translation as c
on b.product_category_name = c.column1
left join olist_orders_dataset as d
on a.order_id = d.order_id
left join olist_customers_dataset as e
on d.customer_id = e.customer_id
left join olist_order_payments_dataset as f
on a.order_id = f.order_id
where e.customer_state = 'SP'
and e.customer_city = 'campinas'
group by c.column2, e.customer_state, e.customer_city
order by 2 asc , 4 desc

select  a.product_id, sum(c.price) as total_price, sum(d.payment_value) as price_paid, count(d.order_id) as total_orders,(sum(d.payment_value) - sum(c.price)) as extra_amount_paid 
from olist_products_dataset as a
join product_category_name_translation as b
on a.product_category_name = b.column1
left join olist_order_items_dataset as c
on a.product_id = c.product_id
left join olist_order_payments_dataset as d
on c.order_id = d.order_id
left join olist_orders_dataset as e 
on c.order_id =e.order_id
left join olist_customers_dataset as f
on e.customer_id = f.customer_id
where b.column2 = 'bed_bath_table'
and f.customer_state = 'SP'
and f.customer_city = 'campinas'
group by  a.product_id
order by 4 desc

--> in state RJ
--> c.3]

select distinct(a.seller_id), a.seller_city, d.customer_city,
DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) as days_to_deliver, 
datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date) as expected_days,
case when ( DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) - datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date)) <0 then 'good'
when ( DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) - datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date)) >=0 then 'poor' 
end as performance
from olist_sellers_dataset as a
left join olist_order_items_dataset as b
on a.seller_id = b.seller_id
left join olist_orders_dataset as c
on b.order_id = c.order_id
left join olist_customers_dataset as d
on c.customer_id = d.customer_id
where (a.seller_state = 'RJ'
or d.customer_state = 'RJ')
and (a.seller_city in ('rio de janerio' ,'niteroi')
or d.customer_city in ('rio de janerio' ,'niteroi'))
and DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) is not null
order by 3 asc, 4 desc
--> for state rio de janerio
--> c.1]
select c.column2 as category_name, e.customer_state,e.customer_city, sum(a.price) as total_price ,sum(f.payment_value) as price_paid,
count(distinct(d.order_id)) as total_orders, (sum(f.payment_value) - sum(a.price)) as extra_amount_paid
from olist_order_items_dataset as a
left join olist_products_dataset as b
on a.product_id = b.product_id
join product_category_name_translation as c
on b.product_category_name = c.column1
left join olist_orders_dataset as d
on a.order_id = d.order_id
left join olist_customers_dataset as e
on d.customer_id = e.customer_id
left join olist_order_payments_dataset as f
on a.order_id = f.order_id
where e.customer_state = 'RJ'
and e.customer_city = 'rio de janeiro' 
group by c.column2, e.customer_state, e.customer_city
order by 2 asc, 3 desc, 4 desc, 5 desc

--> c.4]
select top 1 c.column2 as category_name, e.customer_state,e.customer_city, count(distinct(d.order_id)) as total_orders
from olist_order_items_dataset as a
left join olist_products_dataset as b
on a.product_id = b.product_id
join product_category_name_translation as c
on b.product_category_name = c.column1
left join olist_orders_dataset as d
on a.order_id = d.order_id
left join olist_customers_dataset as e
on d.customer_id = e.customer_id
left join olist_order_payments_dataset as f
on a.order_id = f.order_id
where e.customer_state = 'RJ'
and e.customer_city = 'rio de janeiro'
group by c.column2, e.customer_state, e.customer_city
order by 2 asc , 4 desc

select  a.product_id, sum(c.price) as total_price, sum(d.payment_value) as price_paid, count(d.order_id) as total_orders,(sum(d.payment_value) - sum(c.price)) as extra_amount_paid 
from olist_products_dataset as a
join product_category_name_translation as b
on a.product_category_name = b.column1
left join olist_order_items_dataset as c
on a.product_id = c.product_id
left join olist_order_payments_dataset as d
on c.order_id = d.order_id
left join olist_orders_dataset as e 
on c.order_id =e.order_id
left join olist_customers_dataset as f
on e.customer_id = f.customer_id
where b.column2 = 'bed_bath_table'
and f.customer_state = 'RJ'
and f.customer_city = 'rio de janeiro'
group by  a.product_id
order by 4 desc

--> for state niteroi
--> c.1]
select c.column2 as category_name, e.customer_state,e.customer_city, sum(a.price) as total_price ,sum(f.payment_value) as price_paid,
count(distinct(d.order_id)) as total_orders, (sum(f.payment_value) - sum(a.price)) as extra_amount_paid
from olist_order_items_dataset as a
left join olist_products_dataset as b
on a.product_id = b.product_id
join product_category_name_translation as c
on b.product_category_name = c.column1
left join olist_orders_dataset as d
on a.order_id = d.order_id
left join olist_customers_dataset as e
on d.customer_id = e.customer_id
left join olist_order_payments_dataset as f
on a.order_id = f.order_id
where e.customer_state = 'RJ'
and e.customer_city = 'niteroi' 
group by c.column2, e.customer_state, e.customer_city
order by 2 asc, 3 desc, 4 desc, 5 desc

-->c.4]
select top 1 c.column2 as category_name, e.customer_state,e.customer_city, count(distinct(d.order_id)) as total_orders
from olist_order_items_dataset as a
left join olist_products_dataset as b
on a.product_id = b.product_id
join product_category_name_translation as c
on b.product_category_name = c.column1
left join olist_orders_dataset as d
on a.order_id = d.order_id
left join olist_customers_dataset as e
on d.customer_id = e.customer_id
left join olist_order_payments_dataset as f
on a.order_id = f.order_id
where e.customer_state = 'RJ'
and e.customer_city = 'niteroi' 
group by c.column2, e.customer_state, e.customer_city
order by 2 asc , 4 desc

select  a.product_id, sum(c.price) as total_price, sum(d.payment_value) as price_paid, count(d.order_id) as total_orders,(sum(d.payment_value) - sum(c.price)) as extra_amount_paid 
from olist_products_dataset as a
join product_category_name_translation as b
on a.product_category_name = b.column1
left join olist_order_items_dataset as c
on a.product_id = c.product_id
left join olist_order_payments_dataset as d
on c.order_id = d.order_id
left join olist_orders_dataset as e 
on c.order_id =e.order_id
left join olist_customers_dataset as f
on e.customer_id = f.customer_id
where b.column2 = 'bed_bath_table'
and f.customer_state = 'RJ'
and f.customer_city = 'niteroi' 
group by  a.product_id
order by 4 desc

-->c.2]
create table post_order_decline_city(
customer_state varchar(50),
customer_city varchar(50),
_5star float,
_4star float,
_3star float,
_2star float,
_1star float)

insert into post_order_decline_city
select c.customer_state, c.customer_city, sum(case when b.review_score = 5 then 1
else 0
end) as _5star ,
sum(case when b.review_score = 4 then 1
else 0
end) as _4star ,
sum(case when b.review_score = 3 then 1
else 0
end) as _3star ,
sum(case when b.review_score = 2 then 1
else 0
end) as _2star ,
sum(case when b.review_score = 1 then 1
else 0
end) as _1star 
from olist_orders_dataset as a
left join olist_order_reviews_dataset as b
on a.order_id = b.order_id
left join olist_customers_dataset as c
on a.customer_id = c.customer_id
where c.customer_state in ('SP','RJ','AC','RO')
and c.customer_city in ('niteroi','rio de janeiro','campinas','sao paulo','vilhena','ariquemes','rio branco','brasileia')
group by c.customer_state,c.customer_city


select a.*, ((a._5star+a._4star) /  (a._5star+a._4star+a._3star+a._2star+a._1star))*100 as percent_of_positive_reviews, 
(100 -((a._5star+a._4star) /  (a._5star+a._4star+a._3star+a._2star+a._1star))*100 ) as percent_of_negeative_reciews,
avg(datediff(day,d.review_creation_date,d.review_answer_timestamp)) as avg_days_to_answer_reviews
from post_order_decline_city as a
left join olist_customers_dataset as b
on a.customer_state = b.customer_state
left join olist_orders_dataset as c
on b.customer_id = c.customer_id
left join olist_order_reviews_dataset as d
on c.order_id = d.order_id
group by a.customer_state,a.customer_city,a._5star,a._4star,a._3star,a._2star,a._1star
order by a.customer_state , 2,3


-->c.5]
create table perf_decline_earlier_city (
seller_id varchar(50),
seller_city varchar(50),
customer_city varchar(40),
days_to_deliver int,
expected_days int,
performance int
)

insert into perf_decline_earlier_city
select  distinct(a.seller_id), a.seller_city, d.customer_city, DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) as days_to_deliver, datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date) as expected_days,case when ( DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) - datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date)) <0 then 1
when ( DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) - datediff(day,c.order_purchase_timestamp,c.order_estimated_delivery_date)) >=0 then 0 
end as performance
from olist_sellers_dataset as a
left join olist_order_items_dataset as b
on a.seller_id = b.seller_id
left join olist_orders_dataset as c
on b.order_id = c.order_id
left join olist_customers_dataset as d
on c.customer_id = d.customer_id
where a.seller_state in('AC','RO','SP','RJ')
or d.customer_state in ('AC','RO','SP','RJ')
and DATEDIFF( day, c.order_delivered_carrier_date,c.order_delivered_customer_date) is not null
and a.seller_city in  ('niteroi','rio de janeiro','campinas','sao paulo','vilhena','ariquemes','rio branco','brasileia')
or d.customer_city in  ('niteroi','rio de janeiro','campinas','sao paulo','vilhena','ariquemes','rio branco','brasileia')
order by 3 asc, 4 desc

select * from perf_decline_earlier_city
alter table perf_decline_earlier_city
alter column performance float
--> for state ac
select (sum(case when performance = 1 then 1
else 0
end)*100)/ (select (cast (count(performance) as float)) from perf_decline_earlier_city) as percent_of_order_before_date
from perf_decline_earlier_city
where customer_city in  ('rio branco','brasileia')
or seller_city in  ('rio branco','brasileia')
--> for state ro
select (sum(case when performance = 1 then 1
else 0
end)*100)/ (select (cast (count(performance) as float)) from perf_decline_earlier_city) as percent_of_order_before_date
from perf_decline_earlier_city
where customer_city in  ('vilhena','ariquemes')
or seller_city in ('vilhena','ariquemes')
--> for state sp
select (sum(case when performance = 1 then 1
else 0
end)*100)/ (select (cast (count(performance) as float)) from perf_decline_earlier_city) as percent_of_order_before_date
from perf_decline_earlier_city
where customer_city in  ('campinas','sao paulo')
or seller_city in  ('campinas','sao paulo')
--> for state rj
select (sum(case when performance = 1 then 1
else 0
end)*100)/ (select (cast (count(performance) as float)) from perf_decline_earlier_city) as percent_of_order_before_date
from perf_decline_earlier_city
where customer_city in  ('niteroi','rio de janeiro')
or seller_city in  ('niteroi','rio de janeiro')

