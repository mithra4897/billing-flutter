import '../../screen.dart';

class PurchaseRequisitionLineDraft {
  PurchaseRequisitionLineDraft({
    this.itemId,
    this.warehouseId,
    this.uomId,
    String? description,
    String? requestedQty,
    String? estimatedRate,
    String? remarks,
  }) : descriptionController = TextEditingController(text: description ?? ''),
       requestedQtyController = TextEditingController(text: requestedQty ?? ''),
       estimatedRateController = TextEditingController(
         text: estimatedRate ?? '',
       ),
       remarksController = TextEditingController(text: remarks ?? '');

  factory PurchaseRequisitionLineDraft.fromJson(Map<String, dynamic> json) {
    return PurchaseRequisitionLineDraft(
      itemId: intValue(json, 'item_id'),
      warehouseId: intValue(json, 'warehouse_id'),
      uomId: intValue(json, 'uom_id'),
      description: stringValue(json, 'description'),
      requestedQty: stringValue(json, 'requested_qty'),
      estimatedRate: stringValue(json, 'estimated_rate'),
      remarks: stringValue(json, 'remarks'),
    );
  }

  int? itemId;
  int? warehouseId;
  int? uomId;
  final TextEditingController descriptionController;
  final TextEditingController requestedQtyController;
  final TextEditingController estimatedRateController;
  final TextEditingController remarksController;

  void dispose() {
    descriptionController.dispose();
    requestedQtyController.dispose();
    estimatedRateController.dispose();
    remarksController.dispose();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'item_id': itemId,
      'warehouse_id': warehouseId,
      'uom_id': uomId,
      'description': nullIfEmpty(descriptionController.text),
      'requested_qty': double.tryParse(requestedQtyController.text.trim()) ?? 0,
      'estimated_rate':
          double.tryParse(estimatedRateController.text.trim()) ?? 0,
      'remarks': nullIfEmpty(remarksController.text),
    };
  }
}

class PurchaseRequisitionManagementController extends GetxController {
  PurchaseRequisitionManagementController();

  static const List<AppDropdownItem<String>> statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All'),
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'approved', label: 'Approved'),
        AppDropdownItem(value: 'partially_ordered', label: 'Partially Ordered'),
        AppDropdownItem(value: 'fully_ordered', label: 'Fully Ordered'),
        AppDropdownItem(value: 'closed', label: 'Closed'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  final PurchaseService _purchaseService = PurchaseService();
  final MasterService _masterService = MasterService();
  final AuthService _authService = AuthService();
  final HrService _hrService = HrService();
  final InventoryService _inventoryService = InventoryService();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController requisitionNoController = TextEditingController();
  final TextEditingController requisitionDateController =
      TextEditingController();
  final TextEditingController requiredDateController = TextEditingController();
  final TextEditingController purposeController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  String statusFilter = '';
  List<PurchaseRequisitionModel> items = const <PurchaseRequisitionModel>[];
  List<PurchaseRequisitionModel> filteredItems =
      const <PurchaseRequisitionModel>[];
  List<FinancialYearModel> financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<UserModel> users = const <UserModel>[];
  List<DepartmentModel> departments = const <DepartmentModel>[];
  List<ItemModel> itemsLookup = const <ItemModel>[];
  List<UomModel> uoms = const <UomModel>[];
  List<UomConversionModel> uomConversions = const <UomConversionModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];
  PurchaseRequisitionModel? selectedItem;
  int? contextCompanyId;
  int? contextBranchId;
  int? contextLocationId;
  int? contextFinancialYearId;
  int? companyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? documentSeriesId;
  int? requestedById;
  String? departmentName;
  bool isActive = true;
  List<PurchaseRequisitionLineDraft> lines = <PurchaseRequisitionLineDraft>[];

  bool _initialized = false;

  bool get canEditSelectedRequisition {
    if (selectedItem == null) {
      return true;
    }
    return stringValue(selectedItem!.toJson(), 'requisition_status') == 'draft';
  }

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applyFilters);
    WorkingContextService.version.addListener(_handleWorkingContextChanged);
  }

  @override
  void onClose() {
    WorkingContextService.version.removeListener(_handleWorkingContextChanged);
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applyFilters)
      ..dispose();
    requisitionNoController.dispose();
    requisitionDateController.dispose();
    requiredDateController.dispose();
    purposeController.dispose();
    notesController.dispose();
    _disposeLines(lines);
    super.onClose();
  }

  Future<void> initialize({int? initialId}) async {
    if (!_initialized) {
      _initialized = true;
    }
    await loadPage(selectId: initialId);
  }

  Future<void> _handleWorkingContextChanged() async {
    await loadPage(
      selectId: intValue(selectedItem?.toJson() ?? const {}, 'id'),
    );
  }

  Future<void> loadPage({int? selectId}) async {
    initialLoading = items.isEmpty;
    pageError = null;
    update();

    try {
      final responses = await Future.wait<dynamic>([
        _purchaseService.requisitions(
          filters: const {'per_page': 200, 'sort_by': 'requisition_date'},
        ),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
        _masterService.branches(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
        _masterService.businessLocations(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
        _masterService.financialYears(
          filters: const {'per_page': 100, 'sort_by': 'fy_name'},
        ),
        _masterService.documentSeries(
          filters: const {'per_page': 200, 'sort_by': 'series_name'},
        ),
        _authService.users(
          filters: const {'per_page': 200, 'sort_by': 'username'},
        ),
        _hrService.departments(
          filters: const {'per_page': 200, 'sort_by': 'department_name'},
        ),
        _inventoryService.items(
          filters: const {'per_page': 300, 'sort_by': 'item_name'},
        ),
        _inventoryService.uoms(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
        _inventoryService.uomConversionsAll(
          filters: const {'per_page': 500, 'sort_by': 'from_uom_id'},
        ),
        _masterService.warehouses(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
      ]);

      final documents =
          (responses[0] as PaginatedResponse<PurchaseRequisitionModel>).data ??
          const <PurchaseRequisitionModel>[];
      final companies =
          (responses[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final branches =
          (responses[2] as PaginatedResponse<BranchModel>).data ??
          const <BranchModel>[];
      final locations =
          (responses[3] as PaginatedResponse<BusinessLocationModel>).data ??
          const <BusinessLocationModel>[];
      final nextFinancialYears =
          (responses[4] as PaginatedResponse<FinancialYearModel>).data ??
          const <FinancialYearModel>[];
      final nextDocumentSeries =
          (responses[5] as PaginatedResponse<DocumentSeriesModel>).data ??
          const <DocumentSeriesModel>[];
      final nextUsers =
          (responses[6] as PaginatedResponse<UserModel>).data ??
          const <UserModel>[];
      final nextDepartments =
          (responses[7] as PaginatedResponse<DepartmentModel>).data ??
          const <DepartmentModel>[];
      final nextItems =
          (responses[8] as PaginatedResponse<ItemModel>).data ??
          const <ItemModel>[];
      final nextUoms =
          (responses[9] as PaginatedResponse<UomModel>).data ??
          const <UomModel>[];
      final nextConversions =
          (responses[10] as ApiResponse<List<UomConversionModel>>).data ??
          const <UomConversionModel>[];
      final nextWarehouses =
          (responses[11] as PaginatedResponse<WarehouseModel>).data ??
          const <WarehouseModel>[];

      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: companies
                .where((item) => item.isActive)
                .toList(growable: false),
            branches: branches
                .where((item) => item.isActive)
                .toList(growable: false),
            locations: locations
                .where((item) => item.isActive)
                .toList(growable: false),
            financialYears: nextFinancialYears
                .where((item) => item.isActive)
                .toList(growable: false),
          );

      items = documents;
      financialYears = nextFinancialYears;
      documentSeries = nextDocumentSeries
          .where((item) => item.isActive)
          .toList(growable: false);
      users = nextUsers
          .where((item) => (item.status ?? 'active') == 'active')
          .toList(growable: false);
      departments = nextDepartments
          .where((item) => item.isActive)
          .toList(growable: false);
      itemsLookup = nextItems
          .where((item) => item.isActive)
          .toList(growable: false);
      uoms = nextUoms.where((item) => item.isActive).toList(growable: false);
      uomConversions = nextConversions
          .where((item) => item.isActive)
          .toList(growable: false);
      warehouses = nextWarehouses
          .where((item) => item.isActive)
          .toList(growable: false);
      contextCompanyId = contextSelection.companyId;
      contextBranchId = contextSelection.branchId;
      contextLocationId = contextSelection.locationId;
      contextFinancialYearId = contextSelection.financialYearId;
      filteredItems = _filterItems(items, searchController.text, statusFilter);
      initialLoading = false;
      update();

      final selected = selectId != null
          ? documents.cast<PurchaseRequisitionModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : (selectedItem == null
                ? (documents.isNotEmpty ? documents.first : null)
                : documents.cast<PurchaseRequisitionModel?>().firstWhere(
                    (item) =>
                        intValue(item?.toJson() ?? const {}, 'id') ==
                        intValue(selectedItem!.toJson(), 'id'),
                    orElse: () => documents.isNotEmpty ? documents.first : null,
                  ));

      if (selected != null) {
        await selectDocument(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
      update();
    } catch (errorValue) {
      pageError = errorValue.toString();
      initialLoading = false;
      update();
    }
  }

  Future<void> selectDocument(
    PurchaseRequisitionModel model, {
    bool notify = true,
  }) async {
    final id = intValue(model.toJson(), 'id');
    if (id == null) {
      return;
    }
    final response = await _purchaseService.requisition(id);
    final full = response.data ?? model;
    final data = full.toJson();
    final nextLines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(PurchaseRequisitionLineDraft.fromJson)
        .toList(growable: true);

    selectedItem = full;
    companyId = intValue(data, 'company_id');
    branchId = intValue(data, 'branch_id');
    locationId = intValue(data, 'location_id');
    financialYearId = intValue(data, 'financial_year_id');
    documentSeriesId = intValue(data, 'document_series_id');
    requestedById = intValue(data, 'requested_by');
    requisitionNoController.text = stringValue(data, 'requisition_no');
    requisitionDateController.text = displayDate(
      nullableStringValue(data, 'requisition_date'),
    );
    requiredDateController.text = displayDate(
      nullableStringValue(data, 'required_date'),
    );
    departmentName = nullableStringValue(data, 'department');
    purposeController.text = stringValue(data, 'purpose');
    notesController.text = stringValue(data, 'notes');
    isActive = boolValue(data, 'is_active', fallback: true);
    _replaceLines(nextLines, notify: false);
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedItem = null;
    companyId = contextCompanyId;
    branchId = contextBranchId;
    locationId = contextLocationId;
    financialYearId = contextFinancialYearId;
    final series = documentSeriesForContext();
    documentSeriesId = series.isNotEmpty ? series.first.id : null;
    requestedById = null;
    requisitionNoController.clear();
    requisitionDateController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    requiredDateController.clear();
    departmentName = null;
    purposeController.clear();
    notesController.clear();
    isActive = true;
    _replaceLines(const <PurchaseRequisitionLineDraft>[], notify: false);
    formError = null;
    if (notify) {
      update();
    }
  }

  void setStatusFilter(String value) {
    statusFilter = value;
    filteredItems = _filterItems(items, searchController.text, statusFilter);
    update();
  }

  List<PurchaseRequisitionModel> _filterItems(
    List<PurchaseRequisitionModel> source,
    String query,
    String status,
  ) {
    final search = query.trim().toLowerCase();
    return source
        .where((item) {
          final data = item.toJson();
          final statusMatches =
              status.isEmpty ||
              stringValue(data, 'requisition_status') == status;
          final searchMatches =
              search.isEmpty ||
              [
                stringValue(data, 'requisition_no'),
                stringValue(data, 'purpose'),
                stringValue(data, 'department'),
                stringValue(data, 'requisition_status'),
              ].join(' ').toLowerCase().contains(search);
          return statusMatches && searchMatches;
        })
        .toList(growable: false);
  }

  void _applyFilters() {
    filteredItems = _filterItems(items, searchController.text, statusFilter);
    update();
  }

  List<UomModel> uomOptionsForItem(int? itemId) {
    final item = itemsLookup.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == itemId,
      orElse: () => null,
    );
    return allowedUomsForItem(item, uoms, uomConversions);
  }

  int? resolveDefaultUom(int? itemId, int? currentUomId) {
    final item = itemsLookup.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == itemId,
      orElse: () => null,
    );
    return defaultUomIdForItem(
      item,
      uoms,
      uomConversions,
      current: currentUomId,
    );
  }

  List<DocumentSeriesModel> documentSeriesForContext() {
    return documentSeries
        .where((item) {
          final documentTypeOk =
              item.documentType == null ||
              item.documentType == 'PURCHASE_REQUISITION';
          final companyOk = companyId == null || item.companyId == companyId;
          final fyOk =
              financialYearId == null ||
              item.financialYearId == financialYearId;
          return documentTypeOk && companyOk && fyOk;
        })
        .toList(growable: false);
  }

  List<AppDropdownItem<String>> get departmentItems {
    final mapped = departments
        .where((item) => item.departmentName != null)
        .map(
          (item) => AppDropdownItem(
            value: item.departmentName!,
            label: item.departmentName!,
          ),
        )
        .toList(growable: false);
    final selected = departmentName?.trim();
    final hasSelected = selected != null && selected.isNotEmpty;
    final exists = hasSelected && mapped.any((item) => item.value == selected);
    if (hasSelected && !exists) {
      return <AppDropdownItem<String>>[
        AppDropdownItem(value: selected, label: selected),
        ...mapped,
      ];
    }
    return mapped;
  }

  void _disposeLines(List<PurchaseRequisitionLineDraft> entries) {
    for (final line in entries) {
      line.dispose();
    }
  }

  void addLine() {
    lines = List<PurchaseRequisitionLineDraft>.from(lines)
      ..add(PurchaseRequisitionLineDraft());
    update();
  }

  void removeLine(int index) {
    final updatedLines = List<PurchaseRequisitionLineDraft>.from(lines);
    updatedLines.removeAt(index);
    _replaceLines(updatedLines);
  }

  void _replaceLines(
    List<PurchaseRequisitionLineDraft> nextLines, {
    bool notify = true,
  }) {
    replaceDisposableDraftEntries<PurchaseRequisitionLineDraft>(
      previous: lines,
      next: nextLines,
      createEmpty: () => PurchaseRequisitionLineDraft(),
      assign: (entries) => lines = entries,
      dispose: (entry) => entry.dispose(),
      notify: notify ? update : null,
    );
  }

  void setFinancialYearId(int? value) {
    financialYearId = value;
    final series = documentSeriesForContext();
    documentSeriesId = series.isNotEmpty ? series.first.id : null;
    update();
  }

  void setDocumentSeriesId(int? value) {
    documentSeriesId = value;
    update();
  }

  void setRequestedById(int? value) {
    requestedById = value;
    update();
  }

  void setDepartmentName(String? value) {
    departmentName = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  void setLineItemId(PurchaseRequisitionLineDraft line, int? value) {
    line.itemId = value;
    line.uomId = resolveDefaultUom(value, line.uomId);
    update();
  }

  void setLineUomId(PurchaseRequisitionLineDraft line, int? value) {
    line.uomId = value;
    update();
  }

  void setLineWarehouseId(PurchaseRequisitionLineDraft line, int? value) {
    line.warehouseId = value;
    update();
  }

  Future<void> save(BuildContext context) async {
    if (!canEditSelectedRequisition) {
      formError = 'Only draft purchase requisitions can be updated.';
      update();
      return;
    }

    if (!formKey.currentState!.validate()) {
      return;
    }

    final invalidLine = lines.any(
      (line) =>
          line.itemId == null ||
          line.uomId == null ||
          (double.tryParse(line.requestedQtyController.text.trim()) ?? 0) <= 0,
    );
    if (invalidLine) {
      formError = 'Each line needs item, UOM, and quantity.';
      update();
      return;
    }

    saving = true;
    formError = null;
    update();

    final payload = <String, dynamic>{
      'company_id': companyId,
      'branch_id': branchId,
      'location_id': locationId,
      'financial_year_id': financialYearId,
      'document_series_id': documentSeriesId,
      'requisition_no': nullIfEmpty(requisitionNoController.text),
      'requisition_date': requisitionDateController.text.trim(),
      'required_date': nullIfEmpty(requiredDateController.text),
      'requested_by': requestedById,
      'department': departmentName == null
          ? null
          : nullIfEmpty(departmentName!),
      'purpose': nullIfEmpty(purposeController.text),
      'notes': nullIfEmpty(notesController.text),
      'is_active': isActive,
      'lines': lines.map((line) => line.toJson()).toList(growable: false),
    };

    try {
      final response = selectedItem == null
          ? await _purchaseService.createRequisition(
              PurchaseRequisitionModel.fromJson(payload),
            )
          : await _purchaseService.updateRequisition(
              intValue(selectedItem!.toJson(), 'id')!,
              PurchaseRequisitionModel.fromJson(payload),
            );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
      await loadPage(
        selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
      );
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> executeAction(
    BuildContext context,
    Future<ApiResponse<PurchaseRequisitionModel>> Function() action,
  ) async {
    try {
      final response = await action();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
      await loadPage(
        selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
      );
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
    }
  }
}
