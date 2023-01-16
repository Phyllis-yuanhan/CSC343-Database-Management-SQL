-- Months.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO booking, public;
DROP TABLE IF EXISTS q1 CASCADE;

DROP VIEW IF EXISTS ticket_with_price, 
sold_tickets, total, venue_total_seat, total_ticket, percent CASCADE;


CREATE VIEW ticket_with_price AS SELECT Ticket.concert_id, ticket_id, amount from 
Ticket, Price 
WHERE Ticket.section_id=Price.section_id and Ticket.concert_id=Price.concert_id;

CREATE VIEW sold_tickets AS SELECT concert_id, amount, Purchase.ticket_id
from ticket_with_price, Purchase
WHERE ticket_with_price.ticket_id=Purchase.ticket_id;

CREATE VIEW total AS SELECT concert_id, sum(amount) as total_value
FROM sold_tickets GROUP BY concert_id;

CREATE VIEW venue_total_seat AS SELECT concert_id, count(*) as seat_count 
FROM Concert, Venue, Section, Seat
WHERE Concert.venue_id=Venue.venue_id and Section.venue_id=Venue.venue_id 
and Seat.section_id=Section.section_id
GROUP BY concert_id;

CREATE VIEW total_ticket AS SELECT concert_id, count(*) as sold_count
FROM sold_tickets
GROUP BY concert_id;

CREATE VIEW percent AS SELECT concert_id, (cast(sold_count as decimal(5,2))/cast(seat_count as decimal(5,2)))as percentage
FROM venue_total_seat NATURAL JOIN total_ticket;

SELECT * FROM percent NATURAL JOIN total;