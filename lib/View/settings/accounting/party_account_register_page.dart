import '../../../screen.dart';

class PartyAccountRegisterPage extends StatefulWidget {
  const PartyAccountRegisterPage({
    super.key,
    this.embedded = false,
    this.initialPartyId,
  });

  final bool embedded;
  final int? initialPartyId;

  @override
  State<PartyAccountRegisterPage> createState() =>
      _PartyAccountRegisterPageState();
}

class _PartyAccountRegisterPageState extends State<PartyAccountRegisterPage> {
  static const List<AppDropdownItem<String>> _accountPurposeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'primary', label: 'Primary'),
        AppDropdownItem(value: 'receivable', label: 'Receivable'),
        AppDropdownItem(value: 'payable', label: 'Payable'),
        AppDropdownItem(value: 'advance', label: 'Advance'),
        AppDropdownItem(value: 'salary', label: 'Salary'),
        AppDropdownItem(value: 'commission', label: 'Commission'),
        AppDropdownItem(value: 'other', label: 'Other'),
      ];
  static const List<AppDropdownItem<String?>> _accountPurposeFilterItems =
      <AppDropdownItem<String?>>[
        AppDropdownItem<String?>(value: null, label: 'All purposes'),
        AppDropdownItem<String?>(value: 'primary', label: 'Primary'),
        AppDropdownItem<String?>(value: 'receivable', label: 'Receivable'),
        AppDropdownItem<String?>(value: 'payable', label: 'Payable'),
        AppDropdownItem<String?>(value: 'advance', label: 'Advance'),
        AppDropdownItem<String?>(value: 'salary', label: 'Salary'),
        AppDropdownItem<String?>(value: 'commission', label: 'Commission'),
        AppDropdownItem<String?>(value: 'other', label: 'Other'),
      ];
  static const List<AppDropdownItem<bool?>> _activeFilterItems =
      <AppDropdownItem<bool?>>[
        AppDropdownItem<bool?>(value: null, label: 'All statuses'),
        AppDropdownItem<bool?>(value: true, label: 'Active'),
        AppDropdownItem<bool?>(value: false, label: 'Inactive'),
      ];

  final AccountsService _accountsService = AccountsService();
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final ScrollController _pageScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _initialLoading = true;
  bool _loading = false;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<PartyAccountModel> _rows = const <PartyAccountModel>[];
  PaginationMeta? _meta;
  int _page = 1;
  int _perPage = 20;

  List<CompanyModel> _companies = const <CompanyModel>[];
  List<PartyModel> _parties = const <PartyModel>[];
  List<AccountModel> _accounts = const <AccountModel>[];
  int? _companyId;
  String? _filterPurpose;
  bool? _filterActive;

  PartyAccountModel? _editing;
  int? _formPartyId;
  int? _formAccountId;
  String _formPurpose = 'primary';
  bool _formDefault = true;
  bool _formActive = true;

  bool _canCreate = false;
  bool _canUpdate = false;
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _formPartyId = widget.initialPartyId;
    _bootstrap();
  }

  @override
  void didUpdateWidget(covariant PartyAccountRegisterPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPartyId != widget.initialPartyId) {
      _formPartyId = widget.initialPartyId;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _searchController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadPermissions() async {
    final codes = await SessionStorage.getPermissionCodes();
    if (!mounted) {
      return;
    }
    setState(() {
      _canCreate = codes.contains('accounts.create');
      _canUpdate = codes.contains('accounts.update');
      _canDelete = codes.contains('accounts.delete');
    });
  }

  Future<void> _bootstrap() async {
    setState(() {
      _initialLoading = true;
      _pageError = null;
    });
    await _loadPermissions();
    try {
      final companiesResponse = await _masterService.companies(
        filters: const {'per_page': 200, 'sort_by': 'legal_name'},
      );
      final partiesResponse = await _partiesService.parties(
        filters: const {'per_page': 500, 'sort_by': 'party_name'},
      );
      final companies = (companiesResponse.data ?? const <CompanyModel>[])
          .where((CompanyModel c) => c.isActive)
          .toList(growable: false);
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: companies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _companies = companies;
        _companyId = contextSelection.companyId;
        _parties =
            partiesResponse.data
                ?.where((PartyModel p) => p.isActive)
                .toList(growable: false) ??
            const <PartyModel>[];
        _initialLoading = false;
      });
      await _loadAccountsForCompany();
      await _fetch(resetPage: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _initialLoading = false;
        _pageError = error.toString();
      });
    }
  }

  Future<void> _loadAccountsForCompany() async {
    final companyId = _companyId;
    if (companyId == null) {
      if (mounted) {
        setState(() => _accounts = const <AccountModel>[]);
      }
      return;
    }
    try {
      final response = await _accountsService.accountsAll(
        filters: <String, dynamic>{
          'company_id': companyId,
          'is_active': 1,
          'sort_by': 'account_name',
        },
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _accounts = (response.data ?? const <AccountModel>[])
            .where((AccountModel a) => a.id != null && a.isActive)
            .toList(growable: false);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _accounts = const <AccountModel>[]);
    }
  }

  Future<void> _fetch({bool resetPage = false}) async {
    if (resetPage) {
      _page = 1;
    }
    setState(() {
      _loading = true;
      _pageError = null;
    });
    try {
      final filters = <String, dynamic>{
        'page': _page,
        'per_page': _perPage,
        'sort_by': 'id',
        'sort_order': 'desc',
      };
      if (_companyId != null) {
        filters['company_id'] = _companyId;
      }
      if ((_filterPurpose ?? '').isNotEmpty) {
        filters['account_purpose'] = _filterPurpose;
      }
      if (_filterActive != null) {
        filters['is_active'] = _filterActive! ? 1 : 0;
      }
      final q = _searchController.text.trim();
      if (q.isNotEmpty) {
        filters['search'] = q;
      }
      final response = await _accountsService.partyAccountsRegister(
        filters: filters,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _rows = response.data ?? const <PartyAccountModel>[];
        _meta = response.meta;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _pageError = error.toString();
      });
    }
  }

  void _newMapping() {
    setState(() {
      _editing = null;
      _formError = null;
      _formPartyId = widget.initialPartyId ?? _formPartyId;
      _formAccountId = null;
      _formPurpose = 'primary';
      _formDefault = true;
      _formActive = true;
      _remarksController.clear();
    });
  }

  void _editRow(PartyAccountModel row) {
    setState(() {
      _editing = row;
      _formError = null;
      _formPartyId = row.partyId;
      _formAccountId = row.accountId;
      _formPurpose = row.accountPurpose ?? 'primary';
      _formDefault = row.isDefault;
      _formActive = row.isActive;
      _remarksController.text = row.remarks ?? '';
    });
  }

  Future<void> _save() async {
    if (!_canCreate && _editing == null) {
      return;
    }
    if (!_canUpdate && _editing != null) {
      return;
    }
    if (_companyId == null) {
      setState(() => _formError = 'Select a company before saving.');
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final partyId = _formPartyId;
    if (partyId == null) {
      setState(() => _formError = 'Party is required.');
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final model = PartyAccountModel(
        id: _editing?.id,
        partyId: partyId,
        accountId: _formAccountId,
        accountPurpose: _formPurpose,
        isDefault: _formDefault,
        isActive: _formActive,
        remarks: nullIfEmpty(_remarksController.text),
      );

      final ApiResponse<PartyAccountModel> response = _editing == null
          ? await _accountsService.createPartyAccount(model)
          : await _accountsService.updatePartyAccount(_editing!.id!, model);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _fetch(resetPage: true);
      _newMapping();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final id = _editing?.id;
    if (id == null || !_canDelete) {
      return;
    }
    setState(() {
      _saving = true;
      _formError = null;
    });
    try {
      final response = await _accountsService.deletePartyAccount(id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _fetch(resetPage: true);
      _newMapping();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  PaginationMeta get _effectiveMeta =>
      _meta ??
      PaginationMeta(
        currentPage: _page,
        lastPage: 1,
        perPage: _perPage,
        total: _rows.length,
      );

  List<Widget> _buildShellActions() {
    return [
      AdaptiveShellActionButton(
        onPressed: _loading ? null : _openFilterPanel,
        icon: Icons.filter_alt_outlined,
        label: 'Filter',
        filled: false,
      ),
      AdaptiveShellActionButton(
        onPressed: _saving ? null : _newMapping,
        icon: Icons.add_outlined,
        label: 'New mapping',
        filled: false,
      ),
      AdaptiveShellActionButton(
        onPressed: _loading ? null : () => _fetch(resetPage: true),
        icon: Icons.refresh_outlined,
        label: 'Refresh',
        filled: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (widget.embedded) {
      return ShellPageActions(actions: _buildShellActions(), child: content);
    }
    return AppStandaloneShell(
      title: 'Party account register',
      scrollController: _pageScrollController,
      actions: _buildShellActions(),
      child: content,
    );
  }

  Future<void> _openFilterPanel() async {
    final companyItems = <AppDropdownItem<int?>>[
      const AppDropdownItem<int?>(value: null, label: 'All companies'),
      ..._companies.map(
        (CompanyModel c) => AppDropdownItem<int?>(
          value: c.id,
          label: c.toString(),
        ),
      ),
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 600 ? 12.0 : 24.0;
    final dialogPadding = screenWidth < 600 ? 16.0 : AppUiConstants.cardPadding;

    final applied = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final appTheme = Theme.of(
          dialogContext,
        ).extension<AppThemeExtension>()!;

        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                dialogPadding,
                dialogPadding,
                dialogPadding,
                MediaQuery.of(dialogContext).viewInsets.bottom + dialogPadding,
              ),
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Filter Party Accounts',
                              style: Theme.of(dialogContext).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            tooltip: 'Close',
                            icon: const Icon(Icons.close),
                            color: appTheme.mutedText,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _filterBox(
                            child: AppDropdownField<int?>.fromMapped(
                              labelText: 'Company',
                              mappedItems: companyItems,
                              initialValue: _companyId,
                              onChanged: (value) {
                                setDialogState(() {
                                  _companyId = value;
                                });
                              },
                            ),
                          ),
                          _filterBox(
                            child: AppFormTextField(
                              controller: _searchController,
                              labelText: 'Search',
                              hintText: 'Party or account',
                            ),
                          ),
                          _filterBox(
                            child: AppDropdownField<String?>.fromMapped(
                              labelText: 'Purpose',
                              mappedItems: _accountPurposeFilterItems,
                              initialValue: _filterPurpose,
                              onChanged: (value) => setDialogState(
                                () => _filterPurpose = value,
                              ),
                            ),
                          ),
                          _filterBox(
                            child: AppDropdownField<bool?>.fromMapped(
                              labelText: 'Active',
                              mappedItems: _activeFilterItems,
                              initialValue: _filterActive,
                              onChanged: (value) => setDialogState(
                                () => _filterActive = value,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            icon: const Icon(Icons.search),
                            label: const Text('Apply Filters'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _filterPurpose = null;
                                _filterActive = null;
                              });
                              Navigator.of(dialogContext).pop(true);
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    if (applied == true) {
      await _loadAccountsForCompany();
      await _fetch(resetPage: true);
    }
  }

  Widget _buildContent(BuildContext context) {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading party accounts...');
    }
    if (_pageError != null && _rows.isEmpty) {
      return AppErrorStateView(
        title: 'Unable to load party accounts',
        message: _pageError!,
        onRetry: _bootstrap,
      );
    }

    final partyItems = _parties
        .where((PartyModel p) => p.id != null)
        .map(
          (PartyModel p) => AppDropdownItem<int>(
            value: p.id!,
            label: [
              p.displayName ?? p.partyName ?? '',
              if ((p.partyCode ?? '').isNotEmpty) p.partyCode!,
            ].where((String s) => s.isNotEmpty).join(' · '),
          ),
        )
        .toList(growable: false);

    final accountItems = _accounts
        .map(
          (AccountModel item) => AppDropdownItem<int>(
            value: item.id!,
            label: [
              item.accountName ?? '',
              if ((item.accountCode ?? '').isNotEmpty) item.accountCode!,
            ].where((String s) => s.isNotEmpty).join(' · '),
          ),
        )
        .toList(growable: false);

    final canEdit =
        (_editing == null && _canCreate) ||
        (_editing != null && _canUpdate);

    return SingleChildScrollView(
      controller: _pageScrollController,
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_pageError != null) ...[
            AppErrorStateView.inline(message: _pageError!),
            const SizedBox(height: AppUiConstants.spacingMd),
          ],
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editing == null ? 'New mapping' : 'Edit mapping',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppUiConstants.spacingSm),
                Text(
                  'Choose a company in filters so the correct ledgers appear. '
                  'Mappings are saved against the selected party and account.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_formError != null) ...[
                  const SizedBox(height: AppUiConstants.spacingMd),
                  AppErrorStateView.inline(message: _formError!),
                ],
                const SizedBox(height: AppUiConstants.spacingMd),
                if (_companyId == null)
                  const Text(
                    'Select a company to enable account selection and saving.',
                  )
                else if (!canEdit)
                  const Text('You do not have permission to change mappings.')
                else
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SettingsFormWrap(
                          children: [
                            AppDropdownField<int>.fromMapped(
                              labelText: 'Party',
                              mappedItems: partyItems,
                              initialValue: _formPartyId,
                              onChanged: (value) =>
                                  setState(() => _formPartyId = value),
                              validator: Validators.requiredSelection('Party'),
                            ),
                            AppDropdownField<int>.fromMapped(
                              labelText: 'Account',
                              mappedItems: accountItems,
                              initialValue: _formAccountId,
                              onChanged: (value) =>
                                  setState(() => _formAccountId = value),
                              validator: Validators.requiredSelection('Account'),
                            ),
                            AppDropdownField<String>.fromMapped(
                              labelText: 'Purpose',
                              mappedItems: _accountPurposeItems,
                              initialValue: _formPurpose,
                              onChanged: (value) => setState(
                                () => _formPurpose = value ?? 'primary',
                              ),
                              validator: Validators.requiredSelection('Purpose'),
                            ),
                            AppFormTextField(
                              labelText: 'Remarks',
                              controller: _remarksController,
                              maxLines: 3,
                              validator: Validators.optionalMaxLength(
                                1000,
                                'Remarks',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppUiConstants.spacingMd),
                        Wrap(
                          spacing: AppUiConstants.spacingMd,
                          runSpacing: AppUiConstants.spacingSm,
                          children: [
                            AppSwitchTile(
                              label: 'Default for purpose',
                              value: _formDefault,
                              onChanged: (bool value) =>
                                  setState(() => _formDefault = value),
                            ),
                            AppSwitchTile(
                              label: 'Active',
                              value: _formActive,
                              onChanged: (bool value) =>
                                  setState(() => _formActive = value),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppUiConstants.spacingLg),
                        Row(
                          children: [
                            if (_editing?.id != null && _canDelete)
                              TextButton(
                                onPressed: _saving ? null : _delete,
                                child: const Text('Delete'),
                              ),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed:
                                  (_saving || !canEdit) ? null : _save,
                              icon: const Icon(Icons.save_outlined),
                              label: Text(_saving ? 'Saving…' : 'Save'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          ReportPaginationBar(
            meta: _effectiveMeta,
            onPerPageChanged: (int value) {
              setState(() => _perPage = value);
              _fetch(resetPage: true);
            },
            onPageChanged: (int value) {
              setState(() => _page = value);
              _fetch();
            },
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          AppSectionCard(
            child: _loading && _rows.isEmpty
                ? const AppLoadingView(message: 'Loading...')
                : _rows.isEmpty
                ? const SettingsEmptyState(
                    icon: Icons.link_outlined,
                    title: 'No mappings',
                    message:
                        'No rows match the filters. Add a mapping with the form above.',
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: DataTable(
                            headingRowHeight: 40,
                            dataRowMinHeight: 40,
                            dataRowMaxHeight: 56,
                            columns: const [
                              DataColumn(label: Text('Party')),
                              DataColumn(label: Text('Account')),
                              DataColumn(label: Text('Purpose')),
                              DataColumn(label: Text('Default')),
                              DataColumn(label: Text('Active')),
                              DataColumn(label: Text('')),
                            ],
                            rows: _rows.map((PartyAccountModel row) {
                              final partyLabel =
                                  row.partyName?.isNotEmpty == true
                                  ? row.partyName!
                                  : (row.partyCode ?? '—');
                              final accountLabel =
                                  row.accountName?.isNotEmpty == true
                                  ? row.accountName!
                                  : (row.accountCode ?? '—');
                              final selected = _editing?.id == row.id;
                              return DataRow(
                                selected: selected,
                                cells: [
                                  DataCell(Text(partyLabel)),
                                  DataCell(Text(accountLabel)),
                                  DataCell(Text(row.accountPurpose ?? '—')),
                                  DataCell(Text(row.isDefault ? 'Yes' : 'No')),
                                  DataCell(Text(row.isActive ? 'Yes' : 'No')),
                                  DataCell(
                                    IconButton(
                                      tooltip: 'Edit',
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => _editRow(row),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(growable: false),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterBox({required Widget child}) {
    return SizedBox(width: 240, child: child);
  }
}
