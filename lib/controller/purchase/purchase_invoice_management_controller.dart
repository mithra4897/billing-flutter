import '../../screen.dart';

class PurchaseInvoiceManagementController extends GetxController {
  PurchaseInvoiceManagementController();

  static const List<AppDropdownItem<String>> statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All'),
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'posted', label: 'Posted'),
        AppDropdownItem(value: 'partially_paid', label: 'Partially Paid'),
        AppDropdownItem(value: 'paid', label: 'Paid'),
        AppDropdownItem(
          value: 'partially_returned',
          label: 'Partially Returned',
        ),
        AppDropdownItem(value: 'returned', label: 'Returned'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  final PurchaseService _purchaseService = PurchaseService();
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final AccountsService _accountsService = AccountsService();
  final InventoryService _inventoryService = InventoryService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController invoiceNoController = TextEditingController();
  final TextEditingController invoiceDateController = TextEditingController();
  final TextEditingController dueDateController = TextEditingController();
  final TextEditingController supplierReferenceNoController =
      TextEditingController();
  final TextEditingController supplierReferenceDateController =
      TextEditingController();
  final TextEditingController currencyCodeController = TextEditingController();
  final TextEditingController exchangeRateController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController termsController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  String statusFilter = '';
  List<PurchaseInvoiceModel> items = const <PurchaseInvoiceModel>[];
  List<PurchaseInvoiceModel> filteredItems = const <PurchaseInvoiceModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<FinancialYearModel> financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<PurchaseOrderModel> orders = const <PurchaseOrderModel>[];
  List<PurchaseReceiptModel> receipts = const <PurchaseReceiptModel>[];
  List<PartyModel> suppliers = const <PartyModel>[];
  final Map<int, PartyModel> supplierLookupById = <int, PartyModel>{};
  List<AccountModel> accounts = const <AccountModel>[];
  List<ItemModel> itemsLookup = const <ItemModel>[];
  final Map<int, ItemModel> itemLookupById = <int, ItemModel>{};
  List<UomModel> uoms = const <UomModel>[];
  List<UomConversionModel> uomConversions = const <UomConversionModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];
  List<TaxCodeModel> taxCodes = const <TaxCodeModel>[];
  PurchaseInvoiceModel? selectedItem;
  int? contextCompanyId;
  int? contextBranchId;
  int? contextLocationId;
  int? contextFinancialYearId;
  int? companyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? documentSeriesId;
  int? purchaseOrderId;
  int? purchaseReceiptId;
  int? supplierPartyId;
  int? adjustmentAccountId;
  List<PurchaseInvoiceLineModel> lines = <PurchaseInvoiceLineModel>[];
  bool isActive = true;
  bool _initialized = false;

  bool get canEditSelectedInvoice {
    if (selectedItem == null) {
      return true;
    }
    return purchaseDocumentIsDraftEditable(selectedItem!.invoiceStatus);
  }

  bool get isSelectedInvoiceReadOnly =>
      selectedItem != null && !canEditSelectedInvoice;

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
    invoiceNoController.dispose();
    invoiceDateController.dispose();
    dueDateController.dispose();
    supplierReferenceNoController.dispose();
    supplierReferenceDateController.dispose();
    currencyCodeController.dispose();
    exchangeRateController.dispose();
    notesController.dispose();
    termsController.dispose();
    super.onClose();
  }

  Future<void> initialize({int? initialId}) async {
    if (!_initialized) _initialized = true;
    await loadPage(selectId: initialId);
  }

  Future<void> _handleWorkingContextChanged() async {
    await loadPage(selectId: selectedItem?.id);
  }

  Future<void> loadPage({int? selectId}) async {
    initialLoading = items.isEmpty;
    pageError = null;
    update();
    try {
      final responses = await Future.wait<dynamic>([
        _purchaseService.invoices(
          filters: const {'per_page': 200, 'sort_by': 'invoice_date'},
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
        _purchaseService.ordersAll(filters: const {'sort_by': 'order_date'}),
        _purchaseService.receiptsAll(
          filters: const {'sort_by': 'receipt_date'},
        ),
        _partiesService.partyTypes(filters: const {'per_page': 100}),
        _partiesService.parties(
          filters: const {'per_page': 300, 'sort_by': 'party_name'},
        ),
        _accountsService.accountsAll(
          filters: const {'sort_by': 'account_name'},
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
          (responses[0] as PaginatedResponse<PurchaseInvoiceModel>).data ??
          const <PurchaseInvoiceModel>[];
      companies =
          (responses[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      financialYears =
          (responses[4] as PaginatedResponse<FinancialYearModel>).data ??
          const <FinancialYearModel>[];
      documentSeries =
          ((responses[5] as PaginatedResponse<DocumentSeriesModel>).data ??
                  const <DocumentSeriesModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      orders =
          (responses[6] as ApiResponse<List<PurchaseOrderModel>>).data ??
          const <PurchaseOrderModel>[];
      receipts =
          (responses[7] as ApiResponse<List<PurchaseReceiptModel>>).data ??
          const <PurchaseReceiptModel>[];
      suppliers = purchaseSuppliers(
        parties:
            (responses[9] as PaginatedResponse<PartyModel>).data ??
            const <PartyModel>[],
        partyTypes:
            (responses[8] as PaginatedResponse<PartyTypeModel>).data ??
            const <PartyTypeModel>[],
      );
      supplierLookupById
        ..clear()
        ..addEntries(
          suppliers
              .where((item) => item.id != null)
              .map((item) => MapEntry(item.id!, item)),
        );
      accounts =
          ((responses[10] as ApiResponse<List<AccountModel>>).data ??
                  const <AccountModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      itemsLookup =
          ((responses[11] as PaginatedResponse<ItemModel>).data ??
                  const <ItemModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      itemLookupById
        ..clear()
        ..addEntries(
          itemsLookup
              .where((item) => item.id != null)
              .map((item) => MapEntry(item.id!, item)),
        );
      uoms =
          ((responses[12] as PaginatedResponse<UomModel>).data ??
                  const <UomModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      uomConversions =
          ((responses[13] as ApiResponse<List<UomConversionModel>>).data ??
                  const <UomConversionModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      warehouses =
          ((responses[14] as PaginatedResponse<WarehouseModel>).data ??
                  const <WarehouseModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      taxCodes =
          ((responses[15] as PaginatedResponse<TaxCodeModel>).data ??
                  const <TaxCodeModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      contextCompanyId = contextSelection.companyId;
      contextBranchId = contextSelection.branchId;
      contextLocationId = contextSelection.locationId;
      contextFinancialYearId = contextSelection.financialYearId;
      initialLoading = false;
      filteredItems = _filterItems(items, searchController.text, statusFilter);
      update();

      final selected = selectId != null
          ? items.cast<PurchaseInvoiceModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : null;
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
    PurchaseInvoiceModel item, {
    bool notify = true,
  }) async {
    final response = await _purchaseService.invoice(item.id!);
    final full = response.data ?? item;
    selectedItem = full;
    companyId = full.companyId;
    branchId = full.branchId;
    locationId = full.locationId;
    financialYearId = full.financialYearId;
    documentSeriesId = full.documentSeriesId;
    purchaseOrderId = full.purchaseOrderId;
    purchaseReceiptId = full.purchaseReceiptId;
    supplierPartyId = full.supplierPartyId;
    adjustmentAccountId = full.adjustmentAccountId;
    invoiceNoController.text = full.invoiceNo ?? '';
    invoiceDateController.text = displayDate(full.invoiceDate);
    dueDateController.text = displayDate(full.dueDate);
    supplierReferenceNoController.text = full.supplierReferenceNo ?? '';
    supplierReferenceDateController.text = displayDate(
      full.supplierReferenceDate,
    );
    currencyCodeController.text = full.currencyCode ?? 'INR';
    exchangeRateController.text = full.exchangeRate?.toString() ?? '1';
    notesController.text = full.notes ?? '';
    termsController.text = full.termsConditions ?? '';
    lines = full.lines.isEmpty
        ? <PurchaseInvoiceLineModel>[
            PurchaseInvoiceLineModel(
              itemId: 0,
              uomId: 0,
              invoicedQty: 0,
              rate: 0,
            ),
          ]
        : full.lines;
    isActive = full.isActive;
    formError = null;
    if (full.purchaseReceiptId != null) {
      unawaited(enrichLinesFromReceiptHeader(full.purchaseReceiptId!));
    }
    if (notify) update();
  }

  void resetForm({bool notify = true}) {
    final series = seriesOptions();
    selectedItem = null;
    companyId = contextCompanyId;
    branchId = contextBranchId;
    locationId = contextLocationId;
    financialYearId = contextFinancialYearId;
    documentSeriesId = series.isNotEmpty ? series.first.id : null;
    purchaseOrderId = null;
    purchaseReceiptId = null;
    supplierPartyId = null;
    adjustmentAccountId = null;
    invoiceNoController.clear();
    invoiceDateController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    dueDateController.clear();
    supplierReferenceNoController.clear();
    supplierReferenceDateController.clear();
    currencyCodeController.text = 'INR';
    exchangeRateController.text = '1';
    notesController.clear();
    termsController.clear();
    lines = <PurchaseInvoiceLineModel>[
      PurchaseInvoiceLineModel(itemId: 0, uomId: 0, invoicedQty: 0, rate: 0),
    ];
    isActive = true;
    formError = null;
    if (notify) update();
  }

  List<PurchaseInvoiceModel> _filterItems(
    List<PurchaseInvoiceModel> source,
    String query,
    String status,
  ) {
    return filterBySearchAndStatus(
      source,
      query: query,
      status: status,
      statusOf: (item) => item.invoiceStatus,
      searchFieldsOf: (item) => <String>[
        item.invoiceNo ?? '',
        purchaseStatusLabel(item.invoiceStatus),
        item.toJson()['supplier_name']?.toString() ?? '',
      ],
    );
  }

  void _applyFilters() {
    filteredItems = _filterItems(items, searchController.text, statusFilter);
    update();
  }

  void setStatusFilter(String value) {
    statusFilter = value;
    _applyFilters();
  }

  ItemModel? itemById(int? itemId) =>
      itemId == null ? null : itemLookupById[itemId];

  PartyModel? supplierById(int? supplierId) =>
      supplierId == null ? null : supplierLookupById[supplierId];

  DocumentPrintDataModel purchaseInvoicePrintData() {
    final company = companies.cast<CompanyModel?>().firstWhere(
      (item) => item?.id == companyId,
      orElse: () => null,
    );
    final supplier = supplierById(supplierPartyId);
    var subtotal = 0.0;
    var taxAmount = 0.0;
    final gstBreakupGroups = <String, dynamic>{};
    final printLines = lines
        .where((line) => line.itemId > 0)
        .map((line) {
          final qty = line.invoicedQty;
          final rate = line.rate;
          final discount = line.discountPercent ?? 0;
          final taxCode = purchaseTaxCodeById(taxCodes, line.taxCodeId);
          final breakdown = computePurchaseLineTaxBreakdown(
            qty: qty,
            rate: rate,
            discountPercent: discount,
            taxCode: taxCode,
            taxPercent: line.taxPercent,
            taxType: line.taxType,
          );
          final taxPercent = (line.taxPercent ?? taxCode?.taxRate ?? 0)
              .toDouble();
          subtotal += breakdown.taxable;
          taxAmount += breakdown.total - breakdown.taxable;
          accumulatePrintTemplateGstBreakup(
            gstBreakupGroups,
            taxCode: taxCode,
            taxPercent: taxPercent,
            taxable: breakdown.taxable,
            cgst: breakdown.cgst,
            sgst: breakdown.sgst,
            igst: breakdown.igst,
          );
          final item = itemById(line.itemId);
          return DocumentPrintLineModel(
            itemName:
                item?.itemName ?? item?.itemCode ?? (line.description ?? ''),
            description: line.description ?? '',
            qty: qty,
            rate: rate,
            taxAmount: double.parse(
              (breakdown.total - breakdown.taxable).toStringAsFixed(2),
            ),
            lineTotal: double.parse(breakdown.taxable.toStringAsFixed(2)),
          );
        })
        .toList(growable: false);

    final roundedSubtotal = double.parse(subtotal.toStringAsFixed(2));
    final roundedTax = double.parse(taxAmount.toStringAsFixed(2));
    final roundedTotal = double.parse(
      (subtotal + taxAmount).toStringAsFixed(2),
    );
    return buildManagedDocumentPrintData(
      companies: companies,
      companyId: companyId,
      company: company,
      documentNumber: nullIfEmpty(invoiceNoController.text) ?? 'Draft',
      documentDate: invoiceDateController.text.trim(),
      referenceNumber: supplierReferenceNoController.text.trim(),
      partyName: supplier?.partyName ?? '',
      notes: notesController.text.trim(),
      termsConditions: termsController.text.trim(),
      subtotal: roundedSubtotal,
      taxAmount: roundedTax,
      totalAmount: roundedTotal,
      currencyCode: currencyCodeController.text.trim().isEmpty
          ? 'INR'
          : currencyCodeController.text.trim(),
      lines: printLines,
      gstBreakup: finalizePrintTemplateGstBreakup(gstBreakupGroups),
    );
  }

  Future<void> openPrintPreview(BuildContext context) {
    return openManagedDocumentPrintPreview(
      context,
      documentType: 'purchase_invoice',
      title: 'Purchase Invoice',
      documentData: purchaseInvoicePrintData(),
    );
  }

  PurchaseLineTaxBreakdown taxBreakdownForLine(PurchaseInvoiceLineModel line) {
    return computePurchaseLineTaxBreakdown(
      qty: line.invoicedQty,
      rate: line.rate,
      discountPercent: line.discountPercent ?? 0,
      taxCode: purchaseTaxCodeById(taxCodes, line.taxCodeId),
      taxPercent: line.taxPercent,
      taxType: line.taxType,
    );
  }

  PurchaseDocumentTaxSummary invoiceTaxSummary() {
    return summarizePurchaseLineTaxes(lines.map(taxBreakdownForLine));
  }

  List<UomModel> uomOptionsForItem(int? itemId) {
    return allowedUomsForItem(itemById(itemId), uoms, uomConversions);
  }

  int? resolveDefaultUom(int? itemId, int? currentUomId) {
    return defaultUomIdForItem(
      itemById(itemId),
      uoms,
      uomConversions,
      current: currentUomId,
    );
  }

  List<DocumentSeriesModel> seriesOptions() {
    return documentSeries
        .where((item) {
          final typeOk =
              item.documentType == null ||
              item.documentType == 'PURCHASE_INVOICE';
          final companyOk = companyId == null || item.companyId == companyId;
          final fyOk =
              financialYearId == null ||
              item.financialYearId == financialYearId;
          return typeOk && companyOk && fyOk;
        })
        .toList(growable: false);
  }

  int? defaultSeriesIdFor({
    required int? companyId,
    required int? financialYearId,
  }) {
    final options = documentSeries
        .where((item) {
          final typeOk =
              item.documentType == null ||
              item.documentType == 'PURCHASE_INVOICE';
          final companyOk = companyId == null || item.companyId == companyId;
          final fyOk =
              financialYearId == null ||
              item.financialYearId == financialYearId;
          return typeOk && companyOk && fyOk;
        })
        .toList(growable: false);
    return options.isNotEmpty ? options.first.id : null;
  }

  double pendingInvoiceQtyForOrderLine(Map<String, dynamic> line) {
    final orderedQty = double.tryParse(stringValue(line, 'ordered_qty')) ?? 0;
    final invoicedQty = double.tryParse(stringValue(line, 'invoiced_qty')) ?? 0;
    return (orderedQty - invoicedQty).clamp(0, double.infinity).toDouble();
  }

  List<PurchaseInvoiceLineModel> buildInvoiceLinesFromOrder(
    PurchaseOrderModel order,
  ) {
    final orderLines = (order.toJson()['lines'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();
    final nextLines = orderLines
        .map((line) {
          final pendingQty = pendingInvoiceQtyForOrderLine(line);
          if (pendingQty <= 0) return null;
          return PurchaseInvoiceLineModel(
            purchaseOrderLineId: intValue(line, 'id'),
            itemId: intValue(line, 'item_id') ?? 0,
            warehouseId: intValue(line, 'warehouse_id'),
            uomId: intValue(line, 'uom_id') ?? 0,
            invoicedQty: pendingQty,
            rate: double.tryParse(stringValue(line, 'rate')) ?? 0,
            description: nullableStringValue(line, 'description'),
            discountPercent:
                double.tryParse(stringValue(line, 'discount_percent')) ?? 0,
            taxCodeId: intValue(line, 'tax_code_id'),
            remarks: nullableStringValue(line, 'remarks'),
          );
        })
        .whereType<PurchaseInvoiceLineModel>()
        .toList(growable: false);
    return nextLines.isEmpty
        ? <PurchaseInvoiceLineModel>[
            PurchaseInvoiceLineModel(
              itemId: 0,
              uomId: 0,
              invoicedQty: 0,
              rate: 0,
            ),
          ]
        : nextLines;
  }

  List<PurchaseInvoiceLineModel> mergeInvoiceLinesWithReceiptLines(
    PurchaseReceiptModel receipt,
    List<PurchaseInvoiceLineModel> sourceLines,
  ) {
    final receiptLines =
        (receipt.toJson()['lines'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
    final pendingLeft = <int, double>{};
    for (final rl in receiptLines) {
      final id = intValue(rl, 'id');
      if (id == null) continue;
      pendingLeft[id] =
          double.tryParse(stringValue(rl, 'pending_invoice_qty')) ?? 0;
    }
    return sourceLines
        .map((line) {
          if (line.itemId <= 0 || line.purchaseOrderLineId == null) {
            return line.copyWith(purchaseReceiptLineId: null);
          }
          final candidates =
              receiptLines
                  .where(
                    (rl) =>
                        intValue(rl, 'purchase_order_line_id') ==
                            line.purchaseOrderLineId &&
                        intValue(rl, 'item_id') == line.itemId,
                  )
                  .map((rl) => intValue(rl, 'id'))
                  .whereType<int>()
                  .toList()
                ..sort();
          int? chosenId;
          for (final id in candidates) {
            if ((pendingLeft[id] ?? 0) > 0) {
              chosenId = id;
              break;
            }
          }
          if (chosenId == null) {
            return line.copyWith(purchaseReceiptLineId: null);
          }
          var qty = line.invoicedQty;
          final cap = pendingLeft[chosenId] ?? 0;
          if (qty > cap) qty = cap;
          pendingLeft[chosenId] = (pendingLeft[chosenId] ?? 0) - qty;
          return line.copyWith(
            purchaseReceiptLineId: chosenId,
            invoicedQty: qty,
          );
        })
        .toList(growable: false);
  }

  Future<void> enrichLinesFromReceiptHeader(int receiptId) async {
    final needs = lines.any(
      (l) =>
          l.purchaseOrderLineId != null &&
          l.itemId > 0 &&
          l.purchaseReceiptLineId == null,
    );
    if (!needs) return;
    final response = await _purchaseService.receipt(receiptId);
    if (response.data == null) return;
    final next = mergeInvoiceLinesWithReceiptLines(response.data!, lines);
    var changed = false;
    if (lines.length != next.length) {
      changed = true;
    } else {
      for (var i = 0; i < lines.length; i++) {
        final a = lines[i];
        final b = next[i];
        if (a.purchaseReceiptLineId != b.purchaseReceiptLineId ||
            a.invoicedQty != b.invoicedQty) {
          changed = true;
          break;
        }
      }
    }
    if (!changed) return;
    lines = next;
    formError = null;
    update();
  }

  Future<void> handlePurchaseReceiptChanged(int? receiptId) async {
    if (receiptId == null) {
      purchaseReceiptId = null;
      lines = lines
          .map((l) => l.copyWith(purchaseReceiptLineId: null))
          .toList(growable: false);
      formError = null;
      update();
      return;
    }
    purchaseReceiptId = receiptId;
    update();
    final response = await _purchaseService.receipt(receiptId);
    if (response.data == null) return;
    final receipt = response.data!;
    final receiptPoId = intValue(receipt.toJson(), 'purchase_order_id');
    if (purchaseOrderId != null &&
        receiptPoId != null &&
        receiptPoId != purchaseOrderId) {
      purchaseReceiptId = null;
      lines = lines
          .map((l) => l.copyWith(purchaseReceiptLineId: null))
          .toList(growable: false);
      formError =
          'Purchase receipt does not belong to the selected purchase order.';
      update();
      return;
    }
    lines = mergeInvoiceLinesWithReceiptLines(receipt, lines);
    formError = null;
    update();
  }

  Future<void> handlePurchaseOrderChanged(int? orderId) async {
    if (orderId == null) {
      purchaseOrderId = null;
      purchaseReceiptId = null;
      supplierPartyId = null;
      lines = <PurchaseInvoiceLineModel>[
        PurchaseInvoiceLineModel(itemId: 0, uomId: 0, invoicedQty: 0, rate: 0),
      ];
      formError = null;
      update();
      return;
    }
    final response = await _purchaseService.order(orderId);
    final order = response.data;
    if (order == null) return;
    final data = order.toJson();
    final nextLines = buildInvoiceLinesFromOrder(order);
    final nextCompanyId = intValue(data, 'company_id');
    final nextFinancialYearId = intValue(data, 'financial_year_id');
    purchaseOrderId = orderId;
    purchaseReceiptId = null;
    companyId = nextCompanyId;
    branchId = intValue(data, 'branch_id');
    locationId = intValue(data, 'location_id');
    financialYearId = nextFinancialYearId;
    documentSeriesId = defaultSeriesIdFor(
      companyId: nextCompanyId,
      financialYearId: nextFinancialYearId,
    );
    supplierPartyId = intValue(data, 'supplier_party_id');
    invoiceNoController.clear();
    dueDateController.text = displayDate(
      nullableStringValue(data, 'expected_receipt_date'),
    );
    supplierReferenceNoController.text = stringValue(
      data,
      'supplier_reference_no',
    );
    supplierReferenceDateController.text = displayDate(
      nullableStringValue(data, 'supplier_reference_date'),
    );
    currencyCodeController.text = stringValue(data, 'currency_code', 'INR');
    exchangeRateController.text = stringValue(data, 'exchange_rate', '1');
    notesController.text = stringValue(data, 'notes');
    termsController.text = stringValue(data, 'terms_conditions');
    lines = nextLines;
    formError = nextLines.length == 1 && nextLines.first.itemId == 0
        ? 'Selected purchase order has no pending invoice quantity.'
        : null;
    update();
  }

  void addLine() {
    lines = List<PurchaseInvoiceLineModel>.from(lines)
      ..add(
        PurchaseInvoiceLineModel(itemId: 0, uomId: 0, invoicedQty: 0, rate: 0),
      );
    update();
  }

  void updateLine(int index, PurchaseInvoiceLineModel line) {
    final next = List<PurchaseInvoiceLineModel>.from(lines);
    next[index] = line;
    lines = next;
    update();
  }

  void removeLine(int index) {
    final next = List<PurchaseInvoiceLineModel>.from(lines)..removeAt(index);
    if (next.isEmpty) {
      next.add(
        PurchaseInvoiceLineModel(itemId: 0, uomId: 0, invoicedQty: 0, rate: 0),
      );
    }
    lines = next;
    update();
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

  void setSupplierPartyId(int? value) {
    supplierPartyId = value;
    update();
  }

  void setAdjustmentAccountId(int? value) {
    adjustmentAccountId = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  Future<void> save(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;
    if (lines.any(
      (line) => line.itemId <= 0 || line.uomId <= 0 || line.invoicedQty <= 0,
    )) {
      formError = 'Each line needs item, UOM, and invoiced quantity.';
      update();
      return;
    }
    saving = true;
    formError = null;
    update();
    final invoice = PurchaseInvoiceModel(
      id: selectedItem?.id ?? 0,
      companyId: companyId ?? 0,
      branchId: branchId ?? 0,
      locationId: locationId ?? 0,
      financialYearId: financialYearId ?? 0,
      supplierPartyId: supplierPartyId ?? 0,
      invoiceDate: invoiceDateController.text.trim(),
      documentSeriesId: documentSeriesId,
      purchaseOrderId: purchaseOrderId,
      purchaseReceiptId: purchaseReceiptId,
      invoiceNo: nullIfEmpty(invoiceNoController.text),
      dueDate: nullIfEmpty(dueDateController.text),
      currencyCode: nullIfEmpty(currencyCodeController.text),
      exchangeRate: double.tryParse(exchangeRateController.text.trim()),
      adjustmentAccountId: adjustmentAccountId,
      notes: nullIfEmpty(notesController.text),
      termsConditions: nullIfEmpty(termsController.text),
      supplierReferenceNo: nullIfEmpty(supplierReferenceNoController.text),
      supplierReferenceDate: nullIfEmpty(supplierReferenceDateController.text),
      isActive: isActive,
      lines: lines,
    );
    try {
      final response = selectedItem == null
          ? await _purchaseService.createInvoice(invoice)
          : await _purchaseService.updateInvoice(selectedItem!.id!, invoice);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
      final saved = response.data;
      if (saved != null) {
        _upsertInvoice(saved);
        await selectDocument(saved, notify: false);
        update();
      } else {
        await loadPage(selectId: response.data?.id);
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
    Future<ApiResponse<PurchaseInvoiceModel>> Function() action,
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
        _upsertInvoice(updated);
        await selectDocument(updated, notify: false);
        update();
      } else {
        await loadPage(selectId: response.data?.id);
      }
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
    }
  }

  void _upsertInvoice(PurchaseInvoiceModel invoice) {
    final id = invoice.id;
    if (id == null) {
      return;
    }
    final nextItems = List<PurchaseInvoiceModel>.from(items);
    final existingIndex = nextItems.indexWhere((item) => item.id == id);
    if (existingIndex >= 0) {
      nextItems[existingIndex] = invoice;
    } else {
      nextItems.insert(0, invoice);
    }
    items = nextItems;
    _applyFilters();
  }
}
