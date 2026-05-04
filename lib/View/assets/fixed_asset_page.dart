import '../../screen.dart';
import '../hr/hr_workflow_dialogs.dart';

Map<String, dynamic>? _assetJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

String _assetCategoryLabel(Map<String, dynamic> data) {
  final category = _assetJsonMap(data['category']);
  if (category == null) {
    return '';
  }
  final code = stringValue(category, 'category_code');
  final name = stringValue(category, 'category_name');
  if (code.isNotEmpty && name.isNotEmpty) {
    return '$code - $name';
  }
  return code.isNotEmpty ? code : name;
}

class FixedAssetPage extends StatefulWidget {
  const FixedAssetPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<FixedAssetPage> createState() => _FixedAssetPageState();
}

class _FixedAssetPageState extends State<FixedAssetPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final AssetsService _assets = AssetsService();
  final MasterService _master = MasterService();
  final PartiesService _partiesService = PartiesService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _assetCodeController = TextEditingController();
  final TextEditingController _assetNameController = TextEditingController();
  final TextEditingController _assetTagController = TextEditingController();
  final TextEditingController _serialNoController = TextEditingController();
  final TextEditingController _manufacturerController = TextEditingController();
  final TextEditingController _modelNoController = TextEditingController();
  final TextEditingController _purchaseDateController = TextEditingController();
  final TextEditingController _capitalizationDateController =
      TextEditingController();
  final TextEditingController _putToUseDateController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _employeeController = TextEditingController();
  final TextEditingController _acquisitionCostController =
      TextEditingController();
  final TextEditingController _additionalCostController =
      TextEditingController();
  final TextEditingController _capitalizationValueController =
      TextEditingController();
  final TextEditingController _salvageValueController = TextEditingController();
  final TextEditingController _conditionStatusController =
      TextEditingController();
  final TextEditingController _warrantyStartController =
      TextEditingController();
  final TextEditingController _warrantyEndController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _loading = true;
  bool _detailLoading = false;
  bool _saving = false;
  bool _actionBusy = false;
  String? _pageError;
  String? _formError;
  String? _actionMessage;
  int? _sessionCompanyId;

  List<AssetModel> _rows = const <AssetModel>[];
  List<AssetCategoryModel> _categories = const <AssetCategoryModel>[];
  List<CostCenterModel> _costCenters = const <CostCenterModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<BranchModel> _branches = const <BranchModel>[];
  List<BusinessLocationModel> _locations = const <BusinessLocationModel>[];
  List<WarehouseModel> _warehouses = const <WarehouseModel>[];
  List<PartyModel> _parties = const <PartyModel>[];

  AssetModel? _selected;
  AssetModel? _detail;

  int? _companyId;
  int? _branchId;
  int? _locationId;
  int? _categoryId;
  int? _costCenterId;
  int? _warehouseId;
  int? _supplierPartyId;
  bool _isDepreciable = true;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _load(selectId: widget.initialId);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _assetCodeController.dispose();
    _assetNameController.dispose();
    _assetTagController.dispose();
    _serialNoController.dispose();
    _manufacturerController.dispose();
    _modelNoController.dispose();
    _purchaseDateController.dispose();
    _capitalizationDateController.dispose();
    _putToUseDateController.dispose();
    _departmentController.dispose();
    _employeeController.dispose();
    _acquisitionCostController.dispose();
    _additionalCostController.dispose();
    _capitalizationValueController.dispose();
    _salvageValueController.dispose();
    _conditionStatusController.dispose();
    _warrantyStartController.dispose();
    _warrantyEndController.dispose();
    _notesController.dispose();
    _pageScrollController.dispose();
    _workspaceController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _snack() {
    final msg = _actionMessage;
    _actionMessage = null;
    if (!mounted || msg == null || msg.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  List<AssetModel> get _filteredRows {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'asset_code'),
            stringValue(data, 'asset_name'),
            stringValue(data, 'asset_status'),
            _assetCategoryLabel(data),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  List<AssetCategoryModel> get _categoryOptions {
    return _categories
        .where((category) {
          if (_companyId == null) {
            return true;
          }
          return intValue(category.toJson(), 'company_id') == _companyId;
        })
        .toList(growable: false);
  }

  List<CostCenterModel> get _costCenterOptions {
    return _costCenters
        .where((costCenter) {
          if (_companyId == null) {
            return true;
          }
          return costCenter.companyId == _companyId;
        })
        .toList(growable: false);
  }

  List<BranchModel> get _branchOptions {
    return _branches
        .where((branch) {
          if (_companyId == null) {
            return true;
          }
          return branch.companyId == _companyId;
        })
        .toList(growable: false);
  }

  List<BusinessLocationModel> get _locationOptions {
    return _locations
        .where((location) {
          if (_companyId != null && location.companyId != _companyId) {
            return false;
          }
          if (_branchId != null && location.branchId != _branchId) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  List<WarehouseModel> get _warehouseOptions {
    return _warehouses
        .where((warehouse) {
          if (_companyId != null && warehouse.companyId != _companyId) {
            return false;
          }
          if (_branchId != null && warehouse.branchId != _branchId) {
            return false;
          }
          if (_locationId != null && warehouse.locationId != _locationId) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  String _listTitle(AssetModel row) {
    final data = row.toJson();
    final code = stringValue(data, 'asset_code');
    if (code.isNotEmpty) {
      return code;
    }
    return stringValue(data, 'asset_name');
  }

  String _listSubtitle(AssetModel row) {
    final data = row.toJson();
    return [
      stringValue(data, 'asset_name'),
      _assetCategoryLabel(data),
      stringValue(data, 'asset_status'),
    ].where((value) => value.trim().isNotEmpty).join(' · ');
  }

  void _resetDraft() {
    _selected = null;
    _detail = null;
    _formError = null;
    _companyId = _sessionCompanyId;
    _branchId = null;
    _locationId = null;
    _categoryId = null;
    _costCenterId = null;
    _warehouseId = null;
    _supplierPartyId = null;
    _isDepreciable = true;
    _isActive = true;
    _assetCodeController.clear();
    _assetNameController.clear();
    _assetTagController.clear();
    _serialNoController.clear();
    _manufacturerController.clear();
    _modelNoController.clear();
    _purchaseDateController.clear();
    _capitalizationDateController.clear();
    _putToUseDateController.clear();
    _departmentController.clear();
    _employeeController.clear();
    _acquisitionCostController.clear();
    _additionalCostController.clear();
    _capitalizationValueController.clear();
    _salvageValueController.clear();
    _conditionStatusController.text = 'good';
    _warrantyStartController.clear();
    _warrantyEndController.clear();
    _notesController.clear();
    setState(() {});
  }

  void _applyFromModel(AssetModel model) {
    final data = model.toJson();
    _companyId = intValue(data, 'company_id');
    _branchId = intValue(data, 'branch_id');
    _locationId = intValue(data, 'location_id');
    _categoryId = intValue(data, 'asset_category_id');
    _costCenterId = intValue(data, 'cost_center_id');
    _warehouseId = intValue(data, 'warehouse_id');
    _supplierPartyId = intValue(data, 'supplier_party_id');
    _isDepreciable =
        data['is_depreciable'] == true || data['is_depreciable'] == 1;
    _isActive = data['is_active'] == true || data['is_active'] == 1;
    _assetCodeController.text = stringValue(data, 'asset_code');
    _assetNameController.text = stringValue(data, 'asset_name');
    _assetTagController.text = stringValue(data, 'asset_tag_no');
    _serialNoController.text = stringValue(data, 'serial_no');
    _manufacturerController.text = stringValue(data, 'manufacturer');
    _modelNoController.text = stringValue(data, 'model_no');
    _purchaseDateController.text = stringValue(data, 'purchase_date');
    _capitalizationDateController.text = stringValue(
      data,
      'capitalization_date',
    );
    _putToUseDateController.text = stringValue(data, 'put_to_use_date');
    _departmentController.text = stringValue(data, 'department_name');
    _employeeController.text = stringValue(data, 'employee_name');
    _acquisitionCostController.text =
        data['acquisition_cost']?.toString() ?? '';
    _additionalCostController.text = data['additional_cost']?.toString() ?? '';
    _capitalizationValueController.text =
        data['capitalization_value']?.toString() ?? '';
    _salvageValueController.text = data['salvage_value']?.toString() ?? '';
    _conditionStatusController.text = stringValue(data, 'condition_status');
    _warrantyStartController.text = stringValue(data, 'warranty_start_date');
    _warrantyEndController.text = stringValue(data, 'warranty_end_date');
    _notesController.text = stringValue(data, 'notes');
  }

  Future<void> _load({int? selectId}) async {
    setState(() {
      _loading = true;
      _pageError = null;
    });
    try {
      final info = await hrSessionCompanyInfo();
      _sessionCompanyId = info.companyId;
      final listFilters = <String, dynamic>{'per_page': 200};
      final optionFilters = <String, dynamic>{'per_page': 500};
      if (info.companyId != null) {
        listFilters['company_id'] = info.companyId;
        optionFilters['company_id'] = info.companyId;
      }

      final responses = await Future.wait<dynamic>([
        _assets.assets(filters: listFilters),
        _assets.categories(filters: optionFilters),
        _assets.costCenters(filters: optionFilters),
        _master.companies(filters: const {'per_page': 200}),
        _master.branches(filters: const {'per_page': 500}),
        _master.businessLocations(filters: const {'per_page': 500}),
        _master.warehouses(filters: const {'per_page': 500}),
        _partiesService.parties(filters: const {'per_page': 500}),
      ]);

      _rows =
          (responses[0] as PaginatedResponse<AssetModel>).data ??
          const <AssetModel>[];
      _categories =
          (responses[1] as PaginatedResponse<AssetCategoryModel>).data ??
          const <AssetCategoryModel>[];
      _costCenters =
          (responses[2] as PaginatedResponse<CostCenterModel>).data ??
          const <CostCenterModel>[];
      _companies =
          ((responses[3] as PaginatedResponse<CompanyModel>).data ??
                  const <CompanyModel>[])
              .where((company) => company.isActive)
              .toList(growable: false);
      _branches =
          ((responses[4] as PaginatedResponse<BranchModel>).data ??
                  const <BranchModel>[])
              .where((branch) => branch.isActive)
              .toList(growable: false);
      _locations =
          ((responses[5] as PaginatedResponse<BusinessLocationModel>).data ??
                  const <BusinessLocationModel>[])
              .where((location) => location.isActive)
              .toList(growable: false);
      _warehouses =
          ((responses[6] as PaginatedResponse<WarehouseModel>).data ??
                  const <WarehouseModel>[])
              .where((warehouse) => warehouse.isActive)
              .toList(growable: false);
      _parties =
          ((responses[7] as PaginatedResponse<PartyModel>).data ??
                  const <PartyModel>[])
              .where((party) => party.isActive)
              .toList(growable: false);

      _loading = false;

      if (selectId != null) {
        final existing = _rows.cast<AssetModel?>().firstWhere(
          (row) => intValue(row?.toJson() ?? const {}, 'id') == selectId,
          orElse: () => null,
        );
        if (existing != null) {
          await _select(existing);
          return;
        }
        await _loadDetailById(selectId);
        return;
      }

      _resetDraft();
    } catch (e) {
      setState(() {
        _pageError = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _reloadList() async {
    final info = await hrSessionCompanyInfo();
    final filters = <String, dynamic>{'per_page': 200};
    if (info.companyId != null) {
      filters['company_id'] = info.companyId;
    }
    final response = await _assets.assets(filters: filters);
    _rows = response.data ?? const <AssetModel>[];
  }

  Future<void> _loadDetailById(int id) async {
    setState(() {
      _detailLoading = true;
      _formError = null;
    });
    try {
      final response = await _assets.asset(id);
      if (response.success == true && response.data != null) {
        _detail = response.data;
        _selected = response.data;
        _applyFromModel(response.data!);
      } else {
        _formError = response.message;
      }
    } catch (e) {
      _formError = e.toString();
    } finally {
      if (mounted) {
        setState(() => _detailLoading = false);
      }
    }
  }

  Future<void> _select(AssetModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) {
      return;
    }
    setState(() {
      _selected = row;
      _detailLoading = true;
      _formError = null;
    });
    try {
      final response = await _assets.asset(id);
      if (response.success == true && response.data != null) {
        _detail = response.data;
        _applyFromModel(response.data!);
      } else {
        _formError = response.message;
      }
    } catch (e) {
      _formError = e.toString();
    } finally {
      if (mounted) {
        setState(() => _detailLoading = false);
      }
    }
  }

  Future<void> _save() async {
    final companyId = _companyId;
    final categoryId = _categoryId;
    final code = _assetCodeController.text.trim();
    final name = _assetNameController.text.trim();
    if (companyId == null) {
      setState(() => _formError = 'Company is required.');
      return;
    }
    if (categoryId == null) {
      setState(() => _formError = 'Asset category is required.');
      return;
    }
    if (code.isEmpty || name.isEmpty) {
      setState(() => _formError = 'Asset code and asset name are required.');
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });
    try {
      final payload = <String, dynamic>{
        'company_id': companyId,
        'asset_category_id': categoryId,
        'asset_code': code,
        'asset_name': name,
        'condition_status':
            nullIfEmpty(_conditionStatusController.text.trim()) ?? 'good',
        'is_depreciable': _isDepreciable,
        'is_active': _isActive,
        if (_branchId != null) 'branch_id': _branchId,
        if (_locationId != null) 'location_id': _locationId,
        if (_costCenterId != null) 'cost_center_id': _costCenterId,
        if (_warehouseId != null) 'warehouse_id': _warehouseId,
        if (_supplierPartyId != null) 'supplier_party_id': _supplierPartyId,
        if (nullIfEmpty(_assetTagController.text.trim()) != null)
          'asset_tag_no': _assetTagController.text.trim(),
        if (nullIfEmpty(_serialNoController.text.trim()) != null)
          'serial_no': _serialNoController.text.trim(),
        if (nullIfEmpty(_manufacturerController.text.trim()) != null)
          'manufacturer': _manufacturerController.text.trim(),
        if (nullIfEmpty(_modelNoController.text.trim()) != null)
          'model_no': _modelNoController.text.trim(),
        if (nullIfEmpty(_purchaseDateController.text.trim()) != null)
          'purchase_date': _purchaseDateController.text.trim(),
        if (nullIfEmpty(_capitalizationDateController.text.trim()) != null)
          'capitalization_date': _capitalizationDateController.text.trim(),
        if (nullIfEmpty(_putToUseDateController.text.trim()) != null)
          'put_to_use_date': _putToUseDateController.text.trim(),
        if (nullIfEmpty(_departmentController.text.trim()) != null)
          'department_name': _departmentController.text.trim(),
        if (nullIfEmpty(_employeeController.text.trim()) != null)
          'employee_name': _employeeController.text.trim(),
        if (double.tryParse(_acquisitionCostController.text.trim()) != null)
          'acquisition_cost': double.parse(
            _acquisitionCostController.text.trim(),
          ),
        if (double.tryParse(_additionalCostController.text.trim()) != null)
          'additional_cost': double.parse(
            _additionalCostController.text.trim(),
          ),
        if (double.tryParse(_capitalizationValueController.text.trim()) != null)
          'capitalization_value': double.parse(
            _capitalizationValueController.text.trim(),
          ),
        if (double.tryParse(_salvageValueController.text.trim()) != null)
          'salvage_value': double.parse(_salvageValueController.text.trim()),
        if (nullIfEmpty(_warrantyStartController.text.trim()) != null)
          'warranty_start_date': _warrantyStartController.text.trim(),
        if (nullIfEmpty(_warrantyEndController.text.trim()) != null)
          'warranty_end_date': _warrantyEndController.text.trim(),
        if (nullIfEmpty(_notesController.text.trim()) != null)
          'notes': _notesController.text.trim(),
      };

      final existingId = intValue(_detail?.toJson() ?? const {}, 'id');
      final response = existingId == null
          ? await _assets.createAsset(AssetModel(payload))
          : await _assets.updateAsset(existingId, AssetModel(payload));
      if (response.success != true || response.data == null) {
        setState(() => _formError = response.message);
        return;
      }

      _detail = response.data;
      _selected = response.data;
      _applyFromModel(response.data!);
      await _reloadList();
      final savedId = intValue(response.data!.toJson(), 'id');
      if (savedId != null) {
        _selected =
            _rows.cast<AssetModel?>().firstWhere(
              (row) => intValue(row?.toJson() ?? const {}, 'id') == savedId,
              orElse: () => null,
            ) ??
            response.data;
      }
      _actionMessage = existingId == null ? 'Asset created.' : 'Asset updated.';
      _snack();
    } catch (e) {
      setState(() => _formError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _runAction(
    Future<ApiResponse<AssetModel>> Function() fn,
    String message,
  ) async {
    setState(() {
      _actionBusy = true;
      _formError = null;
    });
    try {
      final response = await fn();
      if (response.success != true || response.data == null) {
        setState(() => _formError = response.message);
        return;
      }
      _detail = response.data;
      _selected = response.data;
      _applyFromModel(response.data!);
      await _reloadList();
      _actionMessage = message;
      _snack();
    } catch (e) {
      setState(() => _formError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _actionBusy = false);
      }
    }
  }

  Future<void> _delete() async {
    final id = intValue(_detail?.toJson() ?? const {}, 'id');
    if (id == null) {
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete asset'),
        content: const Text(
          'Requires all asset books to be removed first. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    setState(() => _actionBusy = true);
    try {
      final response = await _assets.deleteAsset(id);
      if (response.success != true) {
        setState(() => _formError = response.message);
        return;
      }
      await _reloadList();
      _resetDraft();
      _actionMessage = 'Asset deleted.';
      _snack();
    } catch (e) {
      setState(() => _formError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _actionBusy = false);
      }
    }
  }

  void _openBooks() {
    final id = intValue(_detail?.toJson() ?? const {}, 'id');
    if (id == null) {
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => _AssetBooksDialog(assetId: id),
    ).then((_) {
      if (mounted) {
        _loadDetailById(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _loading
            ? null
            : () {
                _resetDraft();
                if (!Responsive.isDesktop(context)) {
                  _workspaceController.openEditor();
                }
              },
        icon: Icons.add_outlined,
        label: 'New asset',
      ),
    ];

    final content = _buildContent(context);
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'Fixed assets',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_loading) {
      return const AppLoadingView(message: 'Loading assets...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load assets',
        message: _pageError!,
        onRetry: () => _load(selectId: widget.initialId),
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Fixed assets',
      editorTitle: _selected == null ? 'New asset' : _listTitle(_selected!),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<AssetModel>(
        searchController: _searchController,
        searchHint: 'Search code, name, category, status',
        items: _filteredRows,
        selectedItem: _selected,
        emptyMessage: 'No assets found.',
        itemBuilder: (item, selected) {
          return SettingsListTile(
            title: _listTitle(item),
            subtitle: _listSubtitle(item),
            selected: selected,
            onTap: () async {
              final isDesktop = Responsive.isDesktop(context);
              await _select(item);
              if (!mounted) {
                return;
              }
              if (!isDesktop) {
                _workspaceController.openEditor();
              }
            },
          );
        },
      ),
      editor: _detailLoading
          ? const AppLoadingView(message: 'Loading asset...')
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_formError != null) ...[
                    AppErrorStateView.inline(message: _formError!),
                    const SizedBox(height: AppUiConstants.spacingSm),
                  ],
                  Text(
                    _selected == null ? 'New asset' : 'Edit asset',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppUiConstants.spacingMd),
                  if (_saving || _actionBusy) const LinearProgressIndicator(),
                  SettingsFormWrap(
                    children: [
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Company',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _companyId,
                        items: _companies
                            .where((company) => company.id != null)
                            .map(
                              (company) => DropdownMenuItem<int>(
                                value: company.id,
                                child: Text(company.toString()),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: _saving || _actionBusy
                            ? null
                            : (value) => setState(() {
                                _companyId = value;
                                _branchId = null;
                                _locationId = null;
                                _categoryId = null;
                                _costCenterId = null;
                                _warehouseId = null;
                              }),
                      ),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Branch',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _branchId,
                        items: _branchOptions
                            .where((branch) => branch.id != null)
                            .map(
                              (branch) => DropdownMenuItem<int>(
                                value: branch.id,
                                child: Text(branch.toString()),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: _saving || _actionBusy
                            ? null
                            : (value) => setState(() {
                                _branchId = value;
                                _locationId = null;
                                _warehouseId = null;
                              }),
                      ),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _locationId,
                        items: _locationOptions
                            .where((location) => location.id != null)
                            .map(
                              (location) => DropdownMenuItem<int>(
                                value: location.id,
                                child: Text(location.toString()),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: _saving || _actionBusy
                            ? null
                            : (value) => setState(() {
                                _locationId = value;
                                _warehouseId = null;
                              }),
                      ),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Asset category',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _categoryId,
                        items: _categoryOptions
                            .where(
                              (category) =>
                                  intValue(category.toJson(), 'id') != null,
                            )
                            .map(
                              (category) => DropdownMenuItem<int>(
                                value: intValue(category.toJson(), 'id'),
                                child: Text(
                                  stringValue(
                                        category.toJson(),
                                        'category_name',
                                      ).isNotEmpty
                                      ? stringValue(
                                          category.toJson(),
                                          'category_name',
                                        )
                                      : stringValue(
                                          category.toJson(),
                                          'category_code',
                                        ),
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: _saving || _actionBusy
                            ? null
                            : (value) => setState(() => _categoryId = value),
                      ),
                      AppFormTextField(
                        labelText: 'Asset code',
                        controller: _assetCodeController,
                      ),
                      AppFormTextField(
                        labelText: 'Asset name',
                        controller: _assetNameController,
                      ),
                      AppFormTextField(
                        labelText: 'Asset tag no',
                        controller: _assetTagController,
                      ),
                      AppFormTextField(
                        labelText: 'Serial no',
                        controller: _serialNoController,
                      ),
                      AppFormTextField(
                        labelText: 'Manufacturer',
                        controller: _manufacturerController,
                      ),
                      AppFormTextField(
                        labelText: 'Model no',
                        controller: _modelNoController,
                      ),
                      AppFormTextField(
                        labelText: 'Purchase date',
                        controller: _purchaseDateController,
                        hintText: 'YYYY-MM-DD',
                      ),
                      AppFormTextField(
                        labelText: 'Capitalization date',
                        controller: _capitalizationDateController,
                        hintText: 'YYYY-MM-DD',
                      ),
                      AppFormTextField(
                        labelText: 'Put to use date',
                        controller: _putToUseDateController,
                        hintText: 'YYYY-MM-DD',
                      ),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Supplier',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _supplierPartyId,
                        items: _parties
                            .where((party) => party.id != null)
                            .map(
                              (party) => DropdownMenuItem<int>(
                                value: party.id,
                                child: Text(party.toString()),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: _saving || _actionBusy
                            ? null
                            : (value) =>
                                  setState(() => _supplierPartyId = value),
                      ),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Cost center',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _costCenterId,
                        items: _costCenterOptions
                            .where((costCenter) => costCenter.id != null)
                            .map(
                              (costCenter) => DropdownMenuItem<int>(
                                value: costCenter.id,
                                child: Text(costCenter.toString()),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: _saving || _actionBusy
                            ? null
                            : (value) => setState(() => _costCenterId = value),
                      ),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Warehouse',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _warehouseId,
                        items: _warehouseOptions
                            .where((warehouse) => warehouse.id != null)
                            .map(
                              (warehouse) => DropdownMenuItem<int>(
                                value: warehouse.id,
                                child: Text(warehouse.toString()),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: _saving || _actionBusy
                            ? null
                            : (value) => setState(() => _warehouseId = value),
                      ),
                      AppFormTextField(
                        labelText: 'Department',
                        controller: _departmentController,
                      ),
                      AppFormTextField(
                        labelText: 'Employee',
                        controller: _employeeController,
                      ),
                      AppFormTextField(
                        labelText: 'Acquisition cost',
                        controller: _acquisitionCostController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      AppFormTextField(
                        labelText: 'Additional cost',
                        controller: _additionalCostController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      AppFormTextField(
                        labelText: 'Capitalization value',
                        controller: _capitalizationValueController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      AppFormTextField(
                        labelText: 'Salvage value',
                        controller: _salvageValueController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      AppFormTextField(
                        labelText: 'Condition status',
                        controller: _conditionStatusController,
                        hintText: 'good, fair, damaged',
                      ),
                      AppFormTextField(
                        labelText: 'Warranty start',
                        controller: _warrantyStartController,
                        hintText: 'YYYY-MM-DD',
                      ),
                      AppFormTextField(
                        labelText: 'Warranty end',
                        controller: _warrantyEndController,
                        hintText: 'YYYY-MM-DD',
                      ),
                      AppFormTextField(
                        labelText: 'Notes',
                        controller: _notesController,
                        maxLines: 3,
                      ),
                    ],
                  ),
                  SwitchListTile(
                    title: const Text('Depreciable'),
                    value: _isDepreciable,
                    onChanged: _saving || _actionBusy
                        ? null
                        : (value) => setState(() => _isDepreciable = value),
                  ),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: _isActive,
                    onChanged: _saving || _actionBusy
                        ? null
                        : (value) => setState(() => _isActive = value),
                  ),
                  const SizedBox(height: AppUiConstants.spacingMd),
                  Wrap(
                    spacing: AppUiConstants.spacingSm,
                    runSpacing: AppUiConstants.spacingSm,
                    children: [
                      AppActionButton(
                        icon: Icons.save_outlined,
                        label: _selected == null ? 'Save' : 'Update',
                        busy: _saving,
                        onPressed: _actionBusy ? null : _save,
                      ),
                      if (_selected != null)
                        AppActionButton(
                          icon: Icons.flash_on_outlined,
                          label: 'Activate',
                          filled: false,
                          onPressed: _saving || _actionBusy
                              ? null
                              : () => _runAction(
                                  () => _assets.activateAsset(
                                    intValue(_detail!.toJson(), 'id')!,
                                    const AssetModel(<String, dynamic>{}),
                                  ),
                                  'Asset updated.',
                                ),
                        ),
                      if (_selected != null)
                        AppActionButton(
                          icon: Icons.menu_book_outlined,
                          label: 'Books',
                          filled: false,
                          onPressed: _saving || _actionBusy ? null : _openBooks,
                        ),
                      if (_selected != null)
                        AppActionButton(
                          icon: Icons.delete_outline,
                          label: 'Delete',
                          filled: false,
                          onPressed: _saving || _actionBusy ? null : _delete,
                        ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _AssetBooksDialog extends StatefulWidget {
  const _AssetBooksDialog({required this.assetId});

  final int assetId;

  @override
  State<_AssetBooksDialog> createState() => _AssetBooksDialogState();
}

class _AssetBooksDialogState extends State<_AssetBooksDialog> {
  final AssetsService _assets = AssetsService();
  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<AssetBookModel> _books = const <AssetBookModel>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _assets.assetBooks(
        widget.assetId,
        filters: const {'per_page': 100},
      );
      setState(() {
        _books = response.data ?? const <AssetBookModel>[];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _deleteBook(int bookId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete asset book'),
        content: const Text('Delete this book for the asset?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      final response = await _assets.deleteAssetBook(widget.assetId, bookId);
      if (!mounted) {
        return;
      }
      if (response.success != true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
        return;
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Books - asset #${widget.assetId}'),
      content: SizedBox(
        width: 480,
        height: 360,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Text(_error!)
            : _busy
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _books.length,
                itemBuilder: (context, index) {
                  final book = _books[index].toJson();
                  final id = intValue(book, 'id');
                  final type = stringValue(book, 'book_type');
                  final nbv = book['net_book_value']?.toString() ?? '';
                  return ListTile(
                    title: Text(type.isEmpty ? 'Book' : type),
                    subtitle: Text('NBV: $nbv'),
                    trailing: id == null
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteBook(id),
                          ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(onPressed: _load, child: const Text('Refresh')),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
