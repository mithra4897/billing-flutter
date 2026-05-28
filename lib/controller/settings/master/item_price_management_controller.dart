import '../../../screen.dart';

class ItemPriceManagementController extends GetxController {
  ItemPriceManagementController({
    required this.fixedItemId,
    required this.fixedItem,
    required this.fixedItemLabel,
  });

  final int? fixedItemId;
  final ItemModel? fixedItem;
  final String? fixedItemLabel;

  static const List<AppDropdownItem<String>> priceTypeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'purchase', label: 'Purchase'),
        AppDropdownItem(value: 'sales', label: 'Sales'),
        AppDropdownItem(value: 'mrp', label: 'MRP'),
        AppDropdownItem(value: 'retail', label: 'Retail'),
        AppDropdownItem(value: 'wholesale', label: 'Wholesale'),
        AppDropdownItem(value: 'special', label: 'Special'),
      ];

  final InventoryService _inventoryService = InventoryService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController masterSearchController = TextEditingController();
  final TextEditingController priceSearchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController validFromController = TextEditingController();
  final TextEditingController validToController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  bool showDraftTile = false;
  String? pageError;
  String? formError;
  List<ItemModel> allItems = const <ItemModel>[];
  List<ItemModel> filteredItems = const <ItemModel>[];
  List<ItemPriceModel> prices = const <ItemPriceModel>[];
  List<ItemPriceModel> filteredPrices = const <ItemPriceModel>[];
  List<UomModel> uoms = const <UomModel>[];
  List<UomConversionModel> uomConversions = const <UomConversionModel>[];
  ItemModel? selectedItemMaster;
  ItemPriceModel? selectedPrice;
  int? uomId;
  String priceType = 'sales';
  bool isDefault = false;
  bool isActive = true;

  @override
  void onInit() {
    super.onInit();
    masterSearchController.addListener(_applyMasterSearch);
    priceSearchController.addListener(_applyPriceSearch);
    loadData();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    masterSearchController
      ..removeListener(_applyMasterSearch)
      ..dispose();
    priceSearchController
      ..removeListener(_applyPriceSearch)
      ..dispose();
    priceController.dispose();
    validFromController.dispose();
    validToController.dispose();
    super.onClose();
  }

  Future<void> loadData({int? selectPriceId}) async {
    initialLoading = allItems.isEmpty;
    pageError = null;
    update();

    try {
      final responses = await Future.wait<dynamic>([
        _inventoryService.items(
          filters: const {'per_page': 300, 'sort_by': 'item_name'},
        ),
        _inventoryService.uoms(
          filters: const {'per_page': 200, 'sort_by': 'uom_name'},
        ),
        _inventoryService.uomConversions(
          filters: const {
            'per_page': 500,
            'sort_by': 'from_uom_id',
            'sort_order': 'asc',
          },
        ),
      ]);

      final items =
          (responses[0] as PaginatedResponse<ItemModel>).data ??
          const <ItemModel>[];
      final nextUoms =
          (responses[1] as PaginatedResponse<UomModel>).data ??
          const <UomModel>[];
      final nextConversions =
          (responses[2] as PaginatedResponse<UomConversionModel>).data ??
          const <UomConversionModel>[];

      allItems = items;
      filteredItems = filterItemList(items, masterSearchController.text);
      uoms = nextUoms.where((item) => item.isActive).toList(growable: false);
      uomConversions = nextConversions
          .where((item) => item.isActive)
          .toList(growable: false);

      if (fixedItemId != null) {
        selectedItemMaster =
            fixedItem ??
            items.cast<ItemModel?>().firstWhere(
              (item) => item?.id == fixedItemId,
              orElse: () => null,
            );
      } else {
        selectedItemMaster ??= items.isNotEmpty ? items.first : null;
      }

      update();
      await loadPrices(selectPriceId: selectPriceId);
    } catch (errorValue) {
      initialLoading = false;
      pageError = errorValue.toString();
      update();
    }
  }

  Future<void> loadPrices({int? selectPriceId}) async {
    final itemId = selectedItemMaster?.id;
    if (itemId == null) {
      prices = const <ItemPriceModel>[];
      filteredPrices = const <ItemPriceModel>[];
      initialLoading = false;
      resetForm(notify: false);
      update();
      return;
    }

    try {
      final response = await _inventoryService.itemPrices(
        filters: {
          'per_page': 300,
          'item_id': itemId,
          'sort_by': 'valid_from',
          'sort_order': 'desc',
        },
      );
      final items = response.data ?? const <ItemPriceModel>[];

      prices = items;
      filteredPrices = filterPrices(items, priceSearchController.text);
      initialLoading = false;

      final selected = selectPriceId != null
          ? items.cast<ItemPriceModel?>().firstWhere(
              (item) => item?.id == selectPriceId,
              orElse: () => null,
            )
          : (selectedPrice == null
                ? null
                : items.cast<ItemPriceModel?>().firstWhere(
                    (item) => item?.id == selectedPrice?.id,
                    orElse: () => null,
                  ));

      if (selected != null) {
        selectPrice(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (errorValue) {
      initialLoading = false;
      pageError = errorValue.toString();
    }

    update();
  }

  List<ItemModel> filterItemList(List<ItemModel> source, String query) {
    return filterMasterList(source, query, (item) {
      return [item.itemCode, item.itemName, item.itemType ?? ''];
    });
  }

  List<ItemPriceModel> filterPrices(List<ItemPriceModel> source, String query) {
    return filterMasterList(source, query, (item) {
      return [
        item.priceType ?? '',
        item.uomName ?? '',
        item.uomSymbol ?? '',
        item.validFrom ?? '',
        item.validTo ?? '',
      ];
    });
  }

  Set<int> allowedUomIdsForItem(ItemModel? item) {
    final seedIds = <int>{
      if (item?.baseUomId != null) item!.baseUomId!,
      if (item?.purchaseUomId != null) item!.purchaseUomId!,
      if (item?.salesUomId != null) item!.salesUomId!,
    };

    if (seedIds.isEmpty) {
      return <int>{};
    }

    final allowed = <int>{...seedIds};
    for (final conversion in uomConversions) {
      final fromId = conversion.fromUomId;
      final toId = conversion.toUomId;
      if (fromId == null || toId == null) {
        continue;
      }
      if (seedIds.contains(fromId) || seedIds.contains(toId)) {
        allowed.add(fromId);
        allowed.add(toId);
      }
    }
    return allowed;
  }

  List<UomModel> get allowedUoms {
    final allowedIds = allowedUomIdsForItem(selectedItemMaster);
    if (selectedPrice?.uomId != null) {
      allowedIds.add(selectedPrice!.uomId!);
    }
    if (allowedIds.isEmpty) {
      return uoms;
    }
    return uoms
        .where((uom) => uom.id != null && allowedIds.contains(uom.id))
        .toList(growable: false);
  }

  int? get defaultUomId {
    final item = selectedItemMaster;
    final allowedIds = allowedUomIdsForItem(item);
    final preferred = <int?>[
      item?.salesUomId,
      item?.baseUomId,
      item?.purchaseUomId,
    ];
    for (final id in preferred) {
      if (id != null && (allowedIds.isEmpty || allowedIds.contains(id))) {
        return id;
      }
    }
    return allowedUoms.isNotEmpty ? allowedUoms.first.id : null;
  }

  void _applyMasterSearch() {
    filteredItems = filterItemList(allItems, masterSearchController.text);
    update();
  }

  void _applyPriceSearch() {
    filteredPrices = filterPrices(prices, priceSearchController.text);
    update();
  }

  void selectMasterItem(ItemModel item) {
    selectedItemMaster = item;
    selectedPrice = null;
    uomId = defaultUomId;
    update();
    loadPrices();
  }

  void selectPrice(ItemPriceModel item, {bool notify = true}) {
    if (selectedPrice?.id == item.id) {
      resetForm(notify: notify);
      return;
    }
    showDraftTile = false;
    selectedPrice = item;
    uomId = item.uomId;
    priceType = item.priceType ?? 'sales';
    priceController.text = item.price?.toString() ?? '';
    validFromController.text = displayDate(item.validFrom);
    validToController.text = displayDate(item.validTo);
    isDefault = item.isDefault;
    isActive = item.isActive;
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedPrice = null;
    uomId = defaultUomId;
    priceType = 'sales';
    priceController.clear();
    validFromController.clear();
    validToController.clear();
    isDefault = false;
    isActive = true;
    formError = null;
    if (notify) {
      update();
    }
  }

  Future<void> save() async {
    final itemId = selectedItemMaster?.id;
    if (formKey.currentState?.validate() != true || itemId == null) {
      return;
    }

    saving = true;
    formError = null;
    update();

    final model = ItemPriceModel(
      id: selectedPrice?.id,
      itemId: itemId,
      priceType: priceType,
      uomId: uomId,
      price: double.tryParse(priceController.text.trim()),
      validFrom: nullIfEmpty(validFromController.text),
      validTo: nullIfEmpty(validToController.text),
      isDefault: isDefault,
      isActive: isActive,
    );

    try {
      final response = selectedPrice == null
          ? await _inventoryService.createItemPrice(model)
          : await _inventoryService.updateItemPrice(selectedPrice!.id!, model);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      showDraftTile = false;
      resetForm();
      await loadPrices();
    } catch (errorValue) {
      formError = errorValue.toString();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> deleteSelectedPrice() async {
    final id = selectedPrice?.id;
    if (id == null) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _inventoryService.deleteItemPrice(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadPrices();
    } catch (errorValue) {
      formError = errorValue.toString();
    } finally {
      saving = false;
      update();
    }
  }

  void startNew({required bool isDesktop}) {
    showDraftTile = true;
    resetForm();
    if (fixedItemId == null && !isDesktop) {
      workspaceController.openEditor();
    }
  }

  void hideDraftTile() {
    showDraftTile = false;
    resetForm();
    update();
  }

  void setPriceType(String? value) {
    priceType = value ?? 'sales';
    update();
  }

  void setUomId(int? value) {
    uomId = value;
    update();
  }

  void setIsDefault(bool value) {
    isDefault = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }
}
