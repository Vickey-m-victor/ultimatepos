-- Initial MySQL setup for UltimatePOS
-- This file is executed when the MySQL container is first created

-- Set SQL mode for better compatibility
SET sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';

-- Grant all privileges to the application user
GRANT ALL PRIVILEGES ON ultimatepos.* TO 'ultimatepos'@'%';
FLUSH PRIVILEGES;

-- Optimize MySQL settings for POS system
SET GLOBAL innodb_buffer_pool_size = 256M;
SET GLOBAL max_connections = 200;
SET GLOBAL wait_timeout = 600;
SET GLOBAL interactive_timeout = 600;