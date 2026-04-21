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
          label: 'Payment',
          icon: Icons.payments_outlined,
        ),
        _VoucherModeOption(
          category: 'receipt',
          label: 'Receipt',
          icon: Icons.receipt_long_outlined,
        ),
        _VoucherModeOption(
          category: 'contra',
          label: 'Contra',
          icon: Icons.swap_horiz_outlined,
        ),
        _VoucherModeOption(
          category: 'journal',
          label: 'Journal',
          icon: Icons.menu_book_outlined,
        ),
      ];

  final AccountsService _accountsService = AccountsService();
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
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
        _accountsService.accountsAll(
          filters: const {'sort_by': 'account_name'},
        ),
        _partiesService.parties(
          filters: const {'per_page': 200, 'sort_by': 'party_name'},
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
      final accounts =
          (responses[7] as ApiResponse<List<AccountModel>>).data ??
          const <AccountModel>[];
      final parties =
          (responses[8] as PaginatedResponse<PartyModel>).data ??
          const <PartyModel>[];
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

      setState(() {
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
        _initialLoading = false;
        _syncVoucherTypeWithMode();
        _syncDocumentSeriesSelection();
      });

      final selected = selectId != null
          ? vouchers.cast<VoucherModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedVoucher == null
                ? (vouchers.isNotEmpty ? vouchers.first : null)
                : vouchers.cast<VoucherModel?>().firstWhere(
                    (item) => item?.id == _selectedVoucher?.id,
                    orElse: () => vouchers.isNotEmpty ? vouchers.first : null,
                  ));

      if (selected != null) {
        await _selectVoucher(selected);
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

  List<AccountModel> get _cashBankAccounts {
    return _accounts
        .where(
          (item) => item.accountType == 'cash' || item.accountType == 'bank',
        )
        .toList(growable: false);
  }

  List<AccountModel> get _manualAccounts {
    return _accounts
        .where((item) => item.allowManualEntries || item.isSystemAccount)
        .toList(growable: false);
  }

  List<DocumentSeriesModel> get _filteredDocumentSeriesOptions {
    return _documentSeries
        .where((item) {
          final documentTypeMatches =
              (_selectedVoucherType?.documentType?.trim().isEmpty ?? true) ||
              item.documentType == _selectedVoucherType?.documentType;
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
            narration: item.lineNarration ?? '',
          ),
        )
        .toList(growable: true);
    if (_lines.isEmpty) {
      _lines = <_VoucherLineDraft>[_VoucherLineDraft()];
    }
    _hydrateQuickEntryFromLines(full);
    _formError = null;
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
    _approvalStatus = 'draft';
    _postingStatus = 'draft';
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
    final lineNarration = nullIfEmpty(_lineNarrationController.text);

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

    setState(() {
      _saving = true;
      _formError = null;
    });

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
      final response = _selectedVoucher == null
          ? await _accountsService.createVoucher(model)
          : await _accountsService.updateVoucher(_selectedVoucher!.id!, model);
      final saved = response.data;
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage(selectId: saved?.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
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
                AppFormTextField(
                  labelText: 'Reference No',
                  controller: _referenceNoController,
                  validator: Validators.optionalMaxLength(100, 'Reference No'),
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
                  mappedItems: _accounts
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
            AppActionButton(
              icon: Icons.save_outlined,
              label: _selectedVoucher == null
                  ? 'Save Voucher'
                  : 'Update Voucher',
              onPressed: _save,
              busy: _saving,
            ),
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
                    return FilterChip(
                      selected: _voucherMode == option.category,
                      label: Text(option.label),
                      avatar: Icon(option.icon, size: 18),
                      onSelected: (_) {
                        setState(() {
                          _voucherMode = option.category;
                          _syncVoucherTypeWithMode();
                          _documentSeriesId = null;
                          _syncDocumentSeriesSelection();
                        });
                      },
                    );
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
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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
              ? 'Record a payment with one debit and one credit.'
              : _voucherMode == 'receipt'
              ? 'Record a receipt with one debit and one credit.'
              : 'Move money between cash / bank accounts.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
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
            AppFormTextField(
              labelText: 'Cost Center',
              controller: _costCenterController,
              validator: Validators.optionalMaxLength(100, 'Cost Center'),
            ),
            AppFormTextField(
              labelText: 'Department',
              controller: _departmentController,
              validator: Validators.optionalMaxLength(100, 'Department'),
            ),
            AppFormTextField(
              labelText: 'Project',
              controller: _projectController,
              validator: Validators.optionalMaxLength(100, 'Project'),
            ),
            AppFormTextField(
              labelText: 'Line Narration',
              controller: _lineNarrationController,
              maxLines: 2,
              validator: Validators.optionalMaxLength(500, 'Line Narration'),
            ),
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
                        mappedItems: _accounts
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
        return 'Expense / Target Account';
      case 'receipt':
        return 'Received In';
      case 'contra':
        return 'Deposit To';
      default:
        return 'Debit Account';
    }
  }

  String get _creditAccountLabel {
    switch (_voucherMode) {
      case 'payment':
        return 'Paid Through';
      case 'receipt':
        return 'Received From';
      case 'contra':
        return 'Withdraw From';
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
        return _manualAccounts;
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
        return _manualAccounts;
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
    this.narration = '',
  });

  int? accountId;
  int? partyId;
  String entryType;
  String amountText;
  String narration;
}

class _VoucherModeOption {
  const _VoucherModeOption({
    required this.category,
    required this.label,
    required this.icon,
  });

  final String category;
  final String label;
  final IconData icon;
}
