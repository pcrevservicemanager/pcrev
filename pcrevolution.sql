-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 18, 2026 at 08:38 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `pcrevolution`
--

-- --------------------------------------------------------

--
-- Table structure for table `inventory_items`
--

CREATE TABLE `inventory_items` (
  `id` int(11) NOT NULL,
  `sku` varchar(64) DEFAULT NULL,
  `name` varchar(200) NOT NULL,
  `category` varchar(100) DEFAULT NULL,
  `cost` decimal(12,2) NOT NULL DEFAULT 0.00,
  `price` decimal(12,2) NOT NULL DEFAULT 0.00,
  `stock_qty` int(11) NOT NULL DEFAULT 0,
  `reorder_level` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `job_orders`
--

CREATE TABLE `job_orders` (
  `id` int(11) NOT NULL,
  `status_token` varchar(32) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `client_category` enum('New Customer','Referral','Repeat Customer') NOT NULL DEFAULT 'New Customer',
  `customer_name` varchar(150) NOT NULL,
  `contact_number` varchar(50) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `fb_name` varchar(150) DEFAULT NULL,
  `si_dr_number` varchar(64) DEFAULT NULL,
  `years_of_unit` varchar(50) DEFAULT NULL,
  `warranty` tinyint(1) DEFAULT NULL,
  `purchase_date` date DEFAULT NULL,
  `action_taken` text DEFAULT NULL,
  `diagnosed_by` varchar(100) DEFAULT NULL,
  `tech_assigned` varchar(100) DEFAULT NULL,
  `checklist` text DEFAULT NULL,
  `received_by` varchar(100) DEFAULT NULL,
  `released_to` varchar(150) DEFAULT NULL,
  `released_at` datetime DEFAULT NULL,
  `status` enum('Received','Diagnosing','Waiting for Parts','Repairing','Ready for Pickup','Released') NOT NULL DEFAULT 'Received',
  `tech_user_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `job_orders`
--

INSERT INTO `job_orders` (`id`, `status_token`, `created_at`, `client_category`, `customer_name`, `contact_number`, `email`, `fb_name`, `si_dr_number`, `years_of_unit`, `warranty`, `purchase_date`, `action_taken`, `diagnosed_by`, `tech_assigned`, `checklist`, `received_by`, `released_to`, `released_at`, `status`, `tech_user_id`) VALUES
(1193, 'ambI5DmPxh0', '2026-11-11 14:20:15', 'New Customer', 'Cust1', '09563058107', 'genesisvillanueva348@gmail.com', '', '', '', NULL, NULL, '', '', 'Staff1', '', 'Tech1', '', NULL, 'Diagnosing', 2);

-- --------------------------------------------------------

--
-- Table structure for table `job_order_items`
--

CREATE TABLE `job_order_items` (
  `id` int(11) NOT NULL,
  `job_order_id` int(11) NOT NULL,
  `qty` int(11) NOT NULL DEFAULT 1,
  `description` varchar(255) NOT NULL,
  `serial_no` varchar(100) DEFAULT NULL,
  `issue` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `job_order_items`
--

INSERT INTO `job_order_items` (`id`, `job_order_id`, `qty`, `description`, `serial_no`, `issue`) VALUES
(3, 1193, 1, 'Desktop', '1234', 'Not boot');

-- --------------------------------------------------------

--
-- Table structure for table `sales`
--

CREATE TABLE `sales` (
  `id` int(11) NOT NULL,
  `si_dr_number` varchar(64) DEFAULT NULL,
  `customer_name` varchar(150) DEFAULT NULL,
  `job_order_id` int(11) DEFAULT NULL,
  `total` decimal(12,2) NOT NULL DEFAULT 0.00,
  `payment_method` varchar(50) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sale_items`
--

CREATE TABLE `sale_items` (
  `id` int(11) NOT NULL,
  `sale_id` int(11) NOT NULL,
  `item_id` int(11) DEFAULT NULL,
  `qty` int(11) NOT NULL,
  `unit_price` decimal(12,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tickets`
--

CREATE TABLE `tickets` (
  `id` int(11) NOT NULL,
  `subject` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `customer_name` varchar(150) DEFAULT NULL,
  `job_order_id` int(11) DEFAULT NULL,
  `priority` varchar(20) NOT NULL DEFAULT 'Normal',
  `status` varchar(20) NOT NULL DEFAULT 'Open',
  `assigned_to` varchar(100) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(30) NOT NULL,
  `full_name` varchar(150) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('Admin','Technical In-Charge','Service Manager','HR') NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `full_name`, `password_hash`, `role`, `active`, `created_at`) VALUES
(1, 'admin', 'Genesis Villanueva', 'pbkdf2:sha256:1000000$sOtvvAEqlbjiJWZL$e8fd2d57d69791fa71f903955b1721a71271977b42bf36102127b90a483ee3c4', 'Admin', 1, '2026-11-11 13:50:28'),
(2, 'staff', 'Staff1', 'pbkdf2:sha256:1000000$tSpqsF6iqjIRNMca$a6b54a413cdc083479de01c1fcc8c73db36f78b7a1426b21e3a307b3122c6e61', 'Technical In-Charge', 1, '2026-11-11 16:06:59');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `inventory_items`
--
ALTER TABLE `inventory_items`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `sku` (`sku`);

--
-- Indexes for table `job_orders`
--
ALTER TABLE `job_orders`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `status_token` (`status_token`),
  ADD KEY `fk_job_tech` (`tech_user_id`);

--
-- Indexes for table `job_order_items`
--
ALTER TABLE `job_order_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `job_order_id` (`job_order_id`);

--
-- Indexes for table `sales`
--
ALTER TABLE `sales`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `si_dr_number` (`si_dr_number`),
  ADD KEY `job_order_id` (`job_order_id`);

--
-- Indexes for table `sale_items`
--
ALTER TABLE `sale_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sale_id` (`sale_id`),
  ADD KEY `item_id` (`item_id`);

--
-- Indexes for table `tickets`
--
ALTER TABLE `tickets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `job_order_id` (`job_order_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `inventory_items`
--
ALTER TABLE `inventory_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `job_orders`
--
ALTER TABLE `job_orders`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1194;

--
-- AUTO_INCREMENT for table `job_order_items`
--
ALTER TABLE `job_order_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `sales`
--
ALTER TABLE `sales`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `sale_items`
--
ALTER TABLE `sale_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tickets`
--
ALTER TABLE `tickets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `job_orders`
--
ALTER TABLE `job_orders`
  ADD CONSTRAINT `fk_job_tech` FOREIGN KEY (`tech_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `job_order_items`
--
ALTER TABLE `job_order_items`
  ADD CONSTRAINT `job_order_items_ibfk_1` FOREIGN KEY (`job_order_id`) REFERENCES `job_orders` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `sales`
--
ALTER TABLE `sales`
  ADD CONSTRAINT `sales_ibfk_1` FOREIGN KEY (`job_order_id`) REFERENCES `job_orders` (`id`);

--
-- Constraints for table `sale_items`
--
ALTER TABLE `sale_items`
  ADD CONSTRAINT `sale_items_ibfk_1` FOREIGN KEY (`sale_id`) REFERENCES `sales` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `sale_items_ibfk_2` FOREIGN KEY (`item_id`) REFERENCES `inventory_items` (`id`);

--
-- Constraints for table `tickets`
--
ALTER TABLE `tickets`
  ADD CONSTRAINT `tickets_ibfk_1` FOREIGN KEY (`job_order_id`) REFERENCES `job_orders` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
