-- Could not: The constraint that each venue has at least 10 seats can not be
-- enforced without assertions or triggers.
-- Did not: There is no such constraints in our schema.
-- Extra constraints: There is no such constraints in our schema.
-- Assumptions: In the queries required, we assumed that each venue has at least 1 seat.

DROP SCHEMA IF EXISTS booking cascade;
CREATE SCHEMA booking;
set search_path to booking, public;

-- A owner's information, including the owner's name and phone number.
CREATE TABLE Owner(
    owner_name varchar(80) NOT NULL,
    owner_phone varchar(80) PRIMARY KEY
);


-- A venue's information, including its name, city, address, a unique venue_id
-- and the owner's phone number.
CREATE TABLE Venue(
    venue_id integer PRIMARY KEY,
    name varchar(80) NOT NULL,
    city varchar(80) NOT NULL,
    address varchar(80) NOT NULL,
    owner_phone varchar(80) NOT NULL REFERENCES Owner
);


-- A concert that has a unique concert_id, with the venue_id of the 
-- venue it is held in as well as its name and time. 
CREATE TABLE Concert(
    concert_id integer PRIMARY KEY,
    venue_id integer NOT NULL REFERENCES Venue,
    name varchar(80) NOT NULL,
    datetime timestamp NOT NULL,
    unique(venue_id, datetime)
);


-- The information of a section of a venue, including the venue_id of the
-- venue this section is in, as well as the section's name and a unique section_id.
CREATE TABLE Section(
    venue_id integer NOT NULL REFERENCES Venue,
    name varchar(80) NOT NULL,
    section_id integer PRIMARY KEY,
    unique(venue_id, name)
);


-- The information of a seat in a section of a venue.
-- Including the section_id of the section the seat is in,
-- an identifier of the seat (e.g. "14B") and whether the seat
-- is for people with mobility issues.
CREATE TABLE Seat(
    section_id integer NOT NULL REFERENCES Section,
    identifier varchar(80) NOT NULL,
    mobility boolean NOT NULL DEFAULT false,
    unique(section_id, identifier)
);

-- The information of a ticket for a specific seat of a concert.
-- Including section_id of the section the seat is in, the seat
-- identifier, and concert_id of the concert this ticket is for,
-- and a unique ticket_id for this ticket.
CREATE TABLE Ticket(
    section_id integer NOT NULL REFERENCES Section,
    seat_identifier varchar(80) NOT NULL,
    concert_id integer NOT NULL REFERENCES Concert,
    ticket_id integer PRIMARY KEY
);

-- The amount of money that the ticket costs if the ticket
-- is for concert of concert_id and the seat is in section 
-- of section_id.
CREATE TABLE Price(
    concert_id integer NOT NULL REFERENCES Concert,
    section_id integer NOT NULL REFERENCES Section,
    amount integer,
    PRIMARY KEY(concert_id, section_id)
);

-- The information of a user, including only the username.
CREATE TABLE Client(
    username varchar(80) PRIMARY KEY
);

-- The record of purchases when user of username buys 
-- the ticket of ticket_id, and the time of when the purchase 
-- is made.
CREATE TABLE Purchase(
    username varchar(80) NOT NULL REFERENCES Client,
    ticket_id integer NOT NULL REFERENCES Ticket,
    time timestamp NOT NULL,
    PRIMARY KEY(username, ticket_id)
);