import '../../screen.dart';

class OrderLineDraft {
  OrderLineDraft({
    this.salesQuotationLineId,
    this.itemId,
    this.warehouseId,
    this.uomId,
    this.taxCodeId,
    String? description,
    String? qty,
    String? rate,
    String? discountPercent,
    String? remarks,
  }) : descriptionController = TextEditingController(text: description ?? ''),
       qtyController = TextEditingController(text: qty ?? ''),
       rateController = TextEditingController(text: rate ?? ''),
       discountController = TextEditingController(text: discountPercent ?? ''),
       remarksController = TextEditingController(text: remarks ?? '');

  factory OrderLineDraft.fromJson(Map<String, dynamic> json) {
    final qty = json['ordered_qty'] ?? json['qty'];
    return OrderLineDraft(
      salesQuotationLineId: intValue(json, 'sales_quotation_line_id'),
      itemId: intValue(json, 'item_id'),
      warehouseId: intValue(json, 'warehouse_id'),
      uomId: intValue(json, 'uom_id'),
      taxCodeId: intValue(json, 'tax_code_id'),
      description: stringValue(json, 'description'),
      qty: qty?.toString() ?? '',
      rate: stringValue(json, 'rate'),
      discountPercent: stringValue(json, 'discount_percent'),
      remarks: stringValue(json, 'remarks'),
    );
  }

  factory OrderLineDraft.fromQuotationLine(Map<String, dynamic> json) {
    final qty = json['qty'];
    return OrderLineDraft(
      salesQuotationLineId: intValue(json, 'id'),
      itemId: intValue(json, 'item_id'),
      warehouseId: intValue(json, 'warehouse_id'),
      uomId: intValue(json, 'uom_id'),
      taxCodeId: intValue(json, 'tax_code_id'),
      description: stringValue(json, 'description'),
      qty: qty?.toString() ?? '',
      rate: stringValue(json, 'rate'),
      discountPercent: stringValue(json, 'discount_percent'),
      remarks: stringValue(json, 'remarks'),
    );
  }

  int? salesQuotationLineId;
  int? itemId;
  int? warehouseId;
  int? uomId;
  int? taxCodeId;
  final TextEditingController descriptionController;
  final TextEditingController qtyController;
  final TextEditingController rateController;
  final TextEditingController discountController;
  final TextEditingController remarksController;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (salesQuotationLineId != null)
        'sales_quotation_line_id': salesQuotationLineId,
      'item_id': itemId,
      'warehouse_id': warehouseId,
      'uom_id': uomId,
      'tax_code_id': taxCodeId,
      'description': nullIfEmpty(descriptionController.text),
      'ordered_qty': double.tryParse(qtyController.text.trim()) ?? 0,
      'rate': double.tryParse(rateController.text.trim()) ?? 0,
      'discount_percent': double.tryParse(discountController.text.trim()) ?? 0,
      'remarks': nullIfEmpty(remarksController.text),
    };
  }

  void dispose() {
    descriptionController.dispose();
    qtyController.dispose();
    rateController.dispose();
    discountController.dispose();
    remarksController.dispose();
  }
}

class SalesOrderManagementController extends GetxController {
  SalesOrderManagementController();

  static const List<AppDropdownItem<String>>
  listStatusFilter = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'confirmed', label: 'Confirmed'),
    AppDropdownItem(value: 'partially_delivered', label: 'Partially delivered'),
    AppDropdownItem(value: 'fully_delivered', label: 'Fully delivered'),
    AppDropdownItem(value: 'partially_invoiced', label: 'Partially invoiced'),
    AppDropdownItem(value: 'fully_invoiced', label: 'Fully invoiced'),
    AppDropdownItem(value: 'closed', label: 'Closed'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  final SalesService _salesService = SalesService();
  final CrmService _crmService = CrmService();
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final InventoryService _inventoryService = InventoryService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController orderNoController = TextEditingController();
  final TextEditingController orderDateController = TextEditingController();
  final TextEditingController expectedDeliveryController =
      TextEditingController();
  final TextEditingController customerRefNoController = TextEditingController();
  final TextEditingController customerRefDateController =
      TextEditingController();
  final TextEditingController currencyCodeController = TextEditingController();
  final TextEditingController exchangeRateController = TextEditingController();
  final TextEditingController roundOffController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController termsController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  String statusFilter = '';
  List<SalesOrderModel> items = const <SalesOrderModel>[];
  List<SalesOrderModel> filteredItems = const <SalesOrderModel>[];
  List<SalesQuotationModel> quotationsAll = const <SalesQuotationModel>[];
  List<FinancialYearModel> financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<PartyModel> customers = const <PartyModel>[];
  List<ItemModel> itemsLookup = const <ItemModel>[];
  List<UomModel> uoms = const <UomModel>[];
  List<UomConversionModel> uomConversions = const <UomConversionModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];
  List<TaxCodeModel> taxCodes = const <TaxCodeModel>[];
  SalesOrderModel? selectedItem;
  int? contextCompanyId;
  int? contextBranchId;
  int? contextLocationId;
  int? contextFinancialYearId;
  int? companyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? documentSeriesId;
  int? customerPartyId;
  int? salesQuotationId;
  List<Map<String, dynamic>>? quotationLinesCache;
  Map<String, dynamic>? salesChain;
  bool isActive = true;
  List<OrderLineDraft> lines = <OrderLineDraft>[];

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
    orderNoController.dispose();
    orderDateController.dispose();
    expectedDeliveryController.dispose();
    customerRefNoController.dispose();
    customerRefDateController.dispose();
    currencyCodeController.dispose();
    exchangeRateController.dispose();
    roundOffController.dispose();
    notesController.dispose();
    termsController.dispose();
    _disposeLines(lines);
    super.onClose();
  }

  Future<void> initialize({
    int? initialId,
    int? initialQuotationId,
    bool editorOnly = false,
  }) async {
    if (!_initialized) {
      _initialized = true;
    }
    await loadPage(
      selectId: initialId,
      initialQuotationId: initialQuotationId,
      editorOnly: editorOnly,
    );
  }

  String errorMessage(Object error) {
    if (error is ApiException) {
      return error.displayMessage;
    }
    if (error is ApiResponse) {
      return error.message;
    }
    return error.toString();
  }

  bool get canEdit {
    if (selectedItem == null) {
      return true;
    }
    return stringValue(selectedItem!.toJson(), 'order_status') == 'draft';
  }

  String get status =>
      stringValue(selectedItem?.toJson() ?? const {}, 'order_status', 'draft');

  List<SalesQuotationModel> get quotationChoices {
    final currentCompanyId = companyId;
    final customerId = customerPartyId;
    return quotationsAll
        .where((quotation) {
          final json = quotation.toJson();
          if (currentCompanyId != null &&
              intValue(json, 'company_id') != currentCompanyId) {
            return false;
          }
          if (customerId != null &&
              intValue(json, 'customer_party_id') != customerId) {
            return false;
          }
          final quotationStatus = stringValue(json, 'quotation_status');
          return const {'posted', 'sent', 'accepted'}.contains(quotationStatus);
        })
        .toList(growable: false);
  }

  String quotationLinePickerLabel(Map<String, dynamic> line) {
    final itemId = intValue(line, 'item_id');
    final item = itemsLookup.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == itemId,
      orElse: () => null,
    );
    final quoteQty = double.tryParse(line['qty']?.toString() ?? '') ?? 0;
    final lineNo = intValue(line, 'line_no') ?? 0;
    final name = (item?.itemName ?? '').trim().isNotEmpty
        ? item!.itemName
        : 'Item $itemId';
    return 'L$lineNo · $name · quote qty $quoteQty';
  }

  Future<void> _handleWorkingContextChanged() async {
    await loadPage(
      selectId: intValue(selectedItem?.toJson() ?? const {}, 'id'),
    );
  }

  Future<void> fetchQuotationLines(int quotationId) async {
    try {
      final response = await _salesService.quotation(quotationId);
      final data = response.data?.toJson() ?? <String, dynamic>{};
      final rawLines = data['lines'] as List<dynamic>?;
      quotationLinesCache = rawLines
          ?.whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: false);
    } catch (_) {
      quotationLinesCache = const <Map<String, dynamic>>[];
    }
    update();
  }

  Future<void> onHeaderQuotationChanged(int? value) async {
    if (!canEdit) {
      return;
    }
    salesQuotationId = value;
    quotationLinesCache = value == null ? null : const <Map<String, dynamic>>[];
    for (final line in lines) {
      line.salesQuotationLineId = null;
    }
    update();
    if (value != null) {
      await fetchQuotationLines(value);
    } else {
      quotationLinesCache = null;
      update();
    }
    await refreshSalesChain();
  }

  Future<void> refreshSalesChain() async {
    final orderId = intValue(selectedItem?.toJson() ?? const {}, 'id');
    final quotationId = salesQuotationId;
    try {
      if (orderId != null) {
        final response = await _crmService.salesChain(orderId: orderId);
        salesChain = response.data;
      } else if (quotationId != null) {
        final response = await _crmService.salesChain(quotationId: quotationId);
        salesChain = response.data;
      } else {
        salesChain = null;
      }
    } catch (_) {
      salesChain = null;
    }
    update();
  }

  void applyQuotationLinePick(OrderLineDraft line, int? quotationLineId) {
    line.salesQuotationLineId = quotationLineId;
    if (quotationLineId != null) {
      Map<String, dynamic>? quotationLine;
      for (final entry
          in quotationLinesCache ?? const <Map<String, dynamic>>[]) {
        if (intValue(entry, 'id') == quotationLineId) {
          quotationLine = entry;
          break;
        }
      }
      if (quotationLine != null) {
        line.itemId = intValue(quotationLine, 'item_id');
        line.uomId = intValue(quotationLine, 'uom_id');
        line.warehouseId = intValue(quotationLine, 'warehouse_id');
        line.rateController.text = stringValue(quotationLine, 'rate');
        final quoteQty =
            double.tryParse(quotationLine['qty']?.toString() ?? '') ?? 0;
        if (quoteQty > 0) {
          line.qtyController.text = quoteQty.toString();
        }
      }
    }
    update();
  }

  List<DocumentSeriesModel> seriesOptions() {
    return documentSeries
        .where((item) {
          final typeOk =
              item.documentType == null || item.documentType == 'SALES_ORDER';
          final companyOk = companyId == null || item.companyId == companyId;
          final fyOk =
              financialYearId == null ||
              item.financialYearId == financialYearId;
          return typeOk && companyOk && fyOk;
        })
        .toList(growable: false);
  }

  Future<void> loadPage({
    int? selectId,
    int? initialQuotationId,
    bool editorOnly = false,
  }) async {
    initialLoading = items.isEmpty;
    pageError = null;
    update();
    try {
      final responses = await Future.wait<dynamic>([
        _salesService.orders(
          filters: const {'per_page': 200, 'sort_by': 'order_date'},
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
        _partiesService.partyTypes(filters: const {'per_page': 100}),
        _partiesService.parties(
          filters: const {'per_page': 400, 'sort_by': 'party_name'},
        ),
        _inventoryService.items(
          filters: const {'per_page': 400, 'sort_by': 'item_name'},
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
        _inventoryService.taxCodes(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
        _salesService.quotationsAll(
          filters: const {'sort_by': 'quotation_date'},
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
          (responses[0] as PaginatedResponse<SalesOrderModel>).data ??
          const <SalesOrderModel>[];
      financialYears =
          (responses[4] as PaginatedResponse<FinancialYearModel>).data ??
          const <FinancialYearModel>[];
      documentSeries =
          ((responses[5] as PaginatedResponse<DocumentSeriesModel>).data ??
                  const <DocumentSeriesModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      customers = salesCustomersOrFallback(
        parties:
            ((responses[7] as PaginatedResponse<PartyModel>).data ??
            const <PartyModel>[]),
        partyTypes:
            (responses[6] as PaginatedResponse<PartyTypeModel>).data ??
            const <PartyTypeModel>[],
      );
      itemsLookup =
          ((responses[8] as PaginatedResponse<ItemModel>).data ??
                  const <ItemModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      uoms =
          ((responses[9] as PaginatedResponse<UomModel>).data ??
                  const <UomModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      uomConversions =
          ((responses[10] as PaginatedResponse<UomConversionModel>).data ??
                  const <UomConversionModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      warehouses =
          ((responses[11] as PaginatedResponse<WarehouseModel>).data ??
                  const <WarehouseModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      taxCodes =
          ((responses[12] as PaginatedResponse<TaxCodeModel>).data ??
                  const <TaxCodeModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      quotationsAll =
          (responses[13] as ApiResponse<List<SalesQuotationModel>>).data ??
          const <SalesQuotationModel>[];
      contextCompanyId = contextSelection.companyId;
      contextBranchId = contextSelection.branchId;
      contextLocationId = contextSelection.locationId;
      contextFinancialYearId = contextSelection.financialYearId;
      initialLoading = false;
      _applyFilters(notify: false);

      final selected = selectId != null
          ? items.cast<SalesOrderModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : (editorOnly
                ? null
                : (selectedItem == null
                      ? (items.isNotEmpty ? items.first : null)
                      : null));

      if (selected != null) {
        await selectDocument(selected, notify: false);
      } else {
        resetForm(notify: false);
        if (initialQuotationId != null && editorOnly) {
          await prefillNewOrderFromQuotation(initialQuotationId);
        }
      }
      update();
    } catch (error) {
      pageError = errorMessage(error);
      initialLoading = false;
      update();
    }
  }

  Future<void> prefillNewOrderFromQuotation(int quotationId) async {
    try {
      final response = await _salesService.quotation(quotationId);
      final quotation = response.data;
      if (quotation == null) {
        return;
      }
      final data = quotation.toJson();
      final nextLines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(OrderLineDraft.fromQuotationLine)
          .toList(growable: true);
      _disposeLines(lines);
      salesQuotationId = quotationId;
      companyId = intValue(data, 'company_id');
      branchId = intValue(data, 'branch_id');
      locationId = intValue(data, 'location_id');
      financialYearId = intValue(data, 'financial_year_id');
      final series = seriesOptions();
      documentSeriesId = series.isNotEmpty
          ? series.first.id
          : intValue(data, 'document_series_id');
      customerPartyId = intValue(data, 'customer_party_id');
      orderNoController.clear();
      orderDateController.text = DateTime.now()
          .toIso8601String()
          .split('T')
          .first;
      expectedDeliveryController.text = displayDate(
        nullableStringValue(data, 'valid_until'),
      );
      customerRefNoController.text = stringValue(data, 'customer_reference_no');
      customerRefDateController.text = displayDate(
        nullableStringValue(data, 'customer_reference_date'),
      );
      currencyCodeController.text = stringValue(data, 'currency_code', 'INR');
      exchangeRateController.text = stringValue(data, 'exchange_rate', '1');
      roundOffController.clear();
      notesController.text = stringValue(data, 'notes');
      termsController.text = stringValue(data, 'terms_conditions');
      isActive = true;
      lines = nextLines.isEmpty
          ? <OrderLineDraft>[OrderLineDraft()]
          : nextLines;
      formError = null;
      update();
      await fetchQuotationLines(quotationId);
      await refreshSalesChain();
    } catch (error) {
      formError = error.toString();
      update();
    }
  }

  Future<void> selectDocument(
    SalesOrderModel item, {
    bool notify = true,
  }) async {
    final id = intValue(item.toJson(), 'id');
    if (id == null) {
      return;
    }
    final response = await _salesService.order(id);
    final full = response.data ?? item;
    final data = full.toJson();
    final nextLines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(OrderLineDraft.fromJson)
        .toList(growable: true);
    _disposeLines(lines);
    final quotationId = intValue(data, 'sales_quotation_id');
    selectedItem = full;
    companyId = intValue(data, 'company_id');
    branchId = intValue(data, 'branch_id');
    locationId = intValue(data, 'location_id');
    financialYearId = intValue(data, 'financial_year_id');
    documentSeriesId = intValue(data, 'document_series_id');
    customerPartyId = intValue(data, 'customer_party_id');
    salesQuotationId = quotationId == 0 ? null : quotationId;
    quotationLinesCache = null;
    orderNoController.text = stringValue(data, 'order_no');
    orderDateController.text = displayDate(
      nullableStringValue(data, 'order_date'),
    );
    expectedDeliveryController.text = displayDate(
      nullableStringValue(data, 'expected_delivery_date'),
    );
    customerRefNoController.text = stringValue(data, 'customer_reference_no');
    customerRefDateController.text = displayDate(
      nullableStringValue(data, 'customer_reference_date'),
    );
    currencyCodeController.text = stringValue(data, 'currency_code', 'INR');
    exchangeRateController.text = stringValue(data, 'exchange_rate', '1');
    roundOffController.text =
        stringValue(data, 'round_off_amount').trim().isEmpty
        ? ''
        : stringValue(data, 'round_off_amount');
    notesController.text = stringValue(data, 'notes');
    termsController.text = stringValue(data, 'terms_conditions');
    isActive = boolValue(data, 'is_active', fallback: true);
    lines = nextLines.isEmpty ? <OrderLineDraft>[OrderLineDraft()] : nextLines;
    formError = null;
    if (salesQuotationId != null) {
      await fetchQuotationLines(salesQuotationId!);
    }
    await refreshSalesChain();
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    _disposeLines(lines);
    final series = seriesOptions();
    selectedItem = null;
    companyId = contextCompanyId;
    branchId = contextBranchId;
    locationId = contextLocationId;
    financialYearId = contextFinancialYearId;
    documentSeriesId = series.isNotEmpty ? series.first.id : null;
    customerPartyId = null;
    salesQuotationId = null;
    quotationLinesCache = null;
    orderNoController.clear();
    orderDateController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    expectedDeliveryController.clear();
    customerRefNoController.clear();
    customerRefDateController.clear();
    currencyCodeController.text = 'INR';
    exchangeRateController.text = '1';
    roundOffController.clear();
    notesController.clear();
    termsController.clear();
    isActive = true;
    lines = <OrderLineDraft>[OrderLineDraft()];
    formError = null;
    salesChain = null;
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
              stringValue(data, 'order_status') == statusFilter;
          final customerLabel = quotationCustomerLabel(data);
          final searchOk =
              search.isEmpty ||
              [
                stringValue(data, 'order_no'),
                stringValue(data, 'order_status'),
                customerLabel,
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

  List<UomModel> uomOptionsForItem(int? itemId) {
    final item = itemsLookup.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == itemId,
      orElse: () => null,
    );
    return allowedUomsForItem(item, uoms, uomConversions);
  }

  String get currencyCodeForTaxSummary {
    final currency = currencyCodeController.text.trim();
    return currency.isEmpty ? 'INR' : currency;
  }

  SalesLineTaxBreakdown taxBreakdownForLine(OrderLineDraft line) {
    return computeSalesLineTaxBreakdown(
      qty: double.tryParse(line.qtyController.text.trim()) ?? 0,
      rate: double.tryParse(line.rateController.text.trim()) ?? 0,
      discountPercent:
          double.tryParse(line.discountController.text.trim()) ?? 0,
      taxCode: salesTaxCodeById(taxCodes, line.taxCodeId),
    );
  }

  SalesDocumentTaxSummary taxSummary() {
    final roundOff = double.tryParse(roundOffController.text.trim()) ?? 0;
    return summarizeSalesLineTaxes(
      lines.map(taxBreakdownForLine),
      adjustment: roundOff,
    );
  }

  Map<String, dynamic> linePayload(OrderLineDraft line) {
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
    lines = List<OrderLineDraft>.from(lines)..add(OrderLineDraft());
    update();
  }

  void removeLine(int index) {
    final next = List<OrderLineDraft>.from(lines);
    next.removeAt(index).dispose();
    lines = next.isEmpty ? <OrderLineDraft>[OrderLineDraft()] : next;
    update();
  }

  void setFinancialYearId(int? value) {
    if (!canEdit) return;
    financialYearId = value;
    final options = seriesOptions();
    documentSeriesId = options.isNotEmpty ? options.first.id : null;
    update();
  }

  void setDocumentSeriesId(int? value) {
    if (!canEdit) return;
    documentSeriesId = value;
    update();
  }

  void setCustomerPartyId(int? value) {
    if (!canEdit) return;
    customerPartyId = value;
    if (salesQuotationId != null) {
      final stillOk = quotationChoices.any(
        (quotation) => intValue(quotation.toJson(), 'id') == salesQuotationId,
      );
      if (!stillOk) {
        salesQuotationId = null;
        quotationLinesCache = null;
        for (final line in lines) {
          line.salesQuotationLineId = null;
        }
      }
    }
    update();
  }

  void setIsActive(bool value) {
    if (!canEdit) return;
    isActive = value;
    update();
  }

  void refreshComputedState() {
    update();
  }

  void setLineItemId(int index, int? value) {
    if (!canEdit) return;
    final line = lines[index];
    line.itemId = value;
    line.salesQuotationLineId = null;
    final item = itemsLookup.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == value,
      orElse: () => null,
    );
    applySalesLineDefaultsFromItemMaster(
      item: item,
      uoms: uoms,
      conversions: uomConversions,
      rateController: line.rateController,
      setUom: (uomId) => line.uomId = uomId,
      currentUomId: line.uomId,
      setTaxCodeId: (taxCodeId) => line.taxCodeId = taxCodeId,
      setWarehouseId: (warehouseId) => line.warehouseId = warehouseId,
      currentWarehouseId: line.warehouseId,
      warehouses: warehouses,
    );
    update();
  }

  void setLineUomId(int index, int? value) {
    if (!canEdit) return;
    lines[index].uomId = value;
    update();
  }

  void setLineWarehouseId(int index, int? value) {
    if (!canEdit) return;
    lines[index].warehouseId = value;
    update();
  }

  void setLineTaxCodeId(int index, int? value) {
    if (!canEdit) return;
    lines[index].taxCodeId = value;
    update();
  }

  Future<void> save(BuildContext context) async {
    if (!canEdit) {
      formError = 'Only draft orders can be updated.';
      update();
      return;
    }
    if (!formKey.currentState!.validate()) {
      return;
    }
    if (lines.any(
      (line) =>
          line.itemId == null ||
          line.uomId == null ||
          (double.tryParse(line.qtyController.text.trim()) ?? 0) <= 0,
    )) {
      formError = 'Each line needs item, UOM, and quantity.';
      update();
      return;
    }
    saving = true;
    formError = null;
    update();
    final summary = taxSummary();
    final payload = <String, dynamic>{
      'company_id': companyId,
      'branch_id': branchId,
      'location_id': locationId,
      'financial_year_id': financialYearId,
      'document_series_id': documentSeriesId,
      'sales_quotation_id': salesQuotationId,
      'order_no': nullIfEmpty(orderNoController.text),
      'order_date': orderDateController.text.trim(),
      'expected_delivery_date': nullIfEmpty(expectedDeliveryController.text),
      'customer_party_id': customerPartyId,
      'customer_reference_no': nullIfEmpty(customerRefNoController.text),
      'customer_reference_date': nullIfEmpty(customerRefDateController.text),
      'currency_code': nullIfEmpty(currencyCodeController.text) ?? 'INR',
      'exchange_rate': double.tryParse(exchangeRateController.text.trim()) ?? 1,
      'round_off_amount': double.tryParse(roundOffController.text.trim()) ?? 0,
      'taxable_amount': roundToDouble(summary.taxable, 2),
      'cgst_amount': roundToDouble(summary.cgst, 2),
      'sgst_amount': roundToDouble(summary.sgst, 2),
      'igst_amount': roundToDouble(summary.igst, 2),
      'cess_amount': roundToDouble(summary.cess, 2),
      'total_amount': roundToDouble(summary.total, 2),
      'notes': nullIfEmpty(notesController.text),
      'terms_conditions': nullIfEmpty(termsController.text),
      'is_active': isActive,
      'lines': lines.map(linePayload).toList(growable: false),
    };
    try {
      final response = selectedItem == null
          ? await _salesService.createOrder(SalesOrderModel.fromJson(payload))
          : await _salesService.updateOrder(
              intValue(selectedItem!.toJson(), 'id')!,
              SalesOrderModel.fromJson(payload),
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
      formError = errorMessage(error);
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> docAction(
    BuildContext context,
    Future<ApiResponse<SalesOrderModel>> Function() action,
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
      formError = errorMessage(error);
      update();
    }
  }

  Future<void> deleteSelected(BuildContext context) async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) return;
    try {
      final response = await _salesService.deleteOrder(id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
      await loadPage();
    } catch (error) {
      formError = errorMessage(error);
      update();
    }
  }

  Future<void> confirmSelected(BuildContext context) async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) return;
    await docAction(
      context,
      () => _salesService.confirmOrder(
        id,
        SalesOrderModel.fromJson(const <String, dynamic>{}),
      ),
    );
  }

  Future<void> cancelSelected(BuildContext context) async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) return;
    await docAction(
      context,
      () => _salesService.cancelOrder(
        id,
        SalesOrderModel.fromJson(const <String, dynamic>{}),
      ),
    );
  }

  Future<void> closeSelected(BuildContext context) async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) return;
    await docAction(
      context,
      () => _salesService.closeOrder(
        id,
        SalesOrderModel.fromJson(const <String, dynamic>{}),
      ),
    );
  }

  void _disposeLines(List<OrderLineDraft> values) {
    for (final line in values) {
      line.dispose();
    }
  }
}
