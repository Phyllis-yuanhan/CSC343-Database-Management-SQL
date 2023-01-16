SET SEARCH_PATH TO booking, public;

DROP VIEW IF EXISTS intermediate_step CASCADE;

CREATE VIEW buy_number AS SELECT username, count(*) as number
FROM Purchase
GROUP BY username;

CREATE VIEW not_highest AS SELECT b1.username 
FROM buy_number b1, buy_number b2
WHERE b1.username != b2.username and b1.number < b2.number;


SELECT * FROM 
(SELECT * FROM ((SELECT username FROM Purchase) EXCEPT (SELECT username FROM not_highest)) as result) as result;