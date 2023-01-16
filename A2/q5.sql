-- Bigger and smaller spenders.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q5 CASCADE;

CREATE TABLE q5(
    client_id INTEGER,
    month VARCHAR(7),
    total FLOAT,
    comparison VARCHAR(30)
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS New_Request,AvgMonth,emptyframe, TotalAmount,rideAmount, clientAmount, result CASCADE;


-- Define views for your intermediate steps here:

 -- Change datetime in Request into required month ('2021 07')
 CREATE VIEW New_Request AS(
    SELECT request_id, client_id, to_char(datetime, 'YYYY MM') AS month, amount
    FROM Request NATURAL JOIN Billed);

 -- Caculate avg of each month 
 CREATE VIEW AvgMonth AS(
    SELECT month, avg(amount) AS average
    FROM Billed NATURAL JOIN New_Request
    GROUP BY month);
 -- create view including every client with every month (someone has rides)
 CREATE VIEW emptyframe AS(
    SELECT client_id, month
    FROM (SELECT distinct(month) from New_Request) AS allmonth, Client);
 -- clients with rides's total amount for each month
 CREATE VIEW rideAmount AS(
    SELECT client_id, month, sum(amount) as amount
    FROM New_Request
    Group By client_id, month);

 -- record billed monthly amount for each client, the amount for client who doesn't have ride that month is 0
 CREATE VIEW clientAmount AS(
    SELECT client_id, month, coalesce(amount,0) as amount
    FROM rideAmount NATURAL Right JOIN emptyframe);

 -- calculate the total amount for every client each month
 CREATE VIEW TotalAmount AS(
    SELECT client_id, month, sum(amount) as total
    FROM clientAmount
    GROUP BY client_id, month);

-- Compare client's total amount with avg, create new column comparison
 CREATE VIEW result AS(
    SELECT client_id, month, total,
       CASE WHEN total >= average THEN 'at or above'
            WHEN total < average THEN 'below'
       END AS comparison
    FROM TotalAmount NATURAL JOIN AvgMonth);
-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q5 
SELECT * from result;
