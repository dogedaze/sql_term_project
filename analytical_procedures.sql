-- Which departments have the highest incident volume?--
select a.agency_id,a.agency_name,count(s.unique_key)
from Service_Request as s, agency as a
where a.agency_id =s.agency_id
group by a.agency_id,a.agency_name
order by  count(s.unique_key) desc;

--RATE OF CALL COMPLETIONS --
alter table Service_request
add column duration integer;

update service_request
set duration= closed_date-created_date;

Create or replace function starttofinish(duration integer)
	Returns varchar(255) AS
	$func$
		Declare starttofinish varchar(255);
		BEGIN
			IF $1 between 0 and 4 THEN starttofinish = '1- Under 5 days';
			ELSEIF $1 between 5 and 15 THEN starttofinish = '2- 5-15 days';
			ELSEIF $1 between 16 and 29 THEN starttofinish = '3- 16-29 days';
			ELSEIF $1 between 30 and 60 THEN starttofinish = '4- 30-60 days';
			ELSEIF $1 between 61 and 90 THEN starttofinish = '5- 61-90 days';
			ELSEIF $1 between 91 and 120 THEN starttofinish = '6- 91-120 days';
			ELSEIF $1 between 121 and 180 THEN starttofinish = '7- 121-180 days';
			ELSEIF $1 > 180 THEN starttofinish = '8- Over 180 days';
			ELSEIF $1 is null THEN starttofinish = '9- Still open';
		END IF;
		RETURN starttofinish;
	END;
	$func$
LANGUAGE plpgsql; -- in PL/pgSQL (procedrual language)

--
--How many are closed under a week?--
select count (starttofinish(duration))
from Service_Request
where starttofinish(duration) = '1- Under 5 days';

-- Start to finish chart sorted by open data channel--
select (starttofinish(duration)),open_data_channel_type,count(unique_key)
from Service_Request
group by (starttofinish(duration)),open_data_channel_type
order by  open_data_channel_type,(starttofinish(duration));

-- Start to finish chart sorted by open data channel--
select (starttofinish(duration)),open_data_channel_type,count(unique_key)
from Service_Request
group by (starttofinish(duration)),open_data_channel_type
order by  open_data_channel_type,(starttofinish(duration));

-- Is there a difference between departments --
select a.agency_id,a.agency_name,(starttofinish(duration)),count(s.unique_key)
from Service_Request as s, agency as a
where a.agency_id =s.agency_id
group by (starttofinish(duration)),a.agency_id,s.agency_id,a.agency_name
order by s.agency_id, (starttofinish(duration));

-- Which department has most tickets closed under 5 days? -- 
select a.agency_id,a.agency_name,(starttofinish(duration)),count(s.unique_key)
from Service_Request as s, agency as a
where a.agency_id =s.agency_id and starttofinish(duration) = '1- Under 5 days'
group by (starttofinish(duration)),a.agency_id,s.agency_id,a.agency_name
order by count(s.unique_key) desc, s.agency_id, (starttofinish(duration));

--What are top complaint types --
select c.complaint_type,count(s.unique_key)
from Service_Request as s, complaint as c
where c.complaint_id =s.complaint_id
group by c.complaint_id,c.complaint_type
order by  count(s.unique_key) desc;

--Zone and call volume: Do we need more people in certain areas? --
select c.borough,count(s.unique_key)
from Service_Request as s, complaint_address as c
where c.complaint_id =s.complaint_id
group by c.complaint_id,c.borough
order by  count(s.unique_key) desc;

--Certain time of year: Do we hire seasonal workers?--
alter table Service_request
add column s_month integer;

update service_request
set s_month= extract(month from created_date);


Create or replace function months(s_month integer)
	Returns varchar(255) AS
	$func$
		Declare months varchar(255);
		BEGIN
			IF $1 =1 THEN months = 'January';
			ELSEIF $1 =2 THEN months = 'February';
			ELSEIF $1 =3 THEN months = 'March';
			ELSEIF $1 =4 THEN months = 'April';
			ELSEIF $1 =5 THEN months = 'May';
			ELSEIF $1 =6 THEN months = 'June';
			ELSEIF $1 =7 THEN months = 'July';
			ELSEIF $1 =8 THEN months = 'August';
			ELSEIF $1 =9 THEN months = 'September';
			ELSEIF $1 =10 THEN months = 'October';
			ELSEIF $1 =11 THEN months = 'November';
			ELSEIF $1 =12 THEN months = 'December';
		END IF;
		RETURN months;
	END;
	$func$
LANGUAGE plpgsql; -- in PL/pgSQL (procedrual language)

select (months(s_month)),count(unique_key)
from Service_Request
group by (months(s_month))
order by  count(unique_key) desc;

--Open calls that took longer than 30 days to resolve? 60 days? This is for managers to troublshoot --
-- follow up with why they are still open--
select c.status,c.complaint_type,(starttofinish(duration)),count(s.unique_key)
from Service_Request as s, complaint as c
where c.complaint_id =s.complaint_id and starttofinish(duration) = '4- 30-60 days' and status='Open'
group by (starttofinish(duration)),c.status,s.complaint_id,c.complaint_type
order by count(s.unique_key) desc, s.complaint_id, (starttofinish(duration));

select c.status,c.complaint_type,(starttofinish(duration)),count(s.unique_key)
from Service_Request as s, complaint as c
where c.complaint_id =s.complaint_id and starttofinish(duration) = '5- 61-90 days' and status='Open'
group by (starttofinish(duration)),c.status,s.complaint_id,c.complaint_type
order by count(s.unique_key) desc, s.complaint_id, (starttofinish(duration));

-- How many calls are left unreolved during the year--
select c.status,count(s.unique_key)
from Service_Request as s, complaint as c
where c.complaint_id =s.complaint_id and status='Open' and extract(year from created_date)='2021'
group by c.status
order by count(s.unique_key) desc;

-- What is the most used open data channel type? this will be used to allocate resources --
-- By year--
select open_data_channel_type,count(unique_key)
from Service_Request
where extract(year from created_date)='2021'
group by open_data_channel_type
order by count(unique_key) desc;
-- By month--
select (months(s_month)),open_data_channel_type,count(unique_key)
from Service_Request
where (months(s_month))='October'
group by (months(s_month)),open_data_channel_type
order by  count(unique_key) desc;
