import '../../../screen.dart';

class VoucherLineDraft {
  VoucherLineDraft({
    this.accountId,
    this.partyId,
    this.entryType = 'debit',
    this.amountText = '',
    this.costCenter = '',
    this.department = '',
    this.project = '',
    this.narration = '',
  });

  int? accountId;
  int? partyId;
  String entryType;
  String amountText;
  String costCenter;
  String department;
  String project;
  String narration;
}

class VoucherModeOption {
  const VoucherModeOption({
    required this.category,
    required this.label,
    this.subtitle,
    required this.icon,
  });

  final String category;
  final String label;
  final String? subtitle;
  final IconData icon;
}

class VoucherManagementController extends GetxController {
  VoucherManagementController();

  static const List<AppDropdownItem<String>> approvalStatusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'pending', label: 'Pending'),
        AppDropdownItem(value: 'approved', label: 'Approved'),
        AppDropdownItem(value: 'rejected', label: 'Rejected'),
      ];

  static const List<AppDropdownItem<String>> postingStatusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'posted', label: 'Posted'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  static const List<AppDropdownItem<String>> entryTypeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'debit', label: 'Debit'),
        AppDropdownItem(value: 'credit', label: 'Credit'),
      ];

  static const List<VoucherModeOption> voucherModeOptions = <VoucherModeOption>[
    VoucherModeOption(
      category: 'payment',
      label: 'Expense',
      subtitle: 'Cash / bank -> expense ledger',
      icon: Icons.payments_outlined,
    ),
    VoucherModeOption(
      category: 'receipt',
      label: 'Receipt',
      subtitle: 'Indirect income -> cash / bank',
      icon: Icons.receipt_long_outlined,
    ),
    VoucherModeOption(
      category: 'contra',
      label: 'Contra',
      subtitle: 'Cash / bank transfers',
      icon: Icons.swap_horiz_outlined,
    ),
    VoucherModeOption(
      category: 'journal',
      label: 'Journal',
      subtitle: 'Multi-line entries',
      icon: Icons.menu_book_outlined,
    ),
  ];

  final AccountsService _accountsService = AccountsService();
  final AssetsService _assetsService = AssetsService();
  final HrService _hrService = HrService();
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final ProjectService _projectService = ProjectService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController voucherNoController = TextEditingController();
  final TextEditingController voucherDateController = TextEditingController();
  final TextEditingController referenceNoController = TextEditingController();
  final TextEditingController referenceDateController = TextEditingController();
  final TextEditingController narrationController = TextEditingController();
  final TextEditingController adjustmentRemarksController =
      TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController costCenterController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController projectController = TextEditingController();
  final TextEditingController lineNarrationController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<VoucherModel> vouchers = const <VoucherModel>[];
  List<VoucherModel> filteredVouchers = const <VoucherModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<VoucherTypeModel> voucherTypes = const <VoucherTypeModel>[];
  List<AccountModel> accounts = const <AccountModel>[];
  List<PartyModel> parties = const <PartyModel>[];
  List<CostCenterModel> costCenters = const <CostCenterModel>[];
  List<DepartmentModel> departments = const <DepartmentModel>[];
  List<ProjectModel> projects = const <ProjectModel>[];
  VoucherModel? selectedVoucher;
  int? contextCompanyId;
  int? contextBranchId;
  int? contextLocationId;
  int? contextFinancialYearId;
  int? companyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? voucherTypeId;
  int? documentSeriesId;
  int? adjustmentAccountId;
  int? debitAccountId;
  int? creditAccountId;
  int? debitPartyId;
  int? creditPartyId;
  String approvalStatus = 'draft';
  String postingStatus = 'draft';
  String voucherMode = 'payment';
  bool isActive = true;
  bool simpleEntryMode = true;
  Set<String> permissionCodes = {};
  bool isSuperAdmin = false;
  bool deleting = false;
  bool auditLogLoading = false;
  List<VoucherLineDraft> lines = <VoucherLineDraft>[];

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(applySearch);
    loadPage();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(applySearch)
      ..dispose();
    voucherNoController.dispose();
    voucherDateController.dispose();
    referenceNoController.dispose();
    referenceDateController.dispose();
    narrationController.dispose();
    adjustmentRemarksController.dispose();
    amountController.dispose();
    costCenterController.dispose();
    departmentController.dispose();
    projectController.dispose();
    lineNarrationController.dispose();
    super.onClose();
  }

  Future<void> loadPage({int? selectId}) async {
    initialLoading = vouchers.isEmpty;
    pageError = null;
    update();

    try {
      final permissionCodesResponse = await SessionStorage.getPermissionCodes();
      final currentUser = await SessionStorage.getCurrentUser();
      final superAdmin =
          currentUser?['is_super_admin'] == true ||
          currentUser?['is_super_admin'] == 1;

      final responses = await Future.wait<dynamic>([
        _accountsService.vouchers(
          filters: const {'per_page': 200, 'sort_by': 'voucher_date'},
        ),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
        _masterService.branches(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
        _masterService.businessLocations(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
        _masterService.financialYears(
          filters: const {'per_page': 100, 'sort_by': 'fy_name'},
        ),
        _masterService.documentSeries(
          filters: const {'per_page': 200, 'sort_by': 'series_name'},
        ),
        _accountsService.voucherTypesAll(filters: const {'sort_by': 'name'}),
        _partiesService.parties(
          filters: const {'per_page': 200, 'sort_by': 'party_name'},
        ),
        _assetsService.costCenters(
          filters: const {'per_page': 500, 'sort_by': 'cost_center_name'},
        ),
        _hrService.departments(
          filters: const {'per_page': 500, 'sort_by': 'department_name'},
        ),
        _projectService.projects(
          filters: const {'per_page': 500, 'sort_by': 'project_name'},
        ),
      ]);

      final nextVouchers =
          (responses[0] as PaginatedResponse<VoucherModel>).data ??
          const <VoucherModel>[];
      final companies =
          (responses[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final branches =
          (responses[2] as PaginatedResponse<BranchModel>).data ??
          const <BranchModel>[];
      final locations =
          (responses[3] as PaginatedResponse<BusinessLocationModel>).data ??
          const <BusinessLocationModel>[];
      final years =
          (responses[4] as PaginatedResponse<FinancialYearModel>).data ??
          const <FinancialYearModel>[];
      final nextSeries =
          (responses[5] as PaginatedResponse<DocumentSeriesModel>).data ??
          const <DocumentSeriesModel>[];
      final nextVoucherTypes =
          (responses[6] as ApiResponse<List<VoucherTypeModel>>).data ??
          const <VoucherTypeModel>[];
      final nextParties =
          (responses[7] as PaginatedResponse<PartyModel>).data ??
          const <PartyModel>[];
      final nextCostCenters =
          (responses[8] as PaginatedResponse<CostCenterModel>).data ??
          const <CostCenterModel>[];
      final nextDepartments =
          (responses[9] as PaginatedResponse<DepartmentModel>).data ??
          const <DepartmentModel>[];
      final nextProjects =
          (responses[10] as PaginatedResponse<ProjectModel>).data ??
          const <ProjectModel>[];

      final activeCompanies = companies.where((item) => item.isActive).toList();
      final activeBranches = branches.where((item) => item.isActive).toList();
      final activeLocations = locations.where((item) => item.isActive).toList();
      final activeFinancialYears = years
          .where((item) => item.isActive)
          .toList();
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: activeBranches,
            locations: activeLocations,
            financialYears: activeFinancialYears,
          );

      final accountsResponse = await _accountsService.accountsAll(
        filters: <String, dynamic>{
          'sort_by': 'account_name',
          if (contextSelection.companyId != null)
            'company_id': contextSelection.companyId,
        },
      );
      final nextAccounts = accountsResponse.data ?? const <AccountModel>[];

      permissionCodes = permissionCodesResponse.toSet();
      isSuperAdmin = superAdmin;
      vouchers = nextVouchers;
      filteredVouchers = filterVouchers(nextVouchers, searchController.text);
      contextCompanyId = contextSelection.companyId;
      contextBranchId = contextSelection.branchId;
      contextLocationId = contextSelection.locationId;
      contextFinancialYearId = contextSelection.financialYearId;
      documentSeries = nextSeries.where((item) => item.isActive).toList();
      voucherTypes = nextVoucherTypes
          .where(
            (item) =>
                item.isActive &&
                const <String>[
                  'payment',
                  'receipt',
                  'contra',
                  'journal',
                ].contains(item.voucherCategory),
          )
          .toList();
      accounts = nextAccounts.where((item) => item.isActive).toList();
      parties = nextParties.where((item) => item.isActive).toList();
      costCenters = nextCostCenters.where((item) => item.isActive).toList();
      departments = nextDepartments.where((item) => item.isActive).toList();
      projects = nextProjects.where((item) => item.isActive ?? true).toList();
      initialLoading = false;
      syncVoucherTypeWithMode();
      syncDocumentSeriesSelection();
      update();

      if (selectId != null) {
        final selected = nextVouchers.cast<VoucherModel?>().firstWhere(
          (item) => item?.id == selectId,
          orElse: () => null,
        );
        if (selected != null) {
          await selectVoucher(selected, notify: false);
        } else {
          resetForm(notify: false);
        }
      } else if (selectedVoucher?.id != null) {
        final reselect = nextVouchers.cast<VoucherModel?>().firstWhere(
          (item) => item?.id == selectedVoucher?.id,
          orElse: () => null,
        );
        if (reselect != null) {
          await selectVoucher(reselect, notify: false);
        } else {
          resetForm(notify: false);
        }
      } else {
        resetForm(notify: false);
      }
    } catch (errorValue) {
      pageError = errorValue.toString();
      initialLoading = false;
    }

    update();
  }

  List<VoucherModel> filterVouchers(List<VoucherModel> items, String query) {
    return filterMasterList(items, query, (item) {
      return [
        item.voucherNo ?? '',
        item.referenceNo ?? '',
        item.voucherTypeName ?? '',
        item.narration ?? '',
      ];
    });
  }

  void applySearch() {
    filteredVouchers = filterVouchers(vouchers, searchController.text);
    update();
  }

  VoucherTypeModel? get selectedVoucherType {
    if (voucherTypeId == null) {
      return null;
    }
    for (final item in voucherTypes) {
      if (item.id == voucherTypeId) {
        return item;
      }
    }
    return null;
  }

  List<VoucherTypeModel> get voucherTypesForMode {
    return voucherTypes
        .where((item) => item.voucherCategory == voucherMode)
        .toList(growable: false);
  }

  bool get usesQuickEntry => voucherMode != 'journal';

  bool get hasAccountsUpdate =>
      isSuperAdmin || permissionCodes.contains('accounts.update');

  bool get hasAccountsDelete =>
      isSuperAdmin || permissionCodes.contains('accounts.delete');

  bool get canEditSelectedVoucher {
    final voucher = selectedVoucher;
    if (voucher == null) {
      return true;
    }
    if ((voucher.postingStatus ?? '').toLowerCase() == 'cancelled') {
      return false;
    }
    if (voucher.isSystemGenerated && !isSuperAdmin) {
      return false;
    }
    return hasAccountsUpdate;
  }

  bool get canDeleteSelectedVoucher {
    final voucher = selectedVoucher;
    if (voucher?.id == null) {
      return false;
    }
    if ((voucher!.postingStatus ?? '').toLowerCase() == 'cancelled') {
      return false;
    }
    if (voucher.isSystemGenerated && !isSuperAdmin) {
      return false;
    }
    return hasAccountsDelete;
  }

  List<AccountModel> get accountsScoped {
    final cid = companyId ?? contextCompanyId;
    if (cid == null) {
      return accounts;
    }
    return accounts
        .where((item) => item.companyId == cid)
        .toList(growable: false);
  }

  List<AccountModel> get cashBankAccounts {
    return accountsScoped
        .where(
          (item) => item.accountType == 'cash' || item.accountType == 'bank',
        )
        .toList(growable: false);
  }

  List<AccountModel> get manualAccounts {
    return accountsScoped
        .where((item) => item.allowManualEntries || item.isSystemAccount)
        .toList(growable: false);
  }

  List<CostCenterModel> get costCentersScoped {
    final cid = companyId ?? contextCompanyId;
    if (cid == null) {
      return costCenters;
    }
    return costCenters
        .where((item) => item.companyId == null || item.companyId == cid)
        .toList(growable: false);
  }

  List<ProjectModel> get projectsScoped {
    final cid = companyId ?? contextCompanyId;
    if (cid == null) {
      return projects;
    }
    return projects
        .where((item) => item.companyId == null || item.companyId == cid)
        .toList(growable: false);
  }

  Map<String, dynamic>? accountGroupJson(AccountModel item) {
    final map = item.toJson();
    final value = map['account_group'] ?? map['accountGroup'];
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  String? accountGroupNatureOf(AccountModel item) =>
      accountGroupJson(item)?['group_nature']?.toString();

  String? accountGroupCategoryOf(AccountModel item) =>
      accountGroupJson(item)?['group_category']?.toString();

  String costCenterValueOf(CostCenterModel item) =>
      item.costCenterCode?.trim().isNotEmpty == true
      ? item.costCenterCode!.trim()
      : (item.costCenterName ?? '').trim();

  String costCenterLabel(CostCenterModel item) {
    final code = item.costCenterCode?.trim() ?? '';
    final name = item.costCenterName?.trim() ?? '';
    if (code.isNotEmpty && name.isNotEmpty && code != name) {
      return '$code - $name';
    }
    return code.isNotEmpty ? code : name;
  }

  String departmentValueOf(DepartmentModel item) =>
      (item.departmentName ?? '').trim();

  String projectValueOf(ProjectModel item) =>
      item.projectCode?.trim().isNotEmpty == true
      ? item.projectCode!.trim()
      : (item.projectName ?? '').trim();

  String projectLabel(ProjectModel item) {
    final code = item.projectCode?.trim() ?? '';
    final name = item.projectName?.trim() ?? '';
    if (code.isNotEmpty && name.isNotEmpty && code != name) {
      return '$code - $name';
    }
    return code.isNotEmpty ? code : name;
  }

  List<AppDropdownItem<String>> dimensionItems(
    Iterable<String> seededValues,
    Iterable<AppDropdownItem<String>> options,
  ) {
    final items = <AppDropdownItem<String>>[];
    final seen = <String>{};

    void addValue(String? raw, {String? label}) {
      final value = raw?.trim() ?? '';
      if (value.isEmpty || !seen.add(value)) {
        return;
      }
      items.add(AppDropdownItem<String>(value: value, label: label ?? value));
    }

    for (final value in seededValues) {
      addValue(value);
    }
    for (final option in options) {
      addValue(option.value, label: option.label);
    }
    return items;
  }

  List<AppDropdownItem<String>> costCenterItems([String? currentValue]) =>
      dimensionItems(
        <String>[?currentValue],
        [
          for (final item in costCentersScoped)
            if (costCenterValueOf(item).isNotEmpty)
              AppDropdownItem<String>(
                value: costCenterValueOf(item),
                label: costCenterLabel(item),
              ),
        ],
      );

  List<AppDropdownItem<String>> departmentItems([String? currentValue]) =>
      dimensionItems(
        <String>[?currentValue],
        [
          for (final item in departments)
            if (departmentValueOf(item).isNotEmpty)
              AppDropdownItem<String>(
                value: departmentValueOf(item),
                label: departmentValueOf(item),
              ),
        ],
      );

  List<AppDropdownItem<String>> projectItems([String? currentValue]) =>
      dimensionItems(
        <String>[?currentValue],
        [
          for (final item in projectsScoped)
            if (projectValueOf(item).isNotEmpty)
              AppDropdownItem<String>(
                value: projectValueOf(item),
                label: projectLabel(item),
              ),
        ],
      );

  List<AccountModel> get expenseLedgerOptions {
    bool isExpenseLedger(AccountModel item) {
      final nature = accountGroupNatureOf(item)?.toLowerCase();
      final category = accountGroupCategoryOf(item)?.toLowerCase();
      if (nature == 'expense') {
        return true;
      }
      return category == 'direct_expense' || category == 'indirect_expense';
    }

    final scoped = manualAccounts.where(isExpenseLedger).toList();
    if (scoped.isNotEmpty) {
      return scoped;
    }
    return manualAccounts
        .where(
          (item) => item.accountType != 'cash' && item.accountType != 'bank',
        )
        .toList(growable: false);
  }

  List<AccountModel> get indirectIncomeLedgerOptions {
    final scoped = manualAccounts
        .where(
          (item) =>
              accountGroupCategoryOf(item)?.toLowerCase() == 'indirect_income',
        )
        .toList();
    if (scoped.isNotEmpty) {
      return scoped;
    }
    return manualAccounts
        .where((item) => accountGroupNatureOf(item)?.toLowerCase() == 'income')
        .toList(growable: false);
  }

  List<DocumentSeriesModel> get filteredDocumentSeriesOptions {
    return documentSeries
        .where((item) {
          final documentType = selectedVoucherType?.documentType?.trim() ?? '';
          final documentTypeMatches = documentType.isNotEmpty
              ? item.documentType == documentType
              : <String>{
                  'PAYMENT_VOUCHER',
                  'RECEIPT_VOUCHER',
                  'CONTRA_VOUCHER',
                  'JOURNAL_VOUCHER',
                }.contains(item.documentType);
          final companyMatches =
              companyId == null ||
              item.companyId == null ||
              item.companyId == companyId;
          final financialYearMatches =
              financialYearId == null ||
              item.financialYearId == null ||
              item.financialYearId == financialYearId;
          return documentTypeMatches && companyMatches && financialYearMatches;
        })
        .toList(growable: false);
  }

  void syncVoucherTypeWithMode() {
    final options = voucherTypesForMode;
    if (options.isEmpty) {
      voucherTypeId = null;
      return;
    }
    final currentExists = options.any((item) => item.id == voucherTypeId);
    if (!currentExists) {
      voucherTypeId = options.first.id;
    }
  }

  void syncDocumentSeriesSelection() {
    final options = filteredDocumentSeriesOptions;
    if (options.isEmpty) {
      documentSeriesId = null;
      return;
    }
    final currentExists = options.any((item) => item.id == documentSeriesId);
    if (!currentExists) {
      documentSeriesId = options.first.id;
    }
  }

  Future<void> selectVoucher(VoucherModel voucher, {bool notify = true}) async {
    final response = await _accountsService.voucher(voucher.id!);
    final full = response.data ?? voucher;

    selectedVoucher = full;
    companyId = full.companyId;
    branchId = full.branchId;
    locationId = full.locationId;
    financialYearId = full.financialYearId;
    voucherTypeId = full.voucherTypeId;
    voucherMode = resolveVoucherMode(full);
    documentSeriesId = full.documentSeriesId;
    voucherNoController.text = full.voucherNo ?? '';
    voucherDateController.text =
        full.voucherDate?.split('T').first.split(' ').first ?? '';
    referenceNoController.text = full.referenceNo ?? '';
    referenceDateController.text =
        full.referenceDate?.split('T').first.split(' ').first ?? '';
    narrationController.text = full.narration ?? '';
    adjustmentAccountId = full.adjustmentAccountId;
    adjustmentRemarksController.text = full.adjustmentRemarks ?? '';
    approvalStatus = full.approvalStatus ?? 'approved';
    postingStatus = full.postingStatus ?? 'posted';
    isActive = full.isActive;
    lines = full.lines
        .map(
          (item) => VoucherLineDraft(
            accountId: item.accountId,
            partyId: item.partyId,
            entryType: item.entryType ?? 'debit',
            amountText: (item.amount ?? 0).toString(),
            costCenter: item.costCenter ?? '',
            department: item.department ?? '',
            project: item.project ?? '',
            narration: item.lineNarration ?? '',
          ),
        )
        .toList(growable: true);
    if (lines.isEmpty) {
      lines = <VoucherLineDraft>[VoucherLineDraft()];
    }
    hydrateQuickEntryFromLines(full);
    formError = null;
    final mode = resolveVoucherMode(full);
    simpleEntryMode =
        mode != 'journal' &&
        full.lines.length <= 2 &&
        (full.referenceNo == null || full.referenceNo!.trim().isEmpty) &&
        full.adjustmentAccountId == null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedVoucher = null;
    companyId = contextCompanyId;
    branchId = contextBranchId;
    locationId = contextLocationId;
    financialYearId = contextFinancialYearId;
    voucherMode = 'payment';
    syncVoucherTypeWithMode();
    documentSeriesId = null;
    syncDocumentSeriesSelection();
    voucherNoController.clear();
    voucherDateController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    referenceNoController.clear();
    referenceDateController.clear();
    narrationController.clear();
    adjustmentAccountId = null;
    adjustmentRemarksController.clear();
    amountController.clear();
    costCenterController.clear();
    departmentController.clear();
    projectController.clear();
    lineNarrationController.clear();
    debitAccountId = null;
    creditAccountId = null;
    debitPartyId = null;
    creditPartyId = null;
    approvalStatus = simpleEntryMode ? 'approved' : 'draft';
    postingStatus = simpleEntryMode ? 'posted' : 'draft';
    isActive = true;
    lines = <VoucherLineDraft>[VoucherLineDraft()];
    formError = null;
    if (notify) {
      update();
    }
  }

  String resolveVoucherMode(VoucherModel voucher) {
    final category = voucher.voucherCategory?.trim().toLowerCase();
    if (const <String>[
      'payment',
      'receipt',
      'contra',
      'journal',
    ].contains(category)) {
      return category!;
    }
    return 'journal';
  }

  void hydrateQuickEntryFromLines(VoucherModel voucher) {
    amountController.clear();
    costCenterController.clear();
    departmentController.clear();
    projectController.clear();
    lineNarrationController.clear();
    debitAccountId = null;
    creditAccountId = null;
    debitPartyId = null;
    creditPartyId = null;

    if (!usesQuickEntry) {
      return;
    }

    final debitLine = voucher.lines.cast<VoucherLineModel?>().firstWhere(
      (item) => item?.entryType == 'debit',
      orElse: () => null,
    );
    final creditLine = voucher.lines.cast<VoucherLineModel?>().firstWhere(
      (item) => item?.entryType == 'credit',
      orElse: () => null,
    );
    if (debitLine == null || creditLine == null) {
      return;
    }

    debitAccountId = debitLine.accountId;
    creditAccountId = creditLine.accountId;
    debitPartyId = debitLine.partyId;
    creditPartyId = creditLine.partyId;
    amountController.text = ((debitLine.amount ?? creditLine.amount) ?? 0)
        .toStringAsFixed(2);
    costCenterController.text =
        debitLine.costCenter ?? creditLine.costCenter ?? '';
    departmentController.text =
        debitLine.department ?? creditLine.department ?? '';
    projectController.text = debitLine.project ?? creditLine.project ?? '';
    lineNarrationController.text =
        debitLine.lineNarration ?? creditLine.lineNarration ?? '';
  }

  List<VoucherLineModel> buildQuickEntryLines() {
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    final costCenter = nullIfEmpty(costCenterController.text);
    final department = nullIfEmpty(departmentController.text);
    final project = nullIfEmpty(projectController.text);
    final lineNarration =
        nullIfEmpty(lineNarrationController.text) ??
        (simpleEntryMode ? nullIfEmpty(narrationController.text) : null);

    return <VoucherLineModel>[
      VoucherLineModel(
        accountId: debitAccountId,
        partyId: debitPartyId,
        entryType: 'debit',
        amount: amount,
        costCenter: costCenter,
        department: department,
        project: project,
        lineNarration: lineNarration,
      ),
      VoucherLineModel(
        accountId: creditAccountId,
        partyId: creditPartyId,
        entryType: 'credit',
        amount: amount,
        costCenter: costCenter,
        department: department,
        project: project,
        lineNarration: lineNarration,
      ),
    ];
  }

  void addLine() {
    lines = List<VoucherLineDraft>.from(lines)..add(VoucherLineDraft());
    update();
  }

  void removeLine(int index) {
    lines = List<VoucherLineDraft>.from(lines)..removeAt(index);
    if (lines.isEmpty) {
      lines.add(VoucherLineDraft());
    }
    update();
  }

  double get totalDebit {
    double total = 0;
    for (final line in lines) {
      final amount = double.tryParse(line.amountText.trim()) ?? 0;
      if (line.entryType == 'debit') {
        total += amount;
      }
    }
    return total;
  }

  double get totalCredit {
    double total = 0;
    for (final line in lines) {
      final amount = double.tryParse(line.amountText.trim()) ?? 0;
      if (line.entryType == 'credit') {
        total += amount;
      }
    }
    return total;
  }

  Future<void> saveVoucher() async {
    if (formKey.currentState?.validate() != true) {
      return;
    }

    if (usesQuickEntry) {
      final amount = double.tryParse(amountController.text.trim()) ?? 0;
      if (debitAccountId == null || creditAccountId == null || amount <= 0) {
        formError = 'Complete both accounts and amount for this voucher.';
        update();
        return;
      }
      if (voucherMode == 'contra' && debitAccountId == creditAccountId) {
        formError =
            'Contra needs two different cash / bank ledgers (e.g. bank -> cash).';
        update();
        return;
      }
    }

    final hasInvalidLine =
        !usesQuickEntry &&
        lines.any(
          (line) =>
              line.accountId == null ||
              double.tryParse(line.amountText.trim()) == null ||
              (double.tryParse(line.amountText.trim()) ?? 0) <= 0,
        );
    if (hasInvalidLine) {
      formError = 'Each voucher line needs account and amount.';
      update();
      return;
    }

    final linesForSave = usesQuickEntry
        ? buildQuickEntryLines()
        : lines
              .map(
                (line) => VoucherLineModel(
                  accountId: line.accountId,
                  partyId: line.partyId,
                  entryType: line.entryType,
                  amount: double.tryParse(line.amountText.trim()),
                  costCenter: nullIfEmpty(line.costCenter),
                  department: nullIfEmpty(line.department),
                  project: nullIfEmpty(line.project),
                  lineNarration: nullIfEmpty(line.narration),
                ),
              )
              .toList(growable: false);

    final debitTotal = linesForSave
        .where((line) => line.entryType == 'debit')
        .fold<double>(0, (sum, line) => sum + (line.amount ?? 0));
    final creditTotal = linesForSave
        .where((line) => line.entryType == 'credit')
        .fold<double>(0, (sum, line) => sum + (line.amount ?? 0));
    if ((debitTotal - creditTotal).abs() > 0.009 &&
        adjustmentAccountId == null) {
      formError =
          'Total debit and total credit must be equal. Select an adjustment account if you want auto-balance.';
      update();
      return;
    }

    syncDocumentSeriesSelection();
    final seriesOptions = filteredDocumentSeriesOptions;
    if (seriesOptions.isEmpty) {
      final documentType = selectedVoucherType?.documentType?.trim() ?? '';
      formError = documentType.isEmpty
          ? 'No document series for accounting vouchers. In Settings -> Document series, add rows for PAYMENT_VOUCHER, RECEIPT_VOUCHER, CONTRA_VOUCHER (and JOURNAL_VOUCHER) for this company and financial year.'
          : 'No document series for $documentType. Create one under Settings -> Document series for this financial year.';
      update();
      return;
    }
    if (documentSeriesId != null &&
        !seriesOptions.any((item) => item.id == documentSeriesId)) {
      formError =
          'Document series no longer matches this voucher type. Pick a series from the list again.';
      update();
      return;
    }

    saving = true;
    formError = null;
    update();

    final wasCreate = selectedVoucher == null;
    final model = VoucherModel(
      id: selectedVoucher?.id,
      companyId: companyId,
      branchId: branchId,
      locationId: locationId,
      financialYearId: financialYearId,
      voucherTypeId: voucherTypeId,
      documentSeriesId: documentSeriesId,
      voucherNo: nullIfEmpty(voucherNoController.text.trim()),
      voucherDate: voucherDateController.text.trim(),
      referenceNo: nullIfEmpty(referenceNoController.text),
      referenceDate: nullIfEmpty(referenceDateController.text),
      narration: nullIfEmpty(narrationController.text),
      adjustmentAccountId: adjustmentAccountId,
      adjustmentRemarks: nullIfEmpty(adjustmentRemarksController.text),
      approvalStatus: approvalStatus,
      postingStatus: postingStatus,
      isActive: isActive,
      lines: linesForSave,
    );

    try {
      final response = wasCreate
          ? await _accountsService.createVoucher(model)
          : await _accountsService.updateVoucher(selectedVoucher!.id!, model);
      final saved = response.data;
      final okMessage = response.message.isNotEmpty
          ? response.message
          : (wasCreate ? 'Voucher saved' : 'Voucher updated');
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(okMessage)),
      );
      if (wasCreate) {
        await loadPage();
        resetForm();
      } else {
        await loadPage(selectId: saved?.id);
      }
    } catch (errorValue) {
      final message = errorValue is ApiException
          ? errorValue.displayMessage
          : errorValue.toString();
      formError = message;
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: appScaffoldMessengerKey.currentContext == null
              ? null
              : Theme.of(
                  appScaffoldMessengerKey.currentContext!,
                ).colorScheme.error,
        ),
      );
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> deleteSelectedVoucher() async {
    final id = selectedVoucher?.id;
    if (id == null || !canDeleteSelectedVoucher) {
      return;
    }

    deleting = true;
    formError = null;
    update();

    try {
      final response = await _accountsService.deleteVoucher(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            response.message.isNotEmpty ? response.message : 'Voucher deleted',
          ),
        ),
      );
      await loadPage();
      resetForm();
    } catch (errorValue) {
      final message = errorValue is ApiException
          ? errorValue.displayMessage
          : errorValue.toString();
      formError = message;
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: appScaffoldMessengerKey.currentContext == null
              ? null
              : Theme.of(
                  appScaffoldMessengerKey.currentContext!,
                ).colorScheme.error,
        ),
      );
    } finally {
      deleting = false;
      update();
    }
  }

  Future<List<Map<String, dynamic>>> fetchVoucherAuditLog() async {
    final id = selectedVoucher?.id;
    if (id == null) {
      return const <Map<String, dynamic>>[];
    }

    auditLogLoading = true;
    update();
    try {
      final response = await _accountsService.voucherAuditTrail(id);
      if (!response.success) {
        throw ApiException(
          response.message.isNotEmpty
              ? response.message
              : 'Could not load activity log',
        );
      }
      return response.data ?? const <Map<String, dynamic>>[];
    } finally {
      auditLogLoading = false;
      update();
    }
  }

  void startNewEntry({required bool isDesktop}) {
    resetForm();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }

  void setSimpleEntryMode(bool value) {
    simpleEntryMode = value;
    update();
  }

  void setVoucherMode(String value) {
    voucherMode = value;
    if (value == 'journal') {
      simpleEntryMode = false;
    }
    syncVoucherTypeWithMode();
    documentSeriesId = null;
    syncDocumentSeriesSelection();
    update();
  }

  void setVoucherTypeId(int? value) {
    voucherTypeId = value;
    documentSeriesId = null;
    syncDocumentSeriesSelection();
    update();
  }

  void setDocumentSeriesId(int? value) {
    documentSeriesId = value;
    update();
  }

  void setApprovalStatus(String? value) {
    approvalStatus = value ?? 'approved';
    update();
  }

  void setPostingStatus(String? value) {
    postingStatus = value ?? 'posted';
    update();
  }

  void setAdjustmentAccountId(int? value) {
    adjustmentAccountId = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  void setDebitAccountId(int? value) {
    debitAccountId = value;
    update();
  }

  void setCreditAccountId(int? value) {
    creditAccountId = value;
    update();
  }

  void setDebitPartyId(int? value) {
    debitPartyId = value;
    update();
  }

  void setCreditPartyId(int? value) {
    creditPartyId = value;
    update();
  }

  void setCostCenter(String? value) {
    costCenterController.text = value ?? '';
    update();
  }

  void setDepartment(String? value) {
    departmentController.text = value ?? '';
    update();
  }

  void setProject(String? value) {
    projectController.text = value ?? '';
    update();
  }

  void setLineAccountId(int index, int? value) {
    lines[index].accountId = value;
    update();
  }

  void setLinePartyId(int index, int? value) {
    lines[index].partyId = value;
    update();
  }

  void setLineEntryType(int index, String? value) {
    lines[index].entryType = value ?? 'debit';
    update();
  }

  void setLineAmountText(int index, String value) {
    lines[index].amountText = value;
  }

  void setLineCostCenter(int index, String? value) {
    lines[index].costCenter = value ?? '';
    update();
  }

  void setLineDepartment(int index, String? value) {
    lines[index].department = value ?? '';
    update();
  }

  void setLineProject(int index, String? value) {
    lines[index].project = value ?? '';
    update();
  }

  void setLineNarration(int index, String value) {
    lines[index].narration = value;
  }

  String get debitAccountLabel {
    switch (voucherMode) {
      case 'payment':
        return 'Expense ledger (debit)';
      case 'receipt':
        return 'Deposit to (cash / bank)';
      case 'contra':
        return 'To account (debit)';
      default:
        return 'Debit Account';
    }
  }

  String get creditAccountLabel {
    switch (voucherMode) {
      case 'payment':
        return 'Pay from (cash / bank)';
      case 'receipt':
        return 'Indirect income ledger (credit)';
      case 'contra':
        return 'From account (credit)';
      default:
        return 'Credit Account';
    }
  }

  String get debitPartyLabel {
    switch (voucherMode) {
      case 'payment':
        return 'Payee Party';
      case 'receipt':
        return 'Cash / Bank Party';
      case 'contra':
        return 'Deposit Party';
      default:
        return 'Debit Party';
    }
  }

  String get creditPartyLabel {
    switch (voucherMode) {
      case 'payment':
        return 'Cash / Bank Party';
      case 'receipt':
        return 'Payer Party';
      case 'contra':
        return 'Withdraw Party';
      default:
        return 'Credit Party';
    }
  }

  List<AccountModel> get debitAccountOptions {
    switch (voucherMode) {
      case 'payment':
        return expenseLedgerOptions;
      case 'receipt':
        return cashBankAccounts;
      case 'contra':
        return cashBankAccounts;
      default:
        return manualAccounts;
    }
  }

  List<AccountModel> get creditAccountOptions {
    switch (voucherMode) {
      case 'payment':
        return cashBankAccounts;
      case 'receipt':
        return indirectIncomeLedgerOptions;
      case 'contra':
        return cashBankAccounts;
      default:
        return manualAccounts;
    }
  }
}
