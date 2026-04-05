import '../../core/api/api_endpoints.dart';
import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/accounting/account_group_model.dart';
import '../../model/accounting/account_model.dart';
import '../../model/accounting/bank_reconciliation_model.dart';
import '../../model/accounting/budget_vs_actual_model.dart';
import '../../model/accounting/budget_model.dart';
import '../../model/accounting/cash_session_model.dart';
import '../../model/accounting/document_posting_model.dart';
import '../../model/accounting/party_account_model.dart';
import '../../model/accounting/posting_rule_group_model.dart';
import '../../model/accounting/posting_rule_model.dart';
import '../../model/accounting/voucher_allocation_model.dart';
import '../../model/accounting/voucher_model.dart';
import '../../model/accounting/voucher_type_model.dart';
import '../../model/common/erp_report_row_model.dart';
import '../base/erp_module_service.dart';

class AccountsService extends ErpModuleService {
  AccountsService({super.apiClient});

  Future<PaginatedResponse<AccountGroupModel>> accountGroups({
    Map<String, dynamic>? filters,
  }) => paginated<AccountGroupModel>(
    '/accounting/account-groups',
    filters: filters,
    fromJson: AccountGroupModel.fromJson,
  );

  Future<ApiResponse<List<AccountGroupModel>>> accountGroupsAll({
    Map<String, dynamic>? filters,
  }) => collection<AccountGroupModel>(
    '/accounting/account-groups/list/all',
    filters: filters,
    fromJson: AccountGroupModel.fromJson,
  );

  Future<ApiResponse<AccountGroupModel>> accountGroup(int id) =>
      object<AccountGroupModel>(
        '/accounting/account-groups/$id',
        fromJson: AccountGroupModel.fromJson,
      );

  Future<ApiResponse<AccountGroupModel>> createAccountGroup(
    AccountGroupModel body,
  ) => createModel<AccountGroupModel>(
    '/accounting/account-groups',
    body,
    fromJson: AccountGroupModel.fromJson,
  );

  Future<ApiResponse<AccountGroupModel>> updateAccountGroup(
    int id,
    AccountGroupModel body,
  ) => updateModel<AccountGroupModel>(
    '/accounting/account-groups/$id',
    body,
    fromJson: AccountGroupModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deleteAccountGroup(int id) =>
      destroy('/accounting/account-groups/$id');

  Future<PaginatedResponse<AccountModel>> accounts({
    Map<String, dynamic>? filters,
  }) {
    return client.getPaginated<AccountModel>(
      ApiEndpoints.accounts,
      queryParameters: filters,
      itemFromJson: AccountModel.fromJson,
    );
  }

  Future<ApiResponse<List<AccountModel>>> accountsAll({
    Map<String, dynamic>? filters,
  }) => collection<AccountModel>(
    '/accounting/accounts/list/all',
    filters: filters,
    fromJson: AccountModel.fromJson,
  );

  Future<ApiResponse<AccountModel>> account(int id) => object<AccountModel>(
    '/accounting/accounts/$id',
    fromJson: AccountModel.fromJson,
  );

  Future<ApiResponse<AccountModel>> createAccount(AccountModel body) =>
      createModel<AccountModel>(
        '/accounting/accounts',
        body,
        fromJson: AccountModel.fromJson,
      );

  Future<ApiResponse<AccountModel>> updateAccount(int id, AccountModel body) =>
      updateModel<AccountModel>(
        '/accounting/accounts/$id',
        body,
        fromJson: AccountModel.fromJson,
      );

  Future<ApiResponse<dynamic>> deleteAccount(int id) =>
      destroy('/accounting/accounts/$id');

  Future<PaginatedResponse<VoucherTypeModel>> voucherTypes({
    Map<String, dynamic>? filters,
  }) => paginated<VoucherTypeModel>(
    '/accounting/voucher-types',
    filters: filters,
    fromJson: VoucherTypeModel.fromJson,
  );

  Future<ApiResponse<List<VoucherTypeModel>>> voucherTypesAll({
    Map<String, dynamic>? filters,
  }) => collection<VoucherTypeModel>(
    '/accounting/voucher-types/list/all',
    filters: filters,
    fromJson: VoucherTypeModel.fromJson,
  );

  Future<ApiResponse<VoucherTypeModel>> voucherType(int id) =>
      object<VoucherTypeModel>(
        '/accounting/voucher-types/$id',
        fromJson: VoucherTypeModel.fromJson,
      );

  Future<ApiResponse<VoucherTypeModel>> createVoucherType(
    VoucherTypeModel body,
  ) => createModel<VoucherTypeModel>(
    '/accounting/voucher-types',
    body,
    fromJson: VoucherTypeModel.fromJson,
  );

  Future<ApiResponse<VoucherTypeModel>> updateVoucherType(
    int id,
    VoucherTypeModel body,
  ) => updateModel<VoucherTypeModel>(
    '/accounting/voucher-types/$id',
    body,
    fromJson: VoucherTypeModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deleteVoucherType(int id) =>
      destroy('/accounting/voucher-types/$id');

  Future<PaginatedResponse<PostingRuleGroupModel>> postingRuleGroups({
    Map<String, dynamic>? filters,
  }) => paginated<PostingRuleGroupModel>(
    '/accounting/posting-rule-groups',
    filters: filters,
    fromJson: PostingRuleGroupModel.fromJson,
  );

  Future<ApiResponse<List<PostingRuleGroupModel>>> postingRuleGroupsAll({
    Map<String, dynamic>? filters,
  }) => collection<PostingRuleGroupModel>(
    '/accounting/posting-rule-groups/list/all',
    filters: filters,
    fromJson: PostingRuleGroupModel.fromJson,
  );

  Future<ApiResponse<PostingRuleGroupModel>> postingRuleGroup(int id) =>
      object<PostingRuleGroupModel>(
        '/accounting/posting-rule-groups/$id',
        fromJson: PostingRuleGroupModel.fromJson,
      );

  Future<ApiResponse<PostingRuleGroupModel>> createPostingRuleGroup(
    PostingRuleGroupModel body,
  ) => createModel<PostingRuleGroupModel>(
    '/accounting/posting-rule-groups',
    body,
    fromJson: PostingRuleGroupModel.fromJson,
  );

  Future<ApiResponse<PostingRuleGroupModel>> updatePostingRuleGroup(
    int id,
    PostingRuleGroupModel body,
  ) => updateModel<PostingRuleGroupModel>(
    '/accounting/posting-rule-groups/$id',
    body,
    fromJson: PostingRuleGroupModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deletePostingRuleGroup(int id) =>
      destroy('/accounting/posting-rule-groups/$id');

  Future<PaginatedResponse<PostingRuleModel>> postingRules({
    Map<String, dynamic>? filters,
  }) => paginated<PostingRuleModel>(
    '/accounting/posting-rules',
    filters: filters,
    fromJson: PostingRuleModel.fromJson,
  );

  Future<ApiResponse<List<PostingRuleModel>>> postingRulesAll({
    Map<String, dynamic>? filters,
  }) => collection<PostingRuleModel>(
    '/accounting/posting-rules/list/all',
    filters: filters,
    fromJson: PostingRuleModel.fromJson,
  );

  Future<ApiResponse<PostingRuleModel>> postingRule(int id) =>
      object<PostingRuleModel>(
        '/accounting/posting-rules/$id',
        fromJson: PostingRuleModel.fromJson,
      );

  Future<ApiResponse<PostingRuleModel>> createPostingRule(
    PostingRuleModel body,
  ) => createModel<PostingRuleModel>(
    '/accounting/posting-rules',
    body,
    fromJson: PostingRuleModel.fromJson,
  );

  Future<ApiResponse<PostingRuleModel>> updatePostingRule(
    int id,
    PostingRuleModel body,
  ) => updateModel<PostingRuleModel>(
    '/accounting/posting-rules/$id',
    body,
    fromJson: PostingRuleModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deletePostingRule(int id) =>
      destroy('/accounting/posting-rules/$id');

  Future<PaginatedResponse<DocumentPostingModel>> documentPostings({
    Map<String, dynamic>? filters,
  }) => paginated<DocumentPostingModel>(
    '/accounting/document-postings',
    filters: filters,
    fromJson: DocumentPostingModel.fromJson,
  );

  Future<ApiResponse<List<DocumentPostingModel>>> documentPostingsAll({
    Map<String, dynamic>? filters,
  }) => collection<DocumentPostingModel>(
    '/accounting/document-postings/list/all',
    filters: filters,
    fromJson: DocumentPostingModel.fromJson,
  );

  Future<ApiResponse<DocumentPostingModel>> documentPosting(int id) =>
      object<DocumentPostingModel>(
        '/accounting/document-postings/$id',
        fromJson: DocumentPostingModel.fromJson,
      );

  Future<ApiResponse<DocumentPostingModel>> createDocumentPosting(
    DocumentPostingModel body,
  ) => createModel<DocumentPostingModel>(
    '/accounting/document-postings',
    body,
    fromJson: DocumentPostingModel.fromJson,
  );

  Future<ApiResponse<DocumentPostingModel>> updateDocumentPosting(
    int id,
    DocumentPostingModel body,
  ) => updateModel<DocumentPostingModel>(
    '/accounting/document-postings/$id',
    body,
    fromJson: DocumentPostingModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deleteDocumentPosting(int id) =>
      destroy('/accounting/document-postings/$id');

  Future<PaginatedResponse<PartyAccountModel>> partyAccounts({
    Map<String, dynamic>? filters,
  }) => paginated<PartyAccountModel>(
    '/accounting/party-accounts',
    filters: filters,
    fromJson: PartyAccountModel.fromJson,
  );

  Future<ApiResponse<PartyAccountModel>> defaultPartyAccount({
    Map<String, dynamic>? filters,
  }) => object<PartyAccountModel>(
    '/accounting/party-accounts/default',
    fromJson: PartyAccountModel.fromJson,
  );

  Future<ApiResponse<PartyAccountModel>> partyAccount(int id) =>
      object<PartyAccountModel>(
        '/accounting/party-accounts/$id',
        fromJson: PartyAccountModel.fromJson,
      );

  Future<ApiResponse<PartyAccountModel>> createPartyAccount(
    PartyAccountModel body,
  ) => createModel<PartyAccountModel>(
    '/accounting/party-accounts',
    body,
    fromJson: PartyAccountModel.fromJson,
  );

  Future<ApiResponse<PartyAccountModel>> updatePartyAccount(
    int id,
    PartyAccountModel body,
  ) => updateModel<PartyAccountModel>(
    '/accounting/party-accounts/$id',
    body,
    fromJson: PartyAccountModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deletePartyAccount(int id) =>
      destroy('/accounting/party-accounts/$id');

  Future<PaginatedResponse<BudgetModel>> budgets({
    Map<String, dynamic>? filters,
  }) => paginated<BudgetModel>(
    '/accounting/budgets',
    filters: filters,
    fromJson: BudgetModel.fromJson,
  );

  Future<ApiResponse<BudgetModel>> budget(int id) => object<BudgetModel>(
    '/accounting/budgets/$id',
    fromJson: BudgetModel.fromJson,
  );

  Future<ApiResponse<BudgetModel>> createBudget(BudgetModel body) =>
      createModel<BudgetModel>(
        '/accounting/budgets',
        body,
        fromJson: BudgetModel.fromJson,
      );

  Future<ApiResponse<BudgetModel>> updateBudget(int id, BudgetModel body) =>
      updateModel<BudgetModel>(
        '/accounting/budgets/$id',
        body,
        fromJson: BudgetModel.fromJson,
      );

  Future<ApiResponse<dynamic>> deleteBudget(int id) =>
      destroy('/accounting/budgets/$id');

  Future<ApiResponse<BudgetVsActualModel>> budgetVsActual(
    int id, {
    Map<String, dynamic>? filters,
  }) => object<BudgetVsActualModel>(
    '/accounting/budgets/$id/vs-actual',
    fromJson: BudgetVsActualModel.fromJson,
  );

  Future<PaginatedResponse<VoucherModel>> vouchers({
    Map<String, dynamic>? filters,
  }) {
    return client.getPaginated<VoucherModel>(
      ApiEndpoints.vouchers,
      queryParameters: filters,
      itemFromJson: VoucherModel.fromJson,
    );
  }

  Future<ApiResponse<List<VoucherModel>>> vouchersAll({
    Map<String, dynamic>? filters,
  }) => collection<VoucherModel>(
    '/accounting/vouchers/list/all',
    filters: filters,
    fromJson: VoucherModel.fromJson,
  );

  Future<ApiResponse<VoucherModel>> voucher(int id) {
    return client.get<VoucherModel>(
      '${ApiEndpoints.vouchers}/$id',
      fromData: (json) => VoucherModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<VoucherModel>> createVoucher(VoucherModel body) =>
      createModel<VoucherModel>(
        '/accounting/vouchers',
        body,
        fromJson: VoucherModel.fromJson,
      );

  Future<ApiResponse<VoucherModel>> updateVoucher(int id, VoucherModel body) =>
      updateModel<VoucherModel>(
        '/accounting/vouchers/$id',
        body,
        fromJson: VoucherModel.fromJson,
      );

  Future<PaginatedResponse<VoucherAllocationModel>> voucherAllocations({
    Map<String, dynamic>? filters,
  }) => paginated<VoucherAllocationModel>(
    '/accounting/voucher-allocations',
    filters: filters,
    fromJson: VoucherAllocationModel.fromJson,
  );

  Future<ApiResponse<VoucherAllocationModel>> voucherAllocation(int id) =>
      object<VoucherAllocationModel>(
        '/accounting/voucher-allocations/$id',
        fromJson: VoucherAllocationModel.fromJson,
      );

  Future<ApiResponse<VoucherAllocationModel>> createVoucherAllocation(
    VoucherAllocationModel body,
  ) => createModel<VoucherAllocationModel>(
    '/accounting/voucher-allocations',
    body,
    fromJson: VoucherAllocationModel.fromJson,
  );

  Future<ApiResponse<VoucherAllocationModel>> updateVoucherAllocation(
    int id,
    VoucherAllocationModel body,
  ) => updateModel<VoucherAllocationModel>(
    '/accounting/voucher-allocations/$id',
    body,
    fromJson: VoucherAllocationModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deleteVoucherAllocation(int id) =>
      destroy('/accounting/voucher-allocations/$id');

  Future<PaginatedResponse<CashSessionModel>> cashSessions({
    Map<String, dynamic>? filters,
  }) => paginated<CashSessionModel>(
    '/accounting/cash-sessions',
    filters: filters,
    fromJson: CashSessionModel.fromJson,
  );

  Future<ApiResponse<CashSessionModel>> cashSession(int id) =>
      object<CashSessionModel>(
        '/accounting/cash-sessions/$id',
        fromJson: CashSessionModel.fromJson,
      );

  Future<ApiResponse<CashSessionModel>> openCashSession(
    CashSessionModel body,
  ) => actionModel<CashSessionModel>(
    '/accounting/cash-sessions/open',
    body: body,
    fromJson: CashSessionModel.fromJson,
  );

  Future<ApiResponse<CashSessionModel>> closeCashSession(
    int id,
    CashSessionModel body,
  ) => actionModel<CashSessionModel>(
    '/accounting/cash-sessions/$id/close',
    body: body,
    fromJson: CashSessionModel.fromJson,
  );

  Future<ApiResponse<CashSessionModel>> cancelCashSession(
    int id,
    CashSessionModel body,
  ) => actionModel<CashSessionModel>(
    '/accounting/cash-sessions/$id/cancel',
    body: body,
    fromJson: CashSessionModel.fromJson,
  );

  Future<PaginatedResponse<BankReconciliationModel>> bankReconciliation({
    Map<String, dynamic>? filters,
  }) => paginated<BankReconciliationModel>(
    '/accounting/bank-reconciliation',
    filters: filters,
    fromJson: BankReconciliationModel.fromJson,
  );

  Future<ApiResponse<BankReconciliationModel>> bankReconciliationEntry(
    int id,
  ) => object<BankReconciliationModel>(
    '/accounting/bank-reconciliation/$id',
    fromJson: BankReconciliationModel.fromJson,
  );

  Future<ApiResponse<BankReconciliationModel>> createBankReconciliation(
    BankReconciliationModel body,
  ) => createModel<BankReconciliationModel>(
    '/accounting/bank-reconciliation',
    body,
    fromJson: BankReconciliationModel.fromJson,
  );

  Future<ApiResponse<BankReconciliationModel>> updateBankReconciliation(
    int id,
    BankReconciliationModel body,
  ) => updateModel<BankReconciliationModel>(
    '/accounting/bank-reconciliation/$id',
    body,
    fromJson: BankReconciliationModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deleteBankReconciliation(int id) =>
      destroy('/accounting/bank-reconciliation/$id');

  Future<PaginatedResponse<ErpReportRowModel>> reportGeneralLedger({
    Map<String, dynamic>? filters,
  }) => paginated<ErpReportRowModel>(
    '/accounting/reports/general-ledger',
    filters: filters,
    fromJson: ErpReportRowModel.fromJson,
  );

  Future<PaginatedResponse<ErpReportRowModel>> reportAccountsReceivableAging({
    Map<String, dynamic>? filters,
  }) => paginated<ErpReportRowModel>(
    '/accounting/reports/accounts-receivable-aging',
    filters: filters,
    fromJson: ErpReportRowModel.fromJson,
  );

  Future<PaginatedResponse<ErpReportRowModel>> reportAccountsPayableAging({
    Map<String, dynamic>? filters,
  }) => paginated<ErpReportRowModel>(
    '/accounting/reports/accounts-payable-aging',
    filters: filters,
    fromJson: ErpReportRowModel.fromJson,
  );

  Future<PaginatedResponse<ErpReportRowModel>> reportBalanceSheet({
    Map<String, dynamic>? filters,
  }) => paginated<ErpReportRowModel>(
    '/accounting/reports/balance-sheet',
    filters: filters,
    fromJson: ErpReportRowModel.fromJson,
  );

  Future<PaginatedResponse<ErpReportRowModel>> reportProfitAndLoss({
    Map<String, dynamic>? filters,
  }) => paginated<ErpReportRowModel>(
    '/accounting/reports/profit-loss',
    filters: filters,
    fromJson: ErpReportRowModel.fromJson,
  );

  Future<PaginatedResponse<ErpReportRowModel>> reportTrialBalance({
    Map<String, dynamic>? filters,
  }) => paginated<ErpReportRowModel>(
    '/accounting/reports/trial-balance',
    filters: filters,
    fromJson: ErpReportRowModel.fromJson,
  );

  Future<PaginatedResponse<ErpReportRowModel>> reportCashFlow({
    Map<String, dynamic>? filters,
  }) => paginated<ErpReportRowModel>(
    '/accounting/reports/cash-flow',
    filters: filters,
    fromJson: ErpReportRowModel.fromJson,
  );

  Future<PaginatedResponse<ErpReportRowModel>> reportFinancialStatements({
    Map<String, dynamic>? filters,
  }) => paginated<ErpReportRowModel>(
    '/accounting/reports/financial-statements',
    filters: filters,
    fromJson: ErpReportRowModel.fromJson,
  );
}
