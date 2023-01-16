"""
Part2 of csc343 A2: Code that could be part of a ride-sharing application.
csc343, Fall 2022
University of Toronto

--------------------------------------------------------------------------------
This file is Copyright (c) 2022 Diane Horton and Marina Tawfik.
All forms of distribution, whether as given or with any changes, are
expressly prohibited.
--------------------------------------------------------------------------------
"""
import psycopg2 as pg
import psycopg2.extensions as pg_ext
from typing import Optional, List, Any
from datetime import datetime
import re


class GeoLoc:
    """A geographic location.

    === Instance Attributes ===
    longitude: the angular distance of this GeoLoc, east or west of the prime
        meridian.
    latitude: the angular distance of this GeoLoc, north or south of the
        Earth's equator.

    === Representation Invariants ===
    - longitude is in the closed interval [-180.0, 180.0]
    - latitude is in the closed interval [-90.0, 90.0]

    >>> where = GeoLoc(-25.0, 50.0)
    >>> where.longitude
    -25.0
    >>> where.latitude
    50.0
    """
    longitude: float
    latitude: float

    def __init__(self, longitude: float, latitude: float) -> None:
        """Initialize this geographic location with longitude <longitude> and
        latitude <latitude>.
        """
        self.longitude = longitude
        self.latitude = latitude

        assert -180.0 <= longitude <= 180.0, \
            f"Invalid value for longitude: {longitude}"
        assert -90.0 <= latitude <= 90.0, \
            f"Invalid value for latitude: {latitude}"


class Assignment2:
    """A class that can work with data conforming to the schema in schema.ddl.

    === Instance Attributes ===
    connection: connection to a PostgreSQL database of ride-sharing information.

    Representation invariants:
    - The database to which connection is established conforms to the schema
      in schema.ddl.
    """
    connection: Optional[pg_ext.connection]

    def __init__(self) -> None:
        """Initialize this Assignment2 instance, with no database connection
        yet.
        """
        self.connection = None

    def connect(self, dbname: str, username: str, password: str) -> bool:
        """Establish a connection to the database <dbname> using the
        username <username> and password <password>, and assign it to the
        instance attribute <connection>. In addition, set the search path to
        uber, public.

        Return True if the connection was made successfully, False otherwise.
        I.e., do NOT throw an error if making the connection fails.

        >>> a2 = Assignment2()
        >>> # This example will work for you if you change the arguments as
        >>> # appropriate for your account.
        >>> a2.connect("csc343h-pengyua9", "pengyua9", "")
        True
        >>> # In this example, the connection cannot be made.
        >>> a2.connect("nonsense", "silly", "junk")
        False
        """
        try:
            self.connection = pg.connect(
                dbname=dbname, user=username, password=password,
                options="-c search_path=uber,public"
            )
            # This allows psycopg2 to learn about our custom type geo_loc.
            self._register_geo_loc()
            return True
        except pg.Error:
            return False

    def disconnect(self) -> bool:
        """Close the database connection.

        Return True if closing the connection was successful, False otherwise.
        I.e., do NOT throw an error if closing the connection failed.

        >>> a2 = Assignment2()
        >>> # This example will work for you if you change the arguments as
        >>> # appropriate for your account.
        >>> a2.connect("csc343h-pengyua9", "pengyua9", "")
        True
        >>> a2.disconnect()
        True
        >>> a2.disconnect()
        False
        """
        try:
            if not self.connection.closed:
                self.connection.close()
            return True
        except pg.Error:
            return False

    # ======================= Driver-related methods ======================= #

    def clock_in(self, driver_id: int, when: datetime, geo_loc: GeoLoc) -> bool:
        """Record the fact that the driver with id <driver_id> has declared that
        they are available to start their shift at date time <when> and with
        starting location <geo_loc>. Do so by inserting a row in both the
        ClockedIn and the Location tables.

        If there are no rows are in the ClockedIn table, the id of the shift
        is 1. Otherwise, it is the maximum current shift id + 1.

        A driver can NOT start a new shift if they have an ongoing shift.

        Return True if clocking in was successful, False otherwise. I.e., do NOT
        throw an error if clocking in fails.

        Precondition:
            - <when> is after all dates currently recorded in the database.
        """
        try:
            cur = self.connection.cursor()
            cur.execute("SELECT * FROM Driver;")
            drivers = cur.fetchall()
            if driver_id not in [driver[0] for driver in drivers]:
                return False

            cur.execute("(SELECT * FROM ClockedIn) EXCEPT ALL (SELECT ClockedIn.shift_id, ClockedIn.driver_id, "
                        "ClockedIn.datetime "
                        "FROM ClockedIn, ClockedOut "
                        "where ClockedIn.shift_id = ClockedOut.shift_id);")
            unfinished = cur.fetchall()
            for t in unfinished:
                if t[1] == driver_id:
                    return False
            cur.execute("SELECT * FROM ClockedIn;")
            all_shift = cur.fetchall()
            if len(all_shift) == 0:
                shift_id = 1
            else:
                shift_id = max([t[0] for t in all_shift]) + 1
            insert_clockedin = (shift_id, driver_id, when)
            insert_location = (shift_id, when, geo_loc)
            cur.execute(f"INSERT INTO ClockedIn VALUES(%s, %s, %s);", insert_clockedin)
            cur.execute(f"INSERT INTO Location VALUES(%s, %s, %s);", insert_location)
            self.connection.commit()
            return True

        except pg.Error as ex:
            # You may find it helpful to uncomment this line while debugging,
            # as it will show you all the details of the error that occurred:
            # raise ex
            return False

    def pick_up(self, driver_id: int, client_id: int, when: datetime) -> bool:
        """Record the fact that the driver with driver id <driver_id> has
        picked up the client with client id <client_id> at date time <when>.

        If (a) the driver is currently on an ongoing shift, and
           (b) they have been dispatched to pick up the client, and
           (c) the corresponding pick-up has not been recorded
        record it by adding a row to the Pickup table, and return True.
        Otherwise, return False.

        You may not assume that the dispatch actually occurred, but you may
        assume there is no more than one outstanding dispatch entry for this
        driver and this client.

        Return True if the operation was successful, False otherwise. I.e.,
        do NOT throw an error if this pick up fails.

        Precondition:
            - <when> is after all dates currently recorded in the database.
        """
        try:
            cur = self.connection.cursor()
            cur.execute("(SELECT * FROM ClockedIn) EXCEPT ALL (SELECT ClockedIn.shift_id, ClockedIn.driver_id, "
                        "ClockedIn.datetime "
                        "FROM ClockedIn, ClockedOut "
                        "where ClockedIn.shift_id = ClockedOut.shift_id);")
            unfinished = cur.fetchall()
            shift_id = False
            for t in unfinished:
                if t[1] == driver_id:
                    shift_id = t[0]
            if not shift_id:
                return False
            cur.execute(f"SELECT * FROM Dispatch, Request "
                        f"where Dispatch.request_id = Request.request_id "
                        f"and Request.client_id=%s"
                        f" and Dispatch.shift_id=%s;", (str(client_id), str(shift_id)))
            request_id = cur.fetchall()
            if not request_id:
                return False
            request_id = request_id[0][0]
            cur.execute(f"SELECT * FROM Pickup WHERE request_id=%s;", str(request_id))
            result = cur.fetchall()
            if len(result) != 0:
                return False
            cur.execute(f"INSERT INTO Pickup VALUES(%s, %s);", (str(request_id), when))
            self.connection.commit()
            return True

        except pg.Error as ex:
            # You may find it helpful to uncomment this line while debugging,
            # as it will show you all the details of the error that occurred:
            # raise ex
            return False

    # ===================== Dispatcher-related methods ===================== #

    def dispatch(self, nw: GeoLoc, se: GeoLoc, when: datetime) -> None:
        """Dispatch drivers to the clients who have requested rides in the area
        bounded by <nw> and <se>, such that:
            - <nw> is the longitude and latitude in the northwest corner of this
            area
            - <se> is the longitude and latitude in the southeast corner of this
            area
        and record the dispatch time as <when>.

        Area boundaries are inclusive. For example, the point (4.0, 10.0)
        is considered within the area defined by
                    NW = (1.0, 10.0) and SE = (25.0, 2.0)
        even though it is right at the upper boundary of the area.

        NOTE: + longitude values decrease as we move further west, and
                latitude values decrease as we move further south.
              + You may find the PostgreSQL operators @> and <@> helpful.

        For all clients who have requested rides in this area (i.e., whose
        request has a source location in this area) and a driver has not
        been dispatched to them yet, dispatch drivers to them one at a time,
        from the client with the highest total billings down to the client
        with the lowest total billings, or until there are no more drivers
        available.

        Only drivers who meet all of these conditions are dispatched:
            (a) They are currently on an ongoing shift.
            (b) They are available and are NOT currently dispatched or on
            an ongoing ride.
            (c) Their most recent recorded location is in the area bounded by
            <nw> and <se>.
        When choosing a driver for a particular client, if there are several
        drivers to choose from, choose the one closest to the client's source
        location. In the case of a tie, any one of the tied drivers may be
        dispatched.

        Dispatching a driver is accomplished by adding a row to the Dispatch
        table. The dispatch car location is the driver's most recent recorded
        location. All dispatching that results from a call to this method is
        recorded to have happened at the same time, which is passed through
        parameter <when>.

        If an exception occurs during dispatch, rollback ALL changes.

        Precondition:
            - <when> is after all dates currently recorded in the database.
        """
        try:
            cur = self.connection.cursor()
            longitude_lower = min(nw.longitude, se.longitude)
            longitude_upper = max(nw.longitude, se.longitude)
            latitude_lower = min(nw.latitude, se.latitude)
            latitude_upper = max(nw.latitude, se.latitude)
            
            # ordered by clients' billing amount
            cur.execute('create temporary view not_respond_request as '
                        'select * from ((select request_id from Request) '
                        'except '
                        '(select request_id from Dispatch)) as c;')

            cur.execute(f"create temporary view not_respond_request_with_source as "
                        "select not_respond_request.request_id, source "
                        "from not_respond_request join request on not_respond_request.request_id = request.request_id "
                        "where source[0] <= %s and source[0] >= %s and source[1] <= %s and source[1] >= %s;", 
                        (longitude_upper, longitude_lower, latitude_upper, latitude_lower))
            cur.execute("SELECT * FROM not_respond_request_with_source;")
            if len(cur.fetchall()) != 0:

                cur.execute("create temporary view available_a as "
                            "select * from ((SELECT * FROM ClockedIn) EXCEPT ALL "
                            "(SELECT ClockedIn.shift_id, ClockedIn.driver_id, ClockedIn.datetime "
                            "FROM ClockedIn, ClockedOut "
                            "where ClockedIn.shift_id = ClockedOut.shift_id)) as a;")

                cur.execute('create temporary view available_b as '
                            'select * from ClockedIn '
                            'where shift_id not in '
                            '(select shift_id from Dispatch, dropoff where Dispatch.request_id <> dropoff.request_id); ')
                # find drivers that meet first two conditions
                cur.execute('create temporary view available_ab as '
                            'select * from ((select driver_id from available_a) Intersect '
                            '(select driver_id from available_a)) as ab;')

                # find most recent recorded location for drivers that have a dropoff record
                cur.execute("create temporary view recorded_dropoff as "
                            "select ClockedIn.shift_id, ClockedIn.driver_id, Dropoff.datetime, Request.destination "
                            "from ClockedIn, Dispatch, Dropoff, Request, available_ab "
                            "where ClockedIn.driver_id =available_ab.driver_id and "
                            "ClockedIn.shift_id = Dispatch.shift_id and Dispatch.request_id = request.request_id and "
                            "Dropoff.request_id = request.request_id;")

                cur.execute("create temporary view most_recent_recorded_dropoff as "
                            "select * from recorded_dropoff d "
                            "where datetime >= ALL "
                            "(select datetime from recorded_dropoff dd where d.driver_id = dd.driver_id);")
                # find most recent recorded location for drivers that have a location record
                cur.execute("create temporary view recorded_loc as "
                            "select ClockedIn.shift_id, ClockedIn.driver_id, location.datetime, location.location "
                            "from ClockedIn, location "
                            "where ClockedIn.shift_id = location.shift_id;")
                cur.execute("create temporary view most_recent_recorded_loc as "
                            "select * from available_ab NATURAL LEFT JOIN (select * from recorded_loc l "
                            "where datetime >= ALL "
                            "(select datetime from recorded_loc ll where l.driver_id = ll.driver_id)) as a;")
                # find most_recent_location for every qualified driver (meet first two condition)
                cur.execute('create temporary view both_record as '
                            'select most_recent_recorded_loc.shift_id, most_recent_recorded_loc.driver_id,'
                            'case when most_recent_recorded_loc.datetime >= most_recent_recorded_dropoff.datetime '
                            'then most_recent_recorded_loc.datetime else most_recent_recorded_dropoff.datetime '
                            'END as datetime, '
                            'case when most_recent_recorded_loc.datetime >= most_recent_recorded_dropoff.datetime '
                            'then most_recent_recorded_loc.location else most_recent_recorded_dropoff.destination '
                            'END as location '
                            'from most_recent_recorded_loc, most_recent_recorded_dropoff '
                            'where most_recent_recorded_loc.driver_id = most_recent_recorded_dropoff.driver_id;')

                cur.execute('create temporary view most_recent_location as '
                            'SELECT a.shift_id, a.driver_id, '
                            'case when a.datetime is NULL then most_recent_recorded_loc.datetime else a.datetime '
                            'END as datetime, '
                            'case when a.location is NULL then most_recent_recorded_loc.location else a.location '
                            'END as location '
                            'from (select * from available_ab NATURAL LEFT JOIN both_record) as a, '
                            'most_recent_recorded_loc '
                            'where a.driver_id = most_recent_recorded_loc.driver_id;')

                # find drivers meet the third condition
                cur.execute(f"create temporary view qualified_driver as "
                            f"select shift_id, driver_id, datetime, location "
                            f"from most_recent_location "
                            f"where location[0] <= %s and location[0] >= %s and location[1] <= %s and location[1] >= %s;",
                            (longitude_upper, longitude_lower, latitude_upper, latitude_lower))
                cur.execute('SELECT * FROM qualified_driver;')
                obsrv = cur.fetchall()
                if len(obsrv) != 0:

                    # calculate distance for each driver, client pair
                    cur.execute('create temporary view distance as '
                                'select request_id, shift_id, driver_id, datetime, location, '
                                'not_respond_request_with_source.source <@> qualified_driver.location as distance '
                                'from not_respond_request_with_source, qualified_driver;')

                    cur.execute('SELECT * FROM distance;')
                    observations = cur.fetchall()
                    requests = [obs[0] for obs in observations]
                    full_info = []
                    for r in requests:
                        cur.execute(f'select client_id from Request where request_id=%s;', (str(r),))
                        client_id = cur.fetchone()[0]
                        cur.execute(f'select SUM(amount) from Request, Billed '
                                    f'where Request.request_id=Billed.request_id '
                                    f'and Request.client_id=%s;', (str(client_id), ))
                        corresponding_amount = cur.fetchone()[0]
                        full_info.append((r, client_id, corresponding_amount))
                    full_info.sort(key=lambda x: x[2])
                    dispatched = set()
                    for info in full_info:
                        curr_shift = 0
                        curr_loc = ''
                        curr_time = ''
                        min_d = float('inf')
                        for obs in observations:
                            if obs[0] == info[0] and obs[5] < min_d and not obs[1] in dispatched and obs[1]:
                                min_d = obs[5]
                                curr_shift = obs[1]
                                curr_loc = obs[4]
                        if curr_shift != 0:
                            cur.execute('INSERT INTO Dispatch VALUES (%s, %s, %s, %s);',
                                        (info[0], curr_shift, curr_loc, when))
                            dispatched.add(curr_shift)
            cur.execute('select * from dispatch;')
            print(cur.fetchall())

            self.connection.commit()
        except pg.Error as ex:
            # You may find it helpful to uncomment this line while debugging,
            # as it will show you all the details of the error that occurred:
            # raise ex
            self.connection.rollback()

    # =======================     Helper methods     ======================= #

    # You do not need to understand this code. See the doctest example in
    # class GeoLoc (look for ">>>") for how to use class GeoLoc.

    def _register_geo_loc(self) -> None:
        """Register the GeoLoc type and create the GeoLoc type adapter.

        This method
            (1) informs psycopg2 that the Python class GeoLoc corresponds
                to geo_loc in PostgreSQL.
            (2) defines the logic for quoting GeoLoc objects so that you
                can use GeoLoc objects in calls to execute.
            (3) defines the logic of reading GeoLoc objects from PostgreSQL.

        DO NOT make any modifications to this method.
        """

        def adapt_geo_loc(loc: GeoLoc) -> pg_ext.AsIs:
            """Convert the given geographical location <loc> to a quoted
            SQL string.
            """
            longitude = pg_ext.adapt(loc.longitude)
            latitude = pg_ext.adapt(loc.latitude)
            return pg_ext.AsIs(f"'({longitude}, {latitude})'::geo_loc")

        def cast_geo_loc(value: Optional[str], *args: List[Any]) \
                -> Optional[GeoLoc]:
            """Convert the given value <value> to a GeoLoc object.

            Throw an InterfaceError if the given value can't be converted to
            a GeoLoc object.
            """
            if value is None:
                return None
            m = re.match(r"\(([^)]+),([^)]+)\)", value)

            if m:
                return GeoLoc(float(m.group(1)), float(m.group(2)))
            else:
                raise pg.InterfaceError(f"bad geo_loc representation: {value}")

        with self.connection, self.connection.cursor() as cursor:
            cursor.execute("SELECT NULL::geo_loc")
            geo_loc_oid = cursor.description[0][1]

            geo_loc_type = pg_ext.new_type(
                (geo_loc_oid,), "GeoLoc", cast_geo_loc
            )
            pg_ext.register_type(geo_loc_type)
            pg_ext.register_adapter(GeoLoc, adapt_geo_loc)


def sample_test_function() -> None:
    """A sample test function."""
    a2 = Assignment2()
    try:
        # TODO: Change this to connect to your own database:
        connected = a2.connect("csc343h-pengyua9", "pengyua9", "")
        print(f"[Connected] Expected True | Got {connected}.")

        # TODO: Test one or more methods here, or better yet, make more testing
        #   functions, with each testing a different aspect of the code.

        # ------------------- Testing Clocked In -----------------------------#

        # These tests assume that you have already loaded the sample data we
        # provided into your database.

        # This driver doesn't exist in db
        clocked_in = a2.clock_in(
            989898, datetime.now(), GeoLoc(-79.233, 43.712)
        )
        print(f"[ClockIn] Expected False | Got {clocked_in}.")

        # This drive does exist in the db
        clocked_in = a2.clock_in(
            22222, datetime.now(), GeoLoc(-79.233, 43.712)
        )
        print(f"[ClockIn] Expected True | Got {clocked_in}.")
        a2.dispatch(GeoLoc(-180, 90), GeoLoc(-180, 90), datetime.now())
        # Same driver clocks in again
        clocked_in = a2.clock_in(
            22222, datetime.now(), GeoLoc(-79.233, 43.712)
        )
        
        print(f"[ClockIn] Expected False | Got {clocked_in}.")

    finally:
        a2.disconnect()


if __name__ == "__main__":
    # Un comment-out the next two lines if you would like all the doctest
    # examples (see ">>>" in the method and class docstrings) to be run
    # and checked.
    # import doctest
    # doctest.testmod()

    # TODO: Put your testing code here, or call testing functions such as
    #   this one:
    sample_test_function()
