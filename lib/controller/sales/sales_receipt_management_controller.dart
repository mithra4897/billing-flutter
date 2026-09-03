import '../../screen.dart';
import 'sales_module_refresh_controller.dart';

String _positiveReceiptAmountText(double? amount) {
  if (amount == null || amount <= 0) {
    return '';
  }
  final normalized = roundToDouble(amount, 2);
  return normalized == normalized.roundToDouble()
      ? normalized.round().toString()
      : normalized.appFixed();
}

class SalesReceiptAllocationDraft {
  SalesReceiptAllocationDraft({
    this.salesInvoiceId,
    this.allocationType = 'against_invoice',
    String? allocatedAmount,
    String? remarks,
    this.isAutoAllocated = false,
    this.sourceReceiptNo,
    this.allocatedAt,
    this.allocatedByName,
    this.salesInvoiceNo,
  }) : amountController = TextEditingController(text: allocatedAmount ?? ''),
       remarksController = TextEditingController(text: remarks ?? '');

  factory SalesReceiptAllocationDraft.fromJson(Map<String, dynamic> json) {
    return SalesReceiptAllocationDraft(
      salesInvoiceId: intValue(json, 'sales_invoice_id'),
      allocationType: stringValue(json, 'allocation_type', 'against_invoice'),
      allocatedAmount: _positiveReceiptAmountText(
        Validators.parseFlexibleNumber(json['allocated_amount']?.toString()),
      ),
      remarks: stringValue(json, 'remarks'),
      isAutoAllocated: boolValue(json, 'is_auto_allocated'),
      sourceReceiptNo: json['source_receipt'] is Map
          ? stringValue(
              Map<String, dynamic>.from(json['source_receipt'] as Map),
              'receipt_no',
            )
          : null,
      allocatedAt: nullableStringValue(json, 'allocated_at'),
      allocatedByName: json['allocated_by_user'] is Map
          ? stringValue(
              Map<String, dynamic>.from(json['allocated_by_user'] as Map),
              'display_name',
              stringValue(
                Map<String, dynamic>.from(json['allocated_by_user'] as Map),
                'username',
              ),
            )
          : null,
      salesInvoiceNo: json['invoice'] is Map
          ? stringValue(
              Map<String, dynamic>.from(json['invoice'] as Map),
              'invoice_no',
            )
          : nullableStringValue(json, 'invoice_no'),
    );
  }

  int? salesInvoiceId;
  String allocationType;
  final bool isAutoAllocated;
  final String? sourceReceiptNo;
  final String? allocatedAt;
  final String? allocatedByName;
  final String? salesInvoiceNo;
  final TextEditingController amountController;
  final TextEditingController remarksController;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sales_invoice_id': salesInvoiceId,
      'allocated_amount':
          Validators.parseFlexibleNumber(amountController.text) ?? 0,
      'allocation_type': allocationType,
      'remarks': nullIfEmpty(remarksController.text),
      'is_auto_allocated': isAutoAllocated,
    };
  }

  void dispose() {
    amountController.dispose();
    remarksController.dispose();
  }
}

class SalesReceiptManagementController extends GetxController {
  SalesReceiptManagementController();

  static const List<AppDropdownItem<String>> statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All'),
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'posted', label: 'Finished'),
        AppDropdownItem(
          value: 'partially_allocated',
          label: 'Partially Completed',
        ),
        AppDropdownItem(value: 'fully_allocated', label: 'Completed'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  final SalesService _salesService = SalesService();
  final CrmService _crmService = CrmService();
  final PartiesService _partiesService = PartiesService();
  final SalesModuleRefreshController _refreshController =
      SalesModuleRefreshController.ensureRegistered();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController dateFromController = TextEditingController();
  final TextEditingController dateToController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController receiptNoController = TextEditingController();
  final TextEditingController receiptDateController = TextEditingController();
  final TextEditingController paymentReferenceNoController =
      TextEditingController();
  final TextEditingController paymentReferenceDateController =
      TextEditingController();
  final TextEditingController directCustomerDetailsController =
      TextEditingController();
  final TextEditingController paidAmountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  bool emailing = false;
  bool autoAllocating = false;
  String? pageError;
  String? formError;
  String statusFilter = '';
  String paymentMode = 'bank';
  List<SalesReceiptModel> items = const <SalesReceiptModel>[];
  List<SalesReceiptModel> filteredItems = const <SalesReceiptModel>[];
  List<FinancialYearModel> financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<PartyModel> customers = const <PartyModel>[];
  List<AccountModel> accounts = const <AccountModel>[];
  List<SalesInvoiceModel> invoices = const <SalesInvoiceModel>[];
  SalesReceiptModel? selectedItem;
  SalesReceiptModel? pendingSelection;
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
  int? accountId;
  bool isDirectCustomer = false;
  bool isActive = true;
  Map<String, dynamic>? salesChain;
  List<SalesReceiptAllocationDraft> allocations =
      <SalesReceiptAllocationDraft>[];
  int persistedAllocationCount = 0;

  bool _initialized = false;

  bool get canEditSelectedReceipt {
    if (selectedItem == null) {
      return true;
    }
    return stringValue(selectedItem!.toJson(), 'receipt_status') == 'draft';
  }

  bool get isSelectedReceiptReadOnly =>
      selectedItem != null && !canEditSelectedReceipt;

  double get remainingUnallocatedAmount =>
      Validators.parseFlexibleNumber(
        selectedItem?.toJson()['unallocated_amount']?.toString(),
      ) ??
      0;

  bool get canAllocateRemainingAdvance {
    final status = stringValue(
      selectedItem?.toJson() ?? const <String, dynamic>{},
      'receipt_status',
    );
    return selectedItem != null &&
        !isDirectCustomer &&
        customerPartyId != null &&
        (status == 'posted' || status == 'partially_allocated') &&
        remainingUnallocatedAmount > 0;
  }

  bool isPersistedAllocation(int index) => index < persistedAllocationCount;

  List<SalesReceiptAllocationDraft> get newRemainingAllocations =>
      allocations.skip(persistedAllocationCount).toList(growable: false);

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
    receiptNoController.dispose();
    receiptDateController.dispose();
    paymentReferenceNoController.dispose();
    paymentReferenceDateController.dispose();
    directCustomerDetailsController.dispose();
    paidAmountController.dispose();
    notesController.dispose();
    _disposeAllocations(allocations);
    super.onClose();
  }

  Future<void> initialize({
    int? initialId,
    int? initialSalesInvoiceId,
    bool editorOnly = false,
  }) async {
    if (!_initialized) {
      _initialized = true;
    }
    await loadPage(
      selectId: initialId,
      initialSalesInvoiceId: initialSalesInvoiceId,
      editorOnly: editorOnly,
    );
  }

  Future<void> _handleWorkingContextChanged() async {
    await loadPage(
      selectId: intValue(selectedItem?.toJson() ?? const {}, 'id'),
    );
  }

  List<AppDropdownItem<String>> paymentModeDropdownItems() {
    const core = <AppDropdownItem<String>>[
      AppDropdownItem(value: 'cash', label: 'Cash'),
      AppDropdownItem(value: 'bank', label: 'Bank'),
    ];
    final mode = paymentMode.toLowerCase();
    if (mode != 'cash' && mode != 'bank') {
      final raw = paymentMode;
      final label = raw.isEmpty
          ? 'Other (legacy)'
          : '${raw[0].toUpperCase()}${raw.length > 1 ? raw.substring(1) : ''} (legacy)';
      return <AppDropdownItem<String>>[
        ...core,
        AppDropdownItem(value: raw, label: label),
      ];
    }
    return core;
  }

  bool accountEligibleForReceipt(AccountModel account) {
    final accountType = (account.accountType ?? '').toLowerCase();
    if (accountType != 'cash' && accountType != 'bank') {
      return false;
    }
    if (companyId != null && account.companyId != companyId) {
      return false;
    }
    final mode = paymentMode.toLowerCase();
    if (mode == 'cash') {
      return accountType == 'cash';
    }
    if (mode == 'bank') {
      return accountType == 'bank';
    }
    return true;
  }

  List<AccountModel> get receiptLedgerOptions =>
      accounts.where(accountEligibleForReceipt).toList(growable: false);

  void clearAccountIfInvalidForReceipt() {
    final currentId = accountId;
    if (currentId == null) {
      return;
    }
    if (!receiptLedgerOptions.any((account) => account.id == currentId)) {
      accountId = null;
    }
  }

  Future<void> loadPage({
    int? selectId,
    int? initialSalesInvoiceId,
    bool editorOnly = false,
  }) async {
    initialLoading = items.isEmpty;
    pageError = null;
    update();

    try {
      await MasterDataCache.to.ensureLoaded();
      final cache = MasterDataCache.to;
      final responses = await Future.wait<dynamic>([
        _salesService.receipts(
          filters: const {
            'per_page': 200,
            'sort_by': 'receipt_date',
            'sort_order': 'desc',
          },
        ),
        _salesService.invoices(
          filters: const {
            'per_page': 300,
            'sort_by': 'invoice_date',
            'sort_order': 'desc',
          },
        ),
      ]);

      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: cache.activeCompanies,
            branches: cache.activeBranches,
            locations: cache.activeLocations,
            financialYears: cache.activeFinancialYears,
          );

      items =
          (responses[0] as PaginatedResponse<SalesReceiptModel>).data ??
          const <SalesReceiptModel>[];
      final pending = pendingSelection;
      if (pending != null) {
        final pendingId = intValue(pending.toJson(), 'id');
        if (pendingId != null) {
          final existingIndex = items.indexWhere(
            (item) => intValue(item.toJson(), 'id') == pendingId,
          );
          if (existingIndex >= 0) {
            final nextItems = List<SalesReceiptModel>.from(items);
            nextItems[existingIndex] = pending;
            items = nextItems;
          } else {
            items = <SalesReceiptModel>[pending, ...items];
          }
        }
      }
      financialYears = cache.financialYears;
      documentSeries = cache.activeDocumentSeries;
      customers = salesCustomersOrFallback(
        parties: cache.parties,
        partyTypes: cache.partyTypes,
      );
      accounts = cache.activeAccounts;
      invoices =
          (responses[1] as PaginatedResponse<SalesInvoiceModel>).data ??
          const <SalesInvoiceModel>[];
      contextCompanyId = contextSelection.companyId;
      contextBranchId = contextSelection.branchId;
      contextLocationId = contextSelection.locationId;
      contextFinancialYearId = contextSelection.financialYearId;
      initialLoading = false;
      filteredItems = _filterItems(items, searchController.text, statusFilter);
      update();

      final selected = selectId != null
          ? items.cast<SalesReceiptModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () {
                final pending = pendingSelection;
                if (intValue(pending?.toJson() ?? const {}, 'id') == selectId) {
                  return pending;
                }
                final current = selectedItem;
                if (intValue(current?.toJson() ?? const {}, 'id') == selectId) {
                  return current;
                }
                return null;
              },
            )
          : (editorOnly
                ? null
                : (selectedItem == null
                      ? (items.isNotEmpty ? items.first : null)
                      : null));
      if (selected == null && selectId != null) {
        try {
          final detail = (await _salesService.receipt(selectId)).data;
          if (detail != null) {
            pendingSelection = null;
            await selectDocument(detail, notify: false);
            update();
            return;
          }
        } catch (_) {}
      }
      if (selected != null) {
        pendingSelection = null;
        await selectDocument(selected, notify: false);
      } else {
        resetForm(notify: false);
        if (initialSalesInvoiceId != null && editorOnly) {
          await bootstrapNewReceiptFromInvoice(initialSalesInvoiceId);
        }
      }
      update();
    } catch (error) {
      pageError = error.toString();
      initialLoading = false;
      update();
    }
  }

  Future<void> selectDocument(
    SalesReceiptModel item, {
    bool notify = true,
  }) async {
    final id = intValue(item.toJson(), 'id');
    if (id == null) {
      return;
    }
    final response = await _salesService.receipt(id);
    final full = response.data ?? item;
    final data = full.toJson();
    final nextAllocations =
        (data['allocations'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(SalesReceiptAllocationDraft.fromJson)
            .toList(growable: true);
    selectedItem = full;
    companyId = intValue(data, 'company_id');
    branchId = intValue(data, 'branch_id');
    locationId = intValue(data, 'location_id');
    financialYearId = intValue(data, 'financial_year_id');
    documentSeriesId = intValue(data, 'document_series_id');
    isDirectCustomer = boolValue(data, 'is_direct_customer');
    customerPartyId = isDirectCustomer
        ? null
        : intValue(data, 'customer_party_id');
    directCustomerDetailsController.text = stringValue(
      data,
      'direct_customer_details',
    );
    accountId = intValue(data, 'account_id');
    paymentMode = stringValue(data, 'payment_mode', 'bank');
    clearAccountIfInvalidForReceipt();
    receiptNoController.text = stringValue(data, 'receipt_no');
    receiptDateController.text = displayDate(
      nullableStringValue(data, 'receipt_date'),
    );
    paymentReferenceNoController.text = stringValue(
      data,
      'payment_reference_no',
    );
    paymentReferenceDateController.text = displayDate(
      nullableStringValue(data, 'payment_reference_date'),
    );
    paidAmountController.text = _positiveReceiptAmountText(
      Validators.parseFlexibleNumber(data['paid_amount']?.toString()),
    );
    notesController.text = stringValue(data, 'notes');
    isActive = boolValue(data, 'is_active', fallback: true);
    _replaceAllocations(nextAllocations, notify: false);
    persistedAllocationCount = nextAllocations.length;
    formError = null;
    update();
    await refreshSalesChain();
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
    isDirectCustomer = false;
    accountId = null;
    paymentMode = 'bank';
    receiptNoController.clear();
    receiptDateController.text = displayTodayDate();
    paymentReferenceNoController.clear();
    paymentReferenceDateController.clear();
    directCustomerDetailsController.clear();
    paidAmountController.clear();
    notesController.clear();
    isActive = true;
    _replaceAllocations(const <SalesReceiptAllocationDraft>[], notify: false);
    persistedAllocationCount = 0;
    formError = null;
    salesChain = null;
    if (notify) {
      update();
    }
  }

  Future<void> bootstrapNewReceiptFromInvoice(int invoiceId) async {
    try {
      final response = await _salesService.invoice(invoiceId);
      final invoice = response.data;
      if (invoice == null) {
        return;
      }
      final data = invoice.toJson();
      final balance =
          Validators.parseFlexibleNumber(data['balance_amount']?.toString()) ??
          0;
      if (balance <= 0) {
        formError = 'This invoice has no outstanding balance to receive.';
        update();
        return;
      }
      final allocationAmount = balance == balance.roundToDouble()
          ? balance.round().toString()
          : balance.appFixed();
      companyId = invoice.companyId;
      branchId = invoice.branchId;
      locationId = invoice.locationId;
      financialYearId = invoice.financialYearId;
      final series = seriesOptions();
      documentSeriesId =
          invoice.documentSeriesId ??
          (series.isNotEmpty ? series.first.id : null);
      isDirectCustomer = invoice.isDirectCustomer;
      customerPartyId = invoice.isDirectCustomer
          ? null
          : (invoice.customerPartyId > 0 ? invoice.customerPartyId : null);
      final invoiceCustomer = invoice.customer;
      if (customerPartyId != null &&
          invoiceCustomer != null &&
          !customers.any((customer) => customer.id == customerPartyId)) {
        customers = <PartyModel>[
          ...customers,
          PartyModel.fromJson(invoiceCustomer),
        ];
      }
      directCustomerDetailsController.text =
          invoice.directCustomerDetails?.trim() ?? '';
      paidAmountController.text = allocationAmount;
      if (!invoices.any((entry) => entry.id == invoice.id)) {
        invoices = <SalesInvoiceModel>[invoice, ...invoices];
      }
      _replaceAllocations(<SalesReceiptAllocationDraft>[
        SalesReceiptAllocationDraft(
          salesInvoiceId: invoice.id,
          allocationType: 'against_invoice',
          allocatedAmount: allocationAmount,
          remarks: 'Against ${invoice.invoiceNo ?? 'invoice #${invoice.id}'}',
        ),
      ], notify: false);
      persistedAllocationCount = 0;
      formError = null;
      update();
      await refreshSalesChain(invoiceId: invoice.id);
      update();
    } catch (error) {
      formError = error.toString();
      update();
    }
  }

  void _applyFilters() {
    filteredItems = _filterItems(items, searchController.text, statusFilter);
    update();
  }

  List<SalesReceiptModel> _filterItems(
    List<SalesReceiptModel> source,
    String searchText,
    String status,
  ) {
    return filterBySearchAndStatus(
          source,
          query: searchText,
          status: status,
          statusOf: (item) => stringValue(item.toJson(), 'receipt_status'),
          searchFieldsOf: (item) {
            final data = item.toJson();
            return <String>[
              stringValue(data, 'receipt_no'),
              stringValue(data, 'receipt_status'),
              quotationCustomerLabel(data),
              stringValue(data, 'payment_reference_no'),
            ];
          },
        )
        .where(
          (item) => matchesDateValueRange(
            nullableStringValue(item.toJson(), 'receipt_date'),
            fromValue: dateFromController.text,
            toValue: dateToController.text,
          ),
        )
        .toList(growable: false);
  }

  void setStatusFilter(String value) {
    statusFilter = value;
    _applyFilters();
  }

  List<DocumentSeriesModel> seriesOptions() {
    return documentSeries
        .where((item) {
          final typeOk =
              item.documentType == null || item.documentType == 'SALES_RECEIPT';
          final companyOk = companyId == null || item.companyId == companyId;
          final fyOk =
              financialYearId == null ||
              item.financialYearId == financialYearId;
          return typeOk && companyOk && fyOk;
        })
        .toList(growable: false);
  }

  List<SalesInvoiceModel> get invoiceOptions {
    final referencedInvoiceIds = allocations
        .map((allocation) => allocation.salesInvoiceId)
        .whereType<int>()
        .toSet();
    return invoices
        .where((invoice) {
          if (invoice.companyId != companyId) {
            return false;
          }
          final customerMatches = isDirectCustomer
              ? invoice.isDirectCustomer
              : !invoice.isDirectCustomer &&
                    (customerPartyId == null ||
                        invoice.customerPartyId == customerPartyId);
          if (!customerMatches) {
            return false;
          }
          final invoiceId = invoice.id;
          final isAlreadyReferenced =
              invoiceId != null && referencedInvoiceIds.contains(invoiceId);
          return isAlreadyReferenced || invoiceOutstandingAmount(invoice) > 0;
        })
        .toList(growable: false);
  }

  List<SalesInvoiceModel> invoiceOptionsForAllocation(int index) {
    final allocation = allocations[index];
    final relevantAllocations = canAllocateRemainingAdvance
        ? allocations.skip(persistedAllocationCount)
        : allocations;
    return invoiceOptions
        .where((invoice) {
          final invoiceId = invoice.id;
          if (invoiceId == null) {
            return false;
          }
          if (allocation.salesInvoiceId == invoiceId) {
            return true;
          }
          final allocatedOnOtherLines = relevantAllocations
              .where(
                (other) =>
                    !identical(other, allocation) &&
                    other.salesInvoiceId == invoiceId,
              )
              .fold<double>(
                0,
                (sum, other) =>
                    sum +
                    (Validators.parseFlexibleNumber(
                          other.amountController.text,
                        ) ??
                        0),
              );
          return invoiceOutstandingAmount(invoice) - allocatedOnOtherLines >
              0.005;
        })
        .toList(growable: false);
  }

  SalesInvoiceModel? invoiceById(int? invoiceId) {
    if (invoiceId == null) {
      return null;
    }
    return invoices.cast<SalesInvoiceModel?>().firstWhere(
      (invoice) => invoice?.id == invoiceId,
      orElse: () => null,
    );
  }

  double invoiceOutstandingAmount(SalesInvoiceModel? invoice) {
    if (invoice == null) {
      return 0;
    }
    return invoice.balanceAmount ?? 0;
  }

  String formatReceiptAmount(double amount) {
    final normalized = roundToDouble(amount, 2);
    return normalized == normalized.roundToDouble()
        ? normalized.round().toString()
        : normalized.appFixed();
  }

  double totalAllocatedAmount() {
    return roundToDouble(
      allocations.fold<double>(0, (sum, allocation) {
        if (allocation.salesInvoiceId == null) {
          return sum;
        }
        return sum +
            (Validators.parseFlexibleNumber(allocation.amountController.text) ??
                0);
      }),
      2,
    );
  }

  double get displayedCustomerAdvance {
    final newlyAllocated = newRemainingAllocations.fold<double>(
      0,
      (sum, allocation) =>
          sum +
          (allocation.salesInvoiceId == null
              ? 0
              : Validators.parseFlexibleNumber(
                      allocation.amountController.text,
                    ) ??
                    0),
    );
    if (canAllocateRemainingAdvance) {
      return roundToDouble(
        (remainingUnallocatedAmount - newlyAllocated).clamp(0, double.infinity),
        2,
      );
    }
    final received =
        Validators.parseFlexibleNumber(paidAmountController.text) ?? 0;
    return roundToDouble(
      (received - totalAllocatedAmount()).clamp(0, double.infinity),
      2,
    );
  }

  void refreshAllocationTotals({bool notify = true}) {
    if (notify) {
      update();
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

  void setCustomerPartyId(int? value) {
    customerPartyId = value;
    _pruneAllocationsForCurrentCustomer();
    update();
  }

  Future<List<ErpLinkFieldOption<int>>> searchCustomerOptions(String query) =>
      searchPartyLinkOptions(
        service: _partiesService,
        query: query,
        currentRoleParties: customers,
        onDiscovered: (party) {
          if (!customers.any((customer) => customer.id == party.id)) {
            customers = <PartyModel>[...customers, party];
          }
        },
      );

  void setDirectCustomer(bool value) {
    isDirectCustomer = value;
    if (value) {
      customerPartyId = null;
      directCustomerDetailsController.text = directCustomerDetailsController
          .text
          .trim();
    } else {
      directCustomerDetailsController.clear();
    }
    _pruneAllocationsForCurrentCustomer();
    update();
  }

  void setPaymentMode(String? value) {
    paymentMode = value ?? 'bank';
    clearAccountIfInvalidForReceipt();
    update();
  }

  void setAccountId(int? value) {
    accountId = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  void addAllocation() {
    if (isSelectedReceiptReadOnly && !canAllocateRemainingAdvance) {
      return;
    }
    final newlyAllocated = newRemainingAllocations.fold<double>(
      0,
      (sum, allocation) =>
          sum +
          (Validators.parseFlexibleNumber(allocation.amountController.text) ??
              0),
    );
    if (canAllocateRemainingAdvance &&
        newlyAllocated >= remainingUnallocatedAmount) {
      formError = 'The remaining customer advance is already fully allocated.';
      update();
      return;
    }
    allocations = List<SalesReceiptAllocationDraft>.from(allocations)
      ..add(SalesReceiptAllocationDraft());
    update();
  }

  void removeAllocation(int index) {
    if (isPersistedAllocation(index)) {
      return;
    }
    final nextAllocations = List<SalesReceiptAllocationDraft>.from(allocations);
    final removed = nextAllocations.removeAt(index);
    allocations = nextAllocations;
    refreshAllocationTotals();
    disposeDraftEntriesNextFrame<SalesReceiptAllocationDraft>([
      removed,
    ], (entry) => entry.dispose());
  }

  void setAllocationSalesInvoiceId(int index, int? value) {
    final allocation = allocations[index];
    allocation.salesInvoiceId = value;
    final invoice = invoiceById(value);
    final outstanding = invoiceOutstandingAmount(invoice);
    final relevantAllocations = canAllocateRemainingAdvance
        ? allocations.skip(persistedAllocationCount)
        : allocations;
    final allocatedOnOtherLines = relevantAllocations
        .where((other) => !identical(other, allocation))
        .fold<double>(
          0,
          (sum, other) =>
              sum +
              (Validators.parseFlexibleNumber(other.amountController.text) ??
                  0),
        );
    final allocatedToInvoiceOnOtherLines = relevantAllocations
        .where(
          (other) =>
              !identical(other, allocation) && other.salesInvoiceId == value,
        )
        .fold<double>(
          0,
          (sum, other) =>
              sum +
              (Validators.parseFlexibleNumber(other.amountController.text) ??
                  0),
        );
    final availableReceiptAmount = canAllocateRemainingAdvance
        ? remainingUnallocatedAmount
        : Validators.parseFlexibleNumber(paidAmountController.text) ?? 0;
    final remainingReceipt = availableReceiptAmount - allocatedOnOtherLines;
    final remainingInvoice = outstanding - allocatedToInvoiceOnOtherLines;
    final maximumAllocation = remainingReceipt < remainingInvoice
        ? remainingReceipt
        : remainingInvoice;
    allocation.amountController.text = maximumAllocation <= 0
        ? ''
        : formatReceiptAmount(maximumAllocation);
    if ((allocation.remarksController.text).trim().isEmpty && invoice != null) {
      allocation.remarksController.text =
          'Against ${invoice.invoiceNo ?? 'invoice #${invoice.id}'}';
    }
    refreshAllocationTotals(notify: false);
    unawaited(refreshSalesChain(invoiceId: value));
    update();
  }

  Future<void> autoAllocateOldestInvoices() async {
    if ((isSelectedReceiptReadOnly && !canAllocateRemainingAdvance) ||
        autoAllocating) {
      return;
    }
    final editableAllocations = canAllocateRemainingAdvance
        ? newRemainingAllocations
        : allocations;
    if (editableAllocations.isNotEmpty) {
      formError =
          'Remove the existing allocation lines before using Auto Allocate.';
      update();
      return;
    }
    if (isDirectCustomer) {
      formError =
          'Auto Allocate is available only for a registered customer account.';
      update();
      return;
    }
    final selectedCompanyId = companyId;
    final selectedCustomerId = customerPartyId;
    final receivedAmount = canAllocateRemainingAdvance
        ? remainingUnallocatedAmount
        : Validators.parseFlexibleNumber(paidAmountController.text) ?? 0;
    if (selectedCompanyId == null || selectedCustomerId == null) {
      formError = 'Select a customer before auto allocation.';
      update();
      return;
    }
    if (receivedAmount <= 0) {
      formError =
          'Enter a received amount greater than zero before auto allocation.';
      update();
      return;
    }

    autoAllocating = true;
    formError = null;
    update();
    try {
      final response = await _salesService.previewReceiptAutoAllocation(
        companyId: selectedCompanyId,
        customerPartyId: selectedCustomerId,
        paidAmount: receivedAmount,
      );
      final data = response.data ?? const <String, dynamic>{};
      final previewLines = (data['allocations'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (line) => SalesReceiptAllocationDraft.fromJson(
              Map<String, dynamic>.from(line),
            ),
          )
          .toList(growable: true);
      if (previewLines.isEmpty) {
        formError = 'No outstanding sales invoices were found.';
      } else if (canAllocateRemainingAdvance) {
        allocations = <SalesReceiptAllocationDraft>[
          ...allocations,
          ...previewLines,
        ];
      } else {
        _replaceAllocations(previewLines, notify: false);
        persistedAllocationCount = 0;
      }
    } catch (error) {
      formError = error.toString();
    } finally {
      autoAllocating = false;
      update();
    }
  }

  void setAllocationType(int index, String? value) {
    allocations[index].allocationType = value ?? 'against_invoice';
    update();
  }

  Future<void> save(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    final directCustomerDetails = nullIfEmpty(
      directCustomerDetailsController.text,
    );
    if (isDirectCustomer) {
      if (directCustomerDetails == null) {
        formError = 'Enter direct customer details.';
        update();
        return;
      }
    } else if (customerPartyId == null) {
      formError = 'Choose a customer or mark this as direct customer.';
      update();
      return;
    }
    final paidAmount =
        Validators.parseFlexibleNumber(paidAmountController.text) ?? 0;
    if (paidAmount <= 0) {
      formError = 'Received amount must be greater than zero.';
      update();
      return;
    }
    final allocationError = _validateAllocationLines(
      allocations,
      maximumTotal: paidAmount,
    );
    if (allocationError != null) {
      formError = allocationError;
      update();
      return;
    }
    if (totalAllocatedAmount() > roundToDouble(paidAmount, 2)) {
      formError = 'Total allocated amount cannot exceed the received amount.';
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
      'receipt_no': nullIfEmpty(receiptNoController.text),
      'receipt_date': receiptDateController.text.trim(),
      'customer_party_id': customerPartyId,
      'is_direct_customer': isDirectCustomer,
      'direct_customer_details': directCustomerDetails,
      'payment_mode': paymentMode,
      'account_id': accountId,
      'payment_reference_no': nullIfEmpty(paymentReferenceNoController.text),
      'payment_reference_date': nullIfEmpty(
        paymentReferenceDateController.text,
      ),
      'paid_amount': paidAmount,
      'notes': nullIfEmpty(notesController.text),
      'is_active': isActive,
      if (allocations.isNotEmpty)
        'allocations': allocations
            .map((item) => item.toJson())
            .toList(growable: false),
    };
    try {
      final response = selectedItem == null
          ? await _salesService.createReceipt(
              SalesReceiptModel.fromJson(normalizeDatePayload(payload)),
            )
          : await _salesService.updateReceipt(
              intValue(selectedItem!.toJson(), 'id')!,
              SalesReceiptModel.fromJson(normalizeDatePayload(payload)),
            );
      final saved = response.data;
      if (saved != null) {
        pendingSelection = saved;
        final savedId = intValue(saved.toJson(), 'id');
        if (savedId != null) {
          final existingIndex = items.indexWhere(
            (item) => intValue(item.toJson(), 'id') == savedId,
          );
          if (existingIndex >= 0) {
            final nextItems = List<SalesReceiptModel>.from(items);
            nextItems[existingIndex] = saved;
            items = nextItems;
          } else {
            items = <SalesReceiptModel>[saved, ...items];
          }
          filteredItems = _filterItems(
            items,
            searchController.text,
            statusFilter,
          );
        }
      }
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
      await loadPage(
        selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
      );
      _refreshController.notifyChanged(source: 'sales_receipt');
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
    Future<ApiResponse<SalesReceiptModel>> Function() action,
  ) async {
    try {
      final response = await action();
      final saved = response.data;
      if (saved != null) {
        pendingSelection = saved;
        final savedId = intValue(saved.toJson(), 'id');
        if (savedId != null) {
          final existingIndex = items.indexWhere(
            (item) => intValue(item.toJson(), 'id') == savedId,
          );
          if (existingIndex >= 0) {
            final nextItems = List<SalesReceiptModel>.from(items);
            nextItems[existingIndex] = saved;
            items = nextItems;
          } else {
            items = <SalesReceiptModel>[saved, ...items];
          }
          filteredItems = _filterItems(
            items,
            searchController.text,
            statusFilter,
          );
        }
      }
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
      await loadPage(
        selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
      );
      _refreshController.notifyChanged(source: 'sales_receipt');
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
      () => _salesService.postReceipt(
        id,
        SalesReceiptModel.fromJson(const <String, dynamic>{}),
      ),
    );
  }

  Future<void> saveRemainingAllocations(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final receiptId = intValue(
      selectedItem?.toJson() ?? const <String, dynamic>{},
      'id',
    );
    final newLines = newRemainingAllocations;
    if (receiptId == null || !canAllocateRemainingAdvance) {
      return;
    }
    if (newLines.isEmpty) {
      formError = 'Add at least one invoice allocation.';
      update();
      return;
    }
    final allocationError = _validateAllocationLines(
      newLines,
      maximumTotal: remainingUnallocatedAmount,
    );
    if (allocationError != null) {
      formError = allocationError;
      update();
      return;
    }

    saving = true;
    formError = null;
    update();
    try {
      final response = await _salesService.allocateRemainingReceipt(
        receiptId,
        newLines.map((line) => line.toJson()).toList(growable: false),
      );
      final updated = response.data;
      if (updated != null) {
        pendingSelection = updated;
        await selectDocument(updated, notify: false);
      } else {
        await loadPage(selectId: receiptId);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
      _refreshController.notifyChanged(source: 'sales_receipt');
    } catch (error) {
      formError = error.toString();
    } finally {
      saving = false;
      update();
    }
  }

  String? _validateAllocationLines(
    List<SalesReceiptAllocationDraft> lines, {
    required double maximumTotal,
  }) {
    final allocatedByInvoice = <int, double>{};
    var total = 0.0;
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final lineNo = index + 1;
      final invoiceId = line.salesInvoiceId;
      final amount =
          Validators.parseFlexibleNumber(line.amountController.text) ?? 0;
      if (invoiceId == null) {
        return 'Select an invoice for allocation line $lineNo.';
      }
      if (amount <= 0) {
        return 'Enter an amount for allocation line $lineNo.';
      }
      allocatedByInvoice[invoiceId] =
          (allocatedByInvoice[invoiceId] ?? 0) + amount;
      total += amount;
    }
    for (final entry in allocatedByInvoice.entries) {
      final invoice = invoiceById(entry.key);
      if (invoice != null &&
          roundToDouble(entry.value, 2) >
              roundToDouble(invoiceOutstandingAmount(invoice), 2)) {
        return 'Total allocation for ${invoice.invoiceNo ?? 'invoice'} cannot exceed its outstanding amount.';
      }
    }
    if (roundToDouble(total, 2) > roundToDouble(maximumTotal, 2)) {
      return 'Total allocation cannot exceed ${formatReceiptAmount(maximumTotal)}.';
    }
    return null;
  }

  DocumentPrintDataModel salesReceiptPrintData() {
    final companies = MasterDataCache.to.activeCompanies;
    final company = companies.cast<CompanyModel?>().firstWhere(
      (item) => item?.id == companyId,
      orElse: () => null,
    );
    final customer = customers.cast<PartyModel?>().firstWhere(
      (item) => item?.id == customerPartyId,
      orElse: () => null,
    );
    final address = customer?.addresses.cast<PartyAddressModel?>().firstWhere(
      (item) => item?.isActive == true && item?.isDefault == true,
      orElse: () => customer.addresses.cast<PartyAddressModel?>().firstWhere(
        (item) => item?.isActive == true,
        orElse: () => null,
      ),
    );
    final gst = customer?.gstDetails.cast<PartyGstDetailModel?>().firstWhere(
      (item) => item?.isActive != false && item?.isDefault == true,
      orElse: () => null,
    );
    final paidAmount =
        Validators.parseFlexibleNumber(paidAmountController.text) ?? 0;
    final printLines = allocations.indexed
        .map((entry) {
          final index = entry.$1;
          final allocation = entry.$2;
          final invoice = invoices.cast<SalesInvoiceModel?>().firstWhere(
            (item) => item?.id == allocation.salesInvoiceId,
            orElse: () => null,
          );
          final amount =
              Validators.parseFlexibleNumber(
                allocation.amountController.text,
              ) ??
              0;
          return DocumentPrintLineModel(
            lineNo: index + 1,
            itemName: invoice?.invoiceNo ?? 'Advance / Unallocated',
            description: allocation.remarksController.text.trim().isNotEmpty
                ? allocation.remarksController.text.trim()
                : allocation.allocationType.replaceAll('_', ' '),
            qty: 1,
            rate: amount,
            lineTotal: amount,
          );
        })
        .toList(growable: false);

    return buildManagedDocumentPrintData(
      companies: companies,
      companyId: companyId,
      company: company,
      documentNumber: receiptNoController.text.trim().isEmpty
          ? 'Draft'
          : receiptNoController.text.trim(),
      documentDate: receiptDateController.text.trim(),
      referenceNumber: paymentReferenceNoController.text.trim(),
      partyName: isDirectCustomer
          ? directCustomerDetailsController.text.trim()
          : (customer?.displayName ?? customer?.partyName ?? 'Not provided'),
      partyAddress: formatPartyAddress(address),
      partyContact: resolvePartyContact(customer),
      partyGstin: gst?.gstin ?? '',
      notes: notesController.text.trim(),
      subtotal: paidAmount,
      taxAmount: 0,
      totalAmount: paidAmount,
      currencyCode: 'INR',
      lines: printLines,
      extraData: <String, dynamic>{
        'payment_mode': paymentMode,
        'payment_reference_date': paymentReferenceDateController.text.trim(),
        if (stringValue(selectedItem?.toJson() ?? const {}, 'receipt_status') ==
            'draft')
          'watermark_text': 'DRAFT',
      },
    );
  }

  Future<void> openPrintPreview(BuildContext context) {
    final canOutput =
        stringValue(selectedItem?.toJson() ?? const {}, 'receipt_status') !=
        'draft';
    return openManagedDocumentPrintPreview(
      context,
      documentType: 'sales_receipt',
      title: 'Sales Receipt',
      documentDataBuilder: salesReceiptPrintData,
      documentId: selectedItem?.id,
      companyId: companyId,
      allowPrint: canOutput,
      allowDownload: canOutput,
      allowTemplateEditing: true,
    );
  }

  Future<void> sendEmailPdfDirectly(BuildContext context) async {
    final id = selectedItem?.id;
    if (id == null || emailing) return;
    emailing = true;
    update();
    try {
      final number = selectedItem?.receiptNo?.trim();
      await sendPrintableDocumentEmailDirectly(
        context,
        payload: PrintableDocumentEmailPayload(
          target: const PrintableDocumentEmailTarget(
            module: 'sales',
            documentType: 'sales_receipt',
          ),
          title: 'Sales Receipt',
          documentId: id,
          documentData: salesReceiptPrintData(),
          companyId: companyId,
          fileName: number == null || number.isEmpty
              ? 'sales_receipt_$id.pdf'
              : '${number.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')}.pdf',
        ),
      );
    } finally {
      emailing = false;
      update();
    }
  }

  Future<void> cancelSelected(BuildContext context) async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) {
      return;
    }
    final reason = await promptCancellationReason(
      context,
      title: 'Cancel receipt',
      subjectLabel: selectedItem?.toString() ?? 'this sales receipt',
    );
    if (reason == null || !context.mounted) {
      return;
    }
    await docAction(
      context,
      () => _salesService.cancelReceipt(id, <String, dynamic>{
        'cancel_reason': reason,
      }),
    );
  }

  void _disposeAllocations(List<SalesReceiptAllocationDraft> values) {
    for (final allocation in values) {
      allocation.dispose();
    }
  }

  void _replaceAllocations(
    List<SalesReceiptAllocationDraft> nextAllocations, {
    bool notify = true,
  }) {
    final previous = allocations;
    allocations = List<SalesReceiptAllocationDraft>.from(nextAllocations);
    refreshAllocationTotals(notify: false);
    if (notify) {
      update();
    }
    disposeDraftEntriesNextFrame<SalesReceiptAllocationDraft>(
      previous,
      (allocation) => allocation.dispose(),
    );
  }

  Future<void> refreshSalesChain({int? invoiceId}) async {
    final receiptId = intValue(selectedItem?.toJson() ?? const {}, 'id');
    final sourceInvoiceId =
        invoiceId ??
        allocations
            .cast<SalesReceiptAllocationDraft?>()
            .firstWhere(
              (allocation) => allocation?.salesInvoiceId != null,
              orElse: () => null,
            )
            ?.salesInvoiceId;
    try {
      if (receiptId != null) {
        final response = await _crmService.salesChain(receiptId: receiptId);
        salesChain = response.data;
      } else if (sourceInvoiceId != null) {
        final response = await _crmService.salesChain(
          invoiceId: sourceInvoiceId,
        );
        salesChain = response.data;
      } else {
        salesChain = null;
      }
    } catch (_) {
      salesChain = null;
    }
    update();
  }

  void _pruneAllocationsForCurrentCustomer() {
    if (allocations.isEmpty) {
      return;
    }
    final allowedInvoiceIds = invoiceOptions
        .map((invoice) => invoice.id)
        .whereType<int>()
        .toSet();
    final nextAllocations = <SalesReceiptAllocationDraft>[];
    final removedAllocations = <SalesReceiptAllocationDraft>[];
    for (final allocation in allocations) {
      final invoiceId = allocation.salesInvoiceId;
      final shouldKeep =
          invoiceId == null || allowedInvoiceIds.contains(invoiceId);
      if (shouldKeep) {
        nextAllocations.add(allocation);
      } else {
        removedAllocations.add(allocation);
      }
    }
    if (removedAllocations.isEmpty) {
      return;
    }
    allocations = nextAllocations;
    refreshAllocationTotals(notify: false);
    disposeDraftEntriesNextFrame<SalesReceiptAllocationDraft>(
      removedAllocations,
      (allocation) => allocation.dispose(),
    );
  }
}
