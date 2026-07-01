-- phpMyAdmin SQL Dump
-- version 5.2.3deb1
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Jun 23, 2026 at 06:58 AM
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
-- Table structure for table `items`
--

CREATE TABLE `items` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `item_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `item_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `item_name_local` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `item_type` enum('stock','service','manufactured','trade','raw_material','semi_finished','finished_goods','consumable','asset','non_stock') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'stock',
  `category_id` bigint UNSIGNED DEFAULT NULL,
  `brand_id` bigint UNSIGNED DEFAULT NULL,
  `base_uom_id` bigint UNSIGNED NOT NULL,
  `purchase_uom_id` bigint UNSIGNED DEFAULT NULL,
  `sales_uom_id` bigint UNSIGNED DEFAULT NULL,
  `tax_code_id` bigint UNSIGNED DEFAULT NULL,
  `sku` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `barcode` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `hsn_sac_code` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `has_batch` tinyint(1) NOT NULL DEFAULT '0',
  `has_serial` tinyint(1) NOT NULL DEFAULT '0',
  `has_expiry` tinyint(1) NOT NULL DEFAULT '0',
  `track_inventory` tinyint(1) NOT NULL DEFAULT '1',
  `is_saleable` tinyint(1) NOT NULL DEFAULT '1',
  `is_purchaseable` tinyint(1) NOT NULL DEFAULT '1',
  `is_manufacturable` tinyint(1) NOT NULL DEFAULT '0',
  `is_jobwork_applicable` tinyint(1) NOT NULL DEFAULT '0',
  `standard_cost` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `standard_selling_price` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `mrp` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `min_stock_level` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `reorder_level` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `reorder_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `weight` decimal(18,6) DEFAULT NULL,
  `volume` decimal(18,6) DEFAULT NULL,
  `image_path` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `items`
--

INSERT INTO `items` (`id`, `company_id`, `item_code`, `item_name`, `item_name_local`, `item_type`, `category_id`, `brand_id`, `base_uom_id`, `purchase_uom_id`, `sales_uom_id`, `tax_code_id`, `sku`, `barcode`, `hsn_sac_code`, `has_batch`, `has_serial`, `has_expiry`, `track_inventory`, `is_saleable`, `is_purchaseable`, `is_manufacturable`, `is_jobwork_applicable`, `standard_cost`, `standard_selling_price`, `mrp`, `min_stock_level`, `reorder_level`, `reorder_qty`, `weight`, `volume`, `image_path`, `is_active`, `remarks`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(42, 1, 'SFG/0018', 'IC MG82F6B08001', NULL, 'semi_finished', 3, 1, 1, 1, 1, 4, NULL, NULL, '85423100', 0, 0, 0, 0, 1, 0, 0, 0, 0.0000, 0.0000, 0.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 4, '2026-06-22 06:35:12', '2026-06-22 06:42:15');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `items`
--
ALTER TABLE `items`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_items_company_code` (`company_id`,`item_code`),
  ADD UNIQUE KEY `uq_items_company_name` (`company_id`,`item_name`),
  ADD KEY `idx_items_company_id` (`company_id`),
  ADD KEY `idx_items_category_id` (`category_id`),
  ADD KEY `idx_items_brand_id` (`brand_id`),
  ADD KEY `idx_items_base_uom_id` (`base_uom_id`),
  ADD KEY `idx_items_tax_code_id` (`tax_code_id`),
  ADD KEY `idx_items_item_type` (`item_type`),
  ADD KEY `idx_items_barcode` (`barcode`),
  ADD KEY `idx_items_hsn_sac_code` (`hsn_sac_code`),
  ADD KEY `idx_items_is_active` (`is_active`),
  ADD KEY `fk_items_purchase_uom` (`purchase_uom_id`),
  ADD KEY `fk_items_sales_uom` (`sales_uom_id`),
  ADD KEY `fk_items_created_by` (`created_by`),
  ADD KEY `fk_items_updated_by` (`updated_by`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `items`
--
ALTER TABLE `items`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=44;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `items`
--
ALTER TABLE `items`
  ADD CONSTRAINT `fk_items_base_uom` FOREIGN KEY (`base_uom_id`) REFERENCES `uoms` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_items_brand` FOREIGN KEY (`brand_id`) REFERENCES `brands` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_items_category` FOREIGN KEY (`category_id`) REFERENCES `item_categories` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_items_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_items_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_items_purchase_uom` FOREIGN KEY (`purchase_uom_id`) REFERENCES `uoms` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_items_sales_uom` FOREIGN KEY (`sales_uom_id`) REFERENCES `uoms` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_items_tax_code` FOREIGN KEY (`tax_code_id`) REFERENCES `tax_codes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_items_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
