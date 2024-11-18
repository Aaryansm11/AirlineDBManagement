-- Step 1: Create the database
CREATE DATABASE AirlineDB;

-- Step 2: Use the database
USE AirlineDB;

-- Step 3: Create tables

-- Flights table
CREATE TABLE Flights (
    flight_id INT PRIMARY KEY AUTO_INCREMENT,
    flight_number VARCHAR(10) NOT NULL,
    departure_time DATETIME NOT NULL,
    arrival_time DATETIME NOT NULL,
    source VARCHAR(50),
    destination VARCHAR(50),
    class ENUM('Economy', 'Business', 'First') NOT NULL
);

-- Passengers table
CREATE TABLE Passengers (
    passenger_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    seat_preference ENUM('Window', 'Aisle', 'Middle'),
    class ENUM('Economy', 'Business', 'First')
);

-- Seat Allocation table
CREATE TABLE Seat_Allocation (
    allocation_id INT PRIMARY KEY AUTO_INCREMENT,
    flight_id INT,
    seat_number VARCHAR(10),
    status ENUM('Available', 'Booked'),
    FOREIGN KEY (flight_id) REFERENCES Flights(flight_id)
);

-- Loyalty Program table
CREATE TABLE Loyalty_Program (
    passenger_id INT PRIMARY KEY,
    points DECIMAL(10, 2),
    FOREIGN KEY (passenger_id) REFERENCES Passengers(passenger_id)
);

-- Booking table
CREATE TABLE Booking (
    booking_id INT PRIMARY KEY AUTO_INCREMENT,
    flight_id INT,
    passenger_id INT,
    seat_number VARCHAR(10),
    FOREIGN KEY (flight_id) REFERENCES Flights(flight_id),
    FOREIGN KEY (passenger_id) REFERENCES Passengers(passenger_id)
);

-- Step 4: Populate tables with sample data

-- Insert data into Flights table
INSERT INTO Flights (flight_number, departure_time, arrival_time, source, destination, class)
VALUES
('SK123', '2024-11-20 08:00:00', '2024-11-20 11:00:00', 'New York', 'London', 'Economy'),
('SK456', '2024-11-21 09:00:00', '2024-11-21 12:00:00', 'Los Angeles', 'Tokyo', 'Business'),
('SK789', '2024-11-22 10:00:00', '2024-11-22 14:00:00', 'Sydney', 'Singapore', 'Economy'),
('SK101', '2024-11-23 07:00:00', '2024-11-23 11:00:00', 'Mumbai', 'Dubai', 'First'),
('SK202', '2024-11-24 13:00:00', '2024-11-24 16:00:00', 'Paris', 'Berlin', 'Business');

-- Insert data into Passengers table
INSERT INTO Passengers (first_name, last_name, seat_preference, class)
VALUES
('John', 'Doe', 'Window', 'Economy'),
('Jane', 'Smith', 'Aisle', 'Business'),
('Alice', 'Johnson', 'Middle', 'Economy'),
('Robert', 'Brown', 'Window', 'First'),
('Emily', 'Davis', 'Aisle', 'Business');

-- Insert data into Seat Allocation table
INSERT INTO Seat_Allocation (flight_id, seat_number, status)
VALUES
(1, '1A', 'Available'),
(1, '1B', 'Booked'),
(2, '2A', 'Available'),
(2, '2B', 'Booked'),
(3, '3C', 'Available');

-- Insert data into Loyalty Program table
INSERT INTO Loyalty_Program (passenger_id, points)
VALUES
(1, 1000.50),
(2, 2000.75),
(3, 1500.00),
(4, 3000.25),
(5, 500.00);

-- Insert data into Booking table
INSERT INTO Booking (flight_id, passenger_id, seat_number)
VALUES
(1, 1, '1B'),
(2, 2, '2B'),
(3, 3, '3C'),
(4, 4, '1A'),
(5, 5, '2A');

-- Step 5: Create a federated user for the local server
CREATE USER 'fed_user'@'%' IDENTIFIED BY 'fed_password';

-- Grant privileges to the federated user
GRANT ALL PRIVILEGES ON AirlineDB.* TO 'fed_user'@'%';

-- Flush privileges to apply changes
FLUSH PRIVILEGES;
DELIMITER //

CREATE PROCEDURE TransferBooking(
    IN original_booking_id INT,
    IN new_flight_id INT
)
BEGIN
    DECLARE original_passenger_id INT;
    DECLARE old_flight_id INT;
    DECLARE old_seat_number VARCHAR(10);
    DECLARE new_seat_number VARCHAR(10);
    
    -- Retrieve the passenger ID, old flight ID, and old seat number for the original booking
    SELECT passenger_id, flight_id, seat_number 
    INTO original_passenger_id, old_flight_id, old_seat_number
    FROM Booking
    WHERE booking_id = original_booking_id;

    -- Check for available seats on the new flight
    SELECT seat_number INTO new_seat_number
    FROM Seat_Allocation
    WHERE flight_id = new_flight_id AND status = 'Available'
    LIMIT 1;

    IF new_seat_number IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No available seats on the selected flight.';
    ELSE
        -- Update the Booking with the new flight ID and seat number
        UPDATE Booking
        SET flight_id = new_flight_id,
            seat_number = new_seat_number
        WHERE booking_id = original_booking_id;

        -- Mark the new seat as Booked
        UPDATE Seat_Allocation
        SET status = 'Booked'
        WHERE flight_id = new_flight_id AND seat_number = new_seat_number;

        -- Free up the old seat (optional if applicable)
        UPDATE Seat_Allocation
        SET status = 'Available'
        WHERE flight_id = old_flight_id AND seat_number = old_seat_number;
    END IF;
END //

DELIMITER ;
CALL TransferBooking(1, 3);
ALTER TABLE Seat_Allocation
ADD COLUMN last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
DELIMITER //

CREATE TRIGGER update_seat_availability
AFTER INSERT ON Booking
FOR EACH ROW
BEGIN
    -- Decrease available seats after a new booking
    UPDATE Seat_Allocation
    SET status = 'Booked', 
        last_updated = CURRENT_TIMESTAMP
    WHERE flight_id = NEW.flight_id AND seat_number = NEW.seat_number;
END //

CREATE TRIGGER revert_seat_availability
AFTER DELETE ON Booking
FOR EACH ROW
BEGIN
    -- Increase available seats after a cancellation
    UPDATE Seat_Allocation
    SET status = 'Available', 
        last_updated = CURRENT_TIMESTAMP
    WHERE flight_id = OLD.flight_id AND seat_number = OLD.seat_number;
END //

DELIMITER ;
DELIMITER //

CREATE FUNCTION calculate_future_points(
    current_points DECIMAL(10, 2),
    growth_rate DECIMAL(5, 2),
    years INT
) 
RETURNS DECIMAL(10, 2)
DETERMINISTIC
BEGIN
    RETURN current_points * POWER(1 + growth_rate / 100, years);
END //

DELIMITER ;
SELECT 
    CONCAT(first_name, ' ', last_name) AS full_name,
    LP.points AS current_points,
    calculate_future_points(LP.points, 5, 5) AS projected_points
FROM 
    Passengers P
JOIN 
    Loyalty_Program LP ON P.passenger_id = LP.passenger_id;
CREATE TABLE employees ( employee_id INT PRIMARY KEY, employee_name VARCHAR(100)
);
-- Employee_hierarchy table
CREATE TABLE employee_hierarchy ( employee_id INT, manager_id INT,
FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
FOREIGN KEY (manager_id) REFERENCES employees(employee_id)
);
-- Insert employees
INSERT INTO employees (employee_id, employee_name) VALUES
(1, 'Alice'),
(2, 'Bob'),
(3, 'Charlie');
-- Insert employee hierarchy (relationships between employees)
INSERT INTO employee_hierarchy (employee_id, manager_id) VALUES
(2, 1), -- Bob reports to Alice
(3, 1); -- Charlie reports to Alice
WITH RECURSIVE EmployeeHierarchy AS (
    -- Base case: Find employees who report directly to Alice
    SELECT 
        eh.employee_id, 
        e.employee_name, 
        eh.manager_id
    FROM 
        employee_hierarchy eh
    INNER JOIN employees e ON eh.employee_id = e.employee_id
    WHERE 
        eh.manager_id = (SELECT employee_id FROM employees WHERE employee_name = 'Alice')

    UNION ALL

    -- Recursive case: Find employees who report indirectly to Alice
    SELECT 
        eh.employee_id, 
        e.employee_name, 
        eh.manager_id
    FROM 
        employee_hierarchy eh
    INNER JOIN employees e ON eh.employee_id = e.employee_id
    INNER JOIN EmployeeHierarchy eh_recursive ON eh.manager_id = eh_recursive.employee_id
)

SELECT * FROM EmployeeHierarchy;

-- -- transation isolation part:
----session 1
-- START TRANSACTION;

-- -- Update the seat number for booking_id = 3
-- UPDATE Booking
-- SET seat_number = '3D'
-- WHERE booking_id = 3;
---- session 2
-- -- Hold the transaction open
-- UPDATE Booking
-- SET seat_number = '3E'
-- WHERE booking_id = 3;
---- session 1 
-- commit; 