import '../../core/api/api_endpoints.dart';
import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/accounting/account_group_model.dart';
import '../../model/accounting/accounting_report_model.dart';
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
import '../base/erp_module_service.dart';

class AccountsService extends ErpModuleService {
  AccountsService({super.apiClient});

  Future<PaginatedResponse<AccountGroupModel>> accountGroups({
    Map<String, dynamic>? filters,
  }) => paginated<AccountGroupModel>(
    ApiEndpoints.accountGroups,
    filters: filters,
    fromJson: AccountGroupModel.fromJson,
  );

  Future<ApiResponse<List<AccountGroupModel>>> accountGroupsAll({
    Map<String, dynamic>? filters,
  }) => collection<AccountGroupModel>(
    ApiEndpoints.accountGroupsListAll,
    filters: filters,
    fromJson: AccountGroupModel.fromJson,
  );

  Future<ApiResponse<AccountGroupModel>> accountGroup(int id) =>
      object<AccountGroupModel>(
        '${ApiEndpoints.accountGroups}/$id',
        fromJson: AccountGroupModel.fromJson,
      );

  Future<ApiResponse<AccountGroupModel>> createAccountGroup(
    AccountGroupModel body,
  ) => createModel<AccountGroupModel>(
    ApiEndpoints.accountGroups,
    body,
    fromJson: AccountGroupModel.fromJson,
  );

  Future<ApiResponse<AccountGroupModel>> updateAccountGroup(
    int id,
    AccountGroupModel body,
  ) => updateModel<AccountGroupModel>(
    '${ApiEndpoints.accountGroups}/$id',
    body,
    fromJson: AccountGroupModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deleteAccountGroup(int id) =>
      destroy('${ApiEndpoints.accountGroups}/$id');

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
    ApiEndpoints.accountsListAll,
    filters: filters,
    fromJson: AccountModel.fromJson,
  );

  Future<ApiResponse<AccountModel>> account(int id) => object<AccountModel>(
    '${ApiEndpoints.accounts}/$id',
    fromJson: AccountModel.fromJson,
  );

  Future<ApiResponse<AccountModel>> createAccount(AccountModel body) =>
      createModel<AccountModel>(
        ApiEndpoints.accounts,
        body,
        fromJson: AccountModel.fromJson,
      );

  Future<ApiResponse<AccountModel>> updateAccount(int id, AccountModel body) =>
      updateModel<AccountModel>(
        '${ApiEndpoints.accounts}/$id',
        body,
        fromJson: AccountModel.fromJson,
      );

  Future<ApiResponse<dynamic>> deleteAccount(int id) =>
      destroy('${ApiEndpoints.accounts}/$id');

  Future<PaginatedResponse<VoucherTypeModel>> voucherTypes({
    Map<String, dynamic>? filters,
  }) => paginated<VoucherTypeModel>(
    ApiEndpoints.voucherTypes,
    filters: filters,
    fromJson: VoucherTypeModel.fromJson,
  );

  Future<ApiResponse<List<VoucherTypeModel>>> voucherTypesAll({
    Map<String, dynamic>? filters,
  }) => collection<VoucherTypeModel>(
    ApiEndpoints.voucherTypesListAll,
    filters: filters,
    fromJson: VoucherTypeModel.fromJson,
  );

  Future<ApiResponse<VoucherTypeModel>> voucherType(int id) =>
      object<VoucherTypeModel>(
        '${ApiEndpoints.voucherTypes}/$id',
        fromJson: VoucherTypeModel.fromJson,
      );

  Future<ApiResponse<VoucherTypeModel>> createVoucherType(
    VoucherTypeModel body,
  ) => createModel<VoucherTypeModel>(
    ApiEndpoints.voucherTypes,
    body,
    fromJson: VoucherTypeModel.fromJson,
  );

  Future<ApiResponse<VoucherTypeModel>> updateVoucherType(
    int id,
    VoucherTypeModel body,
  ) => updateModel<VoucherTypeModel>(
    '${ApiEndpoints.voucherTypes}/$id',
    body,
    fromJson: VoucherTypeModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deleteVoucherType(int id) =>
      destroy('${ApiEndpoints.voucherTypes}/$id');

  Future<PaginatedResponse<PostingRuleGroupModel>> postingRuleGroups({
    Map<String, dynamic>? filters,
  }) => paginated<PostingRuleGroupModel>(
    ApiEndpoints.postingRuleGroups,
    filters: filters,
    fromJson: PostingRuleGroupModel.fromJson,
  );

  Future<ApiResponse<List<PostingRuleGroupModel>>> postingRuleGroupsAll({
    Map<String, dynamic>? filters,
  }) => collection<PostingRuleGroupModel>(
    ApiEndpoints.postingRuleGroupsListAll,
    filters: filters,
    fromJson: PostingRuleGroupModel.fromJson,
  );

  Future<ApiResponse<PostingRuleGroupModel>> postingRuleGroup(int id) =>
      object<PostingRuleGroupModel>(
        '${ApiEndpoints.postingRuleGroups}/$id',
        fromJson: PostingRuleGroupModel.fromJson,
      );

  Future<ApiResponse<PostingRuleGroupModel>> createPostingRuleGroup(
    PostingRuleGroupModel body,
  ) => createModel<PostingRuleGroupModel>(
    ApiEndpoints.postingRuleGroups,
    body,
    fromJson: PostingRuleGroupModel.fromJson,
  );

  Future<ApiResponse<PostingRuleGroupModel>> updatePostingRuleGroup(
    int id,
    PostingRuleGroupModel body,
  ) => updateModel<PostingRuleGroupModel>(
    '${ApiEndpoints.postingRuleGroups}/$id',
    body,
    fromJson: PostingRuleGroupModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deletePostingRuleGroup(int id) =>
      destroy('${ApiEndpoints.postingRuleGroups}/$id');

  Future<PaginatedResponse<PostingRuleModel>> postingRules({
    Map<String, dynamic>? filters,
  }) => paginated<PostingRuleModel>(
    ApiEndpoints.postingRules,
    filters: filters,
    fromJson: PostingRuleModel.fromJson,
  );

  Future<ApiResponse<List<PostingRuleModel>>> postingRulesAll({
    Map<String, dynamic>? filters,
  }) => collection<PostingRuleModel>(
    ApiEndpoints.postingRulesListAll,
    filters: filters,
    fromJson: PostingRuleModel.fromJson,
  );

  Future<ApiResponse<PostingRuleModel>> postingRule(int id) =>
      object<PostingRuleModel>(
        '${ApiEndpoints.postingRules}/$id',
        fromJson: PostingRuleModel.fromJson,
      );

  Future<ApiResponse<PostingRuleModel>> createPostingRule(
    PostingRuleModel body,
  ) => createModel<PostingRuleModel>(
    ApiEndpoints.postingRules,
    body,
    fromJson: PostingRuleModel.fromJson,
  );

  Future<ApiResponse<PostingRuleModel>> updatePostingRule(
    int id,
    PostingRuleModel body,
  ) => updateModel<PostingRuleModel>(
    '${ApiEndpoints.postingRules}/$id',
    body,
    fromJson: PostingRuleModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deletePostingRule(int id) =>
      destroy('${ApiEndpoints.postingRules}/$id');

  Future<PaginatedResponse<DocumentPostingModel>> documentPostings({
    Map<String, dynamic>? filters,
  }) => paginated<DocumentPostingModel>(
    ApiEndpoints.documentPostings,
    filters: filters,
    fromJson: DocumentPostingModel.fromJson,
  );

  Future<ApiResponse<List<DocumentPostingModel>>> documentPostingsAll({
    Map<String, dynamic>? filters,
  }) => collection<DocumentPostingModel>(
    ApiEndpoints.documentPostingsListAll,
    filters: filters,
    fromJson: DocumentPostingModel.fromJson,
  );

  Future<ApiResponse<DocumentPostingModel>> documentPosting(int id) =>
      object<DocumentPostingModel>(
        '${ApiEndpoints.documentPostings}/$id',
        fromJson: DocumentPostingModel.fromJson,
      );

  Future<ApiResponse<DocumentPostingModel>> createDocumentPosting(
    DocumentPostingModel body,
  ) => createModel<DocumentPostingModel>(
    ApiEndpoints.documentPostings,
    body,
    fromJson: DocumentPostingModel.fromJson,
  );

  Future<ApiResponse<DocumentPostingModel>> updateDocumentPosting(
    int id,
    DocumentPostingModel body,
  ) => updateModel<DocumentPostingModel>(
    '${ApiEndpoints.documentPostings}/$id',
    body,
    fromJson: DocumentPostingModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deleteDocumentPosting(int id) =>
      destroy('${ApiEndpoints.documentPostings}/$id');

  Future<ApiResponse<List<PartyAccountModel>>> partyAccounts({
    Map<String, dynamic>? filters,
  }) => collection<PartyAccountModel>(
    ApiEndpoints.partyAccounts,
    filters: filters,
    fromJson: PartyAccountModel.fromJson,
  );

  Future<PaginatedResponse<PartyAccountModel>> partyAccountsRegister({
    Map<String, dynamic>? filters,
  }) => paginated<PartyAccountModel>(
    ApiEndpoints.partyAccounts,
    filters: filters,
    fromJson: PartyAccountModel.fromJson,
  );

  Future<ApiResponse<PartyAccountModel>> defaultPartyAccount({
    Map<String, dynamic>? filters,
  }) => object<PartyAccountModel>(
    ApiEndpoints.partyAccountsDefault,
    fromJson: PartyAccountModel.fromJson,
  );

  Future<ApiResponse<PartyAccountModel>> partyAccount(int id) =>
      object<PartyAccountModel>(
        '${ApiEndpoints.partyAccounts}/$id',
        fromJson: PartyAccountModel.fromJson,
      );

  Future<ApiResponse<PartyAccountModel>> createPartyAccount(
    PartyAccountModel body,
  ) => createModel<PartyAccountModel>(
    ApiEndpoints.partyAccounts,
    body,
    fromJson: PartyAccountModel.fromJson,
  );

  Future<ApiResponse<PartyAccountModel>> updatePartyAccount(
    int id,
    PartyAccountModel body,
  ) => updateModel<PartyAccountModel>(
    '${ApiEndpoints.partyAccounts}/$id',
    body,
    fromJson: PartyAccountModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deletePartyAccount(int id) =>
      destroy('${ApiEndpoints.partyAccounts}/$id');

  Future<PaginatedResponse<BudgetModel>> budgets({
    Map<String, dynamic>? filters,
  }) => paginated<BudgetModel>(
    ApiEndpoints.budgets,
    filters: filters,
    fromJson: BudgetModel.fromJson,
  );

  Future<ApiResponse<BudgetModel>> budget(int id) => object<BudgetModel>(
    '${ApiEndpoints.budgets}/$id',
    fromJson: BudgetModel.fromJson,
  );

  Future<ApiResponse<BudgetModel>> createBudget(BudgetModel body) =>
      createModel<BudgetModel>(
        ApiEndpoints.budgets,
        body,
        fromJson: BudgetModel.fromJson,
      );

  Future<ApiResponse<BudgetModel>> updateBudget(int id, BudgetModel body) =>
      updateModel<BudgetModel>(
        '${ApiEndpoints.budgets}/$id',
        body,
        fromJson: BudgetModel.fromJson,
      );

  Future<ApiResponse<dynamic>> deleteBudget(int id) =>
      destroy('${ApiEndpoints.budgets}/$id');

  Future<ApiResponse<BudgetVsActualModel>> budgetVsActual(
    int id, {
    Map<String, dynamic>? filters,
  }) => object<BudgetVsActualModel>(
    '${ApiEndpoints.budgets}/$id/vs-actual',
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
    ApiEndpoints.vouchersListAll,
    filters: filters,
    fromJson: VoucherModel.fromJson,
  );

  Future<ApiResponse<VoucherModel>> voucher(int id) {
    return client.get<VoucherModel>(
      '${ApiEndpoints.vouchers}/$id',
      fromData: (json) => VoucherModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> voucherAuditTrail(int id) {
    return client.get<List<Map<String, dynamic>>>(
      '${ApiEndpoints.vouchers}/$id/audit-trail',
      fromData: (dynamic json) {
        if (json is! List) {
          return <Map<String, dynamic>>[];
        }
        return json.map((dynamic e) {
          if (e is Map<String, dynamic>) {
            return e;
          }
          if (e is Map) {
            return Map<String, dynamic>.from(e);
          }
          return <String, dynamic>{};
        }).where((m) => m.isNotEmpty).toList();
      },
    );
  }

  Future<ApiResponse<VoucherModel>> createVoucher(VoucherModel body) =>
      createModel<VoucherModel>(
        ApiEndpoints.vouchers,
        body,
        fromJson: VoucherModel.fromJson,
      );

  Future<ApiResponse<VoucherModel>> updateVoucher(int id, VoucherModel body) =>
      updateModel<VoucherModel>(
        '${ApiEndpoints.vouchers}/$id',
        body,
        fromJson: VoucherModel.fromJson,
      );

  Future<ApiResponse<dynamic>> deleteVoucher(int id) =>
      destroy('${ApiEndpoints.vouchers}/$id');

  Future<PaginatedResponse<VoucherAllocationModel>> voucherAllocations({
    Map<String, dynamic>? filters,
  }) => paginated<VoucherAllocationModel>(
    ApiEndpoints.voucherAllocations,
    filters: filters,
    fromJson: VoucherAllocationModel.fromJson,
  );

  Future<ApiResponse<VoucherAllocationModel>> voucherAllocation(int id) =>
      object<VoucherAllocationModel>(
        '${ApiEndpoints.voucherAllocations}/$id',
        fromJson: VoucherAllocationModel.fromJson,
      );

  Future<ApiResponse<VoucherAllocationModel>> createVoucherAllocation(
    VoucherAllocationModel body,
  ) => createModel<VoucherAllocationModel>(
    ApiEndpoints.voucherAllocations,
    body,
    fromJson: VoucherAllocationModel.fromJson,
  );

  Future<ApiResponse<VoucherAllocationModel>> updateVoucherAllocation(
    int id,
    VoucherAllocationModel body,
  ) => updateModel<VoucherAllocationModel>(
    '${ApiEndpoints.voucherAllocations}/$id',
    body,
    fromJson: VoucherAllocationModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deleteVoucherAllocation(int id) =>
      destroy('${ApiEndpoints.voucherAllocations}/$id');

  Future<ApiResponse<List<CashSessionModel>>> cashSessions({
    Map<String, dynamic>? filters,
  }) => collection<CashSessionModel>(
    ApiEndpoints.cashSessions,
    filters: filters,
    fromJson: CashSessionModel.fromJson,
  );

  Future<ApiResponse<CashSessionModel>> cashSession(int id) =>
      object<CashSessionModel>(
        '${ApiEndpoints.cashSessions}/$id',
        fromJson: CashSessionModel.fromJson,
      );

  Future<ApiResponse<CashSessionModel>> openCashSession(
    CashSessionModel body,
  ) => actionModel<CashSessionModel>(
    ApiEndpoints.cashSessionsOpen,
    body: body,
    fromJson: CashSessionModel.fromJson,
  );

  Future<ApiResponse<CashSessionModel>> closeCashSession(
    int id,
    CashSessionModel body,
  ) => actionModel<CashSessionModel>(
    '${ApiEndpoints.cashSessions}/$id/close',
    body: body,
    fromJson: CashSessionModel.fromJson,
  );

  Future<ApiResponse<CashSessionModel>> cancelCashSession(
    int id,
    CashSessionModel body,
  ) => actionModel<CashSessionModel>(
    '${ApiEndpoints.cashSessions}/$id/cancel',
    body: body,
    fromJson: CashSessionModel.fromJson,
  );

  Future<ApiResponse<List<BankReconciliationModel>>> bankReconciliation({
    Map<String, dynamic>? filters,
  }) => collection<BankReconciliationModel>(
    ApiEndpoints.bankReconciliation,
    filters: filters,
    fromJson: BankReconciliationModel.fromJson,
  );

  Future<ApiResponse<BankReconciliationModel>> bankReconciliationEntry(
    int id,
  ) => object<BankReconciliationModel>(
    '${ApiEndpoints.bankReconciliation}/$id',
    fromJson: BankReconciliationModel.fromJson,
  );

  Future<ApiResponse<BankReconciliationModel>> createBankReconciliation(
    BankReconciliationModel body,
  ) => createModel<BankReconciliationModel>(
    ApiEndpoints.bankReconciliation,
    body,
    fromJson: BankReconciliationModel.fromJson,
  );

  Future<ApiResponse<BankReconciliationModel>> updateBankReconciliation(
    int id,
    BankReconciliationModel body,
  ) => updateModel<BankReconciliationModel>(
    '${ApiEndpoints.bankReconciliation}/$id',
    body,
    fromJson: BankReconciliationModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deleteBankReconciliation(int id) =>
      destroy('${ApiEndpoints.bankReconciliation}/$id');

  Future<ApiResponse<AccountingReportModel>> reportDayBook({
    Map<String, dynamic>? filters,
  }) => client.get<AccountingReportModel>(
    ApiEndpoints.reportsDayBook,
    queryParameters: filters,
    fromData: (json) =>
        AccountingReportModel.fromJson(json as Map<String, dynamic>),
  );

  Future<ApiResponse<AccountingReportModel>> reportGeneralLedger({
    Map<String, dynamic>? filters,
  }) => client.get<AccountingReportModel>(
    ApiEndpoints.reportsGeneralLedger,
    queryParameters: filters,
    fromData: (json) =>
        AccountingReportModel.fromJson(json as Map<String, dynamic>),
  );

  Future<ApiResponse<AccountingReportModel>> reportAccountsReceivableAging({
    Map<String, dynamic>? filters,
  }) => client.get<AccountingReportModel>(
    ApiEndpoints.reportsAccountsReceivableAging,
    queryParameters: filters,
    fromData: (json) =>
        AccountingReportModel.fromJson(json as Map<String, dynamic>),
  );

  Future<ApiResponse<AccountingReportModel>> reportAccountsPayableAging({
    Map<String, dynamic>? filters,
  }) => client.get<AccountingReportModel>(
    ApiEndpoints.reportsAccountsPayableAging,
    queryParameters: filters,
    fromData: (json) =>
        AccountingReportModel.fromJson(json as Map<String, dynamic>),
  );

  Future<ApiResponse<AccountingReportModel>> reportBalanceSheet({
    Map<String, dynamic>? filters,
  }) => client.get<AccountingReportModel>(
    ApiEndpoints.reportsBalanceSheet,
    queryParameters: filters,
    fromData: (json) =>
        AccountingReportModel.fromJson(json as Map<String, dynamic>),
  );

  Future<ApiResponse<AccountingReportModel>> reportProfitAndLoss({
    Map<String, dynamic>? filters,
  }) => client.get<AccountingReportModel>(
    ApiEndpoints.reportsProfitLoss,
    queryParameters: filters,
    fromData: (json) =>
        AccountingReportModel.fromJson(json as Map<String, dynamic>),
  );

  Future<ApiResponse<AccountingReportModel>> reportTrialBalance({
    Map<String, dynamic>? filters,
  }) => client.get<AccountingReportModel>(
    ApiEndpoints.reportsTrialBalance,
    queryParameters: filters,
    fromData: (json) =>
        AccountingReportModel.fromJson(json as Map<String, dynamic>),
  );

  Future<ApiResponse<AccountingReportModel>> reportCashFlow({
    Map<String, dynamic>? filters,
  }) => client.get<AccountingReportModel>(
    ApiEndpoints.reportsCashFlow,
    queryParameters: filters,
    fromData: (json) =>
        AccountingReportModel.fromJson(json as Map<String, dynamic>),
  );

  Future<ApiResponse<AccountingReportModel>> reportFinancialStatements({
    Map<String, dynamic>? filters,
  }) => client.get<AccountingReportModel>(
    ApiEndpoints.reportsFinancialStatements,
    queryParameters: filters,
    fromData: (json) =>
        AccountingReportModel.fromJson(json as Map<String, dynamic>),
  );
}
