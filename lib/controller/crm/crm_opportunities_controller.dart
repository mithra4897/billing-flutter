import '../../screen.dart';

class CrmOpportunitiesController extends GetxController {
  static const int allFilterIntValue = 0;
  static const String allFilterStringValue = '__all__';
  static const List<AppDropdownItem<String>> filterStatusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'open', label: 'Open'),
        AppDropdownItem(value: 'won', label: 'Won'),
      ];

  CrmOpportunitiesController({
    required this.startInNewMode,
    required this.initialSelectId,
  });

  final bool startInNewMode;
  final int? initialSelectId;

  final CrmService _crmService = CrmService();
  final InventoryService _inventoryService = InventoryService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController expectedValueController =
      TextEditingController();
  final TextEditingController probabilityController = TextEditingController();
  final TextEditingController expectedCloseDateController =
      TextEditingController();
  final TextEditingController filterCloseFromController =
      TextEditingController();
  final TextEditingController filterCloseToController = TextEditingController();

  int activeTabIndex = 0;
  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<CrmOpportunityModel> items = const <CrmOpportunityModel>[];
  List<CrmOpportunityModel> filteredItems = const <CrmOpportunityModel>[];
  List<CrmEnquiryModel> enquiries = const <CrmEnquiryModel>[];
  List<CrmStageModel> stages = const <CrmStageModel>[];
  List<ItemModel> itemsLookup = const <ItemModel>[];
  CrmOpportunityModel? selectedItem;
  int? enquiryId;
  int? stageId;
  int? filterEnquiryId;
  int? filterStageId;
  String? filterStatus;
  String status = 'open';
  List<OpportunityProductDraft> products = <OpportunityProductDraft>[];
  int? expandedProductIndex;
  Map<String, dynamic>? salesChain;
  bool appliedInitialNewMode = false;
  bool filtersApplied = false;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(applySearch);
    loadPage(selectId: initialSelectId);
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(applySearch)
      ..dispose();
    nameController.dispose();
    expectedValueController.dispose();
    probabilityController.dispose();
    expectedCloseDateController.dispose();
    filterCloseFromController.dispose();
    filterCloseToController.dispose();
    disposeProducts(products);
    super.onClose();
  }

  static bool isCompletedOpportunity(CrmOpportunityModel item) =>
      stringValue(item.toJson(), 'status') == 'won';

  String normalizedStageType(CrmStageModel stage) =>
      stringValue(stage.toJson(), 'stage_type').trim().toLowerCase();

  bool isAllowedOpportunityStage(CrmStageModel stage) {
    final type = normalizedStageType(stage);
    return type == 'opportunity' ||
        type == 'closed_won' ||
        type == 'closed_lost' ||
        type == 'closed won' ||
        type == 'closed lost';
  }

  Future<void> loadPage({int? selectId}) async {
    initialLoading = items.isEmpty;
    pageError = null;
    update();

    try {
      final responses = await Future.wait<dynamic>([
        _crmService.opportunities(
          filters: const {'per_page': 200, 'sort_by': 'opportunity_name'},
        ),
        _crmService.enquiries(
          filters: const {'per_page': 300, 'sort_by': 'enquiry_no'},
        ),
        _crmService.stages(
          filters: const {'per_page': 200, 'sort_by': 'sequence_no'},
        ),
        _inventoryService.items(
          filters: const {'per_page': 300, 'sort_by': 'item_name'},
        ),
      ]);

      items =
          (responses[0] as PaginatedResponse<CrmOpportunityModel>).data ??
              const <CrmOpportunityModel>[];
      enquiries =
          (responses[1] as PaginatedResponse<CrmEnquiryModel>).data ??
              const <CrmEnquiryModel>[];
      stages = () {
        final allStages =
            ((responses[2] as PaginatedResponse<CrmStageModel>).data ??
                    const <CrmStageModel>[])
                .where((item) => boolValue(item.toJson(), 'is_active', fallback: true))
                .toList(growable: false);
        final filtered =
            allStages.where(isAllowedOpportunityStage).toList(growable: false);
        return filtered.isNotEmpty ? filtered : allStages;
      }();
      itemsLookup = ((responses[3] as PaginatedResponse<ItemModel>).data ??
              const <ItemModel>[])
          .where((item) => item.isActive)
          .toList();
      initialLoading = false;
      applySearch(notify: false);

      if (startInNewMode && selectId == null && !appliedInitialNewMode) {
        appliedInitialNewMode = true;
        resetForm(notify: false);
        update();
        return;
      }

      final selected = selectId != null
          ? items.cast<CrmOpportunityModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : (selectedItem == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<CrmOpportunityModel?>().firstWhere(
                    (item) =>
                        intValue(item?.toJson() ?? const {}, 'id') ==
                        intValue(selectedItem!.toJson(), 'id'),
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected != null) {
        await selectItem(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (error) {
      initialLoading = false;
      pageError = error.toString();
    }

    update();
  }

  void applySearch({bool notify = true}) {
    filteredItems = filterMasterList(items, searchController.text, (item) {
          final data = item.toJson();
          return [
            stringValue(data, 'opportunity_name'),
            stringValue(data, 'status'),
            stringValue(data, 'expected_value'),
          ];
        })
        .where((item) {
          final data = item.toJson();
          final completed = isCompletedOpportunity(item);
          final requestedStatus =
              (filtersApplied ? (filterStatus ?? allFilterStringValue) : (filterStatus ?? ''))
                  .trim();
          final showAllStatuses =
              filtersApplied && requestedStatus == allFilterStringValue;
          if (completed && !showAllStatuses && requestedStatus != 'won') {
            return false;
          }
          final closeDate = displayDate(
            nullableStringValue(data, 'expected_close_date'),
          );
          final filterFrom = filterCloseFromController.text.trim();
          final filterTo = filterCloseToController.text.trim();
          if (filterEnquiryId != null &&
              intValue(data, 'enquiry_id') != filterEnquiryId) {
            return false;
          }
          if (filterStageId != null &&
              intValue(data, 'stage_id') != filterStageId) {
            return false;
          }
          if ((filterStatus ?? '').isNotEmpty &&
              filterStatus != allFilterStringValue &&
              stringValue(data, 'status') != filterStatus) {
            return false;
          }
          if (filterFrom.isNotEmpty &&
              (closeDate.isEmpty || closeDate.compareTo(filterFrom) < 0)) {
            return false;
          }
          if (filterTo.isNotEmpty &&
              (closeDate.isEmpty || closeDate.compareTo(filterTo) > 0)) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
    if (notify) update();
  }

  Future<void> selectItem(
    CrmOpportunityModel item, {
    bool notify = true,
  }) async {
    final id = intValue(item.toJson(), 'id');
    if (id == null) return;
    final response = await _crmService.opportunity(id);
    final full = response.data ?? item;
    final data = full.toJson();
    final nextProducts =
        (data['products'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(OpportunityProductDraft.fromJson)
            .toList(growable: true);

    disposeProducts(products);
    selectedItem = full;
    enquiryId = intValue(data, 'enquiry_id');
    stageId = intValue(data, 'stage_id');
    status = stringValue(data, 'status', 'open');
    nameController.text = stringValue(data, 'opportunity_name');
    expectedValueController.text = stringValue(data, 'expected_value');
    probabilityController.text = stringValue(data, 'probability_percent');
    expectedCloseDateController.text = displayDate(
      nullableStringValue(data, 'expected_close_date'),
    );
    products = nextProducts;
    expandedProductIndex = null;
    formError = null;
    await refreshSalesChainForOpportunity(id);
    if (notify) update();
  }

  int? selectedOpportunityId() => intValue(selectedItem?.toJson() ?? const {}, 'id');

  Future<void> refreshSalesChainForOpportunity(int opportunityId) async {
    try {
      final response = await _crmService.salesChain(
        opportunityId: opportunityId,
      );
      salesChain = response.data;
    } catch (_) {
      salesChain = null;
    }
  }

  void resetForm({bool notify = true}) {
    disposeProducts(products);
    selectedItem = null;
    enquiryId = null;
    stageId = null;
    status = 'open';
    nameController.clear();
    expectedValueController.clear();
    probabilityController.clear();
    expectedCloseDateController.clear();
    products = <OpportunityProductDraft>[];
    expandedProductIndex = null;
    formError = null;
    activeTabIndex = 0;
    salesChain = null;
    if (notify) update();
  }

  void disposeProducts(List<OpportunityProductDraft> source) {
    for (final product in source) {
      product.dispose();
    }
  }

  void addProduct() {
    products = List<OpportunityProductDraft>.from(products)
      ..add(OpportunityProductDraft());
    expandedProductIndex = products.length - 1;
    update();
  }

  void removeProduct(int index) {
    final nextProducts = List<OpportunityProductDraft>.from(products);
    nextProducts.removeAt(index).dispose();
    products = nextProducts;
    if (expandedProductIndex == index) {
      expandedProductIndex = null;
    } else if ((expandedProductIndex ?? -1) > index) {
      expandedProductIndex = expandedProductIndex! - 1;
    }
    update();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    saving = true;
    formError = null;
    update();

    final payload = CrmOpportunityModel.fromJson({
      'enquiry_id': enquiryId,
      'opportunity_name': nameController.text.trim(),
      'expected_value': double.tryParse(expectedValueController.text.trim()) ?? 0,
      'stage_id': stageId,
      'probability_percent':
          double.tryParse(probabilityController.text.trim()) ?? 0,
      'expected_close_date': nullIfEmpty(expectedCloseDateController.text),
      'status': status,
      'products': products.map((item) => item.toJson()).toList(growable: false),
    });

    try {
      final response = selectedItem == null
          ? await _crmService.createOpportunity(payload)
          : await _crmService.updateOpportunity(
              intValue(selectedItem!.toJson(), 'id')!,
              payload,
            );
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadPage(
        selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
      );
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> delete() async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) return;
    try {
      final response = await _crmService.deleteOpportunity(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadPage();
    } catch (error) {
      formError = error.toString();
      update();
    }
  }

  Future<void> win() async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) return;
    try {
      final response = await _crmService.winOpportunity(
        id,
        CrmOpportunityModel.fromJson(const <String, dynamic>{}),
      );
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadPage(selectId: id);
    } catch (error) {
      formError = error.toString();
      update();
    }
  }

  Future<void> lose() async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) return;
    try {
      final response = await _crmService.loseOpportunity(
        id,
        CrmOpportunityModel.fromJson(const <String, dynamic>{}),
      );
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadPage(selectId: id);
    } catch (error) {
      formError = error.toString();
      update();
    }
  }

  void setFilterStageId(int? value) {
    filterStageId = value == allFilterIntValue ? null : value;
    update();
  }

  void setFilterStatus(String? value) {
    filterStatus = value;
    update();
  }

  void clearFilters() {
    filterStageId = null;
    filterStatus = null;
    filtersApplied = false;
    filterCloseFromController.clear();
    filterCloseToController.clear();
    applySearch();
  }

  void markFiltersApplied() {
    filtersApplied = true;
    applySearch();
  }

  void setStageId(int? value) {
    stageId = value;
    update();
  }

  void setEnquiryId(int? value) {
    enquiryId = value;
    update();
  }

  void setExpandedProductIndex(int? value) {
    expandedProductIndex = value;
    update();
  }

  void setActiveTabIndex(int index) {
    activeTabIndex = index;
    update();
  }
}

class OpportunityProductDraft {
  OpportunityProductDraft({this.itemId, String? qty, String? estimatedPrice})
    : qtyController = TextEditingController(text: qty ?? ''),
      estimatedPriceController = TextEditingController(
        text: estimatedPrice ?? '',
      );

  factory OpportunityProductDraft.fromJson(Map<String, dynamic> json) {
    return OpportunityProductDraft(
      itemId: intValue(json, 'item_id'),
      qty: stringValue(json, 'qty'),
      estimatedPrice: stringValue(json, 'estimated_price'),
    );
  }

  int? itemId;
  final TextEditingController qtyController;
  final TextEditingController estimatedPriceController;

  String itemLabel(List<ItemModel> items) {
    final item = items.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == itemId,
      orElse: () => null,
    );
    return item?.toString() ?? 'Opportunity Product';
  }

  String get qtySummary {
    final qty = qtyController.text.trim();
    return qty.isNotEmpty ? 'Qty $qty' : '';
  }

  String get priceSummary {
    final price = estimatedPriceController.text.trim();
    return price.isNotEmpty ? 'Price $price' : '';
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'qty': double.tryParse(qtyController.text.trim()) ?? 0,
      'estimated_price':
          double.tryParse(estimatedPriceController.text.trim()) ?? 0,
    };
  }

  void dispose() {
    qtyController.dispose();
    estimatedPriceController.dispose();
  }
}
