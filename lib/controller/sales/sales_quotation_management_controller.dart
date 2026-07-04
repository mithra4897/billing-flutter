import '../../screen.dart';
import 'sales_module_refresh_controller.dart';

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
  bool _disposed = false;

  Map<String, dynamic> toJson() {
    final rate = Validators.parseFlexibleNumber(rateController.text);
    final discountPercent = Validators.parseFlexibleNumber(
      discountController.text,
    );
    return <String, dynamic>{
      if (id != null) 'id': id,
      'item_id': itemId,
      'uom_id': uomId,
      'tax_code_id': taxCodeId,
      'description': nullIfEmpty(descriptionController.text),
      'qty': Validators.parseFlexibleNumber(qtyController.text) ?? 0,
      'rate': rate,
      'discount_percent': discountPercent,
      'remarks': nullIfEmpty(remarksController.text),
    };
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    descriptionController.dispose();
    qtyController.dispose();
    rateController.dispose();
    discountController.dispose();
    remarksController.dispose();
  }
}

class SalesQuotationManagementController extends GetxController {
  SalesQuotationManagementController();

  static const String lineItemsSectionId = 'quotation_line_items';
  static final RegExp _revisionHeaderPattern = RegExp(
    r'^Revised Quote (\d+) for quotation (.+?)(?: dated .*)?$',
    multiLine: true,
  );

  static const List<AppDropdownItem<String>> listStatusFilter =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All'),
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'posted', label: 'Finished'),
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
  final TaxesService _taxesService = TaxesService();
  final SalesModuleRefreshController _refreshController =
      SalesModuleRefreshController.ensureRegistered();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController dateFromController = TextEditingController();
  final TextEditingController dateToController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController quotationNoController = TextEditingController();
  final TextEditingController quotationDateController = TextEditingController();
  final TextEditingController validUntilController = TextEditingController();
  final TextEditingController customerRefNoController = TextEditingController();
  final TextEditingController customerRefDateController =
      TextEditingController();
  final TextEditingController roundOffController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController termsController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  String statusFilter = '';
  String dashboardFilter = '';
  List<SalesQuotationModel> items = const <SalesQuotationModel>[];
  List<SalesQuotationModel> filteredItems = const <SalesQuotationModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<BusinessLocationModel> locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<PartyModel> customers = const <PartyModel>[];
  final Map<int, PartyModel> customerDetailsById = <int, PartyModel>{};
  final Map<int, List<PartyGstDetailModel>> customerGstDetailsById =
      <int, List<PartyGstDetailModel>>{};
  List<GstRegistrationModel> gstRegistrations = const <GstRegistrationModel>[];
  List<ItemModel> itemsLookup = const <ItemModel>[];
  final Map<int, ItemModel> itemLookupById = <int, ItemModel>{};
  List<ItemPriceModel> itemPrices = const <ItemPriceModel>[];
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
  bool applyRoundOff = true;
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
    dateFromController.dispose();
    dateToController.dispose();
    searchController
      ..removeListener(_applyFilters)
      ..dispose();
    quotationNoController.dispose();
    quotationDateController.dispose();
    validUntilController.dispose();
    customerRefNoController.dispose();
    customerRefDateController.dispose();
    roundOffController.dispose();
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

  bool get mounted => !isClosed;

  List<AppDropdownItem<int>> get financialYearDropdownItems => financialYears
      .where((item) => item.id != null)
      .map((item) => AppDropdownItem(value: item.id!, label: item.toString()))
      .toList(growable: false);

  List<AppDropdownItem<int>> get documentSeriesDropdownItems => seriesOptions()
      .where((item) => item.id != null)
      .map((item) => AppDropdownItem(value: item.id!, label: item.toString()))
      .toList(growable: false);

  List<AppDropdownItem<int>> get customerDropdownItems => customers
      .where((item) => item.id != null)
      .map((item) => AppDropdownItem(value: item.id!, label: item.toString()))
      .toList(growable: false);

  List<AppSearchPickerOption<int>> get itemPickerOptions => itemsLookup
      .where((item) => item.id != null)
      .map(
        (item) => AppSearchPickerOption<int>(
          value: item.id!,
          label: item.toString(),
          subtitle: item.itemCode,
          searchText: item.pickerSearchText,
        ),
      )
      .toList(growable: false);

  List<AppDropdownItem<int>> get taxCodeDropdownItems => taxCodes
      .where((item) => item.id != null)
      .map((item) => AppDropdownItem(value: item.id!, label: item.toString()))
      .toList(growable: false);

  ItemModel? itemById(int? itemId) =>
      itemId == null ? null : itemLookupById[itemId];

  String? itemLabelById(int? itemId) => itemById(itemId)?.toString();

  void refreshLineItemsSection() => update(<Object>[lineItemsSectionId]);

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
        _inventoryService.itemPrices(
          filters: const {
            'per_page': 1000,
            'sort_by': 'valid_from',
            'sort_order': 'desc',
          },
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
        _taxesService.gstRegistrationsAll(
          filters: const {'is_active': 1, 'sort_by': 'id'},
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
      locations =
          (responses[3] as PaginatedResponse<BusinessLocationModel>).data ??
          const <BusinessLocationModel>[];
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
      customerDetailsById
        ..clear()
        ..addEntries(
          customers
              .where((item) => item.id != null)
              .map((item) => MapEntry(item.id!, item)),
        );
      itemsLookup =
          ((responses[8] as PaginatedResponse<ItemModel>).data ??
                  const <ItemModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      itemPrices =
          ((responses[9] as PaginatedResponse<ItemPriceModel>).data ??
                  const <ItemPriceModel>[])
              .where((price) => price.isActive)
              .toList(growable: false);
      itemLookupById
        ..clear()
        ..addEntries(
          itemsLookup
              .where((item) => item.id != null)
              .map((item) => MapEntry(item.id!, item)),
        );
      uoms =
          ((responses[10] as PaginatedResponse<UomModel>).data ??
                  const <UomModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      uomConversions =
          ((responses[11] as PaginatedResponse<UomConversionModel>).data ??
                  const <UomConversionModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      taxCodes =
          ((responses[12] as PaginatedResponse<TaxCodeModel>).data ??
                  const <TaxCodeModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      gstRegistrations =
          (responses[13] as ApiResponse<List<GstRegistrationModel>>).data ??
          const <GstRegistrationModel>[];
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
      if (selected == null && selectId != null) {
        try {
          final detail = (await _salesService.quotation(selectId)).data;
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
    roundOffController.text =
        stringValue(data, 'round_off_amount').trim().isEmpty
        ? ''
        : stringValue(data, 'round_off_amount');
    applyRoundOff =
        (Validators.parseFlexibleNumber(roundOffController.text.trim()) ?? 0) !=
        0;
    notesController.text = stringValue(data, 'notes');
    termsController.text = stringValue(data, 'terms_conditions');
    isActive = boolValue(data, 'is_active', fallback: true);
    crmOpportunityId = intValue(data, 'crm_opportunity_id');
    _replaceLines(nextLines, notify: false);
    formError = null;
    unawaited(ensureCustomerPrintContext(customerPartyId));
    await refreshSalesChain(notify: false);
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
    customerPartyId = null;
    quotationNoController.clear();
    quotationDateController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    validUntilController.clear();
    customerRefNoController.clear();
    customerRefDateController.clear();
    roundOffController.clear();
    applyRoundOff = true;
    notesController.clear();
    termsController.text = documentTermsDefault('sales_quotation');
    isActive = true;
    _replaceLines(const <QuotationLineDraft>[], notify: false);
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
        unawaited(ensureCustomerPrintContext(partyId));
      }
      final note =
          'Linked CRM enquiry: ${stringValue(opportunityData, 'opportunity_name')}'
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
    filteredItems =
        filterBySearchAndStatus(
              items,
              query: searchController.text,
              status: statusFilter,
              statusOf: (item) =>
                  stringValue(item.toJson(), 'quotation_status'),
              searchFieldsOf: (item) {
                final data = item.toJson();
                return <String>[
                  stringValue(data, 'quotation_no'),
                  stringValue(data, 'quotation_status'),
                  quotationCustomerLabel(data),
                ];
              },
            )
            .where(
              (item) =>
                  matchesDateValueRange(
                    nullableStringValue(item.toJson(), 'quotation_date'),
                    fromValue: dateFromController.text,
                    toValue: dateToController.text,
                  ) &&
                  _matchesDashboardFilter(item),
            )
            .toList(growable: false);
    if (notify) {
      update();
    }
  }

  bool _matchesDashboardFilter(SalesQuotationModel item) {
    switch (dashboardFilter.trim()) {
      case 'open':
        final status = stringValue(
          item.toJson(),
          'quotation_status',
        ).trim().toLowerCase();
        return !<String>{
          'accepted',
          'rejected',
          'expired',
          'cancelled',
        }.contains(status);
      default:
        return true;
    }
  }

  void applyDashboardFilter(String value) {
    dashboardFilter = value.trim();
    if (dashboardFilter == 'open') {
      statusFilter = '';
    }
    searchController.clear();
    dateFromController.clear();
    dateToController.clear();
    _applyFilters();
  }

  void setStatusFilter(String value) {
    statusFilter = value;
    _applyFilters();
  }

  PartyModel? customerListEntryById(int? partyId) {
    if (partyId == null) {
      return null;
    }
    return customers.cast<PartyModel?>().firstWhere(
      (party) => party?.id == partyId,
      orElse: () => null,
    );
  }

  PartyModel? customerForPrintContext(int? partyId) {
    if (partyId == null) {
      return null;
    }
    return customerDetailsById[partyId] ?? customerListEntryById(partyId);
  }

  Future<void> ensureCustomerPrintContext(int? partyId) async {
    if (partyId == null) {
      return;
    }
    try {
      final responses = await Future.wait<dynamic>([
        _partiesService.party(partyId),
        _partiesService.partyAddresses(
          partyId,
          filters: const <String, dynamic>{'per_page': 100},
        ),
        _partiesService.partyContacts(
          partyId,
          filters: const <String, dynamic>{'per_page': 100},
        ),
        _partiesService.partyGstDetails(
          partyId,
          filters: const <String, dynamic>{'per_page': 100},
        ),
      ]);
      if (!mounted) {
        return;
      }
      final party = (responses[0] as ApiResponse<PartyModel>).data;
      if (party != null) {
        customerDetailsById[partyId] = party.copyWith(
          addresses:
              (responses[1] as PaginatedResponse<PartyAddressModel>).data ??
              party.addresses,
          contacts:
              (responses[2] as PaginatedResponse<PartyContactModel>).data ??
              party.contacts,
          gstDetails:
              (responses[3] as PaginatedResponse<PartyGstDetailModel>).data ??
              party.gstDetails,
        );
        customerGstDetailsById[partyId] =
            (responses[3] as PaginatedResponse<PartyGstDetailModel>).data ??
            const <PartyGstDetailModel>[];
      }
    } catch (_) {}
  }

  List<UomModel> uomOptionsForItem(int? itemId) {
    return allowedUomsForItem(itemById(itemId), uoms, uomConversions);
  }

  String get currencyCodeForTaxSummary {
    return 'INR';
  }

  String? resolveCompanyStateCodeForSummary() {
    return resolveCompanyStateCodeForGstSummary(
      gstRegistrations: gstRegistrations,
      locations: locations,
      companies: companies,
      companyId: companyId,
      branchId: branchId,
      locationId: locationId,
    );
  }

  String? resolveCustomerStateCodeForSummary() {
    final customer = customerForPrintContext(customerPartyId);
    final selected = selectedItem?.toJson() ?? const <String, dynamic>{};
    return resolvePartyStateCodeForGstSummary(
      party: customer,
      gstDetails:
          customerGstDetailsById[customerPartyId] ??
          customer?.gstDetails ??
          const <PartyGstDetailModel>[],
      shippingAddressId: intValue(selected, 'shipping_address_id'),
      billingAddressId: intValue(selected, 'billing_address_id'),
      preferredAddressType: 'shipping',
    );
  }

  bool? isInterStateForSummary() {
    return resolveIsInterStateForGstSummary(
      companyStateCode: resolveCompanyStateCodeForSummary(),
      counterpartyStateCode: resolveCustomerStateCodeForSummary(),
    );
  }

  SalesLineTaxBreakdown taxBreakdownForLine(QuotationLineDraft line) {
    return computeSalesLineTaxBreakdown(
      qty: Validators.parseFlexibleNumber(line.qtyController.text) ?? 0,
      rate: Validators.parseFlexibleNumber(line.rateController.text) ?? 0,
      discountPercent:
          Validators.parseFlexibleNumber(line.discountController.text) ?? 0,
      taxCode: salesTaxCodeById(taxCodes, line.taxCodeId),
      isInterState: isInterStateForSummary(),
    );
  }

  SalesDocumentTaxSummary taxSummary() {
    return summarizeSalesLineTaxes(lines.map(taxBreakdownForLine));
  }

  void _syncAutoRoundOff() {
    Validators.syncAutoRoundOffController(
      roundOffController,
      enabled: applyRoundOff,
      baseTotal: taxSummary().total,
    );
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
    final documentStatus = status.trim().toLowerCase();
    final summary = taxSummary();
    final roundOffAmount = applyRoundOff
        ? (Validators.parseFlexibleNumber(roundOffController.text.trim()) ?? 0)
        : 0.0;
    final selected = selectedItem?.toJson() ?? const <String, dynamic>{};
    final company = companies.cast<CompanyModel?>().firstWhere(
      (item) => item?.id == companyId,
      orElse: () => null,
    );
    final customer = customerForPrintContext(customerPartyId);
    final customerData = selected['customer'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(
            selected['customer'] as Map<String, dynamic>,
          )
        : customer?.toJson() ?? const <String, dynamic>{};
    final preferredAddress = preferredPartyAddress(
      customer,
      shippingAddressId: intValue(selected, 'shipping_address_id'),
      billingAddressId: intValue(selected, 'billing_address_id'),
    );
    final gstBreakupGroups = <String, dynamic>{};
    final printLines = lines
        .where((line) => line.itemId != null && line.itemId! > 0)
        .map((line) {
          final item = itemById(line.itemId);
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
            lineNo: lines.indexOf(line) + 1,
            itemName:
                item?.itemName ??
                item?.itemCode ??
                line.descriptionController.text.trim(),
            description: line.descriptionController.text.trim(),
            hsn: item?.hsnSacCode?.trim() ?? '',
            qty: Validators.parseFlexibleNumber(line.qtyController.text) ?? 0,
            rate: Validators.parseFlexibleNumber(line.rateController.text) ?? 0,
            taxAmount: roundToDouble(breakdown.total - breakdown.taxable, 2),
            lineTotal: roundToDouble(breakdown.total, 2),
          );
        })
        .toList(growable: false);
    final totalTax = summary.cgst + summary.sgst + summary.igst + summary.cess;

    return buildManagedDocumentPrintData(
      companies: companies,
      companyId: companyId,
      company: company,
      documentNumber: nullIfEmpty(quotationNoController.text) ?? 'Draft',
      documentDate: quotationDateController.text.trim(),
      referenceNumber: customerRefNoController.text.trim(),
      partyName: stringValue(customerData, 'party_name').isNotEmpty
          ? stringValue(customerData, 'party_name')
          : quotationCustomerLabel(selected),
      partyAddress: formatPartyAddress(
        preferredAddress,
        fallback: formatPartyAddressFromData(customerData),
      ),
      partyContact: resolvePartyContact(
        customer,
        fallback: stringValue(customerData, 'mobile_no'),
      ),
      partyGstin: resolvePartyPrintGstin(
        customer,
        gstDetails:
            customerGstDetailsById[customerPartyId] ??
            const <PartyGstDetailModel>[],
        sourceData: customerData,
        fallback: stringValue(customerData, 'gstin'),
      ),
      notes: notesController.text.trim(),
      termsConditions: termsController.text.trim(),
      subtotal: roundToDouble(summary.gross, 2),
      taxAmount: roundToDouble(totalTax, 2),
      totalAmount: roundToDouble(summary.total + roundOffAmount, 2),
      currencyCode: 'INR',
      lines: printLines,
      gstBreakup: finalizePrintTemplateGstBreakup(gstBreakupGroups),
      extraData: documentStatus == 'draft'
          ? const <String, dynamic>{'watermark_text': 'DRAFT'}
          : const <String, dynamic>{},
    );
  }

  Future<void> openPrintPreview(
    BuildContext context, {
    bool allowPrint = false,
    bool allowDownload = false,
    bool allowTemplateEditing = false,
  }) async {
    await openManagedDocumentPrintPreview(
      context,
      prepare: () => ensureCustomerPrintContext(customerPartyId),
      documentType: 'sales_quotation',
      title: 'Quotation',
      documentDataBuilder: quotationPrintData,
      allowPrint: allowPrint,
      allowDownload: allowDownload,
      allowTemplateEditing: allowTemplateEditing,
    );
  }

  void addLine() {
    lines = List<QuotationLineDraft>.from(lines)..add(QuotationLineDraft());
    refreshComputedState();
  }

  void removeLine(int index) {
    final next = List<QuotationLineDraft>.from(lines);
    next.removeAt(index);
    _replaceLines(next);
  }

  void _replaceLines(List<QuotationLineDraft> nextLines, {bool notify = true}) {
    replaceDisposableDraftEntries<QuotationLineDraft>(
      previous: lines,
      next: nextLines,
      createEmpty: () => QuotationLineDraft(),
      assign: (entries) => lines = entries,
      dispose: (entry) => entry.dispose(),
      notify: notify
          ? () {
              _syncAutoRoundOff();
              refreshLineItemsSection();
            }
          : null,
    );
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
    unawaited(ensureCustomerPrintContext(value));
    update();
  }

  void setIsActive(bool value) {
    if (!canEdit) {
      return;
    }
    isActive = value;
    update();
  }

  void setApplyRoundOff(bool value) {
    if (!canEdit) {
      return;
    }
    applyRoundOff = value;
    if (value) {
      _syncAutoRoundOff();
    } else {
      roundOffController.clear();
    }
    update();
  }

  void refreshComputedState() {
    _syncAutoRoundOff();
    refreshLineItemsSection();
  }

  void setLineItemId(int index, int? value) {
    if (!canEdit) {
      return;
    }
    final line = lines[index];
    line.itemId = value;
    final item = itemById(value);
    applySalesLineDefaultsFromItemMaster(
      item: item,
      itemPrices: itemPrices,
      uoms: uoms,
      conversions: uomConversions,
      rateController: line.rateController,
      setUom: (uomId) => line.uomId = uomId,
      currentUomId: line.uomId,
      setTaxCodeId: (taxCodeId) => line.taxCodeId = taxCodeId,
    );
    refreshComputedState();
  }

  void setLineUomId(int index, int? value) {
    if (!canEdit) {
      return;
    }
    lines[index].uomId = value;
    refreshComputedState();
  }

  void setLineTaxCodeId(int index, int? value) {
    if (!canEdit) {
      return;
    }
    lines[index].taxCodeId = value;
    refreshLineItemsSection();
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
    saving = true;
    formError = null;
    update();
    final preserveApplyRoundOff = applyRoundOff;
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
      'round_off_amount': applyRoundOff
          ? (Validators.parseFlexibleNumber(roundOffController.text.trim()) ??
                0)
          : 0,
      'taxable_amount': roundToDouble(summary.taxable, 2),
      'cgst_amount': roundToDouble(summary.cgst, 2),
      'sgst_amount': roundToDouble(summary.sgst, 2),
      'igst_amount': roundToDouble(summary.igst, 2),
      'cess_amount': roundToDouble(summary.cess, 2),
      'total_amount': roundToDouble(
        summary.total +
            (applyRoundOff
                ? (Validators.parseFlexibleNumber(
                        roundOffController.text.trim(),
                      ) ??
                      0)
                : 0),
        2,
      ),
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
      if (preserveApplyRoundOff &&
          (Validators.parseFlexibleNumber(roundOffController.text.trim()) ??
                  0) ==
              0) {
        applyRoundOff = true;
        update();
      }
      _refreshController.notifyChanged(source: 'sales_quotation');
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
      final currentId = intValue(selectedItem?.toJson() ?? const {}, 'id');
      final response = await action();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
      await loadPage(
        selectId:
            intValue(response.data?.toJson() ?? const {}, 'id') ?? currentId,
      );
      _refreshController.notifyChanged(source: 'sales_quotation');
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
      _refreshController.notifyChanged(source: 'sales_quotation');
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
    final reason = await promptCancellationReason(
      context,
      title: 'Cancel quotation',
      subjectLabel: selectedItem?.toString() ?? 'this sales quotation',
    );
    if (reason == null || !context.mounted) return;
    await docAction(
      context,
      () => _salesService.cancelQuotation(id, <String, dynamic>{
        'cancel_reason': reason,
      }),
    );
  }

  String _revisionSourceNumberFromData(Map<String, dynamic> data) {
    final notes = stringValue(data, 'notes');
    final match = _revisionHeaderPattern.firstMatch(notes);
    if (match != null) {
      final source = (match.group(2) ?? '').trim();
      if (source.isNotEmpty) {
        return source;
      }
    }
    return stringValue(data, 'quotation_no', 'Draft');
  }

  int _nextRevisionNumber(String sourceNumber) {
    var maxRevision = 0;
    for (final item in items) {
      final notes = stringValue(item.toJson(), 'notes');
      final match = _revisionHeaderPattern.firstMatch(notes);
      if (match == null) {
        continue;
      }
      final source = (match.group(2) ?? '').trim();
      if (source != sourceNumber) {
        continue;
      }
      final value = int.tryParse(match.group(1) ?? '');
      if (value != null && value > maxRevision) {
        maxRevision = value;
      }
    }
    return maxRevision + 1;
  }

  String _withoutRevisionHeader(String notes) {
    final trimmed = notes.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final match = _revisionHeaderPattern.firstMatch(trimmed);
    if (match == null || match.start != 0) {
      return trimmed;
    }
    return trimmed
        .substring(match.end)
        .trimLeft()
        .replaceFirst(RegExp(r'^\n+'), '');
  }

  void reviseSelected(BuildContext context) {
    final data = selectedItem?.toJson() ?? const <String, dynamic>{};
    if (data.isEmpty) {
      return;
    }

    final nextLines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map((line) {
          final copy = Map<String, dynamic>.from(line)
            ..remove('id')
            ..remove('sales_quotation_id')
            ..remove('created_at')
            ..remove('updated_at');
          return QuotationLineDraft.fromJson(copy);
        })
        .toList(growable: true);

    final sourceNumber = _revisionSourceNumberFromData(data);
    final revisionNumber = _nextRevisionNumber(sourceNumber);
    final sourceDate = displayDate(nullableStringValue(data, 'quotation_date'));
    final revisionHeader = [
      'Revised Quote $revisionNumber for quotation $sourceNumber',
      if (sourceDate.isNotEmpty) 'dated $sourceDate',
    ].join(' ');
    final originalNotes = _withoutRevisionHeader(stringValue(data, 'notes'));

    selectedItem = null;
    companyId = intValue(data, 'company_id') ?? contextCompanyId;
    branchId = intValue(data, 'branch_id') ?? contextBranchId;
    locationId = intValue(data, 'location_id') ?? contextLocationId;
    financialYearId =
        intValue(data, 'financial_year_id') ?? contextFinancialYearId;
    documentSeriesId = intValue(data, 'document_series_id');
    customerPartyId = intValue(data, 'customer_party_id');
    quotationNoController.clear();
    quotationDateController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    validUntilController.text = displayDate(
      nullableStringValue(data, 'valid_until'),
    );
    customerRefNoController.text = stringValue(data, 'customer_reference_no');
    customerRefDateController.text = displayDate(
      nullableStringValue(data, 'customer_reference_date'),
    );
    roundOffController.text =
        stringValue(data, 'round_off_amount').trim().isEmpty
        ? ''
        : stringValue(data, 'round_off_amount');
    applyRoundOff =
        (Validators.parseFlexibleNumber(roundOffController.text.trim()) ?? 0) !=
        0;
    notesController.text = originalNotes.isEmpty
        ? revisionHeader
        : '$revisionHeader\n\n$originalNotes';
    termsController.text = stringValue(data, 'terms_conditions');
    isActive = boolValue(data, 'is_active', fallback: true);
    crmOpportunityId = intValue(data, 'crm_opportunity_id');
    salesChain = null;
    formError = null;
    _replaceLines(nextLines, notify: false);
    _syncAutoRoundOff();
    unawaited(ensureCustomerPrintContext(customerPartyId));
    update();
    if (Responsive.isMobile(context) || Responsive.isTablet(context)) {
      workspaceController.openEditor();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Revision draft created as Revised Quote $revisionNumber. Update details and save it.',
        ),
      ),
    );
  }

  void _disposeLines(List<QuotationLineDraft> values) {
    for (final line in values) {
      line.dispose();
    }
  }
}
