-- phpMyAdmin SQL Dump
-- version 5.2.3deb1
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Jun 23, 2026 at 05:33 AM
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
-- Table structure for table `sales_invoices`
--

CREATE TABLE `sales_invoices` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `sales_order_id` bigint UNSIGNED DEFAULT NULL,
  `sales_delivery_id` bigint UNSIGNED DEFAULT NULL,
  `invoice_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `invoice_date` date NOT NULL,
  `due_date` date DEFAULT NULL,
  `customer_party_id` bigint UNSIGNED NOT NULL,
  `billing_address_id` bigint UNSIGNED DEFAULT NULL,
  `shipping_address_id` bigint UNSIGNED DEFAULT NULL,
  `contact_id` bigint UNSIGNED DEFAULT NULL,
  `customer_reference_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `customer_reference_date` date DEFAULT NULL,
  `currency_code` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'INR',
  `exchange_rate` decimal(18,6) NOT NULL DEFAULT '1.000000',
  `subtotal` decimal(18,2) NOT NULL DEFAULT '0.00',
  `discount_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `taxable_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `cgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `sgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `igst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `cess_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `round_off_method` enum('manual','bill','item') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'manual',
  `round_off_precision` decimal(18,2) NOT NULL DEFAULT '1.00',
  `round_off_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `total_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `adjustment_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `adjustment_account_id` bigint UNSIGNED DEFAULT NULL,
  `adjustment_remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `paid_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `balance_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `invoice_status` enum('draft','posted','partially_paid','paid','partially_returned','returned','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `terms_conditions` text COLLATE utf8mb4_unicode_ci,
  `posted_by` bigint UNSIGNED DEFAULT NULL,
  `posted_at` datetime DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `sales_invoices`
--

INSERT INTO `sales_invoices` (`id`, `company_id`, `branch_id`, `location_id`, `financial_year_id`, `document_series_id`, `sales_order_id`, `sales_delivery_id`, `invoice_no`, `invoice_date`, `due_date`, `customer_party_id`, `billing_address_id`, `shipping_address_id`, `contact_id`, `customer_reference_no`, `customer_reference_date`, `currency_code`, `exchange_rate`, `subtotal`, `discount_amount`, `taxable_amount`, `cgst_amount`, `sgst_amount`, `igst_amount`, `cess_amount`, `round_off_method`, `round_off_precision`, `round_off_amount`, `total_amount`, `adjustment_amount`, `adjustment_account_id`, `adjustment_remarks`, `paid_amount`, `balance_amount`, `voucher_id`, `invoice_status`, `notes`, `terms_conditions`, `posted_by`, `posted_at`, `is_active`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(82, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0054', '2026-05-22', NULL, 63, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 4100.00, 0.00, 4100.00, 0.00, 0.00, 738.00, 0.00, 'manual', 1.00, 0.00, 4838.00, 0.00, NULL, NULL, 0.00, 4838.00, 176, 'posted', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-22 11:36:30', 1, 4, 4, '2026-06-22 11:36:27', '2026-06-22 11:36:30');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `sales_invoices`
--
ALTER TABLE `sales_invoices`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_sales_invoices_company_no` (`company_id`,`invoice_no`),
  ADD KEY `idx_sales_invoices_customer` (`customer_party_id`),
  ADD KEY `idx_sales_invoices_date` (`invoice_date`),
  ADD KEY `idx_sales_invoices_due_date` (`due_date`),
  ADD KEY `idx_sales_invoices_status` (`invoice_status`),
  ADD KEY `fk_sales_invoices_branch` (`branch_id`),
  ADD KEY `fk_sales_invoices_location` (`location_id`),
  ADD KEY `fk_sales_invoices_financial_year` (`financial_year_id`),
  ADD KEY `fk_sales_invoices_document_series` (`document_series_id`),
  ADD KEY `fk_sales_invoices_order` (`sales_order_id`),
  ADD KEY `fk_sales_invoices_delivery` (`sales_delivery_id`),
  ADD KEY `fk_sales_invoices_billing_address` (`billing_address_id`),
  ADD KEY `fk_sales_invoices_shipping_address` (`shipping_address_id`),
  ADD KEY `fk_sales_invoices_contact` (`contact_id`),
  ADD KEY `fk_sales_invoices_adjustment_account` (`adjustment_account_id`),
  ADD KEY `fk_sales_invoices_voucher` (`voucher_id`),
  ADD KEY `fk_sales_invoices_posted_by` (`posted_by`),
  ADD KEY `fk_sales_invoices_created_by` (`created_by`),
  ADD KEY `fk_sales_invoices_updated_by` (`updated_by`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `sales_invoices`
--
ALTER TABLE `sales_invoices`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=83;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `sales_invoices`
--
ALTER TABLE `sales_invoices`
  ADD CONSTRAINT `fk_sales_invoices_adjustment_account` FOREIGN KEY (`adjustment_account_id`) REFERENCES `accounts` (`id`),
  ADD CONSTRAINT `fk_sales_invoices_billing_address` FOREIGN KEY (`billing_address_id`) REFERENCES `party_addresses` (`id`),
  ADD CONSTRAINT `fk_sales_invoices_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_sales_invoices_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_sales_invoices_contact` FOREIGN KEY (`contact_id`) REFERENCES `party_contacts` (`id`),
  ADD CONSTRAINT `fk_sales_invoices_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_sales_invoices_customer` FOREIGN KEY (`customer_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_sales_invoices_delivery` FOREIGN KEY (`sales_delivery_id`) REFERENCES `sales_deliveries` (`id`),
  ADD CONSTRAINT `fk_sales_invoices_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_sales_invoices_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_sales_invoices_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_sales_invoices_order` FOREIGN KEY (`sales_order_id`) REFERENCES `sales_orders` (`id`),
  ADD CONSTRAINT `fk_sales_invoices_posted_by` FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_sales_invoices_shipping_address` FOREIGN KEY (`shipping_address_id`) REFERENCES `party_addresses` (`id`),
  ADD CONSTRAINT `fk_sales_invoices_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_sales_invoices_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
