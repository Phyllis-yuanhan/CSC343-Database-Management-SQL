SET SEARCH_PATH TO booking, public;


INSERT INTO Owner(owner_name, owner_phone) VALUES
	('Maple Leaf Sports & Entertainment', '4169393333'),
	('The Corporation of Massey Hall and Roy Thomson Hall', '4169995555');

INSERT INTO Venue(venue_id, name, city, address, owner_phone) VALUES
	(1, 'Massey Hall', 'Toronto', '178 Victoria Street', '4169995555'),
	(2, 'Roy Thomson Hall', 'Toronto', '60 Simcoe St', '4169995555'),
	(3, 'ScotiaBank Arena', 'Toronto', '40 Bay St', '4169393333');

INSERT INTO Concert(concert_id, venue_id, name, datetime) VALUES
	(11111, 1, 'Ron Sexsmith', '2022-12-03 19:30'),
	(22222, 1, 'Women''s Blues Review', '2022-11-25 20:00'),
	(33333, 3, 'Mariah Carey - Merry Christmas to all', '2022-12-09 20:00'),
	(44444, 3, 'Mariah Carey - Merry Christmas to all', '2022-12-11 20:00'),
	(55555, 2, 'TSO - Elf in Concert', '2022-12-09 19:30');

INSERT INTO Section(venue_id, name, section_id) VALUES
	(1, 'floor', 123),
	(1, 'balcony', 234),
	(2, 'main hall', 345),
	(3, '100', 456),
	(3, '200', 567),
	(3, '300', 678);

INSERT INTO Seat(section_id, identifier, mobility) VALUES
	(123, 'A1', true),
	(123, 'A2', true),
	(123, 'A3', true),
	(123, 'A4', false),
	(123, 'A5', false),
	(123, 'A6', false),
	(123, 'A7', false),
	(123, 'A8', true),
	(123, 'A9', true),
	(123, 'A10', true),
	(123, 'B1', false),
	(123, 'B2', false),
	(123, 'B3', false),
	(123, 'B4', false),
	(123, 'B5', false),
	(123, 'B6', false),
	(123, 'B7', false),
	(123, 'B8', false),
	(123, 'B9', false),
	(123, 'B10', false),
	(234, 'C1', false),
	(234, 'C2', false),
	(234, 'C3', false),
	(234, 'C4', false),
	(234, 'C5', false),
	(345, 'AA1', false),
	(345, 'AA2', false),
	(345, 'AA3', false),
	(345, 'BB1', false),
	(345, 'BB2', false),
	(345, 'BB3', false),
	(345, 'BB4', false),
	(345, 'BB5', false),
	(345, 'BB6', false),
	(345, 'BB7', false),
	(345, 'BB8', false),
	(345, 'CC1', false),
	(345, 'CC2', false),
	(345, 'CC3', false),
	(345, 'CC4', false),
	(345, 'CC5', false),
	(345, 'CC6', false),
	(345, 'CC7', false),
	(345, 'CC8', false),
	(345, 'CC9', false),
	(345, 'CC10', false),
	(456, 'row 1, seat 1', true), 
	(456, 'row 1, seat 2', true), 
	(456, 'row 1, seat 3', true), 
	(456, 'row 1, seat 4', true), 
	(456, 'row 1, seat 5', true), 
	(456, 'row 2, seat 1', true), 
	(456, 'row 2, seat 2', true), 
	(456, 'row 2, seat 3', true), 
	(456, 'row 2, seat 4', true), 
	(456, 'row 2, seat 5', true), 
	(567, 'row 1, seat 1', false), 
	(567, 'row 1, seat 2', false), 
	(567, 'row 1, seat 3', false), 
	(567, 'row 1, seat 4', false), 
	(567, 'row 1, seat 5', false), 
	(567, 'row 2, seat 1', false), 
	(567, 'row 2, seat 2', false), 
	(567, 'row 2, seat 3', false), 
	(567, 'row 2, seat 4', false), 
	(567, 'row 2, seat 5', false),
	(678, 'row 1, seat 1', false), 
	(678, 'row 1, seat 2', false), 
	(678, 'row 1, seat 3', false), 
	(678, 'row 1, seat 4', false), 
	(678, 'row 1, seat 5', false), 
	(678, 'row 2, seat 1', false), 
	(678, 'row 2, seat 2', false), 
	(678, 'row 2, seat 3', false), 
	(678, 'row 2, seat 4', false), 
	(678, 'row 2, seat 5', false);

INSERT INTO Ticket(section_id, seat_identifier, concert_id, ticket_id) VALUES
	(123, 'A5', 22222, 8888),
	(234, 'C2', 22222, 9999),
	(123, 'B3', 11111, 1111),
	(345, 'BB7', 55555, 2222),
	(456, 'row 1, seat 3', 33333, 3333),
	(567, 'row 2, seat 3', 44444, 4444),
	(567, 'row 2, seat 4', 44444, 5555);

INSERT INTO Price(concert_id, section_id, amount) VALUES
	(11111, 123, 130),
	(11111, 234, 90),
	(22222, 123, 150),
	(22222, 234, 125),
	(33333, 456, 986),
	(33333, 567, 244),
	(33333, 678, 176),
	(44444, 456, 936),
	(44444, 567, 194),
	(44444, 678, 126),
	(55555, 345, 159);

INSERT INTO Client(username) VALUES
	('ahightower'),
	('d_targaryen'),
	('cristonc');

INSERT INTO Purchase(username, ticket_id, time) VALUES
	('ahightower', 8888, '2022-11-29 7:30'),
	('ahightower', 9999, '2022-11-29 7:30'),
	('d_targaryen', 1111, '2022-11-28 7:30'),
	('d_targaryen', 2222, '2022-11-28 8:30'),
	('cristonc', 3333, '2022-11-28 8:30'),
	('cristonc', 4444, '2022-11-28 9:30'),
	('cristonc', 5555, '2022-11-28 9:30');
