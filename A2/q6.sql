-- Frequent riders.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q6 CASCADE;

CREATE TABLE q6(
    client_id INTEGER,
    year CHAR(4),
    rides INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS requestclientnumber, totalnumber, emptyframe, firstmax, secondmax, thirdmax, firstlow, secondlow, thirdlow  CASCADE;


-- Define views for your intermediate steps here:
 --Count each client's number of rides in a single year
CREATE VIEW requestclientnumber AS (
    select client_id, EXTRACT(YEAR FROM Request.datetime) AS year, count(request_id) AS rides
    from Request
    GROUP BY client_id, EXTRACT(YEAR FROM Request.datetime));

 -- create view including every client with every year that have requests
 CREATE VIEW emptyframe AS(
    SELECT client_id, year
    FROM (SELECT distinct(year) from requestclientnumber) AS allyear, Client);
 
 --record every clients' number of rides in every years with requests
 CREATE VIEW totalnumber AS (
    select client_id, year, coalesce(rides,0) as rides
    from requestclientnumber NATURAL Right JOIN emptyframe);

 --find top 1
CREATE VIEW firstmax AS (
    select client_id, year, rides
    from totalnumber t
    where t.client_id not in (select t2.client_id from totalnumber t2 where t.year = t2.year and t2.rides < t.rides));
 
 -- find top 2
CREATE VIEW secondmax AS (
    select client_id, year, rides
    from ((select * from totalnumber) except (select * from firstmax)) t
    where t.client_id not in (select t2.client_id from totalnumber t2 where t.year = t2.year and t2.rides < t.rides));
 
 --find top 3
CREATE VIEW thirdmax AS (
    select client_id, year, rides
    from ((select * from totalnumber) except (select * from firstmax) except (select * from secondmax)) t
    where t.client_id not in (select t2.client_id from totalnumber t2 where t.year = t2.year and t2.rides < t.rides));
 
 --find lowest 1
CREATE VIEW firstlow AS (
    select client_id, year, rides
    from totalnumber t
    where t.client_id not in (select t2.client_id from totalnumber t2 where t.year = t2.year and t2.rides > t.rides));

 --find lowest 2
CREATE VIEW secondlow AS (
    select client_id, year, rides
    from ((select * from totalnumber) except (select * from firstlow)) t
    where t.client_id not in (select t2.client_id from totalnumber t2 where t.year = t2.year and t2.rides > t.rides));

 --find lowest 3
CREATE VIEW thirdlow AS (
    select client_id, year, rides
    from ((select * from totalnumber) except (select * from firstlow) except (select * from secondlow)) t
    where t.client_id not in (select t2.client_id from totalnumber t2 where t.year = t2.year and t2.rides > t.rides));

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q6
((select * from firstmax) union (select * from secondmax) union (select * from thirdmax) union (select * from firstlow) union (select * from secondlow) union (select * from thirdlow)); 