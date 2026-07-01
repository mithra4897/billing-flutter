-- phpMyAdmin SQL Dump
-- version 5.2.3deb1
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Jun 26, 2026 at 04:55 AM
-- Server version: 8.4.10-0ubuntu0.26.04.1
-- PHP Version: 8.5.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `billing`
--

-- --------------------------------------------------------

--
-- Table structure for table `warehouses`
--

CREATE TABLE `warehouses` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `warehouse_type` enum('main','raw_material','finished_goods','wip','damage','returns','transit','jobwork','other') COLLATE utf8mb4_unicode_ci DEFAULT 'main',
  `parent_warehouse_id` bigint UNSIGNED DEFAULT NULL,
  `allow_negative_stock` tinyint(1) NOT NULL DEFAULT '0',
  `is_sellable_stock` tinyint(1) NOT NULL DEFAULT '1',
  `is_reserved_only` tinyint(1) NOT NULL DEFAULT '0',
  `is_default` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `warehouses`
--

INSERT INTO `warehouses` (`id`, `company_id`, `branch_id`, `location_id`, `code`, `name`, `warehouse_type`, `parent_warehouse_id`, `allow_negative_stock`, `is_sellable_stock`, `is_reserved_only`, `is_default`, `is_active`, `remarks`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 1, 'MAIN-STK', 'Main Stock', 'main', NULL, 0, 1, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(2, 1, 1, 1, 'RM-STK', 'Raw Material Store', 'raw_material', NULL, 0, 1, 0, 0, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(3, 1, 1, 1, 'FG-STK', 'Finished Goods Store', 'finished_goods', NULL, 0, 1, 0, 0, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(4, 1, 1, 1, 'WIP-STK', 'WIP Store', 'wip', NULL, 0, 0, 0, 0, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(5, 1, 1, 1, 'DMG-STK', 'Damage Store', 'damage', NULL, 0, 0, 0, 0, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(6, 1, 1, 1, 'RTN-STK', 'Returns Store', 'returns', NULL, 0, 0, 0, 0, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(7, 1, 1, 1, 'TRN-STK', 'Transit Store', 'transit', NULL, 0, 0, 0, 0, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(8, 1, 1, 1, 'JOB-STK', 'Jobwork Store', 'jobwork', NULL, 0, 0, 0, 0, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `warehouses`
--
ALTER TABLE `warehouses`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_warehouses_location_code` (`location_id`,`code`),
  ADD UNIQUE KEY `uq_warehouses_location_name` (`location_id`,`name`),
  ADD KEY `idx_warehouses_company_id` (`company_id`),
  ADD KEY `idx_warehouses_branch_id` (`branch_id`),
  ADD KEY `idx_warehouses_location_id` (`location_id`),
  ADD KEY `idx_warehouses_parent` (`parent_warehouse_id`),
  ADD KEY `idx_warehouses_type` (`warehouse_type`),
  ADD KEY `idx_warehouses_is_default` (`is_default`),
  ADD KEY `idx_warehouses_is_active` (`is_active`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `warehouses`
--
ALTER TABLE `warehouses`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `warehouses`
--
ALTER TABLE `warehouses`
  ADD CONSTRAINT `fk_warehouses_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_warehouses_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_warehouses_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_warehouses_parent` FOREIGN KEY (`parent_warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
