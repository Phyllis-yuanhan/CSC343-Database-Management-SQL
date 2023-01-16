-- Consistent raters.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q9 CASCADE;

CREATE TABLE q9(
    client_id INTEGER,
    email VARCHAR(30)
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS client_driver_id, client_driver, client_driver_with_rate, rating_status, qualified CASCADE;


-- Define views for your intermediate steps here:
 -- find all clients and drives pairs, with their request id.
 create view client_driver_id as (
    select r.request_id , r.client_id, c.driver_id
    from Request r join Dispatch d on r.request_id = d.request_id
                   join ClockedIn c on d.shift_id= c.shift_id);

 -- find every (clients and drives) pairs, without their request id.
 create view client_driver as (
    select client_id, driver_id
    from client_driver_id
    Group BY client_id, driver_id);

 -- find corresponding ratings, if no rating then record as 1.
 create view client_driver_with_rate as (
    select request_id, client_id, driver_id, coalesce(rating,0) as rating
    from client_driver_id NATURAL LEFT JOIN DriverRating);

 -- check if a client who has rated the driver they have ever had a ride with.
 create view rating_status as(
    select client_id,
           case when max(rating) >0 then 'yes'
           else 'no'
           end as status
    from client_driver_with_rate
    Group BY client_id, driver_id);

-- select client that rates every driver they have ever had a ride with. 
 create view qualified as(
    select distinct(client_id)
    from rating_status
    where client_id not in (select client_id from rating_status where status = 'no'));

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q9
select Client.client_id, Client.email from Client NATURAL join qualified;