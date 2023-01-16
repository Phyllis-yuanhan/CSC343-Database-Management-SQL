-- Scratching backs?

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q8 CASCADE;

CREATE TABLE q8(
    client_id INTEGER,
    reciprocals INTEGER,
    difference FLOAT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS qualified, reciprocal_num, total_difference, result CASCADE;


-- Define views for your intermediate steps here:
 -- find clients who have at least one reciprocal rating, and record their ratings with the differences
 Create VIEW qualified AS(
    select Request.client_id, DriverRating.rating AS driver_rate, ClientRating.rating AS client_rate, DriverRating.rating - ClientRating.rating as diff
    from Request JOIN DriverRating on Request.request_id = DriverRating.request_id
                 JOIN ClientRating on Request.request_id = ClientRating.request_id);
 
 -- record the number of reciprocal ratings they have
 Create VIEW reciprocal_num AS(
    select client_id, count(driver_rate) as reciprocals
    from qualified
    Group By client_id);
 
 -- caculate the total difference between their rating of the driver and the driver's rating of them for a ride
 Create VIEW total_difference AS(
    select client_id, sum(diff) as difference_sum
    from qualified
    Group By client_id);
 
 -- combine table as request
 Create VIEW result AS(
    select reciprocal_num.client_id, reciprocals, round(difference_sum*1.0/reciprocals, 1) as difference
    from reciprocal_num NATURAL JOIN total_difference);
    
-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q8
select * from result;