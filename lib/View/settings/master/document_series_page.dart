import '../../../screen.dart';

class DocumentSeriesManagementPage extends StatefulWidget {
  const DocumentSeriesManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<DocumentSeriesManagementPage> createState() =>
      _DocumentSeriesManagementPageState();
}

class _DocumentSeriesManagementPageState
    extends State<DocumentSeriesManagementPage> {
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _documentTypeController = TextEditingController();
  final TextEditingController _prefixController = TextEditingController();
  final TextEditingController _suffixController = TextEditingController();
  final TextEditingController _nextNumberController = TextEditingController();
  final TextEditingController _numberLengthController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<DocumentSeriesModel> _series = const <DocumentSeriesModel>[];
  List<DocumentSeriesModel> _filteredSeries = const <DocumentSeriesModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  DocumentSeriesModel? _selectedSeries;
  int? _contextCompanyId;
  int? _contextFinancialYearId;
  int? _companyId;
  int? _financialYearId;
  bool _isDefault = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadData();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _documentTypeController.dispose();
    _prefixController.dispose();
    _suffixController.dispose();
    _nextNumberController.dispose();
    _numberLengthController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadData({int? selectId}) async {
    setState(() {
      _initialLoading = _series.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait<dynamic>([
        _masterService.documentSeries(
          filters: const {'per_page': 200, 'sort_by': 'series_name'},
        ),
        _masterService.companies(filters: const {'per_page': 200}),
        _masterService.financialYears(filters: const {'per_page': 200}),
      ]);
      final items =
          (responses[0] as PaginatedResponse<DocumentSeriesModel>).data ??
          const <DocumentSeriesModel>[];
      final companies =
          (responses[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final financialYears =
          (responses[2] as PaginatedResponse<FinancialYearModel>).data ??
          const <FinancialYearModel>[];
      final activeCompanies = companies
          .where((item) => item.isActive)
          .toList(growable: false);
      final activeFinancialYears = financialYears
          .where((item) => item.isActive)
          .toList(growable: false);
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: activeFinancialYears,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _series = items;
        _companies = activeCompanies;
        _contextCompanyId = contextSelection.companyId;
        _contextFinancialYearId = contextSelection.financialYearId;
        _filteredSeries = _filterSeries(items);
        _initialLoading = false;
      });

      final visibleSeries = _filterSeries(items);
      final selected = selectId != null
          ? visibleSeries.cast<DocumentSeriesModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedSeries == null
                ? (visibleSeries.isNotEmpty ? visibleSeries.first : null)
                : visibleSeries.cast<DocumentSeriesModel?>().firstWhere(
                    (item) => item?.id == _selectedSeries?.id,
                    orElse: () =>
                        visibleSeries.isNotEmpty ? visibleSeries.first : null,
                  ));

      if (selected != null) {
        _selectSeries(selected);
      } else {
        _resetForm();
      }
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

  void _applySearch() {
    setState(() {
      _filteredSeries = _filterSeries(_series);
    });
  }

  List<DocumentSeriesModel> _filterSeries(List<DocumentSeriesModel> items) {
    final scoped = items
        .where(
          (series) =>
              (_contextCompanyId == null || series.companyId == _contextCompanyId) &&
              (_contextFinancialYearId == null ||
                  series.financialYearId == _contextFinancialYearId),
        )
        .toList(growable: false);

    return filterMasterList(scoped, _searchController.text, (series) {
      return [
        series.seriesCode ?? '',
        series.seriesName ?? '',
        series.documentType ?? '',
      ];
    });
  }

  void _selectSeries(DocumentSeriesModel series) {
    _selectedSeries = series;
    _companyId = series.companyId;
    _financialYearId = series.financialYearId;
    _codeController.text = series.seriesCode ?? '';
    _nameController.text = series.seriesName ?? '';
    _documentTypeController.text = series.documentType ?? '';
    _prefixController.text = series.prefix ?? '';
    _suffixController.text = series.suffix ?? '';
    _nextNumberController.text = series.nextNumber?.toString() ?? '';
    _numberLengthController.text = series.numberLength?.toString() ?? '';
    _remarksController.text = series.remarks ?? '';
    _isDefault = series.isDefault;
    _isActive = series.isActive;
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedSeries = null;
    _companyId = _contextCompanyId;
    _financialYearId = _contextFinancialYearId;
    _codeController.clear();
    _nameController.clear();
    _documentTypeController.clear();
    _prefixController.clear();
    _suffixController.clear();
    _nextNumberController.text = '1';
    _numberLengthController.text = '6';
    _remarksController.clear();
    _isDefault = false;
    _isActive = true;
    _formError = null;
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final model = DocumentSeriesModel(
      id: _selectedSeries?.id,
      companyId: _companyId,
      financialYearId: _financialYearId,
      seriesCode: _codeController.text.trim(),
      seriesName: _nameController.text.trim(),
      documentType: _documentTypeController.text.trim(),
      prefix: nullIfEmpty(_prefixController.text),
      suffix: nullIfEmpty(_suffixController.text),
      nextNumber: int.tryParse(_nextNumberController.text.trim()),
      numberLength: int.tryParse(_numberLengthController.text.trim()),
      isDefault: _isDefault,
      isActive: _isActive,
      remarks: nullIfEmpty(_remarksController.text),
    );

    try {
      final response = _selectedSeries == null
          ? await _masterService.store(
              '/masters/document-series',
              model.toJson(),
            )
          : await _masterService.update(
              '/masters/document-series/${_selectedSeries!.id}',
              model.toJson(),
            );
      final savedId = response.data?.id;
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData(selectId: savedId);
    } catch (error) {
      setState(() {
        _formError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _startNew() {
    _resetForm();
    if (!Responsive.isDesktop(context)) {
      _workspaceController.openEditor();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _startNew,
        icon: Icons.confirmation_number_outlined,
        label: 'New Series',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Document Series',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading document series...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load document series',
        message: _pageError!,
        onRetry: _loadData,
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Document Series',
      editorTitle: _selectedSeries?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<DocumentSeriesModel>(
        searchController: _searchController,
        searchHint: 'Search document series',
        items: _filteredSeries,
        selectedItem: _selectedSeries,
        emptyMessage: 'No document series found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.seriesName ?? '',
          subtitle: [
            item.seriesCode ?? '',
            item.documentType ?? '',
            companyNameById(_companies, item.companyId),
          ].where((part) => part.trim().isNotEmpty).join(' · '),
          selected: selected,
          onTap: () => _selectSeries(item),
        ),
      ),
      editor: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_formError != null) ...[
                Text(
                  _formError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Series Code'),
                validator: Validators.compose([
                  Validators.required('Series Code'),
                  Validators.optionalMaxLength(50, 'Series Code'),
                ]),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Series Name'),
                validator: Validators.compose([
                  Validators.required('Series Name'),
                  Validators.optionalMaxLength(100, 'Series Name'),
                ]),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _documentTypeController,
                decoration: const InputDecoration(labelText: 'Document Type'),
                validator: Validators.compose([
                  Validators.required('Document Type'),
                  Validators.optionalMaxLength(50, 'Document Type'),
                ]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _prefixController,
                      decoration: const InputDecoration(labelText: 'Prefix'),
                      validator: Validators.optionalMaxLength(20, 'Prefix'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _suffixController,
                      decoration: const InputDecoration(labelText: 'Suffix'),
                      validator: Validators.optionalMaxLength(20, 'Suffix'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nextNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Next Number',
                      ),
                      keyboardType: TextInputType.number,
                      validator: Validators.optionalNonNegativeInteger(
                        'Next Number',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _numberLengthController,
                      decoration: const InputDecoration(
                        labelText: 'Number Length',
                      ),
                      keyboardType: TextInputType.number,
                      validator: Validators.optionalNonNegativeInteger(
                        'Number Length',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Default Series'),
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving...' : 'Save'),
                ),
              ),
            ],
          ),
        ),
    );
  }
}
