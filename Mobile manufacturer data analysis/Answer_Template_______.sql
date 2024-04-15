--Q1--BEGIN . List all the states in which we have customers who have bought cellphones from 2005 till today.
	
select l.State  from FACT_TRANSACTIONS t right join DIM_LOCATION l on l.IDLocation=t.IDLocation 
		 right join DIM_DATE d on d.DATE=t.Date
		 right join DIM_CUSTOMER c on c.IDCustomer=t.IDCustomer
where d.year>=2005

--Q1--END

--Q2--BEGIN . What state in the US is buying the most 'Samsung' cell phones?
select top 1 l.State, count(*) as Total_Ph_Sold from FACT_TRANSACTIONS t right join DIM_LOCATION l 
         on t.IDLocation=l.IDLocation
		 inner join DIM_MODEL m on m.IDModel=t.IDModel
		 inner join DIM_MANUFACTURER ma on ma.IDManufacturer=m.IDManufacturer
		 where ma.Manufacturer_Name='Samsung' and l.Country='us'
		 group by l.State
		 order by Total_Ph_Sold desc
--Q2--END

--Q3--BEGIN      . Show the number of transactions for each model per zip code per state.
select m.Model_Name,l.ZipCode,l.State,count(*) [No of transactions] from FACT_TRANSACTIONS t right join DIM_MODEL m on  t.IDModel=m.IDModel
	     right join DIM_LOCATION l on l.IDLocation=t.IDLocation

		 group by m.Model_Name,l.ZipCode,l.State
		 order by m.Model_Name,l.ZipCode,l.State

--Q3--END

--Q4--BEGIN. Show the cheapest cellphone (Output should contain the price also)
select top 1 Model_Name,Manufacturer_Name, Unit_price 
                        from DIM_MODEL m join DIM_MANUFACTURER ma 
                        on m.IDManufacturer=ma.IDManufacturer	
order by Unit_price asc
--Q4--END

--Q5--BEGIN . Find out the average price for each model in the top5 manufacturers in terms of sales quantity and order by average price.

------------------Not so Optimized approach--------------------------------
select m.Model_Name, avg(t.TotalPrice) as Avg_Price 
from 
                       (select  top 5 ma.IDManufacturer,ma.Manufacturer_Name, sum(t.Quantity) as [sales quantity] 
					    from FACT_TRANSACTIONS t right join DIM_MODEL m on m.IDModel=t.IDModel
                        right join DIM_MANUFACTURER ma on ma.IDManufacturer=m.IDManufacturer
						group by ma.Manufacturer_Name, ma.IDManufacturer
						order by [sales quantity] desc) as top5_manufac 
		 left join DIM_MODEL m on top5_manufac.IDManufacturer=m.IDManufacturer
		 left join FACT_TRANSACTIONS t on t.IDModel=m.IDModel
		 group by m.Model_Name
		 order by Avg_Price

------------------Optimized Approach------------------------------------------
select Model_Name,avg(totalprice) as Avg_Price from (select *, DENSE_RANK() over( order by  [sales quantity] desc) as rank_ 
                        from (select ma.IDManufacturer,ma.Manufacturer_Name,m.Model_Name,t.Quantity,t.TotalPrice, 
						sum(t.Quantity) over(partition by ma.manufacturer_name,ma.idmanufacturer) as [sales quantity] 
					    from FACT_TRANSACTIONS t right join DIM_MODEL m on m.IDModel=t.IDModel
                        right join DIM_MANUFACTURER ma on ma.IDManufacturer=m.IDManufacturer) as nt) as ranked_manufac
where rank_<=5
group by Model_Name
order by Avg_Price




--Q5--END

--Q6--BEGIN  . List the names of the customers and the average amount spent in 2009, where the average is higher than 500
----------------------Poor optmization and readability issue------------------------------------
select * from (select distinct c.Customer_Name ,avg(t.TotalPrice) over(partition by c.idcustomer) as [Avg amount spend] 
                     from FACT_TRANSACTIONS t right join DIM_CUSTOMER c on c.IDCustomer=t.IDCustomer
                     right join DIM_DATE d on d.DATE=t.Date
					 where d.YEAR=2009) as avg_tran_in2009

where [Avg amount spend]>500
------------------------Better at expressing and optmized as well--------------------------------
select c.Customer_Name, avg(t.totalprice) as x 
from FACT_TRANSACTIONS t join DIM_DATE d on d.date=t.date
         join DIM_CUSTOMER c on c.IDCustomer=t.IDCustomer
		 where d.year=2009 
		 group by c.Customer_Name
		 having avg(t.totalprice)>500
--Q6--END
	
--Q7--BEGIN  . List if there is any model that was in the top 5 in terms of quantity, simultaneously in 2008, 2009 and 2010.
/*
THIS APPROACH WONT WORK UNLESS YOU USE JOINS BETWEEN THE TEMPORARY TABLES AS ORDER BY DONT WORK WITH IN VIEWS,SUBQUERY and CTEs


select distinct  t.IDModel, sum(t.quantity) over(partition by t.idmodel) as Total_Quantity 
from FACT_TRANSACTIONS t right join  DIM_DATE d on d.DATE=t.Date
where d.YEAR=2008
order by Total_Quantity desc
intersect
select distinct top 5  t.IDModel, sum(t.quantity) over(partition by t.idmodel) as Total_Quantity 
from FACT_TRANSACTIONS t right join  DIM_DATE d on d.DATE=t.Date
where d.YEAR=2009
order by Total_Quantity desc
 */

select idmodel,model_name  
from (
		select IDModel,total_quantity,model_name,row_number() over(partition by yr order by total_quantity desc ) as rank_ 
				from(
						select distinct t.IDModel,m.model_name,year(date) as yr,sum(t.quantity) over(partition by t.idmodel,year(date)) as total_quantity 
						from FACT_TRANSACTIONS t 
						join DIM_MODEL m on m.IDModel=t.IDModel 
						where year(date) in (2008,2009,2010)) as t1 
								                                       ) as ranked_ModelIDs
where rank_<=5
group by IDModel, model_name
having count(idmodel)=3

------------Using CTEs----------------------------------------
with top5_models_by_quantity_2008 as
(select * from (select IDModel,row_number() over(order by total_quantity desc ) as rank_ 
                         from(select distinct t.IDModel,sum(t.quantity) over(partition by t.idmodel) as total_quantity 
								from FACT_TRANSACTIONS t join DIM_DATE d on d.DATE=t.Date
								where d.YEAR=2008) as ranked_ModelIDs
								)as x
								where rank_<=5),
top5_models_by_quantity_2009 as
(select * from (select IDModel,row_number() over(order by total_quantity desc ) as rank_ 
                         from(select distinct t.IDModel,sum(t.quantity) over(partition by t.idmodel) as total_quantity 
								from FACT_TRANSACTIONS t join DIM_DATE d on d.DATE=t.Date
								where d.YEAR=2009) as ranked_ModelIDs
								)as x
								where rank_<=5),
top5_models_by_quantity_2010 as
(select * from (select IDModel,row_number() over(order by total_quantity desc ) as rank_ 
                         from(select distinct t.IDModel,sum(t.quantity) over(partition by t.idmodel) as total_quantity 
								from FACT_TRANSACTIONS t join DIM_DATE d on d.DATE=t.Date
								where d.YEAR=2010) as ranked_ModelIDs
								)as x
								where rank_<=5)
-- (104,105,109,130,111) (101,107,121,109,123)(108,109,118,122,123)
select m.IDModel,m.Model_Name from				
			(	select idmodel from top5_models_by_quantity_2008
				intersect
				select idmodel from top5_models_by_quantity_2009
				intersect
				select idmodel from top5_models_by_quantity_2010
				) as common_id 
		join DIM_MODEL m on m.IDModel=common_id.IDModel

--Q7--END	
--Q8--BEGIN  
-- Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer with the 2nd top sales in the year of 2010.
------------------------------- READABLE AND WELL OPTIMIZED-------------------------------
with Sales_by_Manufacturers_in_2009_10 as
(select *, rank() over(partition by year order by total_sales  desc) as rank_ from 
									(
										select distinct ma.Manufacturer_Name,year(t.date) as [Year], 
										    sum(t.TotalPrice) over(partition by ma.manufacturer_name,year(t.date)) as Total_sales  
										from FACT_TRANSACTIONS t right join DIM_MODEL m 
										on t.IDModel=m.IDModel 
										right join DIM_MANUFACTURER ma 
	 								    on ma.IDManufacturer=m.IDManufacturer
									    where year(t.Date) in (2009,2010)
																					) as rank_wise_sales)
select * from Sales_by_Manufacturers_in_2009_10
where rank_=2
---------------------------MORE READABLE BUT LESS OPTIMIZED (IF SIZE OF THE DATASET IS HUGE)----------------------
with Sales_by_Manufacturers_in_2009 as
(select *, rank() over(order by total_sales  desc) as rank_ from 
									(
										select distinct ma.Manufacturer_Name,year(t.date) as [Year], 
										    sum(t.TotalPrice) over(partition by ma.manufacturer_name) as Total_sales  
										from FACT_TRANSACTIONS t right join DIM_MODEL m 
										on t.IDModel=m.IDModel 
										right join DIM_MANUFACTURER ma 
	 								    on ma.IDManufacturer=m.IDManufacturer
									    where year(t.Date)=2009
																					) as top_manufacturers_2009 ),

Sales_by_Manufacturers_in_2010 as
(select *, rank() over(order by total_sales  desc) as rank_ from 
									(
										select distinct ma.Manufacturer_Name,year(t.date) as [Year], 
											sum(t.TotalPrice) over(partition by ma.manufacturer_name) as Total_sales  
										from FACT_TRANSACTIONS t right join DIM_MODEL m 
										on t.IDModel=m.IDModel 
									    right join DIM_MANUFACTURER ma 
	 								    on ma.IDManufacturer=m.IDManufacturer
									    where year(t.Date)=2010
																					) as top_manufacturers_2010 )

select * from Sales_by_Manufacturers_in_2009
where rank_=2
union all
select * from Sales_by_Manufacturers_in_2010
where rank_=2


--Q8--END
--Q9--BEGIN . Show the manufacturers that sold cellphones in 2010 but did not in 2009.
	

--manufactures in 2010 except manufacturers in 2009

select Manufacturer_Name from (select distinct ma.Manufacturer_Name,year(t.date) as year, 
								count(*) over(PARTITION by ma.idmanufacturer, year(t.date)) as transaction_count 
                        
						from FACT_TRANSACTIONS t 
						join DIM_MODEL m on m.IDModel=t.IDModel
						join DIM_MANUFACTURER ma on ma.IDManufacturer=m.IDManufacturer
						where year(t.date) in (2009,2010)) as c
group by Manufacturer_Name
having count(manufacturer_name)=1

--Q9--END

--Reason why the top 100 customer cant be shown for each year!
select year(t.date), count(distinct t.idcustomer) from DIM_CUSTOMER c join FACT_TRANSACTIONS t on t.IDCustomer=c.IDCustomer 
group by year(t.date)



--Q10--BEGIN 
-- Find top 10 customers and their average spend, average quantity by each year. Also find the percentage of change in their spend.

-------------------------------------------USING CTE---------------------------------------
with Avg_QTY_Spend_with_top_10_cust as
(select  distinct c.IDCustomer, d.year,cast(avg(t.Quantity) over(partition by c.idcustomer,d.year) as float) as avg_quantity, 
									avg(t.TotalPrice) over(partition by c.idcustomer, d.year)  as Avg_spend	
									from FACT_TRANSACTIONS t 
									join DIM_CUSTOMER c on c.IDCustomer=t.IDCustomer
									join DIM_DATE d on d.DATE=t.Date
									where c.idcustomer in (select top 10 idcustomer from 
											FACT_TRANSACTIONS 
											where TotalPrice>0 
											group by IDCustomer 
											order by sum(TotalPrice) desc)	),
 Yoy_calculation_and_result as
( select *, (((avg_spend)-(prev_yr_avg))/(prev_yr_avg))*100 as [yoy_%age] 	from
				(select * ,case 
							when year=year_min then null else lag(avg_spend,1) over(order by idcustomer) end as prev_yr_avg
								from (select *, min(year) over(partition by idcustomer) as year_min 
								from Avg_QTY_Spend_with_top_10_cust ) as cal_of_avg_prev_yr
) as c)
 
select * from yoy_calculation_and_result
																																									
																																									
																																									
																																									where IDCustomer=10006
with avg_spend_qty as
(select *, case
				when year=2003 
				
				
				then null else lag(avg_spend,1) over(order by idcustomer) end as prev_yr_avg
				from( 
				select distinct c.IDCustomer, d.year, avg(t.TotalPrice) over(partition by c.idcustomer, d.year)  as Avg_spend,
									cast(avg(t.Quantity) over(partition by c.idcustomer,d.year) as float) as avg_quantity	
									from FACT_TRANSACTIONS t 
									join DIM_CUSTOMER c on c.IDCustomer=t.IDCustomer
									join DIM_DATE d on d.DATE=t.Date ) as yoy_prep ),
yoy_and_rank as
( select *,row_number() over(partition by year order by avg_spend desc,avg_quantity desc) as Yearly_Rank
			from (select *, (((avg_spend)-(prev_yr_avg))/(prev_yr_avg))*100 as [yoy_%age] 
							from avg_spend_qty) with_rank_yoy)
select * from yoy_and_rank
where Yearly_Rank<=10
--Q10--END
	