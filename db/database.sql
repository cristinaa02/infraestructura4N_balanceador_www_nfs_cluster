
-- Create a database
DROP DATABASE IF EXISTS lamp_db;
CREATE DATABASE lamp_db CHARSET utf8mb4;
USE lamp_db;

-- Create the users table
CREATE TABLE users (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  age INT UNSIGNED NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- -- Usuario de la aplicación
-- DROP USER IF EXISTS 'user'@'%';
-- CREATE USER 'user'@'%' IDENTIFIED BY 'pass';
-- GRANT ALL PRIVILEGES ON lamp_db.* TO 'user'@'%';

-- -- Usuario para HAProxy (health checks)
-- DROP USER IF EXISTS 'haproxy'@'%';
-- CREATE USER 'haproxy'@'%' IDENTIFIED BY 'pass';
-- GRANT PROCESS ON *.* TO 'haproxy'@'%';

FLUSH PRIVILEGES;