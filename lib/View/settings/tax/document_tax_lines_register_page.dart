import '../../../screen.dart';

class DocumentTaxLinesRegisterPage extends StatefulWidget {
  const DocumentTaxLinesRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<DocumentTaxLinesRegisterPage> createState() =>
      _DocumentTaxLinesRegisterPageState();
}

class _DocumentTaxLinesRegisterPageState
    extends State<DocumentTaxLinesRegisterPage> {
  final TaxesService _taxesService = TaxesService();
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _initialLoading = true;
  bool _loading = false;
  String? _pageError;
  List<DocumentTaxLineModel> _rows = const <DocumentTaxLineModel>[];
  PaginationMeta? _meta;
  int _page = 1;
  int _perPage = 20;

  List<CompanyModel> _companies = const <CompanyModel>[];
  List<BranchModel> _branches = const <BranchModel>[];
  List<FinancialYearModel> _financialYears = const <FinancialYearModel>[];
  int? _companyId;
  int? _branchId;
  int? _financialYearId;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().toIso8601String().split('T').first;
    _dateFromController.text = today;
    _dateToController.text = today;
    _bootstrap();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<BranchModel> get _branchOptions => _branches
      .where(
        (BranchModel b) =>
            b.isActive &&
            (_companyId == null ||
                b.companyId == null ||
                b.companyId == _companyId),
      )
      .toList(growable: false);

  List<FinancialYearModel> get _financialYearOptions => _financialYears
      .where(
        (FinancialYearModel y) =>
            _companyId == null ||
            y.companyId == null ||
            y.companyId == _companyId,
      )
      .toList(growable: false);

  Future<void> _bootstrap() async {
    setState(() {
      _initialLoading = true;
      _pageError = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _masterService.companies(
          filters: const {'per_page': 200, 'sort_by': 'legal_name'},
        ),
        _masterService.branches(
          filters: const {'per_page': 500, 'sort_by': 'name'},
        ),
        _masterService.financialYears(
          filters: const {'per_page': 200, 'sort_by': 'start_date'},
        ),
      ]);

      final companies =
          (results[0] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final branches =
          (results[1] as PaginatedResponse<BranchModel>).data ??
          const <BranchModel>[];
      final years =
          (results[2] as PaginatedResponse<FinancialYearModel>).data ??
          const <FinancialYearModel>[];

      final activeCompanies = companies
          .where((CompanyModel c) => c.isActive)
          .toList(growable: false);
      final activeBranches = branches
          .where((BranchModel b) => b.isActive)
          .toList(growable: false);
      final activeYears = years
          .where((FinancialYearModel y) => y.isActive != false)
          .toList(growable: false);

      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: activeBranches,
            locations: const <BusinessLocationModel>[],
            financialYears: activeYears,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _companies = activeCompanies;
        _branches = activeBranches;
        _financialYears = activeYears;
        _companyId = contextSelection.companyId;
        _branchId = contextSelection.branchId;
        _financialYearId = contextSelection.financialYearId;
        _initialLoading = false;
      });
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

  Future<void> _fetch({bool resetPage = false}) async {
    if (_companyId == null) {
      setState(() {
        _pageError = 'Company is required.';
      });
      return;
    }
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
        'company_id': _companyId,
        'sort_by': 'document_date',
        'sort_order': 'desc',
      };
      if (_branchId != null) {
        filters['branch_id'] = _branchId;
      }
      if (_financialYearId != null) {
        filters['financial_year_id'] = _financialYearId;
      }
      final from = _dateFromController.text.trim();
      final to = _dateToController.text.trim();
      if (from.length == 10) {
        filters['document_date_from'] = from;
      }
      if (to.length == 10) {
        filters['document_date_to'] = to;
      }
      final q = _searchController.text.trim();
      if (q.isNotEmpty) {
        filters['search'] = q;
      }

      final response = await _taxesService.documentTaxLines(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _rows = response.data ?? const <DocumentTaxLineModel>[];
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

  PaginationMeta get _effectiveMeta =>
      _meta ??
      PaginationMeta(
        currentPage: _page,
        lastPage: 1,
        perPage: _perPage,
        total: _rows.length,
      );

  String _cell(DocumentTaxLineModel row, String key) {
    final dynamic v = row.data[key];
    if (v == null) {
      return '';
    }
    return v.toString();
  }

  String _itemLabel(DocumentTaxLineModel row) {
    final dynamic item = row.data['item'];
    if (item is Map<String, dynamic>) {
      return item['item_name']?.toString() ??
          item['item_code']?.toString() ??
          '';
    }
    return '';
  }

  String _taxLabel(DocumentTaxLineModel row) {
    final dynamic tax = row.data['tax_code'];
    if (tax is Map<String, dynamic>) {
      return tax['tax_name']?.toString() ?? tax['tax_code']?.toString() ?? '';
    }
    return '';
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
        onPressed: _loading ? null : () => _fetch(resetPage: true),
        icon: Icons.refresh_outlined,
        label: 'Refresh',
      ),
    ];
  }

  Future<void> _openFilterPanel() async {
    final companyItems = _companies
        .map(
          (CompanyModel c) =>
              AppDropdownItem<int?>(value: c.id, label: c.toString()),
        )
        .toList(growable: false);

    final branchItems = <AppDropdownItem<int?>>[
      const AppDropdownItem<int?>(value: null, label: 'All branches'),
      ..._branchOptions.map(
        (BranchModel b) =>
            AppDropdownItem<int?>(value: b.id, label: b.name ?? 'Branch'),
      ),
    ];

    final fyItems = <AppDropdownItem<int?>>[
      const AppDropdownItem<int?>(value: null, label: 'All financial years'),
      ..._financialYearOptions.map(
        (FinancialYearModel y) => AppDropdownItem<int?>(
          value: y.id,
          label: y.fyName?.isNotEmpty == true ? y.fyName! : (y.fyCode ?? 'FY'),
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
                              'Filter Document Tax Lines',
                              style: Theme.of(dialogContext)
                                  .textTheme
                                  .titleLarge
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
                              labelText: 'Financial year',
                              mappedItems: fyItems,
                              initialValue: _financialYearId,
                              onChanged: (value) => setDialogState(
                                () => _financialYearId = value,
                              ),
                            ),
                          ),
                          _filterBox(
                            child: AppFormTextField(
                              controller: _dateFromController,
                              labelText: 'From',
                              hintText: 'YYYY-MM-DD',
                              keyboardType: TextInputType.datetime,
                              inputFormatters: const [DateInputFormatter()],
                            ),
                          ),
                          _filterBox(
                            child: AppFormTextField(
                              controller: _dateToController,
                              labelText: 'To',
                              hintText: 'YYYY-MM-DD',
                              keyboardType: TextInputType.datetime,
                              inputFormatters: const [DateInputFormatter()],
                            ),
                          ),
                          _filterBox(
                            child: AppFormTextField(
                              controller: _searchController,
                              labelText: 'Search',
                              hintText: 'Document no. / HSN',
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
                                _branchId = null;
                                _financialYearId = null;
                                _dateFromController.clear();
                                _dateToController.clear();
                                _searchController.clear();
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
      _fetch(resetPage: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (widget.embedded) {
      return ShellPageActions(actions: _buildShellActions(), child: content);
    }
    return AppStandaloneShell(
      title: 'Document tax lines',
      scrollController: _pageScrollController,
      actions: _buildShellActions(),
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading tax lines...');
    }
    if (_pageError != null && _rows.isEmpty && !_loading) {
      return AppErrorStateView(
        title: 'Unable to load document tax lines',
        message: _pageError!,
        onRetry: _bootstrap,
      );
    }

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
          ReportPaginationBar(
            meta: _effectiveMeta,
            onPerPageChanged: (value) {
              setState(() => _perPage = value);
              _fetch(resetPage: true);
            },
            onPageChanged: (value) {
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
                    icon: Icons.receipt_long_outlined,
                    title: 'No tax lines',
                    message:
                        'No document tax lines match the filters for this company.',
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
                            dataRowMaxHeight: 64,
                            columns: const [
                              DataColumn(label: Text('Date')),
                              DataColumn(label: Text('Document')),
                              DataColumn(label: Text('Module')),
                              DataColumn(label: Text('Taxable')),
                              DataColumn(label: Text('CGST')),
                              DataColumn(label: Text('SGST')),
                              DataColumn(label: Text('IGST')),
                              DataColumn(label: Text('CESS')),
                              DataColumn(label: Text('Item')),
                              DataColumn(label: Text('Tax code')),
                            ],
                            rows: _rows
                                .map((DocumentTaxLineModel row) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(_cell(row, 'document_date')),
                                      ),
                                      DataCell(Text(_cell(row, 'document_no'))),
                                      DataCell(
                                        Text(_cell(row, 'document_module')),
                                      ),
                                      DataCell(
                                        Text(_cell(row, 'taxable_amount')),
                                      ),
                                      DataCell(Text(_cell(row, 'cgst_amount'))),
                                      DataCell(Text(_cell(row, 'sgst_amount'))),
                                      DataCell(Text(_cell(row, 'igst_amount'))),
                                      DataCell(Text(_cell(row, 'cess_amount'))),
                                      DataCell(Text(_itemLabel(row))),
                                      DataCell(Text(_taxLabel(row))),
                                    ],
                                  );
                                })
                                .toList(growable: false),
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
