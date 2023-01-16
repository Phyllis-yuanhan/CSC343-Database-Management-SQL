-- Months.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO booking, public;

SELECT owner_name, Owner.owner_phone, count(*) as venue_number
FROM Owner LEFT JOIN Venue
ON Owner.owner_phone=Venue.owner_phone
GROUP BY Owner.owner_phone, Owner.owner_name;