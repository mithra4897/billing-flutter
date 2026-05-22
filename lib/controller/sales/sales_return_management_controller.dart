import '../../screen.dart';

class SalesReturnLineDraft {
  SalesReturnLineDraft({
    this.salesInvoiceLineId,
    this.taxCodeId,
    this.taxPercent,
    this.taxType,
    this.discountPercent,
    String? itemName,
    String? warehouseName,
    String? uomName,
    String? returnQty,
    String? rate,
    String? remarks,
  }) : itemNameController = TextEditingController(text: itemName ?? ''),
       warehouseNameController = TextEditingController(
         text: warehouseName ?? '',
       ),
       uomNameController = TextEditingController(text: uomName ?? ''),
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
    return draft;
  }

  int? salesInvoiceLineId;
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
  final TextEditingController remarksController;

  void applyInvoiceLine(SalesInvoiceLineModel? line) {
    salesInvoiceLineId = line?.id;
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
      'sales_invoice_line_id': salesInvoiceLineId,
      'item_id': itemId,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      'uom_id': uomId,
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
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController returnNoController = TextEditingController();
  final TextEditingController returnDateController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
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
    _disposeLines(lines);
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
    notesController.text = stringValue(data, 'notes');
    isActive = boolValue(data, 'is_active', fallback: true);
    invoiceLines =
        invoiceResponse?.data?.lines ?? const <SalesInvoiceLineModel>[];
    lines = nextLines.isEmpty
        ? <SalesReturnLineDraft>[SalesReturnLineDraft()]
        : nextLines;
    formError = null;
    _syncLineDisplayNames();
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    final series = seriesOptions();
    _disposeLines(lines);
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
    notesController.clear();
    isActive = true;
    invoiceLines = const <SalesInvoiceLineModel>[];
    lines = <SalesReturnLineDraft>[SalesReturnLineDraft()];
    formError = null;
    if (notify) {
      update();
    }
  }

  void _applyFilters({bool notify = true}) {
    final search = searchController.text.trim().toLowerCase();
    filteredItems = items
        .where((item) {
          final data = item.toJson();
          final statusOk =
              statusFilter.isEmpty ||
              stringValue(data, 'return_status') == statusFilter;
          final searchOk =
              search.isEmpty ||
              [
                stringValue(data, 'return_no'),
                stringValue(data, 'return_status'),
                stringValue(data, 'reason'),
                quotationCustomerLabel(data),
              ].join(' ').toLowerCase().contains(search);
          return statusOk && searchOk;
        })
        .toList(growable: false);
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
    _disposeLines(lines);
    salesInvoiceId = value;
    customerPartyId = null;
    invoiceLines = const <SalesInvoiceLineModel>[];
    lines = <SalesReturnLineDraft>[SalesReturnLineDraft()];
    update();
    if (value == null) {
      return;
    }
    final response = await _salesService.invoice(value);
    final invoice = response.data;
    customerPartyId = invoice?.customerPartyId;
    invoiceLines = invoice?.lines ?? const <SalesInvoiceLineModel>[];
    _disposeLines(lines);
    lines = invoiceLines.isEmpty
        ? <SalesReturnLineDraft>[SalesReturnLineDraft()]
        : <SalesReturnLineDraft>[
            SalesReturnLineDraft.fromInvoiceLine(invoiceLines.first),
          ];
    _syncLineDisplayNames();
    update();
  }

  void _syncLineDisplayNames() {
    for (final line in lines) {
      line.itemNameController.text = itemName(line.itemId);
      line.warehouseNameController.text = warehouseName(line.warehouseId);
      line.uomNameController.text = uomName(line.uomId);
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
    update();
  }

  void removeLine(int index) {
    final nextLines = List<SalesReturnLineDraft>.from(lines);
    final removed = nextLines.removeAt(index);
    removed.dispose();
    if (nextLines.isEmpty) {
      nextLines.add(SalesReturnLineDraft());
    }
    lines = nextLines;
    update();
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
    update();
  }

  void refreshLineState() {
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
      'taxable_amount': roundToDouble(summary.taxable, 2),
      'cgst_amount': roundToDouble(summary.cgst, 2),
      'sgst_amount': roundToDouble(summary.sgst, 2),
      'igst_amount': roundToDouble(summary.igst, 2),
      'cess_amount': roundToDouble(summary.cess, 2),
      'total_amount': roundToDouble(summary.total, 2),
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
