-- phpMyAdmin SQL Dump
-- version 5.2.3deb1
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Jun 20, 2026 at 05:09 AM
-- Server version: 8.4.9-0ubuntu0.26.04.1
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
-- Table structure for table `accounts`
--

CREATE TABLE `accounts` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED DEFAULT NULL,
  `account_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `account_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `account_group_id` bigint UNSIGNED NOT NULL,
  `account_type` enum('general','party','cash','bank','tax','employee','customer','supplier','job_worker','transporter') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'general',
  `opening_balance` decimal(18,2) NOT NULL DEFAULT '0.00',
  `opening_balance_type` enum('debit','credit') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'debit',
  `currency_code` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'INR',
  `allow_manual_entries` tinyint(1) NOT NULL DEFAULT '1',
  `allow_reconciliation` tinyint(1) NOT NULL DEFAULT '0',
  `is_control_account` tinyint(1) NOT NULL DEFAULT '0',
  `is_system_account` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `accounts`
--

INSERT INTO `accounts` (`id`, `company_id`, `branch_id`, `account_code`, `account_name`, `account_group_id`, `account_type`, `opening_balance`, `opening_balance_type`, `currency_code`, `allow_manual_entries`, `allow_reconciliation`, `is_control_account`, `is_system_account`, `is_active`, `remarks`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(1, 1, NULL, 'CASH001', 'Cash Account', 6, 'cash', 0.00, 'debit', 'INR', 1, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(2, 1, NULL, 'BANK001', 'Bank Account', 6, 'bank', 0.00, 'debit', 'INR', 1, 1, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(3, 1, NULL, 'ARCTRL', 'Accounts Receivable Control', 7, 'general', 0.00, 'debit', 'INR', 0, 0, 1, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(4, 1, NULL, 'APCTRL', 'Accounts Payable Control', 11, 'general', 0.00, 'credit', 'INR', 0, 0, 1, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(5, 1, NULL, 'SALE001', 'Sales Account', 14, 'general', 0.00, 'credit', 'INR', 0, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(6, 1, NULL, 'DIRINC001', 'Direct Income Account', 15, 'general', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(7, 1, NULL, 'OTHINC001', 'Other Income Account', 16, 'general', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(8, 1, NULL, 'PUR001', 'Purchase Account', 17, 'general', 0.00, 'debit', 'INR', 0, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(9, 1, NULL, 'DIRECTEXP001', 'Direct Expense Account', 18, 'general', 0.00, 'debit', 'INR', 1, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(10, 1, NULL, 'SALARYEXP001', 'Salary Expense Account', 19, 'general', 0.00, 'debit', 'INR', 1, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(11, 1, NULL, 'OFFEXP001', 'Office Expense Account', 19, 'general', 0.00, 'debit', 'INR', 1, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(12, 1, NULL, 'OTHEXP001', 'Other Expense Account', 19, 'general', 0.00, 'debit', 'INR', 1, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(13, 1, NULL, 'MAINTEXP001', 'Maintenance Expense Account', 19, 'general', 0.00, 'debit', 'INR', 1, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(14, 1, NULL, 'GSTIN001', 'Input GST', 10, 'tax', 0.00, 'debit', 'INR', 0, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(15, 1, NULL, 'GSTOUT001', 'Output GST Payable', 12, 'tax', 0.00, 'credit', 'INR', 0, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(16, 1, NULL, 'SALPAY001', 'Salary Payable Account', 13, 'general', 0.00, 'credit', 'INR', 0, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(17, 1, NULL, 'MAINTPAY001', 'Maintenance Payable Account', 13, 'general', 0.00, 'credit', 'INR', 0, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(18, 1, NULL, 'STOCK001', 'Inventory Stock Asset', 8, 'general', 0.00, 'debit', 'INR', 0, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(19, 1, NULL, 'COGS001', 'Cost Of Goods Sold', 18, 'general', 0.00, 'debit', 'INR', 0, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(20, 1, NULL, 'SRNB001', 'Stock Received Not Billed', 11, 'general', 0.00, 'credit', 'INR', 0, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(21, 1, NULL, 'STKADJ001', 'Inventory Adjustment Account', 19, 'general', 0.00, 'debit', 'INR', 1, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(22, 1, NULL, 'STKLOSS001', 'Inventory Loss Account', 19, 'general', 0.00, 'debit', 'INR', 1, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(23, 1, NULL, 'WIP001', 'Work In Progress Inventory', 8, 'general', 0.00, 'debit', 'INR', 0, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(24, 1, NULL, 'MFGVAR001', 'Manufacturing Variance Account', 18, 'general', 0.00, 'debit', 'INR', 1, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(25, 1, NULL, 'SCRAP001', 'Production Scrap And Rejection Loss', 18, 'general', 0.00, 'debit', 'INR', 1, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(26, 1, NULL, 'JOBWIP001', 'Jobwork Work In Progress', 8, 'general', 0.00, 'debit', 'INR', 0, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(27, 1, NULL, 'JOBGRNI001', 'Jobwork Accrued Not Billed', 11, 'general', 0.00, 'credit', 'INR', 0, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(28, 1, NULL, 'JOBLOSS001', 'Jobwork Rejection And Processing Loss', 18, 'general', 0.00, 'debit', 'INR', 1, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(29, 1, NULL, 'STKTRANS001', 'Stock Transfer Clearing Account', 8, 'general', 0.00, 'debit', 'INR', 0, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(30, 1, NULL, 'SERVEXP001', 'Service Work Order Expense Account', 19, 'general', 0.00, 'debit', 'INR', 1, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(31, 1, NULL, 'SERVPAY001', 'Service Work Order Accrued Payable', 11, 'general', 0.00, 'credit', 'INR', 0, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(32, 1, NULL, 'SERVREV001', 'Service Work Order Revenue Account', 14, 'general', 0.00, 'credit', 'INR', 0, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(33, 1, NULL, 'PROJEXP001', 'Project Cost Allocation Account', 18, 'general', 0.00, 'debit', 'INR', 1, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(34, 1, NULL, 'PROJPAY001', 'Project Cost Accrued Payable', 11, 'general', 0.00, 'credit', 'INR', 0, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(35, 1, NULL, 'OPENSTK001', 'Opening Stock Adjustment', 3, 'general', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37'),
(40, 1, NULL, 'EMPPAYEMP00001', 'Pavithra L Salary Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee salary payable ledger', NULL, NULL, '2026-05-07 03:20:49', '2026-05-08 01:02:47'),
(41, 1, NULL, 'EMPRMBEMP00001', 'Pavithra L Reimbursement Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee reimbursement payable ledger', NULL, NULL, '2026-05-07 03:20:49', '2026-05-08 01:02:47'),
(42, 1, NULL, 'EMPPAYEMP00002', 'Gokul M Salary Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee salary payable ledger', NULL, NULL, '2026-05-07 03:27:34', '2026-05-07 03:27:34'),
(43, 1, NULL, 'EMPRMBEMP00002', 'Gokul M Reimbursement Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee reimbursement payable ledger', NULL, NULL, '2026-05-07 03:27:34', '2026-05-07 03:27:34'),
(44, 1, NULL, 'EMPPAYEMP00003', 'Rithish B Salary Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee salary payable ledger', NULL, NULL, '2026-05-07 04:19:08', '2026-05-07 04:19:08'),
(45, 1, NULL, 'EMPRMBEMP00003', 'Rithish B Reimbursement Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee reimbursement payable ledger', NULL, NULL, '2026-05-07 04:19:08', '2026-05-07 04:19:08'),
(46, 1, NULL, 'EMPPAYEMP00004', 'Pooja S Salary Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee salary payable ledger', NULL, NULL, '2026-05-07 04:19:18', '2026-05-07 04:19:18'),
(47, 1, NULL, 'EMPRMBEMP00004', 'Pooja S Reimbursement Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee reimbursement payable ledger', NULL, NULL, '2026-05-07 04:19:18', '2026-05-07 04:19:18'),
(48, 1, NULL, 'EMPPAYEMP00005', 'Meena Muruganantham Salary Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee salary payable ledger', NULL, NULL, '2026-05-07 04:20:42', '2026-05-07 04:20:42'),
(49, 1, NULL, 'EMPRMBEMP00005', 'Meena Muruganantham Reimbursement Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee reimbursement payable ledger', NULL, NULL, '2026-05-07 04:20:42', '2026-05-07 04:20:42'),
(50, 1, NULL, 'EMPPAYEMP00006', 'Balaji Velan Salary Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee salary payable ledger', NULL, NULL, '2026-05-07 04:21:15', '2026-05-07 04:21:15'),
(51, 1, NULL, 'EMPRMBEMP00006', 'Balaji Velan Reimbursement Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee reimbursement payable ledger', NULL, NULL, '2026-05-07 04:21:15', '2026-05-07 04:21:15'),
(52, 1, NULL, 'EMPPAYEMP00007', 'Vijayaragav L.G Salary Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee salary payable ledger', NULL, NULL, '2026-05-07 04:22:00', '2026-05-07 04:22:00'),
(53, 1, NULL, 'EMPRMBEMP00007', 'Vijayaragav L.G Reimbursement Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee reimbursement payable ledger', NULL, NULL, '2026-05-07 04:22:00', '2026-05-07 04:22:00'),
(54, 1, NULL, 'EMPPAYEMP00008', 'Dinesh Kumar S Salary Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee salary payable ledger', NULL, NULL, '2026-05-07 04:22:29', '2026-05-07 04:22:29'),
(55, 1, NULL, 'EMPRMBEMP00008', 'Dinesh Kumar S Reimbursement Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee reimbursement payable ledger', NULL, NULL, '2026-05-07 04:22:29', '2026-05-07 04:22:29'),
(56, 1, NULL, 'EMPPAYEMP00009', 'Mithra S Salary Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee salary payable ledger', NULL, NULL, '2026-05-07 04:22:45', '2026-05-07 04:22:45'),
(57, 1, NULL, 'EMPRMBEMP00009', 'Mithra S Reimbursement Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee reimbursement payable ledger', NULL, NULL, '2026-05-07 04:22:45', '2026-05-07 04:22:45'),
(58, 1, NULL, 'EMPPAYEMP00010', 'Balaji P Salary Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee salary payable ledger', NULL, NULL, '2026-05-07 04:23:00', '2026-05-07 04:23:00'),
(59, 1, NULL, 'EMPRMBEMP00010', 'Balaji P Reimbursement Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee reimbursement payable ledger', NULL, NULL, '2026-05-07 04:23:00', '2026-05-07 04:23:00'),
(60, 1, NULL, 'EMPPAYEMP00011', 'Gokul S Salary Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee salary payable ledger', NULL, NULL, '2026-05-07 04:24:32', '2026-05-07 04:24:32'),
(61, 1, NULL, 'EMPRMBEMP00011', 'Gokul S Reimbursement Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee reimbursement payable ledger', NULL, NULL, '2026-05-07 04:24:32', '2026-05-07 04:24:32'),
(62, 1, NULL, 'EMPPAYEMP00012', 'Siva M Salary Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee salary payable ledger', NULL, NULL, '2026-05-07 04:25:26', '2026-05-07 04:25:26'),
(63, 1, NULL, 'EMPRMBEMP00012', 'Siva M Reimbursement Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee reimbursement payable ledger', NULL, NULL, '2026-05-07 04:25:26', '2026-05-07 04:25:26'),
(64, 1, NULL, 'EMPPAYEMP00013', 'Kamaraj G Salary Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee salary payable ledger', NULL, NULL, '2026-05-07 04:32:46', '2026-05-07 04:32:46'),
(65, 1, NULL, 'EMPRMBEMP00013', 'Kamaraj G Reimbursement Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee reimbursement payable ledger', NULL, NULL, '2026-05-07 04:32:46', '2026-05-07 04:32:46'),
(66, 1, NULL, 'EMPPAYEMP00014', 'Elakkiya Shanmugam Salary Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee salary payable ledger', NULL, NULL, '2026-05-07 04:33:19', '2026-05-07 04:33:19'),
(67, 1, NULL, 'EMPRMBEMP00014', 'Elakkiya Shanmugam Reimbursement Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee reimbursement payable ledger', NULL, NULL, '2026-05-07 04:33:19', '2026-05-07 04:33:19'),
(68, 1, NULL, 'EMPPAYEMP00015', 'Janarthanam A Salary Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee salary payable ledger', NULL, NULL, '2026-05-07 04:33:48', '2026-05-07 04:33:48'),
(69, 1, NULL, 'EMPRMBEMP00015', 'Janarthanam A Reimbursement Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee reimbursement payable ledger', NULL, NULL, '2026-05-07 04:33:48', '2026-05-07 04:33:48'),
(70, 1, NULL, 'EMPPAYEMP00016', 'Yuvaraj Palani Salary Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee salary payable ledger', NULL, NULL, '2026-05-07 23:48:37', '2026-05-07 23:48:37'),
(71, 1, NULL, 'EMPRMBEMP00016', 'Yuvaraj Palani Reimbursement Payable', 13, 'employee', 0.00, 'credit', 'INR', 1, 0, 0, 1, 1, 'Employee reimbursement payable ledger', NULL, NULL, '2026-05-07 23:48:37', '2026-05-07 23:48:37'),
(72, 1, 1, 'cash0001', 'petty cash', 14, 'cash', 1000.00, 'debit', 'INR', 1, 0, 0, 0, 1, NULL, 2, 2, '2026-05-26 07:26:16', '2026-05-31 23:25:52'),
(73, 1, 1, 'Bank-002', 'KVB', 14, 'bank', 10000.00, 'credit', 'INR', 1, 0, 0, 0, 1, NULL, 4, 4, '2026-05-29 01:15:36', '2026-06-20 04:56:50'),
(74, 1, 1, 'Bank-001', 'IDBI BANK', 14, 'bank', 10000.00, 'credit', 'INR', 1, 0, 0, 0, 1, NULL, 4, 4, '2026-05-29 01:37:59', '2026-06-01 04:25:19'),
(99, 1, 1, 'Bank-003', 'DB BANK', 14, 'bank', 0.00, 'debit', 'INR', 1, 0, 0, 0, 1, NULL, 4, 4, '2026-06-20 04:58:25', '2026-06-20 05:07:55');

-- --------------------------------------------------------

--
-- Table structure for table `account_groups`
--

CREATE TABLE `account_groups` (
  `id` bigint UNSIGNED NOT NULL,
  `group_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `group_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `parent_group_id` bigint UNSIGNED DEFAULT NULL,
  `group_nature` enum('asset','liability','income','expense','equity') COLLATE utf8mb4_unicode_ci NOT NULL,
  `group_category` enum('cash_bank','receivable','payable','stock','tax','sales','purchase','direct_income','direct_expense','indirect_income','indirect_expense','fixed_asset','current_asset','current_liability','long_term_liability','equity','other') COLLATE utf8mb4_unicode_ci DEFAULT 'other',
  `affects_profit_loss` tinyint(1) NOT NULL DEFAULT '1',
  `is_system_group` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `account_groups`
--

INSERT INTO `account_groups` (`id`, `group_code`, `group_name`, `parent_group_id`, `group_nature`, `group_category`, `affects_profit_loss`, `is_system_group`, `is_active`, `remarks`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(1, 'ASSET', 'Assets', NULL, 'asset', 'other', 0, 1, 1, NULL, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42'),
(2, 'LIAB', 'Liabilities', NULL, 'liability', 'other', 0, 1, 1, NULL, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42'),
(3, 'EQUITY', 'Equity', NULL, 'equity', 'equity', 0, 1, 1, NULL, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42'),
(4, 'INCOME', 'Income', NULL, 'income', 'other', 1, 1, 1, NULL, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42'),
(5, 'EXPENSE', 'Expenses', NULL, 'expense', 'other', 1, 1, 1, NULL, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42'),
(6, 'CASHBANK', 'Cash & Bank', 1, 'asset', 'cash_bank', 0, 1, 1, NULL, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42'),
(7, 'RECEIVABLE', 'Accounts Receivable', 1, 'asset', 'receivable', 0, 1, 1, NULL, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42'),
(8, 'STOCK', 'Stock In Hand', 1, 'asset', 'stock', 0, 1, 1, NULL, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42'),
(9, 'FIXEDASSET', 'Fixed Assets', 1, 'asset', 'fixed_asset', 0, 1, 1, NULL, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42'),
(10, 'INPUTGST', 'Input GST', 1, 'asset', 'tax', 0, 1, 1, NULL, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42'),
(11, 'PAYABLE', 'Accounts Payable', 2, 'liability', 'payable', 0, 1, 1, NULL, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42'),
(12, 'DUTIES', 'Duties & Taxes', 2, 'liability', 'tax', 0, 1, 1, NULL, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42'),
(13, 'SALARYPAY', 'Salary Payable', 2, 'liability', 'current_liability', 0, 1, 1, NULL, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42'),
(14, 'SALES', 'Sales Accounts', 4, 'income', 'sales', 1, 1, 1, NULL, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42'),
(15, 'DIRECTINC', 'Direct Income', 4, 'income', 'direct_income', 1, 1, 1, NULL, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42'),
(16, 'OTHERINC', 'Indirect Income', 4, 'income', 'indirect_income', 1, 1, 1, NULL, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42'),
(17, 'PURCHASE', 'Purchase Accounts', 5, 'expense', 'purchase', 1, 1, 1, NULL, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42'),
(18, 'DIRECTEXP', 'Direct Expenses', 5, 'expense', 'direct_expense', 1, 1, 1, NULL, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42'),
(19, 'INDIRECTEXP', 'Indirect Expenses', 5, 'expense', 'indirect_expense', 1, 1, 1, NULL, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42');

-- --------------------------------------------------------

--
-- Table structure for table `amc_contracts`
--

CREATE TABLE `amc_contracts` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `contract_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `contract_date` date NOT NULL,
  `vendor_party_id` bigint UNSIGNED NOT NULL,
  `contract_type` enum('amc','cmc','service_contract','warranty_extension','other') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'amc',
  `contract_start_date` date NOT NULL,
  `contract_end_date` date NOT NULL,
  `coverage_scope` enum('labor_only','parts_only','labor_and_parts','inspection_only','custom') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'labor_only',
  `visit_frequency` enum('monthly','quarterly','half_yearly','yearly','on_call','custom') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'quarterly',
  `contract_value` decimal(18,2) NOT NULL DEFAULT '0.00',
  `tax_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `total_value` decimal(18,2) NOT NULL DEFAULT '0.00',
  `response_time_hours` decimal(18,2) DEFAULT NULL,
  `resolution_time_hours` decimal(18,2) DEFAULT NULL,
  `contract_status` enum('draft','active','expired','terminated','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `approved_by` bigint UNSIGNED DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `amc_contract_assets`
--

CREATE TABLE `amc_contract_assets` (
  `id` bigint UNSIGNED NOT NULL,
  `amc_contract_id` bigint UNSIGNED NOT NULL,
  `asset_id` bigint UNSIGNED NOT NULL,
  `coverage_notes` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `assets`
--

CREATE TABLE `assets` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED DEFAULT NULL,
  `location_id` bigint UNSIGNED DEFAULT NULL,
  `asset_category_id` bigint UNSIGNED NOT NULL,
  `asset_code` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `asset_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `asset_tag_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `serial_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `manufacturer` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `model_no` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `purchase_date` date DEFAULT NULL,
  `capitalization_date` date DEFAULT NULL,
  `put_to_use_date` date DEFAULT NULL,
  `purchase_invoice_id` bigint UNSIGNED DEFAULT NULL,
  `purchase_invoice_line_id` bigint UNSIGNED DEFAULT NULL,
  `supplier_party_id` bigint UNSIGNED DEFAULT NULL,
  `asset_account_id` bigint UNSIGNED DEFAULT NULL,
  `accum_depreciation_account_id` bigint UNSIGNED DEFAULT NULL,
  `depreciation_expense_account_id` bigint UNSIGNED DEFAULT NULL,
  `cost_center_id` bigint UNSIGNED DEFAULT NULL,
  `department_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `employee_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `warehouse_id` bigint UNSIGNED DEFAULT NULL,
  `acquisition_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `additional_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `capitalization_value` decimal(18,2) NOT NULL DEFAULT '0.00',
  `salvage_value` decimal(18,2) NOT NULL DEFAULT '0.00',
  `asset_status` enum('draft','active','under_construction','under_maintenance','transferred','disposed','retired','lost','inactive') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `condition_status` enum('new','good','fair','poor','damaged') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'good',
  `warranty_start_date` date DEFAULT NULL,
  `warranty_end_date` date DEFAULT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `activated_by` bigint UNSIGNED DEFAULT NULL,
  `activated_at` datetime DEFAULT NULL,
  `disposed_by` bigint UNSIGNED DEFAULT NULL,
  `disposed_at` datetime DEFAULT NULL,
  `is_depreciable` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `asset_books`
--

CREATE TABLE `asset_books` (
  `id` bigint UNSIGNED NOT NULL,
  `asset_id` bigint UNSIGNED NOT NULL,
  `book_type` enum('financial','tax','management') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'financial',
  `depreciation_method` enum('straight_line','written_down_value','manual') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'straight_line',
  `useful_life_months` int NOT NULL DEFAULT '60',
  `depreciation_rate` decimal(10,6) NOT NULL DEFAULT '0.000000',
  `capitalization_value` decimal(18,2) NOT NULL DEFAULT '0.00',
  `salvage_value` decimal(18,2) NOT NULL DEFAULT '0.00',
  `depreciable_value` decimal(18,2) NOT NULL DEFAULT '0.00',
  `accumulated_depreciation` decimal(18,2) NOT NULL DEFAULT '0.00',
  `net_book_value` decimal(18,2) NOT NULL DEFAULT '0.00',
  `depreciation_start_date` date DEFAULT NULL,
  `depreciation_end_date` date DEFAULT NULL,
  `last_depreciation_date` date DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `asset_categories`
--

CREATE TABLE `asset_categories` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `category_code` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `category_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `parent_category_id` bigint UNSIGNED DEFAULT NULL,
  `asset_type` enum('machinery','vehicle','computer','furniture','building','electrical','tool','office_equipment','other') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'other',
  `capitalization_threshold` decimal(18,2) NOT NULL DEFAULT '0.00',
  `default_asset_account_id` bigint UNSIGNED DEFAULT NULL,
  `default_accum_depreciation_account_id` bigint UNSIGNED DEFAULT NULL,
  `default_depreciation_expense_account_id` bigint UNSIGNED DEFAULT NULL,
  `default_disposal_gain_account_id` bigint UNSIGNED DEFAULT NULL,
  `default_disposal_loss_account_id` bigint UNSIGNED DEFAULT NULL,
  `default_depreciation_method` enum('straight_line','written_down_value','manual') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'straight_line',
  `default_useful_life_months` int NOT NULL DEFAULT '60',
  `default_salvage_value` decimal(18,2) NOT NULL DEFAULT '0.00',
  `is_tag_required` tinyint(1) NOT NULL DEFAULT '1',
  `is_serial_required` tinyint(1) NOT NULL DEFAULT '0',
  `is_depreciable` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `asset_depreciation_lines`
--

CREATE TABLE `asset_depreciation_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `asset_depreciation_run_id` bigint UNSIGNED NOT NULL,
  `asset_book_id` bigint UNSIGNED NOT NULL,
  `asset_id` bigint UNSIGNED NOT NULL,
  `depreciation_from_date` date NOT NULL,
  `depreciation_to_date` date NOT NULL,
  `opening_book_value` decimal(18,2) NOT NULL DEFAULT '0.00',
  `depreciation_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `closing_book_value` decimal(18,2) NOT NULL DEFAULT '0.00',
  `accumulated_depreciation_before` decimal(18,2) NOT NULL DEFAULT '0.00',
  `accumulated_depreciation_after` decimal(18,2) NOT NULL DEFAULT '0.00',
  `line_status` enum('draft','processed','posted','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `asset_depreciation_runs`
--

CREATE TABLE `asset_depreciation_runs` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `run_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `run_date` date NOT NULL,
  `depreciation_from_date` date NOT NULL,
  `depreciation_to_date` date NOT NULL,
  `book_type` enum('financial','tax','management') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'financial',
  `run_status` enum('draft','processing','completed','posted','cancelled','failed') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `total_assets_processed` int NOT NULL DEFAULT '0',
  `total_depreciation_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `error_message` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `posted_by` bigint UNSIGNED DEFAULT NULL,
  `posted_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `asset_disposals`
--

CREATE TABLE `asset_disposals` (
  `id` bigint UNSIGNED NOT NULL,
  `asset_id` bigint UNSIGNED NOT NULL,
  `disposal_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `disposal_date` date NOT NULL,
  `disposal_type` enum('sale','scrap','write_off','retirement','loss','theft') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'sale',
  `sale_party_id` bigint UNSIGNED DEFAULT NULL,
  `sales_invoice_id` bigint UNSIGNED DEFAULT NULL,
  `disposal_value` decimal(18,2) NOT NULL DEFAULT '0.00',
  `disposal_expense` decimal(18,2) NOT NULL DEFAULT '0.00',
  `book_value_at_disposal` decimal(18,2) NOT NULL DEFAULT '0.00',
  `gain_or_loss_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `disposal_status` enum('draft','approved','posted','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `approved_by` bigint UNSIGNED DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `asset_downtime_logs`
--

CREATE TABLE `asset_downtime_logs` (
  `id` bigint UNSIGNED NOT NULL,
  `asset_id` bigint UNSIGNED NOT NULL,
  `maintenance_work_order_id` bigint UNSIGNED DEFAULT NULL,
  `downtime_reason` enum('breakdown','planned_maintenance','inspection','power_failure','operator_issue','spare_waiting','vendor_waiting','other') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'breakdown',
  `downtime_start` datetime NOT NULL,
  `downtime_end` datetime DEFAULT NULL,
  `downtime_minutes` decimal(18,2) NOT NULL DEFAULT '0.00',
  `production_impact_notes` text COLLATE utf8mb4_unicode_ci,
  `is_planned` tinyint(1) NOT NULL DEFAULT '0',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `asset_transfers`
--

CREATE TABLE `asset_transfers` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `transfer_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `transfer_date` date NOT NULL,
  `transfer_reason` enum('location_change','department_change','employee_assignment','branch_transfer','repair_movement','other') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'location_change',
  `from_branch_id` bigint UNSIGNED DEFAULT NULL,
  `to_branch_id` bigint UNSIGNED DEFAULT NULL,
  `from_location_id` bigint UNSIGNED DEFAULT NULL,
  `to_location_id` bigint UNSIGNED DEFAULT NULL,
  `from_department_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `to_department_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `from_employee_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `to_employee_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `transfer_status` enum('draft','approved','completed','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `approved_by` bigint UNSIGNED DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `asset_transfer_lines`
--

CREATE TABLE `asset_transfer_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `asset_transfer_id` bigint UNSIGNED NOT NULL,
  `line_no` int NOT NULL,
  `asset_id` bigint UNSIGNED NOT NULL,
  `from_branch_id` bigint UNSIGNED DEFAULT NULL,
  `to_branch_id` bigint UNSIGNED DEFAULT NULL,
  `from_location_id` bigint UNSIGNED DEFAULT NULL,
  `to_location_id` bigint UNSIGNED DEFAULT NULL,
  `from_department_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `to_department_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `from_employee_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `to_employee_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `attendance_records`
--

CREATE TABLE `attendance_records` (
  `id` bigint UNSIGNED NOT NULL,
  `employee_id` bigint UNSIGNED DEFAULT NULL,
  `attendance_date` date DEFAULT NULL,
  `check_in` datetime DEFAULT NULL,
  `check_out` datetime DEFAULT NULL,
  `status` enum('present','absent','leave','half_day','holiday') COLLATE utf8mb4_unicode_ci DEFAULT 'present'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `audit_logs`
--

CREATE TABLE `audit_logs` (
  `id` bigint UNSIGNED NOT NULL,
  `user_id` bigint UNSIGNED DEFAULT NULL,
  `company_id` bigint UNSIGNED DEFAULT NULL,
  `branch_id` bigint UNSIGNED DEFAULT NULL,
  `location_id` bigint UNSIGNED DEFAULT NULL,
  `module` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `entity_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `entity_id` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `action` enum('create','update','delete','restore','approve','reject','post','cancel','print','export','login','logout') COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `old_values` json DEFAULT NULL,
  `new_values` json DEFAULT NULL,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `host_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `bank_reconciliation`
--

CREATE TABLE `bank_reconciliation` (
  `id` bigint UNSIGNED NOT NULL,
  `account_id` bigint UNSIGNED NOT NULL,
  `voucher_line_id` bigint UNSIGNED NOT NULL,
  `bank_date` date DEFAULT NULL,
  `cleared_date` date DEFAULT NULL,
  `reconciliation_status` enum('pending','cleared','bounced','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `bank_reference_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `reconciled_by` bigint UNSIGNED DEFAULT NULL,
  `reconciled_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `boms`
--

CREATE TABLE `boms` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `bom_code` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `bom_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `output_item_id` bigint UNSIGNED NOT NULL,
  `output_uom_id` bigint UNSIGNED NOT NULL,
  `version_no` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '1.0',
  `revision_no` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `batch_size` decimal(18,6) NOT NULL DEFAULT '1.000000',
  `standard_output_qty` decimal(18,6) NOT NULL DEFAULT '1.000000',
  `scrap_percent` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `yield_percent` decimal(8,4) NOT NULL DEFAULT '100.0000',
  `bom_type` enum('production','assembly','packing','repacking','process','jobwork') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'production',
  `approval_status` enum('draft','approved','inactive','obsolete') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `effective_from` date DEFAULT NULL,
  `effective_to` date DEFAULT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `approved_by` bigint UNSIGNED DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `bom_lines`
--

CREATE TABLE `bom_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `bom_id` bigint UNSIGNED NOT NULL,
  `line_no` int NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `line_type` enum('raw_material','packing_material','consumable','semi_finished','service','by_product','scrap') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'raw_material',
  `required_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `wastage_percent` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `net_required_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `issue_stage` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_backflush` tinyint(1) NOT NULL DEFAULT '1',
  `is_optional` tinyint(1) NOT NULL DEFAULT '0',
  `standard_rate` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `standard_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `bom_operations`
--

CREATE TABLE `bom_operations` (
  `id` bigint UNSIGNED NOT NULL,
  `bom_id` bigint UNSIGNED NOT NULL,
  `operation_no` int NOT NULL,
  `operation_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `work_center` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `setup_time_minutes` decimal(18,2) NOT NULL DEFAULT '0.00',
  `run_time_minutes` decimal(18,2) NOT NULL DEFAULT '0.00',
  `labor_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `machine_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `overhead_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `notes` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `branches`
--

CREATE TABLE `branches` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `branch_type` enum('head_office','branch_office','factory','warehouse_office','retail_outlet','service_center','other') COLLATE utf8mb4_unicode_ci DEFAULT 'branch_office',
  `is_head_office` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `branches`
--

INSERT INTO `branches` (`id`, `company_id`, `code`, `name`, `branch_type`, `is_head_office`, `is_active`, `remarks`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(1, 1, 'HO', 'Head Office', 'head_office', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37');

-- --------------------------------------------------------

--
-- Table structure for table `brands`
--

CREATE TABLE `brands` (
  `id` bigint UNSIGNED NOT NULL,
  `brand_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `brand_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `brands`
--

INSERT INTO `brands` (`id`, `brand_code`, `brand_name`, `is_active`, `remarks`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(1, 'GEN', 'Generic', 1, NULL, NULL, NULL, '2026-05-05 05:31:43', '2026-05-05 05:31:43');

-- --------------------------------------------------------

--
-- Table structure for table `budgets`
--

CREATE TABLE `budgets` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED DEFAULT NULL,
  `budget_code` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `budget_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `date_from` date NOT NULL,
  `date_to` date NOT NULL,
  `budget_status` enum('draft','approved','closed','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `budget_lines`
--

CREATE TABLE `budget_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `budget_id` bigint UNSIGNED NOT NULL,
  `line_no` int NOT NULL,
  `account_id` bigint UNSIGNED NOT NULL,
  `budget_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `business_locations`
--

CREATE TABLE `business_locations` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `location_type` enum('billing','warehouse','office','factory','retail','service','jobwork','other') COLLATE utf8mb4_unicode_ci DEFAULT 'billing',
  `contact_person` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address_line1` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address_line2` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `area` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `district` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `state_code` varchar(5) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `state_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `country_code` varchar(5) COLLATE utf8mb4_unicode_ci DEFAULT 'IN',
  `postal_code` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `allow_sales` tinyint(1) NOT NULL DEFAULT '1',
  `allow_purchase` tinyint(1) NOT NULL DEFAULT '1',
  `allow_stock` tinyint(1) NOT NULL DEFAULT '1',
  `allow_accounts` tinyint(1) NOT NULL DEFAULT '1',
  `allow_hr` tinyint(1) NOT NULL DEFAULT '1',
  `is_default` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `business_locations`
--

INSERT INTO `business_locations` (`id`, `company_id`, `branch_id`, `code`, `name`, `location_type`, `contact_person`, `phone`, `email`, `address_line1`, `address_line2`, `area`, `city`, `district`, `state_code`, `state_name`, `country_code`, `postal_code`, `latitude`, `longitude`, `allow_sales`, `allow_purchase`, `allow_stock`, `allow_accounts`, `allow_hr`, `is_default`, `is_active`, `remarks`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 'MAIN', 'Main Business Location', 'billing', 'System Admin', '9443036233', 'sakthicontroller@gmail.com', '153, Karunai Nagar, K.Sevoor', 'Katpadi Taluk', 'Katpadi', 'Vellore', 'Vellore', '33', 'Tamil Nadu', 'IN', '632106', NULL, NULL, 1, 1, 1, 1, 1, 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37');

-- --------------------------------------------------------

--
-- Table structure for table `cash_sessions`
--

CREATE TABLE `cash_sessions` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `user_id` bigint UNSIGNED NOT NULL,
  `cash_account_id` bigint UNSIGNED NOT NULL,
  `opening_datetime` datetime NOT NULL,
  `closing_datetime` datetime DEFAULT NULL,
  `opening_balance` decimal(18,2) NOT NULL DEFAULT '0.00',
  `expected_closing_balance` decimal(18,2) DEFAULT NULL,
  `actual_closing_balance` decimal(18,2) DEFAULT NULL,
  `variance_amount` decimal(18,2) DEFAULT NULL,
  `status` enum('open','closed','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'open',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `companies`
--

CREATE TABLE `companies` (
  `id` bigint UNSIGNED NOT NULL,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `legal_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `trade_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `company_type` enum('proprietorship','partnership','llp','private_limited','public_limited','trust','society','other') COLLATE utf8mb4_unicode_ci DEFAULT 'proprietorship',
  `gstin` varchar(15) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pan` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tan` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cin` varchar(21) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `website` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address_line1` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address_line2` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `area` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `district` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `state_code` varchar(5) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `state_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `country_code` varchar(5) COLLATE utf8mb4_unicode_ci DEFAULT 'IN',
  `postal_code` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `base_currency` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'INR',
  `timezone` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Asia/Kolkata',
  `logo_path` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `seal_path` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `letter_head_path` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `companies`
--

INSERT INTO `companies` (`id`, `code`, `legal_name`, `trade_name`, `company_type`, `gstin`, `pan`, `tan`, `cin`, `phone`, `email`, `website`, `address_line1`, `address_line2`, `area`, `city`, `district`, `state_code`, `state_name`, `country_code`, `postal_code`, `base_currency`, `timezone`, `logo_path`, `seal_path`, `letter_head_path`, `is_active`, `remarks`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(1, 'CMP001', 'Sakthi Controller OPC Pvt Ltd', 'Sakthi Controller OPC Pvt Ltd', 'private_limited', '33ABKCS2354K1Z5', 'ABKCS2354K', NULL, NULL, '9443036233', 'sakthicontroller@gmail.com', NULL, '153, Karunai Nagar, K.Sevoor', 'Katpadi Taluk', 'Katpadi', 'Vellore', 'Vellore', '33', 'Tamil Nadu', 'IN', '632106', 'INR', 'Asia/Kolkata', NULL, NULL, NULL, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37');

-- --------------------------------------------------------

--
-- Table structure for table `cost_centers`
--

CREATE TABLE `cost_centers` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `parent_id` bigint UNSIGNED DEFAULT NULL,
  `cost_center_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cost_center_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cost_center_type` enum('department','branch','project','production','service','admin','other') COLLATE utf8mb4_unicode_ci DEFAULT 'department',
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `cost_centers`
--

INSERT INTO `cost_centers` (`id`, `company_id`, `parent_id`, `cost_center_code`, `cost_center_name`, `cost_center_type`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 2, NULL, 'CC-OPS', 'Operations - Corporate', '', 1, '2026-06-17 08:25:27', '2026-06-17 08:25:27'),
(2, 2, NULL, 'CC-MFG', 'Manufacturing - Peenya', 'production', 1, '2026-06-17 08:25:27', '2026-06-17 08:25:27');

-- --------------------------------------------------------

--
-- Table structure for table `crm_enquiry_lines`
--

CREATE TABLE `crm_enquiry_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `enquiry_id` bigint UNSIGNED NOT NULL,
  `item_id` bigint UNSIGNED DEFAULT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `qty` decimal(18,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `crm_followups`
--

CREATE TABLE `crm_followups` (
  `id` bigint UNSIGNED NOT NULL,
  `enquiry_id` bigint UNSIGNED DEFAULT NULL,
  `followup_date` datetime DEFAULT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `next_followup` datetime DEFAULT NULL,
  `assigned_to` bigint UNSIGNED DEFAULT NULL,
  `status` enum('pending','done','skipped') COLLATE utf8mb4_unicode_ci DEFAULT 'pending'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `crm_leads`
--

CREATE TABLE `crm_leads` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `lead_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `company_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mobile` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `source_id` bigint UNSIGNED DEFAULT NULL,
  `assigned_to` bigint UNSIGNED DEFAULT NULL,
  `lead_status` enum('new','in_progress','converted','lost') COLLATE utf8mb4_unicode_ci DEFAULT 'new',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `crm_lead_activities`
--

CREATE TABLE `crm_lead_activities` (
  `id` bigint UNSIGNED NOT NULL,
  `lead_id` bigint UNSIGNED NOT NULL,
  `activity_type` enum('call','email','meeting','note','whatsapp') COLLATE utf8mb4_unicode_ci NOT NULL,
  `activity_datetime` datetime NOT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `next_followup` datetime DEFAULT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `crm_opportunities`
--

CREATE TABLE `crm_opportunities` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `enquiry_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `enquiry_date` date DEFAULT NULL,
  `lead_id` bigint UNSIGNED DEFAULT NULL,
  `customer_party_id` bigint UNSIGNED DEFAULT NULL,
  `stage_id` bigint UNSIGNED DEFAULT NULL,
  `assigned_to` bigint UNSIGNED DEFAULT NULL,
  `enquiry_status` enum('open','in_progress','converted','lost') COLLATE utf8mb4_unicode_ci DEFAULT 'open',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `opportunity_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `expected_value` decimal(18,2) DEFAULT '0.00',
  `probability_percent` decimal(5,2) DEFAULT '0.00',
  `expected_close_date` date DEFAULT NULL,
  `status` enum('open','won','lost') COLLATE utf8mb4_unicode_ci DEFAULT 'open'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `crm_opportunity_products`
--

CREATE TABLE `crm_opportunity_products` (
  `id` bigint UNSIGNED NOT NULL,
  `opportunity_id` bigint UNSIGNED DEFAULT NULL,
  `item_id` bigint UNSIGNED DEFAULT NULL,
  `qty` decimal(18,2) DEFAULT NULL,
  `estimated_price` decimal(18,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `crm_sources`
--

CREATE TABLE `crm_sources` (
  `id` bigint UNSIGNED NOT NULL,
  `source_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `crm_sources`
--

INSERT INTO `crm_sources` (`id`, `source_name`, `is_active`) VALUES
(1, 'Advertisement', 1),
(2, 'Walk-in', 1),
(3, 'Cold Calling', 1),
(4, 'Exhibition', 1),
(5, 'Website', 1),
(6, 'WhatsApp', 1),
(7, 'YouTube', 1),
(8, 'Referral', 1),
(9, 'IndiaMART', 1),
(10, 'Dealer', 1),
(11, 'College Seminar', 1),
(12, 'Repeat Customer', 1);

-- --------------------------------------------------------

--
-- Table structure for table `crm_stages`
--

CREATE TABLE `crm_stages` (
  `id` bigint UNSIGNED NOT NULL,
  `stage_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `stage_type` enum('lead','enquiry','opportunity','converted','closed_won','closed_lost') COLLATE utf8mb4_unicode_ci NOT NULL,
  `sequence_no` int NOT NULL,
  `probability_percent` decimal(5,2) DEFAULT '0.00',
  `is_default` tinyint(1) DEFAULT '0',
  `is_active` tinyint(1) DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `departments`
--

CREATE TABLE `departments` (
  `id` bigint UNSIGNED NOT NULL,
  `department_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `departments`
--

INSERT INTO `departments` (`id`, `department_name`, `is_active`) VALUES
(1, 'Administration', 1),
(2, 'Accounts', 1),
(3, 'Sales', 1),
(4, 'Purchase', 1),
(5, 'Stores', 1),
(6, 'Production', 1),
(7, 'Service', 1),
(8, 'Human Resources', 1),
(9, 'Software Developer', 1),
(10, 'Software-SCOPL', 1),
(11, 'Management', 1),
(12, 'Embededd - SCOPL', 1),
(13, 'Customer Service', 1),
(14, 'Sales', 1);

-- --------------------------------------------------------

--
-- Table structure for table `designations`
--

CREATE TABLE `designations` (
  `id` bigint UNSIGNED NOT NULL,
  `designation_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `designations`
--

INSERT INTO `designations` (`id`, `designation_name`, `is_active`) VALUES
(1, 'Manager', 1),
(2, 'Executive', 1),
(3, 'Supervisor', 1),
(4, 'Operator', 1),
(5, 'Technician', 1),
(6, 'Assistant', 1),
(7, 'Software', 1),
(8, 'Business Development Manager', 1),
(9, 'Senior Embedded Developer', 1),
(10, 'Product Manager', 1),
(11, 'Director & Founder', 1),
(12, 'Embedded Developer', 1),
(13, 'Chief Executive Officer', 1),
(14, 'Production Technician', 1),
(15, 'Customer Service Representative', 1),
(16, 'Software Developer', 1),
(17, 'Accounts & stores executive', 1),
(18, 'Software Trainee', 1),
(19, 'Marketing Specialist', 1);

-- --------------------------------------------------------

--
-- Table structure for table `document_postings`
--

CREATE TABLE `document_postings` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_module` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `document_table` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `document_id` bigint UNSIGNED NOT NULL,
  `document_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `document_date` date NOT NULL,
  `posting_rule_group_id` bigint UNSIGNED DEFAULT NULL,
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `posting_status` enum('pending','posted','reversed','failed','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `posted_at` datetime DEFAULT NULL,
  `reversed_at` datetime DEFAULT NULL,
  `error_message` text COLLATE utf8mb4_unicode_ci,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `document_postings`
--

INSERT INTO `document_postings` (`id`, `company_id`, `branch_id`, `location_id`, `financial_year_id`, `document_module`, `document_table`, `document_id`, `document_no`, `document_date`, `posting_rule_group_id`, `voucher_id`, `posting_status`, `posted_at`, `reversed_at`, `error_message`, `remarks`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(52, 1, 1, 1, 1, 'sales', 'sales_invoices', 29, 'SI/26-27/0001', '2026-06-19', NULL, 87, 'posted', '2026-06-19 06:53:39', NULL, NULL, NULL, 4, 4, '2026-06-19 06:53:39', '2026-06-19 06:53:39'),
(53, 1, 1, 1, 1, 'sales', 'sales_invoices', 30, 'SI/26-27/0002', '2026-04-02', NULL, 89, 'posted', '2026-06-19 09:30:05', NULL, NULL, NULL, 4, 4, '2026-06-19 09:30:05', '2026-06-19 09:30:05'),
(54, 1, 1, 1, 1, 'sales', 'sales_invoices', 31, 'SI/26-27/0003', '2026-04-02', NULL, 90, 'posted', '2026-06-19 09:34:59', NULL, NULL, NULL, 4, 4, '2026-06-19 09:34:59', '2026-06-19 09:34:59'),
(55, 1, 1, 1, 1, 'sales', 'sales_invoices', 32, 'SI/26-27/0004', '2026-04-03', NULL, 91, 'posted', '2026-06-19 09:38:01', NULL, NULL, NULL, 4, 4, '2026-06-19 09:38:01', '2026-06-19 09:38:01'),
(56, 1, 1, 1, 1, 'sales', 'sales_invoices', 33, 'SI/26-27/0005', '2026-04-03', NULL, 92, 'posted', '2026-06-19 09:44:02', NULL, NULL, NULL, 4, 4, '2026-06-19 09:44:02', '2026-06-19 09:44:02'),
(57, 1, 1, 1, 1, 'sales', 'sales_invoices', 34, 'SI/26-27/0006', '2026-04-04', NULL, 93, 'posted', '2026-06-19 09:54:03', NULL, NULL, NULL, 4, 4, '2026-06-19 09:54:03', '2026-06-19 09:54:03'),
(58, 1, 1, 1, 1, 'sales', 'sales_invoices', 35, 'SI/26-27/0007', '2026-04-06', NULL, 94, 'posted', '2026-06-19 10:00:44', NULL, NULL, NULL, 4, 4, '2026-06-19 10:00:44', '2026-06-19 10:00:44'),
(59, 1, 1, 1, 1, 'sales', 'sales_invoices', 36, 'SI/26-27/0008', '2026-04-06', NULL, 95, 'posted', '2026-06-19 10:28:29', NULL, NULL, NULL, 4, 4, '2026-06-19 10:28:29', '2026-06-19 10:28:29'),
(60, 1, 1, 1, 1, 'sales', 'sales_invoices', 37, 'SI/26-27/0009', '2026-04-06', NULL, 96, 'posted', '2026-06-19 10:30:51', NULL, NULL, NULL, 4, 4, '2026-06-19 10:30:51', '2026-06-19 10:30:51'),
(61, 1, 1, 1, 1, 'sales', 'sales_invoices', 38, 'SI/26-27/0010', '2026-04-07', NULL, 97, 'posted', '2026-06-19 10:32:55', NULL, NULL, NULL, 4, 4, '2026-06-19 10:32:55', '2026-06-19 10:32:55'),
(62, 1, 1, 1, 1, 'sales', 'sales_invoices', 39, 'SI/26-27/0011', '2026-04-08', NULL, 98, 'posted', '2026-06-19 10:47:22', NULL, NULL, NULL, 4, 4, '2026-06-19 10:47:22', '2026-06-19 10:47:22'),
(63, 1, 1, 1, 1, 'sales', 'sales_invoices', 40, 'SI/26-27/0012', '2026-04-08', NULL, 99, 'posted', '2026-06-19 10:55:49', NULL, NULL, NULL, 4, 4, '2026-06-19 10:55:49', '2026-06-19 10:55:49'),
(64, 1, 1, 1, 1, 'sales', 'sales_invoices', 41, 'SI/26-27/0013', '2026-04-10', NULL, 100, 'posted', '2026-06-19 10:59:38', NULL, NULL, NULL, 4, 4, '2026-06-19 10:59:38', '2026-06-19 10:59:38'),
(65, 1, 1, 1, 1, 'sales', 'sales_invoices', 42, 'SI/26-27/0014', '2026-04-11', NULL, 101, 'posted', '2026-06-19 11:19:14', NULL, NULL, NULL, 4, 4, '2026-06-19 11:19:14', '2026-06-19 11:19:14'),
(66, 1, 1, 1, 1, 'sales', 'sales_invoices', 43, 'SI/26-27/0015', '2026-04-13', NULL, 102, 'posted', '2026-06-19 11:20:56', NULL, NULL, NULL, 4, 4, '2026-06-19 11:20:56', '2026-06-19 11:20:56'),
(67, 1, 1, 1, 1, 'sales', 'sales_invoices', 44, 'SI/26-27/0016', '2026-04-15', NULL, 103, 'posted', '2026-06-19 11:24:35', NULL, NULL, NULL, 4, 4, '2026-06-19 11:24:35', '2026-06-19 11:24:35'),
(68, 1, 1, 1, 1, 'sales', 'sales_invoices', 45, 'SI/26-27/0017', '2026-04-16', NULL, 104, 'posted', '2026-06-19 11:26:16', NULL, NULL, NULL, 4, 4, '2026-06-19 11:26:16', '2026-06-19 11:26:16'),
(69, 1, 1, 1, 1, 'sales', 'sales_invoices', 46, 'SI/26-27/0018', '2026-04-17', NULL, 105, 'posted', '2026-06-19 11:29:17', NULL, NULL, NULL, 4, 4, '2026-06-19 11:29:17', '2026-06-19 11:29:17'),
(70, 1, 1, 1, 1, 'sales', 'sales_invoices', 47, 'SI/26-27/0019', '2026-04-17', NULL, 106, 'posted', '2026-06-19 11:32:01', NULL, NULL, NULL, 4, 4, '2026-06-19 11:32:01', '2026-06-19 11:32:01'),
(71, 1, 1, 1, 1, 'sales', 'sales_invoices', 48, 'SI/26-27/0020', '2026-04-17', NULL, 107, 'posted', '2026-06-19 11:34:10', NULL, NULL, NULL, 4, 4, '2026-06-19 11:34:10', '2026-06-19 11:34:10'),
(72, 1, 1, 1, 1, 'sales', 'sales_invoices', 49, 'SI/26-27/0021', '2026-04-20', NULL, 108, 'posted', '2026-06-19 11:40:27', NULL, NULL, NULL, 4, 4, '2026-06-19 11:40:27', '2026-06-19 11:40:27'),
(73, 1, 1, 1, 1, 'sales', 'sales_invoices', 50, 'SI/26-27/0022', '2026-04-21', NULL, 109, 'posted', '2026-06-19 11:47:14', NULL, NULL, NULL, 4, 4, '2026-06-19 11:47:14', '2026-06-19 11:47:14'),
(74, 1, 1, 1, 1, 'sales', 'sales_invoices', 51, 'SI/26-27/0023', '2026-04-28', NULL, 110, 'posted', '2026-06-19 11:50:25', NULL, NULL, NULL, 4, 4, '2026-06-19 11:50:25', '2026-06-19 11:50:25'),
(75, 1, 1, 1, 1, 'sales', 'sales_invoices', 52, 'SI/26-27/0024', '2026-04-28', NULL, 111, 'posted', '2026-06-19 12:05:09', NULL, NULL, NULL, 4, 4, '2026-06-19 12:05:09', '2026-06-19 12:05:09'),
(76, 1, 1, 1, 1, 'sales', 'sales_invoices', 53, 'SI/26-27/0025', '2026-04-28', NULL, 112, 'posted', '2026-06-19 12:07:15', NULL, NULL, NULL, 4, 4, '2026-06-19 12:07:15', '2026-06-19 12:07:15'),
(77, 1, 1, 1, 1, 'sales', 'sales_invoices', 54, 'SI/26-27/0026', '2026-04-29', NULL, 113, 'posted', '2026-06-19 12:28:45', NULL, NULL, NULL, 4, 4, '2026-06-19 12:28:45', '2026-06-19 12:28:45'),
(78, 1, 1, 1, 1, 'sales', 'sales_invoices', 55, 'SI/26-27/0027', '2026-04-30', NULL, 114, 'posted', '2026-06-19 12:30:26', NULL, NULL, NULL, 4, 4, '2026-06-19 12:30:26', '2026-06-19 12:30:26'),
(79, 1, 1, 1, 1, 'sales', 'sales_receipts', 21, 'SR/26-27/0001', '2026-04-01', NULL, 115, 'posted', '2026-06-19 12:43:55', NULL, NULL, NULL, 4, 4, '2026-06-19 12:43:55', '2026-06-19 12:43:55'),
(80, 1, 1, 1, 1, 'sales', 'sales_receipts', 22, 'SR/26-27/0002', '2026-04-02', NULL, 116, 'posted', '2026-06-20 05:04:25', NULL, NULL, NULL, 4, 4, '2026-06-20 05:04:25', '2026-06-20 05:04:25');

-- --------------------------------------------------------

--
-- Table structure for table `document_posting_lines`
--

CREATE TABLE `document_posting_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `document_posting_id` bigint UNSIGNED NOT NULL,
  `line_no` int NOT NULL,
  `account_id` bigint UNSIGNED NOT NULL,
  `entry_side` enum('debit','credit') COLLATE utf8mb4_unicode_ci NOT NULL,
  `amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `narration` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `source_amount_field` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `source_rule_id` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `document_posting_lines`
--

INSERT INTO `document_posting_lines` (`id`, `document_posting_id`, `line_no`, `account_id`, `entry_side`, `amount`, `narration`, `source_amount_field`, `source_rule_id`, `created_at`) VALUES
(131, 52, 1, 3, 'debit', 25193.00, 'Customer receivable', NULL, NULL, '2026-06-19 06:53:39'),
(132, 52, 2, 5, 'credit', 21350.00, 'Sales income', NULL, NULL, '2026-06-19 06:53:39'),
(133, 52, 3, 15, 'credit', 3843.00, 'Output tax payable', NULL, NULL, '2026-06-19 06:53:39'),
(134, 53, 1, 3, 'debit', 1463.00, 'Customer receivable', NULL, NULL, '2026-06-19 09:30:05'),
(135, 53, 2, 5, 'credit', 1240.00, 'Sales income', NULL, NULL, '2026-06-19 09:30:05'),
(136, 53, 3, 15, 'credit', 223.20, 'Output tax payable', NULL, NULL, '2026-06-19 09:30:05'),
(137, 53, 4, 12, 'debit', 0.20, 'Round off expense', NULL, NULL, '2026-06-19 09:30:05'),
(138, 54, 1, 3, 'debit', 56300.00, 'Customer receivable', NULL, NULL, '2026-06-19 09:34:59'),
(139, 54, 2, 5, 'credit', 47711.90, 'Sales income', NULL, NULL, '2026-06-19 09:34:59'),
(140, 54, 3, 15, 'credit', 8588.14, 'Output tax payable', NULL, NULL, '2026-06-19 09:34:59'),
(141, 54, 4, 12, 'debit', 0.04, 'Round off expense', NULL, NULL, '2026-06-19 09:34:59'),
(142, 55, 1, 3, 'debit', 5000.01, 'Customer receivable', NULL, NULL, '2026-06-19 09:38:01'),
(143, 55, 2, 5, 'credit', 4237.29, 'Sales income', NULL, NULL, '2026-06-19 09:38:01'),
(144, 55, 3, 15, 'credit', 762.72, 'Output tax payable', NULL, NULL, '2026-06-19 09:38:01'),
(145, 56, 1, 3, 'debit', 5320.00, 'Customer receivable', NULL, NULL, '2026-06-19 09:44:02'),
(146, 56, 2, 5, 'credit', 4508.47, 'Sales income', NULL, NULL, '2026-06-19 09:44:02'),
(147, 56, 3, 15, 'credit', 811.52, 'Output tax payable', NULL, NULL, '2026-06-19 09:44:02'),
(148, 56, 4, 7, 'credit', 0.01, 'Round off income', NULL, NULL, '2026-06-19 09:44:02'),
(149, 57, 1, 3, 'debit', 5200.00, 'Customer receivable', NULL, NULL, '2026-06-19 09:54:03'),
(150, 57, 2, 5, 'credit', 4406.78, 'Sales income', NULL, NULL, '2026-06-19 09:54:03'),
(151, 57, 3, 15, 'credit', 793.22, 'Output tax payable', NULL, NULL, '2026-06-19 09:54:03'),
(152, 58, 1, 3, 'debit', 10400.00, 'Customer receivable', NULL, NULL, '2026-06-19 10:00:44'),
(153, 58, 2, 5, 'credit', 8813.56, 'Sales income', NULL, NULL, '2026-06-19 10:00:44'),
(154, 58, 3, 15, 'credit', 1586.44, 'Output tax payable', NULL, NULL, '2026-06-19 10:00:44'),
(155, 59, 1, 3, 'debit', 5320.00, 'Customer receivable', NULL, NULL, '2026-06-19 10:28:29'),
(156, 59, 2, 5, 'credit', 4508.47, 'Sales income', NULL, NULL, '2026-06-19 10:28:29'),
(157, 59, 3, 15, 'credit', 811.52, 'Output tax payable', NULL, NULL, '2026-06-19 10:28:29'),
(158, 59, 4, 7, 'credit', 0.01, 'Round off income', NULL, NULL, '2026-06-19 10:28:29'),
(159, 60, 1, 3, 'debit', 5000.01, 'Customer receivable', NULL, NULL, '2026-06-19 10:30:51'),
(160, 60, 2, 5, 'credit', 4237.29, 'Sales income', NULL, NULL, '2026-06-19 10:30:51'),
(161, 60, 3, 15, 'credit', 762.72, 'Output tax payable', NULL, NULL, '2026-06-19 10:30:51'),
(162, 61, 1, 3, 'debit', 5840.00, 'Customer receivable', NULL, NULL, '2026-06-19 10:32:55'),
(163, 61, 2, 5, 'credit', 4949.15, 'Sales income', NULL, NULL, '2026-06-19 10:32:55'),
(164, 61, 3, 15, 'credit', 890.85, 'Output tax payable', NULL, NULL, '2026-06-19 10:32:55'),
(165, 62, 1, 3, 'debit', 29610.00, 'Customer receivable', NULL, NULL, '2026-06-19 10:47:22'),
(166, 62, 2, 5, 'credit', 25093.20, 'Sales income', NULL, NULL, '2026-06-19 10:47:22'),
(167, 62, 3, 15, 'credit', 4516.78, 'Output tax payable', NULL, NULL, '2026-06-19 10:47:22'),
(168, 62, 4, 7, 'credit', 0.02, 'Round off income', NULL, NULL, '2026-06-19 10:47:22'),
(169, 63, 1, 3, 'debit', 5840.01, 'Customer receivable', NULL, NULL, '2026-06-19 10:55:49'),
(170, 63, 2, 5, 'credit', 4949.15, 'Sales income', NULL, NULL, '2026-06-19 10:55:49'),
(171, 63, 3, 15, 'credit', 890.86, 'Output tax payable', NULL, NULL, '2026-06-19 10:55:49'),
(172, 64, 1, 3, 'debit', 5840.01, 'Customer receivable', NULL, NULL, '2026-06-19 10:59:38'),
(173, 64, 2, 5, 'credit', 4949.15, 'Sales income', NULL, NULL, '2026-06-19 10:59:38'),
(174, 64, 3, 15, 'credit', 890.86, 'Output tax payable', NULL, NULL, '2026-06-19 10:59:38'),
(175, 65, 1, 3, 'debit', 5700.01, 'Customer receivable', NULL, NULL, '2026-06-19 11:19:14'),
(176, 65, 2, 5, 'credit', 4830.51, 'Sales income', NULL, NULL, '2026-06-19 11:19:14'),
(177, 65, 3, 15, 'credit', 869.50, 'Output tax payable', NULL, NULL, '2026-06-19 11:19:14'),
(178, 66, 1, 3, 'debit', 5600.00, 'Customer receivable', NULL, NULL, '2026-06-19 11:20:56'),
(179, 66, 2, 5, 'credit', 4745.76, 'Sales income', NULL, NULL, '2026-06-19 11:20:56'),
(180, 66, 3, 15, 'credit', 854.24, 'Output tax payable', NULL, NULL, '2026-06-19 11:20:56'),
(181, 67, 1, 3, 'debit', 29210.00, 'Customer receivable', NULL, NULL, '2026-06-19 11:24:35'),
(182, 67, 2, 5, 'credit', 24754.24, 'Sales income', NULL, NULL, '2026-06-19 11:24:35'),
(183, 67, 3, 15, 'credit', 4455.76, 'Output tax payable', NULL, NULL, '2026-06-19 11:24:35'),
(184, 68, 1, 3, 'debit', 11400.00, 'Customer receivable', NULL, NULL, '2026-06-19 11:26:16'),
(185, 68, 2, 5, 'credit', 9661.02, 'Sales income', NULL, NULL, '2026-06-19 11:26:16'),
(186, 68, 3, 15, 'credit', 1738.98, 'Output tax payable', NULL, NULL, '2026-06-19 11:26:16'),
(187, 69, 1, 3, 'debit', 5700.01, 'Customer receivable', NULL, NULL, '2026-06-19 11:29:17'),
(188, 69, 2, 5, 'credit', 4830.51, 'Sales income', NULL, NULL, '2026-06-19 11:29:17'),
(189, 69, 3, 15, 'credit', 869.50, 'Output tax payable', NULL, NULL, '2026-06-19 11:29:17'),
(190, 70, 1, 3, 'debit', 6276.00, 'Customer receivable', NULL, NULL, '2026-06-19 11:32:01'),
(191, 70, 2, 5, 'credit', 5318.64, 'Sales income', NULL, NULL, '2026-06-19 11:32:01'),
(192, 70, 3, 15, 'credit', 957.36, 'Output tax payable', NULL, NULL, '2026-06-19 11:32:01'),
(193, 71, 1, 3, 'debit', 5840.01, 'Customer receivable', NULL, NULL, '2026-06-19 11:34:10'),
(194, 71, 2, 5, 'credit', 4949.15, 'Sales income', NULL, NULL, '2026-06-19 11:34:10'),
(195, 71, 3, 15, 'credit', 890.86, 'Output tax payable', NULL, NULL, '2026-06-19 11:34:10'),
(196, 72, 1, 3, 'debit', 5840.01, 'Customer receivable', NULL, NULL, '2026-06-19 11:40:27'),
(197, 72, 2, 5, 'credit', 4949.15, 'Sales income', NULL, NULL, '2026-06-19 11:40:27'),
(198, 72, 3, 15, 'credit', 890.86, 'Output tax payable', NULL, NULL, '2026-06-19 11:40:27'),
(199, 73, 1, 3, 'debit', 5840.01, 'Customer receivable', NULL, NULL, '2026-06-19 11:47:14'),
(200, 73, 2, 5, 'credit', 4949.15, 'Sales income', NULL, NULL, '2026-06-19 11:47:14'),
(201, 73, 3, 15, 'credit', 890.86, 'Output tax payable', NULL, NULL, '2026-06-19 11:47:14'),
(202, 74, 1, 3, 'debit', 5300.00, 'Customer receivable', NULL, NULL, '2026-06-19 11:50:25'),
(203, 74, 2, 5, 'credit', 4491.53, 'Sales income', NULL, NULL, '2026-06-19 11:50:25'),
(204, 74, 3, 15, 'credit', 808.48, 'Output tax payable', NULL, NULL, '2026-06-19 11:50:25'),
(205, 74, 4, 12, 'debit', 0.01, 'Round off expense', NULL, NULL, '2026-06-19 11:50:25'),
(206, 75, 1, 3, 'debit', 14160.00, 'Customer receivable', NULL, NULL, '2026-06-19 12:05:09'),
(207, 75, 2, 5, 'credit', 12000.00, 'Sales income', NULL, NULL, '2026-06-19 12:05:09'),
(208, 75, 3, 15, 'credit', 2160.00, 'Output tax payable', NULL, NULL, '2026-06-19 12:05:09'),
(209, 76, 1, 3, 'debit', 29210.00, 'Customer receivable', NULL, NULL, '2026-06-19 12:07:15'),
(210, 76, 2, 5, 'credit', 24754.24, 'Sales income', NULL, NULL, '2026-06-19 12:07:15'),
(211, 76, 3, 15, 'credit', 4455.76, 'Output tax payable', NULL, NULL, '2026-06-19 12:07:15'),
(212, 77, 1, 3, 'debit', 5840.01, 'Customer receivable', NULL, NULL, '2026-06-19 12:28:45'),
(213, 77, 2, 5, 'credit', 4949.15, 'Sales income', NULL, NULL, '2026-06-19 12:28:45'),
(214, 77, 3, 15, 'credit', 890.86, 'Output tax payable', NULL, NULL, '2026-06-19 12:28:45'),
(215, 78, 1, 3, 'debit', 5600.00, 'Customer receivable', NULL, NULL, '2026-06-19 12:30:26'),
(216, 78, 2, 5, 'credit', 4745.76, 'Sales income', NULL, NULL, '2026-06-19 12:30:26'),
(217, 78, 3, 15, 'credit', 854.24, 'Output tax payable', NULL, NULL, '2026-06-19 12:30:26'),
(218, 79, 1, 74, 'debit', 25193.00, 'Customer receipt cash/bank debit', NULL, NULL, '2026-06-19 12:43:55'),
(219, 79, 2, 3, 'credit', 25193.00, 'Customer receipt receivable credit', NULL, NULL, '2026-06-19 12:43:55'),
(220, 80, 1, 74, 'debit', 1463.00, 'Customer receipt cash/bank debit', NULL, NULL, '2026-06-20 05:04:25'),
(221, 80, 2, 3, 'credit', 1463.00, 'Customer receipt receivable credit', NULL, NULL, '2026-06-20 05:04:25');

-- --------------------------------------------------------

--
-- Table structure for table `document_series`
--

CREATE TABLE `document_series` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED DEFAULT NULL,
  `location_id` bigint UNSIGNED DEFAULT NULL,
  `financial_year_id` bigint UNSIGNED DEFAULT NULL,
  `document_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `series_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `prefix` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `suffix` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `next_number` bigint UNSIGNED NOT NULL DEFAULT '1',
  `number_length` int NOT NULL DEFAULT '5',
  `reset_policy` enum('never','financial_year','calendar_year','monthly') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'financial_year',
  `is_default` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `document_series`
--

INSERT INTO `document_series` (`id`, `company_id`, `branch_id`, `location_id`, `financial_year_id`, `document_type`, `series_name`, `prefix`, `suffix`, `next_number`, `number_length`, `reset_policy`, `is_default`, `is_active`, `remarks`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 1, 1, 'PARTY', 'Default PARTY', '', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:13:13'),
(2, 1, 1, 1, 1, 'SALES_QUOTATION', 'Default SALES QUOTATION', 'QT/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-06-10 23:55:36'),
(3, 1, 1, 1, 1, 'SALES_ORDER', 'Default SALES ORDER', 'SO/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-06-11 00:07:36'),
(4, 1, 1, 1, 1, 'DELIVERY_CHALLAN', 'Default DELIVERY CHALLAN', 'DC/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-06-11 00:08:41'),
(5, 1, 1, 1, 1, 'SALES_INVOICE', 'Default SALES INVOICE', 'SI/26-27/', '', 28, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-06-19 12:30:15'),
(6, 1, 1, 1, 1, 'SALES_RECEIPT', 'Default SALES RECEIPT', 'SR/26-27/', '', 3, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-06-20 05:04:17'),
(7, 1, 1, 1, 1, 'SALES_RETURN', 'Default SALES RETURN', 'SRT/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-06-09 00:29:50'),
(8, 1, 1, 1, 1, 'PURCHASE_REQUISITION', 'Default PURCHASE REQUISITION', 'PRQ/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-28 06:27:19'),
(9, 1, 1, 1, 1, 'PURCHASE_ORDER', 'Default PURCHASE ORDER', 'PO/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-06-12 00:59:28'),
(10, 1, 1, 1, 1, 'PURCHASE_RECEIPT', 'Default PURCHASE RECEIPT', 'GRN/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-06-10 00:54:42'),
(11, 1, 1, 1, 1, 'PURCHASE_INVOICE', 'Default PURCHASE INVOICE', 'PI/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-06-09 04:21:53'),
(12, 1, 1, 1, 1, 'PURCHASE_PAYMENT', 'Default PURCHASE PAYMENT', 'PP/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-06-08 00:42:47'),
(13, 1, 1, 1, 1, 'PURCHASE_RETURN', 'Default PURCHASE RETURN', 'PRT/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-06-08 02:00:25'),
(14, 1, 1, 1, 1, 'STOCK_OPENING', 'Default STOCK OPENING', 'OPN/26-27/', '', 3, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-06-19 09:28:39'),
(15, 1, 1, 1, 1, 'STOCK_ADJUSTMENT', 'Default STOCK ADJUSTMENT', 'ADJ/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:08:33'),
(16, 1, 1, 1, 1, 'STOCK_TRANSFER', 'Default STOCK TRANSFER', 'ST/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:07:34'),
(17, 1, 1, 1, 1, 'STOCK_ISSUE', 'Default STOCK ISSUE', 'ISS/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:08:04'),
(18, 1, 1, 1, 1, 'STOCK_RECEIPT_INTERNAL', 'Default STOCK RECEIPT INTERNAL', 'ISR/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:07:45'),
(19, 1, 1, 1, 1, 'STOCK_DAMAGE', 'Default STOCK DAMAGE', 'DMG/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:08:12'),
(20, 1, 1, 1, 1, 'STOCK_COUNT', 'Default STOCK COUNT', 'CNT/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:08:21'),
(21, 1, 1, 1, 1, 'BOM', 'Default BOM', 'BOM/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:15:25'),
(22, 1, 1, 1, 1, 'PRODUCTION_ORDER', 'Default PRODUCTION ORDER', 'PROD/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:11:36'),
(23, 1, 1, 1, 1, 'PRODUCTION_MATERIAL_ISSUE', 'Default PRODUCTION MATERIAL ISSUE', 'PMI/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:11:51'),
(24, 1, 1, 1, 1, 'PRODUCTION_RECEIPT', 'Default PRODUCTION RECEIPT', 'PRC/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:11:27'),
(25, 1, 1, 1, 1, 'JOBWORK_ORDER', 'Default JOBWORK ORDER', 'JWO/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-30 06:40:22'),
(26, 1, 1, 1, 1, 'JOBWORK_DISPATCH', 'Default JOBWORK DISPATCH', 'JWD/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:14:39'),
(27, 1, 1, 1, 1, 'JOBWORK_RECEIPT', 'Default JOBWORK RECEIPT', 'JWR/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:14:16'),
(28, 1, 1, 1, 1, 'JOBWORK_CHARGE', 'Default JOBWORK CHARGE', 'JWC/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:14:52'),
(29, 1, 1, 1, 1, 'QC_INSPECTION', 'Default QC INSPECTION', 'QCI/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:10:16'),
(30, 1, 1, 1, 1, 'MRP_RUN', 'Default MRP RUN', 'MRP/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:13:27'),
(31, 1, 1, 1, 1, 'SERVICE_CONTRACT', 'Default SERVICE CONTRACT', 'SCN/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:09:06'),
(32, 1, 1, 1, 1, 'SERVICE_TICKET', 'Default SERVICE TICKET', 'STK/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:08:53'),
(33, 1, 1, 1, 1, 'SERVICE_WORK_ORDER', 'Default SERVICE WORK ORDER', 'SWO/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:08:44'),
(34, 1, 1, 1, 1, 'MAINTENANCE_REQUEST', 'Default MAINTENANCE REQUEST', 'MTR/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:13:48'),
(35, 1, 1, 1, 1, 'MAINTENANCE_WORK_ORDER', 'Default MAINTENANCE WORK ORDER', 'MWO/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:13:39'),
(36, 1, 1, 1, 1, 'AMC_CONTRACT', 'Default AMC CONTRACT', 'AMC/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:16:25'),
(37, 1, 1, 1, 1, 'ASSET_DEPRECIATION_RUN', 'Default ASSET DEPRECIATION RUN', 'ADR/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:16:13'),
(38, 1, 1, 1, 1, 'ASSET_TRANSFER', 'Default ASSET TRANSFER', 'ATR/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:15:35'),
(39, 1, 1, 1, 1, 'ASSET_DISPOSAL', 'Default ASSET DISPOSAL', 'ADP/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:16:03'),
(40, 1, 1, 1, 1, 'PAYMENT_VOUCHER', 'Default PAYMENT VOUCHER', 'PV/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-06-10 00:32:59'),
(41, 1, 1, 1, 1, 'RECEIPT_VOUCHER', 'Default RECEIPT VOUCHER', 'RV/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-06-10 00:33:37'),
(42, 1, 1, 1, 1, 'JOURNAL_VOUCHER', 'Default JOURNAL VOUCHER', 'JV/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:14:02'),
(43, 1, 1, 1, 1, 'CONTRA_VOUCHER', 'Default CONTRA VOUCHER', 'CV/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:15:13'),
(44, 1, 1, 1, 1, 'PAYSLIP', 'Default PAYSLIP', 'PS/26-27/', '', 1, 4, 'financial_year', 1, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-07 23:12:03'),
(45, 1, NULL, NULL, 1, 'DELIVERY_CHALLAN', 'RETURNABLE DELIVERY CHALLAN', 'RDC/26-27/', NULL, 1, 4, 'financial_year', 0, 1, NULL, NULL, NULL, '2026-05-29 06:07:03', '2026-05-29 06:33:30');

-- --------------------------------------------------------

--
-- Table structure for table `document_tax_lines`
--

CREATE TABLE `document_tax_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_module` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `document_table` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `document_id` bigint UNSIGNED NOT NULL,
  `document_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `document_date` date NOT NULL,
  `line_table` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `line_id` bigint UNSIGNED DEFAULT NULL,
  `item_id` bigint UNSIGNED DEFAULT NULL,
  `tax_code_id` bigint UNSIGNED DEFAULT NULL,
  `hsn_sac_code` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `taxable_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `cgst_percent` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `cgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `sgst_percent` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `sgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `igst_percent` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `igst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `cess_percent` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `cess_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `tax_application` enum('cgst_sgst','igst','cess_only','exempt','nil_rated','non_gst') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'cgst_sgst',
  `reverse_charge_applicable` tinyint(1) NOT NULL DEFAULT '0',
  `input_tax_credit_allowed` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `document_tax_lines`
--

INSERT INTO `document_tax_lines` (`id`, `company_id`, `branch_id`, `location_id`, `financial_year_id`, `document_module`, `document_table`, `document_id`, `document_no`, `document_date`, `line_table`, `line_id`, `item_id`, `tax_code_id`, `hsn_sac_code`, `taxable_amount`, `cgst_percent`, `cgst_amount`, `sgst_percent`, `sgst_amount`, `igst_percent`, `igst_amount`, `cess_percent`, `cess_amount`, `tax_application`, `reverse_charge_applicable`, `input_tax_credit_allowed`, `created_at`) VALUES
(115, 1, 1, 1, 1, 'sales', 'sales_invoices', 29, 'SI/26-27/0001', '2026-06-19', 'sales_invoice_lines', 47, 3, 4, '91091010', 21000.00, 0.0000, 0.00, 0.0000, 0.00, 18.0000, 3780.00, 0.0000, 0.00, 'igst', 0, 0, '2026-06-19 06:53:39'),
(116, 1, 1, 1, 1, 'sales', 'sales_invoices', 29, 'SI/26-27/0001', '2026-06-19', 'sales_invoice_lines', 48, 32, 4, '996819', 350.00, 0.0000, 0.00, 0.0000, 0.00, 18.0000, 63.00, 0.0000, 0.00, 'igst', 0, 0, '2026-06-19 06:53:39'),
(118, 1, 1, 1, 1, 'sales', 'sales_invoices', 30, 'SI/26-27/0002', '2026-04-02', 'sales_invoice_lines', 49, 6, 4, '38101010', 1240.00, 9.0000, 111.60, 9.0000, 111.60, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 09:30:05'),
(121, 1, 1, 1, 1, 'sales', 'sales_invoices', 31, 'SI/26-27/0003', '2026-04-02', 'sales_invoice_lines', 51, 3, 4, '91091010', 47711.90, 0.0000, 0.00, 0.0000, 0.00, 18.0000, 8588.14, 0.0000, 0.00, 'igst', 0, 0, '2026-06-19 09:34:59'),
(123, 1, 1, 1, 1, 'sales', 'sales_invoices', 32, 'SI/26-27/0004', '2026-04-03', 'sales_invoice_lines', 52, 3, 4, '91091010', 4237.29, 9.0000, 381.36, 9.0000, 381.36, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 09:38:01'),
(125, 1, 1, 1, 1, 'sales', 'sales_invoices', 33, 'SI/26-27/0005', '2026-04-03', 'sales_invoice_lines', 53, 3, 4, '91091010', 4508.47, 9.0000, 405.76, 9.0000, 405.76, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 09:44:02'),
(128, 1, 1, 1, 1, 'sales', 'sales_invoices', 34, 'SI/26-27/0006', '2026-04-04', 'sales_invoice_lines', 55, 3, 4, '91091010', 4406.78, 9.0000, 396.61, 9.0000, 396.61, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 09:54:03'),
(132, 1, 1, 1, 1, 'sales', 'sales_invoices', 35, 'SI/26-27/0007', '2026-04-06', 'sales_invoice_lines', 58, 3, 4, '91091010', 8813.56, 9.0000, 793.22, 9.0000, 793.22, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 10:00:44'),
(134, 1, 1, 1, 1, 'sales', 'sales_invoices', 36, 'SI/26-27/0008', '2026-04-06', 'sales_invoice_lines', 59, 3, 4, '91091010', 4508.47, 9.0000, 405.76, 9.0000, 405.76, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 10:28:29'),
(136, 1, 1, 1, 1, 'sales', 'sales_invoices', 37, 'SI/26-27/0009', '2026-04-06', 'sales_invoice_lines', 60, 3, 4, '91091010', 4237.29, 9.0000, 381.36, 9.0000, 381.36, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 10:30:51'),
(139, 1, 1, 1, 1, 'sales', 'sales_invoices', 38, 'SI/26-27/0010', '2026-04-07', 'sales_invoice_lines', 61, 3, 4, '91091010', 4830.51, 0.0000, 0.00, 0.0000, 0.00, 18.0000, 869.49, 0.0000, 0.00, 'igst', 0, 0, '2026-06-19 10:32:55'),
(140, 1, 1, 1, 1, 'sales', 'sales_invoices', 38, 'SI/26-27/0010', '2026-04-07', 'sales_invoice_lines', 62, 32, 4, '996819', 118.64, 0.0000, 0.00, 0.0000, 0.00, 18.0000, 21.36, 0.0000, 0.00, 'igst', 0, 0, '2026-06-19 10:32:55'),
(143, 1, 1, 1, 1, 'sales', 'sales_invoices', 39, 'SI/26-27/0011', '2026-04-08', 'sales_invoice_lines', 63, 3, 4, '91091010', 24500.00, 9.0000, 2205.00, 9.0000, 2205.00, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 10:47:22'),
(144, 1, 1, 1, 1, 'sales', 'sales_invoices', 39, 'SI/26-27/0011', '2026-04-08', 'sales_invoice_lines', 64, 32, 4, '996819', 593.20, 9.0000, 53.39, 9.0000, 53.39, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 10:47:22'),
(147, 1, 1, 1, 1, 'sales', 'sales_invoices', 40, 'SI/26-27/0012', '2026-04-08', 'sales_invoice_lines', 65, 3, 4, '91091010', 4830.51, 9.0000, 434.75, 9.0000, 434.75, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 10:55:49'),
(148, 1, 1, 1, 1, 'sales', 'sales_invoices', 40, 'SI/26-27/0012', '2026-04-08', 'sales_invoice_lines', 66, 32, 4, '996819', 118.64, 9.0000, 10.68, 9.0000, 10.68, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 10:55:49'),
(151, 1, 1, 1, 1, 'sales', 'sales_invoices', 41, 'SI/26-27/0013', '2026-04-10', 'sales_invoice_lines', 67, 3, 4, '91091010', 4830.51, 9.0000, 434.75, 9.0000, 434.75, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 10:59:38'),
(152, 1, 1, 1, 1, 'sales', 'sales_invoices', 41, 'SI/26-27/0013', '2026-04-10', 'sales_invoice_lines', 68, 32, 4, '996819', 118.64, 9.0000, 10.68, 9.0000, 10.68, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 10:59:38'),
(154, 1, 1, 1, 1, 'sales', 'sales_invoices', 42, 'SI/26-27/0014', '2026-04-11', 'sales_invoice_lines', 69, 3, 4, '91091010', 4830.51, 9.0000, 434.75, 9.0000, 434.75, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 11:19:15'),
(156, 1, 1, 1, 1, 'sales', 'sales_invoices', 43, 'SI/26-27/0015', '2026-04-13', 'sales_invoice_lines', 70, 3, 4, '91091010', 4745.76, 9.0000, 427.12, 9.0000, 427.12, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 11:20:56'),
(159, 1, 1, 1, 1, 'sales', 'sales_invoices', 44, 'SI/26-27/0016', '2026-04-15', 'sales_invoice_lines', 71, 3, 4, '91091010', 24500.00, 0.0000, 0.00, 0.0000, 0.00, 18.0000, 4410.00, 0.0000, 0.00, 'igst', 0, 0, '2026-06-19 11:24:35'),
(160, 1, 1, 1, 1, 'sales', 'sales_invoices', 44, 'SI/26-27/0016', '2026-04-15', 'sales_invoice_lines', 72, 32, 4, '996819', 254.24, 0.0000, 0.00, 0.0000, 0.00, 18.0000, 45.76, 0.0000, 0.00, 'igst', 0, 0, '2026-06-19 11:24:35'),
(162, 1, 1, 1, 1, 'sales', 'sales_invoices', 45, 'SI/26-27/0017', '2026-04-16', 'sales_invoice_lines', 73, 3, 4, '91091010', 9661.02, 9.0000, 869.49, 9.0000, 869.49, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 11:26:16'),
(164, 1, 1, 1, 1, 'sales', 'sales_invoices', 46, 'SI/26-27/0018', '2026-04-17', 'sales_invoice_lines', 74, 3, 4, '91091010', 4830.51, 9.0000, 434.75, 9.0000, 434.75, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 11:29:17'),
(166, 1, 1, 1, 1, 'sales', 'sales_invoices', 47, 'SI/26-27/0019', '2026-04-17', 'sales_invoice_lines', 75, 3, 4, '91091010', 5318.64, 9.0000, 478.68, 9.0000, 478.68, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 11:32:01'),
(169, 1, 1, 1, 1, 'sales', 'sales_invoices', 48, 'SI/26-27/0020', '2026-04-17', 'sales_invoice_lines', 76, 3, 4, '91091010', 4830.51, 9.0000, 434.75, 9.0000, 434.75, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 11:34:10'),
(170, 1, 1, 1, 1, 'sales', 'sales_invoices', 48, 'SI/26-27/0020', '2026-04-17', 'sales_invoice_lines', 77, 32, 4, '996819', 118.64, 9.0000, 10.68, 9.0000, 10.68, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 11:34:10'),
(175, 1, 1, 1, 1, 'sales', 'sales_invoices', 49, 'SI/26-27/0021', '2026-04-20', 'sales_invoice_lines', 80, 3, 4, '91091010', 4830.51, 9.0000, 434.75, 9.0000, 434.75, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 11:40:27'),
(176, 1, 1, 1, 1, 'sales', 'sales_invoices', 49, 'SI/26-27/0021', '2026-04-20', 'sales_invoice_lines', 81, 32, 4, '996819', 118.64, 9.0000, 10.68, 9.0000, 10.68, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 11:40:27'),
(179, 1, 1, 1, 1, 'sales', 'sales_invoices', 50, 'SI/26-27/0022', '2026-04-21', 'sales_invoice_lines', 82, 3, 4, '91091010', 4830.51, 9.0000, 434.75, 9.0000, 434.75, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 11:47:14'),
(180, 1, 1, 1, 1, 'sales', 'sales_invoices', 50, 'SI/26-27/0022', '2026-04-21', 'sales_invoice_lines', 83, 32, 4, '996819', 118.64, 9.0000, 10.68, 9.0000, 10.68, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 11:47:14'),
(182, 1, 1, 1, 1, 'sales', 'sales_invoices', 51, 'SI/26-27/0023', '2026-04-28', 'sales_invoice_lines', 84, 3, 4, '91091010', 4491.53, 9.0000, 404.24, 9.0000, 404.24, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 11:50:25'),
(184, 1, 1, 1, 1, 'sales', 'sales_invoices', 52, 'SI/26-27/0024', '2026-04-28', 'sales_invoice_lines', 85, 3, 4, '91091010', 12000.00, 0.0000, 0.00, 0.0000, 0.00, 18.0000, 2160.00, 0.0000, 0.00, 'igst', 0, 0, '2026-06-19 12:05:09'),
(187, 1, 1, 1, 1, 'sales', 'sales_invoices', 53, 'SI/26-27/0025', '2026-04-28', 'sales_invoice_lines', 86, 3, 4, '91091010', 24500.00, 0.0000, 0.00, 0.0000, 0.00, 18.0000, 4410.00, 0.0000, 0.00, 'igst', 0, 0, '2026-06-19 12:07:15'),
(188, 1, 1, 1, 1, 'sales', 'sales_invoices', 53, 'SI/26-27/0025', '2026-04-28', 'sales_invoice_lines', 87, 32, 4, '996819', 254.24, 0.0000, 0.00, 0.0000, 0.00, 18.0000, 45.76, 0.0000, 0.00, 'igst', 0, 0, '2026-06-19 12:07:15'),
(191, 1, 1, 1, 1, 'sales', 'sales_invoices', 54, 'SI/26-27/0026', '2026-04-29', 'sales_invoice_lines', 88, 3, 4, '91091010', 4830.51, 9.0000, 434.75, 9.0000, 434.75, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 12:28:45'),
(192, 1, 1, 1, 1, 'sales', 'sales_invoices', 54, 'SI/26-27/0026', '2026-04-29', 'sales_invoice_lines', 89, 32, 4, '996819', 118.64, 9.0000, 10.68, 9.0000, 10.68, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 12:28:45'),
(194, 1, 1, 1, 1, 'sales', 'sales_invoices', 55, 'SI/26-27/0027', '2026-04-30', 'sales_invoice_lines', 90, 3, 4, '91091010', 4745.76, 9.0000, 427.12, 9.0000, 427.12, 0.0000, 0.00, 0.0000, 0.00, 'cgst_sgst', 0, 0, '2026-06-19 12:30:26');

-- --------------------------------------------------------

--
-- Table structure for table `email_messages`
--

CREATE TABLE `email_messages` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED DEFAULT NULL,
  `email_setting_id` bigint UNSIGNED DEFAULT NULL,
  `email_template_id` bigint UNSIGNED DEFAULT NULL,
  `email_rule_id` bigint UNSIGNED DEFAULT NULL,
  `module` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `document_type` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `document_id` bigint UNSIGNED DEFAULT NULL,
  `event_code` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `trigger_mode` enum('manual','auto') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'manual',
  `recipient_to` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `recipient_cc` text COLLATE utf8mb4_unicode_ci,
  `recipient_bcc` text COLLATE utf8mb4_unicode_ci,
  `subject` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `body` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_html` tinyint(1) NOT NULL DEFAULT '1',
  `status` enum('queued','sent','failed','skipped') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'queued',
  `error_message` text COLLATE utf8mb4_unicode_ci,
  `sent_at` datetime DEFAULT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `email_module_settings`
--

CREATE TABLE `email_module_settings` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED DEFAULT NULL,
  `module` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `document_type` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `auto_email_enabled` tinyint(1) NOT NULL DEFAULT '1',
  `manual_email_enabled` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `email_rules`
--

CREATE TABLE `email_rules` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED DEFAULT NULL,
  `rule_code` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `rule_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `module` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `document_type` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `event_code` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `template_id` bigint UNSIGNED DEFAULT NULL,
  `auto_enabled` tinyint(1) NOT NULL DEFAULT '1',
  `manual_enabled` tinyint(1) NOT NULL DEFAULT '1',
  `send_to_party_email` tinyint(1) NOT NULL DEFAULT '0',
  `send_to_contact_email` tinyint(1) NOT NULL DEFAULT '0',
  `send_to_assigned_user` tinyint(1) NOT NULL DEFAULT '0',
  `send_to_owner_user` tinyint(1) NOT NULL DEFAULT '0',
  `recipient_emails` text COLLATE utf8mb4_unicode_ci,
  `cc_emails` text COLLATE utf8mb4_unicode_ci,
  `bcc_emails` text COLLATE utf8mb4_unicode_ci,
  `subject_override` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `body_override` mediumtext COLLATE utf8mb4_unicode_ci,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `email_settings`
--

CREATE TABLE `email_settings` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED DEFAULT NULL,
  `setting_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `mail_driver` enum('disabled','log','mail') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'log',
  `from_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `from_email` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `reply_to_email` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `smtp_host` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `smtp_port` int DEFAULT NULL,
  `smtp_encryption` enum('tls','ssl','none') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `smtp_username` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `smtp_password` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `auto_email_enabled` tinyint(1) NOT NULL DEFAULT '1',
  `is_default` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `email_templates`
--

CREATE TABLE `email_templates` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED DEFAULT NULL,
  `template_code` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `template_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `module` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `document_type` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `event_code` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `subject_template` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `body_template` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_html` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `employees`
--

CREATE TABLE `employees` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `employee_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employee_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `department_id` bigint UNSIGNED DEFAULT NULL,
  `designation_id` bigint UNSIGNED DEFAULT NULL,
  `mobile` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `joining_date` date DEFAULT NULL,
  `relieving_date` date DEFAULT NULL,
  `employment_type` enum('permanent','contract','trainee','intern') COLLATE utf8mb4_unicode_ci DEFAULT 'permanent',
  `status` enum('active','inactive','terminated') COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `salary_mode` enum('monthly','daily','hourly') COLLATE utf8mb4_unicode_ci DEFAULT 'monthly',
  `bank_account_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ifsc_code` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `profile_photo_path` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `esi_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pf_uan_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pf_account_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `passport_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `passport_issue_date` date DEFAULT NULL,
  `passport_expiry_date` date DEFAULT NULL,
  `passport_place_of_issue` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `personal_insurance_provider` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `personal_insurance_policy_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `personal_insurance_amount` decimal(18,2) DEFAULT NULL,
  `company_insurance_provider` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `company_insurance_policy_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `company_insurance_amount` decimal(18,2) DEFAULT NULL,
  `cost_center_id` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `employees`
--

INSERT INTO `employees` (`id`, `company_id`, `employee_code`, `employee_name`, `department_id`, `designation_id`, `mobile`, `email`, `joining_date`, `relieving_date`, `employment_type`, `status`, `salary_mode`, `bank_account_no`, `ifsc_code`, `profile_photo_path`, `esi_no`, `pf_uan_no`, `pf_account_no`, `passport_no`, `passport_issue_date`, `passport_expiry_date`, `passport_place_of_issue`, `personal_insurance_provider`, `personal_insurance_policy_no`, `personal_insurance_amount`, `company_insurance_provider`, `company_insurance_policy_no`, `company_insurance_amount`, `cost_center_id`, `created_at`) VALUES
(4, 1, 'EMP/00001', 'Pavithra L', 2, 17, '9345769647', 'pavithral@sakthicontroller.com', '2026-03-06', NULL, 'trainee', 'active', 'monthly', '6860015527', 'IDIB000D003', NULL, '5138293153', '102309890067', '102309890067', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-05-07 03:20:49'),
(5, 1, 'EMP/00002', 'Gokul M', 10, 16, '9344109615', 'gokulm@sakthicontroller.com', '2024-11-20', NULL, 'permanent', 'active', 'monthly', '924010066953856', 'UTIB0003451', NULL, '5136862338', '102148154021', '102148154021', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-05-07 03:27:34'),
(6, 1, 'EMP/00003', 'Rithish B', 6, 14, '9361486176', 'rithishbm2004@gmail.com', '2025-04-15', NULL, 'permanent', 'active', 'monthly', '42558591904', 'SBIN0007126', NULL, '5135139837', '102000550826', '102000550826', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-05-07 04:19:08'),
(7, 1, 'EMP/00004', 'Pooja S', 10, 18, '6374913971', 'poojas@sakthicontroller.com', '2026-03-02', NULL, 'trainee', 'active', 'monthly', '7377651635', 'IDIB0004198', NULL, '5138293214', '102308135609', '102308135609', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-05-07 04:19:18'),
(8, 1, 'EMP/00005', 'Meena Muruganantham', 6, 14, '7449061947', 'meena.v7449@gmail.com', '2025-07-15', NULL, 'permanent', 'active', 'monthly', '032100050311998', 'BZHPV9768D', NULL, '5137634041', '102231792177', '102231792177', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-05-07 04:20:42'),
(9, 1, 'EMP/00006', 'Balaji Velan', 13, 15, '9994238228', 'balaji@sakthicontroller.com', '2023-09-25', NULL, 'permanent', 'active', 'monthly', '922010063693562', 'UTIB0002823', NULL, '5136656674', '101206940033', '101206940033', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-05-07 04:21:15'),
(10, 1, 'EMP/00007', 'Vijayaragav L.G', 12, 12, '9043162339', 'vijayaragav@sakthicontroller.com', '2025-09-15', NULL, 'permanent', 'active', 'monthly', '1788155000038891', 'KVBL0001788', NULL, '5137975109', '102251759575', '102251759575', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-05-07 04:22:00'),
(11, 1, 'EMP/00008', 'Dinesh Kumar S', 6, 14, '9344360234', 'kumarlskumarls@gmail.com', '2024-02-02', NULL, 'permanent', 'active', 'monthly', '923010058893279', 'UTIBB0002823', NULL, '5136662046', '100441996970', '100441996970', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-05-07 04:22:29'),
(12, 1, 'EMP/00009', 'Mithra S', 11, 13, '9597773302', 'mithra@sakthicontroller.com', '2023-01-19', NULL, 'permanent', 'active', 'monthly', '1737155000028382', 'KVBL0001737', NULL, '51366656302', '102126998361', '102126998361', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-05-07 04:22:45'),
(13, 1, 'EMP/00010', 'Balaji P', 12, 12, '7010653789', 'balajip@sakthicontroller.com', '2025-09-01', NULL, 'permanent', 'active', 'monthly', '7132874048', 'IDIB000P236', NULL, '5137777771', '102242722879', '102242722879', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-05-07 04:23:00'),
(14, 1, 'EMP/00011', 'Gokul S', 12, 12, '6383551162', 'gokuls@sakthicontroller.com', '2024-09-11', NULL, 'permanent', 'active', 'monthly', '924010049557372', 'UTIB0000523', NULL, '5136661543', '102126998357', '102126998357', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-05-07 04:24:32'),
(15, 1, 'EMP/00012', 'Siva M', 11, 11, '9442060203', 'siva@sakthicontroller.com', '2023-01-19', NULL, 'permanent', 'active', 'monthly', NULL, NULL, NULL, '5136661631', '102126994739', '102126994739', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-05-07 04:25:26'),
(16, 1, 'EMP/00013', 'Kamaraj G', 6, 10, '9442677861', 'kamaraj@sakthicontroller.com', '2023-02-01', NULL, 'permanent', 'active', 'monthly', '923010058893305', 'UTIB0002823', NULL, '5136657880', '102126994741', '102126994741', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-05-07 04:32:46'),
(17, 1, 'EMP/00014', 'Elakkiya Shanmugam', 12, 9, '8608074597', 'elakkiya@sakthicontroller.com', '2024-02-12', NULL, 'permanent', 'active', 'monthly', '923010058892988', 'UTIB0002823', NULL, '5348967026', '101979827561', '101979827561', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-05-07 04:33:19'),
(18, 1, 'EMP/00015', 'Janarthanam A', 11, 8, '9443023497', 'jana@sakthicontroller.com', '2025-07-15', NULL, 'permanent', 'active', 'monthly', '168010100212434', 'UTIB0004264', NULL, '5136662008', '100944735902', '100944735902', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-05-07 04:33:48'),
(19, 1, 'EMP/00016', 'Yuvaraj Palani', 3, 19, '7904284246', 'yuvaraj@sakthicontroller.com', '2026-05-04', NULL, 'permanent', 'active', 'monthly', '924010049703025', 'UTIB0003451', NULL, '5136661396', '101339239732', '101339239732', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-05-07 23:48:37');

-- --------------------------------------------------------

--
-- Table structure for table `employee_accounts`
--

CREATE TABLE `employee_accounts` (
  `id` bigint UNSIGNED NOT NULL,
  `employee_id` bigint UNSIGNED NOT NULL,
  `account_id` bigint UNSIGNED NOT NULL,
  `account_purpose` enum('payable','advance','reimbursement','other') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'payable',
  `is_default` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `employee_accounts`
--

INSERT INTO `employee_accounts` (`id`, `employee_id`, `account_id`, `account_purpose`, `is_default`, `is_active`, `created_at`, `updated_at`) VALUES
(3, 4, 40, 'payable', 1, 1, '2026-05-07 03:20:49', '2026-05-07 03:20:49'),
(4, 4, 41, 'reimbursement', 1, 1, '2026-05-07 03:20:49', '2026-05-07 03:20:49'),
(5, 5, 42, 'payable', 1, 1, '2026-05-07 03:27:34', '2026-05-07 03:27:34'),
(6, 5, 43, 'reimbursement', 1, 1, '2026-05-07 03:27:34', '2026-05-07 03:27:34'),
(7, 6, 44, 'payable', 1, 1, '2026-05-07 04:19:08', '2026-05-07 04:19:08'),
(8, 6, 45, 'reimbursement', 1, 1, '2026-05-07 04:19:08', '2026-05-07 04:19:08'),
(9, 7, 46, 'payable', 1, 1, '2026-05-07 04:19:18', '2026-05-07 04:19:18'),
(10, 7, 47, 'reimbursement', 1, 1, '2026-05-07 04:19:18', '2026-05-07 04:19:18'),
(11, 8, 48, 'payable', 1, 1, '2026-05-07 04:20:42', '2026-05-07 04:20:42'),
(12, 8, 49, 'reimbursement', 1, 1, '2026-05-07 04:20:42', '2026-05-07 04:20:42'),
(13, 9, 50, 'payable', 1, 1, '2026-05-07 04:21:15', '2026-05-07 04:21:15'),
(14, 9, 51, 'reimbursement', 1, 1, '2026-05-07 04:21:15', '2026-05-07 04:21:15'),
(15, 10, 52, 'payable', 1, 1, '2026-05-07 04:22:00', '2026-05-07 04:22:00'),
(16, 10, 53, 'reimbursement', 1, 1, '2026-05-07 04:22:00', '2026-05-07 04:22:00'),
(17, 11, 54, 'payable', 1, 1, '2026-05-07 04:22:29', '2026-05-07 04:22:29'),
(18, 11, 55, 'reimbursement', 1, 1, '2026-05-07 04:22:29', '2026-05-07 04:22:29'),
(19, 12, 56, 'payable', 1, 1, '2026-05-07 04:22:45', '2026-05-07 04:22:45'),
(20, 12, 57, 'reimbursement', 1, 1, '2026-05-07 04:22:45', '2026-05-07 04:22:45'),
(21, 13, 58, 'payable', 1, 1, '2026-05-07 04:23:00', '2026-05-07 04:23:00'),
(22, 13, 59, 'reimbursement', 1, 1, '2026-05-07 04:23:00', '2026-05-07 04:23:00'),
(23, 14, 60, 'payable', 1, 1, '2026-05-07 04:24:32', '2026-05-07 04:24:32'),
(24, 14, 61, 'reimbursement', 1, 1, '2026-05-07 04:24:32', '2026-05-07 04:24:32'),
(25, 15, 62, 'payable', 1, 1, '2026-05-07 04:25:26', '2026-05-07 04:25:26'),
(26, 15, 63, 'reimbursement', 1, 1, '2026-05-07 04:25:26', '2026-05-07 04:25:26'),
(27, 16, 64, 'payable', 1, 1, '2026-05-07 04:32:46', '2026-05-07 04:32:46'),
(28, 16, 65, 'reimbursement', 1, 1, '2026-05-07 04:32:46', '2026-05-07 04:32:46'),
(29, 17, 66, 'payable', 1, 1, '2026-05-07 04:33:19', '2026-05-07 04:33:19'),
(30, 17, 67, 'reimbursement', 1, 1, '2026-05-07 04:33:19', '2026-05-07 04:33:19'),
(31, 18, 68, 'payable', 1, 1, '2026-05-07 04:33:48', '2026-05-07 04:33:48'),
(32, 18, 69, 'reimbursement', 1, 1, '2026-05-07 04:33:48', '2026-05-07 04:33:48'),
(33, 19, 70, 'payable', 1, 1, '2026-05-07 23:48:37', '2026-05-07 23:48:37'),
(34, 19, 71, 'reimbursement', 1, 1, '2026-05-07 23:48:37', '2026-05-07 23:48:37');

-- --------------------------------------------------------

--
-- Table structure for table `employee_addresses`
--

CREATE TABLE `employee_addresses` (
  `id` bigint UNSIGNED NOT NULL,
  `employee_id` bigint UNSIGNED NOT NULL,
  `address_type` enum('present','permanent') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'present',
  `address_line1` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address_line2` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `landmark` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `state_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `postal_code` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `country` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `employee_addresses`
--

INSERT INTO `employee_addresses` (`id`, `employee_id`, `address_type`, `address_line1`, `address_line2`, `landmark`, `city`, `state_name`, `postal_code`, `country`, `phone_number`, `created_at`, `updated_at`) VALUES
(142, 13, 'permanent', 'No. 121 ,School Street , Kuppathamottur Village ,Ammundi Post ,Sugarmill Via', '', 'Katpadi Taluk ,', 'Vellore', 'Tamil Nadu', '632519', 'India', '7010653789', '2026-05-12 01:18:38', '2026-05-12 01:18:38'),
(145, 14, 'permanent', '2/BA ,Pillaiyar Kovil Street ,Vazhvankundram ,kothamagalam post ,', '', 'K.V Kuppam Taluk ,', 'Vellore', 'Tamil Nadu', '632104', 'Tamil Nadu', '6383551162', '2026-05-12 01:20:16', '2026-05-12 01:20:16'),
(147, 5, 'permanent', '272,Gollamangalam,Guduyatham(tk),', '', '', 'Vellore', 'Tamil Nadu', '635809', 'India', '9344109615', '2026-05-12 01:21:01', '2026-05-12 01:21:01'),
(156, 7, 'permanent', 'No.2/248A,Thiruvalluvar Nagar,Kamarajar Nagar Ariyur', '', '', 'Vellore', 'Tamil Nadu', '632055', 'India', '6374913979', '2026-05-12 01:27:13', '2026-05-12 01:27:13'),
(164, 9, 'permanent', '10, Eswaran Kovil Street, Shenbakkam,', '', '', 'Vellore', 'Tamil Nadu', '632008', 'India', '9994238228', '2026-05-12 01:37:50', '2026-05-12 01:37:50'),
(177, 17, 'permanent', 'No,26/12A3,State Bank Quarters Back Side', '', 'Thermal 4 Roads ,Mettur Dam.', 'SALEM', 'TAMIL NADU', '636201', 'INDIA', '8608074597', '2026-05-12 02:02:48', '2026-05-12 02:02:48'),
(185, 19, 'permanent', '1/20, Chinnakukkndi, M.G.R.Nagar, Arcot(tk),', '', '', 'Ranipet', 'Tamil Nadu', '632503', 'India', '7904284246', '2026-05-13 06:29:27', '2026-05-13 06:29:27'),
(187, 16, 'permanent', '1/215, Eswaran Kovil St, Veppur,', '', 'Visharam(po),', 'Ranipet', 'Tamil Nadu', '632509', 'India', '9442677861', '2026-05-13 06:37:06', '2026-05-13 06:37:06'),
(198, 18, 'permanent', '10/3, Kalainagar St, Pulavar Nagar, Rangapuram,', '', '', 'Vellore', 'Tamil Nadu', '632009', 'India', '8220209026', '2026-05-13 23:49:35', '2026-05-13 23:49:35'),
(205, 12, 'permanent', 'No.73, Phase 3 St, Vaibhav Nagar,  Katpadi', '', 'VIT-Post', 'Vellore', 'Tamil Nadu', '632006', 'India', '9597773302', '2026-05-13 23:52:16', '2026-05-13 23:52:16'),
(213, 11, 'permanent', '1/92 Ramer Kovil Street ,  Mahimandalam ,', '', 'Melpodinathm ,', 'Vellore', 'Tamil Nadu', '632516', 'India', '9344360234', '2026-05-13 23:57:49', '2026-05-13 23:57:49'),
(215, 10, 'permanent', '4/40, Barathiyar St, Arapakkam, Puttuthakku(po),', '', '', 'Raniprt', 'Tamil Nadu', '632517', 'India', '9043162339', '2026-05-13 23:58:59', '2026-05-13 23:58:59'),
(223, 8, 'permanent', '12, Jegajothi Nagar, Rangapuram,Eriyur,', '', '', 'Vellore', 'Tamil Nadu', '632009', 'India', '7449061947', '2026-05-14 00:04:50', '2026-05-14 00:04:50'),
(235, 6, 'permanent', '143, Batti St, Anpoondi Sathiyamangalam(po),', '', '', 'Vellore', 'Tamil Nadu', '632114', 'India', '9361486176', '2026-05-27 00:56:43', '2026-05-27 00:56:43'),
(236, 4, 'permanent', '5/271,Pillayar Kovil Street,Karigiri Post, Sakkarakuttai,Katapadi', '', '', 'Vellore', 'Tamil Nadu', '632106', 'India', '9345769647', '2026-05-27 01:05:30', '2026-05-27 01:05:30');

-- --------------------------------------------------------

--
-- Table structure for table `employee_relations`
--

CREATE TABLE `employee_relations` (
  `id` bigint UNSIGNED NOT NULL,
  `employee_id` bigint UNSIGNED NOT NULL,
  `relation_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `age` int DEFAULT NULL,
  `phone_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `relationship` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `employee_relations`
--

INSERT INTO `employee_relations` (`id`, `employee_id`, `relation_name`, `age`, `phone_number`, `relationship`, `created_at`, `updated_at`) VALUES
(339, 13, 'Logeshwaran P', 25, '', 'Brother', '2026-05-12 01:18:38', '2026-05-12 01:18:38'),
(340, 13, 'Panneerselvam', 56, '9442670289', 'Father', '2026-05-12 01:18:38', '2026-05-12 01:18:38'),
(341, 13, 'Sundhari P', 50, '', 'Mother', '2026-05-12 01:18:38', '2026-05-12 01:18:38'),
(350, 14, 'S.Hemanath', 28, '', 'Brother', '2026-05-12 01:20:16', '2026-05-12 01:20:16'),
(351, 14, 'Surendar', 26, '', 'Brother', '2026-05-12 01:20:16', '2026-05-12 01:20:16'),
(352, 14, 'N.Sivakumar', 57, '9786540054', 'Father', '2026-05-12 01:20:16', '2026-05-12 01:20:16'),
(353, 14, 'S.Chitra', 53, '', 'Mother', '2026-05-12 01:20:16', '2026-05-12 01:20:16'),
(357, 5, 'Madhan Kumar', 47, '8668107653', 'Father', '2026-05-12 01:21:01', '2026-05-12 01:21:01'),
(358, 5, 'Radha', 40, '', 'Mother', '2026-05-12 01:21:01', '2026-05-12 01:21:01'),
(359, 5, 'Ramya', 20, '', 'Sister', '2026-05-12 01:21:01', '2026-05-12 01:21:01'),
(372, 7, 'Lakshmi S', 50, '8438109907', 'Mother', '2026-05-12 01:27:13', '2026-05-12 01:27:13'),
(401, 9, 'Reethusri B', 5, '', 'Daughter', '2026-05-12 01:37:50', '2026-05-12 01:37:50'),
(402, 9, 'Muniammal V', 70, '9629017134', 'Mother', '2026-05-12 01:37:50', '2026-05-12 01:37:50'),
(403, 9, 'Varun B', 10, '', 'Son', '2026-05-12 01:37:50', '2026-05-12 01:37:50'),
(404, 9, 'Nandhini B', 27, '', 'Wife', '2026-05-12 01:37:50', '2026-05-12 01:37:50'),
(429, 17, 'Shanmugam M', 56, '9942640832', 'Father', '2026-05-12 02:02:48', '2026-05-12 02:02:48'),
(430, 17, 'Nirmala S', 46, '8667726204', 'Mother', '2026-05-12 02:02:48', '2026-05-12 02:02:48'),
(445, 19, 'Palani S', 60, '9688281313', 'Father', '2026-05-13 06:29:27', '2026-05-13 06:29:27'),
(446, 19, 'Amudha P', 54, '', 'Mother', '2026-05-13 06:29:27', '2026-05-13 06:29:27'),
(450, 16, 'Sundharraj', 21, '', 'Brother', '2026-05-13 06:37:06', '2026-05-13 06:37:06'),
(451, 16, 'Gunasekaran', 51, '7639694640', 'Father', '2026-05-13 06:37:06', '2026-05-13 06:37:06'),
(452, 16, 'Chitra', 46, '', 'Mother', '2026-05-13 06:37:06', '2026-05-13 06:37:06'),
(493, 18, 'Sedhumadhavan A', 45, '', 'Brother', '2026-05-13 23:49:35', '2026-05-13 23:49:35'),
(494, 18, 'Venkatakrishanan', 47, '9886540077', 'Brother', '2026-05-13 23:49:35', '2026-05-13 23:49:35'),
(495, 18, 'Poomani A', 65, '', 'Mother', '2026-05-13 23:49:35', '2026-05-13 23:49:35'),
(496, 18, 'Sharmila C', 40, '', 'Wife', '2026-05-13 23:49:35', '2026-05-13 23:49:35'),
(521, 12, 'Sakthi Priya S', 10, '', 'Daughter', '2026-05-13 23:52:16', '2026-05-13 23:52:16'),
(522, 12, 'Siva M', 41, '9442060203', 'Husband', '2026-05-13 23:52:16', '2026-05-13 23:52:16'),
(523, 12, 'Sankari M', 45, '', 'sister', '2026-05-13 23:52:16', '2026-05-13 23:52:16'),
(524, 12, 'Kavin s', 4, '', 'Son', '2026-05-13 23:52:16', '2026-05-13 23:52:16'),
(553, 11, 'Hamachandar.S', 25, '', 'Brother', '2026-05-13 23:57:49', '2026-05-13 23:57:49'),
(554, 11, 'Sekar.S', 52, '', 'Father', '2026-05-13 23:57:49', '2026-05-13 23:57:49'),
(555, 11, 'Chitra.S', 50, '7639627752', 'Mother', '2026-05-13 23:57:49', '2026-05-13 23:57:49'),
(556, 11, 'Serthiga.S', 18, '', 'Sister', '2026-05-13 23:57:49', '2026-05-13 23:57:49'),
(559, 10, 'Vijayaramana L.G', 22, '', 'Brother', '2026-05-13 23:58:59', '2026-05-13 23:58:59'),
(560, 10, 'Latha V', 52, '9488438390', 'Mother', '2026-05-13 23:58:59', '2026-05-13 23:58:59'),
(582, 8, 'M.RoshiniSri', 3, '', 'Daughter', '2026-05-14 00:04:50', '2026-05-14 00:04:50'),
(583, 8, 'P.Muruganantham', 43, '7449061947', 'Husband', '2026-05-14 00:04:50', '2026-05-14 00:04:50'),
(584, 8, 'M.Karhti Kashav', 5, '', 'Son', '2026-05-14 00:04:50', '2026-05-14 00:04:50'),
(618, 6, 'M.Balasubramani', 58, '9894331681', 'Father', '2026-05-27 00:56:43', '2026-05-27 00:56:43'),
(619, 6, 'Manjula', 48, '', 'Mother', '2026-05-27 00:56:43', '2026-05-27 00:56:43'),
(620, 6, 'B.Samdhiya', 24, '', 'Sister', '2026-05-27 00:56:43', '2026-05-27 00:56:43'),
(621, 4, 'Mohan L', 24, '9360599336', 'Brother', '2026-05-27 01:05:30', '2026-05-27 01:05:30'),
(622, 4, 'Loganathan V', NULL, '8489214637', 'Father', '2026-05-27 01:05:30', '2026-05-27 01:05:30'),
(623, 4, 'Rose L', NULL, '9787878248', 'Mother', '2026-05-27 01:05:30', '2026-05-27 01:05:30');

-- --------------------------------------------------------

--
-- Table structure for table `employee_salary_components`
--

CREATE TABLE `employee_salary_components` (
  `id` bigint UNSIGNED NOT NULL,
  `salary_structure_id` bigint UNSIGNED DEFAULT NULL,
  `component_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `component_type` enum('earning','deduction') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `amount` decimal(18,2) DEFAULT NULL,
  `calculation_basis` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'fixed' COMMENT 'fixed, percent_basic, percent_gross, percent_ctc',
  `percent_value` decimal(9,4) DEFAULT NULL,
  `contribution_role` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'employee' COMMENT 'employee=payslip, employer=CTC cost'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `employee_salary_components`
--

INSERT INTO `employee_salary_components` (`id`, `salary_structure_id`, `component_name`, `component_type`, `amount`, `calculation_basis`, `percent_value`, `contribution_role`) VALUES
(102, 56, 'Net Amount', 'earning', 11635.00, 'fixed', NULL, 'employee'),
(103, 56, 'SPL', 'earning', 3107.00, 'fixed', NULL, 'employee'),
(104, 56, 'HRA', 'earning', 3107.00, 'fixed', NULL, 'employee'),
(105, 56, 'ESI', 'earning', 47.00, 'fixed', NULL, 'employee'),
(106, 56, 'PF', 'earning', 745.68, 'fixed', NULL, 'employee'),
(107, 56, 'Gross', 'earning', 12428.00, 'percent_gross', 100.0000, 'employee'),
(108, 56, 'Basic', 'earning', 6214.00, 'percent_basic', 50.0000, 'employee'),
(120, 59, 'SPL', 'earning', 5000.00, 'fixed', NULL, 'employee'),
(121, 59, 'HRA', 'earning', 5000.00, 'fixed', NULL, 'employee'),
(122, 59, 'Net Amount', 'deduction', 18725.00, 'fixed', NULL, 'employee'),
(123, 59, 'ESI', 'deduction', 75.00, 'fixed', NULL, 'employee'),
(124, 59, 'PF', 'deduction', 1200.00, 'fixed', NULL, 'employee'),
(125, 59, 'Gross', 'earning', 20000.00, 'percent_gross', 100.0000, 'employee'),
(126, 59, 'Basic', 'earning', 10000.00, 'percent_basic', 50.0000, 'employee'),
(133, 61, 'SPL', 'earning', 4125.00, 'fixed', NULL, 'employee'),
(134, 61, 'HRA', 'earning', 4125.00, 'fixed', NULL, 'employee'),
(135, 61, 'Net Amount', 'earning', 15448.00, 'fixed', NULL, 'employee'),
(136, 61, 'ESI', 'earning', 62.00, 'fixed', NULL, 'employee'),
(137, 61, 'PF', 'earning', 990.00, 'fixed', NULL, 'employee'),
(138, 61, 'Gross', 'earning', 16500.00, 'percent_gross', 100.0000, 'employee'),
(139, 61, 'Basic', 'earning', 8250.00, 'percent_basic', 50.0000, 'employee'),
(174, 70, 'ESI', 'earning', 45.00, 'fixed', NULL, 'employee'),
(175, 70, 'PF', 'earning', 720.00, 'fixed', NULL, 'employee'),
(176, 70, 'Net Amount', 'earning', 11235.00, 'fixed', NULL, 'employee'),
(177, 70, 'Gross', 'earning', 12000.00, 'percent_gross', 100.0000, 'employee'),
(178, 70, 'SPL', 'earning', 3000.00, 'fixed', NULL, 'employee'),
(179, 70, 'HRA', 'earning', 3000.00, 'fixed', NULL, 'employee'),
(180, 70, 'Basic', 'earning', 6000.00, 'percent_basic', 50.0000, 'employee'),
(199, 78, 'Net Salary', 'earning', 21533.00, 'fixed', NULL, 'employee'),
(200, 78, 'ESI', 'earning', 87.00, 'fixed', NULL, 'employee'),
(201, 78, 'PF', 'earning', 1380.00, 'fixed', NULL, 'employee'),
(202, 78, 'HRA', 'earning', 5750.00, 'fixed', NULL, 'employee'),
(203, 78, 'Gross', 'earning', 23000.00, 'percent_gross', 100.0000, 'employee'),
(204, 78, 'Basic', 'earning', 11500.00, 'percent_basic', 50.0000, 'employee'),
(246, 91, 'Net Amount', 'earning', 26074.00, 'fixed', NULL, 'employee'),
(247, 91, 'ESI', 'earning', 105.00, 'fixed', NULL, 'employee'),
(248, 91, 'PF', 'earning', 1671.00, 'fixed', NULL, 'employee'),
(249, 91, 'SPL', 'earning', 6962.00, 'fixed', NULL, 'employee'),
(250, 91, 'HRA', 'earning', 6963.00, 'fixed', NULL, 'employee'),
(251, 91, 'Gross', 'earning', 27850.00, 'percent_gross', 100.0000, 'employee'),
(252, 91, 'Basic', 'earning', 13925.00, 'percent_basic', 50.0000, 'employee'),
(274, 99, 'Net Amount', 'earning', 28087.00, 'fixed', NULL, 'employee'),
(275, 99, 'ESI', 'earning', 113.00, 'fixed', NULL, 'employee'),
(276, 99, 'PF', 'earning', 1800.00, 'fixed', NULL, 'employee'),
(277, 99, 'SPL', 'earning', 7500.00, 'fixed', NULL, 'employee'),
(278, 99, 'HRA', 'earning', 7500.00, 'fixed', NULL, 'employee'),
(279, 99, 'Gross', 'earning', 30000.00, 'percent_gross', 100.0000, 'employee'),
(280, 99, 'Basic', 'earning', 15000.00, 'percent_basic', 50.0000, 'employee'),
(287, 101, 'HRA', 'earning', 6250.00, 'fixed', NULL, 'employee'),
(288, 101, 'SPL', 'earning', 6250.00, 'fixed', NULL, 'employee'),
(289, 101, 'Net Amount', 'earning', 23406.00, 'fixed', NULL, 'employee'),
(290, 101, 'ESI', 'earning', 94.00, 'fixed', NULL, 'employee'),
(291, 101, 'PF', 'earning', 1500.00, 'fixed', NULL, 'employee'),
(292, 101, 'Gross', 'earning', 23406.00, 'percent_gross', 100.0000, 'employee'),
(293, 101, 'Basic', 'earning', 12500.00, 'percent_basic', 50.0000, 'employee'),
(322, 112, 'Net Amount', 'earning', 22083.00, 'fixed', NULL, 'employee'),
(323, 112, 'ESI', 'earning', 89.00, 'fixed', NULL, 'employee'),
(324, 112, 'PF', 'earning', 1415.28, 'fixed', NULL, 'employee'),
(325, 112, 'SPL', 'earning', 5896.00, 'fixed', NULL, 'employee'),
(326, 112, 'HRA', 'earning', 5897.00, 'fixed', NULL, 'employee'),
(327, 112, 'Gross', 'earning', 23587.00, 'percent_gross', 100.0000, 'employee'),
(328, 112, 'Basic', 'earning', 11794.00, 'percent_basic', 50.0000, 'employee'),
(350, 119, 'Gross', 'earning', 30000.00, 'percent_gross', 100.0000, 'employee'),
(351, 119, 'Net Amount', 'earning', 28087.00, 'fixed', NULL, 'employee'),
(352, 119, 'ESI', 'earning', 113.00, 'fixed', NULL, 'employee'),
(353, 119, 'PF', 'earning', 1800.00, 'fixed', NULL, 'employee'),
(354, 119, 'SPL', 'earning', 7500.00, 'fixed', NULL, 'employee'),
(355, 119, 'HRA', 'earning', 7500.00, 'fixed', NULL, 'employee'),
(356, 119, 'Basic', 'earning', 15000.00, 'percent_basic', 50.0000, 'employee'),
(378, 127, 'Gross Amount', 'earning', 20076.00, 'fixed', NULL, 'employee'),
(379, 127, 'Net Amount', 'earning', 18795.00, 'fixed', NULL, 'employee'),
(380, 127, 'ESI', 'earning', 76.00, 'fixed', NULL, 'employee'),
(381, 127, 'PF', 'earning', 1204.56, 'fixed', NULL, 'employee'),
(382, 127, 'SPL', 'earning', 5019.00, 'fixed', NULL, 'employee'),
(383, 127, 'HRA', 'earning', 5019.00, 'fixed', NULL, 'employee'),
(384, 127, 'Basic', 'earning', 10038.00, 'percent_basic', 50.0000, 'employee'),
(391, 129, 'ESI', 'earning', 47.00, 'fixed', NULL, 'employee'),
(392, 129, 'PF', 'earning', 745.68, 'fixed', NULL, 'employee'),
(393, 129, 'Net Amount', 'earning', 11635.00, 'fixed', NULL, 'employee'),
(394, 129, 'Gross', 'earning', 12428.00, 'percent_gross', 100.0000, 'employee'),
(395, 129, 'SPL', 'earning', 3107.00, 'fixed', NULL, 'employee'),
(396, 129, 'HRA', 'earning', 3107.00, 'fixed', NULL, 'employee'),
(397, 129, 'Basic', 'earning', 6214.00, 'percent_basic', 50.0000, 'employee'),
(419, 137, 'Gross Amount', 'earning', 16500.00, 'fixed', NULL, 'employee'),
(420, 137, 'Net Amount', 'earning', 15448.00, 'fixed', NULL, 'employee'),
(421, 137, 'PF', 'earning', 990.00, 'fixed', NULL, 'employee'),
(422, 137, 'ESI', 'earning', 62.00, 'fixed', NULL, 'employee'),
(423, 137, 'SPL', 'earning', 4125.00, 'fixed', NULL, 'employee'),
(424, 137, 'HRA', 'earning', 4125.00, 'fixed', NULL, 'employee'),
(425, 137, 'Basic', 'earning', 8250.00, 'percent_basic', 50.0000, 'employee'),
(471, 149, 'Gross Amount', 'earning', 15000.00, 'percent_gross', 100.0000, 'employee'),
(472, 149, 'Net Amount', 'earning', 14043.00, 'fixed', NULL, 'employee'),
(473, 149, 'ESI', 'earning', 57.00, 'fixed', NULL, 'employee'),
(474, 149, 'PF', 'earning', 900.00, 'fixed', NULL, 'employee'),
(475, 149, 'SPL', 'earning', 3750.00, 'fixed', NULL, 'employee'),
(476, 149, 'HRA', 'earning', 3750.00, 'fixed', NULL, 'employee'),
(477, 149, 'Basic', 'earning', 7500.00, 'percent_basic', 50.0000, 'employee'),
(478, 150, 'SPL', 'earning', 3000.00, 'fixed', NULL, 'employee'),
(479, 150, 'HRA', 'earning', 3000.00, 'fixed', NULL, 'employee'),
(480, 150, 'Net Amount', 'earning', 11235.00, 'fixed', NULL, 'employee'),
(481, 150, 'ESI', 'earning', 45.00, 'fixed', NULL, 'employee'),
(482, 150, 'PF', 'earning', 720.00, 'fixed', NULL, 'employee'),
(483, 150, 'Gross', 'earning', 12000.00, 'percent_gross', 100.0000, 'employee'),
(484, 150, 'Basic', 'earning', 6000.00, 'percent_basic', 50.0000, 'employee');

-- --------------------------------------------------------

--
-- Table structure for table `employee_salary_structures`
--

CREATE TABLE `employee_salary_structures` (
  `id` bigint UNSIGNED NOT NULL,
  `employee_id` bigint UNSIGNED NOT NULL,
  `effective_from` date NOT NULL,
  `basic_salary` decimal(18,2) DEFAULT '0.00',
  `gross_salary` decimal(18,2) DEFAULT '0.00',
  `net_salary` decimal(18,2) DEFAULT '0.00',
  `ctc_monthly` decimal(18,2) DEFAULT NULL COMMENT 'Full monthly CTC incl. employer cost; payroll uses gross if null',
  `is_active` tinyint(1) DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `employee_salary_structures`
--

INSERT INTO `employee_salary_structures` (`id`, `employee_id`, `effective_from`, `basic_salary`, `gross_salary`, `net_salary`, `ctc_monthly`, `is_active`) VALUES
(56, 13, '2026-02-02', 6214.00, 12428.00, 11635.00, 160508.00, 1),
(59, 14, '2026-02-02', 10000.00, 20000.00, 18725.00, NULL, 1),
(61, 5, '2025-11-02', 8250.00, 16500.00, 15448.00, 213108.00, 1),
(70, 7, '2026-04-02', 6000.00, 12000.00, 11235.00, 154980.00, 1),
(78, 9, '2026-02-02', 11500.00, 23000.00, 21533.00, 297048.00, 1),
(91, 17, '2026-02-02', 13925.00, 26074.00, 23406.00, NULL, 1),
(99, 19, '2026-05-04', 15000.00, 30000.00, 28087.00, NULL, 1),
(101, 16, '2026-02-02', 12500.00, 25000.00, 23406.00, NULL, 1),
(112, 18, '2026-03-02', 11794.00, 23587.00, 22083.00, 304635.00, 1),
(119, 12, '2026-04-02', 15000.00, 30000.00, 28087.00, 387456.00, 1),
(127, 11, '2026-04-02', 10038.00, 20076.00, 18795.00, 259291.00, 1),
(129, 10, '2026-02-02', 6214.00, 12428.00, 11635.00, 160508.00, 1),
(137, 8, '2026-04-02', 8250.00, 16500.00, 15448.00, 213108.00, 1),
(149, 6, '2026-04-02', 7500.00, 15000.00, 14043.00, 193728.00, 1),
(150, 4, '2026-04-02', 6000.00, 12000.00, 11235.00, 154980.00, 1);

-- --------------------------------------------------------

--
-- Table structure for table `expense_claims`
--

CREATE TABLE `expense_claims` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `employee_id` bigint UNSIGNED NOT NULL,
  `claim_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `claim_date` date NOT NULL,
  `total_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `claim_status` enum('draft','applied','approved','reimbursed','rejected','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `reimbursement_voucher_id` bigint UNSIGNED DEFAULT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `approved_by` bigint UNSIGNED DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `reimbursed_by` bigint UNSIGNED DEFAULT NULL,
  `reimbursed_at` datetime DEFAULT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `expense_claim_lines`
--

CREATE TABLE `expense_claim_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `expense_claim_id` bigint UNSIGNED NOT NULL,
  `line_no` int NOT NULL,
  `expense_date` date NOT NULL,
  `expense_category` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `project_id` bigint UNSIGNED DEFAULT NULL,
  `project_task_id` bigint UNSIGNED DEFAULT NULL,
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `financial_years`
--

CREATE TABLE `financial_years` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `fy_code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `fy_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `is_current` tinyint(1) NOT NULL DEFAULT '0',
  `is_locked` tinyint(1) NOT NULL DEFAULT '0',
  `lock_date` date DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ;

--
-- Dumping data for table `financial_years`
--

INSERT INTO `financial_years` (`id`, `company_id`, `fy_code`, `fy_name`, `start_date`, `end_date`, `is_current`, `is_locked`, `lock_date`, `is_active`, `remarks`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(1, 1, 'FY26-27', '2026-2027', '2026-04-01', '2027-03-31', 1, 0, NULL, 1, NULL, 2, 2, '2026-05-06 03:03:37', '2026-05-06 03:03:37');

-- --------------------------------------------------------

--
-- Table structure for table `gst_registrations`
--

CREATE TABLE `gst_registrations` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED DEFAULT NULL,
  `location_id` bigint UNSIGNED DEFAULT NULL,
  `registration_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `gstin` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pan_no` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `state_id` bigint UNSIGNED NOT NULL,
  `state_code` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `legal_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `trade_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `registration_type` enum('regular','composition','sez','sez_unit','casual','non_resident','unregistered') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'regular',
  `effective_from` date DEFAULT NULL,
  `effective_to` date DEFAULT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `gst_tax_rules`
--

CREATE TABLE `gst_tax_rules` (
  `id` bigint UNSIGNED NOT NULL,
  `rule_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `rule_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `transaction_type` enum('sales','purchase','sales_return','purchase_return','service_sales','service_purchase') COLLATE utf8mb4_unicode_ci NOT NULL,
  `item_type` enum('stock','service','manufactured','raw_material','semi_finished','finished_goods','consumable','asset','non_stock','all') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'all',
  `tax_code_id` bigint UNSIGNED NOT NULL,
  `place_of_supply_result` enum('intra_state','inter_state','export','import','sez','reverse_charge','all') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'all',
  `tax_application` enum('cgst_sgst','igst','cess_only','exempt','nil_rated','non_gst') COLLATE utf8mb4_unicode_ci NOT NULL,
  `reverse_charge_applicable` tinyint(1) NOT NULL DEFAULT '0',
  `input_tax_credit_allowed` tinyint(1) NOT NULL DEFAULT '1',
  `priority_order` int NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `hr_statutory_esi`
--

CREATE TABLE `hr_statutory_esi` (
  `id` bigint UNSIGNED NOT NULL,
  `statutory_profile_id` bigint UNSIGNED NOT NULL,
  `employee_percent` decimal(9,4) NOT NULL DEFAULT '0.7500',
  `employer_percent` decimal(9,4) NOT NULL DEFAULT '3.2500',
  `gross_ceiling` decimal(18,2) DEFAULT NULL,
  `calculate_on` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'gross',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `hr_statutory_pf`
--

CREATE TABLE `hr_statutory_pf` (
  `id` bigint UNSIGNED NOT NULL,
  `statutory_profile_id` bigint UNSIGNED NOT NULL,
  `employee_percent` decimal(9,4) NOT NULL DEFAULT '12.0000',
  `employer_percent` decimal(9,4) NOT NULL DEFAULT '12.0000',
  `wage_ceiling` decimal(18,2) DEFAULT NULL,
  `calculate_on` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'basic',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `hr_statutory_profiles`
--

CREATE TABLE `hr_statutory_profiles` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `profile_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Default',
  `effective_from` date NOT NULL,
  `effective_to` date DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `professional_tax_state_code` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'State/UT whose notified PT schedule these slabs follow (e.g. Karnataka, Maharashtra)',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `hr_statutory_pt_slabs`
--

CREATE TABLE `hr_statutory_pt_slabs` (
  `id` bigint UNSIGNED NOT NULL,
  `statutory_profile_id` bigint UNSIGNED NOT NULL,
  `gross_from` decimal(18,2) NOT NULL DEFAULT '0.00',
  `gross_to` decimal(18,2) DEFAULT NULL,
  `employee_tax_monthly` decimal(18,2) NOT NULL DEFAULT '0.00',
  `employer_tax_monthly` decimal(18,2) NOT NULL DEFAULT '0.00',
  `sort_order` int NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
(2, 1, 'MFG/00001', 'HappyBell 2025', NULL, 'manufactured', NULL, 1, 1, 1, 1, 4, NULL, NULL, '91091010', 0, 0, 0, 1, 1, 0, 0, 1, 6600.0000, 7500.0000, 7500.0000, 1.000000, 0.000000, 0.000000, 1.150000, NULL, NULL, 1, NULL, 2, 4, '2026-05-07 05:33:47', '2026-05-29 00:06:07'),
(3, 1, 'MFG/00002', 'HappyBell 2020', NULL, 'manufactured', NULL, NULL, 1, 1, 1, 4, NULL, NULL, '91091010', 0, 0, 0, 1, 1, 0, 0, 1, 6600.0000, 7500.0000, 7500.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 2, 4, '2026-05-07 05:38:59', '2026-05-29 00:06:37'),
(4, 1, 'MFG/00003', 'BELL BOY', NULL, 'manufactured', NULL, 1, 1, 1, 1, 4, NULL, NULL, '853110', 0, 0, 0, 1, 1, 0, 0, 1, 3960.0000, 4500.0000, 4500.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 2, 4, '2026-05-07 05:40:01', '2026-05-29 00:06:26'),
(5, 1, 'MFG/00004', 'BLUESCALE – BLUETOOTH RATION SHOP SCALE', NULL, 'manufactured', NULL, 1, 1, 1, 1, 4, NULL, NULL, '84231000', 0, 0, 0, 1, 1, 0, 0, 0, 1188.0000, 1350.0000, 1350.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 2, 2, '2026-05-07 05:45:42', '2026-05-28 02:06:12'),
(6, 1, 'TRA/00002', 'FLUX', NULL, 'trade', 1, 1, 5, 5, 5, 4, NULL, NULL, '38101010', 0, 0, 0, 1, 1, 0, 0, 0, 272.8000, 310.0000, 310.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 2, 4, '2026-05-07 06:27:56', '2026-05-28 04:06:14'),
(7, 1, 'SFG/00017', '8051 Basic Development Board', '8051 Basic Development Board', 'semi_finished', 2, 1, 2, 1, 1, 4, NULL, NULL, '85340000', 0, 0, 0, 1, 1, 0, 0, 0, 158.4000, 180.0000, 180.0000, 0.000000, 0.000000, 0.000000, 0.300000, NULL, NULL, 1, NULL, 4, 2, '2026-05-15 01:28:03', '2026-05-28 05:35:57'),
(8, 1, 'SFG/00020', 'USB to Isolated TTL – Machine Edition', 'USB to Isolated TTL – Machine Edition', 'semi_finished', 2, 1, 1, 1, 1, 4, NULL, NULL, '85369090', 0, 0, 0, 1, 1, 0, 0, 0, 660.0000, 750.0000, 750.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 2, '2026-05-15 01:32:29', '2026-05-28 05:39:39'),
(9, 1, 'SFG/00022', 'WiFi to Serial Converter', 'WiFi to Serial Converter', 'semi_finished', 2, NULL, 2, 1, 1, 4, NULL, NULL, '85176290', 0, 0, 0, 1, 1, 0, 0, 0, 968.0000, 1100.0000, 1100.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 2, '2026-05-15 01:34:39', '2026-05-28 05:43:45'),
(10, 1, 'SFG/00018', 'Multiport Scale – WiFi/Bluetooth/USB/485', 'Multiport Scale – WiFi/Bluetooth/USB/485', 'semi_finished', 2, 1, 1, 1, 1, 4, NULL, NULL, '84718000', 0, 0, 0, 1, 1, 0, 0, 0, 1452.0000, 1650.0000, 1650.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 2, '2026-05-15 01:36:58', '2026-05-28 05:38:05'),
(11, 1, 'SFG/00019', 'LPT to Serial/USB Converter', 'LPT to Serial/USB Converter', 'semi_finished', 2, 1, 1, 1, 1, 4, NULL, NULL, '84718000', 0, 0, 0, 1, 1, 0, 0, 0, 3080.0000, 3500.0000, 3500.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 2, '2026-05-15 01:43:26', '2026-05-28 05:36:50'),
(12, 1, 'SFG/00023', 'USB/RS232 External Display – 1 Inch', 'USB/RS232 External Display – 1 Inch', 'semi_finished', 2, 1, 1, 1, 1, 4, NULL, NULL, '85369090', 0, 0, 0, 1, 1, 0, 0, 0, 924.0000, 1050.0000, 1050.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 2, '2026-05-15 01:44:58', '2026-05-28 05:43:19'),
(13, 1, 'SFG/00021', 'USB to RS232 Isolated Converter', NULL, 'semi_finished', 2, 1, 1, 1, 1, 4, NULL, NULL, '85369090', 0, 0, 0, 1, 1, 0, 0, 0, 748.0000, 850.0000, 850.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 2, '2026-05-15 01:55:49', '2026-05-28 05:42:27'),
(14, 1, 'SFG/00002', 'RS232 to LPT (Serial to LPT)', NULL, 'semi_finished', 2, 1, 1, 1, 1, 4, NULL, NULL, '85444299', 0, 0, 0, 1, 1, 0, 0, 0, 1320.0000, 1500.0000, 1500.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 2, '2026-05-15 02:58:03', '2026-05-28 05:38:38'),
(15, 1, 'SFG/00003', 'Pinky Scale – World Smallest Scale Board', NULL, 'semi_finished', 2, 1, 1, NULL, 1, 4, NULL, NULL, '84718000', 0, 0, 0, 1, 1, 0, 0, 0, 1056.0000, 1200.0000, 1200.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 2, '2026-05-15 03:05:17', '2026-05-28 05:38:28'),
(16, 1, 'SFG/00004', 'HookScale-WiFi & Bluehooth Weighing Controller', NULL, 'semi_finished', 2, 1, 1, 1, 1, 4, NULL, NULL, '84238900', 0, 0, 0, 1, 1, 0, 0, 0, 1408.0000, 1600.0000, 1600.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 2, '2026-05-15 03:07:48', '2026-05-28 05:36:31'),
(17, 1, 'SFG/00005', 'Smart Voice Playback Module', NULL, 'semi_finished', 2, 1, 1, 1, 1, 4, NULL, NULL, '85198100', 0, 0, 0, 1, 1, 0, 0, 0, 924.0000, 1050.0000, 1050.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 2, '2026-05-15 03:11:28', '2026-05-28 05:38:48'),
(18, 1, 'SFG/00006', 'LPT to USB CDC/HID/Keyboard Converter', NULL, 'semi_finished', 2, 1, 1, 1, 1, 4, NULL, NULL, '850440', 0, 0, 0, 1, 1, 0, 0, 0, 3080.0000, 3500.0000, 3500.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 2, '2026-05-15 03:19:21', '2026-05-28 05:37:05'),
(19, 1, 'SFG/00007', 'Mini Wi-Fi Serial Weigh Module', NULL, 'semi_finished', 2, 1, 1, 1, 1, 4, NULL, NULL, '85177990', 0, 0, 0, 1, 1, 0, 0, 0, 1056.0000, 1200.0000, 1200.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 2, '2026-05-15 03:24:37', '2026-05-28 05:37:52'),
(20, 1, 'SFG/00008', 'UART-to-Current Loop (0–20mA / 4–20mA)', NULL, 'semi_finished', 2, 1, 1, 1, 1, 4, NULL, NULL, '85437090', 0, 0, 0, 1, 1, 0, 0, 0, 1584.0000, 1800.0000, 1800.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 2, '2026-05-15 03:28:15', '2026-05-28 05:39:22'),
(21, 1, 'SFG/00009', 'Buddy51-mini – 8051 Development Kit', NULL, 'semi_finished', 2, 1, 1, 1, 1, 4, NULL, NULL, '85439000', 0, 0, 0, 1, 1, 0, 0, 0, 410.1680, 466.1000, 466.1000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 2, '2026-05-15 03:33:36', '2026-05-28 05:36:13'),
(22, 1, 'SFG/00010', 'Multi-Motor Controller for Spinning', NULL, 'semi_finished', 2, 1, 1, 1, 1, 4, NULL, NULL, '85371000', 0, 0, 0, 1, 1, 0, 0, 0, 7040.0000, 8000.0000, 8000.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 2, '2026-05-15 03:35:30', '2026-05-28 05:37:42'),
(23, 1, 'SFG/00011', 'USB to Isolated TTL – PC Edition', NULL, 'semi_finished', 2, 1, 1, 1, 1, 4, NULL, NULL, '85369090', 0, 0, 0, 1, 1, 0, 0, 0, 660.0000, 750.0000, 750.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 2, '2026-05-15 03:37:17', '2026-05-28 05:40:07'),
(24, 1, 'SFG/00012', 'P10 Display Controller', NULL, 'semi_finished', 2, 1, 1, 1, 1, 4, NULL, NULL, '85312000', 0, 0, 0, 1, 1, 0, 0, 0, 1056.0000, 1200.0000, 1200.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 2, '2026-05-15 03:41:11', '2026-05-28 05:38:17'),
(25, 1, 'SFG/00013', 'WeighSensei – RS485 Modbus Weigh Scale', NULL, 'semi_finished', 2, 1, 1, 1, 1, 4, NULL, NULL, '84238190', 0, 0, 0, 1, 1, 0, 0, 0, 2112.0000, 2400.0000, 2400.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 2, '2026-05-15 03:44:22', '2026-05-28 05:43:31'),
(26, 1, 'SFG/00014', 'USB to RS485 Converter V2', NULL, 'semi_finished', 2, 1, 1, 1, 1, 4, NULL, NULL, '85176290', 0, 0, 0, 1, 1, 0, 0, 0, 660.0000, 750.0000, 750.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 2, '2026-05-15 03:45:50', '2026-05-28 05:42:56'),
(27, 1, 'SFG/00015', 'TTL to RS485 Converter', NULL, 'semi_finished', 2, 1, 1, 1, 1, 4, NULL, NULL, '85389000', 0, 0, 0, 1, 1, 0, 0, 0, 440.0000, 500.0000, 500.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 2, '2026-05-15 03:47:54', '2026-05-28 05:39:01'),
(28, 1, 'SFG/00016', 'USB to RS485 Converter', NULL, 'semi_finished', 2, 1, 1, 1, 1, 4, NULL, NULL, '85176290', 0, 0, 0, 1, 1, 0, 0, 0, 660.0000, 750.0000, 750.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 2, '2026-05-15 03:49:21', '2026-05-28 05:42:44'),
(29, 1, 'TRA/00001', 'GONG BELL', NULL, 'trade', 1, 1, 1, 1, 1, 4, NULL, NULL, '83061000', 0, 0, 0, 1, 1, 0, 0, 0, 1938.9832, 2203.3900, 2203.3900, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 2, '2026-05-22 03:31:52', '2026-05-28 03:06:18'),
(31, 1, 'test1', 'test', 'test', 'finished_goods', 3, 1, 1, 1, 1, 4, NULL, NULL, NULL, 0, 0, 0, 1, 1, 1, 0, 1, 0.0000, 0.0000, 0.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 2, 2, '2026-05-26 07:04:36', '2026-05-26 07:12:45'),
(32, 1, 'SHIPPING CHARGE', 'Shipping Charges', NULL, 'non_stock', 1, 1, 2, 1, 1, 4, NULL, NULL, '996819', 0, 0, 0, 0, 1, 0, 0, 0, 0.0000, 118.0000, 118.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 4, '2026-05-28 05:54:44', '2026-05-28 06:09:40'),
(33, 1, 'COD CHARGES', 'COD Charges', NULL, 'non_stock', 1, 1, 1, 1, 1, 4, NULL, NULL, '996819', 0, 0, 0, 0, 0, 1, 0, 0, 0.0000, 83.9000, 83.9000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 4, '2026-05-28 05:58:45', '2026-05-28 05:58:52'),
(34, 1, 'RAW/00001', 'PCB Fabrication', NULL, 'raw_material', 2, NULL, 1, 1, NULL, 4, NULL, NULL, '85340000', 0, 0, 0, 0, 1, 1, 0, 0, 0.0000, 60.6500, 60.6500, 300.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 4, '2026-05-29 03:56:13', '2026-05-29 03:56:13'),
(35, 1, 'TRA/00003', 'Emax Simonk Multirotor 30A', NULL, 'trade', 1, 1, 1, 1, 1, 2, NULL, NULL, '88073020', 0, 0, 0, 1, 0, 1, 0, 0, 0.0000, 0.0000, 0.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 4, '2026-05-29 04:39:22', '2026-05-29 05:30:07'),
(36, 1, 'RAW/00002', 'BOX', NULL, 'raw_material', NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 0, 1, 0, 1, 0, 0, 0.0000, 0.0000, 0.0000, 0.000000, 0.000000, 0.000000, NULL, NULL, NULL, 1, NULL, 4, 4, '2026-06-01 06:41:10', '2026-06-01 06:50:53');

-- --------------------------------------------------------

--
-- Table structure for table `item_alternates`
--

CREATE TABLE `item_alternates` (
  `id` bigint UNSIGNED NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `alternate_item_id` bigint UNSIGNED NOT NULL,
  `priority_order` int NOT NULL DEFAULT '1',
  `reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `item_alternates`
--

INSERT INTO `item_alternates` (`id`, `item_id`, `alternate_item_id`, `priority_order`, `reason`, `is_active`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(1, 39, 40, 2, 'Upsell bundle - demo inactive pair', 0, 7, NULL, '2026-06-17 08:25:27', '2026-06-17 08:25:27');

-- --------------------------------------------------------

--
-- Table structure for table `item_categories`
--

CREATE TABLE `item_categories` (
  `id` bigint UNSIGNED NOT NULL,
  `category_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `category_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `parent_category_id` bigint UNSIGNED DEFAULT NULL,
  `image_path` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `item_categories`
--

INSERT INTO `item_categories` (`id`, `category_code`, `category_name`, `parent_category_id`, `image_path`, `is_active`, `remarks`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(1, 'GEN', 'General', NULL, NULL, 1, NULL, NULL, NULL, '2026-05-05 05:31:43', '2026-05-05 05:31:43'),
(2, 'RM', 'Raw Materials', NULL, NULL, 1, NULL, NULL, NULL, '2026-05-05 05:31:43', '2026-05-05 05:31:43'),
(3, 'FG', 'Finished Goods', NULL, NULL, 1, NULL, NULL, NULL, '2026-05-05 05:31:43', '2026-05-05 05:31:43'),
(4, 'SERV', 'Services', NULL, NULL, 1, NULL, NULL, NULL, '2026-05-05 05:31:43', '2026-05-05 05:31:43');

-- --------------------------------------------------------

--
-- Table structure for table `item_planning_policies`
--

CREATE TABLE `item_planning_policies` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED DEFAULT NULL,
  `location_id` bigint UNSIGNED DEFAULT NULL,
  `warehouse_id` bigint UNSIGNED DEFAULT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `planning_method` enum('manual','reorder','mrp','min_max','make_to_order','make_to_stock') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'reorder',
  `procurement_type` enum('purchase','production','jobwork','transfer','mixed') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'purchase',
  `lead_time_days` int NOT NULL DEFAULT '0',
  `safety_stock_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `reorder_level_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `reorder_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `min_stock_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `max_stock_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `minimum_order_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `max_order_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `order_multiple_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `preferred_supplier_party_id` bigint UNSIGNED DEFAULT NULL,
  `preferred_bom_id` bigint UNSIGNED DEFAULT NULL,
  `preferred_warehouse_id` bigint UNSIGNED DEFAULT NULL,
  `planning_fence_days` int NOT NULL DEFAULT '0',
  `is_mrp_enabled` tinyint(1) NOT NULL DEFAULT '1',
  `is_reorder_enabled` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `item_prices`
--

CREATE TABLE `item_prices` (
  `id` bigint UNSIGNED NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `price_type` enum('purchase','sales','mrp','wholesale','retail','special') COLLATE utf8mb4_unicode_ci NOT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `price` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `valid_from` date DEFAULT NULL,
  `valid_to` date DEFAULT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `item_prices`
--

INSERT INTO `item_prices` (`id`, `item_id`, `price_type`, `uom_id`, `price`, `valid_from`, `valid_to`, `is_default`, `is_active`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(1, 7, 'sales', 1, 180.0000, NULL, NULL, 1, 1, 4, 4, '2026-05-27 23:43:11', '2026-05-27 23:43:11'),
(2, 5, 'sales', 1, 1350.0000, NULL, NULL, 0, 1, 4, 4, '2026-05-27 23:45:10', '2026-05-27 23:45:10'),
(3, 21, 'sales', 1, 466.1000, NULL, NULL, 1, 1, 4, 4, '2026-05-27 23:46:56', '2026-05-27 23:46:56'),
(4, 11, 'sales', 1, 3500.0000, NULL, NULL, 1, 1, 4, 4, '2026-05-28 00:12:31', '2026-05-28 00:12:31'),
(5, 19, 'sales', 1, 1200.0000, NULL, NULL, 1, 1, 4, 4, '2026-05-28 00:13:54', '2026-05-28 00:13:54'),
(6, 24, 'sales', 1, 1200.0000, NULL, NULL, 1, 1, 4, 4, '2026-05-28 00:14:37', '2026-05-28 00:14:37'),
(7, 22, 'sales', 1, 8000.0000, NULL, NULL, 1, 1, 4, 4, '2026-05-28 00:44:11', '2026-05-28 00:44:11'),
(8, 4, 'sales', 1, 4500.0000, NULL, NULL, 0, 1, 4, 4, '2026-05-28 03:19:59', '2026-05-28 03:19:59'),
(9, 6, 'sales', 5, 310.0000, NULL, NULL, 0, 1, 4, 4, '2026-05-28 03:20:25', '2026-05-28 03:20:25'),
(10, 29, 'sales', 1, 2203.3900, NULL, NULL, 0, 1, 4, 4, '2026-05-28 03:20:57', '2026-05-28 03:20:57'),
(11, 16, 'sales', 1, 1600.0000, NULL, NULL, 0, 1, 4, 4, '2026-05-28 03:21:36', '2026-05-28 03:21:36'),
(12, 18, 'sales', 1, 3500.0000, NULL, NULL, 1, 1, 4, 4, '2026-05-28 03:22:01', '2026-05-28 03:22:01'),
(13, 10, 'sales', 1, 1650.0000, NULL, NULL, 1, 1, 4, 4, '2026-05-28 03:22:34', '2026-05-28 03:22:34'),
(14, 15, 'sales', 1, 1200.0000, NULL, NULL, 0, 1, 4, 4, '2026-05-28 03:22:54', '2026-05-28 03:22:54'),
(15, 14, 'sales', 1, 1500.0000, NULL, NULL, 1, 1, 4, 4, '2026-05-28 03:23:48', '2026-05-28 03:23:48'),
(16, 17, 'sales', 1, 1050.0000, NULL, NULL, 1, 1, 4, 4, '2026-05-28 03:24:06', '2026-05-28 03:24:06'),
(17, 20, 'sales', 1, 1800.0000, NULL, NULL, 1, 1, 4, 4, '2026-05-28 03:40:45', '2026-05-28 03:40:45'),
(18, 8, 'sales', 1, 750.0000, NULL, NULL, 1, 1, 4, 4, '2026-05-28 03:41:02', '2026-05-28 03:41:02'),
(19, 23, 'sales', 1, 750.0000, NULL, NULL, 1, 1, 4, 4, '2026-05-28 03:41:17', '2026-05-28 03:41:17'),
(20, 13, 'sales', 1, 850.0000, NULL, NULL, 1, 1, 4, 4, '2026-05-28 03:41:32', '2026-05-28 03:41:32'),
(21, 28, 'sales', 1, 750.0000, NULL, NULL, 1, 1, 4, 4, '2026-05-28 03:41:47', '2026-05-28 03:41:47'),
(22, 26, 'sales', 1, 750.0000, NULL, NULL, 1, 1, 4, 4, '2026-05-28 03:42:17', '2026-05-28 03:42:17'),
(23, 12, 'sales', 1, 1050.0000, NULL, NULL, 0, 1, 4, 4, '2026-05-28 03:42:34', '2026-05-28 03:42:34'),
(24, 25, 'sales', 1, 2400.0000, NULL, NULL, 1, 1, 4, 4, '2026-05-28 03:43:11', '2026-05-28 03:43:11'),
(25, 9, 'sales', 1, 1100.0000, NULL, NULL, 1, 1, 4, 4, '2026-05-28 03:44:01', '2026-05-28 03:44:01'),
(26, 2, 'sales', 1, 7500.0000, NULL, NULL, 1, 1, 2, 2, '2026-05-28 03:52:24', '2026-05-28 03:52:24'),
(27, 3, 'sales', 1, 7500.0000, NULL, NULL, 1, 1, 2, 2, '2026-05-28 03:52:37', '2026-05-28 03:52:37'),
(28, 32, 'sales', 1, 118.0000, NULL, NULL, 1, 1, 4, 4, '2026-05-28 05:56:01', '2026-05-28 06:09:51'),
(29, 35, 'sales', 1, 1687.6190, NULL, NULL, 1, 1, 4, 4, '2026-05-29 05:21:10', '2026-05-29 05:21:10');

-- --------------------------------------------------------

--
-- Table structure for table `item_supplier_map`
--

CREATE TABLE `item_supplier_map` (
  `id` bigint UNSIGNED NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `supplier_party_id` bigint UNSIGNED NOT NULL,
  `supplier_item_code` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `supplier_item_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `purchase_uom_id` bigint UNSIGNED DEFAULT NULL,
  `supplier_rate` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `lead_time_days` int NOT NULL DEFAULT '0',
  `minimum_order_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `is_primary_supplier` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `item_supplier_map`
--

INSERT INTO `item_supplier_map` (`id`, `item_id`, `supplier_party_id`, `supplier_item_code`, `supplier_item_name`, `purchase_uom_id`, `supplier_rate`, `lead_time_days`, `minimum_order_qty`, `is_primary_supplier`, `is_active`, `remarks`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(1, 35, 42, '29157', 'Emax SimonK Multiroter', 1, 1687.6190, 0, 0.000000, 1, 1, NULL, 4, 4, '2026-05-29 05:20:44', '2026-05-29 05:20:44');

-- --------------------------------------------------------

--
-- Table structure for table `jobwork_charges`
--

CREATE TABLE `jobwork_charges` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `charge_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `charge_date` date NOT NULL,
  `jobwork_order_id` bigint UNSIGNED NOT NULL,
  `supplier_party_id` bigint UNSIGNED NOT NULL,
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `purchase_invoice_id` bigint UNSIGNED DEFAULT NULL,
  `charge_status` enum('draft','posted','invoiced','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `subtotal` decimal(18,2) NOT NULL DEFAULT '0.00',
  `discount_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `taxable_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `cgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `sgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `igst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `cess_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `round_off_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `total_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `posted_by` bigint UNSIGNED DEFAULT NULL,
  `posted_at` datetime DEFAULT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobwork_charge_lines`
--

CREATE TABLE `jobwork_charge_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `jobwork_charge_id` bigint UNSIGNED NOT NULL,
  `line_no` int NOT NULL,
  `service_description` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `item_id` bigint UNSIGNED DEFAULT NULL,
  `output_item_id` bigint UNSIGNED DEFAULT NULL,
  `qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `rate` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `tax_code_id` bigint UNSIGNED DEFAULT NULL,
  `tax_percent` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `cgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `sgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `igst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `cess_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `line_total` decimal(18,2) NOT NULL DEFAULT '0.00',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobwork_dispatches`
--

CREATE TABLE `jobwork_dispatches` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `dispatch_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `dispatch_date` date NOT NULL,
  `jobwork_order_id` bigint UNSIGNED NOT NULL,
  `supplier_party_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED NOT NULL,
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `dc_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `dc_date` date DEFAULT NULL,
  `vehicle_no` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `transporter_party_id` bigint UNSIGNED DEFAULT NULL,
  `lr_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `lr_date` date DEFAULT NULL,
  `dispatch_status` enum('draft','posted','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `posted_by` bigint UNSIGNED DEFAULT NULL,
  `posted_at` datetime DEFAULT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobwork_dispatch_lines`
--

CREATE TABLE `jobwork_dispatch_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `jobwork_dispatch_id` bigint UNSIGNED NOT NULL,
  `jobwork_order_material_id` bigint UNSIGNED DEFAULT NULL,
  `line_no` int NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED NOT NULL,
  `batch_id` bigint UNSIGNED DEFAULT NULL,
  `serial_id` bigint UNSIGNED DEFAULT NULL,
  `dispatch_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `unit_cost` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `total_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobwork_orders`
--

CREATE TABLE `jobwork_orders` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `jobwork_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `jobwork_date` date NOT NULL,
  `supplier_party_id` bigint UNSIGNED NOT NULL,
  `process_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `process_type` enum('cutting','stitching','polishing','coating','printing','assembly','machining','packing','finishing','other') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'other',
  `source_type` enum('manual','production_order','sales_order','rework','other') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'manual',
  `source_document_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `source_document_id` bigint UNSIGNED DEFAULT NULL,
  `issue_warehouse_id` bigint UNSIGNED NOT NULL,
  `receipt_warehouse_id` bigint UNSIGNED NOT NULL,
  `expected_return_date` date DEFAULT NULL,
  `jobwork_status` enum('draft','released','partially_dispatched','fully_dispatched','partially_received','fully_received','closed','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `approved_by` bigint UNSIGNED DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobwork_order_materials`
--

CREATE TABLE `jobwork_order_materials` (
  `id` bigint UNSIGNED NOT NULL,
  `jobwork_order_id` bigint UNSIGNED NOT NULL,
  `line_no` int NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `line_type` enum('raw_material','semi_finished','packing_material','consumable') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'raw_material',
  `planned_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `dispatched_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `received_back_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `consumed_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `pending_with_vendor_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `standard_rate` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `standard_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobwork_order_outputs`
--

CREATE TABLE `jobwork_order_outputs` (
  `id` bigint UNSIGNED NOT NULL,
  `jobwork_order_id` bigint UNSIGNED NOT NULL,
  `line_no` int NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `output_type` enum('processed_material','semi_finished','finished_goods','by_product','scrap') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'processed_material',
  `planned_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `received_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `rejected_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `accepted_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `standard_rate` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `standard_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobwork_receipts`
--

CREATE TABLE `jobwork_receipts` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `receipt_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `receipt_date` date NOT NULL,
  `jobwork_order_id` bigint UNSIGNED NOT NULL,
  `supplier_party_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED NOT NULL,
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `supplier_dc_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `supplier_dc_date` date DEFAULT NULL,
  `vehicle_no` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `transporter_party_id` bigint UNSIGNED DEFAULT NULL,
  `lr_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `lr_date` date DEFAULT NULL,
  `receipt_status` enum('draft','posted','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `receipt_mode` enum('material_return','processed_receipt','partial_return','mixed') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'processed_receipt',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `posted_by` bigint UNSIGNED DEFAULT NULL,
  `posted_at` datetime DEFAULT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobwork_receipt_lines`
--

CREATE TABLE `jobwork_receipt_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `jobwork_receipt_id` bigint UNSIGNED NOT NULL,
  `jobwork_order_output_id` bigint UNSIGNED DEFAULT NULL,
  `line_no` int NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED NOT NULL,
  `batch_id` bigint UNSIGNED DEFAULT NULL,
  `serial_id` bigint UNSIGNED DEFAULT NULL,
  `receipt_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `accepted_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `rejected_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `output_type` enum('processed_material','semi_finished','finished_goods','by_product','scrap') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'processed_material',
  `unit_cost` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `total_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `leave_requests`
--

CREATE TABLE `leave_requests` (
  `id` bigint UNSIGNED NOT NULL,
  `employee_id` bigint UNSIGNED DEFAULT NULL,
  `leave_type_id` bigint UNSIGNED DEFAULT NULL,
  `from_date` date DEFAULT NULL,
  `to_date` date DEFAULT NULL,
  `reason` text COLLATE utf8mb4_unicode_ci,
  `cl_approved_days` decimal(8,2) DEFAULT NULL,
  `lop_days` decimal(8,2) DEFAULT NULL,
  `status` enum('pending','approved','rejected') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `approved_by` bigint UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `leave_types`
--

CREATE TABLE `leave_types` (
  `id` bigint UNSIGNED NOT NULL,
  `leave_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `leave_code` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `max_days_per_year` int DEFAULT NULL,
  `is_paid` tinyint(1) DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `login_history`
--

CREATE TABLE `login_history` (
  `id` bigint UNSIGNED NOT NULL,
  `user_id` bigint UNSIGNED NOT NULL,
  `login_at` datetime NOT NULL,
  `logout_at` datetime DEFAULT NULL,
  `login_status` enum('success','failed','blocked') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'success',
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `host_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` text COLLATE utf8mb4_unicode_ci,
  `device_type` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `browser` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `os` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `session_token` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `login_history`
--

INSERT INTO `login_history` (`id`, `user_id`, `login_at`, `logout_at`, `login_status`, `ip_address`, `host_name`, `user_agent`, `device_type`, `browser`, `os`, `session_token`, `remarks`, `created_at`) VALUES
(482, 2, '2026-06-19 04:44:31', NULL, 'success', '192.168.31.92', 'POOJA-PC.lan', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36', 'Desktop', 'Chrome', 'Windows', 'cebfb958cb40c2e6a12614c859b64342a69a8a195b3a7257dbfc1628d013cfdf', 'Login successful', '2026-06-19 04:44:31'),
(483, 4, '2026-06-19 06:45:51', NULL, 'success', '192.168.31.9', 'DESKTOP-KAOIOJP.lan', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36', 'Desktop', 'Chrome', 'Windows', '6094ad7daa5a9a2aa3e3c41bdf5bcd5b45cf6c517a975d1d617890c30a249a8c', 'Login successful', '2026-06-19 06:45:51'),
(484, 4, '2026-06-20 04:40:42', NULL, 'success', '192.168.31.9', 'DESKTOP-KAOIOJP.lan', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36', 'Desktop', 'Chrome', 'Windows', '1addd06d55bfb4659a1782e3fb3e0a9d5d15d74fa947b5384fc136e0c311d34a', 'Login successful', '2026-06-20 04:40:42');

-- --------------------------------------------------------

--
-- Table structure for table `maintenance_plans`
--

CREATE TABLE `maintenance_plans` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `plan_code` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `plan_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `maintenance_type` enum('preventive','predictive','periodic','calibration','inspection','cleaning','lubrication','overhaul','other') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'preventive',
  `schedule_basis` enum('daily','weekly','monthly','quarterly','half_yearly','yearly','running_hours','manual') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'monthly',
  `frequency_value` int NOT NULL DEFAULT '1',
  `checklist_notes` text COLLATE utf8mb4_unicode_ci,
  `is_auto_generate_request` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `maintenance_plan_assets`
--

CREATE TABLE `maintenance_plan_assets` (
  `id` bigint UNSIGNED NOT NULL,
  `maintenance_plan_id` bigint UNSIGNED NOT NULL,
  `asset_id` bigint UNSIGNED NOT NULL,
  `last_service_date` date DEFAULT NULL,
  `next_service_due_date` date DEFAULT NULL,
  `running_hours_threshold` decimal(18,2) DEFAULT NULL,
  `current_running_hours` decimal(18,2) NOT NULL DEFAULT '0.00',
  `assigned_vendor_party_id` bigint UNSIGNED DEFAULT NULL,
  `assigned_internal_team` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `maintenance_requests`
--

CREATE TABLE `maintenance_requests` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED DEFAULT NULL,
  `location_id` bigint UNSIGNED DEFAULT NULL,
  `request_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `request_date` date NOT NULL,
  `asset_id` bigint UNSIGNED NOT NULL,
  `maintenance_plan_id` bigint UNSIGNED DEFAULT NULL,
  `request_type` enum('breakdown','preventive','inspection','calibration','cleaning','service','other') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'breakdown',
  `priority_level` enum('low','normal','high','critical') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'normal',
  `issue_title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `issue_description` text COLLATE utf8mb4_unicode_ci,
  `requested_by` bigint UNSIGNED DEFAULT NULL,
  `request_status` enum('draft','open','approved','assigned','in_progress','completed','cancelled','rejected') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `approved_by` bigint UNSIGNED DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `target_completion_date` date DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `maintenance_work_orders`
--

CREATE TABLE `maintenance_work_orders` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED DEFAULT NULL,
  `location_id` bigint UNSIGNED DEFAULT NULL,
  `financial_year_id` bigint UNSIGNED DEFAULT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `work_order_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `work_order_date` date NOT NULL,
  `maintenance_request_id` bigint UNSIGNED DEFAULT NULL,
  `asset_id` bigint UNSIGNED NOT NULL,
  `maintenance_plan_id` bigint UNSIGNED DEFAULT NULL,
  `work_order_type` enum('breakdown','preventive','inspection','calibration','service','overhaul','other') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'breakdown',
  `execution_mode` enum('internal','external_vendor','amc','mixed') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'internal',
  `vendor_party_id` bigint UNSIGNED DEFAULT NULL,
  `assigned_technician` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `assigned_team` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `work_order_status` enum('draft','approved','assigned','in_progress','waiting_parts','waiting_vendor','completed','closed','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `fault_description` text COLLATE utf8mb4_unicode_ci,
  `action_taken` text COLLATE utf8mb4_unicode_ci,
  `resolution_summary` text COLLATE utf8mb4_unicode_ci,
  `planned_start_datetime` datetime DEFAULT NULL,
  `planned_end_datetime` datetime DEFAULT NULL,
  `actual_start_datetime` datetime DEFAULT NULL,
  `actual_end_datetime` datetime DEFAULT NULL,
  `downtime_minutes` decimal(18,2) NOT NULL DEFAULT '0.00',
  `labor_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `spare_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `external_service_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `other_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `total_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `approved_by` bigint UNSIGNED DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `closed_by` bigint UNSIGNED DEFAULT NULL,
  `closed_at` datetime DEFAULT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `maintenance_work_order_services`
--

CREATE TABLE `maintenance_work_order_services` (
  `id` bigint UNSIGNED NOT NULL,
  `maintenance_work_order_id` bigint UNSIGNED NOT NULL,
  `line_no` int NOT NULL,
  `service_description` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `vendor_party_id` bigint UNSIGNED DEFAULT NULL,
  `purchase_invoice_id` bigint UNSIGNED DEFAULT NULL,
  `qty` decimal(18,6) NOT NULL DEFAULT '1.000000',
  `rate` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `tax_code_id` bigint UNSIGNED DEFAULT NULL,
  `tax_percent` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `tax_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `line_total` decimal(18,2) NOT NULL DEFAULT '0.00',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `maintenance_work_order_spares`
--

CREATE TABLE `maintenance_work_order_spares` (
  `id` bigint UNSIGNED NOT NULL,
  `maintenance_work_order_id` bigint UNSIGNED NOT NULL,
  `line_no` int NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED DEFAULT NULL,
  `batch_id` bigint UNSIGNED DEFAULT NULL,
  `serial_id` bigint UNSIGNED DEFAULT NULL,
  `required_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `issued_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `consumed_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `returned_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `unit_cost` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `total_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `issue_document_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `issue_document_id` bigint UNSIGNED DEFAULT NULL,
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `media_files`
--

CREATE TABLE `media_files` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED DEFAULT NULL,
  `module` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `document_type` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `document_id` bigint UNSIGNED DEFAULT NULL,
  `purpose` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `original_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `stored_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `file_extension` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mime_type` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `file_size` bigint UNSIGNED NOT NULL DEFAULT '0',
  `file_path` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_public` tinyint(1) NOT NULL DEFAULT '0',
  `uploaded_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `media_files`
--

INSERT INTO `media_files` (`id`, `company_id`, `module`, `document_type`, `document_id`, `purpose`, `original_name`, `stored_name`, `file_extension`, `mime_type`, `file_size`, `file_path`, `is_public`, `uploaded_by`, `created_at`) VALUES
(18, 1, 'printing', 'sales_invoice', NULL, 'print_template_image', 'unnamed.png', 'd0254296-a7a8-4cd0-be71-f3053da9c06b.png', 'png', 'image/png', 85255, 'uploads/print-templates/2026/06/d0254296-a7a8-4cd0-be71-f3053da9c06b.png', 1, 4, '2026-06-19 06:54:26');

-- --------------------------------------------------------

--
-- Table structure for table `modules`
--

CREATE TABLE `modules` (
  `id` bigint UNSIGNED NOT NULL,
  `module_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `module_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `module_group` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `route_path` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `icon_key` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `sort_order` int NOT NULL DEFAULT '0',
  `is_system` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `mrp_demands`
--

CREATE TABLE `mrp_demands` (
  `id` bigint UNSIGNED NOT NULL,
  `mrp_run_id` bigint UNSIGNED NOT NULL,
  `demand_source` enum('sales_order','sales_invoice','forecast','production_order','jobwork_order','manual','reorder_trigger') COLLATE utf8mb4_unicode_ci NOT NULL,
  `source_document_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `source_document_id` bigint UNSIGNED DEFAULT NULL,
  `source_line_id` bigint UNSIGNED DEFAULT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED DEFAULT NULL,
  `demand_date` date NOT NULL,
  `required_date` date DEFAULT NULL,
  `demand_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `fulfilled_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `pending_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `priority_level` enum('low','normal','high','critical') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'normal',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `mrp_net_requirements`
--

CREATE TABLE `mrp_net_requirements` (
  `id` bigint UNSIGNED NOT NULL,
  `mrp_run_id` bigint UNSIGNED NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED DEFAULT NULL,
  `gross_demand_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `available_supply_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `safety_stock_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `net_required_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `shortage_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `excess_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `reorder_triggered` tinyint(1) NOT NULL DEFAULT '0',
  `recommended_action` enum('none','purchase','production','jobwork','transfer') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'none',
  `recommended_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `recommended_date` date DEFAULT NULL,
  `lead_time_days` int NOT NULL DEFAULT '0',
  `planning_method` enum('manual','reorder','mrp','min_max','make_to_order','make_to_stock') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'manual',
  `procurement_type` enum('purchase','production','jobwork','transfer','mixed') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'purchase',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `mrp_recommendations`
--

CREATE TABLE `mrp_recommendations` (
  `id` bigint UNSIGNED NOT NULL,
  `mrp_run_id` bigint UNSIGNED NOT NULL,
  `mrp_net_requirement_id` bigint UNSIGNED DEFAULT NULL,
  `recommendation_type` enum('purchase_request','production_request','jobwork_request','stock_transfer_request','expedite_existing_supply','manual_review') COLLATE utf8mb4_unicode_ci NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED DEFAULT NULL,
  `recommended_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `recommended_date` date DEFAULT NULL,
  `priority_level` enum('low','normal','high','critical') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'normal',
  `supplier_party_id` bigint UNSIGNED DEFAULT NULL,
  `bom_id` bigint UNSIGNED DEFAULT NULL,
  `source_warehouse_id` bigint UNSIGNED DEFAULT NULL,
  `recommendation_status` enum('open','approved','converted','rejected','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'open',
  `converted_document_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `converted_document_id` bigint UNSIGNED DEFAULT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `approved_by` bigint UNSIGNED DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `mrp_runs`
--

CREATE TABLE `mrp_runs` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED DEFAULT NULL,
  `location_id` bigint UNSIGNED DEFAULT NULL,
  `warehouse_id` bigint UNSIGNED DEFAULT NULL,
  `planning_calendar_id` bigint UNSIGNED DEFAULT NULL,
  `run_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `run_date` date NOT NULL,
  `planning_start_date` date NOT NULL,
  `planning_end_date` date NOT NULL,
  `run_scope` enum('all_items','selected_items','selected_category','selected_warehouse') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'all_items',
  `run_mode` enum('simulation','official') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'official',
  `run_status` enum('draft','processing','completed','cancelled','failed') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `total_items_processed` int NOT NULL DEFAULT '0',
  `total_shortage_items` int NOT NULL DEFAULT '0',
  `total_recommendations` int NOT NULL DEFAULT '0',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `error_message` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `completed_by` bigint UNSIGNED DEFAULT NULL,
  `completed_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `mrp_supplies`
--

CREATE TABLE `mrp_supplies` (
  `id` bigint UNSIGNED NOT NULL,
  `mrp_run_id` bigint UNSIGNED NOT NULL,
  `supply_source` enum('on_hand_stock','purchase_order','purchase_invoice','production_order','jobwork_receipt','stock_transfer_in','manual') COLLATE utf8mb4_unicode_ci NOT NULL,
  `source_document_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `source_document_id` bigint UNSIGNED DEFAULT NULL,
  `source_line_id` bigint UNSIGNED DEFAULT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED DEFAULT NULL,
  `available_date` date NOT NULL,
  `supply_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `allocated_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `available_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `parties`
--

CREATE TABLE `parties` (
  `id` bigint UNSIGNED NOT NULL,
  `party_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `party_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `display_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `party_type_id` bigint UNSIGNED NOT NULL,
  `is_company` tinyint(1) DEFAULT '0',
  `website` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pan` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `aadhaar` varchar(12) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `default_currency` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT 'INR',
  `opening_balance` decimal(18,2) DEFAULT '0.00',
  `opening_balance_type` enum('debit','credit') COLLATE utf8mb4_unicode_ci DEFAULT 'debit',
  `is_active` tinyint(1) DEFAULT '1',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `parties`
--

INSERT INTO `parties` (`id`, `party_code`, `party_name`, `display_name`, `party_type_id`, `is_company`, `website`, `pan`, `aadhaar`, `default_currency`, `opening_balance`, `opening_balance_type`, `is_active`, `remarks`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(1, 'CUS/00001', 'R.K.S Enterprices', 'R.K.S Enterprices', 1, 0, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 3, 3, '2026-05-06 23:39:45', '2026-05-06 23:39:45'),
(2, 'CUS/00002', 'MARLINTEK', 'MARLINTEK', 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 4, 4, '2026-05-07 06:44:11', '2026-05-07 06:44:11'),
(3, 'CUS/00003', 'SKYWAYS ELECTRONICS', NULL, 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'credit', 1, NULL, 4, 4, '2026-05-07 06:53:50', '2026-06-19 09:33:17'),
(4, 'CUS/00004', 'CLASSIC TRADERS', 'CLASSIC TRADERS', 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 4, 4, '2026-05-07 07:00:21', '2026-05-07 07:00:21'),
(5, 'CUS/00005', 'K.K INDUSTRIAL AUTOMATION', NULL, 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 4, 4, '2026-05-07 07:12:49', '2026-06-19 09:39:04'),
(6, 'CUS/00006', 'SATHYAM ELECTRONICS', NULL, 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 4, 4, '2026-05-07 07:20:36', '2026-05-07 07:20:36'),
(7, 'CUS/0007', 'ANNAI ELECTRONICS', NULL, 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 4, 4, '2026-05-08 01:18:55', '2026-06-19 09:55:10'),
(8, 'CUS/0008', 'PTR ELECTRONICS', NULL, 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 4, 4, '2026-05-08 01:39:50', '2026-06-19 10:44:35'),
(9, 'CUS/0009', 'R&C ACOUSTIC ELECTRONICS', NULL, 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 4, 4, '2026-05-08 01:47:11', '2026-06-19 10:48:44'),
(10, 'CUS/0010', 'CAUVERY ELECTRONICS', NULL, 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 4, 4, '2026-05-08 01:51:12', '2026-06-19 10:56:51'),
(11, 'CUS/0011', 'RADIO PALACE', NULL, 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 4, 4, '2026-05-08 03:01:07', '2026-06-19 11:16:43'),
(12, 'CUS/0012', 'YERUKONDA SOUND SYSTEM', NULL, 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 4, 4, '2026-05-08 03:05:43', '2026-06-19 11:21:45'),
(13, 'CUS/0013', 'JAYAM ELECTRONICS', NULL, 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 4, 4, '2026-05-08 03:11:50', '2026-06-19 11:27:14'),
(14, 'CUS/0014', 'PADMA ELECTRONICS', NULL, 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 4, 4, '2026-05-08 03:18:19', '2026-06-19 11:30:07'),
(15, 'CUS/0015', 'GRAACE AUDIO VISSION', NULL, 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 4, 4, '2026-05-08 03:26:16', '2026-06-19 11:37:19'),
(16, 'CUS/0016', 'SHANTHI ELECTRONICS', NULL, 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 4, 4, '2026-05-08 03:32:17', '2026-06-19 11:48:37'),
(17, 'CUS/0017', 'SRI SHARADAHA ELECTRONICS', 'SRI SHARADAHA ELECTRONICS', 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 4, 4, '2026-05-08 03:36:29', '2026-06-19 12:01:50'),
(18, 'CUS/0018', 'XL ELECTRONICS', 'XL ELECTRONICS', 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'credit', 1, NULL, 4, 4, '2026-05-08 03:41:00', '2026-05-08 03:41:00'),
(19, 'CUS/0019', 'DIGITEK ELECTRONICS', 'DIGITEK ELECTRONICS', 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'credit', 1, NULL, 4, 4, '2026-05-08 03:49:06', '2026-05-08 03:49:06'),
(20, 'CUS/0020', 'K.P BALU ELECTRONIKA', NULL, 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'credit', 1, NULL, 4, 4, '2026-05-08 03:53:39', '2026-05-08 03:53:39'),
(21, 'CUS/0021', 'BHARATH ELECTRONICS', 'BHARATH ELECTRONICS', 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'credit', 1, NULL, 4, 4, '2026-05-08 03:59:23', '2026-05-08 03:59:23'),
(22, 'CUS/0022', 'GANESH TRONICS', NULL, 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'credit', 1, NULL, 4, 4, '2026-05-08 04:03:38', '2026-05-08 04:03:38'),
(23, 'CUS/0023', 'ANANTH ELECTRONICS', 'ANANTH ELECTRONICS', 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'credit', 1, NULL, 4, 4, '2026-05-08 04:13:49', '2026-05-08 04:13:49'),
(24, 'CUS/0024', 'VENKAT', 'VENKAT', 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'credit', 1, NULL, 4, 4, '2026-05-08 04:42:46', '2026-05-08 04:42:46'),
(25, 'CUS/0025', 'TDConnex (chennai)  PVT LIMITED', NULL, 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'credit', 1, NULL, 4, 4, '2026-05-08 04:55:00', '2026-05-08 04:55:00'),
(26, 'CUS/0026', 'JENESIS HORIZON PVT LTD', 'JENESIS HORIZON PVT LTD', 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'credit', 1, NULL, 4, 4, '2026-05-08 05:13:19', '2026-05-08 05:13:19'),
(27, 'CUS/0027', 'LEE PRO DIGICARE', 'LEE PRO DIGICARE', 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'credit', 1, NULL, 4, 4, '2026-05-08 05:28:47', '2026-05-08 05:28:47'),
(28, 'CUS/0028', 'V. MOHAN', 'V. MOHAN', 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'credit', 1, NULL, 4, 4, '2026-05-08 05:34:32', '2026-05-08 05:34:32'),
(29, 'CUS/0029', 'S.VENKATASAN', 'S.VENKATASAN', 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'credit', 1, NULL, 4, 4, '2026-05-08 05:38:57', '2026-05-08 05:38:57'),
(30, 'CUS/0030', 'LAHARI ELECTRONICS', 'LAHARI ELECTRONICS', 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'credit', 1, NULL, 4, 4, '2026-05-08 05:45:43', '2026-05-08 05:45:43'),
(31, 'CUS/0031', 'AMMAJI ENTERPRISES', 'AMMAJI ENTERPRISES', 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'credit', 1, NULL, 4, 4, '2026-05-08 05:49:55', '2026-05-08 05:49:55'),
(32, 'CUS/0032', 'DINESH', 'DINESH', 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'credit', 1, NULL, 4, 4, '2026-05-08 05:54:13', '2026-05-08 05:54:13'),
(33, 'CUS/0033', 'K.RAVI', 'K.RAVI', 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'credit', 1, NULL, 4, 4, '2026-05-08 05:57:59', '2026-05-08 06:04:20'),
(34, 'CUS/0034', 'Dinesh Aneja', 'Dinesh Aneja', 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'credit', 1, NULL, 4, 4, '2026-05-08 06:13:38', '2026-05-08 06:13:38'),
(35, 'CUS/0035', 'Manikandan', 'Manikandan', 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'credit', 1, NULL, 4, 4, '2026-05-08 06:18:33', '2026-05-08 06:18:33'),
(36, 'CUS/0036', 'VIJAYABASKAR', 'VIJAYABASKAR', 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'credit', 1, NULL, 4, 4, '2026-05-08 06:23:30', '2026-05-08 06:23:30'),
(37, 'CUS/0037', 'RAMESH', 'RAMESH', 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'credit', 1, NULL, 4, 4, '2026-05-08 06:28:18', '2026-05-08 06:28:18'),
(38, 'CUS/0038', 'balaji', NULL, 1, 0, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 6, 6, '2026-05-09 01:56:26', '2026-05-09 01:56:26'),
(39, 'CUS/0039', 'Lixon', 'Economic Scales', 1, 1, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 6, 6, '2026-05-09 03:46:50', '2026-05-09 03:46:50'),
(40, 'CUS/0040', 'Yuvaraj', 'Yuvaraj', 1, 0, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 6, 2, '2026-05-09 03:57:42', '2026-05-30 05:27:18'),
(41, 'CUS/0041', 'Testing', 'Testing', 1, 0, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 6, 6, '2026-05-11 05:03:19', '2026-05-11 05:03:19'),
(42, 'SUP/0001', 'MACFOS LIMITED', 'MACFOS LIMITED', 2, 1, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 4, 4, '2026-05-12 02:57:42', '2026-05-12 02:57:42'),
(43, 'SUP/0002', 'HUBTRONICS', 'HUBTRONICS', 2, 1, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 4, 4, '2026-05-12 03:33:24', '2026-05-12 03:33:24'),
(44, 'SUP/0003', 'STERLING ELECTRONICS', 'STERLING ELECTRONICS', 2, 1, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 4, 4, '2026-05-12 03:44:55', '2026-05-12 03:44:55'),
(45, 'SUP/0004', 'OM ELECTRONICS', 'OM ELECTRONICS', 2, 1, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 4, 4, '2026-05-12 03:55:25', '2026-05-12 03:55:25'),
(46, 'SUP/0005', 'MADRAS ELECTRONICS COMPONENTS', NULL, 2, 1, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 4, 4, '2026-05-12 04:04:05', '2026-05-12 04:04:05'),
(47, 'SUP/0006', 'Lion Circuits', NULL, 2, 1, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 4, 4, '2026-05-29 04:27:46', '2026-05-29 04:27:46'),
(48, 'SUP/0007', 'Therrmo Tec', NULL, 2, 1, NULL, NULL, NULL, 'INR', 0.00, 'debit', 1, NULL, 4, 4, '2026-06-01 06:32:19', '2026-06-01 06:32:19');

-- --------------------------------------------------------

--
-- Table structure for table `party_accounts`
--

CREATE TABLE `party_accounts` (
  `id` bigint UNSIGNED NOT NULL,
  `party_id` bigint UNSIGNED NOT NULL,
  `account_id` bigint UNSIGNED NOT NULL,
  `account_purpose` enum('primary','receivable','payable','advance','salary','commission','other') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'primary',
  `is_default` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `party_accounts`
--

INSERT INTO `party_accounts` (`id`, `party_id`, `account_id`, `account_purpose`, `is_default`, `is_active`, `remarks`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(97, 25, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(98, 48, 4, 'payable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(99, 47, 4, 'payable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(100, 46, 4, 'payable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(101, 38, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(102, 22, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(103, 20, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(104, 15, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(105, 14, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(106, 6, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(107, 31, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(108, 23, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(109, 7, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(110, 21, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(111, 10, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(112, 4, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(113, 19, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(114, 32, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(115, 34, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(116, 39, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(117, 43, 4, 'payable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(118, 13, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(119, 26, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(120, 5, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(121, 33, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(122, 30, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(123, 27, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(124, 42, 4, 'payable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(125, 35, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(126, 2, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(127, 45, 4, 'payable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(128, 8, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(129, 1, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(130, 9, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(131, 11, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(132, 37, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(133, 29, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(134, 16, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(135, 3, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(136, 17, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(137, 44, 4, 'payable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(138, 41, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(139, 28, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(140, 24, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(141, 36, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(142, 18, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(143, 12, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44'),
(144, 40, 3, 'receivable', 1, 1, 'Auto-created from document posting', 2, 2, '2026-06-19 04:48:44', '2026-06-19 04:48:44');

-- --------------------------------------------------------

--
-- Table structure for table `party_addresses`
--

CREATE TABLE `party_addresses` (
  `id` bigint UNSIGNED NOT NULL,
  `party_id` bigint UNSIGNED NOT NULL,
  `address_type` enum('billing','shipping','office','factory','other') COLLATE utf8mb4_unicode_ci DEFAULT 'billing',
  `address_line1` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address_line2` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `area` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `district` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `state_code` varchar(5) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `state_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `country_code` varchar(5) COLLATE utf8mb4_unicode_ci DEFAULT 'IN',
  `postal_code` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_default` tinyint(1) DEFAULT '0',
  `is_active` tinyint(1) DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `party_addresses`
--

INSERT INTO `party_addresses` (`id`, `party_id`, `address_type`, `address_line1`, `address_line2`, `area`, `city`, `district`, `state_code`, `state_name`, `country_code`, `postal_code`, `is_default`, `is_active`) VALUES
(1, 1, 'shipping', 'NO#27-7-7,Challapalli Bunglow Site,', NULL, 'Prakasam Road', 'Governorpet', NULL, NULL, 'Vijayawada', 'IN', '520002', 1, 1),
(2, 2, 'shipping', 'NO-153/2A, KAVASAMPATTU,', NULL, 'K.V.Kuppam Taluk,', 'Vellore', NULL, '33', 'TAMIL NADU', 'INDIA', '632204', 1, 1),
(3, 3, 'shipping', '4-3-325/5,BANK STREET', NULL, 'KOTI', 'HYDERABAD', NULL, '36', 'TELANGANA', 'IN', '500001', 1, 1),
(4, 4, 'shipping', 'NO,4 ANNA COMPLEX', NULL, 'BOSE MAIDHANAM', 'SALAM', NULL, '33', 'TAMIL NADU', 'IN', '636001', 1, 1),
(5, 5, 'shipping', '29/37,Teachers Colony', NULL, 'Muthukadai', 'Ranipet', NULL, '33', 'Tamil Nadu', 'IN', '632401', 1, 1),
(6, 6, 'shipping', 'NO.61,Super Bazar,Singarathope', NULL, NULL, 'Trichy', NULL, '33', 'Tamil Nadu', 'IN', '620008', 1, 1),
(7, 7, 'shipping', 'No.17,G.K.MOOPANAR COMPLEX,', NULL, NULL, 'VILLIANUR', NULL, '34', 'PUDUCHERRY', 'IN', '605110', 1, 1),
(8, 8, 'shipping', 'No.7, Super Bazar,', NULL, 'Singaraththope,', 'Trichy', NULL, '33', 'TAMIL NADU', 'IN', '620008', 1, 1),
(9, 9, 'shipping', '10/3, RAYYAN COMPIEX,', NULL, 'GH MAIN ROAD', 'MAYLIADUTHURAI', NULL, '33', 'TAMIL NADU', 'IN', '609001', 1, 1),
(10, 10, 'shipping', 'No.212,Nethaji Road', NULL, 'Perambalur', NULL, NULL, '33', 'TAMIL NADU', 'IN', '621212', 1, 1),
(11, 11, 'shipping', '1796,South Main Street,', NULL, NULL, 'Thanjavur', 'INDIA', '33', 'TAMIL NADU', 'IN', '613009', 1, 1),
(12, 12, 'shipping', 'D.No.8-24-121&122', NULL, 'Main Road', 'Rajahmundry', 'INDIA', '37', 'ANDHRA PRADESH', 'IN', '533101', 1, 1),
(13, 13, 'shipping', 'No.2,Anna Complex,Ragavan Road', NULL, 'Bose Maidanam', 'Salem', NULL, '33', 'TAMIL NADU', 'IN', '636001', 1, 1),
(14, 14, 'shipping', '93/45,Ranger Sannati Street', NULL, 'Near Mosque', 'Namakkal', 'INDIA', '33', 'TAMIL NADU', 'IN', '637001', 1, 1),
(15, 15, 'shipping', '1645,46 SOUTH MAIN STREET', NULL, 'RAMYA ELECTRONICS UPSTAIR', 'TANJAVUR', 'INDIA', '33', 'TAMIL NADU', 'IN', '613009', 1, 1),
(16, 16, 'shipping', '134,OPPANAKARA STREET', NULL, NULL, 'COIMABTORE', 'INDIA', '33', 'TAMIL NADU', 'IN', '641001', 1, 1),
(17, 17, 'shipping', 'OPP.BALAJI THEATRE', NULL, 'YAWAR ROAD', 'JAGITYAL', 'INDIA', '36', 'TELANGANA', 'IN', '505327', 1, 1),
(18, 18, 'shipping', 'AARTHI HOTEL BUILDING,37,', NULL, 'WEST PRADAKSHNAM ROAD', 'KARUR', 'INDIA', '33', 'TAMIL NADU', 'IN', '639001', 1, 1),
(19, 19, 'shipping', '#135,5th CROSS,', NULL, 'K.G. NAGAR', 'BANGALORE', 'INDIA', '29', 'KARNATAKA', 'IN', '560019', 1, 1),
(20, 20, 'shipping', '18,CSI COMPLEX', NULL, 'GH ROAD', 'KARUR', 'INDIA', '33', 'TAMIL NADU', 'IN', '639001', 1, 1),
(21, 21, 'shipping', 'No,44/1,SMS COMPLEX', NULL, 'BUS STAND SOUTH', 'DINDIGUL', 'INDIA', '33', 'TAMIL NADU', 'IN', '624003', 1, 1),
(22, 22, 'shipping', 'No.13-26,Ragavan Road,', NULL, 'Near Bose Maidhanam Old Bus Stand', 'Salem', 'India', '33', 'Tamil Nadu', 'IN', '636001', 1, 1),
(23, 23, 'shipping', 'D.NO,7-8-18, MALLAVARAPU VARI STREET,', NULL, NULL, 'VISAKHPATNAM', 'INDIA', '37', 'ANTRA PRADESH', 'IN', '531001', 1, 1),
(24, 24, 'shipping', '2XFW+V58 UNUGUNTAPALEM PRIMARY', NULL, 'AGRICULTURAL COOPERATIVE SOCIETY, V 852,', 'RUDRAVARAM', 'INDIA', '37', 'ANDHRA PRADESH', 'IN', '524413', 1, 1),
(25, 25, 'shipping', 'GB 220, Green Base Industrial&Logistics Park Hiranandani Parks,', NULL, 'Thriveni Nagar,Vadakkupattu', 'Kancheepuram', 'India', '33', 'Tamil Nadu', 'IN', '603204', 1, 1),
(26, 26, 'shipping', '1-8,Rajeshwari Nagar,', NULL, 'Thirumazhisai', 'Chennai', 'India', '33', 'Tamil Nadu', 'IN', '600124', 1, 1),
(27, 27, 'shipping', 'No,16B/2, navalan nedunchezhian street', NULL, 'Arcot', 'Ranipet', 'India', '33', 'Tamil Nadu', 'IN', '632503', 1, 1),
(28, 28, 'shipping', 'No.48,Main Road', NULL, 'Chinna Allapuram', 'Vellore', 'India', '33', 'Tamil Nadu', 'IN', NULL, 1, 1),
(29, 29, 'shipping', 'NO.2/38,East Road,Vilaripalayam,', NULL, 'Vazhapadi', 'Salem', 'Tamil Nadu', '33', 'Tamil Nadu', 'IN', '636115', 1, 1),
(30, 30, 'shipping', 'MEDAK', NULL, NULL, 'Medak', 'INDIA', '36', 'TELANGANA', 'IN', '502110', 1, 1),
(31, 31, 'shipping', 'Old Warangal Bypass Road,', NULL, 'Behind hp petrol lane', 'Edulapuram', 'India', '36', 'Telangana', 'IN', '507002', 1, 1),
(32, 32, 'shipping', 'No.405,Road Street,', NULL, 'Melpakkam', 'Arakkonam', 'India', '33', 'Tamil Nadu', 'IN', '631002', 1, 1),
(33, 33, 'shipping', 'Sri Srinivasa Electricals opp New Bustand Gadwal,', NULL, '(M),Jogulaba Gadwa(D)', 'Telangana Gadwal', 'India', '36', 'Telangana', 'IN', '509125', 1, 1),
(34, 34, 'shipping', 'Artvillage Farm Anandvan Farm Road End', NULL, 'Faridabad', NULL, 'India', '06', 'Haryana', 'IN', '121003', 1, 1),
(35, 35, 'shipping', 'No,519,Kovil Street,T.K. Anna Nagar,', NULL, 'Chengalnattham Post', 'Ranipet', 'India', '33', 'Tamil Nadu', 'IN', NULL, 1, 1),
(36, 36, 'shipping', 'Dakkili Mandalam Chappalapalli Village & Post', NULL, NULL, 'Thirupathi Jilla', 'India', '37', 'Tamil Nadu', 'IN', '524134', 1, 1),
(37, 37, 'shipping', 'Bethastha Calla,No.2,Brittania Nagar,', NULL, 'Veltech Road,Kollumedu,', 'Vellanur,Avadi tk.', 'India', '33', 'Tamil Nadu', 'IN', '600062', 1, 1),
(38, 38, 'shipping', '272', NULL, NULL, 'vellore', NULL, NULL, NULL, 'IN', '635809', 0, 1),
(39, 39, 'billing', '58, Munichalai Road,Near Primary Health centre,', NULL, 'Madurai', NULL, 'madurai', NULL, 'Tamil Nadu', 'IN', '625009', 0, 1),
(40, 40, 'billing', '1, Sevoor', NULL, 'Karunai Nagar', 'Vellore', 'Vellore', NULL, 'Tamil Nadu', 'IN', '632006', 0, 1),
(41, 42, 'other', 'Sumant Building, Dynamic Logistics Trade Park Survey No.78/1 Dighi,', NULL, 'Bhosari Alandi Road', 'Pune', 'India', '27', 'Maharashtra', 'IN', '411015', 1, 1),
(42, 43, 'billing', '1 punyoday Apartment Survey No 26 CTS 1352 Aundh Wakad Road', NULL, 'Pimpri Chinchwad', 'PUNE', 'India', '27', 'Maharashtra', 'IN', '411027', 1, 1),
(43, 44, 'billing', '20-B Gr.Floor, Vijay Chambers', NULL, 'Opp Dreamland Cinema, Lamington Rd', 'Mumbai', 'India', '27', 'Maharashtra', 'IN', '400004', 1, 1),
(44, 45, 'billing', 'No.2 SEEYALLI AMMAN KOVIL STREET', NULL, NULL, 'CHINTHADRIPET', 'INDIA', '33', 'TAMIL NADU', 'IN', '600002', 1, 1),
(45, 46, 'billing', 'No.26A, Meeran Sahip Street,', NULL, 'Mount Road', 'Chennai', 'India', '33', 'Tamil Nadu', 'IN', '600 002', 1, 1),
(46, 41, 'billing', '272', NULL, NULL, 'palligonda', 'vellore', NULL, 'tamilnadu', 'IN', '635809', 0, 1),
(47, 48, 'billing', 'No.241/2A1,Sipcot,Vanapadi,Road,', NULL, 'Near Stahi India', 'Ranipet', 'India', NULL, 'Tamil Nadu', 'IN', '632403', 1, 1);

-- --------------------------------------------------------

--
-- Table structure for table `party_bank_accounts`
--

CREATE TABLE `party_bank_accounts` (
  `id` bigint UNSIGNED NOT NULL,
  `party_id` bigint UNSIGNED NOT NULL,
  `account_holder_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `account_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bank_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `branch_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ifsc_code` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `swift_code` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `iban` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `upi_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_default` tinyint(1) DEFAULT '0',
  `is_active` tinyint(1) DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `party_contacts`
--

CREATE TABLE `party_contacts` (
  `id` bigint UNSIGNED NOT NULL,
  `party_id` bigint UNSIGNED NOT NULL,
  `contact_name` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `designation` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mobile` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_primary` tinyint(1) DEFAULT '0',
  `is_active` tinyint(1) DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `party_contacts`
--

INSERT INTO `party_contacts` (`id`, `party_id`, `contact_name`, `designation`, `mobile`, `phone`, `email`, `is_primary`, `is_active`) VALUES
(1, 1, 'R.K.S ENTERPRICES', NULL, NULL, '9866842671', NULL, 0, 1),
(2, 2, 'JAWAGAR MANI', NULL, NULL, '8122023344', NULL, 1, 1),
(3, 3, 'SKYWAYS ELECTRONICS', NULL, NULL, '8897547888', NULL, 1, 1),
(4, 4, 'CLASSIC TRADERS', NULL, NULL, '9597422486', NULL, 1, 1),
(5, 5, 'K.K INDUSTRIAL AUTOMATION', NULL, NULL, '9944458633', NULL, 1, 1),
(6, 7, 'ANNAI ELECTRONICS', NULL, NULL, '9443043278', NULL, 0, 1),
(7, 8, 'PTR ELECTRONICS', NULL, NULL, '9842022624', NULL, 1, 1),
(8, 9, 'R&C ACOUSTIC ELECTRONICS', NULL, NULL, '9677600725', NULL, 1, 1),
(9, 10, 'CAUVERY ELECTRONICS', NULL, NULL, '9443635368', NULL, 1, 1),
(10, 11, 'RADIO PALACE', NULL, NULL, '9894533646', NULL, 1, 1),
(11, 12, 'YERUKONDA SOUND SYSTEM', NULL, NULL, '9848873344', NULL, 1, 1),
(12, 13, 'JAYAM ELECTRONICS', NULL, NULL, '9443216166', NULL, 1, 1),
(13, 14, 'PADMA ELECTRONICS', NULL, NULL, '9443227132', NULL, 1, 1),
(14, 15, 'GRAACE AUDIO VISSION', NULL, NULL, '6381255509', NULL, 1, 1),
(15, 16, 'SHANTHI ELECTRONICS', NULL, NULL, '7708818599', NULL, 1, 1),
(16, 17, 'SRI SHARADHA ELECTRONICS', NULL, NULL, '8143835861', NULL, 1, 1),
(17, 18, 'XL ELECTRONICS', NULL, NULL, '9865965296', NULL, 1, 1),
(18, 19, 'DIGITEK ELECTRONICS', NULL, NULL, '7026311751', NULL, 1, 1),
(19, 20, 'K.P BALU ELECTRONIKA', NULL, NULL, '9944185298', NULL, 1, 1),
(20, 21, 'BHARATH ELECTRONICS', NULL, NULL, '9843084434', NULL, 1, 1),
(21, 23, 'ANANTH ELECTRONICS', NULL, NULL, '9848202658', NULL, 1, 1),
(22, 24, 'VENKAT', NULL, NULL, '72004 84865', NULL, 1, 1),
(23, 25, 'UTHAYA PRAKASH', 'PURCHASE', NULL, '9626611788', 'murali.panneerselvam@tdconnex.com', 1, 1),
(24, 26, 'THIRUVEL', 'PURCHASE', NULL, '9884804747', NULL, 1, 1),
(25, 27, 'LEE PRO DIGICARE', NULL, NULL, '9443359694', NULL, 1, 1),
(26, 28, 'V.MOHAN', NULL, NULL, '9442309156', NULL, 1, 1),
(27, 29, 'S.VENKATASAN', NULL, NULL, '9159917944', NULL, 1, 1),
(28, 30, 'LAHARI ELECTRONICS', NULL, NULL, '9440851711', NULL, 1, 1),
(29, 31, 'Ammaji Enterprises', NULL, NULL, '9849337458', NULL, 1, 1),
(30, 32, 'DINESH', NULL, NULL, '9443581214', NULL, 1, 1),
(31, 33, 'K.RAVI', NULL, NULL, '9398945835', NULL, 1, 1),
(32, 34, 'Dinesh Aneja', NULL, NULL, NULL, NULL, 0, 1),
(33, 35, 'MANIKANDAN', NULL, NULL, '9360501141', NULL, 1, 1),
(34, 36, 'VIJAYABASKAR', NULL, NULL, '9490740049', NULL, 1, 1),
(35, 37, 'Ramesh', NULL, NULL, '7200996780', NULL, 1, 1),
(36, 39, 'Lixon', NULL, '9442530062', NULL, NULL, 1, 1),
(37, 40, 'Yuvaraj', 'Marketing', '9443091525', NULL, NULL, 0, 1),
(38, 42, 'MACFOS LIMITED', NULL, NULL, NULL, NULL, 0, 1),
(39, 43, 'HUBTRONICS', NULL, NULL, '02269622847', 'sales@hubtronics.in', 1, 1),
(40, 44, 'STERLING ELECTRONICS', NULL, NULL, '9869610404', 'sanju_sterling@rediffmail.com', 1, 1),
(41, 45, 'OM ELECTRONICS', NULL, NULL, NULL, NULL, 1, 1),
(42, 46, 'MADRAS ELECTRONICS COMPONENTS', NULL, NULL, '42168596', 'mec_chennai@yahoo.co.uk', 1, 1),
(43, 48, 'Therrmo Tec', NULL, '9894201021', NULL, 'therrmotecranipet@gmail.com', 1, 1),
(46, 6, 'SATHYAM ELECTRONICS', NULL, '9486470124', NULL, NULL, 1, 1);

-- --------------------------------------------------------

--
-- Table structure for table `party_credit_limits`
--

CREATE TABLE `party_credit_limits` (
  `id` bigint UNSIGNED NOT NULL,
  `party_id` bigint UNSIGNED NOT NULL,
  `credit_limit` decimal(18,2) DEFAULT '0.00',
  `credit_days` int DEFAULT '0',
  `effective_from` date DEFAULT NULL,
  `effective_to` date DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `party_gst_details`
--

CREATE TABLE `party_gst_details` (
  `id` bigint UNSIGNED NOT NULL,
  `party_id` bigint UNSIGNED NOT NULL,
  `gstin` varchar(15) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `legal_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `trade_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `state_code` varchar(5) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `state_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `registration_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address_line1` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address_line2` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `district` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `postal_code` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_default` tinyint(1) DEFAULT '1',
  `is_active` tinyint(1) DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `party_gst_details`
--

INSERT INTO `party_gst_details` (`id`, `party_id`, `gstin`, `legal_name`, `trade_name`, `state_code`, `state_name`, `registration_type`, `address_line1`, `address_line2`, `city`, `district`, `postal_code`, `is_default`, `is_active`) VALUES
(1, 1, '37ACRPK6027A1ZO', NULL, NULL, NULL, NULL, 'regular', NULL, NULL, NULL, NULL, NULL, 1, 1),
(2, 2, '33ABMFM2202R1Z2', NULL, NULL, NULL, NULL, 'regular', NULL, NULL, NULL, NULL, NULL, 0, 1),
(3, 3, '36AAGFS4164H1Z2', NULL, NULL, NULL, NULL, 'regular', NULL, NULL, NULL, NULL, NULL, 0, 1),
(4, 4, '33AGNPN4597Q1ZD', NULL, NULL, NULL, NULL, 'regular', NULL, NULL, NULL, NULL, NULL, 0, 1),
(5, 5, '33AZXPK7582P1Z6', NULL, NULL, NULL, NULL, 'regular', NULL, NULL, NULL, NULL, NULL, 0, 1),
(6, 7, '34AGJPR9177N1ZF', NULL, NULL, NULL, NULL, 'regular', NULL, NULL, NULL, NULL, NULL, 0, 1),
(7, 8, '33AABPT8385J1Z7', NULL, NULL, NULL, NULL, 'regular', NULL, NULL, NULL, NULL, NULL, 0, 1),
(8, 6, '33CDNPP1727R1ZV', NULL, NULL, NULL, NULL, 'regular', NULL, NULL, NULL, NULL, NULL, 0, 1),
(9, 9, '33ITIPS3667G1Z6', NULL, NULL, NULL, NULL, 'regular', NULL, NULL, NULL, NULL, NULL, 0, 1),
(10, 10, '33GPEPK5047E2Z1', NULL, NULL, NULL, NULL, 'regular', NULL, NULL, NULL, NULL, NULL, 0, 1),
(11, 11, '33ABXPV4535B1ZE', NULL, NULL, NULL, NULL, 'regular', NULL, NULL, NULL, NULL, NULL, 0, 1),
(12, 12, '37AAAFY6861B1Z4', NULL, NULL, NULL, NULL, 'regular', NULL, NULL, NULL, NULL, NULL, 0, 1),
(13, 13, '33ADKPT3078L1Z0', NULL, NULL, NULL, NULL, 'regular', NULL, NULL, NULL, NULL, NULL, 0, 1),
(14, 14, '33AEIPV9328J1ZX', NULL, NULL, NULL, NULL, 'regular', NULL, NULL, NULL, NULL, NULL, 0, 1),
(15, 15, '33ANLPA7340M1ZY', NULL, NULL, NULL, NULL, 'regular', NULL, NULL, NULL, NULL, NULL, 0, 1),
(16, 16, '33CVEPS6072H1ZD', NULL, NULL, NULL, NULL, 'regular', NULL, NULL, NULL, NULL, NULL, 0, 1),
(17, 17, NULL, NULL, NULL, NULL, NULL, 'unregistered', NULL, NULL, NULL, NULL, NULL, 0, 1),
(18, 18, '33BIVPK0449M1ZR', NULL, NULL, NULL, NULL, 'regular', NULL, NULL, NULL, NULL, NULL, 0, 1),
(19, 23, '37AFTPG1719C1ZJ', NULL, NULL, NULL, NULL, 'regular', NULL, NULL, NULL, NULL, NULL, 1, 1),
(20, 25, '33AAKCT1384M1ZY', NULL, NULL, NULL, NULL, 'regular', NULL, NULL, NULL, NULL, NULL, 1, 1),
(21, 26, '33AAFCJ4873L1Z7', NULL, NULL, NULL, NULL, 'regular', NULL, NULL, NULL, NULL, NULL, 0, 1),
(22, 42, '27AALCM3536H1ZA', NULL, NULL, NULL, NULL, 'regular', NULL, NULL, NULL, NULL, NULL, 1, 1),
(23, 43, '27CXIPS5926C1Z7', NULL, NULL, NULL, NULL, 'regular', NULL, NULL, NULL, NULL, NULL, 1, 1),
(24, 44, '27AELPJ3126R1ZZ', NULL, NULL, NULL, NULL, 'regular', NULL, NULL, NULL, NULL, NULL, 1, 1),
(25, 45, '33AABPK3101B1ZT', 'OM ELECTRONICS', 'OM ELECTRONICS', '33', 'TAMIL NADU', 'regular', 'No.2 SEEYALLI AMMAN KOVIL STREET', NULL, 'CHNTHADRIPET', 'INDIA', '600002', 1, 1),
(26, 46, '33AAMFM9988P1Z1', 'MADRAS ELECTRONICS COMPONENTS', 'MADRAS ELECTRONICS COMPONENTS', '33', 'Tamil Nadu', 'regular', 'No.26A, Meeran Sahip Street,Mount Road', NULL, 'Chennai', 'India', '600002', 1, 1),
(27, 48, '33ADZPN4318E1ZD', NULL, NULL, NULL, NULL, 'regular', NULL, NULL, NULL, NULL, NULL, 0, 1);

-- --------------------------------------------------------

--
-- Table structure for table `party_payment_terms`
--

CREATE TABLE `party_payment_terms` (
  `id` bigint UNSIGNED NOT NULL,
  `party_id` bigint UNSIGNED NOT NULL,
  `term_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `days` int DEFAULT '0',
  `due_basis` enum('invoice_date','bill_date','dispatch_date','end_of_month','fixed_days') COLLATE utf8mb4_unicode_ci DEFAULT 'invoice_date',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `is_default` tinyint(1) DEFAULT '0',
  `is_active` tinyint(1) DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `party_payment_terms`
--

INSERT INTO `party_payment_terms` (`id`, `party_id`, `term_name`, `days`, `due_basis`, `remarks`, `is_default`, `is_active`) VALUES
(1, 39, 'Quotation', 0, 'invoice_date', NULL, 0, 1);

-- --------------------------------------------------------

--
-- Table structure for table `party_roles`
--

CREATE TABLE `party_roles` (
  `id` bigint UNSIGNED NOT NULL,
  `party_id` bigint UNSIGNED NOT NULL,
  `party_type_id` bigint UNSIGNED NOT NULL,
  `is_active` tinyint(1) DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `party_roles`
--

INSERT INTO `party_roles` (`id`, `party_id`, `party_type_id`, `is_active`) VALUES
(1, 1, 1, 1),
(2, 2, 1, 1),
(3, 3, 1, 1),
(4, 4, 1, 1),
(5, 5, 1, 1),
(6, 6, 1, 1),
(7, 7, 1, 1),
(8, 8, 1, 1),
(9, 9, 1, 1),
(10, 10, 1, 1),
(11, 11, 1, 1),
(12, 12, 1, 1),
(13, 13, 1, 1),
(14, 14, 1, 1),
(15, 15, 1, 1),
(16, 16, 1, 1),
(17, 17, 1, 1),
(18, 18, 1, 1),
(19, 19, 1, 1),
(20, 20, 1, 1),
(21, 21, 1, 1),
(22, 22, 1, 1),
(23, 23, 1, 1),
(24, 24, 1, 1),
(25, 25, 1, 1),
(26, 26, 1, 1),
(27, 27, 1, 1),
(28, 28, 1, 1),
(29, 29, 1, 1),
(30, 30, 1, 1),
(31, 31, 1, 1),
(32, 32, 1, 1),
(33, 33, 1, 1),
(34, 34, 1, 1),
(35, 35, 1, 1),
(36, 36, 1, 1),
(37, 37, 1, 1),
(38, 38, 1, 1),
(39, 39, 1, 1),
(40, 40, 1, 1),
(41, 41, 1, 1),
(42, 42, 2, 1),
(43, 43, 2, 1),
(44, 44, 2, 1),
(45, 45, 2, 1),
(46, 46, 2, 1),
(47, 47, 2, 1),
(48, 48, 2, 1);

-- --------------------------------------------------------

--
-- Table structure for table `party_types`
--

CREATE TABLE `party_types` (
  `id` bigint UNSIGNED NOT NULL,
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_system` tinyint(1) DEFAULT '1',
  `is_active` tinyint(1) DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `party_types`
--

INSERT INTO `party_types` (`id`, `code`, `name`, `is_system`, `is_active`) VALUES
(1, 'CUSTOMER', 'Customer', 1, 1),
(2, 'SUPPLIER', 'Supplier', 1, 1),
(3, 'JOB_WORKER', 'Job Worker', 1, 1),
(4, 'TRANSPORTER', 'Transporter', 1, 1),
(5, 'GENERAL', 'General', 1, 1);

-- --------------------------------------------------------

--
-- Table structure for table `payroll_lines`
--

CREATE TABLE `payroll_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `payroll_run_id` bigint UNSIGNED DEFAULT NULL,
  `employee_id` bigint UNSIGNED DEFAULT NULL,
  `gross_salary` decimal(18,2) DEFAULT NULL,
  `total_deductions` decimal(18,2) DEFAULT NULL,
  `net_salary` decimal(18,2) DEFAULT NULL,
  `working_days` int DEFAULT NULL,
  `present_days` int DEFAULT NULL,
  `leave_days` int DEFAULT NULL,
  `lop_days` decimal(8,2) DEFAULT '0.00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `payroll_runs`
--

CREATE TABLE `payroll_runs` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED DEFAULT NULL,
  `payroll_month` int DEFAULT NULL,
  `payroll_year` int DEFAULT NULL,
  `run_date` date DEFAULT NULL,
  `status` enum('draft','processed','posted') COLLATE utf8mb4_unicode_ci DEFAULT 'draft',
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `payslips`
--

CREATE TABLE `payslips` (
  `id` bigint UNSIGNED NOT NULL,
  `payroll_line_id` bigint UNSIGNED DEFAULT NULL,
  `payslip_date` date DEFAULT NULL,
  `generated_by` bigint UNSIGNED DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `permissions`
--

CREATE TABLE `permissions` (
  `id` bigint UNSIGNED NOT NULL,
  `module` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `is_system_permission` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `planning_calendars`
--

CREATE TABLE `planning_calendars` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `calendar_code` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `calendar_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `planning_frequency` enum('daily','weekly','monthly','custom') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'weekly',
  `week_start_day` enum('monday','tuesday','wednesday','thursday','friday','saturday','sunday') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'monday',
  `is_default` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `posting_rules`
--

CREATE TABLE `posting_rules` (
  `id` bigint UNSIGNED NOT NULL,
  `posting_rule_group_id` bigint UNSIGNED NOT NULL,
  `line_no` int NOT NULL,
  `entry_side` enum('debit','credit') COLLATE utf8mb4_unicode_ci NOT NULL,
  `account_source_type` enum('fixed_account','customer_control_account','supplier_control_account','item_sales_account','item_purchase_account','tax_output_cgst_account','tax_output_sgst_account','tax_output_igst_account','tax_input_cgst_account','tax_input_sgst_account','tax_input_igst_account','cash_bank_account','round_off_account','discount_account','returns_account','stock_account','cogs_account') COLLATE utf8mb4_unicode_ci NOT NULL,
  `fixed_account_id` bigint UNSIGNED DEFAULT NULL,
  `amount_source` enum('subtotal','discount_amount','taxable_amount','cgst_amount','sgst_amount','igst_amount','cess_amount','round_off_amount','total_amount','paid_amount','balance_amount','stock_value','cogs_value') COLLATE utf8mb4_unicode_ci NOT NULL,
  `narration_template` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `priority_order` int NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `posting_rule_groups`
--

CREATE TABLE `posting_rule_groups` (
  `id` bigint UNSIGNED NOT NULL,
  `group_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `group_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `document_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `trigger_event` enum('on_save','on_approve','on_post','on_cancel','on_reverse') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'on_post',
  `description` text COLLATE utf8mb4_unicode_ci,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `print_templates`
--

CREATE TABLE `print_templates` (
  `id` bigint UNSIGNED NOT NULL,
  `document_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `template_data` json NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `print_templates`
--

INSERT INTO `print_templates` (`id`, `document_type`, `template_data`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'sales_quotation', '{\"shapes\": [{\"x\": 29, \"y\": 28, \"id\": \"pbs-outer-border\", \"bold\": false, \"text\": \"\", \"type\": \"rectangle\", \"align\": \"left\", \"sides\": 5, \"width\": 537, \"height\": 786, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4282156725, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4282156725, \"headerTextColor\": 4279310375}, {\"x\": 102.35546875, \"y\": 34.40234375, \"id\": \"text-doc-type\", \"bold\": true, \"text\": \"QUOTATION\", \"type\": \"text\", \"align\": \"center\", \"sides\": 5, \"width\": 160, \"height\": 18, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 11, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 368, \"y\": 32, \"id\": \"gstin-label\", \"bold\": false, \"text\": \"GSTIN :\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 42, \"height\": 18, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 412, \"y\": 32, \"id\": \"gstin-value\", \"bold\": true, \"text\": \"{{company_gstin}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 148, \"height\": 18, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 29, \"y\": 54, \"id\": \"header-top-divider\", \"bold\": false, \"text\": \"\", \"type\": \"line\", \"align\": \"left\", \"sides\": 5, \"width\": 537, \"height\": 0, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4289111718, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4289111718, \"headerTextColor\": 4279310375}, {\"x\": 35.125, \"y\": 56.14453125, \"id\": \"company-logo\", \"bold\": false, \"text\": \"\", \"type\": \"image\", \"align\": \"left\", \"sides\": 5, \"width\": 68.8515625, \"height\": 65.453125, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"https://bill.sakthicontroller.com/api/public/api/v1/public/media/file?path=uploads%2Fprint-templates%2F2026%2F05%2F001be57a-4299-4605-9c62-25972b1ced35.png\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 0, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 49.7734375, \"y\": 144.796875, \"id\": \"company-address\", \"bold\": false, \"text\": \"Cell : 9443036233, 9597773302\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 208.05859375, \"height\": 17.8125, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 10, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 327, \"y\": 28, \"id\": \"header-vertical-divider\", \"bold\": false, \"text\": \"\", \"type\": \"line\", \"align\": \"left\", \"sides\": 5, \"width\": 0, \"height\": 152, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4289111718, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4289111718, \"headerTextColor\": 4279310375}, {\"x\": 334, \"y\": 58, \"id\": \"customer-label\", \"bold\": true, \"text\": \"Customer\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 230, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 334, \"y\": 76, \"id\": \"party-text\", \"bold\": false, \"text\": \"{{party_name}}\\n{{party_address}}\\n{{party_contact}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 228, \"height\": 64, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 335.6328125, \"y\": 142.96484375, \"id\": \"customer-gstn-label\", \"bold\": false, \"text\": \"Customer GSTN :{{party_gstin}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 186.5859375, \"height\": 16.8125, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 29, \"y\": 180, \"id\": \"header-divider\", \"bold\": false, \"text\": \"\", \"type\": \"line\", \"align\": \"left\", \"sides\": 5, \"width\": 537, \"height\": 0, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4289111718, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4289111718, \"headerTextColor\": 4279310375}, {\"x\": 47.73828125, \"y\": 185.20703125, \"id\": \"doc-no-label\", \"bold\": false, \"text\": \"Doc No :\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 50, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 89.390625, \"y\": 186.2109375, \"id\": \"doc-no-value\", \"bold\": true, \"text\": \"{{document_number}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 110, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 222, \"y\": 186.03125, \"id\": \"date-label\", \"bold\": false, \"text\": \"Date :\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 35, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 251.26171875, \"y\": 186.4296875, \"id\": \"date-value\", \"bold\": true, \"text\": \"{{document_date}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 78, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 354.8125, \"y\": 186.234375, \"id\": \"ref-label\", \"bold\": false, \"text\": \"P.O Number:\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 68.22265625, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 409.68359375, \"y\": 187.29296875, \"id\": \"ref-value\", \"bold\": false, \"text\": \"{{reference_number}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 69.37890625, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 29, \"y\": 204, \"id\": \"lines-table\", \"bold\": false, \"text\": \"\", \"type\": \"table\", \"align\": \"left\", \"sides\": 5, \"width\": 537, \"height\": 365, \"italic\": false, \"cellGap\": 4, \"columns\": [{\"key\": \"item_name\", \"align\": \"left\", \"label\": \"Item\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 4.5}, {\"key\": \"qty\", \"align\": \"center\", \"label\": \"Qty\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 1}, {\"key\": \"rate\", \"align\": \"center\", \"label\": \"Price\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 1.5}, {\"key\": \"tax_amount\", \"align\": \"center\", \"label\": \"Tax\", \"titleAlign\": \"center\", \"totalColumn\": true, \"widthFactor\": 1.5}, {\"key\": \"line_total\", \"align\": \"center\", \"label\": \"Amount\", \"titleAlign\": \"center\", \"totalColumn\": true, \"widthFactor\": 1.5}], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 26, \"underline\": false, \"printTotal\": true, \"barcodeType\": \"code128\", \"headerColor\": 4289581296, \"printHeader\": true, \"strokeColor\": 4282156725, \"strokeWidth\": 1, \"titleHeight\": 22, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 33.859375, \"y\": 577.37890625, \"id\": \"amount-words-label\", \"bold\": false, \"text\": \"Amount in Words:\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 89, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 109.953125, \"y\": 578.08984375, \"id\": \"amount-words-value\", \"bold\": false, \"text\": \"{{amount_in_words}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 240, \"height\": 28, \"italic\": true, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 35.20703125, \"y\": 614.80078125, \"id\": \"gst-breakup-table\", \"bold\": false, \"text\": \"\", \"type\": \"table\", \"align\": \"left\", \"sides\": 5, \"width\": 318, \"height\": 45, \"italic\": false, \"cellGap\": 3, \"columns\": [{\"key\": \"tax_name\", \"align\": \"center\", \"label\": \"Tax\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 2.5}, {\"key\": \"taxable\", \"align\": \"center\", \"label\": \"Taxable Val\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 2.5}, {\"key\": \"cgst\", \"align\": \"center\", \"label\": \"CGST\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 2}, {\"key\": \"sgst\", \"align\": \"center\", \"label\": \"SGST\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 2}, {\"key\": \"igst\", \"align\": \"center\", \"label\": \"IGST\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 2}], \"dataPath\": \"gst_breakup\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 18, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4289581296, \"printHeader\": true, \"strokeColor\": 4282156725, \"strokeWidth\": 1, \"titleHeight\": 18, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 381.58203125, \"y\": 630.51953125, \"id\": \"total-amount-label\", \"bold\": false, \"text\": \"Total Amount\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 92.375, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 14, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 437.6796875, \"y\": 631.171875, \"id\": \"total-amount-value\", \"bold\": true, \"text\": \"{{total_amount}}\", \"type\": \"text\", \"align\": \"right\", \"sides\": 5, \"width\": 111.73828125, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 15, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 33.796875, \"y\": 694.7578125, \"id\": \"terms-title\", \"bold\": true, \"text\": \"Terms and Condition\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 130, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 37, \"y\": 712, \"id\": \"terms-text\", \"bold\": false, \"text\": \"{{terms_conditions}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 320, \"height\": 38, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 8, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 34.8203125, \"y\": 755.421875, \"id\": \"banking-label\", \"bold\": true, \"text\": \"Our Banking Details\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 140, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 352.97265625, \"y\": 785.78515625, \"id\": \"auth-signatory\", \"bold\": false, \"text\": \"Authorised Signatory\", \"type\": \"text\", \"align\": \"right\", \"sides\": 5, \"width\": 198, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 108.11328125, \"y\": 70.61328125, \"id\": \"text-29\", \"bold\": true, \"text\": \"Sakthi Controller \", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 219.93359375, \"height\": 23.19140625, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 16, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 106.89453125, \"y\": 98.53515625, \"id\": \"text-30\", \"bold\": false, \"text\": \"153, Karunai Nagar, K. Sevoor Katpadi Taluk, Tamil Nadu 632106\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 197.296875, \"height\": 35.03515625, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 39.3828125, \"y\": 770.46484375, \"id\": \"text-31\", \"bold\": false, \"text\": \"A/C No: 000041004790019\\nIFSC: DEUT0401PBC\\nBank Name/Branch: Deutsche Bank - vellore\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 200, \"height\": 28, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}], \"gridSize\": 8, \"showGrid\": false, \"pageWidth\": 595, \"pageHeight\": 842, \"mediaPreset\": \"A4\", \"orientation\": \"portrait\", \"backgroundOpacity\": 0.18, \"backgroundImagePath\": null}', 1, '2026-05-16 04:01:48', '2026-05-28 06:42:14'),
(2, 'purchase_invoice', '{\"shapes\": [{\"x\": 29, \"y\": 28, \"id\": \"pbs-outer-border\", \"bold\": false, \"text\": \"\", \"type\": \"rectangle\", \"align\": \"left\", \"sides\": 5, \"width\": 537, \"height\": 786, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4282156725, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4282156725, \"headerTextColor\": 4279310375}, {\"x\": 102.35546875, \"y\": 34.40234375, \"id\": \"text-doc-type\", \"bold\": true, \"text\": \"PURCHASE INVOICE\", \"type\": \"text\", \"align\": \"center\", \"sides\": 5, \"width\": 160, \"height\": 18, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 11, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 368, \"y\": 32, \"id\": \"gstin-label\", \"bold\": false, \"text\": \"GSTIN :\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 42, \"height\": 18, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 412, \"y\": 32, \"id\": \"gstin-value\", \"bold\": true, \"text\": \"{{company_gstin}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 148, \"height\": 18, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 29, \"y\": 54, \"id\": \"header-top-divider\", \"bold\": false, \"text\": \"\", \"type\": \"line\", \"align\": \"left\", \"sides\": 5, \"width\": 537, \"height\": 0, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4289111718, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4289111718, \"headerTextColor\": 4279310375}, {\"x\": 35.125, \"y\": 56.14453125, \"id\": \"company-logo\", \"bold\": false, \"text\": \"\", \"type\": \"image\", \"align\": \"left\", \"sides\": 5, \"width\": 68.8515625, \"height\": 65.453125, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"https://bill.sakthicontroller.com/api/public/api/v1/public/media/file?path=uploads%2Fprint-templates%2F2026%2F05%2F001be57a-4299-4605-9c62-25972b1ced35.png\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 0, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 49.7734375, \"y\": 144.796875, \"id\": \"company-address\", \"bold\": false, \"text\": \"Cell : 9443036233, 9597773302\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 208.05859375, \"height\": 17.8125, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 10, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 327, \"y\": 28, \"id\": \"header-vertical-divider\", \"bold\": false, \"text\": \"\", \"type\": \"line\", \"align\": \"left\", \"sides\": 5, \"width\": 0, \"height\": 152, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4289111718, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4289111718, \"headerTextColor\": 4279310375}, {\"x\": 334, \"y\": 58, \"id\": \"customer-label\", \"bold\": true, \"text\": \"Supplier {{party_address}} {{party_gstin}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 230, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 334, \"y\": 76, \"id\": \"party-text\", \"bold\": false, \"text\": \"{{party_name}}\\n {{party_address}} {{party_gstin}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 228, \"height\": 64, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 331.640625, \"y\": 147.7890625, \"id\": \"customer-gstn-label\", \"bold\": false, \"text\": \"Supplier GSTN :\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 84, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 406.1484375, \"y\": 142.6171875, \"id\": \"customer-gstn-value\", \"bold\": false, \"text\": \"{{party_gstin}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 148, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 29, \"y\": 180, \"id\": \"header-divider\", \"bold\": false, \"text\": \"\", \"type\": \"line\", \"align\": \"left\", \"sides\": 5, \"width\": 537, \"height\": 0, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4289111718, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4289111718, \"headerTextColor\": 4279310375}, {\"x\": 47.73828125, \"y\": 185.20703125, \"id\": \"doc-no-label\", \"bold\": false, \"text\": \"Doc No :\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 50, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 89.390625, \"y\": 186.2109375, \"id\": \"doc-no-value\", \"bold\": true, \"text\": \"{{document_number}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 110, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 222, \"y\": 186.03125, \"id\": \"date-label\", \"bold\": false, \"text\": \"Date :\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 35, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 251.26171875, \"y\": 186.4296875, \"id\": \"date-value\", \"bold\": true, \"text\": \"{{document_date}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 78, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 354.8125, \"y\": 186.234375, \"id\": \"ref-label\", \"bold\": false, \"text\": \"Supplier Ref:\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 68.22265625, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 409.68359375, \"y\": 187.29296875, \"id\": \"ref-value\", \"bold\": false, \"text\": \"{{reference_number}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 69.37890625, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 29, \"y\": 204, \"id\": \"lines-table\", \"bold\": false, \"text\": \"\", \"type\": \"table\", \"align\": \"left\", \"sides\": 5, \"width\": 537, \"height\": 365, \"italic\": false, \"cellGap\": 4, \"columns\": [{\"key\": \"item_name\", \"align\": \"left\", \"label\": \"Item\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 4.5}, {\"key\": \"qty\", \"align\": \"center\", \"label\": \"Qty\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 1}, {\"key\": \"rate\", \"align\": \"center\", \"label\": \"Price\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 1.5}, {\"key\": \"tax_amount\", \"align\": \"center\", \"label\": \"Tax\", \"titleAlign\": \"center\", \"totalColumn\": true, \"widthFactor\": 1.5}, {\"key\": \"line_total\", \"align\": \"center\", \"label\": \"Amount\", \"titleAlign\": \"center\", \"totalColumn\": true, \"widthFactor\": 1.5}], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 26, \"underline\": false, \"printTotal\": true, \"barcodeType\": \"code128\", \"headerColor\": 4289581296, \"printHeader\": true, \"strokeColor\": 4282156725, \"strokeWidth\": 1, \"titleHeight\": 22, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 33.859375, \"y\": 577.37890625, \"id\": \"amount-words-label\", \"bold\": false, \"text\": \"Amount in Words:\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 89, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 109.953125, \"y\": 578.08984375, \"id\": \"amount-words-value\", \"bold\": false, \"text\": \"{{amount_in_words}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 240, \"height\": 28, \"italic\": true, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 35.20703125, \"y\": 614.80078125, \"id\": \"gst-breakup-table\", \"bold\": false, \"text\": \"\", \"type\": \"table\", \"align\": \"left\", \"sides\": 5, \"width\": 318, \"height\": 45, \"italic\": false, \"cellGap\": 3, \"columns\": [{\"key\": \"tax_name\", \"align\": \"center\", \"label\": \"Tax\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 2.5}, {\"key\": \"taxable\", \"align\": \"center\", \"label\": \"Taxable Val\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 2.5}, {\"key\": \"cgst\", \"align\": \"center\", \"label\": \"CGST\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 2}, {\"key\": \"sgst\", \"align\": \"center\", \"label\": \"SGST\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 2}, {\"key\": \"igst\", \"align\": \"center\", \"label\": \"IGST\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 2}], \"dataPath\": \"gst_breakup\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 18, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4289581296, \"printHeader\": true, \"strokeColor\": 4282156725, \"strokeWidth\": 1, \"titleHeight\": 18, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 381.58203125, \"y\": 630.51953125, \"id\": \"total-amount-label\", \"bold\": false, \"text\": \"Total Amount\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 92.375, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 14, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 406.6796875, \"y\": 629.171875, \"id\": \"total-amount-value\", \"bold\": true, \"text\": \"{{total_amount}}\", \"type\": \"text\", \"align\": \"right\", \"sides\": 5, \"width\": 111.73828125, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 15, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 33.796875, \"y\": 694.7578125, \"id\": \"terms-title\", \"bold\": true, \"text\": \"Terms and Condition\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 130, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 37, \"y\": 712, \"id\": \"terms-text\", \"bold\": false, \"text\": \"{{terms_conditions}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 320, \"height\": 38, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 8, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 34.8203125, \"y\": 755.421875, \"id\": \"banking-label\", \"bold\": true, \"text\": \"Our Banking Details\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 140, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 352.97265625, \"y\": 785.78515625, \"id\": \"auth-signatory\", \"bold\": false, \"text\": \"Authorised Signatory\", \"type\": \"text\", \"align\": \"right\", \"sides\": 5, \"width\": 198, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 108.11328125, \"y\": 70.61328125, \"id\": \"text-29\", \"bold\": true, \"text\": \"Sakthi Controller \", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 219.93359375, \"height\": 23.19140625, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 16, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 106.89453125, \"y\": 98.53515625, \"id\": \"text-30\", \"bold\": false, \"text\": \"153, Karunai Nagar, K. Sevoor Katpadi Taluk, Tamil Nadu 632106\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 197.296875, \"height\": 35.03515625, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 39.3828125, \"y\": 770.46484375, \"id\": \"text-31\", \"bold\": false, \"text\": \"A/C No: 000041004790019\\nIFSC: DEUT0401PBC\\nBank Name/Branch: Deutsche Bank - vellore\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 200, \"height\": 28, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}], \"gridSize\": 8, \"showGrid\": false, \"pageWidth\": 595, \"pageHeight\": 842, \"mediaPreset\": \"A4\", \"orientation\": \"portrait\", \"backgroundOpacity\": 0.18, \"backgroundImagePath\": null}', 1, '2026-05-23 03:25:39', '2026-05-28 07:17:14');
INSERT INTO `print_templates` (`id`, `document_type`, `template_data`, `is_active`, `created_at`, `updated_at`) VALUES
(3, 'sales_invoice', '{\"shapes\": [{\"x\": 29, \"y\": 29, \"id\": \"pbs-outer-border\", \"bold\": false, \"text\": \"\", \"type\": \"rectangle\", \"align\": \"left\", \"sides\": 5, \"width\": 537, \"height\": 786, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4282156725, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4282156725, \"headerTextColor\": 4279310375}, {\"x\": 102.35546875, \"y\": 34.40234375, \"id\": \"text-doc-type\", \"bold\": true, \"text\": \"SALES INVOICE\", \"type\": \"text\", \"align\": \"center\", \"sides\": 5, \"width\": 160, \"height\": 18, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 11, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 368, \"y\": 32, \"id\": \"gstin-label\", \"bold\": false, \"text\": \"GSTIN :\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 42, \"height\": 18, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 412, \"y\": 32, \"id\": \"gstin-value\", \"bold\": true, \"text\": \"{{company_gstin}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 148, \"height\": 18, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 29, \"y\": 54, \"id\": \"header-top-divider\", \"bold\": false, \"text\": \"\", \"type\": \"line\", \"align\": \"left\", \"sides\": 5, \"width\": 537, \"height\": 0, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4289111718, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4289111718, \"headerTextColor\": 4279310375}, {\"x\": 35.125, \"y\": 56.14453125, \"id\": \"company-logo\", \"bold\": false, \"text\": \"\", \"type\": \"image\", \"align\": \"left\", \"sides\": 5, \"width\": 68.8515625, \"height\": 65.453125, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"http://bill:8000/api/v1/public/media/file?path=uploads%2Fprint-templates%2F2026%2F06%2Fd0254296-a7a8-4cd0-be71-f3053da9c06b.png\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 0, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 49.7734375, \"y\": 144.796875, \"id\": \"company-address\", \"bold\": false, \"text\": \"Cell : 9443036233, 9597773302\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 208.05859375, \"height\": 17.8125, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 10, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 327, \"y\": 28, \"id\": \"header-vertical-divider\", \"bold\": false, \"text\": \"\", \"type\": \"line\", \"align\": \"left\", \"sides\": 5, \"width\": 0, \"height\": 152, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4289111718, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4289111718, \"headerTextColor\": 4279310375}, {\"x\": 334, \"y\": 58, \"id\": \"customer-label\", \"bold\": true, \"text\": \"Customer\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 230, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 334, \"y\": 76, \"id\": \"party-text\", \"bold\": false, \"text\": \"{{party_name}}\\n{{party_address}}\\n{{party_contact}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 228, \"height\": 64, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 331.640625, \"y\": 147.7890625, \"id\": \"customer-gstn-label\", \"bold\": false, \"text\": \"Customer GSTN :\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 84, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 403.65234375, \"y\": 148.09765625, \"id\": \"customer-gstn-value\", \"bold\": false, \"text\": \"{{party_gstin}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 148, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 29, \"y\": 180, \"id\": \"header-divider\", \"bold\": false, \"text\": \"\", \"type\": \"line\", \"align\": \"left\", \"sides\": 5, \"width\": 537, \"height\": 0, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4289111718, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4289111718, \"headerTextColor\": 4279310375}, {\"x\": 47.73828125, \"y\": 185.20703125, \"id\": \"doc-no-label\", \"bold\": false, \"text\": \"Doc No :\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 50, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 89.390625, \"y\": 186.2109375, \"id\": \"doc-no-value\", \"bold\": true, \"text\": \"{{document_number}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 110, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 222, \"y\": 186.03125, \"id\": \"date-label\", \"bold\": false, \"text\": \"Date :\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 35, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 251.26171875, \"y\": 186.4296875, \"id\": \"date-value\", \"bold\": true, \"text\": \"{{document_date}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 78, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 354.8125, \"y\": 186.234375, \"id\": \"ref-label\", \"bold\": false, \"text\": \"P.O Number:\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 68.22265625, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 409.68359375, \"y\": 187.29296875, \"id\": \"ref-value\", \"bold\": false, \"text\": \"{{reference_number}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 69.37890625, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 29, \"y\": 204, \"id\": \"lines-table\", \"bold\": false, \"text\": \"\", \"type\": \"table\", \"align\": \"left\", \"sides\": 5, \"width\": 537, \"height\": 365, \"italic\": false, \"cellGap\": 4, \"columns\": [{\"key\": \"line_no\", \"align\": \"center\", \"label\": \"S.No\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 0.9}, {\"key\": \"item_name\", \"align\": \"left\", \"label\": \"Item\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 3.6}, {\"key\": \"hsn\", \"align\": \"center\", \"label\": \"HSN\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 1.6}, {\"key\": \"qty\", \"align\": \"center\", \"label\": \"Qty\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 1}, {\"key\": \"rate\", \"align\": \"right\", \"label\": \"Price\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 1.5}, {\"key\": \"tax_amount\", \"align\": \"right\", \"label\": \"Tax\", \"titleAlign\": \"center\", \"totalColumn\": true, \"widthFactor\": 1.5}, {\"key\": \"line_total\", \"align\": \"right\", \"label\": \"Amount\", \"titleAlign\": \"center\", \"totalColumn\": true, \"widthFactor\": 1.3}], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 26, \"underline\": false, \"printTotal\": true, \"barcodeType\": \"code128\", \"headerColor\": 4289581296, \"printHeader\": true, \"strokeColor\": 4282156725, \"strokeWidth\": 1, \"titleHeight\": 22, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 33.859375, \"y\": 577.37890625, \"id\": \"amount-words-label\", \"bold\": false, \"text\": \"Amount in Words:\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 89, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 109.953125, \"y\": 578.08984375, \"id\": \"amount-words-value\", \"bold\": false, \"text\": \"{{amount_in_words}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 240, \"height\": 28, \"italic\": true, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 35.20703125, \"y\": 614.80078125, \"id\": \"gst-breakup-table\", \"bold\": false, \"text\": \"\", \"type\": \"table\", \"align\": \"left\", \"sides\": 5, \"width\": 318, \"height\": 45, \"italic\": false, \"cellGap\": 3, \"columns\": [{\"key\": \"tax_name\", \"align\": \"center\", \"label\": \"Tax\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 2.5}, {\"key\": \"taxable\", \"align\": \"center\", \"label\": \"Taxable Val\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 2.5}, {\"key\": \"cgst\", \"align\": \"center\", \"label\": \"CGST\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 2}, {\"key\": \"sgst\", \"align\": \"center\", \"label\": \"SGST\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 2}, {\"key\": \"igst\", \"align\": \"center\", \"label\": \"IGST\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 2}], \"dataPath\": \"gst_breakup\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 18, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4289581296, \"printHeader\": true, \"strokeColor\": 4282156725, \"strokeWidth\": 1, \"titleHeight\": 18, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 381.58203125, \"y\": 630.51953125, \"id\": \"total-amount-label\", \"bold\": false, \"text\": \"Total Amount:\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 92.375, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 14, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 439.6796875, \"y\": 630.171875, \"id\": \"total-amount-value\", \"bold\": true, \"text\": \"{{total_amount}}\", \"type\": \"text\", \"align\": \"right\", \"sides\": 5, \"width\": 111.73828125, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 14, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 35.40625, \"y\": 673.2734375, \"id\": \"terms-title\", \"bold\": true, \"text\": \"Terms and Condition\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 130, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 37.60546875, \"y\": 695.21875, \"id\": \"terms-text\", \"bold\": false, \"text\": \"{{terms_conditions}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 513.6953125, \"height\": 65.2421875, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 36.46484375, \"y\": 757.578125, \"id\": \"banking-label\", \"bold\": true, \"text\": \"Our Banking Details\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 140, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 352.97265625, \"y\": 785.78515625, \"id\": \"auth-signatory\", \"bold\": false, \"text\": \"Authorised Signatory\", \"type\": \"text\", \"align\": \"right\", \"sides\": 5, \"width\": 198, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 108.11328125, \"y\": 70.61328125, \"id\": \"text-29\", \"bold\": true, \"text\": \"Sakthi Controller \", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 219.93359375, \"height\": 23.19140625, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 15, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 106.89453125, \"y\": 98.53515625, \"id\": \"text-30\", \"bold\": false, \"text\": \"153, Karunai Nagar, K. Sevoor Katpadi Taluk, Tamil Nadu 632106\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 197.296875, \"height\": 35.03515625, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 37.92578125, \"y\": 773.30859375, \"id\": \"text-31\", \"bold\": false, \"text\": \"A/C No: 000041004790019\\nIFSC: DEUT0401PBC\\nBank Name/Branch: Deutsche Bank - vellore\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 234.3046875, \"height\": 36.796875, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}], \"gridSize\": 8, \"showGrid\": false, \"pageWidth\": 595, \"pageHeight\": 842, \"mediaPreset\": \"A4\", \"orientation\": \"portrait\", \"backgroundOpacity\": 0.18, \"backgroundImagePath\": null}', 1, '2026-05-23 03:59:21', '2026-06-19 07:04:33'),
(4, 'sales_delivery', '{\"shapes\": [{\"x\": 29, \"y\": 27, \"id\": \"pbs-outer-border\", \"bold\": false, \"text\": \"\", \"type\": \"rectangle\", \"align\": \"left\", \"sides\": 5, \"width\": 537, \"height\": 786, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4282156725, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4282156725, \"headerTextColor\": 4279310375}, {\"x\": 44.24609375, \"y\": 33.96484375, \"id\": \"text-doc-type\", \"bold\": true, \"text\": \"DELIVERY CHALLAN\", \"type\": \"text\", \"align\": \"center\", \"sides\": 5, \"width\": 263.2734375, \"height\": 16.40625, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 11, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 368, \"y\": 32, \"id\": \"gstin-label\", \"bold\": false, \"text\": \"GSTIN :\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 42, \"height\": 18, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 412, \"y\": 32, \"id\": \"gstin-value\", \"bold\": true, \"text\": \"{{company_gstin}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 148, \"height\": 18, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 29.9296875, \"y\": 52.96875, \"id\": \"header-top-divider\", \"bold\": false, \"text\": \"\", \"type\": \"line\", \"align\": \"left\", \"sides\": 5, \"width\": 537, \"height\": 0, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4289111718, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4289111718, \"headerTextColor\": 4279310375}, {\"x\": 35.125, \"y\": 56.14453125, \"id\": \"company-logo\", \"bold\": false, \"text\": \"\", \"type\": \"image\", \"align\": \"left\", \"sides\": 5, \"width\": 68.8515625, \"height\": 65.453125, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"https://bill.sakthicontroller.com/api/public/api/v1/public/media/file?path=uploads%2Fprint-templates%2F2026%2F05%2F001be57a-4299-4605-9c62-25972b1ced35.png\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 0, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 49.7734375, \"y\": 144.796875, \"id\": \"company-address\", \"bold\": false, \"text\": \"Cell : 9443036233, 9597773302\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 208.05859375, \"height\": 17.8125, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 10, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 327, \"y\": 28, \"id\": \"header-vertical-divider\", \"bold\": false, \"text\": \"\", \"type\": \"line\", \"align\": \"left\", \"sides\": 5, \"width\": 0, \"height\": 152, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4289111718, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4289111718, \"headerTextColor\": 4279310375}, {\"x\": 334, \"y\": 58, \"id\": \"customer-label\", \"bold\": true, \"text\": \"Customer\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 230, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 334, \"y\": 76, \"id\": \"party-text\", \"bold\": false, \"text\": \"{{party_name}}\\n{{party_address}}\\n{{party_contact}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 228, \"height\": 64, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 331.640625, \"y\": 147.7890625, \"id\": \"customer-gstn-label\", \"bold\": false, \"text\": \"Customer GSTN : {{party_gstin}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 84, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 406.1484375, \"y\": 142.6171875, \"id\": \"customer-gstn-value\", \"bold\": false, \"text\": \"{{party_gstin}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 148, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 29, \"y\": 180, \"id\": \"header-divider\", \"bold\": false, \"text\": \"\", \"type\": \"line\", \"align\": \"left\", \"sides\": 5, \"width\": 537, \"height\": 0, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4289111718, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4289111718, \"headerTextColor\": 4279310375}, {\"x\": 47.73828125, \"y\": 185.20703125, \"id\": \"doc-no-label\", \"bold\": false, \"text\": \"Doc No :\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 50, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 89.390625, \"y\": 186.2109375, \"id\": \"doc-no-value\", \"bold\": true, \"text\": \"{{document_number}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 110, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 222, \"y\": 186.03125, \"id\": \"date-label\", \"bold\": false, \"text\": \"Date :\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 35, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 251.26171875, \"y\": 186.4296875, \"id\": \"date-value\", \"bold\": true, \"text\": \"{{document_date}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 78, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 354.8125, \"y\": 186.234375, \"id\": \"ref-label\", \"bold\": false, \"text\": \"Ref :\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 68.22265625, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 409.68359375, \"y\": 187.29296875, \"id\": \"ref-value\", \"bold\": false, \"text\": \"{{reference_number}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 69.37890625, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 29, \"y\": 204, \"id\": \"lines-table\", \"bold\": false, \"text\": \"\", \"type\": \"table\", \"align\": \"left\", \"sides\": 5, \"width\": 537, \"height\": 365, \"italic\": false, \"cellGap\": 4, \"columns\": [{\"key\": \"item_name\", \"align\": \"left\", \"label\": \"Item\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 4.5}, {\"key\": \"qty\", \"align\": \"center\", \"label\": \"Qty\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 1}], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 26, \"underline\": false, \"printTotal\": true, \"barcodeType\": \"code128\", \"headerColor\": 4289581296, \"printHeader\": true, \"strokeColor\": 4282156725, \"strokeWidth\": 1, \"titleHeight\": 22, \"borderRadius\": 0, \"bodyTextColor\": 4282156725, \"headerTextColor\": 4279310375}, {\"x\": 37.796875, \"y\": 633.7578125, \"id\": \"terms-title\", \"bold\": true, \"text\": \"Terms and Condition\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 130, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 37, \"y\": 712, \"id\": \"terms-text\", \"bold\": false, \"text\": \"{{terms_conditions}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 320, \"height\": 38, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 8, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 352.97265625, \"y\": 785.78515625, \"id\": \"auth-signatory\", \"bold\": false, \"text\": \"Authorised Signatory\", \"type\": \"text\", \"align\": \"right\", \"sides\": 5, \"width\": 198, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 108.11328125, \"y\": 70.61328125, \"id\": \"text-29\", \"bold\": true, \"text\": \"Sakthi Controller \", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 219.93359375, \"height\": 23.19140625, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 16, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 106.89453125, \"y\": 98.53515625, \"id\": \"text-30\", \"bold\": false, \"text\": \"153, Karunai Nagar, K. Sevoor Katpadi Taluk, Tamil Nadu 632106\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 197.296875, \"height\": 35.03515625, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}], \"gridSize\": 8, \"showGrid\": false, \"pageWidth\": 595, \"pageHeight\": 842, \"mediaPreset\": \"A4\", \"orientation\": \"portrait\", \"backgroundOpacity\": 0.18, \"backgroundImagePath\": null}', 1, '2026-05-23 04:07:11', '2026-05-29 06:02:57');
INSERT INTO `print_templates` (`id`, `document_type`, `template_data`, `is_active`, `created_at`, `updated_at`) VALUES
(5, 'sales_order', '{\"shapes\": [{\"x\": 29, \"y\": 28, \"id\": \"pbs-outer-border\", \"bold\": false, \"text\": \"\", \"type\": \"rectangle\", \"align\": \"left\", \"sides\": 5, \"width\": 537, \"height\": 786, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4282156725, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4282156725, \"headerTextColor\": 4279310375}, {\"x\": 102.35546875, \"y\": 34.40234375, \"id\": \"text-doc-type\", \"bold\": true, \"text\": \"SALES ORDER\", \"type\": \"text\", \"align\": \"center\", \"sides\": 5, \"width\": 160, \"height\": 18, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 11, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 368, \"y\": 32, \"id\": \"gstin-label\", \"bold\": false, \"text\": \"GSTIN :\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 42, \"height\": 18, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 412, \"y\": 32, \"id\": \"gstin-value\", \"bold\": true, \"text\": \"{{company_gstin}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 148, \"height\": 18, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 29, \"y\": 54, \"id\": \"header-top-divider\", \"bold\": false, \"text\": \"\", \"type\": \"line\", \"align\": \"left\", \"sides\": 5, \"width\": 537, \"height\": 0, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4289111718, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4289111718, \"headerTextColor\": 4279310375}, {\"x\": 35.125, \"y\": 56.14453125, \"id\": \"company-logo\", \"bold\": false, \"text\": \"\", \"type\": \"image\", \"align\": \"left\", \"sides\": 5, \"width\": 68.8515625, \"height\": 65.453125, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"https://bill.sakthicontroller.com/api/public/api/v1/public/media/file?path=uploads%2Fprint-templates%2F2026%2F05%2F001be57a-4299-4605-9c62-25972b1ced35.png\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 0, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 49.7734375, \"y\": 144.796875, \"id\": \"company-address\", \"bold\": false, \"text\": \"Cell : 9443036233, 9597773302\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 208.05859375, \"height\": 17.8125, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 10, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 327, \"y\": 28, \"id\": \"header-vertical-divider\", \"bold\": false, \"text\": \"\", \"type\": \"line\", \"align\": \"left\", \"sides\": 5, \"width\": 0, \"height\": 152, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4289111718, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4289111718, \"headerTextColor\": 4279310375}, {\"x\": 334, \"y\": 58, \"id\": \"customer-label\", \"bold\": true, \"text\": \"Customer\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 230, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 334, \"y\": 76, \"id\": \"party-text\", \"bold\": false, \"text\": \"{{party_name}}\\n{{party_address}}\\n{{party_contact}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 228, \"height\": 64, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 331.640625, \"y\": 147.7890625, \"id\": \"customer-gstn-label\", \"bold\": false, \"text\": \"Customer GSTN :\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 84, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 406.53515625, \"y\": 148.3046875, \"id\": \"customer-gstn-value\", \"bold\": false, \"text\": \"{{party_gstin}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 148, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 29, \"y\": 180, \"id\": \"header-divider\", \"bold\": false, \"text\": \"\", \"type\": \"line\", \"align\": \"left\", \"sides\": 5, \"width\": 537, \"height\": 0, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4289111718, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4289111718, \"headerTextColor\": 4279310375}, {\"x\": 47.73828125, \"y\": 185.20703125, \"id\": \"doc-no-label\", \"bold\": false, \"text\": \"Doc No :\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 50, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 89.390625, \"y\": 186.2109375, \"id\": \"doc-no-value\", \"bold\": true, \"text\": \"{{document_number}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 110, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 222, \"y\": 186.03125, \"id\": \"date-label\", \"bold\": false, \"text\": \"Date :\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 35, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 251.26171875, \"y\": 186.4296875, \"id\": \"date-value\", \"bold\": true, \"text\": \"{{document_date}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 78, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 354.8125, \"y\": 186.234375, \"id\": \"ref-label\", \"bold\": false, \"text\": \"P.O Number:\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 68.22265625, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 409.68359375, \"y\": 187.29296875, \"id\": \"ref-value\", \"bold\": false, \"text\": \"{{reference_number}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 69.37890625, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 29, \"y\": 204, \"id\": \"lines-table\", \"bold\": false, \"text\": \"\", \"type\": \"table\", \"align\": \"left\", \"sides\": 5, \"width\": 537, \"height\": 365, \"italic\": false, \"cellGap\": 4, \"columns\": [{\"key\": \"item_name\", \"align\": \"left\", \"label\": \"Item\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 4.5}, {\"key\": \"qty\", \"align\": \"center\", \"label\": \"Qty\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 1}, {\"key\": \"rate\", \"align\": \"center\", \"label\": \"Price\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 1.5}, {\"key\": \"tax_amount\", \"align\": \"center\", \"label\": \"Tax\", \"titleAlign\": \"center\", \"totalColumn\": true, \"widthFactor\": 1.5}, {\"key\": \"line_total\", \"align\": \"center\", \"label\": \"Amount\", \"titleAlign\": \"center\", \"totalColumn\": true, \"widthFactor\": 1.5}], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 26, \"underline\": false, \"printTotal\": true, \"barcodeType\": \"code128\", \"headerColor\": 4289581296, \"printHeader\": true, \"strokeColor\": 4282156725, \"strokeWidth\": 1, \"titleHeight\": 22, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 33.859375, \"y\": 577.37890625, \"id\": \"amount-words-label\", \"bold\": false, \"text\": \"Amount in Words:\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 89, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 109.953125, \"y\": 578.08984375, \"id\": \"amount-words-value\", \"bold\": false, \"text\": \"{{amount_in_words}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 240, \"height\": 28, \"italic\": true, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 35.20703125, \"y\": 614.80078125, \"id\": \"gst-breakup-table\", \"bold\": false, \"text\": \"\", \"type\": \"table\", \"align\": \"left\", \"sides\": 5, \"width\": 318, \"height\": 45, \"italic\": false, \"cellGap\": 3, \"columns\": [{\"key\": \"tax_name\", \"align\": \"center\", \"label\": \"Tax\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 2.5}, {\"key\": \"taxable\", \"align\": \"center\", \"label\": \"Taxable Val\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 2.5}, {\"key\": \"cgst\", \"align\": \"center\", \"label\": \"CGST\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 2}, {\"key\": \"sgst\", \"align\": \"center\", \"label\": \"SGST\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 2}, {\"key\": \"igst\", \"align\": \"center\", \"label\": \"IGST\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 2}], \"dataPath\": \"gst_breakup\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 18, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4289581296, \"printHeader\": true, \"strokeColor\": 4282156725, \"strokeWidth\": 1, \"titleHeight\": 18, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 381.58203125, \"y\": 630.51953125, \"id\": \"total-amount-label\", \"bold\": false, \"text\": \"Total Amount\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 92.375, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 14, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 406.6796875, \"y\": 629.171875, \"id\": \"total-amount-value\", \"bold\": true, \"text\": \"{{total_amount}}\", \"type\": \"text\", \"align\": \"right\", \"sides\": 5, \"width\": 111.73828125, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 15, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 33.796875, \"y\": 694.7578125, \"id\": \"terms-title\", \"bold\": true, \"text\": \"Terms and Condition\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 130, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 37, \"y\": 712, \"id\": \"terms-text\", \"bold\": false, \"text\": \"{{terms_conditions}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 320, \"height\": 38, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 8, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 34.8203125, \"y\": 755.421875, \"id\": \"banking-label\", \"bold\": true, \"text\": \"Our Banking Details\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 140, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 352.97265625, \"y\": 785.78515625, \"id\": \"auth-signatory\", \"bold\": false, \"text\": \"Authorised Signatory\", \"type\": \"text\", \"align\": \"right\", \"sides\": 5, \"width\": 198, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 108.11328125, \"y\": 70.61328125, \"id\": \"text-29\", \"bold\": true, \"text\": \"Sakthi Controller \", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 219.93359375, \"height\": 23.19140625, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 16, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 106.89453125, \"y\": 98.53515625, \"id\": \"text-30\", \"bold\": false, \"text\": \"153, Karunai Nagar, K. Sevoor Katpadi Taluk, Tamil Nadu 632106\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 197.296875, \"height\": 35.03515625, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 39.3828125, \"y\": 770.46484375, \"id\": \"text-31\", \"bold\": false, \"text\": \"A/C No: 000041004790019\\nIFSC: DEUT0401PBC\\nBank Name/Branch: Deutsche Bank - vellore\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 200, \"height\": 28, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}], \"gridSize\": 8, \"showGrid\": false, \"pageWidth\": 595, \"pageHeight\": 842, \"mediaPreset\": \"A4\", \"orientation\": \"portrait\", \"backgroundOpacity\": 0.18, \"backgroundImagePath\": null}', 1, '2026-05-23 04:28:29', '2026-05-30 00:51:40'),
(6, 'sales_returnable_delivery', '{\"shapes\": [{\"x\": 29, \"y\": 27, \"id\": \"pbs-outer-border\", \"bold\": false, \"text\": \"\", \"type\": \"rectangle\", \"align\": \"left\", \"sides\": 5, \"width\": 537, \"height\": 786, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4282156725, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4282156725, \"headerTextColor\": 4279310375}, {\"x\": 44.24609375, \"y\": 33.96484375, \"id\": \"text-doc-type\", \"bold\": true, \"text\": \"RETURNABLE DELIVERY CHALLAN\", \"type\": \"text\", \"align\": \"center\", \"sides\": 5, \"width\": 263.2734375, \"height\": 16.40625, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 11, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 368, \"y\": 32, \"id\": \"gstin-label\", \"bold\": false, \"text\": \"GSTIN :\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 42, \"height\": 18, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 412, \"y\": 32, \"id\": \"gstin-value\", \"bold\": true, \"text\": \"{{company_gstin}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 148, \"height\": 18, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 29.9296875, \"y\": 52.96875, \"id\": \"header-top-divider\", \"bold\": false, \"text\": \"\", \"type\": \"line\", \"align\": \"left\", \"sides\": 5, \"width\": 537, \"height\": 0, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4289111718, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4289111718, \"headerTextColor\": 4279310375}, {\"x\": 35.125, \"y\": 56.14453125, \"id\": \"company-logo\", \"bold\": false, \"text\": \"\", \"type\": \"image\", \"align\": \"left\", \"sides\": 5, \"width\": 68.8515625, \"height\": 65.453125, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"https://bill.sakthicontroller.com/api/public/api/v1/public/media/file?path=uploads%2Fprint-templates%2F2026%2F05%2F001be57a-4299-4605-9c62-25972b1ced35.png\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 0, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 49.7734375, \"y\": 144.796875, \"id\": \"company-address\", \"bold\": false, \"text\": \"Cell : 9443036233, 9597773302\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 208.05859375, \"height\": 17.8125, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 10, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 327, \"y\": 28, \"id\": \"header-vertical-divider\", \"bold\": false, \"text\": \"\", \"type\": \"line\", \"align\": \"left\", \"sides\": 5, \"width\": 0, \"height\": 152, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4289111718, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4289111718, \"headerTextColor\": 4279310375}, {\"x\": 334, \"y\": 58, \"id\": \"customer-label\", \"bold\": true, \"text\": \"Customer\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 230, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 334, \"y\": 76, \"id\": \"party-text\", \"bold\": false, \"text\": \"{{party_name}}\\n{{party_address}}\\n{{party_contact}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 228, \"height\": 64, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 331.640625, \"y\": 147.7890625, \"id\": \"customer-gstn-label\", \"bold\": false, \"text\": \"Customer GSTN : {{party_gstin}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 84, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 406.1484375, \"y\": 142.6171875, \"id\": \"customer-gstn-value\", \"bold\": false, \"text\": \"{{party_gstin}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 148, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 29, \"y\": 180, \"id\": \"header-divider\", \"bold\": false, \"text\": \"\", \"type\": \"line\", \"align\": \"left\", \"sides\": 5, \"width\": 537, \"height\": 0, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4289111718, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4289111718, \"headerTextColor\": 4279310375}, {\"x\": 47.73828125, \"y\": 185.20703125, \"id\": \"doc-no-label\", \"bold\": false, \"text\": \"Doc No :\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 50, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 89.390625, \"y\": 186.2109375, \"id\": \"doc-no-value\", \"bold\": true, \"text\": \"{{document_number}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 110, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 222, \"y\": 186.03125, \"id\": \"date-label\", \"bold\": false, \"text\": \"Date :\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 35, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 251.26171875, \"y\": 186.4296875, \"id\": \"date-value\", \"bold\": true, \"text\": \"{{document_date}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 78, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 354.8125, \"y\": 186.234375, \"id\": \"ref-label\", \"bold\": false, \"text\": \"Ref :\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 68.22265625, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 409.68359375, \"y\": 187.29296875, \"id\": \"ref-value\", \"bold\": false, \"text\": \"{{reference_number}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 69.37890625, \"height\": 16, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 29, \"y\": 204, \"id\": \"lines-table\", \"bold\": false, \"text\": \"\", \"type\": \"table\", \"align\": \"left\", \"sides\": 5, \"width\": 537, \"height\": 365, \"italic\": false, \"cellGap\": 4, \"columns\": [{\"key\": \"item_name\", \"align\": \"left\", \"label\": \"Item\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 4.5}, {\"key\": \"qty\", \"align\": \"center\", \"label\": \"Qty\", \"titleAlign\": \"center\", \"totalColumn\": false, \"widthFactor\": 1}], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 26, \"underline\": false, \"printTotal\": true, \"barcodeType\": \"code128\", \"headerColor\": 4289581296, \"printHeader\": true, \"strokeColor\": 4282156725, \"strokeWidth\": 1, \"titleHeight\": 22, \"borderRadius\": 0, \"bodyTextColor\": 4282156725, \"headerTextColor\": 4279310375}, {\"x\": 37.796875, \"y\": 633.7578125, \"id\": \"terms-title\", \"bold\": true, \"text\": \"Terms and Condition\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 130, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 37, \"y\": 712, \"id\": \"terms-text\", \"bold\": false, \"text\": \"{{terms_conditions}}\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 320, \"height\": 38, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 8, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 352.97265625, \"y\": 785.78515625, \"id\": \"auth-signatory\", \"bold\": false, \"text\": \"Authorised Signatory\", \"type\": \"text\", \"align\": \"right\", \"sides\": 5, \"width\": 198, \"height\": 14, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 9, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": false, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4281811281, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4281811281, \"headerTextColor\": 4279310375}, {\"x\": 108.11328125, \"y\": 70.61328125, \"id\": \"text-29\", \"bold\": true, \"text\": \"Sakthi Controller \", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 219.93359375, \"height\": 23.19140625, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 16, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}, {\"x\": 106.89453125, \"y\": 98.53515625, \"id\": \"text-30\", \"bold\": false, \"text\": \"153, Karunai Nagar, K. Sevoor Katpadi Taluk, Tamil Nadu 632106\", \"type\": \"text\", \"align\": \"left\", \"sides\": 5, \"width\": 197.296875, \"height\": 35.03515625, \"italic\": false, \"cellGap\": 6, \"columns\": [], \"dataPath\": \"lines\", \"fontSize\": 12, \"assetPath\": \"{{company_logo_url}}\", \"fillAlpha\": 0, \"fillColor\": 4294967295, \"multiline\": true, \"rowHeight\": 30, \"underline\": false, \"printTotal\": false, \"barcodeType\": \"code128\", \"headerColor\": 4294047225, \"printHeader\": true, \"strokeColor\": 4279310375, \"strokeWidth\": 1, \"titleHeight\": 30, \"borderRadius\": 0, \"bodyTextColor\": 4279310375, \"headerTextColor\": 4279310375}], \"gridSize\": 8, \"showGrid\": false, \"pageWidth\": 595, \"pageHeight\": 842, \"mediaPreset\": \"A4\", \"orientation\": \"portrait\", \"backgroundOpacity\": 0.18, \"backgroundImagePath\": null}', 1, '2026-05-29 06:04:16', '2026-05-29 06:04:35');

-- --------------------------------------------------------

--
-- Table structure for table `production_material_issues`
--

CREATE TABLE `production_material_issues` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `issue_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `issue_date` date NOT NULL,
  `production_order_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED NOT NULL,
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `issue_status` enum('draft','posted','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `issue_mode` enum('manual','backflush') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'manual',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `posted_by` bigint UNSIGNED DEFAULT NULL,
  `posted_at` datetime DEFAULT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `production_material_issue_lines`
--

CREATE TABLE `production_material_issue_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `production_material_issue_id` bigint UNSIGNED NOT NULL,
  `production_order_material_id` bigint UNSIGNED DEFAULT NULL,
  `line_no` int NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED NOT NULL,
  `batch_id` bigint UNSIGNED DEFAULT NULL,
  `serial_id` bigint UNSIGNED DEFAULT NULL,
  `issue_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `unit_cost` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `total_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `production_orders`
--

CREATE TABLE `production_orders` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `production_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `production_date` date NOT NULL,
  `bom_id` bigint UNSIGNED NOT NULL,
  `output_item_id` bigint UNSIGNED NOT NULL,
  `output_uom_id` bigint UNSIGNED NOT NULL,
  `planned_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `started_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `completed_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `rejected_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `balance_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `source_type` enum('manual','sales_order','forecast','reorder','mrp') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'manual',
  `source_document_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `source_document_id` bigint UNSIGNED DEFAULT NULL,
  `production_status` enum('draft','released','in_progress','partially_completed','completed','closed','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `planned_start_date` date DEFAULT NULL,
  `planned_end_date` date DEFAULT NULL,
  `actual_start_date` date DEFAULT NULL,
  `actual_end_date` date DEFAULT NULL,
  `warehouse_id` bigint UNSIGNED NOT NULL,
  `wip_warehouse_id` bigint UNSIGNED DEFAULT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `approved_by` bigint UNSIGNED DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `production_order_materials`
--

CREATE TABLE `production_order_materials` (
  `id` bigint UNSIGNED NOT NULL,
  `production_order_id` bigint UNSIGNED NOT NULL,
  `bom_line_id` bigint UNSIGNED DEFAULT NULL,
  `line_no` int NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `line_type` enum('raw_material','packing_material','consumable','semi_finished','service') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'raw_material',
  `planned_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `issued_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `returned_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `consumed_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `balance_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `warehouse_id` bigint UNSIGNED DEFAULT NULL,
  `issue_method` enum('manual','backflush') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'manual',
  `standard_rate` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `standard_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `actual_rate` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `actual_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `line_status` enum('open','partially_issued','fully_issued','consumed','closed') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'open',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `production_order_operations`
--

CREATE TABLE `production_order_operations` (
  `id` bigint UNSIGNED NOT NULL,
  `production_order_id` bigint UNSIGNED NOT NULL,
  `bom_operation_id` bigint UNSIGNED DEFAULT NULL,
  `operation_no` int NOT NULL,
  `operation_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `work_center` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `planned_setup_time_minutes` decimal(18,2) NOT NULL DEFAULT '0.00',
  `planned_run_time_minutes` decimal(18,2) NOT NULL DEFAULT '0.00',
  `actual_setup_time_minutes` decimal(18,2) NOT NULL DEFAULT '0.00',
  `actual_run_time_minutes` decimal(18,2) NOT NULL DEFAULT '0.00',
  `labor_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `machine_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `overhead_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `operation_status` enum('open','in_progress','completed','skipped') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'open',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `production_order_outputs`
--

CREATE TABLE `production_order_outputs` (
  `id` bigint UNSIGNED NOT NULL,
  `production_order_id` bigint UNSIGNED NOT NULL,
  `line_no` int NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `output_type` enum('finished_goods','semi_finished','by_product','scrap') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'finished_goods',
  `planned_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `produced_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `rejected_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `accepted_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `warehouse_id` bigint UNSIGNED DEFAULT NULL,
  `standard_rate` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `standard_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `actual_rate` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `actual_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `line_status` enum('open','partially_received','fully_received','closed') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'open',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `production_receipts`
--

CREATE TABLE `production_receipts` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `receipt_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `receipt_date` date NOT NULL,
  `production_order_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED NOT NULL,
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `receipt_status` enum('draft','posted','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `receipt_type` enum('finished_goods','semi_finished','by_product','scrap','mixed') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'finished_goods',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `posted_by` bigint UNSIGNED DEFAULT NULL,
  `posted_at` datetime DEFAULT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `production_receipt_lines`
--

CREATE TABLE `production_receipt_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `production_receipt_id` bigint UNSIGNED NOT NULL,
  `production_order_output_id` bigint UNSIGNED DEFAULT NULL,
  `line_no` int NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED NOT NULL,
  `batch_id` bigint UNSIGNED DEFAULT NULL,
  `serial_id` bigint UNSIGNED DEFAULT NULL,
  `receipt_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `accepted_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `rejected_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `unit_cost` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `total_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `output_type` enum('finished_goods','semi_finished','by_product','scrap') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'finished_goods',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `projects`
--

CREATE TABLE `projects` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `customer_party_id` bigint UNSIGNED DEFAULT NULL,
  `project_code` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `project_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `project_type` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `billing_method` enum('fixed','time_and_material','milestone','cost_plus') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'fixed',
  `expected_start_date` date DEFAULT NULL,
  `expected_end_date` date DEFAULT NULL,
  `actual_start_date` date DEFAULT NULL,
  `actual_end_date` date DEFAULT NULL,
  `budget_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `percent_completion` decimal(8,2) NOT NULL DEFAULT '0.00',
  `image_path` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `project_status` enum('draft','open','working','on_hold','completed','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `project_billings`
--

CREATE TABLE `project_billings` (
  `id` bigint UNSIGNED NOT NULL,
  `project_id` bigint UNSIGNED NOT NULL,
  `project_milestone_id` bigint UNSIGNED DEFAULT NULL,
  `billing_date` date NOT NULL,
  `billing_basis` enum('milestone','timesheet','fixed','cost_plus') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'fixed',
  `billing_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `sales_invoice_id` bigint UNSIGNED DEFAULT NULL,
  `billing_status` enum('draft','invoiced','paid','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `project_expenses`
--

CREATE TABLE `project_expenses` (
  `id` bigint UNSIGNED NOT NULL,
  `project_id` bigint UNSIGNED NOT NULL,
  `project_task_id` bigint UNSIGNED DEFAULT NULL,
  `expense_date` date NOT NULL,
  `expense_category` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `supplier_party_id` bigint UNSIGNED DEFAULT NULL,
  `purchase_invoice_id` bigint UNSIGNED DEFAULT NULL,
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `expense_status` enum('draft','approved','booked') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'approved',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `project_milestones`
--

CREATE TABLE `project_milestones` (
  `id` bigint UNSIGNED NOT NULL,
  `project_id` bigint UNSIGNED NOT NULL,
  `milestone_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `target_date` date DEFAULT NULL,
  `completion_date` date DEFAULT NULL,
  `milestone_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `milestone_status` enum('open','completed','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'open',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `project_resource_usages`
--

CREATE TABLE `project_resource_usages` (
  `id` bigint UNSIGNED NOT NULL,
  `project_id` bigint UNSIGNED NOT NULL,
  `project_task_id` bigint UNSIGNED DEFAULT NULL,
  `asset_id` bigint UNSIGNED DEFAULT NULL,
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `resource_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `usage_date` date NOT NULL,
  `usage_hours` decimal(18,2) NOT NULL DEFAULT '0.00',
  `usage_qty` decimal(18,2) NOT NULL DEFAULT '0.00',
  `unit_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `total_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `project_tasks`
--

CREATE TABLE `project_tasks` (
  `id` bigint UNSIGNED NOT NULL,
  `project_id` bigint UNSIGNED NOT NULL,
  `task_code` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `task_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `assigned_employee_id` bigint UNSIGNED DEFAULT NULL,
  `planned_start_date` date DEFAULT NULL,
  `planned_end_date` date DEFAULT NULL,
  `actual_start_date` date DEFAULT NULL,
  `actual_end_date` date DEFAULT NULL,
  `estimated_hours` decimal(18,2) NOT NULL DEFAULT '0.00',
  `actual_hours` decimal(18,2) NOT NULL DEFAULT '0.00',
  `estimated_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `actual_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `progress_percent` decimal(8,2) NOT NULL DEFAULT '0.00',
  `task_status` enum('open','working','completed','on_hold','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'open',
  `is_billable` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `project_timesheets`
--

CREATE TABLE `project_timesheets` (
  `id` bigint UNSIGNED NOT NULL,
  `project_id` bigint UNSIGNED NOT NULL,
  `project_task_id` bigint UNSIGNED DEFAULT NULL,
  `employee_id` bigint UNSIGNED NOT NULL,
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `work_date` date NOT NULL,
  `hours_worked` decimal(18,2) NOT NULL DEFAULT '0.00',
  `hourly_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `billable_rate` decimal(18,2) NOT NULL DEFAULT '0.00',
  `cost_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `billable_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `timesheet_status` enum('draft','approved','rejected') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'approved',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `project_vendor_works`
--

CREATE TABLE `project_vendor_works` (
  `id` bigint UNSIGNED NOT NULL,
  `project_id` bigint UNSIGNED NOT NULL,
  `project_task_id` bigint UNSIGNED DEFAULT NULL,
  `vendor_party_id` bigint UNSIGNED NOT NULL,
  `purchase_order_id` bigint UNSIGNED DEFAULT NULL,
  `purchase_invoice_id` bigint UNSIGNED DEFAULT NULL,
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `work_description` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `work_status` enum('open','ordered','in_progress','completed') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'open',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `purchase_invoices`
--

CREATE TABLE `purchase_invoices` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `purchase_order_id` bigint UNSIGNED DEFAULT NULL,
  `purchase_receipt_id` bigint UNSIGNED DEFAULT NULL,
  `invoice_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `invoice_date` date NOT NULL,
  `due_date` date DEFAULT NULL,
  `supplier_party_id` bigint UNSIGNED NOT NULL,
  `billing_address_id` bigint UNSIGNED DEFAULT NULL,
  `shipping_address_id` bigint UNSIGNED DEFAULT NULL,
  `contact_id` bigint UNSIGNED DEFAULT NULL,
  `supplier_reference_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `supplier_reference_date` date DEFAULT NULL,
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
  `paid_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `balance_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `adjustment_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `adjustment_account_id` bigint UNSIGNED DEFAULT NULL,
  `adjustment_remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
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

-- --------------------------------------------------------

--
-- Table structure for table `purchase_invoice_lines`
--

CREATE TABLE `purchase_invoice_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `purchase_invoice_id` bigint UNSIGNED NOT NULL,
  `purchase_order_line_id` bigint UNSIGNED DEFAULT NULL,
  `purchase_receipt_line_id` bigint UNSIGNED DEFAULT NULL,
  `line_no` int NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED DEFAULT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `batch_id` bigint UNSIGNED DEFAULT NULL,
  `serial_id` bigint UNSIGNED DEFAULT NULL,
  `description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `invoiced_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `returned_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `pending_return_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `rate` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `discount_percent` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `discount_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `gross_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `taxable_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `tax_code_id` bigint UNSIGNED DEFAULT NULL,
  `tax_percent` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `cgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `sgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `igst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `cess_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `line_total` decimal(18,2) NOT NULL DEFAULT '0.00',
  `line_status` enum('open','partially_returned','fully_returned','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'open',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `purchase_orders`
--

CREATE TABLE `purchase_orders` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `purchase_requisition_id` bigint UNSIGNED DEFAULT NULL,
  `order_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `order_date` date NOT NULL,
  `expected_receipt_date` date DEFAULT NULL,
  `supplier_party_id` bigint UNSIGNED NOT NULL,
  `billing_address_id` bigint UNSIGNED DEFAULT NULL,
  `shipping_address_id` bigint UNSIGNED DEFAULT NULL,
  `contact_id` bigint UNSIGNED DEFAULT NULL,
  `supplier_reference_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `supplier_reference_date` date DEFAULT NULL,
  `currency_code` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'INR',
  `exchange_rate` decimal(18,6) NOT NULL DEFAULT '1.000000',
  `subtotal` decimal(18,2) NOT NULL DEFAULT '0.00',
  `discount_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `taxable_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `cgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `sgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `igst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `cess_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `round_off_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `total_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `order_status` enum('draft','confirmed','partially_received','fully_received','partially_invoiced','fully_invoiced','closed','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `terms_conditions` text COLLATE utf8mb4_unicode_ci,
  `approved_by` bigint UNSIGNED DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `purchase_order_lines`
--

CREATE TABLE `purchase_order_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `purchase_order_id` bigint UNSIGNED NOT NULL,
  `purchase_requisition_line_id` bigint UNSIGNED DEFAULT NULL,
  `line_no` int NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED DEFAULT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ordered_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `received_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `invoiced_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `pending_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `rate` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `discount_percent` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `discount_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `gross_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `taxable_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `tax_code_id` bigint UNSIGNED DEFAULT NULL,
  `tax_percent` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `cgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `sgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `igst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `cess_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `line_total` decimal(18,2) NOT NULL DEFAULT '0.00',
  `line_status` enum('open','partially_received','fully_received','partially_invoiced','fully_invoiced','closed','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'open',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `purchase_payments`
--

CREATE TABLE `purchase_payments` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `payment_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `payment_date` date NOT NULL,
  `supplier_party_id` bigint UNSIGNED NOT NULL,
  `payment_mode` enum('cash','bank','upi','cheque','card','wallet','adjustment','other') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'bank',
  `account_id` bigint UNSIGNED NOT NULL,
  `reference_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reference_date` date DEFAULT NULL,
  `paid_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `unallocated_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `payment_status` enum('draft','posted','partially_allocated','fully_allocated','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `posted_by` bigint UNSIGNED DEFAULT NULL,
  `posted_at` datetime DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `purchase_payment_allocations`
--

CREATE TABLE `purchase_payment_allocations` (
  `id` bigint UNSIGNED NOT NULL,
  `purchase_payment_id` bigint UNSIGNED NOT NULL,
  `purchase_invoice_id` bigint UNSIGNED DEFAULT NULL,
  `allocated_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `allocation_type` enum('against_invoice','advance','on_account','adjustment') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'against_invoice',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `purchase_receipts`
--

CREATE TABLE `purchase_receipts` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `purchase_order_id` bigint UNSIGNED DEFAULT NULL,
  `receipt_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `receipt_date` date NOT NULL,
  `supplier_party_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED NOT NULL,
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `supplier_dc_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `supplier_dc_date` date DEFAULT NULL,
  `supplier_invoice_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `supplier_invoice_date` date DEFAULT NULL,
  `vehicle_no` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `transporter_party_id` bigint UNSIGNED DEFAULT NULL,
  `lr_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `lr_date` date DEFAULT NULL,
  `receipt_status` enum('draft','posted','partially_invoiced','fully_invoiced','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `posted_by` bigint UNSIGNED DEFAULT NULL,
  `posted_at` datetime DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `purchase_receipt_lines`
--

CREATE TABLE `purchase_receipt_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `purchase_receipt_id` bigint UNSIGNED NOT NULL,
  `purchase_order_line_id` bigint UNSIGNED DEFAULT NULL,
  `line_no` int NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED NOT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `batch_id` bigint UNSIGNED DEFAULT NULL,
  `serial_id` bigint UNSIGNED DEFAULT NULL,
  `description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `received_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `accepted_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `rejected_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `invoiced_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `pending_invoice_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `rate` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `quality_status` enum('accepted','partial_rejected','rejected','hold') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'accepted',
  `line_status` enum('open','partially_invoiced','fully_invoiced','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'open',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `purchase_requisitions`
--

CREATE TABLE `purchase_requisitions` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `requisition_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `requisition_date` date NOT NULL,
  `required_date` date DEFAULT NULL,
  `requested_by` bigint UNSIGNED DEFAULT NULL,
  `department` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `purpose` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `requisition_status` enum('draft','approved','partially_ordered','fully_ordered','closed','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `approved_by` bigint UNSIGNED DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `purchase_requisition_lines`
--

CREATE TABLE `purchase_requisition_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `purchase_requisition_id` bigint UNSIGNED NOT NULL,
  `line_no` int NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED DEFAULT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `requested_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `ordered_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `pending_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `estimated_rate` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `estimated_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `line_status` enum('open','partially_ordered','fully_ordered','closed','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'open',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `purchase_returns`
--

CREATE TABLE `purchase_returns` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `purchase_invoice_id` bigint UNSIGNED DEFAULT NULL,
  `return_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `return_date` date NOT NULL,
  `supplier_party_id` bigint UNSIGNED NOT NULL,
  `subtotal` decimal(18,2) NOT NULL DEFAULT '0.00',
  `discount_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `taxable_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `cgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `sgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `igst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `cess_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `round_off_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `total_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `return_reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `return_status` enum('draft','posted','debited','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `posted_by` bigint UNSIGNED DEFAULT NULL,
  `posted_at` datetime DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `purchase_return_lines`
--

CREATE TABLE `purchase_return_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `purchase_return_id` bigint UNSIGNED NOT NULL,
  `purchase_invoice_line_id` bigint UNSIGNED DEFAULT NULL,
  `line_no` int NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED NOT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `batch_id` bigint UNSIGNED DEFAULT NULL,
  `serial_id` bigint UNSIGNED DEFAULT NULL,
  `return_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `rate` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `discount_percent` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `discount_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `gross_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `taxable_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `tax_code_id` bigint UNSIGNED DEFAULT NULL,
  `tax_percent` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `cgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `sgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `igst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `cess_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `line_total` decimal(18,2) NOT NULL DEFAULT '0.00',
  `return_reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `qc_inspections`
--

CREATE TABLE `qc_inspections` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `inspection_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `inspection_date` date NOT NULL,
  `qc_plan_id` bigint UNSIGNED DEFAULT NULL,
  `inspection_scope` enum('purchase_receipt','production_receipt','jobwork_receipt','stock_receipt','sales_return') COLLATE utf8mb4_unicode_ci NOT NULL,
  `source_document_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `source_document_id` bigint UNSIGNED NOT NULL,
  `source_line_id` bigint UNSIGNED DEFAULT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED DEFAULT NULL,
  `batch_id` bigint UNSIGNED DEFAULT NULL,
  `serial_id` bigint UNSIGNED DEFAULT NULL,
  `lot_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sample_size` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `inspected_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `accepted_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `rejected_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `hold_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `rework_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `inspection_status` enum('draft','in_progress','completed','approved','rejected','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `final_result` enum('accepted','rejected','hold','rework','partial_accept') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `inspected_by` bigint UNSIGNED DEFAULT NULL,
  `inspected_at` datetime DEFAULT NULL,
  `approved_by` bigint UNSIGNED DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `qc_inspection_lines`
--

CREATE TABLE `qc_inspection_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `qc_inspection_id` bigint UNSIGNED NOT NULL,
  `qc_plan_line_id` bigint UNSIGNED DEFAULT NULL,
  `line_no` int NOT NULL,
  `checkpoint_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `checkpoint_type` enum('visual','dimension','weight','color','function','packing','chemical','mechanical','documentation','other') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'visual',
  `expected_value` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `actual_value` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `measured_value` decimal(18,6) DEFAULT NULL,
  `tolerance_min` decimal(18,6) DEFAULT NULL,
  `tolerance_max` decimal(18,6) DEFAULT NULL,
  `result_status` enum('pass','fail','hold','na') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pass',
  `is_critical` tinyint(1) NOT NULL DEFAULT '0',
  `is_mandatory` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `qc_non_conformance_logs`
--

CREATE TABLE `qc_non_conformance_logs` (
  `id` bigint UNSIGNED NOT NULL,
  `qc_inspection_id` bigint UNSIGNED NOT NULL,
  `qc_inspection_line_id` bigint UNSIGNED DEFAULT NULL,
  `defect_code` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `defect_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `severity` enum('minor','major','critical') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'minor',
  `defect_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `root_cause` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `corrective_action` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `preventive_action` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `assigned_to` bigint UNSIGNED DEFAULT NULL,
  `due_date` date DEFAULT NULL,
  `closure_status` enum('open','in_progress','closed','waived') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'open',
  `closed_by` bigint UNSIGNED DEFAULT NULL,
  `closed_at` datetime DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `qc_plans`
--

CREATE TABLE `qc_plans` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED DEFAULT NULL,
  `location_id` bigint UNSIGNED DEFAULT NULL,
  `plan_code` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `plan_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `item_id` bigint UNSIGNED DEFAULT NULL,
  `item_category_id` bigint UNSIGNED DEFAULT NULL,
  `qc_scope` enum('purchase_receipt','production_receipt','jobwork_receipt','stock_receipt','sales_return','all') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'all',
  `sampling_method` enum('100_percent','random','lot_based','batch_based','custom') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '100_percent',
  `acceptance_basis` enum('all_pass','min_pass_percent','critical_only','manual_decision') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'all_pass',
  `min_pass_percent` decimal(8,4) NOT NULL DEFAULT '100.0000',
  `approval_status` enum('draft','approved','inactive','obsolete') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `effective_from` date DEFAULT NULL,
  `effective_to` date DEFAULT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `approved_by` bigint UNSIGNED DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `qc_plan_lines`
--

CREATE TABLE `qc_plan_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `qc_plan_id` bigint UNSIGNED NOT NULL,
  `line_no` int NOT NULL,
  `checkpoint_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `checkpoint_type` enum('visual','dimension','weight','color','function','packing','chemical','mechanical','documentation','other') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'visual',
  `specification` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tolerance_min` decimal(18,6) DEFAULT NULL,
  `tolerance_max` decimal(18,6) DEFAULT NULL,
  `expected_text` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `unit` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_critical` tinyint(1) NOT NULL DEFAULT '0',
  `is_mandatory` tinyint(1) NOT NULL DEFAULT '1',
  `sequence_no` int NOT NULL DEFAULT '1',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `qc_result_actions`
--

CREATE TABLE `qc_result_actions` (
  `id` bigint UNSIGNED NOT NULL,
  `qc_inspection_id` bigint UNSIGNED NOT NULL,
  `action_type` enum('accept_to_stock','reject_to_supplier','reject_to_scrap','move_to_hold','move_to_quarantine','send_for_rework','manual_override') COLLATE utf8mb4_unicode_ci NOT NULL,
  `action_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `target_warehouse_id` bigint UNSIGNED DEFAULT NULL,
  `reference_document_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reference_document_id` bigint UNSIGNED DEFAULT NULL,
  `action_status` enum('pending','completed','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `action_by` bigint UNSIGNED DEFAULT NULL,
  `action_at` datetime DEFAULT NULL,
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `roles`
--

CREATE TABLE `roles` (
  `id` bigint UNSIGNED NOT NULL,
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `is_system_role` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `role_permissions`
--

CREATE TABLE `role_permissions` (
  `id` bigint UNSIGNED NOT NULL,
  `role_id` bigint UNSIGNED NOT NULL,
  `permission_id` bigint UNSIGNED NOT NULL,
  `allow_view` tinyint(1) NOT NULL DEFAULT '0',
  `allow_create` tinyint(1) NOT NULL DEFAULT '0',
  `allow_update` tinyint(1) NOT NULL DEFAULT '0',
  `allow_delete` tinyint(1) NOT NULL DEFAULT '0',
  `allow_approve` tinyint(1) NOT NULL DEFAULT '0',
  `allow_print` tinyint(1) NOT NULL DEFAULT '0',
  `allow_export` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sales_deliveries`
--

CREATE TABLE `sales_deliveries` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `sales_order_id` bigint UNSIGNED DEFAULT NULL,
  `delivery_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `delivery_date` date NOT NULL,
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `customer_party_id` bigint UNSIGNED NOT NULL,
  `billing_address_id` bigint UNSIGNED DEFAULT NULL,
  `shipping_address_id` bigint UNSIGNED DEFAULT NULL,
  `contact_id` bigint UNSIGNED DEFAULT NULL,
  `vehicle_no` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `transporter_party_id` bigint UNSIGNED DEFAULT NULL,
  `lr_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `lr_date` date DEFAULT NULL,
  `delivery_status` enum('draft','posted','partially_invoiced','fully_invoiced','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
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

-- --------------------------------------------------------

--
-- Table structure for table `sales_delivery_lines`
--

CREATE TABLE `sales_delivery_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `sales_delivery_id` bigint UNSIGNED NOT NULL,
  `sales_order_line_id` bigint UNSIGNED DEFAULT NULL,
  `line_no` int NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED NOT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `batch_id` bigint UNSIGNED DEFAULT NULL,
  `serial_id` bigint UNSIGNED DEFAULT NULL,
  `description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `delivered_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `invoiced_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `returned_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `pending_invoice_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `rate` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `line_status` enum('open','partially_invoiced','fully_invoiced','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'open',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sales_delivery_returnable_dcs`
--

CREATE TABLE `sales_delivery_returnable_dcs` (
  `id` bigint UNSIGNED NOT NULL,
  `sales_delivery_id` bigint UNSIGNED NOT NULL,
  `line_no` int UNSIGNED NOT NULL,
  `item_id` bigint UNSIGNED DEFAULT NULL,
  `item_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `qty` decimal(18,6) NOT NULL,
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
(29, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0001', '2026-04-01', NULL, 1, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 21350.00, 0.00, 21350.00, 0.00, 0.00, 3843.00, 0.00, 'manual', 1.00, 0.00, 25193.00, 0.00, NULL, NULL, 25193.00, 0.00, 87, 'paid', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 06:53:39', 1, 4, 4, '2026-06-19 06:53:20', '2026-06-19 12:43:55'),
(30, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0002', '2026-04-02', NULL, 2, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 1240.00, 0.00, 1240.00, 111.60, 111.60, 0.00, 0.00, 'manual', 1.00, -0.20, 1463.00, 0.00, NULL, NULL, 1463.00, 0.00, 89, 'paid', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 09:30:05', 1, 4, 4, '2026-06-19 09:29:55', '2026-06-20 05:04:25'),
(31, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0003', '2026-04-02', NULL, 3, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 47711.90, 0.00, 47711.90, 0.00, 0.00, 8588.14, 0.00, 'manual', 1.00, -0.04, 56300.00, 0.00, NULL, NULL, 0.00, 56300.00, 90, 'posted', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 09:34:59', 1, 4, 4, '2026-06-19 09:34:50', '2026-06-19 09:34:59'),
(32, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0004', '2026-04-03', NULL, 4, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 4237.29, 0.00, 4237.29, 381.36, 381.36, 0.00, 0.00, 'manual', 1.00, 0.00, 5000.01, 0.00, NULL, NULL, 0.00, 5000.01, 91, 'posted', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 09:38:01', 1, 4, 4, '2026-06-19 09:37:45', '2026-06-19 09:38:01'),
(33, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0005', '2026-04-03', NULL, 5, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 4508.47, 0.00, 4508.47, 405.76, 405.76, 0.00, 0.00, 'manual', 1.00, 0.01, 5320.00, 0.00, NULL, NULL, 0.00, 5320.00, 92, 'posted', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 09:44:02', 1, 4, 4, '2026-06-19 09:43:48', '2026-06-19 09:44:02'),
(34, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0006', '2026-04-04', NULL, 6, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 4406.78, 0.00, 4406.78, 396.61, 396.61, 0.00, 0.00, 'manual', 1.00, 0.00, 5200.00, 0.00, NULL, NULL, 0.00, 5200.00, 93, 'posted', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 09:54:03', 1, 4, 4, '2026-06-19 09:53:36', '2026-06-19 09:54:03'),
(35, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0007', '2026-04-06', NULL, 5, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 8813.56, 0.00, 8813.56, 793.22, 793.22, 0.00, 0.00, 'manual', 1.00, 0.00, 10400.00, 0.00, NULL, NULL, 0.00, 10400.00, 94, 'posted', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 10:00:44', 1, 4, 4, '2026-06-19 09:58:32', '2026-06-19 10:00:44'),
(36, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0008', '2026-04-06', NULL, 5, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 4508.47, 0.00, 4508.47, 405.76, 405.76, 0.00, 0.00, 'manual', 1.00, 0.01, 5320.00, 0.00, NULL, NULL, 0.00, 5320.00, 95, 'posted', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 10:28:29', 1, 4, 4, '2026-06-19 10:28:02', '2026-06-19 10:28:29'),
(37, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0009', '2026-04-06', NULL, 4, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 4237.29, 0.00, 4237.29, 381.36, 381.36, 0.00, 0.00, 'manual', 1.00, 0.00, 5000.01, 0.00, NULL, NULL, 0.00, 5000.01, 96, 'posted', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 10:30:51', 1, 4, 4, '2026-06-19 10:30:45', '2026-06-19 10:30:51'),
(38, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0010', '2026-04-07', NULL, 7, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 4949.15, 0.00, 4949.15, 0.00, 0.00, 890.85, 0.00, 'manual', 1.00, 0.00, 5840.00, 0.00, NULL, NULL, 0.00, 5840.00, 97, 'posted', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 10:32:55', 1, 4, 4, '2026-06-19 10:32:47', '2026-06-19 10:32:55'),
(39, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0011', '2026-04-08', NULL, 8, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 25093.20, 0.00, 25093.20, 2258.39, 2258.39, 0.00, 0.00, 'manual', 1.00, 0.02, 29610.00, 0.00, NULL, NULL, 0.00, 29610.00, 98, 'posted', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 10:47:22', 1, 4, 4, '2026-06-19 10:47:10', '2026-06-19 10:47:22'),
(40, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0012', '2026-04-08', NULL, 9, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 4949.15, 0.00, 4949.15, 445.43, 445.43, 0.00, 0.00, 'manual', 1.00, 0.00, 5840.01, 0.00, NULL, NULL, 0.00, 5840.01, 99, 'posted', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 10:55:49', 1, 4, 4, '2026-06-19 10:55:17', '2026-06-19 10:55:49'),
(41, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0013', '2026-04-10', NULL, 10, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 4949.15, 0.00, 4949.15, 445.43, 445.43, 0.00, 0.00, 'manual', 1.00, 0.00, 5840.01, 0.00, NULL, NULL, 0.00, 5840.01, 100, 'posted', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 10:59:38', 1, 4, 4, '2026-06-19 10:59:29', '2026-06-19 10:59:38'),
(42, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0014', '2026-04-11', NULL, 11, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 4830.51, 0.00, 4830.51, 434.75, 434.75, 0.00, 0.00, 'manual', 1.00, 0.00, 5700.01, 0.00, NULL, NULL, 0.00, 5700.01, 101, 'posted', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 11:19:14', 1, 4, 4, '2026-06-19 11:18:54', '2026-06-19 11:19:14'),
(43, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0015', '2026-04-13', NULL, 6, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 4745.76, 0.00, 4745.76, 427.12, 427.12, 0.00, 0.00, 'manual', 1.00, 0.00, 5600.00, 0.00, NULL, NULL, 0.00, 5600.00, 102, 'posted', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 11:20:56', 1, 4, 4, '2026-06-19 11:20:37', '2026-06-19 11:20:56'),
(44, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0016', '2026-04-15', NULL, 12, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 24754.24, 0.00, 24754.24, 0.00, 0.00, 4455.76, 0.00, 'manual', 1.00, 0.00, 29210.00, 0.00, NULL, NULL, 0.00, 29210.00, 103, 'posted', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 11:24:35', 1, 4, 4, '2026-06-19 11:24:30', '2026-06-19 11:24:35'),
(45, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0017', '2026-04-16', NULL, 4, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 9661.02, 0.00, 9661.02, 869.49, 869.49, 0.00, 0.00, 'manual', 1.00, 0.00, 11400.00, 0.00, NULL, NULL, 0.00, 11400.00, 104, 'posted', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 11:26:16', 1, 4, 4, '2026-06-19 11:26:12', '2026-06-19 11:26:16'),
(46, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0018', '2026-04-17', NULL, 13, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 4830.51, 0.00, 4830.51, 434.75, 434.75, 0.00, 0.00, 'manual', 1.00, 0.00, 5700.01, 0.00, NULL, NULL, 0.00, 5700.01, 105, 'posted', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 11:29:17', 1, 4, 4, '2026-06-19 11:28:55', '2026-06-19 11:29:17'),
(47, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0019', '2026-04-17', NULL, 14, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 5318.64, 0.00, 5318.64, 478.68, 478.68, 0.00, 0.00, 'manual', 1.00, 0.00, 6276.00, 0.00, NULL, NULL, 0.00, 6276.00, 106, 'posted', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 11:32:01', 0, 4, 4, '2026-06-19 11:31:55', '2026-06-19 11:32:01'),
(48, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0020', '2026-04-17', NULL, 6, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 4949.15, 0.00, 4949.15, 445.43, 445.43, 0.00, 0.00, 'manual', 1.00, 0.00, 5840.01, 0.00, NULL, NULL, 0.00, 5840.01, 107, 'posted', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 11:34:10', 1, 4, 4, '2026-06-19 11:34:01', '2026-06-19 11:34:10'),
(49, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0021', '2026-04-20', NULL, 15, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 4949.15, 0.00, 4949.15, 445.43, 445.43, 0.00, 0.00, 'manual', 1.00, 0.00, 5840.01, 0.00, NULL, NULL, 0.00, 5840.01, 108, 'posted', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 11:40:27', 1, 4, 4, '2026-06-19 11:40:00', '2026-06-19 11:40:27'),
(50, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0022', '2026-04-21', NULL, 13, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 4949.15, 0.00, 4949.15, 445.43, 445.43, 0.00, 0.00, 'manual', 1.00, 0.00, 5840.01, 0.00, NULL, NULL, 0.00, 5840.01, 109, 'posted', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 11:47:14', 1, 4, 4, '2026-06-19 11:47:07', '2026-06-19 11:47:14'),
(51, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0023', '2026-04-28', NULL, 16, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 4491.53, 0.00, 4491.53, 404.24, 404.24, 0.00, 0.00, 'manual', 1.00, -0.01, 5300.00, 0.00, NULL, NULL, 0.00, 5300.00, 110, 'posted', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 11:50:25', 1, 4, 4, '2026-06-19 11:50:19', '2026-06-19 11:50:25'),
(52, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0024', '2026-04-28', NULL, 17, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 12000.00, 0.00, 12000.00, 0.00, 0.00, 2160.00, 0.00, 'manual', 1.00, 0.00, 14160.00, 0.00, NULL, NULL, 0.00, 14160.00, 111, 'posted', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 12:05:09', 1, 4, 4, '2026-06-19 12:05:05', '2026-06-19 12:05:09'),
(53, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0025', '2026-04-28', NULL, 12, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 24754.24, 0.00, 24754.24, 0.00, 0.00, 4455.76, 0.00, 'manual', 1.00, 0.00, 29210.00, 0.00, NULL, NULL, 0.00, 29210.00, 112, 'posted', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 12:07:15', 1, 4, 4, '2026-06-19 12:07:12', '2026-06-19 12:07:15'),
(54, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0026', '2026-04-29', NULL, 4, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 4949.15, 0.00, 4949.15, 445.43, 445.43, 0.00, 0.00, 'manual', 1.00, 0.00, 5840.01, 0.00, NULL, NULL, 0.00, 5840.01, 113, 'posted', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 12:28:45', 1, 4, 4, '2026-06-19 12:17:30', '2026-06-19 12:28:45'),
(55, 1, 1, 1, 1, 5, NULL, NULL, 'SI/26-27/0027', '2026-04-30', NULL, 18, NULL, NULL, NULL, NULL, NULL, 'INR', 1.000000, 4745.76, 0.00, 4745.76, 427.12, 427.12, 0.00, 0.00, 'manual', 1.00, 0.00, 5600.00, 0.00, NULL, NULL, 0.00, 5600.00, 114, 'posted', NULL, '1. Goods once sold will not be taken back or exchanged unless agreed in writing.\n2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.\n3. Ownership of goods remains with the seller until full payment is received.\n4. All disputes are subject to Vellore jurisdiction.', 4, '2026-06-19 12:30:26', 1, 4, 4, '2026-06-19 12:30:15', '2026-06-19 12:30:26');

-- --------------------------------------------------------

--
-- Table structure for table `sales_invoice_lines`
--

CREATE TABLE `sales_invoice_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `sales_invoice_id` bigint UNSIGNED NOT NULL,
  `sales_order_line_id` bigint UNSIGNED DEFAULT NULL,
  `sales_delivery_line_id` bigint UNSIGNED DEFAULT NULL,
  `line_no` int NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED DEFAULT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `batch_id` bigint UNSIGNED DEFAULT NULL,
  `serial_id` bigint UNSIGNED DEFAULT NULL,
  `description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `invoiced_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `returned_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `pending_return_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `rate` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `discount_percent` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `discount_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `gross_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `taxable_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `tax_code_id` bigint UNSIGNED DEFAULT NULL,
  `tax_percent` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `cgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `sgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `igst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `cess_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `line_total` decimal(18,2) NOT NULL DEFAULT '0.00',
  `line_status` enum('open','partially_returned','fully_returned','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'open',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `sales_invoice_lines`
--

INSERT INTO `sales_invoice_lines` (`id`, `sales_invoice_id`, `sales_order_line_id`, `sales_delivery_line_id`, `line_no`, `item_id`, `warehouse_id`, `uom_id`, `batch_id`, `serial_id`, `description`, `invoiced_qty`, `returned_qty`, `pending_return_qty`, `rate`, `discount_percent`, `discount_amount`, `gross_amount`, `taxable_amount`, `tax_code_id`, `tax_percent`, `cgst_amount`, `sgst_amount`, `igst_amount`, `cess_amount`, `line_total`, `line_status`, `remarks`, `created_at`) VALUES
(47, 29, NULL, NULL, 1, 3, 1, 1, NULL, NULL, 'HappyBell 2020', 5.000000, 0.000000, 0.000000, 4200.0000, 0.0000, 0.00, 21000.00, 21000.00, 4, 18.0000, 0.00, 0.00, 3780.00, 0.00, 24780.00, 'open', NULL, '2026-06-19 06:53:20'),
(48, 29, NULL, NULL, 2, 32, 8, 1, NULL, NULL, 'Shipping Charges', 1.000000, 0.000000, 0.000000, 350.0000, 0.0000, 0.00, 350.00, 350.00, 4, 18.0000, 0.00, 0.00, 63.00, 0.00, 413.00, 'open', NULL, '2026-06-19 06:53:20'),
(49, 30, NULL, NULL, 1, 6, 1, 5, NULL, NULL, 'FLUX', 4.000000, 0.000000, 0.000000, 310.0000, 0.0000, 0.00, 1240.00, 1240.00, 4, 18.0000, 111.60, 111.60, 0.00, 0.00, 1463.20, 'open', NULL, '2026-06-19 09:29:55'),
(51, 31, NULL, NULL, 1, 3, 1, 1, NULL, NULL, 'HappyBell 2020', 10.000000, 0.000000, 0.000000, 4771.1900, 0.0000, 0.00, 47711.90, 47711.90, 4, 18.0000, 0.00, 0.00, 8588.14, 0.00, 56300.04, 'open', NULL, '2026-06-19 09:34:57'),
(52, 32, NULL, NULL, 1, 3, 1, 1, NULL, NULL, 'HappyBell 2020', 1.000000, 0.000000, 0.000000, 4237.2900, 0.0000, 0.00, 4237.29, 4237.29, 4, 18.0000, 381.36, 381.36, 0.00, 0.00, 5000.01, 'open', NULL, '2026-06-19 09:37:45'),
(53, 33, NULL, NULL, 1, 3, 1, 1, NULL, NULL, 'HappyBell 2020', 1.000000, 0.000000, 0.000000, 4508.4700, 0.0000, 0.00, 4508.47, 4508.47, 4, 18.0000, 405.76, 405.76, 0.00, 0.00, 5319.99, 'open', NULL, '2026-06-19 09:43:48'),
(55, 34, NULL, NULL, 1, 3, 1, 1, NULL, NULL, 'HappyBell 2020', 1.000000, 0.000000, 0.000000, 4406.7800, 0.0000, 0.00, 4406.78, 4406.78, 4, 18.0000, 396.61, 396.61, 0.00, 0.00, 5200.00, 'open', NULL, '2026-06-19 09:54:01'),
(58, 35, NULL, NULL, 1, 3, 1, 1, NULL, NULL, 'HappyBell 2020', 2.000000, 0.000000, 0.000000, 4406.7800, 0.0000, 0.00, 8813.56, 8813.56, 4, 18.0000, 793.22, 793.22, 0.00, 0.00, 10400.00, 'open', NULL, '2026-06-19 10:00:32'),
(59, 36, NULL, NULL, 1, 3, 1, 1, NULL, NULL, 'HappyBell 2020', 1.000000, 0.000000, 0.000000, 4508.4700, 0.0000, 0.00, 4508.47, 4508.47, 4, 18.0000, 405.76, 405.76, 0.00, 0.00, 5319.99, 'open', NULL, '2026-06-19 10:28:02'),
(60, 37, NULL, NULL, 1, 3, 1, 1, NULL, NULL, 'HappyBell 2020', 1.000000, 0.000000, 0.000000, 4237.2900, 0.0000, 0.00, 4237.29, 4237.29, 4, 18.0000, 381.36, 381.36, 0.00, 0.00, 5000.01, 'open', NULL, '2026-06-19 10:30:45'),
(61, 38, NULL, NULL, 1, 3, 1, 1, NULL, NULL, 'HappyBell 2020', 1.000000, 0.000000, 0.000000, 4830.5100, 0.0000, 0.00, 4830.51, 4830.51, 4, 18.0000, 0.00, 0.00, 869.49, 0.00, 5700.00, 'open', NULL, '2026-06-19 10:32:47'),
(62, 38, NULL, NULL, 2, 32, 8, 1, NULL, NULL, 'Shipping Charges', 1.000000, 0.000000, 0.000000, 118.6400, 0.0000, 0.00, 118.64, 118.64, 4, 18.0000, 0.00, 0.00, 21.36, 0.00, 140.00, 'open', NULL, '2026-06-19 10:32:47'),
(63, 39, NULL, NULL, 1, 3, 1, 1, NULL, NULL, 'HappyBell 2020', 5.000000, 0.000000, 0.000000, 4900.0000, 0.0000, 0.00, 24500.00, 24500.00, 4, 18.0000, 2205.00, 2205.00, 0.00, 0.00, 28910.00, 'open', NULL, '2026-06-19 10:47:10'),
(64, 39, NULL, NULL, 2, 32, 8, 1, NULL, NULL, 'Shipping Charges', 5.000000, 0.000000, 0.000000, 118.6400, 0.0000, 0.00, 593.20, 593.20, 4, 18.0000, 53.39, 53.39, 0.00, 0.00, 699.98, 'open', NULL, '2026-06-19 10:47:10'),
(65, 40, NULL, NULL, 1, 3, 1, 1, NULL, NULL, 'HappyBell 2020', 1.000000, 0.000000, 0.000000, 4830.5100, 0.0000, 0.00, 4830.51, 4830.51, 4, 18.0000, 434.75, 434.75, 0.00, 0.00, 5700.01, 'open', NULL, '2026-06-19 10:55:17'),
(66, 40, NULL, NULL, 2, 32, 8, 1, NULL, NULL, 'Shipping Charges', 1.000000, 0.000000, 0.000000, 118.6400, 0.0000, 0.00, 118.64, 118.64, 4, 18.0000, 10.68, 10.68, 0.00, 0.00, 140.00, 'open', NULL, '2026-06-19 10:55:17'),
(67, 41, NULL, NULL, 1, 3, 1, 1, NULL, NULL, 'HappyBell 2020', 1.000000, 0.000000, 0.000000, 4830.5100, 0.0000, 0.00, 4830.51, 4830.51, 4, 18.0000, 434.75, 434.75, 0.00, 0.00, 5700.01, 'open', NULL, '2026-06-19 10:59:29'),
(68, 41, NULL, NULL, 2, 32, 8, 1, NULL, NULL, 'Shipping Charges', 1.000000, 0.000000, 0.000000, 118.6400, 0.0000, 0.00, 118.64, 118.64, 4, 18.0000, 10.68, 10.68, 0.00, 0.00, 140.00, 'open', NULL, '2026-06-19 10:59:29'),
(69, 42, NULL, NULL, 1, 3, 1, 1, NULL, NULL, 'HappyBell 2020', 1.000000, 0.000000, 0.000000, 4830.5100, 0.0000, 0.00, 4830.51, 4830.51, 4, 18.0000, 434.75, 434.75, 0.00, 0.00, 5700.01, 'open', NULL, '2026-06-19 11:18:54'),
(70, 43, NULL, NULL, 1, 3, 1, 1, NULL, NULL, 'HappyBell 2020', 1.000000, 0.000000, 0.000000, 4745.7600, 0.0000, 0.00, 4745.76, 4745.76, 4, 18.0000, 427.12, 427.12, 0.00, 0.00, 5600.00, 'open', NULL, '2026-06-19 11:20:37'),
(71, 44, NULL, NULL, 1, 3, 1, 1, NULL, NULL, 'HappyBell 2020', 5.000000, 0.000000, 0.000000, 4900.0000, 0.0000, 0.00, 24500.00, 24500.00, 4, 18.0000, 0.00, 0.00, 4410.00, 0.00, 28910.00, 'open', NULL, '2026-06-19 11:24:30'),
(72, 44, NULL, NULL, 2, 32, 8, 1, NULL, NULL, 'Shipping Charges', 1.000000, 0.000000, 0.000000, 254.2400, 0.0000, 0.00, 254.24, 254.24, 4, 18.0000, 0.00, 0.00, 45.76, 0.00, 300.00, 'open', NULL, '2026-06-19 11:24:30'),
(73, 45, NULL, NULL, 1, 3, 1, 1, NULL, NULL, 'HappyBell 2020', 2.000000, 0.000000, 0.000000, 4830.5100, 0.0000, 0.00, 9661.02, 9661.02, 4, 18.0000, 869.49, 869.49, 0.00, 0.00, 11400.00, 'open', NULL, '2026-06-19 11:26:12'),
(74, 46, NULL, NULL, 1, 3, 1, 1, NULL, NULL, 'HappyBell 2020', 1.000000, 0.000000, 0.000000, 4830.5100, 0.0000, 0.00, 4830.51, 4830.51, 4, 18.0000, 434.75, 434.75, 0.00, 0.00, 5700.01, 'open', NULL, '2026-06-19 11:28:55'),
(75, 47, NULL, NULL, 1, 3, 1, 1, NULL, NULL, 'HappyBell 2020', 1.000000, 0.000000, 0.000000, 5318.6400, 0.0000, 0.00, 5318.64, 5318.64, 4, 18.0000, 478.68, 478.68, 0.00, 0.00, 6276.00, 'open', NULL, '2026-06-19 11:31:55'),
(76, 48, NULL, NULL, 1, 3, 1, 1, NULL, NULL, 'HappyBell 2020', 1.000000, 0.000000, 0.000000, 4830.5100, 0.0000, 0.00, 4830.51, 4830.51, 4, 18.0000, 434.75, 434.75, 0.00, 0.00, 5700.01, 'open', NULL, '2026-06-19 11:34:01'),
(77, 48, NULL, NULL, 2, 32, 8, 1, NULL, NULL, 'Shipping Charges', 1.000000, 0.000000, 0.000000, 118.6400, 0.0000, 0.00, 118.64, 118.64, 4, 18.0000, 10.68, 10.68, 0.00, 0.00, 140.00, 'open', NULL, '2026-06-19 11:34:01'),
(80, 49, NULL, NULL, 1, 3, 1, 1, NULL, NULL, 'HappyBell 2020', 1.000000, 0.000000, 0.000000, 4830.5100, 0.0000, 0.00, 4830.51, 4830.51, 4, 18.0000, 434.75, 434.75, 0.00, 0.00, 5700.01, 'open', NULL, '2026-06-19 11:40:10'),
(81, 49, NULL, NULL, 2, 32, 8, 1, NULL, NULL, 'Shipping Charges', 1.000000, 0.000000, 0.000000, 118.6400, 0.0000, 0.00, 118.64, 118.64, 4, 18.0000, 10.68, 10.68, 0.00, 0.00, 140.00, 'open', NULL, '2026-06-19 11:40:10'),
(82, 50, NULL, NULL, 1, 3, 1, 1, NULL, NULL, 'HappyBell 2020', 1.000000, 0.000000, 0.000000, 4830.5100, 0.0000, 0.00, 4830.51, 4830.51, 4, 18.0000, 434.75, 434.75, 0.00, 0.00, 5700.01, 'open', NULL, '2026-06-19 11:47:07'),
(83, 50, NULL, NULL, 2, 32, 8, 1, NULL, NULL, 'Shipping Charges', 1.000000, 0.000000, 0.000000, 118.6400, 0.0000, 0.00, 118.64, 118.64, 4, 18.0000, 10.68, 10.68, 0.00, 0.00, 140.00, 'open', NULL, '2026-06-19 11:47:07'),
(84, 51, NULL, NULL, 1, 3, 1, 1, NULL, NULL, 'HappyBell 2020', 1.000000, 0.000000, 0.000000, 4491.5300, 0.0000, 0.00, 4491.53, 4491.53, 4, 18.0000, 404.24, 404.24, 0.00, 0.00, 5300.01, 'open', NULL, '2026-06-19 11:50:19'),
(85, 52, NULL, NULL, 1, 3, 1, 1, NULL, NULL, 'HappyBell 2020', 5.000000, 0.000000, 0.000000, 2400.0000, 0.0000, 0.00, 12000.00, 12000.00, 4, 18.0000, 0.00, 0.00, 2160.00, 0.00, 14160.00, 'open', NULL, '2026-06-19 12:05:05'),
(86, 53, NULL, NULL, 1, 3, 1, 1, NULL, NULL, 'HappyBell 2020', 5.000000, 0.000000, 0.000000, 4900.0000, 0.0000, 0.00, 24500.00, 24500.00, 4, 18.0000, 0.00, 0.00, 4410.00, 0.00, 28910.00, 'open', NULL, '2026-06-19 12:07:12'),
(87, 53, NULL, NULL, 2, 32, 8, 1, NULL, NULL, 'Shipping Charges', 1.000000, 0.000000, 0.000000, 254.2400, 0.0000, 0.00, 254.24, 254.24, 4, 18.0000, 0.00, 0.00, 45.76, 0.00, 300.00, 'open', NULL, '2026-06-19 12:07:12'),
(88, 54, NULL, NULL, 1, 3, 1, 1, NULL, NULL, 'HappyBell 2020', 1.000000, 0.000000, 0.000000, 4830.5100, 0.0000, 0.00, 4830.51, 4830.51, 4, 18.0000, 434.75, 434.75, 0.00, 0.00, 5700.01, 'open', NULL, '2026-06-19 12:17:30'),
(89, 54, NULL, NULL, 2, 32, 8, 1, NULL, NULL, 'Shipping Charges', 1.000000, 0.000000, 0.000000, 118.6400, 0.0000, 0.00, 118.64, 118.64, 4, 18.0000, 10.68, 10.68, 0.00, 0.00, 140.00, 'open', NULL, '2026-06-19 12:17:30'),
(90, 55, NULL, NULL, 1, 3, 1, 1, NULL, NULL, 'HappyBell 2020', 1.000000, 0.000000, 0.000000, 4745.7600, 0.0000, 0.00, 4745.76, 4745.76, 4, 18.0000, 427.12, 427.12, 0.00, 0.00, 5600.00, 'open', NULL, '2026-06-19 12:30:15');

-- --------------------------------------------------------

--
-- Table structure for table `sales_orders`
--

CREATE TABLE `sales_orders` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `sales_quotation_id` bigint UNSIGNED DEFAULT NULL,
  `crm_opportunity_id` bigint UNSIGNED DEFAULT NULL,
  `order_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `order_date` date NOT NULL,
  `expected_delivery_date` date DEFAULT NULL,
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
  `round_off_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `total_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `order_status` enum('draft','confirmed','partially_delivered','fully_delivered','partially_invoiced','fully_invoiced','closed','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `terms_conditions` text COLLATE utf8mb4_unicode_ci,
  `approved_by` bigint UNSIGNED DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sales_order_lines`
--

CREATE TABLE `sales_order_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `sales_order_id` bigint UNSIGNED NOT NULL,
  `sales_quotation_line_id` bigint UNSIGNED DEFAULT NULL,
  `line_no` int NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED DEFAULT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ordered_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `delivered_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `invoiced_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `pending_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `rate` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `discount_percent` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `discount_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `gross_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `taxable_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `tax_code_id` bigint UNSIGNED DEFAULT NULL,
  `tax_percent` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `cgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `sgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `igst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `cess_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `line_total` decimal(18,2) NOT NULL DEFAULT '0.00',
  `line_status` enum('open','partially_delivered','fully_delivered','partially_invoiced','fully_invoiced','closed','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'open',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sales_quotations`
--

CREATE TABLE `sales_quotations` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `quotation_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `quotation_date` date NOT NULL,
  `valid_until` date DEFAULT NULL,
  `customer_party_id` bigint UNSIGNED NOT NULL,
  `billing_address_id` bigint UNSIGNED DEFAULT NULL,
  `shipping_address_id` bigint UNSIGNED DEFAULT NULL,
  `contact_id` bigint UNSIGNED DEFAULT NULL,
  `crm_opportunity_id` bigint UNSIGNED DEFAULT NULL,
  `customer_reference_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `customer_reference_date` date DEFAULT NULL,
  `price_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `currency_code` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'INR',
  `exchange_rate` decimal(18,6) NOT NULL DEFAULT '1.000000',
  `subtotal` decimal(18,2) NOT NULL DEFAULT '0.00',
  `discount_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `taxable_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `cgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `sgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `igst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `cess_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `round_off_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `adjustment_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `adjustment_account_id` bigint UNSIGNED DEFAULT NULL,
  `adjustment_remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `total_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `quotation_status` enum('draft','posted','sent','accepted','rejected','expired','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `terms_conditions` text COLLATE utf8mb4_unicode_ci,
  `approved_by` bigint UNSIGNED DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sales_quotation_lines`
--

CREATE TABLE `sales_quotation_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `sales_quotation_id` bigint UNSIGNED NOT NULL,
  `line_no` int NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED DEFAULT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `rate` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `discount_percent` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `discount_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `gross_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `taxable_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `tax_code_id` bigint UNSIGNED DEFAULT NULL,
  `tax_percent` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `cgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `sgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `igst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `cess_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `line_total` decimal(18,2) NOT NULL DEFAULT '0.00',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sales_receipts`
--

CREATE TABLE `sales_receipts` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `receipt_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `receipt_date` date NOT NULL,
  `customer_party_id` bigint UNSIGNED NOT NULL,
  `payment_mode` enum('cash','bank','upi','cheque','card','wallet','adjustment','other') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'cash',
  `account_id` bigint UNSIGNED NOT NULL,
  `payment_reference_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `payment_reference_date` date DEFAULT NULL,
  `paid_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `unallocated_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `receipt_status` enum('draft','posted','partially_allocated','fully_allocated','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `posted_by` bigint UNSIGNED DEFAULT NULL,
  `posted_at` datetime DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `sales_receipts`
--

INSERT INTO `sales_receipts` (`id`, `company_id`, `branch_id`, `location_id`, `financial_year_id`, `document_series_id`, `receipt_no`, `receipt_date`, `customer_party_id`, `payment_mode`, `account_id`, `payment_reference_no`, `payment_reference_date`, `paid_amount`, `unallocated_amount`, `voucher_id`, `receipt_status`, `notes`, `posted_by`, `posted_at`, `is_active`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(21, 1, 1, 1, 1, 6, 'SR/26-27/0001', '2026-04-01', 1, 'bank', 74, '26099592417', '2026-04-09', 25193.00, 0.00, 115, 'fully_allocated', NULL, 4, '2026-06-19 12:43:55', 1, 4, 4, '2026-06-19 12:43:48', '2026-06-19 12:43:55'),
(22, 1, 1, 1, 1, 6, 'SR/26-27/0002', '2026-04-02', 2, 'bank', 74, 'HDFCF78F347B4303', '2026-06-01', 1463.00, 0.00, 116, 'fully_allocated', NULL, 4, '2026-06-20 05:04:25', 1, 4, 4, '2026-06-20 05:04:17', '2026-06-20 05:04:25');

-- --------------------------------------------------------

--
-- Table structure for table `sales_receipt_allocations`
--

CREATE TABLE `sales_receipt_allocations` (
  `id` bigint UNSIGNED NOT NULL,
  `sales_receipt_id` bigint UNSIGNED NOT NULL,
  `sales_invoice_id` bigint UNSIGNED DEFAULT NULL,
  `allocated_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `allocation_type` enum('against_invoice','advance','on_account','adjustment') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'against_invoice',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `sales_receipt_allocations`
--

INSERT INTO `sales_receipt_allocations` (`id`, `sales_receipt_id`, `sales_invoice_id`, `allocated_amount`, `allocation_type`, `remarks`, `created_at`) VALUES
(36, 21, 29, 25193.00, 'against_invoice', 'Against SI/26-27/0001', '2026-06-19 12:43:48'),
(37, 22, 30, 1463.00, 'against_invoice', 'Against SI/26-27/0002', '2026-06-20 05:04:17');

-- --------------------------------------------------------

--
-- Table structure for table `sales_returns`
--

CREATE TABLE `sales_returns` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `sales_invoice_id` bigint UNSIGNED DEFAULT NULL,
  `return_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `return_date` date NOT NULL,
  `customer_party_id` bigint UNSIGNED NOT NULL,
  `subtotal` decimal(18,2) NOT NULL DEFAULT '0.00',
  `discount_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `taxable_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `cgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `sgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `igst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `cess_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `round_off_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `adjustment_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `adjustment_account_id` bigint UNSIGNED DEFAULT NULL,
  `adjustment_remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `total_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `return_reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `return_status` enum('draft','posted','credited','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `posted_by` bigint UNSIGNED DEFAULT NULL,
  `posted_at` datetime DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sales_return_lines`
--

CREATE TABLE `sales_return_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `sales_return_id` bigint UNSIGNED NOT NULL,
  `sales_invoice_line_id` bigint UNSIGNED DEFAULT NULL,
  `line_no` int NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED NOT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `batch_id` bigint UNSIGNED DEFAULT NULL,
  `serial_id` bigint UNSIGNED DEFAULT NULL,
  `return_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `rate` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `discount_percent` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `discount_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `gross_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `taxable_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `tax_code_id` bigint UNSIGNED DEFAULT NULL,
  `tax_percent` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `cgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `sgst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `igst_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `cess_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `line_total` decimal(18,2) NOT NULL DEFAULT '0.00',
  `return_reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `service_contracts`
--

CREATE TABLE `service_contracts` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `contract_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `contract_date` date NOT NULL,
  `customer_party_id` bigint UNSIGNED NOT NULL,
  `contract_type` enum('warranty','amc','cmc','installation_support','paid_support','extended_warranty','other') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'warranty',
  `contract_start_date` date NOT NULL,
  `contract_end_date` date DEFAULT NULL,
  `coverage_scope` enum('labor_only','parts_only','labor_and_parts','inspection_only','installation_only','custom') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'labor_only',
  `visit_frequency` enum('one_time','monthly','quarterly','half_yearly','yearly','on_call','custom') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'on_call',
  `response_time_hours` decimal(18,2) DEFAULT NULL,
  `resolution_time_hours` decimal(18,2) DEFAULT NULL,
  `contract_value` decimal(18,2) NOT NULL DEFAULT '0.00',
  `tax_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `total_value` decimal(18,2) NOT NULL DEFAULT '0.00',
  `sales_invoice_id` bigint UNSIGNED DEFAULT NULL,
  `contract_status` enum('draft','active','expired','terminated','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `approved_by` bigint UNSIGNED DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `service_contract_assets`
--

CREATE TABLE `service_contract_assets` (
  `id` bigint UNSIGNED NOT NULL,
  `service_contract_id` bigint UNSIGNED NOT NULL,
  `asset_id` bigint UNSIGNED DEFAULT NULL,
  `item_id` bigint UNSIGNED DEFAULT NULL,
  `serial_id` bigint UNSIGNED DEFAULT NULL,
  `serial_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `installation_date` date DEFAULT NULL,
  `warranty_start_date` date DEFAULT NULL,
  `warranty_end_date` date DEFAULT NULL,
  `customer_site_address` text COLLATE utf8mb4_unicode_ci,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `service_feedbacks`
--

CREATE TABLE `service_feedbacks` (
  `id` bigint UNSIGNED NOT NULL,
  `service_ticket_id` bigint UNSIGNED NOT NULL,
  `service_work_order_id` bigint UNSIGNED DEFAULT NULL,
  `feedback_date` date NOT NULL,
  `rating_overall` int DEFAULT NULL,
  `rating_technician` int DEFAULT NULL,
  `rating_resolution` int DEFAULT NULL,
  `rating_timeliness` int DEFAULT NULL,
  `customer_feedback` text COLLATE utf8mb4_unicode_ci,
  `resolution_confirmed` tinyint(1) NOT NULL DEFAULT '0',
  `revisit_required` tinyint(1) NOT NULL DEFAULT '0',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `service_tickets`
--

CREATE TABLE `service_tickets` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED DEFAULT NULL,
  `location_id` bigint UNSIGNED DEFAULT NULL,
  `financial_year_id` bigint UNSIGNED DEFAULT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `ticket_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ticket_date` date NOT NULL,
  `customer_party_id` bigint UNSIGNED NOT NULL,
  `contact_person_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `contact_mobile` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `contact_email` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `service_contract_id` bigint UNSIGNED DEFAULT NULL,
  `service_contract_asset_id` bigint UNSIGNED DEFAULT NULL,
  `asset_id` bigint UNSIGNED DEFAULT NULL,
  `item_id` bigint UNSIGNED DEFAULT NULL,
  `serial_id` bigint UNSIGNED DEFAULT NULL,
  `serial_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ticket_type` enum('complaint','installation','demo','preventive_service','breakdown','warranty_claim','amc_visit','paid_service','other') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'complaint',
  `priority_level` enum('low','normal','high','critical') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'normal',
  `issue_title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `issue_description` text COLLATE utf8mb4_unicode_ci,
  `ticket_source` enum('manual','phone','email','website','whatsapp','sales_team','system_generated') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'manual',
  `service_mode` enum('onsite','remote','pickup','workshop','hybrid') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'onsite',
  `coverage_type` enum('under_warranty','under_amc','chargeable','free_service','to_be_decided') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'to_be_decided',
  `target_response_datetime` datetime DEFAULT NULL,
  `target_resolution_datetime` datetime DEFAULT NULL,
  `ticket_status` enum('draft','open','assigned','in_progress','waiting_customer','waiting_parts','waiting_internal','resolved','closed','cancelled','rejected') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `assigned_to_user_id` bigint UNSIGNED DEFAULT NULL,
  `customer_site_address` text COLLATE utf8mb4_unicode_ci,
  `closed_by` bigint UNSIGNED DEFAULT NULL,
  `closed_at` datetime DEFAULT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `service_ticket_activities`
--

CREATE TABLE `service_ticket_activities` (
  `id` bigint UNSIGNED NOT NULL,
  `service_ticket_id` bigint UNSIGNED NOT NULL,
  `activity_type` enum('status_update','customer_call','customer_visit','remote_support','internal_note','technician_note','part_request','approval_note','closure_note','other') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'status_update',
  `activity_datetime` datetime NOT NULL,
  `activity_notes` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `next_followup_datetime` datetime DEFAULT NULL,
  `visibility` enum('internal','customer_visible') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'internal',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `service_visit_logs`
--

CREATE TABLE `service_visit_logs` (
  `id` bigint UNSIGNED NOT NULL,
  `service_work_order_id` bigint UNSIGNED NOT NULL,
  `visit_date` date NOT NULL,
  `visit_type` enum('onsite','pickup','delivery','inspection','installation','remote_followup') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'onsite',
  `check_in_datetime` datetime DEFAULT NULL,
  `check_out_datetime` datetime DEFAULT NULL,
  `travel_distance_km` decimal(18,2) DEFAULT NULL,
  `travel_expense` decimal(18,2) NOT NULL DEFAULT '0.00',
  `visit_notes` text COLLATE utf8mb4_unicode_ci,
  `customer_signature_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `customer_confirmation_status` enum('pending','confirmed','disputed') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `service_work_orders`
--

CREATE TABLE `service_work_orders` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED DEFAULT NULL,
  `location_id` bigint UNSIGNED DEFAULT NULL,
  `financial_year_id` bigint UNSIGNED DEFAULT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `work_order_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `work_order_date` date NOT NULL,
  `service_ticket_id` bigint UNSIGNED NOT NULL,
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `customer_party_id` bigint UNSIGNED NOT NULL,
  `asset_id` bigint UNSIGNED DEFAULT NULL,
  `item_id` bigint UNSIGNED DEFAULT NULL,
  `serial_id` bigint UNSIGNED DEFAULT NULL,
  `serial_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `work_order_type` enum('installation','complaint_resolution','breakdown_service','warranty_service','amc_service','paid_service','inspection','demo','other') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'complaint_resolution',
  `execution_mode` enum('onsite','remote','pickup','workshop','hybrid') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'onsite',
  `technician_user_id` bigint UNSIGNED DEFAULT NULL,
  `vendor_party_id` bigint UNSIGNED DEFAULT NULL,
  `work_order_status` enum('draft','assigned','in_progress','waiting_parts','waiting_customer','completed','closed','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `diagnosis_notes` text COLLATE utf8mb4_unicode_ci,
  `action_taken` text COLLATE utf8mb4_unicode_ci,
  `resolution_summary` text COLLATE utf8mb4_unicode_ci,
  `customer_site_address` text COLLATE utf8mb4_unicode_ci,
  `check_in_datetime` datetime DEFAULT NULL,
  `check_out_datetime` datetime DEFAULT NULL,
  `labor_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `spare_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `external_service_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `travel_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `other_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `total_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `billable_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `completed_by` bigint UNSIGNED DEFAULT NULL,
  `completed_at` datetime DEFAULT NULL,
  `closed_by` bigint UNSIGNED DEFAULT NULL,
  `closed_at` datetime DEFAULT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `service_work_order_services`
--

CREATE TABLE `service_work_order_services` (
  `id` bigint UNSIGNED NOT NULL,
  `service_work_order_id` bigint UNSIGNED NOT NULL,
  `line_no` int NOT NULL,
  `service_description` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `charge_type` enum('labor','installation','inspection','travel','vendor_service','remote_support','other') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'labor',
  `vendor_party_id` bigint UNSIGNED DEFAULT NULL,
  `purchase_invoice_id` bigint UNSIGNED DEFAULT NULL,
  `qty` decimal(18,6) NOT NULL DEFAULT '1.000000',
  `rate` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `warranty_covered` tinyint(1) NOT NULL DEFAULT '0',
  `chargeable_to_customer` tinyint(1) NOT NULL DEFAULT '1',
  `tax_code_id` bigint UNSIGNED DEFAULT NULL,
  `tax_percent` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `tax_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `line_total` decimal(18,2) NOT NULL DEFAULT '0.00',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `service_work_order_spares`
--

CREATE TABLE `service_work_order_spares` (
  `id` bigint UNSIGNED NOT NULL,
  `service_work_order_id` bigint UNSIGNED NOT NULL,
  `line_no` int NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED DEFAULT NULL,
  `batch_id` bigint UNSIGNED DEFAULT NULL,
  `serial_id` bigint UNSIGNED DEFAULT NULL,
  `required_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `issued_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `consumed_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `returned_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `warranty_covered` tinyint(1) NOT NULL DEFAULT '0',
  `chargeable_to_customer` tinyint(1) NOT NULL DEFAULT '1',
  `unit_cost` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `total_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `billable_rate` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `billable_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `issue_document_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `issue_document_id` bigint UNSIGNED DEFAULT NULL,
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `states`
--

CREATE TABLE `states` (
  `id` bigint UNSIGNED NOT NULL,
  `country_code` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'IN',
  `state_code` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `state_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `gst_state_code` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_union_territory` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stock_adjustments`
--

CREATE TABLE `stock_adjustments` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `adjustment_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `adjustment_date` date NOT NULL,
  `adjustment_type` enum('increase','decrease','mixed') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'mixed',
  `reason_code` enum('manual_correction','system_correction','count_difference','warehouse_error','data_migration','other') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'manual_correction',
  `adjustment_status` enum('draft','posted','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `posted_by` bigint UNSIGNED DEFAULT NULL,
  `posted_at` datetime DEFAULT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stock_adjustment_lines`
--

CREATE TABLE `stock_adjustment_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `stock_adjustment_id` bigint UNSIGNED NOT NULL,
  `line_no` int NOT NULL,
  `warehouse_id` bigint UNSIGNED NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `batch_id` bigint UNSIGNED DEFAULT NULL,
  `serial_id` bigint UNSIGNED DEFAULT NULL,
  `system_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `actual_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `adjustment_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `unit_cost` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `total_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `adjustment_direction` enum('in','out') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'in',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stock_balances`
--

CREATE TABLE `stock_balances` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `batch_id` bigint UNSIGNED DEFAULT NULL,
  `serial_id` bigint UNSIGNED DEFAULT NULL,
  `qty_on_hand` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `qty_reserved` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `qty_available` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `avg_cost` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `last_purchase_rate` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `last_sales_rate` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `last_movement_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `updated_by` bigint UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `stock_balances`
--

INSERT INTO `stock_balances` (`id`, `company_id`, `branch_id`, `location_id`, `warehouse_id`, `item_id`, `batch_id`, `serial_id`, `qty_on_hand`, `qty_reserved`, `qty_available`, `avg_cost`, `last_purchase_rate`, `last_sales_rate`, `last_movement_at`, `created_at`, `updated_at`, `updated_by`) VALUES
(18, 1, 1, 1, 1, 3, NULL, NULL, 3.000000, 0.000000, 3.000000, 0.0000, 0.0000, 4745.7600, '2026-04-30 00:00:00', '2026-06-19 06:51:12', '2026-06-19 12:30:26', NULL),
(19, 1, 1, 1, 1, 6, NULL, NULL, 6.000000, 0.000000, 6.000000, 272.8000, 272.8000, 310.0000, '2026-04-02 00:00:00', '2026-06-19 09:28:41', '2026-06-19 09:30:05', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `stock_batches`
--

CREATE TABLE `stock_batches` (
  `id` bigint UNSIGNED NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED NOT NULL,
  `batch_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `mfg_date` date DEFAULT NULL,
  `manufacture_date` date DEFAULT NULL,
  `expiry_date` date DEFAULT NULL,
  `inward_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `outward_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `balance_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `qty_available` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `purchase_rate` decimal(18,4) DEFAULT NULL,
  `sales_rate` decimal(18,4) DEFAULT NULL,
  `mrp` decimal(18,4) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `status` enum('active','expired','blocked','consumed') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'active',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stock_damage_entries`
--

CREATE TABLE `stock_damage_entries` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `damage_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `damage_date` date NOT NULL,
  `warehouse_id` bigint UNSIGNED NOT NULL,
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `damage_type` enum('damage','expiry','breakage','spoilage','loss','other') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'damage',
  `damage_status` enum('draft','posted','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `posted_by` bigint UNSIGNED DEFAULT NULL,
  `posted_at` datetime DEFAULT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stock_damage_lines`
--

CREATE TABLE `stock_damage_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `stock_damage_entry_id` bigint UNSIGNED NOT NULL,
  `line_no` int NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `batch_id` bigint UNSIGNED DEFAULT NULL,
  `serial_id` bigint UNSIGNED DEFAULT NULL,
  `damage_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `unit_cost` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `total_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stock_issues`
--

CREATE TABLE `stock_issues` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `issue_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `issue_date` date NOT NULL,
  `warehouse_id` bigint UNSIGNED NOT NULL,
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `issue_purpose` enum('department_use','production','sample','maintenance','jobwork','other') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'department_use',
  `department_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `issued_to` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `issue_status` enum('draft','posted','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `posted_by` bigint UNSIGNED DEFAULT NULL,
  `posted_at` datetime DEFAULT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stock_issue_lines`
--

CREATE TABLE `stock_issue_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `stock_issue_id` bigint UNSIGNED NOT NULL,
  `line_no` int NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `batch_id` bigint UNSIGNED DEFAULT NULL,
  `serial_id` bigint UNSIGNED DEFAULT NULL,
  `issue_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `unit_cost` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `total_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stock_movements`
--

CREATE TABLE `stock_movements` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `movement_date` datetime NOT NULL,
  `movement_type` enum('opening','purchase_receipt','purchase_return','sales_delivery','sales_return','stock_transfer_in','stock_transfer_out','stock_adjustment_in','stock_adjustment_out','production_issue','production_receipt','jobwork_issue','jobwork_receipt','damage','expiry','sample_issue','sample_receipt','internal_issue','internal_receipt') COLLATE utf8mb4_unicode_ci NOT NULL,
  `reference_module` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reference_table` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reference_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reference_line_id` bigint DEFAULT NULL,
  `reference_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `batch_id` bigint UNSIGNED DEFAULT NULL,
  `serial_id` bigint UNSIGNED DEFAULT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `qty_in` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `qty_out` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `unit_cost` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `total_cost` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `rate` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `amount` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `line_narration` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `posted_by` bigint UNSIGNED DEFAULT NULL,
  `posted_at` datetime DEFAULT NULL,
  `is_cancelled` tinyint(1) NOT NULL DEFAULT '0',
  `cancelled_by` bigint UNSIGNED DEFAULT NULL,
  `cancelled_at` datetime DEFAULT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `stock_movements`
--

INSERT INTO `stock_movements` (`id`, `company_id`, `branch_id`, `location_id`, `warehouse_id`, `financial_year_id`, `item_id`, `movement_date`, `movement_type`, `reference_module`, `reference_table`, `reference_id`, `reference_line_id`, `reference_no`, `batch_id`, `serial_id`, `uom_id`, `qty_in`, `qty_out`, `unit_cost`, `total_cost`, `rate`, `amount`, `line_narration`, `posted_by`, `posted_at`, `is_cancelled`, `cancelled_by`, `cancelled_at`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(69, 1, 1, 1, 1, 1, 3, '2026-06-19 00:00:00', 'opening', 'inventory', 'stock_opening', '17', 30, 'OPN/26-27/0001', NULL, NULL, 1, 60.000000, 0.000000, 0.0000, 0.0000, 0.0000, 0.0000, NULL, 4, '2026-06-19 06:51:12', 0, NULL, NULL, 4, 4, '2026-06-19 06:51:12', '2026-06-19 06:51:12'),
(70, 1, 1, 1, 1, 1, 3, '2026-06-19 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '29', 47, NULL, NULL, NULL, 1, 0.000000, 5.000000, 4200.0000, 21000.0000, 4200.0000, 21000.0000, NULL, 4, '2026-06-19 06:53:39', 0, NULL, NULL, 4, 4, '2026-06-19 06:53:39', '2026-06-19 06:53:39'),
(71, 1, 1, 1, 1, 1, 6, '2026-06-19 00:00:00', 'opening', 'inventory', 'stock_opening', '18', 31, 'OPN/26-27/0002', NULL, NULL, 5, 10.000000, 0.000000, 272.8000, 2728.0000, 272.8000, 2728.0000, NULL, 4, '2026-06-19 09:28:41', 0, NULL, NULL, 4, 4, '2026-06-19 09:28:41', '2026-06-19 09:28:41'),
(72, 1, 1, 1, 1, 1, 6, '2026-04-02 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '30', 49, NULL, NULL, NULL, 5, 0.000000, 4.000000, 310.0000, 1240.0000, 310.0000, 1240.0000, NULL, 4, '2026-06-19 09:30:05', 0, NULL, NULL, 4, 4, '2026-06-19 09:30:05', '2026-06-19 09:30:05'),
(73, 1, 1, 1, 1, 1, 3, '2026-04-02 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '31', 51, NULL, NULL, NULL, 1, 0.000000, 10.000000, 4771.1900, 47711.9000, 4771.1900, 47711.9000, NULL, 4, '2026-06-19 09:34:59', 0, NULL, NULL, 4, 4, '2026-06-19 09:34:59', '2026-06-19 09:34:59'),
(74, 1, 1, 1, 1, 1, 3, '2026-04-03 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '32', 52, NULL, NULL, NULL, 1, 0.000000, 1.000000, 4237.2900, 4237.2900, 4237.2900, 4237.2900, NULL, 4, '2026-06-19 09:38:01', 0, NULL, NULL, 4, 4, '2026-06-19 09:38:01', '2026-06-19 09:38:01'),
(75, 1, 1, 1, 1, 1, 3, '2026-04-03 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '33', 53, NULL, NULL, NULL, 1, 0.000000, 1.000000, 4508.4700, 4508.4700, 4508.4700, 4508.4700, NULL, 4, '2026-06-19 09:44:02', 0, NULL, NULL, 4, 4, '2026-06-19 09:44:02', '2026-06-19 09:44:02'),
(76, 1, 1, 1, 1, 1, 3, '2026-04-04 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '34', 55, NULL, NULL, NULL, 1, 0.000000, 1.000000, 4406.7800, 4406.7800, 4406.7800, 4406.7800, NULL, 4, '2026-06-19 09:54:03', 0, NULL, NULL, 4, 4, '2026-06-19 09:54:03', '2026-06-19 09:54:03'),
(77, 1, 1, 1, 1, 1, 3, '2026-04-06 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '35', 58, NULL, NULL, NULL, 1, 0.000000, 2.000000, 4406.7800, 8813.5600, 4406.7800, 8813.5600, NULL, 4, '2026-06-19 10:00:44', 0, NULL, NULL, 4, 4, '2026-06-19 10:00:44', '2026-06-19 10:00:44'),
(78, 1, 1, 1, 1, 1, 3, '2026-04-06 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '36', 59, NULL, NULL, NULL, 1, 0.000000, 1.000000, 4508.4700, 4508.4700, 4508.4700, 4508.4700, NULL, 4, '2026-06-19 10:28:29', 0, NULL, NULL, 4, 4, '2026-06-19 10:28:29', '2026-06-19 10:28:29'),
(79, 1, 1, 1, 1, 1, 3, '2026-04-06 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '37', 60, NULL, NULL, NULL, 1, 0.000000, 1.000000, 4237.2900, 4237.2900, 4237.2900, 4237.2900, NULL, 4, '2026-06-19 10:30:51', 0, NULL, NULL, 4, 4, '2026-06-19 10:30:51', '2026-06-19 10:30:51'),
(80, 1, 1, 1, 1, 1, 3, '2026-04-07 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '38', 61, NULL, NULL, NULL, 1, 0.000000, 1.000000, 4830.5100, 4830.5100, 4830.5100, 4830.5100, NULL, 4, '2026-06-19 10:32:55', 0, NULL, NULL, 4, 4, '2026-06-19 10:32:55', '2026-06-19 10:32:55'),
(81, 1, 1, 1, 1, 1, 3, '2026-04-08 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '39', 63, NULL, NULL, NULL, 1, 0.000000, 5.000000, 4900.0000, 24500.0000, 4900.0000, 24500.0000, NULL, 4, '2026-06-19 10:47:22', 0, NULL, NULL, 4, 4, '2026-06-19 10:47:22', '2026-06-19 10:47:22'),
(82, 1, 1, 1, 1, 1, 3, '2026-04-08 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '40', 65, NULL, NULL, NULL, 1, 0.000000, 1.000000, 4830.5100, 4830.5100, 4830.5100, 4830.5100, NULL, 4, '2026-06-19 10:55:49', 0, NULL, NULL, 4, 4, '2026-06-19 10:55:49', '2026-06-19 10:55:49'),
(83, 1, 1, 1, 1, 1, 3, '2026-04-10 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '41', 67, NULL, NULL, NULL, 1, 0.000000, 1.000000, 4830.5100, 4830.5100, 4830.5100, 4830.5100, NULL, 4, '2026-06-19 10:59:38', 0, NULL, NULL, 4, 4, '2026-06-19 10:59:38', '2026-06-19 10:59:38'),
(84, 1, 1, 1, 1, 1, 3, '2026-04-11 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '42', 69, NULL, NULL, NULL, 1, 0.000000, 1.000000, 4830.5100, 4830.5100, 4830.5100, 4830.5100, NULL, 4, '2026-06-19 11:19:14', 0, NULL, NULL, 4, 4, '2026-06-19 11:19:14', '2026-06-19 11:19:14'),
(85, 1, 1, 1, 1, 1, 3, '2026-04-13 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '43', 70, NULL, NULL, NULL, 1, 0.000000, 1.000000, 4745.7600, 4745.7600, 4745.7600, 4745.7600, NULL, 4, '2026-06-19 11:20:56', 0, NULL, NULL, 4, 4, '2026-06-19 11:20:56', '2026-06-19 11:20:56'),
(86, 1, 1, 1, 1, 1, 3, '2026-04-15 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '44', 71, NULL, NULL, NULL, 1, 0.000000, 5.000000, 4900.0000, 24500.0000, 4900.0000, 24500.0000, NULL, 4, '2026-06-19 11:24:35', 0, NULL, NULL, 4, 4, '2026-06-19 11:24:35', '2026-06-19 11:24:35'),
(87, 1, 1, 1, 1, 1, 3, '2026-04-16 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '45', 73, NULL, NULL, NULL, 1, 0.000000, 2.000000, 4830.5100, 9661.0200, 4830.5100, 9661.0200, NULL, 4, '2026-06-19 11:26:16', 0, NULL, NULL, 4, 4, '2026-06-19 11:26:16', '2026-06-19 11:26:16'),
(88, 1, 1, 1, 1, 1, 3, '2026-04-17 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '46', 74, NULL, NULL, NULL, 1, 0.000000, 1.000000, 4830.5100, 4830.5100, 4830.5100, 4830.5100, NULL, 4, '2026-06-19 11:29:17', 0, NULL, NULL, 4, 4, '2026-06-19 11:29:17', '2026-06-19 11:29:17'),
(89, 1, 1, 1, 1, 1, 3, '2026-04-17 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '47', 75, NULL, NULL, NULL, 1, 0.000000, 1.000000, 5318.6400, 5318.6400, 5318.6400, 5318.6400, NULL, 4, '2026-06-19 11:32:01', 0, NULL, NULL, 4, 4, '2026-06-19 11:32:01', '2026-06-19 11:32:01'),
(90, 1, 1, 1, 1, 1, 3, '2026-04-17 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '48', 76, NULL, NULL, NULL, 1, 0.000000, 1.000000, 4830.5100, 4830.5100, 4830.5100, 4830.5100, NULL, 4, '2026-06-19 11:34:10', 0, NULL, NULL, 4, 4, '2026-06-19 11:34:10', '2026-06-19 11:34:10'),
(91, 1, 1, 1, 1, 1, 3, '2026-04-20 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '49', 80, NULL, NULL, NULL, 1, 0.000000, 1.000000, 4830.5100, 4830.5100, 4830.5100, 4830.5100, NULL, 4, '2026-06-19 11:40:27', 0, NULL, NULL, 4, 4, '2026-06-19 11:40:27', '2026-06-19 11:40:27'),
(92, 1, 1, 1, 1, 1, 3, '2026-04-21 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '50', 82, NULL, NULL, NULL, 1, 0.000000, 1.000000, 4830.5100, 4830.5100, 4830.5100, 4830.5100, NULL, 4, '2026-06-19 11:47:14', 0, NULL, NULL, 4, 4, '2026-06-19 11:47:14', '2026-06-19 11:47:14'),
(93, 1, 1, 1, 1, 1, 3, '2026-04-28 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '51', 84, NULL, NULL, NULL, 1, 0.000000, 1.000000, 4491.5300, 4491.5300, 4491.5300, 4491.5300, NULL, 4, '2026-06-19 11:50:25', 0, NULL, NULL, 4, 4, '2026-06-19 11:50:25', '2026-06-19 11:50:25'),
(94, 1, 1, 1, 1, 1, 3, '2026-04-28 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '52', 85, NULL, NULL, NULL, 1, 0.000000, 5.000000, 2400.0000, 12000.0000, 2400.0000, 12000.0000, NULL, 4, '2026-06-19 12:05:09', 0, NULL, NULL, 4, 4, '2026-06-19 12:05:09', '2026-06-19 12:05:09'),
(95, 1, 1, 1, 1, 1, 3, '2026-04-28 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '53', 86, NULL, NULL, NULL, 1, 0.000000, 5.000000, 4900.0000, 24500.0000, 4900.0000, 24500.0000, NULL, 4, '2026-06-19 12:07:15', 0, NULL, NULL, 4, 4, '2026-06-19 12:07:15', '2026-06-19 12:07:15'),
(96, 1, 1, 1, 1, 1, 3, '2026-04-29 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '54', 88, NULL, NULL, NULL, 1, 0.000000, 1.000000, 4830.5100, 4830.5100, 4830.5100, 4830.5100, NULL, 4, '2026-06-19 12:28:45', 0, NULL, NULL, 4, 4, '2026-06-19 12:28:45', '2026-06-19 12:28:45'),
(97, 1, 1, 1, 1, 1, 3, '2026-04-30 00:00:00', 'sales_delivery', 'inventory', 'sales_invoice', '55', 90, NULL, NULL, NULL, 1, 0.000000, 1.000000, 4745.7600, 4745.7600, 4745.7600, 4745.7600, NULL, 4, '2026-06-19 12:30:26', 0, NULL, NULL, 4, 4, '2026-06-19 12:30:26', '2026-06-19 12:30:26');

-- --------------------------------------------------------

--
-- Table structure for table `stock_openings`
--

CREATE TABLE `stock_openings` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `opening_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `opening_date` date NOT NULL,
  `opening_status` enum('draft','posted','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `posted_by` bigint UNSIGNED DEFAULT NULL,
  `posted_at` datetime DEFAULT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `stock_openings`
--

INSERT INTO `stock_openings` (`id`, `company_id`, `branch_id`, `location_id`, `financial_year_id`, `document_series_id`, `voucher_id`, `opening_no`, `opening_date`, `opening_status`, `remarks`, `posted_by`, `posted_at`, `created_by`, `updated_by`, `is_active`, `created_at`, `updated_at`) VALUES
(17, 1, 1, 1, 1, 14, NULL, 'OPN/26-27/0001', '2026-06-19', 'posted', NULL, 4, '2026-06-19 06:51:12', 4, 4, 1, '2026-06-19 06:50:00', '2026-06-19 06:51:12'),
(18, 1, 1, 1, 1, 14, 88, 'OPN/26-27/0002', '2026-06-19', 'posted', NULL, 4, '2026-06-19 09:28:41', 4, 4, 1, '2026-06-19 09:28:39', '2026-06-19 09:28:41');

-- --------------------------------------------------------

--
-- Table structure for table `stock_opening_lines`
--

CREATE TABLE `stock_opening_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `stock_opening_id` bigint UNSIGNED NOT NULL,
  `line_no` int NOT NULL,
  `warehouse_id` bigint UNSIGNED NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `batch_id` bigint UNSIGNED DEFAULT NULL,
  `serial_id` bigint UNSIGNED DEFAULT NULL,
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `unit_cost` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `total_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `stock_opening_lines`
--

INSERT INTO `stock_opening_lines` (`id`, `stock_opening_id`, `line_no`, `warehouse_id`, `item_id`, `uom_id`, `batch_id`, `serial_id`, `voucher_id`, `qty`, `unit_cost`, `total_cost`, `remarks`, `created_at`) VALUES
(30, 17, 1, 1, 3, 1, NULL, NULL, NULL, 60.000000, 0.0000, 0.00, NULL, '2026-06-19 06:51:11'),
(31, 18, 1, 1, 6, 5, NULL, NULL, NULL, 10.000000, 272.8000, 2728.00, NULL, '2026-06-19 09:28:39');

-- --------------------------------------------------------

--
-- Table structure for table `stock_physical_counts`
--

CREATE TABLE `stock_physical_counts` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `count_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `count_date` date NOT NULL,
  `warehouse_id` bigint UNSIGNED NOT NULL,
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `count_scope` enum('full_warehouse','selected_items','category','batch','serial') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'selected_items',
  `count_status` enum('draft','counted','reconciled','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `counted_by` bigint UNSIGNED DEFAULT NULL,
  `counted_at` datetime DEFAULT NULL,
  `reconciled_by` bigint UNSIGNED DEFAULT NULL,
  `reconciled_at` datetime DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stock_physical_count_lines`
--

CREATE TABLE `stock_physical_count_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `stock_physical_count_id` bigint UNSIGNED NOT NULL,
  `line_no` int NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `batch_id` bigint UNSIGNED DEFAULT NULL,
  `serial_id` bigint UNSIGNED DEFAULT NULL,
  `system_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `counted_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `variance_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `unit_cost` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `variance_value` decimal(18,2) NOT NULL DEFAULT '0.00',
  `variance_type` enum('excess','shortage','matched') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'matched',
  `is_reconciled` tinyint(1) NOT NULL DEFAULT '0',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stock_receipts_internal`
--

CREATE TABLE `stock_receipts_internal` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `receipt_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `receipt_date` date NOT NULL,
  `warehouse_id` bigint UNSIGNED NOT NULL,
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `receipt_source` enum('department_return','sample_return','jobwork_return','production_return','other') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'department_return',
  `received_from` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `receipt_status` enum('draft','posted','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `posted_by` bigint UNSIGNED DEFAULT NULL,
  `posted_at` datetime DEFAULT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stock_receipt_internal_lines`
--

CREATE TABLE `stock_receipt_internal_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `stock_receipt_internal_id` bigint UNSIGNED NOT NULL,
  `line_no` int NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `batch_id` bigint UNSIGNED DEFAULT NULL,
  `serial_id` bigint UNSIGNED DEFAULT NULL,
  `receipt_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `unit_cost` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `total_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stock_reservations`
--

CREATE TABLE `stock_reservations` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED NOT NULL,
  `batch_id` bigint UNSIGNED DEFAULT NULL,
  `serial_id` bigint UNSIGNED DEFAULT NULL,
  `reference_type` varchar(100) NOT NULL,
  `reference_id` bigint UNSIGNED NOT NULL,
  `reference_line_id` bigint UNSIGNED DEFAULT NULL,
  `reserved_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `released_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `balance_reserved_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `status` varchar(30) NOT NULL DEFAULT 'active',
  `remarks` text,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stock_serials`
--

CREATE TABLE `stock_serials` (
  `id` bigint UNSIGNED NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED NOT NULL,
  `serial_no` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `batch_id` bigint UNSIGNED DEFAULT NULL,
  `status` enum('available','sold','issued','returned','damaged','blocked') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'available',
  `inward_date` date DEFAULT NULL,
  `outward_date` date DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stock_transfers`
--

CREATE TABLE `stock_transfers` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `transfer_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `transfer_date` date NOT NULL,
  `from_warehouse_id` bigint UNSIGNED NOT NULL,
  `to_warehouse_id` bigint UNSIGNED NOT NULL,
  `voucher_id` bigint UNSIGNED DEFAULT NULL,
  `transfer_status` enum('draft','posted','received','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `posted_by` bigint UNSIGNED DEFAULT NULL,
  `posted_at` datetime DEFAULT NULL,
  `received_by` bigint UNSIGNED DEFAULT NULL,
  `received_at` datetime DEFAULT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stock_transfer_lines`
--

CREATE TABLE `stock_transfer_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `stock_transfer_id` bigint UNSIGNED NOT NULL,
  `line_no` int NOT NULL,
  `item_id` bigint UNSIGNED NOT NULL,
  `uom_id` bigint UNSIGNED NOT NULL,
  `from_batch_id` bigint UNSIGNED DEFAULT NULL,
  `to_batch_id` bigint UNSIGNED DEFAULT NULL,
  `from_serial_id` bigint UNSIGNED DEFAULT NULL,
  `to_serial_id` bigint UNSIGNED DEFAULT NULL,
  `transfer_qty` decimal(18,6) NOT NULL DEFAULT '0.000000',
  `unit_cost` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `total_cost` decimal(18,2) NOT NULL DEFAULT '0.00',
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tax_codes`
--

CREATE TABLE `tax_codes` (
  `id` bigint UNSIGNED NOT NULL,
  `tax_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tax_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tax_type` enum('gst','igst','cgst_sgst','cess','none') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'gst',
  `tax_rate` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `cess_rate` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `hsn_sac_code` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tax_codes`
--

INSERT INTO `tax_codes` (`id`, `tax_code`, `tax_name`, `tax_type`, `tax_rate`, `cess_rate`, `hsn_sac_code`, `is_active`, `remarks`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(1, 'GST0', 'GST 0%', 'gst', 0.0000, 0.0000, NULL, 1, NULL, NULL, NULL, '2026-05-05 05:31:43', '2026-05-05 05:31:43'),
(2, 'GST5', 'GST 5%', 'gst', 5.0000, 0.0000, NULL, 1, NULL, NULL, NULL, '2026-05-05 05:31:43', '2026-05-05 05:31:43'),
(3, 'GST12', 'GST 12%', 'gst', 12.0000, 0.0000, NULL, 1, NULL, NULL, NULL, '2026-05-05 05:31:43', '2026-05-05 05:31:43'),
(4, 'GST18', 'GST 18%', 'gst', 18.0000, 0.0000, NULL, 1, NULL, NULL, NULL, '2026-05-05 05:31:43', '2026-05-05 05:31:43'),
(5, 'GST28', 'GST 28%', 'gst', 28.0000, 0.0000, NULL, 1, NULL, NULL, NULL, '2026-05-05 05:31:43', '2026-05-05 05:31:43'),
(6, 'EXEMPT', 'GST Exempt', 'none', 0.0000, 0.0000, NULL, 1, NULL, NULL, NULL, '2026-05-05 05:31:43', '2026-05-05 05:31:43'),
(7, 'NONGST', 'Non GST', 'none', 0.0000, 0.0000, NULL, 1, NULL, NULL, NULL, '2026-05-05 05:31:43', '2026-05-05 05:31:43');

-- --------------------------------------------------------

--
-- Table structure for table `uoms`
--

CREATE TABLE `uoms` (
  `id` bigint UNSIGNED NOT NULL,
  `uom_code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `uom_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `symbol` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_fraction_allowed` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `uoms`
--

INSERT INTO `uoms` (`id`, `uom_code`, `uom_name`, `symbol`, `is_fraction_allowed`, `is_active`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(1, 'PCS', 'Pieces', 'PCS', 0, 1, NULL, NULL, '2026-05-05 05:31:43', '2026-05-05 05:31:43'),
(2, 'BOX', 'Box', 'BOX', 0, 1, NULL, NULL, '2026-05-05 05:31:43', '2026-05-05 05:31:43'),
(3, 'KG', 'Kilogram', 'KG', 1, 1, NULL, NULL, '2026-05-05 05:31:43', '2026-05-05 05:31:43'),
(4, 'GM', 'Gram', 'GM', 1, 1, NULL, NULL, '2026-05-05 05:31:43', '2026-05-05 05:31:43'),
(5, 'LTR', 'Litre', 'LTR', 1, 1, NULL, NULL, '2026-05-05 05:31:43', '2026-05-05 05:31:43'),
(6, 'NOS', 'Numbers', 'NOS', 0, 1, NULL, NULL, '2026-05-05 05:31:43', '2026-05-05 05:31:43'),
(7, 'MTR', 'Meter', 'MTR', 1, 1, NULL, NULL, '2026-05-05 05:31:43', '2026-05-05 05:31:43'),
(8, 'HRS', 'Hours', 'HRS', 1, 1, NULL, NULL, '2026-05-05 05:31:43', '2026-05-05 05:31:43');

-- --------------------------------------------------------

--
-- Table structure for table `uom_conversions`
--

CREATE TABLE `uom_conversions` (
  `id` bigint UNSIGNED NOT NULL,
  `from_uom_id` bigint UNSIGNED NOT NULL,
  `to_uom_id` bigint UNSIGNED NOT NULL,
  `conversion_factor` decimal(18,6) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint UNSIGNED NOT NULL,
  `employee_id` bigint UNSIGNED DEFAULT NULL,
  `employee_code` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `username` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `first_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `display_name` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mobile` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `gender` enum('male','female','other','prefer_not_to_say') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `date_of_birth` date DEFAULT NULL,
  `profile_photo_path` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_super_admin` tinyint(1) NOT NULL DEFAULT '0',
  `is_system_user` tinyint(1) NOT NULL DEFAULT '1',
  `must_change_password` tinyint(1) NOT NULL DEFAULT '0',
  `last_login_at` datetime DEFAULT NULL,
  `last_password_changed_at` datetime DEFAULT NULL,
  `failed_login_attempts` int NOT NULL DEFAULT '0',
  `locked_until` datetime DEFAULT NULL,
  `status` enum('active','inactive','suspended','blocked') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'active',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `employee_id`, `employee_code`, `username`, `password_hash`, `first_name`, `last_name`, `display_name`, `email`, `mobile`, `gender`, `date_of_birth`, `profile_photo_path`, `is_super_admin`, `is_system_user`, `must_change_password`, `last_login_at`, `last_password_changed_at`, `failed_login_attempts`, `locked_until`, `status`, `remarks`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(2, NULL, 'ADMIN001', 'admin', '$2y$12$.8YJ3wissNj037uAmyLq7.fCsV2mCF9ffxzdWnAU.55CeuigZtCxa', 'System', 'Admin', 'System Admin', 'admin@example.com', '9876543210', NULL, NULL, NULL, 1, 1, 0, '2026-06-19 04:44:31', NULL, 0, NULL, 'active', NULL, NULL, NULL, '2026-05-06 03:03:37', '2026-06-19 04:44:31'),
(4, NULL, 'EMP/00001', 'pavithra', '$2y$12$cP5giQIbciKWNAKfgnhGn.MeARdlY6Vbrwa7olGQyup/bC0Zyhi7W', 'pavithra', NULL, 'pavithra', NULL, NULL, NULL, NULL, NULL, 1, 1, 1, '2026-06-20 04:40:42', NULL, 0, NULL, 'active', NULL, 2, NULL, '2026-05-07 03:25:30', '2026-06-20 04:40:42'),
(5, NULL, 'EMP/00002', 'Gokul', '$2y$12$z./NSSMGceaB8GHbUy/MJeBoFH.czm5hlxfnMYQPBFC9zLOT87o9a', 'Gokul', NULL, 'Gokul', 'gokulm@sakthicontroller.com', NULL, NULL, NULL, NULL, 1, 1, 1, '2026-06-01 09:23:18', NULL, 0, NULL, 'active', NULL, 2, 2, '2026-05-07 06:44:32', '2026-06-01 03:53:18'),
(6, NULL, 'EMP/00016', 'Yuvaraj', '$2y$12$VLXDqia8aOy5wkPxSrMyVO8xvavqpF.qwm82L3IHp3dKt45WemFLm', 'Yuvaraj', 'Palani', 'Yuvaraj Palani', 'yuvaraj@sakthicontroller.com', '7904284246', 'male', NULL, NULL, 0, 1, 1, '2026-06-01 09:49:23', NULL, 0, NULL, 'active', NULL, 2, 2, '2026-05-09 01:52:07', '2026-06-01 05:35:50');

-- --------------------------------------------------------

--
-- Table structure for table `user_branch_access`
--

CREATE TABLE `user_branch_access` (
  `id` bigint UNSIGNED NOT NULL,
  `user_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_company_access`
--

CREATE TABLE `user_company_access` (
  `id` bigint UNSIGNED NOT NULL,
  `user_id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_location_access`
--

CREATE TABLE `user_location_access` (
  `id` bigint UNSIGNED NOT NULL,
  `user_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT '0',
  `can_bill` tinyint(1) NOT NULL DEFAULT '1',
  `can_purchase` tinyint(1) NOT NULL DEFAULT '1',
  `can_stock_entry` tinyint(1) NOT NULL DEFAULT '1',
  `can_accounts_entry` tinyint(1) NOT NULL DEFAULT '1',
  `can_hr_entry` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_module_preferences`
--

CREATE TABLE `user_module_preferences` (
  `id` bigint UNSIGNED NOT NULL,
  `user_id` bigint UNSIGNED NOT NULL,
  `module_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `sort_order` int NOT NULL DEFAULT '0',
  `is_hidden` tinyint(1) NOT NULL DEFAULT '0',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_permissions`
--

CREATE TABLE `user_permissions` (
  `id` bigint UNSIGNED NOT NULL,
  `user_id` bigint UNSIGNED NOT NULL,
  `permission_id` bigint UNSIGNED NOT NULL,
  `allow_view` tinyint(1) NOT NULL DEFAULT '0',
  `allow_create` tinyint(1) NOT NULL DEFAULT '0',
  `allow_update` tinyint(1) NOT NULL DEFAULT '0',
  `allow_delete` tinyint(1) NOT NULL DEFAULT '0',
  `allow_approve` tinyint(1) NOT NULL DEFAULT '0',
  `allow_print` tinyint(1) NOT NULL DEFAULT '0',
  `allow_export` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_roles`
--

CREATE TABLE `user_roles` (
  `id` bigint UNSIGNED NOT NULL,
  `user_id` bigint UNSIGNED NOT NULL,
  `role_id` bigint UNSIGNED NOT NULL,
  `is_primary_role` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `assigned_by` bigint UNSIGNED DEFAULT NULL,
  `assigned_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_warehouse_access`
--

CREATE TABLE `user_warehouse_access` (
  `id` bigint UNSIGNED NOT NULL,
  `user_id` bigint UNSIGNED NOT NULL,
  `warehouse_id` bigint UNSIGNED NOT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT '0',
  `can_view_stock` tinyint(1) NOT NULL DEFAULT '1',
  `can_stock_in` tinyint(1) NOT NULL DEFAULT '1',
  `can_stock_out` tinyint(1) NOT NULL DEFAULT '1',
  `can_transfer` tinyint(1) NOT NULL DEFAULT '1',
  `can_adjust` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `vouchers`
--

CREATE TABLE `vouchers` (
  `id` bigint UNSIGNED NOT NULL,
  `company_id` bigint UNSIGNED NOT NULL,
  `branch_id` bigint UNSIGNED NOT NULL,
  `location_id` bigint UNSIGNED NOT NULL,
  `financial_year_id` bigint UNSIGNED NOT NULL,
  `voucher_type_id` bigint UNSIGNED NOT NULL,
  `document_series_id` bigint UNSIGNED DEFAULT NULL,
  `voucher_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `voucher_date` date NOT NULL,
  `reference_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reference_date` date DEFAULT NULL,
  `narration` text COLLATE utf8mb4_unicode_ci,
  `total_debit` decimal(18,2) NOT NULL DEFAULT '0.00',
  `total_credit` decimal(18,2) NOT NULL DEFAULT '0.00',
  `adjustment_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `adjustment_account_id` bigint UNSIGNED DEFAULT NULL,
  `adjustment_remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `source_module` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `source_table` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `source_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approval_status` enum('draft','pending','approved','rejected') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'approved',
  `posting_status` enum('draft','posted','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'posted',
  `approved_by` bigint UNSIGNED DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `posted_by` bigint UNSIGNED DEFAULT NULL,
  `posted_at` datetime DEFAULT NULL,
  `cancelled_by` bigint UNSIGNED DEFAULT NULL,
  `cancelled_at` datetime DEFAULT NULL,
  `cancel_reason` text COLLATE utf8mb4_unicode_ci,
  `is_system_generated` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `vouchers`
--

INSERT INTO `vouchers` (`id`, `company_id`, `branch_id`, `location_id`, `financial_year_id`, `voucher_type_id`, `document_series_id`, `voucher_no`, `voucher_date`, `reference_no`, `reference_date`, `narration`, `total_debit`, `total_credit`, `adjustment_amount`, `adjustment_account_id`, `adjustment_remarks`, `source_module`, `source_table`, `source_id`, `approval_status`, `posting_status`, `approved_by`, `approved_at`, `posted_by`, `posted_at`, `cancelled_by`, `cancelled_at`, `cancel_reason`, `is_system_generated`, `is_active`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(87, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0001', '2026-06-19', 'SI/26-27/0001', '2026-06-19', 'Sales Invoice #SI/26-27/0001', 25193.00, 25193.00, 0.00, NULL, NULL, 'sales', 'sales_invoices', '29', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 06:53:39', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 06:53:39', '2026-06-19 06:53:39'),
(88, 1, 1, 1, 1, 3, NULL, 'JV-OPEN-OPN/26-27/0002', '2026-06-19', 'OPN/26-27/0002', '2026-06-19', 'Opening stock posting #OPN/26-27/0002', 2728.00, 2728.00, 0.00, NULL, NULL, 'inventory', 'stock_openings', '18', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 09:28:41', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 09:28:41', '2026-06-19 09:28:41'),
(89, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0002', '2026-04-02', 'SI/26-27/0002', '2026-04-02', 'Sales Invoice #SI/26-27/0002', 1463.20, 1463.20, 0.00, NULL, NULL, 'sales', 'sales_invoices', '30', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 09:30:05', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 09:30:05', '2026-06-19 09:30:05'),
(90, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0003', '2026-04-02', 'SI/26-27/0003', '2026-04-02', 'Sales Invoice #SI/26-27/0003', 56300.04, 56300.04, 0.00, NULL, NULL, 'sales', 'sales_invoices', '31', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 09:34:59', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 09:34:59', '2026-06-19 09:34:59'),
(91, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0004', '2026-04-03', 'SI/26-27/0004', '2026-04-03', 'Sales Invoice #SI/26-27/0004', 5000.01, 5000.01, 0.00, NULL, NULL, 'sales', 'sales_invoices', '32', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 09:38:01', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 09:38:01', '2026-06-19 09:38:01'),
(92, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0005', '2026-04-03', 'SI/26-27/0005', '2026-04-03', 'Sales Invoice #SI/26-27/0005', 5320.00, 5320.00, 0.00, NULL, NULL, 'sales', 'sales_invoices', '33', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 09:44:02', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 09:44:02', '2026-06-19 09:44:02'),
(93, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0006', '2026-04-04', 'SI/26-27/0006', '2026-04-04', 'Sales Invoice #SI/26-27/0006', 5200.00, 5200.00, 0.00, NULL, NULL, 'sales', 'sales_invoices', '34', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 09:54:03', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 09:54:03', '2026-06-19 09:54:03'),
(94, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0007', '2026-04-06', 'SI/26-27/0007', '2026-04-06', 'Sales Invoice #SI/26-27/0007', 10400.00, 10400.00, 0.00, NULL, NULL, 'sales', 'sales_invoices', '35', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 10:00:44', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 10:00:44', '2026-06-19 10:00:44'),
(95, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0008', '2026-04-06', 'SI/26-27/0008', '2026-04-06', 'Sales Invoice #SI/26-27/0008', 5320.00, 5320.00, 0.00, NULL, NULL, 'sales', 'sales_invoices', '36', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 10:28:29', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 10:28:29', '2026-06-19 10:28:29'),
(96, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0009', '2026-04-06', 'SI/26-27/0009', '2026-04-06', 'Sales Invoice #SI/26-27/0009', 5000.01, 5000.01, 0.00, NULL, NULL, 'sales', 'sales_invoices', '37', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 10:30:51', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 10:30:51', '2026-06-19 10:30:51'),
(97, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0010', '2026-04-07', 'SI/26-27/0010', '2026-04-07', 'Sales Invoice #SI/26-27/0010', 5840.00, 5840.00, 0.00, NULL, NULL, 'sales', 'sales_invoices', '38', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 10:32:55', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 10:32:55', '2026-06-19 10:32:55'),
(98, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0011', '2026-04-08', 'SI/26-27/0011', '2026-04-08', 'Sales Invoice #SI/26-27/0011', 29610.00, 29610.00, 0.00, NULL, NULL, 'sales', 'sales_invoices', '39', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 10:47:22', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 10:47:22', '2026-06-19 10:47:22'),
(99, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0012', '2026-04-08', 'SI/26-27/0012', '2026-04-08', 'Sales Invoice #SI/26-27/0012', 5840.01, 5840.01, 0.00, NULL, NULL, 'sales', 'sales_invoices', '40', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 10:55:49', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 10:55:49', '2026-06-19 10:55:49'),
(100, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0013', '2026-04-10', 'SI/26-27/0013', '2026-04-10', 'Sales Invoice #SI/26-27/0013', 5840.01, 5840.01, 0.00, NULL, NULL, 'sales', 'sales_invoices', '41', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 10:59:38', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 10:59:38', '2026-06-19 10:59:38'),
(101, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0014', '2026-04-11', 'SI/26-27/0014', '2026-04-11', 'Sales Invoice #SI/26-27/0014', 5700.01, 5700.01, 0.00, NULL, NULL, 'sales', 'sales_invoices', '42', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 11:19:14', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 11:19:14', '2026-06-19 11:19:14'),
(102, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0015', '2026-04-13', 'SI/26-27/0015', '2026-04-13', 'Sales Invoice #SI/26-27/0015', 5600.00, 5600.00, 0.00, NULL, NULL, 'sales', 'sales_invoices', '43', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 11:20:56', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 11:20:56', '2026-06-19 11:20:56'),
(103, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0016', '2026-04-15', 'SI/26-27/0016', '2026-04-15', 'Sales Invoice #SI/26-27/0016', 29210.00, 29210.00, 0.00, NULL, NULL, 'sales', 'sales_invoices', '44', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 11:24:35', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 11:24:35', '2026-06-19 11:24:35'),
(104, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0017', '2026-04-16', 'SI/26-27/0017', '2026-04-16', 'Sales Invoice #SI/26-27/0017', 11400.00, 11400.00, 0.00, NULL, NULL, 'sales', 'sales_invoices', '45', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 11:26:16', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 11:26:16', '2026-06-19 11:26:16'),
(105, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0018', '2026-04-17', 'SI/26-27/0018', '2026-04-17', 'Sales Invoice #SI/26-27/0018', 5700.01, 5700.01, 0.00, NULL, NULL, 'sales', 'sales_invoices', '46', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 11:29:17', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 11:29:17', '2026-06-19 11:29:17'),
(106, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0019', '2026-04-17', 'SI/26-27/0019', '2026-04-17', 'Sales Invoice #SI/26-27/0019', 6276.00, 6276.00, 0.00, NULL, NULL, 'sales', 'sales_invoices', '47', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 11:32:01', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 11:32:01', '2026-06-19 11:32:01'),
(107, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0020', '2026-04-17', 'SI/26-27/0020', '2026-04-17', 'Sales Invoice #SI/26-27/0020', 5840.01, 5840.01, 0.00, NULL, NULL, 'sales', 'sales_invoices', '48', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 11:34:10', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 11:34:10', '2026-06-19 11:34:10'),
(108, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0021', '2026-04-20', 'SI/26-27/0021', '2026-04-20', 'Sales Invoice #SI/26-27/0021', 5840.01, 5840.01, 0.00, NULL, NULL, 'sales', 'sales_invoices', '49', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 11:40:27', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 11:40:27', '2026-06-19 11:40:27'),
(109, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0022', '2026-04-21', 'SI/26-27/0022', '2026-04-21', 'Sales Invoice #SI/26-27/0022', 5840.01, 5840.01, 0.00, NULL, NULL, 'sales', 'sales_invoices', '50', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 11:47:14', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 11:47:14', '2026-06-19 11:47:14'),
(110, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0023', '2026-04-28', 'SI/26-27/0023', '2026-04-28', 'Sales Invoice #SI/26-27/0023', 5300.01, 5300.01, 0.00, NULL, NULL, 'sales', 'sales_invoices', '51', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 11:50:25', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 11:50:25', '2026-06-19 11:50:25'),
(111, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0024', '2026-04-28', 'SI/26-27/0024', '2026-04-28', 'Sales Invoice #SI/26-27/0024', 14160.00, 14160.00, 0.00, NULL, NULL, 'sales', 'sales_invoices', '52', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 12:05:09', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 12:05:09', '2026-06-19 12:05:09'),
(112, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0025', '2026-04-28', 'SI/26-27/0025', '2026-04-28', 'Sales Invoice #SI/26-27/0025', 29210.00, 29210.00, 0.00, NULL, NULL, 'sales', 'sales_invoices', '53', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 12:07:15', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 12:07:15', '2026-06-19 12:07:15'),
(113, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0026', '2026-04-29', 'SI/26-27/0026', '2026-04-29', 'Sales Invoice #SI/26-27/0026', 5840.01, 5840.01, 0.00, NULL, NULL, 'sales', 'sales_invoices', '54', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 12:28:45', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 12:28:45', '2026-06-19 12:28:45'),
(114, 1, 1, 1, 1, 5, NULL, 'SV-SI/26-27/0027', '2026-04-30', 'SI/26-27/0027', '2026-04-30', 'Sales Invoice #SI/26-27/0027', 5600.00, 5600.00, 0.00, NULL, NULL, 'sales', 'sales_invoices', '55', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 12:30:26', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 12:30:26', '2026-06-19 12:30:26'),
(115, 1, 1, 1, 1, 2, NULL, 'RV-SR/26-27/0001', '2026-04-01', 'SR/26-27/0001', '2026-04-01', 'Customer Receipt #SR/26-27/0001', 25193.00, 25193.00, 0.00, NULL, NULL, 'sales', 'sales_receipts', '21', 'approved', 'posted', NULL, NULL, 4, '2026-06-19 12:43:55', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-19 12:43:55', '2026-06-19 12:43:55'),
(116, 1, 1, 1, 1, 2, NULL, 'RV-SR/26-27/0002', '2026-04-02', 'SR/26-27/0002', '2026-04-02', 'Customer Receipt #SR/26-27/0002', 1463.00, 1463.00, 0.00, NULL, NULL, 'sales', 'sales_receipts', '22', 'approved', 'posted', NULL, NULL, 4, '2026-06-20 05:04:25', NULL, NULL, NULL, 1, 1, 4, 4, '2026-06-20 05:04:25', '2026-06-20 05:04:25');

-- --------------------------------------------------------

--
-- Table structure for table `voucher_allocations`
--

CREATE TABLE `voucher_allocations` (
  `id` bigint UNSIGNED NOT NULL,
  `voucher_line_id` bigint UNSIGNED NOT NULL,
  `against_voucher_id` bigint UNSIGNED DEFAULT NULL,
  `against_voucher_line_id` bigint UNSIGNED DEFAULT NULL,
  `reference_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `reference_date` date DEFAULT NULL,
  `allocation_amount` decimal(18,2) NOT NULL,
  `allocation_type` enum('receipt','payment','adjustment','advance_setoff') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'adjustment',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `voucher_allocations`
--

INSERT INTO `voucher_allocations` (`id`, `voucher_line_id`, `against_voucher_id`, `against_voucher_line_id`, `reference_no`, `reference_date`, `allocation_amount`, `allocation_type`, `remarks`, `created_at`) VALUES
(31, 307, 87, 217, 'SI/26-27/0001', '2026-04-01', 25193.00, 'receipt', 'Against SI/26-27/0001', '2026-06-19 12:43:55'),
(32, 309, 89, 222, 'SI/26-27/0002', '2026-04-02', 1463.00, 'receipt', 'Against SI/26-27/0002', '2026-06-20 05:04:25');

-- --------------------------------------------------------

--
-- Table structure for table `voucher_lines`
--

CREATE TABLE `voucher_lines` (
  `id` bigint UNSIGNED NOT NULL,
  `voucher_id` bigint UNSIGNED NOT NULL,
  `line_no` int NOT NULL,
  `account_id` bigint UNSIGNED NOT NULL,
  `party_id` bigint UNSIGNED DEFAULT NULL,
  `entry_type` enum('debit','credit') COLLATE utf8mb4_unicode_ci NOT NULL,
  `amount` decimal(18,2) NOT NULL,
  `bill_reference_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bill_reference_date` date DEFAULT NULL,
  `bill_reference_type` enum('new_ref','against_ref','on_account','advance') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cheque_no` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cheque_date` date DEFAULT NULL,
  `bank_reference_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bank_reference_date` date DEFAULT NULL,
  `cost_center` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `department` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `project` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `line_narration` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `voucher_lines`
--

INSERT INTO `voucher_lines` (`id`, `voucher_id`, `line_no`, `account_id`, `party_id`, `entry_type`, `amount`, `bill_reference_no`, `bill_reference_date`, `bill_reference_type`, `cheque_no`, `cheque_date`, `bank_reference_no`, `bank_reference_date`, `cost_center`, `department`, `project`, `line_narration`, `created_at`) VALUES
(217, 87, 1, 3, 1, 'debit', 25193.00, 'SI/26-27/0001', '2026-06-19', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 06:53:39'),
(218, 87, 2, 5, NULL, 'credit', 21350.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 06:53:39'),
(219, 87, 3, 15, NULL, 'credit', 3843.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 06:53:39'),
(220, 88, 1, 18, NULL, 'debit', 2728.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Opening stock asset', '2026-06-19 09:28:41'),
(221, 88, 2, 35, NULL, 'credit', 2728.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Opening stock offset', '2026-06-19 09:28:41'),
(222, 89, 1, 3, 2, 'debit', 1463.00, 'SI/26-27/0002', '2026-04-02', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 09:30:05'),
(223, 89, 2, 5, NULL, 'credit', 1240.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 09:30:05'),
(224, 89, 3, 15, NULL, 'credit', 223.20, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 09:30:05'),
(225, 89, 4, 12, NULL, 'debit', 0.20, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Round off expense', '2026-06-19 09:30:05'),
(226, 90, 1, 3, 3, 'debit', 56300.00, 'SI/26-27/0003', '2026-04-02', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 09:34:59'),
(227, 90, 2, 5, NULL, 'credit', 47711.90, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 09:34:59'),
(228, 90, 3, 15, NULL, 'credit', 8588.14, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 09:34:59'),
(229, 90, 4, 12, NULL, 'debit', 0.04, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Round off expense', '2026-06-19 09:34:59'),
(230, 91, 1, 3, 4, 'debit', 5000.01, 'SI/26-27/0004', '2026-04-03', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 09:38:01'),
(231, 91, 2, 5, NULL, 'credit', 4237.29, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 09:38:01'),
(232, 91, 3, 15, NULL, 'credit', 762.72, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 09:38:01'),
(233, 92, 1, 3, 5, 'debit', 5320.00, 'SI/26-27/0005', '2026-04-03', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 09:44:02'),
(234, 92, 2, 5, NULL, 'credit', 4508.47, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 09:44:02'),
(235, 92, 3, 15, NULL, 'credit', 811.52, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 09:44:02'),
(236, 92, 4, 7, NULL, 'credit', 0.01, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Round off income', '2026-06-19 09:44:02'),
(237, 93, 1, 3, 6, 'debit', 5200.00, 'SI/26-27/0006', '2026-04-04', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 09:54:03'),
(238, 93, 2, 5, NULL, 'credit', 4406.78, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 09:54:03'),
(239, 93, 3, 15, NULL, 'credit', 793.22, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 09:54:03'),
(240, 94, 1, 3, 5, 'debit', 10400.00, 'SI/26-27/0007', '2026-04-06', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 10:00:44'),
(241, 94, 2, 5, NULL, 'credit', 8813.56, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 10:00:44'),
(242, 94, 3, 15, NULL, 'credit', 1586.44, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 10:00:44'),
(243, 95, 1, 3, 5, 'debit', 5320.00, 'SI/26-27/0008', '2026-04-06', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 10:28:29'),
(244, 95, 2, 5, NULL, 'credit', 4508.47, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 10:28:29'),
(245, 95, 3, 15, NULL, 'credit', 811.52, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 10:28:29'),
(246, 95, 4, 7, NULL, 'credit', 0.01, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Round off income', '2026-06-19 10:28:29'),
(247, 96, 1, 3, 4, 'debit', 5000.01, 'SI/26-27/0009', '2026-04-06', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 10:30:51'),
(248, 96, 2, 5, NULL, 'credit', 4237.29, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 10:30:51'),
(249, 96, 3, 15, NULL, 'credit', 762.72, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 10:30:51'),
(250, 97, 1, 3, 7, 'debit', 5840.00, 'SI/26-27/0010', '2026-04-07', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 10:32:55'),
(251, 97, 2, 5, NULL, 'credit', 4949.15, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 10:32:55'),
(252, 97, 3, 15, NULL, 'credit', 890.85, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 10:32:55'),
(253, 98, 1, 3, 8, 'debit', 29610.00, 'SI/26-27/0011', '2026-04-08', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 10:47:22'),
(254, 98, 2, 5, NULL, 'credit', 25093.20, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 10:47:22'),
(255, 98, 3, 15, NULL, 'credit', 4516.78, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 10:47:22'),
(256, 98, 4, 7, NULL, 'credit', 0.02, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Round off income', '2026-06-19 10:47:22'),
(257, 99, 1, 3, 9, 'debit', 5840.01, 'SI/26-27/0012', '2026-04-08', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 10:55:49'),
(258, 99, 2, 5, NULL, 'credit', 4949.15, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 10:55:49'),
(259, 99, 3, 15, NULL, 'credit', 890.86, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 10:55:49'),
(260, 100, 1, 3, 10, 'debit', 5840.01, 'SI/26-27/0013', '2026-04-10', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 10:59:38'),
(261, 100, 2, 5, NULL, 'credit', 4949.15, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 10:59:38'),
(262, 100, 3, 15, NULL, 'credit', 890.86, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 10:59:38'),
(263, 101, 1, 3, 11, 'debit', 5700.01, 'SI/26-27/0014', '2026-04-11', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 11:19:14'),
(264, 101, 2, 5, NULL, 'credit', 4830.51, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 11:19:14'),
(265, 101, 3, 15, NULL, 'credit', 869.50, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 11:19:14'),
(266, 102, 1, 3, 6, 'debit', 5600.00, 'SI/26-27/0015', '2026-04-13', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 11:20:56'),
(267, 102, 2, 5, NULL, 'credit', 4745.76, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 11:20:56'),
(268, 102, 3, 15, NULL, 'credit', 854.24, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 11:20:56'),
(269, 103, 1, 3, 12, 'debit', 29210.00, 'SI/26-27/0016', '2026-04-15', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 11:24:35'),
(270, 103, 2, 5, NULL, 'credit', 24754.24, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 11:24:35'),
(271, 103, 3, 15, NULL, 'credit', 4455.76, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 11:24:35'),
(272, 104, 1, 3, 4, 'debit', 11400.00, 'SI/26-27/0017', '2026-04-16', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 11:26:16'),
(273, 104, 2, 5, NULL, 'credit', 9661.02, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 11:26:16'),
(274, 104, 3, 15, NULL, 'credit', 1738.98, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 11:26:16'),
(275, 105, 1, 3, 13, 'debit', 5700.01, 'SI/26-27/0018', '2026-04-17', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 11:29:17'),
(276, 105, 2, 5, NULL, 'credit', 4830.51, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 11:29:17'),
(277, 105, 3, 15, NULL, 'credit', 869.50, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 11:29:17'),
(278, 106, 1, 3, 14, 'debit', 6276.00, 'SI/26-27/0019', '2026-04-17', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 11:32:01'),
(279, 106, 2, 5, NULL, 'credit', 5318.64, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 11:32:01'),
(280, 106, 3, 15, NULL, 'credit', 957.36, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 11:32:01'),
(281, 107, 1, 3, 6, 'debit', 5840.01, 'SI/26-27/0020', '2026-04-17', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 11:34:10'),
(282, 107, 2, 5, NULL, 'credit', 4949.15, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 11:34:10'),
(283, 107, 3, 15, NULL, 'credit', 890.86, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 11:34:10'),
(284, 108, 1, 3, 15, 'debit', 5840.01, 'SI/26-27/0021', '2026-04-20', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 11:40:27'),
(285, 108, 2, 5, NULL, 'credit', 4949.15, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 11:40:27'),
(286, 108, 3, 15, NULL, 'credit', 890.86, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 11:40:27'),
(287, 109, 1, 3, 13, 'debit', 5840.01, 'SI/26-27/0022', '2026-04-21', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 11:47:14'),
(288, 109, 2, 5, NULL, 'credit', 4949.15, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 11:47:14'),
(289, 109, 3, 15, NULL, 'credit', 890.86, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 11:47:14'),
(290, 110, 1, 3, 16, 'debit', 5300.00, 'SI/26-27/0023', '2026-04-28', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 11:50:25'),
(291, 110, 2, 5, NULL, 'credit', 4491.53, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 11:50:25'),
(292, 110, 3, 15, NULL, 'credit', 808.48, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 11:50:25'),
(293, 110, 4, 12, NULL, 'debit', 0.01, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Round off expense', '2026-06-19 11:50:25'),
(294, 111, 1, 3, 17, 'debit', 14160.00, 'SI/26-27/0024', '2026-04-28', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 12:05:09'),
(295, 111, 2, 5, NULL, 'credit', 12000.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 12:05:09'),
(296, 111, 3, 15, NULL, 'credit', 2160.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 12:05:09'),
(297, 112, 1, 3, 12, 'debit', 29210.00, 'SI/26-27/0025', '2026-04-28', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 12:07:15'),
(298, 112, 2, 5, NULL, 'credit', 24754.24, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 12:07:15'),
(299, 112, 3, 15, NULL, 'credit', 4455.76, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 12:07:15'),
(300, 113, 1, 3, 4, 'debit', 5840.01, 'SI/26-27/0026', '2026-04-29', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 12:28:45'),
(301, 113, 2, 5, NULL, 'credit', 4949.15, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 12:28:45'),
(302, 113, 3, 15, NULL, 'credit', 890.86, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 12:28:45'),
(303, 114, 1, 3, 18, 'debit', 5600.00, 'SI/26-27/0027', '2026-04-30', 'new_ref', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receivable', '2026-06-19 12:30:26'),
(304, 114, 2, 5, NULL, 'credit', 4745.76, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Sales income', '2026-06-19 12:30:26'),
(305, 114, 3, 15, NULL, 'credit', 854.24, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Output tax payable', '2026-06-19 12:30:26'),
(306, 115, 1, 74, NULL, 'debit', 25193.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receipt cash/bank debit', '2026-06-19 12:43:55'),
(307, 115, 2, 3, 1, 'credit', 25193.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receipt receivable credit', '2026-06-19 12:43:55'),
(308, 116, 1, 74, NULL, 'debit', 1463.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receipt cash/bank debit', '2026-06-20 05:04:25'),
(309, 116, 2, 3, 2, 'credit', 1463.00, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Customer receipt receivable credit', '2026-06-20 05:04:25');

-- --------------------------------------------------------

--
-- Table structure for table `voucher_types`
--

CREATE TABLE `voucher_types` (
  `id` bigint UNSIGNED NOT NULL,
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `voucher_category` enum('payment','receipt','journal','contra','sales','purchase','credit_note','debit_note','opening','adjustment') COLLATE utf8mb4_unicode_ci NOT NULL,
  `document_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `auto_post` tinyint(1) NOT NULL DEFAULT '1',
  `requires_approval` tinyint(1) NOT NULL DEFAULT '0',
  `allows_reference_allocation` tinyint(1) NOT NULL DEFAULT '1',
  `is_system_type` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `voucher_types`
--

INSERT INTO `voucher_types` (`id`, `code`, `name`, `voucher_category`, `document_type`, `auto_post`, `requires_approval`, `allows_reference_allocation`, `is_system_type`, `is_active`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(1, 'PAYMENT', 'Payment Voucher', 'payment', 'PAYMENT_VOUCHER', 1, 0, 1, 1, 1, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42'),
(2, 'RECEIPT', 'Receipt Voucher', 'receipt', 'RECEIPT_VOUCHER', 1, 0, 1, 1, 1, NULL, 2, '2026-05-05 05:31:42', '2026-05-19 12:25:05'),
(3, 'JOURNAL', 'Journal Voucher', 'journal', 'JOURNAL_VOUCHER', 1, 0, 1, 1, 1, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42'),
(4, 'CONTRA', 'Contra Voucher', 'contra', 'CONTRA_VOUCHER', 1, 0, 1, 1, 1, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42'),
(5, 'SALES', 'Sales Voucher', 'sales', 'SALES_INVOICE', 1, 0, 1, 1, 1, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42'),
(6, 'PURCHASE', 'Purchase Voucher', 'purchase', 'PURCHASE_INVOICE', 1, 0, 1, 1, 1, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42'),
(7, 'CREDIT_NOTE', 'Credit Note', 'credit_note', 'CREDIT_NOTE', 1, 0, 1, 1, 1, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42'),
(8, 'DEBIT_NOTE', 'Debit Note', 'debit_note', 'DEBIT_NOTE', 1, 0, 1, 1, 1, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42'),
(9, 'OPENING', 'Opening Voucher', 'opening', 'OPENING_BALANCE', 1, 0, 1, 1, 1, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42'),
(10, 'ADJUSTMENT', 'Adjustment Voucher', 'adjustment', 'ADJUSTMENT', 1, 0, 1, 1, 1, NULL, NULL, '2026-05-05 05:31:42', '2026-05-05 05:31:42');

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
-- Indexes for table `accounts`
--
ALTER TABLE `accounts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_accounts_company_code` (`company_id`,`account_code`),
  ADD UNIQUE KEY `uq_accounts_company_name` (`company_id`,`account_name`),
  ADD KEY `idx_accounts_company_id` (`company_id`),
  ADD KEY `idx_accounts_branch_id` (`branch_id`),
  ADD KEY `idx_accounts_group_id` (`account_group_id`),
  ADD KEY `idx_accounts_type` (`account_type`),
  ADD KEY `idx_accounts_is_active` (`is_active`),
  ADD KEY `fk_accounts_created_by` (`created_by`),
  ADD KEY `fk_accounts_updated_by` (`updated_by`);

--
-- Indexes for table `account_groups`
--
ALTER TABLE `account_groups`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_account_groups_code` (`group_code`),
  ADD UNIQUE KEY `uq_account_groups_name` (`group_name`),
  ADD KEY `idx_account_groups_parent` (`parent_group_id`),
  ADD KEY `idx_account_groups_nature` (`group_nature`),
  ADD KEY `idx_account_groups_category` (`group_category`),
  ADD KEY `idx_account_groups_is_active` (`is_active`),
  ADD KEY `fk_account_groups_created_by` (`created_by`),
  ADD KEY `fk_account_groups_updated_by` (`updated_by`);

--
-- Indexes for table `amc_contracts`
--
ALTER TABLE `amc_contracts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_amc_contracts_company_no` (`company_id`,`contract_no`),
  ADD KEY `idx_amc_contracts_vendor` (`vendor_party_id`),
  ADD KEY `idx_amc_contracts_status` (`contract_status`),
  ADD KEY `idx_amc_contracts_end_date` (`contract_end_date`),
  ADD KEY `fk_amc_contracts_approved_by` (`approved_by`),
  ADD KEY `fk_amc_contracts_created_by` (`created_by`),
  ADD KEY `fk_amc_contracts_updated_by` (`updated_by`);

--
-- Indexes for table `amc_contract_assets`
--
ALTER TABLE `amc_contract_assets`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_amc_contract_assets_contract_asset` (`amc_contract_id`,`asset_id`),
  ADD KEY `idx_amc_contract_assets_asset` (`asset_id`);

--
-- Indexes for table `assets`
--
ALTER TABLE `assets`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_assets_company_code` (`company_id`,`asset_code`),
  ADD UNIQUE KEY `uq_assets_company_tag` (`company_id`,`asset_tag_no`),
  ADD KEY `idx_assets_category` (`asset_category_id`),
  ADD KEY `idx_assets_status` (`asset_status`),
  ADD KEY `idx_assets_purchase_invoice` (`purchase_invoice_id`),
  ADD KEY `fk_assets_branch` (`branch_id`),
  ADD KEY `fk_assets_location` (`location_id`),
  ADD KEY `fk_assets_supplier` (`supplier_party_id`),
  ADD KEY `fk_assets_asset_account` (`asset_account_id`),
  ADD KEY `fk_assets_accum_dep_account` (`accum_depreciation_account_id`),
  ADD KEY `fk_assets_dep_exp_account` (`depreciation_expense_account_id`),
  ADD KEY `fk_assets_cost_center` (`cost_center_id`),
  ADD KEY `fk_assets_warehouse` (`warehouse_id`),
  ADD KEY `fk_assets_activated_by` (`activated_by`),
  ADD KEY `fk_assets_disposed_by` (`disposed_by`),
  ADD KEY `fk_assets_created_by` (`created_by`),
  ADD KEY `fk_assets_updated_by` (`updated_by`);

--
-- Indexes for table `asset_books`
--
ALTER TABLE `asset_books`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_asset_books_asset_book` (`asset_id`,`book_type`),
  ADD KEY `idx_asset_books_type` (`book_type`);

--
-- Indexes for table `asset_categories`
--
ALTER TABLE `asset_categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_asset_categories_company_code` (`company_id`,`category_code`),
  ADD KEY `idx_asset_categories_parent` (`parent_category_id`),
  ADD KEY `idx_asset_categories_type` (`asset_type`),
  ADD KEY `fk_asset_categories_asset_account` (`default_asset_account_id`),
  ADD KEY `fk_asset_categories_accum_dep_account` (`default_accum_depreciation_account_id`),
  ADD KEY `fk_asset_categories_dep_exp_account` (`default_depreciation_expense_account_id`),
  ADD KEY `fk_asset_categories_disposal_gain_account` (`default_disposal_gain_account_id`),
  ADD KEY `fk_asset_categories_disposal_loss_account` (`default_disposal_loss_account_id`),
  ADD KEY `fk_asset_categories_created_by` (`created_by`),
  ADD KEY `fk_asset_categories_updated_by` (`updated_by`);

--
-- Indexes for table `asset_depreciation_lines`
--
ALTER TABLE `asset_depreciation_lines`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_asset_depreciation_lines_run` (`asset_depreciation_run_id`),
  ADD KEY `idx_asset_depreciation_lines_asset` (`asset_id`),
  ADD KEY `fk_asset_depreciation_lines_book` (`asset_book_id`);

--
-- Indexes for table `asset_depreciation_runs`
--
ALTER TABLE `asset_depreciation_runs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_asset_depreciation_runs_company_no` (`company_id`,`run_no`),
  ADD KEY `idx_asset_depreciation_runs_date` (`run_date`),
  ADD KEY `idx_asset_depreciation_runs_status` (`run_status`),
  ADD KEY `fk_asset_depreciation_runs_voucher` (`voucher_id`),
  ADD KEY `fk_asset_depreciation_runs_created_by` (`created_by`),
  ADD KEY `fk_asset_depreciation_runs_posted_by` (`posted_by`);

--
-- Indexes for table `asset_disposals`
--
ALTER TABLE `asset_disposals`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_asset_disposals_asset_no` (`asset_id`,`disposal_no`),
  ADD KEY `idx_asset_disposals_date` (`disposal_date`),
  ADD KEY `idx_asset_disposals_status` (`disposal_status`),
  ADD KEY `fk_asset_disposals_sale_party` (`sale_party_id`),
  ADD KEY `fk_asset_disposals_sales_invoice` (`sales_invoice_id`),
  ADD KEY `fk_asset_disposals_voucher` (`voucher_id`),
  ADD KEY `fk_asset_disposals_approved_by` (`approved_by`),
  ADD KEY `fk_asset_disposals_created_by` (`created_by`),
  ADD KEY `fk_asset_disposals_updated_by` (`updated_by`);

--
-- Indexes for table `asset_downtime_logs`
--
ALTER TABLE `asset_downtime_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_asset_downtime_logs_asset` (`asset_id`),
  ADD KEY `idx_asset_downtime_logs_start` (`downtime_start`),
  ADD KEY `fk_asset_downtime_logs_work_order` (`maintenance_work_order_id`),
  ADD KEY `fk_asset_downtime_logs_created_by` (`created_by`),
  ADD KEY `fk_asset_downtime_logs_updated_by` (`updated_by`);

--
-- Indexes for table `asset_transfers`
--
ALTER TABLE `asset_transfers`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_asset_transfers_company_no` (`company_id`,`transfer_no`),
  ADD KEY `idx_asset_transfers_date` (`transfer_date`),
  ADD KEY `idx_asset_transfers_status` (`transfer_status`),
  ADD KEY `fk_asset_transfers_from_branch` (`from_branch_id`),
  ADD KEY `fk_asset_transfers_to_branch` (`to_branch_id`),
  ADD KEY `fk_asset_transfers_from_location` (`from_location_id`),
  ADD KEY `fk_asset_transfers_to_location` (`to_location_id`),
  ADD KEY `fk_asset_transfers_voucher` (`voucher_id`),
  ADD KEY `fk_asset_transfers_approved_by` (`approved_by`),
  ADD KEY `fk_asset_transfers_created_by` (`created_by`),
  ADD KEY `fk_asset_transfers_updated_by` (`updated_by`);

--
-- Indexes for table `asset_transfer_lines`
--
ALTER TABLE `asset_transfer_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_asset_transfer_lines_doc_line` (`asset_transfer_id`,`line_no`),
  ADD KEY `idx_asset_transfer_lines_asset` (`asset_id`),
  ADD KEY `fk_asset_transfer_lines_from_branch` (`from_branch_id`),
  ADD KEY `fk_asset_transfer_lines_to_branch` (`to_branch_id`),
  ADD KEY `fk_asset_transfer_lines_from_location` (`from_location_id`),
  ADD KEY `fk_asset_transfer_lines_to_location` (`to_location_id`);

--
-- Indexes for table `attendance_records`
--
ALTER TABLE `attendance_records`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_attendance_employee` (`employee_id`);

--
-- Indexes for table `audit_logs`
--
ALTER TABLE `audit_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_audit_logs_user_id` (`user_id`),
  ADD KEY `idx_audit_logs_company_id` (`company_id`),
  ADD KEY `idx_audit_logs_branch_id` (`branch_id`),
  ADD KEY `idx_audit_logs_location_id` (`location_id`),
  ADD KEY `idx_audit_logs_module` (`module`),
  ADD KEY `idx_audit_logs_entity` (`entity_name`,`entity_id`),
  ADD KEY `idx_audit_logs_action` (`action`),
  ADD KEY `idx_audit_logs_created_at` (`created_at`);

--
-- Indexes for table `bank_reconciliation`
--
ALTER TABLE `bank_reconciliation`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_bank_reconciliation_voucher_line` (`voucher_line_id`),
  ADD KEY `idx_bank_reconciliation_account_id` (`account_id`),
  ADD KEY `idx_bank_reconciliation_status` (`reconciliation_status`),
  ADD KEY `idx_bank_reconciliation_bank_date` (`bank_date`),
  ADD KEY `idx_bank_reconciliation_cleared_date` (`cleared_date`),
  ADD KEY `fk_bank_reconciliation_reconciled_by` (`reconciled_by`);

--
-- Indexes for table `boms`
--
ALTER TABLE `boms`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_boms_company_code` (`company_id`,`bom_code`),
  ADD UNIQUE KEY `uq_boms_item_version` (`company_id`,`output_item_id`,`version_no`),
  ADD KEY `idx_boms_output_item` (`output_item_id`),
  ADD KEY `idx_boms_status` (`approval_status`),
  ADD KEY `idx_boms_default` (`is_default`),
  ADD KEY `fk_boms_branch` (`branch_id`),
  ADD KEY `fk_boms_location` (`location_id`),
  ADD KEY `fk_boms_output_uom` (`output_uom_id`),
  ADD KEY `fk_boms_approved_by` (`approved_by`),
  ADD KEY `fk_boms_created_by` (`created_by`),
  ADD KEY `fk_boms_updated_by` (`updated_by`);

--
-- Indexes for table `bom_lines`
--
ALTER TABLE `bom_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_bom_lines_doc_line` (`bom_id`,`line_no`),
  ADD KEY `idx_bom_lines_item` (`item_id`),
  ADD KEY `idx_bom_lines_type` (`line_type`),
  ADD KEY `fk_bom_lines_uom` (`uom_id`);

--
-- Indexes for table `bom_operations`
--
ALTER TABLE `bom_operations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_bom_operations_doc_op` (`bom_id`,`operation_no`);

--
-- Indexes for table `branches`
--
ALTER TABLE `branches`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_branches_company_code` (`company_id`,`code`),
  ADD UNIQUE KEY `uq_branches_company_name` (`company_id`,`name`),
  ADD KEY `idx_branches_company_id` (`company_id`),
  ADD KEY `idx_branches_is_head_office` (`is_head_office`),
  ADD KEY `idx_branches_is_active` (`is_active`);

--
-- Indexes for table `brands`
--
ALTER TABLE `brands`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_brands_code` (`brand_code`),
  ADD UNIQUE KEY `uq_brands_name` (`brand_name`),
  ADD KEY `idx_brands_is_active` (`is_active`),
  ADD KEY `fk_brands_created_by` (`created_by`),
  ADD KEY `fk_brands_updated_by` (`updated_by`);

--
-- Indexes for table `budgets`
--
ALTER TABLE `budgets`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_budgets_company_code` (`company_id`,`budget_code`),
  ADD KEY `fk_budgets_financial_year` (`financial_year_id`),
  ADD KEY `fk_budgets_created_by` (`created_by`),
  ADD KEY `fk_budgets_updated_by` (`updated_by`);

--
-- Indexes for table `budget_lines`
--
ALTER TABLE `budget_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_budget_lines_doc_line` (`budget_id`,`line_no`),
  ADD KEY `fk_budget_lines_account` (`account_id`);

--
-- Indexes for table `business_locations`
--
ALTER TABLE `business_locations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_locations_branch_code` (`branch_id`,`code`),
  ADD UNIQUE KEY `uq_locations_branch_name` (`branch_id`,`name`),
  ADD KEY `idx_locations_company_id` (`company_id`),
  ADD KEY `idx_locations_branch_id` (`branch_id`),
  ADD KEY `idx_locations_type` (`location_type`),
  ADD KEY `idx_locations_is_default` (`is_default`),
  ADD KEY `idx_locations_is_active` (`is_active`);

--
-- Indexes for table `cash_sessions`
--
ALTER TABLE `cash_sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_cash_sessions_company_id` (`company_id`),
  ADD KEY `idx_cash_sessions_branch_id` (`branch_id`),
  ADD KEY `idx_cash_sessions_location_id` (`location_id`),
  ADD KEY `idx_cash_sessions_user_id` (`user_id`),
  ADD KEY `idx_cash_sessions_cash_account_id` (`cash_account_id`),
  ADD KEY `idx_cash_sessions_status` (`status`),
  ADD KEY `idx_cash_sessions_opening_datetime` (`opening_datetime`),
  ADD KEY `fk_cash_sessions_created_by` (`created_by`),
  ADD KEY `fk_cash_sessions_updated_by` (`updated_by`);

--
-- Indexes for table `companies`
--
ALTER TABLE `companies`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_companies_code` (`code`),
  ADD UNIQUE KEY `uq_companies_gstin` (`gstin`),
  ADD UNIQUE KEY `uq_companies_pan` (`pan`),
  ADD KEY `idx_companies_legal_name` (`legal_name`),
  ADD KEY `idx_companies_trade_name` (`trade_name`),
  ADD KEY `idx_companies_is_active` (`is_active`);

--
-- Indexes for table `cost_centers`
--
ALTER TABLE `cost_centers`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_cost_center_company_code` (`company_id`,`cost_center_code`),
  ADD KEY `fk_cost_centers_parent` (`parent_id`);

--
-- Indexes for table `crm_enquiry_lines`
--
ALTER TABLE `crm_enquiry_lines`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_crm_enquiry_lines_opportunity` (`enquiry_id`),
  ADD KEY `fk_crm_enquiry_lines_item` (`item_id`);

--
-- Indexes for table `crm_followups`
--
ALTER TABLE `crm_followups`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_crm_followups_opportunity` (`enquiry_id`);

--
-- Indexes for table `crm_leads`
--
ALTER TABLE `crm_leads`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_crm_leads_company` (`company_id`),
  ADD KEY `fk_crm_leads_source` (`source_id`),
  ADD KEY `fk_crm_leads_assigned` (`assigned_to`);

--
-- Indexes for table `crm_lead_activities`
--
ALTER TABLE `crm_lead_activities`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_crm_lead_activities_lead` (`lead_id`);

--
-- Indexes for table `crm_opportunities`
--
ALTER TABLE `crm_opportunities`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_crm_opportunities_company` (`company_id`),
  ADD KEY `fk_crm_opportunities_lead` (`lead_id`),
  ADD KEY `fk_crm_opportunities_customer` (`customer_party_id`),
  ADD KEY `fk_crm_opportunities_stage` (`stage_id`),
  ADD KEY `fk_crm_opportunities_assigned` (`assigned_to`);

--
-- Indexes for table `crm_opportunity_products`
--
ALTER TABLE `crm_opportunity_products`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_crm_opportunity_products_opportunity` (`opportunity_id`),
  ADD KEY `fk_crm_opportunity_products_item` (`item_id`);

--
-- Indexes for table `crm_sources`
--
ALTER TABLE `crm_sources`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `crm_stages`
--
ALTER TABLE `crm_stages`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `departments`
--
ALTER TABLE `departments`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `designations`
--
ALTER TABLE `designations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `document_postings`
--
ALTER TABLE `document_postings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_document_postings_doc` (`document_module`,`document_table`,`document_id`),
  ADD KEY `idx_document_postings_doc_date` (`document_date`),
  ADD KEY `idx_document_postings_status` (`posting_status`),
  ADD KEY `idx_document_postings_voucher` (`voucher_id`),
  ADD KEY `fk_document_postings_company` (`company_id`),
  ADD KEY `fk_document_postings_branch` (`branch_id`),
  ADD KEY `fk_document_postings_location` (`location_id`),
  ADD KEY `fk_document_postings_financial_year` (`financial_year_id`),
  ADD KEY `fk_document_postings_posting_rule_group` (`posting_rule_group_id`),
  ADD KEY `fk_document_postings_created_by` (`created_by`),
  ADD KEY `fk_document_postings_updated_by` (`updated_by`);

--
-- Indexes for table `document_posting_lines`
--
ALTER TABLE `document_posting_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_document_posting_lines_doc_line` (`document_posting_id`,`line_no`),
  ADD KEY `idx_document_posting_lines_account` (`account_id`),
  ADD KEY `idx_document_posting_lines_rule` (`source_rule_id`);

--
-- Indexes for table `document_series`
--
ALTER TABLE `document_series`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_document_series_unique` (`company_id`,`branch_id`,`location_id`,`financial_year_id`,`document_type`,`series_name`),
  ADD KEY `idx_document_series_company_id` (`company_id`),
  ADD KEY `idx_document_series_branch_id` (`branch_id`),
  ADD KEY `idx_document_series_location_id` (`location_id`),
  ADD KEY `idx_document_series_financial_year_id` (`financial_year_id`),
  ADD KEY `idx_document_series_doc_type` (`document_type`),
  ADD KEY `idx_document_series_is_default` (`is_default`),
  ADD KEY `idx_document_series_is_active` (`is_active`);

--
-- Indexes for table `document_tax_lines`
--
ALTER TABLE `document_tax_lines`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_document_tax_lines_doc` (`document_module`,`document_table`,`document_id`),
  ADD KEY `idx_document_tax_lines_doc_date` (`document_date`),
  ADD KEY `idx_document_tax_lines_item` (`item_id`),
  ADD KEY `idx_document_tax_lines_tax_code` (`tax_code_id`),
  ADD KEY `idx_document_tax_lines_hsn` (`hsn_sac_code`),
  ADD KEY `fk_document_tax_lines_company` (`company_id`),
  ADD KEY `fk_document_tax_lines_branch` (`branch_id`),
  ADD KEY `fk_document_tax_lines_location` (`location_id`),
  ADD KEY `fk_document_tax_lines_financial_year` (`financial_year_id`);

--
-- Indexes for table `email_messages`
--
ALTER TABLE `email_messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_email_messages_company` (`company_id`),
  ADD KEY `idx_email_messages_document` (`module`,`document_type`,`document_id`),
  ADD KEY `idx_email_messages_status` (`status`),
  ADD KEY `fk_email_messages_setting` (`email_setting_id`),
  ADD KEY `fk_email_messages_template` (`email_template_id`),
  ADD KEY `fk_email_messages_rule` (`email_rule_id`),
  ADD KEY `fk_email_messages_created_by` (`created_by`);

--
-- Indexes for table `email_module_settings`
--
ALTER TABLE `email_module_settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_email_module_settings_scope` (`company_id`,`module`,`document_type`),
  ADD KEY `idx_email_module_settings_company` (`company_id`),
  ADD KEY `idx_email_module_settings_module` (`module`),
  ADD KEY `fk_email_module_settings_created_by` (`created_by`),
  ADD KEY `fk_email_module_settings_updated_by` (`updated_by`);

--
-- Indexes for table `email_rules`
--
ALTER TABLE `email_rules`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_email_rules_code` (`company_id`,`rule_code`),
  ADD KEY `idx_email_rules_company` (`company_id`),
  ADD KEY `idx_email_rules_module_event` (`module`,`event_code`),
  ADD KEY `fk_email_rules_template` (`template_id`),
  ADD KEY `fk_email_rules_created_by` (`created_by`),
  ADD KEY `fk_email_rules_updated_by` (`updated_by`);

--
-- Indexes for table `email_settings`
--
ALTER TABLE `email_settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_email_settings_company_name` (`company_id`,`setting_name`),
  ADD KEY `idx_email_settings_company` (`company_id`),
  ADD KEY `idx_email_settings_active` (`is_active`),
  ADD KEY `fk_email_settings_created_by` (`created_by`),
  ADD KEY `fk_email_settings_updated_by` (`updated_by`);

--
-- Indexes for table `email_templates`
--
ALTER TABLE `email_templates`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_email_templates_code` (`company_id`,`template_code`),
  ADD KEY `idx_email_templates_company` (`company_id`),
  ADD KEY `idx_email_templates_module` (`module`),
  ADD KEY `fk_email_templates_created_by` (`created_by`),
  ADD KEY `fk_email_templates_updated_by` (`updated_by`);

--
-- Indexes for table `employees`
--
ALTER TABLE `employees`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_employees_company` (`company_id`),
  ADD KEY `fk_employees_department` (`department_id`),
  ADD KEY `fk_employees_designation` (`designation_id`),
  ADD KEY `fk_employees_cost_center` (`cost_center_id`);

--
-- Indexes for table `employee_accounts`
--
ALTER TABLE `employee_accounts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_employee_accounts_employee_purpose` (`employee_id`,`account_purpose`),
  ADD UNIQUE KEY `uq_employee_accounts_employee_account` (`employee_id`,`account_id`),
  ADD KEY `idx_employee_accounts_account` (`account_id`);

--
-- Indexes for table `employee_addresses`
--
ALTER TABLE `employee_addresses`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_employee_addresses_employee_type` (`employee_id`,`address_type`);

--
-- Indexes for table `employee_relations`
--
ALTER TABLE `employee_relations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_employee_relations_employee` (`employee_id`);

--
-- Indexes for table `employee_salary_components`
--
ALTER TABLE `employee_salary_components`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_salary_components_struct` (`salary_structure_id`);

--
-- Indexes for table `employee_salary_structures`
--
ALTER TABLE `employee_salary_structures`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_salary_struct_employee` (`employee_id`);

--
-- Indexes for table `expense_claims`
--
ALTER TABLE `expense_claims`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_expense_claims_company_no` (`company_id`,`claim_no`),
  ADD KEY `idx_expense_claims_employee` (`employee_id`),
  ADD KEY `idx_expense_claims_status` (`claim_status`),
  ADD KEY `fk_expense_claims_voucher` (`voucher_id`),
  ADD KEY `fk_expense_claims_reimbursement_voucher` (`reimbursement_voucher_id`),
  ADD KEY `fk_expense_claims_approved_by` (`approved_by`),
  ADD KEY `fk_expense_claims_reimbursed_by` (`reimbursed_by`),
  ADD KEY `fk_expense_claims_created_by` (`created_by`),
  ADD KEY `fk_expense_claims_updated_by` (`updated_by`);

--
-- Indexes for table `expense_claim_lines`
--
ALTER TABLE `expense_claim_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_expense_claim_lines_doc_line` (`expense_claim_id`,`line_no`),
  ADD KEY `fk_expense_claim_lines_project` (`project_id`),
  ADD KEY `fk_expense_claim_lines_project_task` (`project_task_id`);

--
-- Indexes for table `financial_years`
--
ALTER TABLE `financial_years`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_financial_years_company_code` (`company_id`,`fy_code`),
  ADD UNIQUE KEY `uq_financial_years_company_name` (`company_id`,`fy_name`),
  ADD KEY `idx_financial_years_company_id` (`company_id`),
  ADD KEY `idx_financial_years_dates` (`start_date`,`end_date`),
  ADD KEY `idx_financial_years_is_current` (`is_current`),
  ADD KEY `idx_financial_years_is_locked` (`is_locked`),
  ADD KEY `idx_financial_years_is_active` (`is_active`);

--
-- Indexes for table `gst_registrations`
--
ALTER TABLE `gst_registrations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_gst_registrations_gstin` (`gstin`),
  ADD KEY `idx_gst_registrations_company` (`company_id`),
  ADD KEY `idx_gst_registrations_branch` (`branch_id`),
  ADD KEY `idx_gst_registrations_location` (`location_id`),
  ADD KEY `idx_gst_registrations_state` (`state_id`),
  ADD KEY `idx_gst_registrations_default` (`is_default`),
  ADD KEY `idx_gst_registrations_active` (`is_active`),
  ADD KEY `fk_gst_registrations_created_by` (`created_by`),
  ADD KEY `fk_gst_registrations_updated_by` (`updated_by`);

--
-- Indexes for table `gst_tax_rules`
--
ALTER TABLE `gst_tax_rules`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_gst_tax_rules_code` (`rule_code`),
  ADD KEY `idx_gst_tax_rules_transaction_type` (`transaction_type`),
  ADD KEY `idx_gst_tax_rules_item_type` (`item_type`),
  ADD KEY `idx_gst_tax_rules_tax_code_id` (`tax_code_id`),
  ADD KEY `idx_gst_tax_rules_priority` (`priority_order`),
  ADD KEY `idx_gst_tax_rules_active` (`is_active`),
  ADD KEY `fk_gst_tax_rules_created_by` (`created_by`),
  ADD KEY `fk_gst_tax_rules_updated_by` (`updated_by`);

--
-- Indexes for table `hr_statutory_esi`
--
ALTER TABLE `hr_statutory_esi`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_hr_esi_profile` (`statutory_profile_id`);

--
-- Indexes for table `hr_statutory_pf`
--
ALTER TABLE `hr_statutory_pf`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_hr_pf_profile` (`statutory_profile_id`);

--
-- Indexes for table `hr_statutory_profiles`
--
ALTER TABLE `hr_statutory_profiles`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_hr_stat_prof_lookup` (`company_id`,`is_active`,`effective_from`);

--
-- Indexes for table `hr_statutory_pt_slabs`
--
ALTER TABLE `hr_statutory_pt_slabs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_hr_pt_profile` (`statutory_profile_id`);

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
-- Indexes for table `item_alternates`
--
ALTER TABLE `item_alternates`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_item_alternates_pair` (`item_id`,`alternate_item_id`),
  ADD KEY `idx_item_alternates_item_id` (`item_id`),
  ADD KEY `idx_item_alternates_alternate_item_id` (`alternate_item_id`),
  ADD KEY `idx_item_alternates_priority` (`priority_order`),
  ADD KEY `fk_item_alternates_created_by` (`created_by`),
  ADD KEY `fk_item_alternates_updated_by` (`updated_by`);

--
-- Indexes for table `item_categories`
--
ALTER TABLE `item_categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_item_categories_code` (`category_code`),
  ADD UNIQUE KEY `uq_item_categories_name` (`category_name`),
  ADD KEY `idx_item_categories_parent` (`parent_category_id`),
  ADD KEY `idx_item_categories_is_active` (`is_active`),
  ADD KEY `fk_item_categories_created_by` (`created_by`),
  ADD KEY `fk_item_categories_updated_by` (`updated_by`);

--
-- Indexes for table `item_planning_policies`
--
ALTER TABLE `item_planning_policies`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_item_planning_policies_scope` (`company_id`,`item_id`,`warehouse_id`),
  ADD KEY `idx_item_planning_policies_item` (`item_id`),
  ADD KEY `idx_item_planning_policies_warehouse` (`warehouse_id`),
  ADD KEY `idx_item_planning_policies_method` (`planning_method`),
  ADD KEY `idx_item_planning_policies_procurement` (`procurement_type`),
  ADD KEY `fk_item_planning_policies_branch` (`branch_id`),
  ADD KEY `fk_item_planning_policies_location` (`location_id`),
  ADD KEY `fk_item_planning_policies_preferred_supplier` (`preferred_supplier_party_id`),
  ADD KEY `fk_item_planning_policies_preferred_bom` (`preferred_bom_id`),
  ADD KEY `fk_item_planning_policies_preferred_warehouse` (`preferred_warehouse_id`),
  ADD KEY `fk_item_planning_policies_created_by` (`created_by`),
  ADD KEY `fk_item_planning_policies_updated_by` (`updated_by`);

--
-- Indexes for table `item_prices`
--
ALTER TABLE `item_prices`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_item_prices_item_id` (`item_id`),
  ADD KEY `idx_item_prices_price_type` (`price_type`),
  ADD KEY `idx_item_prices_uom_id` (`uom_id`),
  ADD KEY `idx_item_prices_validity` (`valid_from`,`valid_to`),
  ADD KEY `idx_item_prices_is_default` (`is_default`),
  ADD KEY `fk_item_prices_created_by` (`created_by`),
  ADD KEY `fk_item_prices_updated_by` (`updated_by`);

--
-- Indexes for table `item_supplier_map`
--
ALTER TABLE `item_supplier_map`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_item_supplier_map_item_supplier` (`item_id`,`supplier_party_id`),
  ADD KEY `idx_item_supplier_map_item_id` (`item_id`),
  ADD KEY `idx_item_supplier_map_supplier_party_id` (`supplier_party_id`),
  ADD KEY `idx_item_supplier_map_primary` (`is_primary_supplier`),
  ADD KEY `idx_item_supplier_map_is_active` (`is_active`),
  ADD KEY `fk_item_supplier_map_purchase_uom` (`purchase_uom_id`),
  ADD KEY `fk_item_supplier_map_created_by` (`created_by`),
  ADD KEY `fk_item_supplier_map_updated_by` (`updated_by`);

--
-- Indexes for table `jobwork_charges`
--
ALTER TABLE `jobwork_charges`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_jobwork_charges_company_no` (`company_id`,`charge_no`),
  ADD KEY `idx_jobwork_charges_date` (`charge_date`),
  ADD KEY `idx_jobwork_charges_supplier` (`supplier_party_id`),
  ADD KEY `idx_jobwork_charges_status` (`charge_status`),
  ADD KEY `fk_jobwork_charges_branch` (`branch_id`),
  ADD KEY `fk_jobwork_charges_location` (`location_id`),
  ADD KEY `fk_jobwork_charges_financial_year` (`financial_year_id`),
  ADD KEY `fk_jobwork_charges_document_series` (`document_series_id`),
  ADD KEY `fk_jobwork_charges_jobwork_order` (`jobwork_order_id`),
  ADD KEY `fk_jobwork_charges_purchase_invoice` (`purchase_invoice_id`),
  ADD KEY `fk_jobwork_charges_posted_by` (`posted_by`),
  ADD KEY `fk_jobwork_charges_created_by` (`created_by`),
  ADD KEY `fk_jobwork_charges_updated_by` (`updated_by`),
  ADD KEY `fk_jobwork_charges_voucher` (`voucher_id`);

--
-- Indexes for table `jobwork_charge_lines`
--
ALTER TABLE `jobwork_charge_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_jobwork_charge_lines_doc_line` (`jobwork_charge_id`,`line_no`),
  ADD KEY `idx_jobwork_charge_lines_item` (`item_id`),
  ADD KEY `idx_jobwork_charge_lines_output_item` (`output_item_id`),
  ADD KEY `fk_jobwork_charge_lines_tax_code` (`tax_code_id`);

--
-- Indexes for table `jobwork_dispatches`
--
ALTER TABLE `jobwork_dispatches`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_jobwork_dispatches_company_no` (`company_id`,`dispatch_no`),
  ADD KEY `idx_jobwork_dispatches_date` (`dispatch_date`),
  ADD KEY `idx_jobwork_dispatches_supplier` (`supplier_party_id`),
  ADD KEY `idx_jobwork_dispatches_status` (`dispatch_status`),
  ADD KEY `fk_jobwork_dispatches_branch` (`branch_id`),
  ADD KEY `fk_jobwork_dispatches_location` (`location_id`),
  ADD KEY `fk_jobwork_dispatches_financial_year` (`financial_year_id`),
  ADD KEY `fk_jobwork_dispatches_document_series` (`document_series_id`),
  ADD KEY `fk_jobwork_dispatches_jobwork_order` (`jobwork_order_id`),
  ADD KEY `fk_jobwork_dispatches_warehouse` (`warehouse_id`),
  ADD KEY `fk_jobwork_dispatches_transporter` (`transporter_party_id`),
  ADD KEY `fk_jobwork_dispatches_posted_by` (`posted_by`),
  ADD KEY `fk_jobwork_dispatches_created_by` (`created_by`),
  ADD KEY `fk_jobwork_dispatches_updated_by` (`updated_by`),
  ADD KEY `fk_jobwork_dispatches_voucher` (`voucher_id`);

--
-- Indexes for table `jobwork_dispatch_lines`
--
ALTER TABLE `jobwork_dispatch_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_jobwork_dispatch_lines_doc_line` (`jobwork_dispatch_id`,`line_no`),
  ADD KEY `idx_jobwork_dispatch_lines_item` (`item_id`),
  ADD KEY `fk_jobwork_dispatch_lines_order_material` (`jobwork_order_material_id`),
  ADD KEY `fk_jobwork_dispatch_lines_uom` (`uom_id`),
  ADD KEY `fk_jobwork_dispatch_lines_warehouse` (`warehouse_id`),
  ADD KEY `fk_jobwork_dispatch_lines_batch` (`batch_id`),
  ADD KEY `fk_jobwork_dispatch_lines_serial` (`serial_id`);

--
-- Indexes for table `jobwork_orders`
--
ALTER TABLE `jobwork_orders`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_jobwork_orders_company_no` (`company_id`,`jobwork_no`),
  ADD KEY `idx_jobwork_orders_date` (`jobwork_date`),
  ADD KEY `idx_jobwork_orders_supplier` (`supplier_party_id`),
  ADD KEY `idx_jobwork_orders_status` (`jobwork_status`),
  ADD KEY `fk_jobwork_orders_branch` (`branch_id`),
  ADD KEY `fk_jobwork_orders_location` (`location_id`),
  ADD KEY `fk_jobwork_orders_financial_year` (`financial_year_id`),
  ADD KEY `fk_jobwork_orders_document_series` (`document_series_id`),
  ADD KEY `fk_jobwork_orders_issue_warehouse` (`issue_warehouse_id`),
  ADD KEY `fk_jobwork_orders_receipt_warehouse` (`receipt_warehouse_id`),
  ADD KEY `fk_jobwork_orders_approved_by` (`approved_by`),
  ADD KEY `fk_jobwork_orders_created_by` (`created_by`),
  ADD KEY `fk_jobwork_orders_updated_by` (`updated_by`);

--
-- Indexes for table `jobwork_order_materials`
--
ALTER TABLE `jobwork_order_materials`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_jobwork_order_materials_doc_line` (`jobwork_order_id`,`line_no`),
  ADD KEY `idx_jobwork_order_materials_item` (`item_id`),
  ADD KEY `fk_jobwork_order_materials_uom` (`uom_id`);

--
-- Indexes for table `jobwork_order_outputs`
--
ALTER TABLE `jobwork_order_outputs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_jobwork_order_outputs_doc_line` (`jobwork_order_id`,`line_no`),
  ADD KEY `idx_jobwork_order_outputs_item` (`item_id`),
  ADD KEY `fk_jobwork_order_outputs_uom` (`uom_id`);

--
-- Indexes for table `jobwork_receipts`
--
ALTER TABLE `jobwork_receipts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_jobwork_receipts_company_no` (`company_id`,`receipt_no`),
  ADD KEY `idx_jobwork_receipts_date` (`receipt_date`),
  ADD KEY `idx_jobwork_receipts_supplier` (`supplier_party_id`),
  ADD KEY `idx_jobwork_receipts_status` (`receipt_status`),
  ADD KEY `fk_jobwork_receipts_branch` (`branch_id`),
  ADD KEY `fk_jobwork_receipts_location` (`location_id`),
  ADD KEY `fk_jobwork_receipts_financial_year` (`financial_year_id`),
  ADD KEY `fk_jobwork_receipts_document_series` (`document_series_id`),
  ADD KEY `fk_jobwork_receipts_jobwork_order` (`jobwork_order_id`),
  ADD KEY `fk_jobwork_receipts_warehouse` (`warehouse_id`),
  ADD KEY `fk_jobwork_receipts_transporter` (`transporter_party_id`),
  ADD KEY `fk_jobwork_receipts_posted_by` (`posted_by`),
  ADD KEY `fk_jobwork_receipts_created_by` (`created_by`),
  ADD KEY `fk_jobwork_receipts_updated_by` (`updated_by`),
  ADD KEY `fk_jobwork_receipts_voucher` (`voucher_id`);

--
-- Indexes for table `jobwork_receipt_lines`
--
ALTER TABLE `jobwork_receipt_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_jobwork_receipt_lines_doc_line` (`jobwork_receipt_id`,`line_no`),
  ADD KEY `idx_jobwork_receipt_lines_item` (`item_id`),
  ADD KEY `fk_jobwork_receipt_lines_order_output` (`jobwork_order_output_id`),
  ADD KEY `fk_jobwork_receipt_lines_uom` (`uom_id`),
  ADD KEY `fk_jobwork_receipt_lines_warehouse` (`warehouse_id`),
  ADD KEY `fk_jobwork_receipt_lines_batch` (`batch_id`),
  ADD KEY `fk_jobwork_receipt_lines_serial` (`serial_id`);

--
-- Indexes for table `leave_requests`
--
ALTER TABLE `leave_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_leave_employee` (`employee_id`),
  ADD KEY `fk_leave_type` (`leave_type_id`),
  ADD KEY `fk_leave_approved` (`approved_by`);

--
-- Indexes for table `leave_types`
--
ALTER TABLE `leave_types`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `login_history`
--
ALTER TABLE `login_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_login_history_user_id` (`user_id`),
  ADD KEY `idx_login_history_login_at` (`login_at`),
  ADD KEY `idx_login_history_logout_at` (`logout_at`),
  ADD KEY `idx_login_history_login_status` (`login_status`),
  ADD KEY `idx_login_history_ip_address` (`ip_address`);

--
-- Indexes for table `maintenance_plans`
--
ALTER TABLE `maintenance_plans`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_maintenance_plans_company_code` (`company_id`,`plan_code`),
  ADD KEY `idx_maintenance_plans_type` (`maintenance_type`),
  ADD KEY `fk_maintenance_plans_created_by` (`created_by`),
  ADD KEY `fk_maintenance_plans_updated_by` (`updated_by`);

--
-- Indexes for table `maintenance_plan_assets`
--
ALTER TABLE `maintenance_plan_assets`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_maintenance_plan_assets_plan_asset` (`maintenance_plan_id`,`asset_id`),
  ADD KEY `idx_maintenance_plan_assets_asset` (`asset_id`),
  ADD KEY `idx_maintenance_plan_assets_due_date` (`next_service_due_date`),
  ADD KEY `fk_maintenance_plan_assets_vendor` (`assigned_vendor_party_id`);

--
-- Indexes for table `maintenance_requests`
--
ALTER TABLE `maintenance_requests`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_maintenance_requests_company_no` (`company_id`,`request_no`),
  ADD KEY `idx_maintenance_requests_asset` (`asset_id`),
  ADD KEY `idx_maintenance_requests_status` (`request_status`),
  ADD KEY `idx_maintenance_requests_priority` (`priority_level`),
  ADD KEY `fk_maintenance_requests_branch` (`branch_id`),
  ADD KEY `fk_maintenance_requests_location` (`location_id`),
  ADD KEY `fk_maintenance_requests_plan` (`maintenance_plan_id`),
  ADD KEY `fk_maintenance_requests_requested_by` (`requested_by`),
  ADD KEY `fk_maintenance_requests_approved_by` (`approved_by`),
  ADD KEY `fk_maintenance_requests_created_by` (`created_by`),
  ADD KEY `fk_maintenance_requests_updated_by` (`updated_by`);

--
-- Indexes for table `maintenance_work_orders`
--
ALTER TABLE `maintenance_work_orders`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_maintenance_work_orders_company_no` (`company_id`,`work_order_no`),
  ADD KEY `idx_maintenance_work_orders_asset` (`asset_id`),
  ADD KEY `idx_maintenance_work_orders_status` (`work_order_status`),
  ADD KEY `idx_maintenance_work_orders_vendor` (`vendor_party_id`),
  ADD KEY `fk_maintenance_work_orders_branch` (`branch_id`),
  ADD KEY `fk_maintenance_work_orders_location` (`location_id`),
  ADD KEY `fk_maintenance_work_orders_financial_year` (`financial_year_id`),
  ADD KEY `fk_maintenance_work_orders_document_series` (`document_series_id`),
  ADD KEY `fk_maintenance_work_orders_request` (`maintenance_request_id`),
  ADD KEY `fk_maintenance_work_orders_plan` (`maintenance_plan_id`),
  ADD KEY `fk_maintenance_work_orders_voucher` (`voucher_id`),
  ADD KEY `fk_maintenance_work_orders_approved_by` (`approved_by`),
  ADD KEY `fk_maintenance_work_orders_closed_by` (`closed_by`),
  ADD KEY `fk_maintenance_work_orders_created_by` (`created_by`),
  ADD KEY `fk_maintenance_work_orders_updated_by` (`updated_by`);

--
-- Indexes for table `maintenance_work_order_services`
--
ALTER TABLE `maintenance_work_order_services`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_maintenance_work_order_services_doc_line` (`maintenance_work_order_id`,`line_no`),
  ADD KEY `fk_maintenance_work_order_services_vendor` (`vendor_party_id`),
  ADD KEY `fk_maintenance_work_order_services_purchase_invoice` (`purchase_invoice_id`),
  ADD KEY `fk_maintenance_work_order_services_tax_code` (`tax_code_id`);

--
-- Indexes for table `maintenance_work_order_spares`
--
ALTER TABLE `maintenance_work_order_spares`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_maintenance_work_order_spares_doc_line` (`maintenance_work_order_id`,`line_no`),
  ADD KEY `idx_maintenance_work_order_spares_item` (`item_id`),
  ADD KEY `fk_maintenance_work_order_spares_uom` (`uom_id`),
  ADD KEY `fk_maintenance_work_order_spares_warehouse` (`warehouse_id`),
  ADD KEY `fk_maintenance_work_order_spares_batch` (`batch_id`),
  ADD KEY `fk_maintenance_work_order_spares_serial` (`serial_id`);

--
-- Indexes for table `media_files`
--
ALTER TABLE `media_files`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_media_files_company` (`company_id`),
  ADD KEY `idx_media_files_module` (`module`),
  ADD KEY `idx_media_files_document` (`document_type`,`document_id`),
  ADD KEY `idx_media_files_uploaded_by` (`uploaded_by`);

--
-- Indexes for table `modules`
--
ALTER TABLE `modules`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_modules_code` (`module_code`),
  ADD KEY `idx_modules_sort_order` (`sort_order`),
  ADD KEY `idx_modules_is_active` (`is_active`),
  ADD KEY `fk_modules_created_by` (`created_by`),
  ADD KEY `fk_modules_updated_by` (`updated_by`);

--
-- Indexes for table `mrp_demands`
--
ALTER TABLE `mrp_demands`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_mrp_demands_run` (`mrp_run_id`),
  ADD KEY `idx_mrp_demands_item` (`item_id`),
  ADD KEY `idx_mrp_demands_date` (`demand_date`),
  ADD KEY `fk_mrp_demands_warehouse` (`warehouse_id`);

--
-- Indexes for table `mrp_net_requirements`
--
ALTER TABLE `mrp_net_requirements`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_mrp_net_requirements_run` (`mrp_run_id`),
  ADD KEY `idx_mrp_net_requirements_item` (`item_id`),
  ADD KEY `idx_mrp_net_requirements_action` (`recommended_action`),
  ADD KEY `fk_mrp_net_requirements_warehouse` (`warehouse_id`);

--
-- Indexes for table `mrp_recommendations`
--
ALTER TABLE `mrp_recommendations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_mrp_recommendations_run` (`mrp_run_id`),
  ADD KEY `idx_mrp_recommendations_item` (`item_id`),
  ADD KEY `idx_mrp_recommendations_type` (`recommendation_type`),
  ADD KEY `idx_mrp_recommendations_status` (`recommendation_status`),
  ADD KEY `fk_mrp_recommendations_net_requirement` (`mrp_net_requirement_id`),
  ADD KEY `fk_mrp_recommendations_warehouse` (`warehouse_id`),
  ADD KEY `fk_mrp_recommendations_supplier` (`supplier_party_id`),
  ADD KEY `fk_mrp_recommendations_bom` (`bom_id`),
  ADD KEY `fk_mrp_recommendations_source_warehouse` (`source_warehouse_id`),
  ADD KEY `fk_mrp_recommendations_approved_by` (`approved_by`);

--
-- Indexes for table `mrp_runs`
--
ALTER TABLE `mrp_runs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_mrp_runs_company_no` (`company_id`,`run_no`),
  ADD KEY `idx_mrp_runs_date` (`run_date`),
  ADD KEY `idx_mrp_runs_status` (`run_status`),
  ADD KEY `fk_mrp_runs_branch` (`branch_id`),
  ADD KEY `fk_mrp_runs_location` (`location_id`),
  ADD KEY `fk_mrp_runs_warehouse` (`warehouse_id`),
  ADD KEY `fk_mrp_runs_planning_calendar` (`planning_calendar_id`),
  ADD KEY `fk_mrp_runs_created_by` (`created_by`),
  ADD KEY `fk_mrp_runs_completed_by` (`completed_by`);

--
-- Indexes for table `mrp_supplies`
--
ALTER TABLE `mrp_supplies`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_mrp_supplies_run` (`mrp_run_id`),
  ADD KEY `idx_mrp_supplies_item` (`item_id`),
  ADD KEY `idx_mrp_supplies_date` (`available_date`),
  ADD KEY `fk_mrp_supplies_warehouse` (`warehouse_id`);

--
-- Indexes for table `parties`
--
ALTER TABLE `parties`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_parties_code` (`party_code`),
  ADD KEY `idx_parties_name` (`party_name`),
  ADD KEY `fk_parties_type` (`party_type_id`);

--
-- Indexes for table `party_accounts`
--
ALTER TABLE `party_accounts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_party_accounts_party_account_purpose` (`party_id`,`account_id`,`account_purpose`),
  ADD KEY `idx_party_accounts_party_id` (`party_id`),
  ADD KEY `idx_party_accounts_account_id` (`account_id`),
  ADD KEY `idx_party_accounts_purpose` (`account_purpose`),
  ADD KEY `fk_party_accounts_created_by` (`created_by`),
  ADD KEY `fk_party_accounts_updated_by` (`updated_by`);

--
-- Indexes for table `party_addresses`
--
ALTER TABLE `party_addresses`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_party_addresses_party` (`party_id`);

--
-- Indexes for table `party_bank_accounts`
--
ALTER TABLE `party_bank_accounts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_party_bank_accounts_number` (`party_id`,`account_number`),
  ADD UNIQUE KEY `uq_party_bank_accounts_upi` (`party_id`,`upi_id`),
  ADD KEY `idx_party_bank_accounts_default` (`party_id`,`is_default`);

--
-- Indexes for table `party_contacts`
--
ALTER TABLE `party_contacts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_party_contacts_name` (`contact_name`),
  ADD KEY `idx_party_contacts_mobile` (`mobile`),
  ADD KEY `idx_party_contacts_email` (`email`),
  ADD KEY `idx_party_contacts_primary` (`party_id`,`is_primary`);

--
-- Indexes for table `party_credit_limits`
--
ALTER TABLE `party_credit_limits`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_party_credit_limits_effective` (`party_id`,`effective_from`,`effective_to`);

--
-- Indexes for table `party_gst_details`
--
ALTER TABLE `party_gst_details`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_party_gst_details_gstin` (`gstin`),
  ADD KEY `idx_party_gst_details_default` (`party_id`,`is_default`),
  ADD KEY `idx_party_gst_details_state_code` (`state_code`);

--
-- Indexes for table `party_payment_terms`
--
ALTER TABLE `party_payment_terms`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_party_payment_terms_default` (`party_id`,`is_default`);

--
-- Indexes for table `party_roles`
--
ALTER TABLE `party_roles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_party_roles` (`party_id`,`party_type_id`),
  ADD KEY `fk_party_roles_type` (`party_type_id`);

--
-- Indexes for table `party_types`
--
ALTER TABLE `party_types`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_party_types_code` (`code`);

--
-- Indexes for table `payroll_lines`
--
ALTER TABLE `payroll_lines`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_payroll_lines_run` (`payroll_run_id`),
  ADD KEY `fk_payroll_lines_employee` (`employee_id`);

--
-- Indexes for table `payroll_runs`
--
ALTER TABLE `payroll_runs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_payroll_company` (`company_id`),
  ADD KEY `fk_payroll_voucher` (`voucher_id`);

--
-- Indexes for table `payslips`
--
ALTER TABLE `payslips`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_payslip_line` (`payroll_line_id`);

--
-- Indexes for table `permissions`
--
ALTER TABLE `permissions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_permissions_code` (`code`),
  ADD KEY `idx_permissions_module` (`module`),
  ADD KEY `idx_permissions_name` (`name`),
  ADD KEY `idx_permissions_is_active` (`is_active`),
  ADD KEY `fk_permissions_created_by` (`created_by`),
  ADD KEY `fk_permissions_updated_by` (`updated_by`);

--
-- Indexes for table `planning_calendars`
--
ALTER TABLE `planning_calendars`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_planning_calendars_company_code` (`company_id`,`calendar_code`),
  ADD KEY `fk_planning_calendars_created_by` (`created_by`),
  ADD KEY `fk_planning_calendars_updated_by` (`updated_by`);

--
-- Indexes for table `posting_rules`
--
ALTER TABLE `posting_rules`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_posting_rules_group_line` (`posting_rule_group_id`,`line_no`),
  ADD KEY `idx_posting_rules_group` (`posting_rule_group_id`),
  ADD KEY `idx_posting_rules_side` (`entry_side`),
  ADD KEY `idx_posting_rules_priority` (`priority_order`),
  ADD KEY `fk_posting_rules_fixed_account` (`fixed_account_id`),
  ADD KEY `fk_posting_rules_created_by` (`created_by`),
  ADD KEY `fk_posting_rules_updated_by` (`updated_by`);

--
-- Indexes for table `posting_rule_groups`
--
ALTER TABLE `posting_rule_groups`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_posting_rule_groups_code` (`group_code`),
  ADD KEY `idx_posting_rule_groups_doc_type` (`document_type`),
  ADD KEY `idx_posting_rule_groups_trigger` (`trigger_event`),
  ADD KEY `idx_posting_rule_groups_active` (`is_active`),
  ADD KEY `fk_posting_rule_groups_created_by` (`created_by`),
  ADD KEY `fk_posting_rule_groups_updated_by` (`updated_by`);

--
-- Indexes for table `print_templates`
--
ALTER TABLE `print_templates`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_print_templates_doc_type` (`document_type`);

--
-- Indexes for table `production_material_issues`
--
ALTER TABLE `production_material_issues`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_production_material_issues_company_no` (`company_id`,`issue_no`),
  ADD KEY `idx_production_material_issues_date` (`issue_date`),
  ADD KEY `idx_production_material_issues_status` (`issue_status`),
  ADD KEY `fk_production_material_issues_branch` (`branch_id`),
  ADD KEY `fk_production_material_issues_location` (`location_id`),
  ADD KEY `fk_production_material_issues_financial_year` (`financial_year_id`),
  ADD KEY `fk_production_material_issues_document_series` (`document_series_id`),
  ADD KEY `fk_production_material_issues_production_order` (`production_order_id`),
  ADD KEY `fk_production_material_issues_warehouse` (`warehouse_id`),
  ADD KEY `fk_production_material_issues_posted_by` (`posted_by`),
  ADD KEY `fk_production_material_issues_created_by` (`created_by`),
  ADD KEY `fk_production_material_issues_updated_by` (`updated_by`),
  ADD KEY `fk_production_material_issues_voucher` (`voucher_id`);

--
-- Indexes for table `production_material_issue_lines`
--
ALTER TABLE `production_material_issue_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_production_material_issue_lines_doc_line` (`production_material_issue_id`,`line_no`),
  ADD KEY `idx_production_material_issue_lines_item` (`item_id`),
  ADD KEY `fk_production_material_issue_lines_order_material` (`production_order_material_id`),
  ADD KEY `fk_production_material_issue_lines_uom` (`uom_id`),
  ADD KEY `fk_production_material_issue_lines_warehouse` (`warehouse_id`),
  ADD KEY `fk_production_material_issue_lines_batch` (`batch_id`),
  ADD KEY `fk_production_material_issue_lines_serial` (`serial_id`);

--
-- Indexes for table `production_orders`
--
ALTER TABLE `production_orders`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_production_orders_company_no` (`company_id`,`production_no`),
  ADD KEY `idx_production_orders_date` (`production_date`),
  ADD KEY `idx_production_orders_status` (`production_status`),
  ADD KEY `idx_production_orders_output_item` (`output_item_id`),
  ADD KEY `fk_production_orders_branch` (`branch_id`),
  ADD KEY `fk_production_orders_location` (`location_id`),
  ADD KEY `fk_production_orders_financial_year` (`financial_year_id`),
  ADD KEY `fk_production_orders_document_series` (`document_series_id`),
  ADD KEY `fk_production_orders_bom` (`bom_id`),
  ADD KEY `fk_production_orders_output_uom` (`output_uom_id`),
  ADD KEY `fk_production_orders_warehouse` (`warehouse_id`),
  ADD KEY `fk_production_orders_wip_warehouse` (`wip_warehouse_id`),
  ADD KEY `fk_production_orders_approved_by` (`approved_by`),
  ADD KEY `fk_production_orders_created_by` (`created_by`),
  ADD KEY `fk_production_orders_updated_by` (`updated_by`);

--
-- Indexes for table `production_order_materials`
--
ALTER TABLE `production_order_materials`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_production_order_materials_doc_line` (`production_order_id`,`line_no`),
  ADD KEY `idx_production_order_materials_item` (`item_id`),
  ADD KEY `idx_production_order_materials_status` (`line_status`),
  ADD KEY `fk_production_order_materials_bom_line` (`bom_line_id`),
  ADD KEY `fk_production_order_materials_uom` (`uom_id`),
  ADD KEY `fk_production_order_materials_warehouse` (`warehouse_id`);

--
-- Indexes for table `production_order_operations`
--
ALTER TABLE `production_order_operations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_production_order_operations_doc_op` (`production_order_id`,`operation_no`),
  ADD KEY `fk_production_order_operations_bom_operation` (`bom_operation_id`);

--
-- Indexes for table `production_order_outputs`
--
ALTER TABLE `production_order_outputs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_production_order_outputs_doc_line` (`production_order_id`,`line_no`),
  ADD KEY `idx_production_order_outputs_item` (`item_id`),
  ADD KEY `fk_production_order_outputs_uom` (`uom_id`),
  ADD KEY `fk_production_order_outputs_warehouse` (`warehouse_id`);

--
-- Indexes for table `production_receipts`
--
ALTER TABLE `production_receipts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_production_receipts_company_no` (`company_id`,`receipt_no`),
  ADD KEY `idx_production_receipts_date` (`receipt_date`),
  ADD KEY `idx_production_receipts_status` (`receipt_status`),
  ADD KEY `fk_production_receipts_branch` (`branch_id`),
  ADD KEY `fk_production_receipts_location` (`location_id`),
  ADD KEY `fk_production_receipts_financial_year` (`financial_year_id`),
  ADD KEY `fk_production_receipts_document_series` (`document_series_id`),
  ADD KEY `fk_production_receipts_production_order` (`production_order_id`),
  ADD KEY `fk_production_receipts_warehouse` (`warehouse_id`),
  ADD KEY `fk_production_receipts_posted_by` (`posted_by`),
  ADD KEY `fk_production_receipts_created_by` (`created_by`),
  ADD KEY `fk_production_receipts_updated_by` (`updated_by`),
  ADD KEY `fk_production_receipts_voucher` (`voucher_id`);

--
-- Indexes for table `production_receipt_lines`
--
ALTER TABLE `production_receipt_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_production_receipt_lines_doc_line` (`production_receipt_id`,`line_no`),
  ADD KEY `idx_production_receipt_lines_item` (`item_id`),
  ADD KEY `fk_production_receipt_lines_order_output` (`production_order_output_id`),
  ADD KEY `fk_production_receipt_lines_uom` (`uom_id`),
  ADD KEY `fk_production_receipt_lines_warehouse` (`warehouse_id`),
  ADD KEY `fk_production_receipt_lines_batch` (`batch_id`),
  ADD KEY `fk_production_receipt_lines_serial` (`serial_id`);

--
-- Indexes for table `projects`
--
ALTER TABLE `projects`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_projects_company_code` (`company_id`,`project_code`),
  ADD KEY `fk_projects_customer` (`customer_party_id`),
  ADD KEY `fk_projects_created_by` (`created_by`),
  ADD KEY `fk_projects_updated_by` (`updated_by`);

--
-- Indexes for table `project_billings`
--
ALTER TABLE `project_billings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_project_billings_project` (`project_id`),
  ADD KEY `fk_project_billings_milestone` (`project_milestone_id`),
  ADD KEY `fk_project_billings_sales_invoice` (`sales_invoice_id`);

--
-- Indexes for table `project_expenses`
--
ALTER TABLE `project_expenses`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_project_expenses_project` (`project_id`),
  ADD KEY `fk_project_expenses_task` (`project_task_id`),
  ADD KEY `fk_project_expenses_supplier` (`supplier_party_id`),
  ADD KEY `fk_project_expenses_purchase_invoice` (`purchase_invoice_id`),
  ADD KEY `fk_project_expenses_voucher` (`voucher_id`);

--
-- Indexes for table `project_milestones`
--
ALTER TABLE `project_milestones`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_project_milestones_project` (`project_id`);

--
-- Indexes for table `project_resource_usages`
--
ALTER TABLE `project_resource_usages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_project_resource_usages_project` (`project_id`),
  ADD KEY `fk_project_resource_usages_task` (`project_task_id`),
  ADD KEY `fk_project_resource_usages_asset` (`asset_id`),
  ADD KEY `fk_project_resource_usages_voucher` (`voucher_id`);

--
-- Indexes for table `project_tasks`
--
ALTER TABLE `project_tasks`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_project_tasks_project_code` (`project_id`,`task_code`),
  ADD KEY `fk_project_tasks_employee` (`assigned_employee_id`);

--
-- Indexes for table `project_timesheets`
--
ALTER TABLE `project_timesheets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_project_timesheets_project` (`project_id`),
  ADD KEY `fk_project_timesheets_task` (`project_task_id`),
  ADD KEY `fk_project_timesheets_employee` (`employee_id`),
  ADD KEY `fk_project_timesheets_voucher` (`voucher_id`);

--
-- Indexes for table `project_vendor_works`
--
ALTER TABLE `project_vendor_works`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_project_vendor_works_project` (`project_id`),
  ADD KEY `fk_project_vendor_works_task` (`project_task_id`),
  ADD KEY `fk_project_vendor_works_vendor` (`vendor_party_id`),
  ADD KEY `fk_project_vendor_works_purchase_order` (`purchase_order_id`),
  ADD KEY `fk_project_vendor_works_purchase_invoice` (`purchase_invoice_id`),
  ADD KEY `fk_project_vendor_works_voucher` (`voucher_id`);

--
-- Indexes for table `purchase_invoices`
--
ALTER TABLE `purchase_invoices`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_purchase_invoices_company_no` (`company_id`,`invoice_no`),
  ADD KEY `idx_purchase_invoices_supplier` (`supplier_party_id`),
  ADD KEY `idx_purchase_invoices_date` (`invoice_date`),
  ADD KEY `idx_purchase_invoices_due_date` (`due_date`),
  ADD KEY `idx_purchase_invoices_status` (`invoice_status`),
  ADD KEY `fk_purchase_invoices_branch` (`branch_id`),
  ADD KEY `fk_purchase_invoices_location` (`location_id`),
  ADD KEY `fk_purchase_invoices_financial_year` (`financial_year_id`),
  ADD KEY `fk_purchase_invoices_document_series` (`document_series_id`),
  ADD KEY `fk_purchase_invoices_order` (`purchase_order_id`),
  ADD KEY `fk_purchase_invoices_receipt` (`purchase_receipt_id`),
  ADD KEY `fk_purchase_invoices_billing_address` (`billing_address_id`),
  ADD KEY `fk_purchase_invoices_shipping_address` (`shipping_address_id`),
  ADD KEY `fk_purchase_invoices_contact` (`contact_id`),
  ADD KEY `fk_purchase_invoices_adjustment_account` (`adjustment_account_id`),
  ADD KEY `fk_purchase_invoices_voucher` (`voucher_id`),
  ADD KEY `fk_purchase_invoices_posted_by` (`posted_by`),
  ADD KEY `fk_purchase_invoices_created_by` (`created_by`),
  ADD KEY `fk_purchase_invoices_updated_by` (`updated_by`);

--
-- Indexes for table `purchase_invoice_lines`
--
ALTER TABLE `purchase_invoice_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_purchase_invoice_lines_doc_line` (`purchase_invoice_id`,`line_no`),
  ADD KEY `idx_purchase_invoice_lines_item` (`item_id`),
  ADD KEY `idx_purchase_invoice_lines_warehouse` (`warehouse_id`),
  ADD KEY `fk_purchase_invoice_lines_order_line` (`purchase_order_line_id`),
  ADD KEY `fk_purchase_invoice_lines_receipt_line` (`purchase_receipt_line_id`),
  ADD KEY `fk_purchase_invoice_lines_uom` (`uom_id`),
  ADD KEY `fk_purchase_invoice_lines_batch` (`batch_id`),
  ADD KEY `fk_purchase_invoice_lines_serial` (`serial_id`),
  ADD KEY `fk_purchase_invoice_lines_tax_code` (`tax_code_id`);

--
-- Indexes for table `purchase_orders`
--
ALTER TABLE `purchase_orders`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_purchase_orders_company_no` (`company_id`,`order_no`),
  ADD KEY `idx_purchase_orders_supplier` (`supplier_party_id`),
  ADD KEY `idx_purchase_orders_date` (`order_date`),
  ADD KEY `idx_purchase_orders_status` (`order_status`),
  ADD KEY `fk_purchase_orders_branch` (`branch_id`),
  ADD KEY `fk_purchase_orders_location` (`location_id`),
  ADD KEY `fk_purchase_orders_financial_year` (`financial_year_id`),
  ADD KEY `fk_purchase_orders_document_series` (`document_series_id`),
  ADD KEY `fk_purchase_orders_requisition` (`purchase_requisition_id`),
  ADD KEY `fk_purchase_orders_billing_address` (`billing_address_id`),
  ADD KEY `fk_purchase_orders_shipping_address` (`shipping_address_id`),
  ADD KEY `fk_purchase_orders_contact` (`contact_id`),
  ADD KEY `fk_purchase_orders_approved_by` (`approved_by`),
  ADD KEY `fk_purchase_orders_created_by` (`created_by`),
  ADD KEY `fk_purchase_orders_updated_by` (`updated_by`);

--
-- Indexes for table `purchase_order_lines`
--
ALTER TABLE `purchase_order_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_purchase_order_lines_doc_line` (`purchase_order_id`,`line_no`),
  ADD KEY `idx_purchase_order_lines_item` (`item_id`),
  ADD KEY `idx_purchase_order_lines_warehouse` (`warehouse_id`),
  ADD KEY `idx_purchase_order_lines_status` (`line_status`),
  ADD KEY `fk_purchase_order_lines_requisition_line` (`purchase_requisition_line_id`),
  ADD KEY `fk_purchase_order_lines_uom` (`uom_id`),
  ADD KEY `fk_purchase_order_lines_tax_code` (`tax_code_id`);

--
-- Indexes for table `purchase_payments`
--
ALTER TABLE `purchase_payments`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_purchase_payments_company_no` (`company_id`,`payment_no`),
  ADD KEY `idx_purchase_payments_supplier` (`supplier_party_id`),
  ADD KEY `idx_purchase_payments_date` (`payment_date`),
  ADD KEY `idx_purchase_payments_status` (`payment_status`),
  ADD KEY `fk_purchase_payments_branch` (`branch_id`),
  ADD KEY `fk_purchase_payments_location` (`location_id`),
  ADD KEY `fk_purchase_payments_financial_year` (`financial_year_id`),
  ADD KEY `fk_purchase_payments_document_series` (`document_series_id`),
  ADD KEY `fk_purchase_payments_account` (`account_id`),
  ADD KEY `fk_purchase_payments_voucher` (`voucher_id`),
  ADD KEY `fk_purchase_payments_posted_by` (`posted_by`),
  ADD KEY `fk_purchase_payments_created_by` (`created_by`),
  ADD KEY `fk_purchase_payments_updated_by` (`updated_by`);

--
-- Indexes for table `purchase_payment_allocations`
--
ALTER TABLE `purchase_payment_allocations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_purchase_payment_allocations_payment` (`purchase_payment_id`),
  ADD KEY `idx_purchase_payment_allocations_invoice` (`purchase_invoice_id`);

--
-- Indexes for table `purchase_receipts`
--
ALTER TABLE `purchase_receipts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_purchase_receipts_company_no` (`company_id`,`receipt_no`),
  ADD KEY `idx_purchase_receipts_supplier` (`supplier_party_id`),
  ADD KEY `idx_purchase_receipts_date` (`receipt_date`),
  ADD KEY `idx_purchase_receipts_status` (`receipt_status`),
  ADD KEY `fk_purchase_receipts_branch` (`branch_id`),
  ADD KEY `fk_purchase_receipts_location` (`location_id`),
  ADD KEY `fk_purchase_receipts_financial_year` (`financial_year_id`),
  ADD KEY `fk_purchase_receipts_document_series` (`document_series_id`),
  ADD KEY `fk_purchase_receipts_order` (`purchase_order_id`),
  ADD KEY `fk_purchase_receipts_warehouse` (`warehouse_id`),
  ADD KEY `fk_purchase_receipts_transporter` (`transporter_party_id`),
  ADD KEY `fk_purchase_receipts_posted_by` (`posted_by`),
  ADD KEY `fk_purchase_receipts_created_by` (`created_by`),
  ADD KEY `fk_purchase_receipts_updated_by` (`updated_by`),
  ADD KEY `fk_purchase_receipts_voucher` (`voucher_id`);

--
-- Indexes for table `purchase_receipt_lines`
--
ALTER TABLE `purchase_receipt_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_purchase_receipt_lines_doc_line` (`purchase_receipt_id`,`line_no`),
  ADD KEY `idx_purchase_receipt_lines_item` (`item_id`),
  ADD KEY `idx_purchase_receipt_lines_warehouse` (`warehouse_id`),
  ADD KEY `fk_purchase_receipt_lines_order_line` (`purchase_order_line_id`),
  ADD KEY `fk_purchase_receipt_lines_uom` (`uom_id`),
  ADD KEY `fk_purchase_receipt_lines_batch` (`batch_id`),
  ADD KEY `fk_purchase_receipt_lines_serial` (`serial_id`);

--
-- Indexes for table `purchase_requisitions`
--
ALTER TABLE `purchase_requisitions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_purchase_requisitions_company_no` (`company_id`,`requisition_no`),
  ADD KEY `idx_purchase_requisitions_date` (`requisition_date`),
  ADD KEY `idx_purchase_requisitions_status` (`requisition_status`),
  ADD KEY `fk_purchase_requisitions_branch` (`branch_id`),
  ADD KEY `fk_purchase_requisitions_location` (`location_id`),
  ADD KEY `fk_purchase_requisitions_financial_year` (`financial_year_id`),
  ADD KEY `fk_purchase_requisitions_document_series` (`document_series_id`),
  ADD KEY `fk_purchase_requisitions_requested_by` (`requested_by`),
  ADD KEY `fk_purchase_requisitions_approved_by` (`approved_by`),
  ADD KEY `fk_purchase_requisitions_created_by` (`created_by`),
  ADD KEY `fk_purchase_requisitions_updated_by` (`updated_by`);

--
-- Indexes for table `purchase_requisition_lines`
--
ALTER TABLE `purchase_requisition_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_purchase_requisition_lines_doc_line` (`purchase_requisition_id`,`line_no`),
  ADD KEY `idx_purchase_requisition_lines_item` (`item_id`),
  ADD KEY `idx_purchase_requisition_lines_warehouse` (`warehouse_id`),
  ADD KEY `fk_purchase_requisition_lines_uom` (`uom_id`);

--
-- Indexes for table `purchase_returns`
--
ALTER TABLE `purchase_returns`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_purchase_returns_company_no` (`company_id`,`return_no`),
  ADD KEY `idx_purchase_returns_supplier` (`supplier_party_id`),
  ADD KEY `idx_purchase_returns_date` (`return_date`),
  ADD KEY `idx_purchase_returns_status` (`return_status`),
  ADD KEY `fk_purchase_returns_branch` (`branch_id`),
  ADD KEY `fk_purchase_returns_location` (`location_id`),
  ADD KEY `fk_purchase_returns_financial_year` (`financial_year_id`),
  ADD KEY `fk_purchase_returns_document_series` (`document_series_id`),
  ADD KEY `fk_purchase_returns_invoice` (`purchase_invoice_id`),
  ADD KEY `fk_purchase_returns_voucher` (`voucher_id`),
  ADD KEY `fk_purchase_returns_posted_by` (`posted_by`),
  ADD KEY `fk_purchase_returns_created_by` (`created_by`),
  ADD KEY `fk_purchase_returns_updated_by` (`updated_by`);

--
-- Indexes for table `purchase_return_lines`
--
ALTER TABLE `purchase_return_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_purchase_return_lines_doc_line` (`purchase_return_id`,`line_no`),
  ADD KEY `idx_purchase_return_lines_item` (`item_id`),
  ADD KEY `idx_purchase_return_lines_warehouse` (`warehouse_id`),
  ADD KEY `fk_purchase_return_lines_invoice_line` (`purchase_invoice_line_id`),
  ADD KEY `fk_purchase_return_lines_uom` (`uom_id`),
  ADD KEY `fk_purchase_return_lines_batch` (`batch_id`),
  ADD KEY `fk_purchase_return_lines_serial` (`serial_id`),
  ADD KEY `fk_purchase_return_lines_tax_code` (`tax_code_id`);

--
-- Indexes for table `qc_inspections`
--
ALTER TABLE `qc_inspections`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_qc_inspections_company_no` (`company_id`,`inspection_no`),
  ADD KEY `idx_qc_inspections_date` (`inspection_date`),
  ADD KEY `idx_qc_inspections_scope` (`inspection_scope`),
  ADD KEY `idx_qc_inspections_source` (`source_document_type`,`source_document_id`),
  ADD KEY `idx_qc_inspections_item` (`item_id`),
  ADD KEY `idx_qc_inspections_status` (`inspection_status`),
  ADD KEY `fk_qc_inspections_branch` (`branch_id`),
  ADD KEY `fk_qc_inspections_location` (`location_id`),
  ADD KEY `fk_qc_inspections_financial_year` (`financial_year_id`),
  ADD KEY `fk_qc_inspections_document_series` (`document_series_id`),
  ADD KEY `fk_qc_inspections_qc_plan` (`qc_plan_id`),
  ADD KEY `fk_qc_inspections_uom` (`uom_id`),
  ADD KEY `fk_qc_inspections_warehouse` (`warehouse_id`),
  ADD KEY `fk_qc_inspections_batch` (`batch_id`),
  ADD KEY `fk_qc_inspections_serial` (`serial_id`),
  ADD KEY `fk_qc_inspections_inspected_by` (`inspected_by`),
  ADD KEY `fk_qc_inspections_approved_by` (`approved_by`),
  ADD KEY `fk_qc_inspections_created_by` (`created_by`),
  ADD KEY `fk_qc_inspections_updated_by` (`updated_by`);

--
-- Indexes for table `qc_inspection_lines`
--
ALTER TABLE `qc_inspection_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_qc_inspection_lines_doc_line` (`qc_inspection_id`,`line_no`),
  ADD KEY `idx_qc_inspection_lines_result` (`result_status`),
  ADD KEY `fk_qc_inspection_lines_plan_line` (`qc_plan_line_id`);

--
-- Indexes for table `qc_non_conformance_logs`
--
ALTER TABLE `qc_non_conformance_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_qc_non_conformance_logs_inspection` (`qc_inspection_id`),
  ADD KEY `idx_qc_non_conformance_logs_severity` (`severity`),
  ADD KEY `idx_qc_non_conformance_logs_status` (`closure_status`),
  ADD KEY `fk_qc_non_conformance_logs_inspection_line` (`qc_inspection_line_id`),
  ADD KEY `fk_qc_non_conformance_logs_assigned_to` (`assigned_to`),
  ADD KEY `fk_qc_non_conformance_logs_closed_by` (`closed_by`),
  ADD KEY `fk_qc_non_conformance_logs_created_by` (`created_by`),
  ADD KEY `fk_qc_non_conformance_logs_updated_by` (`updated_by`);

--
-- Indexes for table `qc_plans`
--
ALTER TABLE `qc_plans`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_qc_plans_company_code` (`company_id`,`plan_code`),
  ADD KEY `idx_qc_plans_item` (`item_id`),
  ADD KEY `idx_qc_plans_category` (`item_category_id`),
  ADD KEY `idx_qc_plans_scope` (`qc_scope`),
  ADD KEY `idx_qc_plans_status` (`approval_status`),
  ADD KEY `fk_qc_plans_branch` (`branch_id`),
  ADD KEY `fk_qc_plans_location` (`location_id`),
  ADD KEY `fk_qc_plans_approved_by` (`approved_by`),
  ADD KEY `fk_qc_plans_created_by` (`created_by`),
  ADD KEY `fk_qc_plans_updated_by` (`updated_by`);

--
-- Indexes for table `qc_plan_lines`
--
ALTER TABLE `qc_plan_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_qc_plan_lines_doc_line` (`qc_plan_id`,`line_no`),
  ADD KEY `idx_qc_plan_lines_type` (`checkpoint_type`);

--
-- Indexes for table `qc_result_actions`
--
ALTER TABLE `qc_result_actions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_qc_result_actions_inspection` (`qc_inspection_id`),
  ADD KEY `idx_qc_result_actions_type` (`action_type`),
  ADD KEY `idx_qc_result_actions_status` (`action_status`),
  ADD KEY `fk_qc_result_actions_target_warehouse` (`target_warehouse_id`),
  ADD KEY `fk_qc_result_actions_action_by` (`action_by`);

--
-- Indexes for table `roles`
--
ALTER TABLE `roles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_roles_code` (`code`),
  ADD UNIQUE KEY `uq_roles_name` (`name`),
  ADD KEY `idx_roles_is_system_role` (`is_system_role`),
  ADD KEY `idx_roles_is_active` (`is_active`),
  ADD KEY `fk_roles_created_by` (`created_by`),
  ADD KEY `fk_roles_updated_by` (`updated_by`);

--
-- Indexes for table `role_permissions`
--
ALTER TABLE `role_permissions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_role_permissions_role_permission` (`role_id`,`permission_id`),
  ADD KEY `idx_role_permissions_role_id` (`role_id`),
  ADD KEY `idx_role_permissions_permission_id` (`permission_id`),
  ADD KEY `idx_role_permissions_is_active` (`is_active`),
  ADD KEY `fk_role_permissions_created_by` (`created_by`),
  ADD KEY `fk_role_permissions_updated_by` (`updated_by`);

--
-- Indexes for table `sales_deliveries`
--
ALTER TABLE `sales_deliveries`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_sales_deliveries_company_no` (`company_id`,`delivery_no`),
  ADD KEY `idx_sales_deliveries_customer` (`customer_party_id`),
  ADD KEY `idx_sales_deliveries_date` (`delivery_date`),
  ADD KEY `idx_sales_deliveries_status` (`delivery_status`),
  ADD KEY `fk_sales_deliveries_branch` (`branch_id`),
  ADD KEY `fk_sales_deliveries_location` (`location_id`),
  ADD KEY `fk_sales_deliveries_financial_year` (`financial_year_id`),
  ADD KEY `fk_sales_deliveries_document_series` (`document_series_id`),
  ADD KEY `fk_sales_deliveries_order` (`sales_order_id`),
  ADD KEY `fk_sales_deliveries_billing_address` (`billing_address_id`),
  ADD KEY `fk_sales_deliveries_shipping_address` (`shipping_address_id`),
  ADD KEY `fk_sales_deliveries_contact` (`contact_id`),
  ADD KEY `fk_sales_deliveries_transporter` (`transporter_party_id`),
  ADD KEY `fk_sales_deliveries_posted_by` (`posted_by`),
  ADD KEY `fk_sales_deliveries_created_by` (`created_by`),
  ADD KEY `fk_sales_deliveries_updated_by` (`updated_by`),
  ADD KEY `fk_sales_deliveries_voucher` (`voucher_id`);

--
-- Indexes for table `sales_delivery_lines`
--
ALTER TABLE `sales_delivery_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_sales_delivery_lines_doc_line` (`sales_delivery_id`,`line_no`),
  ADD KEY `idx_sales_delivery_lines_item` (`item_id`),
  ADD KEY `idx_sales_delivery_lines_warehouse` (`warehouse_id`),
  ADD KEY `fk_sales_delivery_lines_order_line` (`sales_order_line_id`),
  ADD KEY `fk_sales_delivery_lines_uom` (`uom_id`),
  ADD KEY `fk_sales_delivery_lines_batch` (`batch_id`),
  ADD KEY `fk_sales_delivery_lines_serial` (`serial_id`);

--
-- Indexes for table `sales_delivery_returnable_dcs`
--
ALTER TABLE `sales_delivery_returnable_dcs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sales_delivery_returnable_dcs_delivery_line_idx` (`sales_delivery_id`,`line_no`),
  ADD KEY `sales_delivery_returnable_dcs_item_fk` (`item_id`),
  ADD KEY `sales_delivery_returnable_dcs_uom_fk` (`uom_id`);

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
-- Indexes for table `sales_invoice_lines`
--
ALTER TABLE `sales_invoice_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_sales_invoice_lines_doc_line` (`sales_invoice_id`,`line_no`),
  ADD KEY `idx_sales_invoice_lines_item` (`item_id`),
  ADD KEY `idx_sales_invoice_lines_warehouse` (`warehouse_id`),
  ADD KEY `fk_sales_invoice_lines_order_line` (`sales_order_line_id`),
  ADD KEY `fk_sales_invoice_lines_delivery_line` (`sales_delivery_line_id`),
  ADD KEY `fk_sales_invoice_lines_uom` (`uom_id`),
  ADD KEY `fk_sales_invoice_lines_batch` (`batch_id`),
  ADD KEY `fk_sales_invoice_lines_serial` (`serial_id`),
  ADD KEY `fk_sales_invoice_lines_tax_code` (`tax_code_id`);

--
-- Indexes for table `sales_orders`
--
ALTER TABLE `sales_orders`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_sales_orders_company_no` (`company_id`,`order_no`),
  ADD KEY `idx_sales_orders_customer` (`customer_party_id`),
  ADD KEY `idx_sales_orders_date` (`order_date`),
  ADD KEY `idx_sales_orders_status` (`order_status`),
  ADD KEY `fk_sales_orders_branch` (`branch_id`),
  ADD KEY `fk_sales_orders_location` (`location_id`),
  ADD KEY `fk_sales_orders_financial_year` (`financial_year_id`),
  ADD KEY `fk_sales_orders_document_series` (`document_series_id`),
  ADD KEY `fk_sales_orders_quotation` (`sales_quotation_id`),
  ADD KEY `fk_sales_orders_crm_opportunity` (`crm_opportunity_id`),
  ADD KEY `fk_sales_orders_billing_address` (`billing_address_id`),
  ADD KEY `fk_sales_orders_shipping_address` (`shipping_address_id`),
  ADD KEY `fk_sales_orders_contact` (`contact_id`),
  ADD KEY `fk_sales_orders_approved_by` (`approved_by`),
  ADD KEY `fk_sales_orders_created_by` (`created_by`),
  ADD KEY `fk_sales_orders_updated_by` (`updated_by`);

--
-- Indexes for table `sales_order_lines`
--
ALTER TABLE `sales_order_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_sales_order_lines_doc_line` (`sales_order_id`,`line_no`),
  ADD KEY `idx_sales_order_lines_item` (`item_id`),
  ADD KEY `idx_sales_order_lines_warehouse` (`warehouse_id`),
  ADD KEY `idx_sales_order_lines_status` (`line_status`),
  ADD KEY `fk_sales_order_lines_quotation_line` (`sales_quotation_line_id`),
  ADD KEY `fk_sales_order_lines_uom` (`uom_id`),
  ADD KEY `fk_sales_order_lines_tax_code` (`tax_code_id`);

--
-- Indexes for table `sales_quotations`
--
ALTER TABLE `sales_quotations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_sales_quotations_company_no` (`company_id`,`quotation_no`),
  ADD KEY `idx_sales_quotations_customer` (`customer_party_id`),
  ADD KEY `idx_sales_quotations_date` (`quotation_date`),
  ADD KEY `idx_sales_quotations_status` (`quotation_status`),
  ADD KEY `fk_sales_quotations_branch` (`branch_id`),
  ADD KEY `fk_sales_quotations_location` (`location_id`),
  ADD KEY `fk_sales_quotations_financial_year` (`financial_year_id`),
  ADD KEY `fk_sales_quotations_document_series` (`document_series_id`),
  ADD KEY `fk_sales_quotations_billing_address` (`billing_address_id`),
  ADD KEY `fk_sales_quotations_shipping_address` (`shipping_address_id`),
  ADD KEY `fk_sales_quotations_contact` (`contact_id`),
  ADD KEY `fk_sales_quotations_crm_opportunity` (`crm_opportunity_id`),
  ADD KEY `fk_sales_quotations_approved_by` (`approved_by`),
  ADD KEY `fk_sales_quotations_created_by` (`created_by`),
  ADD KEY `fk_sales_quotations_updated_by` (`updated_by`);

--
-- Indexes for table `sales_quotation_lines`
--
ALTER TABLE `sales_quotation_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_sales_quotation_lines_doc_line` (`sales_quotation_id`,`line_no`),
  ADD KEY `idx_sales_quotation_lines_item` (`item_id`),
  ADD KEY `idx_sales_quotation_lines_warehouse` (`warehouse_id`),
  ADD KEY `fk_sales_quotation_lines_uom` (`uom_id`),
  ADD KEY `fk_sales_quotation_lines_tax_code` (`tax_code_id`);

--
-- Indexes for table `sales_receipts`
--
ALTER TABLE `sales_receipts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_sales_receipts_company_no` (`company_id`,`receipt_no`),
  ADD KEY `idx_sales_receipts_customer` (`customer_party_id`),
  ADD KEY `idx_sales_receipts_date` (`receipt_date`),
  ADD KEY `idx_sales_receipts_status` (`receipt_status`),
  ADD KEY `fk_sales_receipts_branch` (`branch_id`),
  ADD KEY `fk_sales_receipts_location` (`location_id`),
  ADD KEY `fk_sales_receipts_financial_year` (`financial_year_id`),
  ADD KEY `fk_sales_receipts_document_series` (`document_series_id`),
  ADD KEY `fk_sales_receipts_account` (`account_id`),
  ADD KEY `fk_sales_receipts_voucher` (`voucher_id`),
  ADD KEY `fk_sales_receipts_posted_by` (`posted_by`),
  ADD KEY `fk_sales_receipts_created_by` (`created_by`),
  ADD KEY `fk_sales_receipts_updated_by` (`updated_by`);

--
-- Indexes for table `sales_receipt_allocations`
--
ALTER TABLE `sales_receipt_allocations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_sales_receipt_allocations_receipt` (`sales_receipt_id`),
  ADD KEY `idx_sales_receipt_allocations_invoice` (`sales_invoice_id`);

--
-- Indexes for table `sales_returns`
--
ALTER TABLE `sales_returns`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_sales_returns_company_no` (`company_id`,`return_no`),
  ADD KEY `idx_sales_returns_customer` (`customer_party_id`),
  ADD KEY `idx_sales_returns_date` (`return_date`),
  ADD KEY `idx_sales_returns_status` (`return_status`),
  ADD KEY `fk_sales_returns_branch` (`branch_id`),
  ADD KEY `fk_sales_returns_location` (`location_id`),
  ADD KEY `fk_sales_returns_financial_year` (`financial_year_id`),
  ADD KEY `fk_sales_returns_document_series` (`document_series_id`),
  ADD KEY `fk_sales_returns_invoice` (`sales_invoice_id`),
  ADD KEY `fk_sales_returns_voucher` (`voucher_id`),
  ADD KEY `fk_sales_returns_posted_by` (`posted_by`),
  ADD KEY `fk_sales_returns_created_by` (`created_by`),
  ADD KEY `fk_sales_returns_updated_by` (`updated_by`);

--
-- Indexes for table `sales_return_lines`
--
ALTER TABLE `sales_return_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_sales_return_lines_doc_line` (`sales_return_id`,`line_no`),
  ADD KEY `idx_sales_return_lines_item` (`item_id`),
  ADD KEY `idx_sales_return_lines_warehouse` (`warehouse_id`),
  ADD KEY `fk_sales_return_lines_invoice_line` (`sales_invoice_line_id`),
  ADD KEY `fk_sales_return_lines_uom` (`uom_id`),
  ADD KEY `fk_sales_return_lines_batch` (`batch_id`),
  ADD KEY `fk_sales_return_lines_serial` (`serial_id`),
  ADD KEY `fk_sales_return_lines_tax_code` (`tax_code_id`);

--
-- Indexes for table `service_contracts`
--
ALTER TABLE `service_contracts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_service_contracts_company_no` (`company_id`,`contract_no`),
  ADD KEY `idx_service_contracts_customer` (`customer_party_id`),
  ADD KEY `idx_service_contracts_status` (`contract_status`),
  ADD KEY `idx_service_contracts_end_date` (`contract_end_date`),
  ADD KEY `fk_service_contracts_sales_invoice` (`sales_invoice_id`),
  ADD KEY `fk_service_contracts_approved_by` (`approved_by`),
  ADD KEY `fk_service_contracts_created_by` (`created_by`),
  ADD KEY `fk_service_contracts_updated_by` (`updated_by`);

--
-- Indexes for table `service_contract_assets`
--
ALTER TABLE `service_contract_assets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_service_contract_assets_asset` (`asset_id`),
  ADD KEY `idx_service_contract_assets_item` (`item_id`),
  ADD KEY `idx_service_contract_assets_serial` (`serial_id`),
  ADD KEY `fk_service_contract_assets_contract` (`service_contract_id`);

--
-- Indexes for table `service_feedbacks`
--
ALTER TABLE `service_feedbacks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_service_feedbacks_ticket` (`service_ticket_id`),
  ADD KEY `fk_service_feedbacks_work_order` (`service_work_order_id`),
  ADD KEY `fk_service_feedbacks_created_by` (`created_by`);

--
-- Indexes for table `service_tickets`
--
ALTER TABLE `service_tickets`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_service_tickets_company_no` (`company_id`,`ticket_no`),
  ADD KEY `idx_service_tickets_customer` (`customer_party_id`),
  ADD KEY `idx_service_tickets_status` (`ticket_status`),
  ADD KEY `idx_service_tickets_priority` (`priority_level`),
  ADD KEY `idx_service_tickets_assigned_to` (`assigned_to_user_id`),
  ADD KEY `idx_service_tickets_serial` (`serial_id`),
  ADD KEY `fk_service_tickets_branch` (`branch_id`),
  ADD KEY `fk_service_tickets_location` (`location_id`),
  ADD KEY `fk_service_tickets_financial_year` (`financial_year_id`),
  ADD KEY `fk_service_tickets_document_series` (`document_series_id`),
  ADD KEY `fk_service_tickets_service_contract` (`service_contract_id`),
  ADD KEY `fk_service_tickets_service_contract_asset` (`service_contract_asset_id`),
  ADD KEY `fk_service_tickets_asset` (`asset_id`),
  ADD KEY `fk_service_tickets_item` (`item_id`),
  ADD KEY `fk_service_tickets_closed_by` (`closed_by`),
  ADD KEY `fk_service_tickets_created_by` (`created_by`),
  ADD KEY `fk_service_tickets_updated_by` (`updated_by`);

--
-- Indexes for table `service_ticket_activities`
--
ALTER TABLE `service_ticket_activities`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_service_ticket_activities_ticket` (`service_ticket_id`),
  ADD KEY `idx_service_ticket_activities_datetime` (`activity_datetime`),
  ADD KEY `fk_service_ticket_activities_created_by` (`created_by`);

--
-- Indexes for table `service_visit_logs`
--
ALTER TABLE `service_visit_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_service_visit_logs_work_order` (`service_work_order_id`),
  ADD KEY `idx_service_visit_logs_visit_date` (`visit_date`),
  ADD KEY `fk_service_visit_logs_created_by` (`created_by`);

--
-- Indexes for table `service_work_orders`
--
ALTER TABLE `service_work_orders`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_service_work_orders_company_no` (`company_id`,`work_order_no`),
  ADD KEY `idx_service_work_orders_ticket` (`service_ticket_id`),
  ADD KEY `idx_service_work_orders_customer` (`customer_party_id`),
  ADD KEY `idx_service_work_orders_status` (`work_order_status`),
  ADD KEY `idx_service_work_orders_technician` (`technician_user_id`),
  ADD KEY `fk_service_work_orders_branch` (`branch_id`),
  ADD KEY `fk_service_work_orders_location` (`location_id`),
  ADD KEY `fk_service_work_orders_financial_year` (`financial_year_id`),
  ADD KEY `fk_service_work_orders_document_series` (`document_series_id`),
  ADD KEY `fk_service_work_orders_asset` (`asset_id`),
  ADD KEY `fk_service_work_orders_item` (`item_id`),
  ADD KEY `fk_service_work_orders_serial` (`serial_id`),
  ADD KEY `fk_service_work_orders_vendor` (`vendor_party_id`),
  ADD KEY `fk_service_work_orders_completed_by` (`completed_by`),
  ADD KEY `fk_service_work_orders_closed_by` (`closed_by`),
  ADD KEY `fk_service_work_orders_created_by` (`created_by`),
  ADD KEY `fk_service_work_orders_updated_by` (`updated_by`),
  ADD KEY `fk_service_work_orders_voucher` (`voucher_id`);

--
-- Indexes for table `service_work_order_services`
--
ALTER TABLE `service_work_order_services`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_service_work_order_services_doc_line` (`service_work_order_id`,`line_no`),
  ADD KEY `fk_service_work_order_services_vendor` (`vendor_party_id`),
  ADD KEY `fk_service_work_order_services_purchase_invoice` (`purchase_invoice_id`),
  ADD KEY `fk_service_work_order_services_tax_code` (`tax_code_id`);

--
-- Indexes for table `service_work_order_spares`
--
ALTER TABLE `service_work_order_spares`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_service_work_order_spares_doc_line` (`service_work_order_id`,`line_no`),
  ADD KEY `idx_service_work_order_spares_item` (`item_id`),
  ADD KEY `fk_service_work_order_spares_uom` (`uom_id`),
  ADD KEY `fk_service_work_order_spares_warehouse` (`warehouse_id`),
  ADD KEY `fk_service_work_order_spares_batch` (`batch_id`),
  ADD KEY `fk_service_work_order_spares_serial` (`serial_id`);

--
-- Indexes for table `states`
--
ALTER TABLE `states`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_states_code` (`country_code`,`state_code`),
  ADD UNIQUE KEY `uq_states_name` (`country_code`,`state_name`),
  ADD UNIQUE KEY `uq_states_gst_state_code` (`gst_state_code`),
  ADD KEY `idx_states_country` (`country_code`),
  ADD KEY `idx_states_is_active` (`is_active`);

--
-- Indexes for table `stock_adjustments`
--
ALTER TABLE `stock_adjustments`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_stock_adjustments_company_no` (`company_id`,`adjustment_no`),
  ADD KEY `idx_stock_adjustments_date` (`adjustment_date`),
  ADD KEY `idx_stock_adjustments_status` (`adjustment_status`),
  ADD KEY `fk_stock_adjustments_branch` (`branch_id`),
  ADD KEY `fk_stock_adjustments_location` (`location_id`),
  ADD KEY `fk_stock_adjustments_financial_year` (`financial_year_id`),
  ADD KEY `fk_stock_adjustments_document_series` (`document_series_id`),
  ADD KEY `fk_stock_adjustments_posted_by` (`posted_by`),
  ADD KEY `fk_stock_adjustments_created_by` (`created_by`),
  ADD KEY `fk_stock_adjustments_updated_by` (`updated_by`);

--
-- Indexes for table `stock_adjustment_lines`
--
ALTER TABLE `stock_adjustment_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_stock_adjustment_lines_doc_line` (`stock_adjustment_id`,`line_no`),
  ADD KEY `idx_stock_adjustment_lines_item` (`item_id`),
  ADD KEY `idx_stock_adjustment_lines_warehouse` (`warehouse_id`),
  ADD KEY `fk_stock_adjustment_lines_uom` (`uom_id`),
  ADD KEY `fk_stock_adjustment_lines_batch` (`batch_id`),
  ADD KEY `fk_stock_adjustment_lines_serial` (`serial_id`);

--
-- Indexes for table `stock_balances`
--
ALTER TABLE `stock_balances`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_stock_balances_unique` (`company_id`,`branch_id`,`location_id`,`warehouse_id`,`item_id`,`batch_id`,`serial_id`),
  ADD KEY `idx_stock_balances_company_id` (`company_id`),
  ADD KEY `idx_stock_balances_branch_id` (`branch_id`),
  ADD KEY `idx_stock_balances_location_id` (`location_id`),
  ADD KEY `idx_stock_balances_warehouse_id` (`warehouse_id`),
  ADD KEY `idx_stock_balances_item_id` (`item_id`),
  ADD KEY `idx_stock_balances_qty_available` (`qty_available`),
  ADD KEY `fk_stock_balances_updated_by` (`updated_by`),
  ADD KEY `fk_stock_balances_batch` (`batch_id`),
  ADD KEY `fk_stock_balances_serial` (`serial_id`);

--
-- Indexes for table `stock_batches`
--
ALTER TABLE `stock_batches`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_stock_batches_item_warehouse_batch` (`item_id`,`warehouse_id`,`batch_no`),
  ADD KEY `idx_stock_batches_item_id` (`item_id`),
  ADD KEY `idx_stock_batches_warehouse_id` (`warehouse_id`),
  ADD KEY `idx_stock_batches_expiry_date` (`expiry_date`),
  ADD KEY `idx_stock_batches_status` (`status`);

--
-- Indexes for table `stock_damage_entries`
--
ALTER TABLE `stock_damage_entries`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_stock_damage_entries_company_no` (`company_id`,`damage_no`),
  ADD KEY `idx_stock_damage_entries_date` (`damage_date`),
  ADD KEY `idx_stock_damage_entries_status` (`damage_status`),
  ADD KEY `fk_stock_damage_entries_branch` (`branch_id`),
  ADD KEY `fk_stock_damage_entries_location` (`location_id`),
  ADD KEY `fk_stock_damage_entries_financial_year` (`financial_year_id`),
  ADD KEY `fk_stock_damage_entries_document_series` (`document_series_id`),
  ADD KEY `fk_stock_damage_entries_warehouse` (`warehouse_id`),
  ADD KEY `fk_stock_damage_entries_posted_by` (`posted_by`),
  ADD KEY `fk_stock_damage_entries_created_by` (`created_by`),
  ADD KEY `fk_stock_damage_entries_updated_by` (`updated_by`),
  ADD KEY `fk_stock_damage_entries_voucher` (`voucher_id`);

--
-- Indexes for table `stock_damage_lines`
--
ALTER TABLE `stock_damage_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_stock_damage_lines_doc_line` (`stock_damage_entry_id`,`line_no`),
  ADD KEY `idx_stock_damage_lines_item` (`item_id`),
  ADD KEY `fk_stock_damage_lines_uom` (`uom_id`),
  ADD KEY `fk_stock_damage_lines_batch` (`batch_id`),
  ADD KEY `fk_stock_damage_lines_serial` (`serial_id`);

--
-- Indexes for table `stock_issues`
--
ALTER TABLE `stock_issues`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_stock_issues_company_no` (`company_id`,`issue_no`),
  ADD KEY `idx_stock_issues_date` (`issue_date`),
  ADD KEY `idx_stock_issues_status` (`issue_status`),
  ADD KEY `fk_stock_issues_branch` (`branch_id`),
  ADD KEY `fk_stock_issues_location` (`location_id`),
  ADD KEY `fk_stock_issues_financial_year` (`financial_year_id`),
  ADD KEY `fk_stock_issues_document_series` (`document_series_id`),
  ADD KEY `fk_stock_issues_warehouse` (`warehouse_id`),
  ADD KEY `fk_stock_issues_posted_by` (`posted_by`),
  ADD KEY `fk_stock_issues_created_by` (`created_by`),
  ADD KEY `fk_stock_issues_updated_by` (`updated_by`),
  ADD KEY `fk_stock_issues_voucher` (`voucher_id`);

--
-- Indexes for table `stock_issue_lines`
--
ALTER TABLE `stock_issue_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_stock_issue_lines_doc_line` (`stock_issue_id`,`line_no`),
  ADD KEY `idx_stock_issue_lines_item` (`item_id`),
  ADD KEY `fk_stock_issue_lines_uom` (`uom_id`),
  ADD KEY `fk_stock_issue_lines_batch` (`batch_id`),
  ADD KEY `fk_stock_issue_lines_serial` (`serial_id`);

--
-- Indexes for table `stock_movements`
--
ALTER TABLE `stock_movements`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_stock_movements_company_id` (`company_id`),
  ADD KEY `idx_stock_movements_branch_id` (`branch_id`),
  ADD KEY `idx_stock_movements_location_id` (`location_id`),
  ADD KEY `idx_stock_movements_warehouse_id` (`warehouse_id`),
  ADD KEY `idx_stock_movements_financial_year_id` (`financial_year_id`),
  ADD KEY `idx_stock_movements_item_id` (`item_id`),
  ADD KEY `idx_stock_movements_movement_date` (`movement_date`),
  ADD KEY `idx_stock_movements_movement_type` (`movement_type`),
  ADD KEY `idx_stock_movements_reference` (`reference_module`,`reference_table`,`reference_id`),
  ADD KEY `idx_stock_movements_batch_id` (`batch_id`),
  ADD KEY `idx_stock_movements_serial_id` (`serial_id`),
  ADD KEY `fk_stock_movements_uom` (`uom_id`),
  ADD KEY `fk_stock_movements_posted_by` (`posted_by`),
  ADD KEY `fk_stock_movements_cancelled_by` (`cancelled_by`),
  ADD KEY `fk_stock_movements_created_by` (`created_by`),
  ADD KEY `fk_stock_movements_updated_by` (`updated_by`);

--
-- Indexes for table `stock_openings`
--
ALTER TABLE `stock_openings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_stock_openings_company_no` (`company_id`,`opening_no`),
  ADD KEY `idx_stock_openings_date` (`opening_date`),
  ADD KEY `idx_stock_openings_status` (`opening_status`),
  ADD KEY `fk_stock_openings_branch` (`branch_id`),
  ADD KEY `fk_stock_openings_location` (`location_id`),
  ADD KEY `fk_stock_openings_financial_year` (`financial_year_id`),
  ADD KEY `fk_stock_openings_document_series` (`document_series_id`),
  ADD KEY `fk_stock_openings_posted_by` (`posted_by`),
  ADD KEY `fk_stock_openings_created_by` (`created_by`),
  ADD KEY `fk_stock_openings_updated_by` (`updated_by`),
  ADD KEY `fk_stock_openings_voucher` (`voucher_id`);

--
-- Indexes for table `stock_opening_lines`
--
ALTER TABLE `stock_opening_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_stock_opening_lines_doc_line` (`stock_opening_id`,`line_no`),
  ADD KEY `idx_stock_opening_lines_item` (`item_id`),
  ADD KEY `idx_stock_opening_lines_warehouse` (`warehouse_id`),
  ADD KEY `fk_stock_opening_lines_uom` (`uom_id`),
  ADD KEY `fk_stock_opening_lines_batch` (`batch_id`),
  ADD KEY `fk_stock_opening_lines_serial` (`serial_id`),
  ADD KEY `fk_stock_adjustments_voucher` (`voucher_id`);

--
-- Indexes for table `stock_physical_counts`
--
ALTER TABLE `stock_physical_counts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_stock_physical_counts_company_no` (`company_id`,`count_no`),
  ADD KEY `idx_stock_physical_counts_date` (`count_date`),
  ADD KEY `idx_stock_physical_counts_status` (`count_status`),
  ADD KEY `fk_stock_physical_counts_branch` (`branch_id`),
  ADD KEY `fk_stock_physical_counts_location` (`location_id`),
  ADD KEY `fk_stock_physical_counts_financial_year` (`financial_year_id`),
  ADD KEY `fk_stock_physical_counts_document_series` (`document_series_id`),
  ADD KEY `fk_stock_physical_counts_warehouse` (`warehouse_id`),
  ADD KEY `fk_stock_physical_counts_counted_by` (`counted_by`),
  ADD KEY `fk_stock_physical_counts_reconciled_by` (`reconciled_by`),
  ADD KEY `fk_stock_physical_counts_created_by` (`created_by`),
  ADD KEY `fk_stock_physical_counts_updated_by` (`updated_by`),
  ADD KEY `fk_stock_physical_counts_voucher` (`voucher_id`);

--
-- Indexes for table `stock_physical_count_lines`
--
ALTER TABLE `stock_physical_count_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_stock_physical_count_lines_doc_line` (`stock_physical_count_id`,`line_no`),
  ADD KEY `idx_stock_physical_count_lines_item` (`item_id`),
  ADD KEY `fk_stock_physical_count_lines_uom` (`uom_id`),
  ADD KEY `fk_stock_physical_count_lines_batch` (`batch_id`),
  ADD KEY `fk_stock_physical_count_lines_serial` (`serial_id`);

--
-- Indexes for table `stock_receipts_internal`
--
ALTER TABLE `stock_receipts_internal`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_stock_receipts_internal_company_no` (`company_id`,`receipt_no`),
  ADD KEY `idx_stock_receipts_internal_date` (`receipt_date`),
  ADD KEY `idx_stock_receipts_internal_status` (`receipt_status`),
  ADD KEY `fk_stock_receipts_internal_branch` (`branch_id`),
  ADD KEY `fk_stock_receipts_internal_location` (`location_id`),
  ADD KEY `fk_stock_receipts_internal_financial_year` (`financial_year_id`),
  ADD KEY `fk_stock_receipts_internal_document_series` (`document_series_id`),
  ADD KEY `fk_stock_receipts_internal_warehouse` (`warehouse_id`),
  ADD KEY `fk_stock_receipts_internal_posted_by` (`posted_by`),
  ADD KEY `fk_stock_receipts_internal_created_by` (`created_by`),
  ADD KEY `fk_stock_receipts_internal_updated_by` (`updated_by`),
  ADD KEY `fk_stock_receipts_internal_voucher` (`voucher_id`);

--
-- Indexes for table `stock_receipt_internal_lines`
--
ALTER TABLE `stock_receipt_internal_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_stock_receipt_internal_lines_doc_line` (`stock_receipt_internal_id`,`line_no`),
  ADD KEY `idx_stock_receipt_internal_lines_item` (`item_id`),
  ADD KEY `fk_stock_receipt_internal_lines_uom` (`uom_id`),
  ADD KEY `fk_stock_receipt_internal_lines_batch` (`batch_id`),
  ADD KEY `fk_stock_receipt_internal_lines_serial` (`serial_id`);

--
-- Indexes for table `stock_reservations`
--
ALTER TABLE `stock_reservations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `stock_serials`
--
ALTER TABLE `stock_serials`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_stock_serials_item_serial` (`item_id`,`serial_no`),
  ADD KEY `idx_stock_serials_item_id` (`item_id`),
  ADD KEY `idx_stock_serials_warehouse_id` (`warehouse_id`),
  ADD KEY `idx_stock_serials_batch_id` (`batch_id`),
  ADD KEY `idx_stock_serials_status` (`status`);

--
-- Indexes for table `stock_transfers`
--
ALTER TABLE `stock_transfers`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_stock_transfers_company_no` (`company_id`,`transfer_no`),
  ADD KEY `idx_stock_transfers_date` (`transfer_date`),
  ADD KEY `idx_stock_transfers_status` (`transfer_status`),
  ADD KEY `fk_stock_transfers_branch` (`branch_id`),
  ADD KEY `fk_stock_transfers_location` (`location_id`),
  ADD KEY `fk_stock_transfers_financial_year` (`financial_year_id`),
  ADD KEY `fk_stock_transfers_document_series` (`document_series_id`),
  ADD KEY `fk_stock_transfers_from_warehouse` (`from_warehouse_id`),
  ADD KEY `fk_stock_transfers_to_warehouse` (`to_warehouse_id`),
  ADD KEY `fk_stock_transfers_posted_by` (`posted_by`),
  ADD KEY `fk_stock_transfers_received_by` (`received_by`),
  ADD KEY `fk_stock_transfers_created_by` (`created_by`),
  ADD KEY `fk_stock_transfers_updated_by` (`updated_by`),
  ADD KEY `fk_stock_transfers_voucher` (`voucher_id`);

--
-- Indexes for table `stock_transfer_lines`
--
ALTER TABLE `stock_transfer_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_stock_transfer_lines_doc_line` (`stock_transfer_id`,`line_no`),
  ADD KEY `idx_stock_transfer_lines_item` (`item_id`),
  ADD KEY `fk_stock_transfer_lines_uom` (`uom_id`),
  ADD KEY `fk_stock_transfer_lines_from_batch` (`from_batch_id`),
  ADD KEY `fk_stock_transfer_lines_to_batch` (`to_batch_id`),
  ADD KEY `fk_stock_transfer_lines_from_serial` (`from_serial_id`),
  ADD KEY `fk_stock_transfer_lines_to_serial` (`to_serial_id`);

--
-- Indexes for table `tax_codes`
--
ALTER TABLE `tax_codes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_tax_codes_code` (`tax_code`),
  ADD UNIQUE KEY `uq_tax_codes_name` (`tax_name`),
  ADD KEY `idx_tax_codes_type` (`tax_type`),
  ADD KEY `idx_tax_codes_rate` (`tax_rate`),
  ADD KEY `idx_tax_codes_cess_rate` (`cess_rate`),
  ADD KEY `idx_tax_codes_hsn_sac_code` (`hsn_sac_code`),
  ADD KEY `idx_tax_codes_is_active` (`is_active`),
  ADD KEY `fk_tax_codes_created_by` (`created_by`),
  ADD KEY `fk_tax_codes_updated_by` (`updated_by`);

--
-- Indexes for table `uoms`
--
ALTER TABLE `uoms`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_uoms_code` (`uom_code`),
  ADD UNIQUE KEY `uq_uoms_name` (`uom_name`),
  ADD UNIQUE KEY `uq_uoms_symbol` (`symbol`),
  ADD KEY `idx_uoms_is_active` (`is_active`),
  ADD KEY `fk_uoms_created_by` (`created_by`),
  ADD KEY `fk_uoms_updated_by` (`updated_by`);

--
-- Indexes for table `uom_conversions`
--
ALTER TABLE `uom_conversions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_uom_conversions_pair` (`from_uom_id`,`to_uom_id`),
  ADD KEY `idx_uom_conversions_from_uom` (`from_uom_id`),
  ADD KEY `idx_uom_conversions_to_uom` (`to_uom_id`),
  ADD KEY `fk_uom_conversions_created_by` (`created_by`),
  ADD KEY `fk_uom_conversions_updated_by` (`updated_by`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_users_username` (`username`),
  ADD UNIQUE KEY `uq_users_email` (`email`),
  ADD UNIQUE KEY `uq_users_mobile` (`mobile`),
  ADD UNIQUE KEY `uq_users_employee_id` (`employee_id`),
  ADD UNIQUE KEY `uq_users_employee_code` (`employee_code`),
  ADD KEY `idx_users_employee_id` (`employee_id`),
  ADD KEY `idx_users_first_name` (`first_name`),
  ADD KEY `idx_users_last_name` (`last_name`),
  ADD KEY `idx_users_display_name` (`display_name`),
  ADD KEY `idx_users_status` (`status`),
  ADD KEY `idx_users_is_super_admin` (`is_super_admin`),
  ADD KEY `fk_users_created_by` (`created_by`),
  ADD KEY `fk_users_updated_by` (`updated_by`);

--
-- Indexes for table `user_branch_access`
--
ALTER TABLE `user_branch_access`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_user_branch_access` (`user_id`,`branch_id`),
  ADD KEY `idx_user_branch_access_user_id` (`user_id`),
  ADD KEY `idx_user_branch_access_branch_id` (`branch_id`),
  ADD KEY `idx_user_branch_access_is_default` (`is_default`),
  ADD KEY `idx_user_branch_access_is_active` (`is_active`),
  ADD KEY `fk_user_branch_access_created_by` (`created_by`),
  ADD KEY `fk_user_branch_access_updated_by` (`updated_by`);

--
-- Indexes for table `user_company_access`
--
ALTER TABLE `user_company_access`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_user_company_access` (`user_id`,`company_id`),
  ADD KEY `idx_user_company_access_user_id` (`user_id`),
  ADD KEY `idx_user_company_access_company_id` (`company_id`),
  ADD KEY `idx_user_company_access_is_default` (`is_default`),
  ADD KEY `idx_user_company_access_is_active` (`is_active`),
  ADD KEY `fk_user_company_access_created_by` (`created_by`),
  ADD KEY `fk_user_company_access_updated_by` (`updated_by`);

--
-- Indexes for table `user_location_access`
--
ALTER TABLE `user_location_access`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_user_location_access` (`user_id`,`location_id`),
  ADD KEY `idx_user_location_access_user_id` (`user_id`),
  ADD KEY `idx_user_location_access_location_id` (`location_id`),
  ADD KEY `idx_user_location_access_is_default` (`is_default`),
  ADD KEY `idx_user_location_access_is_active` (`is_active`),
  ADD KEY `fk_user_location_access_created_by` (`created_by`),
  ADD KEY `fk_user_location_access_updated_by` (`updated_by`);

--
-- Indexes for table `user_module_preferences`
--
ALTER TABLE `user_module_preferences`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_user_module_preferences_user_module` (`user_id`,`module_code`),
  ADD KEY `idx_user_module_preferences_sort_order` (`sort_order`),
  ADD KEY `idx_user_module_preferences_is_hidden` (`is_hidden`),
  ADD KEY `fk_user_module_preferences_module` (`module_code`),
  ADD KEY `fk_user_module_preferences_created_by` (`created_by`),
  ADD KEY `fk_user_module_preferences_updated_by` (`updated_by`);

--
-- Indexes for table `user_permissions`
--
ALTER TABLE `user_permissions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_user_permissions_user_permission` (`user_id`,`permission_id`),
  ADD KEY `idx_user_permissions_user_id` (`user_id`),
  ADD KEY `idx_user_permissions_permission_id` (`permission_id`),
  ADD KEY `idx_user_permissions_is_active` (`is_active`),
  ADD KEY `fk_user_permissions_created_by` (`created_by`),
  ADD KEY `fk_user_permissions_updated_by` (`updated_by`);

--
-- Indexes for table `user_roles`
--
ALTER TABLE `user_roles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_user_roles_user_role` (`user_id`,`role_id`),
  ADD KEY `idx_user_roles_user_id` (`user_id`),
  ADD KEY `idx_user_roles_role_id` (`role_id`),
  ADD KEY `idx_user_roles_is_primary_role` (`is_primary_role`),
  ADD KEY `idx_user_roles_is_active` (`is_active`),
  ADD KEY `fk_user_roles_assigned_by` (`assigned_by`),
  ADD KEY `fk_user_roles_created_by` (`created_by`),
  ADD KEY `fk_user_roles_updated_by` (`updated_by`);

--
-- Indexes for table `user_warehouse_access`
--
ALTER TABLE `user_warehouse_access`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_user_warehouse_access` (`user_id`,`warehouse_id`),
  ADD KEY `idx_user_warehouse_access_user_id` (`user_id`),
  ADD KEY `idx_user_warehouse_access_warehouse_id` (`warehouse_id`),
  ADD KEY `idx_user_warehouse_access_is_default` (`is_default`),
  ADD KEY `idx_user_warehouse_access_is_active` (`is_active`),
  ADD KEY `fk_user_warehouse_access_created_by` (`created_by`),
  ADD KEY `fk_user_warehouse_access_updated_by` (`updated_by`);

--
-- Indexes for table `vouchers`
--
ALTER TABLE `vouchers`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_vouchers_company_no` (`company_id`,`voucher_no`),
  ADD KEY `idx_vouchers_company_id` (`company_id`),
  ADD KEY `idx_vouchers_branch_id` (`branch_id`),
  ADD KEY `idx_vouchers_location_id` (`location_id`),
  ADD KEY `idx_vouchers_financial_year_id` (`financial_year_id`),
  ADD KEY `idx_vouchers_voucher_type_id` (`voucher_type_id`),
  ADD KEY `idx_vouchers_voucher_date` (`voucher_date`),
  ADD KEY `idx_vouchers_posting_status` (`posting_status`),
  ADD KEY `idx_vouchers_approval_status` (`approval_status`),
  ADD KEY `idx_vouchers_source` (`source_module`,`source_table`,`source_id`),
  ADD KEY `fk_vouchers_document_series` (`document_series_id`),
  ADD KEY `fk_vouchers_adjustment_account` (`adjustment_account_id`),
  ADD KEY `fk_vouchers_approved_by` (`approved_by`),
  ADD KEY `fk_vouchers_posted_by` (`posted_by`),
  ADD KEY `fk_vouchers_cancelled_by` (`cancelled_by`),
  ADD KEY `fk_vouchers_created_by` (`created_by`),
  ADD KEY `fk_vouchers_updated_by` (`updated_by`);

--
-- Indexes for table `voucher_allocations`
--
ALTER TABLE `voucher_allocations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_voucher_allocations_voucher_line_id` (`voucher_line_id`),
  ADD KEY `idx_voucher_allocations_against_voucher_id` (`against_voucher_id`),
  ADD KEY `idx_voucher_allocations_reference_no` (`reference_no`),
  ADD KEY `fk_voucher_allocations_against_voucher_line` (`against_voucher_line_id`);

--
-- Indexes for table `voucher_lines`
--
ALTER TABLE `voucher_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_voucher_lines_voucher_line` (`voucher_id`,`line_no`),
  ADD KEY `idx_voucher_lines_voucher_id` (`voucher_id`),
  ADD KEY `idx_voucher_lines_account_id` (`account_id`),
  ADD KEY `idx_voucher_lines_party_id` (`party_id`),
  ADD KEY `idx_voucher_lines_entry_type` (`entry_type`),
  ADD KEY `idx_voucher_lines_bill_reference_no` (`bill_reference_no`);

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
-- AUTO_INCREMENT for table `accounts`
--
ALTER TABLE `accounts`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=100;

--
-- AUTO_INCREMENT for table `account_groups`
--
ALTER TABLE `account_groups`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT for table `amc_contracts`
--
ALTER TABLE `amc_contracts`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `amc_contract_assets`
--
ALTER TABLE `amc_contract_assets`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `assets`
--
ALTER TABLE `assets`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `asset_books`
--
ALTER TABLE `asset_books`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `asset_categories`
--
ALTER TABLE `asset_categories`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `asset_depreciation_lines`
--
ALTER TABLE `asset_depreciation_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `asset_depreciation_runs`
--
ALTER TABLE `asset_depreciation_runs`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `asset_disposals`
--
ALTER TABLE `asset_disposals`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `asset_downtime_logs`
--
ALTER TABLE `asset_downtime_logs`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `asset_transfers`
--
ALTER TABLE `asset_transfers`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `asset_transfer_lines`
--
ALTER TABLE `asset_transfer_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `attendance_records`
--
ALTER TABLE `attendance_records`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `audit_logs`
--
ALTER TABLE `audit_logs`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `bank_reconciliation`
--
ALTER TABLE `bank_reconciliation`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `boms`
--
ALTER TABLE `boms`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `bom_lines`
--
ALTER TABLE `bom_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `bom_operations`
--
ALTER TABLE `bom_operations`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `branches`
--
ALTER TABLE `branches`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `brands`
--
ALTER TABLE `brands`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `budgets`
--
ALTER TABLE `budgets`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `budget_lines`
--
ALTER TABLE `budget_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `business_locations`
--
ALTER TABLE `business_locations`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `cash_sessions`
--
ALTER TABLE `cash_sessions`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `companies`
--
ALTER TABLE `companies`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `cost_centers`
--
ALTER TABLE `cost_centers`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `crm_enquiry_lines`
--
ALTER TABLE `crm_enquiry_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `crm_followups`
--
ALTER TABLE `crm_followups`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `crm_leads`
--
ALTER TABLE `crm_leads`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `crm_lead_activities`
--
ALTER TABLE `crm_lead_activities`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `crm_opportunities`
--
ALTER TABLE `crm_opportunities`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `crm_opportunity_products`
--
ALTER TABLE `crm_opportunity_products`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `crm_sources`
--
ALTER TABLE `crm_sources`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `crm_stages`
--
ALTER TABLE `crm_stages`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `departments`
--
ALTER TABLE `departments`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `designations`
--
ALTER TABLE `designations`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT for table `document_postings`
--
ALTER TABLE `document_postings`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=81;

--
-- AUTO_INCREMENT for table `document_posting_lines`
--
ALTER TABLE `document_posting_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=222;

--
-- AUTO_INCREMENT for table `document_series`
--
ALTER TABLE `document_series`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=46;

--
-- AUTO_INCREMENT for table `document_tax_lines`
--
ALTER TABLE `document_tax_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=195;

--
-- AUTO_INCREMENT for table `email_messages`
--
ALTER TABLE `email_messages`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `email_module_settings`
--
ALTER TABLE `email_module_settings`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `email_rules`
--
ALTER TABLE `email_rules`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `email_settings`
--
ALTER TABLE `email_settings`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `email_templates`
--
ALTER TABLE `email_templates`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `employees`
--
ALTER TABLE `employees`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT for table `employee_accounts`
--
ALTER TABLE `employee_accounts`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=45;

--
-- AUTO_INCREMENT for table `employee_addresses`
--
ALTER TABLE `employee_addresses`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=238;

--
-- AUTO_INCREMENT for table `employee_relations`
--
ALTER TABLE `employee_relations`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=625;

--
-- AUTO_INCREMENT for table `employee_salary_components`
--
ALTER TABLE `employee_salary_components`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=487;

--
-- AUTO_INCREMENT for table `employee_salary_structures`
--
ALTER TABLE `employee_salary_structures`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=152;

--
-- AUTO_INCREMENT for table `expense_claims`
--
ALTER TABLE `expense_claims`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `expense_claim_lines`
--
ALTER TABLE `expense_claim_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `financial_years`
--
ALTER TABLE `financial_years`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `gst_registrations`
--
ALTER TABLE `gst_registrations`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `gst_tax_rules`
--
ALTER TABLE `gst_tax_rules`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `hr_statutory_esi`
--
ALTER TABLE `hr_statutory_esi`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `hr_statutory_pf`
--
ALTER TABLE `hr_statutory_pf`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `hr_statutory_profiles`
--
ALTER TABLE `hr_statutory_profiles`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `hr_statutory_pt_slabs`
--
ALTER TABLE `hr_statutory_pt_slabs`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `items`
--
ALTER TABLE `items`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=42;

--
-- AUTO_INCREMENT for table `item_alternates`
--
ALTER TABLE `item_alternates`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `item_categories`
--
ALTER TABLE `item_categories`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `item_planning_policies`
--
ALTER TABLE `item_planning_policies`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `item_prices`
--
ALTER TABLE `item_prices`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT for table `item_supplier_map`
--
ALTER TABLE `item_supplier_map`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `jobwork_charges`
--
ALTER TABLE `jobwork_charges`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jobwork_charge_lines`
--
ALTER TABLE `jobwork_charge_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jobwork_dispatches`
--
ALTER TABLE `jobwork_dispatches`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jobwork_dispatch_lines`
--
ALTER TABLE `jobwork_dispatch_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jobwork_orders`
--
ALTER TABLE `jobwork_orders`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `jobwork_order_materials`
--
ALTER TABLE `jobwork_order_materials`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `jobwork_order_outputs`
--
ALTER TABLE `jobwork_order_outputs`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `jobwork_receipts`
--
ALTER TABLE `jobwork_receipts`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jobwork_receipt_lines`
--
ALTER TABLE `jobwork_receipt_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `leave_requests`
--
ALTER TABLE `leave_requests`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `leave_types`
--
ALTER TABLE `leave_types`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `login_history`
--
ALTER TABLE `login_history`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=485;

--
-- AUTO_INCREMENT for table `maintenance_plans`
--
ALTER TABLE `maintenance_plans`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `maintenance_plan_assets`
--
ALTER TABLE `maintenance_plan_assets`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `maintenance_requests`
--
ALTER TABLE `maintenance_requests`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `maintenance_work_orders`
--
ALTER TABLE `maintenance_work_orders`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `maintenance_work_order_services`
--
ALTER TABLE `maintenance_work_order_services`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `maintenance_work_order_spares`
--
ALTER TABLE `maintenance_work_order_spares`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `media_files`
--
ALTER TABLE `media_files`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT for table `modules`
--
ALTER TABLE `modules`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT for table `mrp_demands`
--
ALTER TABLE `mrp_demands`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `mrp_net_requirements`
--
ALTER TABLE `mrp_net_requirements`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `mrp_recommendations`
--
ALTER TABLE `mrp_recommendations`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `mrp_runs`
--
ALTER TABLE `mrp_runs`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `mrp_supplies`
--
ALTER TABLE `mrp_supplies`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `parties`
--
ALTER TABLE `parties`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=50;

--
-- AUTO_INCREMENT for table `party_accounts`
--
ALTER TABLE `party_accounts`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=145;

--
-- AUTO_INCREMENT for table `party_addresses`
--
ALTER TABLE `party_addresses`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=49;

--
-- AUTO_INCREMENT for table `party_bank_accounts`
--
ALTER TABLE `party_bank_accounts`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `party_contacts`
--
ALTER TABLE `party_contacts`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=47;

--
-- AUTO_INCREMENT for table `party_credit_limits`
--
ALTER TABLE `party_credit_limits`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `party_gst_details`
--
ALTER TABLE `party_gst_details`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- AUTO_INCREMENT for table `party_payment_terms`
--
ALTER TABLE `party_payment_terms`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `party_roles`
--
ALTER TABLE `party_roles`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=50;

--
-- AUTO_INCREMENT for table `party_types`
--
ALTER TABLE `party_types`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `payroll_lines`
--
ALTER TABLE `payroll_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `payroll_runs`
--
ALTER TABLE `payroll_runs`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `payslips`
--
ALTER TABLE `payslips`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `permissions`
--
ALTER TABLE `permissions`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT for table `planning_calendars`
--
ALTER TABLE `planning_calendars`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `posting_rules`
--
ALTER TABLE `posting_rules`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT for table `posting_rule_groups`
--
ALTER TABLE `posting_rule_groups`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `print_templates`
--
ALTER TABLE `print_templates`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `production_material_issues`
--
ALTER TABLE `production_material_issues`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `production_material_issue_lines`
--
ALTER TABLE `production_material_issue_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `production_orders`
--
ALTER TABLE `production_orders`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `production_order_materials`
--
ALTER TABLE `production_order_materials`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `production_order_operations`
--
ALTER TABLE `production_order_operations`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `production_order_outputs`
--
ALTER TABLE `production_order_outputs`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `production_receipts`
--
ALTER TABLE `production_receipts`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `production_receipt_lines`
--
ALTER TABLE `production_receipt_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `projects`
--
ALTER TABLE `projects`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `project_billings`
--
ALTER TABLE `project_billings`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `project_expenses`
--
ALTER TABLE `project_expenses`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `project_milestones`
--
ALTER TABLE `project_milestones`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `project_resource_usages`
--
ALTER TABLE `project_resource_usages`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `project_tasks`
--
ALTER TABLE `project_tasks`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `project_timesheets`
--
ALTER TABLE `project_timesheets`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `project_vendor_works`
--
ALTER TABLE `project_vendor_works`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `purchase_invoices`
--
ALTER TABLE `purchase_invoices`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `purchase_invoice_lines`
--
ALTER TABLE `purchase_invoice_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `purchase_orders`
--
ALTER TABLE `purchase_orders`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `purchase_order_lines`
--
ALTER TABLE `purchase_order_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `purchase_payments`
--
ALTER TABLE `purchase_payments`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `purchase_payment_allocations`
--
ALTER TABLE `purchase_payment_allocations`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `purchase_receipts`
--
ALTER TABLE `purchase_receipts`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `purchase_receipt_lines`
--
ALTER TABLE `purchase_receipt_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `purchase_requisitions`
--
ALTER TABLE `purchase_requisitions`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `purchase_requisition_lines`
--
ALTER TABLE `purchase_requisition_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `purchase_returns`
--
ALTER TABLE `purchase_returns`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `purchase_return_lines`
--
ALTER TABLE `purchase_return_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `qc_inspections`
--
ALTER TABLE `qc_inspections`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `qc_inspection_lines`
--
ALTER TABLE `qc_inspection_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `qc_non_conformance_logs`
--
ALTER TABLE `qc_non_conformance_logs`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `qc_plans`
--
ALTER TABLE `qc_plans`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `qc_plan_lines`
--
ALTER TABLE `qc_plan_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `qc_result_actions`
--
ALTER TABLE `qc_result_actions`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `roles`
--
ALTER TABLE `roles`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `role_permissions`
--
ALTER TABLE `role_permissions`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=96;

--
-- AUTO_INCREMENT for table `sales_deliveries`
--
ALTER TABLE `sales_deliveries`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `sales_delivery_lines`
--
ALTER TABLE `sales_delivery_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=49;

--
-- AUTO_INCREMENT for table `sales_delivery_returnable_dcs`
--
ALTER TABLE `sales_delivery_returnable_dcs`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `sales_invoices`
--
ALTER TABLE `sales_invoices`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=56;

--
-- AUTO_INCREMENT for table `sales_invoice_lines`
--
ALTER TABLE `sales_invoice_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=91;

--
-- AUTO_INCREMENT for table `sales_orders`
--
ALTER TABLE `sales_orders`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `sales_order_lines`
--
ALTER TABLE `sales_order_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- AUTO_INCREMENT for table `sales_quotations`
--
ALTER TABLE `sales_quotations`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `sales_quotation_lines`
--
ALTER TABLE `sales_quotation_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT for table `sales_receipts`
--
ALTER TABLE `sales_receipts`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT for table `sales_receipt_allocations`
--
ALTER TABLE `sales_receipt_allocations`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=38;

--
-- AUTO_INCREMENT for table `sales_returns`
--
ALTER TABLE `sales_returns`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `sales_return_lines`
--
ALTER TABLE `sales_return_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `service_contracts`
--
ALTER TABLE `service_contracts`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `service_contract_assets`
--
ALTER TABLE `service_contract_assets`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `service_feedbacks`
--
ALTER TABLE `service_feedbacks`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `service_tickets`
--
ALTER TABLE `service_tickets`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `service_ticket_activities`
--
ALTER TABLE `service_ticket_activities`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `service_visit_logs`
--
ALTER TABLE `service_visit_logs`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `service_work_orders`
--
ALTER TABLE `service_work_orders`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `service_work_order_services`
--
ALTER TABLE `service_work_order_services`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `service_work_order_spares`
--
ALTER TABLE `service_work_order_spares`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `states`
--
ALTER TABLE `states`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=40;

--
-- AUTO_INCREMENT for table `stock_adjustments`
--
ALTER TABLE `stock_adjustments`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stock_adjustment_lines`
--
ALTER TABLE `stock_adjustment_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stock_balances`
--
ALTER TABLE `stock_balances`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT for table `stock_batches`
--
ALTER TABLE `stock_batches`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `stock_damage_entries`
--
ALTER TABLE `stock_damage_entries`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stock_damage_lines`
--
ALTER TABLE `stock_damage_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stock_issues`
--
ALTER TABLE `stock_issues`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stock_issue_lines`
--
ALTER TABLE `stock_issue_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stock_movements`
--
ALTER TABLE `stock_movements`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=98;

--
-- AUTO_INCREMENT for table `stock_openings`
--
ALTER TABLE `stock_openings`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT for table `stock_opening_lines`
--
ALTER TABLE `stock_opening_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32;

--
-- AUTO_INCREMENT for table `stock_physical_counts`
--
ALTER TABLE `stock_physical_counts`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stock_physical_count_lines`
--
ALTER TABLE `stock_physical_count_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stock_receipts_internal`
--
ALTER TABLE `stock_receipts_internal`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stock_receipt_internal_lines`
--
ALTER TABLE `stock_receipt_internal_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stock_reservations`
--
ALTER TABLE `stock_reservations`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `stock_serials`
--
ALTER TABLE `stock_serials`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `stock_transfers`
--
ALTER TABLE `stock_transfers`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stock_transfer_lines`
--
ALTER TABLE `stock_transfer_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tax_codes`
--
ALTER TABLE `tax_codes`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `uoms`
--
ALTER TABLE `uoms`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `uom_conversions`
--
ALTER TABLE `uom_conversions`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `user_branch_access`
--
ALTER TABLE `user_branch_access`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `user_company_access`
--
ALTER TABLE `user_company_access`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `user_location_access`
--
ALTER TABLE `user_location_access`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `user_module_preferences`
--
ALTER TABLE `user_module_preferences`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_permissions`
--
ALTER TABLE `user_permissions`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=250;

--
-- AUTO_INCREMENT for table `user_roles`
--
ALTER TABLE `user_roles`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `user_warehouse_access`
--
ALTER TABLE `user_warehouse_access`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `vouchers`
--
ALTER TABLE `vouchers`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=117;

--
-- AUTO_INCREMENT for table `voucher_allocations`
--
ALTER TABLE `voucher_allocations`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT for table `voucher_lines`
--
ALTER TABLE `voucher_lines`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=310;

--
-- AUTO_INCREMENT for table `voucher_types`
--
ALTER TABLE `voucher_types`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `warehouses`
--
ALTER TABLE `warehouses`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `accounts`
--
ALTER TABLE `accounts`
  ADD CONSTRAINT `fk_accounts_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_accounts_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_accounts_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_accounts_group` FOREIGN KEY (`account_group_id`) REFERENCES `account_groups` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_accounts_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `account_groups`
--
ALTER TABLE `account_groups`
  ADD CONSTRAINT `fk_account_groups_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_account_groups_parent` FOREIGN KEY (`parent_group_id`) REFERENCES `account_groups` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_account_groups_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `amc_contracts`
--
ALTER TABLE `amc_contracts`
  ADD CONSTRAINT `fk_amc_contracts_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_amc_contracts_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_amc_contracts_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_amc_contracts_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_amc_contracts_vendor` FOREIGN KEY (`vendor_party_id`) REFERENCES `parties` (`id`);

--
-- Constraints for table `amc_contract_assets`
--
ALTER TABLE `amc_contract_assets`
  ADD CONSTRAINT `fk_amc_contract_assets_asset` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`),
  ADD CONSTRAINT `fk_amc_contract_assets_contract` FOREIGN KEY (`amc_contract_id`) REFERENCES `amc_contracts` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `assets`
--
ALTER TABLE `assets`
  ADD CONSTRAINT `fk_assets_accum_dep_account` FOREIGN KEY (`accum_depreciation_account_id`) REFERENCES `accounts` (`id`),
  ADD CONSTRAINT `fk_assets_activated_by` FOREIGN KEY (`activated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_assets_asset_account` FOREIGN KEY (`asset_account_id`) REFERENCES `accounts` (`id`),
  ADD CONSTRAINT `fk_assets_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_assets_category` FOREIGN KEY (`asset_category_id`) REFERENCES `asset_categories` (`id`),
  ADD CONSTRAINT `fk_assets_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_assets_cost_center` FOREIGN KEY (`cost_center_id`) REFERENCES `cost_centers` (`id`),
  ADD CONSTRAINT `fk_assets_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_assets_dep_exp_account` FOREIGN KEY (`depreciation_expense_account_id`) REFERENCES `accounts` (`id`),
  ADD CONSTRAINT `fk_assets_disposed_by` FOREIGN KEY (`disposed_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_assets_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_assets_purchase_invoice` FOREIGN KEY (`purchase_invoice_id`) REFERENCES `purchase_invoices` (`id`),
  ADD CONSTRAINT `fk_assets_supplier` FOREIGN KEY (`supplier_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_assets_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_assets_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `asset_books`
--
ALTER TABLE `asset_books`
  ADD CONSTRAINT `fk_asset_books_asset` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `asset_categories`
--
ALTER TABLE `asset_categories`
  ADD CONSTRAINT `fk_asset_categories_accum_dep_account` FOREIGN KEY (`default_accum_depreciation_account_id`) REFERENCES `accounts` (`id`),
  ADD CONSTRAINT `fk_asset_categories_asset_account` FOREIGN KEY (`default_asset_account_id`) REFERENCES `accounts` (`id`),
  ADD CONSTRAINT `fk_asset_categories_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_asset_categories_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_asset_categories_dep_exp_account` FOREIGN KEY (`default_depreciation_expense_account_id`) REFERENCES `accounts` (`id`),
  ADD CONSTRAINT `fk_asset_categories_disposal_gain_account` FOREIGN KEY (`default_disposal_gain_account_id`) REFERENCES `accounts` (`id`),
  ADD CONSTRAINT `fk_asset_categories_disposal_loss_account` FOREIGN KEY (`default_disposal_loss_account_id`) REFERENCES `accounts` (`id`),
  ADD CONSTRAINT `fk_asset_categories_parent` FOREIGN KEY (`parent_category_id`) REFERENCES `asset_categories` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_asset_categories_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `asset_depreciation_lines`
--
ALTER TABLE `asset_depreciation_lines`
  ADD CONSTRAINT `fk_asset_depreciation_lines_asset` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`),
  ADD CONSTRAINT `fk_asset_depreciation_lines_book` FOREIGN KEY (`asset_book_id`) REFERENCES `asset_books` (`id`),
  ADD CONSTRAINT `fk_asset_depreciation_lines_run` FOREIGN KEY (`asset_depreciation_run_id`) REFERENCES `asset_depreciation_runs` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `asset_depreciation_runs`
--
ALTER TABLE `asset_depreciation_runs`
  ADD CONSTRAINT `fk_asset_depreciation_runs_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_asset_depreciation_runs_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_asset_depreciation_runs_posted_by` FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_asset_depreciation_runs_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`);

--
-- Constraints for table `asset_disposals`
--
ALTER TABLE `asset_disposals`
  ADD CONSTRAINT `fk_asset_disposals_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_asset_disposals_asset` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`),
  ADD CONSTRAINT `fk_asset_disposals_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_asset_disposals_sale_party` FOREIGN KEY (`sale_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_asset_disposals_sales_invoice` FOREIGN KEY (`sales_invoice_id`) REFERENCES `sales_invoices` (`id`),
  ADD CONSTRAINT `fk_asset_disposals_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_asset_disposals_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`);

--
-- Constraints for table `asset_downtime_logs`
--
ALTER TABLE `asset_downtime_logs`
  ADD CONSTRAINT `fk_asset_downtime_logs_asset` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`),
  ADD CONSTRAINT `fk_asset_downtime_logs_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_asset_downtime_logs_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_asset_downtime_logs_work_order` FOREIGN KEY (`maintenance_work_order_id`) REFERENCES `maintenance_work_orders` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `asset_transfers`
--
ALTER TABLE `asset_transfers`
  ADD CONSTRAINT `fk_asset_transfers_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_asset_transfers_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_asset_transfers_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_asset_transfers_from_branch` FOREIGN KEY (`from_branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_asset_transfers_from_location` FOREIGN KEY (`from_location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_asset_transfers_to_branch` FOREIGN KEY (`to_branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_asset_transfers_to_location` FOREIGN KEY (`to_location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_asset_transfers_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_asset_transfers_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`);

--
-- Constraints for table `asset_transfer_lines`
--
ALTER TABLE `asset_transfer_lines`
  ADD CONSTRAINT `fk_asset_transfer_lines_asset` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`),
  ADD CONSTRAINT `fk_asset_transfer_lines_doc` FOREIGN KEY (`asset_transfer_id`) REFERENCES `asset_transfers` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_asset_transfer_lines_from_branch` FOREIGN KEY (`from_branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_asset_transfer_lines_from_location` FOREIGN KEY (`from_location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_asset_transfer_lines_to_branch` FOREIGN KEY (`to_branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_asset_transfer_lines_to_location` FOREIGN KEY (`to_location_id`) REFERENCES `business_locations` (`id`);

--
-- Constraints for table `attendance_records`
--
ALTER TABLE `attendance_records`
  ADD CONSTRAINT `fk_attendance_employee` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`);

--
-- Constraints for table `audit_logs`
--
ALTER TABLE `audit_logs`
  ADD CONSTRAINT `fk_audit_logs_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_audit_logs_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_audit_logs_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_audit_logs_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `bank_reconciliation`
--
ALTER TABLE `bank_reconciliation`
  ADD CONSTRAINT `fk_bank_reconciliation_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_bank_reconciliation_reconciled_by` FOREIGN KEY (`reconciled_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_bank_reconciliation_voucher_line` FOREIGN KEY (`voucher_line_id`) REFERENCES `voucher_lines` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `boms`
--
ALTER TABLE `boms`
  ADD CONSTRAINT `fk_boms_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_boms_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_boms_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_boms_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_boms_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_boms_output_item` FOREIGN KEY (`output_item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_boms_output_uom` FOREIGN KEY (`output_uom_id`) REFERENCES `uoms` (`id`),
  ADD CONSTRAINT `fk_boms_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `bom_lines`
--
ALTER TABLE `bom_lines`
  ADD CONSTRAINT `fk_bom_lines_doc` FOREIGN KEY (`bom_id`) REFERENCES `boms` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_bom_lines_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_bom_lines_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`);

--
-- Constraints for table `bom_operations`
--
ALTER TABLE `bom_operations`
  ADD CONSTRAINT `fk_bom_operations_doc` FOREIGN KEY (`bom_id`) REFERENCES `boms` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `branches`
--
ALTER TABLE `branches`
  ADD CONSTRAINT `fk_branches_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

--
-- Constraints for table `brands`
--
ALTER TABLE `brands`
  ADD CONSTRAINT `fk_brands_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_brands_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `budgets`
--
ALTER TABLE `budgets`
  ADD CONSTRAINT `fk_budgets_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_budgets_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_budgets_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_budgets_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `budget_lines`
--
ALTER TABLE `budget_lines`
  ADD CONSTRAINT `fk_budget_lines_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`),
  ADD CONSTRAINT `fk_budget_lines_budget` FOREIGN KEY (`budget_id`) REFERENCES `budgets` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `business_locations`
--
ALTER TABLE `business_locations`
  ADD CONSTRAINT `fk_locations_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_locations_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

--
-- Constraints for table `cash_sessions`
--
ALTER TABLE `cash_sessions`
  ADD CONSTRAINT `fk_cash_sessions_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_cash_sessions_cash_account` FOREIGN KEY (`cash_account_id`) REFERENCES `accounts` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_cash_sessions_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_cash_sessions_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_cash_sessions_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_cash_sessions_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_cash_sessions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

--
-- Constraints for table `cost_centers`
--
ALTER TABLE `cost_centers`
  ADD CONSTRAINT `fk_cost_centers_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_cost_centers_parent` FOREIGN KEY (`parent_id`) REFERENCES `cost_centers` (`id`);

--
-- Constraints for table `crm_enquiry_lines`
--
ALTER TABLE `crm_enquiry_lines`
  ADD CONSTRAINT `fk_crm_enquiry_lines_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_crm_enquiry_lines_opportunity` FOREIGN KEY (`enquiry_id`) REFERENCES `crm_opportunities` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `crm_followups`
--
ALTER TABLE `crm_followups`
  ADD CONSTRAINT `fk_crm_followups_opportunity` FOREIGN KEY (`enquiry_id`) REFERENCES `crm_opportunities` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `crm_leads`
--
ALTER TABLE `crm_leads`
  ADD CONSTRAINT `fk_crm_leads_assigned` FOREIGN KEY (`assigned_to`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_crm_leads_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_crm_leads_source` FOREIGN KEY (`source_id`) REFERENCES `crm_sources` (`id`);

--
-- Constraints for table `crm_lead_activities`
--
ALTER TABLE `crm_lead_activities`
  ADD CONSTRAINT `fk_crm_lead_activities_lead` FOREIGN KEY (`lead_id`) REFERENCES `crm_leads` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `crm_opportunities`
--
ALTER TABLE `crm_opportunities`
  ADD CONSTRAINT `fk_crm_opportunities_assigned` FOREIGN KEY (`assigned_to`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_crm_opportunities_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_crm_opportunities_customer` FOREIGN KEY (`customer_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_crm_opportunities_lead` FOREIGN KEY (`lead_id`) REFERENCES `crm_leads` (`id`),
  ADD CONSTRAINT `fk_crm_opportunities_stage` FOREIGN KEY (`stage_id`) REFERENCES `crm_stages` (`id`);

--
-- Constraints for table `crm_opportunity_products`
--
ALTER TABLE `crm_opportunity_products`
  ADD CONSTRAINT `fk_crm_opportunity_products_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_crm_opportunity_products_opportunity` FOREIGN KEY (`opportunity_id`) REFERENCES `crm_opportunities` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `document_postings`
--
ALTER TABLE `document_postings`
  ADD CONSTRAINT `fk_document_postings_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_document_postings_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_document_postings_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_document_postings_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_document_postings_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_document_postings_posting_rule_group` FOREIGN KEY (`posting_rule_group_id`) REFERENCES `posting_rule_groups` (`id`),
  ADD CONSTRAINT `fk_document_postings_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_document_postings_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`);

--
-- Constraints for table `document_posting_lines`
--
ALTER TABLE `document_posting_lines`
  ADD CONSTRAINT `fk_document_posting_lines_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`),
  ADD CONSTRAINT `fk_document_posting_lines_doc` FOREIGN KEY (`document_posting_id`) REFERENCES `document_postings` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_document_posting_lines_rule` FOREIGN KEY (`source_rule_id`) REFERENCES `posting_rules` (`id`);

--
-- Constraints for table `document_series`
--
ALTER TABLE `document_series`
  ADD CONSTRAINT `fk_document_series_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_document_series_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_document_series_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_document_series_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

--
-- Constraints for table `document_tax_lines`
--
ALTER TABLE `document_tax_lines`
  ADD CONSTRAINT `fk_document_tax_lines_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_document_tax_lines_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_document_tax_lines_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_document_tax_lines_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_document_tax_lines_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_document_tax_lines_tax_code` FOREIGN KEY (`tax_code_id`) REFERENCES `tax_codes` (`id`);

--
-- Constraints for table `email_messages`
--
ALTER TABLE `email_messages`
  ADD CONSTRAINT `fk_email_messages_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_email_messages_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_email_messages_rule` FOREIGN KEY (`email_rule_id`) REFERENCES `email_rules` (`id`),
  ADD CONSTRAINT `fk_email_messages_setting` FOREIGN KEY (`email_setting_id`) REFERENCES `email_settings` (`id`),
  ADD CONSTRAINT `fk_email_messages_template` FOREIGN KEY (`email_template_id`) REFERENCES `email_templates` (`id`);

--
-- Constraints for table `email_module_settings`
--
ALTER TABLE `email_module_settings`
  ADD CONSTRAINT `fk_email_module_settings_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_email_module_settings_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_email_module_settings_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `email_rules`
--
ALTER TABLE `email_rules`
  ADD CONSTRAINT `fk_email_rules_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_email_rules_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_email_rules_template` FOREIGN KEY (`template_id`) REFERENCES `email_templates` (`id`),
  ADD CONSTRAINT `fk_email_rules_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `email_settings`
--
ALTER TABLE `email_settings`
  ADD CONSTRAINT `fk_email_settings_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_email_settings_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_email_settings_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `email_templates`
--
ALTER TABLE `email_templates`
  ADD CONSTRAINT `fk_email_templates_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_email_templates_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_email_templates_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `employees`
--
ALTER TABLE `employees`
  ADD CONSTRAINT `fk_employees_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_employees_cost_center` FOREIGN KEY (`cost_center_id`) REFERENCES `cost_centers` (`id`),
  ADD CONSTRAINT `fk_employees_department` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`),
  ADD CONSTRAINT `fk_employees_designation` FOREIGN KEY (`designation_id`) REFERENCES `designations` (`id`);

--
-- Constraints for table `employee_accounts`
--
ALTER TABLE `employee_accounts`
  ADD CONSTRAINT `fk_employee_accounts_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_employee_accounts_employee` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `employee_addresses`
--
ALTER TABLE `employee_addresses`
  ADD CONSTRAINT `fk_employee_addresses_employee` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `employee_relations`
--
ALTER TABLE `employee_relations`
  ADD CONSTRAINT `fk_employee_relations_employee` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `employee_salary_components`
--
ALTER TABLE `employee_salary_components`
  ADD CONSTRAINT `fk_salary_components_struct` FOREIGN KEY (`salary_structure_id`) REFERENCES `employee_salary_structures` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `employee_salary_structures`
--
ALTER TABLE `employee_salary_structures`
  ADD CONSTRAINT `fk_salary_struct_employee` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`);

--
-- Constraints for table `expense_claims`
--
ALTER TABLE `expense_claims`
  ADD CONSTRAINT `fk_expense_claims_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_expense_claims_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_expense_claims_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_expense_claims_employee` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`),
  ADD CONSTRAINT `fk_expense_claims_reimbursed_by` FOREIGN KEY (`reimbursed_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_expense_claims_reimbursement_voucher` FOREIGN KEY (`reimbursement_voucher_id`) REFERENCES `vouchers` (`id`),
  ADD CONSTRAINT `fk_expense_claims_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_expense_claims_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`);

--
-- Constraints for table `expense_claim_lines`
--
ALTER TABLE `expense_claim_lines`
  ADD CONSTRAINT `fk_expense_claim_lines_doc` FOREIGN KEY (`expense_claim_id`) REFERENCES `expense_claims` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_expense_claim_lines_project` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_expense_claim_lines_project_task` FOREIGN KEY (`project_task_id`) REFERENCES `project_tasks` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `financial_years`
--
ALTER TABLE `financial_years`
  ADD CONSTRAINT `fk_financial_years_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

--
-- Constraints for table `gst_registrations`
--
ALTER TABLE `gst_registrations`
  ADD CONSTRAINT `fk_gst_registrations_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_gst_registrations_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_gst_registrations_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_gst_registrations_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_gst_registrations_state` FOREIGN KEY (`state_id`) REFERENCES `states` (`id`),
  ADD CONSTRAINT `fk_gst_registrations_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `gst_tax_rules`
--
ALTER TABLE `gst_tax_rules`
  ADD CONSTRAINT `fk_gst_tax_rules_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_gst_tax_rules_tax_code` FOREIGN KEY (`tax_code_id`) REFERENCES `tax_codes` (`id`),
  ADD CONSTRAINT `fk_gst_tax_rules_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `hr_statutory_esi`
--
ALTER TABLE `hr_statutory_esi`
  ADD CONSTRAINT `fk_hr_esi_profile` FOREIGN KEY (`statutory_profile_id`) REFERENCES `hr_statutory_profiles` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `hr_statutory_pf`
--
ALTER TABLE `hr_statutory_pf`
  ADD CONSTRAINT `fk_hr_pf_profile` FOREIGN KEY (`statutory_profile_id`) REFERENCES `hr_statutory_profiles` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `hr_statutory_profiles`
--
ALTER TABLE `hr_statutory_profiles`
  ADD CONSTRAINT `fk_hr_stat_prof_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `hr_statutory_pt_slabs`
--
ALTER TABLE `hr_statutory_pt_slabs`
  ADD CONSTRAINT `fk_hr_pt_profile` FOREIGN KEY (`statutory_profile_id`) REFERENCES `hr_statutory_profiles` (`id`) ON DELETE CASCADE;

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

--
-- Constraints for table `item_alternates`
--
ALTER TABLE `item_alternates`
  ADD CONSTRAINT `fk_item_alternates_alternate_item` FOREIGN KEY (`alternate_item_id`) REFERENCES `items` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_item_alternates_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_item_alternates_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_item_alternates_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `item_categories`
--
ALTER TABLE `item_categories`
  ADD CONSTRAINT `fk_item_categories_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_item_categories_parent` FOREIGN KEY (`parent_category_id`) REFERENCES `item_categories` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_item_categories_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `item_planning_policies`
--
ALTER TABLE `item_planning_policies`
  ADD CONSTRAINT `fk_item_planning_policies_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_item_planning_policies_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_item_planning_policies_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_item_planning_policies_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_item_planning_policies_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_item_planning_policies_preferred_bom` FOREIGN KEY (`preferred_bom_id`) REFERENCES `boms` (`id`),
  ADD CONSTRAINT `fk_item_planning_policies_preferred_supplier` FOREIGN KEY (`preferred_supplier_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_item_planning_policies_preferred_warehouse` FOREIGN KEY (`preferred_warehouse_id`) REFERENCES `warehouses` (`id`),
  ADD CONSTRAINT `fk_item_planning_policies_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_item_planning_policies_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `item_prices`
--
ALTER TABLE `item_prices`
  ADD CONSTRAINT `fk_item_prices_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_item_prices_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_item_prices_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_item_prices_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `item_supplier_map`
--
ALTER TABLE `item_supplier_map`
  ADD CONSTRAINT `fk_item_supplier_map_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_item_supplier_map_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_item_supplier_map_purchase_uom` FOREIGN KEY (`purchase_uom_id`) REFERENCES `uoms` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_item_supplier_map_supplier` FOREIGN KEY (`supplier_party_id`) REFERENCES `parties` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_item_supplier_map_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `jobwork_charges`
--
ALTER TABLE `jobwork_charges`
  ADD CONSTRAINT `fk_jobwork_charges_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_jobwork_charges_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_jobwork_charges_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_jobwork_charges_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_jobwork_charges_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_jobwork_charges_jobwork_order` FOREIGN KEY (`jobwork_order_id`) REFERENCES `jobwork_orders` (`id`),
  ADD CONSTRAINT `fk_jobwork_charges_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_jobwork_charges_posted_by` FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_jobwork_charges_purchase_invoice` FOREIGN KEY (`purchase_invoice_id`) REFERENCES `purchase_invoices` (`id`),
  ADD CONSTRAINT `fk_jobwork_charges_supplier` FOREIGN KEY (`supplier_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_jobwork_charges_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_jobwork_charges_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`);

--
-- Constraints for table `jobwork_charge_lines`
--
ALTER TABLE `jobwork_charge_lines`
  ADD CONSTRAINT `fk_jobwork_charge_lines_doc` FOREIGN KEY (`jobwork_charge_id`) REFERENCES `jobwork_charges` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_jobwork_charge_lines_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_jobwork_charge_lines_output_item` FOREIGN KEY (`output_item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_jobwork_charge_lines_tax_code` FOREIGN KEY (`tax_code_id`) REFERENCES `tax_codes` (`id`);

--
-- Constraints for table `jobwork_dispatches`
--
ALTER TABLE `jobwork_dispatches`
  ADD CONSTRAINT `fk_jobwork_dispatches_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_jobwork_dispatches_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_jobwork_dispatches_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_jobwork_dispatches_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_jobwork_dispatches_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_jobwork_dispatches_jobwork_order` FOREIGN KEY (`jobwork_order_id`) REFERENCES `jobwork_orders` (`id`),
  ADD CONSTRAINT `fk_jobwork_dispatches_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_jobwork_dispatches_posted_by` FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_jobwork_dispatches_supplier` FOREIGN KEY (`supplier_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_jobwork_dispatches_transporter` FOREIGN KEY (`transporter_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_jobwork_dispatches_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_jobwork_dispatches_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`),
  ADD CONSTRAINT `fk_jobwork_dispatches_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `jobwork_dispatch_lines`
--
ALTER TABLE `jobwork_dispatch_lines`
  ADD CONSTRAINT `fk_jobwork_dispatch_lines_batch` FOREIGN KEY (`batch_id`) REFERENCES `stock_batches` (`id`),
  ADD CONSTRAINT `fk_jobwork_dispatch_lines_doc` FOREIGN KEY (`jobwork_dispatch_id`) REFERENCES `jobwork_dispatches` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_jobwork_dispatch_lines_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_jobwork_dispatch_lines_order_material` FOREIGN KEY (`jobwork_order_material_id`) REFERENCES `jobwork_order_materials` (`id`),
  ADD CONSTRAINT `fk_jobwork_dispatch_lines_serial` FOREIGN KEY (`serial_id`) REFERENCES `stock_serials` (`id`),
  ADD CONSTRAINT `fk_jobwork_dispatch_lines_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`),
  ADD CONSTRAINT `fk_jobwork_dispatch_lines_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `jobwork_orders`
--
ALTER TABLE `jobwork_orders`
  ADD CONSTRAINT `fk_jobwork_orders_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_jobwork_orders_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_jobwork_orders_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_jobwork_orders_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_jobwork_orders_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_jobwork_orders_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_jobwork_orders_issue_warehouse` FOREIGN KEY (`issue_warehouse_id`) REFERENCES `warehouses` (`id`),
  ADD CONSTRAINT `fk_jobwork_orders_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_jobwork_orders_receipt_warehouse` FOREIGN KEY (`receipt_warehouse_id`) REFERENCES `warehouses` (`id`),
  ADD CONSTRAINT `fk_jobwork_orders_supplier` FOREIGN KEY (`supplier_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_jobwork_orders_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `jobwork_order_materials`
--
ALTER TABLE `jobwork_order_materials`
  ADD CONSTRAINT `fk_jobwork_order_materials_doc` FOREIGN KEY (`jobwork_order_id`) REFERENCES `jobwork_orders` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_jobwork_order_materials_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_jobwork_order_materials_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`);

--
-- Constraints for table `jobwork_order_outputs`
--
ALTER TABLE `jobwork_order_outputs`
  ADD CONSTRAINT `fk_jobwork_order_outputs_doc` FOREIGN KEY (`jobwork_order_id`) REFERENCES `jobwork_orders` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_jobwork_order_outputs_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_jobwork_order_outputs_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`);

--
-- Constraints for table `jobwork_receipts`
--
ALTER TABLE `jobwork_receipts`
  ADD CONSTRAINT `fk_jobwork_receipts_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_jobwork_receipts_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_jobwork_receipts_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_jobwork_receipts_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_jobwork_receipts_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_jobwork_receipts_jobwork_order` FOREIGN KEY (`jobwork_order_id`) REFERENCES `jobwork_orders` (`id`),
  ADD CONSTRAINT `fk_jobwork_receipts_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_jobwork_receipts_posted_by` FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_jobwork_receipts_supplier` FOREIGN KEY (`supplier_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_jobwork_receipts_transporter` FOREIGN KEY (`transporter_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_jobwork_receipts_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_jobwork_receipts_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`),
  ADD CONSTRAINT `fk_jobwork_receipts_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `jobwork_receipt_lines`
--
ALTER TABLE `jobwork_receipt_lines`
  ADD CONSTRAINT `fk_jobwork_receipt_lines_batch` FOREIGN KEY (`batch_id`) REFERENCES `stock_batches` (`id`),
  ADD CONSTRAINT `fk_jobwork_receipt_lines_doc` FOREIGN KEY (`jobwork_receipt_id`) REFERENCES `jobwork_receipts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_jobwork_receipt_lines_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_jobwork_receipt_lines_order_output` FOREIGN KEY (`jobwork_order_output_id`) REFERENCES `jobwork_order_outputs` (`id`),
  ADD CONSTRAINT `fk_jobwork_receipt_lines_serial` FOREIGN KEY (`serial_id`) REFERENCES `stock_serials` (`id`),
  ADD CONSTRAINT `fk_jobwork_receipt_lines_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`),
  ADD CONSTRAINT `fk_jobwork_receipt_lines_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `leave_requests`
--
ALTER TABLE `leave_requests`
  ADD CONSTRAINT `fk_leave_approved` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_leave_employee` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`),
  ADD CONSTRAINT `fk_leave_type` FOREIGN KEY (`leave_type_id`) REFERENCES `leave_types` (`id`);

--
-- Constraints for table `login_history`
--
ALTER TABLE `login_history`
  ADD CONSTRAINT `fk_login_history_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `maintenance_plans`
--
ALTER TABLE `maintenance_plans`
  ADD CONSTRAINT `fk_maintenance_plans_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_maintenance_plans_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_maintenance_plans_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `maintenance_plan_assets`
--
ALTER TABLE `maintenance_plan_assets`
  ADD CONSTRAINT `fk_maintenance_plan_assets_asset` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`),
  ADD CONSTRAINT `fk_maintenance_plan_assets_plan` FOREIGN KEY (`maintenance_plan_id`) REFERENCES `maintenance_plans` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_maintenance_plan_assets_vendor` FOREIGN KEY (`assigned_vendor_party_id`) REFERENCES `parties` (`id`);

--
-- Constraints for table `maintenance_requests`
--
ALTER TABLE `maintenance_requests`
  ADD CONSTRAINT `fk_maintenance_requests_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_maintenance_requests_asset` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`),
  ADD CONSTRAINT `fk_maintenance_requests_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_maintenance_requests_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_maintenance_requests_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_maintenance_requests_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_maintenance_requests_plan` FOREIGN KEY (`maintenance_plan_id`) REFERENCES `maintenance_plans` (`id`),
  ADD CONSTRAINT `fk_maintenance_requests_requested_by` FOREIGN KEY (`requested_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_maintenance_requests_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `maintenance_work_orders`
--
ALTER TABLE `maintenance_work_orders`
  ADD CONSTRAINT `fk_maintenance_work_orders_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_maintenance_work_orders_asset` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`),
  ADD CONSTRAINT `fk_maintenance_work_orders_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_maintenance_work_orders_closed_by` FOREIGN KEY (`closed_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_maintenance_work_orders_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_maintenance_work_orders_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_maintenance_work_orders_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_maintenance_work_orders_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_maintenance_work_orders_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_maintenance_work_orders_plan` FOREIGN KEY (`maintenance_plan_id`) REFERENCES `maintenance_plans` (`id`),
  ADD CONSTRAINT `fk_maintenance_work_orders_request` FOREIGN KEY (`maintenance_request_id`) REFERENCES `maintenance_requests` (`id`),
  ADD CONSTRAINT `fk_maintenance_work_orders_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_maintenance_work_orders_vendor` FOREIGN KEY (`vendor_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_maintenance_work_orders_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`);

--
-- Constraints for table `maintenance_work_order_services`
--
ALTER TABLE `maintenance_work_order_services`
  ADD CONSTRAINT `fk_maintenance_work_order_services_doc` FOREIGN KEY (`maintenance_work_order_id`) REFERENCES `maintenance_work_orders` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_maintenance_work_order_services_purchase_invoice` FOREIGN KEY (`purchase_invoice_id`) REFERENCES `purchase_invoices` (`id`),
  ADD CONSTRAINT `fk_maintenance_work_order_services_tax_code` FOREIGN KEY (`tax_code_id`) REFERENCES `tax_codes` (`id`),
  ADD CONSTRAINT `fk_maintenance_work_order_services_vendor` FOREIGN KEY (`vendor_party_id`) REFERENCES `parties` (`id`);

--
-- Constraints for table `maintenance_work_order_spares`
--
ALTER TABLE `maintenance_work_order_spares`
  ADD CONSTRAINT `fk_maintenance_work_order_spares_batch` FOREIGN KEY (`batch_id`) REFERENCES `stock_batches` (`id`),
  ADD CONSTRAINT `fk_maintenance_work_order_spares_doc` FOREIGN KEY (`maintenance_work_order_id`) REFERENCES `maintenance_work_orders` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_maintenance_work_order_spares_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_maintenance_work_order_spares_serial` FOREIGN KEY (`serial_id`) REFERENCES `stock_serials` (`id`),
  ADD CONSTRAINT `fk_maintenance_work_order_spares_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`),
  ADD CONSTRAINT `fk_maintenance_work_order_spares_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `media_files`
--
ALTER TABLE `media_files`
  ADD CONSTRAINT `fk_media_files_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_media_files_uploaded_by` FOREIGN KEY (`uploaded_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `modules`
--
ALTER TABLE `modules`
  ADD CONSTRAINT `fk_modules_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_modules_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `mrp_demands`
--
ALTER TABLE `mrp_demands`
  ADD CONSTRAINT `fk_mrp_demands_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_mrp_demands_run` FOREIGN KEY (`mrp_run_id`) REFERENCES `mrp_runs` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_mrp_demands_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `mrp_net_requirements`
--
ALTER TABLE `mrp_net_requirements`
  ADD CONSTRAINT `fk_mrp_net_requirements_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_mrp_net_requirements_run` FOREIGN KEY (`mrp_run_id`) REFERENCES `mrp_runs` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_mrp_net_requirements_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `mrp_recommendations`
--
ALTER TABLE `mrp_recommendations`
  ADD CONSTRAINT `fk_mrp_recommendations_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_mrp_recommendations_bom` FOREIGN KEY (`bom_id`) REFERENCES `boms` (`id`),
  ADD CONSTRAINT `fk_mrp_recommendations_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_mrp_recommendations_net_requirement` FOREIGN KEY (`mrp_net_requirement_id`) REFERENCES `mrp_net_requirements` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_mrp_recommendations_run` FOREIGN KEY (`mrp_run_id`) REFERENCES `mrp_runs` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_mrp_recommendations_source_warehouse` FOREIGN KEY (`source_warehouse_id`) REFERENCES `warehouses` (`id`),
  ADD CONSTRAINT `fk_mrp_recommendations_supplier` FOREIGN KEY (`supplier_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_mrp_recommendations_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `mrp_runs`
--
ALTER TABLE `mrp_runs`
  ADD CONSTRAINT `fk_mrp_runs_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_mrp_runs_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_mrp_runs_completed_by` FOREIGN KEY (`completed_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_mrp_runs_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_mrp_runs_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_mrp_runs_planning_calendar` FOREIGN KEY (`planning_calendar_id`) REFERENCES `planning_calendars` (`id`),
  ADD CONSTRAINT `fk_mrp_runs_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `mrp_supplies`
--
ALTER TABLE `mrp_supplies`
  ADD CONSTRAINT `fk_mrp_supplies_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_mrp_supplies_run` FOREIGN KEY (`mrp_run_id`) REFERENCES `mrp_runs` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_mrp_supplies_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `parties`
--
ALTER TABLE `parties`
  ADD CONSTRAINT `fk_parties_type` FOREIGN KEY (`party_type_id`) REFERENCES `party_types` (`id`);

--
-- Constraints for table `party_accounts`
--
ALTER TABLE `party_accounts`
  ADD CONSTRAINT `fk_party_accounts_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_party_accounts_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_party_accounts_party` FOREIGN KEY (`party_id`) REFERENCES `parties` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_party_accounts_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `party_addresses`
--
ALTER TABLE `party_addresses`
  ADD CONSTRAINT `fk_party_addresses_party` FOREIGN KEY (`party_id`) REFERENCES `parties` (`id`);

--
-- Constraints for table `party_bank_accounts`
--
ALTER TABLE `party_bank_accounts`
  ADD CONSTRAINT `fk_party_bank_party` FOREIGN KEY (`party_id`) REFERENCES `parties` (`id`);

--
-- Constraints for table `party_contacts`
--
ALTER TABLE `party_contacts`
  ADD CONSTRAINT `fk_party_contacts_party` FOREIGN KEY (`party_id`) REFERENCES `parties` (`id`);

--
-- Constraints for table `party_credit_limits`
--
ALTER TABLE `party_credit_limits`
  ADD CONSTRAINT `fk_party_credit_party` FOREIGN KEY (`party_id`) REFERENCES `parties` (`id`);

--
-- Constraints for table `party_gst_details`
--
ALTER TABLE `party_gst_details`
  ADD CONSTRAINT `fk_party_gst_party` FOREIGN KEY (`party_id`) REFERENCES `parties` (`id`);

--
-- Constraints for table `party_payment_terms`
--
ALTER TABLE `party_payment_terms`
  ADD CONSTRAINT `fk_party_terms_party` FOREIGN KEY (`party_id`) REFERENCES `parties` (`id`);

--
-- Constraints for table `party_roles`
--
ALTER TABLE `party_roles`
  ADD CONSTRAINT `fk_party_roles_party` FOREIGN KEY (`party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_party_roles_type` FOREIGN KEY (`party_type_id`) REFERENCES `party_types` (`id`);

--
-- Constraints for table `payroll_lines`
--
ALTER TABLE `payroll_lines`
  ADD CONSTRAINT `fk_payroll_lines_employee` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`),
  ADD CONSTRAINT `fk_payroll_lines_run` FOREIGN KEY (`payroll_run_id`) REFERENCES `payroll_runs` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `payroll_runs`
--
ALTER TABLE `payroll_runs`
  ADD CONSTRAINT `fk_payroll_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_payroll_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`);

--
-- Constraints for table `payslips`
--
ALTER TABLE `payslips`
  ADD CONSTRAINT `fk_payslip_line` FOREIGN KEY (`payroll_line_id`) REFERENCES `payroll_lines` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `permissions`
--
ALTER TABLE `permissions`
  ADD CONSTRAINT `fk_permissions_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_permissions_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `planning_calendars`
--
ALTER TABLE `planning_calendars`
  ADD CONSTRAINT `fk_planning_calendars_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_planning_calendars_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_planning_calendars_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `posting_rules`
--
ALTER TABLE `posting_rules`
  ADD CONSTRAINT `fk_posting_rules_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_posting_rules_fixed_account` FOREIGN KEY (`fixed_account_id`) REFERENCES `accounts` (`id`),
  ADD CONSTRAINT `fk_posting_rules_group` FOREIGN KEY (`posting_rule_group_id`) REFERENCES `posting_rule_groups` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_posting_rules_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `posting_rule_groups`
--
ALTER TABLE `posting_rule_groups`
  ADD CONSTRAINT `fk_posting_rule_groups_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_posting_rule_groups_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `production_material_issues`
--
ALTER TABLE `production_material_issues`
  ADD CONSTRAINT `fk_production_material_issues_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_production_material_issues_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_production_material_issues_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_production_material_issues_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_production_material_issues_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_production_material_issues_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_production_material_issues_posted_by` FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_production_material_issues_production_order` FOREIGN KEY (`production_order_id`) REFERENCES `production_orders` (`id`),
  ADD CONSTRAINT `fk_production_material_issues_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_production_material_issues_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`),
  ADD CONSTRAINT `fk_production_material_issues_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `production_material_issue_lines`
--
ALTER TABLE `production_material_issue_lines`
  ADD CONSTRAINT `fk_production_material_issue_lines_batch` FOREIGN KEY (`batch_id`) REFERENCES `stock_batches` (`id`),
  ADD CONSTRAINT `fk_production_material_issue_lines_doc` FOREIGN KEY (`production_material_issue_id`) REFERENCES `production_material_issues` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_production_material_issue_lines_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_production_material_issue_lines_order_material` FOREIGN KEY (`production_order_material_id`) REFERENCES `production_order_materials` (`id`),
  ADD CONSTRAINT `fk_production_material_issue_lines_serial` FOREIGN KEY (`serial_id`) REFERENCES `stock_serials` (`id`),
  ADD CONSTRAINT `fk_production_material_issue_lines_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`),
  ADD CONSTRAINT `fk_production_material_issue_lines_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `production_orders`
--
ALTER TABLE `production_orders`
  ADD CONSTRAINT `fk_production_orders_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_production_orders_bom` FOREIGN KEY (`bom_id`) REFERENCES `boms` (`id`),
  ADD CONSTRAINT `fk_production_orders_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_production_orders_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_production_orders_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_production_orders_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_production_orders_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_production_orders_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_production_orders_output_item` FOREIGN KEY (`output_item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_production_orders_output_uom` FOREIGN KEY (`output_uom_id`) REFERENCES `uoms` (`id`),
  ADD CONSTRAINT `fk_production_orders_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_production_orders_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`),
  ADD CONSTRAINT `fk_production_orders_wip_warehouse` FOREIGN KEY (`wip_warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `production_order_materials`
--
ALTER TABLE `production_order_materials`
  ADD CONSTRAINT `fk_production_order_materials_bom_line` FOREIGN KEY (`bom_line_id`) REFERENCES `bom_lines` (`id`),
  ADD CONSTRAINT `fk_production_order_materials_doc` FOREIGN KEY (`production_order_id`) REFERENCES `production_orders` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_production_order_materials_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_production_order_materials_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`),
  ADD CONSTRAINT `fk_production_order_materials_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `production_order_operations`
--
ALTER TABLE `production_order_operations`
  ADD CONSTRAINT `fk_production_order_operations_bom_operation` FOREIGN KEY (`bom_operation_id`) REFERENCES `bom_operations` (`id`),
  ADD CONSTRAINT `fk_production_order_operations_doc` FOREIGN KEY (`production_order_id`) REFERENCES `production_orders` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `production_order_outputs`
--
ALTER TABLE `production_order_outputs`
  ADD CONSTRAINT `fk_production_order_outputs_doc` FOREIGN KEY (`production_order_id`) REFERENCES `production_orders` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_production_order_outputs_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_production_order_outputs_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`),
  ADD CONSTRAINT `fk_production_order_outputs_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `production_receipts`
--
ALTER TABLE `production_receipts`
  ADD CONSTRAINT `fk_production_receipts_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_production_receipts_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_production_receipts_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_production_receipts_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_production_receipts_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_production_receipts_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_production_receipts_posted_by` FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_production_receipts_production_order` FOREIGN KEY (`production_order_id`) REFERENCES `production_orders` (`id`),
  ADD CONSTRAINT `fk_production_receipts_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_production_receipts_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`),
  ADD CONSTRAINT `fk_production_receipts_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `production_receipt_lines`
--
ALTER TABLE `production_receipt_lines`
  ADD CONSTRAINT `fk_production_receipt_lines_batch` FOREIGN KEY (`batch_id`) REFERENCES `stock_batches` (`id`),
  ADD CONSTRAINT `fk_production_receipt_lines_doc` FOREIGN KEY (`production_receipt_id`) REFERENCES `production_receipts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_production_receipt_lines_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_production_receipt_lines_order_output` FOREIGN KEY (`production_order_output_id`) REFERENCES `production_order_outputs` (`id`),
  ADD CONSTRAINT `fk_production_receipt_lines_serial` FOREIGN KEY (`serial_id`) REFERENCES `stock_serials` (`id`),
  ADD CONSTRAINT `fk_production_receipt_lines_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`),
  ADD CONSTRAINT `fk_production_receipt_lines_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `projects`
--
ALTER TABLE `projects`
  ADD CONSTRAINT `fk_projects_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_projects_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_projects_customer` FOREIGN KEY (`customer_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_projects_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `project_billings`
--
ALTER TABLE `project_billings`
  ADD CONSTRAINT `fk_project_billings_milestone` FOREIGN KEY (`project_milestone_id`) REFERENCES `project_milestones` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_project_billings_project` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_project_billings_sales_invoice` FOREIGN KEY (`sales_invoice_id`) REFERENCES `sales_invoices` (`id`);

--
-- Constraints for table `project_expenses`
--
ALTER TABLE `project_expenses`
  ADD CONSTRAINT `fk_project_expenses_project` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_project_expenses_purchase_invoice` FOREIGN KEY (`purchase_invoice_id`) REFERENCES `purchase_invoices` (`id`),
  ADD CONSTRAINT `fk_project_expenses_supplier` FOREIGN KEY (`supplier_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_project_expenses_task` FOREIGN KEY (`project_task_id`) REFERENCES `project_tasks` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_project_expenses_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`);

--
-- Constraints for table `project_milestones`
--
ALTER TABLE `project_milestones`
  ADD CONSTRAINT `fk_project_milestones_project` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `project_resource_usages`
--
ALTER TABLE `project_resource_usages`
  ADD CONSTRAINT `fk_project_resource_usages_asset` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`),
  ADD CONSTRAINT `fk_project_resource_usages_project` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_project_resource_usages_task` FOREIGN KEY (`project_task_id`) REFERENCES `project_tasks` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_project_resource_usages_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`);

--
-- Constraints for table `project_tasks`
--
ALTER TABLE `project_tasks`
  ADD CONSTRAINT `fk_project_tasks_employee` FOREIGN KEY (`assigned_employee_id`) REFERENCES `employees` (`id`),
  ADD CONSTRAINT `fk_project_tasks_project` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `project_timesheets`
--
ALTER TABLE `project_timesheets`
  ADD CONSTRAINT `fk_project_timesheets_employee` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`),
  ADD CONSTRAINT `fk_project_timesheets_project` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_project_timesheets_task` FOREIGN KEY (`project_task_id`) REFERENCES `project_tasks` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_project_timesheets_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`);

--
-- Constraints for table `project_vendor_works`
--
ALTER TABLE `project_vendor_works`
  ADD CONSTRAINT `fk_project_vendor_works_project` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_project_vendor_works_purchase_invoice` FOREIGN KEY (`purchase_invoice_id`) REFERENCES `purchase_invoices` (`id`),
  ADD CONSTRAINT `fk_project_vendor_works_purchase_order` FOREIGN KEY (`purchase_order_id`) REFERENCES `purchase_orders` (`id`),
  ADD CONSTRAINT `fk_project_vendor_works_task` FOREIGN KEY (`project_task_id`) REFERENCES `project_tasks` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_project_vendor_works_vendor` FOREIGN KEY (`vendor_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_project_vendor_works_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`);

--
-- Constraints for table `purchase_invoices`
--
ALTER TABLE `purchase_invoices`
  ADD CONSTRAINT `fk_purchase_invoices_adjustment_account` FOREIGN KEY (`adjustment_account_id`) REFERENCES `accounts` (`id`),
  ADD CONSTRAINT `fk_purchase_invoices_billing_address` FOREIGN KEY (`billing_address_id`) REFERENCES `party_addresses` (`id`),
  ADD CONSTRAINT `fk_purchase_invoices_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_purchase_invoices_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_purchase_invoices_contact` FOREIGN KEY (`contact_id`) REFERENCES `party_contacts` (`id`),
  ADD CONSTRAINT `fk_purchase_invoices_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_purchase_invoices_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_purchase_invoices_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_purchase_invoices_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_purchase_invoices_order` FOREIGN KEY (`purchase_order_id`) REFERENCES `purchase_orders` (`id`),
  ADD CONSTRAINT `fk_purchase_invoices_posted_by` FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_purchase_invoices_receipt` FOREIGN KEY (`purchase_receipt_id`) REFERENCES `purchase_receipts` (`id`),
  ADD CONSTRAINT `fk_purchase_invoices_shipping_address` FOREIGN KEY (`shipping_address_id`) REFERENCES `party_addresses` (`id`),
  ADD CONSTRAINT `fk_purchase_invoices_supplier` FOREIGN KEY (`supplier_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_purchase_invoices_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_purchase_invoices_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`);

--
-- Constraints for table `purchase_invoice_lines`
--
ALTER TABLE `purchase_invoice_lines`
  ADD CONSTRAINT `fk_purchase_invoice_lines_batch` FOREIGN KEY (`batch_id`) REFERENCES `stock_batches` (`id`),
  ADD CONSTRAINT `fk_purchase_invoice_lines_doc` FOREIGN KEY (`purchase_invoice_id`) REFERENCES `purchase_invoices` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_purchase_invoice_lines_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_purchase_invoice_lines_order_line` FOREIGN KEY (`purchase_order_line_id`) REFERENCES `purchase_order_lines` (`id`),
  ADD CONSTRAINT `fk_purchase_invoice_lines_receipt_line` FOREIGN KEY (`purchase_receipt_line_id`) REFERENCES `purchase_receipt_lines` (`id`),
  ADD CONSTRAINT `fk_purchase_invoice_lines_serial` FOREIGN KEY (`serial_id`) REFERENCES `stock_serials` (`id`),
  ADD CONSTRAINT `fk_purchase_invoice_lines_tax_code` FOREIGN KEY (`tax_code_id`) REFERENCES `tax_codes` (`id`),
  ADD CONSTRAINT `fk_purchase_invoice_lines_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`),
  ADD CONSTRAINT `fk_purchase_invoice_lines_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `purchase_orders`
--
ALTER TABLE `purchase_orders`
  ADD CONSTRAINT `fk_purchase_orders_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_purchase_orders_billing_address` FOREIGN KEY (`billing_address_id`) REFERENCES `party_addresses` (`id`),
  ADD CONSTRAINT `fk_purchase_orders_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_purchase_orders_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_purchase_orders_contact` FOREIGN KEY (`contact_id`) REFERENCES `party_contacts` (`id`),
  ADD CONSTRAINT `fk_purchase_orders_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_purchase_orders_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_purchase_orders_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_purchase_orders_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_purchase_orders_requisition` FOREIGN KEY (`purchase_requisition_id`) REFERENCES `purchase_requisitions` (`id`),
  ADD CONSTRAINT `fk_purchase_orders_shipping_address` FOREIGN KEY (`shipping_address_id`) REFERENCES `party_addresses` (`id`),
  ADD CONSTRAINT `fk_purchase_orders_supplier` FOREIGN KEY (`supplier_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_purchase_orders_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `purchase_order_lines`
--
ALTER TABLE `purchase_order_lines`
  ADD CONSTRAINT `fk_purchase_order_lines_doc` FOREIGN KEY (`purchase_order_id`) REFERENCES `purchase_orders` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_purchase_order_lines_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_purchase_order_lines_requisition_line` FOREIGN KEY (`purchase_requisition_line_id`) REFERENCES `purchase_requisition_lines` (`id`),
  ADD CONSTRAINT `fk_purchase_order_lines_tax_code` FOREIGN KEY (`tax_code_id`) REFERENCES `tax_codes` (`id`),
  ADD CONSTRAINT `fk_purchase_order_lines_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`),
  ADD CONSTRAINT `fk_purchase_order_lines_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `purchase_payments`
--
ALTER TABLE `purchase_payments`
  ADD CONSTRAINT `fk_purchase_payments_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`),
  ADD CONSTRAINT `fk_purchase_payments_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_purchase_payments_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_purchase_payments_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_purchase_payments_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_purchase_payments_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_purchase_payments_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_purchase_payments_posted_by` FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_purchase_payments_supplier` FOREIGN KEY (`supplier_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_purchase_payments_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_purchase_payments_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`);

--
-- Constraints for table `purchase_payment_allocations`
--
ALTER TABLE `purchase_payment_allocations`
  ADD CONSTRAINT `fk_purchase_payment_allocations_invoice` FOREIGN KEY (`purchase_invoice_id`) REFERENCES `purchase_invoices` (`id`),
  ADD CONSTRAINT `fk_purchase_payment_allocations_payment` FOREIGN KEY (`purchase_payment_id`) REFERENCES `purchase_payments` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `purchase_receipts`
--
ALTER TABLE `purchase_receipts`
  ADD CONSTRAINT `fk_purchase_receipts_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_purchase_receipts_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_purchase_receipts_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_purchase_receipts_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_purchase_receipts_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_purchase_receipts_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_purchase_receipts_order` FOREIGN KEY (`purchase_order_id`) REFERENCES `purchase_orders` (`id`),
  ADD CONSTRAINT `fk_purchase_receipts_posted_by` FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_purchase_receipts_supplier` FOREIGN KEY (`supplier_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_purchase_receipts_transporter` FOREIGN KEY (`transporter_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_purchase_receipts_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_purchase_receipts_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`),
  ADD CONSTRAINT `fk_purchase_receipts_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `purchase_receipt_lines`
--
ALTER TABLE `purchase_receipt_lines`
  ADD CONSTRAINT `fk_purchase_receipt_lines_batch` FOREIGN KEY (`batch_id`) REFERENCES `stock_batches` (`id`),
  ADD CONSTRAINT `fk_purchase_receipt_lines_doc` FOREIGN KEY (`purchase_receipt_id`) REFERENCES `purchase_receipts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_purchase_receipt_lines_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_purchase_receipt_lines_order_line` FOREIGN KEY (`purchase_order_line_id`) REFERENCES `purchase_order_lines` (`id`),
  ADD CONSTRAINT `fk_purchase_receipt_lines_serial` FOREIGN KEY (`serial_id`) REFERENCES `stock_serials` (`id`),
  ADD CONSTRAINT `fk_purchase_receipt_lines_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`),
  ADD CONSTRAINT `fk_purchase_receipt_lines_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `purchase_requisitions`
--
ALTER TABLE `purchase_requisitions`
  ADD CONSTRAINT `fk_purchase_requisitions_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_purchase_requisitions_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_purchase_requisitions_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_purchase_requisitions_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_purchase_requisitions_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_purchase_requisitions_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_purchase_requisitions_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_purchase_requisitions_requested_by` FOREIGN KEY (`requested_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_purchase_requisitions_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `purchase_requisition_lines`
--
ALTER TABLE `purchase_requisition_lines`
  ADD CONSTRAINT `fk_purchase_requisition_lines_doc` FOREIGN KEY (`purchase_requisition_id`) REFERENCES `purchase_requisitions` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_purchase_requisition_lines_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_purchase_requisition_lines_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`),
  ADD CONSTRAINT `fk_purchase_requisition_lines_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `purchase_returns`
--
ALTER TABLE `purchase_returns`
  ADD CONSTRAINT `fk_purchase_returns_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_purchase_returns_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_purchase_returns_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_purchase_returns_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_purchase_returns_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_purchase_returns_invoice` FOREIGN KEY (`purchase_invoice_id`) REFERENCES `purchase_invoices` (`id`),
  ADD CONSTRAINT `fk_purchase_returns_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_purchase_returns_posted_by` FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_purchase_returns_supplier` FOREIGN KEY (`supplier_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_purchase_returns_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_purchase_returns_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`);

--
-- Constraints for table `purchase_return_lines`
--
ALTER TABLE `purchase_return_lines`
  ADD CONSTRAINT `fk_purchase_return_lines_batch` FOREIGN KEY (`batch_id`) REFERENCES `stock_batches` (`id`),
  ADD CONSTRAINT `fk_purchase_return_lines_doc` FOREIGN KEY (`purchase_return_id`) REFERENCES `purchase_returns` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_purchase_return_lines_invoice_line` FOREIGN KEY (`purchase_invoice_line_id`) REFERENCES `purchase_invoice_lines` (`id`),
  ADD CONSTRAINT `fk_purchase_return_lines_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_purchase_return_lines_serial` FOREIGN KEY (`serial_id`) REFERENCES `stock_serials` (`id`),
  ADD CONSTRAINT `fk_purchase_return_lines_tax_code` FOREIGN KEY (`tax_code_id`) REFERENCES `tax_codes` (`id`),
  ADD CONSTRAINT `fk_purchase_return_lines_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`),
  ADD CONSTRAINT `fk_purchase_return_lines_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `qc_inspections`
--
ALTER TABLE `qc_inspections`
  ADD CONSTRAINT `fk_qc_inspections_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_qc_inspections_batch` FOREIGN KEY (`batch_id`) REFERENCES `stock_batches` (`id`),
  ADD CONSTRAINT `fk_qc_inspections_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_qc_inspections_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_qc_inspections_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_qc_inspections_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_qc_inspections_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_qc_inspections_inspected_by` FOREIGN KEY (`inspected_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_qc_inspections_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_qc_inspections_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_qc_inspections_qc_plan` FOREIGN KEY (`qc_plan_id`) REFERENCES `qc_plans` (`id`),
  ADD CONSTRAINT `fk_qc_inspections_serial` FOREIGN KEY (`serial_id`) REFERENCES `stock_serials` (`id`),
  ADD CONSTRAINT `fk_qc_inspections_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`),
  ADD CONSTRAINT `fk_qc_inspections_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_qc_inspections_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `qc_inspection_lines`
--
ALTER TABLE `qc_inspection_lines`
  ADD CONSTRAINT `fk_qc_inspection_lines_doc` FOREIGN KEY (`qc_inspection_id`) REFERENCES `qc_inspections` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_qc_inspection_lines_plan_line` FOREIGN KEY (`qc_plan_line_id`) REFERENCES `qc_plan_lines` (`id`);

--
-- Constraints for table `qc_non_conformance_logs`
--
ALTER TABLE `qc_non_conformance_logs`
  ADD CONSTRAINT `fk_qc_non_conformance_logs_assigned_to` FOREIGN KEY (`assigned_to`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_qc_non_conformance_logs_closed_by` FOREIGN KEY (`closed_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_qc_non_conformance_logs_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_qc_non_conformance_logs_inspection` FOREIGN KEY (`qc_inspection_id`) REFERENCES `qc_inspections` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_qc_non_conformance_logs_inspection_line` FOREIGN KEY (`qc_inspection_line_id`) REFERENCES `qc_inspection_lines` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_qc_non_conformance_logs_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `qc_plans`
--
ALTER TABLE `qc_plans`
  ADD CONSTRAINT `fk_qc_plans_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_qc_plans_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_qc_plans_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_qc_plans_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_qc_plans_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_qc_plans_item_category` FOREIGN KEY (`item_category_id`) REFERENCES `item_categories` (`id`),
  ADD CONSTRAINT `fk_qc_plans_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_qc_plans_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `qc_plan_lines`
--
ALTER TABLE `qc_plan_lines`
  ADD CONSTRAINT `fk_qc_plan_lines_doc` FOREIGN KEY (`qc_plan_id`) REFERENCES `qc_plans` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `qc_result_actions`
--
ALTER TABLE `qc_result_actions`
  ADD CONSTRAINT `fk_qc_result_actions_action_by` FOREIGN KEY (`action_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_qc_result_actions_inspection` FOREIGN KEY (`qc_inspection_id`) REFERENCES `qc_inspections` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_qc_result_actions_target_warehouse` FOREIGN KEY (`target_warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `roles`
--
ALTER TABLE `roles`
  ADD CONSTRAINT `fk_roles_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_roles_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `role_permissions`
--
ALTER TABLE `role_permissions`
  ADD CONSTRAINT `fk_role_permissions_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_role_permissions_permission` FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_role_permissions_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_role_permissions_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `sales_deliveries`
--
ALTER TABLE `sales_deliveries`
  ADD CONSTRAINT `fk_sales_deliveries_billing_address` FOREIGN KEY (`billing_address_id`) REFERENCES `party_addresses` (`id`),
  ADD CONSTRAINT `fk_sales_deliveries_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_sales_deliveries_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_sales_deliveries_contact` FOREIGN KEY (`contact_id`) REFERENCES `party_contacts` (`id`),
  ADD CONSTRAINT `fk_sales_deliveries_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_sales_deliveries_customer` FOREIGN KEY (`customer_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_sales_deliveries_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_sales_deliveries_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_sales_deliveries_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_sales_deliveries_order` FOREIGN KEY (`sales_order_id`) REFERENCES `sales_orders` (`id`),
  ADD CONSTRAINT `fk_sales_deliveries_posted_by` FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_sales_deliveries_shipping_address` FOREIGN KEY (`shipping_address_id`) REFERENCES `party_addresses` (`id`),
  ADD CONSTRAINT `fk_sales_deliveries_transporter` FOREIGN KEY (`transporter_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_sales_deliveries_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_sales_deliveries_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`);

--
-- Constraints for table `sales_delivery_lines`
--
ALTER TABLE `sales_delivery_lines`
  ADD CONSTRAINT `fk_sales_delivery_lines_batch` FOREIGN KEY (`batch_id`) REFERENCES `stock_batches` (`id`),
  ADD CONSTRAINT `fk_sales_delivery_lines_doc` FOREIGN KEY (`sales_delivery_id`) REFERENCES `sales_deliveries` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_sales_delivery_lines_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_sales_delivery_lines_order_line` FOREIGN KEY (`sales_order_line_id`) REFERENCES `sales_order_lines` (`id`),
  ADD CONSTRAINT `fk_sales_delivery_lines_serial` FOREIGN KEY (`serial_id`) REFERENCES `stock_serials` (`id`),
  ADD CONSTRAINT `fk_sales_delivery_lines_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`),
  ADD CONSTRAINT `fk_sales_delivery_lines_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `sales_delivery_returnable_dcs`
--
ALTER TABLE `sales_delivery_returnable_dcs`
  ADD CONSTRAINT `sales_delivery_returnable_dcs_delivery_fk` FOREIGN KEY (`sales_delivery_id`) REFERENCES `sales_deliveries` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `sales_delivery_returnable_dcs_item_fk` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `sales_delivery_returnable_dcs_uom_fk` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`);

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

--
-- Constraints for table `sales_invoice_lines`
--
ALTER TABLE `sales_invoice_lines`
  ADD CONSTRAINT `fk_sales_invoice_lines_batch` FOREIGN KEY (`batch_id`) REFERENCES `stock_batches` (`id`),
  ADD CONSTRAINT `fk_sales_invoice_lines_delivery_line` FOREIGN KEY (`sales_delivery_line_id`) REFERENCES `sales_delivery_lines` (`id`),
  ADD CONSTRAINT `fk_sales_invoice_lines_doc` FOREIGN KEY (`sales_invoice_id`) REFERENCES `sales_invoices` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_sales_invoice_lines_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_sales_invoice_lines_order_line` FOREIGN KEY (`sales_order_line_id`) REFERENCES `sales_order_lines` (`id`),
  ADD CONSTRAINT `fk_sales_invoice_lines_serial` FOREIGN KEY (`serial_id`) REFERENCES `stock_serials` (`id`),
  ADD CONSTRAINT `fk_sales_invoice_lines_tax_code` FOREIGN KEY (`tax_code_id`) REFERENCES `tax_codes` (`id`),
  ADD CONSTRAINT `fk_sales_invoice_lines_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`),
  ADD CONSTRAINT `fk_sales_invoice_lines_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `sales_orders`
--
ALTER TABLE `sales_orders`
  ADD CONSTRAINT `fk_sales_orders_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_sales_orders_billing_address` FOREIGN KEY (`billing_address_id`) REFERENCES `party_addresses` (`id`),
  ADD CONSTRAINT `fk_sales_orders_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_sales_orders_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_sales_orders_contact` FOREIGN KEY (`contact_id`) REFERENCES `party_contacts` (`id`),
  ADD CONSTRAINT `fk_sales_orders_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_sales_orders_crm_opportunity` FOREIGN KEY (`crm_opportunity_id`) REFERENCES `crm_opportunities` (`id`),
  ADD CONSTRAINT `fk_sales_orders_customer` FOREIGN KEY (`customer_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_sales_orders_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_sales_orders_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_sales_orders_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_sales_orders_quotation` FOREIGN KEY (`sales_quotation_id`) REFERENCES `sales_quotations` (`id`),
  ADD CONSTRAINT `fk_sales_orders_shipping_address` FOREIGN KEY (`shipping_address_id`) REFERENCES `party_addresses` (`id`),
  ADD CONSTRAINT `fk_sales_orders_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `sales_order_lines`
--
ALTER TABLE `sales_order_lines`
  ADD CONSTRAINT `fk_sales_order_lines_doc` FOREIGN KEY (`sales_order_id`) REFERENCES `sales_orders` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_sales_order_lines_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_sales_order_lines_quotation_line` FOREIGN KEY (`sales_quotation_line_id`) REFERENCES `sales_quotation_lines` (`id`),
  ADD CONSTRAINT `fk_sales_order_lines_tax_code` FOREIGN KEY (`tax_code_id`) REFERENCES `tax_codes` (`id`),
  ADD CONSTRAINT `fk_sales_order_lines_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`),
  ADD CONSTRAINT `fk_sales_order_lines_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `sales_quotations`
--
ALTER TABLE `sales_quotations`
  ADD CONSTRAINT `fk_sales_quotations_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_sales_quotations_billing_address` FOREIGN KEY (`billing_address_id`) REFERENCES `party_addresses` (`id`),
  ADD CONSTRAINT `fk_sales_quotations_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_sales_quotations_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_sales_quotations_contact` FOREIGN KEY (`contact_id`) REFERENCES `party_contacts` (`id`),
  ADD CONSTRAINT `fk_sales_quotations_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_sales_quotations_crm_opportunity` FOREIGN KEY (`crm_opportunity_id`) REFERENCES `crm_opportunities` (`id`),
  ADD CONSTRAINT `fk_sales_quotations_customer` FOREIGN KEY (`customer_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_sales_quotations_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_sales_quotations_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_sales_quotations_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_sales_quotations_shipping_address` FOREIGN KEY (`shipping_address_id`) REFERENCES `party_addresses` (`id`),
  ADD CONSTRAINT `fk_sales_quotations_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `sales_quotation_lines`
--
ALTER TABLE `sales_quotation_lines`
  ADD CONSTRAINT `fk_sales_quotation_lines_doc` FOREIGN KEY (`sales_quotation_id`) REFERENCES `sales_quotations` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_sales_quotation_lines_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_sales_quotation_lines_tax_code` FOREIGN KEY (`tax_code_id`) REFERENCES `tax_codes` (`id`),
  ADD CONSTRAINT `fk_sales_quotation_lines_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`),
  ADD CONSTRAINT `fk_sales_quotation_lines_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `sales_receipts`
--
ALTER TABLE `sales_receipts`
  ADD CONSTRAINT `fk_sales_receipts_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`),
  ADD CONSTRAINT `fk_sales_receipts_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_sales_receipts_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_sales_receipts_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_sales_receipts_customer` FOREIGN KEY (`customer_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_sales_receipts_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_sales_receipts_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_sales_receipts_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_sales_receipts_posted_by` FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_sales_receipts_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_sales_receipts_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`);

--
-- Constraints for table `sales_receipt_allocations`
--
ALTER TABLE `sales_receipt_allocations`
  ADD CONSTRAINT `fk_sales_receipt_allocations_invoice` FOREIGN KEY (`sales_invoice_id`) REFERENCES `sales_invoices` (`id`),
  ADD CONSTRAINT `fk_sales_receipt_allocations_receipt` FOREIGN KEY (`sales_receipt_id`) REFERENCES `sales_receipts` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `sales_returns`
--
ALTER TABLE `sales_returns`
  ADD CONSTRAINT `fk_sales_returns_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_sales_returns_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_sales_returns_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_sales_returns_customer` FOREIGN KEY (`customer_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_sales_returns_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_sales_returns_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_sales_returns_invoice` FOREIGN KEY (`sales_invoice_id`) REFERENCES `sales_invoices` (`id`),
  ADD CONSTRAINT `fk_sales_returns_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_sales_returns_posted_by` FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_sales_returns_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_sales_returns_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`);

--
-- Constraints for table `sales_return_lines`
--
ALTER TABLE `sales_return_lines`
  ADD CONSTRAINT `fk_sales_return_lines_batch` FOREIGN KEY (`batch_id`) REFERENCES `stock_batches` (`id`),
  ADD CONSTRAINT `fk_sales_return_lines_doc` FOREIGN KEY (`sales_return_id`) REFERENCES `sales_returns` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_sales_return_lines_invoice_line` FOREIGN KEY (`sales_invoice_line_id`) REFERENCES `sales_invoice_lines` (`id`),
  ADD CONSTRAINT `fk_sales_return_lines_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_sales_return_lines_serial` FOREIGN KEY (`serial_id`) REFERENCES `stock_serials` (`id`),
  ADD CONSTRAINT `fk_sales_return_lines_tax_code` FOREIGN KEY (`tax_code_id`) REFERENCES `tax_codes` (`id`),
  ADD CONSTRAINT `fk_sales_return_lines_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`),
  ADD CONSTRAINT `fk_sales_return_lines_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `service_contracts`
--
ALTER TABLE `service_contracts`
  ADD CONSTRAINT `fk_service_contracts_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_service_contracts_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_service_contracts_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_service_contracts_customer` FOREIGN KEY (`customer_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_service_contracts_sales_invoice` FOREIGN KEY (`sales_invoice_id`) REFERENCES `sales_invoices` (`id`),
  ADD CONSTRAINT `fk_service_contracts_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `service_contract_assets`
--
ALTER TABLE `service_contract_assets`
  ADD CONSTRAINT `fk_service_contract_assets_asset` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`),
  ADD CONSTRAINT `fk_service_contract_assets_contract` FOREIGN KEY (`service_contract_id`) REFERENCES `service_contracts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_service_contract_assets_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_service_contract_assets_serial` FOREIGN KEY (`serial_id`) REFERENCES `stock_serials` (`id`);

--
-- Constraints for table `service_feedbacks`
--
ALTER TABLE `service_feedbacks`
  ADD CONSTRAINT `fk_service_feedbacks_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_service_feedbacks_ticket` FOREIGN KEY (`service_ticket_id`) REFERENCES `service_tickets` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_service_feedbacks_work_order` FOREIGN KEY (`service_work_order_id`) REFERENCES `service_work_orders` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `service_tickets`
--
ALTER TABLE `service_tickets`
  ADD CONSTRAINT `fk_service_tickets_asset` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`),
  ADD CONSTRAINT `fk_service_tickets_assigned_to` FOREIGN KEY (`assigned_to_user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_service_tickets_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_service_tickets_closed_by` FOREIGN KEY (`closed_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_service_tickets_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_service_tickets_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_service_tickets_customer` FOREIGN KEY (`customer_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_service_tickets_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_service_tickets_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_service_tickets_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_service_tickets_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_service_tickets_serial` FOREIGN KEY (`serial_id`) REFERENCES `stock_serials` (`id`),
  ADD CONSTRAINT `fk_service_tickets_service_contract` FOREIGN KEY (`service_contract_id`) REFERENCES `service_contracts` (`id`),
  ADD CONSTRAINT `fk_service_tickets_service_contract_asset` FOREIGN KEY (`service_contract_asset_id`) REFERENCES `service_contract_assets` (`id`),
  ADD CONSTRAINT `fk_service_tickets_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `service_ticket_activities`
--
ALTER TABLE `service_ticket_activities`
  ADD CONSTRAINT `fk_service_ticket_activities_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_service_ticket_activities_ticket` FOREIGN KEY (`service_ticket_id`) REFERENCES `service_tickets` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `service_visit_logs`
--
ALTER TABLE `service_visit_logs`
  ADD CONSTRAINT `fk_service_visit_logs_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_service_visit_logs_work_order` FOREIGN KEY (`service_work_order_id`) REFERENCES `service_work_orders` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `service_work_orders`
--
ALTER TABLE `service_work_orders`
  ADD CONSTRAINT `fk_service_work_orders_asset` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`),
  ADD CONSTRAINT `fk_service_work_orders_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_service_work_orders_closed_by` FOREIGN KEY (`closed_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_service_work_orders_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_service_work_orders_completed_by` FOREIGN KEY (`completed_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_service_work_orders_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_service_work_orders_customer` FOREIGN KEY (`customer_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_service_work_orders_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_service_work_orders_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_service_work_orders_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_service_work_orders_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_service_work_orders_serial` FOREIGN KEY (`serial_id`) REFERENCES `stock_serials` (`id`),
  ADD CONSTRAINT `fk_service_work_orders_technician` FOREIGN KEY (`technician_user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_service_work_orders_ticket` FOREIGN KEY (`service_ticket_id`) REFERENCES `service_tickets` (`id`),
  ADD CONSTRAINT `fk_service_work_orders_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_service_work_orders_vendor` FOREIGN KEY (`vendor_party_id`) REFERENCES `parties` (`id`),
  ADD CONSTRAINT `fk_service_work_orders_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`);

--
-- Constraints for table `service_work_order_services`
--
ALTER TABLE `service_work_order_services`
  ADD CONSTRAINT `fk_service_work_order_services_doc` FOREIGN KEY (`service_work_order_id`) REFERENCES `service_work_orders` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_service_work_order_services_purchase_invoice` FOREIGN KEY (`purchase_invoice_id`) REFERENCES `purchase_invoices` (`id`),
  ADD CONSTRAINT `fk_service_work_order_services_tax_code` FOREIGN KEY (`tax_code_id`) REFERENCES `tax_codes` (`id`),
  ADD CONSTRAINT `fk_service_work_order_services_vendor` FOREIGN KEY (`vendor_party_id`) REFERENCES `parties` (`id`);

--
-- Constraints for table `service_work_order_spares`
--
ALTER TABLE `service_work_order_spares`
  ADD CONSTRAINT `fk_service_work_order_spares_batch` FOREIGN KEY (`batch_id`) REFERENCES `stock_batches` (`id`),
  ADD CONSTRAINT `fk_service_work_order_spares_doc` FOREIGN KEY (`service_work_order_id`) REFERENCES `service_work_orders` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_service_work_order_spares_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_service_work_order_spares_serial` FOREIGN KEY (`serial_id`) REFERENCES `stock_serials` (`id`),
  ADD CONSTRAINT `fk_service_work_order_spares_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`),
  ADD CONSTRAINT `fk_service_work_order_spares_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `stock_adjustments`
--
ALTER TABLE `stock_adjustments`
  ADD CONSTRAINT `fk_stock_adjustments_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_stock_adjustments_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_stock_adjustments_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_stock_adjustments_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_stock_adjustments_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_stock_adjustments_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_stock_adjustments_posted_by` FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_stock_adjustments_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `stock_adjustment_lines`
--
ALTER TABLE `stock_adjustment_lines`
  ADD CONSTRAINT `fk_stock_adjustment_lines_batch` FOREIGN KEY (`batch_id`) REFERENCES `stock_batches` (`id`),
  ADD CONSTRAINT `fk_stock_adjustment_lines_doc` FOREIGN KEY (`stock_adjustment_id`) REFERENCES `stock_adjustments` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_stock_adjustment_lines_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_stock_adjustment_lines_serial` FOREIGN KEY (`serial_id`) REFERENCES `stock_serials` (`id`),
  ADD CONSTRAINT `fk_stock_adjustment_lines_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`),
  ADD CONSTRAINT `fk_stock_adjustment_lines_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `stock_balances`
--
ALTER TABLE `stock_balances`
  ADD CONSTRAINT `fk_stock_balances_batch` FOREIGN KEY (`batch_id`) REFERENCES `stock_batches` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_stock_balances_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_stock_balances_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_stock_balances_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_stock_balances_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_stock_balances_serial` FOREIGN KEY (`serial_id`) REFERENCES `stock_serials` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_stock_balances_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_stock_balances_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

--
-- Constraints for table `stock_batches`
--
ALTER TABLE `stock_batches`
  ADD CONSTRAINT `fk_stock_batches_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_stock_batches_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `stock_damage_entries`
--
ALTER TABLE `stock_damage_entries`
  ADD CONSTRAINT `fk_stock_damage_entries_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_stock_damage_entries_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_stock_damage_entries_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_stock_damage_entries_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_stock_damage_entries_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_stock_damage_entries_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_stock_damage_entries_posted_by` FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_stock_damage_entries_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_stock_damage_entries_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`),
  ADD CONSTRAINT `fk_stock_damage_entries_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `stock_damage_lines`
--
ALTER TABLE `stock_damage_lines`
  ADD CONSTRAINT `fk_stock_damage_lines_batch` FOREIGN KEY (`batch_id`) REFERENCES `stock_batches` (`id`),
  ADD CONSTRAINT `fk_stock_damage_lines_doc` FOREIGN KEY (`stock_damage_entry_id`) REFERENCES `stock_damage_entries` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_stock_damage_lines_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_stock_damage_lines_serial` FOREIGN KEY (`serial_id`) REFERENCES `stock_serials` (`id`),
  ADD CONSTRAINT `fk_stock_damage_lines_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`);

--
-- Constraints for table `stock_issues`
--
ALTER TABLE `stock_issues`
  ADD CONSTRAINT `fk_stock_issues_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_stock_issues_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_stock_issues_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_stock_issues_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_stock_issues_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_stock_issues_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_stock_issues_posted_by` FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_stock_issues_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_stock_issues_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`),
  ADD CONSTRAINT `fk_stock_issues_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `stock_issue_lines`
--
ALTER TABLE `stock_issue_lines`
  ADD CONSTRAINT `fk_stock_issue_lines_batch` FOREIGN KEY (`batch_id`) REFERENCES `stock_batches` (`id`),
  ADD CONSTRAINT `fk_stock_issue_lines_doc` FOREIGN KEY (`stock_issue_id`) REFERENCES `stock_issues` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_stock_issue_lines_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_stock_issue_lines_serial` FOREIGN KEY (`serial_id`) REFERENCES `stock_serials` (`id`),
  ADD CONSTRAINT `fk_stock_issue_lines_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`);

--
-- Constraints for table `stock_movements`
--
ALTER TABLE `stock_movements`
  ADD CONSTRAINT `fk_stock_movements_batch` FOREIGN KEY (`batch_id`) REFERENCES `stock_batches` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_stock_movements_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_stock_movements_cancelled_by` FOREIGN KEY (`cancelled_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_stock_movements_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_stock_movements_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_stock_movements_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_stock_movements_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_stock_movements_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_stock_movements_posted_by` FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_stock_movements_serial` FOREIGN KEY (`serial_id`) REFERENCES `stock_serials` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_stock_movements_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_stock_movements_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_stock_movements_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

--
-- Constraints for table `stock_openings`
--
ALTER TABLE `stock_openings`
  ADD CONSTRAINT `fk_stock_openings_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_stock_openings_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_stock_openings_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_stock_openings_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_stock_openings_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_stock_openings_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_stock_openings_posted_by` FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_stock_openings_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_stock_openings_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`);

--
-- Constraints for table `stock_opening_lines`
--
ALTER TABLE `stock_opening_lines`
  ADD CONSTRAINT `fk_stock_adjustments_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`),
  ADD CONSTRAINT `fk_stock_opening_lines_batch` FOREIGN KEY (`batch_id`) REFERENCES `stock_batches` (`id`),
  ADD CONSTRAINT `fk_stock_opening_lines_doc` FOREIGN KEY (`stock_opening_id`) REFERENCES `stock_openings` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_stock_opening_lines_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_stock_opening_lines_serial` FOREIGN KEY (`serial_id`) REFERENCES `stock_serials` (`id`),
  ADD CONSTRAINT `fk_stock_opening_lines_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`),
  ADD CONSTRAINT `fk_stock_opening_lines_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `stock_physical_counts`
--
ALTER TABLE `stock_physical_counts`
  ADD CONSTRAINT `fk_stock_physical_counts_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_stock_physical_counts_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_stock_physical_counts_counted_by` FOREIGN KEY (`counted_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_stock_physical_counts_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_stock_physical_counts_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_stock_physical_counts_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_stock_physical_counts_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_stock_physical_counts_reconciled_by` FOREIGN KEY (`reconciled_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_stock_physical_counts_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_stock_physical_counts_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`),
  ADD CONSTRAINT `fk_stock_physical_counts_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `stock_physical_count_lines`
--
ALTER TABLE `stock_physical_count_lines`
  ADD CONSTRAINT `fk_stock_physical_count_lines_batch` FOREIGN KEY (`batch_id`) REFERENCES `stock_batches` (`id`),
  ADD CONSTRAINT `fk_stock_physical_count_lines_doc` FOREIGN KEY (`stock_physical_count_id`) REFERENCES `stock_physical_counts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_stock_physical_count_lines_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_stock_physical_count_lines_serial` FOREIGN KEY (`serial_id`) REFERENCES `stock_serials` (`id`),
  ADD CONSTRAINT `fk_stock_physical_count_lines_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`);

--
-- Constraints for table `stock_receipts_internal`
--
ALTER TABLE `stock_receipts_internal`
  ADD CONSTRAINT `fk_stock_receipts_internal_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_stock_receipts_internal_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_stock_receipts_internal_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_stock_receipts_internal_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_stock_receipts_internal_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_stock_receipts_internal_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_stock_receipts_internal_posted_by` FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_stock_receipts_internal_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_stock_receipts_internal_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`),
  ADD CONSTRAINT `fk_stock_receipts_internal_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Constraints for table `stock_receipt_internal_lines`
--
ALTER TABLE `stock_receipt_internal_lines`
  ADD CONSTRAINT `fk_stock_receipt_internal_lines_batch` FOREIGN KEY (`batch_id`) REFERENCES `stock_batches` (`id`),
  ADD CONSTRAINT `fk_stock_receipt_internal_lines_doc` FOREIGN KEY (`stock_receipt_internal_id`) REFERENCES `stock_receipts_internal` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_stock_receipt_internal_lines_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_stock_receipt_internal_lines_serial` FOREIGN KEY (`serial_id`) REFERENCES `stock_serials` (`id`),
  ADD CONSTRAINT `fk_stock_receipt_internal_lines_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`);

--
-- Constraints for table `stock_serials`
--
ALTER TABLE `stock_serials`
  ADD CONSTRAINT `fk_stock_serials_batch` FOREIGN KEY (`batch_id`) REFERENCES `stock_batches` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_stock_serials_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_stock_serials_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `stock_transfers`
--
ALTER TABLE `stock_transfers`
  ADD CONSTRAINT `fk_stock_transfers_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  ADD CONSTRAINT `fk_stock_transfers_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  ADD CONSTRAINT `fk_stock_transfers_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_stock_transfers_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`),
  ADD CONSTRAINT `fk_stock_transfers_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`),
  ADD CONSTRAINT `fk_stock_transfers_from_warehouse` FOREIGN KEY (`from_warehouse_id`) REFERENCES `warehouses` (`id`),
  ADD CONSTRAINT `fk_stock_transfers_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`),
  ADD CONSTRAINT `fk_stock_transfers_posted_by` FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_stock_transfers_received_by` FOREIGN KEY (`received_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_stock_transfers_to_warehouse` FOREIGN KEY (`to_warehouse_id`) REFERENCES `warehouses` (`id`),
  ADD CONSTRAINT `fk_stock_transfers_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_stock_transfers_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`);

--
-- Constraints for table `stock_transfer_lines`
--
ALTER TABLE `stock_transfer_lines`
  ADD CONSTRAINT `fk_stock_transfer_lines_doc` FOREIGN KEY (`stock_transfer_id`) REFERENCES `stock_transfers` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_stock_transfer_lines_from_batch` FOREIGN KEY (`from_batch_id`) REFERENCES `stock_batches` (`id`),
  ADD CONSTRAINT `fk_stock_transfer_lines_from_serial` FOREIGN KEY (`from_serial_id`) REFERENCES `stock_serials` (`id`),
  ADD CONSTRAINT `fk_stock_transfer_lines_item` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `fk_stock_transfer_lines_to_batch` FOREIGN KEY (`to_batch_id`) REFERENCES `stock_batches` (`id`),
  ADD CONSTRAINT `fk_stock_transfer_lines_to_serial` FOREIGN KEY (`to_serial_id`) REFERENCES `stock_serials` (`id`),
  ADD CONSTRAINT `fk_stock_transfer_lines_uom` FOREIGN KEY (`uom_id`) REFERENCES `uoms` (`id`);

--
-- Constraints for table `tax_codes`
--
ALTER TABLE `tax_codes`
  ADD CONSTRAINT `fk_tax_codes_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_tax_codes_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `uoms`
--
ALTER TABLE `uoms`
  ADD CONSTRAINT `fk_uoms_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_uoms_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `uom_conversions`
--
ALTER TABLE `uom_conversions`
  ADD CONSTRAINT `fk_uom_conversions_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_uom_conversions_from` FOREIGN KEY (`from_uom_id`) REFERENCES `uoms` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_uom_conversions_to` FOREIGN KEY (`to_uom_id`) REFERENCES `uoms` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_uom_conversions_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `fk_users_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_users_employee` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_users_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `user_branch_access`
--
ALTER TABLE `user_branch_access`
  ADD CONSTRAINT `fk_user_branch_access_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_user_branch_access_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_user_branch_access_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_user_branch_access_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `user_company_access`
--
ALTER TABLE `user_company_access`
  ADD CONSTRAINT `fk_user_company_access_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_user_company_access_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_user_company_access_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_user_company_access_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `user_location_access`
--
ALTER TABLE `user_location_access`
  ADD CONSTRAINT `fk_user_location_access_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_user_location_access_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_user_location_access_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_user_location_access_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `user_module_preferences`
--
ALTER TABLE `user_module_preferences`
  ADD CONSTRAINT `fk_user_module_preferences_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_user_module_preferences_module` FOREIGN KEY (`module_code`) REFERENCES `modules` (`module_code`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_user_module_preferences_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_user_module_preferences_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `user_permissions`
--
ALTER TABLE `user_permissions`
  ADD CONSTRAINT `fk_user_permissions_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_user_permissions_permission` FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_user_permissions_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_user_permissions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `user_roles`
--
ALTER TABLE `user_roles`
  ADD CONSTRAINT `fk_user_roles_assigned_by` FOREIGN KEY (`assigned_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_user_roles_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_user_roles_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_user_roles_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_user_roles_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `user_warehouse_access`
--
ALTER TABLE `user_warehouse_access`
  ADD CONSTRAINT `fk_user_warehouse_access_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_user_warehouse_access_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_user_warehouse_access_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_user_warehouse_access_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `vouchers`
--
ALTER TABLE `vouchers`
  ADD CONSTRAINT `fk_vouchers_adjustment_account` FOREIGN KEY (`adjustment_account_id`) REFERENCES `accounts` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_vouchers_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_vouchers_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_vouchers_cancelled_by` FOREIGN KEY (`cancelled_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_vouchers_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_vouchers_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_vouchers_document_series` FOREIGN KEY (`document_series_id`) REFERENCES `document_series` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_vouchers_financial_year` FOREIGN KEY (`financial_year_id`) REFERENCES `financial_years` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_vouchers_location` FOREIGN KEY (`location_id`) REFERENCES `business_locations` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_vouchers_posted_by` FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_vouchers_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_vouchers_voucher_type` FOREIGN KEY (`voucher_type_id`) REFERENCES `voucher_types` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

--
-- Constraints for table `voucher_allocations`
--
ALTER TABLE `voucher_allocations`
  ADD CONSTRAINT `fk_voucher_allocations_against_voucher` FOREIGN KEY (`against_voucher_id`) REFERENCES `vouchers` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_voucher_allocations_against_voucher_line` FOREIGN KEY (`against_voucher_line_id`) REFERENCES `voucher_lines` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_voucher_allocations_voucher_line` FOREIGN KEY (`voucher_line_id`) REFERENCES `voucher_lines` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `voucher_lines`
--
ALTER TABLE `voucher_lines`
  ADD CONSTRAINT `fk_voucher_lines_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_voucher_lines_party` FOREIGN KEY (`party_id`) REFERENCES `parties` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_voucher_lines_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `voucher_types`
--
ALTER TABLE `voucher_types`
  ADD CONSTRAINT `fk_voucher_types_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_voucher_types_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

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
