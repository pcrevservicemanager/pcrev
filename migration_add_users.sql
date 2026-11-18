-- For a database you ALREADY created. Run once:  mysql -u root -p < migration_add_users.sql
USE pcrevolution;
CREATE TABLE IF NOT EXISTS users (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    username      VARCHAR(30) NOT NULL UNIQUE,
    full_name     VARCHAR(150) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role          ENUM('Admin','Technical In-Charge','Service Manager','HR') NOT NULL,
    active        BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE job_orders
    ADD COLUMN tech_user_id INT NULL,
    ADD CONSTRAINT fk_job_tech FOREIGN KEY (tech_user_id) REFERENCES users(id) ON DELETE SET NULL;
