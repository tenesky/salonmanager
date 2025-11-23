-- SQL schema for the 4people user management.
-- Create the database and user table.

-- Assuming the database 'peopledb' already exists and your user has rights on it.
-- Switch to your CloudPanel database.
USE `peopledb`;

-- Create users table
CREATE TABLE IF NOT EXISTS `users` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `email` VARCHAR(100) NOT NULL,
  `password` VARCHAR(255) NOT NULL,
  `role` ENUM('customer','employee','admin') NOT NULL DEFAULT 'customer',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email_unique` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table for salon services. Each service has a name, a duration in minutes,
-- an optional price and an optional buffer time in minutes that is
-- automatically added after the service ends (e.g. for cleaning up).
CREATE TABLE IF NOT EXISTS `services` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `duration_minutes` INT NOT NULL,
  `price` DECIMAL(10,2) DEFAULT 0,
  `buffer_minutes` INT DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table for appointment bookings. Each booking links a customer to a
-- service and an employee at a specific start time. The end time is
-- derived from the service duration plus its buffer. Status can be
-- used to track cancellations and reschedules.
CREATE TABLE IF NOT EXISTS `bookings` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `customer_id` INT UNSIGNED NOT NULL,
  `employee_id` INT UNSIGNED NOT NULL,
  `service_id` INT UNSIGNED NOT NULL,
  `start_datetime` DATETIME NOT NULL,
  `end_datetime` DATETIME NOT NULL,
  `status` ENUM('confirmed','cancelled_by_customer','cancelled_by_salon','rescheduled') NOT NULL DEFAULT 'confirmed',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Additional tables (e.g. sessions) can be added later as needed.