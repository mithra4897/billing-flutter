import '../../../screen.dart';

class PhysicalStockCountPage extends StatefulWidget {
  const PhysicalStockCountPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PhysicalStockCountPage> createState() => _PhysicalStockCountPageState();
}

class _PhysicalStockCountPageState extends State<PhysicalStockCountPage> {
  static const List<AppDropdownItem<String>> _scopeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'selected_items', label: 'Selected Items'),
        AppDropdownItem(value: 'full_warehouse', label: 'Full Warehouse'),
        AppDropdownItem(value: 'category', label: 'Category'),
        AppDropdownItem(value: 'batch', label: 'Batch'),
        AppDropdownItem(value: 'serial', label: 'Serial'),
      ];

  final InventoryService _inventoryService = InventoryService();
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _countNoController = TextEditingController();
  final TextEditingController _countDateController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<PhysicalStockCountModel> _items = const <PhysicalStockCountModel>[];
  List<PhysicalStockCountModel> _filteredItems =
      const <PhysicalStockCountModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<BranchModel> _branches = const <BranchModel>[];
  List<BusinessLocationModel> _locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> _financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> _documentSeries = const <DocumentSeriesModel>[];
  List<WarehouseModel> _warehouses = const <WarehouseModel>[];
  List<ItemModel> _allItems = const <ItemModel>[];
  List<UomModel> _uoms = const <UomModel>[];
  List<StockBatchModel> _batches = const <StockBatchModel>[];
  List<StockSerialModel> _serials = const <StockSerialModel>[];
  PhysicalStockCountModel? _selectedItem;
  List<PhysicalStockCountLineModel> _lines = <PhysicalStockCountLineModel>[];
  int? _companyId;
  int? _branchId;
  int? _locationId;
  int? _financialYearId;
  int? _documentSeriesId;
  int? _warehouseId;
  String _countScope = 'selected_items';

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
    _countNoController.dispose();
    _countDateController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadData({int? selectId}) async {
    setState(() {
      _initialLoading = _items.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait<dynamic>([
        _inventoryService.physicalStockCounts(
          filters: const {'per_page': 200, 'sort_by': 'count_date'},
        ),
        _masterService.companies(filters: const {'per_page': 200}),
        _masterService.branches(filters: const {'per_page': 200}),
        _masterService.businessLocations(filters: const {'per_page': 200}),
        _masterService.financialYears(filters: const {'per_page': 200}),
        _masterService.documentSeries(filters: const {'per_page': 200}),
        _masterService.warehouses(filters: const {'per_page': 200}),
        _inventoryService.items(
          filters: const {'per_page': 300, 'sort_by': 'item_name'},
        ),
        _inventoryService.uoms(
          filters: const {'per_page': 200, 'sort_by': 'uom_name'},
        ),
        _inventoryService.stockBatchesDropdown(filters: const {}),
        _inventoryService.stockSerialsDropdown(filters: const {}),
      ]);

      final counts =
          (responses[0] as PaginatedResponse<PhysicalStockCountModel>).data ??
          const <PhysicalStockCountModel>[];
      final companies =
          (responses[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final branches =
          (responses[2] as PaginatedResponse<BranchModel>).data ??
          const <BranchModel>[];
      final locations =
          (responses[3] as PaginatedResponse<BusinessLocationModel>).data ??
          const <BusinessLocationModel>[];
      final financialYears =
          (responses[4] as PaginatedResponse<FinancialYearModel>).data ??
          const <FinancialYearModel>[];
      final documentSeries =
          (responses[5] as PaginatedResponse<DocumentSeriesModel>).data ??
          const <DocumentSeriesModel>[];
      final warehouses =
          (responses[6] as PaginatedResponse<WarehouseModel>).data ??
          const <WarehouseModel>[];
      final items =
          (responses[7] as PaginatedResponse<ItemModel>).data ??
          const <ItemModel>[];
      final uoms =
          (responses[8] as PaginatedResponse<UomModel>).data ??
          const <UomModel>[];
      final batches =
          (responses[9] as ApiResponse<List<StockBatchModel>>).data ??
          const <StockBatchModel>[];
      final serials =
          (responses[10] as ApiResponse<List<StockSerialModel>>).data ??
          const <StockSerialModel>[];

      if (!mounted) {
        return;
      }

      setState(() {
        _items = counts;
        _filteredItems = _filterCounts(counts, _searchController.text);
        _companies = companies.where((company) => company.isActive).toList();
        _branches = branches.where((branch) => branch.isActive).toList();
        _locations = locations.where((location) => location.isActive).toList();
        _financialYears = financialYears.where((fy) => fy.isActive).toList();
        _documentSeries = documentSeries
            .where((series) => series.documentType == 'STOCK_COUNT')
            .toList();
        _warehouses = warehouses
            .where((warehouse) => warehouse.isActive)
            .toList();
        _allItems = items.where((item) => item.isActive).toList();
        _uoms = uoms.where((uom) => uom.isActive).toList();
        _batches = batches;
        _serials = serials;
        _initialLoading = false;
      });

      final selected = selectId != null
          ? counts.cast<PhysicalStockCountModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedItem == null
                ? (counts.isNotEmpty ? counts.first : null)
                : counts.cast<PhysicalStockCountModel?>().firstWhere(
                    (item) => item?.id == _selectedItem?.id,
                    orElse: () => counts.isNotEmpty ? counts.first : null,
                  ));

      if (selected != null) {
        _selectCount(selected);
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

  List<PhysicalStockCountModel> _filterCounts(
    List<PhysicalStockCountModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (item) {
      return [
        item.countNo ?? '',
        item.countStatus ?? '',
        item.countScope ?? '',
        item.warehouseName ?? '',
      ];
    });
  }

  void _applySearch() {
    setState(() {
      _filteredItems = _filterCounts(_items, _searchController.text);
    });
  }

  void _selectCount(PhysicalStockCountModel item) {
    _selectedItem = item;
    _companyId = item.companyId;
    _branchId = item.branchId;
    _locationId = item.locationId;
    _financialYearId = item.financialYearId;
    _documentSeriesId = item.documentSeriesId;
    _warehouseId = item.warehouseId;
    _countNoController.text = item.countNo ?? '';
    _countDateController.text =
        item.countDate?.split('T').first.split(' ').first ?? DateTime.now().toIso8601String().split('T').first;
    _remarksController.text = item.remarks ?? '';
    _countScope = item.countScope ?? 'selected_items';
    _lines = item.items.toList(growable: true);
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedItem = null;
    _companyId = _companies.isNotEmpty ? _companies.first.id : null;
    _branchId = _filteredBranchOptions.isNotEmpty
        ? _filteredBranchOptions.first.id
        : null;
    _locationId = _filteredLocationOptions.isNotEmpty
        ? _filteredLocationOptions.first.id
        : null;
    _financialYearId = _filteredFinancialYearOptions.isNotEmpty
        ? _filteredFinancialYearOptions.first.id
        : null;
    _documentSeriesId = _filteredDocumentSeriesOptions.isNotEmpty
        ? _filteredDocumentSeriesOptions.first.id
        : null;
    _warehouseId = _filteredWarehouseOptions.isNotEmpty
        ? _filteredWarehouseOptions.first.id
        : null;
    _countNoController.clear();
    _countDateController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    _remarksController.clear();
    _countScope = 'selected_items';
    _lines = <PhysicalStockCountLineModel>[];
    _formError = null;
    setState(() {});
  }

  List<BranchModel> get _filteredBranchOptions => _branches
      .where((branch) => _companyId == null || branch.companyId == _companyId)
      .toList(growable: false);

  List<BusinessLocationModel> get _filteredLocationOptions => _locations
      .where((location) => _branchId == null || location.branchId == _branchId)
      .toList(growable: false);

  List<FinancialYearModel> get _filteredFinancialYearOptions => _financialYears
      .where((fy) => _companyId == null || fy.companyId == _companyId)
      .toList(growable: false);

  List<DocumentSeriesModel> get _filteredDocumentSeriesOptions =>
      _documentSeries
          .where(
            (series) => _companyId == null || series.companyId == _companyId,
          )
          .toList(growable: false);

  List<WarehouseModel> get _filteredWarehouseOptions => _warehouses
      .where(
        (warehouse) =>
            (_companyId == null || warehouse.companyId == _companyId) &&
            (_branchId == null || warehouse.branchId == _branchId) &&
            (_locationId == null || warehouse.locationId == _locationId),
      )
      .toList(growable: false);

  void _onCompanyChanged(int? value) {
    setState(() {
      _companyId = value;
      _branchId = _filteredBranchOptions.isNotEmpty
          ? _filteredBranchOptions.first.id
          : null;
      _locationId = _filteredLocationOptions.isNotEmpty
          ? _filteredLocationOptions.first.id
          : null;
      _financialYearId = _filteredFinancialYearOptions.isNotEmpty
          ? _filteredFinancialYearOptions.first.id
          : null;
      _documentSeriesId = _filteredDocumentSeriesOptions.isNotEmpty
          ? _filteredDocumentSeriesOptions.first.id
          : null;
      _warehouseId = _filteredWarehouseOptions.isNotEmpty
          ? _filteredWarehouseOptions.first.id
          : null;
    });
  }

  void _onBranchChanged(int? value) {
    setState(() {
      _branchId = value;
      _locationId = _filteredLocationOptions.isNotEmpty
          ? _filteredLocationOptions.first.id
          : null;
      _warehouseId = _filteredWarehouseOptions.isNotEmpty
          ? _filteredWarehouseOptions.first.id
          : null;
    });
  }

  void _onLocationChanged(int? value) {
    setState(() {
      _locationId = value;
      _warehouseId = _filteredWarehouseOptions.isNotEmpty
          ? _filteredWarehouseOptions.first.id
          : null;
    });
  }

  void _addLine() {
    final defaultItem = _allItems.isNotEmpty ? _allItems.first : null;
    final defaultUomId =
        defaultItem?.baseUomId ?? (_uoms.isNotEmpty ? _uoms.first.id : null);
    setState(() {
      _lines = <PhysicalStockCountLineModel>[
        ..._lines,
        PhysicalStockCountLineModel(
          itemId: defaultItem?.id,
          uomId: defaultUomId,
          countedQty: 0,
        ),
      ];
    });
  }

  void _updateLine(int index, PhysicalStockCountLineModel line) {
    setState(() {
      _lines[index] = line;
    });
  }

  void _removeLine(int index) {
    setState(() {
      _lines.removeAt(index);
    });
  }

  List<StockBatchModel> _batchOptionsForItem(int? itemId) {
    return _batches
        .where((batch) {
          final json = batch.toJson();
          return itemId == null ||
              json['item_id']?.toString() == itemId.toString();
        })
        .toList(growable: false);
  }

  List<StockSerialModel> _serialOptionsForItem(int? itemId, int? batchId) {
    return _serials
        .where((serial) {
          final json = serial.toJson();
          final matchesItem =
              itemId == null ||
              json['item_id']?.toString() == itemId.toString();
          final matchesBatch =
              batchId == null ||
              json['batch_id']?.toString() == batchId.toString();
          return matchesItem && matchesBatch;
        })
        .toList(growable: false);
  }

  String _batchLabel(StockBatchModel batch) {
    final json = batch.toJson();
    return json['batch_no']?.toString() ?? 'Batch';
  }

  String _serialLabel(StockSerialModel serial) {
    final json = serial.toJson();
    return json['serial_no']?.toString() ?? 'Serial';
  }

  PhysicalStockCountModel _buildModel() {
    return PhysicalStockCountModel(
      id: _selectedItem?.id,
      companyId: _companyId,
      branchId: _branchId,
      locationId: _locationId,
      financialYearId: _financialYearId,
      documentSeriesId: _documentSeriesId,
      warehouseId: _warehouseId,
      countNo: nullIfEmpty(_countNoController.text),
      countDate: _countDateController.text.trim(),
      countScope: _countScope,
      remarks: nullIfEmpty(_remarksController.text),
      items: _lines,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_lines.isEmpty) {
      setState(() {
        _formError = 'At least one item line is required';
      });
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final model = _buildModel();

    try {
      final response = _selectedItem == null
          ? await _inventoryService.createPhysicalStockCount(model)
          : await _inventoryService.updatePhysicalStockCount(
              _selectedItem!.id!,
              model,
            );
      final saved = response.data;
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData(selectId: saved?.id);
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
    final id = _selectedItem?.id;
    if (id == null) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final response = await _inventoryService.deletePhysicalStockCount(id);
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

  Future<void> _markCounted() async {
    final id = _selectedItem?.id;
    if (id == null) {
      return;
    }
    await _runDocumentAction(
      () => _inventoryService.markPhysicalCounted(id, _buildModel()),
    );
  }

  Future<void> _reconcile() async {
    final id = _selectedItem?.id;
    if (id == null) {
      return;
    }
    await _runDocumentAction(
      () => _inventoryService.reconcilePhysicalStockCount(id, _buildModel()),
    );
  }

  Future<void> _cancel() async {
    final id = _selectedItem?.id;
    if (id == null) {
      return;
    }
    await _runDocumentAction(
      () => _inventoryService.cancelPhysicalStockCount(id, _buildModel()),
    );
  }

  Future<void> _runDocumentAction(
    Future<ApiResponse<PhysicalStockCountModel>> Function() action,
  ) async {
    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final response = await action();
      final saved = response.data;
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData(selectId: saved?.id);
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
        icon: Icons.checklist_rtl_outlined,
        label: 'New Count',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Physical Counts',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading physical counts...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load physical counts',
        message: _pageError!,
        onRetry: _loadData,
      );
    }

    final countStatus = _selectedItem?.countStatus ?? 'draft';

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Physical Counts',
      editorTitle: _selectedItem?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<PhysicalStockCountModel>(
        searchController: _searchController,
        searchHint: 'Search physical counts',
        items: _filteredItems,
        selectedItem: _selectedItem,
        emptyMessage: 'No physical counts found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.countNo ?? '-',
          subtitle: [
            item.countDate ?? '',
            item.countStatus ?? '',
            item.warehouseName ?? '',
          ].where((value) => value.trim().isNotEmpty).join(' · '),
          selected: selected,
          onTap: () => _selectCount(item),
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
                const SizedBox(height: 16),
              ],
              SettingsFormWrap(
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _companyId,
                    decoration: const InputDecoration(labelText: 'Company'),
                    items: _companies
                        .where((company) => company.id != null)
                        .map(
                          (company) => DropdownMenuItem<int>(
                            value: company.id,
                            child: Text(company.toString()),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: _onCompanyChanged,
                    validator: Validators.requiredSelection('Company'),
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: _branchId,
                    decoration: const InputDecoration(labelText: 'Branch'),
                    items: _filteredBranchOptions
                        .where((branch) => branch.id != null)
                        .map(
                          (branch) => DropdownMenuItem<int>(
                            value: branch.id,
                            child: Text(branch.toString()),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: _onBranchChanged,
                    validator: Validators.requiredSelection('Branch'),
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: _locationId,
                    decoration: const InputDecoration(labelText: 'Location'),
                    items: _filteredLocationOptions
                        .where((location) => location.id != null)
                        .map(
                          (location) => DropdownMenuItem<int>(
                            value: location.id,
                            child: Text(location.toString()),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: _onLocationChanged,
                    validator: Validators.requiredSelection('Location'),
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: _financialYearId,
                    decoration: const InputDecoration(
                      labelText: 'Financial Year',
                    ),
                    items: _filteredFinancialYearOptions
                        .map(
                          (fy) => DropdownMenuItem<int>(
                            value: fy.id,
                            child: Text(fy.yearCode),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) =>
                        setState(() => _financialYearId = value),
                    validator: Validators.requiredSelection('Financial Year'),
                  ),
                  DropdownButtonFormField<int?>(
                    initialValue: _documentSeriesId,
                    decoration: const InputDecoration(
                      labelText: 'Document Series',
                    ),
                    items: <DropdownMenuItem<int?>>[
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Auto / None'),
                      ),
                      ..._filteredDocumentSeriesOptions.map(
                        (series) => DropdownMenuItem<int?>(
                          value: series.id,
                          child: Text(series.toString()),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _documentSeriesId = value),
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: _warehouseId,
                    decoration: const InputDecoration(labelText: 'Warehouse'),
                    items: _filteredWarehouseOptions
                        .where((warehouse) => warehouse.id != null)
                        .map(
                          (warehouse) => DropdownMenuItem<int>(
                            value: warehouse.id,
                            child: Text(warehouse.toString()),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) => setState(() => _warehouseId = value),
                    validator: Validators.requiredSelection('Warehouse'),
                  ),
                  AppFormTextField(
                    labelText: 'Count No',
                    controller: _countNoController,
                    validator: Validators.optionalMaxLength(100, 'Count No'),
                  ),
                  AppFormTextField(
                    labelText: 'Count Date',
                    controller: _countDateController,
                    hintText: 'YYYY-MM-DD',
                    validator: Validators.compose([
                      Validators.required('Count Date'),
                      Validators.optionalDate('Count Date'),
                    ]),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _countScope,
                    decoration: const InputDecoration(labelText: 'Count Scope'),
                    items: _scopeItems
                        .map(
                          (scope) => DropdownMenuItem<String>(
                            value: scope.value,
                            child: Text(scope.label),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) =>
                        setState(() => _countScope = value ?? 'selected_items'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppFormTextField(
                labelText: 'Remarks',
                controller: _remarksController,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Item Lines',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  AppActionButton(
                    icon: Icons.add_circle_outline,
                    label: 'Add Line',
                    onPressed: _addLine,
                    filled: false,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_lines.isEmpty)
                const Text('No item lines added yet.')
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _lines.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final line = _lines[index];
                    final batchOptions = _batchOptionsForItem(line.itemId);
                    final serialOptions = _serialOptionsForItem(
                      line.itemId,
                      line.batchId,
                    );
                    final systemController = TextEditingController(
                      text: line.systemQty?.toString() ?? '',
                    );
                    final countedController = TextEditingController(
                      text: line.countedQty?.toString() ?? '',
                    );
                    final costController = TextEditingController(
                      text: line.unitCost?.toString() ?? '',
                    );
                    final remarksController = TextEditingController(
                      text: line.remarks ?? '',
                    );

                    return AppSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Line ${index + 1}'),
                              IconButton(
                                onPressed: () => _removeLine(index),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                          SettingsFormWrap(
                            children: [
                              DropdownButtonFormField<int>(
                                initialValue: line.itemId,
                                decoration: const InputDecoration(
                                  labelText: 'Item',
                                ),
                                items: _allItems
                                    .where((item) => item.id != null)
                                    .map(
                                      (item) => DropdownMenuItem<int>(
                                        value: item.id,
                                        child: Text(item.toString()),
                                      ),
                                    )
                                    .toList(growable: false),
                                onChanged: (value) {
                                  final item = _allItems
                                      .cast<ItemModel?>()
                                      .firstWhere(
                                        (entry) => entry?.id == value,
                                        orElse: () => null,
                                      );
                                  _updateLine(
                                    index,
                                    PhysicalStockCountLineModel(
                                      id: line.id,
                                      itemId: value,
                                      uomId:
                                          item?.baseUomId ??
                                          line.uomId ??
                                          (_uoms.isNotEmpty
                                              ? _uoms.first.id
                                              : null),
                                      countedQty: line.countedQty,
                                      systemQty: line.systemQty,
                                      unitCost: line.unitCost,
                                      remarks: line.remarks,
                                    ),
                                  );
                                },
                              ),
                              DropdownButtonFormField<int>(
                                initialValue: line.uomId,
                                decoration: const InputDecoration(
                                  labelText: 'UOM',
                                ),
                                items: _uoms
                                    .where((uom) => uom.id != null)
                                    .map(
                                      (uom) => DropdownMenuItem<int>(
                                        value: uom.id,
                                        child: Text(uom.toString()),
                                      ),
                                    )
                                    .toList(growable: false),
                                onChanged: (value) => _updateLine(
                                  index,
                                  PhysicalStockCountLineModel(
                                    id: line.id,
                                    itemId: line.itemId,
                                    uomId: value,
                                    batchId: line.batchId,
                                    serialId: line.serialId,
                                    countedQty: line.countedQty,
                                    systemQty: line.systemQty,
                                    unitCost: line.unitCost,
                                    remarks: line.remarks,
                                  ),
                                ),
                              ),
                              DropdownButtonFormField<int?>(
                                initialValue: line.batchId,
                                decoration: const InputDecoration(
                                  labelText: 'Batch',
                                ),
                                items: <DropdownMenuItem<int?>>[
                                  const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text('None'),
                                  ),
                                  ...batchOptions.map(
                                    (batch) => DropdownMenuItem<int?>(
                                      value: int.tryParse(
                                        batch.toJson()['id']?.toString() ?? '',
                                      ),
                                      child: Text(_batchLabel(batch)),
                                    ),
                                  ),
                                ],
                                onChanged: (value) => _updateLine(
                                  index,
                                  PhysicalStockCountLineModel(
                                    id: line.id,
                                    itemId: line.itemId,
                                    uomId: line.uomId,
                                    batchId: value,
                                    serialId: line.serialId,
                                    countedQty: line.countedQty,
                                    systemQty: line.systemQty,
                                    unitCost: line.unitCost,
                                    remarks: line.remarks,
                                  ),
                                ),
                              ),
                              DropdownButtonFormField<int?>(
                                initialValue: line.serialId,
                                decoration: const InputDecoration(
                                  labelText: 'Serial',
                                ),
                                items: <DropdownMenuItem<int?>>[
                                  const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text('None'),
                                  ),
                                  ...serialOptions.map(
                                    (serial) => DropdownMenuItem<int?>(
                                      value: int.tryParse(
                                        serial.toJson()['id']?.toString() ?? '',
                                      ),
                                      child: Text(_serialLabel(serial)),
                                    ),
                                  ),
                                ],
                                onChanged: (value) => _updateLine(
                                  index,
                                  PhysicalStockCountLineModel(
                                    id: line.id,
                                    itemId: line.itemId,
                                    uomId: line.uomId,
                                    batchId: line.batchId,
                                    serialId: value,
                                    countedQty: line.countedQty,
                                    systemQty: line.systemQty,
                                    unitCost: line.unitCost,
                                    remarks: line.remarks,
                                  ),
                                ),
                              ),
                              AppFormTextField(
                                labelText: 'System Qty',
                                controller: systemController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                onChanged: (value) => _updateLine(
                                  index,
                                  PhysicalStockCountLineModel(
                                    id: line.id,
                                    itemId: line.itemId,
                                    uomId: line.uomId,
                                    batchId: line.batchId,
                                    serialId: line.serialId,
                                    countedQty: line.countedQty,
                                    systemQty: double.tryParse(value.trim()),
                                    unitCost: line.unitCost,
                                    remarks: line.remarks,
                                  ),
                                ),
                              ),
                              AppFormTextField(
                                labelText: 'Counted Qty',
                                controller: countedController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                onChanged: (value) => _updateLine(
                                  index,
                                  PhysicalStockCountLineModel(
                                    id: line.id,
                                    itemId: line.itemId,
                                    uomId: line.uomId,
                                    batchId: line.batchId,
                                    serialId: line.serialId,
                                    countedQty: double.tryParse(value.trim()),
                                    systemQty: line.systemQty,
                                    unitCost: line.unitCost,
                                    remarks: line.remarks,
                                  ),
                                ),
                              ),
                              AppFormTextField(
                                labelText: 'Unit Cost',
                                controller: costController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                onChanged: (value) => _updateLine(
                                  index,
                                  PhysicalStockCountLineModel(
                                    id: line.id,
                                    itemId: line.itemId,
                                    uomId: line.uomId,
                                    batchId: line.batchId,
                                    serialId: line.serialId,
                                    countedQty: line.countedQty,
                                    systemQty: line.systemQty,
                                    unitCost: double.tryParse(value.trim()),
                                    remarks: line.remarks,
                                  ),
                                ),
                              ),
                              AppFormTextField(
                                labelText: 'Line Remarks',
                                controller: remarksController,
                                maxLines: 2,
                                onChanged: (value) => _updateLine(
                                  index,
                                  PhysicalStockCountLineModel(
                                    id: line.id,
                                    itemId: line.itemId,
                                    uomId: line.uomId,
                                    batchId: line.batchId,
                                    serialId: line.serialId,
                                    countedQty: line.countedQty,
                                    systemQty: line.systemQty,
                                    unitCost: line.unitCost,
                                    remarks: nullIfEmpty(value),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  AppActionButton(
                    icon: Icons.save_outlined,
                    label: _selectedItem == null
                        ? 'Save Count'
                        : 'Update Count',
                    onPressed: _save,
                    busy: _saving,
                  ),
                  if (_selectedItem?.id != null && countStatus == 'draft')
                    AppActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      onPressed: _saving ? null : _delete,
                      filled: false,
                    ),
                  if (_selectedItem?.id != null && countStatus == 'draft')
                    AppActionButton(
                      icon: Icons.playlist_add_check_outlined,
                      label: 'Mark Counted',
                      onPressed: _saving ? null : _markCounted,
                      filled: false,
                    ),
                  if (_selectedItem?.id != null &&
                      (countStatus == 'draft' || countStatus == 'counted'))
                    AppActionButton(
                      icon: Icons.check_circle_outline,
                      label: 'Reconcile',
                      onPressed: _saving ? null : _reconcile,
                      filled: false,
                    ),
                  if (_selectedItem?.id != null &&
                      countStatus != 'reconciled' &&
                      countStatus != 'cancelled')
                    AppActionButton(
                      icon: Icons.cancel_outlined,
                      label: 'Cancel',
                      onPressed: _saving ? null : _cancel,
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
