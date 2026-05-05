import '../../../screen.dart';

class VoucherManagementPage extends StatefulWidget {
  const VoucherManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<VoucherManagementPage> createState() => _VoucherManagementPageState();
}

class _VoucherManagementPageState extends State<VoucherManagementPage> {
  static const List<AppDropdownItem<String>> _approvalStatusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'pending', label: 'Pending'),
        AppDropdownItem(value: 'approved', label: 'Approved'),
        AppDropdownItem(value: 'rejected', label: 'Rejected'),
      ];

  static const List<AppDropdownItem<String>> _postingStatusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'posted', label: 'Posted'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  static const List<AppDropdownItem<String>> _entryTypeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'debit', label: 'Debit'),
        AppDropdownItem(value: 'credit', label: 'Credit'),
      ];

  static const List<_VoucherModeOption> _voucherModeOptions =
      <_VoucherModeOption>[
        _VoucherModeOption(
          category: 'payment',
          label: 'Expense',
          subtitle: 'Cash / bank → expense ledger',
          icon: Icons.payments_outlined,
        ),
        _VoucherModeOption(
          category: 'receipt',
          label: 'Receipt',
          subtitle: 'Indirect income → cash / bank',
          icon: Icons.receipt_long_outlined,
        ),
        _VoucherModeOption(
          category: 'contra',
          label: 'Contra',
          subtitle: 'Cash / bank transfers',
          icon: Icons.swap_horiz_outlined,
        ),
        _VoucherModeOption(
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
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _voucherNoController = TextEditingController();
  final TextEditingController _voucherDateController = TextEditingController();
  final TextEditingController _referenceNoController = TextEditingController();
  final TextEditingController _referenceDateController =
      TextEditingController();
  final TextEditingController _narrationController = TextEditingController();
  final TextEditingController _adjustmentRemarksController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _costCenterController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _projectController = TextEditingController();
  final TextEditingController _lineNarrationController =
      TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<VoucherModel> _vouchers = const <VoucherModel>[];
  List<VoucherModel> _filteredVouchers = const <VoucherModel>[];
  List<DocumentSeriesModel> _documentSeries = const <DocumentSeriesModel>[];
  List<VoucherTypeModel> _voucherTypes = const <VoucherTypeModel>[];
  List<AccountModel> _accounts = const <AccountModel>[];
  List<PartyModel> _parties = const <PartyModel>[];
  List<CostCenterModel> _costCenters = const <CostCenterModel>[];
  List<DepartmentModel> _departments = const <DepartmentModel>[];
  List<ProjectModel> _projects = const <ProjectModel>[];
  VoucherModel? _selectedVoucher;
  int? _contextCompanyId;
  int? _contextBranchId;
  int? _contextLocationId;
  int? _contextFinancialYearId;
  int? _companyId;
  int? _branchId;
  int? _locationId;
  int? _financialYearId;
  int? _voucherTypeId;
  int? _documentSeriesId;
  int? _adjustmentAccountId;
  int? _debitAccountId;
  int? _creditAccountId;
  int? _debitPartyId;
  int? _creditPartyId;
  String _approvalStatus = 'draft';
  String _postingStatus = 'draft';
  String _voucherMode = 'payment';
  bool _isActive = true;

  /// Hides reference, parties, cost dimensions, approvals — keeps ERP-grade doubles.
  bool _simpleEntryMode = true;
  Set<String> _permissionCodes = {};
  bool _isSuperAdmin = false;
  bool _deleting = false;
  bool _auditLogLoading = false;
  List<_VoucherLineDraft> _lines = <_VoucherLineDraft>[];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadPage();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _voucherNoController.dispose();
    _voucherDateController.dispose();
    _referenceNoController.dispose();
    _referenceDateController.dispose();
    _narrationController.dispose();
    _adjustmentRemarksController.dispose();
    _amountController.dispose();
    _costCenterController.dispose();
    _departmentController.dispose();
    _projectController.dispose();
    _lineNarrationController.dispose();
    super.dispose();
  }

  Future<void> _loadPage({int? selectId}) async {
    setState(() {
      _initialLoading = _vouchers.isEmpty;
      _pageError = null;
    });

    try {
      final permissionCodes = await SessionStorage.getPermissionCodes();
      final currentUser = await SessionStorage.getCurrentUser();
      final isSuperAdmin =
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

      final vouchers =
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
      final series =
          (responses[5] as PaginatedResponse<DocumentSeriesModel>).data ??
          const <DocumentSeriesModel>[];
      final voucherTypes =
          (responses[6] as ApiResponse<List<VoucherTypeModel>>).data ??
          const <VoucherTypeModel>[];
      final parties =
          (responses[7] as PaginatedResponse<PartyModel>).data ??
          const <PartyModel>[];
      final costCenters =
          (responses[8] as PaginatedResponse<CostCenterModel>).data ??
          const <CostCenterModel>[];
      final departments =
          (responses[9] as PaginatedResponse<DepartmentModel>).data ??
          const <DepartmentModel>[];
      final projects =
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

      if (!mounted) return;

      final accountsResponse = await _accountsService.accountsAll(
        filters: <String, dynamic>{
          'sort_by': 'account_name',
          if (contextSelection.companyId != null)
            'company_id': contextSelection.companyId,
        },
      );
      final accounts = accountsResponse.data ?? const <AccountModel>[];

      if (!mounted) return;

      setState(() {
        _permissionCodes = permissionCodes.toSet();
        _isSuperAdmin = isSuperAdmin;
        _vouchers = vouchers;
        _filteredVouchers = _filterVouchers(vouchers, _searchController.text);
        _contextCompanyId = contextSelection.companyId;
        _contextBranchId = contextSelection.branchId;
        _contextLocationId = contextSelection.locationId;
        _contextFinancialYearId = contextSelection.financialYearId;
        _documentSeries = series.where((item) => item.isActive).toList();
        _voucherTypes = voucherTypes
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
        _accounts = accounts.where((item) => item.isActive).toList();
        _parties = parties.where((item) => item.isActive).toList();
        _costCenters = costCenters.where((item) => item.isActive).toList();
        _departments = departments.where((item) => item.isActive).toList();
        _projects = projects.where((item) => item.isActive ?? true).toList();
        _initialLoading = false;
        _syncVoucherTypeWithMode();
        _syncDocumentSeriesSelection();
      });

      if (selectId != null) {
        final selected = vouchers.cast<VoucherModel?>().firstWhere(
          (item) => item?.id == selectId,
          orElse: () => null,
        );
        if (selected != null) {
          await _selectVoucher(selected);
        } else {
          _resetForm();
        }
      } else if (_selectedVoucher?.id != null) {
        final reselect = vouchers.cast<VoucherModel?>().firstWhere(
          (item) => item?.id == _selectedVoucher?.id,
          orElse: () => null,
        );
        if (reselect != null) {
          await _selectVoucher(reselect);
        } else {
          _resetForm();
        }
      } else {
        _resetForm();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pageError = error.toString();
        _initialLoading = false;
      });
    }
  }

  List<VoucherModel> _filterVouchers(List<VoucherModel> items, String query) {
    return filterMasterList(items, query, (item) {
      return [
        item.voucherNo ?? '',
        item.referenceNo ?? '',
        item.voucherTypeName ?? '',
        item.narration ?? '',
      ];
    });
  }

  void _applySearch() {
    setState(() {
      _filteredVouchers = _filterVouchers(_vouchers, _searchController.text);
    });
  }

  VoucherTypeModel? get _selectedVoucherType {
    if (_voucherTypeId == null) {
      return null;
    }

    for (final item in _voucherTypes) {
      if (item.id == _voucherTypeId) {
        return item;
      }
    }

    return null;
  }

  List<VoucherTypeModel> get _voucherTypesForMode {
    return _voucherTypes
        .where((item) => item.voucherCategory == _voucherMode)
        .toList(growable: false);
  }

  bool get _usesQuickEntry => _voucherMode != 'journal';

  bool get _hasAccountsUpdate =>
      _isSuperAdmin || _permissionCodes.contains('accounts.update');

  bool get _hasAccountsDelete =>
      _isSuperAdmin || _permissionCodes.contains('accounts.delete');

  /// Posted manual vouchers stay editable when the role has accounts.update (or super admin).
  /// Super admin may also edit system-generated vouchers (API enforces the same).
  bool get _canEditSelectedVoucher {
    final v = _selectedVoucher;
    if (v == null) {
      return true;
    }
    if ((v.postingStatus ?? '').toLowerCase() == 'cancelled') {
      return false;
    }
    if (v.isSystemGenerated && !_isSuperAdmin) {
      return false;
    }
    return _hasAccountsUpdate;
  }

  bool get _canDeleteSelectedVoucher {
    final v = _selectedVoucher;
    if (v?.id == null) {
      return false;
    }
    if ((v!.postingStatus ?? '').toLowerCase() == 'cancelled') {
      return false;
    }
    if (v.isSystemGenerated && !_isSuperAdmin) {
      return false;
    }
    return _hasAccountsDelete;
  }

  List<AccountModel> get _accountsScoped {
    final cid = _companyId ?? _contextCompanyId;
    if (cid == null) {
      return _accounts;
    }
    return _accounts
        .where((item) => item.companyId == cid)
        .toList(growable: false);
  }

  List<AccountModel> get _cashBankAccounts {
    return _accountsScoped
        .where(
          (item) => item.accountType == 'cash' || item.accountType == 'bank',
        )
        .toList(growable: false);
  }

  List<AccountModel> get _manualAccounts {
    return _accountsScoped
        .where((item) => item.allowManualEntries || item.isSystemAccount)
        .toList(growable: false);
  }

  List<CostCenterModel> get _costCentersScoped {
    final cid = _companyId ?? _contextCompanyId;
    if (cid == null) {
      return _costCenters;
    }
    return _costCenters
        .where((item) => item.companyId == null || item.companyId == cid)
        .toList(growable: false);
  }

  List<ProjectModel> get _projectsScoped {
    final cid = _companyId ?? _contextCompanyId;
    if (cid == null) {
      return _projects;
    }
    return _projects
        .where((item) => item.companyId == null || item.companyId == cid)
        .toList(growable: false);
  }

  Map<String, dynamic>? _accountGroupJson(AccountModel a) {
    final m = a.raw;
    if (m == null) {
      return null;
    }
    final g = m['account_group'] ?? m['accountGroup'];
    if (g is Map<String, dynamic>) {
      return g;
    }
    if (g is Map) {
      return Map<String, dynamic>.from(g);
    }
    return null;
  }

  /// Chart classification from API (`account_group` on ledger JSON / `raw`).
  String? _accountGroupNatureOf(AccountModel a) =>
      _accountGroupJson(a)?['group_nature']?.toString();

  String? _accountGroupCategoryOf(AccountModel a) =>
      _accountGroupJson(a)?['group_category']?.toString();

  String _costCenterValueOf(CostCenterModel item) =>
      item.costCenterCode?.trim().isNotEmpty == true
      ? item.costCenterCode!.trim()
      : (item.costCenterName ?? '').trim();

  String _costCenterLabel(CostCenterModel item) {
    final code = item.costCenterCode?.trim() ?? '';
    final name = item.costCenterName?.trim() ?? '';
    if (code.isNotEmpty && name.isNotEmpty && code != name) {
      return '$code - $name';
    }
    return code.isNotEmpty ? code : name;
  }

  String _departmentValueOf(DepartmentModel item) =>
      (item.departmentName ?? '').trim();

  String _projectValueOf(ProjectModel item) =>
      item.projectCode?.trim().isNotEmpty == true
      ? item.projectCode!.trim()
      : (item.projectName ?? '').trim();

  String _projectLabel(ProjectModel item) {
    final code = item.projectCode?.trim() ?? '';
    final name = item.projectName?.trim() ?? '';
    if (code.isNotEmpty && name.isNotEmpty && code != name) {
      return '$code - $name';
    }
    return code.isNotEmpty ? code : name;
  }

  List<AppDropdownItem<String>> _dimensionItems(
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

  List<AppDropdownItem<String>> _costCenterItems([String? currentValue]) =>
      _dimensionItems(
        <String>[?currentValue],
        [
          for (final item in _costCentersScoped)
            if (_costCenterValueOf(item).isNotEmpty)
              AppDropdownItem<String>(
                value: _costCenterValueOf(item),
                label: _costCenterLabel(item),
              ),
        ],
      );

  List<AppDropdownItem<String>> _departmentItems([String? currentValue]) =>
      _dimensionItems(
        <String>[?currentValue],
        [
          for (final item in _departments)
            if (_departmentValueOf(item).isNotEmpty)
              AppDropdownItem<String>(
                value: _departmentValueOf(item),
                label: _departmentValueOf(item),
              ),
        ],
      );

  List<AppDropdownItem<String>> _projectItems([String? currentValue]) =>
      _dimensionItems(
        <String>[?currentValue],
        [
          for (final item in _projectsScoped)
            if (_projectValueOf(item).isNotEmpty)
              AppDropdownItem<String>(
                value: _projectValueOf(item),
                label: _projectLabel(item),
              ),
        ],
      );

  /// Expense / payment: debit side (chart groups with expense nature or expense categories).
  List<AccountModel> get _expenseLedgerOptions {
    bool isExpenseLedger(AccountModel a) {
      final nature = _accountGroupNatureOf(a)?.toLowerCase();
      final cat = _accountGroupCategoryOf(a)?.toLowerCase();
      if (nature == 'expense') {
        return true;
      }
      if (cat == 'direct_expense' || cat == 'indirect_expense') {
        return true;
      }
      return false;
    }

    final scoped = _manualAccounts.where(isExpenseLedger).toList();
    if (scoped.isNotEmpty) {
      return scoped;
    }
    return _manualAccounts
        .where((a) => a.accountType != 'cash' && a.accountType != 'bank')
        .toList(growable: false);
  }

  /// Misc receipt: credit side — prefer indirect income per chart of accounts.
  List<AccountModel> get _indirectIncomeLedgerOptions {
    final scoped = _manualAccounts
        .where(
          (a) => _accountGroupCategoryOf(a)?.toLowerCase() == 'indirect_income',
        )
        .toList();
    if (scoped.isNotEmpty) {
      return scoped;
    }
    return _manualAccounts
        .where((a) => _accountGroupNatureOf(a)?.toLowerCase() == 'income')
        .toList(growable: false);
  }

  List<DocumentSeriesModel> get _filteredDocumentSeriesOptions {
    return _documentSeries
        .where((item) {
          final vdt = _selectedVoucherType?.documentType?.trim() ?? '';
          final documentTypeMatches = vdt.isNotEmpty
              ? item.documentType == vdt
              : <String>{
                  'PAYMENT_VOUCHER',
                  'RECEIPT_VOUCHER',
                  'CONTRA_VOUCHER',
                  'JOURNAL_VOUCHER',
                }.contains(item.documentType);
          final companyMatches =
              _companyId == null ||
              item.companyId == null ||
              item.companyId == _companyId;
          final financialYearMatches =
              _financialYearId == null ||
              item.financialYearId == null ||
              item.financialYearId == _financialYearId;
          return documentTypeMatches && companyMatches && financialYearMatches;
        })
        .toList(growable: false);
  }

  void _syncVoucherTypeWithMode() {
    final options = _voucherTypesForMode;
    if (options.isEmpty) {
      _voucherTypeId = null;
      return;
    }

    final currentExists = options.any((item) => item.id == _voucherTypeId);
    if (!currentExists) {
      _voucherTypeId = options.first.id;
    }
  }

  void _syncDocumentSeriesSelection() {
    final options = _filteredDocumentSeriesOptions;
    if (options.isEmpty) {
      _documentSeriesId = null;
      return;
    }

    final currentExists = options.any((item) => item.id == _documentSeriesId);
    if (!currentExists) {
      _documentSeriesId = options.first.id;
    }
  }

  Future<void> _selectVoucher(VoucherModel voucher) async {
    final response = await _accountsService.voucher(voucher.id!);
    final full = response.data ?? voucher;

    _selectedVoucher = full;
    _companyId = full.companyId;
    _branchId = full.branchId;
    _locationId = full.locationId;
    _financialYearId = full.financialYearId;
    _voucherTypeId = full.voucherTypeId;
    _voucherMode = _resolveVoucherMode(full);
    _documentSeriesId = full.documentSeriesId;
    _voucherNoController.text = full.voucherNo ?? '';
    _voucherDateController.text =
        full.voucherDate?.split('T').first.split(' ').first ?? '';
    _referenceNoController.text = full.referenceNo ?? '';
    _referenceDateController.text =
        full.referenceDate?.split('T').first.split(' ').first ?? '';
    _narrationController.text = full.narration ?? '';
    _adjustmentAccountId = full.adjustmentAccountId;
    _adjustmentRemarksController.text = full.adjustmentRemarks ?? '';
    _approvalStatus = full.approvalStatus ?? 'approved';
    _postingStatus = full.postingStatus ?? 'posted';
    _isActive = full.isActive;
    _lines = full.lines
        .map(
          (item) => _VoucherLineDraft(
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
    if (_lines.isEmpty) {
      _lines = <_VoucherLineDraft>[_VoucherLineDraft()];
    }
    _hydrateQuickEntryFromLines(full);
    _formError = null;
    final mode = _resolveVoucherMode(full);
    _simpleEntryMode =
        mode != 'journal' &&
        full.lines.length <= 2 &&
        (full.referenceNo == null || full.referenceNo!.trim().isEmpty) &&
        full.adjustmentAccountId == null;
    setState(() {});
  }

  void _resetForm() {
    _selectedVoucher = null;
    _companyId = _contextCompanyId;
    _branchId = _contextBranchId;
    _locationId = _contextLocationId;
    _financialYearId = _contextFinancialYearId;
    _voucherMode = 'payment';
    _syncVoucherTypeWithMode();
    _documentSeriesId = null;
    _syncDocumentSeriesSelection();
    _voucherNoController.clear();
    _voucherDateController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    _referenceNoController.clear();
    _referenceDateController.clear();
    _narrationController.clear();
    _adjustmentAccountId = null;
    _adjustmentRemarksController.clear();
    _amountController.clear();
    _costCenterController.clear();
    _departmentController.clear();
    _projectController.clear();
    _lineNarrationController.clear();
    _debitAccountId = null;
    _creditAccountId = null;
    _debitPartyId = null;
    _creditPartyId = null;
    _approvalStatus = _simpleEntryMode ? 'approved' : 'draft';
    _postingStatus = _simpleEntryMode ? 'posted' : 'draft';
    _isActive = true;
    _lines = <_VoucherLineDraft>[_VoucherLineDraft()];
    _formError = null;
    setState(() {});
  }

  String _resolveVoucherMode(VoucherModel voucher) {
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

  void _hydrateQuickEntryFromLines(VoucherModel voucher) {
    _amountController.clear();
    _costCenterController.clear();
    _departmentController.clear();
    _projectController.clear();
    _lineNarrationController.clear();
    _debitAccountId = null;
    _creditAccountId = null;
    _debitPartyId = null;
    _creditPartyId = null;

    if (!_usesQuickEntry) {
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

    _debitAccountId = debitLine.accountId;
    _creditAccountId = creditLine.accountId;
    _debitPartyId = debitLine.partyId;
    _creditPartyId = creditLine.partyId;
    _amountController.text = ((debitLine.amount ?? creditLine.amount) ?? 0)
        .toStringAsFixed(2);
    _costCenterController.text =
        debitLine.costCenter ?? creditLine.costCenter ?? '';
    _departmentController.text =
        debitLine.department ?? creditLine.department ?? '';
    _projectController.text = debitLine.project ?? creditLine.project ?? '';
    _lineNarrationController.text =
        debitLine.lineNarration ?? creditLine.lineNarration ?? '';
  }

  List<VoucherLineModel> _buildQuickEntryLines() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final costCenter = nullIfEmpty(_costCenterController.text);
    final department = nullIfEmpty(_departmentController.text);
    final project = nullIfEmpty(_projectController.text);
    final lineNarration =
        nullIfEmpty(_lineNarrationController.text) ??
        (_simpleEntryMode ? nullIfEmpty(_narrationController.text) : null);

    return <VoucherLineModel>[
      VoucherLineModel(
        accountId: _debitAccountId,
        partyId: _debitPartyId,
        entryType: 'debit',
        amount: amount,
        costCenter: costCenter,
        department: department,
        project: project,
        lineNarration: lineNarration,
      ),
      VoucherLineModel(
        accountId: _creditAccountId,
        partyId: _creditPartyId,
        entryType: 'credit',
        amount: amount,
        costCenter: costCenter,
        department: department,
        project: project,
        lineNarration: lineNarration,
      ),
    ];
  }

  void _addLine() {
    setState(() {
      _lines = List<_VoucherLineDraft>.from(_lines)..add(_VoucherLineDraft());
    });
  }

  void _removeLine(int index) {
    setState(() {
      _lines = List<_VoucherLineDraft>.from(_lines)..removeAt(index);
      if (_lines.isEmpty) {
        _lines.add(_VoucherLineDraft());
      }
    });
  }

  double get _totalDebit {
    double total = 0;
    for (final line in _lines) {
      final amount = double.tryParse(line.amountText.trim()) ?? 0;
      if (line.entryType == 'debit') {
        total += amount;
      }
    }
    return total;
  }

  double get _totalCredit {
    double total = 0;
    for (final line in _lines) {
      final amount = double.tryParse(line.amountText.trim()) ?? 0;
      if (line.entryType == 'credit') {
        total += amount;
      }
    }
    return total;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_usesQuickEntry) {
      final amount = double.tryParse(_amountController.text.trim()) ?? 0;
      if (_debitAccountId == null || _creditAccountId == null || amount <= 0) {
        setState(() {
          _formError = 'Complete both accounts and amount for this voucher.';
        });
        return;
      }
      if (_voucherMode == 'contra' && _debitAccountId == _creditAccountId) {
        setState(() {
          _formError =
              'Contra needs two different cash / bank ledgers (e.g. bank → cash).';
        });
        return;
      }
    }

    final hasInvalidLine =
        !_usesQuickEntry &&
        _lines.any(
          (line) =>
              line.accountId == null ||
              double.tryParse(line.amountText.trim()) == null ||
              (double.tryParse(line.amountText.trim()) ?? 0) <= 0,
        );
    if (hasInvalidLine) {
      setState(() {
        _formError = 'Each voucher line needs account and amount.';
      });
      return;
    }

    final linesForSave = _usesQuickEntry
        ? _buildQuickEntryLines()
        : _lines
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
        _adjustmentAccountId == null) {
      setState(() {
        _formError =
            'Total debit and total credit must be equal. Select an adjustment account if you want auto-balance.';
      });
      return;
    }

    _syncDocumentSeriesSelection();
    final seriesOptions = _filteredDocumentSeriesOptions;
    if (seriesOptions.isEmpty) {
      final vdt = _selectedVoucherType?.documentType?.trim() ?? '';
      setState(() {
        _formError = vdt.isEmpty
            ? 'No document series for accounting vouchers. In Settings → Document series, add rows for PAYMENT_VOUCHER, RECEIPT_VOUCHER, CONTRA_VOUCHER (and JOURNAL_VOUCHER) for this company and financial year.'
            : 'No document series for $vdt. Create one under Settings → Document series for this financial year.';
      });
      return;
    }
    if (_documentSeriesId != null &&
        !seriesOptions.any((s) => s.id == _documentSeriesId)) {
      setState(() {
        _formError =
            'Document series no longer matches this voucher type. Pick a series from the list again.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final wasCreate = _selectedVoucher == null;

    final model = VoucherModel(
      id: _selectedVoucher?.id,
      companyId: _companyId,
      branchId: _branchId,
      locationId: _locationId,
      financialYearId: _financialYearId,
      voucherTypeId: _voucherTypeId,
      documentSeriesId: _documentSeriesId,
      voucherNo: nullIfEmpty(_voucherNoController.text.trim()),
      voucherDate: _voucherDateController.text.trim(),
      referenceNo: nullIfEmpty(_referenceNoController.text),
      referenceDate: nullIfEmpty(_referenceDateController.text),
      narration: nullIfEmpty(_narrationController.text),
      adjustmentAccountId: _adjustmentAccountId,
      adjustmentRemarks: nullIfEmpty(_adjustmentRemarksController.text),
      approvalStatus: _approvalStatus,
      postingStatus: _postingStatus,
      isActive: _isActive,
      lines: linesForSave,
    );

    try {
      final response = wasCreate
          ? await _accountsService.createVoucher(model)
          : await _accountsService.updateVoucher(_selectedVoucher!.id!, model);
      final saved = response.data;
      if (!mounted) return;
      final okMsg = response.message.isNotEmpty
          ? response.message
          : (wasCreate ? 'Voucher saved' : 'Voucher updated');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(okMsg)));
      if (wasCreate) {
        await _loadPage();
        if (!mounted) return;
        _resetForm();
      } else {
        await _loadPage(selectId: saved?.id);
      }
    } catch (error) {
      if (!mounted) return;
      final msg = error is ApiException
          ? error.displayMessage
          : error.toString();
      setState(() => _formError = msg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final id = _selectedVoucher?.id;
    if (id == null || !_canDeleteSelectedVoucher) {
      return;
    }
    final code = _selectedVoucher?.voucherNo ?? '$id';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete voucher'),
        content: Text(
          'Permanently remove voucher $code? This cannot be undone. '
          'Only users with accounts delete permission see this action.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    setState(() {
      _deleting = true;
      _formError = null;
    });
    try {
      final response = await _accountsService.deleteVoucher(id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message.isNotEmpty ? response.message : 'Voucher deleted',
          ),
        ),
      );
      await _loadPage();
      if (!mounted) {
        return;
      }
      _resetForm();
    } catch (error) {
      if (!mounted) {
        return;
      }
      final msg = error is ApiException
          ? error.displayMessage
          : error.toString();
      setState(() => _formError = msg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  Future<void> _openVoucherAuditLog() async {
    final id = _selectedVoucher?.id;
    if (id == null || !mounted) {
      return;
    }
    setState(() => _auditLogLoading = true);
    try {
      final response = await _accountsService.voucherAuditTrail(id);
      if (!mounted) {
        return;
      }
      if (!response.success) {
        final msg = response.message.isNotEmpty
            ? response.message
            : 'Could not load activity log';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
      final rows = response.data ?? const <Map<String, dynamic>>[];
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (ctx) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.45,
            minChildSize: 0.28,
            maxChildSize: 0.92,
            builder: (sheetCtx, scrollController) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppUiConstants.spacingMd,
                    ),
                    child: Text(
                      'Activity — ${_selectedVoucher?.voucherNo ?? '$id'}',
                      style: Theme.of(sheetCtx).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: AppUiConstants.spacingSm),
                  Expanded(
                    child: rows.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppUiConstants.spacingLg),
                              child: Text(
                                'No logged actions yet for this voucher.',
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppUiConstants.spacingMd,
                            ),
                            itemCount: rows.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final row = rows[index];
                              final action = row['action']?.toString() ?? '';
                              final desc = row['description']?.toString() ?? '';
                              final who = row['user_display']?.toString() ?? '';
                              final when = row['created_at']?.toString() ?? '';
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  desc.isNotEmpty ? desc : action,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  [
                                    who,
                                    when,
                                  ].where((s) => s.isNotEmpty).join(' · '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final msg = error is ApiException
          ? error.displayMessage
          : error.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _auditLogLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: () {
          _resetForm();
          if (!Responsive.isDesktop(context)) {
            _workspaceController.openEditor();
          }
        },
        icon: Icons.add_outlined,
        label: 'New Entry',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Vouchers',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading vouchers...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load vouchers',
        message: _pageError!,
        onRetry: _loadPage,
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Vouchers',
      editorTitle: _selectedVoucher?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<VoucherModel>(
        searchController: _searchController,
        searchHint: 'Search vouchers',
        items: _filteredVouchers,
        selectedItem: _selectedVoucher,
        emptyMessage: 'No vouchers found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.voucherNo ?? '',
          subtitle: [
            item.voucherDate ?? '',
            item.voucherTypeName ?? '',
            item.postingStatus ?? '',
          ].where((value) => value.isNotEmpty).join(' · '),
          detail: item.narration ?? '',
          selected: selected,
          onTap: () => _selectVoucher(item),
        ),
      ),
      editor: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_formError != null) ...[
              AppErrorStateView.inline(message: _formError!),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            AppSwitchTile(
              label: 'Simple entry (recommended)',
              subtitle:
                  'Fewer fields — use full options for references, parties, approvals.',
              value: _simpleEntryMode,
              onChanged: (value) => setState(() => _simpleEntryMode = value),
            ),
            SizedBox(height: AppUiConstants.spacingSm),
            SettingsFormWrap(
              children: [
                _buildVoucherModeField(),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Voucher Type',
                  mappedItems: _voucherTypesForMode
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _voucherTypeId,
                  onChanged: (value) => setState(() {
                    _voucherTypeId = value;
                    _documentSeriesId = null;
                    _syncDocumentSeriesSelection();
                  }),
                  validator: Validators.requiredSelection('Voucher Type'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Document Series',
                  mappedItems: _filteredDocumentSeriesOptions
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _documentSeriesId,
                  onChanged: (value) =>
                      setState(() => _documentSeriesId = value),
                  validator: (value) {
                    final voucherNo = _voucherNoController.text.trim();
                    if (voucherNo.isEmpty && value == null) {
                      return 'Document Series is required';
                    }
                    return null;
                  },
                ),
                AppFormTextField(
                  labelText: 'Voucher No',
                  controller: _voucherNoController,
                  hintText: 'Auto-generated',
                  readOnly: true,
                  validator: Validators.optionalMaxLength(100, 'Voucher No'),
                ),
                AppFormTextField(
                  labelText: 'Voucher Date',
                  controller: _voucherDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([
                    Validators.required('Voucher Date'),
                    Validators.date('Voucher Date'),
                  ]),
                ),
                if (!_simpleEntryMode) ...[
                  AppFormTextField(
                    labelText: 'Reference No',
                    controller: _referenceNoController,
                    validator: Validators.optionalMaxLength(
                      100,
                      'Reference No',
                    ),
                  ),
                  AppFormTextField(
                    labelText: 'Reference Date',
                    controller: _referenceDateController,
                    keyboardType: TextInputType.datetime,
                    inputFormatters: const [DateInputFormatter()],
                    validator: Validators.optionalDate('Reference Date'),
                  ),
                  AppDropdownField<String>.fromMapped(
                    labelText: 'Approval Status',
                    mappedItems: _approvalStatusItems,
                    initialValue: _approvalStatus,
                    onChanged: (value) =>
                        setState(() => _approvalStatus = value ?? 'approved'),
                  ),
                  AppDropdownField<String>.fromMapped(
                    labelText: 'Posting Status',
                    mappedItems: _postingStatusItems,
                    initialValue: _postingStatus,
                    onChanged: (value) =>
                        setState(() => _postingStatus = value ?? 'posted'),
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Adjustment Account',
                    mappedItems: _accountsScoped
                        .where((item) => item.id != null)
                        .map(
                          (item) => AppDropdownItem(
                            value: item.id!,
                            label: item.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: _adjustmentAccountId,
                    onChanged: (value) =>
                        setState(() => _adjustmentAccountId = value),
                  ),
                  AppFormTextField(
                    labelText: 'Adjustment Remarks',
                    controller: _adjustmentRemarksController,
                    validator: Validators.optionalMaxLength(
                      500,
                      'Adjustment Remarks',
                    ),
                  ),
                ],
                AppFormTextField(
                  labelText: 'Narration',
                  controller: _narrationController,
                  maxLines: 3,
                  validator: Validators.optionalMaxLength(1000, 'Narration'),
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSwitchTile(
              label: 'Active',
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: AppUiConstants.spacingLg),
            _buildEntryBody(),
            if (_selectedVoucher != null) ...[
              if ((_selectedVoucher!.postingStatus ?? '').toLowerCase() ==
                  'cancelled') ...[
                Text(
                  'Cancelled vouchers cannot be edited or deleted here.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ] else if (_selectedVoucher!.isSystemGenerated &&
                  !_isSuperAdmin) ...[
                Text(
                  'This voucher was created by the system from another module. '
                  'It cannot be edited or deleted on this screen unless you are a super admin.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ] else if (_selectedVoucher!.isSystemGenerated &&
                  _isSuperAdmin) ...[
                Text(
                  'Super admin: you may edit or delete this system-generated voucher. '
                  'Source documents may no longer match the books.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ] else if (_hasAccountsUpdate) ...[
                Text(
                  'Manual vouchers remain editable after posting when you have accounts update (or super admin). '
                  'Review books after changes.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppActionButton(
                    icon: Icons.save_outlined,
                    label: _selectedVoucher == null
                        ? 'Save Voucher'
                        : 'Update Voucher',
                    onPressed:
                        (_selectedVoucher == null || _canEditSelectedVoucher)
                        ? _save
                        : null,
                    busy: _saving,
                  ),
                ),
                if (_canDeleteSelectedVoucher) ...[
                  const SizedBox(width: AppUiConstants.spacingSm),
                  AppActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    filled: false,
                    onPressed: _deleting ? null : _confirmDelete,
                    busy: _deleting,
                  ),
                ],
              ],
            ),
            if (_selectedVoucher?.id != null) ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppUiConstants.spacingSm,
                      vertical: 2,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                  ),
                  onPressed: _auditLogLoading ? null : _openVoucherAuditLog,
                  child: _auditLogLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Activity log',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherModeField() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Entry Mode', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppUiConstants.spacingXs),
            Wrap(
              spacing: AppUiConstants.spacingXs,
              runSpacing: AppUiConstants.spacingXs,
              children: _voucherModeOptions
                  .map((option) {
                    final chip = FilterChip(
                      selected: _voucherMode == option.category,
                      label: Text(option.label),
                      avatar: Icon(option.icon, size: 18),
                      onSelected: (_) {
                        setState(() {
                          _voucherMode = option.category;
                          if (option.category == 'journal') {
                            _simpleEntryMode = false;
                          }
                          _syncVoucherTypeWithMode();
                          _documentSeriesId = null;
                          _syncDocumentSeriesSelection();
                        });
                      },
                    );
                    final hint = option.subtitle;
                    if (hint == null || hint.isEmpty) {
                      return chip;
                    }
                    return Tooltip(message: hint, child: chip);
                  })
                  .toList(growable: false),
            ),
            if (width > 0) const SizedBox.shrink(),
          ],
        );
      },
    );
  }

  Widget _buildEntryBody() {
    final totals = _usesQuickEntry
        ? <String, double>{
            'debit': double.tryParse(_amountController.text.trim()) ?? 0,
            'credit': double.tryParse(_amountController.text.trim()) ?? 0,
          }
        : <String, double>{'debit': _totalDebit, 'credit': _totalCredit};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionCard(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Debit: ${totals['debit']!.toStringAsFixed(2)}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: Text(
                  'Credit: ${totals['credit']!.toStringAsFixed(2)}',
                  textAlign: TextAlign.end,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppUiConstants.spacingMd),
        if (_usesQuickEntry)
          _buildQuickEntrySection()
        else
          _buildJournalLines(),
        _buildSettlementsReadOnly(),
      ],
    );
  }

  Widget _buildSettlementsReadOnly() {
    final voucher = _selectedVoucher;
    if (voucher == null) {
      return const SizedBox.shrink();
    }
    final tiles = <Widget>[];
    for (final line in voucher.lines) {
      if (line.allocations.isEmpty) {
        continue;
      }
      for (final alloc in line.allocations) {
        final m = alloc.data;
        tiles.add(
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Line ${line.lineNo ?? '?'} · ${m['reference_no'] ?? ''} (${m['allocation_type'] ?? ''})',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            subtitle: Text(
              'Amount: ${m['allocation_amount'] ?? ''} · Against voucher #${m['against_voucher_id'] ?? '—'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      }
    }
    if (tiles.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        const SizedBox(height: AppUiConstants.spacingMd),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bill settlements',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppUiConstants.spacingSm),
              ...tiles,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickEntrySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _voucherMode == 'payment'
              ? 'Record spend: expense ledger is debited, cash or bank is credited.'
              : _voucherMode == 'receipt'
              ? 'Miscellaneous receipt: bank/cash is debited, indirect income is credited (customer receipts stay in Sales).'
              : 'Transfer only between cash and bank ledgers — same amount on both sides.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (_voucherMode == 'payment' && _expenseLedgerOptions.isEmpty) ...[
          const SizedBox(height: AppUiConstants.spacingXs),
          Text(
            'No expense ledgers match your chart (group nature “expense” or categories direct/indirect expense). '
            'Until those exist, all non-cash/bank ledgers are listed below.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
        ],
        if (_voucherMode == 'receipt' &&
            _indirectIncomeLedgerOptions.isEmpty) ...[
          const SizedBox(height: AppUiConstants.spacingXs),
          Text(
            'No “indirect income” group found — showing all income ledgers. Tag account groups as indirect income for a tighter list.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
        ],
        if (_voucherMode == 'contra' && _cashBankAccounts.length < 2) ...[
          const SizedBox(height: AppUiConstants.spacingXs),
          Text(
            'You need at least two active cash/bank ledgers for transfers.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: AppUiConstants.spacingSm),
        SettingsFormWrap(
          children: [
            AppDropdownField<int>.fromMapped(
              labelText: _debitAccountLabel,
              mappedItems: _debitAccountOptions
                  .where((item) => item.id != null)
                  .map(
                    (item) => AppDropdownItem(
                      value: item.id!,
                      label: item.toString(),
                    ),
                  )
                  .toList(growable: false),
              initialValue: _debitAccountId,
              onChanged: (value) => setState(() => _debitAccountId = value),
              validator: Validators.requiredSelection(_debitAccountLabel),
            ),
            AppDropdownField<int>.fromMapped(
              labelText: _creditAccountLabel,
              mappedItems: _creditAccountOptions
                  .where((item) => item.id != null)
                  .map(
                    (item) => AppDropdownItem(
                      value: item.id!,
                      label: item.toString(),
                    ),
                  )
                  .toList(growable: false),
              initialValue: _creditAccountId,
              onChanged: (value) => setState(() => _creditAccountId = value),
              validator: Validators.requiredSelection(_creditAccountLabel),
            ),
            if (!_simpleEntryMode) ...[
              AppDropdownField<int>.fromMapped(
                labelText: _debitPartyLabel,
                mappedItems: _parties
                    .where((item) => item.id != null)
                    .map(
                      (item) => AppDropdownItem(
                        value: item.id!,
                        label: item.toString(),
                      ),
                    )
                    .toList(growable: false),
                initialValue: _debitPartyId,
                onChanged: (value) => setState(() => _debitPartyId = value),
              ),
              AppDropdownField<int>.fromMapped(
                labelText: _creditPartyLabel,
                mappedItems: _parties
                    .where((item) => item.id != null)
                    .map(
                      (item) => AppDropdownItem(
                        value: item.id!,
                        label: item.toString(),
                      ),
                    )
                    .toList(growable: false),
                initialValue: _creditPartyId,
                onChanged: (value) => setState(() => _creditPartyId = value),
              ),
            ],
            AppFormTextField(
              labelText: 'Amount',
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: Validators.compose([
                Validators.required('Amount'),
                Validators.optionalNonNegativeNumber('Amount'),
                (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Amount must be greater than zero';
                  }
                  return null;
                },
              ]),
            ),
            if (!_simpleEntryMode) ...[
              AppDropdownField<String>.fromMapped(
                labelText: 'Cost Center',
                mappedItems: _costCenterItems(_costCenterController.text),
                initialValue: nullIfEmpty(_costCenterController.text),
                onChanged: (value) =>
                    setState(() => _costCenterController.text = value ?? ''),
              ),
              AppDropdownField<String>.fromMapped(
                labelText: 'Department',
                mappedItems: _departmentItems(_departmentController.text),
                initialValue: nullIfEmpty(_departmentController.text),
                onChanged: (value) =>
                    setState(() => _departmentController.text = value ?? ''),
              ),
              AppDropdownField<String>.fromMapped(
                labelText: 'Project',
                mappedItems: _projectItems(_projectController.text),
                initialValue: nullIfEmpty(_projectController.text),
                onChanged: (value) =>
                    setState(() => _projectController.text = value ?? ''),
              ),
              AppFormTextField(
                labelText: 'Line Narration',
                controller: _lineNarrationController,
                maxLines: 2,
                validator: Validators.optionalMaxLength(500, 'Line Narration'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildJournalLines() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Journal Lines',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            AppActionButton(
              icon: Icons.add_outlined,
              label: 'Add Line',
              onPressed: _addLine,
              filled: false,
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        ...List<Widget>.generate(_lines.length, (index) {
          final line = _lines[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppSectionCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Line ${index + 1}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _lines.length == 1
                            ? null
                            : () => _removeLine(index),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                  SettingsFormWrap(
                    children: [
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Account',
                        mappedItems: _accountsScoped
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppDropdownItem(
                                value: item.id!,
                                label: item.toString(),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: line.accountId,
                        onChanged: (value) =>
                            setState(() => line.accountId = value),
                        validator: Validators.requiredSelection('Account'),
                      ),
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Party',
                        mappedItems: _parties
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppDropdownItem(
                                value: item.id!,
                                label: item.toString(),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: line.partyId,
                        onChanged: (value) =>
                            setState(() => line.partyId = value),
                      ),
                      AppDropdownField<String>.fromMapped(
                        labelText: 'Entry Type',
                        mappedItems: _entryTypeItems,
                        initialValue: line.entryType,
                        onChanged: (value) =>
                            setState(() => line.entryType = value ?? 'debit'),
                        validator: Validators.requiredSelection('Entry Type'),
                      ),
                      AppFormTextField(
                        labelText: 'Amount',
                        initialValue: line.amountText,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) => line.amountText = value,
                        validator: Validators.compose([
                          Validators.required('Amount'),
                          Validators.optionalNonNegativeNumber('Amount'),
                          (value) {
                            final parsed = double.tryParse(value?.trim() ?? '');
                            if (parsed == null || parsed <= 0) {
                              return 'Amount must be greater than zero';
                            }
                            return null;
                          },
                        ]),
                      ),
                      AppDropdownField<String>.fromMapped(
                        labelText: 'Cost Center',
                        mappedItems: _costCenterItems(line.costCenter),
                        initialValue: nullIfEmpty(line.costCenter),
                        onChanged: (value) =>
                            setState(() => line.costCenter = value ?? ''),
                      ),
                      AppDropdownField<String>.fromMapped(
                        labelText: 'Department',
                        mappedItems: _departmentItems(line.department),
                        initialValue: nullIfEmpty(line.department),
                        onChanged: (value) =>
                            setState(() => line.department = value ?? ''),
                      ),
                      AppDropdownField<String>.fromMapped(
                        labelText: 'Project',
                        mappedItems: _projectItems(line.project),
                        initialValue: nullIfEmpty(line.project),
                        onChanged: (value) =>
                            setState(() => line.project = value ?? ''),
                      ),
                      AppFormTextField(
                        labelText: 'Line Narration',
                        initialValue: line.narration,
                        onChanged: (value) => line.narration = value,
                        validator: Validators.optionalMaxLength(
                          500,
                          'Line Narration',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  String get _debitAccountLabel {
    switch (_voucherMode) {
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

  String get _creditAccountLabel {
    switch (_voucherMode) {
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

  String get _debitPartyLabel {
    switch (_voucherMode) {
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

  String get _creditPartyLabel {
    switch (_voucherMode) {
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

  List<AccountModel> get _debitAccountOptions {
    switch (_voucherMode) {
      case 'payment':
        return _expenseLedgerOptions;
      case 'receipt':
        return _cashBankAccounts;
      case 'contra':
        return _cashBankAccounts;
      default:
        return _manualAccounts;
    }
  }

  List<AccountModel> get _creditAccountOptions {
    switch (_voucherMode) {
      case 'payment':
        return _cashBankAccounts;
      case 'receipt':
        return _indirectIncomeLedgerOptions;
      case 'contra':
        return _cashBankAccounts;
      default:
        return _manualAccounts;
    }
  }
}

class _VoucherLineDraft {
  _VoucherLineDraft({
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

class _VoucherModeOption {
  const _VoucherModeOption({
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
