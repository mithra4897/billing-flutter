import '../../core/navigation/app_route_state.dart';
import '../../screen.dart';
import '../crm/crm_enquiries_page.dart';
import '../crm/crm_leads_page.dart';
import '../crm/crm_opportunities_page.dart';
import '../crm/crm_sources_page.dart';
import '../crm/crm_stages_page.dart';
import '../dashboard/dashboard_page.dart';
import '../hr/department_page.dart';
import '../hr/designation_page.dart';
import '../hr/employee_page.dart';
import '../hr/expense_claims_page.dart';
import '../hr/hr_registers.dart';
import '../hr/hr_statutory_settings_page.dart';
import '../hr/leave_request_page.dart';
import '../hr/leave_type_page.dart';
import '../inventory/inventory_inquiry_page.dart';
import '../inventory/inventory_registers.dart';
import '../parties/party_management_page.dart';
import '../planning/planning_registers.dart';
import '../manufacturing/manufacturing_registers.dart';
import '../maintenance/maintenance_registers.dart';
import '../assets/asset_registers.dart';
import '../jobwork/jobwork_registers.dart';
import '../quality/quality_registers.dart';
import '../service/service_registers.dart';
import '../project/project_billing_page.dart';
import '../project/project_dashboard_page.dart';
import '../project/project_expense_page.dart';
import '../project/project_milestone_page.dart';
import '../project/project_page.dart';
import '../project/project_resource_usage_page.dart';
import '../project/project_task_page.dart';
import '../project/project_timesheet_page.dart';
import '../project/project_vendor_work_page.dart';
import '../purchase/purchase_invoice_page.dart';
import '../purchase/purchase_order_page.dart';
import '../purchase/purchase_payment_page.dart';
import '../purchase/purchase_receipt_page.dart';
import '../purchase/purchase_register_screens.dart';
import '../sales/sales_delivery_page.dart';
import '../sales/sales_invoice_page.dart';
import '../sales/sales_order_page.dart';
import '../sales/sales_quotation_page.dart';
import '../sales/sales_receipt_page.dart';
import '../sales/sales_register_screens.dart';
import '../sales/sales_return_page.dart';
import '../purchase/purchase_requisition_page.dart';
import '../purchase/purchase_return_page.dart';
import '../settings/accounting/account_group_page.dart';
import '../settings/accounting/account_page.dart';
import '../settings/accounting/bank_reconciliation_page.dart';
import '../settings/accounting/budget_page.dart';
import '../settings/accounting/cash_session_page.dart';
import '../settings/accounting/document_posting_page.dart';
import '../settings/accounting/financial_reports_page.dart';
import '../settings/accounting/party_account_register_page.dart';
import '../settings/accounting/posting_rule_group_page.dart';
import '../settings/accounting/posting_rule_page.dart';
import '../settings/accounting/voucher_page.dart';
import '../settings/accounting/voucher_type_page.dart';
import '../settings/communication/email_messages_page.dart';
import '../settings/communication/email_module_settings_page.dart';
import '../settings/communication/email_rules_page.dart';
import '../settings/communication/email_settings_page.dart';
import '../settings/communication/email_templates_page.dart';
import '../settings/master/branch_page.dart';
import '../settings/master/brand_page.dart';
import '../settings/master/company_page.dart';
import '../settings/master/document_series_page.dart';
import '../settings/master/financial_year_page.dart';
import '../settings/master/item_alternate_page.dart';
import '../settings/master/item_category_page.dart';
import '../settings/master/item_page.dart';
import '../settings/master/item_price_page.dart';
import '../settings/master/item_supplier_map_page.dart';
import '../settings/master/physical_stock_count_page.dart';
import '../settings/master/stock_balance_page.dart';
import '../settings/master/tax_category_page.dart';
import '../settings/master/uom_page.dart';
import '../settings/tax/document_tax_lines_register_page.dart';
import '../settings/tax/gst_registration_page.dart';
import '../settings/tax/gst_tax_rule_page.dart';
import '../settings/tax/state_page.dart';
import '../settings/user/login_history_page.dart';
import '../settings/user/module_preferences_page.dart';
import '../settings/user/profile_page.dart';
import '../settings/user/role_management_page.dart';
import '../settings/user/user_management_page.dart';
import 'module_placeholder_page.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({
    super.key,
    required this.path,
    this.queryParameters = const <String, String>{},
  });

  final String path;
  final Map<String, String> queryParameters;

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  PublicBrandingModel _branding = const PublicBrandingModel(
    companyName: 'Billing ERP',
  );
  AuthContextModel? _authContext;
  late String _currentPath;
  late Map<String, String> _currentQueryParameters;
  late final ShellPageActionsController _shellPageActionsController;
  int _contextVersion = 0;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.path;
    _currentQueryParameters = Map<String, String>.from(widget.queryParameters);
    _shellPageActionsController = ShellPageActionsController();
    AppSessionService.accessVersion.addListener(_handleAccessVersionChanged);
    WorkingContextService.version.addListener(_handleWorkingContextChanged);
    _loadShellContext();
  }

  @override
  void dispose() {
    AppSessionService.accessVersion.removeListener(_handleAccessVersionChanged);
    WorkingContextService.version.removeListener(_handleWorkingContextChanged);
    _shellPageActionsController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AppShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path ||
        !_sameQuery(oldWidget.queryParameters, widget.queryParameters)) {
      _currentPath = widget.path;
      _currentQueryParameters = Map<String, String>.from(
        widget.queryParameters,
      );
    }
  }

  Future<void> _loadShellContext() async {
    final branding = await SessionStorage.getBranding();
    final authContext = await SessionStorage.getAuthContext();
    final permissionCodes = await SessionStorage.getPermissionCodes();
    final currentUser = await SessionStorage.getCurrentUser();
    if (!mounted) {
      return;
    }

    setState(() {
      _branding = branding ?? _branding;
      _authContext = authContext;
    });

    _ensureCurrentRouteAllowed(
      permissionCodes: permissionCodes.toSet(),
      isSuperAdmin:
          currentUser?['is_super_admin'] == true ||
          currentUser?['is_super_admin'] == 1,
      orderedModules: authContext?.menuModules ?? const <ModuleModel>[],
    );
  }

  void _handleAccessVersionChanged() {
    _loadShellContext();
  }

  void _handleWorkingContextChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      _contextVersion = WorkingContextService.version.value;
    });
  }

  void _ensureCurrentRouteAllowed({
    required Set<String> permissionCodes,
    required bool isSuperAdmin,
    required List<ModuleModel> orderedModules,
  }) {
    if (_currentPath == '/dashboard' || _currentPath == '/settings/profile') {
      return;
    }

    final routeItem = AppNavigation.findByPath(_currentPath);
    if (routeItem == null) {
      return;
    }

    final visibleMenu = AppNavigation.visibleMenu(
      permissionCodes: permissionCodes,
      isSuperAdmin: isSuperAdmin,
      orderedModules: orderedModules,
    );

    final isVisible = _containsPath(visibleMenu, _currentPath);
    if (isVisible || !mounted) {
      return;
    }

    _handleNavigate('/dashboard');
  }

  bool _containsPath(List<AppNavigationItem> items, String path) {
    for (final item in items) {
      if (item.path == path) {
        return true;
      }
      if (item.children.isNotEmpty && _containsPath(item.children, path)) {
        return true;
      }
    }

    return false;
  }

  void _handleNavigate(String route) {
    final uri = Uri.parse(route);
    _shellPageActionsController.clearActions();
    setState(() {
      _currentPath = uri.path;
      _currentQueryParameters = Map<String, String>.from(uri.queryParameters);
    });
    AppRouteState.update(uri.toString());

    SystemNavigator.routeInformationUpdated(uri: uri, replace: true);
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveShell(
      title: _titleForPath(_currentPath, _authContext),
      branding: _branding,
      currentPath: _buildCurrentRoute(),
      actionsListenable: _shellPageActionsController,
      onNavigate: _handleNavigate,
      child: Align(
        alignment: AlignmentGeometry.topCenter,
        child: ShellPageActionsScope(
          controller: _shellPageActionsController,
          child: ShellRouteScope(
            onNavigate: _handleNavigate,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 140),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeOut,
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  String _buildCurrentRoute() {
    final uri = Uri(
      path: _currentPath,
      queryParameters: _currentQueryParameters.isEmpty
          ? null
          : _currentQueryParameters,
    );
    return uri.toString();
  }

  Widget _buildContent() {
    final routeKey = ValueKey<String>(
      '${_buildCurrentRoute()}::$_contextVersion',
    );
    final salesRoute = _buildSalesContent(routeKey);
    if (salesRoute != null) {
      return salesRoute;
    }
    final purchaseRoute = _buildPurchaseContent(routeKey);
    if (purchaseRoute != null) {
      return purchaseRoute;
    }

    switch (_currentPath) {
      case '/dashboard':
        return DashboardPage(key: routeKey, embedded: true);
      case '/settings/profile':
        return ProfilePage(key: routeKey, embedded: true);
      case '/settings/users':
        return UserManagementPage(
          key: routeKey,
          embedded: true,
          initialUserId: int.tryParse(_currentQueryParameters['id'] ?? ''),
        );
      case '/settings/login-history':
        return LoginHistoryPage(key: routeKey, embedded: true);
      case '/settings/roles':
        return RoleManagementPage(
          key: routeKey,
          embedded: true,
          initialRoleId: int.tryParse(_currentQueryParameters['id'] ?? ''),
        );
      case '/settings/companies':
        return CompanyManagementPage(key: routeKey, embedded: true);
      case '/settings/branches':
        return BranchManagementPage(key: routeKey, embedded: true);
      case '/settings/business-locations':
        return BranchManagementPage(
          key: routeKey,
          embedded: true,
          initialTabIndex: 1,
        );
      case '/settings/warehouses':
        return BranchManagementPage(
          key: routeKey,
          embedded: true,
          initialTabIndex: 2,
        );
      case '/tax/gst-registrations':
        return GstRegistrationManagementPage(key: routeKey, embedded: true);
      case '/tax/document-tax-lines':
        return DocumentTaxLinesRegisterPage(key: routeKey, embedded: true);
      case '/settings/financial-years':
        return FinancialYearManagementPage(key: routeKey, embedded: true);
      case '/settings/document-series':
        return DocumentSeriesManagementPage(key: routeKey, embedded: true);
      case '/settings/module-preferences':
        return ModulePreferencesPage(key: routeKey, embedded: true);
      case '/inventory/uoms':
        return UomManagementPage(key: routeKey, embedded: true);
      case '/inventory/uom-conversions':
        return UomManagementPage(
          key: routeKey,
          embedded: true,
          initialTabIndex: 1,
        );
      case '/inventory/tax-codes':
        return TaxCategoryManagementPage(key: routeKey, embedded: true);
      case '/inventory/item-categories':
        return ItemCategoryManagementPage(key: routeKey, embedded: true);
      case '/inventory/items':
        return ItemManagementPage(key: routeKey, embedded: true);
      case '/inventory/item-prices':
        return ItemPriceManagementPage(key: routeKey, embedded: true);
      case '/inventory/stock-balances':
        return StockBalancePage(key: routeKey, embedded: true);
      case '/inventory/physical-stock-counts':
        return PhysicalStockCountPage(key: routeKey, embedded: true);
      case '/inventory/brands':
        return BrandManagementPage(key: routeKey, embedded: true);
      case '/inventory/item-alternates':
      case '/inventory/alternate-items':
        return ItemAlternateManagementPage(key: routeKey, embedded: true);
      case '/inventory/item-suppliers':
        return ItemSupplierMapManagementPage(
          key: routeKey,
          embedded: true,
          mode: ItemSupplierMapViewMode.itemWise,
        );
      case '/inventory/supplier-items':
        return ItemSupplierMapManagementPage(
          key: routeKey,
          embedded: true,
          mode: ItemSupplierMapViewMode.supplierWise,
        );
      case '/inventory/inquiry':
        return InventoryInquiryPage(key: routeKey, embedded: true);
      case '/inventory/opening-stocks':
        return OpeningStockRegisterPage(key: routeKey, embedded: true);
      case '/inventory/stock-issues':
        return StockIssueRegisterPage(key: routeKey, embedded: true);
      case '/inventory/internal-stock-receipts':
        return InternalStockReceiptRegisterPage(key: routeKey, embedded: true);
      case '/inventory/stock-transfers':
        return StockTransferRegisterPage(key: routeKey, embedded: true);
      case '/inventory/stock-damage':
        return StockDamageRegisterPage(key: routeKey, embedded: true);
      case '/inventory/adjustments':
        return InventoryAdjustmentRegisterPage(key: routeKey, embedded: true);
      case '/inventory/stock-movements':
        return StockMovementRegisterPage(key: routeKey, embedded: true);
      case '/inventory/stock-batches':
        return StockBatchRegisterPage(key: routeKey, embedded: true);
      case '/inventory/stock-serials':
        return StockSerialRegisterPage(key: routeKey, embedded: true);
      case '/tax/states':
        return StateManagementPage(key: routeKey, embedded: true);
      case '/tax/gst-tax-rules':
        return GstTaxRuleManagementPage(key: routeKey, embedded: true);
      case '/communication/email-settings':
        return EmailSettingsPage(key: routeKey, embedded: true);
      case '/communication/email-module-settings':
        return EmailModuleSettingsPage(key: routeKey, embedded: true);
      case '/communication/email-templates':
        return EmailTemplatesPage(key: routeKey, embedded: true);
      case '/communication/email-rules':
        return EmailRulesPage(key: routeKey, embedded: true);
      case '/communication/email-messages':
        return EmailMessagesPage(key: routeKey, embedded: true);
      case '/communication/send-email':
        return EmailMessagesPage(
          key: routeKey,
          embedded: true,
          openSendComposerOnInit: true,
        );
      case '/crm/leads':
        return CrmLeadsPage(key: routeKey, embedded: true);
      case '/crm/enquiries':
        return CrmEnquiriesPage(
          key: routeKey,
          embedded: true,
          initialSelectId: int.tryParse(
            _currentQueryParameters['select_id'] ?? '',
          ),
        );
      case '/crm/opportunities':
        return CrmOpportunitiesPage(
          key: routeKey,
          embedded: true,
          initialSelectId: int.tryParse(
            _currentQueryParameters['select_id'] ?? '',
          ),
        );
      case '/crm/sources':
        return CrmSourcesPage(key: routeKey, embedded: true);
      case '/crm/stages':
        return CrmStagesPage(key: routeKey, embedded: true);
      case '/parties':
        return PartyManagementPage(key: routeKey, embedded: true);
      case '/accounting/account-groups':
        return AccountGroupManagementPage(key: routeKey, embedded: true);
      case '/accounting/accounts':
        return AccountManagementPage(key: routeKey, embedded: true);
      case '/accounting/vouchers':
        return VoucherManagementPage(key: routeKey, embedded: true);
      case '/accounting/cash-sessions':
        return CashSessionManagementPage(key: routeKey, embedded: true);
      case '/accounting/bank-reconciliation':
        return BankReconciliationManagementPage(key: routeKey, embedded: true);
      case '/accounting/reports':
        return FinancialReportsPage(key: routeKey, embedded: true);
      case '/accounting/voucher-types':
        return VoucherTypeManagementPage(key: routeKey, embedded: true);
      case '/accounting/posting-rule-groups':
        return PostingRuleGroupManagementPage(key: routeKey, embedded: true);
      case '/accounting/posting-rules':
        return PostingRuleManagementPage(key: routeKey, embedded: true);
      case '/accounting/document-postings':
        return DocumentPostingManagementPage(key: routeKey, embedded: true);
      case '/accounting/budgets':
        return BudgetManagementPage(key: routeKey, embedded: true);
      case '/accounting/party-accounts':
      case '/parties/accounts':
        return PartyAccountRegisterPage(
          key: routeKey,
          embedded: true,
          initialPartyId: int.tryParse(
            _currentQueryParameters['party_id'] ?? '',
          ),
        );
      case '/hr/departments':
        return DepartmentManagementPage(key: routeKey, embedded: true);
      case '/hr/designations':
        return DesignationManagementPage(key: routeKey, embedded: true);
      case '/hr/employees':
        return EmployeeManagementPage(
          key: routeKey,
          embedded: true,
          initialEmployeeId: int.tryParse(
            _currentQueryParameters['employee_id'] ?? '',
          ),
        );
      case '/hr/leave-types':
        return LeaveTypeManagementPage(key: routeKey, embedded: true);
      case '/hr/statutory-settings':
        return HrStatutorySettingsPage(key: routeKey, embedded: true);
      case '/hr/leave-requests':
        return LeaveRequestManagementPage(key: routeKey, embedded: true);
      case '/hr/attendance':
        return AttendanceRegisterPage(key: routeKey, embedded: true);
      case '/hr/expense-claims':
        return ExpenseClaimsManagementPage(key: routeKey, embedded: true);
      case '/hr/payroll-runs':
        return PayrollRunRegisterPage(key: routeKey, embedded: true);
      case '/hr/payslips':
        return PayslipRegisterPage(key: routeKey, embedded: true);
      case '/sales/quotations':
        return SalesQuotationRegisterPage(key: routeKey, embedded: true);
      case '/sales/orders':
        return SalesOrderRegisterPage(key: routeKey, embedded: true);
      case '/sales/invoices':
        return SalesInvoiceRegisterPage(key: routeKey, embedded: true);
      case '/sales/deliveries':
        return SalesDeliveryRegisterPage(key: routeKey, embedded: true);
      case '/sales/receipts':
        return SalesReceiptRegisterPage(key: routeKey, embedded: true);
      case '/sales/returns':
        return SalesReturnRegisterPage(key: routeKey, embedded: true);
      case '/purchase/requisitions':
        return PurchaseRequisitionRegisterPage(key: routeKey, embedded: true);
      case '/purchase/orders':
        return PurchaseOrderRegisterPage(key: routeKey, embedded: true);
      case '/purchase/receipts':
        return PurchaseReceiptRegisterPage(key: routeKey, embedded: true);
      case '/purchase/invoices':
        return PurchaseInvoiceRegisterPage(key: routeKey, embedded: true);
      case '/purchase/payments':
        return PurchasePaymentRegisterPage(key: routeKey, embedded: true);
      case '/purchase/returns':
        return PurchaseReturnRegisterPage(key: routeKey, embedded: true);
      case '/planning/stock-reservations':
        return StockReservationRegisterPage(key: routeKey, embedded: true);
      case '/planning/item-policies':
        return ItemPlanningPolicyRegisterPage(key: routeKey, embedded: true);
      case '/planning/calendars':
        return PlanningCalendarRegisterPage(key: routeKey, embedded: true);
      case '/planning/mrp-runs':
        return MrpRunRegisterPage(key: routeKey, embedded: true);
      case '/planning/mrp-demands':
        return MrpDemandRegisterPage(key: routeKey, embedded: true);
      case '/planning/mrp-supplies':
        return MrpSupplyRegisterPage(key: routeKey, embedded: true);
      case '/planning/mrp-net-requirements':
        return MrpNetRequirementRegisterPage(key: routeKey, embedded: true);
      case '/planning/mrp-recommendations':
        return MrpRecommendationRegisterPage(key: routeKey, embedded: true);
      case '/manufacturing/boms':
        return BomRegisterPage(key: routeKey, embedded: true);
      case '/manufacturing/production-orders':
        return ProductionOrderRegisterPage(key: routeKey, embedded: true);
      case '/manufacturing/production-material-issues':
        return ProductionMaterialIssueRegisterPage(key: routeKey, embedded: true);
      case '/manufacturing/production-receipts':
        return ProductionReceiptRegisterPage(key: routeKey, embedded: true);
      case '/jobwork/orders':
        return JobworkOrderRegisterPage(key: routeKey, embedded: true);
      case '/jobwork/dispatches':
        return JobworkDispatchRegisterPage(key: routeKey, embedded: true);
      case '/jobwork/receipts':
        return JobworkReceiptRegisterPage(key: routeKey, embedded: true);
      case '/jobwork/charges':
        return JobworkChargeRegisterPage(key: routeKey, embedded: true);
      case '/quality/qc-plans':
        return QcPlanRegisterPage(key: routeKey, embedded: true);
      case '/quality/qc-inspections':
        return QcInspectionRegisterPage(key: routeKey, embedded: true);
      case '/quality/qc-result-actions':
        return QcResultActionRegisterPage(key: routeKey, embedded: true);
      case '/quality/qc-non-conformance-logs':
        return QcNonConformanceLogRegisterPage(key: routeKey, embedded: true);
      case '/service/contracts':
        return ServiceContractRegisterPage(key: routeKey, embedded: true);
      case '/service/tickets':
        return ServiceTicketRegisterPage(key: routeKey, embedded: true);
      case '/service/warranty-claims':
        return WarrantyClaimRegisterPage(key: routeKey, embedded: true);
      case '/service/work-orders':
        return ServiceWorkOrderRegisterPage(key: routeKey, embedded: true);
      case '/service/feedbacks':
        return ServiceFeedbackRegisterPage(key: routeKey, embedded: true);
      case '/maintenance/plans':
        return MaintenancePlanRegisterPage(key: routeKey, embedded: true);
      case '/maintenance/requests':
        return MaintenanceRequestRegisterPage(key: routeKey, embedded: true);
      case '/maintenance/work-orders':
        return MaintenanceWorkOrderRegisterPage(key: routeKey, embedded: true);
      case '/maintenance/downtime-logs':
        return AssetDowntimeLogRegisterPage(key: routeKey, embedded: true);
      case '/maintenance/amc-contracts':
        return AmcContractRegisterPage(key: routeKey, embedded: true);
      case '/assets/categories':
        return AssetCategoryRegisterPage(key: routeKey, embedded: true);
      case '/assets/cost-centers':
        return AssetCostCenterRegisterPage(key: routeKey, embedded: true);
      case '/assets/register':
        return FixedAssetRegisterPage(key: routeKey, embedded: true);
      case '/assets/depreciation-runs':
        return AssetDepreciationRunRegisterPage(key: routeKey, embedded: true);
      case '/assets/transfers':
        return AssetTransferRegisterPage(key: routeKey, embedded: true);
      case '/assets/disposals':
        return AssetDisposalRegisterPage(key: routeKey, embedded: true);
      case '/assets/reports':
        return AssetReportsHubPage(key: routeKey, embedded: true);
      case '/projects':
        return ProjectManagementPage(key: routeKey, embedded: true);
      case '/projects/dashboard':
        return ProjectDashboardPage(key: routeKey, embedded: true);
      case '/projects/tasks':
        return ProjectTaskManagementPage(key: routeKey, embedded: true);
      case '/projects/milestones':
        return ProjectMilestoneManagementPage(key: routeKey, embedded: true);
      case '/projects/timesheets':
        return ProjectTimesheetManagementPage(key: routeKey, embedded: true);
      case '/projects/expenses':
        return ProjectExpenseManagementPage(key: routeKey, embedded: true);
      case '/projects/resources':
        return ProjectResourceUsageManagementPage(
          key: routeKey,
          embedded: true,
        );
      case '/projects/vendor-works':
        return ProjectVendorWorkManagementPage(key: routeKey, embedded: true);
      case '/projects/billings':
        return ProjectBillingManagementPage(key: routeKey, embedded: true);
      case '/parties/addresses':
        return PartyManagementPage(
          key: routeKey,
          embedded: true,
          initialTabIndex: 1,
        );
      case '/parties/contacts':
        return PartyManagementPage(
          key: routeKey,
          embedded: true,
          initialTabIndex: 2,
        );
      case '/parties/gst-details':
        return PartyManagementPage(
          key: routeKey,
          embedded: true,
          initialTabIndex: 3,
        );
      case '/parties/bank-accounts':
        return PartyManagementPage(
          key: routeKey,
          embedded: true,
          initialTabIndex: 4,
        );
      case '/parties/credit-limits':
        return PartyManagementPage(
          key: routeKey,
          embedded: true,
          initialTabIndex: 5,
        );
      case '/parties/payment-terms':
        return PartyManagementPage(
          key: routeKey,
          embedded: true,
          initialTabIndex: 6,
        );
      default:
        return ModulePlaceholderPage(
          key: routeKey,
          embedded: true,
          path: _currentPath,
          queryParameters: _currentQueryParameters,
        );
    }
  }

  Widget? _buildSalesContent(ValueKey<String> routeKey) {
    final segments = _currentPath
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    if (segments.length != 3 || segments.first != 'sales') {
      return null;
    }
    final module = segments[1];
    final recordSegment = segments[2];
    final isNew = recordSegment == 'new';
    final id = int.tryParse(recordSegment);
    if (!isNew && id == null) {
      return null;
    }

    switch (module) {
      case 'quotations':
        return SalesQuotationPage(
          key: routeKey,
          embedded: true,
          editorOnly: true,
          initialId: id,
          initialCrmOpportunityId: int.tryParse(
            _currentQueryParameters['crm_opportunity_id'] ?? '',
          ),
        );
      case 'orders':
        return SalesOrderPage(
          key: routeKey,
          embedded: true,
          editorOnly: true,
          initialId: id,
          initialQuotationId: int.tryParse(
            _currentQueryParameters['quotation_id'] ?? '',
          ),
        );
      case 'invoices':
        return SalesInvoicePage(
          key: routeKey,
          embedded: true,
          editorOnly: true,
          initialId: id,
          initialQuotationId: int.tryParse(
            _currentQueryParameters['quotation_id'] ?? '',
          ),
        );
      case 'deliveries':
        return SalesDeliveryPage(
          key: routeKey,
          embedded: true,
          editorOnly: true,
          initialId: id,
        );
      case 'receipts':
        return SalesReceiptPage(
          key: routeKey,
          embedded: true,
          editorOnly: true,
          initialId: id,
          initialSalesInvoiceId: int.tryParse(
            _currentQueryParameters['invoice_id'] ?? '',
          ),
        );
      case 'returns':
        return SalesReturnPage(
          key: routeKey,
          embedded: true,
          editorOnly: true,
          initialId: id,
        );
    }
    return null;
  }

  Widget? _buildPurchaseContent(ValueKey<String> routeKey) {
    final segments = _currentPath
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    if (segments.length != 3 || segments.first != 'purchase') {
      return null;
    }
    final module = segments[1];
    final recordSegment = segments[2];
    final isNew = recordSegment == 'new';
    final id = int.tryParse(recordSegment);
    if (!isNew && id == null) {
      return null;
    }

    switch (module) {
      case 'requisitions':
        return PurchaseRequisitionPage(
          key: routeKey,
          embedded: true,
          editorOnly: true,
          initialId: id,
        );
      case 'orders':
        return PurchaseOrderPage(
          key: routeKey,
          embedded: true,
          editorOnly: true,
          initialId: id,
        );
      case 'receipts':
        return PurchaseReceiptPage(
          key: routeKey,
          embedded: true,
          editorOnly: true,
          initialId: id,
        );
      case 'invoices':
        return PurchaseInvoicePage(
          key: routeKey,
          embedded: true,
          editorOnly: true,
          initialId: id,
        );
      case 'payments':
        return PurchasePaymentPage(
          key: routeKey,
          embedded: true,
          editorOnly: true,
          initialId: id,
          initialPurchaseInvoiceId: int.tryParse(
            _currentQueryParameters['invoice_id'] ?? '',
          ),
        );
      case 'returns':
        return PurchaseReturnPage(
          key: routeKey,
          embedded: true,
          editorOnly: true,
          initialId: id,
        );
    }
    return null;
  }

  String _titleForPath(String path, AuthContextModel? authContext) {
    final navigationTitle = AppNavigation.findByPath(path)?.title.trim();
    if ((navigationTitle ?? '').isNotEmpty) {
      return navigationTitle!;
    }

    for (final module in authContext?.menuModules ?? const []) {
      final routePath = module.routePath?.trim();
      final moduleName = module.moduleName?.trim();
      if (routePath == path && (moduleName ?? '').isNotEmpty) {
        return moduleName!;
      }
    }

    if (path.startsWith('/parties/')) {
      return 'Parties';
    }
    if (path.startsWith('/purchase/requisitions/')) {
      return 'Purchase Requisition';
    }
    if (path.startsWith('/purchase/orders/')) {
      return 'Purchase Order';
    }
    if (path.startsWith('/purchase/receipts/')) {
      return 'Purchase Receipt';
    }
    if (path.startsWith('/purchase/invoices/')) {
      return 'Purchase Invoice';
    }
    if (path.startsWith('/purchase/payments/')) {
      return 'Purchase Payment';
    }
    if (path.startsWith('/purchase/returns/')) {
      return 'Purchase Return';
    }
    if (path.startsWith('/sales/quotations/')) {
      return 'Sales Quotation';
    }
    if (path.startsWith('/sales/orders/')) {
      return 'Sales Order';
    }
    if (path.startsWith('/sales/invoices/')) {
      return 'Sales Invoice';
    }
    if (path.startsWith('/sales/deliveries/')) {
      return 'Sales Delivery';
    }
    if (path.startsWith('/sales/receipts/')) {
      return 'Sales Receipt';
    }
    if (path.startsWith('/sales/returns/')) {
      return 'Sales Return';
    }
    return 'Module';
  }

  bool _sameQuery(Map<String, String> left, Map<String, String> right) {
    if (left.length != right.length) {
      return false;
    }

    for (final entry in left.entries) {
      if (right[entry.key] != entry.value) {
        return false;
      }
    }

    return true;
  }
}
