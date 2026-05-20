import '../../../screen.dart';

class ItemAlternateManagementController extends GetxController {
  ItemAlternateManagementController({
    required this.fixedItemId,
    required this.fixedItemLabel,
  });

  final int? fixedItemId;
  final String? fixedItemLabel;

  static const String pageTitle = 'Item Alternates';
  static const String masterLabel = 'Item';
  static const String counterpartyLabel = 'Alternate Item';

  final InventoryService _inventoryService = InventoryService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController masterSearchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController priorityController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  bool showDraftTile = false;
  String? pageError;
  String? formError;
  List<ItemAlternateModel> items = const <ItemAlternateModel>[];
  List<ItemAlternateModel> filteredItems = const <ItemAlternateModel>[];
  List<ItemModel> allItems = const <ItemModel>[];
  List<ItemModel> filteredMasterItems = const <ItemModel>[];
  ItemAlternateModel? selectedItem;
  int? selectedMasterId;
  int? counterpartyId;
  bool isActive = true;

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
    priorityController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  Future<void> loadData({int? selectId}) async {
    initialLoading = allItems.isEmpty;
    pageError = null;
    update();

    try {
      final response = await _inventoryService.items(
        filters: const {'per_page': 300, 'sort_by': 'item_name'},
      );
      final nextItems = response.data ?? const <ItemModel>[];

      allItems = nextItems
          .where((item) => item.isActive)
          .toList(growable: false);
      filteredMasterItems = filterMasterListItems(
        allItems,
        masterSearchController.text,
      );

      if (fixedItemId != null) {
        selectedMasterId = fixedItemId;
      } else {
        selectedMasterId ??= allItems.isNotEmpty ? allItems.first.id : null;
      }

      update();
      await loadMappings(selectId: selectId);
    } catch (errorValue) {
      initialLoading = false;
      pageError = errorValue.toString();
      update();
    }
  }

  Future<void> loadMappings({int? selectId}) async {
    if (selectedMasterId == null) {
      items = const <ItemAlternateModel>[];
      filteredItems = const <ItemAlternateModel>[];
      initialLoading = false;
      resetForm(notify: false);
      update();
      return;
    }

    try {
      final responses =
          await Future.wait<PaginatedResponse<ItemAlternateModel>>([
            _inventoryService.itemAlternates(
              filters: {
                'per_page': 300,
                'sort_by': 'priority_order',
                'sort_order': 'asc',
                'item_id': selectedMasterId,
              },
            ),
            _inventoryService.itemAlternates(
              filters: {
                'per_page': 300,
                'sort_by': 'priority_order',
                'sort_order': 'asc',
                'alternate_item_id': selectedMasterId,
              },
            ),
          ]);

      final uniqueItems = <int?, ItemAlternateModel>{};
      for (final item in <ItemAlternateModel>[
        ...(responses[0].data ?? const <ItemAlternateModel>[]),
        ...(responses[1].data ?? const <ItemAlternateModel>[]),
      ]) {
        uniqueItems[item.id] = item;
      }
      final nextItems = uniqueItems.values.toList(growable: false);

      items = nextItems;
      filteredItems = nextItems;
      initialLoading = false;

      final selected = selectId != null
          ? nextItems.cast<ItemAlternateModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedItem == null
                ? null
                : nextItems.cast<ItemAlternateModel?>().firstWhere(
                    (item) => item?.id == selectedItem?.id,
                    orElse: () => null,
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

  List<ItemModel> filterMasterListItems(List<ItemModel> source, String query) {
    return filterMasterList(source, query, (item) {
      return [item.itemCode, item.itemName, item.itemType ?? ''];
    });
  }

  void _applyMasterSearch() {
    filteredMasterItems = filterMasterListItems(
      allItems,
      masterSearchController.text,
    );
    update();
  }

  void selectMaster(int id) {
    selectedMasterId = id;
    update();
    loadMappings();
  }

  void selectMapping(ItemAlternateModel item, {bool notify = true}) {
    if (selectedItem?.id == item.id) {
      resetForm(notify: notify);
      return;
    }
    showDraftTile = false;
    selectedItem = item;
    counterpartyId = counterpartyIdFor(item);
    priorityController.text = item.priorityOrder?.toString() ?? '1';
    remarksController.text = item.reason ?? '';
    isActive = item.isActive;
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedItem = null;
    counterpartyId = null;
    priorityController.text = '1';
    remarksController.clear();
    isActive = true;
    formError = null;
    if (notify) {
      update();
    }
  }

  Future<void> save() async {
    if (formKey.currentState?.validate() != true || selectedMasterId == null) {
      return;
    }

    saving = true;
    formError = null;
    update();

    final model = ItemAlternateModel(
      id: selectedItem?.id,
      itemId: itemIdForSave(),
      alternateItemId: alternateItemIdForSave(),
      priorityOrder: int.tryParse(priorityController.text.trim()) ?? 1,
      isActive: isActive,
      reason: nullIfEmpty(remarksController.text),
    );

    try {
      final response = selectedItem == null
          ? await _inventoryService.createItemAlternate(model)
          : await _inventoryService.updateItemAlternate(
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

  int? itemIdForSave() {
    if (selectedItem != null && fixedItemId != null) {
      if (selectedItem!.itemId == selectedMasterId) {
        return selectedMasterId;
      }
      if (selectedItem!.alternateItemId == selectedMasterId) {
        return counterpartyId;
      }
    }
    return selectedMasterId;
  }

  int? alternateItemIdForSave() {
    if (selectedItem != null && fixedItemId != null) {
      if (selectedItem!.itemId == selectedMasterId) {
        return counterpartyId;
      }
      if (selectedItem!.alternateItemId == selectedMasterId) {
        return selectedMasterId;
      }
    }
    return counterpartyId;
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
      final response = await _inventoryService.deleteItemAlternate(id);
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

  Future<void> confirmDelete(ItemAlternateModel item) async {
    selectMapping(item);
    await deleteSelected();
  }

  String itemLabel(ItemModel item) {
    final code = item.itemCode.trim();
    final name = item.itemName.trim();
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

  String get selectedMasterTitle {
    final selected = allItems.cast<ItemModel?>().firstWhere(
      (item) => item?.id == selectedMasterId,
      orElse: () => null,
    );
    return selected == null ? pageTitle : itemLabel(selected);
  }

  int? counterpartyIdFor(ItemAlternateModel item) {
    if (item.itemId == selectedMasterId) {
      return item.alternateItemId;
    }
    if (item.alternateItemId == selectedMasterId) {
      return item.itemId;
    }
    return item.alternateItemId;
  }

  String counterpartyLabelFor(ItemAlternateModel item) {
    final isDirect = item.itemId == selectedMasterId;
    final code = isDirect ? item.alternateItemCode : item.itemCode;
    final name = isDirect ? item.alternateItemName : item.itemName;
    if (name.isNotEmpty) {
      return name;
    }
    return code;
  }

  List<ItemModel> get availableCounterpartyOptions {
    final selectedIds = items.map(counterpartyIdFor).whereType<int>().toSet();
    return allItems
        .where(
          (item) =>
              item.id != null &&
              item.id != selectedMasterId &&
              !selectedIds.contains(item.id),
        )
        .toList(growable: false);
  }

  List<ItemModel> get dropdownCounterpartyOptions {
    final options = availableCounterpartyOptions.toList(growable: true);
    if (counterpartyId != null) {
      final selected = allItems.cast<ItemModel?>().firstWhere(
        (item) => item?.id == counterpartyId,
        orElse: () => null,
      );
      if (selected != null &&
          options.every((option) => option.id != selected.id)) {
        options.insert(0, selected);
      }
    }
    return options;
  }

  ItemModel? get selectedMasterItem => allItems.cast<ItemModel?>().firstWhere(
    (item) => item?.id == selectedMasterId,
    orElse: () => null,
  );

  ItemModel? get selectedCounterpartyItem => allItems
      .cast<ItemModel?>()
      .firstWhere((item) => item?.id == counterpartyId, orElse: () => null);

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

  void setCounterpartyId(int? value) {
    counterpartyId = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }
}
