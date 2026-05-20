import '../../../screen.dart';

class UomConversionManagementController extends GetxController {
  UomConversionManagementController();

  final InventoryService _inventoryService = InventoryService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController factorController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<UomConversionModel> items = const <UomConversionModel>[];
  List<UomConversionModel> filteredItems = const <UomConversionModel>[];
  List<UomModel> uoms = const <UomModel>[];
  UomConversionModel? selectedItem;
  int? fromUomId;
  int? toUomId;
  bool isActive = true;

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
    factorController.dispose();
    super.onClose();
  }

  Future<void> loadData({int? selectId}) async {
    initialLoading = items.isEmpty;
    pageError = null;
    update();

    try {
      final responses = await Future.wait<dynamic>([
        _inventoryService.uomConversions(
          filters: const {
            'per_page': 200,
            'sort_by': 'id',
            'sort_order': 'desc',
          },
        ),
        _inventoryService.uoms(
          filters: const {
            'per_page': 200,
            'sort_by': 'uom_name',
            'sort_order': 'asc',
          },
        ),
      ]);

      final nextItems =
          (responses[0] as PaginatedResponse<UomConversionModel>).data ??
          const <UomConversionModel>[];
      final nextUoms =
          (responses[1] as PaginatedResponse<UomModel>).data ??
          const <UomModel>[];

      items = nextItems;
      uoms = nextUoms;
      filteredItems = _filterItems(nextItems, searchController.text);
      initialLoading = false;

      final selected = selectId != null
          ? nextItems.cast<UomConversionModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedItem == null
                ? (nextItems.isNotEmpty ? nextItems.first : null)
                : nextItems.cast<UomConversionModel?>().firstWhere(
                    (item) => item?.id == selectedItem?.id,
                    orElse: () => nextItems.isNotEmpty ? nextItems.first : null,
                  ));

      if (selected != null) {
        selectItem(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (errorValue) {
      initialLoading = false;
      pageError = errorValue.toString();
    }

    update();
  }

  List<UomConversionModel> _filterItems(
    List<UomConversionModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (item) {
      return [
        item.fromDisplay,
        item.toDisplay,
        item.fromUomCode,
        item.toUomCode,
        item.conversionFactor?.toString() ?? '',
      ];
    });
  }

  void _applySearch() {
    filteredItems = _filterItems(items, searchController.text);
    update();
  }

  void selectItem(UomConversionModel item, {bool notify = true}) {
    selectedItem = item;
    fromUomId = item.fromUomId;
    toUomId = item.toUomId;
    factorController.text = item.conversionFactor?.toString() ?? '';
    isActive = item.isActive;
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedItem = null;
    fromUomId = uoms.isNotEmpty ? uoms.first.id : null;
    toUomId = uoms.length > 1
        ? uoms
              .firstWhere(
                (item) => item.id != fromUomId,
                orElse: () => uoms.first,
              )
              .id
        : null;
    factorController.clear();
    isActive = true;
    formError = null;
    if (notify) {
      update();
    }
  }

  List<UomModel> get toUomOptions =>
      uoms.where((uom) => uom.id != fromUomId).toList(growable: false);

  void setFromUomId(int? value) {
    fromUomId = value;
    if (toUomId == value) {
      toUomId = toUomOptions.isNotEmpty ? toUomOptions.first.id : null;
    }
    update();
  }

  void setToUomId(int? value) {
    toUomId = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    saving = true;
    formError = null;
    update();

    final model = UomConversionModel(
      id: selectedItem?.id,
      fromUomId: fromUomId,
      toUomId: toUomId,
      conversionFactor: double.tryParse(factorController.text.trim()),
      isActive: isActive,
    );

    try {
      final response = selectedItem == null
          ? await _inventoryService.createUomConversion(model)
          : await _inventoryService.updateUomConversion(
              selectedItem!.id!,
              model,
            );
      final saved = response.data;

      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadData(selectId: saved?.id);
    } catch (errorValue) {
      formError = errorValue.toString();
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
      final response = await _inventoryService.deleteUomConversion(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadData();
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  void startNew({required bool isDesktop}) {
    resetForm();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }
}
