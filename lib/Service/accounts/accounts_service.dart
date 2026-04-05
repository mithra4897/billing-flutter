import '../../core/api/api_endpoints.dart';
import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/accounting/account_model.dart';
import '../../model/accounting/voucher_model.dart';
import '../base/erp_module_service.dart';

class AccountsService extends ErpModuleService {
  AccountsService({super.apiClient});

  Future accountGroups({Map<String, dynamic>? filters}) =>
      index('/accounting/account-groups', filters: filters);
  Future accountGroupsAll({Map<String, dynamic>? filters}) =>
      list('/accounting/account-groups/list/all', filters: filters);
  Future accountGroup(int id) => show('/accounting/account-groups/$id');
  Future createAccountGroup(Map<String, dynamic> body) =>
      store('/accounting/account-groups', body);
  Future updateAccountGroup(int id, Map<String, dynamic> body) =>
      update('/accounting/account-groups/$id', body);
  Future deleteAccountGroup(int id) =>
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

  Future accountsAll({Map<String, dynamic>? filters}) =>
      list('/accounting/accounts/list/all', filters: filters);
  Future account(int id) => show('/accounting/accounts/$id');
  Future createAccount(Map<String, dynamic> body) =>
      store('/accounting/accounts', body);
  Future updateAccount(int id, Map<String, dynamic> body) =>
      update('/accounting/accounts/$id', body);
  Future deleteAccount(int id) => destroy('/accounting/accounts/$id');

  Future voucherTypes({Map<String, dynamic>? filters}) =>
      index('/accounting/voucher-types', filters: filters);
  Future voucherTypesAll({Map<String, dynamic>? filters}) =>
      list('/accounting/voucher-types/list/all', filters: filters);
  Future voucherType(int id) => show('/accounting/voucher-types/$id');
  Future createVoucherType(Map<String, dynamic> body) =>
      store('/accounting/voucher-types', body);
  Future updateVoucherType(int id, Map<String, dynamic> body) =>
      update('/accounting/voucher-types/$id', body);
  Future deleteVoucherType(int id) => destroy('/accounting/voucher-types/$id');

  Future postingRuleGroups({Map<String, dynamic>? filters}) =>
      index('/accounting/posting-rule-groups', filters: filters);
  Future postingRuleGroupsAll({Map<String, dynamic>? filters}) =>
      list('/accounting/posting-rule-groups/list/all', filters: filters);
  Future postingRuleGroup(int id) =>
      show('/accounting/posting-rule-groups/$id');
  Future createPostingRuleGroup(Map<String, dynamic> body) =>
      store('/accounting/posting-rule-groups', body);
  Future updatePostingRuleGroup(int id, Map<String, dynamic> body) =>
      update('/accounting/posting-rule-groups/$id', body);
  Future deletePostingRuleGroup(int id) =>
      destroy('/accounting/posting-rule-groups/$id');

  Future postingRules({Map<String, dynamic>? filters}) =>
      index('/accounting/posting-rules', filters: filters);
  Future postingRulesAll({Map<String, dynamic>? filters}) =>
      list('/accounting/posting-rules/list/all', filters: filters);
  Future postingRule(int id) => show('/accounting/posting-rules/$id');
  Future createPostingRule(Map<String, dynamic> body) =>
      store('/accounting/posting-rules', body);
  Future updatePostingRule(int id, Map<String, dynamic> body) =>
      update('/accounting/posting-rules/$id', body);
  Future deletePostingRule(int id) => destroy('/accounting/posting-rules/$id');

  Future documentPostings({Map<String, dynamic>? filters}) =>
      index('/accounting/document-postings', filters: filters);
  Future documentPostingsAll({Map<String, dynamic>? filters}) =>
      list('/accounting/document-postings/list/all', filters: filters);
  Future documentPosting(int id) => show('/accounting/document-postings/$id');
  Future createDocumentPosting(Map<String, dynamic> body) =>
      store('/accounting/document-postings', body);
  Future updateDocumentPosting(int id, Map<String, dynamic> body) =>
      update('/accounting/document-postings/$id', body);
  Future deleteDocumentPosting(int id) =>
      destroy('/accounting/document-postings/$id');

  Future partyAccounts({Map<String, dynamic>? filters}) =>
      index('/accounting/party-accounts', filters: filters);
  Future defaultPartyAccount({Map<String, dynamic>? filters}) =>
      show('/accounting/party-accounts/default');
  Future partyAccount(int id) => show('/accounting/party-accounts/$id');
  Future createPartyAccount(Map<String, dynamic> body) =>
      store('/accounting/party-accounts', body);
  Future updatePartyAccount(int id, Map<String, dynamic> body) =>
      update('/accounting/party-accounts/$id', body);
  Future deletePartyAccount(int id) =>
      destroy('/accounting/party-accounts/$id');

  Future budgets({Map<String, dynamic>? filters}) =>
      index('/accounting/budgets', filters: filters);
  Future budget(int id) => show('/accounting/budgets/$id');
  Future createBudget(Map<String, dynamic> body) =>
      store('/accounting/budgets', body);
  Future updateBudget(int id, Map<String, dynamic> body) =>
      update('/accounting/budgets/$id', body);
  Future deleteBudget(int id) => destroy('/accounting/budgets/$id');
  Future budgetVsActual(int id, {Map<String, dynamic>? filters}) =>
      show('/accounting/budgets/$id/vs-actual');

  Future<PaginatedResponse<VoucherModel>> vouchers({
    Map<String, dynamic>? filters,
  }) {
    return client.getPaginated<VoucherModel>(
      ApiEndpoints.vouchers,
      queryParameters: filters,
      itemFromJson: VoucherModel.fromJson,
    );
  }

  Future vouchersAll({Map<String, dynamic>? filters}) =>
      list('/accounting/vouchers/list/all', filters: filters);
  Future<ApiResponse<VoucherModel>> voucher(int id) {
    return client.get<VoucherModel>(
      '${ApiEndpoints.vouchers}/$id',
      fromData: (json) => VoucherModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future createVoucher(Map<String, dynamic> body) =>
      store('/accounting/vouchers', body);
  Future updateVoucher(int id, Map<String, dynamic> body) =>
      update('/accounting/vouchers/$id', body);

  Future voucherAllocations({Map<String, dynamic>? filters}) =>
      index('/accounting/voucher-allocations', filters: filters);
  Future voucherAllocation(int id) =>
      show('/accounting/voucher-allocations/$id');
  Future createVoucherAllocation(Map<String, dynamic> body) =>
      store('/accounting/voucher-allocations', body);
  Future updateVoucherAllocation(int id, Map<String, dynamic> body) =>
      update('/accounting/voucher-allocations/$id', body);
  Future deleteVoucherAllocation(int id) =>
      destroy('/accounting/voucher-allocations/$id');

  Future cashSessions({Map<String, dynamic>? filters}) =>
      index('/accounting/cash-sessions', filters: filters);
  Future cashSession(int id) => show('/accounting/cash-sessions/$id');
  Future openCashSession(Map<String, dynamic> body) =>
      action('/accounting/cash-sessions/open', body: body);
  Future closeCashSession(int id, Map<String, dynamic> body) =>
      action('/accounting/cash-sessions/$id/close', body: body);
  Future cancelCashSession(int id, Map<String, dynamic> body) =>
      action('/accounting/cash-sessions/$id/cancel', body: body);

  Future bankReconciliation({Map<String, dynamic>? filters}) =>
      index('/accounting/bank-reconciliation', filters: filters);
  Future bankReconciliationEntry(int id) =>
      show('/accounting/bank-reconciliation/$id');
  Future createBankReconciliation(Map<String, dynamic> body) =>
      store('/accounting/bank-reconciliation', body);
  Future updateBankReconciliation(int id, Map<String, dynamic> body) =>
      update('/accounting/bank-reconciliation/$id', body);
  Future deleteBankReconciliation(int id) =>
      destroy('/accounting/bank-reconciliation/$id');

  Future reportGeneralLedger({Map<String, dynamic>? filters}) =>
      index('/accounting/reports/general-ledger', filters: filters);
  Future reportAccountsReceivableAging({Map<String, dynamic>? filters}) =>
      index('/accounting/reports/accounts-receivable-aging', filters: filters);
  Future reportAccountsPayableAging({Map<String, dynamic>? filters}) =>
      index('/accounting/reports/accounts-payable-aging', filters: filters);
  Future reportBalanceSheet({Map<String, dynamic>? filters}) =>
      index('/accounting/reports/balance-sheet', filters: filters);
  Future reportProfitAndLoss({Map<String, dynamic>? filters}) =>
      index('/accounting/reports/profit-loss', filters: filters);
  Future reportTrialBalance({Map<String, dynamic>? filters}) =>
      index('/accounting/reports/trial-balance', filters: filters);
  Future reportCashFlow({Map<String, dynamic>? filters}) =>
      index('/accounting/reports/cash-flow', filters: filters);
  Future reportFinancialStatements({Map<String, dynamic>? filters}) =>
      index('/accounting/reports/financial-statements', filters: filters);
}
