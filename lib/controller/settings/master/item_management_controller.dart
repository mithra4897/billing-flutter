import '../../../screen.dart';

class ItemManagementController extends GetxController {
  static const List<AppDropdownItem<String>> itemTypeItems =
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

  ItemManagementController();

  final InventoryService _inventoryService = InventoryService();
  final MasterService _masterService = MasterService();
  final MediaService _mediaService = MediaService();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController localNameController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController hsnController = TextEditingController();
  final TextEditingController standardCostController = TextEditingController();
  final TextEditingController standardSellingPriceController =
      TextEditingController();
  final TextEditingController mrpController = TextEditingController();
  final TextEditingController minStockController = TextEditingController();
  final TextEditingController reorderLevelController = TextEditingController();
  final TextEditingController reorderQtyController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController volumeController = TextEditingController();
  final TextEditingController imagePathController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  bool uploadingImage = false;
  String? pageError;
  String? formError;
  List<ItemModel> items = const <ItemModel>[];
  List<ItemModel> filteredItems = const <ItemModel>[];
  List<ItemCategoryModel> categories = const <ItemCategoryModel>[];
  List<BrandModel> brands = const <BrandModel>[];
  List<UomModel> uoms = const <UomModel>[];
  List<TaxCodeModel> taxCodes = const <TaxCodeModel>[];
  ItemModel? selectedItem;
  int? contextCompanyId;
  int? companyId;
  int? categoryId;
  int? brandId;
  int? baseUomId;
  int? purchaseUomId;
  int? salesUomId;
  int? taxCodeId;
  String itemType = 'stock';
  bool hasBatch = false;
  bool hasSerial = false;
  bool hasExpiry = false;
  bool trackInventory = true;
  bool isSaleable = true;
  bool isPurchaseable = true;
  bool isManufacturable = false;
  bool isJobworkApplicable = false;
  bool isActive = true;
  int activeTabIndex = 0;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    loadData();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    codeController.dispose();
    nameController.dispose();
    localNameController.dispose();
    skuController.dispose();
    barcodeController.dispose();
    hsnController.dispose();
    standardCostController.dispose();
    standardSellingPriceController.dispose();
    mrpController.dispose();
    minStockController.dispose();
    reorderLevelController.dispose();
    reorderQtyController.dispose();
    weightController.dispose();
    volumeController.dispose();
    imagePathController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  Future<void> loadData({int? selectId}) async {
    initialLoading = items.isEmpty;
    pageError = null;
    update();

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

      final nextItems =
          (responses[0] as PaginatedResponse<ItemModel>).data ??
          const <ItemModel>[];
      final companies =
          (responses[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final nextCategories =
          (responses[2] as PaginatedResponse<ItemCategoryModel>).data ??
          const <ItemCategoryModel>[];
      final nextBrands =
          (responses[3] as PaginatedResponse<BrandModel>).data ??
          const <BrandModel>[];
      final nextUoms =
          (responses[4] as PaginatedResponse<UomModel>).data ??
          const <UomModel>[];
      final nextTaxCodes =
          (responses[5] as PaginatedResponse<TaxCodeModel>).data ??
          const <TaxCodeModel>[];

      final activeCompanies = companies
          .where((company) => company.isActive)
          .toList(growable: false);
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );

      items = nextItems;
      contextCompanyId = contextSelection.companyId;
      categories = nextCategories
          .where((category) => category.isActive)
          .toList(growable: false);
      brands = nextBrands
          .where((brand) => brand.isActive)
          .toList(growable: false);
      uoms = nextUoms.where((uom) => uom.isActive).toList(growable: false);
      taxCodes = nextTaxCodes
          .where((tax) => tax.isActive)
          .toList(growable: false);
      filteredItems = _filterItems(nextItems, searchController.text);
      initialLoading = false;

      final selected = selectId != null
          ? nextItems.cast<ItemModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedItem == null
                ? (nextItems.isNotEmpty ? nextItems.first : null)
                : nextItems.cast<ItemModel?>().firstWhere(
                    (item) => item?.id == selectedItem?.id,
                    orElse: () => nextItems.isNotEmpty ? nextItems.first : null,
                  ));

      if (selected != null) {
        selectItem(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (error) {
      initialLoading = false;
      pageError = error.toString();
    }

    update();
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
    filteredItems = _filterItems(items, searchController.text);
    update();
  }

  void selectItem(ItemModel item, {bool notify = true}) {
    selectedItem = item;
    companyId = item.companyId;
    categoryId = item.categoryId;
    brandId = item.brandId;
    baseUomId = item.baseUomId;
    purchaseUomId = item.purchaseUomId;
    salesUomId = item.salesUomId;
    taxCodeId = item.taxCodeId;
    itemType = item.itemType ?? 'stock';
    codeController.text = item.itemCode;
    nameController.text = item.itemName;
    localNameController.text = item.itemNameLocal ?? '';
    skuController.text = item.sku ?? '';
    barcodeController.text = item.barcode ?? '';
    hsnController.text = item.hsnSacCode ?? '';
    standardCostController.text = item.standardCost?.toString() ?? '';
    standardSellingPriceController.text =
        item.standardSellingPrice?.toString() ?? '';
    mrpController.text = item.mrp?.toString() ?? '';
    minStockController.text = item.minStockLevel?.toString() ?? '';
    reorderLevelController.text = item.reorderLevel?.toString() ?? '';
    reorderQtyController.text = item.reorderQty?.toString() ?? '';
    weightController.text = item.weight?.toString() ?? '';
    volumeController.text = item.volume?.toString() ?? '';
    imagePathController.text = item.imagePath ?? '';
    remarksController.text = item.remarks ?? '';
    hasBatch = item.hasBatch;
    hasSerial = item.hasSerial;
    hasExpiry = item.hasExpiry;
    trackInventory = item.trackInventory;
    isSaleable = item.isSaleable;
    isPurchaseable = item.isPurchaseable;
    isManufacturable = item.isManufacturable;
    isJobworkApplicable = item.isJobworkApplicable;
    isActive = item.isActive;
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedItem = null;
    companyId = contextCompanyId;
    categoryId = null;
    brandId = null;
    baseUomId = uoms.isNotEmpty ? uoms.first.id : null;
    purchaseUomId = null;
    salesUomId = null;
    taxCodeId = null;
    itemType = 'stock';
    codeController.clear();
    nameController.clear();
    localNameController.clear();
    skuController.clear();
    barcodeController.clear();
    hsnController.clear();
    standardCostController.clear();
    standardSellingPriceController.clear();
    mrpController.clear();
    minStockController.clear();
    reorderLevelController.clear();
    reorderQtyController.clear();
    weightController.clear();
    volumeController.clear();
    imagePathController.clear();
    remarksController.clear();
    hasBatch = false;
    hasSerial = false;
    hasExpiry = false;
    trackInventory = true;
    isSaleable = true;
    isPurchaseable = true;
    isManufacturable = false;
    isJobworkApplicable = false;
    isActive = true;
    formError = null;
    activeTabIndex = 0;
    if (notify) {
      update();
    }
  }

  void startNew({required bool isDesktop}) {
    resetForm();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    saving = true;
    formError = null;
    update();

    final model = ItemModel(
      id: selectedItem?.id,
      companyId: companyId,
      itemCode: codeController.text.trim(),
      itemName: nameController.text.trim(),
      itemNameLocal: nullIfEmpty(localNameController.text),
      itemType: itemType,
      categoryId: categoryId,
      brandId: brandId,
      baseUomId: baseUomId,
      purchaseUomId: purchaseUomId,
      salesUomId: salesUomId,
      taxCodeId: taxCodeId,
      sku: nullIfEmpty(skuController.text),
      barcode: nullIfEmpty(barcodeController.text),
      hsnSacCode: nullIfEmpty(hsnController.text),
      standardCost: double.tryParse(standardCostController.text.trim()),
      standardSellingPrice: double.tryParse(
        standardSellingPriceController.text.trim(),
      ),
      mrp: double.tryParse(mrpController.text.trim()),
      minStockLevel: double.tryParse(minStockController.text.trim()),
      reorderLevel: double.tryParse(reorderLevelController.text.trim()),
      reorderQty: double.tryParse(reorderQtyController.text.trim()),
      weight: double.tryParse(weightController.text.trim()),
      volume: double.tryParse(volumeController.text.trim()),
      imagePath: nullIfEmpty(imagePathController.text),
      hasBatch: hasBatch,
      hasSerial: hasSerial,
      hasExpiry: hasExpiry,
      trackInventory: trackInventory,
      isSaleable: isSaleable,
      isPurchaseable: isPurchaseable,
      isManufacturable: isManufacturable,
      isJobworkApplicable: isJobworkApplicable,
      isActive: isActive,
      remarks: nullIfEmpty(remarksController.text),
    );

    try {
      if (selectedItem?.id != null) {
        debugPrint(
          'PUT /api/v1/inventory/items/${selectedItem!.id} payload: ${jsonEncode(model.toJson())}',
        );
      } else {
        debugPrint(
          'POST /api/v1/inventory/items payload: ${jsonEncode(model.toJson())}',
        );
      }
      final response = selectedItem == null
          ? await _inventoryService.createItem(model)
          : await _inventoryService.updateItem(selectedItem!.id!, model);
      final saved = response.data;
      if (saved == null) {
        formError = response.message;
        update();
        return;
      }

      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadData(selectId: saved.id);
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> delete() async {
    final id = selectedItem?.id;
    if (id == null) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _inventoryService.deleteItem(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadData();
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> uploadItemImage(BuildContext context) async {
    await MediaUploadHelper.uploadImage(
      context: context,
      mediaService: _mediaService,
      onLoading: (isLoading) {
        uploadingImage = isLoading;
        update();
      },
      onSuccess: (filePath) {
        imagePathController.text = filePath;
        formError = null;
        update();
      },
      onError: (error) {
        formError = error;
        update();
      },
      module: 'inventory',
      documentType: 'items',
      documentId: selectedItem?.id,
      purpose: 'item_image',
      folder: 'inventory/items',
      isPublic: true,
    );
  }

  void setActiveTabIndex(int value) {
    activeTabIndex = value;
    update();
  }

  void setItemType(String? value) {
    itemType = value ?? 'stock';
    if (itemType == 'service' || itemType == 'non_stock') {
      trackInventory = false;
      hasBatch = false;
      hasSerial = false;
      hasExpiry = false;
    } else if (selectedItem == null) {
      trackInventory = true;
    }
    update();
  }

  void setCategoryId(int? value) {
    categoryId = value;
    update();
  }

  void setBrandId(int? value) {
    brandId = value;
    update();
  }

  void setBaseUomId(int? value) {
    baseUomId = value;
    update();
  }

  void setPurchaseUomId(int? value) {
    purchaseUomId = value;
    update();
  }

  void setSalesUomId(int? value) {
    salesUomId = value;
    update();
  }

  void setTaxCodeId(int? value) {
    taxCodeId = value;
    update();
  }

  void setTrackInventory(bool value) {
    trackInventory = value;
    update();
  }

  void setIsSaleable(bool value) {
    isSaleable = value;
    update();
  }

  void setIsPurchaseable(bool value) {
    isPurchaseable = value;
    update();
  }

  void setIsManufacturable(bool value) {
    isManufacturable = value;
    update();
  }

  void setIsJobworkApplicable(bool value) {
    isJobworkApplicable = value;
    update();
  }

  void setHasBatch(bool value) {
    hasBatch = value;
    update();
  }

  void setHasSerial(bool value) {
    hasSerial = value;
    update();
  }

  void setHasExpiry(bool value) {
    hasExpiry = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  String nextSimpleCode(String prefix, Iterable<String> existingCodes) {
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

  Future<void> showCreateCategoryDialog(BuildContext context) async {
    final created = await showDialog<ItemCategoryModel>(
      context: context,
      builder: (dialogContext) {
        final formKey = GlobalKey<FormState>();
        var code = nextSimpleCode(
          'CAT',
          categories.map((item) => item.categoryCode),
        );
        var name = '';
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
                    initialValue: code,
                    onChanged: (value) => code = value,
                    validator: Validators.compose([
                      Validators.required('Category code'),
                      Validators.optionalMaxLength(50, 'Category code'),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  AppFormTextField(
                    labelText: 'Category Name',
                    onChanged: (value) => name = value,
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
                      categoryCode: code.trim(),
                      categoryName: name.trim(),
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

    await loadData(selectId: selectedItem?.id);
    categoryId = created.id;
    update();
  }

  Future<void> showCreateBrandDialog(BuildContext context) async {
    final created = await showDialog<BrandModel>(
      context: context,
      builder: (dialogContext) {
        final formKey = GlobalKey<FormState>();
        var code = nextSimpleCode(
          'BRD',
          brands.map((item) => item.brandCode ?? ''),
        );
        var name = '';
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
                    initialValue: code,
                    onChanged: (value) => code = value,
                    validator: Validators.compose([
                      Validators.required('Brand code'),
                      Validators.optionalMaxLength(50, 'Brand code'),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  AppFormTextField(
                    labelText: 'Brand Name',
                    onChanged: (value) => name = value,
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
                    BrandModel(brandCode: code.trim(), brandName: name.trim()),
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

    await loadData(selectId: selectedItem?.id);
    brandId = created.id;
    update();
  }

  Future<void> showCreateTaxCodeDialog(BuildContext context) async {
    final created = await showDialog<TaxCodeModel>(
      context: context,
      builder: (dialogContext) {
        final formKey = GlobalKey<FormState>();
        var code = nextSimpleCode(
          'TAX',
          taxCodes.map((item) => item.taxCode ?? ''),
        );
        var name = '';
        var taxType = 'gst';
        var rate = '0';
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
                    initialValue: code,
                    onChanged: (value) => code = value,
                    validator: Validators.compose([
                      Validators.required('Tax code'),
                      Validators.optionalMaxLength(50, 'Tax code'),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  AppFormTextField(
                    labelText: 'Tax Name',
                    onChanged: (value) => name = value,
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
                    initialValue: rate,
                    onChanged: (value) => rate = value,
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
                      taxCode: code.trim(),
                      taxName: name.trim(),
                      taxType: taxType,
                      taxRate: double.tryParse(rate.trim()) ?? 0,
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

    await loadData(selectId: selectedItem?.id);
    taxCodeId = created.id;
    update();
  }
}
