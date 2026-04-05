import '../../core/api/api_endpoints.dart';
import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/accounting/account_model.dart';
import '../../model/accounting/voucher_model.dart';
import '../../model/common/erp_record_model.dart';
import '../base/erp_module_service.dart';

class AccountsService extends ErpModuleService {
  AccountsService({super.apiClient});

  Future<PaginatedResponse<ErpRecordModel>> accountGroups({
    Map<String, dynamic>? filters,
  }) => index('/accounting/account-groups', filters: filters);
  Future<ApiResponse<List<ErpRecordModel>>> accountGroupsAll({
    Map<String, dynamic>? filters,
  }) => list('/accounting/account-groups/list/all', filters: filters);
  Future<ApiResponse<ErpRecordModel>> accountGroup(int id) =>
      show('/accounting/account-groups/$id');
  Future<ApiResponse<ErpRecordModel>> createAccountGroup(ErpRecordModel body) =>
      store('/accounting/account-groups', body);
  Future<ApiResponse<ErpRecordModel>> updateAccountGroup(
    int id,
    ErpRecordModel body,
  ) => update('/accounting/account-groups/$id', body);
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

  Future<ApiResponse<List<ErpRecordModel>>> accountsAll({
    Map<String, dynamic>? filters,
  }) => list('/accounting/accounts/list/all', filters: filters);
  Future<ApiResponse<ErpRecordModel>> account(int id) =>
      show('/accounting/accounts/$id');
  Future<ApiResponse<ErpRecordModel>> createAccount(ErpRecordModel body) =>
      store('/accounting/accounts', body);
  Future<ApiResponse<ErpRecordModel>> updateAccount(
    int id,
    ErpRecordModel body,
  ) => update('/accounting/accounts/$id', body);
  Future<ApiResponse<dynamic>> deleteAccount(int id) =>
      destroy('/accounting/accounts/$id');

  Future<PaginatedResponse<ErpRecordModel>> voucherTypes({
    Map<String, dynamic>? filters,
  }) => index('/accounting/voucher-types', filters: filters);
  Future<ApiResponse<List<ErpRecordModel>>> voucherTypesAll({
    Map<String, dynamic>? filters,
  }) => list('/accounting/voucher-types/list/all', filters: filters);
  Future<ApiResponse<ErpRecordModel>> voucherType(int id) =>
      show('/accounting/voucher-types/$id');
  Future<ApiResponse<ErpRecordModel>> createVoucherType(ErpRecordModel body) =>
      store('/accounting/voucher-types', body);
  Future<ApiResponse<ErpRecordModel>> updateVoucherType(
    int id,
    ErpRecordModel body,
  ) => update('/accounting/voucher-types/$id', body);
  Future<ApiResponse<dynamic>> deleteVoucherType(int id) =>
      destroy('/accounting/voucher-types/$id');

  Future<PaginatedResponse<ErpRecordModel>> postingRuleGroups({
    Map<String, dynamic>? filters,
  }) => index('/accounting/posting-rule-groups', filters: filters);
  Future<ApiResponse<List<ErpRecordModel>>> postingRuleGroupsAll({
    Map<String, dynamic>? filters,
  }) => list('/accounting/posting-rule-groups/list/all', filters: filters);
  Future<ApiResponse<ErpRecordModel>> postingRuleGroup(int id) =>
      show('/accounting/posting-rule-groups/$id');
  Future<ApiResponse<ErpRecordModel>> createPostingRuleGroup(
    ErpRecordModel body,
  ) => store('/accounting/posting-rule-groups', body);
  Future<ApiResponse<ErpRecordModel>> updatePostingRuleGroup(
    int id,
    ErpRecordModel body,
  ) => update('/accounting/posting-rule-groups/$id', body);
  Future<ApiResponse<dynamic>> deletePostingRuleGroup(int id) =>
      destroy('/accounting/posting-rule-groups/$id');

  Future<PaginatedResponse<ErpRecordModel>> postingRules({
    Map<String, dynamic>? filters,
  }) => index('/accounting/posting-rules', filters: filters);
  Future<ApiResponse<List<ErpRecordModel>>> postingRulesAll({
    Map<String, dynamic>? filters,
  }) => list('/accounting/posting-rules/list/all', filters: filters);
  Future<ApiResponse<ErpRecordModel>> postingRule(int id) =>
      show('/accounting/posting-rules/$id');
  Future<ApiResponse<ErpRecordModel>> createPostingRule(ErpRecordModel body) =>
      store('/accounting/posting-rules', body);
  Future<ApiResponse<ErpRecordModel>> updatePostingRule(
    int id,
    ErpRecordModel body,
  ) => update('/accounting/posting-rules/$id', body);
  Future<ApiResponse<dynamic>> deletePostingRule(int id) =>
      destroy('/accounting/posting-rules/$id');

  Future<PaginatedResponse<ErpRecordModel>> documentPostings({
    Map<String, dynamic>? filters,
  }) => index('/accounting/document-postings', filters: filters);
  Future<ApiResponse<List<ErpRecordModel>>> documentPostingsAll({
    Map<String, dynamic>? filters,
  }) => list('/accounting/document-postings/list/all', filters: filters);
  Future<ApiResponse<ErpRecordModel>> documentPosting(int id) =>
      show('/accounting/document-postings/$id');
  Future<ApiResponse<ErpRecordModel>> createDocumentPosting(
    ErpRecordModel body,
  ) => store('/accounting/document-postings', body);
  Future<ApiResponse<ErpRecordModel>> updateDocumentPosting(
    int id,
    ErpRecordModel body,
  ) => update('/accounting/document-postings/$id', body);
  Future<ApiResponse<dynamic>> deleteDocumentPosting(int id) =>
      destroy('/accounting/document-postings/$id');

  Future<PaginatedResponse<ErpRecordModel>> partyAccounts({
    Map<String, dynamic>? filters,
  }) => index('/accounting/party-accounts', filters: filters);
  Future<ApiResponse<ErpRecordModel>> defaultPartyAccount({
    Map<String, dynamic>? filters,
  }) => show('/accounting/party-accounts/default');
  Future<ApiResponse<ErpRecordModel>> partyAccount(int id) =>
      show('/accounting/party-accounts/$id');
  Future<ApiResponse<ErpRecordModel>> createPartyAccount(ErpRecordModel body) =>
      store('/accounting/party-accounts', body);
  Future<ApiResponse<ErpRecordModel>> updatePartyAccount(
    int id,
    ErpRecordModel body,
  ) => update('/accounting/party-accounts/$id', body);
  Future<ApiResponse<dynamic>> deletePartyAccount(int id) =>
      destroy('/accounting/party-accounts/$id');

  Future<PaginatedResponse<ErpRecordModel>> budgets({
    Map<String, dynamic>? filters,
  }) => index('/accounting/budgets', filters: filters);
  Future<ApiResponse<ErpRecordModel>> budget(int id) =>
      show('/accounting/budgets/$id');
  Future<ApiResponse<ErpRecordModel>> createBudget(ErpRecordModel body) =>
      store('/accounting/budgets', body);
  Future<ApiResponse<ErpRecordModel>> updateBudget(
    int id,
    ErpRecordModel body,
  ) => update('/accounting/budgets/$id', body);
  Future<ApiResponse<dynamic>> deleteBudget(int id) =>
      destroy('/accounting/budgets/$id');
  Future<ApiResponse<ErpRecordModel>> budgetVsActual(
    int id, {
    Map<String, dynamic>? filters,
  }) => show('/accounting/budgets/$id/vs-actual');

  Future<PaginatedResponse<VoucherModel>> vouchers({
    Map<String, dynamic>? filters,
  }) {
    return client.getPaginated<VoucherModel>(
      ApiEndpoints.vouchers,
      queryParameters: filters,
      itemFromJson: VoucherModel.fromJson,
    );
  }

  Future<ApiResponse<List<ErpRecordModel>>> vouchersAll({
    Map<String, dynamic>? filters,
  }) => list('/accounting/vouchers/list/all', filters: filters);
  Future<ApiResponse<VoucherModel>> voucher(int id) {
    return client.get<VoucherModel>(
      '${ApiEndpoints.vouchers}/$id',
      fromData: (json) => VoucherModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<ErpRecordModel>> createVoucher(ErpRecordModel body) =>
      store('/accounting/vouchers', body);
  Future<ApiResponse<ErpRecordModel>> updateVoucher(
    int id,
    ErpRecordModel body,
  ) => update('/accounting/vouchers/$id', body);

  Future<PaginatedResponse<ErpRecordModel>> voucherAllocations({
    Map<String, dynamic>? filters,
  }) => index('/accounting/voucher-allocations', filters: filters);
  Future<ApiResponse<ErpRecordModel>> voucherAllocation(int id) =>
      show('/accounting/voucher-allocations/$id');
  Future<ApiResponse<ErpRecordModel>> createVoucherAllocation(
    ErpRecordModel body,
  ) => store('/accounting/voucher-allocations', body);
  Future<ApiResponse<ErpRecordModel>> updateVoucherAllocation(
    int id,
    ErpRecordModel body,
  ) => update('/accounting/voucher-allocations/$id', body);
  Future<ApiResponse<dynamic>> deleteVoucherAllocation(int id) =>
      destroy('/accounting/voucher-allocations/$id');

  Future<PaginatedResponse<ErpRecordModel>> cashSessions({
    Map<String, dynamic>? filters,
  }) => index('/accounting/cash-sessions', filters: filters);
  Future<ApiResponse<ErpRecordModel>> cashSession(int id) =>
      show('/accounting/cash-sessions/$id');
  Future<ApiResponse<ErpRecordModel>> openCashSession(ErpRecordModel body) =>
      action('/accounting/cash-sessions/open', body: body);
  Future<ApiResponse<ErpRecordModel>> closeCashSession(
    int id,
    ErpRecordModel body,
  ) => action('/accounting/cash-sessions/$id/close', body: body);
  Future<ApiResponse<ErpRecordModel>> cancelCashSession(
    int id,
    ErpRecordModel body,
  ) => action('/accounting/cash-sessions/$id/cancel', body: body);

  Future<PaginatedResponse<ErpRecordModel>> bankReconciliation({
    Map<String, dynamic>? filters,
  }) => index('/accounting/bank-reconciliation', filters: filters);
  Future<ApiResponse<ErpRecordModel>> bankReconciliationEntry(int id) =>
      show('/accounting/bank-reconciliation/$id');
  Future<ApiResponse<ErpRecordModel>> createBankReconciliation(
    ErpRecordModel body,
  ) => store('/accounting/bank-reconciliation', body);
  Future<ApiResponse<ErpRecordModel>> updateBankReconciliation(
    int id,
    ErpRecordModel body,
  ) => update('/accounting/bank-reconciliation/$id', body);
  Future<ApiResponse<dynamic>> deleteBankReconciliation(int id) =>
      destroy('/accounting/bank-reconciliation/$id');

  Future<PaginatedResponse<ErpRecordModel>> reportGeneralLedger({
    Map<String, dynamic>? filters,
  }) => index('/accounting/reports/general-ledger', filters: filters);
  Future<PaginatedResponse<ErpRecordModel>> reportAccountsReceivableAging({
    Map<String, dynamic>? filters,
  }) =>
      index('/accounting/reports/accounts-receivable-aging', filters: filters);
  Future<PaginatedResponse<ErpRecordModel>> reportAccountsPayableAging({
    Map<String, dynamic>? filters,
  }) => index('/accounting/reports/accounts-payable-aging', filters: filters);
  Future<PaginatedResponse<ErpRecordModel>> reportBalanceSheet({
    Map<String, dynamic>? filters,
  }) => index('/accounting/reports/balance-sheet', filters: filters);
  Future<PaginatedResponse<ErpRecordModel>> reportProfitAndLoss({
    Map<String, dynamic>? filters,
  }) => index('/accounting/reports/profit-loss', filters: filters);
  Future<PaginatedResponse<ErpRecordModel>> reportTrialBalance({
    Map<String, dynamic>? filters,
  }) => index('/accounting/reports/trial-balance', filters: filters);
  Future<PaginatedResponse<ErpRecordModel>> reportCashFlow({
    Map<String, dynamic>? filters,
  }) => index('/accounting/reports/cash-flow', filters: filters);
  Future<PaginatedResponse<ErpRecordModel>> reportFinancialStatements({
    Map<String, dynamic>? filters,
  }) => index('/accounting/reports/financial-statements', filters: filters);
}
