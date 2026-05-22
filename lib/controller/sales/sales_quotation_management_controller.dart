import '../../screen.dart';

class QuotationLineDraft {
  QuotationLineDraft({
    this.id,
    this.itemId,
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

  factory QuotationLineDraft.fromJson(Map<String, dynamic> json) {
    return QuotationLineDraft(
      id: intValue(json, 'id'),
      itemId: intValue(json, 'item_id'),
      uomId: intValue(json, 'uom_id'),
      taxCodeId: intValue(json, 'tax_code_id'),
      description: stringValue(json, 'description'),
      qty: stringValue(json, 'qty'),
      rate: stringValue(json, 'rate'),
      discountPercent: stringValue(json, 'discount_percent'),
      remarks: stringValue(json, 'remarks'),
    );
  }

  int? id;
  int? itemId;
  int? uomId;
  int? taxCodeId;
  final TextEditingController descriptionController;
  final TextEditingController qtyController;
  final TextEditingController rateController;
  final TextEditingController discountController;
  final TextEditingController remarksController;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'item_id': itemId,
      'uom_id': uomId,
      'tax_code_id': taxCodeId,
      'description': nullIfEmpty(descriptionController.text),
      'qty': double.tryParse(qtyController.text.trim()) ?? 0,
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

class SalesQuotationManagementController extends GetxController {
  SalesQuotationManagementController();

  static const List<AppDropdownItem<String>> listStatusFilter =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All'),
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'posted', label: 'Posted'),
        AppDropdownItem(value: 'sent', label: 'Sent'),
        AppDropdownItem(value: 'accepted', label: 'Accepted'),
        AppDropdownItem(value: 'rejected', label: 'Rejected'),
        AppDropdownItem(value: 'expired', label: 'Expired'),
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
  final TextEditingController quotationNoController = TextEditingController();
  final TextEditingController quotationDateController = TextEditingController();
  final TextEditingController validUntilController = TextEditingController();
  final TextEditingController customerRefNoController = TextEditingController();
  final TextEditingController customerRefDateController =
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
  List<SalesQuotationModel> items = const <SalesQuotationModel>[];
  List<SalesQuotationModel> filteredItems = const <SalesQuotationModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<FinancialYearModel> financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<PartyModel> customers = const <PartyModel>[];
  List<ItemModel> itemsLookup = const <ItemModel>[];
  List<UomModel> uoms = const <UomModel>[];
  List<UomConversionModel> uomConversions = const <UomConversionModel>[];
  List<TaxCodeModel> taxCodes = const <TaxCodeModel>[];
  SalesQuotationModel? selectedItem;
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
  bool isActive = true;
  int? crmOpportunityId;
  Map<String, dynamic>? salesChain;
  List<QuotationLineDraft> lines = <QuotationLineDraft>[];

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
    quotationNoController.dispose();
    quotationDateController.dispose();
    validUntilController.dispose();
    customerRefNoController.dispose();
    customerRefDateController.dispose();
    currencyCodeController.dispose();
    exchangeRateController.dispose();
    notesController.dispose();
    termsController.dispose();
    _disposeLines(lines);
    super.onClose();
  }

  Future<void> initialize({
    int? initialId,
    int? initialCrmOpportunityId,
    bool editorOnly = false,
  }) async {
    if (!_initialized) {
      _initialized = true;
    }
    await loadPage(
      selectId: initialId,
      initialCrmOpportunityId: initialCrmOpportunityId,
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
    return stringValue(selectedItem!.toJson(), 'quotation_status') == 'draft';
  }

  String get status => stringValue(
    selectedItem?.toJson() ?? const {},
    'quotation_status',
    'draft',
  );

  Future<void> _handleWorkingContextChanged() async {
    await loadPage(
      selectId: intValue(selectedItem?.toJson() ?? const {}, 'id'),
    );
  }

  List<DocumentSeriesModel> seriesOptions() {
    return documentSeries
        .where((item) {
          final typeOk =
              item.documentType == null ||
              item.documentType == 'SALES_QUOTATION';
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
    int? initialCrmOpportunityId,
    bool editorOnly = false,
  }) async {
    initialLoading = items.isEmpty;
    pageError = null;
    update();
    try {
      final responses = await Future.wait<dynamic>([
        _salesService.quotations(
          filters: const {'per_page': 200, 'sort_by': 'quotation_date'},
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
          (responses[0] as PaginatedResponse<SalesQuotationModel>).data ??
          const <SalesQuotationModel>[];
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
      taxCodes =
          ((responses[11] as PaginatedResponse<TaxCodeModel>).data ??
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
          ? items.cast<SalesQuotationModel?>().firstWhere(
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
        if (initialCrmOpportunityId != null) {
          await applyOpportunityBootstrap(initialCrmOpportunityId);
        }
      }
      update();
    } catch (error) {
      pageError = errorMessage(error);
      initialLoading = false;
      update();
    }
  }

  Future<void> selectDocument(
    SalesQuotationModel item, {
    bool notify = true,
  }) async {
    final id = intValue(item.toJson(), 'id');
    if (id == null) {
      return;
    }
    final response = await _salesService.quotation(id);
    final full = response.data ?? item;
    final data = full.toJson();
    final nextLines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(QuotationLineDraft.fromJson)
        .toList(growable: true);
    _disposeLines(lines);
    selectedItem = full;
    companyId = intValue(data, 'company_id');
    branchId = intValue(data, 'branch_id');
    locationId = intValue(data, 'location_id');
    financialYearId = intValue(data, 'financial_year_id');
    documentSeriesId = intValue(data, 'document_series_id');
    customerPartyId = intValue(data, 'customer_party_id');
    quotationNoController.text = stringValue(data, 'quotation_no');
    quotationDateController.text = displayDate(
      nullableStringValue(data, 'quotation_date'),
    );
    validUntilController.text = displayDate(
      nullableStringValue(data, 'valid_until'),
    );
    customerRefNoController.text = stringValue(data, 'customer_reference_no');
    customerRefDateController.text = displayDate(
      nullableStringValue(data, 'customer_reference_date'),
    );
    currencyCodeController.text = stringValue(data, 'currency_code', 'INR');
    exchangeRateController.text = stringValue(data, 'exchange_rate', '1');
    notesController.text = stringValue(data, 'notes');
    termsController.text = stringValue(data, 'terms_conditions');
    isActive = boolValue(data, 'is_active', fallback: true);
    crmOpportunityId = intValue(data, 'crm_opportunity_id');
    lines = nextLines.isEmpty
        ? <QuotationLineDraft>[QuotationLineDraft()]
        : nextLines;
    formError = null;
    await refreshSalesChain(notify: false);
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
    quotationNoController.clear();
    quotationDateController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    validUntilController.clear();
    customerRefNoController.clear();
    customerRefDateController.clear();
    currencyCodeController.text = 'INR';
    exchangeRateController.text = '1';
    notesController.clear();
    termsController.clear();
    isActive = true;
    lines = <QuotationLineDraft>[QuotationLineDraft()];
    formError = null;
    crmOpportunityId = null;
    salesChain = null;
    if (notify) {
      update();
    }
  }

  Future<void> refreshSalesChain({bool notify = true}) async {
    final savedId = intValue(selectedItem?.toJson() ?? const {}, 'id');
    try {
      if (savedId != null) {
        final response = await _crmService.salesChain(quotationId: savedId);
        salesChain = response.data;
      } else if (crmOpportunityId != null) {
        final response = await _crmService.salesChain(
          opportunityId: crmOpportunityId,
        );
        salesChain = response.data;
      } else {
        salesChain = null;
      }
    } catch (_) {
      salesChain = null;
    }
    if (notify) {
      update();
    }
  }

  Future<void> applyOpportunityBootstrap(int opportunityId) async {
    try {
      final response = await _crmService.opportunity(opportunityId);
      if (response.data == null) {
        return;
      }
      final opportunityData = response.data!.toJson();
      final enquiry = opportunityData['enquiry'];
      if (enquiry is! Map) {
        return;
      }
      final enquiryData = Map<String, dynamic>.from(enquiry);
      final nextCompanyId = intValue(enquiryData, 'company_id');
      final partyId = intValue(enquiryData, 'customer_party_id');
      crmOpportunityId = opportunityId;
      if (nextCompanyId != null) {
        companyId = nextCompanyId;
      }
      if (partyId != null) {
        customerPartyId = partyId;
      }
      final note =
          'Linked CRM opportunity: ${stringValue(opportunityData, 'opportunity_name')}'
              .trim();
      if (note.isNotEmpty && notesController.text.trim().isEmpty) {
        notesController.text = note;
      }
      await refreshSalesChain(notify: false);
      update();
    } catch (_) {
      // optional bootstrap
    }
  }

  void _applyFilters({bool notify = true}) {
    final search = searchController.text.trim().toLowerCase();
    filteredItems = items
        .where((item) {
          final data = item.toJson();
          final statusOk =
              statusFilter.isEmpty ||
              stringValue(data, 'quotation_status') == statusFilter;
          final customerLabel = quotationCustomerLabel(data);
          final searchOk =
              search.isEmpty ||
              [
                stringValue(data, 'quotation_no'),
                stringValue(data, 'quotation_status'),
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

  SalesLineTaxBreakdown taxBreakdownForLine(QuotationLineDraft line) {
    return computeSalesLineTaxBreakdown(
      qty: double.tryParse(line.qtyController.text.trim()) ?? 0,
      rate: double.tryParse(line.rateController.text.trim()) ?? 0,
      discountPercent:
          double.tryParse(line.discountController.text.trim()) ?? 0,
      taxCode: salesTaxCodeById(taxCodes, line.taxCodeId),
    );
  }

  SalesDocumentTaxSummary taxSummary() {
    return summarizeSalesLineTaxes(lines.map(taxBreakdownForLine));
  }

  Map<String, dynamic> linePayload(QuotationLineDraft line) {
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

  DocumentPrintDataModel quotationPrintData() {
    final summary = taxSummary();
    final selected = selectedItem?.toJson() ?? const <String, dynamic>{};
    final company = companies.cast<CompanyModel?>().firstWhere(
      (item) => item?.id == companyId,
      orElse: () => null,
    );
    final customer = customers.cast<PartyModel?>().firstWhere(
      (item) => item?.id == customerPartyId,
      orElse: () => null,
    );
    final customerData = selected['customer'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(
            selected['customer'] as Map<String, dynamic>,
          )
        : customer?.toJson() ?? const <String, dynamic>{};
    final gstBreakupGroups = <String, dynamic>{};
    final printLines = lines
        .where((line) => line.itemId != null && line.itemId! > 0)
        .map((line) {
          final item = itemsLookup.cast<ItemModel?>().firstWhere(
            (entry) => entry?.id == line.itemId,
            orElse: () => null,
          );
          final breakdown = taxBreakdownForLine(line);
          accumulatePrintTemplateGstBreakup(
            gstBreakupGroups,
            taxCode: salesTaxCodeById(taxCodes, line.taxCodeId),
            taxPercent: breakdown.taxPercent,
            taxable: breakdown.taxable,
            cgst: breakdown.cgst,
            sgst: breakdown.sgst,
            igst: breakdown.igst,
            cess: breakdown.cess,
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

    return DocumentPrintDataModel(
      companyName: companyNameById(companies, companyId),
      companyLogoUrl: AppConfig.resolvePublicFileUrl(company?.logoPath) ?? '',
      companyGstin: company?.gstin ?? '',
      documentNumber: nullIfEmpty(quotationNoController.text) ?? 'Draft',
      documentDate: quotationDateController.text.trim(),
      referenceNumber: customerRefNoController.text.trim(),
      partyName: stringValue(customerData, 'party_name').isNotEmpty
          ? stringValue(customerData, 'party_name')
          : quotationCustomerLabel(selected),
      partyAddress: stringValue(customerData, 'address_line1'),
      partyContact: stringValue(customerData, 'mobile_no'),
      partyGstin: stringValue(customerData, 'gstin'),
      notes: notesController.text.trim(),
      termsConditions: termsController.text.trim(),
      subtotal: roundToDouble(summary.taxable, 2),
      taxAmount: roundToDouble(totalTax, 2),
      totalAmount: roundToDouble(summary.total, 2),
      amountInWords: printTemplateAmountInWords(
        roundToDouble(summary.total, 2),
        currencyCodeController.text.trim().isEmpty
            ? 'INR'
            : currencyCodeController.text.trim(),
      ),
      lines: printLines,
      gstBreakup: finalizePrintTemplateGstBreakup(gstBreakupGroups),
    );
  }

  void addLine() {
    lines = List<QuotationLineDraft>.from(lines)..add(QuotationLineDraft());
    update();
  }

  void removeLine(int index) {
    final next = List<QuotationLineDraft>.from(lines);
    next.removeAt(index).dispose();
    lines = next.isEmpty ? <QuotationLineDraft>[QuotationLineDraft()] : next;
    update();
  }

  void setFinancialYearId(int? value) {
    if (!canEdit) {
      return;
    }
    financialYearId = value;
    final options = seriesOptions();
    documentSeriesId = options.isNotEmpty ? options.first.id : null;
    update();
  }

  void setDocumentSeriesId(int? value) {
    if (!canEdit) {
      return;
    }
    documentSeriesId = value;
    update();
  }

  void setCustomerPartyId(int? value) {
    if (!canEdit) {
      return;
    }
    customerPartyId = value;
    update();
  }

  void setIsActive(bool value) {
    if (!canEdit) {
      return;
    }
    isActive = value;
    update();
  }

  void refreshComputedState() {
    update();
  }

  void setLineItemId(int index, int? value) {
    if (!canEdit) {
      return;
    }
    final line = lines[index];
    line.itemId = value;
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
    );
    update();
  }

  void setLineUomId(int index, int? value) {
    if (!canEdit) {
      return;
    }
    lines[index].uomId = value;
    update();
  }

  void setLineTaxCodeId(int index, int? value) {
    if (!canEdit) {
      return;
    }
    lines[index].taxCodeId = value;
    update();
  }

  Future<void> save(BuildContext context) async {
    if (!canEdit) {
      formError = 'Only draft quotations can be updated.';
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
      'quotation_no': nullIfEmpty(quotationNoController.text),
      'quotation_date': quotationDateController.text.trim(),
      'valid_until': nullIfEmpty(validUntilController.text),
      'customer_party_id': customerPartyId,
      'customer_reference_no': nullIfEmpty(customerRefNoController.text),
      'customer_reference_date': nullIfEmpty(customerRefDateController.text),
      'currency_code': nullIfEmpty(currencyCodeController.text) ?? 'INR',
      'exchange_rate': double.tryParse(exchangeRateController.text.trim()) ?? 1,
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
    if (crmOpportunityId != null) {
      payload['crm_opportunity_id'] = crmOpportunityId;
    }
    try {
      final response = selectedItem == null
          ? await _salesService.createQuotation(
              SalesQuotationModel.fromJson(payload),
            )
          : await _salesService.updateQuotation(
              intValue(selectedItem!.toJson(), 'id')!,
              SalesQuotationModel.fromJson(payload),
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
    Future<ApiResponse<SalesQuotationModel>> Function() action,
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
    if (id == null) {
      return;
    }
    try {
      final response = await _salesService.deleteQuotation(id);
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

  Future<void> postSelected(BuildContext context) async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) return;
    await docAction(
      context,
      () => _salesService.postQuotation(
        id,
        SalesQuotationModel.fromJson(const <String, dynamic>{}),
      ),
    );
  }

  Future<void> sendSelected(BuildContext context) async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) return;
    await docAction(
      context,
      () => _salesService.sendQuotation(
        id,
        SalesQuotationModel.fromJson(const <String, dynamic>{}),
      ),
    );
  }

  Future<void> acceptSelected(BuildContext context) async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) return;
    await docAction(
      context,
      () => _salesService.acceptQuotation(
        id,
        SalesQuotationModel.fromJson(const <String, dynamic>{}),
      ),
    );
  }

  Future<void> rejectSelected(BuildContext context) async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) return;
    await docAction(
      context,
      () => _salesService.rejectQuotation(
        id,
        SalesQuotationModel.fromJson(const <String, dynamic>{}),
      ),
    );
  }

  Future<void> expireSelected(BuildContext context) async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) return;
    await docAction(
      context,
      () => _salesService.expireQuotation(
        id,
        SalesQuotationModel.fromJson(const <String, dynamic>{}),
      ),
    );
  }

  Future<void> cancelSelected(BuildContext context) async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) return;
    await docAction(
      context,
      () => _salesService.cancelQuotation(
        id,
        SalesQuotationModel.fromJson(const <String, dynamic>{}),
      ),
    );
  }

  void _disposeLines(List<QuotationLineDraft> values) {
    for (final line in values) {
      line.dispose();
    }
  }
}
