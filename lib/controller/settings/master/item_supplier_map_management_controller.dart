import '../../../screen.dart';

class ItemSupplierMapManagementController extends GetxController {
  ItemSupplierMapManagementController({
    required this.mode,
    required this.fixedItemId,
    required this.fixedItem,
    required this.fixedItemLabel,
  });

  final ItemSupplierMapViewMode mode;
  final int? fixedItemId;
  final ItemModel? fixedItem;
  final String? fixedItemLabel;

  final InventoryService _inventoryService = InventoryService();
  final PartiesService _partiesService = PartiesService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController masterSearchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController supplierItemCodeController =
      TextEditingController();
  final TextEditingController supplierItemNameController =
      TextEditingController();
  final TextEditingController supplierRateController = TextEditingController();
  final TextEditingController leadTimeDaysController = TextEditingController();
  final TextEditingController minOrderQtyController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  bool showDraftTile = false;
  String? pageError;
  String? formError;
  List<ItemSupplierMapModel> items = const <ItemSupplierMapModel>[];
  List<ItemSupplierMapModel> filteredItems = const <ItemSupplierMapModel>[];
  List<ItemModel> allItems = const <ItemModel>[];
  List<ItemModel> filteredMastersItems = const <ItemModel>[];
  List<PartyModel> allSuppliers = const <PartyModel>[];
  List<PartyModel> filteredMasterSuppliers = const <PartyModel>[];
  List<UomModel> uoms = const <UomModel>[];
  List<UomConversionModel> uomConversions = const <UomConversionModel>[];
  ItemSupplierMapModel? selectedItem;
  int? selectedMasterId;
  int? counterpartyId;
  int? purchaseUomId;
  bool isPrimarySupplier = false;
  bool isActive = true;

  bool get isItemWise => mode == ItemSupplierMapViewMode.itemWise;
  String get pageTitle => isItemWise ? 'Item Suppliers' : 'Supplier Items';
  String get masterLabel => isItemWise ? 'Item' : 'Supplier';
  String get counterpartyLabel => isItemWise ? 'Supplier' : 'Item';

  @override
  void onInit() {
    super.onInit();
    masterSearchController.addListener(_applyMasterSearch);
    loadData();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    masterSearchController
      ..removeListener(_applyMasterSearch)
      ..dispose();
    supplierItemCodeController.dispose();
    supplierItemNameController.dispose();
    supplierRateController.dispose();
    leadTimeDaysController.dispose();
    minOrderQtyController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  Future<void> loadData({int? selectId}) async {
    initialLoading = allItems.isEmpty && allSuppliers.isEmpty;
    pageError = null;
    update();

    try {
      final responses = await Future.wait<dynamic>([
        _inventoryService.items(
          filters: const {
            'per_page': 200,
            'sort_by': 'item_name',
            'sort_order': 'asc',
          },
        ),
        _partiesService.partyTypes(
          filters: const {
            'per_page': 200,
            'sort_by': 'name',
            'sort_order': 'asc',
          },
        ),
        _partiesService.parties(
          filters: const {
            'per_page': 200,
            'sort_by': 'display_name',
            'sort_order': 'asc',
          },
        ),
        _inventoryService.uoms(
          filters: const {
            'per_page': 200,
            'sort_by': 'uom_name',
            'sort_order': 'asc',
          },
        ),
        _inventoryService.uomConversions(
          filters: const {
            'per_page': 500,
            'sort_by': 'from_uom_id',
            'sort_order': 'asc',
          },
        ),
      ]);

      final nextItems =
          (responses[0] as PaginatedResponse<ItemModel>).data ??
          const <ItemModel>[];
      final partyTypes =
          (responses[1] as PaginatedResponse<PartyTypeModel>).data ??
          const <PartyTypeModel>[];
      final parties =
          (responses[2] as PaginatedResponse<PartyModel>).data ??
          const <PartyModel>[];
      final nextUoms =
          (responses[3] as PaginatedResponse<UomModel>).data ??
          const <UomModel>[];
      final nextConversions =
          (responses[4] as PaginatedResponse<UomConversionModel>).data ??
          const <UomConversionModel>[];

      final supplierTypeIds = partyTypes
          .where(isSupplierPartyType)
          .map(partyTypeId)
          .whereType<int>()
          .toSet();

      final suppliers = parties
          .where(
            (party) =>
                party.isActive && supplierTypeIds.contains(party.partyTypeId),
          )
          .toList(growable: false);

      allItems = nextItems
          .where((item) => item.isActive)
          .toList(growable: false);
      allSuppliers = suppliers;
      uoms = nextUoms.where((uom) => uom.isActive).toList(growable: false);
      uomConversions = nextConversions
          .where((conversion) => conversion.isActive)
          .toList(growable: false);
      filteredMastersItems = filterMasterItems(
        allItems,
        masterSearchController.text,
      );
      filteredMasterSuppliers = filterMasterSuppliers(
        allSuppliers,
        masterSearchController.text,
      );

      if (isItemWise && fixedItemId != null) {
        selectedMasterId = fixedItemId;
      } else {
        selectedMasterId ??= isItemWise
            ? (allItems.isNotEmpty ? allItems.first.id : null)
            : (allSuppliers.isNotEmpty ? allSuppliers.first.id : null);
      }

      update();
      await loadMappings(selectId: selectId);
    } catch (errorValue) {
      initialLoading = false;
      pageError = errorValue.toString();
      update();
    }
  }

  int? partyTypeId(PartyTypeModel partyType) {
    final json = partyType.toJson();
    return int.tryParse(json['id']?.toString() ?? '');
  }

  bool isSupplierPartyType(PartyTypeModel partyType) {
    final json = partyType.toJson();
    final code = (json['code'] ?? json['type_code'] ?? '')
        .toString()
        .toLowerCase()
        .trim();
    final name = (json['name'] ?? json['type_name'] ?? '')
        .toString()
        .toLowerCase()
        .trim();
    return code.contains('supplier') ||
        code.contains('vendor') ||
        name.contains('supplier') ||
        name.contains('vendor');
  }

  Future<void> loadMappings({int? selectId}) async {
    if (selectedMasterId == null) {
      items = const <ItemSupplierMapModel>[];
      filteredItems = const <ItemSupplierMapModel>[];
      initialLoading = false;
      resetForm(notify: false);
      update();
      return;
    }

    pageError = null;
    update();

    try {
      final response = await _inventoryService.itemSupplierMaps(
        filters: {
          'per_page': 200,
          'sort_by': 'is_primary_supplier',
          'sort_order': 'desc',
          if (isItemWise) 'item_id': selectedMasterId,
          if (!isItemWise) 'supplier_party_id': selectedMasterId,
        },
      );
      final nextItems = response.data ?? const <ItemSupplierMapModel>[];

      items = nextItems;
      filteredItems = nextItems;
      initialLoading = false;

      final selected = selectId != null
          ? nextItems.cast<ItemSupplierMapModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedItem == null
                ? (nextItems.isNotEmpty ? nextItems.first : null)
                : nextItems.cast<ItemSupplierMapModel?>().firstWhere(
                    (item) => item?.id == selectedItem?.id,
                    orElse: () => nextItems.isNotEmpty ? nextItems.first : null,
                  ));

      if (selected != null) {
        selectMapping(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (errorValue) {
      initialLoading = false;
      pageError = errorValue.toString();
    }

    update();
  }

  List<ItemModel> filterMasterItems(List<ItemModel> source, String query) {
    return filterMasterList(source, query, (item) {
      return [item.itemCode, item.itemName];
    });
  }

  List<PartyModel> filterMasterSuppliers(
    List<PartyModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (party) {
      return [
        party.partyCode ?? '',
        party.displayName ?? '',
        party.partyName ?? '',
        party.partyType ?? '',
      ];
    });
  }

  void _applyMasterSearch() {
    filteredMastersItems = filterMasterItems(
      allItems,
      masterSearchController.text,
    );
    filteredMasterSuppliers = filterMasterSuppliers(
      allSuppliers,
      masterSearchController.text,
    );
    update();
  }

  void selectMapping(ItemSupplierMapModel item, {bool notify = true}) {
    if (selectedItem?.id == item.id) {
      resetForm(notify: notify);
      return;
    }
    showDraftTile = false;
    selectedItem = item;
    counterpartyId = isItemWise ? item.supplierId : item.itemId;
    purchaseUomId = item.purchaseUomId;
    supplierItemCodeController.text = item.supplierItemCode ?? '';
    supplierItemNameController.text = item.supplierItemName ?? '';
    supplierRateController.text = item.supplierRate?.toString() ?? '';
    leadTimeDaysController.text = item.leadTimeDays?.toString() ?? '';
    minOrderQtyController.text = item.minOrderQty?.toString() ?? '';
    remarksController.text = item.remarks ?? '';
    isPrimarySupplier = item.isPrimarySupplier;
    isActive = item.isActive;
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedItem = null;
    counterpartyId = null;
    purchaseUomId = defaultPurchaseUomId;
    supplierItemCodeController.clear();
    supplierItemNameController.clear();
    supplierRateController.clear();
    leadTimeDaysController.clear();
    minOrderQtyController.clear();
    remarksController.clear();
    isPrimarySupplier = false;
    isActive = true;
    formError = null;
    if (notify) {
      update();
    }
  }

  ItemModel? get currentItemForUomRules {
    if (isItemWise) {
      return fixedItem ??
          allItems.cast<ItemModel?>().firstWhere(
            (item) => item?.id == selectedMasterId,
            orElse: () => null,
          );
    }
    return allItems.cast<ItemModel?>().firstWhere(
      (item) => item?.id == counterpartyId,
      orElse: () => null,
    );
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

  List<UomModel> get allowedPurchaseUoms {
    final allowedIds = allowedUomIdsForItem(currentItemForUomRules);
    if (selectedItem?.purchaseUomId != null) {
      allowedIds.add(selectedItem!.purchaseUomId!);
    }
    if (allowedIds.isEmpty) {
      return uoms;
    }
    return uoms
        .where((uom) => uom.id != null && allowedIds.contains(uom.id))
        .toList(growable: false);
  }

  int? get defaultPurchaseUomId {
    final item = currentItemForUomRules;
    final allowedIds = allowedUomIdsForItem(item);
    final preferred = <int?>[
      item?.purchaseUomId,
      item?.baseUomId,
      item?.salesUomId,
    ];
    for (final id in preferred) {
      if (id != null && (allowedIds.isEmpty || allowedIds.contains(id))) {
        return id;
      }
    }
    return allowedPurchaseUoms.isNotEmpty ? allowedPurchaseUoms.first.id : null;
  }

  Future<void> save() async {
    if (formKey.currentState?.validate() != true || selectedMasterId == null) {
      return;
    }

    saving = true;
    formError = null;
    update();

    final model = ItemSupplierMapModel(
      id: selectedItem?.id,
      itemId: isItemWise ? selectedMasterId : counterpartyId,
      supplierId: isItemWise ? counterpartyId : selectedMasterId,
      supplierItemCode: nullIfEmpty(supplierItemCodeController.text),
      supplierItemName: nullIfEmpty(supplierItemNameController.text),
      purchaseUomId: purchaseUomId,
      supplierRate: Validators.parseFlexibleNumber(supplierRateController.text),
      leadTimeDays: int.tryParse(leadTimeDaysController.text.trim()),
      minOrderQty: Validators.parseFlexibleNumber(minOrderQtyController.text),
      isPrimarySupplier: isPrimarySupplier,
      isActive: isActive,
      remarks: nullIfEmpty(remarksController.text),
    );

    try {
      final response = selectedItem == null
          ? await _inventoryService.createItemSupplierMap(model)
          : await _inventoryService.updateItemSupplierMap(
              selectedItem!.id!,
              model,
            );
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      showDraftTile = false;
      resetForm();
      await loadMappings();
    } catch (errorValue) {
      formError = errorValue.toString();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> deleteSelected() async {
    final id = selectedItem?.id;
    if (id == null) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _inventoryService.deleteItemSupplierMap(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadMappings();
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

  void selectMaster(int? id) {
    if (id == null) {
      return;
    }
    selectedMasterId = id;
    update();
    loadMappings();
  }

  String itemLabel(ItemModel item) {
    final name = item.itemName.trim();
    final code = item.itemCode.trim();
    if (code.isNotEmpty && name.isNotEmpty) {
      return '$code - $name';
    }
    return name.isNotEmpty ? name : code;
  }

  String supplierLabel(PartyModel party) {
    final name = (party.displayName ?? party.partyName ?? '').trim();
    final code = (party.partyCode ?? '').trim();
    if (code.isNotEmpty && name.isNotEmpty) {
      return '$code - $name';
    }
    return name.isNotEmpty ? name : code;
  }

  String itemSubtitle(ItemModel item) {
    return [
      item.itemType ?? '',
      item.categoryName ?? item.categoryCode ?? '',
      item.baseUomSymbol ?? item.baseUomCode ?? '',
    ].where((value) => value.trim().isNotEmpty).join(' · ');
  }

  String supplierSubtitle(PartyModel party) {
    return [
      party.partyType ?? '',
      party.defaultCurrency ?? '',
      party.pan ?? '',
    ].where((value) => value.trim().isNotEmpty).join(' · ');
  }

  String get selectedMasterTitle {
    if (selectedMasterId == null) {
      return pageTitle;
    }
    if (isItemWise) {
      final item = allItems.cast<ItemModel?>().firstWhere(
        (entry) => entry?.id == selectedMasterId,
        orElse: () => null,
      );
      return item == null ? pageTitle : itemLabel(item);
    }
    final supplier = allSuppliers.cast<PartyModel?>().firstWhere(
      (entry) => entry?.id == selectedMasterId,
      orElse: () => null,
    );
    return supplier == null ? pageTitle : supplierLabel(supplier);
  }

  List<dynamic> get availableCounterpartyOptions {
    final selectedIds = items
        .map((item) => isItemWise ? item.supplierId : item.itemId)
        .whereType<int>()
        .toSet();
    if (isItemWise) {
      return allSuppliers
          .where((party) => party.id != null && !selectedIds.contains(party.id))
          .toList(growable: false);
    }
    return allItems
        .where((item) => !selectedIds.contains(item.id))
        .toList(growable: false);
  }

  List<dynamic> get dropdownCounterpartyOptions {
    final options = availableCounterpartyOptions.toList(growable: true);
    if (counterpartyId != null) {
      final dynamic selected = isItemWise
          ? allSuppliers.cast<PartyModel?>().firstWhere(
              (entry) => entry?.id == counterpartyId,
              orElse: () => null,
            )
          : allItems.cast<ItemModel?>().firstWhere(
              (entry) => entry?.id == counterpartyId,
              orElse: () => null,
            );
      final selectedId = isItemWise
          ? (selected as PartyModel?)?.id
          : (selected as ItemModel?)?.id;
      if (selected != null &&
          options.every((option) => option.id != selectedId)) {
        options.insert(0, selected);
      }
    }
    return options;
  }

  String get selectedDraftCounterpartyLabel {
    if (counterpartyId == null) {
      return isItemWise ? 'New Supplier' : 'New Item';
    }
    if (isItemWise) {
      final supplier = allSuppliers.cast<PartyModel?>().firstWhere(
        (entry) => entry?.id == counterpartyId,
        orElse: () => null,
      );
      return supplier == null ? 'New Supplier' : supplierLabel(supplier);
    }
    final item = allItems.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == counterpartyId,
      orElse: () => null,
    );
    return item == null ? 'New Item' : itemLabel(item);
  }

  dynamic get selectedCounterparty {
    if (counterpartyId == null) {
      return null;
    }
    return isItemWise
        ? allSuppliers.cast<PartyModel?>().firstWhere(
            (entry) => entry?.id == counterpartyId,
            orElse: () => null,
          )
        : allItems.cast<ItemModel?>().firstWhere(
            (entry) => entry?.id == counterpartyId,
            orElse: () => null,
          );
  }

  void setCounterpartyId(int? value) {
    counterpartyId = value;
    if (!allowedUomIdsForItem(currentItemForUomRules).contains(purchaseUomId)) {
      purchaseUomId = defaultPurchaseUomId;
    }
    update();
  }

  void setPurchaseUomId(int? value) {
    purchaseUomId = value;
    update();
  }

  void setIsPrimarySupplier(bool value) {
    isPrimarySupplier = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }
}
