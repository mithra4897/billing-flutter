import '../../screen.dart';
import 'purchase_module_refresh_controller.dart';

class PurchaseReturnLineDraft {
  PurchaseReturnLineDraft({
    this.purchaseInvoiceLineId,
    this.taxCodeId,
    this.taxPercent,
    this.taxType,
    this.discountPercent,
    String? itemName,
    String? warehouseName,
    String? uomName,
    String? returnQty,
    String? rate,
    String? returnReason,
    String? remarks,
  }) : itemNameController = TextEditingController(text: itemName ?? ''),
       warehouseNameController = TextEditingController(
         text: warehouseName ?? '',
       ),
       uomNameController = TextEditingController(text: uomName ?? ''),
       returnQtyController = TextEditingController(text: returnQty ?? ''),
       rateController = TextEditingController(text: rate ?? ''),
       returnReasonController = TextEditingController(text: returnReason ?? ''),
       remarksController = TextEditingController(text: remarks ?? '');

  factory PurchaseReturnLineDraft.fromInvoiceLine(
    PurchaseInvoiceLineModel line,
  ) {
    return PurchaseReturnLineDraft(
      purchaseInvoiceLineId: line.id,
      returnQty: line.invoicedQty.toString(),
      rate: line.rate.toString(),
    )..applyInvoiceLine(line);
  }

  factory PurchaseReturnLineDraft.fromJson(Map<String, dynamic> json) {
    final draft = PurchaseReturnLineDraft(
      purchaseInvoiceLineId: intValue(json, 'purchase_invoice_line_id'),
      taxCodeId: intValue(json, 'tax_code_id'),
      taxPercent: Validators.parseFlexibleNumber(
        json['tax_percent']?.toString(),
      ),
      taxType: stringValue(json, 'tax_type'),
      discountPercent: Validators.parseFlexibleNumber(
        json['discount_percent']?.toString(),
      ),
      returnQty: stringValue(json, 'return_qty'),
      rate: stringValue(json, 'rate'),
      returnReason: stringValue(json, 'return_reason'),
      remarks: stringValue(json, 'remarks'),
    );
    draft.itemId = intValue(json, 'item_id');
    draft.warehouseId = intValue(json, 'warehouse_id');
    draft.uomId = intValue(json, 'uom_id');
    return draft;
  }

  int? purchaseInvoiceLineId;
  int? itemId;
  int? warehouseId;
  int? uomId;
  int? taxCodeId;
  double? taxPercent;
  String? taxType;
  double? discountPercent;
  final TextEditingController itemNameController;
  final TextEditingController warehouseNameController;
  final TextEditingController uomNameController;
  final TextEditingController returnQtyController;
  final TextEditingController rateController;
  final TextEditingController returnReasonController;
  final TextEditingController remarksController;
  bool _disposed = false;

  void applyInvoiceLine(PurchaseInvoiceLineModel? line) {
    purchaseInvoiceLineId = line?.id;
    itemId = line?.itemId;
    warehouseId = line?.warehouseId;
    uomId = line?.uomId;
    taxCodeId = line?.taxCodeId;
    taxPercent = line?.taxPercent;
    taxType = line?.taxType;
    discountPercent = line?.discountPercent;
    itemNameController.text = '';
    warehouseNameController.text = '';
    uomNameController.text = '';
    if (line != null) {
      rateController.text = line.rate.toString();
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'purchase_invoice_line_id': purchaseInvoiceLineId,
      'item_id': itemId,
      'warehouse_id': warehouseId,
      'uom_id': uomId,
      if (taxCodeId != null) 'tax_code_id': taxCodeId,
      if (taxPercent != null) 'tax_percent': taxPercent,
      if (taxType != null) 'tax_type': taxType,
      if (discountPercent != null) 'discount_percent': discountPercent,
      'return_qty':
          Validators.parseFlexibleNumber(returnQtyController.text) ?? 0,
      'rate': Validators.parseFlexibleNumber(rateController.text) ?? 0,
      'return_reason': nullIfEmpty(returnReasonController.text),
      'remarks': nullIfEmpty(remarksController.text),
    };
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    itemNameController.dispose();
    warehouseNameController.dispose();
    uomNameController.dispose();
    returnQtyController.dispose();
    rateController.dispose();
    returnReasonController.dispose();
    remarksController.dispose();
  }
}

class PurchaseReturnManagementController extends GetxController {
  PurchaseReturnManagementController();

  static const List<AppDropdownItem<String>> statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All'),
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'posted', label: 'Posted'),
        AppDropdownItem(value: 'debited', label: 'Debited'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  final PurchaseService _purchaseService = PurchaseService();
  final PurchaseModuleRefreshController _refreshController =
      PurchaseModuleRefreshController.ensureRegistered();
  final MasterService _masterService = MasterService();
  final InventoryService _inventoryService = InventoryService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController returnNoController = TextEditingController();
  final TextEditingController returnDateController = TextEditingController();
  final TextEditingController returnReasonController = TextEditingController();
  final TextEditingController roundOffController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  String statusFilter = '';
  List<PurchaseReturnModel> items = const <PurchaseReturnModel>[];
  List<PurchaseReturnModel> filteredItems = const <PurchaseReturnModel>[];
  List<FinancialYearModel> financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<PurchaseInvoiceModel> invoices = const <PurchaseInvoiceModel>[];
  List<PurchaseInvoiceLineModel> invoiceLines =
      const <PurchaseInvoiceLineModel>[];
  List<ItemModel> itemsLookup = const <ItemModel>[];
  List<UomModel> uoms = const <UomModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];
  PurchaseReturnModel? selectedItem;
  int? contextCompanyId;
  int? contextBranchId;
  int? contextLocationId;
  int? contextFinancialYearId;
  int? companyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? documentSeriesId;
  int? purchaseInvoiceId;
  int? supplierPartyId;
  bool isActive = true;
  bool applyRoundOff = false;
  List<PurchaseReturnLineDraft> lines = <PurchaseReturnLineDraft>[];

  bool _initialized = false;

  bool get canEditSelectedReturn {
    if (selectedItem == null) {
      return true;
    }
    return purchaseDocumentIsDraftEditable(
      stringValue(selectedItem!.toJson(), 'return_status'),
    );
  }

  bool get isSelectedReturnReadOnly =>
      selectedItem != null && !canEditSelectedReturn;

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
    returnNoController.dispose();
    returnDateController.dispose();
    returnReasonController.dispose();
    roundOffController.dispose();
    notesController.dispose();
    _disposeLines(lines);
    super.onClose();
  }

  Future<void> initialize({int? initialId}) async {
    if (!_initialized) {
      _initialized = true;
    }
    await loadPage(selectId: initialId);
    _refreshController.notifyChanged(source: 'purchase_return');
  }

  Future<void> _handleWorkingContextChanged() async {
    await loadPage(
      selectId: intValue(selectedItem?.toJson() ?? const {}, 'id'),
    );
    _refreshController.notifyChanged(source: 'purchase_return');
  }

  Future<void> loadPage({int? selectId}) async {
    initialLoading = items.isEmpty;
    pageError = null;
    update();
    try {
      final responses = await Future.wait<dynamic>([
        _purchaseService.returns(
          filters: const {'per_page': 200, 'sort_by': 'return_date'},
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
        _purchaseService.invoices(
          filters: const {'per_page': 300, 'sort_by': 'invoice_date'},
        ),
        _inventoryService.items(
          filters: const {'per_page': 300, 'sort_by': 'item_name'},
        ),
        _inventoryService.uoms(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
        _masterService.warehouses(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
      ]);
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies:
                ((responses[1] as PaginatedResponse<CompanyModel>).data ??
                        const <CompanyModel>[])
                    .where((item) => item.isActive)
                    .toList(growable: false),
            branches:
                ((responses[2] as PaginatedResponse<BranchModel>).data ??
                        const <BranchModel>[])
                    .where((item) => item.isActive)
                    .toList(growable: false),
            locations:
                ((responses[3] as PaginatedResponse<BusinessLocationModel>)
                            .data ??
                        const <BusinessLocationModel>[])
                    .where((item) => item.isActive)
                    .toList(growable: false),
            financialYears:
                ((responses[4] as PaginatedResponse<FinancialYearModel>).data ??
                        const <FinancialYearModel>[])
                    .where((item) => item.isActive)
                    .toList(growable: false),
          );

      items =
          (responses[0] as PaginatedResponse<PurchaseReturnModel>).data ??
          const <PurchaseReturnModel>[];
      financialYears =
          (responses[4] as PaginatedResponse<FinancialYearModel>).data ??
          const <FinancialYearModel>[];
      documentSeries =
          ((responses[5] as PaginatedResponse<DocumentSeriesModel>).data ??
                  const <DocumentSeriesModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      invoices =
          (responses[6] as PaginatedResponse<PurchaseInvoiceModel>).data ??
          const <PurchaseInvoiceModel>[];
      itemsLookup =
          ((responses[7] as PaginatedResponse<ItemModel>).data ??
                  const <ItemModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      uoms =
          ((responses[8] as PaginatedResponse<UomModel>).data ??
                  const <UomModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      warehouses =
          ((responses[9] as PaginatedResponse<WarehouseModel>).data ??
                  const <WarehouseModel>[])
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
          ? items.cast<PurchaseReturnModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : null;
      if (selected == null && selectId != null) {
        try {
          final detail = (await _purchaseService.returnDoc(selectId)).data;
          if (detail != null) {
            await selectDocument(detail, notify: false);
            update();
            return;
          }
        } catch (_) {}
      }
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
    PurchaseReturnModel item, {
    bool notify = true,
  }) async {
    final id = intValue(item.toJson(), 'id');
    if (id == null) return;
    final response = await _purchaseService.returnDoc(id);
    final full = response.data ?? item;
    final data = full.toJson();
    final nextLines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(PurchaseReturnLineDraft.fromJson)
        .toList(growable: true);
    final invoiceId = intValue(data, 'purchase_invoice_id');
    final invoiceResponse = invoiceId == null
        ? null
        : await _purchaseService.invoice(invoiceId);
    final nextInvoiceLines =
        invoiceResponse?.data?.lines ?? const <PurchaseInvoiceLineModel>[];
    selectedItem = full;
    companyId = intValue(data, 'company_id');
    branchId = intValue(data, 'branch_id');
    locationId = intValue(data, 'location_id');
    financialYearId = intValue(data, 'financial_year_id');
    documentSeriesId = intValue(data, 'document_series_id');
    purchaseInvoiceId = invoiceId;
    supplierPartyId = intValue(data, 'supplier_party_id');
    returnNoController.text = stringValue(data, 'return_no');
    returnDateController.text = displayDate(
      nullableStringValue(data, 'return_date'),
    );
    returnReasonController.text = stringValue(data, 'return_reason');
    roundOffController.text =
        stringValue(data, 'round_off_amount').trim().isEmpty
        ? ''
        : stringValue(data, 'round_off_amount');
    applyRoundOff =
        (Validators.parseFlexibleNumber(roundOffController.text.trim()) ?? 0) !=
        0;
    notesController.text = stringValue(data, 'notes');
    isActive = boolValue(data, 'is_active', fallback: true);
    invoiceLines = nextInvoiceLines;
    _replaceLines(nextLines, notify: false);
    formError = null;
    syncLineDisplayNames();
    _upsertReturn(full, notify: false);
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    final series = seriesOptions();
    selectedItem = null;
    companyId = contextCompanyId;
    branchId = contextBranchId;
    locationId = contextLocationId;
    financialYearId = contextFinancialYearId;
    documentSeriesId = series.isNotEmpty ? series.first.id : null;
    purchaseInvoiceId = null;
    supplierPartyId = null;
    returnNoController.clear();
    returnDateController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    returnReasonController.clear();
    roundOffController.clear();
    applyRoundOff = false;
    notesController.clear();
    isActive = true;
    invoiceLines = const <PurchaseInvoiceLineModel>[];
    _replaceLines(const <PurchaseReturnLineDraft>[], notify: false);
    formError = null;
    if (notify) {
      update();
    }
  }

  void setStatusFilter(String value) {
    statusFilter = value;
    _applyFilters();
  }

  List<PurchaseReturnModel> _filterItems(
    List<PurchaseReturnModel> source,
    String query,
    String status,
  ) {
    return filterBySearchAndStatus(
      source,
      query: query,
      status: status,
      statusOf: (item) => stringValue(item.toJson(), 'return_status'),
      searchFieldsOf: (item) {
        final data = item.toJson();
        return <String>[
          stringValue(data, 'return_no'),
          purchaseStatusLabel(nullableStringValue(data, 'return_status')),
        ];
      },
    );
  }

  void _applyFilters() {
    filteredItems = _filterItems(items, searchController.text, statusFilter);
    update();
  }

  List<DocumentSeriesModel> seriesOptions() {
    return documentSeries
        .where((item) {
          final typeOk =
              item.documentType == null ||
              item.documentType == 'PURCHASE_RETURN';
          final companyOk = companyId == null || item.companyId == companyId;
          final fyOk =
              financialYearId == null ||
              item.financialYearId == financialYearId;
          return typeOk && companyOk && fyOk;
        })
        .toList(growable: false);
  }

  List<PurchaseInvoiceModel> get invoiceOptions => invoices
      .where((item) => companyId == null || item.companyId == companyId)
      .toList(growable: false);

  String itemName(int? id) {
    if (id == null) return '';
    final item = itemsLookup.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == id,
      orElse: () => null,
    );
    return item?.toString() ?? 'Item #$id';
  }

  String warehouseName(int? id) {
    if (id == null) return '';
    final warehouse = warehouses.cast<WarehouseModel?>().firstWhere(
      (entry) => entry?.id == id,
      orElse: () => null,
    );
    return warehouse?.toString() ?? 'Warehouse #$id';
  }

  String uomName(int? id) {
    if (id == null) return '';
    final uom = uoms.cast<UomModel?>().firstWhere(
      (entry) => entry?.id == id,
      orElse: () => null,
    );
    return uom?.toString() ?? 'UOM #$id';
  }

  Future<void> handleInvoiceChanged(int? value) async {
    purchaseInvoiceId = value;
    supplierPartyId = null;
    invoiceLines = const <PurchaseInvoiceLineModel>[];
    _replaceLines(const <PurchaseReturnLineDraft>[], notify: false);
    update();
    if (value == null) {
      return;
    }
    final response = await _purchaseService.invoice(value);
    final invoice = response.data;
    supplierPartyId = invoice?.supplierPartyId;
    invoiceLines = invoice?.lines ?? const <PurchaseInvoiceLineModel>[];
    _replaceLines(
      invoiceLines.isEmpty
          ? const <PurchaseReturnLineDraft>[]
          : <PurchaseReturnLineDraft>[
              PurchaseReturnLineDraft.fromInvoiceLine(invoiceLines.first),
            ],
      notify: false,
    );
    syncLineDisplayNames();
    update();
  }

  void syncLineDisplayNames() {
    for (final line in lines) {
      line.itemNameController.text = itemName(line.itemId);
      line.warehouseNameController.text = warehouseName(line.warehouseId);
      line.uomNameController.text = uomName(line.uomId);
    }
  }

  void addLine() {
    lines = List<PurchaseReturnLineDraft>.from(lines)
      ..add(PurchaseReturnLineDraft());
    update();
  }

  void removeLine(int index) {
    final updated = List<PurchaseReturnLineDraft>.from(lines);
    updated.removeAt(index);
    _replaceLines(updated);
  }

  void _replaceLines(
    List<PurchaseReturnLineDraft> nextLines, {
    bool notify = true,
  }) {
    replaceDisposableDraftEntries<PurchaseReturnLineDraft>(
      previous: lines,
      next: nextLines,
      createEmpty: () => PurchaseReturnLineDraft(),
      assign: (entries) => lines = entries,
      dispose: (entry) => entry.dispose(),
      notify: notify
          ? () {
              _syncAutoRoundOff();
              update();
            }
          : null,
    );
  }

  void setFinancialYearId(int? value) {
    financialYearId = value;
    final series = seriesOptions();
    documentSeriesId = series.isNotEmpty ? series.first.id : null;
    update();
  }

  void setDocumentSeriesId(int? value) {
    documentSeriesId = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  void setApplyRoundOff(bool value) {
    applyRoundOff = value;
    if (value) {
      _syncAutoRoundOff();
    } else {
      roundOffController.clear();
    }
    update();
  }

  void _syncAutoRoundOff() {
    final baseTotal = lines.fold<double>(0, (sum, line) {
      final qty = Validators.parseControllerNumber(line.returnQtyController);
      final rate = Validators.parseControllerNumber(line.rateController);
      return sum + (qty * rate);
    });
    Validators.syncAutoRoundOffController(
      roundOffController,
      enabled: applyRoundOff,
      baseTotal: baseTotal,
    );
  }

  void refreshComputedState() {
    _syncAutoRoundOff();
    update();
  }

  void selectInvoiceLine(PurchaseReturnLineDraft line, int? value) {
    final selected = invoiceLines.cast<PurchaseInvoiceLineModel?>().firstWhere(
      (item) => item?.id == value,
      orElse: () => null,
    );
    if (selected == null) {
      line.applyInvoiceLine(null);
      refreshComputedState();
      return;
    }
    line.applyInvoiceLine(selected);
    line.itemNameController.text = itemName(selected.itemId);
    line.warehouseNameController.text = warehouseName(selected.warehouseId);
    line.uomNameController.text = uomName(selected.uomId);
    refreshComputedState();
  }

  Future<void> save(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;
    if (purchaseInvoiceId == null) {
      formError = 'Purchase invoice is required.';
      update();
      return;
    }
    if (lines.any(
      (line) =>
          line.purchaseInvoiceLineId == null ||
          (Validators.parseFlexibleNumber(line.returnQtyController.text) ??
                  0) <=
              0,
    )) {
      formError = 'Each line needs invoice line and return quantity.';
      update();
      return;
    }
    saving = true;
    formError = null;
    update();
    final preserveApplyRoundOff = applyRoundOff;
    final invoice = invoiceOptions.cast<PurchaseInvoiceModel?>().firstWhere(
      (item) => item?.id == purchaseInvoiceId,
      orElse: () => null,
    );
    final payload = <String, dynamic>{
      'company_id': companyId,
      'branch_id': branchId,
      'location_id': locationId,
      'financial_year_id': financialYearId,
      'document_series_id': documentSeriesId,
      'purchase_invoice_id': purchaseInvoiceId,
      'supplier_party_id': supplierPartyId ?? invoice?.supplierPartyId,
      'return_no': nullIfEmpty(returnNoController.text),
      'return_date': returnDateController.text.trim(),
      'return_reason': nullIfEmpty(returnReasonController.text),
      'round_off_amount': applyRoundOff
          ? (Validators.parseFlexibleNumber(roundOffController.text.trim()) ??
                0)
          : 0,
      'notes': nullIfEmpty(notesController.text),
      'is_active': isActive,
      'lines': lines.map((item) => item.toJson()).toList(growable: false),
    };
    try {
      final response = selectedItem == null
          ? await _purchaseService.createReturn(
              PurchaseReturnModel.fromJson(payload),
            )
          : await _purchaseService.updateReturn(
              intValue(selectedItem!.toJson(), 'id')!,
              PurchaseReturnModel.fromJson(payload),
            );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
      final saved = response.data;
      if (saved != null) {
        _upsertReturn(saved);
        await selectDocument(saved, notify: false);
        if (preserveApplyRoundOff &&
            (Validators.parseFlexibleNumber(roundOffController.text.trim()) ??
                    0) ==
                0) {
          applyRoundOff = true;
        }
        _refreshController.notifyChanged(source: 'purchase_return');
        update();
      } else {
        await loadPage(
          selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
        );
        if (preserveApplyRoundOff &&
            (Validators.parseFlexibleNumber(roundOffController.text.trim()) ??
                    0) ==
                0) {
          applyRoundOff = true;
          update();
        }
        _refreshController.notifyChanged(source: 'purchase_return');
      }
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> docAction(
    BuildContext context,
    Future<ApiResponse<PurchaseReturnModel>> Function() action,
  ) async {
    try {
      final response = await action();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
      final updated = response.data;
      if (updated != null) {
        _upsertReturn(updated);
        await selectDocument(updated, notify: false);
        _refreshController.notifyChanged(source: 'purchase_return');
        update();
      } else {
        await loadPage(
          selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
        );
        _refreshController.notifyChanged(source: 'purchase_return');
      }
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
    }
  }

  void _upsertReturn(PurchaseReturnModel purchaseReturn, {bool notify = true}) {
    final id = intValue(purchaseReturn.toJson(), 'id');
    if (id == null) {
      return;
    }
    final nextItems = List<PurchaseReturnModel>.from(items);
    final existingIndex = nextItems.indexWhere(
      (item) => intValue(item.toJson(), 'id') == id,
    );
    if (existingIndex >= 0) {
      nextItems[existingIndex] = purchaseReturn;
    } else {
      nextItems.insert(0, purchaseReturn);
    }
    items = nextItems;
    if (notify) {
      _applyFilters();
    } else {
      filteredItems = _filterItems(items, searchController.text, statusFilter);
    }
  }

  void _disposeLines(List<PurchaseReturnLineDraft> entries) {
    for (final line in entries) {
      line.dispose();
    }
  }
}
