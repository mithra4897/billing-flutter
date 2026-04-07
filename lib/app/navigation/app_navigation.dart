import 'package:flutter/material.dart';

import '../../model/auth/module_model.dart';

class AppNavigationItem {
  const AppNavigationItem({
    required this.key,
    required this.title,
    required this.icon,
    this.path,
    this.requiredPermissions = const <String>[],
    this.children = const <AppNavigationItem>[],
  });

  final String key;
  final String title;
  final IconData icon;
  final String? path;
  final List<String> requiredPermissions;
  final List<AppNavigationItem> children;

  bool get hasChildren => children.isNotEmpty;
}

class AppNavigation {
  const AppNavigation._();

  static const String dashboardPath = '/dashboard';
  static const Map<String, int> _defaultTopLevelOrder = <String, int>{
    'dashboard': 0,
    'crm': 10,
    'sales': 20,
    'purchase': 30,
    'inventory': 40,
    'planning': 50,
    'manufacturing': 60,
    'quality': 70,
    'jobwork': 80,
    'service': 90,
    'projects': 100,
    'maintenance': 110,
    'assets': 120,
    'accounting': 130,
    'hr': 140,
    'parties': 150,
    'masters': 160,
    'tax': 170,
    'settings': 910,
  };

  static final List<AppNavigationItem> menu = <AppNavigationItem>[
    const AppNavigationItem(
      key: 'dashboard',
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      path: '/dashboard',
    ),
    const AppNavigationItem(
      key: 'settings',
      title: 'Settings',
      icon: Icons.settings_outlined,
      children: [
        AppNavigationItem(
          key: 'settings-tax-categories',
          title: 'Tax Categories',
          icon: Icons.percent_outlined,
          path: '/settings/tax-categories',
          requiredPermissions: ['tax_code.view'],
        ),
        AppNavigationItem(
          key: 'settings-uom',
          title: 'UOM',
          icon: Icons.straighten_outlined,
          path: '/settings/uom',
          requiredPermissions: ['uom.view'],
        ),
        AppNavigationItem(
          key: 'settings-company-setup',
          title: 'Company Setup',
          icon: Icons.corporate_fare_outlined,
          children: [
            AppNavigationItem(
              key: 'settings-companies',
              title: 'Companies',
              icon: Icons.apartment_outlined,
              path: '/settings/companies',
              requiredPermissions: ['company.view'],
            ),
            AppNavigationItem(
              key: 'settings-branches',
              title: 'Branches',
              icon: Icons.account_tree_outlined,
              path: '/settings/branches',
              requiredPermissions: ['branch.view'],
            ),
            AppNavigationItem(
              key: 'settings-business-locations',
              title: 'Business Locations',
              icon: Icons.place_outlined,
              path: '/settings/business-locations',
              requiredPermissions: ['business_location.view'],
            ),
            AppNavigationItem(
              key: 'settings-warehouses',
              title: 'Warehouses',
              icon: Icons.warehouse_outlined,
              path: '/settings/warehouses',
              requiredPermissions: ['warehouse.view'],
            ),
            AppNavigationItem(
              key: 'settings-financial-years',
              title: 'Financial Years',
              icon: Icons.calendar_month_outlined,
              path: '/settings/financial-years',
              requiredPermissions: ['financial_year.view'],
            ),
            AppNavigationItem(
              key: 'settings-document-series',
              title: 'Document Series',
              icon: Icons.confirmation_number_outlined,
              path: '/settings/document-series',
              requiredPermissions: ['document_series.view'],
            ),
            AppNavigationItem(
              key: 'settings-module-preferences',
              title: 'Module Preferences',
              icon: Icons.view_sidebar_outlined,
              path: '/settings/module-preferences',
              requiredPermissions: ['permission.view'],
            ),
          ],
        ),
        AppNavigationItem(
          key: 'settings-access-control',
          title: 'Access Control',
          icon: Icons.admin_panel_settings_outlined,
          children: [
            AppNavigationItem(
              key: 'settings-profile',
              title: 'Profile',
              icon: Icons.person_outline,
              path: '/settings/profile',
            ),
            AppNavigationItem(
              key: 'settings-users',
              title: 'Users',
              icon: Icons.people_outline,
              path: '/settings/users',
              requiredPermissions: ['user.view'],
            ),
            AppNavigationItem(
              key: 'settings-roles',
              title: 'Roles',
              icon: Icons.badge_outlined,
              path: '/settings/roles',
              requiredPermissions: ['role.view'],
            ),
            AppNavigationItem(
              key: 'settings-modules',
              title: 'Modules',
              icon: Icons.apps_outlined,
              path: '/admin/modules',
              requiredPermissions: ['permission.view'],
            ),
            AppNavigationItem(
              key: 'settings-login-history',
              title: 'Login History',
              icon: Icons.history_outlined,
              path: '/settings/login-history',
              requiredPermissions: ['user.view'],
            ),
          ],
        ),
        AppNavigationItem(
          key: 'settings-communication',
          title: 'Communication',
          icon: Icons.mail_outline,
          children: [
            AppNavigationItem(
              key: 'email-settings',
              title: 'Email Settings',
              icon: Icons.settings_ethernet_outlined,
              path: '/communication/email-settings',
              requiredPermissions: ['communication.view'],
            ),
            AppNavigationItem(
              key: 'email-module-settings',
              title: 'Module Settings',
              icon: Icons.tune_outlined,
              path: '/communication/email-module-settings',
              requiredPermissions: ['communication.view'],
            ),
            AppNavigationItem(
              key: 'email-templates',
              title: 'Email Templates',
              icon: Icons.text_snippet_outlined,
              path: '/communication/email-templates',
              requiredPermissions: ['communication.view'],
            ),
            AppNavigationItem(
              key: 'email-rules',
              title: 'Email Rules',
              icon: Icons.notifications_active_outlined,
              path: '/communication/email-rules',
              requiredPermissions: ['communication.view'],
            ),
            AppNavigationItem(
              key: 'email-messages',
              title: 'Email Messages',
              icon: Icons.mark_email_read_outlined,
              path: '/communication/email-messages',
              requiredPermissions: ['communication.view'],
            ),
          ],
        ),
        AppNavigationItem(
          key: 'settings-media',
          title: 'Media',
          icon: Icons.perm_media_outlined,
          children: [
            AppNavigationItem(
              key: 'media-files',
              title: 'Files',
              icon: Icons.folder_copy_outlined,
              path: '/media/files',
              requiredPermissions: ['media.view'],
            ),
          ],
        ),
      ],
    ),
    const AppNavigationItem(
      key: 'tax',
      title: 'Tax',
      icon: Icons.receipt_long_outlined,
      children: [
        AppNavigationItem(
          key: 'tax-states',
          title: 'States',
          icon: Icons.map_outlined,
          path: '/tax/states',
          requiredPermissions: ['taxes.view'],
        ),
        AppNavigationItem(
          key: 'tax-gst-registrations',
          title: 'GST Registrations',
          icon: Icons.assignment_ind_outlined,
          path: '/tax/gst-registrations',
          requiredPermissions: ['taxes.view'],
        ),
        AppNavigationItem(
          key: 'tax-pos-rules',
          title: 'Place of Supply Rules',
          icon: Icons.route_outlined,
          path: '/tax/place-of-supply-rules',
          requiredPermissions: ['taxes.view'],
        ),
        AppNavigationItem(
          key: 'tax-rules',
          title: 'GST Tax Rules',
          icon: Icons.rule_outlined,
          path: '/tax/gst-tax-rules',
          requiredPermissions: ['taxes.view'],
        ),
        AppNavigationItem(
          key: 'document-tax-lines',
          title: 'Document Tax Lines',
          icon: Icons.segment_outlined,
          path: '/tax/document-tax-lines',
          requiredPermissions: ['taxes.view'],
        ),
      ],
    ),
    const AppNavigationItem(
      key: 'masters',
      title: 'Masters',
      icon: Icons.layers_outlined,
      children: [
        AppNavigationItem(
          key: 'master-tax-codes',
          title: 'Tax Codes',
          icon: Icons.percent_outlined,
          path: '/masters/tax-codes',
          requiredPermissions: ['tax_code.view'],
        ),
        AppNavigationItem(
          key: 'master-item-categories',
          title: 'Item Categories',
          icon: Icons.category_outlined,
          path: '/masters/item-categories',
          requiredPermissions: ['item_category.view'],
        ),
        AppNavigationItem(
          key: 'master-items',
          title: 'Items',
          icon: Icons.inventory_2_outlined,
          path: '/masters/items',
          requiredPermissions: ['item.view'],
        ),
      ],
    ),
    const AppNavigationItem(
      key: 'parties',
      title: 'Parties',
      icon: Icons.handshake_outlined,
      path: '/parties',
      requiredPermissions: ['party.view'],
    ),
    const AppNavigationItem(
      key: 'accounting',
      title: 'Accounting',
      icon: Icons.account_balance_wallet_outlined,
      children: [
        AppNavigationItem(
          key: 'account-groups',
          title: 'Account Groups',
          icon: Icons.account_tree_outlined,
          path: '/accounting/account-groups',
          requiredPermissions: ['accounts.view'],
        ),
        AppNavigationItem(
          key: 'accounts',
          title: 'Accounts',
          icon: Icons.account_balance_outlined,
          path: '/accounting/accounts',
          requiredPermissions: ['accounts.view'],
        ),
        AppNavigationItem(
          key: 'voucher-types',
          title: 'Voucher Types',
          icon: Icons.receipt_outlined,
          path: '/accounting/voucher-types',
          requiredPermissions: ['accounts.view'],
        ),
        AppNavigationItem(
          key: 'posting-rule-groups',
          title: 'Posting Rule Groups',
          icon: Icons.grid_view_outlined,
          path: '/accounting/posting-rule-groups',
          requiredPermissions: ['accounts.view'],
        ),
        AppNavigationItem(
          key: 'posting-rules',
          title: 'Posting Rules',
          icon: Icons.rule_folder_outlined,
          path: '/accounting/posting-rules',
          requiredPermissions: ['accounts.view'],
        ),
        AppNavigationItem(
          key: 'document-postings',
          title: 'Document Postings',
          icon: Icons.post_add_outlined,
          path: '/accounting/document-postings',
          requiredPermissions: ['accounts.view'],
        ),
        AppNavigationItem(
          key: 'party-accounts',
          title: 'Party Accounts',
          icon: Icons.supervisor_account_outlined,
          path: '/accounting/party-accounts',
          requiredPermissions: ['accounts.view'],
        ),
        AppNavigationItem(
          key: 'budgets',
          title: 'Budgets',
          icon: Icons.savings_outlined,
          path: '/accounting/budgets',
          requiredPermissions: ['accounts.view'],
        ),
        AppNavigationItem(
          key: 'vouchers',
          title: 'Vouchers',
          icon: Icons.article_outlined,
          path: '/accounting/vouchers',
          requiredPermissions: ['accounts.view'],
        ),
        AppNavigationItem(
          key: 'voucher-allocations',
          title: 'Voucher Allocations',
          icon: Icons.call_split_outlined,
          path: '/accounting/voucher-allocations',
          requiredPermissions: ['accounts.view'],
        ),
        AppNavigationItem(
          key: 'cash-sessions',
          title: 'Cash Sessions',
          icon: Icons.point_of_sale_outlined,
          path: '/accounting/cash-sessions',
          requiredPermissions: ['accounts.view'],
        ),
        AppNavigationItem(
          key: 'bank-reconciliation',
          title: 'Bank Reconciliation',
          icon: Icons.compare_arrows_outlined,
          path: '/accounting/bank-reconciliation',
          requiredPermissions: ['accounts.view'],
        ),
        AppNavigationItem(
          key: 'financial-reports',
          title: 'Financial Reports',
          icon: Icons.assessment_outlined,
          path: '/accounting/reports',
          requiredPermissions: ['accounts.view'],
        ),
      ],
    ),
    const AppNavigationItem(
      key: 'assets',
      title: 'Assets',
      icon: Icons.precision_manufacturing_outlined,
      children: [
        AppNavigationItem(
          key: 'asset-categories',
          title: 'Categories',
          icon: Icons.category_outlined,
          path: '/assets/categories',
          requiredPermissions: ['asset.view'],
        ),
        AppNavigationItem(
          key: 'asset-cost-centers',
          title: 'Cost Centers',
          icon: Icons.center_focus_strong_outlined,
          path: '/assets/cost-centers',
          requiredPermissions: ['asset.view'],
        ),
        AppNavigationItem(
          key: 'asset-register',
          title: 'Assets',
          icon: Icons.devices_other_outlined,
          path: '/assets/register',
          requiredPermissions: ['asset.view'],
        ),
        AppNavigationItem(
          key: 'asset-depreciation',
          title: 'Depreciation Runs',
          icon: Icons.trending_down_outlined,
          path: '/assets/depreciation-runs',
          requiredPermissions: ['asset.view'],
        ),
        AppNavigationItem(
          key: 'asset-transfers',
          title: 'Transfers',
          icon: Icons.swap_horiz_outlined,
          path: '/assets/transfers',
          requiredPermissions: ['asset.view'],
        ),
        AppNavigationItem(
          key: 'asset-disposals',
          title: 'Disposals',
          icon: Icons.delete_sweep_outlined,
          path: '/assets/disposals',
          requiredPermissions: ['asset.view'],
        ),
        AppNavigationItem(
          key: 'asset-reports',
          title: 'Asset Reports',
          icon: Icons.bar_chart_outlined,
          path: '/assets/reports',
          requiredPermissions: ['asset.view'],
        ),
      ],
    ),
    const AppNavigationItem(
      key: 'crm',
      title: 'CRM',
      icon: Icons.support_agent_outlined,
      children: [
        AppNavigationItem(
          key: 'crm-sources',
          title: 'Sources',
          icon: Icons.input_outlined,
          path: '/crm/sources',
          requiredPermissions: ['crm.view'],
        ),
        AppNavigationItem(
          key: 'crm-stages',
          title: 'Stages',
          icon: Icons.stacked_line_chart_outlined,
          path: '/crm/stages',
          requiredPermissions: ['crm.view'],
        ),
        AppNavigationItem(
          key: 'crm-leads',
          title: 'Leads',
          icon: Icons.person_search_outlined,
          path: '/crm/leads',
          requiredPermissions: ['crm.view'],
        ),
        AppNavigationItem(
          key: 'crm-enquiries',
          title: 'Enquiries',
          icon: Icons.contact_support_outlined,
          path: '/crm/enquiries',
          requiredPermissions: ['crm.view'],
        ),
        AppNavigationItem(
          key: 'crm-opportunities',
          title: 'Opportunities',
          icon: Icons.auto_graph_outlined,
          path: '/crm/opportunities',
          requiredPermissions: ['crm.view'],
        ),
      ],
    ),
    const AppNavigationItem(
      key: 'hr',
      title: 'HR',
      icon: Icons.badge_outlined,
      children: [
        AppNavigationItem(
          key: 'hr-departments',
          title: 'Departments',
          icon: Icons.apartment_outlined,
          path: '/hr/departments',
          requiredPermissions: ['hr.view'],
        ),
        AppNavigationItem(
          key: 'hr-designations',
          title: 'Designations',
          icon: Icons.workspace_premium_outlined,
          path: '/hr/designations',
          requiredPermissions: ['hr.view'],
        ),
        AppNavigationItem(
          key: 'hr-employees',
          title: 'Employees',
          icon: Icons.groups_2_outlined,
          path: '/hr/employees',
          requiredPermissions: ['hr.view'],
        ),
        AppNavigationItem(
          key: 'hr-attendance',
          title: 'Attendance',
          icon: Icons.fact_check_outlined,
          path: '/hr/attendance',
          requiredPermissions: ['hr.view'],
        ),
        AppNavigationItem(
          key: 'hr-leave-types',
          title: 'Leave Types',
          icon: Icons.beach_access_outlined,
          path: '/hr/leave-types',
          requiredPermissions: ['hr.view'],
        ),
        AppNavigationItem(
          key: 'hr-leave-requests',
          title: 'Leave Requests',
          icon: Icons.event_available_outlined,
          path: '/hr/leave-requests',
          requiredPermissions: ['hr.view'],
        ),
        AppNavigationItem(
          key: 'hr-payroll-runs',
          title: 'Payroll Runs',
          icon: Icons.payments_outlined,
          path: '/hr/payroll-runs',
          requiredPermissions: ['hr.view'],
        ),
        AppNavigationItem(
          key: 'hr-payslips',
          title: 'Payslips',
          icon: Icons.receipt_long_outlined,
          path: '/hr/payslips',
          requiredPermissions: ['hr.view'],
        ),
        AppNavigationItem(
          key: 'hr-expense-claims',
          title: 'Expense Claims',
          icon: Icons.request_page_outlined,
          path: '/hr/expense-claims',
          requiredPermissions: ['hr.view'],
        ),
      ],
    ),
    const AppNavigationItem(
      key: 'inventory',
      title: 'Inventory',
      icon: Icons.inventory_outlined,
      children: [
        AppNavigationItem(
          key: 'inventory-item-categories',
          title: 'Item Categories',
          icon: Icons.category_outlined,
          path: '/inventory/item-categories',
          requiredPermissions: ['inventory.view'],
        ),
        AppNavigationItem(
          key: 'inventory-brands',
          title: 'Brands',
          icon: Icons.sell_outlined,
          path: '/inventory/brands',
          requiredPermissions: ['inventory.view'],
        ),
        AppNavigationItem(
          key: 'inventory-uoms',
          title: 'UOMs',
          icon: Icons.straighten_outlined,
          path: '/inventory/uoms',
          requiredPermissions: ['inventory.view'],
        ),
        AppNavigationItem(
          key: 'inventory-uom-conversions',
          title: 'UOM Conversions',
          icon: Icons.swap_vert_outlined,
          path: '/inventory/uom-conversions',
          requiredPermissions: ['inventory.view'],
        ),
        AppNavigationItem(
          key: 'inventory-tax-codes',
          title: 'Tax Codes',
          icon: Icons.percent_outlined,
          path: '/inventory/tax-codes',
          requiredPermissions: ['inventory.view'],
        ),
        AppNavigationItem(
          key: 'inventory-items',
          title: 'Items',
          icon: Icons.inventory_2_outlined,
          path: '/inventory/items',
          requiredPermissions: ['inventory.view'],
        ),
        AppNavigationItem(
          key: 'inventory-item-supplier-maps',
          title: 'Item Supplier Maps',
          icon: Icons.local_shipping_outlined,
          path: '/inventory/item-supplier-maps',
          requiredPermissions: ['inventory.view'],
        ),
        AppNavigationItem(
          key: 'inventory-item-alternates',
          title: 'Item Alternates',
          icon: Icons.compare_arrows_outlined,
          path: '/inventory/item-alternates',
          requiredPermissions: ['inventory.view'],
        ),
        AppNavigationItem(
          key: 'inventory-item-prices',
          title: 'Item Prices',
          icon: Icons.price_change_outlined,
          path: '/inventory/item-prices',
          requiredPermissions: ['inventory.view'],
        ),
        AppNavigationItem(
          key: 'inventory-stock-batches',
          title: 'Stock Batches',
          icon: Icons.inventory_2_outlined,
          path: '/inventory/stock-batches',
          requiredPermissions: ['inventory.view'],
        ),
        AppNavigationItem(
          key: 'inventory-stock-serials',
          title: 'Stock Serials',
          icon: Icons.qr_code_outlined,
          path: '/inventory/stock-serials',
          requiredPermissions: ['inventory.view'],
        ),
        AppNavigationItem(
          key: 'inventory-stock-movements',
          title: 'Stock Movements',
          icon: Icons.move_up_outlined,
          path: '/inventory/stock-movements',
          requiredPermissions: ['inventory.view'],
        ),
        AppNavigationItem(
          key: 'inventory-stock-balances',
          title: 'Stock Balances',
          icon: Icons.pie_chart_outline,
          path: '/inventory/stock-balances',
          requiredPermissions: ['inventory.view'],
        ),
        AppNavigationItem(
          key: 'inventory-adjustments',
          title: 'Inventory Adjustments',
          icon: Icons.tune_outlined,
          path: '/inventory/adjustments',
          requiredPermissions: ['inventory.view'],
        ),
        AppNavigationItem(
          key: 'inventory-opening-stocks',
          title: 'Opening Stocks',
          icon: Icons.note_add_outlined,
          path: '/inventory/opening-stocks',
          requiredPermissions: ['inventory.view'],
        ),
        AppNavigationItem(
          key: 'inventory-stock-transfers',
          title: 'Stock Transfers',
          icon: Icons.swap_horiz_outlined,
          path: '/inventory/stock-transfers',
          requiredPermissions: ['inventory.view'],
        ),
        AppNavigationItem(
          key: 'inventory-stock-issues',
          title: 'Stock Issues',
          icon: Icons.outbox_outlined,
          path: '/inventory/stock-issues',
          requiredPermissions: ['inventory.view'],
        ),
        AppNavigationItem(
          key: 'inventory-internal-stock-receipts',
          title: 'Internal Receipts',
          icon: Icons.move_to_inbox_outlined,
          path: '/inventory/internal-stock-receipts',
          requiredPermissions: ['inventory.view'],
        ),
        AppNavigationItem(
          key: 'inventory-stock-damage',
          title: 'Stock Damage',
          icon: Icons.report_gmailerrorred_outlined,
          path: '/inventory/stock-damage',
          requiredPermissions: ['inventory.view'],
        ),
        AppNavigationItem(
          key: 'inventory-physical-stock-counts',
          title: 'Physical Counts',
          icon: Icons.checklist_rtl_outlined,
          path: '/inventory/physical-stock-counts',
          requiredPermissions: ['inventory.view'],
        ),
        AppNavigationItem(
          key: 'inventory-inquiry',
          title: 'Inventory Inquiry',
          icon: Icons.search_outlined,
          path: '/inventory/inquiry',
          requiredPermissions: ['inventory.view'],
        ),
      ],
    ),
    const AppNavigationItem(
      key: 'maintenance',
      title: 'Maintenance',
      icon: Icons.build_circle_outlined,
      children: [
        AppNavigationItem(
          key: 'maintenance-plans',
          title: 'Plans',
          icon: Icons.event_repeat_outlined,
          path: '/maintenance/plans',
          requiredPermissions: ['maintenance.view'],
        ),
        AppNavigationItem(
          key: 'maintenance-requests',
          title: 'Requests',
          icon: Icons.assignment_outlined,
          path: '/maintenance/requests',
          requiredPermissions: ['maintenance.view'],
        ),
        AppNavigationItem(
          key: 'maintenance-work-orders',
          title: 'Work Orders',
          icon: Icons.work_history_outlined,
          path: '/maintenance/work-orders',
          requiredPermissions: ['maintenance.view'],
        ),
        AppNavigationItem(
          key: 'maintenance-downtime',
          title: 'Downtime Logs',
          icon: Icons.timer_off_outlined,
          path: '/maintenance/downtime-logs',
          requiredPermissions: ['maintenance.view'],
        ),
        AppNavigationItem(
          key: 'maintenance-amc-contracts',
          title: 'AMC Contracts',
          icon: Icons.description_outlined,
          path: '/maintenance/amc-contracts',
          requiredPermissions: ['maintenance.view'],
        ),
      ],
    ),
    const AppNavigationItem(
      key: 'manufacturing',
      title: 'Manufacturing',
      icon: Icons.factory_outlined,
      children: [
        AppNavigationItem(
          key: 'manufacturing-boms',
          title: 'BOMs',
          icon: Icons.list_alt_outlined,
          path: '/manufacturing/boms',
          requiredPermissions: ['manufacturing.view'],
        ),
        AppNavigationItem(
          key: 'manufacturing-production-orders',
          title: 'Production Orders',
          icon: Icons.precision_manufacturing_outlined,
          path: '/manufacturing/production-orders',
          requiredPermissions: ['manufacturing.view'],
        ),
        AppNavigationItem(
          key: 'manufacturing-material-issues',
          title: 'Material Issues',
          icon: Icons.upload_file_outlined,
          path: '/manufacturing/production-material-issues',
          requiredPermissions: ['manufacturing.view'],
        ),
        AppNavigationItem(
          key: 'manufacturing-receipts',
          title: 'Production Receipts',
          icon: Icons.download_done_outlined,
          path: '/manufacturing/production-receipts',
          requiredPermissions: ['manufacturing.view'],
        ),
      ],
    ),
    const AppNavigationItem(
      key: 'jobwork',
      title: 'Jobwork',
      icon: Icons.handyman_outlined,
      children: [
        AppNavigationItem(
          key: 'jobwork-orders',
          title: 'Orders',
          icon: Icons.assignment_outlined,
          path: '/jobwork/orders',
          requiredPermissions: ['jobwork.view'],
        ),
        AppNavigationItem(
          key: 'jobwork-dispatches',
          title: 'Dispatches',
          icon: Icons.local_shipping_outlined,
          path: '/jobwork/dispatches',
          requiredPermissions: ['jobwork.view'],
        ),
        AppNavigationItem(
          key: 'jobwork-receipts',
          title: 'Receipts',
          icon: Icons.inventory_outlined,
          path: '/jobwork/receipts',
          requiredPermissions: ['jobwork.view'],
        ),
        AppNavigationItem(
          key: 'jobwork-charges',
          title: 'Charges',
          icon: Icons.currency_rupee_outlined,
          path: '/jobwork/charges',
          requiredPermissions: ['jobwork.view'],
        ),
      ],
    ),
    const AppNavigationItem(
      key: 'planning',
      title: 'Planning',
      icon: Icons.route_outlined,
      children: [
        AppNavigationItem(
          key: 'planning-stock-reservations',
          title: 'Stock Reservations',
          icon: Icons.bookmark_outline,
          path: '/planning/stock-reservations',
          requiredPermissions: ['mrp.view'],
        ),
        AppNavigationItem(
          key: 'planning-item-policies',
          title: 'Item Policies',
          icon: Icons.policy_outlined,
          path: '/planning/item-policies',
          requiredPermissions: ['mrp.view'],
        ),
        AppNavigationItem(
          key: 'planning-calendars',
          title: 'Calendars',
          icon: Icons.calendar_view_month_outlined,
          path: '/planning/calendars',
          requiredPermissions: ['mrp.view'],
        ),
        AppNavigationItem(
          key: 'planning-mrp-runs',
          title: 'MRP Runs',
          icon: Icons.play_circle_outline,
          path: '/planning/mrp-runs',
          requiredPermissions: ['mrp.view'],
        ),
        AppNavigationItem(
          key: 'planning-mrp-demands',
          title: 'MRP Demands',
          icon: Icons.trending_up_outlined,
          path: '/planning/mrp-demands',
          requiredPermissions: ['mrp.view'],
        ),
        AppNavigationItem(
          key: 'planning-mrp-supplies',
          title: 'MRP Supplies',
          icon: Icons.inventory_outlined,
          path: '/planning/mrp-supplies',
          requiredPermissions: ['mrp.view'],
        ),
        AppNavigationItem(
          key: 'planning-mrp-net-requirements',
          title: 'Net Requirements',
          icon: Icons.balance_outlined,
          path: '/planning/mrp-net-requirements',
          requiredPermissions: ['mrp.view'],
        ),
        AppNavigationItem(
          key: 'planning-mrp-recommendations',
          title: 'Recommendations',
          icon: Icons.tips_and_updates_outlined,
          path: '/planning/mrp-recommendations',
          requiredPermissions: ['mrp.view'],
        ),
      ],
    ),
    const AppNavigationItem(
      key: 'projects',
      title: 'Projects',
      icon: Icons.folder_special_outlined,
      children: [
        AppNavigationItem(
          key: 'projects-list',
          title: 'Projects',
          icon: Icons.folder_outlined,
          path: '/projects',
          requiredPermissions: ['project.view'],
        ),
        AppNavigationItem(
          key: 'projects-dashboard',
          title: 'Project Dashboard',
          icon: Icons.insights_outlined,
          path: '/projects/dashboard',
          requiredPermissions: ['project.view'],
        ),
        AppNavigationItem(
          key: 'projects-tasks',
          title: 'Tasks',
          icon: Icons.task_outlined,
          path: '/projects/tasks',
          requiredPermissions: ['project.view'],
        ),
        AppNavigationItem(
          key: 'projects-milestones',
          title: 'Milestones',
          icon: Icons.flag_outlined,
          path: '/projects/milestones',
          requiredPermissions: ['project.view'],
        ),
        AppNavigationItem(
          key: 'projects-timesheets',
          title: 'Timesheets',
          icon: Icons.timer_outlined,
          path: '/projects/timesheets',
          requiredPermissions: ['project.view'],
        ),
        AppNavigationItem(
          key: 'projects-expenses',
          title: 'Expenses',
          icon: Icons.money_off_csred_outlined,
          path: '/projects/expenses',
          requiredPermissions: ['project.view'],
        ),
        AppNavigationItem(
          key: 'projects-resources',
          title: 'Resource Usage',
          icon: Icons.settings_input_component_outlined,
          path: '/projects/resources',
          requiredPermissions: ['project.view'],
        ),
        AppNavigationItem(
          key: 'projects-vendor-works',
          title: 'Vendor Works',
          icon: Icons.business_center_outlined,
          path: '/projects/vendor-works',
          requiredPermissions: ['project.view'],
        ),
        AppNavigationItem(
          key: 'projects-billings',
          title: 'Billings',
          icon: Icons.request_quote_outlined,
          path: '/projects/billings',
          requiredPermissions: ['project.view'],
        ),
      ],
    ),
    const AppNavigationItem(
      key: 'purchase',
      title: 'Purchase',
      icon: Icons.shopping_cart_outlined,
      children: [
        AppNavigationItem(
          key: 'purchase-requisitions',
          title: 'Requisitions',
          icon: Icons.playlist_add_check_outlined,
          path: '/purchase/requisitions',
          requiredPermissions: ['purchase.view'],
        ),
        AppNavigationItem(
          key: 'purchase-orders',
          title: 'Orders',
          icon: Icons.shopping_bag_outlined,
          path: '/purchase/orders',
          requiredPermissions: ['purchase.view'],
        ),
        AppNavigationItem(
          key: 'purchase-receipts',
          title: 'Receipts',
          icon: Icons.inventory_2_outlined,
          path: '/purchase/receipts',
          requiredPermissions: ['purchase.view'],
        ),
        AppNavigationItem(
          key: 'purchase-invoices',
          title: 'Invoices',
          icon: Icons.receipt_long_outlined,
          path: '/purchase/invoices',
          requiredPermissions: ['purchase.view'],
        ),
        AppNavigationItem(
          key: 'purchase-payments',
          title: 'Payments',
          icon: Icons.payments_outlined,
          path: '/purchase/payments',
          requiredPermissions: ['purchase.view'],
        ),
        AppNavigationItem(
          key: 'purchase-returns',
          title: 'Returns',
          icon: Icons.assignment_return_outlined,
          path: '/purchase/returns',
          requiredPermissions: ['purchase.view'],
        ),
      ],
    ),
    const AppNavigationItem(
      key: 'quality',
      title: 'Quality',
      icon: Icons.verified_outlined,
      children: [
        AppNavigationItem(
          key: 'quality-qc-plans',
          title: 'QC Plans',
          icon: Icons.rule_outlined,
          path: '/quality/qc-plans',
          requiredPermissions: ['quality.view'],
        ),
        AppNavigationItem(
          key: 'quality-qc-inspections',
          title: 'QC Inspections',
          icon: Icons.fact_check_outlined,
          path: '/quality/qc-inspections',
          requiredPermissions: ['quality.view'],
        ),
        AppNavigationItem(
          key: 'quality-result-actions',
          title: 'Result Actions',
          icon: Icons.assignment_turned_in_outlined,
          path: '/quality/qc-result-actions',
          requiredPermissions: ['quality.view'],
        ),
        AppNavigationItem(
          key: 'quality-non-conformance',
          title: 'Non Conformance Logs',
          icon: Icons.report_problem_outlined,
          path: '/quality/qc-non-conformance-logs',
          requiredPermissions: ['quality.view'],
        ),
      ],
    ),
    const AppNavigationItem(
      key: 'sales',
      title: 'Sales',
      icon: Icons.point_of_sale_outlined,
      children: [
        AppNavigationItem(
          key: 'sales-quotations',
          title: 'Quotations',
          icon: Icons.request_quote_outlined,
          path: '/sales/quotations',
          requiredPermissions: ['sales.view'],
        ),
        AppNavigationItem(
          key: 'sales-orders',
          title: 'Orders',
          icon: Icons.shopping_cart_checkout_outlined,
          path: '/sales/orders',
          requiredPermissions: ['sales.view'],
        ),
        AppNavigationItem(
          key: 'sales-deliveries',
          title: 'Deliveries',
          icon: Icons.local_shipping_outlined,
          path: '/sales/deliveries',
          requiredPermissions: ['sales.view'],
        ),
        AppNavigationItem(
          key: 'sales-invoices',
          title: 'Invoices',
          icon: Icons.description_outlined,
          path: '/sales/invoices',
          requiredPermissions: ['sales.view'],
        ),
        AppNavigationItem(
          key: 'sales-receipts',
          title: 'Receipts',
          icon: Icons.account_balance_wallet_outlined,
          path: '/sales/receipts',
          requiredPermissions: ['sales.view'],
        ),
        AppNavigationItem(
          key: 'sales-returns',
          title: 'Returns',
          icon: Icons.assignment_return_outlined,
          path: '/sales/returns',
          requiredPermissions: ['sales.view'],
        ),
      ],
    ),
    const AppNavigationItem(
      key: 'service',
      title: 'Service',
      icon: Icons.miscellaneous_services_outlined,
      children: [
        AppNavigationItem(
          key: 'service-contracts',
          title: 'Contracts',
          icon: Icons.description_outlined,
          path: '/service/contracts',
          requiredPermissions: ['service.view'],
        ),
        AppNavigationItem(
          key: 'service-tickets',
          title: 'Tickets',
          icon: Icons.support_outlined,
          path: '/service/tickets',
          requiredPermissions: ['service.view'],
        ),
        AppNavigationItem(
          key: 'service-warranty-claims',
          title: 'Warranty Claims',
          icon: Icons.verified_user_outlined,
          path: '/service/warranty-claims',
          requiredPermissions: ['service.view'],
        ),
        AppNavigationItem(
          key: 'service-work-orders',
          title: 'Work Orders',
          icon: Icons.assignment_outlined,
          path: '/service/work-orders',
          requiredPermissions: ['service.view'],
        ),
        AppNavigationItem(
          key: 'service-feedbacks',
          title: 'Feedbacks',
          icon: Icons.feedback_outlined,
          path: '/service/feedbacks',
          requiredPermissions: ['service.view'],
        ),
      ],
    ),
  ];

  static AppNavigationItem? findByPath(String path) {
    return _findInList(menu, _normalizePath(path));
  }

  static String titleForPath(String path) {
    return findByPath(path)?.title ?? 'Dashboard';
  }

  static List<AppNavigationItem> visibleMenu({
    required Set<String> permissionCodes,
    required bool isSuperAdmin,
    List<ModuleModel> orderedModules = const <ModuleModel>[],
  }) {
    final visibleItems = _visibleItems(
      items: menu,
      permissionCodes: permissionCodes,
      isSuperAdmin: isSuperAdmin,
    );

    return _sortTopLevelItems(visibleItems, orderedModules);
  }

  static bool containsPath(AppNavigationItem item, String path) {
    final normalizedPath = _normalizePath(path);

    if (item.path == normalizedPath) {
      return true;
    }

    for (final child in item.children) {
      if (containsPath(child, normalizedPath)) {
        return true;
      }
    }

    return false;
  }

  static List<String> ancestorKeysForPath(String path) {
    final normalizedPath = _normalizePath(path);
    return _ancestorKeys(menu, normalizedPath) ?? const <String>[];
  }

  static List<String> ancestorKeysForItemKey(String key) {
    return _ancestorKeysForItemKey(menu, key) ?? const <String>[];
  }

  static AppNavigationItem? _findInList(
    List<AppNavigationItem> items,
    String path,
  ) {
    for (final item in items) {
      if (item.path == path) {
        return item;
      }

      final found = _findInList(item.children, path);
      if (found != null) {
        return found;
      }
    }

    return null;
  }

  static List<String>? _ancestorKeys(
    List<AppNavigationItem> items,
    String path,
  ) {
    for (final item in items) {
      if (item.path == path) {
        return <String>[];
      }

      final childPath = _ancestorKeys(item.children, path);
      if (childPath != null) {
        return <String>[item.key, ...childPath];
      }
    }

    return null;
  }

  static List<String>? _ancestorKeysForItemKey(
    List<AppNavigationItem> items,
    String key,
  ) {
    for (final item in items) {
      if (item.key == key) {
        return <String>[];
      }

      final childPath = _ancestorKeysForItemKey(item.children, key);
      if (childPath != null) {
        return <String>[item.key, ...childPath];
      }
    }

    return null;
  }

  static List<AppNavigationItem> _visibleItems({
    required List<AppNavigationItem> items,
    required Set<String> permissionCodes,
    required bool isSuperAdmin,
  }) {
    final visible = <AppNavigationItem>[];

    for (final item in items) {
      final visibleChildren = _visibleItems(
        items: item.children,
        permissionCodes: permissionCodes,
        isSuperAdmin: isSuperAdmin,
      );

      final allowed =
          isSuperAdmin ||
          item.requiredPermissions.isEmpty ||
          item.requiredPermissions.any(permissionCodes.contains);

      if (item.hasChildren) {
        if (visibleChildren.isNotEmpty || allowed) {
          visible.add(
            AppNavigationItem(
              key: item.key,
              title: item.title,
              icon: item.icon,
              path: item.path,
              requiredPermissions: item.requiredPermissions,
              children: visibleChildren,
            ),
          );
        }
        continue;
      }

      if (allowed) {
        visible.add(item);
      }
    }

    return visible;
  }

  static List<AppNavigationItem> _sortTopLevelItems(
    List<AppNavigationItem> items,
    List<ModuleModel> orderedModules,
  ) {
    final orderMap = <String, int>{};
    final hiddenModules = <String>{};

    if (orderedModules.isEmpty) {
      orderMap.addAll(_defaultTopLevelOrder);
    } else {
      for (final module in orderedModules) {
        final code = module.moduleCode?.toLowerCase();
        if (code == null || code.isEmpty) {
          continue;
        }

        final sortOrder = module.effectiveSortOrder ?? module.sortOrder;
        if (sortOrder != null) {
          orderMap[code] = sortOrder;
        }

        if (module.isHidden == true) {
          hiddenModules.add(code);
        }
      }
    }

    final filtered = items
        .where((item) {
          return !hiddenModules.contains(item.key.toLowerCase());
        })
        .toList(growable: false);

    filtered.sort((left, right) {
      if (left.key == 'dashboard') {
        return -1;
      }
      if (right.key == 'dashboard') {
        return 1;
      }

      final leftOrder = orderMap[left.key.toLowerCase()] ?? 100000;
      final rightOrder = orderMap[right.key.toLowerCase()] ?? 100000;
      final orderCompare = leftOrder.compareTo(rightOrder);
      if (orderCompare != 0) {
        return orderCompare;
      }

      return left.title.compareTo(right.title);
    });

    return filtered;
  }

  static String _normalizePath(String path) {
    final uri = Uri.parse(path);
    final normalized = uri.path.isEmpty ? dashboardPath : uri.path;
    return normalized == '/' ? dashboardPath : normalized;
  }
}
