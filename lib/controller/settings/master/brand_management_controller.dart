import '../../../screen.dart';

class BrandManagementController extends GetxController {
  BrandManagementController();

  final InventoryService _inventoryService = InventoryService();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<BrandModel> brands = const <BrandModel>[];
  List<BrandModel> filteredBrands = const <BrandModel>[];
  BrandModel? selectedBrand;
  bool isActive = true;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    loadBrands();
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
    remarksController.dispose();
    super.onClose();
  }

  Future<void> loadBrands({int? selectId}) async {
    initialLoading = brands.isEmpty;
    pageError = null;
    update();

    try {
      final response = await _inventoryService.brands(
        filters: const {'per_page': 200, 'sort_by': 'brand_name'},
      );
      final items = response.data ?? const <BrandModel>[];

      brands = items;
      filteredBrands = _filterBrands(items, searchController.text);
      initialLoading = false;

      final selected = selectId != null
          ? items.cast<BrandModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedBrand == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<BrandModel?>().firstWhere(
                    (item) => item?.id == selectedBrand?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected != null) {
        selectBrand(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (error) {
      initialLoading = false;
      pageError = error.toString();
    }

    update();
  }

  List<BrandModel> _filterBrands(List<BrandModel> source, String query) {
    return filterMasterList(source, query, (brand) {
      return [
        brand.brandCode ?? '',
        brand.brandName ?? '',
        brand.remarks ?? '',
      ];
    });
  }

  void _applySearch() {
    filteredBrands = _filterBrands(brands, searchController.text);
    update();
  }

  void selectBrand(BrandModel brand, {bool notify = true}) {
    selectedBrand = brand;
    codeController.text = brand.brandCode ?? '';
    nameController.text = brand.brandName ?? '';
    remarksController.text = brand.remarks ?? '';
    isActive = brand.isActive;
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedBrand = null;
    codeController.clear();
    nameController.clear();
    remarksController.clear();
    isActive = true;
    formError = null;
    if (notify) {
      update();
    }
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

  Future<void> save() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    saving = true;
    formError = null;
    update();

    final model = BrandModel(
      id: selectedBrand?.id,
      brandCode: codeController.text.trim(),
      brandName: nameController.text.trim(),
      remarks: nullIfEmpty(remarksController.text),
      isActive: isActive,
    );

    try {
      final response = selectedBrand == null
          ? await _inventoryService.createBrand(model)
          : await _inventoryService.updateBrand(selectedBrand!.id!, model);
      final saved = response.data;
      if (saved == null) {
        formError = response.message;
        update();
        return;
      }

      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadBrands(selectId: saved.id);
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> delete() async {
    final id = selectedBrand?.id;
    if (id == null) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _inventoryService.deleteBrand(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadBrands();
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }
}
