DROP SCHEMA IF EXISTS uber cascade;
CREATE SCHEMA uber;
SET search_path TO uber, public;

-- The possible values for geographic coordinates.
-- It is specified in degrees as longitude then latitude
DROP DOMAIN IF EXISTS geo_loc;
CREATE DOMAIN geo_loc AS point 
  DEFAULT NULL
  CHECK ( 
    VALUE[0] BETWEEN -180.0 AND 180.0 
      AND
    VALUE[1] BETWEEN -90.0 AND 90.0 
  );

-- A person who is registered as a client of the company's driving
-- services.
CREATE TABLE Client (
  client_id integer PRIMARY KEY,
  surname varchar(25) NOT NULL,
  firstname varchar(15) NOT NULL,
  email varchar(30) DEFAULT NULL
);

-- A driver for the company. dob is their date of birth.
-- Trained indicates whether or not they attended the optional 
-- new-driver training. vehicle is the vehicle that this driver
-- gives rides in. A driver can have only one vehicle associated with them.
CREATE TABLE Driver (
  driver_id integer PRIMARY KEY,
  surname varchar(25) NOT NULL,
  firstname varchar(15) NOT NULL,
  dob date NOT NULL,
  address varchar NOT NULL,
  vehicle varchar(8) NOT NULL,
  trained boolean NOT NULL DEFAULT false
);

-- The driver with driver_id has started a shift at time datetime. This
-- indicates that they are ready to give rides.
CREATE TABLE ClockedIn(
  shift_id integer PRIMARY KEY,
  driver_id integer NOT NULL REFERENCES Driver,
  datetime timestamp NOT NULL
);

-- The driver working shift shift_id is at location location
-- at time datetime.
CREATE TABLE Location (
  shift_id integer NOT NULL REFERENCES ClockedIn,
  datetime timestamp NOT NULL, 
  location geo_loc NOT NULL,
  PRIMARY KEY (shift_id, datetime)
);

-- The shift shift_id ended at time datetime.
CREATE TABLE ClockedOut (
  shift_id integer NOT NULL PRIMARY KEY REFERENCES ClockedIn,
  datetime timestamp NOT NULL  
);

-- Requests for a ride, and associated events

-- A request for a ride.  source is where the client wants to be
-- picked up from, and destination is where they want to be driven to.
CREATE TABLE Request (
  request_id integer PRIMARY KEY,
  client_id integer NOT NULL REFERENCES Client,
  datetime timestamp NOT NULL,
  source geo_loc NOT NULL,
  destination geo_loc NOT NULL
);

-- A row in this table indicates that a driver was dispatched to
-- pick up a client, in response to their request.  car_location is 
-- the last known location of the car at the time when the driver 
-- was dispatched.
CREATE TABLE Dispatch (
  request_id integer PRIMARY KEY REFERENCES Request,
  shift_id integer NOT NULL REFERENCES ClockedIn,
  car_location geo_loc NOT NULL,  
  datetime timestamp NOT NULL
);

-- A row in this table indicates that the client who made this 
-- request was picked up at this time.
CREATE TABLE Pickup (
  request_id integer PRIMARY KEY NOT NULL REFERENCES Dispatch,
  datetime timestamp NOT NULL
);

-- A row in this table indicates that the client who made this 
-- request was dropped off at this time.
CREATE TABLE Dropoff (
  request_id integer PRIMARY KEY NOT NULL REFERENCES Pickup,
  datetime timestamp NOT NULL
);

-- To do with money

-- This table must have a single row indicating the current rates.
-- base is the cost for being picked up, and per_mile is the  
-- additional cost for every mile travelled.
CREATE TABLE Rates (
  base real NOT NULL,
  per_mile real NOT NULL
);

-- This client associated with this request was billed this
-- amount for the ride.
CREATE TABLE Billed (
  request_id integer PRIMARY KEY REFERENCES Dropoff,
  amount real NOT NULL
);

-- To do with Ratings

-- The possible values of a rating.
DROP DOMAIN IF EXISTS score;
CREATE DOMAIN score AS smallint 
  DEFAULT NULL
  CHECK (VALUE >= 1 AND VALUE <= 5);

-- The driver who gave the ride associated with this dropoff
-- was given this rating by the client who had the ride.
CREATE TABLE DriverRating (
  request_id integer PRIMARY KEY REFERENCES Dropoff,
  rating score NOT NULL
);

-- The client who had the ride associated with this dropoff
-- was given this rating by the driver who gave the ride.
CREATE TABLE ClientRating (
  request_id integer PRIMARY KEY REFERENCES Dropoff,
  rating score NOT NULL
);




----part 2 try
most_recent_recorded
select shift_id, datetime, location
from (select shift_id, datetime, location from LOCATION l
  where datetime >= ALL (select datetime from LOCATION ll where l.shift_id = ll.shift_id)) as a
where shift_id in (select available_a.shift_id from available_a NATURAL JOIN available_b);

select shift_id, car_location as location
from (select shift_id, datetime, car_location from DISPATCH d 
  where datetime >= ALL (select datetime from DISPATCH dd where d.shift_id = d.shift_id)) as a
where shift_id in (select available_a.shift_id from available_a NATURAL JOIN available_b);


select * 
from available_ab NATURAL LEFT JOIN 

where car_location.lag

select * from clockedin
where shift_id in (
  select shift_id
  from dispatch 
  where 
)

create temporary view alllst as 
select ClockedIn.shift_id, ClockedIn.driver_id, Dropoff.datetime, Request.destination, location.datetime as l_d, location.location as ll
from ClockedIn, Dispatch, Dropoff, Request, available_ab, location
where ClockedIn.driver_id =available_ab.driver_id and ClockedIn.shift_id = Dispatch.shift_id and
Dispatch.request_id = request.request_id and Dropoff.request_id = request.request_id and ClockedIn.shift_id = location.shift_id;


create temporary view alllst_2 as 
select shift_id, driver_id, datetime, destination, l_d, ll
from available_ab NATURAL LEFT JOIN (select ClockedIn.shift_id, ClockedIn.driver_id, Dropoff.datetime, Request.destination, location.datetime as l_d, location.location as ll
from ClockedIn, Dispatch, Dropoff, Request, location
where ClockedIn.shift_id = Dispatch.shift_id and
Dispatch.request_id = request.request_id and Dropoff.request_id = request.request_id and ClockedIn.shift_id = location.shift_id) as a;

select shift_id, driver_id, datetime, LOCATION



create temporary view recorded_loc2 as 
                        select ClockedIn.shift_id, ClockedIn.driver_id, location.datetime, location.location 
                        from ClockedIn, location
                        where ClockedIn.shift_id = location.shift_id;



create temporary view both_record as
select most_recent_recorded_loc.shift_id, most_recent_recorded_loc.driver_id, 
       case when most_recent_recorded_loc.datetime >= most_recent_recorded_dropoff.datetime then most_recent_recorded_loc.datetime
            else most_recent_recorded_dropoff.datetime 
            END as datetime,
       case when most_recent_recorded_loc.datetime >= most_recent_recorded_dropoff.datetime then most_recent_recorded_loc.location
            else most_recent_recorded_dropoff.destination 
            END as location 
from most_recent_recorded_loc, most_recent_recorded_dropoff
where most_recent_recorded_loc.driver_id = most_recent_recorded_dropoff.driver_id;

SELECT a.shift_id, a.driver_id, 
       case when a.datetime is NULL then most_recent_recorded_loc.datetime 
            else a.datetime 
            END as datetime,
       case when a.location is NULL then most_recent_recorded_loc.location
            else a.location
            END as location 
       
from (select * from available_ab NATURAL LEFT JOIN both_record) as a, most_recent_recorded_loc
where a.driver_id = most_recent_recorded_loc.driver_id;

create temporary view not_respond_request as 
                        select * from ((select request_id from Request)
                        except 
                        (select request_id from Dispatch)) as c;

create temporary view not_respond_request_with_source as 
                        select not_respond_request.request_id, source 
                        from not_respond_request join request on not_respond_request.request_id = request.request_id;

create temporary view available_a as 
                        select * from ((SELECT * FROM ClockedIn) EXCEPT ALL 
                        (SELECT ClockedIn.shift_id, ClockedIn.driver_id, ClockedIn.datetime 
                        FROM ClockedIn, ClockedOut 
                        where ClockedIn.shift_id = ClockedOut.shift_id)) as a;

create temporary view available_b as 
                        select * from ClockedIn 
                        where shift_id not in 
                        (select shift_id from Dispatch, dropoff where Dispatch.request_id <> dropoff.request_id);

create temporary view available_ab as 
                        select * from ((select driver_id from available_a) Intersect 
                        (select driver_id from available_a)) as ab;

create temporary view recorded_dropoff as 
                        select ClockedIn.shift_id, ClockedIn.driver_id, Dropoff.datetime, Request.destination 
                        from ClockedIn, Dispatch, Dropoff, Request, available_ab 
                        where ClockedIn.driver_id =available_ab.driver_id and 
                        ClockedIn.shift_id = Dispatch.shift_id and Dispatch.request_id = request.request_id and 
                        Dropoff.request_id = request.request_id;

create temporary view most_recent_recorded_dropoff as 
                        select * from recorded_dropoff d 
                        where datetime >= ALL 
                        (select datetime from recorded_dropoff dd where d.driver_id = dd.driver_id);

create temporary view recorded_loc as 
                        select ClockedIn.shift_id, ClockedIn.driver_id, location.datetime, location.location 
                        from ClockedIn, location
                        where ClockedIn.shift_id = location.shift_id;

create temporary view most_recent_recorded_loc as 
                        select * from available_ab NATURAL LEFT JOIN (select * from recorded_loc l 
                        where datetime >= ALL 
                        (select datetime from recorded_loc ll where l.driver_id = ll.driver_id)) as a;

create temporary view both_record as
                        select most_recent_recorded_loc.shift_id, most_recent_recorded_loc.driver_id,
                        case when most_recent_recorded_loc.datetime >= most_recent_recorded_dropoff.datetime 
                        then most_recent_recorded_loc.datetime else most_recent_recorded_dropoff.datetime 
                        END as datetime, 
                        case when most_recent_recorded_loc.datetime >= most_recent_recorded_dropoff.datetime 
                        then most_recent_recorded_loc.location else most_recent_recorded_dropoff.destination 
                        END as location 
                        from most_recent_recorded_loc, most_recent_recorded_dropoff 
                        where most_recent_recorded_loc.driver_id = most_recent_recorded_dropoff.driver_id;

create temporary view most_recent_location as 
                        SELECT a.shift_id, a.driver_id, 
                        case when a.datetime is NULL then most_recent_recorded_loc.datetime else a.datetime
                        END as datetime,
                        case when a.location is NULL then most_recent_recorded_loc.location else a.location 
                        END as location 
                        from (select * from available_ab NATURAL LEFT JOIN both_record) as a, 
                        most_recent_recorded_loc 
                        where a.driver_id = most_recent_recorded_loc.driver_id;

create temporary view distance as 
                        select request_id, shift_id, driver_id, datetime, most_recent_location.location,
                        not_respond_request_with_source.source <@> most_recent_location.location as distance 
                        from not_respond_request_with_source, most_recent_location;
