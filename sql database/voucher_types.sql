-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Jun 18, 2026 at 08:29 AM
-- Server version: 11.8.6-MariaDB-log
-- PHP Version: 7.2.34

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `u199126363_billing`
--

-- --------------------------------------------------------

--
-- Table structure for table `voucher_types`
--

CREATE TABLE `voucher_types` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `code` varchar(50) NOT NULL,
  `name` varchar(100) NOT NULL,
  `voucher_category` enum('payment','receipt','journal','contra','sales','purchase','credit_note','debit_note','opening','adjustment') NOT NULL,
  `document_type` varchar(50) DEFAULT NULL,
  `auto_post` tinyint(1) NOT NULL DEFAULT 1,
  `requires_approval` tinyint(1) NOT NULL DEFAULT 0,
  `allows_reference_allocation` tinyint(1) NOT NULL DEFAULT 1,
  `is_system_type` tinyint(1) NOT NULL DEFAULT 1,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_by` bigint(20) UNSIGNED DEFAULT NULL,
  `updated_by` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `voucher_types`
--

INSERT INTO `voucher_types` (`id`, `code`, `name`, `voucher_category`, `document_type`, `auto_post`, `requires_approval`, `allows_reference_allocation`, `is_system_type`, `is_active`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(1, 'PAYMENT', 'Payment Voucher', 'payment', 'PAYMENT_VOUCHER', 1, 0, 1, 1, 1, NULL, NULL, '2026-05-05 11:01:42', '2026-05-05 11:01:42'),
(2, 'RECEIPT', 'Receipt Voucher', 'receipt', 'RECEIPT_VOUCHER', 1, 0, 1, 1, 1, NULL, 2, '2026-05-05 11:01:42', '2026-05-19 17:55:05'),
(3, 'JOURNAL', 'Journal Voucher', 'journal', 'JOURNAL_VOUCHER', 1, 0, 1, 1, 1, NULL, NULL, '2026-05-05 11:01:42', '2026-05-05 11:01:42'),
(4, 'CONTRA', 'Contra Voucher', 'contra', 'CONTRA_VOUCHER', 1, 0, 1, 1, 1, NULL, NULL, '2026-05-05 11:01:42', '2026-05-05 11:01:42'),
(5, 'SALES', 'Sales Voucher', 'sales', 'SALES_INVOICE', 1, 0, 1, 1, 1, NULL, NULL, '2026-05-05 11:01:42', '2026-05-05 11:01:42'),
(6, 'PURCHASE', 'Purchase Voucher', 'purchase', 'PURCHASE_INVOICE', 1, 0, 1, 1, 1, NULL, NULL, '2026-05-05 11:01:42', '2026-05-05 11:01:42'),
(7, 'CREDIT_NOTE', 'Credit Note', 'credit_note', 'CREDIT_NOTE', 1, 0, 1, 1, 1, NULL, NULL, '2026-05-05 11:01:42', '2026-05-05 11:01:42'),
(8, 'DEBIT_NOTE', 'Debit Note', 'debit_note', 'DEBIT_NOTE', 1, 0, 1, 1, 1, NULL, NULL, '2026-05-05 11:01:42', '2026-05-05 11:01:42'),
(9, 'OPENING', 'Opening Voucher', 'opening', 'OPENING_BALANCE', 1, 0, 1, 1, 1, NULL, NULL, '2026-05-05 11:01:42', '2026-05-05 11:01:42'),
(10, 'ADJUSTMENT', 'Adjustment Voucher', 'adjustment', 'ADJUSTMENT', 1, 0, 1, 1, 1, NULL, NULL, '2026-05-05 11:01:42', '2026-05-05 11:01:42');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `voucher_types`
--
ALTER TABLE `voucher_types`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_voucher_types_code` (`code`),
  ADD UNIQUE KEY `uq_voucher_types_name` (`name`),
  ADD KEY `idx_voucher_types_category` (`voucher_category`),
  ADD KEY `idx_voucher_types_document_type` (`document_type`),
  ADD KEY `fk_voucher_types_created_by` (`created_by`),
  ADD KEY `fk_voucher_types_updated_by` (`updated_by`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `voucher_types`
--
ALTER TABLE `voucher_types`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `voucher_types`
--
ALTER TABLE `voucher_types`
  ADD CONSTRAINT `fk_voucher_types_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_voucher_types_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
