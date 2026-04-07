import '../../../screen.dart';

class ItemManagementPage extends StatefulWidget {
  const ItemManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ItemManagementPage> createState() => _ItemManagementPageState();
}

class _ItemManagementPageState extends State<ItemManagementPage> {
  static const List<AppDropdownItem<String>> _itemTypeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'stock', label: 'Stock'),
        AppDropdownItem(value: 'service', label: 'Service'),
        AppDropdownItem(value: 'manufactured', label: 'Manufactured'),
        AppDropdownItem(value: 'trade', label: 'Trade'),
        AppDropdownItem(value: 'raw_material', label: 'Raw Material'),
        AppDropdownItem(value: 'semi_finished', label: 'Semi Finished'),
        AppDropdownItem(value: 'finished_goods', label: 'Finished Goods'),
        AppDropdownItem(value: 'consumable', label: 'Consumable'),
        AppDropdownItem(value: 'asset', label: 'Asset'),
        AppDropdownItem(value: 'non_stock', label: 'Non Stock'),
      ];

  final InventoryService _inventoryService = InventoryService();
  final MasterService _masterService = MasterService();
  final MediaService _mediaService = MediaService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _localNameController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _hsnController = TextEditingController();
  final TextEditingController _standardCostController = TextEditingController();
  final TextEditingController _standardSellingPriceController =
      TextEditingController();
  final TextEditingController _mrpController = TextEditingController();
  final TextEditingController _minStockController = TextEditingController();
  final TextEditingController _reorderLevelController = TextEditingController();
  final TextEditingController _reorderQtyController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _volumeController = TextEditingController();
  final TextEditingController _imagePathController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  bool _uploadingImage = false;
  String? _pageError;
  String? _formError;
  List<ItemModel> _items = const <ItemModel>[];
  List<ItemModel> _filteredItems = const <ItemModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<ItemCategoryModel> _categories = const <ItemCategoryModel>[];
  List<BrandModel> _brands = const <BrandModel>[];
  List<UomModel> _uoms = const <UomModel>[];
  List<TaxCodeModel> _taxCodes = const <TaxCodeModel>[];
  ItemModel? _selectedItem;
  int? _companyId;
  int? _categoryId;
  int? _brandId;
  int? _baseUomId;
  int? _purchaseUomId;
  int? _salesUomId;
  int? _taxCodeId;
  String _itemType = 'stock';
  bool _hasBatch = false;
  bool _hasSerial = false;
  bool _hasExpiry = false;
  bool _trackInventory = false;
  bool _isSaleable = true;
  bool _isPurchaseable = true;
  bool _isManufacturable = false;
  bool _isJobworkApplicable = false;
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
    _localNameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _hsnController.dispose();
    _standardCostController.dispose();
    _standardSellingPriceController.dispose();
    _mrpController.dispose();
    _minStockController.dispose();
    _reorderLevelController.dispose();
    _reorderQtyController.dispose();
    _weightController.dispose();
    _volumeController.dispose();
    _imagePathController.dispose();
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
        _inventoryService.items(
          filters: const {'per_page': 200, 'sort_by': 'item_name'},
        ),
        _masterService.companies(filters: const {'per_page': 200}),
        _inventoryService.itemCategories(
          filters: const {'per_page': 200, 'sort_by': 'category_name'},
        ),
        _inventoryService.brands(
          filters: const {'per_page': 200, 'sort_by': 'brand_name'},
        ),
        _inventoryService.uoms(
          filters: const {'per_page': 200, 'sort_by': 'uom_name'},
        ),
        _inventoryService.taxCodes(
          filters: const {'per_page': 200, 'sort_by': 'tax_name'},
        ),
      ]);

      final items =
          (responses[0] as PaginatedResponse<ItemModel>).data ??
          const <ItemModel>[];
      final companies =
          (responses[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final categories =
          (responses[2] as PaginatedResponse<ItemCategoryModel>).data ??
          const <ItemCategoryModel>[];
      final brands =
          (responses[3] as PaginatedResponse<BrandModel>).data ??
          const <BrandModel>[];
      final uoms =
          (responses[4] as PaginatedResponse<UomModel>).data ??
          const <UomModel>[];
      final taxCodes =
          (responses[5] as PaginatedResponse<TaxCodeModel>).data ??
          const <TaxCodeModel>[];

      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
        _companies = companies.where((company) => company.isActive).toList();
        _categories = categories
            .where((category) => category.isActive)
            .toList();
        _brands = brands.where((brand) => brand.isActive).toList();
        _uoms = uoms.where((uom) => uom.isActive).toList();
        _taxCodes = taxCodes.where((tax) => tax.isActive).toList();
        _filteredItems = _filterItems(items, _searchController.text);
        _initialLoading = false;
      });

      final selected = selectId != null
          ? items.cast<ItemModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedItem == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<ItemModel?>().firstWhere(
                    (item) => item?.id == _selectedItem?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected != null) {
        _selectItem(selected);
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

  List<ItemModel> _filterItems(List<ItemModel> source, String query) {
    return filterMasterList(source, query, (item) {
      return [
        item.itemCode,
        item.itemName,
        item.itemType ?? '',
        item.sku ?? '',
      ];
    });
  }

  void _applySearch() {
    setState(() {
      _filteredItems = _filterItems(_items, _searchController.text);
    });
  }

  void _selectItem(ItemModel item) {
    _selectedItem = item;
    _companyId = item.companyId;
    _categoryId = item.categoryId;
    _brandId = item.brandId;
    _baseUomId = item.baseUomId;
    _purchaseUomId = item.purchaseUomId;
    _salesUomId = item.salesUomId;
    _taxCodeId = item.taxCodeId;
    _itemType = item.itemType ?? 'stock';
    _codeController.text = item.itemCode;
    _nameController.text = item.itemName;
    _localNameController.text = item.itemNameLocal ?? '';
    _skuController.text = item.sku ?? '';
    _barcodeController.text = item.barcode ?? '';
    _hsnController.text = item.hsnSacCode ?? '';
    _standardCostController.text = item.standardCost?.toString() ?? '';
    _standardSellingPriceController.text =
        item.standardSellingPrice?.toString() ?? '';
    _mrpController.text = item.mrp?.toString() ?? '';
    _minStockController.text = item.minStockLevel?.toString() ?? '';
    _reorderLevelController.text = item.reorderLevel?.toString() ?? '';
    _reorderQtyController.text = item.reorderQty?.toString() ?? '';
    _weightController.text = item.weight?.toString() ?? '';
    _volumeController.text = item.volume?.toString() ?? '';
    _imagePathController.text = item.imagePath ?? '';
    _remarksController.text = item.remarks ?? '';
    _hasBatch = item.hasBatch;
    _hasSerial = item.hasSerial;
    _hasExpiry = item.hasExpiry;
    _trackInventory = item.trackInventory;
    _isSaleable = item.isSaleable;
    _isPurchaseable = item.isPurchaseable;
    _isManufacturable = item.isManufacturable;
    _isJobworkApplicable = item.isJobworkApplicable;
    _isActive = item.isActive;
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedItem = null;
    _companyId = _companies.isNotEmpty ? _companies.first.id : null;
    _categoryId = null;
    _brandId = null;
    _baseUomId = _uoms.isNotEmpty ? _uoms.first.id : null;
    _purchaseUomId = null;
    _salesUomId = null;
    _taxCodeId = null;
    _itemType = 'stock';
    _codeController.clear();
    _nameController.clear();
    _localNameController.clear();
    _skuController.clear();
    _barcodeController.clear();
    _hsnController.clear();
    _standardCostController.clear();
    _standardSellingPriceController.clear();
    _mrpController.clear();
    _minStockController.clear();
    _reorderLevelController.clear();
    _reorderQtyController.clear();
    _weightController.clear();
    _volumeController.clear();
    _imagePathController.clear();
    _remarksController.clear();
    _hasBatch = false;
    _hasSerial = false;
    _hasExpiry = false;
    _trackInventory = false;
    _isSaleable = true;
    _isPurchaseable = true;
    _isManufacturable = false;
    _isJobworkApplicable = false;
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

    final model = ItemModel(
      id: _selectedItem?.id,
      companyId: _companyId,
      itemCode: _codeController.text.trim(),
      itemName: _nameController.text.trim(),
      itemNameLocal: nullIfEmpty(_localNameController.text),
      itemType: _itemType,
      categoryId: _categoryId,
      brandId: _brandId,
      baseUomId: _baseUomId,
      purchaseUomId: _purchaseUomId,
      salesUomId: _salesUomId,
      taxCodeId: _taxCodeId,
      sku: nullIfEmpty(_skuController.text),
      barcode: nullIfEmpty(_barcodeController.text),
      hsnSacCode: nullIfEmpty(_hsnController.text),
      standardCost: double.tryParse(_standardCostController.text.trim()),
      standardSellingPrice: double.tryParse(
        _standardSellingPriceController.text.trim(),
      ),
      mrp: double.tryParse(_mrpController.text.trim()),
      minStockLevel: double.tryParse(_minStockController.text.trim()),
      reorderLevel: double.tryParse(_reorderLevelController.text.trim()),
      reorderQty: double.tryParse(_reorderQtyController.text.trim()),
      weight: double.tryParse(_weightController.text.trim()),
      volume: double.tryParse(_volumeController.text.trim()),
      imagePath: nullIfEmpty(_imagePathController.text),
      hasBatch: _hasBatch,
      hasSerial: _hasSerial,
      hasExpiry: _hasExpiry,
      trackInventory: _trackInventory,
      isSaleable: _isSaleable,
      isPurchaseable: _isPurchaseable,
      isManufacturable: _isManufacturable,
      isJobworkApplicable: _isJobworkApplicable,
      isActive: _isActive,
      remarks: nullIfEmpty(_remarksController.text),
    );

    try {
      final response = _selectedItem == null
          ? await _inventoryService.createItem(model)
          : await _inventoryService.updateItem(_selectedItem!.id!, model);
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
    final id = _selectedItem?.id;
    if (id == null) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final response = await _inventoryService.deleteItem(id);
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

  void _startNew() {
    _resetForm();
    if (!Responsive.isDesktop(context)) {
      _workspaceController.openEditor();
    }
  }

  Future<void> _uploadItemImage() async {
    final pathController = TextEditingController();

    final selectedPath = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Upload Item Image'),
          content: TextField(
            controller: pathController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Local File Path',
              hintText: '/Users/name/Pictures/item.png',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(pathController.text.trim()),
              child: const Text('Upload'),
            ),
          ],
        );
      },
    );

    if (!mounted || selectedPath == null || selectedPath.isEmpty) {
      return;
    }

    setState(() {
      _uploadingImage = true;
      _formError = null;
    });

    try {
      final response = await _mediaService.uploadFile(
        filePath: selectedPath,
        module: 'inventory',
        documentType: 'items',
        documentId: _selectedItem?.id,
        purpose: 'item_image',
        folder: 'inventory/items',
        isPublic: true,
      );

      final uploaded = response.data;
      if (uploaded == null) {
        setState(() {
          _formError = response.message;
        });
        return;
      }

      _imagePathController.text = uploaded.filePath;
      setState(() {});
    } catch (error) {
      setState(() {
        _formError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _uploadingImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _startNew,
        icon: Icons.inventory_2_outlined,
        label: 'New Item',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Items',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading items...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load items',
        message: _pageError!,
        onRetry: _loadData,
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Items',
      editorTitle: _selectedItem?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<ItemModel>(
        searchController: _searchController,
        searchHint: 'Search items',
        items: _filteredItems,
        selectedItem: _selectedItem,
        emptyMessage: 'No item records found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.itemName,
          subtitle: [
            item.itemCode,
            item.itemType ?? '',
          ].where((value) => value.trim().isNotEmpty).join(' · '),
          selected: selected,
          onTap: () => _selectItem(item),
          trailing: SettingsStatusPill(
            label: item.isActive ? 'Active' : 'Inactive',
            active: item.isActive,
          ),
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
                    onChanged: (value) => setState(() => _companyId = value),
                    validator: Validators.requiredSelection('Company'),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _itemType,
                    decoration: const InputDecoration(labelText: 'Item Type'),
                    items: _itemTypeItems
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item.value,
                            child: Text(item.label),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) =>
                        setState(() => _itemType = value ?? 'stock'),
                  ),
                  AppFormTextField(
                    labelText: 'Item Code',
                    controller: _codeController,
                    validator: Validators.compose([
                      Validators.required('Item code'),
                      Validators.optionalMaxLength(50, 'Item code'),
                    ]),
                  ),
                  AppFormTextField(
                    labelText: 'Item Name',
                    controller: _nameController,
                    validator: Validators.compose([
                      Validators.required('Item name'),
                      Validators.optionalMaxLength(255, 'Item name'),
                    ]),
                  ),
                  AppFormTextField(
                    labelText: 'Local Name',
                    controller: _localNameController,
                    validator: Validators.optionalMaxLength(255, 'Local name'),
                  ),
                  DropdownButtonFormField<int?>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: <DropdownMenuItem<int?>>[
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('None'),
                      ),
                      ..._categories.map(
                        (category) => DropdownMenuItem<int?>(
                          value: category.id,
                          child: Text(category.toString()),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _categoryId = value),
                  ),
                  DropdownButtonFormField<int?>(
                    initialValue: _brandId,
                    decoration: const InputDecoration(labelText: 'Brand'),
                    items: <DropdownMenuItem<int?>>[
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('None'),
                      ),
                      ..._brands.map(
                        (brand) => DropdownMenuItem<int?>(
                          value: brand.id,
                          child: Text(brand.toString()),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _brandId = value),
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: _baseUomId,
                    decoration: const InputDecoration(labelText: 'Base UOM'),
                    items: _uoms
                        .where((uom) => uom.id != null)
                        .map(
                          (uom) => DropdownMenuItem<int>(
                            value: uom.id,
                            child: Text(uom.toString()),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) => setState(() => _baseUomId = value),
                    validator: Validators.requiredSelection('Base UOM'),
                  ),
                  DropdownButtonFormField<int?>(
                    initialValue: _purchaseUomId,
                    decoration: const InputDecoration(
                      labelText: 'Purchase UOM',
                    ),
                    items: <DropdownMenuItem<int?>>[
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('None'),
                      ),
                      ..._uoms.map(
                        (uom) => DropdownMenuItem<int?>(
                          value: uom.id,
                          child: Text(uom.toString()),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _purchaseUomId = value),
                  ),
                  DropdownButtonFormField<int?>(
                    initialValue: _salesUomId,
                    decoration: const InputDecoration(labelText: 'Sales UOM'),
                    items: <DropdownMenuItem<int?>>[
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('None'),
                      ),
                      ..._uoms.map(
                        (uom) => DropdownMenuItem<int?>(
                          value: uom.id,
                          child: Text(uom.toString()),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _salesUomId = value),
                  ),
                  DropdownButtonFormField<int?>(
                    initialValue: _taxCodeId,
                    decoration: const InputDecoration(labelText: 'Tax Code'),
                    items: <DropdownMenuItem<int?>>[
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('None'),
                      ),
                      ..._taxCodes.map(
                        (taxCode) => DropdownMenuItem<int?>(
                          value: taxCode.id,
                          child: Text(taxCode.toString()),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _taxCodeId = value),
                  ),
                  AppFormTextField(
                    labelText: 'SKU',
                    controller: _skuController,
                    validator: Validators.optionalMaxLength(100, 'SKU'),
                  ),
                  AppFormTextField(
                    labelText: 'Barcode',
                    controller: _barcodeController,
                    validator: Validators.optionalMaxLength(100, 'Barcode'),
                  ),
                  AppFormTextField(
                    labelText: 'HSN / SAC',
                    controller: _hsnController,
                    validator: Validators.optionalMaxLength(20, 'HSN / SAC'),
                  ),
                  AppFormTextField(
                    labelText: 'Standard Cost',
                    controller: _standardCostController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: Validators.optionalNonNegativeNumber(
                      'Standard Cost',
                    ),
                  ),
                  AppFormTextField(
                    labelText: 'Standard Selling Price',
                    controller: _standardSellingPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: Validators.optionalNonNegativeNumber(
                      'Standard Selling Price',
                    ),
                  ),
                  AppFormTextField(
                    labelText: 'MRP',
                    controller: _mrpController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: Validators.optionalNonNegativeNumber('MRP'),
                  ),
                  AppFormTextField(
                    labelText: 'Minimum Stock Level',
                    controller: _minStockController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: Validators.optionalNonNegativeNumber(
                      'Minimum Stock Level',
                    ),
                  ),
                  AppFormTextField(
                    labelText: 'Reorder Level',
                    controller: _reorderLevelController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: Validators.optionalNonNegativeNumber(
                      'Reorder Level',
                    ),
                  ),
                  AppFormTextField(
                    labelText: 'Reorder Quantity',
                    controller: _reorderQtyController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: Validators.optionalNonNegativeNumber(
                      'Reorder Quantity',
                    ),
                  ),
                  AppFormTextField(
                    labelText: 'Weight',
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: Validators.optionalNonNegativeNumber('Weight'),
                  ),
                  AppFormTextField(
                    labelText: 'Volume',
                    controller: _volumeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: Validators.optionalNonNegativeNumber('Volume'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              UploadPathField(
                controller: _imagePathController,
                labelText: 'Image Path',
                isUploading: _uploadingImage,
                onUpload: _uploadItemImage,
                previewUrl: AppConfig.resolvePublicFileUrl(
                  _imagePathController.text,
                ),
                previewIcon: Icons.inventory_2_outlined,
              ),
              const SizedBox(height: 16),
              AppFormTextField(
                labelText: 'Remarks',
                controller: _remarksController,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 280,
                    child: AppSwitchTile(
                      label: 'Track Inventory',
                      value: _trackInventory,
                      onChanged: (value) =>
                          setState(() => _trackInventory = value),
                    ),
                  ),
                  SizedBox(
                    width: 280,
                    child: AppSwitchTile(
                      label: 'Saleable',
                      value: _isSaleable,
                      onChanged: (value) => setState(() => _isSaleable = value),
                    ),
                  ),
                  SizedBox(
                    width: 280,
                    child: AppSwitchTile(
                      label: 'Purchaseable',
                      value: _isPurchaseable,
                      onChanged: (value) =>
                          setState(() => _isPurchaseable = value),
                    ),
                  ),
                  SizedBox(
                    width: 280,
                    child: AppSwitchTile(
                      label: 'Manufacturable',
                      value: _isManufacturable,
                      onChanged: (value) =>
                          setState(() => _isManufacturable = value),
                    ),
                  ),
                  SizedBox(
                    width: 280,
                    child: AppSwitchTile(
                      label: 'Jobwork Applicable',
                      value: _isJobworkApplicable,
                      onChanged: (value) =>
                          setState(() => _isJobworkApplicable = value),
                    ),
                  ),
                  SizedBox(
                    width: 280,
                    child: AppSwitchTile(
                      label: 'Batch Enabled',
                      value: _hasBatch,
                      onChanged: (value) => setState(() => _hasBatch = value),
                    ),
                  ),
                  SizedBox(
                    width: 280,
                    child: AppSwitchTile(
                      label: 'Serial Enabled',
                      value: _hasSerial,
                      onChanged: (value) => setState(() => _hasSerial = value),
                    ),
                  ),
                  SizedBox(
                    width: 280,
                    child: AppSwitchTile(
                      label: 'Expiry Enabled',
                      value: _hasExpiry,
                      onChanged: (value) => setState(() => _hasExpiry = value),
                    ),
                  ),
                  SizedBox(
                    width: 280,
                    child: AppSwitchTile(
                      label: 'Active',
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
                    label: _selectedItem == null ? 'Save Item' : 'Update Item',
                    onPressed: _save,
                    busy: _saving,
                  ),
                  if (_selectedItem?.id != null)
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
      ),
    );
  }
}
