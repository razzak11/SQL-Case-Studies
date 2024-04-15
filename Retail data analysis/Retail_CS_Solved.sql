--DATA PREP & UNDERSTANDING

--1)
select 'customer' as [Table Name], count(*) as [No of Records] from dbo.Customer
union 
select 'prod_cat_info' as [Table Name], count(*) as [No of Records] from dbo.prod_cat_info
union
select 'transactions' as [Table Name], count(*) as [No of Records] from dbo.Transactions

--2)Total transactions with returns
select count(*) as Total_Returned_Orders 
from ( select distinct transaction_id 
		from Transactions where qty<0 )  as Result

--3)
	SELECT convert(datetime,tran_date,105) as correct_date from Transactions

/*	NOTE- Dates are already in correct format as at the time of
		  loading all the excel files i chose the appropriate datatype
		  for each field in all the tables.
*/

--4) Time range of transaction data
Select 
    Datediff(Day, Min(tran_date), Max(tran_date)) AS [No of Days],
    Datediff(Month, Min(tran_date), Max(tran_date)) AS [No of Months],
    Datediff(Year, Min(tran_date), Max(tran_date)) AS [No of Years]
From transactions


--5) Which product category does the sub-category 'DIY' belongs to?
select prod_cat from prod_cat_info
where prod_subcat='DIY'

/*-----------------------------------------Some Observations & Understandings about the Data------------------------------------------------ 

1) Transaction_id which comes more than two times i.e 3,4,5 etc it maybe due to the return request was submitted multiple 
   times by the customers for their order.
   Possible Reason:- The company poorly handles the return requests resulting into the multiple entries for the same 
   transaction_id i.e more than twice at different tran_date. It could also be due to the data  

2) For any returned order there cannot be just one record in the transaction table. Ideally they MUST BE IN PAIR 
   i,e one record for placing the order and another for returning the order (but practically as i observed in transaction 
   table there are cases where more than two records are present for returned orders).
   
   But there are two such records in transaction table which have no pair and having total_amt<0 i.e no record about 
   when they were actually placed. 
   So clearly indicating that there is discrepancy in the dataset as their counter-record (i.e when those orders were placed) 
   is somehow not entered in the table.

   NOTE:-
   After consulting with our mentor, i was told to include those two records in Q-2 of Data prep section. 
   Therefore we have 2059 return orders otherwise 2057 should also be right considering there is discrepancy in the dataset.
  */





------------------------------------------------------DATA ANALYSIS-------------------------------------------------------------------------
--Q1 which channel is most frequently used for transactions?
select top 1 Store_type, count(transaction_id) [total transactions] 
from Transactions
where qty>0
group by Store_type
order by [total transactions] desc 



--Q-2 What is the count of male and female customers in database?
select gender, count(*) [Total Customers] 
from Customer
where gender <> ''
group by Gender
order by gender desc



--Q-3 From which city do we have the maximum number of customers and how many?
select top 1  city_code, count(customer_id) as [Total Customers] 
from Customer
group by city_code
order by [Total Customers] desc



--Q-4 How many sub categories are their under the books category?
select count(*) as [Total sub-categories in books category] from 
                     (select prod_cat,prod_subcat from prod_cat_info
					  group by prod_cat,prod_subcat
					  having prod_cat='books') as Books_sub_cat_count



-- Q-5 What is the maximum quantity of products ever ordered?
select max(qty) as max_qty_ever_ordered from transactions 



--Q-6 What is the net total revenue generated in categories 'electronics' and 'books'?
select round(sum(total_amt),2) as [Net revenue from electronics and books] 
from transactions t join prod_cat_info pc 
on pc.prod_cat_code = t.prod_cat_code and pc.prod_sub_cat_code = t.prod_subcat_code

where qty>0 and transaction_id not in ( select distinct transaction_id 
													from transactions 
													where qty<0  ) and prod_cat in ('books','electronics')
												


-- Q-7 How many customers have >10 transactions with us, excluding returns?
select count(*) as No_of_Cust 
from(
				select c.customer_Id,count(transaction_id) as Total_Transactions
				from transactions t 
				join  customer c
				on c.customer_Id=t.cust_id
				
				where qty>0 and transaction_id not in (select distinct transaction_id 
													from transactions 
													where qty<0)
				group by c.customer_Id
				having count(transaction_id) >10
														) as Result



-- Q-8 What is the combined revenue earned from the 'electronics' and 'clothing' categories from 'flagship store'?
select round(sum(total_amt),2) as [Combined Revenue]  
from Transactions t join prod_cat_info pc 
on pc.prod_cat_code=t.prod_cat_code and pc.prod_sub_cat_code=t.prod_subcat_code 

where qty>0 and transaction_id not in ( select distinct transaction_id 
													from transactions 
													where qty<0         )  and prod_cat in ('clothing', 'electronics') 
										                                   and Store_type='flagship store'



--Q-9 What is the total revenue generated from male customers in 'electronics' category? 
--    Ouput should display total revenue by prod sub-cat.
select pc.prod_cat,pc.prod_subcat, round(sum(total_amt),2) as [Total Revenue (by Male)] 
from transactions t join customer c 
on c.customer_Id=t.cust_id join prod_cat_info pc 
on pc.prod_cat_code=t.prod_cat_code and pc.prod_sub_cat_code=t.prod_subcat_code 

where qty>0 and 
		transaction_id not in (select distinct transaction_id 
													from transactions 
													where qty<0)
		and Gender='m' 
		and pc.prod_cat='electronics'
group by pc.prod_cat,pc.prod_subcat	



--Q-10 What is the percentage of sales and returns by product sub category; display only top 5 sub categories in terms of sales?
with sales_by_sub_category as
( 
	select *, round((SALES_TOTAL/sum(SALES_TOTAL) over())*100,2) as SALES_PERCENTAGE 
	from(
		select pc.prod_subcat, round(sum(total_amt),2) as SALES_TOTAL
                from(                            
						select * 
						from Transactions																	            
						where qty>0 and transaction_id not in (select transaction_id 
															  from Transactions
															  group by transaction_id
															  having count(transaction_id)>1)      ) --Total successful orders (18819)   
				as t inner join prod_cat_info pc 
				on t.prod_cat_code=pc.prod_cat_code and t.prod_subcat_code=pc.prod_sub_cat_code
				group by pc.prod_subcat) 
										as result  ),
	
return_by_sub_category as
(	
	select *, round((RETURN_TOTAL/sum(RETURN_TOTAL) over())*100,2) as RETURN_PERCENTAGE 
	from(
		select pc.prod_subcat,round(sum(total_amt),2) as RETURN_TOTAL
                 from(					
                        select * 
						from  transactions								   
						where qty>0 and transaction_id in ( select transaction_id 
															  from Transactions
															  group by transaction_id
															  having count(transaction_id)>1)  )          --TOTAL RETURNED ORDERS (2059)
				as t inner join prod_cat_info pc                                                 
				on t.prod_cat_code=pc.prod_cat_code and t.prod_subcat_code=pc.prod_sub_cat_code
				group by pc.prod_subcat) 
										as result )

select top 5  s.prod_subcat,  Sales_Total,  Sales_percentage,  Return_Total,  Return_Percentage
from sales_by_sub_category s join return_by_sub_category r 
on s.prod_subcat=r.prod_subcat
order by sales_total desc



-- Q-11 For all customers aged between 25 to 35 find what is the net total revenue generated by these consumers in last 30 days of
--      transactions from max transaction date available in data.

with max_tran_date as
(select max(tran_date) as max_date from Transactions), 

transactions_L_30Days as
(	
	select t.*, c.DOB, m.max_date
	from Transactions t join Customer c 
	on c.customer_Id=t.cust_id
	cross join max_tran_date m
	
	where qty>0 and tran_date>= DATEADD(DAY,-30, max_date)  
						and transaction_id  not in (select distinct transaction_id from transactions 
													where qty<0)
						                                                                    )
Select round(sum(total_amt),2) [Total Revenue]   
from transactions_L_30Days
where DATEDIFF(year,Dob,max_date) between 25 and 35

--Q-12 Which product category has seen max value of returns in last three months of transactions?
select Top 1 pc.prod_cat, round(sum(total_amt),2) as Max_Price_val_return, round(sum(qty),2) as Max_Quantity_val_return
from(
	    select *  
		from Transactions
		where qty>0 and tran_date> ( select DATEADD(month,-3,max(tran_date)) from transactions) 
					and transaction_id  in (select distinct transaction_id from transactions 
						                                               where qty<0)
																			        ) as Ret_Ord_3M    --Total 155 orders in last 3 months which were returned. 
																			                           -- And 1408 were successful orders in last 3 months.
inner join prod_cat_info pc                                                                    
on pc.prod_cat_code = Ret_Ord_3M.prod_cat_code and pc.prod_sub_cat_code = Ret_Ord_3M.prod_subcat_code
group by pc.prod_cat
order by Max_Price_val_return desc



--Q-13 Which store type sells the maximum products; by value of sales amount and by quantity sold?
select top 1 Store_type,round(sum(total_amt),2) as Total_Sales_amount, round(sum(qty),2) as Total_Qty_sold
from(                            
		select * from Transactions
		where qty>0 and transaction_id not in (select transaction_id 
															  from Transactions
															  group by transaction_id
															  having count(transaction_id)>1) 
						                                                         ) as successful_orders 
group by store_type
order by Total_Sales_amount desc, total_qty_sold desc



--Q-14 what are the categories for which average revenue is above the overall average?
with successful_orders as 
(
		select pc.prod_cat,total_amt  
		from(                            
				select * from Transactions
			    where qty>0 and transaction_id not in (select transaction_id 
															  from Transactions
															  group by transaction_id
															  having count(transaction_id)>1)) 
		as t inner join prod_cat_info pc 
		on pc.prod_cat_code = t.prod_cat_code and pc.prod_sub_cat_code = t.prod_subcat_code
																									)
			                                                             
select prod_cat, avg(total_amt) as [Avg_rev_per_category] 
from successful_orders
group by prod_cat
having avg(total_amt)> (select avg(total_amt) from successful_orders)  --ordinary subquery on cte to get overall avg.



-- Q-15 Find the avg and total revenue by each subcategory for the categories which are among top 5 categories in terms of quantity sold.
with successful_orders as 
(
	select t.total_amt, t.Qty ,pc.*  
	from Transactions t join prod_cat_info pc 
	on pc.prod_cat_code=t.prod_cat_code and pc.prod_sub_cat_code=t.prod_subcat_code

	where qty>0 and transaction_id not in (select transaction_id from Transactions
																 group by transaction_id
																 having count(transaction_id)>1)															 
					                                                                                  ),
top_5_category as
(
	select top 5 prod_cat, sum(qty) as total_qty_sold 
	from successful_orders
	group by prod_cat
	order by total_qty_sold desc
                                  )

select so.prod_cat, prod_subcat, round(avg(total_amt),2) as [Average Revenue], round(sum(total_amt),2) as [Total Revenue]  
from successful_orders so inner join top_5_category tp5 
on so.prod_cat = tp5.prod_cat 
group by so.prod_cat,prod_subcat
order by [Total Revenue] desc


