-- PC Revolution System: MySQL / MariaDB schema
-- Run:  mysql -u root -p < schema.sql      (or import this file in phpMyAdmin)

CREATE DATABASE IF NOT EXISTS pcrevolution CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pcrevolution;

-- ============ STAFF ACCOUNTS ============
CREATE TABLE IF NOT EXISTS users (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    username      VARCHAR(30) NOT NULL UNIQUE,
    full_name     VARCHAR(150) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role          ENUM('Admin','Technical In-Charge','Service Manager','HR') NOT NULL,
    active        BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============ JOB ORDER MODULE (active) ============
-- id doubles as the job order number (starts at 1193, shown as 01193)
CREATE TABLE IF NOT EXISTS job_orders (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    status_token    VARCHAR(32) NOT NULL UNIQUE,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    client_category ENUM('New Customer','Referral','Repeat Customer') NOT NULL DEFAULT 'New Customer',
    customer_name   VARCHAR(150) NOT NULL,
    contact_number  VARCHAR(50),
    email           VARCHAR(150),
    fb_name         VARCHAR(150),
    si_dr_number    VARCHAR(64),
    years_of_unit   VARCHAR(50),
    warranty        BOOLEAN NULL,
    purchase_date   DATE NULL,
    action_taken    TEXT,
    diagnosed_by    VARCHAR(100),
    tech_assigned   VARCHAR(100),
    checklist       TEXT,                 -- comma-separated checked items
    received_by     VARCHAR(100),
    released_to     VARCHAR(150),
    released_at     DATETIME NULL,
    status          ENUM('Received','Diagnosing','Waiting for Parts','Repairing','Ready for Pickup','Released')
                    NOT NULL DEFAULT 'Received',
    tech_user_id    INT NULL,
    FOREIGN KEY (tech_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=1193 DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS job_order_items (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    job_order_id INT NOT NULL,
    qty          INT NOT NULL DEFAULT 1,
    description  VARCHAR(255) NOT NULL,
    serial_no    VARCHAR(100),
    issue        VARCHAR(255),
    FOREIGN KEY (job_order_id) REFERENCES job_orders(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============ INVENTORY MODULE (to follow) ============
CREATE TABLE IF NOT EXISTS inventory_items (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    sku           VARCHAR(64) UNIQUE,
    name          VARCHAR(200) NOT NULL,
    category      VARCHAR(100),
    cost          DECIMAL(12,2) NOT NULL DEFAULT 0,
    price         DECIMAL(12,2) NOT NULL DEFAULT 0,
    stock_qty     INT NOT NULL DEFAULT 0,
    reorder_level INT NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============ POINT OF SALE MODULE (to follow) ============
CREATE TABLE IF NOT EXISTS sales (
    id             INT AUTO_INCREMENT PRIMARY KEY,
    si_dr_number   VARCHAR(64) UNIQUE,
    customer_name  VARCHAR(150),
    job_order_id   INT NULL,
    total          DECIMAL(12,2) NOT NULL DEFAULT 0,
    payment_method VARCHAR(50),
    created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (job_order_id) REFERENCES job_orders(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS sale_items (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    sale_id    INT NOT NULL,
    item_id    INT NULL,
    qty        INT NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES inventory_items(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============ TICKETING MODULE (to follow) ============
CREATE TABLE IF NOT EXISTS tickets (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    subject       VARCHAR(255) NOT NULL,
    description   TEXT,
    customer_name VARCHAR(150),
    job_order_id  INT NULL,
    priority      VARCHAR(20) NOT NULL DEFAULT 'Normal',
    status        VARCHAR(20) NOT NULL DEFAULT 'Open',
    assigned_to   VARCHAR(100),
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (job_order_id) REFERENCES job_orders(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
