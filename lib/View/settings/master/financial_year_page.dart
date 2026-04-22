import '../../../screen.dart';

class FinancialYearManagementPage extends StatefulWidget {
  const FinancialYearManagementPage({
    super.key,
    this.embedded = false,
    this.fixedCompanyId,
  });

  final bool embedded;
  final int? fixedCompanyId;

  @override
  State<FinancialYearManagementPage> createState() =>
      _FinancialYearManagementPageState();
}

class _FinancialYearManagementPageState
    extends State<FinancialYearManagementPage> {
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _fyCodeController = TextEditingController();
  final TextEditingController _fyNameController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _lockDateController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  bool _activating = false;
  bool _showDraftTile = false;
  String? _pageError;
  String? _formError;
  List<FinancialYearModel> _financialYears = const <FinancialYearModel>[];
  List<FinancialYearModel> _filteredFinancialYears =
      const <FinancialYearModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  FinancialYearModel? _selectedFinancialYear;
  int? _companyId;
  bool _isCurrent = false;
  bool _isLocked = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _startDateController.addListener(_syncGeneratedNames);
    _endDateController.addListener(_syncGeneratedNames);
    _loadData();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _fyCodeController.dispose();
    _fyNameController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _lockDateController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FinancialYearManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fixedCompanyId != widget.fixedCompanyId) {
      _selectedFinancialYear = null;
      _loadData();
    }
  }

  Future<void> _loadData({int? selectId}) async {
    setState(() {
      _initialLoading = _financialYears.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait([
        _masterService.financialYears(
          filters: {
            'per_page': 200,
            'sort_by': 'start_date',
            'sort_order': 'desc',
          },
        ),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
      ]);

      final financialYears =
          (responses[0].data as List<FinancialYearModel>?) ??
          const <FinancialYearModel>[];
      final companies =
          (responses[1].data as List<CompanyModel>?) ?? const <CompanyModel>[];
      if (!mounted) {
        return;
      }

      setState(() {
        _financialYears = financialYears;
        _companies = companies;
        _filteredFinancialYears = _filteredItems(financialYears);
        _initialLoading = false;
      });

      final selected = selectId != null
          ? financialYears.cast<FinancialYearModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedFinancialYear == null
                ? (_filteredFinancialYears.isNotEmpty
                      ? _filteredFinancialYears.first
                      : null)
                : financialYears.cast<FinancialYearModel?>().firstWhere(
                    (item) => item?.id == _selectedFinancialYear?.id,
                    orElse: () => _filteredFinancialYears.isNotEmpty
                        ? _filteredFinancialYears.first
                        : null,
                  ));

      if (selected != null) {
        _selectFinancialYear(selected);
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

  List<FinancialYearModel> _filteredItems(List<FinancialYearModel> source) {
    final scoped = widget.fixedCompanyId == null
        ? source
        : source
              .where((item) => item.companyId == widget.fixedCompanyId)
              .toList(growable: false);

    if (widget.embedded && widget.fixedCompanyId != null) {
      return scoped;
    }

    return filterMasterList(scoped, _searchController.text, (item) {
      return [
        item.fyCode ?? '',
        item.fyName ?? '',
        item.companyName ?? companyNameById(_companies, item.companyId),
      ];
    });
  }

  void _applySearch() {
    if (widget.embedded && widget.fixedCompanyId != null) {
      return;
    }

    setState(() {
      _filteredFinancialYears = _filteredItems(_financialYears);
    });
  }

  void _syncGeneratedNames() {
    final start = _startDateController.text.trim();
    final end = _endDateController.text.trim();
    if (start.length != 10 || end.length != 10) {
      return;
    }

    final startYear = int.tryParse(start.substring(0, 4));
    final endYear = int.tryParse(end.substring(0, 4));
    if (startYear == null || endYear == null) {
      return;
    }

    final fyCode =
        'FY${startYear.toString().substring(2)}-${endYear.toString().substring(2)}';
    final fyName = '$startYear-$endYear';

    _fyCodeController.value = _fyCodeController.value.copyWith(
      text: fyCode,
      selection: TextSelection.collapsed(offset: fyCode.length),
    );
    _fyNameController.value = _fyNameController.value.copyWith(
      text: fyName,
      selection: TextSelection.collapsed(offset: fyName.length),
    );

    if (_isLocked && _lockDateController.text.trim().isEmpty) {
      _lockDateController.text = end;
    }
  }

  void _selectFinancialYear(FinancialYearModel item) {
    _selectedFinancialYear = item;
    _showDraftTile = false;
    _companyId = widget.fixedCompanyId ?? item.companyId;
    _fyCodeController.text = item.fyCode ?? '';
    _fyNameController.text = item.fyName ?? '';
    _startDateController.text = item.startDate ?? '';
    _endDateController.text = item.endDate ?? '';
    _lockDateController.text = item.lockDate ?? '';
    _remarksController.text = item.remarks ?? '';
    _isCurrent = item.isCurrent;
    _isLocked = item.isLocked;
    _isActive = item.isActive;
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedFinancialYear = null;
    _companyId =
        widget.fixedCompanyId ??
        (_companies.isNotEmpty ? _companies.first.id : null);
    _fyCodeController.clear();
    _fyNameController.clear();
    _startDateController.clear();
    _endDateController.clear();
    _lockDateController.clear();
    _remarksController.clear();
    _isCurrent = false;
    _isLocked = false;
    _isActive = true;
    _formError = null;
    _syncGeneratedNames();
    setState(() {});
  }

  Future<void> _save(BuildContext formContext) async {
    if (!Form.of(formContext).validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final model = FinancialYearModel(
      id: _selectedFinancialYear?.id,
      companyId: _companyId,
      fyCode: nullIfEmpty(_fyCodeController.text),
      fyName: nullIfEmpty(_fyNameController.text),
      startDate: nullIfEmpty(_startDateController.text),
      endDate: nullIfEmpty(_endDateController.text),
      isCurrent: _isCurrent,
      isLocked: _isLocked,
      lockDate: _isLocked ? nullIfEmpty(_lockDateController.text) : null,
      isActive: _isCurrent ? true : _isActive,
      remarks: nullIfEmpty(_remarksController.text),
    );

    try {
      final response = _selectedFinancialYear == null
          ? await _masterService.createFinancialYear(model)
          : await _masterService.updateFinancialYear(
              _selectedFinancialYear!.id!,
              model,
            );
      final saved = response.data;
      if (!mounted) {
        return;
      }
      if (saved == null) {
        setState(() => _formError = response.message);
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      _showDraftTile = false;
      _resetForm();
      await _loadData();
    } catch (error) {
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _setAsCurrent() async {
    final selected = _selectedFinancialYear;
    if (selected?.id == null) {
      return;
    }

    setState(() {
      _activating = true;
      _formError = null;
    });

    try {
      final response = await _masterService.setActiveFinancialYear(
        selected!.id!,
      );
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      _showDraftTile = false;
      _resetForm();
      await _loadData();
    } catch (error) {
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _activating = false);
      }
    }
  }

  void _startNewFinancialYear() {
    _showDraftTile = true;
    _resetForm();

    if (!widget.embedded && !Responsive.isDesktop(context)) {
      _workspaceController.openEditor();
    }
  }

  Widget _buildListCard() {
    return SettingsListCard<FinancialYearModel>(
      searchController: _searchController,
      searchHint: 'Search financial years',
      items: _filteredFinancialYears,
      selectedItem: _selectedFinancialYear,
      emptyMessage: widget.fixedCompanyId == null
          ? 'No financial years found.'
          : 'No financial years found for this company.',
      itemBuilder: (item, selected) => SettingsListTile(
        title: item.fyName ?? item.fyCode ?? '',
        subtitle: [
          item.fyCode ?? '',
          if (widget.fixedCompanyId == null)
            item.companyName ?? companyNameById(_companies, item.companyId),
          if ((item.startDate ?? '').isNotEmpty || (item.endDate ?? '').isNotEmpty)
            '${item.startDate ?? ''} to ${item.endDate ?? ''}'.trim(),
        ].where((value) => value.trim().isNotEmpty).join(' • '),
        selected: selected,
        trailing: SettingsStatusPill(
          label: item.isCurrent
              ? 'Current'
              : (item.isActive ? 'Active' : 'Inactive'),
          active: item.isCurrent || item.isActive,
        ),
        onTap: () => _selectFinancialYear(item),
      ),
    );
  }

  Widget _buildEditor() {
    return Builder(
      builder: (BuildContext formContext) {
        return Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_formError != null) ...[
                AppErrorStateView.inline(message: _formError!),
                const SizedBox(height: 16),
              ],
              SettingsFormWrap(
                children: [
                  if (widget.fixedCompanyId == null)
                    AppDropdownField<int>.fromMapped(
                      labelText: 'Company',
                      initialValue: _companyId,
                      mappedItems: _companies
                          .where((company) => company.id != null)
                          .map(
                            (company) => AppDropdownItem<int>(
                              value: company.id!,
                              label: company.toString(),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) =>
                          setState(() => _companyId = value),
                      validator: Validators.requiredSelection('Company'),
                    ),
                  AppFormTextField(
                    controller: _fyCodeController,
                    labelText: 'FY Code',
                    readOnly: true,
                    validator: Validators.compose([
                      Validators.required('FY code'),
                      Validators.optionalMaxLength(20, 'FY code'),
                    ]),
                  ),
                  AppFormTextField(
                    controller: _fyNameController,
                    labelText: 'FY Name',
                    readOnly: true,
                    validator: Validators.compose([
                      Validators.required('FY name'),
                      Validators.optionalMaxLength(50, 'FY name'),
                    ]),
                  ),
                  AppFormTextField(
                    controller: _startDateController,
                    labelText: 'Start Date',
                    hintText: 'YYYY-MM-DD',
                    inputFormatters: const [DateInputFormatter()],
                    validator: Validators.compose([
                      Validators.required('Start date'),
                      Validators.optionalDate('Start date'),
                    ]),
                  ),
                  AppFormTextField(
                    controller: _endDateController,
                    labelText: 'End Date',
                    hintText: 'YYYY-MM-DD',
                    inputFormatters: const [DateInputFormatter()],
                    validator: Validators.compose([
                      Validators.required('End date'),
                      Validators.optionalDateOnOrAfter(
                        'End date',
                        () => _startDateController.text,
                        startFieldName: 'Start date',
                      ),
                    ]),
                  ),
                  AppFormTextField(
                    controller: _lockDateController,
                    labelText: 'Lock Date',
                    hintText: 'YYYY-MM-DD',
                    inputFormatters: const [DateInputFormatter()],
                    validator: Validators.optionalDate('Lock date'),
                  ),
                  AppFormTextField(
                    controller: _remarksController,
                    labelText: 'Remarks',
                    maxLines: 3,
                    validator: Validators.optionalMaxLength(1000, 'Remarks'),
                  ),
                ],
              ),
              AppSwitchTile(
                label: 'Current Financial Year',
                subtitle:
                    'Only one financial year can stay current per company.',
                value: _isCurrent,
                onChanged: (value) {
                  setState(() {
                    _isCurrent = value;
                    if (value) {
                      _isActive = true;
                    }
                  });
                },
              ),
              AppSwitchTile(
                label: 'Locked',
                subtitle: 'Use this when entries should no longer be posted.',
                value: _isLocked,
                onChanged: (value) {
                  setState(() {
                    _isLocked = value;
                    if (!value) {
                      _lockDateController.clear();
                    } else if (_lockDateController.text.trim().isEmpty) {
                      _lockDateController.text =
                          _endDateController.text.trim();
                    }
                  });
                },
              ),
              AppSwitchTile(
                label: 'Active',
                value: _isCurrent ? true : _isActive,
                onChanged: _isCurrent
                    ? null
                    : (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  AppActionButton(
                    icon: Icons.save_outlined,
                    label: _selectedFinancialYear == null
                        ? 'Create Financial Year'
                        : 'Update Financial Year',
                    onPressed: _saving
                        ? null
                        : () => _save(formContext),
                    busy: _saving,
                  ),
                  if (_selectedFinancialYear?.id != null &&
                      _selectedFinancialYear?.isCurrent != true)
                    AppActionButton(
                      icon: Icons.check_circle_outline,
                      label: 'Set Current',
                      onPressed: _activating ? null : _setAsCurrent,
                      busy: _activating,
                      filled: false,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmbeddedContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppUiConstants.spacingSm,
            runSpacing: AppUiConstants.spacingSm,
            children: [
              AppActionButton(
                icon: Icons.add_outlined,
                label: 'New Financial Year',
                onPressed: _startNewFinancialYear,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_filteredFinancialYears.isEmpty &&
              !_showDraftTile &&
              _selectedFinancialYear == null)
            const SettingsEmptyState(
              icon: Icons.calendar_month_outlined,
              title: 'No Financial Years',
              message: 'No financial years found for this company yet.',
              minHeight: 160,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_showDraftTile && _selectedFinancialYear == null) ...[
                  SettingsExpandableTile(
                    key: const ValueKey('fy-draft'),
                    title: 'New Financial Year',
                    subtitle: 'Create a financial year for this company.',
                    expanded: true,
                    highlighted: true,
                    leadingIcon: Icons.add_outlined,
                    onToggle: () {
                      setState(() {
                        _showDraftTile = false;
                      });
                      _resetForm();
                    },
                    child: _buildEditor(),
                  ),
                  if (_filteredFinancialYears.isNotEmpty)
                    const SizedBox(height: AppUiConstants.spacingSm),
                ],
                ..._filteredFinancialYears.map((item) {
                  final expanded = identical(item, _selectedFinancialYear);
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppUiConstants.spacingSm,
                    ),
                    child: SettingsExpandableTile(
                      key: ValueKey('fy-${item.id}-$expanded'),
                      title: item.fyName ?? item.fyCode ?? '-',
                      subtitle: [
                        item.fyCode ?? '',
                        if ((item.startDate ?? '').isNotEmpty ||
                            (item.endDate ?? '').isNotEmpty)
                          '${item.startDate ?? ''} to ${item.endDate ?? ''}'
                              .trim(),
                      ].where((value) => value.trim().isNotEmpty).join(' • '),
                      detail: item.isCurrent
                          ? 'Current'
                          : (item.isActive ? 'Active' : 'Inactive'),
                      expanded: expanded,
                      highlighted: expanded,
                      trailing: SettingsStatusPill(
                        label: item.isCurrent
                            ? 'Current'
                            : (item.isActive ? 'Active' : 'Inactive'),
                        active: item.isCurrent || item.isActive,
                      ),
                      onToggle: () {
                        if (expanded) {
                          _resetForm();
                        } else {
                          _selectFinancialYear(item);
                        }
                      },
                      child: _buildEditor(),
                    ),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading financial years...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load financial years',
        message: _pageError!,
        onRetry: _loadData,
      );
    }

    if (widget.embedded) {
      return _buildEmbeddedContent();
    }

    return AppStandaloneShell(
      title: 'Financial Years',
      scrollController: _pageScrollController,
      actions: [
        AdaptiveShellActionButton(
          onPressed: _startNewFinancialYear,
          icon: Icons.add_outlined,
          label: 'New Financial Year',
        ),
      ],
      child: SettingsWorkspace(
        controller: _workspaceController,
        title: 'Financial Years',
        editorTitle: _selectedFinancialYear?.toString(),
        scrollController: _pageScrollController,
        list: _buildListCard(),
        editor: _buildEditor(),
      ),
    );
  }
}
