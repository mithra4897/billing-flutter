/// REST paths appended after [AppConfig.apiPrefix] (default `/api/v1`).
///
/// Canonical backend definitions: `billing-api/routes/*.php`.
/// Route inventory for Phase A modules: `billing-api/doc/contracts/phase_a_routes.md`.
class ApiEndpoints {
  const ApiEndpoints._();

  // --- Auth & session ---
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';
  static const String authContext = '/auth/context';

  // --- Masters ---
  static const String companies = '/masters/companies';
  static const String branches = '/masters/branches';
  static const String businessLocations = '/masters/business-locations';
  static const String warehouses = '/masters/warehouses';
  static const String financialYears = '/masters/financial-years';
  static const String documentSeries = '/masters/document-series';
  static const String printTemplates = '/masters/print-templates';

  static const String parties = '/parties';
  static const String partyAddresses = '/parties/addresses';
  static const String partyContacts = '/parties/contacts';

  // --- Accounting (`routes/accounts.php`) ---
  static const String _acct = '/accounting';

  static const String accountGroups = '$_acct/account-groups';
  static const String accountGroupsListAll = '$_acct/account-groups/list/all';
  static const String accounts = '$_acct/accounts';
  static const String accountsListAll = '$_acct/accounts/list/all';
  static const String voucherTypes = '$_acct/voucher-types';
  static const String voucherTypesListAll = '$_acct/voucher-types/list/all';
  static const String postingRuleGroups = '$_acct/posting-rule-groups';
  static const String postingRuleGroupsListAll =
      '$_acct/posting-rule-groups/list/all';
  static const String postingRules = '$_acct/posting-rules';
  static const String postingRulesListAll = '$_acct/posting-rules/list/all';
  static const String documentPostings = '$_acct/document-postings';
  static const String documentPostingsListAll =
      '$_acct/document-postings/list/all';
  static const String partyAccounts = '$_acct/party-accounts';
  static const String partyAccountsDefault = '$_acct/party-accounts/default';
  static const String budgets = '$_acct/budgets';
  static const String vouchers = '$_acct/vouchers';
  static const String vouchersListAll = '$_acct/vouchers/list/all';
  static const String voucherAllocations = '$_acct/voucher-allocations';
  static const String cashSessions = '$_acct/cash-sessions';
  static const String cashSessionsOpen = '$_acct/cash-sessions/open';
  static const String bankReconciliation = '$_acct/bank-reconciliation';
  static const String reportsDayBook = '$_acct/reports/day-book';
  static const String reportsGeneralLedger = '$_acct/reports/general-ledger';
  static const String reportsAccountsReceivableAging =
      '$_acct/reports/accounts-receivable-aging';
  static const String reportsAccountsPayableAging =
      '$_acct/reports/accounts-payable-aging';
  static const String reportsBalanceSheet = '$_acct/reports/balance-sheet';
  static const String reportsProfitLoss = '$_acct/reports/profit-loss';
  static const String reportsTrialBalance = '$_acct/reports/trial-balance';
  static const String reportsCashFlow = '$_acct/reports/cash-flow';
  static const String reportsFinancialStatements =
      '$_acct/reports/financial-statements';

  // --- Inventory (`routes/inventory.php`) ---
  static const String _inv = '/inventory';

  static const String itemCategories = '$_inv/item-categories';
  static const String itemCategoriesDropdown = '$_inv/item-categories/dropdown';
  static const String brands = '$_inv/brands';
  static const String brandsDropdown = '$_inv/brands/dropdown';
  static const String uoms = '$_inv/uoms';
  static const String uomsDropdown = '$_inv/uoms/dropdown';
  static const String uomConversions = '$_inv/uom-conversions';
  static const String uomConversionsAll = '$_inv/uom-conversions/all';
  static const String uomConversionsFactor = '$_inv/uom-conversions/factor';
  static const String taxCodes = '$_inv/tax-codes';
  static const String taxCodesDropdown = '$_inv/tax-codes/dropdown';
  static const String items = '$_inv/items';
  static const String itemsDropdown = '$_inv/items/dropdown';
  static const String itemSupplierMaps = '$_inv/item-supplier-maps';
  static const String itemSupplierMapsDropdown =
      '$_inv/item-supplier-maps/dropdown';
  static const String itemAlternates = '$_inv/item-alternates';
  static const String itemAlternatesDropdown = '$_inv/item-alternates/dropdown';
  static const String itemPrices = '$_inv/item-prices';
  static const String itemPricesDropdown = '$_inv/item-prices/dropdown';
  static const String stockBatches = '$_inv/stock-batches';
  static const String stockBatchesDropdown = '$_inv/stock-batches/dropdown';
  static const String stockSerials = '$_inv/stock-serials';
  static const String stockSerialsDropdown = '$_inv/stock-serials/dropdown';
  static const String stockMovements = '$_inv/stock-movements';
  static const String stockMovementsDropdown = '$_inv/stock-movements/dropdown';
  static const String stockBalances = '$_inv/stock-balances';
  static const String stockBalancesDropdown = '$_inv/stock-balances/dropdown';
  static const String inventoryAdjustments = '$_inv/inventory-adjustments';
  static const String openingStocks = '$_inv/opening-stocks';
  static const String stockTransfers = '$_inv/stock-transfers';
  static const String stockIssues = '$_inv/stock-issues';
  static const String internalStockReceipts = '$_inv/internal-stock-receipts';
  static const String stockDamageEntries = '$_inv/stock-damage-entries';
  static const String physicalStockCounts = '$_inv/physical-stock-counts';
  static const String inquiryStockSummary = '$_inv/inquiry/stock-summary';
  static const String inquiryWarehouseWiseStock =
      '$_inv/inquiry/warehouse-wise-stock';
  static const String inquiryBatchWiseStock = '$_inv/inquiry/batch-wise-stock';
  static const String inquiryAvailableSerials =
      '$_inv/inquiry/available-serials';
  static const String inquiryStockCard = '$_inv/inquiry/stock-card';
  static const String inquiryReorderStatus = '$_inv/inquiry/reorder-status';

  // --- Purchase (`routes/purchase.php`) ---
  static const String _pur = '/purchase';

  static const String purchaseRequisitions = '$_pur/requisitions';
  static const String purchaseRequisitionsAll = '$_pur/requisitions/all';
  static const String purchaseOrders = '$_pur/orders';
  static const String purchaseOrdersAll = '$_pur/orders/all';
  static const String purchaseReceipts = '$_pur/receipts';
  static const String purchaseReceiptsAll = '$_pur/receipts/all';
  static const String purchaseInvoices = '$_pur/invoices';
  static const String purchaseInvoicesAll = '$_pur/invoices/all';
  static const String purchasePayments = '$_pur/payments';
  static const String purchasePaymentsAll = '$_pur/payments/all';
  static const String purchaseReturns = '$_pur/returns';
  static const String purchaseReturnsAll = '$_pur/returns/all';

  // --- CRM (`routes/crm.php`) ---
  static const String _crm = '/crm';

  static const String crmSources = '$_crm/sources';
  static const String crmStages = '$_crm/stages';
  static const String crmLeads = '$_crm/leads';
  static const String crmEnquiries = '$_crm/enquiries';
  static const String crmPendingFollowups = '$_crm/enquiries/pending-followups';
  static const String crmOpportunities = '$_crm/opportunities';
  static const String crmSalesChain = '$_crm/sales-chain';

  // --- Sales (partial; extend as services migrate) ---
  static const String _sales = '/sales';

  static const String salesSalesChain = '$_sales/sales-chain';
  static const String salesInvoices = '$_sales/invoices';
  static const String salesOrders = '$_sales/orders';
  static const String salesQuotations = '$_sales/quotations';

  // --- Other ---
  static const String mediaFiles = '/media/files';
  static const String emailTemplates = '/communication/email-templates';
  static const String emailRules = '/communication/email-rules';
  static const String emailMessages = '/communication/email-messages';
}
