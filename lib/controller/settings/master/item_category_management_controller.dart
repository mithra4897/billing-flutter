import '../../../screen.dart';

class ItemCategoryManagementController extends GetxController {
  ItemCategoryManagementController();

  final InventoryService _inventoryService = InventoryService();
  final MediaService _mediaService = MediaService();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController imagePathController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  bool uploadingImage = false;
  String? pageError;
  String? formError;
  List<ItemCategoryModel> items = const <ItemCategoryModel>[];
  List<ItemCategoryModel> filteredItems = const <ItemCategoryModel>[];
  ItemCategoryModel? selectedItem;
  int? parentCategoryId;
  bool isActive = true;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    loadItems();
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
    imagePathController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  Future<void> loadItems({int? selectId}) async {
    initialLoading = items.isEmpty;
    pageError = null;
    update();

    try {
      final response = await _inventoryService.itemCategories(
        filters: const {'per_page': 200, 'sort_by': 'category_name'},
      );
      final nextItems = response.data ?? const <ItemCategoryModel>[];

      items = nextItems;
      filteredItems = _filterItems(nextItems, searchController.text);
      initialLoading = false;

      final selected = selectId != null
          ? nextItems.cast<ItemCategoryModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedItem == null
                ? (nextItems.isNotEmpty ? nextItems.first : null)
                : nextItems.cast<ItemCategoryModel?>().firstWhere(
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

  List<ItemCategoryModel> _filterItems(
    List<ItemCategoryModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (item) {
      return [item.categoryCode, item.categoryName];
    });
  }

  void _applySearch() {
    filteredItems = _filterItems(items, searchController.text);
    update();
  }

  void selectItem(ItemCategoryModel item, {bool notify = true}) {
    selectedItem = item;
    codeController.text = item.categoryCode;
    nameController.text = item.categoryName;
    imagePathController.text = item.imagePath ?? '';
    remarksController.text = item.remarks ?? '';
    parentCategoryId = item.parentCategoryId;
    isActive = item.isActive;
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedItem = null;
    codeController.clear();
    nameController.clear();
    imagePathController.clear();
    remarksController.clear();
    parentCategoryId = null;
    isActive = true;
    formError = null;
    if (notify) {
      update();
    }
  }

  List<ItemCategoryModel> get parentOptions => items
      .where((item) => item.id != selectedItem?.id)
      .toList(growable: false);

  void setParentCategoryId(int? value) {
    parentCategoryId = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  void startNew({required bool isDesktop}) {
    resetForm();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }

  Future<void> uploadCategoryImage(BuildContext context) async {
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
      documentType: 'item_categories',
      documentId: selectedItem?.id,
      purpose: 'category_image',
      folder: 'inventory/item-categories',
      isPublic: true,
    );
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    saving = true;
    formError = null;
    update();

    final model = ItemCategoryModel(
      id: selectedItem?.id,
      categoryCode: codeController.text.trim(),
      categoryName: nameController.text.trim(),
      parentCategoryId: parentCategoryId,
      imagePath: nullIfEmpty(imagePathController.text),
      isActive: isActive,
      remarks: nullIfEmpty(remarksController.text),
    );

    try {
      final response = selectedItem == null
          ? await _inventoryService.createItemCategory(model)
          : await _inventoryService.updateItemCategory(
              selectedItem!.id!,
              model,
            );
      final saved = response.data;
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadItems(selectId: saved?.id);
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
      final response = await _inventoryService.deleteItemCategory(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadItems();
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }
}
