SET SEARCH_PATH TO booking, public;

DROP VIEW IF EXISTS total_seat, total_accessible, percent CASCADE;

CREATE VIEW total_seat AS SELECT Venue.venue_id, count(Seat.identifier) as total
FROM Venue, Section, Seat
where Section.venue_id=Venue.venue_id and Seat.section_id=Section.section_id
GROUP BY Venue.venue_id;

CREATE VIEW total_accessible AS SELECT Venue.venue_id,count(Seat.identifier) as acce
FROM Venue, Section, Seat
where Section.venue_id=Venue.venue_id and Seat.section_id=Section.section_id 
and Seat.mobility=true
Group By Venue.venue_id;

CREATE VIEW percent AS SELECT total_seat.venue_id,
COALESCE(cast(acce as decimal(7,2))/cast(total as decimal(7,2)), 0) as percentage
FROM total_seat LEFT JOIN total_accessible
ON total_seat.venue_id = total_accessible.venue_id;

SELECT * FROM percent;