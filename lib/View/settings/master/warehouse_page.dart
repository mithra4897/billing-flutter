import '../../../screen.dart';

class WarehouseManagementPage extends StatefulWidget {
  const WarehouseManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<WarehouseManagementPage> createState() =>
      _WarehouseManagementPageState();
}

class _WarehouseManagementPageState extends State<WarehouseManagementPage> {
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<WarehouseModel> _warehouses = const <WarehouseModel>[];
  List<WarehouseModel> _filteredWarehouses = const <WarehouseModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<BranchModel> _branches = const <BranchModel>[];
  List<BusinessLocationModel> _locations = const <BusinessLocationModel>[];
  WarehouseModel? _selectedWarehouse;
  int? _companyId;
  int? _branchId;
  int? _locationId;
  int? _parentWarehouseId;
  String _warehouseType = 'main';
  bool _allowNegativeStock = false;
  bool _isSellableStock = true;
  bool _isReservedOnly = false;
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
    _searchController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadData({int? selectId}) async {
    setState(() {
      _initialLoading = _warehouses.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait([
        _masterService.warehouses(
          filters: const {'per_page': 100, 'sort_by': 'name'},
        ),
        _masterService.companies(filters: const {'per_page': 100}),
        _masterService.branches(filters: const {'per_page': 100}),
        _masterService.businessLocations(filters: const {'per_page': 100}),
      ]);

      final warehouses =
          responses[0].data as List<WarehouseModel>? ??
          const <WarehouseModel>[];
      final companies =
          responses[1].data as List<CompanyModel>? ?? const <CompanyModel>[];
      final branches =
          responses[2].data as List<BranchModel>? ?? const <BranchModel>[];
      final locations =
          responses[3].data as List<BusinessLocationModel>? ??
          const <BusinessLocationModel>[];
      if (!mounted) {
        return;
      }

      setState(() {
        _warehouses = warehouses;
        _companies = companies;
        _branches = branches;
        _locations = locations;
        _filteredWarehouses = filterMasterList(
          warehouses,
          _searchController.text,
          (warehouse) {
            return [warehouse.code ?? '', warehouse.name ?? ''];
          },
        );
        _initialLoading = false;
      });

      final selected = selectId != null
          ? warehouses.cast<WarehouseModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedWarehouse == null
                ? (warehouses.isNotEmpty ? warehouses.first : null)
                : warehouses.cast<WarehouseModel?>().firstWhere(
                    (item) => item?.id == _selectedWarehouse?.id,
                    orElse: () =>
                        warehouses.isNotEmpty ? warehouses.first : null,
                  ));

      if (selected != null) {
        _selectWarehouse(selected);
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
      _filteredWarehouses = filterMasterList(
        _warehouses,
        _searchController.text,
        (warehouse) {
          return [warehouse.code ?? '', warehouse.name ?? ''];
        },
      );
    });
  }

  void _selectWarehouse(WarehouseModel warehouse) {
    _selectedWarehouse = warehouse;
    _companyId = warehouse.companyId;
    _branchId = warehouse.branchId;
    _locationId = warehouse.locationId;
    _parentWarehouseId = warehouse.parentWarehouseId;
    _codeController.text = warehouse.code ?? '';
    _nameController.text = warehouse.name ?? '';
    _warehouseType = warehouse.warehouseType ?? 'main';
    _allowNegativeStock = warehouse.allowNegativeStock;
    _isSellableStock = warehouse.isSellableStock;
    _isReservedOnly = warehouse.isReservedOnly;
    _isDefault = warehouse.isDefault;
    _isActive = warehouse.isActive;
    _remarksController.text = warehouse.remarks ?? '';
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedWarehouse = null;
    _companyId = _companies.isNotEmpty ? _companies.first.id : null;
    final branches = branchesForCompany(_branches, _companyId);
    _branchId = branches.isNotEmpty ? branches.first.id : null;
    final locations = locationsForBranch(_locations, _branchId);
    _locationId = locations.isNotEmpty ? locations.first.id : null;
    _parentWarehouseId = null;
    _codeController.clear();
    _nameController.clear();
    _warehouseType = 'main';
    _allowNegativeStock = false;
    _isSellableStock = true;
    _isReservedOnly = false;
    _isDefault = false;
    _isActive = true;
    _remarksController.clear();
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

    final model = WarehouseModel(
      id: _selectedWarehouse?.id,
      companyId: _companyId,
      branchId: _branchId,
      locationId: _locationId,
      code: _codeController.text.trim(),
      name: _nameController.text.trim(),
      warehouseType: _warehouseType,
      parentWarehouseId: _parentWarehouseId,
      allowNegativeStock: _allowNegativeStock,
      isSellableStock: _isSellableStock,
      isReservedOnly: _isReservedOnly,
      isDefault: _isDefault,
      isActive: _isActive,
      remarks: nullIfEmpty(_remarksController.text),
    );

    try {
      final response = _selectedWarehouse == null
          ? await _masterService.createWarehouse(model)
          : await _masterService.updateWarehouse(
              _selectedWarehouse!.id!,
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
      await _loadData(selectId: saved.id);
    } catch (error) {
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    final actions = [
      AdaptiveShellActionButton(
        onPressed: _resetForm,
        icon: Icons.add_home_work_outlined,
        label: 'New Warehouse',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Warehouses',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading warehouses...');
    }
    if (_pageError != null) {
      return Center(child: Text(_pageError!));
    }

    final branches = branchesForCompany(_branches, _companyId);
    final locations = locationsForBranch(_locations, _branchId);
    final parentOptions = _warehouses
        .where(
          (item) =>
              item.locationId == _locationId &&
              item.id != _selectedWarehouse?.id,
        )
        .toList(growable: false);

    return SettingsWorkspace(
      scrollController: _pageScrollController,
      list: SettingsListCard<WarehouseModel>(
        searchController: _searchController,
        searchHint: 'Search warehouses',
        items: _filteredWarehouses,
        selectedItem: _selectedWarehouse,
        emptyMessage: 'No warehouses found.',
        itemBuilder: (warehouse, selected) => SettingsListTile(
          title: warehouse.name ?? '',
          subtitle: [
            warehouse.code ?? '',
            locationNameById(_locations, warehouse.locationId),
            warehouse.warehouseType?.replaceAll('_', ' ') ?? '',
          ].where((item) => item.isNotEmpty).join(' • '),
          selected: selected,
          trailing: SettingsStatusPill(
            label: warehouse.isActive ? 'Active' : 'Inactive',
            active: warehouse.isActive,
          ),
          onTap: () => _selectWarehouse(warehouse),
        ),
      ),
      editor: SettingsEditorCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsFormWrap(
                children: [
                  AppDropdownField<int>(
                    initialValue: _companyId,
                    labelText: 'Company',
                    items: _companies
                        .map(
                          (company) => DropdownMenuItem<int>(
                            value: company.id,
                            child: Text(company.legalName ?? ''),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      setState(() {
                        _companyId = value;
                        final branches = branchesForCompany(_branches, value);
                        _branchId = branches.isNotEmpty
                            ? branches.first.id
                            : null;
                        final locations = locationsForBranch(
                          _locations,
                          _branchId,
                        );
                        _locationId = locations.isNotEmpty
                            ? locations.first.id
                            : null;
                        _parentWarehouseId = null;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Company is required' : null,
                  ),
                  AppDropdownField<int>(
                    initialValue: _branchId,
                    labelText: 'Branch',
                    items: branches
                        .map(
                          (branch) => DropdownMenuItem<int>(
                            value: branch.id,
                            child: Text(branch.name ?? ''),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      setState(() {
                        _branchId = value;
                        final locations = locationsForBranch(_locations, value);
                        _locationId = locations.isNotEmpty
                            ? locations.first.id
                            : null;
                        _parentWarehouseId = null;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Branch is required' : null,
                  ),
                  AppDropdownField<int>(
                    initialValue: _locationId,
                    labelText: 'Business Location',
                    items: locations
                        .map(
                          (location) => DropdownMenuItem<int>(
                            value: location.id,
                            child: Text(location.name ?? ''),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      setState(() {
                        _locationId = value;
                        _parentWarehouseId = null;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Location is required' : null,
                  ),
                  AppFormTextField(
                    controller: _codeController,
                    labelText: 'Code',
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Code is required'
                        : null,
                  ),
                  AppFormTextField(
                    controller: _nameController,
                    labelText: 'Name',
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                  AppDropdownField<String>.fromMapped(
                    initialValue: _warehouseType,
                    labelText: 'Warehouse Type',
                    mappedItems: const [
                      AppDropdownItem(value: 'main', label: 'Main'),
                      AppDropdownItem(
                        value: 'raw_material',
                        label: 'Raw Material',
                      ),
                      AppDropdownItem(
                        value: 'finished_goods',
                        label: 'Finished Goods',
                      ),
                      AppDropdownItem(value: 'wip', label: 'WIP'),
                      AppDropdownItem(value: 'damage', label: 'Damage'),
                      AppDropdownItem(value: 'returns', label: 'Returns'),
                      AppDropdownItem(value: 'transit', label: 'Transit'),
                      AppDropdownItem(value: 'jobwork', label: 'Jobwork'),
                      AppDropdownItem(value: 'other', label: 'Other'),
                    ],
                    onChanged: (value) => setState(
                      () => _warehouseType = value ?? _warehouseType,
                    ),
                  ),
                  AppDropdownField<int?>.fromMapped(
                    initialValue: _parentWarehouseId,
                    labelText: 'Parent Warehouse',
                    mappedItems: [
                      const AppDropdownItem<int?>(value: null, label: 'None'),
                      ...parentOptions.map(
                        (warehouse) => AppDropdownItem<int?>(
                          value: warehouse.id,
                          label: warehouse.name ?? '',
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _parentWarehouseId = value),
                  ),
                ],
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  AppToggleChip(
                    label: 'Allow Negative',
                    value: _allowNegativeStock,
                    onChanged: (value) =>
                        setState(() => _allowNegativeStock = value),
                  ),
                  AppToggleChip(
                    label: 'Sellable',
                    value: _isSellableStock,
                    onChanged: (value) =>
                        setState(() => _isSellableStock = value),
                  ),
                  AppToggleChip(
                    label: 'Reserved Only',
                    value: _isReservedOnly,
                    onChanged: (value) =>
                        setState(() => _isReservedOnly = value),
                  ),
                ],
              ),
              AppSwitchTile(
                label: 'Default Warehouse',
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value),
              ),
              AppSwitchTile(
                label: 'Active',
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              AppFormTextField(
                controller: _remarksController,
                maxLines: 3,
                labelText: 'Remarks',
              ),
              if ((_formError ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _formError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [
                  AppActionButton(
                    onPressed: _saving ? null : _save,
                    icon: _selectedWarehouse == null ? Icons.add : Icons.save,
                    label: _saving ? 'Saving...' : 'Save Warehouse',
                    busy: _saving,
                  ),
                  AppActionButton(
                    onPressed: _saving ? null : _resetForm,
                    icon: Icons.refresh,
                    label: 'Reset',
                    filled: false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
