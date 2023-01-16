-- Rainmakers.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q10 CASCADE;

CREATE TABLE q10(
    driver_id INTEGER,
    month CHAR(2),
    mileage_2020 FLOAT,
    billings_2020 FLOAT,
    mileage_2021 FLOAT,
    billings_2021 FLOAT,
    mileage_increase FLOAT,
    billings_increase FLOAT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS emptytable, distance_table, distance_table_2020, distance_table_2021, billing, billing_2020, billing_2021, table_with_distance, table_with_distance_billing  CASCADE;


-- Define views for your intermediate steps here:
 -- create a table with drivers and Every driver appears in 12 rows, one for each month.
 create view emptytable AS(
    select driver_id, to_char(generate_series(1, 12), 'FM09') AS month
    from Driver);
 
 --calculate crow-flies distance for every request
 create view distance_table AS(
    SELECT driver_id, to_char(r.datetime, 'YYYY') AS year, to_char(r.datetime, 'MM') AS month, source <@> destination as distance
    FROM Request r join Dispatch d on r.request_id = d.request_id
                   join ClockedIn c on d.shift_id= c.shift_id
    where to_char(r.datetime, 'YYYY') = '2020' or to_char(r.datetime, 'YYYY') = '2021');

 --calculate total monthly crow-flies distance for 2020
create view distance_table_2020 AS(
    SELECT driver_id, month, sum(distance) as dis_2020
    FROM distance_table
    where year = '2020'
    group by driver_id, month);

 --calculate total monthly crow-flies distance for 2021
create view distance_table_2021 AS(
    SELECT driver_id, month, sum(distance) as dis_2021
    FROM distance_table
    where year = '2021'
    group by driver_id, month);

 --calculate total billing for every request
 create view billing AS(
    SELECT driver_id, to_char(r.datetime, 'YYYY') AS year, to_char(r.datetime, 'MM') AS month, amount
    FROM Request r join Dispatch d on r.request_id = d.request_id
                   join ClockedIn c on d.shift_id= c.shift_id
                   join Billed b on r.request_id = b.request_id
    where to_char(r.datetime, 'YYYY') = '2020' or to_char(r.datetime, 'YYYY') = '2021');

 --calculate total monthly billing for 2020
create view billing_2020 AS(
    SELECT driver_id, month, sum(amount) as bill_2020
    FROM billing
    where year = '2020'
    group by driver_id, month);

 --calculate total monthly billing for 2021
create view billing_2021 AS(
    SELECT driver_id, month, sum(amount)as bill_2021
    FROM billing
    where year = '2021'
    group by driver_id, month);

 --combine table with distance
 CREATE VIEW table_with_distance AS (
    select driver_id, month, coalesce(dis_2020,0) as mileage_2020, coalesce(dis_2021,0) as mileage_2021
    from (select * from distance_table_2020 NATURAL Right JOIN emptytable) as d_2020 NATURAL LEFT JOIN distance_table_2021);
 --combine table with billing
 CREATE VIEW table_with_distance_billing AS (
    select driver_id, month, mileage_2020, coalesce(bill_2020,0) as billings_2020, mileage_2021, coalesce(bill_2021,0) as billings_2021
    from (select * from billing_2020 NATURAL Right JOIN table_with_distance) as d_2020 NATURAL LEFT JOIN billing_2021);

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q10
select driver_id, month, mileage_2020, billings_2020, mileage_2021, billings_2021, mileage_2021-mileage_2020 AS mileage_increase, billings_2021-billings_2020 AS billings_increase
from table_with_distance_billing;