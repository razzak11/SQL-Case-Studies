--Q1--BEGIN 
--List all the states in which we have customers who have bought cellphones from 2005 till today.
	
select distinct l.State  from FACT_TRANSACTIONS t right join DIM_LOCATION l on l.IDLocation=t.IDLocation 
		 right join DIM_DATE d on d.DATE=t.Date
		 right join DIM_CUSTOMER c on c.IDCustomer=t.IDCustomer
where d.year>=2005

--Q1--END

--Q2--BEGIN 
--What state in the US is buying the most 'Samsung' cell phones?

select top 1 l.State, count(*) as Total_Ph_Sold from FACT_TRANSACTIONS t right join DIM_LOCATION l 
         on t.IDLocation=l.IDLocation
		 inner join DIM_MODEL m on m.IDModel=t.IDModel
		 inner join DIM_MANUFACTURER ma on ma.IDManufacturer=m.IDManufacturer
		 where ma.Manufacturer_Name='Samsung' and l.Country='us'
		 group by l.State
		 order by Total_Ph_Sold desc
--Q2--END

--Q3--BEGIN      
--Show the number of transactions for each model per zip code per state.

select m.Model_Name,l.ZipCode,l.State,count(*) [No of transactions] from FACT_TRANSACTIONS t right join DIM_MODEL m on  t.IDModel=m.IDModel
	     right join DIM_LOCATION l on l.IDLocation=t.IDLocation

		 group by m.Model_Name,l.ZipCode,l.State
		 order by m.Model_Name,l.ZipCode,l.State

--Q3--END

--Q4--BEGIN
--Show the cheapest cellphone (Output should contain the price also)

select top 1 Model_Name,Manufacturer_Name, Unit_price 
                        from DIM_MODEL m join DIM_MANUFACTURER ma 
                        on m.IDManufacturer=ma.IDManufacturer	
order by Unit_price asc
--Q4--END

--Q5--BEGIN 
--Find out the average price for each model in the top5 manufacturers in terms of sales quantity and order by average price.

select Model_Name,round(avg(totalprice),2) as Avg_Price 
from (
		select *, DENSE_RANK() over( order by  [sales quantity] desc) as rank_ 
        from(
				select ma.IDManufacturer, ma.Manufacturer_Name, m.Model_Name, t.Quantity, t.TotalPrice, 
					   sum(t.Quantity) over(partition by ma.manufacturer_name,ma.idmanufacturer) as [sales quantity] 
				from FACT_TRANSACTIONS t right join DIM_MODEL m 
				on m.IDModel=t.IDModel
                right join DIM_MANUFACTURER ma 
				on ma.IDManufacturer=m.IDManufacturer	) as t     
																) as ranked_manufacturers
where rank_<=5
group by Model_Name
order by Avg_Price




--Q5--END

--Q6--BEGIN  
--List the names of the customers and the average amount spent in 2009, where the average is higher than 500

select c.Customer_Name, avg(t.totalprice) as Average_Price 
from FACT_TRANSACTIONS t join DIM_DATE d on d.date=t.date
         join DIM_CUSTOMER c on c.IDCustomer=t.IDCustomer
		 where d.year=2009 
		 group by c.Customer_Name
		 having avg(t.totalprice)>500

--Q6--END

--Q7--BEGIN  
--List if there is any model that was in the top 5 in terms of quantity, simultaneously in 2008, 2009 and 2010.

select IDModel, model_name
from(
		select IDModel,total_quantity,model_name,yr,row_number() over(partition by yr order by total_quantity desc ) as rank_ 
				from(
						select distinct t.IDModel,m.model_name,year(date) as yr,sum(t.quantity) over(partition by t.idmodel,year(date)) as total_quantity 
						from FACT_TRANSACTIONS t 
						join DIM_MODEL m on m.IDModel=t.IDModel 
						where year(date) in (2008,2009,2010)) as t1 
								                                       ) as ranked_ModelIDs
where rank_<=5
group by IDModel, model_name
having count(idmodel)=3



--Q7--END	

--Q8--BEGIN
--Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer with the 2nd top sales in the year of 2010.
with Sales_by_Manufacturers_in_2009_10 as
(select *, rank() over(partition by year order by total_sales  desc) as rank_ 
from(
		select distinct ma.Manufacturer_Name,year(t.date) as [Year], 
								sum(t.TotalPrice) over(partition by ma.manufacturer_name,year(t.date)) as Total_sales  
		from FACT_TRANSACTIONS t right join DIM_MODEL m 
	    on t.IDModel=m.IDModel 
	    right join DIM_MANUFACTURER ma 
	 	on ma.IDManufacturer=m.IDManufacturer
		where year(t.Date) in (2009,2010)
																			)   as rank_wise_sales)
select * from Sales_by_Manufacturers_in_2009_10
where rank_=2

--Q8--END


--Q9--BEGIN . 
--Show the manufacturers that sold cellphones in 2010 but did not in 2009.

select Manufacturer_Name 
from(
		select distinct ma.Manufacturer_Name,year(t.date) as year, 
								count(*) over(PARTITION by ma.idmanufacturer, year(t.date)) as transaction_count 
                        
		from FACT_TRANSACTIONS t 
		join DIM_MODEL m on m.IDModel=t.IDModel
		join DIM_MANUFACTURER ma on ma.IDManufacturer=m.IDManufacturer
		where year(t.date) in (2009,2010)          
		                                    ) as Manufacturer_Tran_Count
group by Manufacturer_Name
having count(manufacturer_name)=1

--Q10--BEGIN 
-- Find top 10 customers and their average spend, average quantity by each year. Also find the percentage of change in their spend.
with Avg_QTY_and_Spend_for_top_10_cust as
(
	select  distinct c.IDCustomer,c.Customer_Name, d.year,avg(t.Quantity) over(partition by c.idcustomer,d.year)  as Avg_quantity, 
									avg(t.TotalPrice) over(partition by c.idcustomer, d.year)  as Avg_spend	
	from FACT_TRANSACTIONS t join DIM_CUSTOMER c 
	on c.IDCustomer=t.IDCustomer join DIM_DATE d              -- 'Avg_quantity' and 'Avg_spend' is calculated  for the top 10 customers for each year using
	on d.DATE=t.Date                                          -- window functions.   
	where c.idcustomer in ( select top 10 idcustomer          
							from FACT_TRANSACTIONS            -- Based on the total sum they have spend the top 10 customers are selected.
							where TotalPrice>0 
							group by IDCustomer 
							order by sum(TotalPrice) desc )	
																)

select IDCustomer,Customer_Name,year,avg_spend, 
((avg_spend)-(prev_yr_avg))/(prev_yr_avg)*100 as [%age_Change_in_spend_wrt_prev_yr] 	

from(
		select * ,case 
						when year=year_min then null else lag(avg_spend,1) over(order by idcustomer) end as prev_yr_avg
		from(
				select *, min(year) over(partition by idcustomer) as year_min                   -- For calculation of Percentage change in spend for each year,
				from Avg_QTY_and_Spend_for_top_10_cust ) as [%age_Spend]) as Final_Output       -- prev_yr_avg_spend is needed and also the min year for the 
				                                                                                -- top 10 customers. This is calculated using CTE inside subquery.
				                   
--Q10--END