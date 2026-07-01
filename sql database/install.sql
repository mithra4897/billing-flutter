-- Active: 1776817165285@@127.0.0.1@3306@billing
-- =========================================================
-- MODULE 1A : CORE ORGANIZATION
-- ERP FOUNDATION - MySQL 8
-- =========================================================

-- Recommended before running:
-- CREATE DATABASE erp_core CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- USE erp_core;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- 1. COMPANIES
-- =========================================================
DROP TABLE IF EXISTS companies;

CREATE TABLE companies (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code VARCHAR(20) NOT NULL,
    legal_name VARCHAR(255) NOT NULL,
    trade_name VARCHAR(255) NULL,
    company_type ENUM('proprietorship', 'partnership', 'llp', 'private_limited', 'public_limited', 'trust', 'society', 'other') DEFAULT 'proprietorship',

    gstin VARCHAR(15) NULL,
    pan VARCHAR(10) NULL,
    tan VARCHAR(10) NULL,
    cin VARCHAR(21) NULL,

    phone VARCHAR(20) NULL,
    email VARCHAR(150) NULL,
    website VARCHAR(255) NULL,

    address_line1 VARCHAR(255) NULL,
    address_line2 VARCHAR(255) NULL,
    area VARCHAR(150) NULL,
    city VARCHAR(100) NULL,
    district VARCHAR(100) NULL,
    state_code VARCHAR(5) NULL,
    state_name VARCHAR(100) NULL,
    country_code VARCHAR(5) DEFAULT 'IN',
    postal_code VARCHAR(20) NULL,

    base_currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    timezone VARCHAR(50) NOT NULL DEFAULT 'Asia/Kolkata',

    logo_path VARCHAR(500) NULL,
    seal_path VARCHAR(500) NULL,
    letter_head_path VARCHAR(500) NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,
    remarks TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_companies_code (code),
    UNIQUE KEY uq_companies_gstin (gstin),
    UNIQUE KEY uq_companies_pan (pan),
    INDEX idx_companies_legal_name (legal_name),
    INDEX idx_companies_trade_name (trade_name),
    INDEX idx_companies_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 2. BRANCHES
-- =========================================================
DROP TABLE IF EXISTS branches;

CREATE TABLE branches (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    company_id BIGINT UNSIGNED NOT NULL,

    code VARCHAR(20) NOT NULL,
    name VARCHAR(255) NOT NULL,
    branch_type ENUM('head_office', 'branch_office', 'factory', 'warehouse_office', 'retail_outlet', 'service_center', 'other') DEFAULT 'branch_office',

    is_head_office TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    remarks TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_branches_company_code (company_id, code),
    UNIQUE KEY uq_branches_company_name (company_id, name),
    INDEX idx_branches_company_id (company_id),
    INDEX idx_branches_is_head_office (is_head_office),
    INDEX idx_branches_is_active (is_active),

    CONSTRAINT fk_branches_company
        FOREIGN KEY (company_id) REFERENCES companies(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 3. BUSINESS LOCATIONS
-- Purpose:
-- Actual transaction points:
-- showroom / billing counter / office / plant / outlet
-- =========================================================
DROP TABLE IF EXISTS business_locations;

CREATE TABLE business_locations (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,

    code VARCHAR(20) NOT NULL,
    name VARCHAR(255) NOT NULL,
    location_type ENUM('billing', 'warehouse', 'office', 'factory', 'retail', 'service', 'jobwork', 'other') DEFAULT 'billing',

    contact_person VARCHAR(150) NULL,
    phone VARCHAR(20) NULL,
    email VARCHAR(150) NULL,

    address_line1 VARCHAR(255) NULL,
    address_line2 VARCHAR(255) NULL,
    area VARCHAR(150) NULL,
    city VARCHAR(100) NULL,
    district VARCHAR(100) NULL,
    state_code VARCHAR(5) NULL,
    state_name VARCHAR(100) NULL,
    country_code VARCHAR(5) DEFAULT 'IN',
    postal_code VARCHAR(20) NULL,

    latitude DECIMAL(10,7) NULL,
    longitude DECIMAL(10,7) NULL,

    allow_sales TINYINT(1) NOT NULL DEFAULT 1,
    allow_purchase TINYINT(1) NOT NULL DEFAULT 1,
    allow_stock TINYINT(1) NOT NULL DEFAULT 1,
    allow_accounts TINYINT(1) NOT NULL DEFAULT 1,
    allow_hr TINYINT(1) NOT NULL DEFAULT 1,

    is_default TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    remarks TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_locations_branch_code (branch_id, code),
    UNIQUE KEY uq_locations_branch_name (branch_id, name),
    INDEX idx_locations_company_id (company_id),
    INDEX idx_locations_branch_id (branch_id),
    INDEX idx_locations_type (location_type),
    INDEX idx_locations_is_default (is_default),
    INDEX idx_locations_is_active (is_active),

    CONSTRAINT fk_locations_company
        FOREIGN KEY (company_id) REFERENCES companies(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_locations_branch
        FOREIGN KEY (branch_id) REFERENCES branches(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 4. WAREHOUSES
-- Purpose:
-- Physical stock storage units under a business location
-- Example:
-- Main Store, Finished Goods, Raw Material Store, Damage Store
-- =========================================================
DROP TABLE IF EXISTS warehouses;

CREATE TABLE warehouses (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,

    code VARCHAR(20) NOT NULL,
    name VARCHAR(255) NOT NULL,
    warehouse_type ENUM('main', 'raw_material', 'finished_goods', 'wip', 'damage', 'returns', 'transit', 'jobwork', 'other') DEFAULT 'main',

    parent_warehouse_id BIGINT UNSIGNED NULL,

    allow_negative_stock TINYINT(1) NOT NULL DEFAULT 0,
    is_sellable_stock TINYINT(1) NOT NULL DEFAULT 1,
    is_reserved_only TINYINT(1) NOT NULL DEFAULT 0,
    is_default TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    remarks TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_warehouses_location_code (location_id, code),
    UNIQUE KEY uq_warehouses_location_name (location_id, name),
    INDEX idx_warehouses_company_id (company_id),
    INDEX idx_warehouses_branch_id (branch_id),
    INDEX idx_warehouses_location_id (location_id),
    INDEX idx_warehouses_parent (parent_warehouse_id),
    INDEX idx_warehouses_type (warehouse_type),
    INDEX idx_warehouses_is_default (is_default),
    INDEX idx_warehouses_is_active (is_active),

    CONSTRAINT fk_warehouses_company
        FOREIGN KEY (company_id) REFERENCES companies(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_warehouses_branch
        FOREIGN KEY (branch_id) REFERENCES branches(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_warehouses_location
        FOREIGN KEY (location_id) REFERENCES business_locations(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_warehouses_parent
        FOREIGN KEY (parent_warehouse_id) REFERENCES warehouses(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 5. FINANCIAL YEARS
-- =========================================================
DROP TABLE IF EXISTS financial_years;

CREATE TABLE financial_years (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    company_id BIGINT UNSIGNED NOT NULL,

    fy_code VARCHAR(20) NOT NULL,
    fy_name VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,

    is_current TINYINT(1) NOT NULL DEFAULT 0,
    is_locked TINYINT(1) NOT NULL DEFAULT 0,
    lock_date DATE NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,
    remarks TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_financial_years_company_code (company_id, fy_code),
    UNIQUE KEY uq_financial_years_company_name (company_id, fy_name),
    INDEX idx_financial_years_company_id (company_id),
    INDEX idx_financial_years_dates (start_date, end_date),
    INDEX idx_financial_years_is_current (is_current),
    INDEX idx_financial_years_is_locked (is_locked),
    INDEX idx_financial_years_is_active (is_active),

    CONSTRAINT fk_financial_years_company
        FOREIGN KEY (company_id) REFERENCES companies(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT chk_financial_year_dates
        CHECK (start_date <= end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 6. DOCUMENT SERIES
-- Purpose:
-- numbering control for invoice/order/voucher documents
-- Example:
-- SI/2025-26/00001
-- PO/2025-26/00001
-- JV/2025-26/00001
-- =========================================================
DROP TABLE IF EXISTS document_series;

CREATE TABLE document_series (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NULL,
    location_id BIGINT UNSIGNED NULL,
    financial_year_id BIGINT UNSIGNED NULL,

    document_type VARCHAR(50) NOT NULL,
    series_name VARCHAR(100) NOT NULL,
    prefix VARCHAR(50) NULL,
    suffix VARCHAR(50) NULL,

    next_number BIGINT UNSIGNED NOT NULL DEFAULT 1,
    number_length INT NOT NULL DEFAULT 5,

    reset_policy ENUM('never', 'financial_year', 'calendar_year', 'monthly') NOT NULL DEFAULT 'financial_year',

    is_default TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    remarks TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_document_series_unique (
        company_id,
        branch_id,
        location_id,
        financial_year_id,
        document_type,
        series_name
    ),
    INDEX idx_document_series_company_id (company_id),
    INDEX idx_document_series_branch_id (branch_id),
    INDEX idx_document_series_location_id (location_id),
    INDEX idx_document_series_financial_year_id (financial_year_id),
    INDEX idx_document_series_doc_type (document_type),
    INDEX idx_document_series_is_default (is_default),
    INDEX idx_document_series_is_active (is_active),

    CONSTRAINT fk_document_series_company
        FOREIGN KEY (company_id) REFERENCES companies(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_document_series_branch
        FOREIGN KEY (branch_id) REFERENCES branches(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_document_series_location
        FOREIGN KEY (location_id) REFERENCES business_locations(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_document_series_financial_year
        FOREIGN KEY (financial_year_id) REFERENCES financial_years(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 7. PRINT TEMPLATES
-- =========================================================
DROP TABLE IF EXISTS print_templates;

CREATE TABLE print_templates (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    document_type VARCHAR(50) NOT NULL,
    template_data JSON NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_print_templates_doc_type (document_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- FIRST-RUN NOTE
-- =========================================================
-- Company, branch, location, warehouse, financial year, document series,
-- first admin user, and company-specific ledgers are created by the
-- application installer after the schema import is completed.

SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================
-- MODULE 1B : USERS / ROLES / PERMISSIONS / ACCESS CONTROL
-- ERP FOUNDATION - MySQL 8
-- Depends on MODULE 1A
-- =========================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- 1. USERS
-- Purpose:
-- System login users only
-- (Employees / customers / suppliers are NOT stored here directly)
-- =========================================================
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    employee_id BIGINT UNSIGNED NULL,
    employee_code VARCHAR(30) NULL,
    username VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,

    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NULL,
    display_name VARCHAR(200) NULL,

    email VARCHAR(150) NULL,
    mobile VARCHAR(20) NULL,

    gender ENUM('male', 'female', 'other', 'prefer_not_to_say') NULL,
    date_of_birth DATE NULL,

    profile_photo_path VARCHAR(500) NULL,

    is_super_admin TINYINT(1) NOT NULL DEFAULT 0,
    is_system_user TINYINT(1) NOT NULL DEFAULT 1,
    must_change_password TINYINT(1) NOT NULL DEFAULT 0,

    last_login_at DATETIME NULL,
    last_password_changed_at DATETIME NULL,

    failed_login_attempts INT NOT NULL DEFAULT 0,
    locked_until DATETIME NULL,

    status ENUM('active', 'inactive', 'suspended', 'blocked') NOT NULL DEFAULT 'active',
    remarks TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_users_username (username),
    UNIQUE KEY uq_users_email (email),
    UNIQUE KEY uq_users_mobile (mobile),
    UNIQUE KEY uq_users_employee_id (employee_id),
    UNIQUE KEY uq_users_employee_code (employee_code),

    INDEX idx_users_employee_id (employee_id),
    INDEX idx_users_first_name (first_name),
    INDEX idx_users_last_name (last_name),
    INDEX idx_users_display_name (display_name),
    INDEX idx_users_status (status),
    INDEX idx_users_is_super_admin (is_super_admin),

    CONSTRAINT fk_users_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_users_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 2. ROLES
-- Purpose:
-- Access profiles like Admin / Accountant / Sales / Store
-- =========================================================
DROP TABLE IF EXISTS roles;

CREATE TABLE roles (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    code VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT NULL,

    is_system_role TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_roles_code (code),
    UNIQUE KEY uq_roles_name (name),
    INDEX idx_roles_is_system_role (is_system_role),
    INDEX idx_roles_is_active (is_active),

    CONSTRAINT fk_roles_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_roles_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 3. MODULES
-- Purpose:
-- Top-level application navigation and menu ordering
-- =========================================================
DROP TABLE IF EXISTS modules;

CREATE TABLE modules (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    module_code VARCHAR(50) NOT NULL,
    module_name VARCHAR(100) NOT NULL,
    module_group VARCHAR(100) NULL,
    route_path VARCHAR(150) NULL,
    icon_key VARCHAR(100) NULL,
    description TEXT NULL,
    sort_order INT NOT NULL DEFAULT 0,

    is_system TINYINT(1) NOT NULL DEFAULT 1,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_modules_code (module_code),
    INDEX idx_modules_sort_order (sort_order),
    INDEX idx_modules_is_active (is_active),

    CONSTRAINT fk_modules_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_modules_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 4. USER MENU PREFERENCES
-- Purpose:
-- Per-user override of top-level menu order / visibility
-- =========================================================
DROP TABLE IF EXISTS user_module_preferences;

CREATE TABLE user_module_preferences (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    user_id BIGINT UNSIGNED NOT NULL,
    module_code VARCHAR(50) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    is_hidden TINYINT(1) NOT NULL DEFAULT 0,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_user_module_preferences_user_module (user_id, module_code),
    INDEX idx_user_module_preferences_sort_order (sort_order),
    INDEX idx_user_module_preferences_is_hidden (is_hidden),

    CONSTRAINT fk_user_module_preferences_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_user_module_preferences_module
        FOREIGN KEY (module_code) REFERENCES modules(module_code)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_user_module_preferences_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_user_module_preferences_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 5. PERMISSIONS
-- Purpose:
-- Fine-grained access control
-- Example:
-- sales.invoice.create
-- purchase.order.approve
-- accounts.voucher.post
-- =========================================================
DROP TABLE IF EXISTS permissions;

CREATE TABLE permissions (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    module VARCHAR(50) NOT NULL,
    code VARCHAR(100) NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT NULL,

    is_system_permission TINYINT(1) NOT NULL DEFAULT 1,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_permissions_code (code),
    INDEX idx_permissions_module (module),
    INDEX idx_permissions_name (name),
    INDEX idx_permissions_is_active (is_active),

    CONSTRAINT fk_permissions_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_permissions_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 6. ROLE PERMISSIONS
-- Purpose:
-- Which permission belongs to which role
-- =========================================================
DROP TABLE IF EXISTS role_permissions;

CREATE TABLE role_permissions (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    role_id BIGINT UNSIGNED NOT NULL,
    permission_id BIGINT UNSIGNED NOT NULL,

    allow_view TINYINT(1) NOT NULL DEFAULT 0,
    allow_create TINYINT(1) NOT NULL DEFAULT 0,
    allow_update TINYINT(1) NOT NULL DEFAULT 0,
    allow_delete TINYINT(1) NOT NULL DEFAULT 0,
    allow_approve TINYINT(1) NOT NULL DEFAULT 0,
    allow_print TINYINT(1) NOT NULL DEFAULT 0,
    allow_export TINYINT(1) NOT NULL DEFAULT 0,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_role_permissions_role_permission (role_id, permission_id),
    INDEX idx_role_permissions_role_id (role_id),
    INDEX idx_role_permissions_permission_id (permission_id),
    INDEX idx_role_permissions_is_active (is_active),

    CONSTRAINT fk_role_permissions_role
        FOREIGN KEY (role_id) REFERENCES roles(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_role_permissions_permission
        FOREIGN KEY (permission_id) REFERENCES permissions(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_role_permissions_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_role_permissions_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 7. USER DIRECT PERMISSIONS
-- Purpose:
-- User-specific permission overrides / additions beyond assigned roles
-- =========================================================
DROP TABLE IF EXISTS user_permissions;

CREATE TABLE user_permissions (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    user_id BIGINT UNSIGNED NOT NULL,
    permission_id BIGINT UNSIGNED NOT NULL,

    allow_view TINYINT(1) NOT NULL DEFAULT 0,
    allow_create TINYINT(1) NOT NULL DEFAULT 0,
    allow_update TINYINT(1) NOT NULL DEFAULT 0,
    allow_delete TINYINT(1) NOT NULL DEFAULT 0,
    allow_approve TINYINT(1) NOT NULL DEFAULT 0,
    allow_print TINYINT(1) NOT NULL DEFAULT 0,
    allow_export TINYINT(1) NOT NULL DEFAULT 0,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_user_permissions_user_permission (user_id, permission_id),
    INDEX idx_user_permissions_user_id (user_id),
    INDEX idx_user_permissions_permission_id (permission_id),
    INDEX idx_user_permissions_is_active (is_active),

    CONSTRAINT fk_user_permissions_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_user_permissions_permission
        FOREIGN KEY (permission_id) REFERENCES permissions(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_user_permissions_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_user_permissions_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 8. USER ROLES
-- Purpose:
-- One user can have one or more roles
-- =========================================================
DROP TABLE IF EXISTS user_roles;

CREATE TABLE user_roles (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    user_id BIGINT UNSIGNED NOT NULL,
    role_id BIGINT UNSIGNED NOT NULL,

    is_primary_role TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    assigned_by BIGINT UNSIGNED NULL,
    assigned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_user_roles_user_role (user_id, role_id),
    INDEX idx_user_roles_user_id (user_id),
    INDEX idx_user_roles_role_id (role_id),
    INDEX idx_user_roles_is_primary_role (is_primary_role),
    INDEX idx_user_roles_is_active (is_active),

    CONSTRAINT fk_user_roles_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_user_roles_role
        FOREIGN KEY (role_id) REFERENCES roles(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_user_roles_assigned_by
        FOREIGN KEY (assigned_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_user_roles_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_user_roles_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 6. USER COMPANY ACCESS
-- Purpose:
-- Which companies a user can access
-- =========================================================
DROP TABLE IF EXISTS user_company_access;

CREATE TABLE user_company_access (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    user_id BIGINT UNSIGNED NOT NULL,
    company_id BIGINT UNSIGNED NOT NULL,

    is_default TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_user_company_access (user_id, company_id),
    INDEX idx_user_company_access_user_id (user_id),
    INDEX idx_user_company_access_company_id (company_id),
    INDEX idx_user_company_access_is_default (is_default),
    INDEX idx_user_company_access_is_active (is_active),

    CONSTRAINT fk_user_company_access_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_user_company_access_company
        FOREIGN KEY (company_id) REFERENCES companies(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_user_company_access_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_user_company_access_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 7. USER BRANCH ACCESS
-- Purpose:
-- Which branches a user can access
-- =========================================================
DROP TABLE IF EXISTS user_branch_access;

CREATE TABLE user_branch_access (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    user_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,

    is_default TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_user_branch_access (user_id, branch_id),
    INDEX idx_user_branch_access_user_id (user_id),
    INDEX idx_user_branch_access_branch_id (branch_id),
    INDEX idx_user_branch_access_is_default (is_default),
    INDEX idx_user_branch_access_is_active (is_active),

    CONSTRAINT fk_user_branch_access_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_user_branch_access_branch
        FOREIGN KEY (branch_id) REFERENCES branches(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_user_branch_access_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_user_branch_access_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 8. USER LOCATION ACCESS
-- Purpose:
-- Which business locations a user can access
-- =========================================================
DROP TABLE IF EXISTS user_location_access;

CREATE TABLE user_location_access (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    user_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,

    is_default TINYINT(1) NOT NULL DEFAULT 0,
    can_bill TINYINT(1) NOT NULL DEFAULT 1,
    can_purchase TINYINT(1) NOT NULL DEFAULT 1,
    can_stock_entry TINYINT(1) NOT NULL DEFAULT 1,
    can_accounts_entry TINYINT(1) NOT NULL DEFAULT 1,
    can_hr_entry TINYINT(1) NOT NULL DEFAULT 1,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_user_location_access (user_id, location_id),
    INDEX idx_user_location_access_user_id (user_id),
    INDEX idx_user_location_access_location_id (location_id),
    INDEX idx_user_location_access_is_default (is_default),
    INDEX idx_user_location_access_is_active (is_active),

    CONSTRAINT fk_user_location_access_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_user_location_access_location
        FOREIGN KEY (location_id) REFERENCES business_locations(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_user_location_access_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_user_location_access_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 9. USER WAREHOUSE ACCESS
-- Purpose:
-- Restrict warehouse-wise stock access
-- =========================================================
DROP TABLE IF EXISTS user_warehouse_access;

CREATE TABLE user_warehouse_access (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    user_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NOT NULL,

    is_default TINYINT(1) NOT NULL DEFAULT 0,
    can_view_stock TINYINT(1) NOT NULL DEFAULT 1,
    can_stock_in TINYINT(1) NOT NULL DEFAULT 1,
    can_stock_out TINYINT(1) NOT NULL DEFAULT 1,
    can_transfer TINYINT(1) NOT NULL DEFAULT 1,
    can_adjust TINYINT(1) NOT NULL DEFAULT 1,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_user_warehouse_access (user_id, warehouse_id),
    INDEX idx_user_warehouse_access_user_id (user_id),
    INDEX idx_user_warehouse_access_warehouse_id (warehouse_id),
    INDEX idx_user_warehouse_access_is_default (is_default),
    INDEX idx_user_warehouse_access_is_active (is_active),

    CONSTRAINT fk_user_warehouse_access_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_user_warehouse_access_warehouse
        FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_user_warehouse_access_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_user_warehouse_access_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 10. LOGIN HISTORY
-- Purpose:
-- Login/logout records for audit/security
-- =========================================================
DROP TABLE IF EXISTS login_history;

CREATE TABLE login_history (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    user_id BIGINT UNSIGNED NOT NULL,

    login_at DATETIME NOT NULL,
    logout_at DATETIME NULL,

    login_status ENUM('success', 'failed', 'blocked') NOT NULL DEFAULT 'success',

    ip_address VARCHAR(45) NULL,
    host_name VARCHAR(255) NULL,
    user_agent TEXT NULL,
    device_type VARCHAR(100) NULL,
    browser VARCHAR(100) NULL,
    os VARCHAR(100) NULL,

    session_token VARCHAR(255) NULL,
    remarks TEXT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    INDEX idx_login_history_user_id (user_id),
    INDEX idx_login_history_login_at (login_at),
    INDEX idx_login_history_logout_at (logout_at),
    INDEX idx_login_history_login_status (login_status),
    INDEX idx_login_history_ip_address (ip_address),

    CONSTRAINT fk_login_history_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 11. AUDIT LOGS
-- Purpose:
-- Track create/update/delete/approve/post actions
-- =========================================================
DROP TABLE IF EXISTS audit_logs;

CREATE TABLE audit_logs (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    user_id BIGINT UNSIGNED NULL,

    company_id BIGINT UNSIGNED NULL,
    branch_id BIGINT UNSIGNED NULL,
    location_id BIGINT UNSIGNED NULL,

    module VARCHAR(50) NOT NULL,
    entity_name VARCHAR(100) NOT NULL,
    entity_id VARCHAR(100) NOT NULL,

    action ENUM(
        'create',
        'update',
        'delete',
        'restore',
        'approve',
        'reject',
        'post',
        'cancel',
        'print',
        'export',
        'login',
        'logout'
    ) NOT NULL,

    description TEXT NULL,

    old_values JSON NULL,
    new_values JSON NULL,

    ip_address VARCHAR(45) NULL,
    host_name VARCHAR(255) NULL,
    user_agent TEXT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    INDEX idx_audit_logs_user_id (user_id),
    INDEX idx_audit_logs_company_id (company_id),
    INDEX idx_audit_logs_branch_id (branch_id),
    INDEX idx_audit_logs_location_id (location_id),
    INDEX idx_audit_logs_module (module),
    INDEX idx_audit_logs_entity (entity_name, entity_id),
    INDEX idx_audit_logs_action (action),
    INDEX idx_audit_logs_created_at (created_at),

    CONSTRAINT fk_audit_logs_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_audit_logs_company
        FOREIGN KEY (company_id) REFERENCES companies(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_audit_logs_branch
        FOREIGN KEY (branch_id) REFERENCES branches(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_audit_logs_location
        FOREIGN KEY (location_id) REFERENCES business_locations(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- SEED DATA
-- =========================================================

-- ---------------------------------------------------------
-- Roles
-- ---------------------------------------------------------
INSERT INTO roles (code, name, description, is_system_role, is_active)
VALUES
('SUPER_ADMIN', 'Super Admin', 'Full system access', 1, 1),
('ADMIN', 'Administrator', 'Administrative control over ERP', 1, 1),
('ACCOUNTANT', 'Accountant', 'Accounts and finance operations', 1, 1),
('SALES', 'Sales User', 'Sales and customer operations', 1, 1),
('PURCHASE', 'Purchase User', 'Purchase and supplier operations', 1, 1),
('STORE', 'Store User', 'Stock and warehouse operations', 1, 1),
('HR', 'HR User', 'Employee and payroll operations', 1, 1);

-- ---------------------------------------------------------
-- Modules
-- ---------------------------------------------------------
INSERT INTO modules (
    module_code,
    module_name,
    module_group,
    route_path,
    icon_key,
    description,
    sort_order,
    is_system,
    is_active
)
VALUES
('CRM', 'CRM', 'Front Office', '/crm/leads', 'support_agent_outlined', 'Lead, enquiry, and opportunity management', 10, 1, 1),
('SALES', 'Sales', 'Operations', '/sales/quotations', 'point_of_sale_outlined', 'Customer quotations, orders, deliveries, invoices, receipts, and returns', 20, 1, 1),
('PURCHASE', 'Purchase', 'Operations', '/purchase/requisitions', 'shopping_cart_outlined', 'Purchase requisitions, orders, receipts, invoices, payments, and returns', 30, 1, 1),
('INVENTORY', 'Inventory', 'Operations', '/inventory/items', 'inventory_outlined', 'Inventory item masters, tax codes, UOMs, categories, and stock controls', 40, 1, 1),
('PLANNING', 'Planning', 'Operations', '/planning/mrp-runs', 'route_outlined', 'Stock reservations, policies, MRP runs, and recommendations', 50, 1, 1),
('MANUFACTURING', 'Manufacturing', 'Operations', '/manufacturing/boms', 'factory_outlined', 'BOMs, production orders, material issues, and receipts', 60, 1, 1),
('QUALITY', 'Quality', 'Operations', '/quality/qc-plans', 'verified_outlined', 'Quality planning, inspections, actions, and non-conformance tracking', 70, 1, 1),
('JOBWORK', 'Jobwork', 'Operations', '/jobwork/orders', 'handyman_outlined', 'Subcontract and jobwork dispatch, receipt, and charge tracking', 80, 1, 1),
('SERVICE', 'Service', 'Operations', '/service/contracts', 'miscellaneous_services_outlined', 'After-sales service, warranty claims, tickets, and work orders', 90, 1, 1),
('PROJECTS', 'Projects', 'Operations', '/projects', 'folder_special_outlined', 'Project planning, costing, execution, and billing', 100, 1, 1),
('MAINTENANCE', 'Maintenance', 'Operations', '/maintenance/plans', 'build_circle_outlined', 'Maintenance plans, requests, work orders, downtime, and AMC', 110, 1, 1),
('ASSETS', 'Assets', 'Resources', '/assets/register', 'precision_manufacturing_outlined', 'Asset register, depreciation, transfer, and disposal', 120, 1, 1),
('ACCOUNTING', 'Accounting', 'Finance', '/accounting/accounts', 'account_balance_wallet_outlined', 'Accounting masters, vouchers, budgets, and reports', 130, 1, 1),
('HR', 'HR', 'People', '/hr/employees', 'badge_outlined', 'Employees, attendance, leave, payroll, and expense claims', 140, 1, 1),
('PARTIES', 'Parties', 'Masters', '/parties', 'handshake_outlined', 'Customers, suppliers, contacts, addresses, and commercial terms', 150, 1, 1),
('TAX', 'Tax', 'Compliance', '/tax/states', 'receipt_long_outlined', 'States, GST registrations, rules, and document tax lines', 170, 1, 1),
('COMMUNICATION', 'Communication', 'System', '/communication/email-settings', 'mail_outline', 'Email settings, templates, rules, and messages', 180, 1, 1),
('MEDIA', 'Media', 'System', '/media/files', 'perm_media_outlined', 'Centralized media and file management', 190, 1, 1),
('ADMINISTRATION', 'Administration', 'System', '/admin/users', 'admin_panel_settings_outlined', 'Users, roles, permissions, and access control', 900, 1, 1),
('SETTINGS', 'Settings', 'System', '/settings/companies', 'settings_outlined', 'Company, branch, warehouse, and organization setup', 910, 1, 1);

-- ---------------------------------------------------------
-- Permissions
-- ---------------------------------------------------------
INSERT INTO permissions (module, code, name, description, is_system_permission, is_active)
VALUES
('user', 'user.access', 'User Management', 'Manage user access and maintenance', 1, 1), -- Administration
('role', 'role.access', 'Role Management', 'Manage roles and role assignments', 1, 1),
('permission', 'permission.access', 'Permission Management', 'Manage permission master and mapping', 1, 1),
('company', 'company.access', 'Company', 'Manage company master', 1, 1), -- Master Data
('branch', 'branch.access', 'Branch', 'Manage branch master', 1, 1),
('business_location', 'business_location.access', 'Business Location', 'Manage business location master', 1, 1),
('warehouse', 'warehouse.access', 'Warehouse', 'Manage warehouse master', 1, 1),
('financial_year', 'financial_year.access', 'Financial Year', 'Manage financial year master', 1, 1),
('document_series', 'document_series.access', 'Document Series', 'Manage document series master', 1, 1),
('uom', 'uom.access', 'UOM', 'Manage UOM master', 1, 1),
('tax_code', 'tax_code.access', 'Tax Code', 'Manage tax code master', 1, 1),
('item_category', 'item_category.access', 'Item Category', 'Manage item category master', 1, 1),
('item', 'item.access', 'Item', 'Manage item master', 1, 1),
('party_type', 'party_type.access', 'Party Type', 'Manage party type master', 1, 1),
('party', 'party.access', 'Party', 'Manage party master and related details', 1, 1),
('accounts', 'accounts.access', 'Accounts', 'Manage accounting module operations', 1, 1), -- Module Access
('asset', 'asset.access', 'Asset', 'Manage asset module operations', 1, 1),
('taxes', 'taxes.access', 'Taxes', 'Manage tax module operations', 1, 1),
('inventory', 'inventory.access', 'Inventory', 'Manage inventory module operations', 1, 1),
('maintenance', 'maintenance.access', 'Maintenance', 'Manage maintenance module operations', 1, 1),
('manufacturing', 'manufacturing.access', 'Manufacturing', 'Manage manufacturing module operations', 1, 1),
('jobwork', 'jobwork.access', 'Jobwork', 'Manage jobwork module operations', 1, 1),
('quality', 'quality.access', 'Quality', 'Manage quality module operations', 1, 1),
('mrp', 'mrp.access', 'MRP', 'Manage planning and MRP module operations', 1, 1),
('service', 'service.access', 'Service', 'Manage service module operations', 1, 1),
('crm', 'crm.access', 'CRM', 'Manage CRM module operations', 1, 1),
('hr', 'hr.access', 'HR', 'Manage HR, payroll, and leave module operations', 1, 1),
('project', 'project.access', 'Project', 'Manage project planning, costing, and billing operations', 1, 1),
('communication', 'communication.access', 'Communication', 'Manage email communication, templates, rules, and delivery logs', 1, 1),
('media', 'media.access', 'Media Library', 'Manage uploaded images, logos, and document media files', 1, 1),
('sales', 'sales.access', 'Sales', 'Manage sales module operations', 1, 1),
('purchase', 'purchase.access', 'Purchase', 'Manage purchase module operations', 1, 1);

-- ---------------------------------------------------------
-- Grant all permissions to SUPER_ADMIN role
-- ---------------------------------------------------------
INSERT INTO role_permissions (
    role_id,
    permission_id,
    allow_view,
    allow_create,
    allow_update,
    allow_delete,
    allow_approve,
    allow_print,
    allow_export,
    is_active
)
SELECT
    r.id,
    p.id,
    1, 1, 1, 1, 1, 1, 1,
    1
FROM roles r
CROSS JOIN permissions p
WHERE r.code = 'SUPER_ADMIN';

-- ---------------------------------------------------------
-- Grant common permissions to ADMIN role
-- ---------------------------------------------------------
INSERT INTO role_permissions (
    role_id,
    permission_id,
    allow_view,
    allow_create,
    allow_update,
    allow_delete,
    allow_approve,
    allow_print,
    allow_export,
    is_active
)
SELECT
    r.id,
    p.id,
    1, 1, 1, 1,
    CASE
        WHEN p.code IN (
            'accounts.voucher.approve'
        ) THEN 1
        ELSE 0
    END,
    1, 1,
    1
FROM roles r
JOIN permissions p
WHERE r.code = 'ADMIN';

SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================
-- MODULE 2 : PARTY MASTER
-- ERP FOUNDATION - MySQL 8
-- =========================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- 1. PARTY TYPES
-- =========================================================
DROP TABLE IF EXISTS party_types;

CREATE TABLE party_types (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    is_system TINYINT(1) DEFAULT 1,
    is_active TINYINT(1) DEFAULT 1,

    UNIQUE KEY uq_party_types_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO party_types (code, name) VALUES
('CUSTOMER', 'Customer'),
('SUPPLIER', 'Supplier'),
('JOB_WORKER', 'Job Worker'),
('TRANSPORTER', 'Transporter'),
('GENERAL', 'General');


-- =========================================================
-- 2. PARTIES (MAIN MASTER)
-- =========================================================
DROP TABLE IF EXISTS parties;

CREATE TABLE parties (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    party_code VARCHAR(50) NOT NULL,
    party_name VARCHAR(255) NOT NULL,
    display_name VARCHAR(255),

    party_type_id BIGINT UNSIGNED NOT NULL,

    is_company TINYINT(1) DEFAULT 0,

    website VARCHAR(255),

    pan VARCHAR(10),
    aadhaar VARCHAR(12),

    default_currency VARCHAR(10) DEFAULT 'INR',

    opening_balance DECIMAL(18,2) DEFAULT 0,
    opening_balance_type ENUM('debit', 'credit') DEFAULT 'debit',

    is_active TINYINT(1) DEFAULT 1,
    remarks TEXT,

    created_by BIGINT UNSIGNED,
    updated_by BIGINT UNSIGNED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uq_parties_code (party_code),
    INDEX idx_parties_name (party_name),

    CONSTRAINT fk_parties_type FOREIGN KEY (party_type_id) REFERENCES party_types(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 3. PARTY ROLES (MULTI ROLE SUPPORT)
-- =========================================================
DROP TABLE IF EXISTS party_roles;

CREATE TABLE party_roles (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    party_id BIGINT UNSIGNED NOT NULL,
    party_type_id BIGINT UNSIGNED NOT NULL,

    is_active TINYINT(1) DEFAULT 1,

    UNIQUE KEY uq_party_roles (party_id, party_type_id),

    CONSTRAINT fk_party_roles_party FOREIGN KEY (party_id) REFERENCES parties(id),
    CONSTRAINT fk_party_roles_type FOREIGN KEY (party_type_id) REFERENCES party_types(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 4. PARTY ADDRESSES
-- =========================================================
DROP TABLE IF EXISTS party_addresses;

CREATE TABLE party_addresses (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    party_id BIGINT UNSIGNED NOT NULL,

    address_type ENUM('billing', 'shipping', 'office', 'factory', 'other') DEFAULT 'billing',

    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    area VARCHAR(150),
    city VARCHAR(100),
    district VARCHAR(100),
    state_code VARCHAR(5),
    state_name VARCHAR(100),
    country_code VARCHAR(5) DEFAULT 'IN',
    postal_code VARCHAR(20),

    is_default TINYINT(1) DEFAULT 0,
    is_active TINYINT(1) DEFAULT 1,

    CONSTRAINT fk_party_addresses_party FOREIGN KEY (party_id) REFERENCES parties(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 5. PARTY CONTACTS
-- =========================================================
DROP TABLE IF EXISTS party_contacts;

CREATE TABLE party_contacts (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    party_id BIGINT UNSIGNED NOT NULL,

    contact_name VARCHAR(150),
    designation VARCHAR(100),

    mobile VARCHAR(20),
    phone VARCHAR(20),
    email VARCHAR(150),

    is_primary TINYINT(1) DEFAULT 0,
    is_active TINYINT(1) DEFAULT 1,

    INDEX idx_party_contacts_name (contact_name),
    INDEX idx_party_contacts_mobile (mobile),
    INDEX idx_party_contacts_email (email),
    INDEX idx_party_contacts_primary (party_id, is_primary),

    CONSTRAINT fk_party_contacts_party FOREIGN KEY (party_id) REFERENCES parties(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 6. PARTY GST DETAILS
-- =========================================================
DROP TABLE IF EXISTS party_gst_details;

CREATE TABLE party_gst_details (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    party_id BIGINT UNSIGNED NOT NULL,

    gstin VARCHAR(15),
    legal_name VARCHAR(255),
    trade_name VARCHAR(255),

    state_code VARCHAR(5),
    state_name VARCHAR(100),
    registration_type VARCHAR(50),

    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    district VARCHAR(100),
    postal_code VARCHAR(20),

    is_default TINYINT(1) DEFAULT 1,
    is_active TINYINT(1) DEFAULT 1,

    UNIQUE KEY uq_party_gst_details_gstin (gstin),
    INDEX idx_party_gst_details_default (party_id, is_default),
    INDEX idx_party_gst_details_state_code (state_code),

    CONSTRAINT fk_party_gst_party FOREIGN KEY (party_id) REFERENCES parties(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 7. PARTY BANK ACCOUNTS
-- =========================================================
DROP TABLE IF EXISTS party_bank_accounts;

CREATE TABLE party_bank_accounts (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    party_id BIGINT UNSIGNED NOT NULL,

    account_holder_name VARCHAR(255),
    account_number VARCHAR(50),
    bank_name VARCHAR(255),
    branch_name VARCHAR(255),
    ifsc_code VARCHAR(20),
    swift_code VARCHAR(20),
    iban VARCHAR(50),
    upi_id VARCHAR(100),

    is_default TINYINT(1) DEFAULT 0,
    is_active TINYINT(1) DEFAULT 1,

    UNIQUE KEY uq_party_bank_accounts_number (party_id, account_number),
    UNIQUE KEY uq_party_bank_accounts_upi (party_id, upi_id),
    INDEX idx_party_bank_accounts_default (party_id, is_default),

    CONSTRAINT fk_party_bank_party FOREIGN KEY (party_id) REFERENCES parties(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 8. PARTY CREDIT LIMITS
-- =========================================================
DROP TABLE IF EXISTS party_credit_limits;

CREATE TABLE party_credit_limits (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    party_id BIGINT UNSIGNED NOT NULL,

    credit_limit DECIMAL(18,2) DEFAULT 0,
    credit_days INT DEFAULT 0,
    effective_from DATE NULL,
    effective_to DATE NULL,

    is_active TINYINT(1) DEFAULT 1,

    INDEX idx_party_credit_limits_effective (party_id, effective_from, effective_to),

    CONSTRAINT fk_party_credit_party FOREIGN KEY (party_id) REFERENCES parties(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 9. PARTY PAYMENT TERMS
-- =========================================================
DROP TABLE IF EXISTS party_payment_terms;

CREATE TABLE party_payment_terms (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    party_id BIGINT UNSIGNED NOT NULL,

    term_name VARCHAR(100),
    days INT DEFAULT 0,
    due_basis ENUM('invoice_date', 'bill_date', 'dispatch_date', 'end_of_month', 'fixed_days') DEFAULT 'invoice_date',
    remarks TEXT,
    is_default TINYINT(1) DEFAULT 0,

    is_active TINYINT(1) DEFAULT 1,

    INDEX idx_party_payment_terms_default (party_id, is_default),

    CONSTRAINT fk_party_terms_party FOREIGN KEY (party_id) REFERENCES parties(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- FIRST-RUN NOTE
-- =========================================================
-- Parties are business data and should be created by the application.

SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================
-- MODULE 3 : ACCOUNTING FOUNDATION
-- ERP FOUNDATION - MySQL 8
-- Depends on MODULE 1A + 1B + 2
-- =========================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- 1. ACCOUNT GROUPS
-- Purpose:
-- Chart of Accounts hierarchy
-- =========================================================
DROP TABLE IF EXISTS account_groups;

CREATE TABLE account_groups (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    group_code VARCHAR(50) NOT NULL,
    group_name VARCHAR(150) NOT NULL,

    parent_group_id BIGINT UNSIGNED NULL,

    group_nature ENUM(
        'asset',
        'liability',
        'income',
        'expense',
        'equity'
    ) NOT NULL,

    group_category ENUM(
        'cash_bank',
        'receivable',
        'payable',
        'stock',
        'tax',
        'sales',
        'purchase',
        'direct_income',
        'direct_expense',
        'indirect_income',
        'indirect_expense',
        'fixed_asset',
        'current_asset',
        'current_liability',
        'long_term_liability',
        'equity',
        'other'
    ) DEFAULT 'other',

    affects_profit_loss TINYINT(1) NOT NULL DEFAULT 1,
    is_system_group TINYINT(1) NOT NULL DEFAULT 1,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    remarks TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_account_groups_code (group_code),
    UNIQUE KEY uq_account_groups_name (group_name),
    INDEX idx_account_groups_parent (parent_group_id),
    INDEX idx_account_groups_nature (group_nature),
    INDEX idx_account_groups_category (group_category),
    INDEX idx_account_groups_is_active (is_active),

    CONSTRAINT fk_account_groups_parent
        FOREIGN KEY (parent_group_id) REFERENCES account_groups(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_account_groups_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_account_groups_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 2. ACCOUNTS (LEDGERS)
-- Purpose:
-- Actual accounting ledgers
-- =========================================================
DROP TABLE IF EXISTS accounts;

CREATE TABLE accounts (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NULL,

    account_code VARCHAR(50) NOT NULL,
    account_name VARCHAR(255) NOT NULL,

    account_group_id BIGINT UNSIGNED NOT NULL,

    account_type ENUM(
        'general',
        'party',
        'cash',
        'bank',
        'tax',
        'employee',
        'customer',
        'supplier',
        'job_worker',
        'transporter'
    ) NOT NULL DEFAULT 'general',

    opening_balance DECIMAL(18,2) NOT NULL DEFAULT 0,
    opening_balance_type ENUM('debit', 'credit') NOT NULL DEFAULT 'debit',

    currency_code VARCHAR(10) NOT NULL DEFAULT 'INR',

    allow_manual_entries TINYINT(1) NOT NULL DEFAULT 1,
    allow_reconciliation TINYINT(1) NOT NULL DEFAULT 0,

    is_control_account TINYINT(1) NOT NULL DEFAULT 0,
    is_system_account TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    remarks TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_accounts_company_code (company_id, account_code),
    UNIQUE KEY uq_accounts_company_name (company_id, account_name),

    INDEX idx_accounts_company_id (company_id),
    INDEX idx_accounts_branch_id (branch_id),
    INDEX idx_accounts_group_id (account_group_id),
    INDEX idx_accounts_type (account_type),
    INDEX idx_accounts_is_active (is_active),

    CONSTRAINT fk_accounts_company
        FOREIGN KEY (company_id) REFERENCES companies(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_accounts_branch
        FOREIGN KEY (branch_id) REFERENCES branches(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_accounts_group
        FOREIGN KEY (account_group_id) REFERENCES account_groups(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_accounts_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_accounts_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 3. PARTY ACCOUNTS
-- Purpose:
-- Map each party to a ledger account
-- =========================================================
DROP TABLE IF EXISTS party_accounts;

CREATE TABLE party_accounts (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    party_id BIGINT UNSIGNED NOT NULL,
    account_id BIGINT UNSIGNED NOT NULL,

    account_purpose ENUM(
        'primary',
        'receivable',
        'payable',
        'advance',
        'salary',
        'commission',
        'other'
    ) NOT NULL DEFAULT 'primary',

    is_default TINYINT(1) NOT NULL DEFAULT 1,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    remarks TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_party_accounts_party_account_purpose (party_id, account_id, account_purpose),
    INDEX idx_party_accounts_party_id (party_id),
    INDEX idx_party_accounts_account_id (account_id),
    INDEX idx_party_accounts_purpose (account_purpose),

    CONSTRAINT fk_party_accounts_party
        FOREIGN KEY (party_id) REFERENCES parties(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_party_accounts_account
        FOREIGN KEY (account_id) REFERENCES accounts(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_party_accounts_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_party_accounts_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 4. VOUCHER TYPES
-- Purpose:
-- Controls voucher categories
-- =========================================================
DROP TABLE IF EXISTS voucher_types;

CREATE TABLE voucher_types (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    code VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,

    voucher_category ENUM(
        'payment',
        'receipt',
        'journal',
        'contra',
        'sales',
        'purchase',
        'credit_note',
        'debit_note',
        'opening',
        'adjustment'
    ) NOT NULL,

    document_type VARCHAR(50) NULL,

    auto_post TINYINT(1) NOT NULL DEFAULT 1,
    requires_approval TINYINT(1) NOT NULL DEFAULT 0,
    allows_reference_allocation TINYINT(1) NOT NULL DEFAULT 1,
    is_system_type TINYINT(1) NOT NULL DEFAULT 1,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_voucher_types_code (code),
    UNIQUE KEY uq_voucher_types_name (name),
    INDEX idx_voucher_types_category (voucher_category),
    INDEX idx_voucher_types_document_type (document_type),

    CONSTRAINT fk_voucher_types_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_voucher_types_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 5. VOUCHERS
-- Purpose:
-- Voucher header
-- =========================================================
DROP TABLE IF EXISTS vouchers;

CREATE TABLE vouchers (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    voucher_type_id BIGINT UNSIGNED NOT NULL,
    document_series_id BIGINT UNSIGNED NULL,

    voucher_no VARCHAR(100) NOT NULL,
    voucher_date DATE NOT NULL,

    reference_no VARCHAR(100) NULL,
    reference_date DATE NULL,

    narration TEXT NULL,

    total_debit DECIMAL(18,2) NOT NULL DEFAULT 0,
    total_credit DECIMAL(18,2) NOT NULL DEFAULT 0,
    adjustment_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    adjustment_account_id BIGINT UNSIGNED NULL,
    adjustment_remarks VARCHAR(500) NULL,

    source_module VARCHAR(50) NULL,
    source_table VARCHAR(100) NULL,
    source_id VARCHAR(100) NULL,

    approval_status ENUM('draft', 'pending', 'approved', 'rejected') NOT NULL DEFAULT 'approved',
    posting_status ENUM('draft', 'posted', 'cancelled') NOT NULL DEFAULT 'posted',

    approved_by BIGINT UNSIGNED NULL,
    approved_at DATETIME NULL,

    posted_by BIGINT UNSIGNED NULL,
    posted_at DATETIME NULL,

    cancelled_by BIGINT UNSIGNED NULL,
    cancelled_at DATETIME NULL,
    cancel_reason TEXT NULL,

    is_system_generated TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_vouchers_company_no (company_id, voucher_no),

    INDEX idx_vouchers_company_id (company_id),
    INDEX idx_vouchers_branch_id (branch_id),
    INDEX idx_vouchers_location_id (location_id),
    INDEX idx_vouchers_financial_year_id (financial_year_id),
    INDEX idx_vouchers_voucher_type_id (voucher_type_id),
    INDEX idx_vouchers_voucher_date (voucher_date),
    INDEX idx_vouchers_posting_status (posting_status),
    INDEX idx_vouchers_approval_status (approval_status),
    INDEX idx_vouchers_source (source_module, source_table, source_id),

    CONSTRAINT fk_vouchers_company
        FOREIGN KEY (company_id) REFERENCES companies(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_vouchers_branch
        FOREIGN KEY (branch_id) REFERENCES branches(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_vouchers_location
        FOREIGN KEY (location_id) REFERENCES business_locations(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_vouchers_financial_year
        FOREIGN KEY (financial_year_id) REFERENCES financial_years(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_vouchers_voucher_type
        FOREIGN KEY (voucher_type_id) REFERENCES voucher_types(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_vouchers_document_series
        FOREIGN KEY (document_series_id) REFERENCES document_series(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_vouchers_adjustment_account
        FOREIGN KEY (adjustment_account_id) REFERENCES accounts(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_vouchers_approved_by
        FOREIGN KEY (approved_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_vouchers_posted_by
        FOREIGN KEY (posted_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_vouchers_cancelled_by
        FOREIGN KEY (cancelled_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_vouchers_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_vouchers_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 6. VOUCHER LINES
-- Purpose:
-- Actual debit/credit postings
-- =========================================================
DROP TABLE IF EXISTS voucher_lines;

CREATE TABLE voucher_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    voucher_id BIGINT UNSIGNED NOT NULL,
    line_no INT NOT NULL,

    account_id BIGINT UNSIGNED NOT NULL,
    party_id BIGINT UNSIGNED NULL,

    entry_type ENUM('debit', 'credit') NOT NULL,
    amount DECIMAL(18,2) NOT NULL,

    bill_reference_no VARCHAR(100) NULL,
    bill_reference_date DATE NULL,
    bill_reference_type ENUM('new_ref', 'against_ref', 'on_account', 'advance') NULL,

    cheque_no VARCHAR(50) NULL,
    cheque_date DATE NULL,

    bank_reference_no VARCHAR(100) NULL,
    bank_reference_date DATE NULL,

    cost_center VARCHAR(100) NULL,
    department VARCHAR(100) NULL,
    project VARCHAR(100) NULL,

    line_narration VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_voucher_lines_voucher_line (voucher_id, line_no),

    INDEX idx_voucher_lines_voucher_id (voucher_id),
    INDEX idx_voucher_lines_account_id (account_id),
    INDEX idx_voucher_lines_party_id (party_id),
    INDEX idx_voucher_lines_entry_type (entry_type),
    INDEX idx_voucher_lines_bill_reference_no (bill_reference_no),

    CONSTRAINT fk_voucher_lines_voucher
        FOREIGN KEY (voucher_id) REFERENCES vouchers(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_voucher_lines_account
        FOREIGN KEY (account_id) REFERENCES accounts(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_voucher_lines_party
        FOREIGN KEY (party_id) REFERENCES parties(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 7. VOUCHER ALLOCATIONS
-- Purpose:
-- Against reference settlements
-- Example:
-- receipt against invoice
-- payment against purchase bill
-- =========================================================
DROP TABLE IF EXISTS voucher_allocations;

CREATE TABLE voucher_allocations (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    voucher_line_id BIGINT UNSIGNED NOT NULL,

    against_voucher_id BIGINT UNSIGNED NULL,
    against_voucher_line_id BIGINT UNSIGNED NULL,

    reference_no VARCHAR(100) NOT NULL,
    reference_date DATE NULL,

    allocation_amount DECIMAL(18,2) NOT NULL,

    allocation_type ENUM('receipt', 'payment', 'adjustment', 'advance_setoff') NOT NULL DEFAULT 'adjustment',

    remarks TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    INDEX idx_voucher_allocations_voucher_line_id (voucher_line_id),
    INDEX idx_voucher_allocations_against_voucher_id (against_voucher_id),
    INDEX idx_voucher_allocations_reference_no (reference_no),

    CONSTRAINT fk_voucher_allocations_voucher_line
        FOREIGN KEY (voucher_line_id) REFERENCES voucher_lines(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_voucher_allocations_against_voucher
        FOREIGN KEY (against_voucher_id) REFERENCES vouchers(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_voucher_allocations_against_voucher_line
        FOREIGN KEY (against_voucher_line_id) REFERENCES voucher_lines(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 8. CASH SESSIONS
-- Purpose:
-- Opening / closing cash counter session
-- Replaces old CLOSEDCASH
-- =========================================================
DROP TABLE IF EXISTS cash_sessions;

CREATE TABLE cash_sessions (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,

    user_id BIGINT UNSIGNED NOT NULL,

    cash_account_id BIGINT UNSIGNED NOT NULL,

    opening_datetime DATETIME NOT NULL,
    closing_datetime DATETIME NULL,

    opening_balance DECIMAL(18,2) NOT NULL DEFAULT 0,
    expected_closing_balance DECIMAL(18,2) NULL,
    actual_closing_balance DECIMAL(18,2) NULL,
    variance_amount DECIMAL(18,2) NULL,

    status ENUM('open', 'closed', 'cancelled') NOT NULL DEFAULT 'open',

    remarks TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    INDEX idx_cash_sessions_company_id (company_id),
    INDEX idx_cash_sessions_branch_id (branch_id),
    INDEX idx_cash_sessions_location_id (location_id),
    INDEX idx_cash_sessions_user_id (user_id),
    INDEX idx_cash_sessions_cash_account_id (cash_account_id),
    INDEX idx_cash_sessions_status (status),
    INDEX idx_cash_sessions_opening_datetime (opening_datetime),

    CONSTRAINT fk_cash_sessions_company
        FOREIGN KEY (company_id) REFERENCES companies(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_cash_sessions_branch
        FOREIGN KEY (branch_id) REFERENCES branches(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_cash_sessions_location
        FOREIGN KEY (location_id) REFERENCES business_locations(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_cash_sessions_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_cash_sessions_cash_account
        FOREIGN KEY (cash_account_id) REFERENCES accounts(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_cash_sessions_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_cash_sessions_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 9. BANK RECONCILIATION
-- Purpose:
-- Reconcile bank ledger entries
-- =========================================================
DROP TABLE IF EXISTS bank_reconciliation;

CREATE TABLE bank_reconciliation (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    account_id BIGINT UNSIGNED NOT NULL,
    voucher_line_id BIGINT UNSIGNED NOT NULL,

    bank_date DATE NULL,
    cleared_date DATE NULL,

    reconciliation_status ENUM('pending', 'cleared', 'bounced', 'cancelled') NOT NULL DEFAULT 'pending',

    bank_reference_no VARCHAR(100) NULL,
    remarks TEXT NULL,

    reconciled_by BIGINT UNSIGNED NULL,
    reconciled_at DATETIME NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_bank_reconciliation_voucher_line (voucher_line_id),

    INDEX idx_bank_reconciliation_account_id (account_id),
    INDEX idx_bank_reconciliation_status (reconciliation_status),
    INDEX idx_bank_reconciliation_bank_date (bank_date),
    INDEX idx_bank_reconciliation_cleared_date (cleared_date),

    CONSTRAINT fk_bank_reconciliation_account
        FOREIGN KEY (account_id) REFERENCES accounts(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_bank_reconciliation_voucher_line
        FOREIGN KEY (voucher_line_id) REFERENCES voucher_lines(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_bank_reconciliation_reconciled_by
        FOREIGN KEY (reconciled_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- SEED DATA : ACCOUNT GROUPS
-- =========================================================

INSERT INTO account_groups (
    group_code, group_name, parent_group_id, group_nature, group_category,
    affects_profit_loss, is_system_group, is_active
) VALUES
('ASSET', 'Assets', NULL, 'asset', 'other', 0, 1, 1),
('LIAB', 'Liabilities', NULL, 'liability', 'other', 0, 1, 1),
('EQUITY', 'Equity', NULL, 'equity', 'equity', 0, 1, 1),
('INCOME', 'Income', NULL, 'income', 'other', 1, 1, 1),
('EXPENSE', 'Expenses', NULL, 'expense', 'other', 1, 1, 1),

('CASHBANK', 'Cash & Bank', 1, 'asset', 'cash_bank', 0, 1, 1),
('RECEIVABLE', 'Accounts Receivable', 1, 'asset', 'receivable', 0, 1, 1),
('STOCK', 'Stock In Hand', 1, 'asset', 'stock', 0, 1, 1),
('FIXEDASSET', 'Fixed Assets', 1, 'asset', 'fixed_asset', 0, 1, 1),
('INPUTGST', 'Input GST', 1, 'asset', 'tax', 0, 1, 1),

('PAYABLE', 'Accounts Payable', 2, 'liability', 'payable', 0, 1, 1),
('DUTIES', 'Duties & Taxes', 2, 'liability', 'tax', 0, 1, 1),
('SALARYPAY', 'Salary Payable', 2, 'liability', 'current_liability', 0, 1, 1),

('SALES', 'Sales Accounts', 4, 'income', 'sales', 1, 1, 1),
('DIRECTINC', 'Direct Income', 4, 'income', 'direct_income', 1, 1, 1),
('OTHERINC', 'Indirect Income', 4, 'income', 'indirect_income', 1, 1, 1),

('PURCHASE', 'Purchase Accounts', 5, 'expense', 'purchase', 1, 1, 1),
('DIRECTEXP', 'Direct Expenses', 5, 'expense', 'direct_expense', 1, 1, 1),
('INDIRECTEXP', 'Indirect Expenses', 5, 'expense', 'indirect_expense', 1, 1, 1);

-- =========================================================
-- FIRST-RUN NOTE : COMPANY ACCOUNTS
-- =========================================================
-- Company-specific ledgers are generated through the application installer.

-- =========================================================
-- SEED DATA : VOUCHER TYPES
-- =========================================================
INSERT INTO voucher_types (
    code, name, voucher_category, document_type,
    auto_post, requires_approval, allows_reference_allocation,
    is_system_type, is_active
) VALUES
('PAYMENT', 'Payment Voucher', 'payment', 'PAYMENT_VOUCHER', 1, 0, 1, 1, 1),
('RECEIPT', 'Receipt Voucher', 'receipt', 'RECEIPT_VOUCHER', 1, 0, 1, 1, 1),
('JOURNAL', 'Journal Voucher', 'journal', 'JOURNAL_VOUCHER', 1, 0, 1, 1, 1),
('CONTRA', 'Contra Voucher', 'contra', 'CONTRA_VOUCHER', 1, 0, 1, 1, 1),
('SALES', 'Sales Voucher', 'sales', 'SALES_INVOICE', 1, 0, 1, 1, 1),
('PURCHASE', 'Purchase Voucher', 'purchase', 'PURCHASE_INVOICE', 1, 0, 1, 1, 1),
('CREDIT_NOTE', 'Credit Note', 'credit_note', 'CREDIT_NOTE', 1, 0, 1, 1, 1),
('DEBIT_NOTE', 'Debit Note', 'debit_note', 'DEBIT_NOTE', 1, 0, 1, 1, 1),
('OPENING', 'Opening Voucher', 'opening', 'OPENING_BALANCE', 1, 0, 1, 1, 1),
('ADJUSTMENT', 'Adjustment Voucher', 'adjustment', 'ADJUSTMENT', 1, 0, 1, 1, 1);

SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================
-- MODULE 4 : ITEM + INVENTORY FOUNDATION
-- ERP FOUNDATION - MySQL 8
-- Depends on MODULE 1A + 1B + 2 + 3
-- =========================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- 1. ITEM CATEGORIES
-- =========================================================
DROP TABLE IF EXISTS item_categories;

CREATE TABLE item_categories (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    category_code VARCHAR(50) NOT NULL,
    category_name VARCHAR(150) NOT NULL,

    parent_category_id BIGINT UNSIGNED NULL,
    image_path VARCHAR(500) NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,
    remarks TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_item_categories_code (category_code),
    UNIQUE KEY uq_item_categories_name (category_name),

    INDEX idx_item_categories_parent (parent_category_id),
    INDEX idx_item_categories_is_active (is_active),

    CONSTRAINT fk_item_categories_parent
        FOREIGN KEY (parent_category_id) REFERENCES item_categories(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_item_categories_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_item_categories_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 2. BRANDS
-- =========================================================
DROP TABLE IF EXISTS brands;

CREATE TABLE brands (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    brand_code VARCHAR(50) NOT NULL,
    brand_name VARCHAR(150) NOT NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,
    remarks TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_brands_code (brand_code),
    UNIQUE KEY uq_brands_name (brand_name),

    INDEX idx_brands_is_active (is_active),

    CONSTRAINT fk_brands_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_brands_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 3. UOMS (Units of Measure)
-- =========================================================
DROP TABLE IF EXISTS uoms;

CREATE TABLE uoms (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    uom_code VARCHAR(20) NOT NULL,
    uom_name VARCHAR(50) NOT NULL,
    symbol VARCHAR(20) NOT NULL,

    is_fraction_allowed TINYINT(1) NOT NULL DEFAULT 1,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_uoms_code (uom_code),
    UNIQUE KEY uq_uoms_name (uom_name),
    UNIQUE KEY uq_uoms_symbol (symbol),

    INDEX idx_uoms_is_active (is_active),

    CONSTRAINT fk_uoms_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_uoms_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 4. UOM CONVERSIONS
-- Example:
-- 1 BOX = 10 PCS
-- 1 KG = 1000 GM
-- =========================================================
DROP TABLE IF EXISTS uom_conversions;

CREATE TABLE uom_conversions (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    from_uom_id BIGINT UNSIGNED NOT NULL,
    to_uom_id BIGINT UNSIGNED NOT NULL,

    conversion_factor DECIMAL(18,6) NOT NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_uom_conversions_pair (from_uom_id, to_uom_id),

    INDEX idx_uom_conversions_from_uom (from_uom_id),
    INDEX idx_uom_conversions_to_uom (to_uom_id),

    CONSTRAINT fk_uom_conversions_from
        FOREIGN KEY (from_uom_id) REFERENCES uoms(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_uom_conversions_to
        FOREIGN KEY (to_uom_id) REFERENCES uoms(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_uom_conversions_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_uom_conversions_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 5. TAX CODES
-- GST-ready item tax master
-- =========================================================
DROP TABLE IF EXISTS tax_codes;

CREATE TABLE tax_codes (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    tax_code VARCHAR(50) NOT NULL,
    tax_name VARCHAR(100) NOT NULL,

    tax_type ENUM('gst', 'igst', 'cgst_sgst', 'cess', 'none') NOT NULL DEFAULT 'gst',
    tax_rate DECIMAL(8,4) NOT NULL DEFAULT 0,
    cess_rate DECIMAL(8,4) NOT NULL DEFAULT 0,

    hsn_sac_code VARCHAR(20) NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,
    remarks TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_tax_codes_code (tax_code),
    UNIQUE KEY uq_tax_codes_name (tax_name),

    INDEX idx_tax_codes_type (tax_type),
    INDEX idx_tax_codes_rate (tax_rate),
    INDEX idx_tax_codes_cess_rate (cess_rate),
    INDEX idx_tax_codes_hsn_sac_code (hsn_sac_code),
    INDEX idx_tax_codes_is_active (is_active),

    CONSTRAINT fk_tax_codes_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_tax_codes_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 6. ITEMS
-- Main item/service/product master
-- =========================================================
DROP TABLE IF EXISTS items;

CREATE TABLE items (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,

    item_code VARCHAR(50) NOT NULL,
    item_name VARCHAR(255) NOT NULL,
    item_name_local VARCHAR(255) NULL,

    item_type ENUM(
        'stock',
        'service',
        'manufactured',
        'trade',
        'raw_material',
        'semi_finished',
        'finished_goods',
        'consumable',
        'asset',
        'non_stock'
    ) NOT NULL DEFAULT 'stock',

    category_id BIGINT UNSIGNED NULL,
    brand_id BIGINT UNSIGNED NULL,

    base_uom_id BIGINT UNSIGNED NOT NULL,
    purchase_uom_id BIGINT UNSIGNED NULL,
    sales_uom_id BIGINT UNSIGNED NULL,

    tax_code_id BIGINT UNSIGNED NULL,

    sku VARCHAR(100) NULL,
    barcode VARCHAR(100) NULL,

    hsn_sac_code VARCHAR(20) NULL,

    has_batch TINYINT(1) NOT NULL DEFAULT 0,
    has_serial TINYINT(1) NOT NULL DEFAULT 0,
    has_expiry TINYINT(1) NOT NULL DEFAULT 0,

    track_inventory TINYINT(1) NOT NULL DEFAULT 1,
    is_saleable TINYINT(1) NOT NULL DEFAULT 1,
    is_purchaseable TINYINT(1) NOT NULL DEFAULT 1,
    is_manufacturable TINYINT(1) NOT NULL DEFAULT 0,
    is_jobwork_applicable TINYINT(1) NOT NULL DEFAULT 0,

    standard_cost DECIMAL(18,4) NOT NULL DEFAULT 0,
    standard_selling_price DECIMAL(18,4) NOT NULL DEFAULT 0,
    mrp DECIMAL(18,4) NOT NULL DEFAULT 0,

    min_stock_level DECIMAL(18,6) NOT NULL DEFAULT 0,
    reorder_level DECIMAL(18,6) NOT NULL DEFAULT 0,
    reorder_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    weight DECIMAL(18,6) NULL,
    volume DECIMAL(18,6) NULL,

    image_path VARCHAR(500) NULL,
    description TEXT NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,
    remarks TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_items_company_code (company_id, item_code),
    UNIQUE KEY uq_items_company_name (company_id, item_name),

    INDEX idx_items_company_id (company_id),
    INDEX idx_items_category_id (category_id),
    INDEX idx_items_brand_id (brand_id),
    INDEX idx_items_base_uom_id (base_uom_id),
    INDEX idx_items_tax_code_id (tax_code_id),
    INDEX idx_items_item_type (item_type),
    INDEX idx_items_barcode (barcode),
    INDEX idx_items_hsn_sac_code (hsn_sac_code),
    INDEX idx_items_is_active (is_active),

    CONSTRAINT fk_items_company
        FOREIGN KEY (company_id) REFERENCES companies(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_items_category
        FOREIGN KEY (category_id) REFERENCES item_categories(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_items_brand
        FOREIGN KEY (brand_id) REFERENCES brands(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_items_base_uom
        FOREIGN KEY (base_uom_id) REFERENCES uoms(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_items_purchase_uom
        FOREIGN KEY (purchase_uom_id) REFERENCES uoms(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_items_sales_uom
        FOREIGN KEY (sales_uom_id) REFERENCES uoms(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_items_tax_code
        FOREIGN KEY (tax_code_id) REFERENCES tax_codes(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_items_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_items_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 7. ITEM SUPPLIER MAP
-- One item can have many suppliers
-- =========================================================
DROP TABLE IF EXISTS item_supplier_map;

CREATE TABLE item_supplier_map (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    item_id BIGINT UNSIGNED NOT NULL,
    supplier_party_id BIGINT UNSIGNED NOT NULL,

    supplier_item_code VARCHAR(100) NULL,
    supplier_item_name VARCHAR(255) NULL,

    purchase_uom_id BIGINT UNSIGNED NULL,
    supplier_rate DECIMAL(18,4) NOT NULL DEFAULT 0,
    lead_time_days INT NOT NULL DEFAULT 0,
    minimum_order_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    is_primary_supplier TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    remarks TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_item_supplier_map_item_supplier (item_id, supplier_party_id),

    INDEX idx_item_supplier_map_item_id (item_id),
    INDEX idx_item_supplier_map_supplier_party_id (supplier_party_id),
    INDEX idx_item_supplier_map_primary (is_primary_supplier),
    INDEX idx_item_supplier_map_is_active (is_active),

    CONSTRAINT fk_item_supplier_map_item
        FOREIGN KEY (item_id) REFERENCES items(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_item_supplier_map_supplier
        FOREIGN KEY (supplier_party_id) REFERENCES parties(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_item_supplier_map_purchase_uom
        FOREIGN KEY (purchase_uom_id) REFERENCES uoms(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_item_supplier_map_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_item_supplier_map_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 8. ITEM ALTERNATES
-- Example:
-- use alternate raw material if primary unavailable
-- =========================================================
DROP TABLE IF EXISTS item_alternates;

CREATE TABLE item_alternates (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    item_id BIGINT UNSIGNED NOT NULL,
    alternate_item_id BIGINT UNSIGNED NOT NULL,

    priority_order INT NOT NULL DEFAULT 1,
    reason VARCHAR(255) NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_item_alternates_pair (item_id, alternate_item_id),

    INDEX idx_item_alternates_item_id (item_id),
    INDEX idx_item_alternates_alternate_item_id (alternate_item_id),
    INDEX idx_item_alternates_priority (priority_order),

    CONSTRAINT fk_item_alternates_item
        FOREIGN KEY (item_id) REFERENCES items(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_item_alternates_alternate_item
        FOREIGN KEY (alternate_item_id) REFERENCES items(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_item_alternates_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_item_alternates_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 9. ITEM PRICES
-- Supports different price lists / customer types later
-- =========================================================
DROP TABLE IF EXISTS item_prices;

CREATE TABLE item_prices (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    item_id BIGINT UNSIGNED NOT NULL,

    price_type ENUM('purchase', 'sales', 'mrp', 'wholesale', 'retail', 'special') NOT NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    price DECIMAL(18,4) NOT NULL DEFAULT 0,

    valid_from DATE NULL,
    valid_to DATE NULL,

    is_default TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    INDEX idx_item_prices_item_id (item_id),
    INDEX idx_item_prices_price_type (price_type),
    INDEX idx_item_prices_uom_id (uom_id),
    INDEX idx_item_prices_validity (valid_from, valid_to),
    INDEX idx_item_prices_is_default (is_default),

    CONSTRAINT fk_item_prices_item
        FOREIGN KEY (item_id) REFERENCES items(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_item_prices_uom
        FOREIGN KEY (uom_id) REFERENCES uoms(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_item_prices_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_item_prices_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 10. STOCK BATCHES
-- =========================================================
DROP TABLE IF EXISTS stock_batches;

CREATE TABLE stock_batches (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    item_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NOT NULL,

    batch_no VARCHAR(100) NOT NULL,
    manufacture_date DATE NULL,
    expiry_date DATE NULL,

    qty_available DECIMAL(18,6) NOT NULL DEFAULT 0,
    status ENUM('active', 'expired', 'blocked', 'consumed') NOT NULL DEFAULT 'active',

    remarks TEXT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_stock_batches_item_warehouse_batch (item_id, warehouse_id, batch_no),

    INDEX idx_stock_batches_item_id (item_id),
    INDEX idx_stock_batches_warehouse_id (warehouse_id),
    INDEX idx_stock_batches_expiry_date (expiry_date),
    INDEX idx_stock_batches_status (status),

    CONSTRAINT fk_stock_batches_item
        FOREIGN KEY (item_id) REFERENCES items(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_stock_batches_warehouse
        FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE stock_batches
    ADD COLUMN mfg_date DATE NULL AFTER batch_no;

ALTER TABLE stock_batches
    ADD COLUMN inward_qty DECIMAL(18,6) NOT NULL DEFAULT 0 AFTER expiry_date;

ALTER TABLE stock_batches
    ADD COLUMN outward_qty DECIMAL(18,6) NOT NULL DEFAULT 0 AFTER inward_qty;

ALTER TABLE stock_batches
    ADD COLUMN balance_qty DECIMAL(18,6) NOT NULL DEFAULT 0 AFTER outward_qty;

ALTER TABLE stock_batches
    ADD COLUMN purchase_rate DECIMAL(18,4) NULL AFTER qty_available;

ALTER TABLE stock_batches
    ADD COLUMN sales_rate DECIMAL(18,4) NULL AFTER purchase_rate;

ALTER TABLE stock_batches
    ADD COLUMN mrp DECIMAL(18,4) NULL AFTER sales_rate;

ALTER TABLE stock_batches
    ADD COLUMN is_active TINYINT(1) NOT NULL DEFAULT 1 AFTER mrp;

ALTER TABLE stock_batches
    ADD COLUMN created_by BIGINT UNSIGNED NULL AFTER remarks;

ALTER TABLE stock_batches
    ADD COLUMN updated_by BIGINT UNSIGNED NULL AFTER created_by;

-- =========================================================
-- 11. STOCK SERIALS
-- =========================================================
DROP TABLE IF EXISTS stock_serials;

CREATE TABLE stock_serials (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    item_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NOT NULL,

    serial_no VARCHAR(150) NOT NULL,
    batch_id BIGINT UNSIGNED NULL,

    status ENUM('available', 'sold', 'issued', 'returned', 'damaged', 'blocked') NOT NULL DEFAULT 'available',

    inward_date DATE NULL,
    outward_date DATE NULL,

    remarks TEXT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_stock_serials_item_serial (item_id, serial_no),

    INDEX idx_stock_serials_item_id (item_id),
    INDEX idx_stock_serials_warehouse_id (warehouse_id),
    INDEX idx_stock_serials_batch_id (batch_id),
    INDEX idx_stock_serials_status (status),

    CONSTRAINT fk_stock_serials_item
        FOREIGN KEY (item_id) REFERENCES items(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_stock_serials_warehouse
        FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_stock_serials_batch
        FOREIGN KEY (batch_id) REFERENCES stock_batches(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 12. STOCK MOVEMENTS
-- THE MOST IMPORTANT TABLE
-- Every stock change must come here
-- =========================================================
DROP TABLE IF EXISTS stock_movements;

CREATE TABLE stock_movements (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,

    movement_date DATETIME NOT NULL,

    movement_type ENUM(
        'opening',
        'purchase_receipt',
        'purchase_return',
        'sales_delivery',
        'sales_return',
        'stock_transfer_in',
        'stock_transfer_out',
        'stock_adjustment_in',
        'stock_adjustment_out',
        'production_issue',
        'production_receipt',
        'jobwork_issue',
        'jobwork_receipt',
        'damage',
        'expiry',
        'sample_issue',
        'sample_receipt',
        'internal_issue',
        'internal_receipt'
    ) NOT NULL,

    reference_module VARCHAR(50) NULL,
    reference_table VARCHAR(100) NULL,
    reference_id VARCHAR(100) NULL,
    reference_line_id BIGINT NULL,
    reference_no VARCHAR(100) NULL,

    batch_id BIGINT UNSIGNED NULL,
    serial_id BIGINT UNSIGNED NULL,

    uom_id BIGINT UNSIGNED NOT NULL,
    qty_in DECIMAL(18,6) NOT NULL DEFAULT 0,
    qty_out DECIMAL(18,6) NOT NULL DEFAULT 0,

    unit_cost DECIMAL(18,4) NOT NULL DEFAULT 0,
    total_cost DECIMAL(18,4) NOT NULL DEFAULT 0,

    rate DECIMAL(18,4) NOT NULL DEFAULT 0,
    amount DECIMAL(18,4) NOT NULL DEFAULT 0,

    line_narration VARCHAR(500) NULL,

    posted_by BIGINT UNSIGNED NULL,
    posted_at DATETIME NULL,

    is_cancelled TINYINT(1) NOT NULL DEFAULT 0,
    cancelled_by BIGINT UNSIGNED NULL,
    cancelled_at DATETIME NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    INDEX idx_stock_movements_company_id (company_id),
    INDEX idx_stock_movements_branch_id (branch_id),
    INDEX idx_stock_movements_location_id (location_id),
    INDEX idx_stock_movements_warehouse_id (warehouse_id),
    INDEX idx_stock_movements_financial_year_id (financial_year_id),
    INDEX idx_stock_movements_item_id (item_id),
    INDEX idx_stock_movements_movement_date (movement_date),
    INDEX idx_stock_movements_movement_type (movement_type),
    INDEX idx_stock_movements_reference (reference_module, reference_table, reference_id),
    INDEX idx_stock_movements_batch_id (batch_id),
    INDEX idx_stock_movements_serial_id (serial_id),

    CONSTRAINT fk_stock_movements_company
        FOREIGN KEY (company_id) REFERENCES companies(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_stock_movements_branch
        FOREIGN KEY (branch_id) REFERENCES branches(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_stock_movements_location
        FOREIGN KEY (location_id) REFERENCES business_locations(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_stock_movements_warehouse
        FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_stock_movements_financial_year
        FOREIGN KEY (financial_year_id) REFERENCES financial_years(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_stock_movements_item
        FOREIGN KEY (item_id) REFERENCES items(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_stock_movements_uom
        FOREIGN KEY (uom_id) REFERENCES uoms(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_stock_movements_batch
        FOREIGN KEY (batch_id) REFERENCES stock_batches(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_stock_movements_serial
        FOREIGN KEY (serial_id) REFERENCES stock_serials(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_stock_movements_posted_by
        FOREIGN KEY (posted_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_stock_movements_cancelled_by
        FOREIGN KEY (cancelled_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_stock_movements_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_stock_movements_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 13. STOCK BALANCES
-- Summary table for fast stock queries
-- Derived from stock_movements
-- =========================================================
DROP TABLE IF EXISTS stock_balances;

CREATE TABLE stock_balances (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    batch_id BIGINT UNSIGNED NULL,
    serial_id BIGINT UNSIGNED NULL,

    qty_on_hand DECIMAL(18,6) NOT NULL DEFAULT 0,
    qty_reserved DECIMAL(18,6) NOT NULL DEFAULT 0,
    qty_available DECIMAL(18,6) NOT NULL DEFAULT 0,

    avg_cost DECIMAL(18,4) NOT NULL DEFAULT 0,
    last_purchase_rate DECIMAL(18,4) NOT NULL DEFAULT 0,
    last_sales_rate DECIMAL(18,4) NOT NULL DEFAULT 0,

    last_movement_at DATETIME NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    updated_by BIGINT UNSIGNED NULL,

    PRIMARY KEY (id),

    UNIQUE KEY uq_stock_balances_unique (
        company_id, branch_id, location_id, warehouse_id, item_id, batch_id, serial_id
    ),

    INDEX idx_stock_balances_company_id (company_id),
    INDEX idx_stock_balances_branch_id (branch_id),
    INDEX idx_stock_balances_location_id (location_id),
    INDEX idx_stock_balances_warehouse_id (warehouse_id),
    INDEX idx_stock_balances_item_id (item_id),
    INDEX idx_stock_balances_qty_available (qty_available),

    CONSTRAINT fk_stock_balances_company
        FOREIGN KEY (company_id) REFERENCES companies(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_stock_balances_branch
        FOREIGN KEY (branch_id) REFERENCES branches(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_stock_balances_location
        FOREIGN KEY (location_id) REFERENCES business_locations(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_stock_balances_warehouse
        FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_stock_balances_item
        FOREIGN KEY (item_id) REFERENCES items(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_stock_balances_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_stock_balances_batch
        FOREIGN KEY (batch_id) REFERENCES stock_batches(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_stock_balances_serial
        FOREIGN KEY (serial_id) REFERENCES stock_serials(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS stock_reservations;

CREATE TABLE stock_reservations (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id BIGINT UNSIGNED NOT NULL,
    item_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NOT NULL,
    batch_id BIGINT UNSIGNED NULL,
    serial_id BIGINT UNSIGNED NULL,
    reference_type VARCHAR(100) NOT NULL,
    reference_id BIGINT UNSIGNED NOT NULL,
    reference_line_id BIGINT UNSIGNED NULL,
    reserved_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    released_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    balance_reserved_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    status VARCHAR(30) NOT NULL DEFAULT 'active',
    remarks TEXT NULL,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
);

-- =========================================================
-- SEED DATA
-- =========================================================

-- Categories
INSERT INTO item_categories (category_code, category_name, is_active)
VALUES
('GEN', 'General', 1),
('RM', 'Raw Materials', 1),
('FG', 'Finished Goods', 1),
('SERV', 'Services', 1);

-- Brands
INSERT INTO brands (brand_code, brand_name, is_active)
VALUES
('GEN', 'Generic', 1);

-- UOMs
INSERT INTO uoms (uom_code, uom_name, symbol, is_fraction_allowed, is_active)
VALUES
('PCS', 'Pieces', 'PCS', 0, 1),
('BOX', 'Box', 'BOX', 0, 1),
('KG', 'Kilogram', 'KG', 1, 1),
('GM', 'Gram', 'GM', 1, 1),
('LTR', 'Litre', 'LTR', 1, 1),
('NOS', 'Numbers', 'NOS', 0, 1),
('MTR', 'Meter', 'MTR', 1, 1),
('HRS', 'Hours', 'HRS', 1, 1);

-- UOM Conversions
INSERT INTO uom_conversions (from_uom_id, to_uom_id, conversion_factor, is_active)
VALUES
(2, 1, 10.000000, 1), -- 1 BOX = 10 PCS
(3, 4, 1000.000000, 1); -- 1 KG = 1000 GM

-- Tax Codes
INSERT INTO tax_codes (tax_code, tax_name, tax_type, tax_rate, cess_rate, hsn_sac_code, is_active)
VALUES
('GST0', 'GST 0%', 'gst', 0.0000, 0.0000, NULL, 1),
('GST5', 'GST 5%', 'gst', 5.0000, 0.0000, NULL, 1),
('GST12', 'GST 12%', 'gst', 12.0000, 0.0000, NULL, 1),
('GST18', 'GST 18%', 'gst', 18.0000, 0.0000, NULL, 1),
('GST28', 'GST 28%', 'gst', 28.0000, 0.0000, NULL, 1),
('EXEMPT', 'GST Exempt', 'none', 0.0000, 0.0000, NULL, 1),
('NONGST', 'Non GST', 'none', 0.0000, 0.0000, NULL, 1);

-- Items, prices, and supplier mappings are business data and are created
-- after the first-time installation flow.

SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================
-- MODULE 5 : SALES FLOW
-- ERP FOUNDATION - MySQL 8
-- Depends on MODULE 1A + 1B + 2 + 3 + 4
-- =========================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- 1. SALES QUOTATIONS
-- Optional commercial stage before order
-- =========================================================
DROP TABLE IF EXISTS sales_quotation_lines;
DROP TABLE IF EXISTS sales_quotations;

CREATE TABLE sales_quotations (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,
    quotation_no VARCHAR(100) NOT NULL,
    quotation_date DATE NOT NULL,
    valid_until DATE NULL,

    customer_party_id BIGINT UNSIGNED NOT NULL,

    billing_address_id BIGINT UNSIGNED NULL,
    shipping_address_id BIGINT UNSIGNED NULL,
    contact_id BIGINT UNSIGNED NULL,

    crm_opportunity_id BIGINT UNSIGNED NULL,

    customer_reference_no VARCHAR(100) NULL,
    customer_reference_date DATE NULL,

    price_type VARCHAR(50) NULL,

    subtotal DECIMAL(18,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    taxable_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    cgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    sgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    igst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    cess_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    round_off_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    adjustment_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    adjustment_account_id BIGINT UNSIGNED NULL,
    adjustment_remarks VARCHAR(500) NULL,
    total_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    quotation_status ENUM(
        'draft',
        'posted',
        'sent',
        'accepted',
        'rejected',
        'expired',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    notes TEXT NULL,
    terms_conditions TEXT NULL,

    approved_by BIGINT UNSIGNED NULL,
    approved_at DATETIME NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_sales_quotations_company_no (company_id, quotation_no),

    INDEX idx_sales_quotations_customer (customer_party_id),
    INDEX idx_sales_quotations_date (quotation_date),
    INDEX idx_sales_quotations_status (quotation_status),

    CONSTRAINT fk_sales_quotations_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_sales_quotations_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_sales_quotations_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_sales_quotations_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_sales_quotations_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_sales_quotations_customer FOREIGN KEY (customer_party_id) REFERENCES parties(id),
    CONSTRAINT fk_sales_quotations_billing_address FOREIGN KEY (billing_address_id) REFERENCES party_addresses(id),
    CONSTRAINT fk_sales_quotations_shipping_address FOREIGN KEY (shipping_address_id) REFERENCES party_addresses(id),
    CONSTRAINT fk_sales_quotations_contact FOREIGN KEY (contact_id) REFERENCES party_contacts(id),
    CONSTRAINT fk_sales_quotations_crm_opportunity FOREIGN KEY (crm_opportunity_id) REFERENCES crm_opportunities(id),
    CONSTRAINT fk_sales_quotations_approved_by FOREIGN KEY (approved_by) REFERENCES users(id),
    CONSTRAINT fk_sales_quotations_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_sales_quotations_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE sales_quotation_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    sales_quotation_id BIGINT UNSIGNED NOT NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    description VARCHAR(500) NULL,

    qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    rate DECIMAL(18,4) NOT NULL DEFAULT 0,
    discount_percent DECIMAL(8,4) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    gross_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    taxable_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    tax_code_id BIGINT UNSIGNED NULL,
    tax_percent DECIMAL(8,4) NOT NULL DEFAULT 0,
    cgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    sgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    igst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    cess_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    line_total DECIMAL(18,2) NOT NULL DEFAULT 0,

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_sales_quotation_lines_doc_line (sales_quotation_id, line_no),

    INDEX idx_sales_quotation_lines_item (item_id),
    INDEX idx_sales_quotation_lines_warehouse (warehouse_id),

    CONSTRAINT fk_sales_quotation_lines_doc FOREIGN KEY (sales_quotation_id) REFERENCES sales_quotations(id) ON DELETE CASCADE,
    CONSTRAINT fk_sales_quotation_lines_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_sales_quotation_lines_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_sales_quotation_lines_uom FOREIGN KEY (uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_sales_quotation_lines_tax_code FOREIGN KEY (tax_code_id) REFERENCES tax_codes(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 2. SALES ORDERS
-- Commercial commitment, no stock movement
-- =========================================================
DROP TABLE IF EXISTS sales_order_lines;
DROP TABLE IF EXISTS sales_orders;

CREATE TABLE sales_orders (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,
    sales_quotation_id BIGINT UNSIGNED NULL,

    crm_opportunity_id BIGINT UNSIGNED NULL,

    order_no VARCHAR(100) NOT NULL,
    order_date DATE NOT NULL,
    expected_delivery_date DATE NULL,

    customer_party_id BIGINT UNSIGNED NOT NULL,

    billing_address_id BIGINT UNSIGNED NULL,
    shipping_address_id BIGINT UNSIGNED NULL,
    contact_id BIGINT UNSIGNED NULL,

    customer_reference_no VARCHAR(100) NULL,
    customer_reference_date DATE NULL,

    subtotal DECIMAL(18,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    taxable_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    cgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    sgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    igst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    cess_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    round_off_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    order_status ENUM(
        'draft',
        'confirmed',
        'partially_delivered',
        'fully_delivered',
        'partially_invoiced',
        'fully_invoiced',
        'closed',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    notes TEXT NULL,
    terms_conditions TEXT NULL,

    approved_by BIGINT UNSIGNED NULL,
    approved_at DATETIME NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_sales_orders_company_no (company_id, order_no),

    INDEX idx_sales_orders_customer (customer_party_id),
    INDEX idx_sales_orders_date (order_date),
    INDEX idx_sales_orders_status (order_status),

    CONSTRAINT fk_sales_orders_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_sales_orders_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_sales_orders_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_sales_orders_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_sales_orders_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_sales_orders_quotation FOREIGN KEY (sales_quotation_id) REFERENCES sales_quotations(id),
    CONSTRAINT fk_sales_orders_crm_opportunity FOREIGN KEY (crm_opportunity_id) REFERENCES crm_opportunities(id),
    CONSTRAINT fk_sales_orders_customer FOREIGN KEY (customer_party_id) REFERENCES parties(id),
    CONSTRAINT fk_sales_orders_billing_address FOREIGN KEY (billing_address_id) REFERENCES party_addresses(id),
    CONSTRAINT fk_sales_orders_shipping_address FOREIGN KEY (shipping_address_id) REFERENCES party_addresses(id),
    CONSTRAINT fk_sales_orders_contact FOREIGN KEY (contact_id) REFERENCES party_contacts(id),
    CONSTRAINT fk_sales_orders_approved_by FOREIGN KEY (approved_by) REFERENCES users(id),
    CONSTRAINT fk_sales_orders_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_sales_orders_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE sales_order_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    sales_order_id BIGINT UNSIGNED NOT NULL,
    sales_quotation_line_id BIGINT UNSIGNED NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    description VARCHAR(500) NULL,

    ordered_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    delivered_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    invoiced_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    pending_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    rate DECIMAL(18,4) NOT NULL DEFAULT 0,
    discount_percent DECIMAL(8,4) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    gross_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    taxable_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    tax_code_id BIGINT UNSIGNED NULL,
    tax_percent DECIMAL(8,4) NOT NULL DEFAULT 0,
    cgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    sgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    igst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    cess_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    line_total DECIMAL(18,2) NOT NULL DEFAULT 0,

    line_status ENUM(
        'open',
        'partially_delivered',
        'fully_delivered',
        'partially_invoiced',
        'fully_invoiced',
        'closed',
        'cancelled'
    ) NOT NULL DEFAULT 'open',

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_sales_order_lines_doc_line (sales_order_id, line_no),

    INDEX idx_sales_order_lines_item (item_id),
    INDEX idx_sales_order_lines_warehouse (warehouse_id),
    INDEX idx_sales_order_lines_status (line_status),

    CONSTRAINT fk_sales_order_lines_doc FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_sales_order_lines_quotation_line FOREIGN KEY (sales_quotation_line_id) REFERENCES sales_quotation_lines(id),
    CONSTRAINT fk_sales_order_lines_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_sales_order_lines_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_sales_order_lines_uom FOREIGN KEY (uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_sales_order_lines_tax_code FOREIGN KEY (tax_code_id) REFERENCES tax_codes(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 3. SALES DELIVERIES (DELIVERY CHALLAN)
-- This is where stock moves out
-- =========================================================
DROP TABLE IF EXISTS sales_delivery_lines;
DROP TABLE IF EXISTS sales_deliveries;

CREATE TABLE sales_deliveries (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,
    sales_order_id BIGINT UNSIGNED NULL,

    delivery_no VARCHAR(100) NOT NULL,
    delivery_date DATE NOT NULL,
    voucher_id BIGINT UNSIGNED NULL,

    customer_party_id BIGINT UNSIGNED NOT NULL,

    billing_address_id BIGINT UNSIGNED NULL,
    shipping_address_id BIGINT UNSIGNED NULL,
    contact_id BIGINT UNSIGNED NULL,

    vehicle_no VARCHAR(50) NULL,
    transporter_party_id BIGINT UNSIGNED NULL,
    lr_no VARCHAR(100) NULL,
    lr_date DATE NULL,

    delivery_status ENUM(
        'draft',
        'posted',
        'partially_invoiced',
        'fully_invoiced',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    notes TEXT NULL,
    terms_conditions TEXT NULL,

    posted_by BIGINT UNSIGNED NULL,
    posted_at DATETIME NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_sales_deliveries_company_no (company_id, delivery_no),

    INDEX idx_sales_deliveries_customer (customer_party_id),
    INDEX idx_sales_deliveries_date (delivery_date),
    INDEX idx_sales_deliveries_status (delivery_status),

    CONSTRAINT fk_sales_deliveries_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_sales_deliveries_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_sales_deliveries_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_sales_deliveries_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_sales_deliveries_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_sales_deliveries_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id),
    CONSTRAINT fk_sales_deliveries_customer FOREIGN KEY (customer_party_id) REFERENCES parties(id),
    CONSTRAINT fk_sales_deliveries_billing_address FOREIGN KEY (billing_address_id) REFERENCES party_addresses(id),
    CONSTRAINT fk_sales_deliveries_shipping_address FOREIGN KEY (shipping_address_id) REFERENCES party_addresses(id),
    CONSTRAINT fk_sales_deliveries_contact FOREIGN KEY (contact_id) REFERENCES party_contacts(id),
    CONSTRAINT fk_sales_deliveries_transporter FOREIGN KEY (transporter_party_id) REFERENCES parties(id),
    CONSTRAINT fk_sales_deliveries_posted_by FOREIGN KEY (posted_by) REFERENCES users(id),
    CONSTRAINT fk_sales_deliveries_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_sales_deliveries_updated_by FOREIGN KEY (updated_by) REFERENCES users(id),
    CONSTRAINT fk_sales_deliveries_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE sales_delivery_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    sales_delivery_id BIGINT UNSIGNED NOT NULL,
    sales_order_line_id BIGINT UNSIGNED NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NOT NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    batch_id BIGINT UNSIGNED NULL,
    serial_id BIGINT UNSIGNED NULL,

    description VARCHAR(500) NULL,

    delivered_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    invoiced_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    returned_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    pending_invoice_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    rate DECIMAL(18,4) NOT NULL DEFAULT 0,
    amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    line_status ENUM(
        'open',
        'partially_invoiced',
        'fully_invoiced',
        'cancelled'
    ) NOT NULL DEFAULT 'open',

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_sales_delivery_lines_doc_line (sales_delivery_id, line_no),

    INDEX idx_sales_delivery_lines_item (item_id),
    INDEX idx_sales_delivery_lines_warehouse (warehouse_id),

    CONSTRAINT fk_sales_delivery_lines_doc FOREIGN KEY (sales_delivery_id) REFERENCES sales_deliveries(id) ON DELETE CASCADE,
    CONSTRAINT fk_sales_delivery_lines_order_line FOREIGN KEY (sales_order_line_id) REFERENCES sales_order_lines(id),
    CONSTRAINT fk_sales_delivery_lines_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_sales_delivery_lines_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_sales_delivery_lines_uom FOREIGN KEY (uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_sales_delivery_lines_batch FOREIGN KEY (batch_id) REFERENCES stock_batches(id),
    CONSTRAINT fk_sales_delivery_lines_serial FOREIGN KEY (serial_id) REFERENCES stock_serials(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 4. SALES INVOICES
-- Accounting + GST + customer receivable
-- =========================================================
DROP TABLE IF EXISTS sales_invoice_lines;
DROP TABLE IF EXISTS sales_invoices;

CREATE TABLE sales_invoices (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,
    sales_order_id BIGINT UNSIGNED NULL,
    sales_delivery_id BIGINT UNSIGNED NULL,

    invoice_no VARCHAR(100) NOT NULL,
    invoice_date DATE NOT NULL,
    due_date DATE NULL,

    customer_party_id BIGINT UNSIGNED NOT NULL,

    billing_address_id BIGINT UNSIGNED NULL,
    shipping_address_id BIGINT UNSIGNED NULL,
    contact_id BIGINT UNSIGNED NULL,

    customer_reference_no VARCHAR(100) NULL,
    customer_reference_date DATE NULL,

    subtotal DECIMAL(18,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    taxable_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    cgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    sgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    igst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    cess_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    round_off_method ENUM('manual', 'bill', 'item') NOT NULL DEFAULT 'manual',
    round_off_precision DECIMAL(18,2) NOT NULL DEFAULT 1.00,
    round_off_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    adjustment_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    adjustment_account_id BIGINT UNSIGNED NULL,
    adjustment_remarks VARCHAR(500) NULL,

    paid_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    balance_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    voucher_id BIGINT UNSIGNED NULL,

    invoice_status ENUM(
        'draft',
        'posted',
        'partially_paid',
        'paid',
        'partially_returned',
        'returned',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    notes TEXT NULL,
    terms_conditions TEXT NULL,

    posted_by BIGINT UNSIGNED NULL,
    posted_at DATETIME NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_sales_invoices_company_no (company_id, invoice_no),

    INDEX idx_sales_invoices_customer (customer_party_id),
    INDEX idx_sales_invoices_date (invoice_date),
    INDEX idx_sales_invoices_due_date (due_date),
    INDEX idx_sales_invoices_status (invoice_status),

    CONSTRAINT fk_sales_invoices_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_sales_invoices_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_sales_invoices_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_sales_invoices_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_sales_invoices_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_sales_invoices_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id),
    CONSTRAINT fk_sales_invoices_delivery FOREIGN KEY (sales_delivery_id) REFERENCES sales_deliveries(id),
    CONSTRAINT fk_sales_invoices_customer FOREIGN KEY (customer_party_id) REFERENCES parties(id),
    CONSTRAINT fk_sales_invoices_billing_address FOREIGN KEY (billing_address_id) REFERENCES party_addresses(id),
    CONSTRAINT fk_sales_invoices_shipping_address FOREIGN KEY (shipping_address_id) REFERENCES party_addresses(id),
    CONSTRAINT fk_sales_invoices_contact FOREIGN KEY (contact_id) REFERENCES party_contacts(id),
    CONSTRAINT fk_sales_invoices_adjustment_account FOREIGN KEY (adjustment_account_id) REFERENCES accounts(id),
    CONSTRAINT fk_sales_invoices_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id),
    CONSTRAINT fk_sales_invoices_posted_by FOREIGN KEY (posted_by) REFERENCES users(id),
    CONSTRAINT fk_sales_invoices_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_sales_invoices_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE sales_invoice_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    sales_invoice_id BIGINT UNSIGNED NOT NULL,
    sales_order_line_id BIGINT UNSIGNED NULL,
    sales_delivery_line_id BIGINT UNSIGNED NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    batch_id BIGINT UNSIGNED NULL,
    serial_id BIGINT UNSIGNED NULL,

    description VARCHAR(500) NULL,

    invoiced_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    returned_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    pending_return_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    rate DECIMAL(18,4) NOT NULL DEFAULT 0,
    discount_percent DECIMAL(8,4) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    gross_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    taxable_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    tax_code_id BIGINT UNSIGNED NULL,
    tax_percent DECIMAL(8,4) NOT NULL DEFAULT 0,
    cgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    sgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    igst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    cess_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    line_total DECIMAL(18,2) NOT NULL DEFAULT 0,

    line_status ENUM(
        'open',
        'partially_returned',
        'fully_returned',
        'cancelled'
    ) NOT NULL DEFAULT 'open',

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_sales_invoice_lines_doc_line (sales_invoice_id, line_no),

    INDEX idx_sales_invoice_lines_item (item_id),
    INDEX idx_sales_invoice_lines_warehouse (warehouse_id),

    CONSTRAINT fk_sales_invoice_lines_doc FOREIGN KEY (sales_invoice_id) REFERENCES sales_invoices(id) ON DELETE CASCADE,
    CONSTRAINT fk_sales_invoice_lines_order_line FOREIGN KEY (sales_order_line_id) REFERENCES sales_order_lines(id),
    CONSTRAINT fk_sales_invoice_lines_delivery_line FOREIGN KEY (sales_delivery_line_id) REFERENCES sales_delivery_lines(id),
    CONSTRAINT fk_sales_invoice_lines_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_sales_invoice_lines_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_sales_invoice_lines_uom FOREIGN KEY (uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_sales_invoice_lines_batch FOREIGN KEY (batch_id) REFERENCES stock_batches(id),
    CONSTRAINT fk_sales_invoice_lines_serial FOREIGN KEY (serial_id) REFERENCES stock_serials(id),
    CONSTRAINT fk_sales_invoice_lines_tax_code FOREIGN KEY (tax_code_id) REFERENCES tax_codes(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 5. SALES RECEIPTS
-- Customer money received against invoice / advance / on-account
-- =========================================================
DROP TABLE IF EXISTS sales_receipt_allocations;
DROP TABLE IF EXISTS sales_receipts;

CREATE TABLE sales_receipts (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,

    receipt_no VARCHAR(100) NOT NULL,
    receipt_date DATE NOT NULL,

    customer_party_id BIGINT UNSIGNED NOT NULL,

    payment_mode ENUM(
        'cash',
        'bank',
        'upi',
        'cheque',
        'card',
        'wallet',
        'adjustment',
        'other'
    ) NOT NULL DEFAULT 'cash',

    account_id BIGINT UNSIGNED NOT NULL,

    payment_reference_no VARCHAR(100) NULL,
    payment_reference_date DATE NULL,

    paid_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    unallocated_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    voucher_id BIGINT UNSIGNED NULL,

    receipt_status ENUM(
        'draft',
        'posted',
        'partially_allocated',
        'fully_allocated',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    notes TEXT NULL,

    posted_by BIGINT UNSIGNED NULL,
    posted_at DATETIME NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_sales_receipts_company_no (company_id, receipt_no),

    INDEX idx_sales_receipts_customer (customer_party_id),
    INDEX idx_sales_receipts_date (receipt_date),
    INDEX idx_sales_receipts_status (receipt_status),

    CONSTRAINT fk_sales_receipts_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_sales_receipts_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_sales_receipts_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_sales_receipts_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_sales_receipts_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_sales_receipts_customer FOREIGN KEY (customer_party_id) REFERENCES parties(id),
    CONSTRAINT fk_sales_receipts_account FOREIGN KEY (account_id) REFERENCES accounts(id),
    CONSTRAINT fk_sales_receipts_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id),
    CONSTRAINT fk_sales_receipts_posted_by FOREIGN KEY (posted_by) REFERENCES users(id),
    CONSTRAINT fk_sales_receipts_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_sales_receipts_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE sales_receipt_allocations (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    sales_receipt_id BIGINT UNSIGNED NOT NULL,
    sales_invoice_id BIGINT UNSIGNED NULL,

    allocated_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    allocation_type ENUM('against_invoice', 'advance', 'on_account', 'adjustment') NOT NULL DEFAULT 'against_invoice',

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    INDEX idx_sales_receipt_allocations_receipt (sales_receipt_id),
    INDEX idx_sales_receipt_allocations_invoice (sales_invoice_id),

    CONSTRAINT fk_sales_receipt_allocations_receipt FOREIGN KEY (sales_receipt_id) REFERENCES sales_receipts(id) ON DELETE CASCADE,
    CONSTRAINT fk_sales_receipt_allocations_invoice FOREIGN KEY (sales_invoice_id) REFERENCES sales_invoices(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 6. SALES RETURNS
-- Physical return + financial reversal / credit note basis
-- =========================================================
DROP TABLE IF EXISTS sales_return_lines;
DROP TABLE IF EXISTS sales_returns;

CREATE TABLE sales_returns (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,
    sales_invoice_id BIGINT UNSIGNED NULL,

    return_no VARCHAR(100) NOT NULL,
    return_date DATE NOT NULL,

    customer_party_id BIGINT UNSIGNED NOT NULL,

    subtotal DECIMAL(18,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    taxable_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    cgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    sgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    igst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    cess_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    round_off_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    adjustment_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    adjustment_account_id BIGINT UNSIGNED NULL,
    adjustment_remarks VARCHAR(500) NULL,
    total_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    voucher_id BIGINT UNSIGNED NULL,

    return_reason VARCHAR(255) NULL,

    return_status ENUM(
        'draft',
        'posted',
        'credited',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    notes TEXT NULL,

    posted_by BIGINT UNSIGNED NULL,
    posted_at DATETIME NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_sales_returns_company_no (company_id, return_no),

    INDEX idx_sales_returns_customer (customer_party_id),
    INDEX idx_sales_returns_date (return_date),
    INDEX idx_sales_returns_status (return_status),

    CONSTRAINT fk_sales_returns_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_sales_returns_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_sales_returns_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_sales_returns_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_sales_returns_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_sales_returns_invoice FOREIGN KEY (sales_invoice_id) REFERENCES sales_invoices(id),
    CONSTRAINT fk_sales_returns_customer FOREIGN KEY (customer_party_id) REFERENCES parties(id),
    CONSTRAINT fk_sales_returns_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id),
    CONSTRAINT fk_sales_returns_posted_by FOREIGN KEY (posted_by) REFERENCES users(id),
    CONSTRAINT fk_sales_returns_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_sales_returns_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE sales_return_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    sales_return_id BIGINT UNSIGNED NOT NULL,
    sales_invoice_line_id BIGINT UNSIGNED NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NOT NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    batch_id BIGINT UNSIGNED NULL,
    serial_id BIGINT UNSIGNED NULL,

    return_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    rate DECIMAL(18,4) NOT NULL DEFAULT 0,
    discount_percent DECIMAL(8,4) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    gross_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    taxable_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    tax_code_id BIGINT UNSIGNED NULL,
    tax_percent DECIMAL(8,4) NOT NULL DEFAULT 0,
    cgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    sgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    igst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    cess_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    line_total DECIMAL(18,2) NOT NULL DEFAULT 0,

    return_reason VARCHAR(255) NULL,
    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_sales_return_lines_doc_line (sales_return_id, line_no),

    INDEX idx_sales_return_lines_item (item_id),
    INDEX idx_sales_return_lines_warehouse (warehouse_id),

    CONSTRAINT fk_sales_return_lines_doc FOREIGN KEY (sales_return_id) REFERENCES sales_returns(id) ON DELETE CASCADE,
    CONSTRAINT fk_sales_return_lines_invoice_line FOREIGN KEY (sales_invoice_line_id) REFERENCES sales_invoice_lines(id),
    CONSTRAINT fk_sales_return_lines_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_sales_return_lines_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_sales_return_lines_uom FOREIGN KEY (uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_sales_return_lines_batch FOREIGN KEY (batch_id) REFERENCES stock_batches(id),
    CONSTRAINT fk_sales_return_lines_serial FOREIGN KEY (serial_id) REFERENCES stock_serials(id),
    CONSTRAINT fk_sales_return_lines_tax_code FOREIGN KEY (tax_code_id) REFERENCES tax_codes(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================
-- MODULE 6 : PURCHASE FLOW
-- ERP FOUNDATION - MySQL 8
-- Depends on MODULE 1A + 1B + 2 + 3 + 4 + 5
-- =========================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- 1. PURCHASE REQUISITIONS
-- Internal request for procurement
-- =========================================================
DROP TABLE IF EXISTS purchase_requisition_lines;
DROP TABLE IF EXISTS purchase_requisitions;

CREATE TABLE purchase_requisitions (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,

    requisition_no VARCHAR(100) NOT NULL,
    requisition_date DATE NOT NULL,
    required_date DATE NULL,

    requested_by BIGINT UNSIGNED NULL,
    department VARCHAR(100) NULL,
    purpose VARCHAR(255) NULL,

    requisition_status ENUM(
        'draft',
        'approved',
        'partially_ordered',
        'fully_ordered',
        'closed',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    notes TEXT NULL,

    approved_by BIGINT UNSIGNED NULL,
    approved_at DATETIME NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_purchase_requisitions_company_no (company_id, requisition_no),

    INDEX idx_purchase_requisitions_date (requisition_date),
    INDEX idx_purchase_requisitions_status (requisition_status),

    CONSTRAINT fk_purchase_requisitions_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_purchase_requisitions_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_purchase_requisitions_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_purchase_requisitions_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_purchase_requisitions_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_purchase_requisitions_requested_by FOREIGN KEY (requested_by) REFERENCES users(id),
    CONSTRAINT fk_purchase_requisitions_approved_by FOREIGN KEY (approved_by) REFERENCES users(id),
    CONSTRAINT fk_purchase_requisitions_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_purchase_requisitions_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE purchase_requisition_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    purchase_requisition_id BIGINT UNSIGNED NOT NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    description VARCHAR(500) NULL,

    requested_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    ordered_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    pending_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    estimated_rate DECIMAL(18,4) NOT NULL DEFAULT 0,
    estimated_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    line_status ENUM(
        'open',
        'partially_ordered',
        'fully_ordered',
        'closed',
        'cancelled'
    ) NOT NULL DEFAULT 'open',

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_purchase_requisition_lines_doc_line (purchase_requisition_id, line_no),

    INDEX idx_purchase_requisition_lines_item (item_id),
    INDEX idx_purchase_requisition_lines_warehouse (warehouse_id),

    CONSTRAINT fk_purchase_requisition_lines_doc FOREIGN KEY (purchase_requisition_id) REFERENCES purchase_requisitions(id) ON DELETE CASCADE,
    CONSTRAINT fk_purchase_requisition_lines_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_purchase_requisition_lines_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_purchase_requisition_lines_uom FOREIGN KEY (uom_id) REFERENCES uoms(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 2. PURCHASE ORDERS
-- Supplier commitment, no stock movement
-- =========================================================
DROP TABLE IF EXISTS purchase_order_lines;
DROP TABLE IF EXISTS purchase_orders;

CREATE TABLE purchase_orders (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,
    purchase_requisition_id BIGINT UNSIGNED NULL,

    order_no VARCHAR(100) NOT NULL,
    order_date DATE NOT NULL,
    expected_receipt_date DATE NULL,

    supplier_party_id BIGINT UNSIGNED NOT NULL,

    billing_address_id BIGINT UNSIGNED NULL,
    shipping_address_id BIGINT UNSIGNED NULL,
    contact_id BIGINT UNSIGNED NULL,

    supplier_reference_no VARCHAR(100) NULL,
    supplier_reference_date DATE NULL,

    subtotal DECIMAL(18,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    taxable_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    cgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    sgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    igst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    cess_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    round_off_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    order_status ENUM(
        'draft',
        'confirmed',
        'partially_received',
        'fully_received',
        'partially_invoiced',
        'fully_invoiced',
        'closed',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    notes TEXT NULL,
    terms_conditions TEXT NULL,

    approved_by BIGINT UNSIGNED NULL,
    approved_at DATETIME NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_purchase_orders_company_no (company_id, order_no),

    INDEX idx_purchase_orders_supplier (supplier_party_id),
    INDEX idx_purchase_orders_date (order_date),
    INDEX idx_purchase_orders_status (order_status),

    CONSTRAINT fk_purchase_orders_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_purchase_orders_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_purchase_orders_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_purchase_orders_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_purchase_orders_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_purchase_orders_requisition FOREIGN KEY (purchase_requisition_id) REFERENCES purchase_requisitions(id),
    CONSTRAINT fk_purchase_orders_supplier FOREIGN KEY (supplier_party_id) REFERENCES parties(id),
    CONSTRAINT fk_purchase_orders_billing_address FOREIGN KEY (billing_address_id) REFERENCES party_addresses(id),
    CONSTRAINT fk_purchase_orders_shipping_address FOREIGN KEY (shipping_address_id) REFERENCES party_addresses(id),
    CONSTRAINT fk_purchase_orders_contact FOREIGN KEY (contact_id) REFERENCES party_contacts(id),
    CONSTRAINT fk_purchase_orders_approved_by FOREIGN KEY (approved_by) REFERENCES users(id),
    CONSTRAINT fk_purchase_orders_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_purchase_orders_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE purchase_order_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    purchase_order_id BIGINT UNSIGNED NOT NULL,
    purchase_requisition_line_id BIGINT UNSIGNED NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    description VARCHAR(500) NULL,

    ordered_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    received_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    invoiced_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    pending_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    rate DECIMAL(18,4) NOT NULL DEFAULT 0,
    discount_percent DECIMAL(8,4) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    gross_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    taxable_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    tax_code_id BIGINT UNSIGNED NULL,
    tax_percent DECIMAL(8,4) NOT NULL DEFAULT 0,
    cgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    sgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    igst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    cess_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    line_total DECIMAL(18,2) NOT NULL DEFAULT 0,

    line_status ENUM(
        'open',
        'partially_received',
        'fully_received',
        'partially_invoiced',
        'fully_invoiced',
        'closed',
        'cancelled'
    ) NOT NULL DEFAULT 'open',

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_purchase_order_lines_doc_line (purchase_order_id, line_no),

    INDEX idx_purchase_order_lines_item (item_id),
    INDEX idx_purchase_order_lines_warehouse (warehouse_id),
    INDEX idx_purchase_order_lines_status (line_status),

    CONSTRAINT fk_purchase_order_lines_doc FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_purchase_order_lines_requisition_line FOREIGN KEY (purchase_requisition_line_id) REFERENCES purchase_requisition_lines(id),
    CONSTRAINT fk_purchase_order_lines_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_purchase_order_lines_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_purchase_order_lines_uom FOREIGN KEY (uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_purchase_order_lines_tax_code FOREIGN KEY (tax_code_id) REFERENCES tax_codes(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 2A. TRANSPORTERS
-- Simple transporter master for produce tracking
-- =========================================================
DROP TABLE IF EXISTS transporters;

CREATE TABLE transporters (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(150) NOT NULL,
    transporter_type ENUM(
        'courier',
        'third_party',
        'own_vehicle',
        'customer_pickup',
        'supplier_delivery'
    ) NOT NULL DEFAULT 'courier',
    delivery_mode ENUM(
        'direct_delivery',
        'pickup'
    ) NOT NULL DEFAULT 'direct_delivery',
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    remarks TEXT NULL,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_transporters_name (name),
    INDEX idx_transporters_type (transporter_type),
    INDEX idx_transporters_delivery_mode (delivery_mode),
    INDEX idx_transporters_active (is_active),

    CONSTRAINT fk_transporters_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_transporters_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 2B. PRODUCE TRACKING
-- Tracks finished produce after sales delivery / purchase order dispatch
-- =========================================================
DROP TABLE IF EXISTS produce_tracking_lines;
DROP TABLE IF EXISTS produce_trackings;

CREATE TABLE produce_trackings (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,

    tracking_no VARCHAR(100) NOT NULL,
    tracking_date DATE NOT NULL,

    reference_flow ENUM(
        'sales_delivery',
        'purchase_order',
        'combined'
    ) NOT NULL DEFAULT 'sales_delivery',

    sales_delivery_id BIGINT UNSIGNED NULL,
    purchase_order_id BIGINT UNSIGNED NULL,

    source_warehouse_id BIGINT UNSIGNED NULL,
    assigned_to_type ENUM(
        'employee',
        'supplier'
    ) NULL,
    assigned_employee_id BIGINT UNSIGNED NULL,
    assigned_supplier_party_id BIGINT UNSIGNED NULL,

    destination_type ENUM(
        'customer',
        'supplier',
        'branch',
        'warehouse',
        'job_site',
        'other'
    ) NOT NULL DEFAULT 'customer',

    destination_party_id BIGINT UNSIGNED NULL,
    destination_warehouse_id BIGINT UNSIGNED NULL,
    destination_location VARCHAR(255) NULL,
    destination_address TEXT NULL,

    transporter_party_id BIGINT UNSIGNED NULL,
    transporter_id BIGINT UNSIGNED NULL,
    vehicle_no VARCHAR(50) NULL,
    driver_name VARCHAR(150) NULL,
    driver_phone VARCHAR(20) NULL,
    lr_no VARCHAR(100) NULL,
    lr_date DATE NULL,

    tracking_status ENUM(
        'draft',
        'ready_to_dispatch',
        'dispatched',
        'in_transit',
        'reached_destination',
        'delivered',
        'returned',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    current_location VARCHAR(255) NULL,
    current_latitude DECIMAL(10,7) NULL,
    current_longitude DECIMAL(10,7) NULL,
    last_location_update_at DATETIME NULL,

    remarks TEXT NULL,

    posted_by BIGINT UNSIGNED NULL,
    posted_at DATETIME NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_produce_trackings_company_no (company_id, tracking_no),

    INDEX idx_produce_trackings_date (tracking_date),
    INDEX idx_produce_trackings_status (tracking_status),
    INDEX idx_produce_trackings_flow (reference_flow),
    INDEX idx_produce_trackings_sales_delivery (sales_delivery_id),
    INDEX idx_produce_trackings_purchase_order (purchase_order_id),
    INDEX idx_produce_trackings_assigned_type (assigned_to_type),
    INDEX idx_produce_trackings_assigned_employee (assigned_employee_id),
    INDEX idx_produce_trackings_assigned_supplier (assigned_supplier_party_id),
    INDEX idx_produce_trackings_destination_party (destination_party_id),
    INDEX idx_produce_trackings_transporter (transporter_party_id),
    INDEX idx_produce_trackings_transporter_master (transporter_id),

    CONSTRAINT fk_produce_trackings_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_produce_trackings_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_produce_trackings_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_produce_trackings_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_produce_trackings_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_produce_trackings_sales_delivery FOREIGN KEY (sales_delivery_id) REFERENCES sales_deliveries(id),
    CONSTRAINT fk_produce_trackings_purchase_order FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id),
    CONSTRAINT fk_produce_trackings_source_warehouse FOREIGN KEY (source_warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_produce_trackings_assigned_employee FOREIGN KEY (assigned_employee_id) REFERENCES employees(id),
    CONSTRAINT fk_produce_trackings_assigned_supplier FOREIGN KEY (assigned_supplier_party_id) REFERENCES parties(id),
    CONSTRAINT fk_produce_trackings_destination_party FOREIGN KEY (destination_party_id) REFERENCES parties(id),
    CONSTRAINT fk_produce_trackings_destination_warehouse FOREIGN KEY (destination_warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_produce_trackings_transporter FOREIGN KEY (transporter_party_id) REFERENCES parties(id),
    CONSTRAINT fk_produce_trackings_transporter_master FOREIGN KEY (transporter_id) REFERENCES transporters(id),
    CONSTRAINT fk_produce_trackings_posted_by FOREIGN KEY (posted_by) REFERENCES users(id),
    CONSTRAINT fk_produce_trackings_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_produce_trackings_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE produce_tracking_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    produce_tracking_id BIGINT UNSIGNED NOT NULL,
    sales_delivery_line_id BIGINT UNSIGNED NULL,
    purchase_order_line_id BIGINT UNSIGNED NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NOT NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    batch_id BIGINT UNSIGNED NULL,
    serial_id BIGINT UNSIGNED NULL,

    tracked_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    delivered_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    received_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    balance_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    line_status ENUM(
        'open',
        'in_transit',
        'delivered',
        'returned',
        'cancelled'
    ) NOT NULL DEFAULT 'open',

    current_location VARCHAR(255) NULL,
    last_location_update_at DATETIME NULL,
    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_produce_tracking_lines_doc_line (produce_tracking_id, line_no),

    INDEX idx_produce_tracking_lines_item (item_id),
    INDEX idx_produce_tracking_lines_warehouse (warehouse_id),
    INDEX idx_produce_tracking_lines_sales_delivery_line (sales_delivery_line_id),
    INDEX idx_produce_tracking_lines_purchase_order_line (purchase_order_line_id),
    INDEX idx_produce_tracking_lines_status (line_status),

    CONSTRAINT fk_produce_tracking_lines_doc FOREIGN KEY (produce_tracking_id) REFERENCES produce_trackings(id) ON DELETE CASCADE,
    CONSTRAINT fk_produce_tracking_lines_sales_delivery_line FOREIGN KEY (sales_delivery_line_id) REFERENCES sales_delivery_lines(id),
    CONSTRAINT fk_produce_tracking_lines_purchase_order_line FOREIGN KEY (purchase_order_line_id) REFERENCES purchase_order_lines(id),
    CONSTRAINT fk_produce_tracking_lines_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_produce_tracking_lines_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_produce_tracking_lines_uom FOREIGN KEY (uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_produce_tracking_lines_batch FOREIGN KEY (batch_id) REFERENCES stock_batches(id),
    CONSTRAINT fk_produce_tracking_lines_serial FOREIGN KEY (serial_id) REFERENCES stock_serials(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 3. PURCHASE RECEIPTS (GOODS RECEIPT NOTE / INWARD)
-- This is where stock comes in
-- =========================================================
DROP TABLE IF EXISTS purchase_receipt_lines;
DROP TABLE IF EXISTS purchase_receipts;

CREATE TABLE purchase_receipts (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,
    purchase_order_id BIGINT UNSIGNED NULL,

    receipt_no VARCHAR(100) NOT NULL,
    receipt_date DATE NOT NULL,

    supplier_party_id BIGINT UNSIGNED NOT NULL,

    warehouse_id BIGINT UNSIGNED NOT NULL,
    voucher_id BIGINT UNSIGNED NULL,

    supplier_dc_no VARCHAR(100) NULL,
    supplier_dc_date DATE NULL,
    supplier_invoice_no VARCHAR(100) NULL,
    supplier_invoice_date DATE NULL,

    vehicle_no VARCHAR(50) NULL,
    transporter_party_id BIGINT UNSIGNED NULL,
    lr_no VARCHAR(100) NULL,
    lr_date DATE NULL,

    receipt_status ENUM(
        'draft',
        'posted',
        'partially_invoiced',
        'fully_invoiced',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    notes TEXT NULL,

    posted_by BIGINT UNSIGNED NULL,
    posted_at DATETIME NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_purchase_receipts_company_no (company_id, receipt_no),

    INDEX idx_purchase_receipts_supplier (supplier_party_id),
    INDEX idx_purchase_receipts_date (receipt_date),
    INDEX idx_purchase_receipts_status (receipt_status),

    CONSTRAINT fk_purchase_receipts_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_purchase_receipts_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_purchase_receipts_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_purchase_receipts_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_purchase_receipts_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_purchase_receipts_order FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id),
    CONSTRAINT fk_purchase_receipts_supplier FOREIGN KEY (supplier_party_id) REFERENCES parties(id),
    CONSTRAINT fk_purchase_receipts_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_purchase_receipts_transporter FOREIGN KEY (transporter_party_id) REFERENCES parties(id),
    CONSTRAINT fk_purchase_receipts_posted_by FOREIGN KEY (posted_by) REFERENCES users(id),
    CONSTRAINT fk_purchase_receipts_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_purchase_receipts_updated_by FOREIGN KEY (updated_by) REFERENCES users(id),
    CONSTRAINT fk_purchase_receipts_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE purchase_receipt_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    purchase_receipt_id BIGINT UNSIGNED NOT NULL,
    purchase_order_line_id BIGINT UNSIGNED NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NOT NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    batch_id BIGINT UNSIGNED NULL,
    serial_id BIGINT UNSIGNED NULL,

    description VARCHAR(500) NULL,

    received_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    accepted_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    rejected_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    invoiced_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    pending_invoice_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    rate DECIMAL(18,4) NOT NULL DEFAULT 0,
    amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    quality_status ENUM(
        'accepted',
        'partial_rejected',
        'rejected',
        'hold'
    ) NOT NULL DEFAULT 'accepted',

    line_status ENUM(
        'open',
        'partially_invoiced',
        'fully_invoiced',
        'cancelled'
    ) NOT NULL DEFAULT 'open',

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_purchase_receipt_lines_doc_line (purchase_receipt_id, line_no),

    INDEX idx_purchase_receipt_lines_item (item_id),
    INDEX idx_purchase_receipt_lines_warehouse (warehouse_id),

    CONSTRAINT fk_purchase_receipt_lines_doc FOREIGN KEY (purchase_receipt_id) REFERENCES purchase_receipts(id) ON DELETE CASCADE,
    CONSTRAINT fk_purchase_receipt_lines_order_line FOREIGN KEY (purchase_order_line_id) REFERENCES purchase_order_lines(id),
    CONSTRAINT fk_purchase_receipt_lines_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_purchase_receipt_lines_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_purchase_receipt_lines_uom FOREIGN KEY (uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_purchase_receipt_lines_batch FOREIGN KEY (batch_id) REFERENCES stock_batches(id),
    CONSTRAINT fk_purchase_receipt_lines_serial FOREIGN KEY (serial_id) REFERENCES stock_serials(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 4. PURCHASE INVOICES
-- Accounting + GST input + supplier payable
-- =========================================================
DROP TABLE IF EXISTS purchase_invoice_lines;
DROP TABLE IF EXISTS purchase_invoices;

CREATE TABLE purchase_invoices (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,
    purchase_order_id BIGINT UNSIGNED NULL,
    purchase_receipt_id BIGINT UNSIGNED NULL,

    invoice_no VARCHAR(100) NOT NULL,
    invoice_date DATE NOT NULL,
    due_date DATE NULL,

    supplier_party_id BIGINT UNSIGNED NOT NULL,

    billing_address_id BIGINT UNSIGNED NULL,
    shipping_address_id BIGINT UNSIGNED NULL,
    contact_id BIGINT UNSIGNED NULL,

    supplier_reference_no VARCHAR(100) NULL,
    supplier_reference_date DATE NULL,

    subtotal DECIMAL(18,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    taxable_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    cgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    sgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    igst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    cess_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    round_off_method ENUM('manual', 'bill', 'item') NOT NULL DEFAULT 'manual',
    round_off_precision DECIMAL(18,2) NOT NULL DEFAULT 1.00,
    round_off_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    paid_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    balance_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    adjustment_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    adjustment_account_id BIGINT UNSIGNED NULL,
    adjustment_remarks VARCHAR(500) NULL,

    voucher_id BIGINT UNSIGNED NULL,

    invoice_status ENUM(
        'draft',
        'posted',
        'partially_paid',
        'paid',
        'partially_returned',
        'returned',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    notes TEXT NULL,
    terms_conditions TEXT NULL,

    posted_by BIGINT UNSIGNED NULL,
    posted_at DATETIME NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_purchase_invoices_company_no (company_id, invoice_no),

    INDEX idx_purchase_invoices_supplier (supplier_party_id),
    INDEX idx_purchase_invoices_date (invoice_date),
    INDEX idx_purchase_invoices_due_date (due_date),
    INDEX idx_purchase_invoices_status (invoice_status),

    CONSTRAINT fk_purchase_invoices_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_purchase_invoices_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_purchase_invoices_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_purchase_invoices_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_purchase_invoices_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_purchase_invoices_order FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id),
    CONSTRAINT fk_purchase_invoices_receipt FOREIGN KEY (purchase_receipt_id) REFERENCES purchase_receipts(id),
    CONSTRAINT fk_purchase_invoices_supplier FOREIGN KEY (supplier_party_id) REFERENCES parties(id),
    CONSTRAINT fk_purchase_invoices_billing_address FOREIGN KEY (billing_address_id) REFERENCES party_addresses(id),
    CONSTRAINT fk_purchase_invoices_shipping_address FOREIGN KEY (shipping_address_id) REFERENCES party_addresses(id),
    CONSTRAINT fk_purchase_invoices_contact FOREIGN KEY (contact_id) REFERENCES party_contacts(id),
    CONSTRAINT fk_purchase_invoices_adjustment_account FOREIGN KEY (adjustment_account_id) REFERENCES accounts(id),
    CONSTRAINT fk_purchase_invoices_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id),
    CONSTRAINT fk_purchase_invoices_posted_by FOREIGN KEY (posted_by) REFERENCES users(id),
    CONSTRAINT fk_purchase_invoices_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_purchase_invoices_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE purchase_invoice_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    purchase_invoice_id BIGINT UNSIGNED NOT NULL,
    purchase_order_line_id BIGINT UNSIGNED NULL,
    purchase_receipt_line_id BIGINT UNSIGNED NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    batch_id BIGINT UNSIGNED NULL,
    serial_id BIGINT UNSIGNED NULL,

    description VARCHAR(500) NULL,

    invoiced_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    returned_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    pending_return_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    rate DECIMAL(18,4) NOT NULL DEFAULT 0,
    discount_percent DECIMAL(8,4) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    gross_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    taxable_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    tax_code_id BIGINT UNSIGNED NULL,
    tax_percent DECIMAL(8,4) NOT NULL DEFAULT 0,
    cgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    sgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    igst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    cess_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    line_total DECIMAL(18,2) NOT NULL DEFAULT 0,

    line_status ENUM(
        'open',
        'partially_returned',
        'fully_returned',
        'cancelled'
    ) NOT NULL DEFAULT 'open',

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_purchase_invoice_lines_doc_line (purchase_invoice_id, line_no),

    INDEX idx_purchase_invoice_lines_item (item_id),
    INDEX idx_purchase_invoice_lines_warehouse (warehouse_id),

    CONSTRAINT fk_purchase_invoice_lines_doc FOREIGN KEY (purchase_invoice_id) REFERENCES purchase_invoices(id) ON DELETE CASCADE,
    CONSTRAINT fk_purchase_invoice_lines_order_line FOREIGN KEY (purchase_order_line_id) REFERENCES purchase_order_lines(id),
    CONSTRAINT fk_purchase_invoice_lines_receipt_line FOREIGN KEY (purchase_receipt_line_id) REFERENCES purchase_receipt_lines(id),
    CONSTRAINT fk_purchase_invoice_lines_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_purchase_invoice_lines_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_purchase_invoice_lines_uom FOREIGN KEY (uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_purchase_invoice_lines_batch FOREIGN KEY (batch_id) REFERENCES stock_batches(id),
    CONSTRAINT fk_purchase_invoice_lines_serial FOREIGN KEY (serial_id) REFERENCES stock_serials(id),
    CONSTRAINT fk_purchase_invoice_lines_tax_code FOREIGN KEY (tax_code_id) REFERENCES tax_codes(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 5. PURCHASE PAYMENTS
-- Supplier payment / advance / on-account
-- =========================================================
DROP TABLE IF EXISTS purchase_payment_allocations;
DROP TABLE IF EXISTS purchase_payments;

CREATE TABLE purchase_payments (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,

    payment_no VARCHAR(100) NOT NULL,
    payment_date DATE NOT NULL,

    supplier_party_id BIGINT UNSIGNED NOT NULL,

    payment_mode ENUM(
        'cash',
        'bank',
        'upi',
        'cheque',
        'card',
        'wallet',
        'adjustment',
        'other'
    ) NOT NULL DEFAULT 'bank',

    account_id BIGINT UNSIGNED NOT NULL,

    reference_no VARCHAR(100) NULL,
    reference_date DATE NULL,

    paid_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    unallocated_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    voucher_id BIGINT UNSIGNED NULL,

    payment_status ENUM(
        'draft',
        'posted',
        'partially_allocated',
        'fully_allocated',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    notes TEXT NULL,

    posted_by BIGINT UNSIGNED NULL,
    posted_at DATETIME NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_purchase_payments_company_no (company_id, payment_no),

    INDEX idx_purchase_payments_supplier (supplier_party_id),
    INDEX idx_purchase_payments_date (payment_date),
    INDEX idx_purchase_payments_status (payment_status),

    CONSTRAINT fk_purchase_payments_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_purchase_payments_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_purchase_payments_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_purchase_payments_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_purchase_payments_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_purchase_payments_supplier FOREIGN KEY (supplier_party_id) REFERENCES parties(id),
    CONSTRAINT fk_purchase_payments_account FOREIGN KEY (account_id) REFERENCES accounts(id),
    CONSTRAINT fk_purchase_payments_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id),
    CONSTRAINT fk_purchase_payments_posted_by FOREIGN KEY (posted_by) REFERENCES users(id),
    CONSTRAINT fk_purchase_payments_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_purchase_payments_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE purchase_payment_allocations (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    purchase_payment_id BIGINT UNSIGNED NOT NULL,
    purchase_invoice_id BIGINT UNSIGNED NULL,

    allocated_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    allocation_type ENUM('against_invoice', 'advance', 'on_account', 'adjustment') NOT NULL DEFAULT 'against_invoice',

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    INDEX idx_purchase_payment_allocations_payment (purchase_payment_id),
    INDEX idx_purchase_payment_allocations_invoice (purchase_invoice_id),

    CONSTRAINT fk_purchase_payment_allocations_payment FOREIGN KEY (purchase_payment_id) REFERENCES purchase_payments(id) ON DELETE CASCADE,
    CONSTRAINT fk_purchase_payment_allocations_invoice FOREIGN KEY (purchase_invoice_id) REFERENCES purchase_invoices(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 6. PURCHASE RETURNS
-- Material return + financial reversal / debit note basis
-- =========================================================
DROP TABLE IF EXISTS purchase_return_lines;
DROP TABLE IF EXISTS purchase_returns;

CREATE TABLE purchase_returns (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,
    purchase_invoice_id BIGINT UNSIGNED NULL,

    return_no VARCHAR(100) NOT NULL,
    return_date DATE NOT NULL,

    supplier_party_id BIGINT UNSIGNED NOT NULL,

    subtotal DECIMAL(18,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    taxable_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    cgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    sgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    igst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    cess_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    round_off_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    voucher_id BIGINT UNSIGNED NULL,

    return_reason VARCHAR(255) NULL,

    return_status ENUM(
        'draft',
        'posted',
        'debited',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    notes TEXT NULL,

    posted_by BIGINT UNSIGNED NULL,
    posted_at DATETIME NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_purchase_returns_company_no (company_id, return_no),

    INDEX idx_purchase_returns_supplier (supplier_party_id),
    INDEX idx_purchase_returns_date (return_date),
    INDEX idx_purchase_returns_status (return_status),

    CONSTRAINT fk_purchase_returns_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_purchase_returns_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_purchase_returns_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_purchase_returns_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_purchase_returns_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_purchase_returns_invoice FOREIGN KEY (purchase_invoice_id) REFERENCES purchase_invoices(id),
    CONSTRAINT fk_purchase_returns_supplier FOREIGN KEY (supplier_party_id) REFERENCES parties(id),
    CONSTRAINT fk_purchase_returns_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id),
    CONSTRAINT fk_purchase_returns_posted_by FOREIGN KEY (posted_by) REFERENCES users(id),
    CONSTRAINT fk_purchase_returns_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_purchase_returns_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE purchase_return_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    purchase_return_id BIGINT UNSIGNED NOT NULL,
    purchase_invoice_line_id BIGINT UNSIGNED NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NOT NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    batch_id BIGINT UNSIGNED NULL,
    serial_id BIGINT UNSIGNED NULL,

    return_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    rate DECIMAL(18,4) NOT NULL DEFAULT 0,
    discount_percent DECIMAL(8,4) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    gross_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    taxable_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    tax_code_id BIGINT UNSIGNED NULL,
    tax_percent DECIMAL(8,4) NOT NULL DEFAULT 0,
    cgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    sgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    igst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    cess_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    line_total DECIMAL(18,2) NOT NULL DEFAULT 0,

    return_reason VARCHAR(255) NULL,
    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_purchase_return_lines_doc_line (purchase_return_id, line_no),

    INDEX idx_purchase_return_lines_item (item_id),
    INDEX idx_purchase_return_lines_warehouse (warehouse_id),

    CONSTRAINT fk_purchase_return_lines_doc FOREIGN KEY (purchase_return_id) REFERENCES purchase_returns(id) ON DELETE CASCADE,
    CONSTRAINT fk_purchase_return_lines_invoice_line FOREIGN KEY (purchase_invoice_line_id) REFERENCES purchase_invoice_lines(id),
    CONSTRAINT fk_purchase_return_lines_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_purchase_return_lines_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_purchase_return_lines_uom FOREIGN KEY (uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_purchase_return_lines_batch FOREIGN KEY (batch_id) REFERENCES stock_batches(id),
    CONSTRAINT fk_purchase_return_lines_serial FOREIGN KEY (serial_id) REFERENCES stock_serials(id),
    CONSTRAINT fk_purchase_return_lines_tax_code FOREIGN KEY (tax_code_id) REFERENCES tax_codes(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


SET FOREIGN_KEY_CHECKS = 1;
-- =========================================================
-- MODULE 7 : GST / TAX ENGINE + DOCUMENT POSTING RULES
-- ERP FOUNDATION - MySQL 8
-- Depends on MODULE 1A + 1B + 2 + 3 + 4 + 5 + 6
-- =========================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- 1. STATES MASTER
-- Used for GST intra/inter-state determination
-- =========================================================
DROP TABLE IF EXISTS states;

CREATE TABLE states (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    country_code VARCHAR(10) NOT NULL DEFAULT 'IN',
    state_code VARCHAR(10) NOT NULL,
    state_name VARCHAR(100) NOT NULL,
    gst_state_code VARCHAR(10) NULL,

    is_union_territory TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_states_code (country_code, state_code),
    UNIQUE KEY uq_states_name (country_code, state_name),
    UNIQUE KEY uq_states_gst_state_code (gst_state_code),

    INDEX idx_states_country (country_code),
    INDEX idx_states_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 2. GST REGISTRATIONS
-- Company / branch / location GST registration details
-- =========================================================
DROP TABLE IF EXISTS gst_registrations;

CREATE TABLE gst_registrations (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NULL,
    location_id BIGINT UNSIGNED NULL,

    registration_name VARCHAR(255) NOT NULL,
    gstin VARCHAR(20) NULL,
    pan_no VARCHAR(20) NULL,

    state_id BIGINT UNSIGNED NOT NULL,
    state_code VARCHAR(10) NULL,

    legal_name VARCHAR(255) NULL,
    trade_name VARCHAR(255) NULL,

    registration_type ENUM(
        'regular',
        'composition',
        'sez',
        'sez_unit',
        'casual',
        'non_resident',
        'unregistered'
    ) NOT NULL DEFAULT 'regular',

    effective_from DATE NULL,
    effective_to DATE NULL,

    is_default TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    remarks TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_gst_registrations_gstin (gstin),

    INDEX idx_gst_registrations_company (company_id),
    INDEX idx_gst_registrations_branch (branch_id),
    INDEX idx_gst_registrations_location (location_id),
    INDEX idx_gst_registrations_state (state_id),
    INDEX idx_gst_registrations_default (is_default),
    INDEX idx_gst_registrations_active (is_active),

    CONSTRAINT fk_gst_registrations_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_gst_registrations_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_gst_registrations_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_gst_registrations_state FOREIGN KEY (state_id) REFERENCES states(id),
    CONSTRAINT fk_gst_registrations_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_gst_registrations_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 3. GST TAX RULES
-- Main tax decision engine
-- =========================================================
DROP TABLE IF EXISTS gst_tax_rules;

CREATE TABLE gst_tax_rules (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    rule_code VARCHAR(50) NOT NULL,
    rule_name VARCHAR(150) NOT NULL,

    transaction_type ENUM(
        'sales',
        'purchase',
        'sales_return',
        'purchase_return',
        'service_sales',
        'service_purchase'
    ) NOT NULL,

    item_type ENUM(
        'stock',
        'service',
        'manufactured',
        'raw_material',
        'semi_finished',
        'finished_goods',
        'consumable',
        'asset',
        'non_stock',
        'all'
    ) NOT NULL DEFAULT 'all',

    tax_code_id BIGINT UNSIGNED NOT NULL,

    place_of_supply_result ENUM(
        'intra_state',
        'inter_state',
        'export',
        'import',
        'sez',
        'reverse_charge',
        'all'
    ) NOT NULL DEFAULT 'all',

    tax_application ENUM(
        'cgst_sgst',
        'igst',
        'cess_only',
        'exempt',
        'nil_rated',
        'non_gst'
    ) NOT NULL,

    reverse_charge_applicable TINYINT(1) NOT NULL DEFAULT 0,
    input_tax_credit_allowed TINYINT(1) NOT NULL DEFAULT 1,

    priority_order INT NOT NULL DEFAULT 1,

    is_active TINYINT(1) NOT NULL DEFAULT 1,
    remarks TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_gst_tax_rules_code (rule_code),

    INDEX idx_gst_tax_rules_transaction_type (transaction_type),
    INDEX idx_gst_tax_rules_item_type (item_type),
    INDEX idx_gst_tax_rules_tax_code_id (tax_code_id),
    INDEX idx_gst_tax_rules_priority (priority_order),
    INDEX idx_gst_tax_rules_active (is_active),

    CONSTRAINT fk_gst_tax_rules_tax_code FOREIGN KEY (tax_code_id) REFERENCES tax_codes(id),
    CONSTRAINT fk_gst_tax_rules_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_gst_tax_rules_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 5. DOCUMENT TAX LINES
-- Tax breakup storage for any posted document
-- Generic structure for invoices / returns / etc.
-- =========================================================
DROP TABLE IF EXISTS document_tax_lines;

CREATE TABLE document_tax_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_module VARCHAR(50) NOT NULL,
    document_table VARCHAR(100) NOT NULL,
    document_id BIGINT UNSIGNED NOT NULL,
    document_no VARCHAR(100) NULL,
    document_date DATE NOT NULL,

    line_table VARCHAR(100) NULL,
    line_id BIGINT UNSIGNED NULL,

    item_id BIGINT UNSIGNED NULL,
    tax_code_id BIGINT UNSIGNED NULL,

    hsn_sac_code VARCHAR(20) NULL,

    taxable_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    cgst_percent DECIMAL(8,4) NOT NULL DEFAULT 0,
    cgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    sgst_percent DECIMAL(8,4) NOT NULL DEFAULT 0,
    sgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    igst_percent DECIMAL(8,4) NOT NULL DEFAULT 0,
    igst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    cess_percent DECIMAL(8,4) NOT NULL DEFAULT 0,
    cess_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    tax_application ENUM(
        'cgst_sgst',
        'igst',
        'cess_only',
        'exempt',
        'nil_rated',
        'non_gst'
    ) NOT NULL DEFAULT 'cgst_sgst',

    reverse_charge_applicable TINYINT(1) NOT NULL DEFAULT 0,
    input_tax_credit_allowed TINYINT(1) NOT NULL DEFAULT 1,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    INDEX idx_document_tax_lines_doc (document_module, document_table, document_id),
    INDEX idx_document_tax_lines_doc_date (document_date),
    INDEX idx_document_tax_lines_item (item_id),
    INDEX idx_document_tax_lines_tax_code (tax_code_id),
    INDEX idx_document_tax_lines_hsn (hsn_sac_code),

    CONSTRAINT fk_document_tax_lines_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_document_tax_lines_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_document_tax_lines_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_document_tax_lines_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_document_tax_lines_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_document_tax_lines_tax_code FOREIGN KEY (tax_code_id) REFERENCES tax_codes(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 6. COMMUNICATION / EMAIL ENGINE
-- System-wide mail settings, templates, rules, and delivery logs
-- =========================================================
DROP TABLE IF EXISTS email_messages;
DROP TABLE IF EXISTS email_rules;
DROP TABLE IF EXISTS email_templates;
DROP TABLE IF EXISTS email_module_settings;
DROP TABLE IF EXISTS email_settings;

CREATE TABLE email_settings (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NULL,

    setting_name VARCHAR(150) NOT NULL,
    mail_driver ENUM('disabled', 'log', 'mail') NOT NULL DEFAULT 'log',
    from_name VARCHAR(150) NOT NULL,
    from_email VARCHAR(150) NOT NULL,
    reply_to_email VARCHAR(150) NULL,

    smtp_host VARCHAR(150) NULL,
    smtp_port INT NULL,
    smtp_encryption ENUM('tls', 'ssl', 'none') NULL,
    smtp_username VARCHAR(150) NULL,
    smtp_password VARCHAR(255) NULL,

    auto_email_enabled TINYINT(1) NOT NULL DEFAULT 1,
    is_default TINYINT(1) NOT NULL DEFAULT 1,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_email_settings_company_name (company_id, setting_name),

    INDEX idx_email_settings_company (company_id),
    INDEX idx_email_settings_active (is_active),

    CONSTRAINT fk_email_settings_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_email_settings_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_email_settings_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE email_module_settings (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NULL,
    module VARCHAR(50) NOT NULL,
    document_type VARCHAR(100) NULL,

    auto_email_enabled TINYINT(1) NOT NULL DEFAULT 1,
    manual_email_enabled TINYINT(1) NOT NULL DEFAULT 1,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    remarks VARCHAR(500) NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_email_module_settings_scope (company_id, module, document_type),

    INDEX idx_email_module_settings_company (company_id),
    INDEX idx_email_module_settings_module (module),

    CONSTRAINT fk_email_module_settings_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_email_module_settings_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_email_module_settings_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE email_templates (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NULL,
    template_code VARCHAR(100) NOT NULL,
    template_name VARCHAR(150) NOT NULL,
    module VARCHAR(50) NOT NULL,
    document_type VARCHAR(100) NULL,
    event_code VARCHAR(100) NULL,

    subject_template VARCHAR(255) NOT NULL,
    body_template MEDIUMTEXT NOT NULL,
    is_html TINYINT(1) NOT NULL DEFAULT 1,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_email_templates_code (company_id, template_code),

    INDEX idx_email_templates_company (company_id),
    INDEX idx_email_templates_module (module),

    CONSTRAINT fk_email_templates_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_email_templates_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_email_templates_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE email_rules (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NULL,
    rule_code VARCHAR(100) NOT NULL,
    rule_name VARCHAR(150) NOT NULL,
    module VARCHAR(50) NOT NULL,
    document_type VARCHAR(100) NULL,
    event_code VARCHAR(100) NOT NULL,
    template_id BIGINT UNSIGNED NULL,

    auto_enabled TINYINT(1) NOT NULL DEFAULT 1,
    manual_enabled TINYINT(1) NOT NULL DEFAULT 1,
    send_to_party_email TINYINT(1) NOT NULL DEFAULT 0,
    send_to_contact_email TINYINT(1) NOT NULL DEFAULT 0,
    send_to_assigned_user TINYINT(1) NOT NULL DEFAULT 0,
    send_to_owner_user TINYINT(1) NOT NULL DEFAULT 0,

    recipient_emails TEXT NULL,
    cc_emails TEXT NULL,
    bcc_emails TEXT NULL,
    subject_override VARCHAR(255) NULL,
    body_override MEDIUMTEXT NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_email_rules_code (company_id, rule_code),

    INDEX idx_email_rules_company (company_id),
    INDEX idx_email_rules_module_event (module, event_code),

    CONSTRAINT fk_email_rules_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_email_rules_template FOREIGN KEY (template_id) REFERENCES email_templates(id),
    CONSTRAINT fk_email_rules_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_email_rules_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE email_messages (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NULL,
    email_setting_id BIGINT UNSIGNED NULL,
    email_template_id BIGINT UNSIGNED NULL,
    email_rule_id BIGINT UNSIGNED NULL,

    module VARCHAR(50) NULL,
    document_type VARCHAR(100) NULL,
    document_id BIGINT UNSIGNED NULL,
    event_code VARCHAR(100) NULL,

    trigger_mode ENUM('manual', 'auto') NOT NULL DEFAULT 'manual',
    recipient_to TEXT NOT NULL,
    recipient_cc TEXT NULL,
    recipient_bcc TEXT NULL,
    subject VARCHAR(255) NOT NULL,
    body MEDIUMTEXT NOT NULL,
    is_html TINYINT(1) NOT NULL DEFAULT 1,

    status ENUM('queued', 'sent', 'failed', 'skipped') NOT NULL DEFAULT 'queued',
    error_message TEXT NULL,
    sent_at DATETIME NULL,

    created_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    INDEX idx_email_messages_company (company_id),
    INDEX idx_email_messages_document (module, document_type, document_id),
    INDEX idx_email_messages_status (status),

    CONSTRAINT fk_email_messages_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_email_messages_setting FOREIGN KEY (email_setting_id) REFERENCES email_settings(id),
    CONSTRAINT fk_email_messages_template FOREIGN KEY (email_template_id) REFERENCES email_templates(id),
    CONSTRAINT fk_email_messages_rule FOREIGN KEY (email_rule_id) REFERENCES email_rules(id),
    CONSTRAINT fk_email_messages_created_by FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- SEED DATA : COMMUNICATION / EMAIL ENGINE
-- =========================================================
INSERT INTO email_settings (
    company_id, setting_name, mail_driver, from_name, from_email,
    reply_to_email, auto_email_enabled, is_default, is_active
) VALUES
(NULL, 'System Default Mail', 'log', 'Billing ERP', 'noreply@example.com', NULL, 1, 1, 1);

INSERT INTO email_module_settings (
    company_id, module, document_type, auto_email_enabled, manual_email_enabled, is_active, remarks
) VALUES
(NULL, 'sales', NULL, 1, 1, 1, 'Sales module communication control'),
(NULL, 'purchase', NULL, 1, 1, 1, 'Purchase module communication control'),
(NULL, 'accounts', NULL, 1, 1, 1, 'Accounts module communication control'),
(NULL, 'inventory', NULL, 1, 1, 1, 'Inventory module communication control'),
(NULL, 'hr', NULL, 1, 1, 1, 'HR module communication control'),
(NULL, 'crm', NULL, 1, 1, 1, 'CRM module communication control'),
(NULL, 'service', NULL, 1, 1, 1, 'Service and support module communication control'),
(NULL, 'manufacturing', NULL, 1, 1, 1, 'Manufacturing module communication control'),
(NULL, 'asset', NULL, 1, 1, 1, 'Asset module communication control'),
(NULL, 'project', NULL, 1, 1, 1, 'Project module communication control');

INSERT INTO email_templates (
    company_id, template_code, template_name, module, document_type, event_code,
    subject_template, body_template, is_html, is_active
) VALUES
(NULL, 'SALES_QUOTATION_SENT', 'Sales Quotation Sent', 'sales', 'sales_quotation', 'quotation_sent', 'Quotation {{document_no}} from Billing ERP', '<p>Dear {{party_name}},</p><p>Your quotation <strong>{{document_no}}</strong> dated {{document_date}} is ready.</p><p>Total amount: {{total_amount}}</p>', 1, 1),
(NULL, 'SALES_INVOICE_POSTED', 'Sales Invoice Posted', 'sales', 'sales_invoice', 'sales_invoice_posted', 'Invoice {{document_no}} posted', '<p>Dear {{party_name}},</p><p>Your invoice <strong>{{document_no}}</strong> dated {{document_date}} has been posted.</p><p>Total amount: {{total_amount}}</p>', 1, 1),
(NULL, 'PURCHASE_ORDER_CONFIRMED', 'Purchase Order Confirmed', 'purchase', 'purchase_order', 'purchase_order_confirmed', 'Purchase Order {{document_no}} confirmed', '<p>Dear {{party_name}},</p><p>Purchase order <strong>{{document_no}}</strong> dated {{document_date}} has been confirmed.</p><p>Total amount: {{total_amount}}</p>', 1, 1),
(NULL, 'PURCHASE_INVOICE_POSTED', 'Purchase Invoice Posted', 'purchase', 'purchase_invoice', 'purchase_invoice_posted', 'Purchase Invoice {{document_no}} booked', '<p>Dear {{party_name}},</p><p>Purchase invoice <strong>{{document_no}}</strong> dated {{document_date}} has been booked.</p><p>Total amount: {{total_amount}}</p>', 1, 1),
(NULL, 'SERVICE_TICKET_CREATED', 'Service Ticket Created', 'service', 'service_ticket', 'service_ticket_created', 'Service ticket {{document_no}} created', '<p>Hello,</p><p>Service ticket <strong>{{document_no}}</strong> has been created.</p><p>Issue: {{issue_title}}</p>', 1, 1),
(NULL, 'LEAVE_REQUEST_SUBMITTED', 'Leave Request Submitted', 'hr', 'leave_request', 'leave_request_submitted', 'Leave request submitted', '<p>Hello,</p><p>A leave request has been submitted.</p><p>Status: {{status}}</p><p>Notes: {{notes}}</p>', 1, 1),
(NULL, 'LEAVE_REQUEST_APPROVED', 'Leave Request Approved', 'hr', 'leave_request', 'leave_request_approved', 'Leave request approved', '<p>Hello,</p><p>Your leave request has been approved.</p><p>Status: {{status}}</p></p>', 1, 1),
(NULL, 'PAYSLIP_GENERATED', 'Payslip Generated', 'hr', 'payslip', 'payslip_generated', 'Payslip {{document_no}} generated', '<p>Hello,</p><p>Your payslip <strong>{{document_no}}</strong> has been generated.</p><p>Net salary: {{total_amount}}</p>', 1, 1);

INSERT INTO email_rules (
    company_id, rule_code, rule_name, module, document_type, event_code, template_id,
    auto_enabled, manual_enabled, send_to_party_email, send_to_contact_email,
    send_to_assigned_user, send_to_owner_user, recipient_emails, cc_emails, bcc_emails, is_active
)
SELECT
    NULL,
    seed.rule_code,
    seed.rule_name,
    seed.module,
    seed.document_type,
    seed.event_code,
    et.id,
    1,
    1,
    seed.send_to_party_email,
    seed.send_to_contact_email,
    seed.send_to_assigned_user,
    seed.send_to_owner_user,
    NULL,
    NULL,
    NULL,
    1
FROM (
    SELECT 'RULE_SALES_QUOTATION_SENT' AS rule_code, 'Quotation sent to customer' AS rule_name, 'sales' AS module, 'sales_quotation' AS document_type, 'quotation_sent' AS event_code, 'SALES_QUOTATION_SENT' AS template_code, 1 AS send_to_party_email, 1 AS send_to_contact_email, 0 AS send_to_assigned_user, 0 AS send_to_owner_user
    UNION ALL SELECT 'RULE_SALES_INVOICE_POSTED', 'Sales invoice posted to customer', 'sales', 'sales_invoice', 'sales_invoice_posted', 'SALES_INVOICE_POSTED', 1, 1, 0, 0
    UNION ALL SELECT 'RULE_PURCHASE_ORDER_CONFIRMED', 'Purchase order confirmed to supplier', 'purchase', 'purchase_order', 'purchase_order_confirmed', 'PURCHASE_ORDER_CONFIRMED', 1, 1, 0, 0
    UNION ALL SELECT 'RULE_PURCHASE_INVOICE_POSTED', 'Purchase invoice posted to supplier', 'purchase', 'purchase_invoice', 'purchase_invoice_posted', 'PURCHASE_INVOICE_POSTED', 1, 1, 0, 0
    UNION ALL SELECT 'RULE_SERVICE_TICKET_CREATED', 'Service ticket auto reply', 'service', 'service_ticket', 'service_ticket_created', 'SERVICE_TICKET_CREATED', 1, 0, 1, 0
    UNION ALL SELECT 'RULE_LEAVE_REQUEST_SUBMITTED', 'Leave request submitted notification', 'hr', 'leave_request', 'leave_request_submitted', 'LEAVE_REQUEST_SUBMITTED', 0, 0, 0, 1
    UNION ALL SELECT 'RULE_LEAVE_REQUEST_APPROVED', 'Leave request approved notification', 'hr', 'leave_request', 'leave_request_approved', 'LEAVE_REQUEST_APPROVED', 0, 0, 0, 1
    UNION ALL SELECT 'RULE_PAYSLIP_GENERATED', 'Payslip generated notification', 'hr', 'payslip', 'payslip_generated', 'PAYSLIP_GENERATED', 0, 0, 0, 1
) AS seed
INNER JOIN email_templates et ON et.template_code = seed.template_code AND et.company_id IS NULL;


-- =========================================================
-- 7. POSTING RULE GROUPS
-- Groups of accounting rules by document type
-- =========================================================
DROP TABLE IF EXISTS posting_rules;
DROP TABLE IF EXISTS posting_rule_groups;

CREATE TABLE posting_rule_groups (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    group_code VARCHAR(50) NOT NULL,
    group_name VARCHAR(150) NOT NULL,

    document_type VARCHAR(50) NOT NULL,

    trigger_event ENUM(
        'on_save',
        'on_approve',
        'on_post',
        'on_cancel',
        'on_reverse'
    ) NOT NULL DEFAULT 'on_post',

    description TEXT NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_posting_rule_groups_code (group_code),

    INDEX idx_posting_rule_groups_doc_type (document_type),
    INDEX idx_posting_rule_groups_trigger (trigger_event),
    INDEX idx_posting_rule_groups_active (is_active),

    CONSTRAINT fk_posting_rule_groups_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_posting_rule_groups_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 7. POSTING RULES
-- Defines debit / credit logic for each document type
-- =========================================================
CREATE TABLE posting_rules (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    posting_rule_group_id BIGINT UNSIGNED NOT NULL,

    line_no INT NOT NULL,

    entry_side ENUM('debit', 'credit') NOT NULL,

    account_source_type ENUM(
        'fixed_account',
        'customer_control_account',
        'supplier_control_account',
        'item_sales_account',
        'item_purchase_account',
        'tax_output_cgst_account',
        'tax_output_sgst_account',
        'tax_output_igst_account',
        'tax_input_cgst_account',
        'tax_input_sgst_account',
        'tax_input_igst_account',
        'cash_bank_account',
        'round_off_account',
        'discount_account',
        'returns_account',
        'stock_account',
        'cogs_account'
    ) NOT NULL,

    fixed_account_id BIGINT UNSIGNED NULL,

    amount_source ENUM(
        'subtotal',
        'discount_amount',
        'taxable_amount',
        'cgst_amount',
        'sgst_amount',
        'igst_amount',
        'cess_amount',
        'round_off_amount',
        'total_amount',
        'paid_amount',
        'balance_amount',
        'stock_value',
        'cogs_value'
    ) NOT NULL,

    narration_template VARCHAR(500) NULL,

    priority_order INT NOT NULL DEFAULT 1,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_posting_rules_group_line (posting_rule_group_id, line_no),

    INDEX idx_posting_rules_group (posting_rule_group_id),
    INDEX idx_posting_rules_side (entry_side),
    INDEX idx_posting_rules_priority (priority_order),

    CONSTRAINT fk_posting_rules_group FOREIGN KEY (posting_rule_group_id) REFERENCES posting_rule_groups(id) ON DELETE CASCADE,
    CONSTRAINT fk_posting_rules_fixed_account FOREIGN KEY (fixed_account_id) REFERENCES accounts(id),
    CONSTRAINT fk_posting_rules_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_posting_rules_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 8. DOCUMENT POSTINGS
-- Stores which voucher got created for which document
-- =========================================================
DROP TABLE IF EXISTS document_posting_lines;
DROP TABLE IF EXISTS document_postings;

CREATE TABLE document_postings (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_module VARCHAR(50) NOT NULL,
    document_table VARCHAR(100) NOT NULL,
    document_id BIGINT UNSIGNED NOT NULL,
    document_no VARCHAR(100) NULL,
    document_date DATE NOT NULL,

    posting_rule_group_id BIGINT UNSIGNED NULL,
    voucher_id BIGINT UNSIGNED NULL,

    posting_status ENUM(
        'pending',
        'posted',
        'reversed',
        'failed',
        'cancelled'
    ) NOT NULL DEFAULT 'pending',

    posted_at DATETIME NULL,
    reversed_at DATETIME NULL,

    error_message TEXT NULL,
    remarks TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    UNIQUE KEY uq_document_postings_doc (document_module, document_table, document_id),

    INDEX idx_document_postings_doc_date (document_date),
    INDEX idx_document_postings_status (posting_status),
    INDEX idx_document_postings_voucher (voucher_id),

    CONSTRAINT fk_document_postings_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_document_postings_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_document_postings_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_document_postings_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_document_postings_posting_rule_group FOREIGN KEY (posting_rule_group_id) REFERENCES posting_rule_groups(id),
    CONSTRAINT fk_document_postings_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id),
    CONSTRAINT fk_document_postings_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_document_postings_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 9. DOCUMENT POSTING LINES
-- Snapshot of generated posting lines for audit
-- =========================================================
CREATE TABLE document_posting_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    document_posting_id BIGINT UNSIGNED NOT NULL,

    line_no INT NOT NULL,

    account_id BIGINT UNSIGNED NOT NULL,

    entry_side ENUM('debit', 'credit') NOT NULL,
    amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    narration VARCHAR(500) NULL,

    source_amount_field VARCHAR(100) NULL,
    source_rule_id BIGINT UNSIGNED NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_document_posting_lines_doc_line (document_posting_id, line_no),

    INDEX idx_document_posting_lines_account (account_id),
    INDEX idx_document_posting_lines_rule (source_rule_id),

    CONSTRAINT fk_document_posting_lines_doc FOREIGN KEY (document_posting_id) REFERENCES document_postings(id) ON DELETE CASCADE,
    CONSTRAINT fk_document_posting_lines_account FOREIGN KEY (account_id) REFERENCES accounts(id),
    CONSTRAINT fk_document_posting_lines_rule FOREIGN KEY (source_rule_id) REFERENCES posting_rules(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- SEED DATA : STATES (INDIA)
-- Minimal useful set, extend later if needed
-- =========================================================
INSERT INTO states (country_code, state_code, state_name, gst_state_code, is_union_territory, is_active)
VALUES
-- STATES
('IN', 'JK', 'Jammu and Kashmir', '01', 0, 1),
('IN', 'HP', 'Himachal Pradesh', '02', 0, 1),
('IN', 'PB', 'Punjab', '03', 0, 1),
('IN', 'UT-CH', 'Chandigarh', '04', 1, 1),
('IN', 'UK', 'Uttarakhand', '05', 0, 1),
('IN', 'HR', 'Haryana', '06', 0, 1),
('IN', 'DL', 'Delhi', '07', 1, 1),
('IN', 'RJ', 'Rajasthan', '08', 0, 1),
('IN', 'UP', 'Uttar Pradesh', '09', 0, 1),
('IN', 'BR', 'Bihar', '10', 0, 1),
('IN', 'SK', 'Sikkim', '11', 0, 1),
('IN', 'AR', 'Arunachal Pradesh', '12', 0, 1),
('IN', 'NL', 'Nagaland', '13', 0, 1),
('IN', 'MN', 'Manipur', '14', 0, 1),
('IN', 'MZ', 'Mizoram', '15', 0, 1),
('IN', 'TR', 'Tripura', '16', 0, 1),
('IN', 'ML', 'Meghalaya', '17', 0, 1),
('IN', 'AS', 'Assam', '18', 0, 1),
('IN', 'WB', 'West Bengal', '19', 0, 1),
('IN', 'JH', 'Jharkhand', '20', 0, 1),
('IN', 'OD', 'Odisha', '21', 0, 1),
('IN', 'CT', 'Chhattisgarh', '22', 0, 1),
('IN', 'MP', 'Madhya Pradesh', '23', 0, 1),
('IN', 'GJ', 'Gujarat', '24', 0, 1),
('IN', 'DH', 'Dadra and Nagar Haveli and Daman and Diu', '26', 1, 1),
('IN', 'MH', 'Maharashtra', '27', 0, 1),
('IN', 'KA', 'Karnataka', '29', 0, 1),
('IN', 'GA', 'Goa', '30', 0, 1),
('IN', 'LD', 'Lakshadweep', '31', 1, 1),
('IN', 'KL', 'Kerala', '32', 0, 1),
('IN', 'TN', 'Tamil Nadu', '33', 0, 1),
('IN', 'PY', 'Puducherry', '34', 1, 1),
('IN', 'AN', 'Andaman and Nicobar Islands', '35', 1, 1),
('IN', 'TS', 'Telangana', '36', 0, 1),
('IN', 'AP', 'Andhra Pradesh', '37', 0, 1),
('IN', 'LA', 'Ladakh', '38', 1, 1),
('IN', 'FC', 'Foreign Country', '96', 1, 1),
('IN', 'OT', 'Other Territory', '97', 1, 1)
ON DUPLICATE KEY UPDATE
    state_name = VALUES(state_name),
    gst_state_code = VALUES(gst_state_code),
    is_union_territory = VALUES(is_union_territory),
    is_active = VALUES(is_active),
    updated_at = CURRENT_TIMESTAMP;

-- OPTIONAL / SPECIAL PURPOSE GST CODE
-- use only if you explicitly support this in ERP for special registrations
INSERT INTO states (country_code, state_code, state_name, gst_state_code, is_union_territory, is_active)
VALUES
('IN', 'NR', 'Centre Jurisdiction / Non-Resident Taxable Person', '99', 1, 1)
ON DUPLICATE KEY UPDATE
    state_name = VALUES(state_name),
    gst_state_code = VALUES(gst_state_code),
    is_union_territory = VALUES(is_union_territory),
    is_active = VALUES(is_active),
    updated_at = CURRENT_TIMESTAMP;


-- =========================================================
-- SEED DATA : GST TAX RULES
-- Linked by tax_code instead of assuming auto-increment ids
-- =========================================================
INSERT INTO gst_tax_rules (
    rule_code, rule_name, transaction_type, item_type,
    tax_code_id, place_of_supply_result, tax_application,
    reverse_charge_applicable, input_tax_credit_allowed,
    priority_order, is_active
)
SELECT
    seed.rule_code,
    seed.rule_name,
    seed.transaction_type,
    seed.item_type,
    tc.id,
    seed.place_of_supply_result,
    seed.tax_application,
    seed.reverse_charge_applicable,
    seed.input_tax_credit_allowed,
    seed.priority_order,
    seed.is_active
FROM (
    SELECT 'SALE_STOCK_INTRASTATE_GST18' AS rule_code, 'Sales Stock Intra GST18' AS rule_name, 'sales' AS transaction_type, 'stock' AS item_type, 'GST18' AS tax_code, 'intra_state' AS place_of_supply_result, 'cgst_sgst' AS tax_application, 0 AS reverse_charge_applicable, 0 AS input_tax_credit_allowed, 1 AS priority_order, 1 AS is_active
    UNION ALL SELECT 'SALE_STOCK_INTERSTATE_GST18', 'Sales Stock Inter GST18', 'sales', 'stock', 'GST18', 'inter_state', 'igst', 0, 0, 2, 1
    UNION ALL SELECT 'SALE_RETURN_STOCK_INTRASTATE_GST18', 'Sales Return Stock Intra GST18', 'sales_return', 'stock', 'GST18', 'intra_state', 'cgst_sgst', 0, 0, 1, 1
    UNION ALL SELECT 'SALE_RETURN_STOCK_INTERSTATE_GST18', 'Sales Return Stock Inter GST18', 'sales_return', 'stock', 'GST18', 'inter_state', 'igst', 0, 0, 2, 1
    UNION ALL SELECT 'PUR_STOCK_INTRASTATE_GST18', 'Purchase Stock Intra GST18', 'purchase', 'stock', 'GST18', 'intra_state', 'cgst_sgst', 0, 1, 1, 1
    UNION ALL SELECT 'PUR_STOCK_INTERSTATE_GST18', 'Purchase Stock Inter GST18', 'purchase', 'stock', 'GST18', 'inter_state', 'igst', 0, 1, 2, 1
    UNION ALL SELECT 'PUR_RETURN_STOCK_INTRASTATE_GST18', 'Purchase Return Stock Intra GST18', 'purchase_return', 'stock', 'GST18', 'intra_state', 'cgst_sgst', 0, 1, 1, 1
    UNION ALL SELECT 'PUR_RETURN_STOCK_INTERSTATE_GST18', 'Purchase Return Stock Inter GST18', 'purchase_return', 'stock', 'GST18', 'inter_state', 'igst', 0, 1, 2, 1
    UNION ALL SELECT 'SALE_SERVICE_INTRASTATE_GST18', 'Sales Service Intra GST18', 'service_sales', 'service', 'GST18', 'intra_state', 'cgst_sgst', 0, 0, 1, 1
    UNION ALL SELECT 'SALE_SERVICE_INTERSTATE_GST18', 'Sales Service Inter GST18', 'service_sales', 'service', 'GST18', 'inter_state', 'igst', 0, 0, 2, 1
    UNION ALL SELECT 'PUR_SERVICE_INTRASTATE_GST18', 'Purchase Service Intra GST18', 'service_purchase', 'service', 'GST18', 'intra_state', 'cgst_sgst', 0, 1, 1, 1
    UNION ALL SELECT 'PUR_SERVICE_INTERSTATE_GST18', 'Purchase Service Inter GST18', 'service_purchase', 'service', 'GST18', 'inter_state', 'igst', 0, 1, 2, 1
) AS seed
INNER JOIN tax_codes tc ON tc.tax_code = seed.tax_code
ON DUPLICATE KEY UPDATE
    rule_name = VALUES(rule_name),
    transaction_type = VALUES(transaction_type),
    item_type = VALUES(item_type),
    tax_code_id = VALUES(tax_code_id),
    place_of_supply_result = VALUES(place_of_supply_result),
    tax_application = VALUES(tax_application),
    reverse_charge_applicable = VALUES(reverse_charge_applicable),
    input_tax_credit_allowed = VALUES(input_tax_credit_allowed),
    priority_order = VALUES(priority_order),
    is_active = VALUES(is_active),
    updated_at = CURRENT_TIMESTAMP;


-- =========================================================
-- SEED DATA : POSTING RULE GROUPS
-- =========================================================
INSERT INTO posting_rule_groups (
    group_code, group_name, document_type, trigger_event, description, is_active
) VALUES
('SALES_INVOICE_POST', 'Sales Invoice Posting', 'SALES_INVOICE', 'on_post', 'Posting rules for sales invoice', 1),
('SALES_RECEIPT_POST', 'Sales Receipt Posting', 'SALES_RECEIPT', 'on_post', 'Posting rules for sales receipt', 1),
('SALES_RETURN_POST', 'Sales Return Posting', 'SALES_RETURN', 'on_post', 'Posting rules for sales return', 1),
('PURCHASE_INVOICE_POST', 'Purchase Invoice Posting', 'PURCHASE_INVOICE', 'on_post', 'Posting rules for purchase invoice', 1),
('PURCHASE_PAYMENT_POST', 'Purchase Payment Posting', 'PURCHASE_PAYMENT', 'on_post', 'Posting rules for purchase payment', 1),
('PURCHASE_RETURN_POST', 'Purchase Return Posting', 'PURCHASE_RETURN', 'on_post', 'Posting rules for purchase return', 1)
ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;


-- =========================================================
-- SEED DATA : POSTING RULES
-- IMPORTANT:
-- Replace fixed_account_id later with your actual chart of accounts ids
-- Keep NULL now if account is dynamic
-- =========================================================

-- SALES INVOICE
INSERT INTO posting_rules (
    posting_rule_group_id, line_no, entry_side, account_source_type,
    fixed_account_id, amount_source, narration_template,
    priority_order, is_active
) VALUES
(1, 1, 'debit',  'customer_control_account', NULL, 'total_amount', 'Sales Invoice Customer Debit', 1, 1),
(1, 2, 'credit', 'item_sales_account',       NULL, 'taxable_amount', 'Sales Revenue Credit', 2, 1),
(1, 3, 'credit', 'tax_output_cgst_account',  NULL, 'cgst_amount', 'Output CGST Credit', 3, 1),
(1, 4, 'credit', 'tax_output_sgst_account',  NULL, 'sgst_amount', 'Output SGST Credit', 4, 1),
(1, 5, 'credit', 'tax_output_igst_account',  NULL, 'igst_amount', 'Output IGST Credit', 5, 1),
(2, 1, 'debit',  'cash_bank_account',        NULL, 'paid_amount', 'Cash/Bank Debit', 1, 1), -- SALES RECEIPT
(2, 2, 'credit', 'customer_control_account', NULL, 'paid_amount', 'Customer Credit', 2, 1),
(3, 1, 'debit',  'returns_account',          NULL, 'taxable_amount', 'Sales Return Debit', 1, 1), -- SALES RETURN
(3, 2, 'debit',  'tax_output_cgst_account',  NULL, 'cgst_amount', 'Output CGST Reversal', 2, 1),
(3, 3, 'debit',  'tax_output_sgst_account',  NULL, 'sgst_amount', 'Output SGST Reversal', 3, 1),
(3, 4, 'debit',  'tax_output_igst_account',  NULL, 'igst_amount', 'Output IGST Reversal', 4, 1),
(3, 5, 'credit', 'customer_control_account', NULL, 'total_amount', 'Customer Credit Reduction', 5, 1),
(4, 1, 'debit',  'item_purchase_account',    NULL, 'taxable_amount', 'Purchase Debit', 1, 1), -- PURCHASE INVOICE
(4, 2, 'debit',  'tax_input_cgst_account',   NULL, 'cgst_amount', 'Input CGST Debit', 2, 1),
(4, 3, 'debit',  'tax_input_sgst_account',   NULL, 'sgst_amount', 'Input SGST Debit', 3, 1),
(4, 4, 'debit',  'tax_input_igst_account',   NULL, 'igst_amount', 'Input IGST Debit', 4, 1),
(4, 5, 'credit', 'supplier_control_account', NULL, 'total_amount', 'Supplier Credit', 5, 1),
(5, 1, 'debit',  'supplier_control_account', NULL, 'paid_amount', 'Supplier Debit', 1, 1), -- PURCHASE PAYMENT
(5, 2, 'credit', 'cash_bank_account',        NULL, 'paid_amount', 'Cash/Bank Credit', 2, 1),
(6, 1, 'debit',  'supplier_control_account', NULL, 'total_amount', 'Supplier Debit Reduction', 1, 1), -- PURCHASE RETURN
(6, 2, 'credit', 'returns_account',          NULL, 'taxable_amount', 'Purchase Return Credit', 2, 1),
(6, 3, 'credit', 'tax_input_cgst_account',   NULL, 'cgst_amount', 'Input CGST Reversal', 3, 1),
(6, 4, 'credit', 'tax_input_sgst_account',   NULL, 'sgst_amount', 'Input SGST Reversal', 4, 1),
(6, 5, 'credit', 'tax_input_igst_account',   NULL, 'igst_amount', 'Input IGST Reversal', 5, 1);

SET FOREIGN_KEY_CHECKS = 1;
-- =========================================================
-- MODULE 8 : STOCK OPERATIONS + INVENTORY TRANSACTION ENGINE
-- ERP FOUNDATION - MySQL 8
-- Depends on MODULE 1A + 1B + 2 + 3 + 4 + 5 + 6 + 7
-- =========================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- 1. STOCK OPENINGS
-- Initial stock opening for financial year / system go-live
-- =========================================================
DROP TABLE IF EXISTS stock_opening_lines;
DROP TABLE IF EXISTS stock_openings;

CREATE TABLE stock_openings (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,
    voucher_id BIGINT UNSIGNED NULL,

    opening_no VARCHAR(100) NOT NULL,
    opening_date DATE NOT NULL,

    opening_status ENUM(
        'draft',
        'posted',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    remarks TEXT NULL,

    posted_by BIGINT UNSIGNED NULL,
    posted_at DATETIME NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_stock_openings_company_no (company_id, opening_no),

    INDEX idx_stock_openings_date (opening_date),
    INDEX idx_stock_openings_status (opening_status),

    CONSTRAINT fk_stock_openings_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_stock_openings_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_stock_openings_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_stock_openings_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_stock_openings_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_stock_openings_posted_by FOREIGN KEY (posted_by) REFERENCES users(id),
    CONSTRAINT fk_stock_openings_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_stock_openings_updated_by FOREIGN KEY (updated_by) REFERENCES users(id),
    CONSTRAINT fk_stock_openings_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE stock_opening_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    stock_opening_id BIGINT UNSIGNED NOT NULL,
    line_no INT NOT NULL,

    warehouse_id BIGINT UNSIGNED NOT NULL,
    item_id BIGINT UNSIGNED NOT NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    batch_id BIGINT UNSIGNED NULL,
    serial_id BIGINT UNSIGNED NULL,
    voucher_id BIGINT UNSIGNED NULL,

    qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    unit_cost DECIMAL(18,4) NOT NULL DEFAULT 0,
    total_cost DECIMAL(18,2) NOT NULL DEFAULT 0,

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_stock_opening_lines_doc_line (stock_opening_id, line_no),

    INDEX idx_stock_opening_lines_item (item_id),
    INDEX idx_stock_opening_lines_warehouse (warehouse_id),

    CONSTRAINT fk_stock_opening_lines_doc FOREIGN KEY (stock_opening_id) REFERENCES stock_openings(id) ON DELETE CASCADE,
    CONSTRAINT fk_stock_opening_lines_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_stock_opening_lines_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_stock_opening_lines_uom FOREIGN KEY (uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_stock_opening_lines_batch FOREIGN KEY (batch_id) REFERENCES stock_batches(id),
    CONSTRAINT fk_stock_opening_lines_serial FOREIGN KEY (serial_id) REFERENCES stock_serials(id),
    CONSTRAINT fk_stock_adjustments_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 2. STOCK ADJUSTMENTS
-- Manual stock correction (excess / shortage)
-- =========================================================
DROP TABLE IF EXISTS stock_adjustment_lines;
DROP TABLE IF EXISTS stock_adjustments;

CREATE TABLE stock_adjustments (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,

    adjustment_no VARCHAR(100) NOT NULL,
    adjustment_date DATE NOT NULL,

    adjustment_type ENUM(
        'increase',
        'decrease',
        'mixed'
    ) NOT NULL DEFAULT 'mixed',

    reason_code ENUM(
        'manual_correction',
        'system_correction',
        'count_difference',
        'warehouse_error',
        'data_migration',
        'other'
    ) NOT NULL DEFAULT 'manual_correction',

    adjustment_status ENUM(
        'draft',
        'posted',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    remarks TEXT NULL,

    posted_by BIGINT UNSIGNED NULL,
    posted_at DATETIME NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_stock_adjustments_company_no (company_id, adjustment_no),

    INDEX idx_stock_adjustments_date (adjustment_date),
    INDEX idx_stock_adjustments_status (adjustment_status),

    CONSTRAINT fk_stock_adjustments_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_stock_adjustments_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_stock_adjustments_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_stock_adjustments_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_stock_adjustments_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_stock_adjustments_posted_by FOREIGN KEY (posted_by) REFERENCES users(id),
    CONSTRAINT fk_stock_adjustments_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_stock_adjustments_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE stock_adjustment_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    stock_adjustment_id BIGINT UNSIGNED NOT NULL,
    line_no INT NOT NULL,

    warehouse_id BIGINT UNSIGNED NOT NULL,
    item_id BIGINT UNSIGNED NOT NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    batch_id BIGINT UNSIGNED NULL,
    serial_id BIGINT UNSIGNED NULL,

    system_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    actual_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    adjustment_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    unit_cost DECIMAL(18,4) NOT NULL DEFAULT 0,
    total_cost DECIMAL(18,2) NOT NULL DEFAULT 0,

    adjustment_direction ENUM('in', 'out') NOT NULL DEFAULT 'in',

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_stock_adjustment_lines_doc_line (stock_adjustment_id, line_no),

    INDEX idx_stock_adjustment_lines_item (item_id),
    INDEX idx_stock_adjustment_lines_warehouse (warehouse_id),

    CONSTRAINT fk_stock_adjustment_lines_doc FOREIGN KEY (stock_adjustment_id) REFERENCES stock_adjustments(id) ON DELETE CASCADE,
    CONSTRAINT fk_stock_adjustment_lines_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_stock_adjustment_lines_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_stock_adjustment_lines_uom FOREIGN KEY (uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_stock_adjustment_lines_batch FOREIGN KEY (batch_id) REFERENCES stock_batches(id),
    CONSTRAINT fk_stock_adjustment_lines_serial FOREIGN KEY (serial_id) REFERENCES stock_serials(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 3. STOCK TRANSFERS
-- Warehouse to warehouse / location movement
-- =========================================================
DROP TABLE IF EXISTS stock_transfer_lines;
DROP TABLE IF EXISTS stock_transfers;

CREATE TABLE stock_transfers (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,

    transfer_no VARCHAR(100) NOT NULL,
    transfer_date DATE NOT NULL,

    from_warehouse_id BIGINT UNSIGNED NOT NULL,
    to_warehouse_id BIGINT UNSIGNED NOT NULL,
    voucher_id BIGINT UNSIGNED NULL,

    transfer_status ENUM(
        'draft',
        'posted',
        'received',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    remarks TEXT NULL,

    posted_by BIGINT UNSIGNED NULL,
    posted_at DATETIME NULL,

    received_by BIGINT UNSIGNED NULL,
    received_at DATETIME NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_stock_transfers_company_no (company_id, transfer_no),

    INDEX idx_stock_transfers_date (transfer_date),
    INDEX idx_stock_transfers_status (transfer_status),

    CONSTRAINT fk_stock_transfers_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_stock_transfers_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_stock_transfers_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_stock_transfers_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_stock_transfers_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_stock_transfers_from_warehouse FOREIGN KEY (from_warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_stock_transfers_to_warehouse FOREIGN KEY (to_warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_stock_transfers_posted_by FOREIGN KEY (posted_by) REFERENCES users(id),
    CONSTRAINT fk_stock_transfers_received_by FOREIGN KEY (received_by) REFERENCES users(id),
    CONSTRAINT fk_stock_transfers_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_stock_transfers_updated_by FOREIGN KEY (updated_by) REFERENCES users(id),
    CONSTRAINT fk_stock_transfers_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE stock_transfer_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    stock_transfer_id BIGINT UNSIGNED NOT NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    from_batch_id BIGINT UNSIGNED NULL,
    to_batch_id BIGINT UNSIGNED NULL,

    from_serial_id BIGINT UNSIGNED NULL,
    to_serial_id BIGINT UNSIGNED NULL,

    transfer_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    unit_cost DECIMAL(18,4) NOT NULL DEFAULT 0,
    total_cost DECIMAL(18,2) NOT NULL DEFAULT 0,

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_stock_transfer_lines_doc_line (stock_transfer_id, line_no),

    INDEX idx_stock_transfer_lines_item (item_id),

    CONSTRAINT fk_stock_transfer_lines_doc FOREIGN KEY (stock_transfer_id) REFERENCES stock_transfers(id) ON DELETE CASCADE,
    CONSTRAINT fk_stock_transfer_lines_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_stock_transfer_lines_uom FOREIGN KEY (uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_stock_transfer_lines_from_batch FOREIGN KEY (from_batch_id) REFERENCES stock_batches(id),
    CONSTRAINT fk_stock_transfer_lines_to_batch FOREIGN KEY (to_batch_id) REFERENCES stock_batches(id),
    CONSTRAINT fk_stock_transfer_lines_from_serial FOREIGN KEY (from_serial_id) REFERENCES stock_serials(id),
    CONSTRAINT fk_stock_transfer_lines_to_serial FOREIGN KEY (to_serial_id) REFERENCES stock_serials(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 4. STOCK ISSUES
-- Internal issue: production, department usage, sample, maintenance
-- =========================================================
DROP TABLE IF EXISTS stock_issue_lines;
DROP TABLE IF EXISTS stock_issues;

CREATE TABLE stock_issues (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,

    issue_no VARCHAR(100) NOT NULL,
    issue_date DATE NOT NULL,

    warehouse_id BIGINT UNSIGNED NOT NULL,
    voucher_id BIGINT UNSIGNED NULL,

    issue_purpose ENUM(
        'department_use',
        'production',
        'sample',
        'maintenance',
        'jobwork',
        'other'
    ) NOT NULL DEFAULT 'department_use',

    department_name VARCHAR(100) NULL,
    issued_to VARCHAR(255) NULL,

    issue_status ENUM(
        'draft',
        'posted',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    remarks TEXT NULL,

    posted_by BIGINT UNSIGNED NULL,
    posted_at DATETIME NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_stock_issues_company_no (company_id, issue_no),

    INDEX idx_stock_issues_date (issue_date),
    INDEX idx_stock_issues_status (issue_status),

    CONSTRAINT fk_stock_issues_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_stock_issues_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_stock_issues_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_stock_issues_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_stock_issues_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_stock_issues_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_stock_issues_posted_by FOREIGN KEY (posted_by) REFERENCES users(id),
    CONSTRAINT fk_stock_issues_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_stock_issues_updated_by FOREIGN KEY (updated_by) REFERENCES users(id),
    CONSTRAINT fk_stock_issues_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE stock_issue_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    stock_issue_id BIGINT UNSIGNED NOT NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    batch_id BIGINT UNSIGNED NULL,
    serial_id BIGINT UNSIGNED NULL,

    issue_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    unit_cost DECIMAL(18,4) NOT NULL DEFAULT 0,
    total_cost DECIMAL(18,2) NOT NULL DEFAULT 0,

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_stock_issue_lines_doc_line (stock_issue_id, line_no),

    INDEX idx_stock_issue_lines_item (item_id),

    CONSTRAINT fk_stock_issue_lines_doc FOREIGN KEY (stock_issue_id) REFERENCES stock_issues(id) ON DELETE CASCADE,
    CONSTRAINT fk_stock_issue_lines_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_stock_issue_lines_uom FOREIGN KEY (uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_stock_issue_lines_batch FOREIGN KEY (batch_id) REFERENCES stock_batches(id),
    CONSTRAINT fk_stock_issue_lines_serial FOREIGN KEY (serial_id) REFERENCES stock_serials(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 5. INTERNAL STOCK RECEIPTS
-- Non-purchase inward: sample return, department return, internal return
-- =========================================================
DROP TABLE IF EXISTS stock_receipt_internal_lines;
DROP TABLE IF EXISTS stock_receipts_internal;

CREATE TABLE stock_receipts_internal (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,

    receipt_no VARCHAR(100) NOT NULL,
    receipt_date DATE NOT NULL,

    warehouse_id BIGINT UNSIGNED NOT NULL,
    voucher_id BIGINT UNSIGNED NULL,

    receipt_source ENUM(
        'department_return',
        'sample_return',
        'jobwork_return',
        'production_return',
        'other'
    ) NOT NULL DEFAULT 'department_return',

    received_from VARCHAR(255) NULL,

    receipt_status ENUM(
        'draft',
        'posted',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    remarks TEXT NULL,

    posted_by BIGINT UNSIGNED NULL,
    posted_at DATETIME NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_stock_receipts_internal_company_no (company_id, receipt_no),

    INDEX idx_stock_receipts_internal_date (receipt_date),
    INDEX idx_stock_receipts_internal_status (receipt_status),

    CONSTRAINT fk_stock_receipts_internal_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_stock_receipts_internal_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_stock_receipts_internal_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_stock_receipts_internal_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_stock_receipts_internal_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_stock_receipts_internal_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_stock_receipts_internal_posted_by FOREIGN KEY (posted_by) REFERENCES users(id),
    CONSTRAINT fk_stock_receipts_internal_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_stock_receipts_internal_updated_by FOREIGN KEY (updated_by) REFERENCES users(id),
    CONSTRAINT fk_stock_receipts_internal_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE stock_receipt_internal_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    stock_receipt_internal_id BIGINT UNSIGNED NOT NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    batch_id BIGINT UNSIGNED NULL,
    serial_id BIGINT UNSIGNED NULL,

    receipt_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    unit_cost DECIMAL(18,4) NOT NULL DEFAULT 0,
    total_cost DECIMAL(18,2) NOT NULL DEFAULT 0,

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_stock_receipt_internal_lines_doc_line (stock_receipt_internal_id, line_no),

    INDEX idx_stock_receipt_internal_lines_item (item_id),

    CONSTRAINT fk_stock_receipt_internal_lines_doc FOREIGN KEY (stock_receipt_internal_id) REFERENCES stock_receipts_internal(id) ON DELETE CASCADE,
    CONSTRAINT fk_stock_receipt_internal_lines_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_stock_receipt_internal_lines_uom FOREIGN KEY (uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_stock_receipt_internal_lines_batch FOREIGN KEY (batch_id) REFERENCES stock_batches(id),
    CONSTRAINT fk_stock_receipt_internal_lines_serial FOREIGN KEY (serial_id) REFERENCES stock_serials(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 6. STOCK DAMAGE / EXPIRY ENTRIES
-- =========================================================
DROP TABLE IF EXISTS stock_damage_lines;
DROP TABLE IF EXISTS stock_damage_entries;

CREATE TABLE stock_damage_entries (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,

    damage_no VARCHAR(100) NOT NULL,
    damage_date DATE NOT NULL,

    warehouse_id BIGINT UNSIGNED NOT NULL,
    voucher_id BIGINT UNSIGNED NULL,

    damage_type ENUM(
        'damage',
        'expiry',
        'breakage',
        'spoilage',
        'loss',
        'other'
    ) NOT NULL DEFAULT 'damage',

    damage_status ENUM(
        'draft',
        'posted',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    remarks TEXT NULL,

    posted_by BIGINT UNSIGNED NULL,
    posted_at DATETIME NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_stock_damage_entries_company_no (company_id, damage_no),

    INDEX idx_stock_damage_entries_date (damage_date),
    INDEX idx_stock_damage_entries_status (damage_status),

    CONSTRAINT fk_stock_damage_entries_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_stock_damage_entries_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_stock_damage_entries_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_stock_damage_entries_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_stock_damage_entries_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_stock_damage_entries_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_stock_damage_entries_posted_by FOREIGN KEY (posted_by) REFERENCES users(id),
    CONSTRAINT fk_stock_damage_entries_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_stock_damage_entries_updated_by FOREIGN KEY (updated_by) REFERENCES users(id),
    CONSTRAINT fk_stock_damage_entries_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE stock_damage_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    stock_damage_entry_id BIGINT UNSIGNED NOT NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    batch_id BIGINT UNSIGNED NULL,
    serial_id BIGINT UNSIGNED NULL,

    damage_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    unit_cost DECIMAL(18,4) NOT NULL DEFAULT 0,
    total_cost DECIMAL(18,2) NOT NULL DEFAULT 0,

    reason VARCHAR(255) NULL,
    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_stock_damage_lines_doc_line (stock_damage_entry_id, line_no),

    INDEX idx_stock_damage_lines_item (item_id),

    CONSTRAINT fk_stock_damage_lines_doc FOREIGN KEY (stock_damage_entry_id) REFERENCES stock_damage_entries(id) ON DELETE CASCADE,
    CONSTRAINT fk_stock_damage_lines_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_stock_damage_lines_uom FOREIGN KEY (uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_stock_damage_lines_batch FOREIGN KEY (batch_id) REFERENCES stock_batches(id),
    CONSTRAINT fk_stock_damage_lines_serial FOREIGN KEY (serial_id) REFERENCES stock_serials(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 7. PHYSICAL STOCK COUNTS
-- Physical verification / cycle count / full stock take
-- =========================================================
DROP TABLE IF EXISTS stock_physical_count_lines;
DROP TABLE IF EXISTS stock_physical_counts;

CREATE TABLE stock_physical_counts (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,

    count_no VARCHAR(100) NOT NULL,
    count_date DATE NOT NULL,

    warehouse_id BIGINT UNSIGNED NOT NULL,
    voucher_id BIGINT UNSIGNED NULL,

    count_scope ENUM(
        'full_warehouse',
        'selected_items',
        'category',
        'batch',
        'serial'
    ) NOT NULL DEFAULT 'selected_items',

    count_status ENUM(
        'draft',
        'counted',
        'reconciled',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    counted_by BIGINT UNSIGNED NULL,
    counted_at DATETIME NULL,

    reconciled_by BIGINT UNSIGNED NULL,
    reconciled_at DATETIME NULL,

    remarks TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_stock_physical_counts_company_no (company_id, count_no),

    INDEX idx_stock_physical_counts_date (count_date),
    INDEX idx_stock_physical_counts_status (count_status),

    CONSTRAINT fk_stock_physical_counts_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_stock_physical_counts_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_stock_physical_counts_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_stock_physical_counts_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_stock_physical_counts_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_stock_physical_counts_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_stock_physical_counts_counted_by FOREIGN KEY (counted_by) REFERENCES users(id),
    CONSTRAINT fk_stock_physical_counts_reconciled_by FOREIGN KEY (reconciled_by) REFERENCES users(id),
    CONSTRAINT fk_stock_physical_counts_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_stock_physical_counts_updated_by FOREIGN KEY (updated_by) REFERENCES users(id),
    CONSTRAINT fk_stock_physical_counts_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE stock_physical_count_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    stock_physical_count_id BIGINT UNSIGNED NOT NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    batch_id BIGINT UNSIGNED NULL,
    serial_id BIGINT UNSIGNED NULL,

    system_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    counted_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    variance_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    unit_cost DECIMAL(18,4) NOT NULL DEFAULT 0,
    variance_value DECIMAL(18,2) NOT NULL DEFAULT 0,

    variance_type ENUM(
        'excess',
        'shortage',
        'matched'
    ) NOT NULL DEFAULT 'matched',

    is_reconciled TINYINT(1) NOT NULL DEFAULT 0,

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_stock_physical_count_lines_doc_line (stock_physical_count_id, line_no),

    INDEX idx_stock_physical_count_lines_item (item_id),

    CONSTRAINT fk_stock_physical_count_lines_doc FOREIGN KEY (stock_physical_count_id) REFERENCES stock_physical_counts(id) ON DELETE CASCADE,
    CONSTRAINT fk_stock_physical_count_lines_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_stock_physical_count_lines_uom FOREIGN KEY (uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_stock_physical_count_lines_batch FOREIGN KEY (batch_id) REFERENCES stock_batches(id),
    CONSTRAINT fk_stock_physical_count_lines_serial FOREIGN KEY (serial_id) REFERENCES stock_serials(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


SET FOREIGN_KEY_CHECKS = 1;
-- =========================================================
-- MODULE 9 : MANUFACTURING / BOM / PRODUCTION ENGINE
-- ERP FOUNDATION - MySQL 8
-- Depends on MODULE 1A + 1B + 2 + 3 + 4 + 5 + 6 + 7 + 8
-- =========================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- 1. BOMS (BILL OF MATERIALS)
-- Defines what raw materials are needed to produce FG / SFG
-- =========================================================
DROP TABLE IF EXISTS bom_operations;
DROP TABLE IF EXISTS bom_lines;
DROP TABLE IF EXISTS boms;

CREATE TABLE boms (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,

    bom_code VARCHAR(100) NOT NULL,
    bom_name VARCHAR(255) NOT NULL,

    output_item_id BIGINT UNSIGNED NOT NULL,
    output_uom_id BIGINT UNSIGNED NOT NULL,

    version_no VARCHAR(50) NOT NULL DEFAULT '1.0',
    revision_no VARCHAR(50) NULL,

    batch_size DECIMAL(18,6) NOT NULL DEFAULT 1,
    standard_output_qty DECIMAL(18,6) NOT NULL DEFAULT 1,

    scrap_percent DECIMAL(8,4) NOT NULL DEFAULT 0,
    yield_percent DECIMAL(8,4) NOT NULL DEFAULT 100,

    bom_type ENUM(
        'production',
        'assembly',
        'packing',
        'repacking',
        'process',
        'jobwork'
    ) NOT NULL DEFAULT 'production',

    approval_status ENUM(
        'draft',
        'approved',
        'inactive',
        'obsolete'
    ) NOT NULL DEFAULT 'draft',

    effective_from DATE NULL,
    effective_to DATE NULL,

    notes TEXT NULL,

    approved_by BIGINT UNSIGNED NULL,
    approved_at DATETIME NULL,

    is_default TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_boms_company_code (company_id, bom_code),
    UNIQUE KEY uq_boms_item_version (company_id, output_item_id, version_no),

    INDEX idx_boms_output_item (output_item_id),
    INDEX idx_boms_status (approval_status),
    INDEX idx_boms_default (is_default),

    CONSTRAINT fk_boms_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_boms_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_boms_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_boms_output_item FOREIGN KEY (output_item_id) REFERENCES items(id),
    CONSTRAINT fk_boms_output_uom FOREIGN KEY (output_uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_boms_approved_by FOREIGN KEY (approved_by) REFERENCES users(id),
    CONSTRAINT fk_boms_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_boms_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE bom_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    bom_id BIGINT UNSIGNED NOT NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    line_type ENUM(
        'raw_material',
        'packing_material',
        'consumable',
        'semi_finished',
        'service',
        'by_product',
        'scrap'
    ) NOT NULL DEFAULT 'raw_material',

    required_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    wastage_percent DECIMAL(8,4) NOT NULL DEFAULT 0,
    net_required_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    issue_stage VARCHAR(100) NULL,

    is_backflush TINYINT(1) NOT NULL DEFAULT 1,
    is_optional TINYINT(1) NOT NULL DEFAULT 0,

    standard_rate DECIMAL(18,4) NOT NULL DEFAULT 0,
    standard_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_bom_lines_doc_line (bom_id, line_no),

    INDEX idx_bom_lines_item (item_id),
    INDEX idx_bom_lines_type (line_type),

    CONSTRAINT fk_bom_lines_doc FOREIGN KEY (bom_id) REFERENCES boms(id) ON DELETE CASCADE,
    CONSTRAINT fk_bom_lines_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_bom_lines_uom FOREIGN KEY (uom_id) REFERENCES uoms(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE bom_operations (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    bom_id BIGINT UNSIGNED NOT NULL,
    operation_no INT NOT NULL,

    operation_name VARCHAR(255) NOT NULL,
    work_center VARCHAR(100) NULL,

    setup_time_minutes DECIMAL(18,2) NOT NULL DEFAULT 0,
    run_time_minutes DECIMAL(18,2) NOT NULL DEFAULT 0,

    labor_cost DECIMAL(18,2) NOT NULL DEFAULT 0,
    machine_cost DECIMAL(18,2) NOT NULL DEFAULT 0,
    overhead_cost DECIMAL(18,2) NOT NULL DEFAULT 0,

    notes VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_bom_operations_doc_op (bom_id, operation_no),

    CONSTRAINT fk_bom_operations_doc FOREIGN KEY (bom_id) REFERENCES boms(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 2. PRODUCTION ORDERS
-- Main manufacturing order / work order
-- =========================================================
DROP TABLE IF EXISTS production_order_outputs;
DROP TABLE IF EXISTS production_order_operations;
DROP TABLE IF EXISTS production_order_materials;
DROP TABLE IF EXISTS production_orders;

CREATE TABLE production_orders (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,

    production_no VARCHAR(100) NOT NULL,
    production_date DATE NOT NULL,

    bom_id BIGINT UNSIGNED NOT NULL,

    output_item_id BIGINT UNSIGNED NOT NULL,
    output_uom_id BIGINT UNSIGNED NOT NULL,

    planned_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    started_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    completed_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    rejected_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    balance_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    source_type ENUM(
        'manual',
        'sales_order',
        'forecast',
        'reorder',
        'mrp'
    ) NOT NULL DEFAULT 'manual',

    source_document_type VARCHAR(50) NULL,
    source_document_id BIGINT UNSIGNED NULL,

    production_status ENUM(
        'draft',
        'released',
        'in_progress',
        'partially_completed',
        'completed',
        'closed',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    planned_start_date DATE NULL,
    planned_end_date DATE NULL,
    actual_start_date DATE NULL,
    actual_end_date DATE NULL,

    warehouse_id BIGINT UNSIGNED NOT NULL,
    wip_warehouse_id BIGINT UNSIGNED NULL,

    notes TEXT NULL,

    approved_by BIGINT UNSIGNED NULL,
    approved_at DATETIME NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_production_orders_company_no (company_id, production_no),

    INDEX idx_production_orders_date (production_date),
    INDEX idx_production_orders_status (production_status),
    INDEX idx_production_orders_output_item (output_item_id),

    CONSTRAINT fk_production_orders_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_production_orders_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_production_orders_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_production_orders_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_production_orders_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_production_orders_bom FOREIGN KEY (bom_id) REFERENCES boms(id),
    CONSTRAINT fk_production_orders_output_item FOREIGN KEY (output_item_id) REFERENCES items(id),
    CONSTRAINT fk_production_orders_output_uom FOREIGN KEY (output_uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_production_orders_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_production_orders_wip_warehouse FOREIGN KEY (wip_warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_production_orders_approved_by FOREIGN KEY (approved_by) REFERENCES users(id),
    CONSTRAINT fk_production_orders_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_production_orders_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE production_order_materials (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    production_order_id BIGINT UNSIGNED NOT NULL,
    bom_line_id BIGINT UNSIGNED NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    line_type ENUM(
        'raw_material',
        'packing_material',
        'consumable',
        'semi_finished',
        'service'
    ) NOT NULL DEFAULT 'raw_material',

    planned_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    issued_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    returned_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    consumed_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    balance_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    warehouse_id BIGINT UNSIGNED NULL,

    issue_method ENUM(
        'manual',
        'backflush'
    ) NOT NULL DEFAULT 'manual',

    standard_rate DECIMAL(18,4) NOT NULL DEFAULT 0,
    standard_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    actual_rate DECIMAL(18,4) NOT NULL DEFAULT 0,
    actual_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    line_status ENUM(
        'open',
        'partially_issued',
        'fully_issued',
        'consumed',
        'closed'
    ) NOT NULL DEFAULT 'open',

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_production_order_materials_doc_line (production_order_id, line_no),

    INDEX idx_production_order_materials_item (item_id),
    INDEX idx_production_order_materials_status (line_status),

    CONSTRAINT fk_production_order_materials_doc FOREIGN KEY (production_order_id) REFERENCES production_orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_production_order_materials_bom_line FOREIGN KEY (bom_line_id) REFERENCES bom_lines(id),
    CONSTRAINT fk_production_order_materials_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_production_order_materials_uom FOREIGN KEY (uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_production_order_materials_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE production_order_operations (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    production_order_id BIGINT UNSIGNED NOT NULL,
    bom_operation_id BIGINT UNSIGNED NULL,
    operation_no INT NOT NULL,

    operation_name VARCHAR(255) NOT NULL,
    work_center VARCHAR(100) NULL,

    planned_setup_time_minutes DECIMAL(18,2) NOT NULL DEFAULT 0,
    planned_run_time_minutes DECIMAL(18,2) NOT NULL DEFAULT 0,
    actual_setup_time_minutes DECIMAL(18,2) NOT NULL DEFAULT 0,
    actual_run_time_minutes DECIMAL(18,2) NOT NULL DEFAULT 0,

    labor_cost DECIMAL(18,2) NOT NULL DEFAULT 0,
    machine_cost DECIMAL(18,2) NOT NULL DEFAULT 0,
    overhead_cost DECIMAL(18,2) NOT NULL DEFAULT 0,

    operation_status ENUM(
        'open',
        'in_progress',
        'completed',
        'skipped'
    ) NOT NULL DEFAULT 'open',

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_production_order_operations_doc_op (production_order_id, operation_no),

    CONSTRAINT fk_production_order_operations_doc FOREIGN KEY (production_order_id) REFERENCES production_orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_production_order_operations_bom_operation FOREIGN KEY (bom_operation_id) REFERENCES bom_operations(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE production_order_outputs (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    production_order_id BIGINT UNSIGNED NOT NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    output_type ENUM(
        'finished_goods',
        'semi_finished',
        'by_product',
        'scrap'
    ) NOT NULL DEFAULT 'finished_goods',

    planned_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    produced_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    rejected_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    accepted_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    warehouse_id BIGINT UNSIGNED NULL,

    standard_rate DECIMAL(18,4) NOT NULL DEFAULT 0,
    standard_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    actual_rate DECIMAL(18,4) NOT NULL DEFAULT 0,
    actual_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    line_status ENUM(
        'open',
        'partially_received',
        'fully_received',
        'closed'
    ) NOT NULL DEFAULT 'open',

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_production_order_outputs_doc_line (production_order_id, line_no),

    INDEX idx_production_order_outputs_item (item_id),

    CONSTRAINT fk_production_order_outputs_doc FOREIGN KEY (production_order_id) REFERENCES production_orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_production_order_outputs_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_production_order_outputs_uom FOREIGN KEY (uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_production_order_outputs_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 3. PRODUCTION MATERIAL ISSUE
-- Material issue against production order
-- =========================================================
DROP TABLE IF EXISTS production_material_issue_lines;
DROP TABLE IF EXISTS production_material_issues;

CREATE TABLE production_material_issues (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,

    issue_no VARCHAR(100) NOT NULL,
    issue_date DATE NOT NULL,

    production_order_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NOT NULL,
    voucher_id BIGINT UNSIGNED NULL,

    issue_status ENUM(
        'draft',
        'posted',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    issue_mode ENUM(
        'manual',
        'backflush'
    ) NOT NULL DEFAULT 'manual',

    remarks TEXT NULL,

    posted_by BIGINT UNSIGNED NULL,
    posted_at DATETIME NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_production_material_issues_company_no (company_id, issue_no),

    INDEX idx_production_material_issues_date (issue_date),
    INDEX idx_production_material_issues_status (issue_status),

    CONSTRAINT fk_production_material_issues_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_production_material_issues_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_production_material_issues_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_production_material_issues_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_production_material_issues_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_production_material_issues_production_order FOREIGN KEY (production_order_id) REFERENCES production_orders(id),
    CONSTRAINT fk_production_material_issues_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_production_material_issues_posted_by FOREIGN KEY (posted_by) REFERENCES users(id),
    CONSTRAINT fk_production_material_issues_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_production_material_issues_updated_by FOREIGN KEY (updated_by) REFERENCES users(id),
    CONSTRAINT fk_production_material_issues_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE production_material_issue_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    production_material_issue_id BIGINT UNSIGNED NOT NULL,
    production_order_material_id BIGINT UNSIGNED NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    warehouse_id BIGINT UNSIGNED NOT NULL,

    batch_id BIGINT UNSIGNED NULL,
    serial_id BIGINT UNSIGNED NULL,

    issue_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    unit_cost DECIMAL(18,4) NOT NULL DEFAULT 0,
    total_cost DECIMAL(18,2) NOT NULL DEFAULT 0,

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_production_material_issue_lines_doc_line (production_material_issue_id, line_no),

    INDEX idx_production_material_issue_lines_item (item_id),

    CONSTRAINT fk_production_material_issue_lines_doc FOREIGN KEY (production_material_issue_id) REFERENCES production_material_issues(id) ON DELETE CASCADE,
    CONSTRAINT fk_production_material_issue_lines_order_material FOREIGN KEY (production_order_material_id) REFERENCES production_order_materials(id),
    CONSTRAINT fk_production_material_issue_lines_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_production_material_issue_lines_uom FOREIGN KEY (uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_production_material_issue_lines_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_production_material_issue_lines_batch FOREIGN KEY (batch_id) REFERENCES stock_batches(id),
    CONSTRAINT fk_production_material_issue_lines_serial FOREIGN KEY (serial_id) REFERENCES stock_serials(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 4. PRODUCTION RECEIPTS
-- Finished goods / by-product / scrap receipt from production
-- =========================================================
DROP TABLE IF EXISTS production_receipt_lines;
DROP TABLE IF EXISTS production_receipts;

CREATE TABLE production_receipts (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,

    receipt_no VARCHAR(100) NOT NULL,
    receipt_date DATE NOT NULL,

    production_order_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NOT NULL,
    voucher_id BIGINT UNSIGNED NULL,

    receipt_status ENUM(
        'draft',
        'posted',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    receipt_type ENUM(
        'finished_goods',
        'semi_finished',
        'by_product',
        'scrap',
        'mixed'
    ) NOT NULL DEFAULT 'finished_goods',

    remarks TEXT NULL,

    posted_by BIGINT UNSIGNED NULL,
    posted_at DATETIME NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_production_receipts_company_no (company_id, receipt_no),

    INDEX idx_production_receipts_date (receipt_date),
    INDEX idx_production_receipts_status (receipt_status),

    CONSTRAINT fk_production_receipts_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_production_receipts_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_production_receipts_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_production_receipts_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_production_receipts_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_production_receipts_production_order FOREIGN KEY (production_order_id) REFERENCES production_orders(id),
    CONSTRAINT fk_production_receipts_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_production_receipts_posted_by FOREIGN KEY (posted_by) REFERENCES users(id),
    CONSTRAINT fk_production_receipts_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_production_receipts_updated_by FOREIGN KEY (updated_by) REFERENCES users(id),
    CONSTRAINT fk_production_receipts_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE production_receipt_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    production_receipt_id BIGINT UNSIGNED NOT NULL,
    production_order_output_id BIGINT UNSIGNED NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    warehouse_id BIGINT UNSIGNED NOT NULL,

    batch_id BIGINT UNSIGNED NULL,
    serial_id BIGINT UNSIGNED NULL,

    receipt_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    accepted_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    rejected_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    unit_cost DECIMAL(18,4) NOT NULL DEFAULT 0,
    total_cost DECIMAL(18,2) NOT NULL DEFAULT 0,

    output_type ENUM(
        'finished_goods',
        'semi_finished',
        'by_product',
        'scrap'
    ) NOT NULL DEFAULT 'finished_goods',

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_production_receipt_lines_doc_line (production_receipt_id, line_no),

    INDEX idx_production_receipt_lines_item (item_id),

    CONSTRAINT fk_production_receipt_lines_doc FOREIGN KEY (production_receipt_id) REFERENCES production_receipts(id) ON DELETE CASCADE,
    CONSTRAINT fk_production_receipt_lines_order_output FOREIGN KEY (production_order_output_id) REFERENCES production_order_outputs(id),
    CONSTRAINT fk_production_receipt_lines_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_production_receipt_lines_uom FOREIGN KEY (uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_production_receipt_lines_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_production_receipt_lines_batch FOREIGN KEY (batch_id) REFERENCES stock_batches(id),
    CONSTRAINT fk_production_receipt_lines_serial FOREIGN KEY (serial_id) REFERENCES stock_serials(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


SET FOREIGN_KEY_CHECKS = 1;
-- =========================================================
-- MODULE 10 : JOBWORK / SUBCONTRACTING / OUTSOURCED PRODUCTION
-- ERP FOUNDATION - MySQL 8
-- Depends on MODULE 1A + 1B + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9
-- =========================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- 1. JOBWORK ORDERS
-- Main subcontract / jobwork instruction to vendor
-- =========================================================
DROP TABLE IF EXISTS jobwork_order_outputs;
DROP TABLE IF EXISTS jobwork_order_materials;
DROP TABLE IF EXISTS jobwork_orders;

CREATE TABLE jobwork_orders (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,

    jobwork_no VARCHAR(100) NOT NULL,
    jobwork_date DATE NOT NULL,

    supplier_party_id BIGINT UNSIGNED NOT NULL,

    process_name VARCHAR(255) NOT NULL,
    process_type ENUM(
        'cutting',
        'stitching',
        'polishing',
        'coating',
        'printing',
        'assembly',
        'machining',
        'packing',
        'finishing',
        'other'
    ) NOT NULL DEFAULT 'other',

    source_type ENUM(
        'manual',
        'production_order',
        'sales_order',
        'rework',
        'other'
    ) NOT NULL DEFAULT 'manual',

    source_document_type VARCHAR(50) NULL,
    source_document_id BIGINT UNSIGNED NULL,

    issue_warehouse_id BIGINT UNSIGNED NOT NULL,
    receipt_warehouse_id BIGINT UNSIGNED NOT NULL,

    expected_return_date DATE NULL,

    jobwork_status ENUM(
        'draft',
        'released',
        'partially_dispatched',
        'fully_dispatched',
        'partially_received',
        'fully_received',
        'closed',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    notes TEXT NULL,

    approved_by BIGINT UNSIGNED NULL,
    approved_at DATETIME NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_jobwork_orders_company_no (company_id, jobwork_no),

    INDEX idx_jobwork_orders_date (jobwork_date),
    INDEX idx_jobwork_orders_supplier (supplier_party_id),
    INDEX idx_jobwork_orders_status (jobwork_status),

    CONSTRAINT fk_jobwork_orders_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_jobwork_orders_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_jobwork_orders_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_jobwork_orders_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_jobwork_orders_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_jobwork_orders_supplier FOREIGN KEY (supplier_party_id) REFERENCES parties(id),
    CONSTRAINT fk_jobwork_orders_issue_warehouse FOREIGN KEY (issue_warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_jobwork_orders_receipt_warehouse FOREIGN KEY (receipt_warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_jobwork_orders_approved_by FOREIGN KEY (approved_by) REFERENCES users(id),
    CONSTRAINT fk_jobwork_orders_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_jobwork_orders_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE jobwork_order_materials (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    jobwork_order_id BIGINT UNSIGNED NOT NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    line_type ENUM(
        'raw_material',
        'semi_finished',
        'packing_material',
        'consumable'
    ) NOT NULL DEFAULT 'raw_material',

    planned_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    dispatched_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    received_back_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    consumed_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    pending_with_vendor_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    standard_rate DECIMAL(18,4) NOT NULL DEFAULT 0,
    standard_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_jobwork_order_materials_doc_line (jobwork_order_id, line_no),

    INDEX idx_jobwork_order_materials_item (item_id),

    CONSTRAINT fk_jobwork_order_materials_doc FOREIGN KEY (jobwork_order_id) REFERENCES jobwork_orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_jobwork_order_materials_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_jobwork_order_materials_uom FOREIGN KEY (uom_id) REFERENCES uoms(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE jobwork_order_outputs (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    jobwork_order_id BIGINT UNSIGNED NOT NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    output_type ENUM(
        'processed_material',
        'semi_finished',
        'finished_goods',
        'by_product',
        'scrap'
    ) NOT NULL DEFAULT 'processed_material',

    planned_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    received_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    rejected_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    accepted_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    standard_rate DECIMAL(18,4) NOT NULL DEFAULT 0,
    standard_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_jobwork_order_outputs_doc_line (jobwork_order_id, line_no),

    INDEX idx_jobwork_order_outputs_item (item_id),

    CONSTRAINT fk_jobwork_order_outputs_doc FOREIGN KEY (jobwork_order_id) REFERENCES jobwork_orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_jobwork_order_outputs_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_jobwork_order_outputs_uom FOREIGN KEY (uom_id) REFERENCES uoms(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 2. JOBWORK DISPATCHES
-- Material outward to vendor
-- =========================================================
DROP TABLE IF EXISTS jobwork_dispatch_lines;
DROP TABLE IF EXISTS jobwork_dispatches;

CREATE TABLE jobwork_dispatches (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,

    dispatch_no VARCHAR(100) NOT NULL,
    dispatch_date DATE NOT NULL,

    jobwork_order_id BIGINT UNSIGNED NOT NULL,
    supplier_party_id BIGINT UNSIGNED NOT NULL,

    warehouse_id BIGINT UNSIGNED NOT NULL,
    voucher_id BIGINT UNSIGNED NULL,

    dc_no VARCHAR(100) NULL,
    dc_date DATE NULL,

    vehicle_no VARCHAR(50) NULL,
    transporter_party_id BIGINT UNSIGNED NULL,
    lr_no VARCHAR(100) NULL,
    lr_date DATE NULL,

    dispatch_status ENUM(
        'draft',
        'posted',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    remarks TEXT NULL,

    posted_by BIGINT UNSIGNED NULL,
    posted_at DATETIME NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_jobwork_dispatches_company_no (company_id, dispatch_no),

    INDEX idx_jobwork_dispatches_date (dispatch_date),
    INDEX idx_jobwork_dispatches_supplier (supplier_party_id),
    INDEX idx_jobwork_dispatches_status (dispatch_status),

    CONSTRAINT fk_jobwork_dispatches_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_jobwork_dispatches_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_jobwork_dispatches_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_jobwork_dispatches_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_jobwork_dispatches_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_jobwork_dispatches_jobwork_order FOREIGN KEY (jobwork_order_id) REFERENCES jobwork_orders(id),
    CONSTRAINT fk_jobwork_dispatches_supplier FOREIGN KEY (supplier_party_id) REFERENCES parties(id),
    CONSTRAINT fk_jobwork_dispatches_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_jobwork_dispatches_transporter FOREIGN KEY (transporter_party_id) REFERENCES parties(id),
    CONSTRAINT fk_jobwork_dispatches_posted_by FOREIGN KEY (posted_by) REFERENCES users(id),
    CONSTRAINT fk_jobwork_dispatches_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_jobwork_dispatches_updated_by FOREIGN KEY (updated_by) REFERENCES users(id),
    CONSTRAINT fk_jobwork_dispatches_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE jobwork_dispatch_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    jobwork_dispatch_id BIGINT UNSIGNED NOT NULL,
    jobwork_order_material_id BIGINT UNSIGNED NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    warehouse_id BIGINT UNSIGNED NOT NULL,

    batch_id BIGINT UNSIGNED NULL,
    serial_id BIGINT UNSIGNED NULL,

    dispatch_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    unit_cost DECIMAL(18,4) NOT NULL DEFAULT 0,
    total_cost DECIMAL(18,2) NOT NULL DEFAULT 0,

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_jobwork_dispatch_lines_doc_line (jobwork_dispatch_id, line_no),

    INDEX idx_jobwork_dispatch_lines_item (item_id),

    CONSTRAINT fk_jobwork_dispatch_lines_doc FOREIGN KEY (jobwork_dispatch_id) REFERENCES jobwork_dispatches(id) ON DELETE CASCADE,
    CONSTRAINT fk_jobwork_dispatch_lines_order_material FOREIGN KEY (jobwork_order_material_id) REFERENCES jobwork_order_materials(id),
    CONSTRAINT fk_jobwork_dispatch_lines_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_jobwork_dispatch_lines_uom FOREIGN KEY (uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_jobwork_dispatch_lines_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_jobwork_dispatch_lines_batch FOREIGN KEY (batch_id) REFERENCES stock_batches(id),
    CONSTRAINT fk_jobwork_dispatch_lines_serial FOREIGN KEY (serial_id) REFERENCES stock_serials(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 3. JOBWORK RECEIPTS
-- Processed / returned material inward from vendor
-- =========================================================
DROP TABLE IF EXISTS jobwork_receipt_lines;
DROP TABLE IF EXISTS jobwork_receipts;

CREATE TABLE jobwork_receipts (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,

    receipt_no VARCHAR(100) NOT NULL,
    receipt_date DATE NOT NULL,

    jobwork_order_id BIGINT UNSIGNED NOT NULL,
    supplier_party_id BIGINT UNSIGNED NOT NULL,

    warehouse_id BIGINT UNSIGNED NOT NULL,
    voucher_id BIGINT UNSIGNED NULL,

    supplier_dc_no VARCHAR(100) NULL,
    supplier_dc_date DATE NULL,

    vehicle_no VARCHAR(50) NULL,
    transporter_party_id BIGINT UNSIGNED NULL,
    lr_no VARCHAR(100) NULL,
    lr_date DATE NULL,

    receipt_status ENUM(
        'draft',
        'posted',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    receipt_mode ENUM(
        'material_return',
        'processed_receipt',
        'partial_return',
        'mixed'
    ) NOT NULL DEFAULT 'processed_receipt',

    remarks TEXT NULL,

    posted_by BIGINT UNSIGNED NULL,
    posted_at DATETIME NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_jobwork_receipts_company_no (company_id, receipt_no),

    INDEX idx_jobwork_receipts_date (receipt_date),
    INDEX idx_jobwork_receipts_supplier (supplier_party_id),
    INDEX idx_jobwork_receipts_status (receipt_status),

    CONSTRAINT fk_jobwork_receipts_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_jobwork_receipts_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_jobwork_receipts_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_jobwork_receipts_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_jobwork_receipts_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_jobwork_receipts_jobwork_order FOREIGN KEY (jobwork_order_id) REFERENCES jobwork_orders(id),
    CONSTRAINT fk_jobwork_receipts_supplier FOREIGN KEY (supplier_party_id) REFERENCES parties(id),
    CONSTRAINT fk_jobwork_receipts_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_jobwork_receipts_transporter FOREIGN KEY (transporter_party_id) REFERENCES parties(id),
    CONSTRAINT fk_jobwork_receipts_posted_by FOREIGN KEY (posted_by) REFERENCES users(id),
    CONSTRAINT fk_jobwork_receipts_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_jobwork_receipts_updated_by FOREIGN KEY (updated_by) REFERENCES users(id),
    CONSTRAINT fk_jobwork_receipts_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE jobwork_receipt_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    jobwork_receipt_id BIGINT UNSIGNED NOT NULL,
    jobwork_order_output_id BIGINT UNSIGNED NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    warehouse_id BIGINT UNSIGNED NOT NULL,

    batch_id BIGINT UNSIGNED NULL,
    serial_id BIGINT UNSIGNED NULL,

    receipt_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    accepted_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    rejected_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    output_type ENUM(
        'processed_material',
        'semi_finished',
        'finished_goods',
        'by_product',
        'scrap'
    ) NOT NULL DEFAULT 'processed_material',

    unit_cost DECIMAL(18,4) NOT NULL DEFAULT 0,
    total_cost DECIMAL(18,2) NOT NULL DEFAULT 0,

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_jobwork_receipt_lines_doc_line (jobwork_receipt_id, line_no),

    INDEX idx_jobwork_receipt_lines_item (item_id),

    CONSTRAINT fk_jobwork_receipt_lines_doc FOREIGN KEY (jobwork_receipt_id) REFERENCES jobwork_receipts(id) ON DELETE CASCADE,
    CONSTRAINT fk_jobwork_receipt_lines_order_output FOREIGN KEY (jobwork_order_output_id) REFERENCES jobwork_order_outputs(id),
    CONSTRAINT fk_jobwork_receipt_lines_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_jobwork_receipt_lines_uom FOREIGN KEY (uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_jobwork_receipt_lines_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_jobwork_receipt_lines_batch FOREIGN KEY (batch_id) REFERENCES stock_batches(id),
    CONSTRAINT fk_jobwork_receipt_lines_serial FOREIGN KEY (serial_id) REFERENCES stock_serials(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 4. JOBWORK CHARGES
-- Vendor processing charges / subcontract service billing
-- =========================================================
DROP TABLE IF EXISTS jobwork_charge_lines;
DROP TABLE IF EXISTS jobwork_charges;

CREATE TABLE jobwork_charges (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,

    charge_no VARCHAR(100) NOT NULL,
    charge_date DATE NOT NULL,

    jobwork_order_id BIGINT UNSIGNED NOT NULL,
    supplier_party_id BIGINT UNSIGNED NOT NULL,
    voucher_id BIGINT UNSIGNED NULL,

    purchase_invoice_id BIGINT UNSIGNED NULL,

    charge_status ENUM(
        'draft',
        'posted',
        'invoiced',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    subtotal DECIMAL(18,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    taxable_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    cgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    sgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    igst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    cess_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    round_off_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    remarks TEXT NULL,

    posted_by BIGINT UNSIGNED NULL,
    posted_at DATETIME NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_jobwork_charges_company_no (company_id, charge_no),

    INDEX idx_jobwork_charges_date (charge_date),
    INDEX idx_jobwork_charges_supplier (supplier_party_id),
    INDEX idx_jobwork_charges_status (charge_status),

    CONSTRAINT fk_jobwork_charges_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_jobwork_charges_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_jobwork_charges_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_jobwork_charges_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_jobwork_charges_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_jobwork_charges_jobwork_order FOREIGN KEY (jobwork_order_id) REFERENCES jobwork_orders(id),
    CONSTRAINT fk_jobwork_charges_supplier FOREIGN KEY (supplier_party_id) REFERENCES parties(id),
    CONSTRAINT fk_jobwork_charges_purchase_invoice FOREIGN KEY (purchase_invoice_id) REFERENCES purchase_invoices(id),
    CONSTRAINT fk_jobwork_charges_posted_by FOREIGN KEY (posted_by) REFERENCES users(id),
    CONSTRAINT fk_jobwork_charges_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_jobwork_charges_updated_by FOREIGN KEY (updated_by) REFERENCES users(id),
    CONSTRAINT fk_jobwork_charges_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE jobwork_charge_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    jobwork_charge_id BIGINT UNSIGNED NOT NULL,
    line_no INT NOT NULL,

    service_description VARCHAR(255) NOT NULL,

    item_id BIGINT UNSIGNED NULL,
    output_item_id BIGINT UNSIGNED NULL,

    qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    rate DECIMAL(18,4) NOT NULL DEFAULT 0,
    amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    tax_code_id BIGINT UNSIGNED NULL,
    tax_percent DECIMAL(8,4) NOT NULL DEFAULT 0,
    cgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    sgst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    igst_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    cess_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    line_total DECIMAL(18,2) NOT NULL DEFAULT 0,

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_jobwork_charge_lines_doc_line (jobwork_charge_id, line_no),

    INDEX idx_jobwork_charge_lines_item (item_id),
    INDEX idx_jobwork_charge_lines_output_item (output_item_id),

    CONSTRAINT fk_jobwork_charge_lines_doc FOREIGN KEY (jobwork_charge_id) REFERENCES jobwork_charges(id) ON DELETE CASCADE,
    CONSTRAINT fk_jobwork_charge_lines_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_jobwork_charge_lines_output_item FOREIGN KEY (output_item_id) REFERENCES items(id),
    CONSTRAINT fk_jobwork_charge_lines_tax_code FOREIGN KEY (tax_code_id) REFERENCES tax_codes(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================
-- MODULE 11 : QUALITY CONTROL / INSPECTION / APPROVAL ENGINE
-- ERP FOUNDATION - MySQL 8
-- Depends on MODULE 1A + 1B + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9 + 10
-- =========================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- 1. QC PLANS
-- Master quality plan per item / item category / process
-- =========================================================
DROP TABLE IF EXISTS qc_plan_lines;
DROP TABLE IF EXISTS qc_plans;

CREATE TABLE qc_plans (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NULL,
    location_id BIGINT UNSIGNED NULL,

    plan_code VARCHAR(100) NOT NULL,
    plan_name VARCHAR(255) NOT NULL,

    item_id BIGINT UNSIGNED NULL,
    item_category_id BIGINT UNSIGNED NULL,

    qc_scope ENUM(
        'purchase_receipt',
        'production_receipt',
        'jobwork_receipt',
        'stock_receipt',
        'sales_return',
        'all'
    ) NOT NULL DEFAULT 'all',

    sampling_method ENUM(
        '100_percent',
        'random',
        'lot_based',
        'batch_based',
        'custom'
    ) NOT NULL DEFAULT '100_percent',

    acceptance_basis ENUM(
        'all_pass',
        'min_pass_percent',
        'critical_only',
        'manual_decision'
    ) NOT NULL DEFAULT 'all_pass',

    min_pass_percent DECIMAL(8,4) NOT NULL DEFAULT 100,

    approval_status ENUM(
        'draft',
        'approved',
        'inactive',
        'obsolete'
    ) NOT NULL DEFAULT 'draft',

    effective_from DATE NULL,
    effective_to DATE NULL,

    notes TEXT NULL,

    approved_by BIGINT UNSIGNED NULL,
    approved_at DATETIME NULL,

    is_default TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_qc_plans_company_code (company_id, plan_code),

    INDEX idx_qc_plans_item (item_id),
    INDEX idx_qc_plans_category (item_category_id),
    INDEX idx_qc_plans_scope (qc_scope),
    INDEX idx_qc_plans_status (approval_status),

    CONSTRAINT fk_qc_plans_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_qc_plans_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_qc_plans_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_qc_plans_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_qc_plans_item_category FOREIGN KEY (item_category_id) REFERENCES item_categories(id),
    CONSTRAINT fk_qc_plans_approved_by FOREIGN KEY (approved_by) REFERENCES users(id),
    CONSTRAINT fk_qc_plans_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_qc_plans_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE qc_plan_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    qc_plan_id BIGINT UNSIGNED NOT NULL,
    line_no INT NOT NULL,

    checkpoint_name VARCHAR(255) NOT NULL,
    checkpoint_type ENUM(
        'visual',
        'dimension',
        'weight',
        'color',
        'function',
        'packing',
        'chemical',
        'mechanical',
        'documentation',
        'other'
    ) NOT NULL DEFAULT 'visual',

    specification VARCHAR(500) NULL,
    tolerance_min DECIMAL(18,6) NULL,
    tolerance_max DECIMAL(18,6) NULL,
    expected_text VARCHAR(255) NULL,

    unit VARCHAR(50) NULL,

    is_critical TINYINT(1) NOT NULL DEFAULT 0,
    is_mandatory TINYINT(1) NOT NULL DEFAULT 1,

    sequence_no INT NOT NULL DEFAULT 1,

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_qc_plan_lines_doc_line (qc_plan_id, line_no),

    INDEX idx_qc_plan_lines_type (checkpoint_type),

    CONSTRAINT fk_qc_plan_lines_doc FOREIGN KEY (qc_plan_id) REFERENCES qc_plans(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 2. QC INSPECTIONS
-- Transaction-level inspection against receipt / output / return
-- =========================================================
DROP TABLE IF EXISTS qc_inspection_lines;
DROP TABLE IF EXISTS qc_inspections;

CREATE TABLE qc_inspections (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NOT NULL,
    location_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NOT NULL,

    document_series_id BIGINT UNSIGNED NULL,

    inspection_no VARCHAR(100) NOT NULL,
    inspection_date DATE NOT NULL,

    qc_plan_id BIGINT UNSIGNED NULL,

    inspection_scope ENUM(
        'purchase_receipt',
        'production_receipt',
        'jobwork_receipt',
        'stock_receipt',
        'sales_return'
    ) NOT NULL,

    source_document_type VARCHAR(50) NOT NULL,
    source_document_id BIGINT UNSIGNED NOT NULL,
    source_line_id BIGINT UNSIGNED NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    uom_id BIGINT UNSIGNED NOT NULL,

    warehouse_id BIGINT UNSIGNED NULL,
    batch_id BIGINT UNSIGNED NULL,
    serial_id BIGINT UNSIGNED NULL,

    lot_no VARCHAR(100) NULL,
    sample_size DECIMAL(18,6) NOT NULL DEFAULT 0,
    inspected_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    accepted_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    rejected_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    hold_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    rework_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    inspection_status ENUM(
        'draft',
        'in_progress',
        'completed',
        'approved',
        'rejected',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    final_result ENUM(
        'accepted',
        'rejected',
        'hold',
        'rework',
        'partial_accept'
    ) NULL,

    inspected_by BIGINT UNSIGNED NULL,
    inspected_at DATETIME NULL,

    approved_by BIGINT UNSIGNED NULL,
    approved_at DATETIME NULL,

    remarks TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_qc_inspections_company_no (company_id, inspection_no),

    INDEX idx_qc_inspections_date (inspection_date),
    INDEX idx_qc_inspections_scope (inspection_scope),
    INDEX idx_qc_inspections_source (source_document_type, source_document_id),
    INDEX idx_qc_inspections_item (item_id),
    INDEX idx_qc_inspections_status (inspection_status),

    CONSTRAINT fk_qc_inspections_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_qc_inspections_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_qc_inspections_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_qc_inspections_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_qc_inspections_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_qc_inspections_qc_plan FOREIGN KEY (qc_plan_id) REFERENCES qc_plans(id),
    CONSTRAINT fk_qc_inspections_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_qc_inspections_uom FOREIGN KEY (uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_qc_inspections_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_qc_inspections_batch FOREIGN KEY (batch_id) REFERENCES stock_batches(id),
    CONSTRAINT fk_qc_inspections_serial FOREIGN KEY (serial_id) REFERENCES stock_serials(id),
    CONSTRAINT fk_qc_inspections_inspected_by FOREIGN KEY (inspected_by) REFERENCES users(id),
    CONSTRAINT fk_qc_inspections_approved_by FOREIGN KEY (approved_by) REFERENCES users(id),
    CONSTRAINT fk_qc_inspections_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_qc_inspections_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE qc_inspection_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    qc_inspection_id BIGINT UNSIGNED NOT NULL,
    qc_plan_line_id BIGINT UNSIGNED NULL,
    line_no INT NOT NULL,

    checkpoint_name VARCHAR(255) NOT NULL,
    checkpoint_type ENUM(
        'visual',
        'dimension',
        'weight',
        'color',
        'function',
        'packing',
        'chemical',
        'mechanical',
        'documentation',
        'other'
    ) NOT NULL DEFAULT 'visual',

    expected_value VARCHAR(255) NULL,
    actual_value VARCHAR(255) NULL,

    measured_value DECIMAL(18,6) NULL,
    tolerance_min DECIMAL(18,6) NULL,
    tolerance_max DECIMAL(18,6) NULL,

    result_status ENUM(
        'pass',
        'fail',
        'hold',
        'na'
    ) NOT NULL DEFAULT 'pass',

    is_critical TINYINT(1) NOT NULL DEFAULT 0,
    is_mandatory TINYINT(1) NOT NULL DEFAULT 1,

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_qc_inspection_lines_doc_line (qc_inspection_id, line_no),

    INDEX idx_qc_inspection_lines_result (result_status),

    CONSTRAINT fk_qc_inspection_lines_doc FOREIGN KEY (qc_inspection_id) REFERENCES qc_inspections(id) ON DELETE CASCADE,
    CONSTRAINT fk_qc_inspection_lines_plan_line FOREIGN KEY (qc_plan_line_id) REFERENCES qc_plan_lines(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 3. QC RESULT ACTIONS
-- What happened after QC result (accept / reject / hold / rework)
-- =========================================================
DROP TABLE IF EXISTS qc_result_actions;

CREATE TABLE qc_result_actions (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    qc_inspection_id BIGINT UNSIGNED NOT NULL,

    action_type ENUM(
        'accept_to_stock',
        'reject_to_supplier',
        'reject_to_scrap',
        'move_to_hold',
        'move_to_quarantine',
        'send_for_rework',
        'manual_override'
    ) NOT NULL,

    action_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    target_warehouse_id BIGINT UNSIGNED NULL,

    reference_document_type VARCHAR(50) NULL,
    reference_document_id BIGINT UNSIGNED NULL,

    action_status ENUM(
        'pending',
        'completed',
        'cancelled'
    ) NOT NULL DEFAULT 'pending',

    action_by BIGINT UNSIGNED NULL,
    action_at DATETIME NULL,

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    INDEX idx_qc_result_actions_inspection (qc_inspection_id),
    INDEX idx_qc_result_actions_type (action_type),
    INDEX idx_qc_result_actions_status (action_status),

    CONSTRAINT fk_qc_result_actions_inspection FOREIGN KEY (qc_inspection_id) REFERENCES qc_inspections(id) ON DELETE CASCADE,
    CONSTRAINT fk_qc_result_actions_target_warehouse FOREIGN KEY (target_warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_qc_result_actions_action_by FOREIGN KEY (action_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 4. QC NON-CONFORMANCE LOGS
-- Root cause / defect tracking / corrective action history
-- =========================================================
DROP TABLE IF EXISTS qc_non_conformance_logs;

CREATE TABLE qc_non_conformance_logs (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    qc_inspection_id BIGINT UNSIGNED NOT NULL,
    qc_inspection_line_id BIGINT UNSIGNED NULL,

    defect_code VARCHAR(100) NULL,
    defect_name VARCHAR(255) NOT NULL,

    severity ENUM(
        'minor',
        'major',
        'critical'
    ) NOT NULL DEFAULT 'minor',

    defect_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    root_cause VARCHAR(500) NULL,
    corrective_action VARCHAR(500) NULL,
    preventive_action VARCHAR(500) NULL,

    assigned_to BIGINT UNSIGNED NULL,
    due_date DATE NULL,

    closure_status ENUM(
        'open',
        'in_progress',
        'closed',
        'waived'
    ) NOT NULL DEFAULT 'open',

    closed_by BIGINT UNSIGNED NULL,
    closed_at DATETIME NULL,

    remarks TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    INDEX idx_qc_non_conformance_logs_inspection (qc_inspection_id),
    INDEX idx_qc_non_conformance_logs_severity (severity),
    INDEX idx_qc_non_conformance_logs_status (closure_status),

    CONSTRAINT fk_qc_non_conformance_logs_inspection FOREIGN KEY (qc_inspection_id) REFERENCES qc_inspections(id) ON DELETE CASCADE,
    CONSTRAINT fk_qc_non_conformance_logs_inspection_line FOREIGN KEY (qc_inspection_line_id) REFERENCES qc_inspection_lines(id) ON DELETE SET NULL,
    CONSTRAINT fk_qc_non_conformance_logs_assigned_to FOREIGN KEY (assigned_to) REFERENCES users(id),
    CONSTRAINT fk_qc_non_conformance_logs_closed_by FOREIGN KEY (closed_by) REFERENCES users(id),
    CONSTRAINT fk_qc_non_conformance_logs_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_qc_non_conformance_logs_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================
-- MODULE 12 : MATERIAL REQUIREMENT PLANNING (MRP) / REORDER / PLANNING ENGINE
-- ERP FOUNDATION - MySQL 8
-- Depends on MODULE 1A + 1B + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9 + 10 + 11
-- =========================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- 1. ITEM PLANNING POLICIES
-- Planning rules per item / warehouse
-- =========================================================
DROP TABLE IF EXISTS item_planning_policies;

CREATE TABLE item_planning_policies (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NULL,
    location_id BIGINT UNSIGNED NULL,
    warehouse_id BIGINT UNSIGNED NULL,

    item_id BIGINT UNSIGNED NOT NULL,

    planning_method ENUM(
        'manual',
        'reorder',
        'mrp',
        'min_max',
        'make_to_order',
        'make_to_stock'
    ) NOT NULL DEFAULT 'reorder',

    procurement_type ENUM(
        'purchase',
        'production',
        'jobwork',
        'transfer',
        'mixed'
    ) NOT NULL DEFAULT 'purchase',

    lead_time_days INT NOT NULL DEFAULT 0,
    safety_stock_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    reorder_level_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    reorder_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    min_stock_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    max_stock_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    minimum_order_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    max_order_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    order_multiple_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    preferred_supplier_party_id BIGINT UNSIGNED NULL,
    preferred_bom_id BIGINT UNSIGNED NULL,
    preferred_warehouse_id BIGINT UNSIGNED NULL,

    planning_fence_days INT NOT NULL DEFAULT 0,

    is_mrp_enabled TINYINT(1) NOT NULL DEFAULT 1,
    is_reorder_enabled TINYINT(1) NOT NULL DEFAULT 1,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    remarks TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_item_planning_policies_scope (
        company_id, item_id, warehouse_id
    ),

    INDEX idx_item_planning_policies_item (item_id),
    INDEX idx_item_planning_policies_warehouse (warehouse_id),
    INDEX idx_item_planning_policies_method (planning_method),
    INDEX idx_item_planning_policies_procurement (procurement_type),

    CONSTRAINT fk_item_planning_policies_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_item_planning_policies_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_item_planning_policies_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_item_planning_policies_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_item_planning_policies_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_item_planning_policies_preferred_supplier FOREIGN KEY (preferred_supplier_party_id) REFERENCES parties(id),
    CONSTRAINT fk_item_planning_policies_preferred_bom FOREIGN KEY (preferred_bom_id) REFERENCES boms(id),
    CONSTRAINT fk_item_planning_policies_preferred_warehouse FOREIGN KEY (preferred_warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_item_planning_policies_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_item_planning_policies_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 2. PLANNING CALENDARS
-- Optional planning buckets / cycle definitions
-- =========================================================
DROP TABLE IF EXISTS planning_calendars;

CREATE TABLE planning_calendars (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,

    calendar_code VARCHAR(100) NOT NULL,
    calendar_name VARCHAR(255) NOT NULL,

    planning_frequency ENUM(
        'daily',
        'weekly',
        'monthly',
        'custom'
    ) NOT NULL DEFAULT 'weekly',

    week_start_day ENUM(
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday'
    ) NOT NULL DEFAULT 'monday',

    is_default TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    remarks TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_planning_calendars_company_code (company_id, calendar_code),

    CONSTRAINT fk_planning_calendars_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_planning_calendars_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_planning_calendars_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 3. MRP RUNS
-- Each planning run / simulation / snapshot
-- =========================================================
DROP TABLE IF EXISTS mrp_recommendations;
DROP TABLE IF EXISTS mrp_net_requirements;
DROP TABLE IF EXISTS mrp_supplies;
DROP TABLE IF EXISTS mrp_demands;
DROP TABLE IF EXISTS mrp_runs;

CREATE TABLE mrp_runs (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NULL,
    location_id BIGINT UNSIGNED NULL,
    warehouse_id BIGINT UNSIGNED NULL,

    planning_calendar_id BIGINT UNSIGNED NULL,

    run_no VARCHAR(100) NOT NULL,
    run_date DATE NOT NULL,

    planning_start_date DATE NOT NULL,
    planning_end_date DATE NOT NULL,

    run_scope ENUM(
        'all_items',
        'selected_items',
        'selected_category',
        'selected_warehouse'
    ) NOT NULL DEFAULT 'all_items',

    run_mode ENUM(
        'simulation',
        'official'
    ) NOT NULL DEFAULT 'official',

    run_status ENUM(
        'draft',
        'processing',
        'completed',
        'cancelled',
        'failed'
    ) NOT NULL DEFAULT 'draft',

    total_items_processed INT NOT NULL DEFAULT 0,
    total_shortage_items INT NOT NULL DEFAULT 0,
    total_recommendations INT NOT NULL DEFAULT 0,

    notes TEXT NULL,
    error_message TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    completed_by BIGINT UNSIGNED NULL,
    completed_at DATETIME NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_mrp_runs_company_no (company_id, run_no),

    INDEX idx_mrp_runs_date (run_date),
    INDEX idx_mrp_runs_status (run_status),

    CONSTRAINT fk_mrp_runs_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_mrp_runs_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_mrp_runs_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_mrp_runs_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_mrp_runs_planning_calendar FOREIGN KEY (planning_calendar_id) REFERENCES planning_calendars(id),
    CONSTRAINT fk_mrp_runs_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_mrp_runs_completed_by FOREIGN KEY (completed_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 4. MRP DEMANDS
-- Demand collected from sales / forecast / production / manual
-- =========================================================
CREATE TABLE mrp_demands (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    mrp_run_id BIGINT UNSIGNED NOT NULL,

    demand_source ENUM(
        'sales_order',
        'sales_invoice',
        'forecast',
        'production_order',
        'jobwork_order',
        'manual',
        'reorder_trigger'
    ) NOT NULL,

    source_document_type VARCHAR(50) NULL,
    source_document_id BIGINT UNSIGNED NULL,
    source_line_id BIGINT UNSIGNED NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NULL,

    demand_date DATE NOT NULL,
    required_date DATE NULL,

    demand_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    fulfilled_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    pending_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    priority_level ENUM(
        'low',
        'normal',
        'high',
        'critical'
    ) NOT NULL DEFAULT 'normal',

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    INDEX idx_mrp_demands_run (mrp_run_id),
    INDEX idx_mrp_demands_item (item_id),
    INDEX idx_mrp_demands_date (demand_date),

    CONSTRAINT fk_mrp_demands_run FOREIGN KEY (mrp_run_id) REFERENCES mrp_runs(id) ON DELETE CASCADE,
    CONSTRAINT fk_mrp_demands_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_mrp_demands_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 5. MRP SUPPLIES
-- Available / incoming supply collected during planning
-- =========================================================
CREATE TABLE mrp_supplies (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    mrp_run_id BIGINT UNSIGNED NOT NULL,

    supply_source ENUM(
        'on_hand_stock',
        'purchase_order',
        'purchase_invoice',
        'production_order',
        'jobwork_receipt',
        'stock_transfer_in',
        'manual'
    ) NOT NULL,

    source_document_type VARCHAR(50) NULL,
    source_document_id BIGINT UNSIGNED NULL,
    source_line_id BIGINT UNSIGNED NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NULL,

    available_date DATE NOT NULL,

    supply_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    allocated_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    available_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    INDEX idx_mrp_supplies_run (mrp_run_id),
    INDEX idx_mrp_supplies_item (item_id),
    INDEX idx_mrp_supplies_date (available_date),

    CONSTRAINT fk_mrp_supplies_run FOREIGN KEY (mrp_run_id) REFERENCES mrp_runs(id) ON DELETE CASCADE,
    CONSTRAINT fk_mrp_supplies_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_mrp_supplies_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 6. MRP NET REQUIREMENTS
-- Final shortage / excess result per item
-- =========================================================
CREATE TABLE mrp_net_requirements (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    mrp_run_id BIGINT UNSIGNED NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NULL,

    gross_demand_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    available_supply_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    safety_stock_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    net_required_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    shortage_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    excess_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    reorder_triggered TINYINT(1) NOT NULL DEFAULT 0,
    recommended_action ENUM(
        'none',
        'purchase',
        'production',
        'jobwork',
        'transfer'
    ) NOT NULL DEFAULT 'none',

    recommended_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    recommended_date DATE NULL,

    lead_time_days INT NOT NULL DEFAULT 0,

    planning_method ENUM(
        'manual',
        'reorder',
        'mrp',
        'min_max',
        'make_to_order',
        'make_to_stock'
    ) NOT NULL DEFAULT 'manual',

    procurement_type ENUM(
        'purchase',
        'production',
        'jobwork',
        'transfer',
        'mixed'
    ) NOT NULL DEFAULT 'purchase',

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    INDEX idx_mrp_net_requirements_run (mrp_run_id),
    INDEX idx_mrp_net_requirements_item (item_id),
    INDEX idx_mrp_net_requirements_action (recommended_action),

    CONSTRAINT fk_mrp_net_requirements_run FOREIGN KEY (mrp_run_id) REFERENCES mrp_runs(id) ON DELETE CASCADE,
    CONSTRAINT fk_mrp_net_requirements_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_mrp_net_requirements_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 7. MRP RECOMMENDATIONS
-- User-facing actionable recommendations from MRP
-- =========================================================
CREATE TABLE mrp_recommendations (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    mrp_run_id BIGINT UNSIGNED NOT NULL,
    mrp_net_requirement_id BIGINT UNSIGNED NULL,

    recommendation_type ENUM(
        'purchase_request',
        'production_request',
        'jobwork_request',
        'stock_transfer_request',
        'expedite_existing_supply',
        'manual_review'
    ) NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NULL,

    recommended_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    recommended_date DATE NULL,

    priority_level ENUM(
        'low',
        'normal',
        'high',
        'critical'
    ) NOT NULL DEFAULT 'normal',

    supplier_party_id BIGINT UNSIGNED NULL,
    bom_id BIGINT UNSIGNED NULL,
    source_warehouse_id BIGINT UNSIGNED NULL,

    recommendation_status ENUM(
        'open',
        'approved',
        'converted',
        'rejected',
        'cancelled'
    ) NOT NULL DEFAULT 'open',

    converted_document_type VARCHAR(50) NULL,
    converted_document_id BIGINT UNSIGNED NULL,

    notes TEXT NULL,

    approved_by BIGINT UNSIGNED NULL,
    approved_at DATETIME NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    INDEX idx_mrp_recommendations_run (mrp_run_id),
    INDEX idx_mrp_recommendations_item (item_id),
    INDEX idx_mrp_recommendations_type (recommendation_type),
    INDEX idx_mrp_recommendations_status (recommendation_status),

    CONSTRAINT fk_mrp_recommendations_run FOREIGN KEY (mrp_run_id) REFERENCES mrp_runs(id) ON DELETE CASCADE,
    CONSTRAINT fk_mrp_recommendations_net_requirement FOREIGN KEY (mrp_net_requirement_id) REFERENCES mrp_net_requirements(id) ON DELETE SET NULL,
    CONSTRAINT fk_mrp_recommendations_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_mrp_recommendations_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_mrp_recommendations_supplier FOREIGN KEY (supplier_party_id) REFERENCES parties(id),
    CONSTRAINT fk_mrp_recommendations_bom FOREIGN KEY (bom_id) REFERENCES boms(id),
    CONSTRAINT fk_mrp_recommendations_source_warehouse FOREIGN KEY (source_warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_mrp_recommendations_approved_by FOREIGN KEY (approved_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================
-- MODULE 13 : ASSET MANAGEMENT / FIXED ASSETS / DEPRECIATION ENGINE
-- ERP FOUNDATION - MySQL 8
-- Depends on MODULE 1A + 1B + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9 + 10 + 11 + 12
-- =========================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- 1. ASSET CATEGORIES
-- Asset classification + default accounting/depreciation setup
-- =========================================================
DROP TABLE IF EXISTS asset_disposals;
DROP TABLE IF EXISTS asset_transfer_lines;
DROP TABLE IF EXISTS asset_transfers;
DROP TABLE IF EXISTS asset_depreciation_lines;
DROP TABLE IF EXISTS asset_depreciation_runs;
DROP TABLE IF EXISTS asset_books;
DROP TABLE IF EXISTS assets;
DROP TABLE IF EXISTS cost_centers;
DROP TABLE IF EXISTS asset_categories;

CREATE TABLE asset_categories (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,

    category_code VARCHAR(100) NOT NULL,
    category_name VARCHAR(255) NOT NULL,

    parent_category_id BIGINT UNSIGNED NULL,

    asset_type ENUM(
        'machinery',
        'vehicle',
        'computer',
        'furniture',
        'building',
        'electrical',
        'tool',
        'office_equipment',
        'other'
    ) NOT NULL DEFAULT 'other',

    capitalization_threshold DECIMAL(18,2) NOT NULL DEFAULT 0,

    default_asset_account_id BIGINT UNSIGNED NULL,
    default_accum_depreciation_account_id BIGINT UNSIGNED NULL,
    default_depreciation_expense_account_id BIGINT UNSIGNED NULL,
    default_disposal_gain_account_id BIGINT UNSIGNED NULL,
    default_disposal_loss_account_id BIGINT UNSIGNED NULL,

    default_depreciation_method ENUM(
        'straight_line',
        'written_down_value',
        'manual'
    ) NOT NULL DEFAULT 'straight_line',

    default_useful_life_months INT NOT NULL DEFAULT 60,
    default_salvage_value DECIMAL(18,2) NOT NULL DEFAULT 0,

    is_tag_required TINYINT(1) NOT NULL DEFAULT 1,
    is_serial_required TINYINT(1) NOT NULL DEFAULT 0,
    is_depreciable TINYINT(1) NOT NULL DEFAULT 1,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    remarks TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_asset_categories_company_code (company_id, category_code),

    INDEX idx_asset_categories_parent (parent_category_id),
    INDEX idx_asset_categories_type (asset_type),

    CONSTRAINT fk_asset_categories_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_asset_categories_parent FOREIGN KEY (parent_category_id) REFERENCES asset_categories(id) ON DELETE SET NULL,
    CONSTRAINT fk_asset_categories_asset_account FOREIGN KEY (default_asset_account_id) REFERENCES accounts(id),
    CONSTRAINT fk_asset_categories_accum_dep_account FOREIGN KEY (default_accum_depreciation_account_id) REFERENCES accounts(id),
    CONSTRAINT fk_asset_categories_dep_exp_account FOREIGN KEY (default_depreciation_expense_account_id) REFERENCES accounts(id),
    CONSTRAINT fk_asset_categories_disposal_gain_account FOREIGN KEY (default_disposal_gain_account_id) REFERENCES accounts(id),
    CONSTRAINT fk_asset_categories_disposal_loss_account FOREIGN KEY (default_disposal_loss_account_id) REFERENCES accounts(id),
    CONSTRAINT fk_asset_categories_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_asset_categories_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE cost_centers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    company_id BIGINT UNSIGNED NOT NULL,

    parent_id BIGINT UNSIGNED NULL,

    cost_center_code VARCHAR(50) NOT NULL,
    cost_center_name VARCHAR(255) NOT NULL,

    cost_center_type ENUM(
        'department',
        'branch',
        'project',
        'production',
        'service',
        'admin',
        'other'
    ) DEFAULT 'department',

    is_active TINYINT(1) DEFAULT 1,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_cost_centers_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_cost_centers_parent FOREIGN KEY (parent_id) REFERENCES cost_centers(id),

    UNIQUE KEY uq_cost_center_company_code (company_id, cost_center_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 2. ASSETS MASTER
-- Main fixed asset register
-- =========================================================
CREATE TABLE assets (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NULL,
    location_id BIGINT UNSIGNED NULL,

    asset_category_id BIGINT UNSIGNED NOT NULL,

    asset_code VARCHAR(100) NOT NULL,
    asset_name VARCHAR(255) NOT NULL,

    asset_tag_no VARCHAR(100) NULL,
    serial_no VARCHAR(100) NULL,
    manufacturer VARCHAR(255) NULL,
    model_no VARCHAR(255) NULL,

    purchase_date DATE NULL,
    capitalization_date DATE NULL,
    put_to_use_date DATE NULL,

    purchase_invoice_id BIGINT UNSIGNED NULL,
    purchase_invoice_line_id BIGINT UNSIGNED NULL,
    supplier_party_id BIGINT UNSIGNED NULL,

    asset_account_id BIGINT UNSIGNED NULL,
    accum_depreciation_account_id BIGINT UNSIGNED NULL,
    depreciation_expense_account_id BIGINT UNSIGNED NULL,

    cost_center_id BIGINT UNSIGNED NULL,
    department_name VARCHAR(100) NULL,
    employee_name VARCHAR(255) NULL,

    warehouse_id BIGINT UNSIGNED NULL,

    acquisition_cost DECIMAL(18,2) NOT NULL DEFAULT 0,
    additional_cost DECIMAL(18,2) NOT NULL DEFAULT 0,
    capitalization_value DECIMAL(18,2) NOT NULL DEFAULT 0,
    salvage_value DECIMAL(18,2) NOT NULL DEFAULT 0,

    asset_status ENUM(
        'draft',
        'active',
        'under_construction',
        'under_maintenance',
        'transferred',
        'disposed',
        'retired',
        'lost',
        'inactive'
    ) NOT NULL DEFAULT 'draft',

    condition_status ENUM(
        'new',
        'good',
        'fair',
        'poor',
        'damaged'
    ) NOT NULL DEFAULT 'good',

    warranty_start_date DATE NULL,
    warranty_end_date DATE NULL,

    notes TEXT NULL,

    activated_by BIGINT UNSIGNED NULL,
    activated_at DATETIME NULL,

    disposed_by BIGINT UNSIGNED NULL,
    disposed_at DATETIME NULL,

    is_depreciable TINYINT(1) NOT NULL DEFAULT 1,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_assets_company_code (company_id, asset_code),
    UNIQUE KEY uq_assets_company_tag (company_id, asset_tag_no),

    INDEX idx_assets_category (asset_category_id),
    INDEX idx_assets_status (asset_status),
    INDEX idx_assets_purchase_invoice (purchase_invoice_id),

    CONSTRAINT fk_assets_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_assets_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_assets_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_assets_category FOREIGN KEY (asset_category_id) REFERENCES asset_categories(id),
    CONSTRAINT fk_assets_purchase_invoice FOREIGN KEY (purchase_invoice_id) REFERENCES purchase_invoices(id),
    CONSTRAINT fk_assets_supplier FOREIGN KEY (supplier_party_id) REFERENCES parties(id),
    CONSTRAINT fk_assets_asset_account FOREIGN KEY (asset_account_id) REFERENCES accounts(id),
    CONSTRAINT fk_assets_accum_dep_account FOREIGN KEY (accum_depreciation_account_id) REFERENCES accounts(id),
    CONSTRAINT fk_assets_dep_exp_account FOREIGN KEY (depreciation_expense_account_id) REFERENCES accounts(id),
    CONSTRAINT fk_assets_cost_center FOREIGN KEY (cost_center_id) REFERENCES cost_centers(id),
    CONSTRAINT fk_assets_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_assets_activated_by FOREIGN KEY (activated_by) REFERENCES users(id),
    CONSTRAINT fk_assets_disposed_by FOREIGN KEY (disposed_by) REFERENCES users(id),
    CONSTRAINT fk_assets_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_assets_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 3. ASSET BOOKS
-- Depreciation book per asset (financial / tax / management)
-- =========================================================
CREATE TABLE asset_books (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    asset_id BIGINT UNSIGNED NOT NULL,

    book_type ENUM(
        'financial',
        'tax',
        'management'
    ) NOT NULL DEFAULT 'financial',

    depreciation_method ENUM(
        'straight_line',
        'written_down_value',
        'manual'
    ) NOT NULL DEFAULT 'straight_line',

    useful_life_months INT NOT NULL DEFAULT 60,
    depreciation_rate DECIMAL(10,6) NOT NULL DEFAULT 0,

    capitalization_value DECIMAL(18,2) NOT NULL DEFAULT 0,
    salvage_value DECIMAL(18,2) NOT NULL DEFAULT 0,

    depreciable_value DECIMAL(18,2) NOT NULL DEFAULT 0,
    accumulated_depreciation DECIMAL(18,2) NOT NULL DEFAULT 0,
    net_book_value DECIMAL(18,2) NOT NULL DEFAULT 0,

    depreciation_start_date DATE NULL,
    depreciation_end_date DATE NULL,
    last_depreciation_date DATE NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_asset_books_asset_book (asset_id, book_type),

    INDEX idx_asset_books_type (book_type),

    CONSTRAINT fk_asset_books_asset FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 4. ASSET DEPRECIATION RUNS
-- Monthly/periodic depreciation processing
-- =========================================================
CREATE TABLE asset_depreciation_runs (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,

    run_no VARCHAR(100) NOT NULL,
    run_date DATE NOT NULL,

    depreciation_from_date DATE NOT NULL,
    depreciation_to_date DATE NOT NULL,

    book_type ENUM(
        'financial',
        'tax',
        'management'
    ) NOT NULL DEFAULT 'financial',

    run_status ENUM(
        'draft',
        'processing',
        'completed',
        'posted',
        'cancelled',
        'failed'
    ) NOT NULL DEFAULT 'draft',

    voucher_id BIGINT UNSIGNED NULL,

    total_assets_processed INT NOT NULL DEFAULT 0,
    total_depreciation_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    notes TEXT NULL,
    error_message TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    posted_by BIGINT UNSIGNED NULL,
    posted_at DATETIME NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_asset_depreciation_runs_company_no (company_id, run_no),

    INDEX idx_asset_depreciation_runs_date (run_date),
    INDEX idx_asset_depreciation_runs_status (run_status),

    CONSTRAINT fk_asset_depreciation_runs_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_asset_depreciation_runs_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id),
    CONSTRAINT fk_asset_depreciation_runs_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_asset_depreciation_runs_posted_by FOREIGN KEY (posted_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 5. ASSET DEPRECIATION LINES
-- Asset-wise depreciation details per run
-- =========================================================
CREATE TABLE asset_depreciation_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    asset_depreciation_run_id BIGINT UNSIGNED NOT NULL,
    asset_book_id BIGINT UNSIGNED NOT NULL,
    asset_id BIGINT UNSIGNED NOT NULL,

    depreciation_from_date DATE NOT NULL,
    depreciation_to_date DATE NOT NULL,

    opening_book_value DECIMAL(18,2) NOT NULL DEFAULT 0,
    depreciation_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    closing_book_value DECIMAL(18,2) NOT NULL DEFAULT 0,

    accumulated_depreciation_before DECIMAL(18,2) NOT NULL DEFAULT 0,
    accumulated_depreciation_after DECIMAL(18,2) NOT NULL DEFAULT 0,

    line_status ENUM(
        'draft',
        'processed',
        'posted',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    INDEX idx_asset_depreciation_lines_run (asset_depreciation_run_id),
    INDEX idx_asset_depreciation_lines_asset (asset_id),

    CONSTRAINT fk_asset_depreciation_lines_run FOREIGN KEY (asset_depreciation_run_id) REFERENCES asset_depreciation_runs(id) ON DELETE CASCADE,
    CONSTRAINT fk_asset_depreciation_lines_book FOREIGN KEY (asset_book_id) REFERENCES asset_books(id),
    CONSTRAINT fk_asset_depreciation_lines_asset FOREIGN KEY (asset_id) REFERENCES assets(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 6. ASSET TRANSFERS
-- Movement of assets between branch/location/department/user
-- =========================================================
CREATE TABLE asset_transfers (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,

    transfer_no VARCHAR(100) NOT NULL,
    transfer_date DATE NOT NULL,

    transfer_reason ENUM(
        'location_change',
        'department_change',
        'employee_assignment',
        'branch_transfer',
        'repair_movement',
        'other'
    ) NOT NULL DEFAULT 'location_change',

    from_branch_id BIGINT UNSIGNED NULL,
    to_branch_id BIGINT UNSIGNED NULL,

    from_location_id BIGINT UNSIGNED NULL,
    to_location_id BIGINT UNSIGNED NULL,

    from_department_name VARCHAR(100) NULL,
    to_department_name VARCHAR(100) NULL,

    from_employee_name VARCHAR(255) NULL,
    to_employee_name VARCHAR(255) NULL,

    transfer_status ENUM(
        'draft',
        'approved',
        'completed',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    voucher_id BIGINT UNSIGNED NULL,

    remarks TEXT NULL,

    approved_by BIGINT UNSIGNED NULL,
    approved_at DATETIME NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_asset_transfers_company_no (company_id, transfer_no),

    INDEX idx_asset_transfers_date (transfer_date),
    INDEX idx_asset_transfers_status (transfer_status),

    CONSTRAINT fk_asset_transfers_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_asset_transfers_from_branch FOREIGN KEY (from_branch_id) REFERENCES branches(id),
    CONSTRAINT fk_asset_transfers_to_branch FOREIGN KEY (to_branch_id) REFERENCES branches(id),
    CONSTRAINT fk_asset_transfers_from_location FOREIGN KEY (from_location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_asset_transfers_to_location FOREIGN KEY (to_location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_asset_transfers_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id),
    CONSTRAINT fk_asset_transfers_approved_by FOREIGN KEY (approved_by) REFERENCES users(id),
    CONSTRAINT fk_asset_transfers_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_asset_transfers_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE asset_transfer_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    asset_transfer_id BIGINT UNSIGNED NOT NULL,
    line_no INT NOT NULL,

    asset_id BIGINT UNSIGNED NOT NULL,

    from_branch_id BIGINT UNSIGNED NULL,
    to_branch_id BIGINT UNSIGNED NULL,

    from_location_id BIGINT UNSIGNED NULL,
    to_location_id BIGINT UNSIGNED NULL,

    from_department_name VARCHAR(100) NULL,
    to_department_name VARCHAR(100) NULL,

    from_employee_name VARCHAR(255) NULL,
    to_employee_name VARCHAR(255) NULL,

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_asset_transfer_lines_doc_line (asset_transfer_id, line_no),

    INDEX idx_asset_transfer_lines_asset (asset_id),

    CONSTRAINT fk_asset_transfer_lines_doc FOREIGN KEY (asset_transfer_id) REFERENCES asset_transfers(id) ON DELETE CASCADE,
    CONSTRAINT fk_asset_transfer_lines_asset FOREIGN KEY (asset_id) REFERENCES assets(id),
    CONSTRAINT fk_asset_transfer_lines_from_branch FOREIGN KEY (from_branch_id) REFERENCES branches(id),
    CONSTRAINT fk_asset_transfer_lines_to_branch FOREIGN KEY (to_branch_id) REFERENCES branches(id),
    CONSTRAINT fk_asset_transfer_lines_from_location FOREIGN KEY (from_location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_asset_transfer_lines_to_location FOREIGN KEY (to_location_id) REFERENCES business_locations(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 7. ASSET DISPOSALS
-- Sale / scrap / write-off / retirement
-- =========================================================
CREATE TABLE asset_disposals (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    asset_id BIGINT UNSIGNED NOT NULL,

    disposal_no VARCHAR(100) NOT NULL,
    disposal_date DATE NOT NULL,

    disposal_type ENUM(
        'sale',
        'scrap',
        'write_off',
        'retirement',
        'loss',
        'theft'
    ) NOT NULL DEFAULT 'sale',

    sale_party_id BIGINT UNSIGNED NULL,
    sales_invoice_id BIGINT UNSIGNED NULL,

    disposal_value DECIMAL(18,2) NOT NULL DEFAULT 0,
    disposal_expense DECIMAL(18,2) NOT NULL DEFAULT 0,

    book_value_at_disposal DECIMAL(18,2) NOT NULL DEFAULT 0,
    gain_or_loss_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    disposal_status ENUM(
        'draft',
        'approved',
        'posted',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    voucher_id BIGINT UNSIGNED NULL,

    remarks TEXT NULL,

    approved_by BIGINT UNSIGNED NULL,
    approved_at DATETIME NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_asset_disposals_asset_no (asset_id, disposal_no),

    INDEX idx_asset_disposals_date (disposal_date),
    INDEX idx_asset_disposals_status (disposal_status),

    CONSTRAINT fk_asset_disposals_asset FOREIGN KEY (asset_id) REFERENCES assets(id),
    CONSTRAINT fk_asset_disposals_sale_party FOREIGN KEY (sale_party_id) REFERENCES parties(id),
    CONSTRAINT fk_asset_disposals_sales_invoice FOREIGN KEY (sales_invoice_id) REFERENCES sales_invoices(id),
    CONSTRAINT fk_asset_disposals_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id),
    CONSTRAINT fk_asset_disposals_approved_by FOREIGN KEY (approved_by) REFERENCES users(id),
    CONSTRAINT fk_asset_disposals_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_asset_disposals_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================
-- MODULE 14 : MAINTENANCE / BREAKDOWN / SERVICE / AMC ENGINE
-- ERP FOUNDATION - MySQL 8
-- Depends on MODULE 1A + 1B + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9 + 10 + 11 + 12 + 13
-- =========================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- DROP ORDER
-- =========================================================
DROP TABLE IF EXISTS amc_contract_assets;
DROP TABLE IF EXISTS amc_contracts;
DROP TABLE IF EXISTS asset_downtime_logs;
DROP TABLE IF EXISTS maintenance_work_order_services;
DROP TABLE IF EXISTS maintenance_work_order_spares;
DROP TABLE IF EXISTS maintenance_work_orders;
DROP TABLE IF EXISTS maintenance_requests;
DROP TABLE IF EXISTS maintenance_plan_assets;
DROP TABLE IF EXISTS maintenance_plans;

-- =========================================================
-- 1. MAINTENANCE PLANS
-- Preventive / periodic maintenance scheduling
-- =========================================================
CREATE TABLE maintenance_plans (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,

    plan_code VARCHAR(100) NOT NULL,
    plan_name VARCHAR(255) NOT NULL,

    maintenance_type ENUM(
        'preventive',
        'predictive',
        'periodic',
        'calibration',
        'inspection',
        'cleaning',
        'lubrication',
        'overhaul',
        'other'
    ) NOT NULL DEFAULT 'preventive',

    schedule_basis ENUM(
        'daily',
        'weekly',
        'monthly',
        'quarterly',
        'half_yearly',
        'yearly',
        'running_hours',
        'manual'
    ) NOT NULL DEFAULT 'monthly',

    frequency_value INT NOT NULL DEFAULT 1,

    checklist_notes TEXT NULL,

    is_auto_generate_request TINYINT(1) NOT NULL DEFAULT 1,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_maintenance_plans_company_code (company_id, plan_code),

    INDEX idx_maintenance_plans_type (maintenance_type),

    CONSTRAINT fk_maintenance_plans_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_maintenance_plans_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_maintenance_plans_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE maintenance_plan_assets (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    maintenance_plan_id BIGINT UNSIGNED NOT NULL,
    asset_id BIGINT UNSIGNED NOT NULL,

    last_service_date DATE NULL,
    next_service_due_date DATE NULL,

    running_hours_threshold DECIMAL(18,2) NULL,
    current_running_hours DECIMAL(18,2) NOT NULL DEFAULT 0,

    assigned_vendor_party_id BIGINT UNSIGNED NULL,
    assigned_internal_team VARCHAR(255) NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_maintenance_plan_assets_plan_asset (maintenance_plan_id, asset_id),

    INDEX idx_maintenance_plan_assets_asset (asset_id),
    INDEX idx_maintenance_plan_assets_due_date (next_service_due_date),

    CONSTRAINT fk_maintenance_plan_assets_plan FOREIGN KEY (maintenance_plan_id) REFERENCES maintenance_plans(id) ON DELETE CASCADE,
    CONSTRAINT fk_maintenance_plan_assets_asset FOREIGN KEY (asset_id) REFERENCES assets(id),
    CONSTRAINT fk_maintenance_plan_assets_vendor FOREIGN KEY (assigned_vendor_party_id) REFERENCES parties(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 2. MAINTENANCE REQUESTS
-- Breakdown / preventive / inspection request intake
-- =========================================================
CREATE TABLE maintenance_requests (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NULL,
    location_id BIGINT UNSIGNED NULL,

    request_no VARCHAR(100) NOT NULL,
    request_date DATE NOT NULL,

    asset_id BIGINT UNSIGNED NOT NULL,
    maintenance_plan_id BIGINT UNSIGNED NULL,

    request_type ENUM(
        'breakdown',
        'preventive',
        'inspection',
        'calibration',
        'cleaning',
        'service',
        'other'
    ) NOT NULL DEFAULT 'breakdown',

    priority_level ENUM(
        'low',
        'normal',
        'high',
        'critical'
    ) NOT NULL DEFAULT 'normal',

    issue_title VARCHAR(255) NOT NULL,
    issue_description TEXT NULL,

    requested_by BIGINT UNSIGNED NULL,

    request_status ENUM(
        'draft',
        'open',
        'approved',
        'assigned',
        'in_progress',
        'completed',
        'cancelled',
        'rejected'
    ) NOT NULL DEFAULT 'draft',

    approved_by BIGINT UNSIGNED NULL,
    approved_at DATETIME NULL,

    target_completion_date DATE NULL,

    remarks TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_maintenance_requests_company_no (company_id, request_no),

    INDEX idx_maintenance_requests_asset (asset_id),
    INDEX idx_maintenance_requests_status (request_status),
    INDEX idx_maintenance_requests_priority (priority_level),

    CONSTRAINT fk_maintenance_requests_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_maintenance_requests_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_maintenance_requests_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_maintenance_requests_asset FOREIGN KEY (asset_id) REFERENCES assets(id),
    CONSTRAINT fk_maintenance_requests_plan FOREIGN KEY (maintenance_plan_id) REFERENCES maintenance_plans(id),
    CONSTRAINT fk_maintenance_requests_requested_by FOREIGN KEY (requested_by) REFERENCES users(id),
    CONSTRAINT fk_maintenance_requests_approved_by FOREIGN KEY (approved_by) REFERENCES users(id),
    CONSTRAINT fk_maintenance_requests_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_maintenance_requests_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 3. MAINTENANCE WORK ORDERS
-- Actual execution document
-- =========================================================
CREATE TABLE maintenance_work_orders (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NULL,
    location_id BIGINT UNSIGNED NULL,
    financial_year_id BIGINT UNSIGNED NULL,

    document_series_id BIGINT UNSIGNED NULL,

    work_order_no VARCHAR(100) NOT NULL,
    work_order_date DATE NOT NULL,

    maintenance_request_id BIGINT UNSIGNED NULL,
    asset_id BIGINT UNSIGNED NOT NULL,
    maintenance_plan_id BIGINT UNSIGNED NULL,

    work_order_type ENUM(
        'breakdown',
        'preventive',
        'inspection',
        'calibration',
        'service',
        'overhaul',
        'other'
    ) NOT NULL DEFAULT 'breakdown',

    execution_mode ENUM(
        'internal',
        'external_vendor',
        'amc',
        'mixed'
    ) NOT NULL DEFAULT 'internal',

    vendor_party_id BIGINT UNSIGNED NULL,

    assigned_technician VARCHAR(255) NULL,
    assigned_team VARCHAR(255) NULL,

    work_order_status ENUM(
        'draft',
        'approved',
        'assigned',
        'in_progress',
        'waiting_parts',
        'waiting_vendor',
        'completed',
        'closed',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    fault_description TEXT NULL,
    action_taken TEXT NULL,
    resolution_summary TEXT NULL,

    planned_start_datetime DATETIME NULL,
    planned_end_datetime DATETIME NULL,
    actual_start_datetime DATETIME NULL,
    actual_end_datetime DATETIME NULL,

    downtime_minutes DECIMAL(18,2) NOT NULL DEFAULT 0,
    labor_cost DECIMAL(18,2) NOT NULL DEFAULT 0,
    spare_cost DECIMAL(18,2) NOT NULL DEFAULT 0,
    external_service_cost DECIMAL(18,2) NOT NULL DEFAULT 0,
    other_cost DECIMAL(18,2) NOT NULL DEFAULT 0,
    total_cost DECIMAL(18,2) NOT NULL DEFAULT 0,
    voucher_id BIGINT UNSIGNED NULL,

    remarks TEXT NULL,

    approved_by BIGINT UNSIGNED NULL,
    approved_at DATETIME NULL,
    closed_by BIGINT UNSIGNED NULL,
    closed_at DATETIME NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_maintenance_work_orders_company_no (company_id, work_order_no),

    INDEX idx_maintenance_work_orders_asset (asset_id),
    INDEX idx_maintenance_work_orders_status (work_order_status),
    INDEX idx_maintenance_work_orders_vendor (vendor_party_id),

    CONSTRAINT fk_maintenance_work_orders_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_maintenance_work_orders_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_maintenance_work_orders_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_maintenance_work_orders_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_maintenance_work_orders_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_maintenance_work_orders_request FOREIGN KEY (maintenance_request_id) REFERENCES maintenance_requests(id),
    CONSTRAINT fk_maintenance_work_orders_asset FOREIGN KEY (asset_id) REFERENCES assets(id),
    CONSTRAINT fk_maintenance_work_orders_plan FOREIGN KEY (maintenance_plan_id) REFERENCES maintenance_plans(id),
    CONSTRAINT fk_maintenance_work_orders_vendor FOREIGN KEY (vendor_party_id) REFERENCES parties(id),
    CONSTRAINT fk_maintenance_work_orders_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id),
    CONSTRAINT fk_maintenance_work_orders_approved_by FOREIGN KEY (approved_by) REFERENCES users(id),
    CONSTRAINT fk_maintenance_work_orders_closed_by FOREIGN KEY (closed_by) REFERENCES users(id),
    CONSTRAINT fk_maintenance_work_orders_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_maintenance_work_orders_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 4. WORK ORDER SPARES
-- Spare parts / consumables used during maintenance
-- =========================================================
CREATE TABLE maintenance_work_order_spares (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    maintenance_work_order_id BIGINT UNSIGNED NOT NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    uom_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NULL,

    batch_id BIGINT UNSIGNED NULL,
    serial_id BIGINT UNSIGNED NULL,

    required_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    issued_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    consumed_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    returned_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    unit_cost DECIMAL(18,4) NOT NULL DEFAULT 0,
    total_cost DECIMAL(18,2) NOT NULL DEFAULT 0,

    issue_document_type VARCHAR(50) NULL,
    issue_document_id BIGINT UNSIGNED NULL,

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_maintenance_work_order_spares_doc_line (maintenance_work_order_id, line_no),

    INDEX idx_maintenance_work_order_spares_item (item_id),

    CONSTRAINT fk_maintenance_work_order_spares_doc FOREIGN KEY (maintenance_work_order_id) REFERENCES maintenance_work_orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_maintenance_work_order_spares_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_maintenance_work_order_spares_uom FOREIGN KEY (uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_maintenance_work_order_spares_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_maintenance_work_order_spares_batch FOREIGN KEY (batch_id) REFERENCES stock_batches(id),
    CONSTRAINT fk_maintenance_work_order_spares_serial FOREIGN KEY (serial_id) REFERENCES stock_serials(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 5. WORK ORDER SERVICES
-- External labor / vendor service / AMC service entries
-- =========================================================
CREATE TABLE maintenance_work_order_services (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    maintenance_work_order_id BIGINT UNSIGNED NOT NULL,
    line_no INT NOT NULL,

    service_description VARCHAR(255) NOT NULL,

    vendor_party_id BIGINT UNSIGNED NULL,
    purchase_invoice_id BIGINT UNSIGNED NULL,

    qty DECIMAL(18,6) NOT NULL DEFAULT 1,
    rate DECIMAL(18,4) NOT NULL DEFAULT 0,
    amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    tax_code_id BIGINT UNSIGNED NULL,
    tax_percent DECIMAL(8,4) NOT NULL DEFAULT 0,
    tax_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    line_total DECIMAL(18,2) NOT NULL DEFAULT 0,

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_maintenance_work_order_services_doc_line (maintenance_work_order_id, line_no),

    CONSTRAINT fk_maintenance_work_order_services_doc FOREIGN KEY (maintenance_work_order_id) REFERENCES maintenance_work_orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_maintenance_work_order_services_vendor FOREIGN KEY (vendor_party_id) REFERENCES parties(id),
    CONSTRAINT fk_maintenance_work_order_services_purchase_invoice FOREIGN KEY (purchase_invoice_id) REFERENCES purchase_invoices(id),
    CONSTRAINT fk_maintenance_work_order_services_tax_code FOREIGN KEY (tax_code_id) REFERENCES tax_codes(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 6. ASSET DOWNTIME LOGS
-- Detailed downtime tracking
-- =========================================================
CREATE TABLE asset_downtime_logs (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    asset_id BIGINT UNSIGNED NOT NULL,
    maintenance_work_order_id BIGINT UNSIGNED NULL,

    downtime_reason ENUM(
        'breakdown',
        'planned_maintenance',
        'inspection',
        'power_failure',
        'operator_issue',
        'spare_waiting',
        'vendor_waiting',
        'other'
    ) NOT NULL DEFAULT 'breakdown',

    downtime_start DATETIME NOT NULL,
    downtime_end DATETIME NULL,

    downtime_minutes DECIMAL(18,2) NOT NULL DEFAULT 0,

    production_impact_notes TEXT NULL,

    is_planned TINYINT(1) NOT NULL DEFAULT 0,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    INDEX idx_asset_downtime_logs_asset (asset_id),
    INDEX idx_asset_downtime_logs_start (downtime_start),

    CONSTRAINT fk_asset_downtime_logs_asset FOREIGN KEY (asset_id) REFERENCES assets(id),
    CONSTRAINT fk_asset_downtime_logs_work_order FOREIGN KEY (maintenance_work_order_id) REFERENCES maintenance_work_orders(id) ON DELETE SET NULL,
    CONSTRAINT fk_asset_downtime_logs_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_asset_downtime_logs_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 7. AMC CONTRACTS
-- Annual / periodic service agreements
-- =========================================================
CREATE TABLE amc_contracts (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,

    contract_no VARCHAR(100) NOT NULL,
    contract_date DATE NOT NULL,

    vendor_party_id BIGINT UNSIGNED NOT NULL,

    contract_type ENUM(
        'amc',
        'cmc',
        'service_contract',
        'warranty_extension',
        'other'
    ) NOT NULL DEFAULT 'amc',

    contract_start_date DATE NOT NULL,
    contract_end_date DATE NOT NULL,

    coverage_scope ENUM(
        'labor_only',
        'parts_only',
        'labor_and_parts',
        'inspection_only',
        'custom'
    ) NOT NULL DEFAULT 'labor_only',

    visit_frequency ENUM(
        'monthly',
        'quarterly',
        'half_yearly',
        'yearly',
        'on_call',
        'custom'
    ) NOT NULL DEFAULT 'quarterly',

    contract_value DECIMAL(18,2) NOT NULL DEFAULT 0,
    tax_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    total_value DECIMAL(18,2) NOT NULL DEFAULT 0,

    response_time_hours DECIMAL(18,2) NULL,
    resolution_time_hours DECIMAL(18,2) NULL,

    contract_status ENUM(
        'draft',
        'active',
        'expired',
        'terminated',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    remarks TEXT NULL,

    approved_by BIGINT UNSIGNED NULL,
    approved_at DATETIME NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_amc_contracts_company_no (company_id, contract_no),

    INDEX idx_amc_contracts_vendor (vendor_party_id),
    INDEX idx_amc_contracts_status (contract_status),
    INDEX idx_amc_contracts_end_date (contract_end_date),

    CONSTRAINT fk_amc_contracts_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_amc_contracts_vendor FOREIGN KEY (vendor_party_id) REFERENCES parties(id),
    CONSTRAINT fk_amc_contracts_approved_by FOREIGN KEY (approved_by) REFERENCES users(id),
    CONSTRAINT fk_amc_contracts_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_amc_contracts_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE amc_contract_assets (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    amc_contract_id BIGINT UNSIGNED NOT NULL,
    asset_id BIGINT UNSIGNED NOT NULL,

    coverage_notes VARCHAR(500) NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_amc_contract_assets_contract_asset (amc_contract_id, asset_id),

    INDEX idx_amc_contract_assets_asset (asset_id),

    CONSTRAINT fk_amc_contract_assets_contract FOREIGN KEY (amc_contract_id) REFERENCES amc_contracts(id) ON DELETE CASCADE,
    CONSTRAINT fk_amc_contract_assets_asset FOREIGN KEY (asset_id) REFERENCES assets(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================
-- MODULE 15 : SERVICE / INSTALLATION / CUSTOMER SUPPORT / AFTER-SALES ENGINE
-- ERP FOUNDATION - MySQL 8
-- Depends on MODULE 1A + 1B + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9 + 10 + 11 + 12 + 13 + 14
-- =========================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- DROP ORDER
-- =========================================================
DROP TABLE IF EXISTS service_feedbacks;
DROP TABLE IF EXISTS service_visit_logs;
DROP TABLE IF EXISTS service_work_order_services;
DROP TABLE IF EXISTS service_work_order_spares;
DROP TABLE IF EXISTS service_work_orders;
DROP TABLE IF EXISTS service_ticket_activities;
DROP TABLE IF EXISTS service_tickets;
DROP TABLE IF EXISTS service_contract_assets;
DROP TABLE IF EXISTS service_contracts;

-- =========================================================
-- 1. SERVICE CONTRACTS
-- Warranty / AMC / paid support / installation coverage
-- =========================================================
CREATE TABLE service_contracts (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,

    contract_no VARCHAR(100) NOT NULL,
    contract_date DATE NOT NULL,

    customer_party_id BIGINT UNSIGNED NOT NULL,

    contract_type ENUM(
        'warranty',
        'amc',
        'cmc',
        'installation_support',
        'paid_support',
        'extended_warranty',
        'other'
    ) NOT NULL DEFAULT 'warranty',

    contract_start_date DATE NOT NULL,
    contract_end_date DATE NULL,

    coverage_scope ENUM(
        'labor_only',
        'parts_only',
        'labor_and_parts',
        'inspection_only',
        'installation_only',
        'custom'
    ) NOT NULL DEFAULT 'labor_only',

    visit_frequency ENUM(
        'one_time',
        'monthly',
        'quarterly',
        'half_yearly',
        'yearly',
        'on_call',
        'custom'
    ) NOT NULL DEFAULT 'on_call',

    response_time_hours DECIMAL(18,2) NULL,
    resolution_time_hours DECIMAL(18,2) NULL,

    contract_value DECIMAL(18,2) NOT NULL DEFAULT 0,
    tax_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    total_value DECIMAL(18,2) NOT NULL DEFAULT 0,

    sales_invoice_id BIGINT UNSIGNED NULL,

    contract_status ENUM(
        'draft',
        'active',
        'expired',
        'terminated',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    notes TEXT NULL,

    approved_by BIGINT UNSIGNED NULL,
    approved_at DATETIME NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_service_contracts_company_no (company_id, contract_no),

    INDEX idx_service_contracts_customer (customer_party_id),
    INDEX idx_service_contracts_status (contract_status),
    INDEX idx_service_contracts_end_date (contract_end_date),

    CONSTRAINT fk_service_contracts_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_service_contracts_customer FOREIGN KEY (customer_party_id) REFERENCES parties(id),
    CONSTRAINT fk_service_contracts_sales_invoice FOREIGN KEY (sales_invoice_id) REFERENCES sales_invoices(id),
    CONSTRAINT fk_service_contracts_approved_by FOREIGN KEY (approved_by) REFERENCES users(id),
    CONSTRAINT fk_service_contracts_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_service_contracts_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE service_contract_assets (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    service_contract_id BIGINT UNSIGNED NOT NULL,
    asset_id BIGINT UNSIGNED NULL,
    item_id BIGINT UNSIGNED NULL,
    serial_id BIGINT UNSIGNED NULL,

    serial_no VARCHAR(100) NULL,
    installation_date DATE NULL,
    warranty_start_date DATE NULL,
    warranty_end_date DATE NULL,

    customer_site_address TEXT NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    INDEX idx_service_contract_assets_asset (asset_id),
    INDEX idx_service_contract_assets_item (item_id),
    INDEX idx_service_contract_assets_serial (serial_id),

    CONSTRAINT fk_service_contract_assets_contract FOREIGN KEY (service_contract_id) REFERENCES service_contracts(id) ON DELETE CASCADE,
    CONSTRAINT fk_service_contract_assets_asset FOREIGN KEY (asset_id) REFERENCES assets(id),
    CONSTRAINT fk_service_contract_assets_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_service_contract_assets_serial FOREIGN KEY (serial_id) REFERENCES stock_serials(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 2. SERVICE TICKETS
-- Customer complaint / support / installation request
-- =========================================================
CREATE TABLE service_tickets (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NULL,
    location_id BIGINT UNSIGNED NULL,
    financial_year_id BIGINT UNSIGNED NULL,

    document_series_id BIGINT UNSIGNED NULL,

    ticket_no VARCHAR(100) NOT NULL,
    ticket_date DATE NOT NULL,

    customer_party_id BIGINT UNSIGNED NOT NULL,
    contact_person_name VARCHAR(255) NULL,
    contact_mobile VARCHAR(50) NULL,
    contact_email VARCHAR(255) NULL,

    service_contract_id BIGINT UNSIGNED NULL,
    service_contract_asset_id BIGINT UNSIGNED NULL,

    asset_id BIGINT UNSIGNED NULL,
    item_id BIGINT UNSIGNED NULL,
    serial_id BIGINT UNSIGNED NULL,
    serial_no VARCHAR(100) NULL,

    ticket_type ENUM(
        'complaint',
        'installation',
        'demo',
        'preventive_service',
        'breakdown',
        'warranty_claim',
        'amc_visit',
        'paid_service',
        'other'
    ) NOT NULL DEFAULT 'complaint',

    priority_level ENUM(
        'low',
        'normal',
        'high',
        'critical'
    ) NOT NULL DEFAULT 'normal',

    issue_title VARCHAR(255) NOT NULL,
    issue_description TEXT NULL,

    ticket_source ENUM(
        'manual',
        'phone',
        'email',
        'website',
        'whatsapp',
        'sales_team',
        'system_generated'
    ) NOT NULL DEFAULT 'manual',

    service_mode ENUM(
        'onsite',
        'remote',
        'pickup',
        'workshop',
        'hybrid'
    ) NOT NULL DEFAULT 'onsite',

    coverage_type ENUM(
        'under_warranty',
        'under_amc',
        'chargeable',
        'free_service',
        'to_be_decided'
    ) NOT NULL DEFAULT 'to_be_decided',

    target_response_datetime DATETIME NULL,
    target_resolution_datetime DATETIME NULL,

    ticket_status ENUM(
        'draft',
        'open',
        'assigned',
        'in_progress',
        'waiting_customer',
        'waiting_parts',
        'waiting_internal',
        'resolved',
        'closed',
        'cancelled',
        'rejected'
    ) NOT NULL DEFAULT 'draft',

    assigned_to_user_id BIGINT UNSIGNED NULL,

    customer_site_address TEXT NULL,

    closed_by BIGINT UNSIGNED NULL,
    closed_at DATETIME NULL,

    notes TEXT NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_service_tickets_company_no (company_id, ticket_no),

    INDEX idx_service_tickets_customer (customer_party_id),
    INDEX idx_service_tickets_status (ticket_status),
    INDEX idx_service_tickets_priority (priority_level),
    INDEX idx_service_tickets_assigned_to (assigned_to_user_id),
    INDEX idx_service_tickets_serial (serial_id),

    CONSTRAINT fk_service_tickets_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_service_tickets_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_service_tickets_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_service_tickets_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_service_tickets_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_service_tickets_customer FOREIGN KEY (customer_party_id) REFERENCES parties(id),
    CONSTRAINT fk_service_tickets_service_contract FOREIGN KEY (service_contract_id) REFERENCES service_contracts(id),
    CONSTRAINT fk_service_tickets_service_contract_asset FOREIGN KEY (service_contract_asset_id) REFERENCES service_contract_assets(id),
    CONSTRAINT fk_service_tickets_asset FOREIGN KEY (asset_id) REFERENCES assets(id),
    CONSTRAINT fk_service_tickets_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_service_tickets_serial FOREIGN KEY (serial_id) REFERENCES stock_serials(id),
    CONSTRAINT fk_service_tickets_assigned_to FOREIGN KEY (assigned_to_user_id) REFERENCES users(id),
    CONSTRAINT fk_service_tickets_closed_by FOREIGN KEY (closed_by) REFERENCES users(id),
    CONSTRAINT fk_service_tickets_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_service_tickets_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 3. SERVICE TICKET ACTIVITIES
-- Communication / status updates / internal notes
-- =========================================================
CREATE TABLE service_ticket_activities (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    service_ticket_id BIGINT UNSIGNED NOT NULL,

    activity_type ENUM(
        'status_update',
        'customer_call',
        'customer_visit',
        'remote_support',
        'internal_note',
        'technician_note',
        'part_request',
        'approval_note',
        'closure_note',
        'other'
    ) NOT NULL DEFAULT 'status_update',

    activity_datetime DATETIME NOT NULL,

    activity_notes TEXT NOT NULL,

    next_followup_datetime DATETIME NULL,

    visibility ENUM(
        'internal',
        'customer_visible'
    ) NOT NULL DEFAULT 'internal',

    created_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    INDEX idx_service_ticket_activities_ticket (service_ticket_id),
    INDEX idx_service_ticket_activities_datetime (activity_datetime),

    CONSTRAINT fk_service_ticket_activities_ticket FOREIGN KEY (service_ticket_id) REFERENCES service_tickets(id) ON DELETE CASCADE,
    CONSTRAINT fk_service_ticket_activities_created_by FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 4. SERVICE WORK ORDERS
-- Technician execution document
-- =========================================================
CREATE TABLE service_work_orders (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    company_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NULL,
    location_id BIGINT UNSIGNED NULL,
    financial_year_id BIGINT UNSIGNED NULL,

    document_series_id BIGINT UNSIGNED NULL,

    work_order_no VARCHAR(100) NOT NULL,
    work_order_date DATE NOT NULL,

    service_ticket_id BIGINT UNSIGNED NOT NULL,
    voucher_id BIGINT UNSIGNED NULL,

    customer_party_id BIGINT UNSIGNED NOT NULL,
    asset_id BIGINT UNSIGNED NULL,
    item_id BIGINT UNSIGNED NULL,
    serial_id BIGINT UNSIGNED NULL,
    serial_no VARCHAR(100) NULL,

    work_order_type ENUM(
        'installation',
        'complaint_resolution',
        'breakdown_service',
        'warranty_service',
        'amc_service',
        'paid_service',
        'inspection',
        'demo',
        'other'
    ) NOT NULL DEFAULT 'complaint_resolution',

    execution_mode ENUM(
        'onsite',
        'remote',
        'pickup',
        'workshop',
        'hybrid'
    ) NOT NULL DEFAULT 'onsite',

    technician_user_id BIGINT UNSIGNED NULL,
    vendor_party_id BIGINT UNSIGNED NULL,

    work_order_status ENUM(
        'draft',
        'assigned',
        'in_progress',
        'waiting_parts',
        'waiting_customer',
        'completed',
        'closed',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',

    diagnosis_notes TEXT NULL,
    action_taken TEXT NULL,
    resolution_summary TEXT NULL,

    customer_site_address TEXT NULL,

    check_in_datetime DATETIME NULL,
    check_out_datetime DATETIME NULL,

    labor_cost DECIMAL(18,2) NOT NULL DEFAULT 0,
    spare_cost DECIMAL(18,2) NOT NULL DEFAULT 0,
    external_service_cost DECIMAL(18,2) NOT NULL DEFAULT 0,
    travel_cost DECIMAL(18,2) NOT NULL DEFAULT 0,
    other_cost DECIMAL(18,2) NOT NULL DEFAULT 0,
    total_cost DECIMAL(18,2) NOT NULL DEFAULT 0,

    billable_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    remarks TEXT NULL,

    completed_by BIGINT UNSIGNED NULL,
    completed_at DATETIME NULL,
    closed_by BIGINT UNSIGNED NULL,
    closed_at DATETIME NULL,

    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_service_work_orders_company_no (company_id, work_order_no),

    INDEX idx_service_work_orders_ticket (service_ticket_id),
    INDEX idx_service_work_orders_customer (customer_party_id),
    INDEX idx_service_work_orders_status (work_order_status),
    INDEX idx_service_work_orders_technician (technician_user_id),

    CONSTRAINT fk_service_work_orders_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_service_work_orders_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
    CONSTRAINT fk_service_work_orders_location FOREIGN KEY (location_id) REFERENCES business_locations(id),
    CONSTRAINT fk_service_work_orders_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_service_work_orders_document_series FOREIGN KEY (document_series_id) REFERENCES document_series(id),
    CONSTRAINT fk_service_work_orders_ticket FOREIGN KEY (service_ticket_id) REFERENCES service_tickets(id),
    CONSTRAINT fk_service_work_orders_customer FOREIGN KEY (customer_party_id) REFERENCES parties(id),
    CONSTRAINT fk_service_work_orders_asset FOREIGN KEY (asset_id) REFERENCES assets(id),
    CONSTRAINT fk_service_work_orders_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_service_work_orders_serial FOREIGN KEY (serial_id) REFERENCES stock_serials(id),
    CONSTRAINT fk_service_work_orders_technician FOREIGN KEY (technician_user_id) REFERENCES users(id),
    CONSTRAINT fk_service_work_orders_vendor FOREIGN KEY (vendor_party_id) REFERENCES parties(id),
    CONSTRAINT fk_service_work_orders_completed_by FOREIGN KEY (completed_by) REFERENCES users(id),
    CONSTRAINT fk_service_work_orders_closed_by FOREIGN KEY (closed_by) REFERENCES users(id),
    CONSTRAINT fk_service_work_orders_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_service_work_orders_updated_by FOREIGN KEY (updated_by) REFERENCES users(id),
    CONSTRAINT fk_service_work_orders_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 5. SERVICE WORK ORDER SPARES
-- Customer-site spare parts / replacements
-- =========================================================
CREATE TABLE service_work_order_spares (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    service_work_order_id BIGINT UNSIGNED NOT NULL,
    line_no INT NOT NULL,

    item_id BIGINT UNSIGNED NOT NULL,
    uom_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NULL,

    batch_id BIGINT UNSIGNED NULL,
    serial_id BIGINT UNSIGNED NULL,

    required_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    issued_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    consumed_qty DECIMAL(18,6) NOT NULL DEFAULT 0,
    returned_qty DECIMAL(18,6) NOT NULL DEFAULT 0,

    warranty_covered TINYINT(1) NOT NULL DEFAULT 0,
    chargeable_to_customer TINYINT(1) NOT NULL DEFAULT 1,

    unit_cost DECIMAL(18,4) NOT NULL DEFAULT 0,
    total_cost DECIMAL(18,2) NOT NULL DEFAULT 0,

    billable_rate DECIMAL(18,4) NOT NULL DEFAULT 0,
    billable_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    issue_document_type VARCHAR(50) NULL,
    issue_document_id BIGINT UNSIGNED NULL,

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_service_work_order_spares_doc_line (service_work_order_id, line_no),

    INDEX idx_service_work_order_spares_item (item_id),

    CONSTRAINT fk_service_work_order_spares_doc FOREIGN KEY (service_work_order_id) REFERENCES service_work_orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_service_work_order_spares_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT fk_service_work_order_spares_uom FOREIGN KEY (uom_id) REFERENCES uoms(id),
    CONSTRAINT fk_service_work_order_spares_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    CONSTRAINT fk_service_work_order_spares_batch FOREIGN KEY (batch_id) REFERENCES stock_batches(id),
    CONSTRAINT fk_service_work_order_spares_serial FOREIGN KEY (serial_id) REFERENCES stock_serials(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 6. SERVICE WORK ORDER SERVICES
-- Labor / travel / vendor service / charge lines
-- =========================================================
CREATE TABLE service_work_order_services (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    service_work_order_id BIGINT UNSIGNED NOT NULL,
    line_no INT NOT NULL,

    service_description VARCHAR(255) NOT NULL,

    charge_type ENUM(
        'labor',
        'installation',
        'inspection',
        'travel',
        'vendor_service',
        'remote_support',
        'other'
    ) NOT NULL DEFAULT 'labor',

    vendor_party_id BIGINT UNSIGNED NULL,
    purchase_invoice_id BIGINT UNSIGNED NULL,

    qty DECIMAL(18,6) NOT NULL DEFAULT 1,
    rate DECIMAL(18,4) NOT NULL DEFAULT 0,
    amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    warranty_covered TINYINT(1) NOT NULL DEFAULT 0,
    chargeable_to_customer TINYINT(1) NOT NULL DEFAULT 1,

    tax_code_id BIGINT UNSIGNED NULL,
    tax_percent DECIMAL(8,4) NOT NULL DEFAULT 0,
    tax_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

    line_total DECIMAL(18,2) NOT NULL DEFAULT 0,

    remarks VARCHAR(500) NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_service_work_order_services_doc_line (service_work_order_id, line_no),

    CONSTRAINT fk_service_work_order_services_doc FOREIGN KEY (service_work_order_id) REFERENCES service_work_orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_service_work_order_services_vendor FOREIGN KEY (vendor_party_id) REFERENCES parties(id),
    CONSTRAINT fk_service_work_order_services_purchase_invoice FOREIGN KEY (purchase_invoice_id) REFERENCES purchase_invoices(id),
    CONSTRAINT fk_service_work_order_services_tax_code FOREIGN KEY (tax_code_id) REFERENCES tax_codes(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 7. SERVICE VISIT LOGS
-- Technician movement / customer site visit tracking
-- =========================================================
CREATE TABLE service_visit_logs (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    service_work_order_id BIGINT UNSIGNED NOT NULL,

    visit_date DATE NOT NULL,
    visit_type ENUM(
        'onsite',
        'pickup',
        'delivery',
        'inspection',
        'installation',
        'remote_followup'
    ) NOT NULL DEFAULT 'onsite',

    check_in_datetime DATETIME NULL,
    check_out_datetime DATETIME NULL,

    travel_distance_km DECIMAL(18,2) NULL,
    travel_expense DECIMAL(18,2) NOT NULL DEFAULT 0,

    visit_notes TEXT NULL,

    customer_signature_name VARCHAR(255) NULL,
    customer_confirmation_status ENUM(
        'pending',
        'confirmed',
        'disputed'
    ) NOT NULL DEFAULT 'pending',

    created_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    INDEX idx_service_visit_logs_work_order (service_work_order_id),
    INDEX idx_service_visit_logs_visit_date (visit_date),

    CONSTRAINT fk_service_visit_logs_work_order FOREIGN KEY (service_work_order_id) REFERENCES service_work_orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_service_visit_logs_created_by FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 8. SERVICE FEEDBACKS
-- Customer closure feedback / satisfaction capture
-- =========================================================
CREATE TABLE service_feedbacks (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    service_ticket_id BIGINT UNSIGNED NOT NULL,
    service_work_order_id BIGINT UNSIGNED NULL,

    feedback_date DATE NOT NULL,

    rating_overall INT NULL,
    rating_technician INT NULL,
    rating_resolution INT NULL,
    rating_timeliness INT NULL,

    customer_feedback TEXT NULL,

    resolution_confirmed TINYINT(1) NOT NULL DEFAULT 0,
    revisit_required TINYINT(1) NOT NULL DEFAULT 0,

    created_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    INDEX idx_service_feedbacks_ticket (service_ticket_id),

    CONSTRAINT fk_service_feedbacks_ticket FOREIGN KEY (service_ticket_id) REFERENCES service_tickets(id) ON DELETE CASCADE,
    CONSTRAINT fk_service_feedbacks_work_order FOREIGN KEY (service_work_order_id) REFERENCES service_work_orders(id) ON DELETE SET NULL,
    CONSTRAINT fk_service_feedbacks_created_by FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================
-- MODULE 16 : CRM / LEAD / ENQUIRY / FOLLOW-UP / OPPORTUNITY ENGINE
-- =========================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- DROP ORDER
-- =========================================================
DROP TABLE IF EXISTS crm_opportunity_products;
DROP TABLE IF EXISTS crm_opportunities;
DROP TABLE IF EXISTS crm_followups;
DROP TABLE IF EXISTS crm_enquiry_lines;
DROP TABLE IF EXISTS crm_enquiries;
DROP TABLE IF EXISTS crm_lead_activities;
DROP TABLE IF EXISTS crm_leads;
DROP TABLE IF EXISTS crm_stages;
DROP TABLE IF EXISTS crm_sources;

-- =========================================================
-- 1. CRM SOURCES
-- =========================================================
CREATE TABLE crm_sources (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    source_name VARCHAR(100) NOT NULL,
    is_active TINYINT(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
INSERT INTO crm_sources (source_name, is_active) VALUES
('Advertisement', 1),
('Walk-in', 1),
('Cold Calling', 1),
('Exhibition', 1),
('Website', 1),
('WhatsApp', 1),
('YouTube', 1),
('Referral', 1),
('IndiaMART', 1),
('Dealer', 1),
('College Seminar', 1),
('Repeat Customer', 1);

-- =========================================================
-- 2. CRM STAGES (PIPELINE)
-- =========================================================
CREATE TABLE crm_stages (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    stage_name VARCHAR(100) NOT NULL,
    stage_type ENUM(
        'lead',
        'enquiry',
        'opportunity',
        'converted',
        'closed_won',
        'closed_lost'
    ) NOT NULL,

    sequence_no INT NOT NULL,
    probability_percent DECIMAL(5,2) DEFAULT 0,

    is_default TINYINT(1) DEFAULT 0,
    is_active TINYINT(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO crm_stages (stage_name, stage_type, sequence_no, probability_percent, is_default, is_active) VALUES
('New Enquiry','enquiry',10,10,1,1),
('Contacted','enquiry',20,15,0,1),
('Requirement Gathering','enquiry',30,20,0,1),
('Demo Requested','enquiry',40,25,0,1),
('Quotation Requested','opportunity',50,35,0,1),
('Quotation Sent','opportunity',60,45,0,1),
('Follow-up','opportunity',70,55,0,1),
('Negotiation','opportunity',80,70,0,1),
('Sample Testing','opportunity',90,80,0,1),
('Waiting for Response','opportunity',100,60,0,1);

-- =========================================================
-- 3. CRM LEADS
-- =========================================================
CREATE TABLE crm_leads (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    company_id BIGINT UNSIGNED NOT NULL,

    lead_name VARCHAR(255) NOT NULL,
    company_name VARCHAR(255) NULL,

    mobile VARCHAR(50),
    email VARCHAR(255),

    source_id BIGINT UNSIGNED NULL,

    assigned_to BIGINT UNSIGNED NULL,

    lead_status ENUM(
        'new',
        'in_progress',
        'converted',
        'lost'
    ) DEFAULT 'new',

    remarks TEXT,

    created_by BIGINT UNSIGNED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_crm_leads_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_crm_leads_source FOREIGN KEY (source_id) REFERENCES crm_sources(id),
    CONSTRAINT fk_crm_leads_assigned FOREIGN KEY (assigned_to) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 4. LEAD ACTIVITIES
-- =========================================================
CREATE TABLE crm_lead_activities (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    lead_id BIGINT UNSIGNED NOT NULL,

    activity_type ENUM(
        'call',
        'email',
        'meeting',
        'note',
        'whatsapp'
    ) NOT NULL,

    activity_datetime DATETIME NOT NULL,
    notes TEXT,

    next_followup DATETIME NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',

    created_by BIGINT UNSIGNED,

    CONSTRAINT fk_crm_lead_activities_lead FOREIGN KEY (lead_id) REFERENCES crm_leads(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 5. CRM OPPORTUNITIES (UNIFIED ENQUIRY + OPPORTUNITY PIPELINE)
-- =========================================================
CREATE TABLE crm_opportunities (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    company_id BIGINT UNSIGNED NOT NULL,

    enquiry_no VARCHAR(100),
    enquiry_date DATE,

    lead_id BIGINT UNSIGNED NULL,
    customer_party_id BIGINT UNSIGNED NULL,

    stage_id BIGINT UNSIGNED NULL,

    assigned_to BIGINT UNSIGNED NULL,

    enquiry_status ENUM(
        'open',
        'in_progress',
        'converted',
        'lost'
    ) DEFAULT 'open',

    remarks TEXT,

    opportunity_name VARCHAR(255),
    expected_value DECIMAL(18,2) DEFAULT 0,
    probability_percent DECIMAL(5,2) DEFAULT 0,
    expected_close_date DATE,

    status ENUM(
        'open',
        'won',
        'lost'
    ) DEFAULT 'open',

    CONSTRAINT fk_crm_opportunities_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_crm_opportunities_lead FOREIGN KEY (lead_id) REFERENCES crm_leads(id),
    CONSTRAINT fk_crm_opportunities_customer FOREIGN KEY (customer_party_id) REFERENCES parties(id),
    CONSTRAINT fk_crm_opportunities_stage FOREIGN KEY (stage_id) REFERENCES crm_stages(id),
    CONSTRAINT fk_crm_opportunities_assigned FOREIGN KEY (assigned_to) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 6. PIPELINE LINES
-- =========================================================
CREATE TABLE crm_enquiry_lines (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    enquiry_id BIGINT UNSIGNED NOT NULL,

    item_id BIGINT UNSIGNED,
    description VARCHAR(255),

    qty DECIMAL(18,2),

    CONSTRAINT fk_crm_enquiry_lines_opportunity FOREIGN KEY (enquiry_id) REFERENCES crm_opportunities(id) ON DELETE CASCADE,
    CONSTRAINT fk_crm_enquiry_lines_item FOREIGN KEY (item_id) REFERENCES items(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 7. FOLLOWUPS
-- =========================================================
CREATE TABLE crm_followups (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    enquiry_id BIGINT UNSIGNED,

    followup_date DATETIME,
    notes TEXT,

    next_followup DATETIME,

    assigned_to BIGINT UNSIGNED,

    status ENUM('pending','done','skipped') DEFAULT 'pending',

    CONSTRAINT fk_crm_followups_opportunity FOREIGN KEY (enquiry_id) REFERENCES crm_opportunities(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 8. OPPORTUNITY PRODUCTS
-- =========================================================
CREATE TABLE crm_opportunity_products (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    opportunity_id BIGINT UNSIGNED,

    item_id BIGINT UNSIGNED,
    qty DECIMAL(18,2),
    estimated_price DECIMAL(18,2),

    CONSTRAINT fk_crm_opportunity_products_opportunity FOREIGN KEY (opportunity_id) REFERENCES crm_opportunities(id) ON DELETE CASCADE,
    CONSTRAINT fk_crm_opportunity_products_item FOREIGN KEY (item_id) REFERENCES items(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================
-- MODULE 17 : HR / EMPLOYEE / ATTENDANCE / PAYROLL ENGINE
-- =========================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- DROP ORDER
-- =========================================================
DROP TABLE IF EXISTS payslips;
DROP TABLE IF EXISTS payroll_lines;
DROP TABLE IF EXISTS payroll_runs;
DROP TABLE IF EXISTS leave_requests;
DROP TABLE IF EXISTS leave_types;
DROP TABLE IF EXISTS attendance_records;
DROP TABLE IF EXISTS employee_salary_components;
DROP TABLE IF EXISTS employee_addresses;
DROP TABLE IF EXISTS employee_relations;
DROP TABLE IF EXISTS employee_accounts;
DROP TABLE IF EXISTS employee_salary_structures;
DROP TABLE IF EXISTS employee_accounts;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS designations;
DROP TABLE IF EXISTS departments;

-- =========================================================
-- 1. DEPARTMENTS
-- =========================================================
CREATE TABLE departments (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    is_active TINYINT(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 2. DESIGNATIONS
-- =========================================================
CREATE TABLE designations (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    designation_name VARCHAR(100) NOT NULL,
    is_active TINYINT(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 3. EMPLOYEES
-- =========================================================
CREATE TABLE employees (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    company_id BIGINT UNSIGNED NOT NULL,

    employee_code VARCHAR(50) NOT NULL,
    employee_name VARCHAR(255) NOT NULL,

    department_id BIGINT UNSIGNED,
    designation_id BIGINT UNSIGNED,

    mobile VARCHAR(50),
    email VARCHAR(255),

    joining_date DATE,
    relieving_date DATE,

    employment_type ENUM(
        'permanent',
        'contract',
        'trainee',
        'intern'
    ) DEFAULT 'permanent',

    status ENUM(
        'active',
        'inactive',
        'terminated'
    ) DEFAULT 'active',

    salary_mode ENUM(
        'monthly',
        'daily',
        'hourly'
    ) DEFAULT 'monthly',

    bank_account_no VARCHAR(100),
    ifsc_code VARCHAR(50),
    profile_photo_path VARCHAR(500) NULL,

    esi_no VARCHAR(100) NULL,
    pf_uan_no VARCHAR(100) NULL,
    pf_account_no VARCHAR(100) NULL,

    passport_no VARCHAR(100) NULL,
    passport_issue_date DATE NULL,
    passport_expiry_date DATE NULL,
    passport_place_of_issue VARCHAR(255) NULL,

    personal_insurance_provider VARCHAR(255) NULL,
    personal_insurance_policy_no VARCHAR(100) NULL,
    personal_insurance_amount DECIMAL(18,2) NULL,

    company_insurance_provider VARCHAR(255) NULL,
    company_insurance_policy_no VARCHAR(100) NULL,
    company_insurance_amount DECIMAL(18,2) NULL,

    cost_center_id BIGINT UNSIGNED,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_employees_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_employees_department FOREIGN KEY (department_id) REFERENCES departments(id),
    CONSTRAINT fk_employees_designation FOREIGN KEY (designation_id) REFERENCES designations(id),
    CONSTRAINT fk_employees_cost_center FOREIGN KEY (cost_center_id) REFERENCES cost_centers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE users
    ADD CONSTRAINT fk_users_employee
        FOREIGN KEY (employee_id) REFERENCES employees(id)
        ON DELETE SET NULL ON UPDATE CASCADE;

CREATE TABLE employee_addresses (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    employee_id BIGINT UNSIGNED NOT NULL,
    address_type ENUM('present', 'permanent') NOT NULL DEFAULT 'present',

    address_line1 VARCHAR(255) NULL,
    address_line2 VARCHAR(255) NULL,
    landmark VARCHAR(255) NULL,
    city VARCHAR(100) NULL,
    state_name VARCHAR(100) NULL,
    postal_code VARCHAR(20) NULL,
    country VARCHAR(100) NULL,
    phone_number VARCHAR(50) NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uq_employee_addresses_employee_type (employee_id, address_type),
    CONSTRAINT fk_employee_addresses_employee FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE employee_relations (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    employee_id BIGINT UNSIGNED NOT NULL,
    relation_name VARCHAR(255) NOT NULL,
    age INT NULL,
    phone_number VARCHAR(50) NULL,
    relationship VARCHAR(100) NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_employee_relations_employee (employee_id),
    CONSTRAINT fk_employee_relations_employee FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE employee_accounts (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    employee_id BIGINT UNSIGNED NOT NULL,
    account_id BIGINT UNSIGNED NOT NULL,

    account_purpose ENUM(
        'payable',
        'advance',
        'reimbursement',
        'other'
    ) NOT NULL DEFAULT 'payable',

    is_default TINYINT(1) NOT NULL DEFAULT 1,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uq_employee_accounts_employee_purpose (employee_id, account_purpose),
    UNIQUE KEY uq_employee_accounts_employee_account (employee_id, account_id),
    INDEX idx_employee_accounts_account (account_id),

    CONSTRAINT fk_employee_accounts_employee FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    CONSTRAINT fk_employee_accounts_account FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 4. SALARY STRUCTURE
-- =========================================================
CREATE TABLE employee_salary_structures (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    employee_id BIGINT UNSIGNED NOT NULL,

    effective_from DATE NOT NULL,

    basic_salary DECIMAL(18,2) DEFAULT 0,
    gross_salary DECIMAL(18,2) DEFAULT 0,
    net_salary DECIMAL(18,2) DEFAULT 0,
    ctc_monthly DECIMAL(18,2) NULL COMMENT 'Full monthly CTC incl. employer cost; payroll uses gross if null',

    is_active TINYINT(1) DEFAULT 1,

    CONSTRAINT fk_salary_struct_employee FOREIGN KEY (employee_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- =========================================================
-- 5. SALARY COMPONENTS
-- =========================================================
CREATE TABLE employee_salary_components (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    salary_structure_id BIGINT UNSIGNED,

    component_name VARCHAR(100),
    component_type ENUM('earning','deduction'),

    amount DECIMAL(18,2),
    calculation_basis VARCHAR(32) NOT NULL DEFAULT 'fixed' COMMENT 'fixed, percent_basic, percent_gross, percent_ctc',
    percent_value DECIMAL(9,4) NULL,
    contribution_role VARCHAR(20) NOT NULL DEFAULT 'employee' COMMENT 'employee=payslip, employer=CTC cost',

    CONSTRAINT fk_salary_components_struct FOREIGN KEY (salary_structure_id) REFERENCES employee_salary_structures(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 5b. HR STATUTORY (ESI / PF / PT) - company profiles
-- =========================================================
CREATE TABLE hr_statutory_profiles (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id BIGINT UNSIGNED NOT NULL,
    profile_name VARCHAR(100) NOT NULL DEFAULT 'Default',
    effective_from DATE NOT NULL,
    effective_to DATE NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    remarks VARCHAR(500) NULL,
    professional_tax_state_code VARCHAR(64) NULL COMMENT 'State/UT whose notified PT schedule these slabs follow (e.g. Karnataka, Maharashtra)',
    created_at TIMESTAMP NULL DEFAULT NULL,
    updated_at TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT fk_hr_stat_prof_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    INDEX idx_hr_stat_prof_lookup (company_id, is_active, effective_from)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE hr_statutory_pf (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    statutory_profile_id BIGINT UNSIGNED NOT NULL,
    employee_percent DECIMAL(9,4) NOT NULL DEFAULT 12.0000,
    employer_percent DECIMAL(9,4) NOT NULL DEFAULT 12.0000,
    wage_ceiling DECIMAL(18,2) NULL,
    calculate_on VARCHAR(32) NOT NULL DEFAULT 'basic',
    created_at TIMESTAMP NULL DEFAULT NULL,
    updated_at TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY uq_hr_pf_profile (statutory_profile_id),
    CONSTRAINT fk_hr_pf_profile FOREIGN KEY (statutory_profile_id) REFERENCES hr_statutory_profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE hr_statutory_esi (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    statutory_profile_id BIGINT UNSIGNED NOT NULL,
    employee_percent DECIMAL(9,4) NOT NULL DEFAULT 0.7500,
    employer_percent DECIMAL(9,4) NOT NULL DEFAULT 3.2500,
    gross_ceiling DECIMAL(18,2) NULL,
    calculate_on VARCHAR(32) NOT NULL DEFAULT 'gross',
    created_at TIMESTAMP NULL DEFAULT NULL,
    updated_at TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY uq_hr_esi_profile (statutory_profile_id),
    CONSTRAINT fk_hr_esi_profile FOREIGN KEY (statutory_profile_id) REFERENCES hr_statutory_profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE hr_statutory_pt_slabs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    statutory_profile_id BIGINT UNSIGNED NOT NULL,
    gross_from DECIMAL(18,2) NOT NULL DEFAULT 0,
    gross_to DECIMAL(18,2) NULL,
    employee_tax_monthly DECIMAL(18,2) NOT NULL DEFAULT 0,
    employer_tax_monthly DECIMAL(18,2) NOT NULL DEFAULT 0,
    sort_order INT NOT NULL DEFAULT 0,
    CONSTRAINT fk_hr_pt_profile FOREIGN KEY (statutory_profile_id) REFERENCES hr_statutory_profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 6. ATTENDANCE
-- =========================================================
CREATE TABLE attendance_records (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    employee_id BIGINT UNSIGNED,
    attendance_date DATE,

    check_in DATETIME,
    check_out DATETIME,

    status ENUM(
        'present',
        'absent',
        'leave',
        'half_day',
        'holiday'
    ) DEFAULT 'present',

    CONSTRAINT fk_attendance_employee FOREIGN KEY (employee_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 7. LEAVE TYPES
-- =========================================================
CREATE TABLE leave_types (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    leave_name VARCHAR(100),
    leave_code VARCHAR(20) NULL,
    max_days_per_year INT,

    is_paid TINYINT(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO departments (department_name, is_active) VALUES
('Administration', 1),
('Accounts', 1),
('Sales', 1),
('Purchase', 1),
('Stores', 1),
('Production', 1),
('Service', 1),
('Human Resources', 1);

INSERT INTO designations (designation_name, is_active) VALUES
('Manager', 1),
('Executive', 1),
('Supervisor', 1),
('Operator', 1),
('Technician', 1),
('Assistant', 1);

INSERT INTO leave_types (leave_name, leave_code, max_days_per_year, is_paid) VALUES
('Casual Leave', 'CL', 12, 1),
('Sick Leave', 'SL', 12, 1),
('Earned Leave', 'EL', 18, 1),
('Loss Of Pay', 'LOP', 365, 0);

-- =========================================================
-- 8. LEAVE REQUESTS
-- =========================================================
CREATE TABLE leave_requests (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    employee_id BIGINT UNSIGNED,

    leave_type_id BIGINT UNSIGNED,

    from_date DATE,
    to_date DATE,

    reason TEXT,

    cl_approved_days DECIMAL(8,2) NULL,
    lop_days DECIMAL(8,2) NULL,

    status ENUM(
        'pending',
        'approved',
        'rejected'
    ) DEFAULT 'pending',

    approved_by BIGINT UNSIGNED,

    CONSTRAINT fk_leave_employee FOREIGN KEY (employee_id) REFERENCES employees(id),
    CONSTRAINT fk_leave_type FOREIGN KEY (leave_type_id) REFERENCES leave_types(id),
    CONSTRAINT fk_leave_approved FOREIGN KEY (approved_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 9. PAYROLL RUN
-- =========================================================
CREATE TABLE payroll_runs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    company_id BIGINT UNSIGNED,

    payroll_month INT,
    payroll_year INT,

    run_date DATE,

    status ENUM(
        'draft',
        'processed',
        'posted'
    ) DEFAULT 'draft',

    voucher_id BIGINT UNSIGNED NULL,

    created_by BIGINT UNSIGNED,

    CONSTRAINT fk_payroll_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_payroll_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 10. PAYROLL LINES
-- =========================================================
CREATE TABLE payroll_lines (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    payroll_run_id BIGINT UNSIGNED,
    employee_id BIGINT UNSIGNED,

    gross_salary DECIMAL(18,2),
    total_deductions DECIMAL(18,2),
    net_salary DECIMAL(18,2),

    working_days INT,
    present_days INT,
    leave_days INT,
    lop_days DECIMAL(8,2) DEFAULT 0,

    CONSTRAINT fk_payroll_lines_run FOREIGN KEY (payroll_run_id) REFERENCES payroll_runs(id) ON DELETE CASCADE,
    CONSTRAINT fk_payroll_lines_employee FOREIGN KEY (employee_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 11. PAYSLIPS
-- =========================================================
CREATE TABLE payslips (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    payroll_line_id BIGINT UNSIGNED,

    payslip_date DATE,

    generated_by BIGINT UNSIGNED,

    remarks TEXT,

    CONSTRAINT fk_payslip_line FOREIGN KEY (payroll_line_id) REFERENCES payroll_lines(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- ACCOUNTING BUDGETS
-- =========================================================
DROP TABLE IF EXISTS budget_lines;
DROP TABLE IF EXISTS budgets;

CREATE TABLE budgets (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id BIGINT UNSIGNED NOT NULL,
    financial_year_id BIGINT UNSIGNED NULL,
    budget_code VARCHAR(100) NOT NULL,
    budget_name VARCHAR(255) NOT NULL,
    date_from DATE NOT NULL,
    date_to DATE NOT NULL,
    budget_status ENUM('draft', 'approved', 'closed', 'cancelled') NOT NULL DEFAULT 'draft',
    notes TEXT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_budgets_company_code (company_id, budget_code),
    CONSTRAINT fk_budgets_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_budgets_financial_year FOREIGN KEY (financial_year_id) REFERENCES financial_years(id),
    CONSTRAINT fk_budgets_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_budgets_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE budget_lines (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    budget_id BIGINT UNSIGNED NOT NULL,
    line_no INT NOT NULL,
    account_id BIGINT UNSIGNED NOT NULL,
    budget_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    remarks VARCHAR(500) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_budget_lines_doc_line (budget_id, line_no),
    CONSTRAINT fk_budget_lines_budget FOREIGN KEY (budget_id) REFERENCES budgets(id) ON DELETE CASCADE,
    CONSTRAINT fk_budget_lines_account FOREIGN KEY (account_id) REFERENCES accounts(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- PROJECT MANAGEMENT
-- =========================================================
DROP TABLE IF EXISTS project_billings;
DROP TABLE IF EXISTS project_vendor_works;
DROP TABLE IF EXISTS project_resource_usages;
DROP TABLE IF EXISTS project_expenses;
DROP TABLE IF EXISTS project_timesheets;
DROP TABLE IF EXISTS project_milestones;
DROP TABLE IF EXISTS project_tasks;
DROP TABLE IF EXISTS projects;

CREATE TABLE projects (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id BIGINT UNSIGNED NOT NULL,
    customer_party_id BIGINT UNSIGNED NULL,
    project_code VARCHAR(100) NOT NULL,
    project_name VARCHAR(255) NOT NULL,
    project_type VARCHAR(100) NULL,
    billing_method ENUM('fixed', 'time_and_material', 'milestone', 'cost_plus') NOT NULL DEFAULT 'fixed',
    expected_start_date DATE NULL,
    expected_end_date DATE NULL,
    actual_start_date DATE NULL,
    actual_end_date DATE NULL,
    budget_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    percent_completion DECIMAL(8,2) NOT NULL DEFAULT 0,
    image_path VARCHAR(500) NULL,
    project_status ENUM('draft', 'open', 'working', 'on_hold', 'completed', 'cancelled') NOT NULL DEFAULT 'draft',
    notes TEXT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_projects_company_code (company_id, project_code),
    CONSTRAINT fk_projects_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_projects_customer FOREIGN KEY (customer_party_id) REFERENCES parties(id),
    CONSTRAINT fk_projects_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_projects_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS media_files;

CREATE TABLE media_files (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    company_id BIGINT UNSIGNED NULL,
    module VARCHAR(50) NULL,
    document_type VARCHAR(100) NULL,
    document_id BIGINT UNSIGNED NULL,
    purpose VARCHAR(100) NULL,
    original_name VARCHAR(255) NOT NULL,
    stored_name VARCHAR(255) NOT NULL,
    file_extension VARCHAR(20) NULL,
    mime_type VARCHAR(150) NULL,
    file_size BIGINT UNSIGNED NOT NULL DEFAULT 0,
    file_path VARCHAR(500) NOT NULL,
    is_public TINYINT(1) NOT NULL DEFAULT 0,
    uploaded_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_media_files_company (company_id),
    INDEX idx_media_files_module (module),
    INDEX idx_media_files_document (document_type, document_id),
    INDEX idx_media_files_uploaded_by (uploaded_by),
    CONSTRAINT fk_media_files_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_media_files_uploaded_by FOREIGN KEY (uploaded_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE project_tasks (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    project_id BIGINT UNSIGNED NOT NULL,
    task_code VARCHAR(100) NOT NULL,
    task_name VARCHAR(255) NOT NULL,
    description TEXT NULL,
    assigned_employee_id BIGINT UNSIGNED NULL,
    planned_start_date DATE NULL,
    planned_end_date DATE NULL,
    actual_start_date DATE NULL,
    actual_end_date DATE NULL,
    estimated_hours DECIMAL(18,2) NOT NULL DEFAULT 0,
    actual_hours DECIMAL(18,2) NOT NULL DEFAULT 0,
    estimated_cost DECIMAL(18,2) NOT NULL DEFAULT 0,
    actual_cost DECIMAL(18,2) NOT NULL DEFAULT 0,
    progress_percent DECIMAL(8,2) NOT NULL DEFAULT 0,
    task_status ENUM('open', 'working', 'completed', 'on_hold', 'cancelled') NOT NULL DEFAULT 'open',
    is_billable TINYINT(1) NOT NULL DEFAULT 1,
    remarks VARCHAR(500) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_project_tasks_project_code (project_id, task_code),
    CONSTRAINT fk_project_tasks_project FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT fk_project_tasks_employee FOREIGN KEY (assigned_employee_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE project_milestones (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    project_id BIGINT UNSIGNED NOT NULL,
    milestone_name VARCHAR(255) NOT NULL,
    target_date DATE NULL,
    completion_date DATE NULL,
    milestone_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    milestone_status ENUM('open', 'completed', 'cancelled') NOT NULL DEFAULT 'open',
    remarks VARCHAR(500) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_project_milestones_project FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE project_timesheets (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    project_id BIGINT UNSIGNED NOT NULL,
    project_task_id BIGINT UNSIGNED NULL,
    employee_id BIGINT UNSIGNED NOT NULL,
    voucher_id BIGINT UNSIGNED NULL,
    work_date DATE NOT NULL,
    hours_worked DECIMAL(18,2) NOT NULL DEFAULT 0,
    hourly_cost DECIMAL(18,2) NOT NULL DEFAULT 0,
    billable_rate DECIMAL(18,2) NOT NULL DEFAULT 0,
    cost_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    billable_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    timesheet_status ENUM('draft', 'approved', 'rejected') NOT NULL DEFAULT 'approved',
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_project_timesheets_project FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT fk_project_timesheets_task FOREIGN KEY (project_task_id) REFERENCES project_tasks(id) ON DELETE SET NULL,
    CONSTRAINT fk_project_timesheets_employee FOREIGN KEY (employee_id) REFERENCES employees(id),
    CONSTRAINT fk_project_timesheets_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE project_expenses (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    project_id BIGINT UNSIGNED NOT NULL,
    project_task_id BIGINT UNSIGNED NULL,
    expense_date DATE NOT NULL,
    expense_category VARCHAR(100) NOT NULL,
    description VARCHAR(500) NOT NULL,
    supplier_party_id BIGINT UNSIGNED NULL,
    purchase_invoice_id BIGINT UNSIGNED NULL,
    voucher_id BIGINT UNSIGNED NULL,
    amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    expense_status ENUM('draft', 'approved', 'booked') NOT NULL DEFAULT 'approved',
    remarks VARCHAR(500) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_project_expenses_project FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT fk_project_expenses_task FOREIGN KEY (project_task_id) REFERENCES project_tasks(id) ON DELETE SET NULL,
    CONSTRAINT fk_project_expenses_supplier FOREIGN KEY (supplier_party_id) REFERENCES parties(id),
    CONSTRAINT fk_project_expenses_purchase_invoice FOREIGN KEY (purchase_invoice_id) REFERENCES purchase_invoices(id),
    CONSTRAINT fk_project_expenses_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE project_resource_usages (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    project_id BIGINT UNSIGNED NOT NULL,
    project_task_id BIGINT UNSIGNED NULL,
    asset_id BIGINT UNSIGNED NULL,
    voucher_id BIGINT UNSIGNED NULL,
    resource_name VARCHAR(255) NOT NULL,
    usage_date DATE NOT NULL,
    usage_hours DECIMAL(18,2) NOT NULL DEFAULT 0,
    usage_qty DECIMAL(18,2) NOT NULL DEFAULT 0,
    unit_cost DECIMAL(18,2) NOT NULL DEFAULT 0,
    total_cost DECIMAL(18,2) NOT NULL DEFAULT 0,
    remarks VARCHAR(500) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_project_resource_usages_project FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT fk_project_resource_usages_task FOREIGN KEY (project_task_id) REFERENCES project_tasks(id) ON DELETE SET NULL,
    CONSTRAINT fk_project_resource_usages_asset FOREIGN KEY (asset_id) REFERENCES assets(id),
    CONSTRAINT fk_project_resource_usages_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE project_vendor_works (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    project_id BIGINT UNSIGNED NOT NULL,
    project_task_id BIGINT UNSIGNED NULL,
    vendor_party_id BIGINT UNSIGNED NOT NULL,
    purchase_order_id BIGINT UNSIGNED NULL,
    purchase_invoice_id BIGINT UNSIGNED NULL,
    voucher_id BIGINT UNSIGNED NULL,
    work_description VARCHAR(500) NOT NULL,
    amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    work_status ENUM('open', 'ordered', 'in_progress', 'completed') NOT NULL DEFAULT 'open',
    remarks VARCHAR(500) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_project_vendor_works_project FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT fk_project_vendor_works_task FOREIGN KEY (project_task_id) REFERENCES project_tasks(id) ON DELETE SET NULL,
    CONSTRAINT fk_project_vendor_works_vendor FOREIGN KEY (vendor_party_id) REFERENCES parties(id),
    CONSTRAINT fk_project_vendor_works_purchase_order FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id),
    CONSTRAINT fk_project_vendor_works_purchase_invoice FOREIGN KEY (purchase_invoice_id) REFERENCES purchase_invoices(id),
    CONSTRAINT fk_project_vendor_works_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE project_billings (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    project_id BIGINT UNSIGNED NOT NULL,
    project_milestone_id BIGINT UNSIGNED NULL,
    billing_date DATE NOT NULL,
    billing_basis ENUM('milestone', 'timesheet', 'fixed', 'cost_plus') NOT NULL DEFAULT 'fixed',
    billing_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    sales_invoice_id BIGINT UNSIGNED NULL,
    billing_status ENUM('draft', 'invoiced', 'paid', 'cancelled') NOT NULL DEFAULT 'draft',
    remarks VARCHAR(500) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_project_billings_project FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT fk_project_billings_milestone FOREIGN KEY (project_milestone_id) REFERENCES project_milestones(id) ON DELETE SET NULL,
    CONSTRAINT fk_project_billings_sales_invoice FOREIGN KEY (sales_invoice_id) REFERENCES sales_invoices(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- =========================================================
-- ACCOUNTING COMPLETION ADDITIONS
-- Fresh-install support for perpetual inventory + expense claims
-- =========================================================

-- Additional company ledgers required by inventory, manufacturing, jobwork,
-- service, project, and opening stock flows are also created by the installer.

DROP TABLE IF EXISTS expense_claim_lines;
DROP TABLE IF EXISTS expense_claims;

CREATE TABLE expense_claims (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    company_id BIGINT UNSIGNED NOT NULL,
    employee_id BIGINT UNSIGNED NOT NULL,
    claim_no VARCHAR(100) NOT NULL,
    claim_date DATE NOT NULL,
    total_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    claim_status ENUM('draft', 'applied', 'approved', 'reimbursed', 'rejected', 'cancelled') NOT NULL DEFAULT 'draft',
    voucher_id BIGINT UNSIGNED NULL,
    reimbursement_voucher_id BIGINT UNSIGNED NULL,
    notes TEXT NULL,
    approved_by BIGINT UNSIGNED NULL,
    approved_at DATETIME NULL,
    reimbursed_by BIGINT UNSIGNED NULL,
    reimbursed_at DATETIME NULL,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_expense_claims_company_no (company_id, claim_no),
    INDEX idx_expense_claims_employee (employee_id),
    INDEX idx_expense_claims_status (claim_status),
    CONSTRAINT fk_expense_claims_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_expense_claims_employee FOREIGN KEY (employee_id) REFERENCES employees(id),
    CONSTRAINT fk_expense_claims_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(id),
    CONSTRAINT fk_expense_claims_reimbursement_voucher FOREIGN KEY (reimbursement_voucher_id) REFERENCES vouchers(id),
    CONSTRAINT fk_expense_claims_approved_by FOREIGN KEY (approved_by) REFERENCES users(id),
    CONSTRAINT fk_expense_claims_reimbursed_by FOREIGN KEY (reimbursed_by) REFERENCES users(id),
    CONSTRAINT fk_expense_claims_created_by FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_expense_claims_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE expense_claim_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    expense_claim_id BIGINT UNSIGNED NOT NULL,
    line_no INT NOT NULL,
    expense_date DATE NOT NULL,
    expense_category VARCHAR(100) NOT NULL,
    description VARCHAR(500) NOT NULL,
    amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    project_id BIGINT UNSIGNED NULL,
    project_task_id BIGINT UNSIGNED NULL,
    remarks VARCHAR(500) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_expense_claim_lines_doc_line (expense_claim_id, line_no),
    CONSTRAINT fk_expense_claim_lines_doc FOREIGN KEY (expense_claim_id) REFERENCES expense_claims(id) ON DELETE CASCADE,
    CONSTRAINT fk_expense_claim_lines_project FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE SET NULL,
    CONSTRAINT fk_expense_claim_lines_project_task FOREIGN KEY (project_task_id) REFERENCES project_tasks(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE sales_delivery_returnable_dcs (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    sales_delivery_id BIGINT UNSIGNED NOT NULL,
    line_no INT UNSIGNED NOT NULL,
    item_id BIGINT UNSIGNED NULL,
    item_name VARCHAR(255) NULL,
    uom_id BIGINT UNSIGNED NOT NULL,
    description VARCHAR(500) NULL,
    qty DECIMAL(18,6) NOT NULL,
    remarks VARCHAR(500) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY sales_delivery_returnable_dcs_delivery_line_idx (sales_delivery_id, line_no),
    CONSTRAINT sales_delivery_returnable_dcs_delivery_fk
        FOREIGN KEY (sales_delivery_id) REFERENCES sales_deliveries(id) ON DELETE CASCADE,
    CONSTRAINT sales_delivery_returnable_dcs_item_fk
        FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT sales_delivery_returnable_dcs_uom_fk
        FOREIGN KEY (uom_id) REFERENCES uoms(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
