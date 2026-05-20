import '../../../screen.dart';

class GstTaxRuleManagementController extends GetxController {
  static const List<DropdownMenuItem<String>> transactionTypes =
      <DropdownMenuItem<String>>[
        DropdownMenuItem(value: 'sales', child: Text('Sales')),
        DropdownMenuItem(value: 'purchase', child: Text('Purchase')),
        DropdownMenuItem(value: 'sales_return', child: Text('Sales Return')),
        DropdownMenuItem(
          value: 'purchase_return',
          child: Text('Purchase Return'),
        ),
        DropdownMenuItem(value: 'service_sales', child: Text('Service Sales')),
        DropdownMenuItem(
          value: 'service_purchase',
          child: Text('Service Purchase'),
        ),
      ];
  static const List<DropdownMenuItem<String>> itemTypes =
      <DropdownMenuItem<String>>[
        DropdownMenuItem(value: 'all', child: Text('All')),
        DropdownMenuItem(value: 'stock', child: Text('Stock')),
        DropdownMenuItem(value: 'service', child: Text('Service')),
        DropdownMenuItem(value: 'manufactured', child: Text('Manufactured')),
        DropdownMenuItem(value: 'raw_material', child: Text('Raw Material')),
        DropdownMenuItem(value: 'semi_finished', child: Text('Semi Finished')),
        DropdownMenuItem(
          value: 'finished_goods',
          child: Text('Finished Goods'),
        ),
        DropdownMenuItem(value: 'consumable', child: Text('Consumable')),
        DropdownMenuItem(value: 'asset', child: Text('Asset')),
        DropdownMenuItem(value: 'non_stock', child: Text('Non Stock')),
      ];
  static const List<DropdownMenuItem<String>> placeResults =
      <DropdownMenuItem<String>>[
        DropdownMenuItem(value: 'all', child: Text('All')),
        DropdownMenuItem(value: 'intra_state', child: Text('Intra State')),
        DropdownMenuItem(value: 'inter_state', child: Text('Inter State')),
        DropdownMenuItem(value: 'export', child: Text('Export')),
        DropdownMenuItem(value: 'import', child: Text('Import')),
        DropdownMenuItem(value: 'sez', child: Text('SEZ')),
        DropdownMenuItem(
          value: 'reverse_charge',
          child: Text('Reverse Charge'),
        ),
      ];
  static const List<DropdownMenuItem<String>> taxApplications =
      <DropdownMenuItem<String>>[
        DropdownMenuItem(value: 'cgst_sgst', child: Text('CGST + SGST')),
        DropdownMenuItem(value: 'igst', child: Text('IGST')),
        DropdownMenuItem(value: 'cess_only', child: Text('CESS Only')),
        DropdownMenuItem(value: 'exempt', child: Text('Exempt')),
        DropdownMenuItem(value: 'nil_rated', child: Text('Nil Rated')),
        DropdownMenuItem(value: 'non_gst', child: Text('Non GST')),
      ];

  GstTaxRuleManagementController();

  final TaxesService _taxesService = TaxesService();
  final InventoryService _inventoryService = InventoryService();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priorityController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<GstTaxRuleModel> items = const <GstTaxRuleModel>[];
  List<GstTaxRuleModel> filteredItems = const <GstTaxRuleModel>[];
  List<TaxCodeModel> taxCodes = const <TaxCodeModel>[];
  GstTaxRuleModel? selectedItem;
  String transactionType = 'sales';
  String itemType = 'all';
  int? taxCodeId;
  String placeResult = 'all';
  String taxApplication = 'cgst_sgst';
  bool reverseCharge = false;
  bool itcAllowed = true;
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
    codeController.dispose();
    nameController.dispose();
    priorityController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  Future<void> loadData({int? selectId}) async {
    initialLoading = items.isEmpty;
    pageError = null;
    update();

    try {
      final responses = await Future.wait<dynamic>([
        _taxesService.gstTaxRules(filters: const {'per_page': 200}),
        _inventoryService.taxCodes(filters: const {'per_page': 200}),
      ]);

      final nextItems =
          (responses[0] as PaginatedResponse<GstTaxRuleModel>).data ??
          const <GstTaxRuleModel>[];
      final nextTaxCodes =
          (responses[1] as PaginatedResponse<TaxCodeModel>).data ??
          const <TaxCodeModel>[];

      items = nextItems;
      taxCodes = nextTaxCodes;
      filteredItems = _filterItems(nextItems, searchController.text);
      initialLoading = false;

      final selected = selectId != null
          ? nextItems.cast<GstTaxRuleModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedItem == null
                ? (nextItems.isNotEmpty ? nextItems.first : null)
                : nextItems.cast<GstTaxRuleModel?>().firstWhere(
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

  List<GstTaxRuleModel> _filterItems(
    List<GstTaxRuleModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (item) {
      return [item.ruleCode, item.ruleName, item.transactionType];
    });
  }

  void _applySearch() {
    filteredItems = _filterItems(items, searchController.text);
    update();
  }

  void selectItem(GstTaxRuleModel item, {bool notify = true}) {
    selectedItem = item;
    codeController.text = item.ruleCode;
    nameController.text = item.ruleName;
    priorityController.text = item.priorityOrder?.toString() ?? '1';
    remarksController.text = item.remarks ?? '';
    transactionType = item.transactionType.isEmpty ? 'sales' : item.transactionType;
    itemType = item.itemType.isEmpty ? 'all' : item.itemType;
    taxCodeId = item.taxCodeId;
    placeResult = item.placeOfSupplyResult.isEmpty
        ? 'all'
        : item.placeOfSupplyResult;
    taxApplication = item.taxApplication.isEmpty
        ? 'cgst_sgst'
        : item.taxApplication;
    reverseCharge = item.reverseChargeApplicable;
    itcAllowed = item.inputTaxCreditAllowed;
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
    priorityController.text = '1';
    remarksController.clear();
    transactionType = 'sales';
    itemType = 'all';
    taxCodeId = taxCodes.isNotEmpty ? taxCodes.first.id : null;
    placeResult = 'all';
    taxApplication = 'cgst_sgst';
    reverseCharge = false;
    itcAllowed = true;
    isActive = true;
    formError = null;
    if (notify) {
      update();
    }
  }

  void setTransactionType(String? value) {
    transactionType = value ?? 'sales';
    update();
  }

  void setItemType(String? value) {
    itemType = value ?? 'all';
    update();
  }

  void setTaxCodeId(int? value) {
    taxCodeId = value;
    update();
  }

  void setPlaceResult(String? value) {
    placeResult = value ?? 'all';
    update();
  }

  void setTaxApplication(String? value) {
    taxApplication = value ?? 'cgst_sgst';
    update();
  }

  void setReverseCharge(bool value) {
    reverseCharge = value;
    update();
  }

  void setItcAllowed(bool value) {
    itcAllowed = value;
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

    final model = GstTaxRuleModel(
      id: selectedItem?.id,
      ruleCode: codeController.text.trim(),
      ruleName: nameController.text.trim(),
      transactionType: transactionType,
      itemType: itemType,
      taxCodeId: taxCodeId,
      placeOfSupplyResult: placeResult,
      taxApplication: taxApplication,
      reverseChargeApplicable: reverseCharge,
      inputTaxCreditAllowed: itcAllowed,
      priorityOrder: int.tryParse(priorityController.text.trim()) ?? 1,
      isActive: isActive,
      remarks: nullIfEmpty(remarksController.text),
    );

    try {
      final response = selectedItem == null
          ? await _taxesService.createGstTaxRule(model)
          : await _taxesService.updateGstTaxRule(selectedItem!.id!, model);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadData(selectId: response.data?.id);
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
      final response = await _taxesService.deleteGstTaxRule(id);
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
}
