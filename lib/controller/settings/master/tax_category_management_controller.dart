import '../../../screen.dart';

class TaxCategoryManagementController extends GetxController {
  static const List<AppDropdownItem<String>> taxTypeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'gst', label: 'GST'),
        AppDropdownItem(value: 'igst', label: 'IGST'),
        AppDropdownItem(value: 'cgst_sgst', label: 'CGST + SGST'),
        AppDropdownItem(value: 'cess', label: 'CESS'),
        AppDropdownItem(value: 'none', label: 'No Tax'),
      ];

  TaxCategoryManagementController();

  final InventoryService _inventoryService = InventoryService();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController cessRateController = TextEditingController();
  final TextEditingController hsnSacController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<TaxCodeModel> taxCodes = const <TaxCodeModel>[];
  List<TaxCodeModel> filteredTaxCodes = const <TaxCodeModel>[];
  TaxCodeModel? selectedTaxCode;
  String taxType = 'gst';
  bool isActive = true;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    loadTaxCodes();
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
    rateController.dispose();
    cessRateController.dispose();
    hsnSacController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  Future<void> loadTaxCodes({int? selectId}) async {
    initialLoading = taxCodes.isEmpty;
    pageError = null;
    update();

    try {
      final response = await _inventoryService.taxCodes(
        filters: const {'per_page': 100, 'sort_by': 'tax_name'},
      );
      final items = response.data ?? const <TaxCodeModel>[];

      taxCodes = items;
      filteredTaxCodes = _filterTaxCodes(items, searchController.text);
      initialLoading = false;

      final selected = selectId != null
          ? items.cast<TaxCodeModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedTaxCode == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<TaxCodeModel?>().firstWhere(
                    (item) => item?.id == selectedTaxCode?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected != null) {
        selectTaxCode(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (error) {
      initialLoading = false;
      pageError = error.toString();
    }

    update();
  }

  List<TaxCodeModel> _filterTaxCodes(List<TaxCodeModel> source, String query) {
    return filterMasterList(source, query, (taxCode) {
      return [
        taxCode.taxCode ?? '',
        taxCode.taxName ?? '',
        taxCode.taxType ?? '',
      ];
    });
  }

  void _applySearch() {
    filteredTaxCodes = _filterTaxCodes(taxCodes, searchController.text);
    update();
  }

  void selectTaxCode(TaxCodeModel taxCode, {bool notify = true}) {
    selectedTaxCode = taxCode;
    codeController.text = taxCode.taxCode ?? '';
    nameController.text = taxCode.taxName ?? '';
    rateController.text = taxCode.taxRate?.toString() ?? '';
    cessRateController.text = taxCode.cessRate?.toString() ?? '';
    hsnSacController.text = taxCode.hsnSacCode ?? '';
    remarksController.text = taxCode.remarks ?? '';
    taxType = taxCode.taxType ?? 'gst';
    isActive = taxCode.isActive;
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedTaxCode = null;
    codeController.clear();
    nameController.clear();
    rateController.clear();
    cessRateController.clear();
    hsnSacController.clear();
    remarksController.clear();
    taxType = 'gst';
    isActive = true;
    formError = null;
    if (notify) {
      update();
    }
  }

  void setTaxType(String? value) {
    taxType = value ?? 'gst';
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

  Future<void> save() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    saving = true;
    formError = null;
    update();

    final model = TaxCodeModel(
      id: selectedTaxCode?.id,
      taxCode: codeController.text.trim(),
      taxName: nameController.text.trim(),
      taxType: taxType,
      taxRate: double.tryParse(rateController.text.trim()),
      cessRate: double.tryParse(cessRateController.text.trim()),
      hsnSacCode: nullIfEmpty(hsnSacController.text),
      remarks: nullIfEmpty(remarksController.text),
      isActive: isActive,
    );

    try {
      final response = selectedTaxCode == null
          ? await _inventoryService.createTaxCode(model)
          : await _inventoryService.updateTaxCode(selectedTaxCode!.id!, model);
      final saved = response.data;
      if (saved == null) {
        formError = response.message;
        update();
        return;
      }

      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadTaxCodes(selectId: saved.id);
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> delete() async {
    final id = selectedTaxCode?.id;
    if (id == null) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _inventoryService.deleteTaxCode(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadTaxCodes();
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }
}
