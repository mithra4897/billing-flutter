import '../../../screen.dart';

class FinancialReportsController extends GetxController {
  FinancialReportsController();

  final GlobalKey<FormState> reportFilterFormKey = GlobalKey<FormState>();

  static const List<AppDropdownItem<String>> reportItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'day_book', label: 'Day Book'),
        AppDropdownItem(value: 'general_ledger', label: 'General Ledger'),
        AppDropdownItem(
          value: 'accounts_receivable_aging',
          label: 'Accounts Receivable Aging',
        ),
        AppDropdownItem(
          value: 'accounts_payable_aging',
          label: 'Accounts Payable Aging',
        ),
        AppDropdownItem(value: 'trial_balance', label: 'Trial Balance'),
        AppDropdownItem(value: 'profit_and_loss', label: 'Profit & Loss'),
        AppDropdownItem(value: 'balance_sheet', label: 'Balance Sheet'),
        AppDropdownItem(value: 'cash_flow', label: 'Cash Flow'),
        AppDropdownItem(
          value: 'financial_statement_pack',
          label: 'Financial Statement Pack',
        ),
      ];

  final AccountsService _accountsService = AccountsService();
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final ScrollController pageScrollController = ScrollController();
  final TextEditingController dateFromController = TextEditingController();
  final TextEditingController dateToController = TextEditingController();
  final TextEditingController asOfDateController = TextEditingController();

  bool initialLoading = true;
  bool loading = false;
  String? error;
  String reportType = 'day_book';
  int? companyId;
  int? accountId;
  int? partyId;
  int? dayBookBranchId;
  List<AccountModel> accounts = const <AccountModel>[];
  List<PartyAccountModel> partyAccounts = const <PartyAccountModel>[];
  List<BranchModel> branches = const <BranchModel>[];
  List<PartyModel> parties = const <PartyModel>[];
  AccountingReportModel? report;

  @override
  void onInit() {
    super.onInit();
    final today = DateTime.now().toIso8601String().split('T').first;
    asOfDateController.text = today;
    dateFromController.text = today;
    dateToController.text = today;
    loadLookups();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    dateFromController.dispose();
    dateToController.dispose();
    asOfDateController.dispose();
    super.onClose();
  }

  Future<void> loadLookups() async {
    initialLoading = true;
    error = null;
    update();

    try {
      final responses = await Future.wait<dynamic>([
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
        _accountsService.accountsAll(
          filters: const {'sort_by': 'account_name'},
        ),
        _masterService.branches(
          filters: const {'per_page': 500, 'sort_by': 'name'},
        ),
        _partiesService.parties(
          filters: const {'per_page': 200, 'sort_by': 'party_name'},
        ),
      ]);

      final companies =
          (responses[0] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final nextAccounts =
          (responses[1] as ApiResponse<List<AccountModel>>).data ??
          const <AccountModel>[];
      final nextBranches =
          (responses[2] as PaginatedResponse<BranchModel>).data ??
          const <BranchModel>[];
      final nextParties =
          (responses[3] as PaginatedResponse<PartyModel>).data ??
          const <PartyModel>[];
      final activeCompanies = companies
          .where((item) => item.isActive)
          .toList(growable: false);
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );
      final nextCompanyId = contextSelection.companyId;
      final partyAccountResponse = nextCompanyId == null
          ? null
          : await _accountsService.partyAccountsRegister(
              filters: <String, dynamic>{
                'company_id': nextCompanyId,
                'is_active': 1,
                'per_page': 200,
                'sort_by': 'id',
                'sort_order': 'desc',
              },
            );

      accounts = nextAccounts.where((item) => item.isActive).toList();
      partyAccounts =
          partyAccountResponse?.data ?? const <PartyAccountModel>[];
      branches = nextBranches.where((item) => item.isActive).toList();
      parties = nextParties.where((item) => item.isActive).toList();
      companyId = nextCompanyId;
      _sanitizeSelections();
      initialLoading = false;
    } catch (errorValue) {
      error = errorValue.toString();
      initialLoading = false;
    }

    update();
  }

  Future<void> runReport() async {
    if (companyId == null) {
      error = 'Company is required.';
      update();
      return;
    }
    if (reportType == 'general_ledger' && accountId == null) {
      error = 'Account is required for general ledger.';
      update();
      return;
    }

    loading = true;
    error = null;
    update();

    final filters = <String, dynamic>{'company_id': companyId};
    switch (reportType) {
      case 'day_book':
        _putNonEmptyFilter(filters, 'date_from', dateFromController.text);
        _putNonEmptyFilter(filters, 'date_to', dateToController.text);
        if (dayBookBranchId != null) {
          filters['branch_id'] = dayBookBranchId;
        }
        break;
      case 'general_ledger':
        filters['account_id'] = accountId;
        if (partyId != null) filters['party_id'] = partyId;
        _putNonEmptyFilter(filters, 'date_from', dateFromController.text);
        _putNonEmptyFilter(filters, 'date_to', dateToController.text);
        break;
      case 'accounts_receivable_aging':
      case 'accounts_payable_aging':
        if (partyId != null) filters['party_id'] = partyId;
        _putNonEmptyFilter(filters, 'as_of_date', asOfDateController.text);
        break;
      case 'trial_balance':
      case 'balance_sheet':
        _putNonEmptyFilter(filters, 'as_of_date', asOfDateController.text);
        break;
      case 'profit_and_loss':
      case 'cash_flow':
      case 'financial_statement_pack':
        _putNonEmptyFilter(filters, 'date_from', dateFromController.text);
        _putNonEmptyFilter(filters, 'date_to', dateToController.text);
        if (reportType == 'financial_statement_pack') {
          _putNonEmptyFilter(filters, 'as_of_date', asOfDateController.text);
        }
        break;
    }

    try {
      final response = switch (reportType) {
        'day_book' => await _accountsService.reportDayBook(filters: filters),
        'general_ledger' => await _accountsService.reportGeneralLedger(
          filters: filters,
        ),
        'accounts_receivable_aging' =>
          await _accountsService.reportAccountsReceivableAging(
            filters: filters,
          ),
        'accounts_payable_aging' =>
          await _accountsService.reportAccountsPayableAging(filters: filters),
        'trial_balance' => await _accountsService.reportTrialBalance(
          filters: filters,
        ),
        'profit_and_loss' => await _accountsService.reportProfitAndLoss(
          filters: filters,
        ),
        'balance_sheet' => await _accountsService.reportBalanceSheet(
          filters: filters,
        ),
        'cash_flow' => await _accountsService.reportCashFlow(filters: filters),
        _ => await _accountsService.reportFinancialStatements(filters: filters),
      };

      report = response.data;
    } catch (errorValue) {
      error = errorValue.toString();
    } finally {
      loading = false;
      update();
    }
  }

  Future<void> copyReportTsv() async {
    if (report == null) {
      return;
    }
    final text = FinancialReportViews.toTsv(reportType, report!.data);
    await Clipboard.setData(ClipboardData(text: text));
    appScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Report copied as tab-separated text')),
    );
  }

  bool get needsAccount => reportType == 'general_ledger';

  bool get needsParty =>
      reportType == 'general_ledger' ||
      reportType == 'accounts_receivable_aging' ||
      reportType == 'accounts_payable_aging';

  bool get needsDayBookBranch => reportType == 'day_book';

  List<BranchModel> get branchOptions => branches
      .where(
        (b) =>
            b.isActive &&
            (companyId == null ||
                b.companyId == null ||
                b.companyId == companyId),
      )
      .toList(growable: false);

  List<AccountModel> get accountOptions => accounts
      .where(
        (account) =>
            account.isActive &&
            (companyId == null ||
                account.companyId == null ||
                account.companyId == companyId),
      )
      .toList(growable: false);

  List<PartyModel> get partyOptions {
    final activePartiesById = <int, PartyModel>{
      for (final party in parties)
        if (party.id != null && party.isActive) party.id!: party,
    };
    final companyPartyAccounts = partyAccounts
        .where(
          (mapping) =>
              mapping.isActive &&
              mapping.partyId != null &&
              mapping.accountId != null,
        )
        .toList(growable: false);

    Iterable<PartyAccountModel> allowedMappings = companyPartyAccounts;
    if (reportType == 'accounts_receivable_aging') {
      allowedMappings = allowedMappings.where(
        (mapping) => (mapping.accountPurpose ?? '').toLowerCase() == 'receivable',
      );
    } else if (reportType == 'accounts_payable_aging') {
      allowedMappings = allowedMappings.where(
        (mapping) => (mapping.accountPurpose ?? '').toLowerCase() == 'payable',
      );
    } else if (reportType == 'general_ledger' && accountId != null) {
      allowedMappings = allowedMappings.where(
        (mapping) => mapping.accountId == accountId,
      );
    }

    final allowedPartyIds = allowedMappings
        .map((mapping) => mapping.partyId)
        .whereType<int>()
        .toSet();
    final optionList = allowedPartyIds
        .map((id) => activePartiesById[id])
        .whereType<PartyModel>()
        .toList(growable: false);

    if (optionList.isNotEmpty) {
      return optionList;
    }
    return activePartiesById.values.toList(growable: false);
  }

  bool get usesDateRange =>
      reportType == 'day_book' ||
      reportType == 'general_ledger' ||
      reportType == 'profit_and_loss' ||
      reportType == 'cash_flow' ||
      reportType == 'financial_statement_pack';

  bool get usesAsOfDate =>
      reportType == 'accounts_receivable_aging' ||
      reportType == 'accounts_payable_aging' ||
      reportType == 'trial_balance' ||
      reportType == 'balance_sheet' ||
      reportType == 'financial_statement_pack';

  bool get usesStrictReportDateRange =>
      reportType == 'day_book' || reportType == 'general_ledger';

  void setReportType(String? value) {
    reportType = value ?? 'day_book';
    if (!needsAccount) {
      accountId = null;
    }
    if (!needsParty) {
      partyId = null;
    }
    if (!needsDayBookBranch) {
      dayBookBranchId = null;
    }
    report = null;
    _sanitizeSelections();
    update();
  }

  void setDayBookBranchId(int? value) {
    dayBookBranchId = value;
    update();
  }

  void setAccountId(int? value) {
    accountId = value;
    report = null;
    _sanitizeSelections();
    update();
  }

  void setPartyId(int? value) {
    partyId = value;
    report = null;
    update();
  }

  void clearFilters() {
    reportType = 'day_book';
    accountId = null;
    partyId = null;
    dayBookBranchId = null;
    final today = DateTime.now().toIso8601String().split('T').first;
    dateFromController.text = today;
    dateToController.text = today;
    asOfDateController.text = today;
    report = null;
    update();
  }

  void _sanitizeSelections() {
    final accountIds = accountOptions
        .map((account) => account.id)
        .whereType<int>()
        .toSet();
    if (accountId != null && !accountIds.contains(accountId)) {
      accountId = null;
    }

    final partyIds = partyOptions
        .map((party) => party.id)
        .whereType<int>()
        .toSet();
    if (partyId != null && !partyIds.contains(partyId)) {
      partyId = null;
    }
  }

  void _putNonEmptyFilter(
    Map<String, dynamic> filters,
    String key,
    String rawValue,
  ) {
    final value = rawValue.trim();
    if (value.isNotEmpty) {
      filters[key] = value;
    }
  }
}
