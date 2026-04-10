import '../../../screen.dart';

class CashSessionManagementPage extends StatefulWidget {
  const CashSessionManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CashSessionManagementPage> createState() =>
      _CashSessionManagementPageState();
}

class _CashSessionManagementPageState extends State<CashSessionManagementPage> {
  final AccountsService _accountsService = AccountsService();
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _openFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _closeFormKey = GlobalKey<FormState>();
  final TextEditingController _openingDatetimeController =
      TextEditingController();
  final TextEditingController _openingBalanceController =
      TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _closingDatetimeController =
      TextEditingController();
  final TextEditingController _expectedClosingController =
      TextEditingController();
  final TextEditingController _actualClosingController =
      TextEditingController();
  final TextEditingController _closingRemarksController =
      TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<CashSessionModel> _sessions = const <CashSessionModel>[];
  List<CashSessionModel> _filteredSessions = const <CashSessionModel>[];
  List<AccountModel> _cashAccounts = const <AccountModel>[];
  CashSessionModel? _selectedSession;
  int? _contextCompanyId;
  int? _contextBranchId;
  int? _contextLocationId;
  int? _companyId;
  int? _branchId;
  int? _locationId;
  int? _cashAccountId;
  int? _currentUserId;
  String? _currentUserLabel;

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
    _openingDatetimeController.dispose();
    _openingBalanceController.dispose();
    _remarksController.dispose();
    _closingDatetimeController.dispose();
    _expectedClosingController.dispose();
    _actualClosingController.dispose();
    _closingRemarksController.dispose();
    super.dispose();
  }

  Future<void> _loadPage({int? selectId}) async {
    setState(() {
      _initialLoading = _sessions.isEmpty;
      _pageError = null;
    });

    try {
      final currentUser = await SessionStorage.getCurrentUser();
      final responses = await Future.wait<dynamic>([
        _accountsService.cashSessions(),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
        _masterService.branches(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
        _masterService.businessLocations(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
        _accountsService.accountsAll(
          filters: const {
            'account_type': 'cash',
            'is_active': 1,
            'sort_by': 'account_name',
          },
        ),
      ]);

      final sessions =
          (responses[0] as ApiResponse<List<CashSessionModel>>).data ??
              const <CashSessionModel>[];
      final companies = (responses[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final branches = (responses[2] as PaginatedResponse<BranchModel>).data ??
          const <BranchModel>[];
      final locations =
          (responses[3] as PaginatedResponse<BusinessLocationModel>).data ??
              const <BusinessLocationModel>[];
      final accounts = (responses[4] as ApiResponse<List<AccountModel>>).data ??
          const <AccountModel>[];
      final activeCompanies = companies
          .where((item) => item.isActive)
          .toList(growable: false);
      final activeBranches = branches
          .where((item) => item.isActive)
          .toList(growable: false);
      final activeLocations = locations
          .where((item) => item.isActive)
          .toList(growable: false);
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: activeBranches,
            locations: activeLocations,
            financialYears: const <FinancialYearModel>[],
          );

      if (!mounted) return;

      setState(() {
        _sessions = sessions;
        _filteredSessions = _filterSessions(sessions, _searchController.text);
        _contextCompanyId = contextSelection.companyId;
        _contextBranchId = contextSelection.branchId;
        _contextLocationId = contextSelection.locationId;
        _cashAccounts = accounts.where((item) => item.isActive).toList();
        _currentUserId = int.tryParse(currentUser?['id']?.toString() ?? '');
        _currentUserLabel =
            currentUser?['display_name']?.toString() ??
            currentUser?['username']?.toString();
        _initialLoading = false;
      });

      final selected = selectId != null
          ? sessions.cast<CashSessionModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedSession == null
                ? (sessions.isNotEmpty ? sessions.first : null)
                : sessions.cast<CashSessionModel?>().firstWhere(
                    (item) => item?.id == _selectedSession?.id,
                    orElse: () => sessions.isNotEmpty ? sessions.first : null,
                  ));

      if (selected != null) {
        _selectSession(selected);
      } else {
        _resetOpenForm();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pageError = error.toString();
        _initialLoading = false;
      });
    }
  }

  List<CashSessionModel> _filterSessions(
    List<CashSessionModel> items,
    String query,
  ) {
    return filterMasterList(items, query, (item) {
      return [
        item.cashAccountName ?? '',
        item.cashAccountCode ?? '',
        item.username ?? '',
        item.userDisplayName ?? '',
        item.status ?? '',
      ];
    });
  }

  void _applySearch() {
    setState(() {
      _filteredSessions = _filterSessions(_sessions, _searchController.text);
    });
  }

  List<AccountModel> get _cashAccountOptions {
    return _cashAccounts.where((item) {
      final companyMatches =
          _companyId == null || item.companyId == null || item.companyId == _companyId;
      final branchMatches =
          _branchId == null || item.branchId == null || item.branchId == _branchId;
      return companyMatches && branchMatches;
    }).toList(growable: false);
  }

  void _selectSession(CashSessionModel item) {
    _selectedSession = item;
    _companyId = item.companyId;
    _branchId = item.branchId;
    _locationId = item.locationId;
    _cashAccountId = item.cashAccountId;
    _openingDatetimeController.text = item.openingDatetime?.split('.').first ?? '';
    _openingBalanceController.text = item.openingBalance?.toString() ?? '0';
    _remarksController.text = item.remarks ?? '';
    _closingDatetimeController.text =
        item.closingDatetime?.split('.').first ??
        DateTime.now().toIso8601String().split('.').first;
    _expectedClosingController.text =
        item.expectedClosingBalance?.toString() ?? '';
    _actualClosingController.text =
        item.actualClosingBalance?.toString() ?? '';
    _closingRemarksController.text = item.remarks ?? '';
    _formError = null;
    setState(() {});
  }

  void _resetOpenForm() {
    _selectedSession = null;
    _companyId = _contextCompanyId;
    _branchId = _contextBranchId;
    _locationId = _contextLocationId;
    _cashAccountId = _cashAccountOptions.isNotEmpty
        ? _cashAccountOptions.first.id
        : null;
    _openingDatetimeController.text =
        DateTime.now().toIso8601String().split('.').first;
    _openingBalanceController.text = '0';
    _remarksController.clear();
    _closingDatetimeController.text =
        DateTime.now().toIso8601String().split('.').first;
    _expectedClosingController.clear();
    _actualClosingController.clear();
    _closingRemarksController.clear();
    _formError = null;
    setState(() {});
  }

  Future<void> _openSession() async {
    if (!_openFormKey.currentState!.validate() || _currentUserId == null) return;

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final response = await _accountsService.openCashSession(
        CashSessionModel(
          companyId: _companyId,
          branchId: _branchId,
          locationId: _locationId,
          userId: _currentUserId,
          cashAccountId: _cashAccountId,
          openingDatetime: _openingDatetimeController.text.trim(),
          openingBalance:
              double.tryParse(_openingBalanceController.text.trim()) ?? 0,
          remarks: nullIfEmpty(_remarksController.text),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage(selectId: response.data?.id);
    } catch (error) {
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _closeSession() async {
    final id = _selectedSession?.id;
    if (id == null || !_closeFormKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final response = await _accountsService.closeCashSession(
        id,
        CashSessionModel(
          closingDatetime: _closingDatetimeController.text.trim(),
          expectedClosingBalance:
              double.tryParse(_expectedClosingController.text.trim()),
          actualClosingBalance:
              double.tryParse(_actualClosingController.text.trim()),
          remarks: nullIfEmpty(_closingRemarksController.text),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage(selectId: response.data?.id);
    } catch (error) {
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cancelSession() async {
    final id = _selectedSession?.id;
    if (id == null) return;

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final response = await _accountsService.cancelCashSession(
        id,
        CashSessionModel(remarks: nullIfEmpty(_closingRemarksController.text)),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage(selectId: response.data?.id);
    } catch (error) {
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: () {
          _resetOpenForm();
          if (!Responsive.isDesktop(context)) {
            _workspaceController.openEditor();
          }
        },
        icon: Icons.point_of_sale_outlined,
        label: 'Open Session',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Cash Sessions',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading cash sessions...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load cash sessions',
        message: _pageError!,
        onRetry: _loadPage,
      );
    }

    final isOpen = (_selectedSession?.status ?? '') == 'open';

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Cash Sessions',
      editorTitle: _selectedSession?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<CashSessionModel>(
        searchController: _searchController,
        searchHint: 'Search cash sessions',
        items: _filteredSessions,
        selectedItem: _selectedSession,
        emptyMessage: 'No cash sessions found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.cashAccountName ?? item.cashAccountCode ?? '',
          subtitle: [
            item.userDisplayName ?? item.username ?? '',
            item.status ?? '',
            item.openingDatetime?.split(' ').first ?? '',
          ].where((value) => value.isNotEmpty).join(' · '),
          selected: selected,
          onTap: () => _selectSession(item),
        ),
      ),
      editor: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_formError != null) ...[
              AppErrorStateView.inline(message: _formError!),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            Text(
              'Current User',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(_currentUserLabel ?? 'Unknown user'),
            const SizedBox(height: AppUiConstants.spacingMd),
            Form(
              key: _openFormKey,
              child: SettingsFormWrap(
                children: [
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Cash Account',
                    mappedItems: _cashAccountOptions
                        .where((item) => item.id != null)
                        .map((item) => AppDropdownItem(value: item.id!, label: item.toString()))
                        .toList(growable: false),
                    initialValue: _cashAccountId,
                    onChanged: (value) => setState(() => _cashAccountId = value),
                    validator: Validators.requiredSelection('Cash Account'),
                  ),
                  AppFormTextField(
                    labelText: 'Opening Datetime',
                    controller: _openingDatetimeController,
                    validator: Validators.required('Opening Datetime'),
                  ),
                  AppFormTextField(
                    labelText: 'Opening Balance',
                    controller: _openingBalanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: Validators.optionalNonNegativeNumber(
                      'Opening Balance',
                    ),
                  ),
                  AppFormTextField(
                    labelText: 'Remarks',
                    controller: _remarksController,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            AppActionButton(
              icon: Icons.play_circle_outline,
              label: 'Open Session',
              onPressed: _openSession,
              busy: _saving,
            ),
            if (_selectedSession != null) ...[
              const SizedBox(height: AppUiConstants.spacingLg),
              Divider(color: Theme.of(context).dividerColor),
              const SizedBox(height: AppUiConstants.spacingMd),
              Text(
                'Close Or Cancel Selected Session',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              Form(
                key: _closeFormKey,
                child: SettingsFormWrap(
                  children: [
                    AppFormTextField(
                      labelText: 'Closing Datetime',
                      controller: _closingDatetimeController,
                      validator: isOpen
                          ? Validators.required('Closing Datetime')
                          : null,
                    ),
                    AppFormTextField(
                      labelText: 'Expected Closing Balance',
                      controller: _expectedClosingController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: isOpen
                          ? Validators.optionalNonNegativeNumber(
                              'Expected Closing Balance',
                            )
                          : null,
                    ),
                    AppFormTextField(
                      labelText: 'Actual Closing Balance',
                      controller: _actualClosingController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: isOpen
                          ? Validators.optionalNonNegativeNumber(
                              'Actual Closing Balance',
                            )
                          : null,
                    ),
                    AppFormTextField(
                      labelText: 'Remarks',
                      controller: _closingRemarksController,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              Wrap(
                spacing: AppUiConstants.spacingSm,
                runSpacing: AppUiConstants.spacingSm,
                children: [
                  if (isOpen)
                    AppActionButton(
                      icon: Icons.stop_circle_outlined,
                      label: 'Close Session',
                      onPressed: _closeSession,
                      busy: _saving,
                    ),
                  if ((_selectedSession?.status ?? '') != 'closed')
                    AppActionButton(
                      icon: Icons.cancel_outlined,
                      label: 'Cancel Session',
                      onPressed: _cancelSession,
                      busy: _saving,
                      filled: false,
                    ),
                ],
              ),
            ],
          ],
        ),
    );
  }
}
