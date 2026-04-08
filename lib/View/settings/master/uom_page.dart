import '../../../screen.dart';

class UomManagementPage extends StatefulWidget {
  const UomManagementPage({
    super.key,
    this.embedded = false,
    this.initialTabIndex = 0,
  });

  final bool embedded;
  final int initialTabIndex;

  @override
  State<UomManagementPage> createState() => _UomManagementPageState();
}

class _UomManagementPageState extends State<UomManagementPage>
    with SingleTickerProviderStateMixin {
  final InventoryService _inventoryService = InventoryService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _symbolController = TextEditingController();
  final GlobalKey<FormState> _conversionFormKey = GlobalKey<FormState>();
  final TextEditingController _conversionFactorController =
      TextEditingController();
  late final TabController _tabController;

  bool _initialLoading = true;
  bool _saving = false;
  bool _savingConversion = false;
  String? _pageError;
  String? _formError;
  String? _conversionError;
  List<UomModel> _uoms = const <UomModel>[];
  List<UomModel> _filteredUoms = const <UomModel>[];
  List<UomConversionModel> _conversions = const <UomConversionModel>[];
  UomModel? _selectedUom;
  bool _isActive = true;
  bool _isFractionAllowed = false;
  int? _conversionTargetUomId;
  bool _conversionActive = true;
  UomConversionModel? _selectedConversionRecord;
  bool _selectedConversionReversed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _searchController.addListener(_applySearch);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _symbolController.dispose();
    _conversionFactorController.dispose();
    super.dispose();
  }

  Future<void> _loadData({int? selectId}) async {
    setState(() {
      _initialLoading = _uoms.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait<dynamic>([
        _inventoryService.uoms(
          filters: const {'per_page': 200, 'sort_by': 'uom_name'},
        ),
        _inventoryService.uomConversions(
          filters: const {
            'per_page': 500,
            'sort_by': 'id',
            'sort_order': 'asc',
          },
        ),
      ]);

      final uoms =
          (responses[0] as PaginatedResponse<UomModel>).data ??
          const <UomModel>[];
      final conversions =
          (responses[1] as PaginatedResponse<UomConversionModel>).data ??
          const <UomConversionModel>[];

      if (!mounted) {
        return;
      }

      setState(() {
        _uoms = uoms;
        _conversions = conversions;
        _filteredUoms = _filterUoms(uoms, _searchController.text);
        _initialLoading = false;
      });

      final selected = selectId != null
          ? uoms.cast<UomModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedUom == null
                ? (uoms.isNotEmpty ? uoms.first : null)
                : uoms.cast<UomModel?>().firstWhere(
                    (item) => item?.id == _selectedUom?.id,
                    orElse: () => uoms.isNotEmpty ? uoms.first : null,
                  ));

      if (selected != null) {
        _selectUom(selected);
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

  List<UomModel> _filterUoms(List<UomModel> source, String query) {
    return filterMasterList(source, query, (uom) {
      return [uom.uomCode ?? '', uom.uomName ?? '', uom.symbol ?? ''];
    });
  }

  void _applySearch() {
    setState(() {
      _filteredUoms = _filterUoms(_uoms, _searchController.text);
    });
  }

  void _selectUom(UomModel uom) {
    _selectedUom = uom;
    _codeController.text = uom.uomCode ?? '';
    _nameController.text = uom.uomName ?? '';
    _symbolController.text = uom.symbol ?? '';
    _isFractionAllowed = uom.isFractionAllowed;
    _isActive = uom.isActive;
    _formError = null;
    _resetConversionForm();
    setState(() {});
  }

  void _resetForm() {
    _selectedUom = null;
    _codeController.clear();
    _nameController.clear();
    _symbolController.clear();
    _isFractionAllowed = false;
    _isActive = true;
    _formError = null;
    _resetConversionForm();
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

    final model = UomModel(
      id: _selectedUom?.id,
      uomCode: _codeController.text.trim(),
      uomName: _nameController.text.trim(),
      symbol: _symbolController.text.trim(),
      isFractionAllowed: _isFractionAllowed,
      isActive: _isActive,
    );

    try {
      final response = _selectedUom == null
          ? await _inventoryService.createUom(model)
          : await _inventoryService.updateUom(_selectedUom!.id!, model);
      final saved = response.data;
      if (!mounted) {
        return;
      }
      if (saved == null) {
        setState(() {
          _formError = response.message;
        });
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData(selectId: saved.id);
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

  Future<void> _delete() async {
    final id = _selectedUom?.id;
    if (id == null) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final response = await _inventoryService.deleteUom(id);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData();
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

  List<_UomConversionViewModel> get _displayConversions {
    final selectedId = _selectedUom?.id;
    if (selectedId == null) {
      return const <_UomConversionViewModel>[];
    }

    final views = <_UomConversionViewModel>[];
    for (final record in _conversions) {
      if (record.fromUomId == selectedId) {
        views.add(
          _UomConversionViewModel(
            record: record,
            otherUomId: record.toUomId,
            otherLabel: _uomLabel(record.toUomName, record.toUomCode),
            displayFactor: record.conversionFactor,
            isActive: record.isActive,
            reversed: false,
          ),
        );
      } else if (record.toUomId == selectedId) {
        final factor = record.conversionFactor;
        views.add(
          _UomConversionViewModel(
            record: record,
            otherUomId: record.fromUomId,
            otherLabel: _uomLabel(record.fromUomName, record.fromUomCode),
            displayFactor: factor == null || factor == 0 ? null : (1 / factor),
            isActive: record.isActive,
            reversed: true,
          ),
        );
      }
    }

    views.sort(
      (left, right) => left.otherLabel.toLowerCase().compareTo(
        right.otherLabel.toLowerCase(),
      ),
    );
    return views;
  }

  String _uomLabel(String? name, String? code) {
    final trimmedName = (name ?? '').trim();
    if (trimmedName.isNotEmpty) {
      return trimmedName;
    }
    return (code ?? '').trim();
  }

  void _resetConversionForm() {
    final selectedId = _selectedUom?.id;
    _selectedConversionRecord = null;
    _selectedConversionReversed = false;
    _conversionFactorController.clear();
    _conversionActive = true;
    _conversionError = null;
    _conversionTargetUomId = _uoms
        .where((uom) => uom.id != null && uom.id != selectedId)
        .cast<UomModel?>()
        .firstWhere((_) => true, orElse: () => null)
        ?.id;
  }

  void _selectConversion(_UomConversionViewModel view) {
    _selectedConversionRecord = view.record;
    _selectedConversionReversed = view.reversed;
    _conversionTargetUomId = view.otherUomId;
    _conversionFactorController.text = view.displayFactor?.toString() ?? '';
    _conversionActive = view.isActive;
    _conversionError = null;
    setState(() {});
  }

  Future<void> _saveConversion() async {
    final currentUomId = _selectedUom?.id;
    if (currentUomId == null ||
        !(_conversionFormKey.currentState?.validate() ?? false)) {
      return;
    }

    final targetUomId = _conversionTargetUomId;
    final displayFactor = double.tryParse(
      _conversionFactorController.text.trim(),
    );
    if (targetUomId == null || displayFactor == null || displayFactor <= 0) {
      setState(() {
        _conversionError =
            'Target UOM and valid conversion factor are required.';
      });
      return;
    }

    final fromUomId = _selectedConversionRecord == null
        ? currentUomId
        : (_selectedConversionReversed ? targetUomId : currentUomId);
    final toUomId = _selectedConversionRecord == null
        ? targetUomId
        : (_selectedConversionReversed ? currentUomId : targetUomId);
    final storedFactor = _selectedConversionReversed
        ? 1 / displayFactor
        : displayFactor;

    setState(() {
      _savingConversion = true;
      _conversionError = null;
    });

    final model = UomConversionModel(
      id: _selectedConversionRecord?.id,
      fromUomId: fromUomId,
      toUomId: toUomId,
      conversionFactor: storedFactor,
      isActive: _conversionActive,
    );

    try {
      final response = _selectedConversionRecord == null
          ? await _inventoryService.createUomConversion(model)
          : await _inventoryService.updateUomConversion(
              _selectedConversionRecord!.id!,
              model,
            );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData(selectId: currentUomId);
    } catch (error) {
      setState(() {
        _conversionError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _savingConversion = false;
        });
      }
    }
  }

  Future<void> _deleteConversion() async {
    final id = _selectedConversionRecord?.id;
    final currentUomId = _selectedUom?.id;
    if (id == null || currentUomId == null) {
      return;
    }

    setState(() {
      _savingConversion = true;
      _conversionError = null;
    });

    try {
      final response = await _inventoryService.deleteUomConversion(id);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData(selectId: currentUomId);
    } catch (error) {
      setState(() {
        _conversionError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _savingConversion = false;
        });
      }
    }
  }

  void _startNewUom() {
    _resetForm();
    _tabController.animateTo(0);

    if (!Responsive.isDesktop(context)) {
      _workspaceController.openEditor();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _startNewUom,
        icon: Icons.add_circle_outline,
        label: 'New UOM',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'UOM',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading UOM...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load UOM',
        message: _pageError!,
        onRetry: _loadData,
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'UOM',
      editorTitle: _selectedUom?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<UomModel>(
        searchController: _searchController,
        searchHint: 'Search UOM',
        items: _filteredUoms,
        selectedItem: _selectedUom,
        emptyMessage: 'No UOM records found.',
        itemBuilder: (uom, selected) => SettingsListTile(
          title: uom.uomName ?? '-',
          subtitle: [
            uom.symbol ?? '',
            uom.uomCode ?? '',
          ].where((value) => value.trim().isNotEmpty).join(' · '),
          selected: selected,
          onTap: () => _selectUom(uom),
          trailing: SettingsStatusPill(
            label: uom.isActive ? 'Active' : 'Inactive',
            active: uom.isActive,
          ),
        ),
      ),
      editor: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Primary'),
                  Tab(text: 'Conversions'),
                ],
              ),
              const SizedBox(height: 20),
              IndexedStack(
                index: _tabController.index,
                children: [_buildPrimaryTab(), _buildConversionsTab()],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPrimaryTab() {
    return AppSectionCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_formError != null) ...[
              AppErrorStateView.inline(message: _formError!),
              const SizedBox(height: 16),
            ],
            SettingsFormWrap(
              children: [
                AppFormTextField(
                  labelText: 'UOM Code',
                  controller: _codeController,
                  validator: Validators.required('UOM code'),
                ),
                AppFormTextField(
                  labelText: 'UOM Name',
                  controller: _nameController,
                  validator: Validators.required('UOM name'),
                ),
                AppFormTextField(
                  labelText: 'Symbol',
                  controller: _symbolController,
                  validator: Validators.required('Symbol'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                SizedBox(
                  child: AppSwitchTile(
                    label: 'Fraction Allowed',
                    subtitle: 'Enable decimal quantity for this unit.',
                    value: _isFractionAllowed,
                    onChanged: (value) =>
                        setState(() => _isFractionAllowed = value),
                  ),
                ),
                SizedBox(
                  child: AppSwitchTile(
                    label: 'Active',
                    subtitle: 'Inactive UOMs stay hidden from normal use.',
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: _selectedUom == null ? 'Save UOM' : 'Update UOM',
                  onPressed: _save,
                  busy: _saving,
                ),
                if (_selectedUom?.id != null)
                  AppActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    onPressed: _saving ? null : _delete,
                    filled: false,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionsTab() {
    final selectedUom = _selectedUom;
    if (selectedUom?.id == null) {
      return const SettingsEmptyState(
        icon: Icons.straighten_outlined,
        title: 'Save UOM First',
        message: 'Conversions become available after the UOM is saved.',
      );
    }
    final currentUom = selectedUom!;

    final targetOptions = _uoms
        .where((uom) => uom.id != null && uom.id != currentUom.id)
        .toList(growable: false);

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conversions for ${currentUom.uomName ?? currentUom.uomCode}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          if (_displayConversions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No conversions defined for this UOM.'),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _displayConversions.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _displayConversions[index];
                return SettingsListTile(
                  title: item.otherLabel,
                  subtitle: [
                    if (item.displayFactor != null)
                      'Factor ${item.displayFactor}',
                    if (item.reversed) 'Reverse view',
                    if (item.isActive) 'Active',
                  ].join(' · '),
                  selected: identical(item.record, _selectedConversionRecord),
                  onTap: () => _selectConversion(item),
                );
              },
            ),
          const SizedBox(height: 20),
          Form(
            key: _conversionFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_conversionError != null) ...[
                  AppErrorStateView.inline(message: _conversionError!),
                  const SizedBox(height: 12),
                ],
                SettingsFormWrap(
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: _conversionTargetUomId,
                      decoration: const InputDecoration(labelText: 'To UOM'),
                      items: targetOptions
                          .map(
                            (uom) => DropdownMenuItem<int>(
                              value: uom.id,
                              child: Text(uom.toString()),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) =>
                          setState(() => _conversionTargetUomId = value),
                      validator: Validators.requiredSelection('To UOM'),
                    ),
                    AppFormTextField(
                      labelText: 'Conversion Factor',
                      controller: _conversionFactorController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: Validators.compose([
                        Validators.required('Conversion factor'),
                        Validators.optionalNonNegativeNumber(
                          'Conversion factor',
                        ),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Factor is from the selected UOM to the target UOM. Reverse view is calculated automatically.',
                ),
                const SizedBox(height: 12),
                AppSwitchTile(
                  label: 'Active',
                  value: _conversionActive,
                  onChanged: (value) =>
                      setState(() => _conversionActive = value),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    AppActionButton(
                      icon: Icons.save_outlined,
                      label: _selectedConversionRecord == null
                          ? 'Save Conversion'
                          : 'Update Conversion',
                      onPressed: _saveConversion,
                      busy: _savingConversion,
                    ),
                    AppActionButton(
                      icon: Icons.refresh_outlined,
                      label: 'New',
                      filled: false,
                      onPressed: _savingConversion
                          ? null
                          : () => setState(_resetConversionForm),
                    ),
                    if (_selectedConversionRecord?.id != null)
                      AppActionButton(
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        filled: false,
                        onPressed: _savingConversion ? null : _deleteConversion,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UomConversionViewModel {
  const _UomConversionViewModel({
    required this.record,
    required this.otherUomId,
    required this.otherLabel,
    required this.displayFactor,
    required this.isActive,
    required this.reversed,
  });

  final UomConversionModel record;
  final int? otherUomId;
  final String otherLabel;
  final double? displayFactor;
  final bool isActive;
  final bool reversed;
}
