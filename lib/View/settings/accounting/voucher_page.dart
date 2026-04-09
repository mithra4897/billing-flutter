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

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<VoucherModel> _vouchers = const <VoucherModel>[];
  List<VoucherModel> _filteredVouchers = const <VoucherModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<BranchModel> _branches = const <BranchModel>[];
  List<BusinessLocationModel> _locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> _financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> _documentSeries = const <DocumentSeriesModel>[];
  List<VoucherTypeModel> _voucherTypes = const <VoucherTypeModel>[];
  List<AccountModel> _accounts = const <AccountModel>[];
  List<PartyModel> _parties = const <PartyModel>[];
  VoucherModel? _selectedVoucher;
  int? _companyId;
  int? _branchId;
  int? _locationId;
  int? _financialYearId;
  int? _voucherTypeId;
  int? _documentSeriesId;
  int? _adjustmentAccountId;
  String _approvalStatus = 'approved';
  String _postingStatus = 'posted';
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
        _accountsService.accountsAll(filters: const {'sort_by': 'account_name'}),
        _partiesService.parties(
          filters: const {'per_page': 200, 'sort_by': 'party_name'},
        ),
      ]);

      final vouchers = (responses[0] as PaginatedResponse<VoucherModel>).data ??
          const <VoucherModel>[];
      final companies = (responses[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final branches = (responses[2] as PaginatedResponse<BranchModel>).data ??
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
      final parties = (responses[8] as PaginatedResponse<PartyModel>).data ??
          const <PartyModel>[];

      if (!mounted) return;

      setState(() {
        _vouchers = vouchers;
        _filteredVouchers = _filterVouchers(vouchers, _searchController.text);
        _companies = companies.where((item) => item.isActive).toList();
        _branches = branches.where((item) => item.isActive).toList();
        _locations = locations.where((item) => item.isActive).toList();
        _financialYears = years.where((item) => item.isActive).toList();
        _documentSeries = series
            .where(
              (item) => item.isActive && (item.documentType ?? '') == 'JOURNAL_VOUCHER',
            )
            .toList();
        _voucherTypes = voucherTypes.where((item) => item.isActive).toList();
        _accounts = accounts.where((item) => item.isActive).toList();
        _parties = parties.where((item) => item.isActive).toList();
        _initialLoading = false;
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

  List<BranchModel> get _branchOptions {
    if (_companyId == null) return _branches;
    return _branches
        .where((item) => item.companyId == null || item.companyId == _companyId)
        .toList(growable: false);
  }

  List<BusinessLocationModel> get _locationOptions {
    if (_branchId == null) return _locations;
    return _locations
        .where((item) => item.branchId == null || item.branchId == _branchId)
        .toList(growable: false);
  }

  List<FinancialYearModel> get _yearOptions {
    if (_companyId == null) return _financialYears;
    return _financialYears
        .where((item) => item.companyId == _companyId)
        .toList(growable: false);
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
    _documentSeriesId = full.documentSeriesId;
    _voucherNoController.text = full.voucherNo ?? '';
    _voucherDateController.text = full.voucherDate?.split('T').first.split(' ').first ?? '';
    _referenceNoController.text = full.referenceNo ?? '';
    _referenceDateController.text = full.referenceDate?.split('T').first.split(' ').first ?? '';
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
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedVoucher = null;
    _companyId = _companies.isNotEmpty ? _companies.first.id : null;
    _branchId = null;
    _locationId = null;
    _financialYearId = _yearOptions.isNotEmpty ? _yearOptions.first.id : null;
    _voucherTypeId = _voucherTypes.isNotEmpty ? _voucherTypes.first.id : null;
    _documentSeriesId = _documentSeries.isNotEmpty ? _documentSeries.first.id : null;
    _voucherNoController.clear();
    _voucherDateController.text = DateTime.now().toIso8601String().split('T').first;
    _referenceNoController.clear();
    _referenceDateController.clear();
    _narrationController.clear();
    _adjustmentAccountId = null;
    _adjustmentRemarksController.clear();
    _approvalStatus = 'approved';
    _postingStatus = 'posted';
    _isActive = true;
    _lines = <_VoucherLineDraft>[_VoucherLineDraft()];
    _formError = null;
    setState(() {});
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final hasInvalidLine = _lines.any(
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
      voucherNo: _voucherNoController.text.trim(),
      voucherDate: _voucherDateController.text.trim(),
      referenceNo: nullIfEmpty(_referenceNoController.text),
      referenceDate: nullIfEmpty(_referenceDateController.text),
      narration: nullIfEmpty(_narrationController.text),
      adjustmentAccountId: _adjustmentAccountId,
      adjustmentRemarks: nullIfEmpty(_adjustmentRemarksController.text),
      approvalStatus: _approvalStatus,
      postingStatus: _postingStatus,
      isActive: _isActive,
      lines: _lines
          .map(
            (line) => VoucherLineModel(
              accountId: line.accountId,
              partyId: line.partyId,
              entryType: line.entryType,
              amount: double.tryParse(line.amountText.trim()),
              lineNarration: nullIfEmpty(line.narration),
            ),
          )
          .toList(growable: false),
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
        label: 'New Voucher',
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
      editor: AppSectionCard(
        child: Form(
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
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Company',
                    mappedItems: _companies
                        .where((item) => item.id != null)
                        .map((item) => AppDropdownItem(value: item.id!, label: item.toString()))
                        .toList(growable: false),
                    initialValue: _companyId,
                    onChanged: (value) {
                      setState(() {
                        _companyId = value;
                        if (!_branchOptions.any((item) => item.id == _branchId)) {
                          _branchId = null;
                        }
                        if (!_yearOptions.any((item) => item.id == _financialYearId)) {
                          _financialYearId = null;
                        }
                      });
                    },
                    validator: Validators.requiredSelection('Company'),
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Branch',
                    mappedItems: _branchOptions
                        .where((item) => item.id != null)
                        .map((item) => AppDropdownItem(value: item.id!, label: item.toString()))
                        .toList(growable: false),
                    initialValue: _branchId,
                    onChanged: (value) {
                      setState(() {
                        _branchId = value;
                        if (!_locationOptions.any((item) => item.id == _locationId)) {
                          _locationId = null;
                        }
                      });
                    },
                    validator: Validators.requiredSelection('Branch'),
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Location',
                    mappedItems: _locationOptions
                        .where((item) => item.id != null)
                        .map((item) => AppDropdownItem(value: item.id!, label: item.toString()))
                        .toList(growable: false),
                    initialValue: _locationId,
                    onChanged: (value) => setState(() => _locationId = value),
                    validator: Validators.requiredSelection('Location'),
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Financial Year',
                    mappedItems: _yearOptions
                        .map(
                          (item) =>
                              AppDropdownItem(value: item.id, label: item.toString()),
                        )
                        .toList(growable: false),
                    initialValue: _financialYearId,
                    onChanged: (value) =>
                        setState(() => _financialYearId = value),
                    validator: Validators.requiredSelection('Financial Year'),
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Voucher Type',
                    mappedItems: _voucherTypes
                        .where((item) => item.id != null)
                        .map((item) => AppDropdownItem(value: item.id!, label: item.toString()))
                        .toList(growable: false),
                    initialValue: _voucherTypeId,
                    onChanged: (value) => setState(() => _voucherTypeId = value),
                    validator: Validators.requiredSelection('Voucher Type'),
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Document Series',
                    mappedItems: _documentSeries
                        .where((item) => item.id != null)
                        .map((item) => AppDropdownItem(value: item.id!, label: item.toString()))
                        .toList(growable: false),
                    initialValue: _documentSeriesId,
                    onChanged: (value) =>
                        setState(() => _documentSeriesId = value),
                  ),
                  AppFormTextField(
                    labelText: 'Voucher No',
                    controller: _voucherNoController,
                    validator: Validators.compose([
                      Validators.required('Voucher No'),
                      Validators.optionalMaxLength(100, 'Voucher No'),
                    ]),
                  ),
                  AppFormTextField(
                    labelText: 'Voucher Date',
                    controller: _voucherDateController,
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
                    validator: Validators.optionalDate('Reference Date'),
                  ),
                  AppDropdownField<String>.fromMapped(
                    labelText: 'Approval Status',
                    mappedItems: _approvalStatusItems,
                    initialValue: _approvalStatus,
                    onChanged: (value) => setState(
                      () => _approvalStatus = value ?? 'approved',
                    ),
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
                        .map((item) => AppDropdownItem(value: item.id!, label: item.toString()))
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
              Row(
                children: [
                  Text(
                    'Voucher Lines',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
                                  .map((item) => AppDropdownItem(value: item.id!, label: item.toString()))
                                  .toList(growable: false),
                              initialValue: line.accountId,
                              onChanged: (value) =>
                                  setState(() => line.accountId = value),
                            ),
                            AppDropdownField<int>.fromMapped(
                              labelText: 'Party',
                              mappedItems: _parties
                                  .where((item) => item.id != null)
                                  .map((item) => AppDropdownItem(value: item.id!, label: item.toString()))
                                  .toList(growable: false),
                              initialValue: line.partyId,
                              onChanged: (value) =>
                                  setState(() => line.partyId = value),
                            ),
                            AppDropdownField<String>.fromMapped(
                              labelText: 'Entry Type',
                              mappedItems: _entryTypeItems,
                              initialValue: line.entryType,
                              onChanged: (value) => setState(
                                () => line.entryType = value ?? 'debit',
                              ),
                            ),
                            AppFormTextField(
                              labelText: 'Amount',
                              initialValue: line.amountText,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (value) => line.amountText = value,
                            ),
                            AppFormTextField(
                              labelText: 'Line Narration',
                              initialValue: line.narration,
                              onChanged: (value) => line.narration = value,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              AppActionButton(
                icon: Icons.save_outlined,
                label: _selectedVoucher == null ? 'Save Voucher' : 'Update Voucher',
                onPressed: _save,
                busy: _saving,
              ),
            ],
          ),
        ),
      ),
    );
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
