import '../../../screen.dart';

class BankReconciliationManagementPage extends StatefulWidget {
  const BankReconciliationManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<BankReconciliationManagementPage> createState() =>
      _BankReconciliationManagementPageState();
}

class _BankReconciliationManagementPageState
    extends State<BankReconciliationManagementPage> {
  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'pending', label: 'Pending'),
        AppDropdownItem(value: 'cleared', label: 'Cleared'),
        AppDropdownItem(value: 'bounced', label: 'Bounced'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  final AccountsService _accountsService = AccountsService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _bankDateController = TextEditingController();
  final TextEditingController _clearedDateController = TextEditingController();
  final TextEditingController _bankReferenceController =
      TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<BankReconciliationModel> _records = const <BankReconciliationModel>[];
  List<BankReconciliationModel> _filteredRecords =
      const <BankReconciliationModel>[];
  List<AccountModel> _bankAccounts = const <AccountModel>[];
  List<VoucherModel> _vouchers = const <VoucherModel>[];
  List<VoucherLineModel> _voucherLineOptions = const <VoucherLineModel>[];
  BankReconciliationModel? _selectedRecord;
  int? _accountId;
  int? _voucherId;
  int? _voucherLineId;
  String _status = 'pending';

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
    _bankDateController.dispose();
    _clearedDateController.dispose();
    _bankReferenceController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadPage({int? selectId}) async {
    setState(() {
      _initialLoading = _records.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait<dynamic>([
        _accountsService.bankReconciliation(),
        _accountsService.accountsAll(
          filters: const {
            'account_type': 'bank',
            'allow_reconciliation': 1,
            'is_active': 1,
            'sort_by': 'account_name',
          },
        ),
        _accountsService.vouchersAll(
          filters: const {'posting_status': 'posted', 'sort_by': 'voucher_date'},
        ),
      ]);

      final records =
          (responses[0] as ApiResponse<List<BankReconciliationModel>>).data ??
              const <BankReconciliationModel>[];
      final bankAccounts =
          (responses[1] as ApiResponse<List<AccountModel>>).data ??
              const <AccountModel>[];
      final vouchers = (responses[2] as ApiResponse<List<VoucherModel>>).data ??
          const <VoucherModel>[];

      if (!mounted) return;

      setState(() {
        _records = records;
        _filteredRecords = _filterRecords(records, _searchController.text);
        _bankAccounts = bankAccounts.where((item) => item.isActive).toList();
        _vouchers = vouchers;
        _initialLoading = false;
      });

      final selected = selectId != null
          ? records.cast<BankReconciliationModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedRecord == null
                ? (records.isNotEmpty ? records.first : null)
                : records.cast<BankReconciliationModel?>().firstWhere(
                    (item) => item?.id == _selectedRecord?.id,
                    orElse: () => records.isNotEmpty ? records.first : null,
                  ));

      if (selected != null) {
        _selectRecord(selected);
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

  List<BankReconciliationModel> _filterRecords(
    List<BankReconciliationModel> items,
    String query,
  ) {
    return filterMasterList(items, query, (item) {
      return [
        item.accountName ?? '',
        item.bankReferenceNo ?? '',
        item.voucherNo ?? '',
        item.reconciliationStatus ?? '',
      ];
    });
  }

  void _applySearch() {
    setState(() {
      _filteredRecords = _filterRecords(_records, _searchController.text);
    });
  }

  Future<void> _loadVoucherLinesForSelection() async {
    if (_voucherId == null || _accountId == null) {
      setState(() => _voucherLineOptions = const <VoucherLineModel>[]);
      return;
    }

    final response = await _accountsService.voucher(_voucherId!);
    final voucher = response.data;
    final usedLineIds = _records
        .where((item) => item.id != _selectedRecord?.id)
        .map((item) => item.voucherLineId)
        .whereType<int>()
        .toSet();

    final options = (voucher?.lines ?? const <VoucherLineModel>[])
        .where(
          (item) =>
              item.accountId == _accountId &&
              !usedLineIds.contains(item.id),
        )
        .toList(growable: false);

    if (!mounted) return;
    setState(() {
      _voucherLineOptions = options;
      if (!_voucherLineOptions.any((item) => item.id == _voucherLineId)) {
        _voucherLineId = null;
      }
    });
  }

  void _selectRecord(BankReconciliationModel item) {
    _selectedRecord = item;
    _accountId = item.accountId;
    _voucherId = null;
    _voucherLineId = item.voucherLineId;
    _status = item.reconciliationStatus ?? 'pending';
    _bankDateController.text = item.bankDate ?? '';
    _clearedDateController.text = item.clearedDate ?? '';
    _bankReferenceController.text = item.bankReferenceNo ?? '';
    _remarksController.text = item.remarks ?? '';
    _formError = null;
    _voucherLineOptions = const <VoucherLineModel>[];
    setState(() {});
  }

  void _resetForm() {
    _selectedRecord = null;
    _accountId = _bankAccounts.isNotEmpty ? _bankAccounts.first.id : null;
    _voucherId = null;
    _voucherLineId = null;
    _status = 'pending';
    _bankDateController.clear();
    _clearedDateController.clear();
    _bankReferenceController.clear();
    _remarksController.clear();
    _voucherLineOptions = const <VoucherLineModel>[];
    _formError = null;
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final model = BankReconciliationModel(
        id: _selectedRecord?.id,
        accountId: _accountId,
        voucherLineId: _voucherLineId,
        bankDate: nullIfEmpty(_bankDateController.text),
        clearedDate: nullIfEmpty(_clearedDateController.text),
        reconciliationStatus: _status,
        bankReferenceNo: nullIfEmpty(_bankReferenceController.text),
        remarks: nullIfEmpty(_remarksController.text),
      );

      final response = _selectedRecord == null
          ? await _accountsService.createBankReconciliation(model)
          : await _accountsService.updateBankReconciliation(
              _selectedRecord!.id!,
              model,
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
          _resetForm();
          if (!Responsive.isDesktop(context)) {
            _workspaceController.openEditor();
          }
        },
        icon: Icons.compare_arrows_outlined,
        label: 'New Reconciliation',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Bank Reconciliation',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading bank reconciliation...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load bank reconciliation',
        message: _pageError!,
        onRetry: _loadPage,
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Bank Reconciliation',
      editorTitle: _selectedRecord?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<BankReconciliationModel>(
        searchController: _searchController,
        searchHint: 'Search reconciliation records',
        items: _filteredRecords,
        selectedItem: _selectedRecord,
        emptyMessage: 'No reconciliation records found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.accountName ?? item.accountCode ?? '',
          subtitle: [
            item.voucherNo ?? '',
            item.reconciliationStatus ?? '',
            item.bankDate ?? '',
          ].where((value) => value.isNotEmpty).join(' · '),
          selected: selected,
          onTap: () => _selectRecord(item),
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
                    labelText: 'Bank Account',
                    mappedItems: _bankAccounts
                        .where((item) => item.id != null)
                        .map((item) => AppDropdownItem(value: item.id!, label: item.toString()))
                        .toList(growable: false),
                    initialValue: _accountId,
                    onChanged: (value) async {
                      setState(() {
                        _accountId = value;
                        _voucherLineId = null;
                      });
                      await _loadVoucherLinesForSelection();
                    },
                    validator: Validators.requiredSelection('Bank Account'),
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Voucher',
                    mappedItems: _vouchers
                        .where((item) => item.id != null)
                        .map((item) => AppDropdownItem(value: item.id!, label: item.toString()))
                        .toList(growable: false),
                    initialValue: _voucherId,
                    onChanged: (value) async {
                      setState(() {
                        _voucherId = value;
                        _voucherLineId = null;
                      });
                      await _loadVoucherLinesForSelection();
                    },
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Voucher Line',
                    mappedItems: _voucherLineOptions
                        .where((item) => item.id != null)
                        .map(
                          (item) => AppDropdownItem(
                            value: item.id!,
                            label:
                                '${item.entryType?.toUpperCase() ?? ''} · ${item.amount ?? 0} · ${item.accountName ?? item.accountCode ?? ''}',
                          ),
                        )
                        .toList(growable: false),
                    initialValue: _voucherLineId,
                    onChanged: (value) =>
                        setState(() => _voucherLineId = value),
                    validator: Validators.requiredSelection('Voucher Line'),
                  ),
                  AppDropdownField<String>.fromMapped(
                    labelText: 'Status',
                    mappedItems: _statusItems,
                    initialValue: _status,
                    onChanged: (value) =>
                        setState(() => _status = value ?? 'pending'),
                  ),
                  AppFormTextField(
                    labelText: 'Bank Date',
                    controller: _bankDateController,
                    validator: Validators.optionalDate('Bank Date'),
                  ),
                  AppFormTextField(
                    labelText: 'Cleared Date',
                    controller: _clearedDateController,
                    validator: Validators.optionalDate('Cleared Date'),
                  ),
                  AppFormTextField(
                    labelText: 'Bank Reference No',
                    controller: _bankReferenceController,
                    validator: Validators.optionalMaxLength(
                      100,
                      'Bank Reference No',
                    ),
                  ),
                  AppFormTextField(
                    labelText: 'Remarks',
                    controller: _remarksController,
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: AppUiConstants.spacingLg),
              AppActionButton(
                icon: Icons.save_outlined,
                label: _selectedRecord == null
                    ? 'Save Reconciliation'
                    : 'Update Reconciliation',
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
