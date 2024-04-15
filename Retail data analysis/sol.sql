
----------------------------ABOUT DUPLICATE RECORDS---------------------------- 
--	There are total 4232 records which are inserted atleast more than twice in transaction table.
--	And there are 2057 unique transaction_id or orders which were actually returned (as their count is more than 1).
--	So 4232 - (2057*2)= 118 
--	Hence there are 118 rows in transaction table corresponding to those ids which are present 
--	more than equal to 3 (112 ids i.e 112*1) and more than equal to 4 ( 3 ids i.e 3*2) times.
select distinct transaction_id from Transactions---------------20878
select distinct transaction_id from Transactions---------------20876
where Qty>0 and Rate>0 and total_amt>0


select transaction_id, count(transaction_id) from transactions
group by transaction_id
having count(transaction_id)=1




--DATA PREP & UNDERSTANDING

--1)
select  (select count(*) from customer) as total_cust_records,
  (select count(*) from prod_cat_info) as total_categories,
   (select count(*) from Transactions) as total_transactions_records
-----------------------------or-----------------------------------------------------
select 'customer' as [Table Name], count(*) as [No of Records] from dbo.Customer
union 
select 'prod_cat_info' as [Table Name], count(*) as [No of Records] from dbo.prod_cat_info
union
select 'transactions' as [Table Name], count(*) as [No of Records] from dbo.Transactions


/*-----------------------------------------Some important observations--------------------------------------------------------------------------- 
1) Any transaction_id that comes more than once in transactions table corresponds to orders that must have been returned.
2) Transaction_id which comes more than two times i.e 3,4,5 etc indicates that their can be duplicate records corresponding to those ids
   OR it could be due to a consumer had requested for cancelling the order multiple times.
3) For any returned order there cannot be just one record in the transaction table for that order. Ideally they MUST BE IN PAIR 
   i,e one record for placing the order and another for returning the order. There are two records in transaction table which are not 
   in pair hence must be avoided.*/
select distinct transaction_id from Transactions
except
select transaction_id from Transactions
where Qty>0 and Rate>0 and total_amt>0

select * from Transactions
where transaction_id in ('97439039119','8868056339')

-- so these two transaction_id should not be used.



-------Test table to see records corresponding to return orders-------------- 
select * from (select transaction_id, count(transaction_id) total from Transactions
group by transaction_id
having count(transaction_id)>1) as return_orders join Transactions t on t.transaction_id=return_orders.transaction_id
order by t.transaction_id

--Successful orders
select * from transactions
where qty>0 and transaction_id not in (select transaction_id from Transactions group by transaction_id having count(transaction_id)>1)
--Returned orders
select * from transactions
where qty>0 and transaction_id in (select transaction_id from Transactions group by transaction_id having count(transaction_id)>1)


--2)Total transactions with returns
select distinct transaction_id from Transactions
where qty<0

----------------------------ABOUT RECORDS ---------------------------- 
--	There are total 4232 records which are inserted atleast more than twice in transaction table.
--	And there are 2057 unique transaction_id or orders which were actually returned (as their count is more than 1).
--	So 4232 - (2057*2)= 118 
--	Hence there are 118 rows in transaction table corresponding to those ids which are present 
--	more than equal to 3 (112 ids i.e 112*1) and more than equal to 4 ( 3 ids i.e 3*2) times.

--3) Dates are already in correct format


--4) Time range of transaction data
select (select DATEDIFF(day,min(tran_date),max(tran_date)) from Transactions) as [No of Days],
        (select DATEDIFF(MONTH,min(tran_date),max(tran_date)) from Transactions) as [No of Months] ,
		(select DATEDIFF(YEAR,min(tran_date),max(tran_date)) from Transactions) as [No of Years]

--------------OR (More efficient)---------------------
SELECT 
    DATEDIFF(DAY, MIN(tran_date), MAX(tran_date)) AS [No of Days],
    DATEDIFF(MONTH, MIN(tran_date), MAX(tran_date)) AS [No of Months],
    DATEDIFF(YEAR, MIN(tran_date), MAX(tran_date)) AS [No of Years]
FROM Transactions

--5) Which product category does the sub-category 'DIY' belongs to?

select prod_cat from prod_cat_info
where prod_subcat='DIY'

-----------------------------------------DATA ANALYSIS-------------------------------------------
--Q1 which channel is most frequently used for transactions?
select top 1 Store_type, count(transaction_id) [total transactions] from Transactions
where qty>0
group by Store_type
order by [total transactions] desc 


--Q-2 What is the count of male and female customers in database?
select gender, count(*) [Total Customers] from Customer
where gender <> ''
group by Gender
order by gender desc

--Q-3 From which city do we have the maximum number of customers and how many?
select top 1  city_code, count(customer_id) as [Total Customers] from Customer
group by city_code
order by [Total Customers] desc

--Q-4 How many sub categories are their under the books category?

select count(*) as [Total sub-categories in books category] from 
                     (select prod_cat,prod_subcat from prod_cat_info
					  group by prod_cat,prod_subcat
					  having prod_cat='books') as Books_sub_cat_count


-- Q-5 What is the maximum quantity of products ever ordered?
/*select prod_cat,max(qty) from transactions t join prod_cat_info pc on pc.prod_cat_code=t.prod_cat_code and pc.prod_sub_cat_code=t.prod_subcat_code
where t.qty>0
group by prod_cat*/


select max(qty) from transactions 

--Q-6 What is the net total revenue generated in categories 'electronics' and 'books'?
 
select round(sum(total_amt),2) as [Net revenue from electronics and books] 
from transactions t 
join  prod_cat_info pc 
on pc.prod_cat_code = t.prod_cat_code and pc.prod_sub_cat_code = t.prod_subcat_code
where qty>0 and transaction_id not in (select transaction_id 
												from Transactions 
												group by transaction_id		
												having count(transaction_id)>1) and prod_cat in ('books','electronics') 

-- Q-7 How many customers have >10 transactions with us, excluding returns?

select c.customer_Id,count(transaction_id) as Total_Transactions
from transactions t 
join  customer c
on c.customer_Id=t.cust_id
where qty>0 and transaction_id not in (select transaction_id 
												from Transactions 
												group by transaction_id		
												having count(transaction_id)>1)
group by c.customer_Id
having count(transaction_id) >10

-- Q-8 What is the combined revenue earned from the 'electronics' and 'clothing' categories from 'flagship store'?
select round(sum(total_amt),2) as [Combined Revenue]  from Transactions t join prod_cat_info pc 
on pc.prod_cat_code=t.prod_cat_code and pc.prod_sub_cat_code=t.prod_subcat_code 
where qty>0 and transaction_id not in (select transaction_id 
											from Transactions 
											group by transaction_id 
											having count(transaction_id)>1) and prod_cat in ('clothing', 'electronics') and Store_type= 'flagship store'
						        		         

--Q-9 What is the total revenue generated from male customers in 'electronics' category? 
--    Ouput should display total revenue by prod sub-cat.

select pc.prod_cat,pc.prod_subcat, round(sum(total_amt),2) as [Total Revenue (by Male)] from 
transactions t 
join customer c 
on c.customer_Id=t.cust_id 
join prod_cat_info pc 
on pc.prod_cat_code=t.prod_cat_code and pc.prod_sub_cat_code=t.prod_subcat_code 
where qty>0 and 
		transaction_id not in (select transaction_id from Transactions group by transaction_id having count(transaction_id)>1)
		and Gender='m' 
		and pc.prod_cat='electronics'
group by pc.prod_cat,pc.prod_subcat		  



--Q-10 What is the percentage of sales and returns by product sub category; display only top 5 sub categories in terms of sales?
with sales_by_sub_category as
( 
select *, round((SALES_TOTAL/sum(SALES_TOTAL) over())*100,2) as SALES_PERCENTAGE from
    (select pc.prod_subcat, round(sum(total_amt),2) as SALES_TOTAL
                from(                            
					select * from Transactions
					where qty>0 and transaction_id not in (	select transaction_id from Transactions
															group by transaction_id
															having count(transaction_id)>1)  ) as t 
				inner join prod_cat_info pc 
				on t.prod_cat_code=pc.prod_cat_code and t.prod_subcat_code=pc.prod_sub_cat_code
	group by pc.prod_subcat) as result),
	
return_by_sub_category as
(	
select *, round((RETURN_TOTAL/sum(RETURN_TOTAL) over())*100,2) as RETURN_PERCENTAGE from
	(select pc.prod_subcat,round(sum(total_amt),2) as RETURN_TOTAL
                 from(					
                        select * from  transactions                      --TOTAL RETURNED ORDERS (2057) except the two orders    
						where qty>0 and transaction_id in ( select transaction_id from Transactions
															group by transaction_id
															having count(transaction_id)>1)  ) as t
				inner join prod_cat_info pc 
				on t.prod_cat_code=pc.prod_cat_code and t.prod_subcat_code=pc.prod_sub_cat_code
	group by pc.prod_subcat ) as result)

select top 5  s.prod_subcat, Sales_Total , Sales_percentage, Return_Total,Return_Percentage
from sales_by_sub_category s join return_by_sub_category r 
on s.prod_subcat=r.prod_subcat
order by s.sales_total desc

/*------------------FAILED OUTPUT------------------------------
combined_data as
(Select 'sales' as TransactionType,
         prod_subcat,
		 total_amt as	Amount
		 from successful_orders
		 union all
 Select 'Return' as TransactionType,
         prod_subcat,
		 returned_amt as Amount
		 from returned_orders),

subcategory_summary AS (
    SELECT
        prod_subcat,
        TransactionType,
        round(SUM(Amount),2) AS TotalAmount
    FROM combined_data
    GROUP BY
        prod_subcat,
        TransactionType
)

select *,(TotalAmount / (SUM(TotalAmount) OVER ()+sum(totalamount) over()))*100 AS percentage from subcategory_summary
order by 
   case when TransactionType='sales' then TotalAmount end desc,
   case when TransactionType='return' then TotalAmount end asc */


-- Q-11 For all customers aged between 25 to 35 find what is the net total revenue generated by these consumers in last 30 days of
--      transactions from max transaction date available in data.

with successful_orders as 
( 
    select t.transaction_id,cust_id,tran_date,prod_subcat_code,prod_cat_code,qty,rate,tax,total_amt,Store_type 
                from(                            
						select transaction_id 
						from transactions                          --TOTAL ORDERS PLACED (20876) exluding two transaction ids
						where qty>0 and rate>0 and total_amt>0     --which are inserted only once but with negative qty,rate and amount. 
						except                                     --TOTAL- RETURNED= successful orders
						select transaction_id                      --TOTAL RETURNED ORDERS (2057)
						from Transactions    
						group by transaction_id
						having count(transaction_id)>1
						                               ) 					
				as t1 inner join Transactions t on t.transaction_id = t1.transaction_id
		         ),
cust_with_age as
(	select *, datediff(year, DOB, getdate()) as age
                from customer
				 ) 

select round(sum(so.total_amt),2) as [Total Revenue Generated] from successful_orders so join cust_with_age c on c.customer_Id=so.cust_id 
where so.tran_date> (select DATEADD(day,-30, max(tran_date)) from successful_orders) and (c.age between 25 and 35) 

													   

--Q-12 Which product category has seen max value of returns in last three months of transactions?
select top 1 prod_cat_code, round(sum(Qty),2) as [Total_order_value_returned] 
                                              from (
													select transaction_id    --find tran_id wrt those orders which were returned in past 3 months.
													from Transactions        
													where tran_date > ( select DATEADD(month,-3,max(tran_date)) from transactions)
													group by transaction_id
													having count(transaction_id)>1) as Ret_orders_3m
				
									          inner join Transactions t on t.transaction_id = Ret_orders_3m.transaction_id
											  where t.qty>0 
                                              group by prod_cat_code
											  order by Total_order_value_returned desc



--Total 1745 order placed in last 3 months. 
--There are only 155 orders which were returned.

--Q-13 Which store type sells the maximum products; by value of sales amount and by quantity sold?
-----------need to discuss this question------------------------
select top 1 Store_type,round(sum(total_amt),2) as sales_amount, round(sum(qty),2) as total_qty_sold
         from(                            
			  select * from Transactions
			  where qty>0 and transaction_id not in (select transaction_id from Transactions
													 group by transaction_id
													 having count(transaction_id)>1)  
						                               ) as t 
group by store_type
order by sales_amount desc, total_qty_sold desc


--Q-14 what are the categories for which average revenue is above the overall average?
with successful_orders as 
( 
    select pc.prod_cat,total_amt  
			from(                            
                    select * from Transactions
			        where qty>0 and transaction_id not in (select transaction_id from Transactions
															  group by transaction_id
															  having count(transaction_id)>1) ) as t 
	 inner join prod_cat_info pc 
	 on pc.prod_cat_code=t.prod_cat_code and pc.prod_sub_cat_code=t.prod_subcat_code)
			                                                               
select prod_cat, avg(total_amt) as [Avg_rev_per_category] from successful_orders
group by prod_cat
having avg(total_amt)> (select avg(total_amt) from successful_orders)  --ordinary subquery on cte to get overall avg.

------------------------------------- Using Subquery-------------------------------
select prod_cat, avg(total_amt) as [Avg_rev_per_category] 
from Transactions t join prod_cat_info pc 
on pc.prod_cat_code=t.prod_cat_code and pc.prod_sub_cat_code=t.prod_subcat_code
where qty>0 and transaction_id not in (select transaction_id from Transactions
													 group by transaction_id
													 having count(transaction_id)>1) 
group by prod_cat
having avg(total_amt) > (select avg(total_amt) from Transactions
							where qty>0 and transaction_id not in (select transaction_id from Transactions
																	group by transaction_id
																	having count(transaction_id)>1))

-- Q-15 Find the avg and total revenue by each subcategory for the categories which are among top 5 categories in terms of quantity sold.

with successful_orders as 
( 
select t.total_amt, t.Qty ,pc.*  from Transactions t join prod_cat_info pc 
on pc.prod_cat_code=t.prod_cat_code and pc.prod_sub_cat_code=t.prod_subcat_code
where qty>0 and transaction_id not in (select transaction_id from Transactions
															  group by transaction_id
															  having count(transaction_id)>1)
															 
					                                                                       ),
top_5_cat as
(
	select top 5 prod_cat, sum(qty) as total_qty_sold 
	from successful_orders
	group by prod_cat
	order by total_qty_sold desc
                                  )

select so.prod_cat, prod_subcat, round(avg(total_amt),2) as [Average Revenue], round(sum(total_amt),2) as [Total Revenue]  
from successful_orders so inner join top_5_cat tp5 
on so.prod_cat = tp5.prod_cat 
group by so.prod_cat,prod_subcat
order by [Total Revenue] desc

/*
with successful_orders as 
( 
    select t.transaction_id,cust_id,tran_date,prod_subcat_code,prod_cat_code,qty,rate,tax,total_amt,Store_type 
                from(                            
						select transaction_id 
						from transactions                          --TOTAL ORDERS PLACED (20876) exluding two transaction ids
						where qty>0 and rate>0 and total_amt>0     --which are inserted only once but with negative qty,rate and amount. 
						except                                     --TOTAL- RETURNED= successful orders
						select transaction_id                      --TOTAL RETURNED ORDERS (2057)
						from Transactions    
						group by transaction_id
						having count(transaction_id)>1
						                               ) 					
				as t1 inner join Transactions t on t.transaction_id = t1.transaction_id
					                                                                       ),
top_5_cat as
(
	select top 5 prod_cat_code, sum(qty) as total_qty_sold 
	from successful_orders
	group by prod_cat_code
	order by total_qty_sold desc
                                  )
select * from top_5_cat
select pc.prod_cat, pc.prod_subcat, round(avg(total_amt),2) as [Average Revenue], round(sum(total_amt),2) as [Total Revenue]  
from successful_orders so inner join top_5_cat tp5 
on so.prod_cat_code = tp5.prod_cat_code inner join prod_cat_info pc 
on pc.prod_cat_code=so.prod_cat_code and pc.prod_sub_cat_code=so.prod_subcat_code
group by pc.prod_cat,pc.prod_subcat
order by [Total Revenue] desc

*/






		select * from transactions
		where transaction_id not in (select transaction_id from successful_orders)
 

select prod_cat_code as [category],sum(Qty) as qty_sold 
from transactions
where (Qty>0 and Rate>0 and total_amt>0)
group by prod_cat_code


