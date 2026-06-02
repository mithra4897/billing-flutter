import '../../screen.dart';
import '../../helper/purchase_register_reload_helper.dart';

enum PurchaseOrderLinkDriver { none, supplier, requisition }

class PurchaseOrderLineDraft {
  PurchaseOrderLineDraft({
    this.purchaseRequisitionLineId,
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

  factory PurchaseOrderLineDraft.fromRequisitionLine(
    Map<String, dynamic> json,
  ) {
    final pendingQty = double.tryParse(stringValue(json, 'pending_qty'));
    final requestedQty = double.tryParse(stringValue(json, 'requested_qty'));
    final effectiveQty = pendingQty != null && pendingQty > 0
        ? pendingQty
        : (requestedQty ?? 0);

    return PurchaseOrderLineDraft(
      purchaseRequisitionLineId: intValue(json, 'id'),
      itemId: intValue(json, 'item_id'),
      warehouseId: intValue(json, 'warehouse_id'),
      uomId: intValue(json, 'uom_id'),
      description: stringValue(json, 'description'),
      qty: effectiveQty > 0 ? effectiveQty.toString() : '',
      rate: stringValue(json, 'estimated_rate'),
      remarks: stringValue(json, 'remarks'),
    );
  }

  factory PurchaseOrderLineDraft.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderLineDraft(
      purchaseRequisitionLineId: intValue(json, 'purchase_requisition_line_id'),
      itemId: intValue(json, 'item_id'),
      warehouseId: intValue(json, 'warehouse_id'),
      uomId: intValue(json, 'uom_id'),
      taxCodeId: intValue(json, 'tax_code_id'),
      description: stringValue(json, 'description'),
      qty: stringValue(json, 'ordered_qty'),
      rate: stringValue(json, 'rate'),
      discountPercent: stringValue(json, 'discount_percent'),
      remarks: stringValue(json, 'remarks'),
    );
  }

  int? purchaseRequisitionLineId;
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
      'purchase_requisition_line_id': purchaseRequisitionLineId,
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

class PurchaseOrderManagementController extends GetxController {
  PurchaseOrderManagementController();

  static const int allSelectionId = -1;
  static const List<AppDropdownItem<String>>
  statusItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'confirmed', label: 'Confirmed'),
    AppDropdownItem(value: 'partially_received', label: 'Partially Received'),
    AppDropdownItem(value: 'fully_received', label: 'Fully Received'),
    AppDropdownItem(value: 'partially_invoiced', label: 'Partially Invoiced'),
    AppDropdownItem(value: 'fully_invoiced', label: 'Fully Invoiced'),
    AppDropdownItem(value: 'closed', label: 'Closed'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  final PurchaseService _purchaseService = PurchaseService();
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
  final TextEditingController expectedReceiptDateController =
      TextEditingController();
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
  List<PurchaseOrderModel> items = const <PurchaseOrderModel>[];
  List<PurchaseOrderModel> filteredItems = const <PurchaseOrderModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<FinancialYearModel> financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<PurchaseRequisitionModel> requisitions =
      const <PurchaseRequisitionModel>[];
  List<PartyModel> suppliers = const <PartyModel>[];
  List<ItemModel> itemsLookup = const <ItemModel>[];
  List<UomModel> uoms = const <UomModel>[];
  List<UomConversionModel> uomConversions = const <UomConversionModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];
  List<TaxCodeModel> taxCodes = const <TaxCodeModel>[];
  List<ItemSupplierMapModel> itemSupplierMaps = const <ItemSupplierMapModel>[];
  final Map<int, PartyModel> supplierDetailsById = <int, PartyModel>{};
  final Map<int, List<PartyGstDetailModel>> supplierGstDetailsById =
      <int, List<PartyGstDetailModel>>{};
  PurchaseOrderModel? selectedItem;
  int? contextCompanyId;
  int? contextBranchId;
  int? contextLocationId;
  int? contextFinancialYearId;
  int? companyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? documentSeriesId;
  int? purchaseRequisitionId;
  int? supplierPartyId;
  bool isActive = true;
  String? selectionInfo;
  List<PurchaseOrderLineDraft> lines = <PurchaseOrderLineDraft>[];
  final Map<int, PurchaseRequisitionModel> requisitionDetailCache =
      <int, PurchaseRequisitionModel>{};
  PurchaseOrderLinkDriver linkDriver = PurchaseOrderLinkDriver.none;
  bool _initialized = false;

  bool get canEditSelectedOrder {
    if (selectedItem == null) return true;
    return purchaseDocumentIsDraftEditable(
      stringValue(selectedItem!.toJson(), 'order_status'),
    );
  }

  bool get isSelectedOrderReadOnly =>
      selectedItem != null && !canEditSelectedOrder;

  bool get isAllSupplierSelected => supplierPartyId == allSelectionId;
  bool get isAllRequisitionSelected => purchaseRequisitionId == allSelectionId;
  bool get hasSpecificSupplierSelection =>
      supplierPartyId != null && !isAllSupplierSelected;
  bool get hasSpecificRequisitionSelection =>
      purchaseRequisitionId != null && !isAllRequisitionSelected;

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
    expectedReceiptDateController.dispose();
    supplierReferenceNoController.dispose();
    supplierReferenceDateController.dispose();
    currencyCodeController.dispose();
    exchangeRateController.dispose();
    notesController.dispose();
    termsController.dispose();
    _disposeLines(lines);
    super.onClose();
  }

  Future<void> initialize({int? initialId}) async {
    if (!_initialized) _initialized = true;
    await loadPage(selectId: initialId);
    reloadPurchaseOrderRegister();
  }

  Future<void> _handleWorkingContextChanged() async {
    await loadPage(
      selectId: intValue(selectedItem?.toJson() ?? const {}, 'id'),
    );
    reloadPurchaseOrderRegister();
  }

  Future<void> loadPage({int? selectId}) async {
    initialLoading = items.isEmpty;
    pageError = null;
    update();
    try {
      final responses = await Future.wait<dynamic>([
        _purchaseService.ordersAll(filters: const {'sort_by': 'order_date'}),
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
        _purchaseService.requisitionsAll(
          filters: const {'sort_by': 'requisition_date'},
        ),
        _partiesService.partyTypes(filters: const {'per_page': 100}),
        _partiesService.parties(
          filters: const {'per_page': 300, 'sort_by': 'party_name'},
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
        _inventoryService.itemSupplierMaps(
          filters: const {'per_page': 1000, 'is_active': 1},
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
          (responses[0] as ApiResponse<List<PurchaseOrderModel>>).data ??
          const <PurchaseOrderModel>[];
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
      requisitions =
          (responses[6] as ApiResponse<List<PurchaseRequisitionModel>>).data ??
          const <PurchaseRequisitionModel>[];
      suppliers = purchaseSuppliers(
        parties:
            ((responses[8] as PaginatedResponse<PartyModel>).data ??
            const <PartyModel>[]),
        partyTypes:
            (responses[7] as PaginatedResponse<PartyTypeModel>).data ??
            const <PartyTypeModel>[],
      );
      itemsLookup =
          ((responses[9] as PaginatedResponse<ItemModel>).data ??
                  const <ItemModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      uoms =
          ((responses[10] as PaginatedResponse<UomModel>).data ??
                  const <UomModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      uomConversions =
          ((responses[11] as ApiResponse<List<UomConversionModel>>).data ??
                  const <UomConversionModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      warehouses =
          ((responses[12] as PaginatedResponse<WarehouseModel>).data ??
                  const <WarehouseModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      taxCodes =
          ((responses[13] as PaginatedResponse<TaxCodeModel>).data ??
                  const <TaxCodeModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      itemSupplierMaps =
          ((responses[14] as PaginatedResponse<ItemSupplierMapModel>).data ??
                  const <ItemSupplierMapModel>[])
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
          ? items.cast<PurchaseOrderModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : null;
      if (selected == null && selectId != null) {
        try {
          final detail = (await _purchaseService.order(selectId)).data;
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
    PurchaseOrderModel item, {
    bool notify = true,
  }) async {
    final id = intValue(item.toJson(), 'id');
    if (id == null) return;
    final response = await _purchaseService.order(id);
    final full = response.data ?? item;
    final data = full.toJson();
    final nextLines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(PurchaseOrderLineDraft.fromJson)
        .toList(growable: true);
    selectedItem = full;
    companyId = intValue(data, 'company_id');
    branchId = intValue(data, 'branch_id');
    locationId = intValue(data, 'location_id');
    financialYearId = intValue(data, 'financial_year_id');
    documentSeriesId = intValue(data, 'document_series_id');
    purchaseRequisitionId = intValue(data, 'purchase_requisition_id');
    supplierPartyId = intValue(data, 'supplier_party_id');
    orderNoController.text = stringValue(data, 'order_no');
    orderDateController.text = displayDate(
      nullableStringValue(data, 'order_date'),
    );
    expectedReceiptDateController.text = displayDate(
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
    isActive = boolValue(data, 'is_active', fallback: true);
    _replaceLines(nextLines, notify: false);
    formError = null;
    selectionInfo = null;
    _upsertOrder(full, notify: false);
    if (notify) update();
  }

  void resetForm({bool notify = true}) {
    final seriesOpts = seriesOptions();
    selectedItem = null;
    companyId = contextCompanyId;
    branchId = contextBranchId;
    locationId = contextLocationId;
    financialYearId = contextFinancialYearId;
    documentSeriesId = seriesOpts.isNotEmpty ? seriesOpts.first.id : null;
    purchaseRequisitionId = null;
    supplierPartyId = null;
    orderNoController.clear();
    orderDateController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    expectedReceiptDateController.clear();
    supplierReferenceNoController.clear();
    supplierReferenceDateController.clear();
    currencyCodeController.text = 'INR';
    exchangeRateController.text = '1';
    notesController.clear();
    termsController.clear();
    isActive = true;
    _replaceLines(const <PurchaseOrderLineDraft>[], notify: false);
    formError = null;
    selectionInfo = null;
    linkDriver = PurchaseOrderLinkDriver.none;
    if (notify) update();
  }

  List<PurchaseOrderModel> _filterItems(
    List<PurchaseOrderModel> source,
    String query,
    String status,
  ) {
    return filterBySearchAndStatus(
      source,
      query: query,
      status: status,
      statusOf: (item) => stringValue(item.toJson(), 'order_status'),
      searchFieldsOf: (item) {
        final data = item.toJson();
        return <String>[
          stringValue(data, 'order_no'),
          purchaseStatusLabel(nullableStringValue(data, 'order_status')),
          stringValue(data, 'supplier_name'),
          stringValue(data, 'supplier_reference_no'),
        ];
      },
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

  PurchaseLineTaxBreakdown taxBreakdownForLine(PurchaseOrderLineDraft line) {
    final qty = double.tryParse(line.qtyController.text.trim()) ?? 0;
    final rate = double.tryParse(line.rateController.text.trim()) ?? 0;
    final discount = double.tryParse(line.discountController.text.trim()) ?? 0;
    return computePurchaseLineTaxBreakdown(
      qty: qty,
      rate: rate,
      discountPercent: discount,
      taxCode: purchaseTaxCodeById(taxCodes, line.taxCodeId),
    );
  }

  PurchaseDocumentTaxSummary orderTaxSummary() {
    return summarizePurchaseLineTaxes(lines.map(taxBreakdownForLine));
  }

  PartyModel? supplierById(int? supplierId) {
    return suppliers.cast<PartyModel?>().firstWhere(
      (entry) => entry?.id == supplierId,
      orElse: () => null,
    );
  }

  PartyModel? supplierForPrintContext(int? supplierId) {
    if (supplierId == null) {
      return null;
    }
    return supplierDetailsById[supplierId] ?? supplierById(supplierId);
  }

  Future<void> ensureSupplierPrintContext(int? supplierId) async {
    if (supplierId == null) {
      return;
    }
    try {
      final responses = await Future.wait<dynamic>([
        _partiesService.party(supplierId),
        _partiesService.partyAddresses(
          supplierId,
          filters: const <String, dynamic>{'per_page': 100},
        ),
        _partiesService.partyContacts(
          supplierId,
          filters: const <String, dynamic>{'per_page': 100},
        ),
        _partiesService.partyGstDetails(
          supplierId,
          filters: const <String, dynamic>{'per_page': 100},
        ),
      ]);
      final party = (responses[0] as ApiResponse<PartyModel>).data;
      if (party != null) {
        supplierDetailsById[supplierId] = party.copyWith(
          addresses:
              (responses[1] as PaginatedResponse<PartyAddressModel>).data ??
              party.addresses,
          contacts:
              (responses[2] as PaginatedResponse<PartyContactModel>).data ??
              party.contacts,
        );
        supplierGstDetailsById[supplierId] =
            (responses[3] as PaginatedResponse<PartyGstDetailModel>).data ??
            party.gstDetails;
      }
    } catch (_) {}
  }

  DocumentPrintDataModel purchaseOrderPrintData() {
    final company = companies.cast<CompanyModel?>().firstWhere(
      (item) => item?.id == companyId,
      orElse: () => null,
    );
    final selected = selectedItem;
    final selectedData = selected?.toJson() ?? const <String, dynamic>{};
    final supplier = supplierForPrintContext(supplierPartyId);
    final supplierData = supplier?.toJson() ?? const <String, dynamic>{};
    final preferredAddress = preferredPartyAddress(
      supplier,
      shippingAddressId: intValue(selectedData, 'shipping_address_id'),
      billingAddressId: intValue(selectedData, 'billing_address_id'),
    );
    final summary = orderTaxSummary();
    final gstBreakupGroups = <String, dynamic>{};
    final printLines = lines
        .where((line) => line.itemId != null && line.itemId! > 0)
        .map((line) {
          final item = itemById(line.itemId);
          final breakdown = taxBreakdownForLine(line);
          final taxCode = purchaseTaxCodeById(taxCodes, line.taxCodeId);
          accumulatePrintTemplateGstBreakup(
            gstBreakupGroups,
            taxCode: taxCode,
            taxPercent: (taxCode?.taxRate ?? 0).toDouble(),
            taxable: breakdown.taxable,
            cgst: breakdown.cgst,
            sgst: breakdown.sgst,
            igst: breakdown.igst,
          );
          return DocumentPrintLineModel(
            itemName:
                item?.itemName ??
                item?.itemCode ??
                line.descriptionController.text.trim(),
            description: line.descriptionController.text.trim(),
            qty: double.tryParse(line.qtyController.text.trim()) ?? 0,
            rate: double.tryParse(line.rateController.text.trim()) ?? 0,
            taxAmount: roundToDouble(breakdown.total - breakdown.taxable, 2),
            lineTotal: roundToDouble(breakdown.taxable, 2),
          );
        })
        .toList(growable: false);
    final totalTax = summary.cgst + summary.sgst + summary.igst + summary.cess;

    return buildManagedDocumentPrintData(
      companies: companies,
      companyId: companyId,
      company: company,
      documentNumber: nullIfEmpty(orderNoController.text) ?? 'Draft',
      documentDate: orderDateController.text.trim(),
      referenceNumber: supplierReferenceNoController.text.trim(),
      partyName: supplier?.partyName ?? '',
      partyAddress: formatPartyAddress(
        preferredAddress,
        fallback: stringValue(supplierData, 'address_line1'),
      ),
      partyContact: resolvePartyContact(
        supplier,
        fallback: stringValue(supplierData, 'mobile_no'),
      ),
      partyGstin: resolvePreferredPartyGstin(
        supplierGstDetailsById[supplierPartyId] ??
            supplier?.gstDetails ??
            const <PartyGstDetailModel>[],
        sourceData: supplierData,
        fallback: stringValue(supplierData, 'gstin'),
      ),
      notes: notesController.text.trim(),
      termsConditions: termsController.text.trim(),
      subtotal: roundToDouble(summary.taxable, 2),
      taxAmount: roundToDouble(totalTax, 2),
      totalAmount: roundToDouble(summary.total, 2),
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
      prepare: () => ensureSupplierPrintContext(supplierPartyId),
      documentType: 'purchase_order',
      title: 'Purchase Order',
      documentDataBuilder: purchaseOrderPrintData,
    );
  }

  List<DocumentSeriesModel> seriesOptions() {
    return documentSeries
        .where((item) {
          final typeOk =
              item.documentType == null ||
              item.documentType == 'PURCHASE_ORDER';
          final companyOk = companyId == null || item.companyId == companyId;
          final fyOk =
              financialYearId == null ||
              item.financialYearId == financialYearId;
          return typeOk && companyOk && fyOk;
        })
        .toList(growable: false);
  }

  void addLine() {
    lines = List<PurchaseOrderLineDraft>.from(lines)
      ..add(PurchaseOrderLineDraft());
    update();
  }

  void removeLine(int index) {
    final updated = List<PurchaseOrderLineDraft>.from(lines);
    updated.removeAt(index);
    _replaceLines(updated);
  }

  ItemModel? itemById(int? itemId) {
    return itemsLookup.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == itemId,
      orElse: () => null,
    );
  }

  String itemDescription(ItemModel? item, {String? fallback}) {
    final itemName = item?.itemName.trim() ?? '';
    if (itemName.isNotEmpty) return itemName;
    final itemCode = item?.itemCode.trim() ?? '';
    if (itemCode.isNotEmpty) return itemCode;
    return fallback?.trim() ?? '';
  }

  Future<void> primeAllRequisitionDetails() async {
    final idsToLoad = requisitions
        .map((item) => intValue(item.toJson(), 'id'))
        .whereType<int>()
        .where((id) => !requisitionDetailCache.containsKey(id))
        .toList(growable: false);
    if (idsToLoad.isEmpty) return;
    final responses = await Future.wait<PurchaseRequisitionModel?>(
      idsToLoad.map(loadRequisitionDetail),
    );
    for (final doc in responses) {
      final id = intValue(doc?.toJson() ?? const <String, dynamic>{}, 'id');
      if (id != null && doc != null) requisitionDetailCache[id] = doc;
    }
  }

  Future<PurchaseRequisitionModel?> loadRequisitionDetail(int id) async {
    final cached = requisitionDetailCache[id];
    if (cached != null) return cached;
    final response = await _purchaseService.requisition(id);
    final doc = response.data;
    if (doc != null) requisitionDetailCache[id] = doc;
    return doc;
  }

  List<Map<String, dynamic>> requisitionLineMaps(
    PurchaseRequisitionModel? doc,
  ) {
    final data = doc?.toJson() ?? const <String, dynamic>{};
    return (data['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  Set<int> supplierItemIds(int supplierId) {
    return itemSupplierMaps
        .where((entry) => entry.isActive && entry.supplierId == supplierId)
        .map((entry) => entry.itemId)
        .whereType<int>()
        .toSet();
  }

  List<ItemSupplierMapModel> supplierMaps(int supplierId) {
    return itemSupplierMaps
        .where((entry) => entry.isActive && entry.supplierId == supplierId)
        .toList(growable: false);
  }

  Set<int> mappedPurchaseItemIds({int? supplierId}) {
    final mappedIds = itemSupplierMaps
        .where(
          (entry) =>
              entry.isActive &&
              (supplierId == null || entry.supplierId == supplierId),
        )
        .map((entry) => entry.itemId)
        .whereType<int>()
        .toSet();
    return mappedIds;
  }

  List<ItemModel> get purchasableItemOptions {
    final specificSupplierId = hasSpecificSupplierSelection
        ? supplierPartyId
        : null;
    final allowedIds = mappedPurchaseItemIds(supplierId: specificSupplierId);
    if (allowedIds.isEmpty) {
      return const <ItemModel>[];
    }
    return itemsLookup
        .where((item) => item.id != null && allowedIds.contains(item.id))
        .toList(growable: false);
  }

  void applyItemAndSupplierDefaults(
    PurchaseOrderLineDraft draft, {
    int? supplierId,
    String? fallbackDescription,
    String? fallbackRemarks,
  }) {
    final item = itemById(draft.itemId);
    draft.uomId = resolveDefaultUom(draft.itemId, draft.uomId);
    draft.taxCodeId = item?.taxCodeId;
    if (draft.descriptionController.text.trim().isEmpty) {
      draft.descriptionController.text = itemDescription(
        item,
        fallback: fallbackDescription,
      );
    }
    final currentRate = double.tryParse(draft.rateController.text.trim()) ?? 0;
    if (currentRate <= 0 && item?.standardCost != null) {
      draft.rateController.text = item!.standardCost!.toString();
    }
    if (draft.remarksController.text.trim().isEmpty &&
        (fallbackRemarks?.trim().isNotEmpty ?? false)) {
      draft.remarksController.text = fallbackRemarks!.trim();
    } else if (draft.remarksController.text.trim().isEmpty &&
        (item?.remarks?.trim().isNotEmpty ?? false)) {
      draft.remarksController.text = item!.remarks!.trim();
    }
    if (supplierId != null) {
      final supplierMap = supplierMaps(supplierId)
          .cast<ItemSupplierMapModel?>()
          .firstWhere(
            (entry) => entry?.itemId == draft.itemId,
            orElse: () => null,
          );
      if (supplierMap != null) {
        draft.uomId =
            supplierMap.purchaseUomId ??
            resolveDefaultUom(draft.itemId, draft.uomId);
        draft.rateController.text =
            supplierMap.supplierRate?.toString() ?? draft.rateController.text;
        draft.taxCodeId = item?.taxCodeId;
        if (draft.descriptionController.text.trim().isEmpty) {
          draft.descriptionController.text = itemDescription(
            item,
            fallback: supplierMap.supplierItemName ?? supplierMap.itemName,
          );
        }
        if (draft.remarksController.text.trim().isEmpty &&
            (supplierMap.remarks?.trim().isNotEmpty ?? false)) {
          draft.remarksController.text = supplierMap.remarks!.trim();
        }
      }
    }
  }

  bool isOpenDemandRequisition(PurchaseRequisitionModel? requisition) {
    final status = stringValue(
      requisition?.toJson() ?? const <String, dynamic>{},
      'requisition_status',
    );
    return status == 'approved' || status == 'partially_ordered';
  }

  bool isOpenDemandRequisitionLine(Map<String, dynamic> line) {
    final pendingQty = double.tryParse(stringValue(line, 'pending_qty')) ?? 0;
    final status = stringValue(line, 'line_status');
    if (pendingQty <= 0) return false;
    return status != 'cancelled' && status != 'fully_ordered';
  }

  List<Map<String, dynamic>> openDemandLinesForSupplier(int supplierId) {
    final allowedItemIds = supplierItemIds(supplierId);
    if (allowedItemIds.isEmpty) return const <Map<String, dynamic>>[];
    final demandLines = <Map<String, dynamic>>[];
    for (final requisition in requisitionDetailCache.values) {
      if (!isOpenDemandRequisition(requisition)) continue;
      final requisitionData = requisition.toJson();
      final requisitionId = intValue(requisitionData, 'id');
      final requisitionNo = stringValue(requisitionData, 'requisition_no');
      for (final line in requisitionLineMaps(requisition)) {
        final itemId = intValue(line, 'item_id');
        if (itemId == null || !allowedItemIds.contains(itemId)) continue;
        if (!isOpenDemandRequisitionLine(line)) continue;
        demandLines.add(<String, dynamic>{
          ...line,
          'requisition_id': requisitionId,
          if (requisitionNo.isNotEmpty) 'requisition_no': requisitionNo,
        });
      }
    }
    demandLines.sort((left, right) {
      final leftRequisitionId = intValue(left, 'requisition_id') ?? 0;
      final rightRequisitionId = intValue(right, 'requisition_id') ?? 0;
      if (leftRequisitionId != rightRequisitionId) {
        return leftRequisitionId.compareTo(rightRequisitionId);
      }
      final leftLineId = intValue(left, 'id') ?? 0;
      final rightLineId = intValue(right, 'id') ?? 0;
      return leftLineId.compareTo(rightLineId);
    });
    return demandLines;
  }

  List<PurchaseOrderLineDraft> linesFromSupplierDemand(int supplierId) {
    return openDemandLinesForSupplier(supplierId)
        .map((line) {
          final draft = PurchaseOrderLineDraft.fromRequisitionLine(line);
          draft.purchaseRequisitionLineId = null;
          applyItemAndSupplierDefaults(
            draft,
            supplierId: supplierId,
            fallbackDescription: stringValue(
              line,
              'requisition_no',
              stringValue(line, 'description'),
            ),
            fallbackRemarks: stringValue(line, 'remarks'),
          );
          return draft;
        })
        .where((line) => line.itemId != null)
        .toList(growable: false);
  }

  List<PurchaseOrderLineDraft> linesFromSupplierMaps(int supplierId) {
    return supplierMaps(supplierId)
        .map((map) {
          final draft = PurchaseOrderLineDraft(
            itemId: map.itemId,
            warehouseId: null,
            uomId: map.purchaseUomId,
            description: map.supplierItemName ?? map.itemName,
            qty: '',
            rate: map.supplierRate?.toString() ?? '',
            remarks: map.remarks,
          );
          applyItemAndSupplierDefaults(
            draft,
            supplierId: supplierId,
            fallbackDescription: map.supplierItemName ?? map.itemName,
            fallbackRemarks: map.remarks,
          );
          return draft;
        })
        .where((line) => line.itemId != null)
        .toList(growable: false);
  }

  List<PurchaseOrderLineDraft> linesFromAllSupplierMaps() {
    return itemSupplierMaps
        .where((map) => map.isActive)
        .map((map) {
          final draft = PurchaseOrderLineDraft(
            itemId: map.itemId,
            warehouseId: null,
            uomId: map.purchaseUomId,
            description: map.supplierItemName ?? map.itemName,
            qty: '',
            rate: map.supplierRate?.toString() ?? '',
            remarks: map.remarks,
          );
          applyItemAndSupplierDefaults(
            draft,
            supplierId: map.supplierId,
            fallbackDescription: map.supplierItemName ?? map.itemName,
            fallbackRemarks: map.remarks,
          );
          return draft;
        })
        .where((line) => line.itemId != null)
        .toList(growable: false);
  }

  ({List<PurchaseOrderLineDraft> lines, int excluded}) linesFromRequisition(
    PurchaseRequisitionModel requisition, {
    int? supplierId,
  }) {
    final lineMaps = requisitionLineMaps(requisition);
    final allowedItemIds = supplierId != null
        ? supplierItemIds(supplierId)
        : null;
    final filtered = allowedItemIds == null
        ? lineMaps
        : lineMaps
              .where(
                (line) => allowedItemIds.contains(intValue(line, 'item_id')),
              )
              .toList(growable: false);
    final nextLines = filtered
        .map((line) {
          final draft = PurchaseOrderLineDraft.fromRequisitionLine(line);
          applyItemAndSupplierDefaults(
            draft,
            supplierId: supplierId,
            fallbackDescription: stringValue(line, 'description'),
            fallbackRemarks: stringValue(line, 'remarks'),
          );
          return draft;
        })
        .where((line) => line.itemId != null)
        .toList(growable: false);
    return (lines: nextLines, excluded: lineMaps.length - filtered.length);
  }

  List<PurchaseOrderLineDraft> linesFromAllRequisitions({int? supplierId}) {
    final sorted = requisitionDetailCache.values.toList(growable: false)
      ..sort((left, right) {
        final leftId = intValue(left.toJson(), 'id') ?? 0;
        final rightId = intValue(right.toJson(), 'id') ?? 0;
        return leftId.compareTo(rightId);
      });
    return sorted
        .expand(
          (requisition) =>
              linesFromRequisition(requisition, supplierId: supplierId).lines,
        )
        .toList(growable: false);
  }

  Future<void> primeRequisitionDetailsForSupplier(int supplierId) async {
    final itemIds = supplierItemIds(supplierId);
    if (itemIds.isEmpty) return;
    final idsToLoad = requisitions
        .map((item) => intValue(item.toJson(), 'id'))
        .whereType<int>()
        .where((id) => !requisitionDetailCache.containsKey(id))
        .toList(growable: false);
    if (idsToLoad.isEmpty) return;
    final responses = await Future.wait<PurchaseRequisitionModel?>(
      idsToLoad.map(loadRequisitionDetail),
    );
    for (final doc in responses) {
      final id = intValue(doc?.toJson() ?? const <String, dynamic>{}, 'id');
      if (id != null && doc != null) requisitionDetailCache[id] = doc;
    }
  }

  List<PartyModel> get filteredSupplierOptions {
    if (linkDriver != PurchaseOrderLinkDriver.requisition ||
        !hasSpecificRequisitionSelection) {
      return suppliers;
    }
    final requisition = requisitionDetailCache[purchaseRequisitionId!];
    if (requisition == null) return suppliers;
    final itemIds = requisitionLineMaps(
      requisition,
    ).map((line) => intValue(line, 'item_id')).whereType<int>().toSet();
    if (itemIds.isEmpty) return suppliers;
    final allowedSupplierIds = itemSupplierMaps
        .where((entry) => entry.isActive && itemIds.contains(entry.itemId))
        .map((entry) => entry.supplierId)
        .whereType<int>()
        .toSet();
    return suppliers
        .where(
          (entry) => entry.id != null && allowedSupplierIds.contains(entry.id),
        )
        .toList(growable: false);
  }

  List<PurchaseRequisitionModel> get filteredRequisitionOptions {
    final openRequisitions = requisitions
        .where((req) {
          final id = intValue(req.toJson(), 'id');
          final detail = id != null ? requisitionDetailCache[id] : null;
          if (detail != null) {
            return isOpenDemandRequisition(detail);
          }
          return isOpenDemandRequisition(req);
        })
        .toList(growable: false);

    if (linkDriver != PurchaseOrderLinkDriver.supplier ||
        !hasSpecificSupplierSelection) {
      return openRequisitions;
    }

    final allowedItemIds = supplierItemIds(supplierPartyId!);
    if (allowedItemIds.isEmpty) return const <PurchaseRequisitionModel>[];
    return openRequisitions
        .where((req) {
          final id = intValue(req.toJson(), 'id');
          final detail = id != null ? requisitionDetailCache[id] : null;
          if (detail == null) return true;
          return requisitionLineMaps(detail).any((line) {
            final itemId = intValue(line, 'item_id');
            return itemId != null &&
                allowedItemIds.contains(itemId) &&
                isOpenDemandRequisitionLine(line);
          });
        })
        .toList(growable: false);
  }

  Future<void> handleRequisitionChanged(int? requisitionId) async {
    if (requisitionId == null) {
      purchaseRequisitionId = null;
      selectionInfo = null;
      if (supplierPartyId == null) {
        linkDriver = PurchaseOrderLinkDriver.none;
      } else if (linkDriver == PurchaseOrderLinkDriver.requisition) {
        linkDriver = PurchaseOrderLinkDriver.none;
      }
      update();
      return;
    }

    if (linkDriver == PurchaseOrderLinkDriver.none && supplierPartyId == null) {
      linkDriver = PurchaseOrderLinkDriver.requisition;
    }
    purchaseRequisitionId = requisitionId;
    formError = null;
    selectionInfo = null;
    update();

    try {
      if (requisitionId == allSelectionId) {
        await primeAllRequisitionDetails();
        final currentSupplierId = hasSpecificSupplierSelection
            ? supplierPartyId
            : null;
        final mappedLines = linesFromAllRequisitions(
          supplierId: currentSupplierId,
        );
        _replaceLines(mappedLines, notify: false);
        formError = mappedLines.isEmpty
            ? 'No requisition lines found to copy.'
            : null;
        selectionInfo = mappedLines.isEmpty
            ? null
            : 'Loaded lines from all requisitions.';
        update();
        return;
      }

      final requisition = await loadRequisitionDetail(requisitionId);
      final data = requisition?.toJson() ?? const <String, dynamic>{};
      if (requisition == null) {
        formError = 'Selected requisition could not be loaded.';
        update();
        return;
      }
      final result = linesFromRequisition(
        requisition,
        supplierId: hasSpecificSupplierSelection ? supplierPartyId : null,
      );
      final mappedLines = result.lines;
      if (linkDriver == PurchaseOrderLinkDriver.requisition &&
          hasSpecificSupplierSelection &&
          !filteredSupplierOptions.any((item) => item.id == supplierPartyId)) {
        supplierPartyId = null;
      }
      if (mappedLines.isEmpty) {
        formError = !hasSpecificSupplierSelection
            ? 'Selected requisition has no lines to copy.'
            : 'No common items found between selected requisition and supplier.';
        _replaceLines(const <PurchaseOrderLineDraft>[], notify: false);
        update();
        return;
      }
      companyId = intValue(data, 'company_id') ?? companyId;
      branchId = intValue(data, 'branch_id') ?? branchId;
      locationId = intValue(data, 'location_id') ?? locationId;
      financialYearId = intValue(data, 'financial_year_id') ?? financialYearId;
      _replaceLines(mappedLines, notify: false);
      selectionInfo = result.excluded > 0
          ? '${result.excluded} requisition item(s) excluded because they are not mapped to the selected supplier.'
          : null;
      final options = seriesOptions();
      if (options.isNotEmpty &&
          !options.any((item) => item.id == documentSeriesId)) {
        documentSeriesId = options.first.id;
      }
      update();
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
    }
  }

  Future<void> handleSupplierChanged(int? supplierId) async {
    if (supplierId == null) {
      supplierPartyId = null;
      selectionInfo = null;
      if (purchaseRequisitionId == null) {
        linkDriver = PurchaseOrderLinkDriver.none;
      } else if (linkDriver == PurchaseOrderLinkDriver.supplier) {
        linkDriver = PurchaseOrderLinkDriver.none;
      }
      update();
      return;
    }

    if (linkDriver == PurchaseOrderLinkDriver.none &&
        purchaseRequisitionId == null) {
      linkDriver = PurchaseOrderLinkDriver.supplier;
    }
    supplierPartyId = supplierId;
    formError = null;
    selectionInfo = null;
    update();

    try {
      if (supplierId == allSelectionId) {
        await primeAllRequisitionDetails();
      } else {
        await primeRequisitionDetailsForSupplier(supplierId);
      }

      if (linkDriver == PurchaseOrderLinkDriver.supplier &&
          hasSpecificRequisitionSelection &&
          !filteredRequisitionOptions.any(
            (req) => intValue(req.toJson(), 'id') == purchaseRequisitionId,
          )) {
        purchaseRequisitionId = null;
      }

      final supplierDemandLines = !hasSpecificRequisitionSelection
          ? (isAllSupplierSelected
                ? linesFromAllRequisitions()
                : linesFromSupplierDemand(supplierId))
          : const <PurchaseOrderLineDraft>[];
      final mappedLines = hasSpecificRequisitionSelection
          ? linesFromRequisition(
              requisitionDetailCache[purchaseRequisitionId!]!,
              supplierId: hasSpecificSupplierSelection ? supplierId : null,
            ).lines
          : (supplierDemandLines.isNotEmpty
                ? supplierDemandLines
                : (isAllSupplierSelected
                      ? linesFromAllSupplierMaps()
                      : linesFromSupplierMaps(supplierId)));

      if (mappedLines.isEmpty) {
        formError = !hasSpecificRequisitionSelection
            ? 'No supplier item mappings found for selected supplier.'
            : 'No common items found between selected supplier and requisition.';
        _replaceLines(const <PurchaseOrderLineDraft>[], notify: false);
        update();
        return;
      }

      _replaceLines(mappedLines, notify: false);
      if (hasSpecificRequisitionSelection) {
        final result = linesFromRequisition(
          requisitionDetailCache[purchaseRequisitionId!]!,
          supplierId: hasSpecificSupplierSelection ? supplierId : null,
        );
        selectionInfo = result.excluded > 0
            ? '${result.excluded} requisition item(s) excluded because they are not mapped to the selected supplier.'
            : null;
      } else {
        selectionInfo = isAllSupplierSelected
            ? 'Loaded lines for all suppliers.'
            : supplierDemandLines.isNotEmpty
            ? 'Loaded open requisition demand for the selected supplier. Select a requisition to keep direct line linkage.'
            : 'No open requisition demand found for this supplier, so item defaults were loaded from supplier mapping.';
      }
      update();
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
    }
  }

  void setFinancialYearId(int? value) {
    financialYearId = value;
    final options = seriesOptions();
    documentSeriesId = options.isNotEmpty ? options.first.id : null;
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

  void setLineItemId(PurchaseOrderLineDraft line, int? value) {
    line.itemId = value;
    line.warehouseId ??= warehouses.isNotEmpty ? warehouses.first.id : null;
    applyItemAndSupplierDefaults(
      line,
      supplierId: hasSpecificSupplierSelection ? supplierPartyId : null,
    );
    update();
  }

  void setLineUomId(PurchaseOrderLineDraft line, int? value) {
    line.uomId = value;
    update();
  }

  void setLineWarehouseId(PurchaseOrderLineDraft line, int? value) {
    line.warehouseId = value;
    update();
  }

  void setLineTaxCodeId(PurchaseOrderLineDraft line, int? value) {
    line.taxCodeId = value;
    update();
  }

  Future<void> save(BuildContext context) async {
    if (!canEditSelectedOrder) {
      formError = 'Only draft purchase orders can be updated.';
      update();
      return;
    }
    if (isAllSupplierSelected) {
      formError =
          'Select a specific supplier before saving the purchase order.';
      update();
      return;
    }
    if (!formKey.currentState!.validate()) return;
    if (lines.any(
      (line) =>
          line.itemId == null ||
          line.uomId == null ||
          (double.tryParse(line.qtyController.text.trim()) ?? 0) <= 0,
    )) {
      formError = 'Each line needs item, UOM, and ordered quantity.';
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
      'purchase_requisition_id': isAllRequisitionSelected
          ? null
          : purchaseRequisitionId,
      'order_no': nullIfEmpty(orderNoController.text),
      'order_date': orderDateController.text.trim(),
      'expected_receipt_date': nullIfEmpty(expectedReceiptDateController.text),
      'supplier_party_id': supplierPartyId,
      'supplier_reference_no': nullIfEmpty(supplierReferenceNoController.text),
      'supplier_reference_date': nullIfEmpty(
        supplierReferenceDateController.text,
      ),
      'currency_code': nullIfEmpty(currencyCodeController.text) ?? 'INR',
      'exchange_rate': double.tryParse(exchangeRateController.text.trim()) ?? 1,
      'notes': nullIfEmpty(notesController.text),
      'terms_conditions': nullIfEmpty(termsController.text),
      'is_active': isActive,
      'lines': lines.map((line) => line.toJson()).toList(growable: false),
    };
    try {
      final response = selectedItem == null
          ? await _purchaseService.createOrder(
              PurchaseOrderModel.fromJson(payload),
            )
          : await _purchaseService.updateOrder(
              intValue(selectedItem!.toJson(), 'id')!,
              PurchaseOrderModel.fromJson(payload),
            );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
      final saved = response.data;
      if (saved != null) {
        _upsertOrder(saved);
        await selectDocument(saved, notify: false);
        reloadPurchaseOrderRegister();
        update();
      } else {
        await loadPage(
          selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
        );
        reloadPurchaseOrderRegister();
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
    Future<ApiResponse<PurchaseOrderModel>> Function() action,
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
        _upsertOrder(updated);
        await selectDocument(updated, notify: false);
        reloadPurchaseOrderRegister();
        update();
      } else {
        await loadPage(
          selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
        );
        reloadPurchaseOrderRegister();
      }
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
    }
  }

  void _upsertOrder(PurchaseOrderModel order, {bool notify = true}) {
    final id = intValue(order.toJson(), 'id');
    if (id == null) {
      return;
    }
    final nextItems = List<PurchaseOrderModel>.from(items);
    final existingIndex = nextItems.indexWhere(
      (item) => intValue(item.toJson(), 'id') == id,
    );
    if (existingIndex >= 0) {
      nextItems[existingIndex] = order;
    } else {
      nextItems.insert(0, order);
    }
    items = nextItems;
    if (notify) {
      _applyFilters();
    } else {
      filteredItems = _filterItems(items, searchController.text, statusFilter);
    }
  }

  void _replaceLines(
    List<PurchaseOrderLineDraft> nextLines, {
    bool notify = true,
  }) {
    replaceDisposableDraftEntries<PurchaseOrderLineDraft>(
      previous: lines,
      next: nextLines,
      createEmpty: () => PurchaseOrderLineDraft(),
      assign: (entries) => lines = entries,
      dispose: (entry) => entry.dispose(),
      notify: notify ? update : null,
    );
  }

  void _disposeLines(List<PurchaseOrderLineDraft> entries) {
    for (final line in entries) {
      line.dispose();
    }
  }
}
