import '../../../screen.dart';
import 'financial_report_views.dart';

class FinancialReportsPage extends StatefulWidget {
  const FinancialReportsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<FinancialReportsPage> createState() => _FinancialReportsPageState();
}

class _FinancialReportsPageState extends State<FinancialReportsPage> {
  static const List<AppDropdownItem<String>> _reportItems =
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
  final ScrollController _pageScrollController = ScrollController();
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  final TextEditingController _asOfDateController = TextEditingController();

  bool _initialLoading = true;
  bool _loading = false;
  String? _error;
  String _reportType = 'day_book';
  int? _companyId;
  int? _accountId;
  int? _partyId;
  int? _dayBookBranchId;
  List<AccountModel> _accounts = const <AccountModel>[];
  List<BranchModel> _branches = const <BranchModel>[];
  List<PartyModel> _parties = const <PartyModel>[];
  AccountingReportModel? _report;

  @override
  void initState() {
    super.initState();
    _asOfDateController.text = DateTime.now().toIso8601String().split('T').first;
    _dateFromController.text = DateTime.now().toIso8601String().split('T').first;
    _dateToController.text = DateTime.now().toIso8601String().split('T').first;
    _loadLookups();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();
    _asOfDateController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    setState(() {
      _initialLoading = true;
      _error = null;
    });

    try {
      final responses = await Future.wait<dynamic>([
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
        _accountsService.accountsAll(filters: const {'sort_by': 'account_name'}),
        _masterService.branches(
          filters: const {'per_page': 500, 'sort_by': 'name'},
        ),
        _partiesService.parties(
          filters: const {'per_page': 200, 'sort_by': 'party_name'},
        ),
      ]);

      final companies = (responses[0] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final accounts = (responses[1] as ApiResponse<List<AccountModel>>).data ??
          const <AccountModel>[];
      final branches = (responses[2] as PaginatedResponse<BranchModel>).data ??
          const <BranchModel>[];
      final parties = (responses[3] as PaginatedResponse<PartyModel>).data ??
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

      if (!mounted) return;
      setState(() {
        _accounts = accounts.where((item) => item.isActive).toList();
        _branches = branches.where((item) => item.isActive).toList();
        _parties = parties.where((item) => item.isActive).toList();
        _companyId = contextSelection.companyId;
        _initialLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _initialLoading = false;
      });
    }
  }

  Future<void> _runReport() async {
    if (_companyId == null) {
      setState(() => _error = 'Company is required.');
      return;
    }
    if (_reportType == 'general_ledger' && _accountId == null) {
      setState(() => _error = 'Account is required for general ledger.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final filters = <String, dynamic>{'company_id': _companyId};
    switch (_reportType) {
      case 'day_book':
        filters['date_from'] = _dateFromController.text.trim();
        filters['date_to'] = _dateToController.text.trim();
        if (_dayBookBranchId != null) {
          filters['branch_id'] = _dayBookBranchId;
        }
        break;
      case 'general_ledger':
        filters['account_id'] = _accountId;
        if (_partyId != null) filters['party_id'] = _partyId;
        filters['date_from'] = _dateFromController.text.trim();
        filters['date_to'] = _dateToController.text.trim();
        break;
      case 'accounts_receivable_aging':
      case 'accounts_payable_aging':
        if (_partyId != null) filters['party_id'] = _partyId;
        filters['as_of_date'] = _asOfDateController.text.trim();
        break;
      case 'trial_balance':
      case 'balance_sheet':
        filters['as_of_date'] = _asOfDateController.text.trim();
        break;
      case 'profit_and_loss':
      case 'cash_flow':
      case 'financial_statement_pack':
        filters['date_from'] = _dateFromController.text.trim();
        filters['date_to'] = _dateToController.text.trim();
        if (_reportType == 'financial_statement_pack') {
          filters['as_of_date'] = _asOfDateController.text.trim();
        }
        break;
    }

    try {
      final response = switch (_reportType) {
        'day_book' => await _accountsService.reportDayBook(filters: filters),
        'general_ledger' => await _accountsService.reportGeneralLedger(
            filters: filters,
          ),
        'accounts_receivable_aging' =>
          await _accountsService.reportAccountsReceivableAging(filters: filters),
        'accounts_payable_aging' =>
          await _accountsService.reportAccountsPayableAging(filters: filters),
        'trial_balance' =>
          await _accountsService.reportTrialBalance(filters: filters),
        'profit_and_loss' =>
          await _accountsService.reportProfitAndLoss(filters: filters),
        'balance_sheet' =>
          await _accountsService.reportBalanceSheet(filters: filters),
        'cash_flow' => await _accountsService.reportCashFlow(filters: filters),
        _ => await _accountsService.reportFinancialStatements(filters: filters),
      };

      if (!mounted) return;
      setState(() {
        _report = response.data;
      });
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _needsAccount => _reportType == 'general_ledger';
  bool get _needsParty =>
      _reportType == 'general_ledger' ||
      _reportType == 'accounts_receivable_aging' ||
      _reportType == 'accounts_payable_aging';
  bool get _needsDayBookBranch => _reportType == 'day_book';
  List<BranchModel> get _branchOptions => _branches
      .where(
        (b) =>
            b.isActive &&
            (_companyId == null || b.companyId == null || b.companyId == _companyId),
      )
      .toList(growable: false);
  bool get _usesDateRange =>
      _reportType == 'day_book' ||
      _reportType == 'general_ledger' ||
      _reportType == 'profit_and_loss' ||
      _reportType == 'cash_flow' ||
      _reportType == 'financial_statement_pack';
  bool get _usesAsOfDate =>
      _reportType == 'accounts_receivable_aging' ||
      _reportType == 'accounts_payable_aging' ||
      _reportType == 'trial_balance' ||
      _reportType == 'balance_sheet' ||
      _reportType == 'financial_statement_pack';

  Future<void> _openFilterPanel() async {
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Filter Financial Reports',
                          style: Theme.of(dialogContext).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        tooltip: 'Close',
                        icon: const Icon(Icons.close),
                        color: appTheme.mutedText,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFilterFields(dialogContext),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        icon: const Icon(Icons.play_arrow_outlined),
                        label: const Text('Run Report'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _reportType = 'day_book';
                            _accountId = null;
                            _partyId = null;
                            _dayBookBranchId = null;
                            final today = DateTime.now()
                                .toIso8601String()
                                .split('T')
                                .first;
                            _dateFromController.text = today;
                            _dateToController.text = today;
                            _asOfDateController.text = today;
                          });
                          Navigator.of(dialogContext).pop(true);
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (applied == true) {
      _runReport();
    }
  }

  Future<void> _copyReportTsv() async {
    if (_report == null) {
      return;
    }
    final text = FinancialReportViews.toTsv(_reportType, _report!.data);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report copied as tab-separated text')),
    );
  }

  List<Widget> _buildShellActions() {
    return [
      AdaptiveShellActionButton(
        onPressed: _loading ? null : _openFilterPanel,
        icon: Icons.filter_alt_outlined,
        label: 'Filter',
        filled: false,
      ),
      AdaptiveShellActionButton(
        onPressed: _loading || _report == null ? null : _copyReportTsv,
        icon: Icons.copy_outlined,
        label: 'Copy TSV',
        filled: false,
      ),
      AdaptiveShellActionButton(
        onPressed: _loading ? null : _runReport,
        icon: Icons.assessment_outlined,
        label: 'Run Report',
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
      title: 'Financial Reports',
      scrollController: _pageScrollController,
      actions: _buildShellActions(),
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading report lookups...');
    }
    if (_error != null && _report == null) {
      return AppErrorStateView(
        title: 'Unable to prepare reports',
        message: _error!,
        onRetry: _loadLookups,
      );
    }

    return SingleChildScrollView(
      controller: _pageScrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) ...[
            AppErrorStateView.inline(message: _error!),
            const SizedBox(height: AppUiConstants.spacingMd),
          ],
          AppSectionCard(
            child: _report == null
                ? const SettingsEmptyState(
                    icon: Icons.bar_chart_outlined,
                    title: 'Run a report',
                    message:
                        'Choose report filters above and run the report to see accounting output.',
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _reportItems
                                .firstWhere(
                                  (item) => item.value == _reportType,
                                  orElse: () => const AppDropdownItem(
                                    value: '',
                                    label: 'Report',
                                  ),
                                )
                                .label,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppUiConstants.spacingMd),
                      FinancialReportViews.buildBody(
                        context,
                        _reportType,
                        _report!.data,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterFields(BuildContext context) {
    return SettingsFormWrap(
      children: [
        AppDropdownField<String>.fromMapped(
          labelText: 'Report',
          mappedItems: _reportItems,
          initialValue: _reportType,
          onChanged: (value) => setState(
            () {
              _reportType = value ?? 'day_book';
              if (!_needsAccount) {
                _accountId = null;
              }
              if (!_needsParty) {
                _partyId = null;
              }
              if (!_needsDayBookBranch) {
                _dayBookBranchId = null;
              }
            },
          ),
        ),
        if (_needsDayBookBranch)
          AppDropdownField<int?>.fromMapped(
            labelText: 'Branch (optional)',
            mappedItems: <AppDropdownItem<int?>>[
              const AppDropdownItem<int?>(value: null, label: 'All branches'),
              ..._branchOptions
                  .where((b) => b.id != null)
                  .map(
                    (b) => AppDropdownItem<int?>(value: b.id, label: b.toString()),
                  ),
            ],
            initialValue: _dayBookBranchId,
            onChanged: (value) => setState(() => _dayBookBranchId = value),
          ),
        if (_needsAccount)
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
            initialValue: _accountId,
            onChanged: (value) => setState(() => _accountId = value),
          ),
        if (_needsParty)
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
            initialValue: _partyId,
            onChanged: (value) => setState(() => _partyId = value),
          ),
        if (_usesDateRange)
          AppFormTextField(
            labelText: 'Date From',
            controller: _dateFromController,
            validator: Validators.optionalDate('Date From'),
          ),
        if (_usesDateRange)
          AppFormTextField(
            labelText: 'Date To',
            controller: _dateToController,
            validator: Validators.optionalDate('Date To'),
          ),
        if (_usesAsOfDate)
          AppFormTextField(
            labelText: 'As Of Date',
            controller: _asOfDateController,
            validator: Validators.optionalDate('As Of Date'),
          ),
      ],
    );
  }
}
