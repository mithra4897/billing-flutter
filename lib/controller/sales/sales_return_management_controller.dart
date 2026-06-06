import '../../screen.dart';
import 'sales_module_refresh_controller.dart';

class SalesReturnLineDraft {
  SalesReturnLineDraft({
    this.salesInvoiceLineId,
    this.batchId,
    this.serialId,
    this.taxCodeId,
    this.taxPercent,
    this.taxType,
    this.discountPercent,
    String? itemName,
    String? warehouseName,
    String? uomName,
    String? batchNo,
    String? serialNo,
    String? returnQty,
    String? rate,
    String? remarks,
  }) : itemNameController = TextEditingController(text: itemName ?? ''),
       warehouseNameController = TextEditingController(
         text: warehouseName ?? '',
       ),
       uomNameController = TextEditingController(text: uomName ?? ''),
       batchNoController = TextEditingController(text: batchNo ?? ''),
       serialNoController = TextEditingController(text: serialNo ?? ''),
       returnQtyController = TextEditingController(text: returnQty ?? ''),
       rateController = TextEditingController(text: rate ?? ''),
       remarksController = TextEditingController(text: remarks ?? '');

  factory SalesReturnLineDraft.fromInvoiceLine(SalesInvoiceLineModel line) {
    return SalesReturnLineDraft(
      salesInvoiceLineId: line.id,
      returnQty: line.invoicedQty.toString(),
      rate: line.rate.toString(),
    )..applyInvoiceLine(line);
  }

  factory SalesReturnLineDraft.fromJson(Map<String, dynamic> json) {
    final batchJson = json['batch'] is Map<String, dynamic>
        ? json['batch'] as Map<String, dynamic>
        : null;
    final serialJson = json['serial'] is Map<String, dynamic>
        ? json['serial'] as Map<String, dynamic>
        : null;
    final invoiceLineJson = json['sales_invoice_line'] is Map<String, dynamic>
        ? json['sales_invoice_line'] as Map<String, dynamic>
        : (json['salesInvoiceLine'] is Map<String, dynamic>
              ? json['salesInvoiceLine'] as Map<String, dynamic>
              : null);
    final draft = SalesReturnLineDraft(
      salesInvoiceLineId: intValue(json, 'sales_invoice_line_id'),
      taxCodeId: intValue(json, 'tax_code_id'),
      taxPercent: double.tryParse(json['tax_percent']?.toString() ?? ''),
      taxType: stringValue(json, 'tax_type'),
      discountPercent: double.tryParse(
        json['discount_percent']?.toString() ?? '',
      ),
      returnQty: stringValue(json, 'return_qty'),
      rate: stringValue(json, 'rate'),
      remarks: stringValue(json, 'remarks'),
    );
    draft.itemId = intValue(json, 'item_id');
    draft.warehouseId = intValue(json, 'warehouse_id');
    draft.uomId = intValue(json, 'uom_id');
    draft.batchId =
        intValue(json, 'batch_id') ??
        intValue(batchJson ?? const <String, dynamic>{}, 'id') ??
        intValue(invoiceLineJson ?? const <String, dynamic>{}, 'batch_id');
    draft.serialId =
        intValue(json, 'serial_id') ??
        intValue(serialJson ?? const <String, dynamic>{}, 'id') ??
        intValue(invoiceLineJson ?? const <String, dynamic>{}, 'serial_id');
    draft.batchNoController.text = stringValue(json, 'batch_no').isNotEmpty
        ? stringValue(json, 'batch_no')
        : (stringValue(
                batchJson ?? const <String, dynamic>{},
                'batch_no',
              ).isNotEmpty
              ? stringValue(batchJson ?? const <String, dynamic>{}, 'batch_no')
              : stringValue(
                  invoiceLineJson ?? const <String, dynamic>{},
                  'batch_no',
                ));
    draft.serialNoController.text = stringValue(json, 'serial_no').isNotEmpty
        ? stringValue(json, 'serial_no')
        : (stringValue(
                serialJson ?? const <String, dynamic>{},
                'serial_no',
              ).isNotEmpty
              ? stringValue(
                  serialJson ?? const <String, dynamic>{},
                  'serial_no',
                )
              : stringValue(
                  invoiceLineJson ?? const <String, dynamic>{},
                  'serial_no',
                ));
    return draft;
  }

  int? salesInvoiceLineId;
  int? itemId;
  int? warehouseId;
  int? uomId;
  int? batchId;
  int? serialId;
  int? taxCodeId;
  double? taxPercent;
  String? taxType;
  double? discountPercent;
  final TextEditingController itemNameController;
  final TextEditingController warehouseNameController;
  final TextEditingController uomNameController;
  final TextEditingController batchNoController;
  final TextEditingController serialNoController;
  final TextEditingController returnQtyController;
  final TextEditingController rateController;
  final TextEditingController remarksController;

  void applyInvoiceLine(SalesInvoiceLineModel? line) {
    salesInvoiceLineId = line?.id;
    itemId = line?.itemId;
    warehouseId = line?.warehouseId;
    uomId = line?.uomId;
    batchId = line?.batchId;
    serialId = line?.serialId;
    taxCodeId = line?.taxCodeId;
    taxPercent = line?.taxPercent;
    taxType = line?.taxType;
    discountPercent = line?.discountPercent;
    itemNameController.text = '';
    warehouseNameController.text = '';
    uomNameController.text = '';
    batchNoController.text = line?.batchNo ?? '';
    serialNoController.text = line?.serialNo ?? '';
    if (line != null) {
      rateController.text = line.rate.toString();
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sales_invoice_line_id': salesInvoiceLineId,
      'item_id': itemId,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      'uom_id': uomId,
      if (batchId != null) 'batch_id': batchId,
      if (serialId != null) 'serial_id': serialId,
      if (batchNoController.text.trim().isNotEmpty)
        'batch_no': batchNoController.text.trim(),
      if (serialNoController.text.trim().isNotEmpty)
        'serial_no': serialNoController.text.trim(),
      if (taxCodeId != null) 'tax_code_id': taxCodeId,
      if (discountPercent != null) 'discount_percent': discountPercent,
      if (taxPercent != null) 'tax_percent': taxPercent,
      'return_qty': double.tryParse(returnQtyController.text.trim()) ?? 0,
      'rate': double.tryParse(rateController.text.trim()) ?? 0,
      'remarks': nullIfEmpty(remarksController.text),
    };
  }

  void dispose() {
    itemNameController.dispose();
    warehouseNameController.dispose();
    uomNameController.dispose();
    batchNoController.dispose();
    serialNoController.dispose();
    returnQtyController.dispose();
    rateController.dispose();
    remarksController.dispose();
  }
}

class SalesReturnManagementController extends GetxController {
  SalesReturnManagementController();

  static const List<AppDropdownItem<String>> statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All'),
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'posted', label: 'Posted'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  final SalesService _salesService = SalesService();
  final MasterService _masterService = MasterService();
  final InventoryService _inventoryService = InventoryService();
  final SalesModuleRefreshController _refreshController =
      SalesModuleRefreshController.ensureRegistered();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController returnNoController = TextEditingController();
  final TextEditingController returnDateController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController roundOffController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  String statusFilter = '';
  List<SalesReturnModel> items = const <SalesReturnModel>[];
  List<SalesReturnModel> filteredItems = const <SalesReturnModel>[];
  List<FinancialYearModel> financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<SalesInvoiceModel> invoices = const <SalesInvoiceModel>[];
  List<SalesInvoiceLineModel> invoiceLines = const <SalesInvoiceLineModel>[];
  List<ItemModel> itemsLookup = const <ItemModel>[];
  List<UomModel> uoms = const <UomModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];
  List<TaxCodeModel> taxCodes = const <TaxCodeModel>[];
  SalesReturnModel? selectedItem;
  int? contextCompanyId;
  int? contextBranchId;
  int? contextLocationId;
  int? contextFinancialYearId;
  int? companyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? documentSeriesId;
  int? salesInvoiceId;
  int? customerPartyId;
  bool isActive = true;
  bool applyRoundOff = false;
  List<SalesReturnLineDraft> lines = <SalesReturnLineDraft>[];

  bool _initialized = false;

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
    reasonController.dispose();
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
        _salesService.returns(
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
        _salesService.invoices(
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
        _inventoryService.taxCodes(
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
          (responses[0] as PaginatedResponse<SalesReturnModel>).data ??
          const <SalesReturnModel>[];
      financialYears =
          (responses[4] as PaginatedResponse<FinancialYearModel>).data ??
          const <FinancialYearModel>[];
      documentSeries =
          ((responses[5] as PaginatedResponse<DocumentSeriesModel>).data ??
                  const <DocumentSeriesModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      invoices =
          (responses[6] as PaginatedResponse<SalesInvoiceModel>).data ??
          const <SalesInvoiceModel>[];
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
      taxCodes =
          ((responses[10] as PaginatedResponse<TaxCodeModel>).data ??
                  const <TaxCodeModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      contextCompanyId = contextSelection.companyId;
      contextBranchId = contextSelection.branchId;
      contextLocationId = contextSelection.locationId;
      contextFinancialYearId = contextSelection.financialYearId;
      initialLoading = false;
      _applyFilters(notify: false);

      final selected = selectId != null
          ? items.cast<SalesReturnModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : selectedItem == null
          ? (items.isNotEmpty ? items.first : null)
          : null;

      if (selected == null && selectId != null) {
        try {
          final detail = (await _salesService.returnDoc(selectId)).data;
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
    } catch (error) {
      pageError = error.toString();
      initialLoading = false;
      update();
    }
  }

  Future<void> selectDocument(
    SalesReturnModel item, {
    bool notify = true,
  }) async {
    final id = intValue(item.toJson(), 'id');
    if (id == null) {
      return;
    }
    final response = await _salesService.returnDoc(id);
    final full = response.data ?? item;
    final data = full.toJson();
    final nextLines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(SalesReturnLineDraft.fromJson)
        .toList(growable: true);
    final invoiceId = intValue(data, 'sales_invoice_id');
    final invoiceResponse = invoiceId == null
        ? null
        : await _salesService.invoice(invoiceId);
    selectedItem = full;
    companyId = intValue(data, 'company_id');
    branchId = intValue(data, 'branch_id');
    locationId = intValue(data, 'location_id');
    financialYearId = intValue(data, 'financial_year_id');
    documentSeriesId = intValue(data, 'document_series_id');
    salesInvoiceId = invoiceId;
    customerPartyId = intValue(data, 'customer_party_id');
    returnNoController.text = stringValue(data, 'return_no');
    returnDateController.text = displayDate(
      nullableStringValue(data, 'return_date'),
    );
    reasonController.text = stringValue(data, 'reason');
    roundOffController.text =
        stringValue(data, 'round_off_amount').trim().isEmpty
        ? ''
        : stringValue(data, 'round_off_amount');
    applyRoundOff = (double.tryParse(roundOffController.text.trim()) ?? 0) != 0;
    notesController.text = stringValue(data, 'notes');
    isActive = boolValue(data, 'is_active', fallback: true);
    invoiceLines =
        invoiceResponse?.data?.lines ?? const <SalesInvoiceLineModel>[];
    _replaceLines(nextLines, notify: false);
    formError = null;
    _syncLineDisplayNames();
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
    salesInvoiceId = null;
    customerPartyId = null;
    returnNoController.clear();
    returnDateController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    reasonController.clear();
    roundOffController.clear();
    applyRoundOff = false;
    notesController.clear();
    isActive = true;
    invoiceLines = const <SalesInvoiceLineModel>[];
    _replaceLines(const <SalesReturnLineDraft>[], notify: false);
    formError = null;
    if (notify) {
      update();
    }
  }

  void _applyFilters({bool notify = true}) {
    filteredItems = filterBySearchAndStatus(
      items,
      query: searchController.text,
      status: statusFilter,
      statusOf: (item) => stringValue(item.toJson(), 'return_status'),
      searchFieldsOf: (item) {
        final data = item.toJson();
        return <String>[
          stringValue(data, 'return_no'),
          stringValue(data, 'return_status'),
          stringValue(data, 'reason'),
          quotationCustomerLabel(data),
        ];
      },
    );
    if (notify) {
      update();
    }
  }

  void setStatusFilter(String value) {
    statusFilter = value;
    _applyFilters();
  }

  List<DocumentSeriesModel> seriesOptions() {
    return documentSeries
        .where((item) {
          final typeOk =
              item.documentType == null || item.documentType == 'SALES_RETURN';
          final companyOk = companyId == null || item.companyId == companyId;
          final fyOk =
              financialYearId == null ||
              item.financialYearId == financialYearId;
          return typeOk && companyOk && fyOk;
        })
        .toList(growable: false);
  }

  List<SalesInvoiceModel> get invoiceOptions => invoices
      .where((item) {
        if (item.id == salesInvoiceId) {
          return true;
        }
        final status = (item.invoiceStatus ?? '').trim().toLowerCase();
        final statusOk = status == 'partially_paid' || status == 'paid';
        final companyOk = companyId == null || item.companyId == companyId;
        final branchOk = branchId == null || item.branchId == branchId;
        final locationOk = locationId == null || item.locationId == locationId;
        final customerOk =
            customerPartyId == null || item.customerPartyId == customerPartyId;
        final returnableOk = item.lines.any(_invoiceLineIsReturnable);
        return statusOk &&
            companyOk &&
            branchOk &&
            locationOk &&
            customerOk &&
            returnableOk;
      })
      .toList(growable: false);

  List<SalesInvoiceLineModel> get invoiceLineOptions => invoiceLines
      .where((item) {
        if (item.id == null || selectedInvoiceLineIds.contains(item.id)) {
          return true;
        }
        return _invoiceLineIsReturnable(item);
      })
      .toList(growable: false);

  Set<int> get selectedInvoiceLineIds =>
      lines.map((line) => line.salesInvoiceLineId).whereType<int>().toSet();

  bool _invoiceLineIsReturnable(SalesInvoiceLineModel line) {
    final returnedQty = line.returnedQty ?? 0;
    return line.invoicedQty > returnedQty;
  }

  ItemModel? itemById(int? id) {
    if (id == null) {
      return null;
    }
    return itemsLookup.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == id,
      orElse: () => null,
    );
  }

  bool isBatchManagedItem(int? itemId) => itemById(itemId)?.hasBatch == true;

  bool isSerialManagedItem(int? itemId) => itemById(itemId)?.hasSerial == true;

  String itemName(int? id) {
    if (id == null) {
      return '';
    }
    final item = itemsLookup.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == id,
      orElse: () => null,
    );
    return item?.toString() ?? 'Item #$id';
  }

  String warehouseName(int? id) {
    if (id == null) {
      return '';
    }
    final warehouse = warehouses.cast<WarehouseModel?>().firstWhere(
      (entry) => entry?.id == id,
      orElse: () => null,
    );
    return warehouse?.toString() ?? 'Warehouse #$id';
  }

  String uomName(int? id) {
    if (id == null) {
      return '';
    }
    final uom = uoms.cast<UomModel?>().firstWhere(
      (entry) => entry?.id == id,
      orElse: () => null,
    );
    return uom?.toString() ?? 'UOM #$id';
  }

  Future<void> handleInvoiceChanged(int? value) async {
    salesInvoiceId = value;
    customerPartyId = null;
    invoiceLines = const <SalesInvoiceLineModel>[];
    _replaceLines(const <SalesReturnLineDraft>[], notify: false);
    update();
    if (value == null) {
      return;
    }
    final response = await _salesService.invoice(value);
    final invoice = response.data;
    customerPartyId = invoice?.customerPartyId;
    invoiceLines = invoice?.lines ?? const <SalesInvoiceLineModel>[];
    _replaceLines(
      invoiceLines.isEmpty
          ? const <SalesReturnLineDraft>[]
          : <SalesReturnLineDraft>[
              SalesReturnLineDraft.fromInvoiceLine(invoiceLines.first),
            ],
      notify: false,
    );
    _syncLineDisplayNames();
    update();
  }

  void _syncLineDisplayNames() {
    for (final line in lines) {
      line.itemNameController.text = itemName(line.itemId);
      line.warehouseNameController.text = warehouseName(line.warehouseId);
      line.uomNameController.text = uomName(line.uomId);
      final sourceLine = invoiceLines.cast<SalesInvoiceLineModel?>().firstWhere(
        (entry) => entry?.id == line.salesInvoiceLineId,
        orElse: () => null,
      );
      line.batchId ??= sourceLine?.batchId;
      line.serialId ??= sourceLine?.serialId;
      if (line.batchNoController.text.trim().isEmpty) {
        line.batchNoController.text = sourceLine?.batchNo ?? '';
      }
      if (line.serialNoController.text.trim().isEmpty) {
        line.serialNoController.text = sourceLine?.serialNo ?? '';
      }
    }
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

  SalesInvoiceModel? get selectedInvoice => invoiceOptions
      .cast<SalesInvoiceModel?>()
      .firstWhere((item) => item?.id == salesInvoiceId, orElse: () => null);

  String get currencyCodeForTaxSummary {
    final currency = selectedInvoice?.currencyCode?.trim() ?? '';
    return currency.isEmpty ? 'INR' : currency;
  }

  SalesLineTaxBreakdown taxBreakdownForLine(SalesReturnLineDraft line) {
    return computeSalesLineTaxBreakdown(
      qty: double.tryParse(line.returnQtyController.text.trim()) ?? 0,
      rate: double.tryParse(line.rateController.text.trim()) ?? 0,
      discountPercent: line.discountPercent ?? 0,
      taxCode: salesTaxCodeById(taxCodes, line.taxCodeId),
      taxPercent: line.taxPercent,
      taxType: line.taxType,
    );
  }

  SalesDocumentTaxSummary taxSummary() {
    return summarizeSalesLineTaxes(lines.map(taxBreakdownForLine));
  }

  void _syncAutoRoundOff() {
    if (!applyRoundOff) {
      return;
    }
    final baseTotal = taxSummary().total;
    final autoRoundOff = roundToDouble(baseTotal.round() - baseTotal, 2);
    roundOffController.text = autoRoundOff.toStringAsFixed(2);
  }

  Map<String, dynamic> linePayload(SalesReturnLineDraft line) {
    final payload = line.toJson();
    final breakdown = taxBreakdownForLine(line);
    return <String, dynamic>{
      ...payload,
      'discount_amount': roundToDouble(breakdown.gross - breakdown.taxable, 2),
      'gross_amount': roundToDouble(breakdown.gross, 2),
      'taxable_amount': roundToDouble(breakdown.taxable, 2),
      'tax_percent': roundToDouble(breakdown.taxPercent, 4),
      'cgst_amount': roundToDouble(breakdown.cgst, 2),
      'sgst_amount': roundToDouble(breakdown.sgst, 2),
      'igst_amount': roundToDouble(breakdown.igst, 2),
      'cess_amount': roundToDouble(breakdown.cess, 2),
      'line_total': roundToDouble(breakdown.total, 2),
    };
  }

  void addLine() {
    lines = List<SalesReturnLineDraft>.from(lines)..add(SalesReturnLineDraft());
    _syncAutoRoundOff();
    update();
  }

  void removeLine(int index) {
    final nextLines = List<SalesReturnLineDraft>.from(lines);
    nextLines.removeAt(index);
    _replaceLines(nextLines);
  }

  void _replaceLines(
    List<SalesReturnLineDraft> nextLines, {
    bool notify = true,
  }) {
    replaceDisposableDraftEntries<SalesReturnLineDraft>(
      previous: lines,
      next: nextLines,
      createEmpty: () => SalesReturnLineDraft(),
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

  void handleLineSelected(int index, int? value) {
    final line = lines[index];
    final selected = invoiceLineOptions
        .cast<SalesInvoiceLineModel?>()
        .firstWhere((item) => item?.id == value, orElse: () => null);
    if (selected == null) {
      line.applyInvoiceLine(null);
    } else {
      line.applyInvoiceLine(selected);
      line.itemNameController.text = itemName(selected.itemId);
      line.warehouseNameController.text = warehouseName(selected.warehouseId);
      line.uomNameController.text = uomName(selected.uomId);
    }
    _syncAutoRoundOff();
    update();
  }

  void refreshLineState() {
    _syncAutoRoundOff();
    update();
  }

  Future<void> save(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    if (salesInvoiceId == null) {
      formError = 'Sales invoice is required.';
      update();
      return;
    }
    if (lines.any((line) {
      return line.salesInvoiceLineId == null ||
          (double.tryParse(line.returnQtyController.text.trim()) ?? 0) <= 0;
    })) {
      formError = 'Each line needs invoice line and return quantity.';
      update();
      return;
    }
    saving = true;
    formError = null;
    update();
    final preserveApplyRoundOff = applyRoundOff;
    final invoice = invoices.cast<SalesInvoiceModel?>().firstWhere(
      (item) => item?.id == salesInvoiceId,
      orElse: () => null,
    );
    final summary = taxSummary();
    final payload = <String, dynamic>{
      'company_id': companyId,
      'branch_id': branchId,
      'location_id': locationId,
      'financial_year_id': financialYearId,
      'document_series_id': documentSeriesId,
      'sales_invoice_id': salesInvoiceId,
      'customer_party_id': customerPartyId ?? invoice?.customerPartyId,
      'return_no': nullIfEmpty(returnNoController.text),
      'return_date': returnDateController.text.trim(),
      'reason': nullIfEmpty(reasonController.text),
      'round_off_amount': applyRoundOff
          ? (double.tryParse(roundOffController.text.trim()) ?? 0)
          : 0,
      'taxable_amount': roundToDouble(summary.taxable, 2),
      'cgst_amount': roundToDouble(summary.cgst, 2),
      'sgst_amount': roundToDouble(summary.sgst, 2),
      'igst_amount': roundToDouble(summary.igst, 2),
      'cess_amount': roundToDouble(summary.cess, 2),
      'total_amount': roundToDouble(
        summary.total +
            (applyRoundOff
                ? (double.tryParse(roundOffController.text.trim()) ?? 0)
                : 0),
        2,
      ),
      'notes': nullIfEmpty(notesController.text),
      'is_active': isActive,
      'lines': lines.map(linePayload).toList(growable: false),
    };
    try {
      final response = selectedItem == null
          ? await _salesService.createReturn(SalesReturnModel.fromJson(payload))
          : await _salesService.updateReturn(
              intValue(selectedItem!.toJson(), 'id')!,
              SalesReturnModel.fromJson(payload),
            );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
      await loadPage(
        selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
      );
      if (preserveApplyRoundOff &&
          (double.tryParse(roundOffController.text.trim()) ?? 0) == 0) {
        applyRoundOff = true;
        update();
      }
      _refreshController.notifyChanged(source: 'sales_return');
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> docAction(
    BuildContext context,
    Future<ApiResponse<SalesReturnModel>> Function() action,
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
      _refreshController.notifyChanged(source: 'sales_return');
    } catch (error) {
      formError = error.toString();
      update();
    }
  }

  Future<void> postSelected(BuildContext context) async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) {
      return;
    }
    await docAction(
      context,
      () => _salesService.postReturn(
        id,
        SalesReturnModel.fromJson(const <String, dynamic>{}),
      ),
    );
  }

  Future<void> cancelSelected(BuildContext context) async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) {
      return;
    }
    await docAction(
      context,
      () => _salesService.cancelReturn(
        id,
        SalesReturnModel.fromJson(const <String, dynamic>{}),
      ),
    );
  }

  void _disposeLines(List<SalesReturnLineDraft> values) {
    for (final line in values) {
      line.dispose();
    }
  }
}
