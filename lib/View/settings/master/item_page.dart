import '../../../helper/media_upload_helper.dart';
import '../../../screen.dart';
import '../../../model/inventory/opening_stock_model.dart';
import 'item_alternate_page.dart';
import 'item_price_page.dart';
import 'item_supplier_map_page.dart';

class ItemManagementPage extends StatefulWidget {
  const ItemManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ItemManagementPage> createState() => _ItemManagementPageState();
}

class _ItemManagementPageState extends State<ItemManagementPage>
    with SingleTickerProviderStateMixin {
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
  late final TabController _tabController;
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
  bool _itemCodeManuallyEdited = false;
  bool _suppressItemCodeListener = false;
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
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _searchController.addListener(_applySearch);
    _codeController.addListener(_handleItemCodeChanged);
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

  void _handleItemCodeChanged() {
    if (_suppressItemCodeListener) {
      return;
    }

    _itemCodeManuallyEdited = true;
  }

  String _itemTypeCode(String itemType) {
    switch (itemType) {
      case 'service':
        return 'SRV';
      case 'manufactured':
        return 'MFG';
      case 'trade':
        return 'TRD';
      case 'raw_material':
        return 'RAW';
      case 'semi_finished':
        return 'SFG';
      case 'finished_goods':
        return 'FGD';
      case 'consumable':
        return 'CON';
      case 'asset':
        return 'AST';
      case 'non_stock':
        return 'NST';
      case 'stock':
      default:
        return 'STK';
    }
  }

  String _generateItemCode({
    required int? companyId,
    required String itemType,
  }) {
    final prefix = _itemTypeCode(itemType);
    var nextNumber = 1;
    final pattern = RegExp('^${RegExp.escape(prefix)}/(\\d+)\$');

    for (final item in _items) {
      if (companyId != null && item.companyId != companyId) {
        continue;
      }

      final match = pattern.firstMatch(item.itemCode.trim().toUpperCase());
      if (match == null) {
        continue;
      }

      final value = int.tryParse(match.group(1) ?? '');
      if (value != null && value >= nextNumber) {
        nextNumber = value + 1;
      }
    }

    return '$prefix/${nextNumber.toString().padLeft(5, '0')}';
  }

  void _setItemCode(String value, {bool autoGenerated = false}) {
    _suppressItemCodeListener = true;
    _codeController.text = value;
    _suppressItemCodeListener = false;
    _itemCodeManuallyEdited = !autoGenerated;
  }

  void _updateGeneratedItemCodeIfNeeded() {
    if (_selectedItem != null || _itemCodeManuallyEdited) {
      return;
    }

    _setItemCode(
      _generateItemCode(companyId: _companyId, itemType: _itemType),
      autoGenerated: true,
    );
    if (mounted) {
      setState(() {});
    }
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
    _setItemCode(item.itemCode);
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
    _itemCodeManuallyEdited = false;
    _setItemCode(
      _generateItemCode(companyId: _companyId, itemType: _itemType),
      autoGenerated: true,
    );
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
    await MediaUploadHelper.uploadImage(
      context: context,
      mediaService: _mediaService,
      onLoading: (isLoading) {
        if (mounted) setState(() => _uploadingImage = isLoading);
      },
      onSuccess: (filePath) {
        if (mounted) {
          setState(() {
            _imagePathController.text = filePath;
            _formError = null;
          });
        }
      },
      onError: (error) {
        if (mounted) setState(() => _formError = error);
      },
      module: 'inventory',
      documentType: 'items',
      documentId: _selectedItem?.id,
      purpose: 'item_image',
      folder: 'inventory/items',
      isPublic: true,
    );
  }

  String _nextSimpleCode(String prefix, Iterable<String> existingCodes) {
    var nextNumber = 1;
    final pattern = RegExp('^${RegExp.escape(prefix)}/(\\d+)\$');

    for (final code in existingCodes) {
      final match = pattern.firstMatch(code.trim().toUpperCase());
      if (match == null) {
        continue;
      }
      final value = int.tryParse(match.group(1) ?? '');
      if (value != null && value >= nextNumber) {
        nextNumber = value + 1;
      }
    }

    return '$prefix/${nextNumber.toString().padLeft(4, '0')}';
  }

  Future<void> _createCategoryInline() async {
    final codeController = TextEditingController(
      text: _nextSimpleCode(
        'CAT',
        _categories.map((item) => item.categoryCode),
      ),
    );
    final nameController = TextEditingController();

    final created = await showDialog<ItemCategoryModel>(
      context: context,
      builder: (dialogContext) {
        final formKey = GlobalKey<FormState>();
        return AlertDialog(
          title: const Text('Add Category'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppFormTextField(
                    labelText: 'Category Code',
                    controller: codeController,
                    validator: Validators.compose([
                      Validators.required('Category code'),
                      Validators.optionalMaxLength(50, 'Category code'),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  AppFormTextField(
                    labelText: 'Category Name',
                    controller: nameController,
                    validator: Validators.compose([
                      Validators.required('Category name'),
                      Validators.optionalMaxLength(150, 'Category name'),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                try {
                  final response = await _inventoryService.createItemCategory(
                    ItemCategoryModel(
                      categoryCode: codeController.text.trim(),
                      categoryName: nameController.text.trim(),
                    ),
                  );
                  if (!dialogContext.mounted) {
                    return;
                  }
                  Navigator.of(dialogContext).pop(response.data);
                } catch (error) {
                  if (!dialogContext.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(SnackBar(content: Text(error.toString())));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (created == null) {
      return;
    }

    await _loadData(selectId: _selectedItem?.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _categoryId = created.id;
    });
  }

  Future<void> _createBrandInline() async {
    final codeController = TextEditingController(
      text: _nextSimpleCode('BRD', _brands.map((item) => item.brandCode ?? '')),
    );
    final nameController = TextEditingController();

    final created = await showDialog<BrandModel>(
      context: context,
      builder: (dialogContext) {
        final formKey = GlobalKey<FormState>();
        return AlertDialog(
          title: const Text('Add Brand'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppFormTextField(
                    labelText: 'Brand Code',
                    controller: codeController,
                    validator: Validators.compose([
                      Validators.required('Brand code'),
                      Validators.optionalMaxLength(50, 'Brand code'),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  AppFormTextField(
                    labelText: 'Brand Name',
                    controller: nameController,
                    validator: Validators.compose([
                      Validators.required('Brand name'),
                      Validators.optionalMaxLength(150, 'Brand name'),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                try {
                  final response = await _inventoryService.createBrand(
                    BrandModel(
                      brandCode: codeController.text.trim(),
                      brandName: nameController.text.trim(),
                    ),
                  );
                  if (!dialogContext.mounted) {
                    return;
                  }
                  Navigator.of(dialogContext).pop(response.data);
                } catch (error) {
                  if (!dialogContext.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(SnackBar(content: Text(error.toString())));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (created == null) {
      return;
    }

    await _loadData(selectId: _selectedItem?.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _brandId = created.id;
    });
  }

  Future<void> _createTaxCodeInline() async {
    final codeController = TextEditingController(
      text: _nextSimpleCode('TAX', _taxCodes.map((item) => item.taxCode ?? '')),
    );
    final nameController = TextEditingController();
    final rateController = TextEditingController(text: '0');
    String taxType = 'gst';

    final created = await showDialog<TaxCodeModel>(
      context: context,
      builder: (dialogContext) {
        final formKey = GlobalKey<FormState>();
        return AlertDialog(
          title: const Text('Add Tax Code'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppFormTextField(
                    labelText: 'Tax Code',
                    controller: codeController,
                    validator: Validators.compose([
                      Validators.required('Tax code'),
                      Validators.optionalMaxLength(50, 'Tax code'),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  AppFormTextField(
                    labelText: 'Tax Name',
                    controller: nameController,
                    validator: Validators.compose([
                      Validators.required('Tax name'),
                      Validators.optionalMaxLength(100, 'Tax name'),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: taxType,
                    decoration: const InputDecoration(labelText: 'Tax Type'),
                    items: const [
                      DropdownMenuItem(value: 'gst', child: Text('GST')),
                      DropdownMenuItem(value: 'igst', child: Text('IGST')),
                      DropdownMenuItem(
                        value: 'cgst_sgst',
                        child: Text('CGST + SGST'),
                      ),
                      DropdownMenuItem(value: 'cess', child: Text('Cess')),
                      DropdownMenuItem(value: 'none', child: Text('None')),
                    ],
                    onChanged: (value) => taxType = value ?? 'gst',
                  ),
                  const SizedBox(height: 12),
                  AppFormTextField(
                    labelText: 'Tax Rate',
                    controller: rateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: Validators.compose([
                      Validators.required('Tax rate'),
                      Validators.optionalNonNegativeNumber('Tax rate'),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                try {
                  final response = await _inventoryService.createTaxCode(
                    TaxCodeModel(
                      taxCode: codeController.text.trim(),
                      taxName: nameController.text.trim(),
                      taxType: taxType,
                      taxRate: double.tryParse(rateController.text.trim()) ?? 0,
                    ),
                  );
                  if (!dialogContext.mounted) {
                    return;
                  }
                  Navigator.of(dialogContext).pop(response.data);
                } catch (error) {
                  if (!dialogContext.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(SnackBar(content: Text(error.toString())));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (created == null) {
      return;
    }

    await _loadData(selectId: _selectedItem?.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _taxCodeId = created.id;
    });
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
                  Tab(text: 'Alternate Items'),
                  Tab(text: 'Suppliers'),
                  Tab(text: 'Item Prices'),
                  Tab(text: 'Opening Stock'),
                ],
              ),
              const SizedBox(height: 20),
              IndexedStack(
                index: _tabController.index,
                children: [
                  _buildPrimaryTab(),
                  _buildAlternateItemsTab(),
                  _buildSuppliersTab(),
                  _buildItemPricesTab(),
                  _buildOpeningStockTab(),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPrimaryTab() {
    return Form(
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
                onChanged: (value) {
                  setState(() => _companyId = value);
                  _updateGeneratedItemCodeIfNeeded();
                },
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
                onChanged: (value) {
                  setState(() => _itemType = value ?? 'stock');
                  _updateGeneratedItemCodeIfNeeded();
                },
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
                decoration: InputDecoration(
                  labelText: 'Category',
                  suffixIcon: IconButton(
                    tooltip: 'Add Category',
                    onPressed: _createCategoryInline,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ),
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
                decoration: InputDecoration(
                  labelText: 'Brand',
                  suffixIcon: IconButton(
                    tooltip: 'Add Brand',
                    onPressed: _createBrandInline,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ),
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
                decoration: const InputDecoration(labelText: 'Purchase UOM'),
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
                onChanged: (value) => setState(() => _purchaseUomId = value),
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
                decoration: InputDecoration(
                  labelText: 'Tax Code',
                  suffixIcon: IconButton(
                    tooltip: 'Add Tax Code',
                    onPressed: _createTaxCodeInline,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ),
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
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 1080 ? 3 : (width >= 720 ? 2 : 1);
              final spacing = 12.0;
              final tileWidth = (width - ((columns - 1) * spacing)) / columns;

              final tiles = <Widget>[
                _ItemFlagTile(
                  label: 'Track Inventory',
                  value: _trackInventory,
                  onChanged: (value) => setState(() => _trackInventory = value),
                ),
                _ItemFlagTile(
                  label: 'Saleable',
                  value: _isSaleable,
                  onChanged: (value) => setState(() => _isSaleable = value),
                ),
                _ItemFlagTile(
                  label: 'Purchaseable',
                  value: _isPurchaseable,
                  onChanged: (value) => setState(() => _isPurchaseable = value),
                ),
                _ItemFlagTile(
                  label: 'Jobwork Applicable',
                  value: _isJobworkApplicable,
                  onChanged: (value) =>
                      setState(() => _isJobworkApplicable = value),
                ),
                _ItemFlagTile(
                  label: 'Batch Enabled',
                  value: _hasBatch,
                  onChanged: (value) => setState(() => _hasBatch = value),
                ),
                _ItemFlagTile(
                  label: 'Serial Enabled',
                  value: _hasSerial,
                  onChanged: (value) => setState(() => _hasSerial = value),
                ),
                _ItemFlagTile(
                  label: 'Expiry Enabled',
                  value: _hasExpiry,
                  onChanged: (value) => setState(() => _hasExpiry = value),
                ),
                _ItemFlagTile(
                  label: 'Active',
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ];

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: tiles
                    .map((tile) => SizedBox(width: tileWidth, child: tile))
                    .toList(growable: false),
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
    );
  }

  Widget _buildAlternateItemsTab() {
    final item = _selectedItem;
    if (item?.id == null) {
      return _buildPendingItemSelectionState('alternate items');
    }

    return ItemAlternateManagementPage(
      key: ValueKey('alt-${item!.id}'),
      fixedItemId: item.id,
      fixedItemLabel: item.toString(),
    );
  }

  Widget _buildSuppliersTab() {
    final item = _selectedItem;
    if (item?.id == null) {
      return _buildPendingItemSelectionState('suppliers');
    }

    return ItemSupplierMapManagementPage(
      key: ValueKey('sup-${item!.id}'),
      mode: ItemSupplierMapViewMode.itemWise,
      fixedItemId: item.id,
      fixedItem: item,
      fixedItemLabel: item.toString(),
    );
  }

  Widget _buildItemPricesTab() {
    final item = _selectedItem;
    if (item?.id == null) {
      return _buildPendingItemSelectionState('item prices');
    }

    return ItemPriceManagementPage(
      key: ValueKey('price-${item!.id}'),
      fixedItemId: item.id,
      fixedItem: item,
      fixedItemLabel: item.toString(),
    );
  }

  Widget _buildOpeningStockTab() {
    final item = _selectedItem;
    if (item?.id == null) {
      return _buildPendingItemSelectionState('opening stock');
    }

    return _ItemOpeningStockSection(
      key: ValueKey('opening-${item!.id}'),
      item: item,
    );
  }

  Widget _buildPendingItemSelectionState(String featureLabel) {
    return SettingsEmptyState(
      icon: Icons.inventory_2_outlined,
      title: 'Select Or Save Item',
      message:
          'Use the Primary tab to select an existing item or save this item first before managing $featureLabel.',
    );
  }
}

class _ItemFlagTile extends StatelessWidget {
  const _ItemFlagTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final extension = theme.extension<AppThemeExtension>()!;
    final tileBackground = extension.subtleFill;
    final borderColor = value
        ? primary.withValues(alpha: 0.30)
        : extension.mutedText.withValues(alpha: 0.24);

    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(
        horizontal: AppUiConstants.cardPadding * 0.5,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: tileBackground,
        borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Switch.adaptive(
            value: value,
            activeColor: primary,
            activeTrackColor: primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ItemOpeningStockSection extends StatefulWidget {
  const _ItemOpeningStockSection({super.key, required this.item});

  final ItemModel item;

  @override
  State<_ItemOpeningStockSection> createState() =>
      _ItemOpeningStockSectionState();
}

class _ItemOpeningStockSectionState extends State<_ItemOpeningStockSection> {
  final InventoryService _inventoryService = InventoryService();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  List<OpeningStockModel> _entries = const <OpeningStockModel>[];
  List<OpeningStockModel> _filteredEntries = const <OpeningStockModel>[];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _inventoryService.openingStocks(
        filters: {
          'item_id': widget.item.id,
          'company_id': widget.item.companyId,
          'per_page': 100,
          'sort_by': 'opening_date',
          'sort_order': 'desc',
        },
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _entries = response.data ?? const <OpeningStockModel>[];
        _filteredEntries = _filter(_entries, _searchController.text);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<OpeningStockModel> _filter(
    List<OpeningStockModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (entry) {
      final json = entry.toJson();
      return [
        json['opening_no']?.toString() ?? '',
        json['opening_status']?.toString() ?? '',
        json['opening_date']?.toString() ?? '',
        json['remarks']?.toString() ?? '',
      ];
    });
  }

  void _applySearch() {
    setState(() {
      _filteredEntries = _filter(_entries, _searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppLoadingView(message: 'Loading opening stock...');
    }

    if (_error != null) {
      return AppErrorStateView.inline(message: _error!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opening stock history for ${widget.item.itemName}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search opening stock entries',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 16),
        if (_filteredEntries.isEmpty)
          const Text('No opening stock entries found for this item.')
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredEntries.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = _filteredEntries[index].toJson();
              final status = entry['opening_status']?.toString() ?? '';
              return SettingsListTile(
                title: entry['opening_no']?.toString() ?? 'Opening Stock',
                subtitle: [
                  entry['opening_date']?.toString() ?? '',
                  status,
                  if ((entry['remarks']?.toString() ?? '').trim().isNotEmpty)
                    entry['remarks'].toString(),
                ].where((value) => value.trim().isNotEmpty).join(' · '),
                selected: false,
                onTap: () {},
                trailing: SettingsStatusPill(
                  label: status.isEmpty ? 'Draft' : status,
                  active: status.toLowerCase() == 'posted',
                ),
              );
            },
          ),
      ],
    );
  }
}
