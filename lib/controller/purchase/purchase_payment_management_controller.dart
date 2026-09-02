import '../../screen.dart';
import 'purchase_module_refresh_controller.dart';

String _positivePaymentAmountText(double? amount) {
  if (amount == null || amount <= 0) {
    return '';
  }
  final normalized = roundToDouble(amount, 2);
  return normalized == normalized.roundToDouble()
      ? normalized.round().toString()
      : normalized.appFixed();
}

class PaymentAllocationDraft {
  PaymentAllocationDraft({
    this.purchaseInvoiceId,
    this.allocationType = 'against_invoice',
    String? allocatedAmount,
    String? remarks,
    this.isAutoAllocated = false,
    this.sourcePaymentNo,
    this.allocatedAt,
    this.allocatedByName,
    this.purchaseInvoiceNo,
  }) : amountController = TextEditingController(text: allocatedAmount ?? ''),
       remarksController = TextEditingController(text: remarks ?? '');

  factory PaymentAllocationDraft.fromJson(Map<String, dynamic> json) {
    return PaymentAllocationDraft(
      purchaseInvoiceId: intValue(json, 'purchase_invoice_id'),
      allocationType: stringValue(json, 'allocation_type', 'against_invoice'),
      allocatedAmount: _positivePaymentAmountText(
        Validators.parseFlexibleNumber(json['allocated_amount']?.toString()),
      ),
      remarks: stringValue(json, 'remarks'),
      isAutoAllocated: boolValue(json, 'is_auto_allocated'),
      sourcePaymentNo: json['source_payment'] is Map
          ? stringValue(
              Map<String, dynamic>.from(json['source_payment'] as Map),
              'payment_no',
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
      purchaseInvoiceNo: json['invoice'] is Map
          ? stringValue(
              Map<String, dynamic>.from(json['invoice'] as Map),
              'invoice_no',
            )
          : nullableStringValue(json, 'invoice_no'),
    );
  }

  int? purchaseInvoiceId;
  String allocationType;
  final bool isAutoAllocated;
  final String? sourcePaymentNo;
  final String? allocatedAt;
  final String? allocatedByName;
  final String? purchaseInvoiceNo;
  final TextEditingController amountController;
  final TextEditingController remarksController;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'purchase_invoice_id': purchaseInvoiceId,
      'allocated_amount':
          Validators.parseFlexibleNumber(amountController.text) ?? 0,
      'allocation_type': allocationType,
      'remarks': nullIfEmpty(remarksController.text),
    };
  }

  void dispose() {
    amountController.dispose();
    remarksController.dispose();
  }
}

class PurchasePaymentManagementController extends GetxController {
  final PartiesService _partiesService = PartiesService();
  PurchasePaymentManagementController();

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

  static const List<AppDropdownItem<String>> paymentModeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'cash', label: 'Cash'),
        AppDropdownItem(value: 'bank', label: 'Bank'),
        AppDropdownItem(value: 'upi', label: 'UPI'),
        AppDropdownItem(value: 'cheque', label: 'Cheque'),
        AppDropdownItem(value: 'card', label: 'Card'),
        AppDropdownItem(value: 'wallet', label: 'Wallet'),
        AppDropdownItem(value: 'adjustment', label: 'Adjustment'),
        AppDropdownItem(value: 'other', label: 'Other'),
      ];

  final PurchaseService _purchaseService = PurchaseService();
  final PurchaseModuleRefreshController _refreshController =
      PurchaseModuleRefreshController.ensureRegistered();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController dateFromController = TextEditingController();
  final TextEditingController dateToController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController paymentNoController = TextEditingController();
  final TextEditingController paymentDateController = TextEditingController();
  final TextEditingController referenceNoController = TextEditingController();
  final TextEditingController referenceDateController = TextEditingController();
  final TextEditingController paidAmountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  bool autoAllocating = false;
  String? pageError;
  String? formError;
  String statusFilter = '';
  int? filterSupplierId;
  String paymentMode = 'bank';
  List<PurchasePaymentModel> items = const <PurchasePaymentModel>[];
  List<PurchasePaymentModel> filteredItems = const <PurchasePaymentModel>[];
  List<FinancialYearModel> financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<PartyModel> suppliers = const <PartyModel>[];
  List<AccountModel> accounts = const <AccountModel>[];
  List<PurchaseInvoiceModel> invoices = const <PurchaseInvoiceModel>[];
  PurchasePaymentModel? selectedItem;
  Map<String, dynamic>? purchaseChain;
  int? contextCompanyId;
  int? contextBranchId;
  int? contextLocationId;
  int? contextFinancialYearId;
  int? companyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? documentSeriesId;
  int? supplierPartyId;
  int? accountId;
  bool isActive = true;
  List<PaymentAllocationDraft> allocations = <PaymentAllocationDraft>[];
  int persistedAllocationCount = 0;
  bool _paidAmountManuallyEdited = false;
  bool _syncingPaidAmountController = false;

  bool _initialized = false;

  bool get canEditSelectedPayment {
    if (selectedItem == null) {
      return true;
    }
    return purchaseDocumentIsDraftEditable(
      stringValue(selectedItem!.toJson(), 'payment_status'),
    );
  }

  bool get isSelectedPaymentReadOnly =>
      selectedItem != null && !canEditSelectedPayment;

  double get remainingUnallocatedAmount =>
      Validators.parseFlexibleNumber(
        selectedItem?.toJson()['unallocated_amount']?.toString(),
      ) ??
      0;

  bool get canAllocateRemainingAdvance {
    final status = stringValue(
      selectedItem?.toJson() ?? const <String, dynamic>{},
      'payment_status',
    );
    return selectedItem != null &&
        (status == 'posted' || status == 'partially_allocated') &&
        remainingUnallocatedAmount > 0;
  }

  bool isPersistedAllocation(int index) => index < persistedAllocationCount;

  List<PaymentAllocationDraft> get newRemainingAllocations =>
      allocations.skip(persistedAllocationCount).toList(growable: false);

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applyFilters);
    dateFromController.addListener(_applyFilters);
    dateToController.addListener(_applyFilters);
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
    dateFromController
      ..removeListener(_applyFilters)
      ..dispose();
    dateToController
      ..removeListener(_applyFilters)
      ..dispose();
    paymentNoController.dispose();
    paymentDateController.dispose();
    referenceNoController.dispose();
    referenceDateController.dispose();
    paidAmountController.dispose();
    notesController.dispose();
    _disposeAllocations(allocations);
    super.onClose();
  }

  Future<void> initialize({
    int? initialId,
    int? initialPurchaseInvoiceId,
  }) async {
    if (!_initialized) {
      _initialized = true;
    }
    await loadPage(
      selectId: initialId,
      initialPurchaseInvoiceId: initialPurchaseInvoiceId,
    );
    _refreshController.notifyChanged(source: 'purchase_payment');
  }

  Future<void> _handleWorkingContextChanged() async {
    await loadPage(
      selectId: intValue(selectedItem?.toJson() ?? const {}, 'id'),
    );
    _refreshController.notifyChanged(source: 'purchase_payment');
  }

  Future<void> loadPage({
    int? selectId,
    int? initialPurchaseInvoiceId,
    bool editorOnly = false,
  }) async {
    initialLoading = items.isEmpty;
    pageError = null;
    update();

    try {
      await MasterDataCache.to.ensureLoaded();
      final cache = MasterDataCache.to;
      final responses = await Future.wait<dynamic>([
        _purchaseService.paymentsAll(
          filters: const {'sort_by': 'payment_date'},
        ),
        _purchaseService.invoices(
          filters: const {'per_page': 300, 'sort_by': 'invoice_date'},
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
          (responses[0] as ApiResponse<List<PurchasePaymentModel>>).data ??
          const <PurchasePaymentModel>[];
      financialYears = cache.financialYears;
      documentSeries = cache.activeDocumentSeries;
      suppliers = purchaseSuppliers(
        parties: cache.parties,
        partyTypes: cache.partyTypes,
      );
      accounts = cache.activeAccounts;
      invoices =
          (responses[1] as PaginatedResponse<PurchaseInvoiceModel>).data ??
          const <PurchaseInvoiceModel>[];
      contextCompanyId = contextSelection.companyId;
      contextBranchId = contextSelection.branchId;
      contextLocationId = contextSelection.locationId;
      contextFinancialYearId = contextSelection.financialYearId;
      initialLoading = false;
      filteredItems = _filterItems(items, searchController.text, statusFilter);
      update();

      final selected = selectId != null
          ? items.cast<PurchasePaymentModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : null;
      if (selected == null && selectId != null) {
        try {
          final detail = (await _purchaseService.payment(selectId)).data;
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
        if (initialPurchaseInvoiceId != null) {
          await bootstrapNewPaymentFromInvoice(initialPurchaseInvoiceId);
        }
      }
      update();
    } catch (errorValue) {
      pageError = errorValue.toString();
      initialLoading = false;
      update();
    }
  }

  Future<void> selectDocument(
    PurchasePaymentModel item, {
    bool notify = true,
  }) async {
    final id = intValue(item.toJson(), 'id');
    if (id == null) return;
    final response = await _purchaseService.payment(id);
    final full = response.data ?? item;
    final data = full.toJson();
    final nextAllocations =
        (data['allocations'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(PaymentAllocationDraft.fromJson)
            .toList(growable: true);
    selectedItem = full;
    companyId = intValue(data, 'company_id');
    branchId = intValue(data, 'branch_id');
    locationId = intValue(data, 'location_id');
    financialYearId = intValue(data, 'financial_year_id');
    documentSeriesId = intValue(data, 'document_series_id');
    supplierPartyId = intValue(data, 'supplier_party_id');
    accountId = intValue(data, 'account_id');
    paymentMode = stringValue(data, 'payment_mode', 'bank');
    paymentNoController.text = stringValue(data, 'payment_no');
    paymentDateController.text = displayDate(
      nullableStringValue(data, 'payment_date'),
    );
    referenceNoController.text = stringValue(data, 'reference_no');
    referenceDateController.text = displayDate(
      nullableStringValue(data, 'reference_date'),
    );
    paidAmountController.text = _positivePaymentAmountText(
      Validators.parseFlexibleNumber(data['paid_amount']?.toString()),
    );
    _paidAmountManuallyEdited = false;
    notesController.text = stringValue(data, 'notes');
    isActive = boolValue(data, 'is_active', fallback: true);
    _replaceAllocations(nextAllocations, notify: false);
    persistedAllocationCount = nextAllocations.length;
    formError = null;
    _upsertPayment(full, notify: false);
    await refreshPurchaseChain(notify: false);
    if (notify) update();
  }

  Future<void> refreshPurchaseChain({bool notify = true}) async {
    final id = selectedItem?.id;
    if (id == null) {
      purchaseChain = null;
      if (notify) update();
      return;
    }

    try {
      final response = await _purchaseService.purchaseChain(paymentId: id);
      purchaseChain = response.data;
    } catch (_) {
      purchaseChain = null;
    }

    if (notify) update();
  }

  void resetForm({bool notify = true}) {
    final series = seriesOptions();
    _replaceAllocations(const <PaymentAllocationDraft>[], notify: false);
    persistedAllocationCount = 0;
    selectedItem = null;
    purchaseChain = null;
    companyId = contextCompanyId;
    branchId = contextBranchId;
    locationId = contextLocationId;
    financialYearId = contextFinancialYearId;
    documentSeriesId = series.isNotEmpty ? series.first.id : null;
    supplierPartyId = null;
    accountId = null;
    paymentMode = 'bank';
    paymentNoController.clear();
    paymentDateController.text = displayTodayDate();
    referenceNoController.clear();
    referenceDateController.clear();
    paidAmountController.clear();
    _paidAmountManuallyEdited = false;
    notesController.clear();
    isActive = true;
    formError = null;
    if (notify) update();
  }

  Future<void> bootstrapNewPaymentFromInvoice(int invoiceId) async {
    try {
      final response = await _purchaseService.invoice(invoiceId);
      final invoice = response.data;
      if (invoice == null) {
        return;
      }
      final outstanding = invoiceOutstanding(invoice);
      if (outstanding <= 0) {
        formError = 'This purchase invoice has no outstanding balance to pay.';
        update();
        return;
      }
      final allocAmount = outstanding == outstanding.roundToDouble()
          ? outstanding.round().toString()
          : outstanding.appFixed();

      companyId = invoice.companyId;
      branchId = invoice.branchId;
      locationId = invoice.locationId;
      financialYearId = invoice.financialYearId;
      documentSeriesId = defaultSeriesIdFor(
        companyId: invoice.companyId,
        financialYearId: invoice.financialYearId,
      );
      supplierPartyId = invoice.supplierPartyId;
      referenceNoController.clear();
      referenceDateController.text = displayDate(invoice.invoiceDate);
      paidAmountController.text = allocAmount;
      _paidAmountManuallyEdited = false;
      notesController.text = invoice.notes ?? '';
      if (!invoices.any((entry) => entry.id == invoice.id)) {
        invoices = <PurchaseInvoiceModel>[invoice, ...invoices];
      }
      _replaceAllocations(<PaymentAllocationDraft>[
        PaymentAllocationDraft(
          purchaseInvoiceId: invoice.id,
          allocationType: 'against_invoice',
          allocatedAmount: allocAmount,
          remarks: 'Against ${invoice.invoiceNo ?? 'invoice #${invoice.id}'}',
        ),
      ], notify: false);
      formError = null;
      update();
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
    }
  }

  void setStatusFilter(String value) {
    statusFilter = value;
    _applyFilters();
  }

  List<PurchasePaymentModel> _filterItems(
    List<PurchasePaymentModel> source,
    String query,
    String status,
  ) {
    var result = filterBySearchAndStatus(
      source,
      query: query,
      status: status,
      statusOf: (item) => stringValue(item.toJson(), 'payment_status'),
      searchFieldsOf: (item) {
        final data = item.toJson();
        return <String>[
          stringValue(data, 'payment_no'),
          purchaseStatusLabel(nullableStringValue(data, 'payment_status')),
          stringValue(data, 'supplier_name'),
          stringValue(data, 'reference_no'),
        ];
      },
    );

    if (filterSupplierId != null) {
      result = result
          .where((item) => item.supplierPartyId == filterSupplierId)
          .toList();
    }

    return result.where((item) {
      return matchesDateValueRange(
        item.paymentDate,
        fromValue: dateFromController.text,
        toValue: dateToController.text,
      );
    }).toList();
  }

  void _applyFilters() {
    filteredItems = _filterItems(items, searchController.text, statusFilter);
    update();
  }

  void setFilterSupplierId(int? id) {
    filterSupplierId = id;
    _applyFilters();
  }

  void clearFilters() {
    filterSupplierId = null;
    statusFilter = '';
    searchController.clear();
    dateFromController.clear();
    dateToController.clear();
    _applyFilters();
  }

  List<DocumentSeriesModel> seriesOptions() {
    return documentSeries
        .where((item) {
          final typeOk =
              item.documentType == null ||
              item.documentType == 'PURCHASE_PAYMENT';
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
              item.documentType == 'PURCHASE_PAYMENT';
          final companyOk = companyId == null || item.companyId == companyId;
          final fyOk =
              financialYearId == null ||
              item.financialYearId == financialYearId;
          return typeOk && companyOk && fyOk;
        })
        .toList(growable: false);
    return options.isNotEmpty ? options.first.id : null;
  }

  double invoiceOutstanding(PurchaseInvoiceModel invoice) {
    final rawBalance = invoice.toJson()['balance_amount'];
    final balance = Validators.parseFlexibleNumber(rawBalance?.toString());
    if (balance != null) {
      return balance;
    }
    final rawTotal = invoice.toJson()['total_amount'];
    if (rawTotal is num) {
      return rawTotal.toDouble();
    }
    return Validators.parseFlexibleNumber(rawTotal?.toString()) ?? 0;
  }

  double totalAllocatedAmount() {
    return allocations.fold<double>(
      0,
      (sum, allocation) =>
          sum +
          (Validators.parseFlexibleNumber(allocation.amountController.text) ??
              0),
    );
  }

  void handlePaidAmountChanged() {
    if (_syncingPaidAmountController) {
      return;
    }
    _paidAmountManuallyEdited = true;
  }

  String nestedInvoiceSubtitle(PurchaseInvoiceModel invoice) {
    final supplierName =
        invoice.toJson()['supplier_name']?.toString() ??
        ((invoice.toJson()['supplier'] is Map<String, dynamic>)
            ? stringValue(
                invoice.toJson()['supplier'] as Map<String, dynamic>,
                'party_name',
              )
            : '');
    final outstanding = invoiceOutstanding(invoice);
    final parts = <String>[
      if (supplierName.trim().isNotEmpty) supplierName.trim(),
      if (outstanding > 0) 'Outstanding ${outstanding.appFixed()}',
    ];
    return parts.join(' · ');
  }

  void syncPaidAmountFromAllocations() {
    if (canAllocateRemainingAdvance) {
      update();
      return;
    }
    final total = totalAllocatedAmount();
    final current =
        Validators.parseFlexibleNumber(paidAmountController.text) ?? 0;
    final nextAmount = _paidAmountManuallyEdited ? current : total;
    _syncingPaidAmountController = true;
    paidAmountController.text = nextAmount > 0 ? nextAmount.appFixed() : '';
    _syncingPaidAmountController = false;
    update();
  }

  Future<void> handleAllocationInvoiceChanged(
    int index,
    int? purchaseInvoiceId,
  ) async {
    if (index < 0 || index >= allocations.length) return;

    if (purchaseInvoiceId == null) {
      allocations[index].purchaseInvoiceId = null;
      allocations[index].amountController.clear();
      syncPaidAmountFromAllocations();
      return;
    }

    final response = await _purchaseService.invoice(purchaseInvoiceId);
    final invoice = response.data;
    if (invoice == null) return;

    final outstanding = invoiceOutstanding(invoice);
    final paidAmount = canAllocateRemainingAdvance
        ? remainingUnallocatedAmount
        : Validators.parseFlexibleNumber(paidAmountController.text) ?? 0;
    final allocatedOnOtherLines = allocations
        .asMap()
        .entries
        .where(
          (entry) =>
              entry.key != index &&
              (!canAllocateRemainingAdvance ||
                  entry.key >= persistedAllocationCount),
        )
        .fold<double>(
          0,
          (sum, entry) =>
              sum +
              (Validators.parseFlexibleNumber(
                    entry.value.amountController.text,
                  ) ??
                  0),
        );
    final allocatedToInvoiceOnOtherLines = allocations
        .asMap()
        .entries
        .where(
          (entry) =>
              entry.key != index &&
              entry.value.purchaseInvoiceId == purchaseInvoiceId &&
              (!canAllocateRemainingAdvance ||
                  entry.key >= persistedAllocationCount),
        )
        .fold<double>(
          0,
          (sum, entry) =>
              sum +
              (Validators.parseFlexibleNumber(
                    entry.value.amountController.text,
                  ) ??
                  0),
        );
    final remainingPayment = paidAmount > 0
        ? paidAmount - allocatedOnOtherLines
        : outstanding;
    if (remainingPayment <= 0) {
      allocations[index].purchaseInvoiceId = null;
      allocations[index].amountController.clear();
      formError =
          'The full paid amount is already allocated. Increase Paid Amount or reduce another allocation.';
      update();
      return;
    }

    allocations[index].purchaseInvoiceId = purchaseInvoiceId;
    allocations[index].allocationType = 'against_invoice';
    final currentAllocated =
        Validators.parseFlexibleNumber(
          allocations[index].amountController.text,
        ) ??
        0;
    final remainingInvoice = outstanding - allocatedToInvoiceOnOtherLines;
    final maximumAllocation = remainingPayment < remainingInvoice
        ? remainingPayment
        : remainingInvoice;
    final nextAllocated = currentAllocated <= 0
        ? maximumAllocation
        : (currentAllocated > maximumAllocation
              ? maximumAllocation
              : currentAllocated);
    allocations[index].amountController.text = nextAllocated > 0
        ? nextAllocated.appFixed()
        : '';
    companyId = invoice.companyId;
    branchId = invoice.branchId;
    locationId = invoice.locationId;
    financialYearId = invoice.financialYearId;
    documentSeriesId = defaultSeriesIdFor(
      companyId: invoice.companyId,
      financialYearId: invoice.financialYearId,
    );
    supplierPartyId = invoice.supplierPartyId;
    referenceDateController.text = referenceDateController.text.trim().isEmpty
        ? displayDate(invoice.invoiceDate)
        : referenceDateController.text;
    notesController.text = notesController.text.trim().isEmpty
        ? (invoice.notes ?? '')
        : notesController.text;
    syncPaidAmountFromAllocations();
    formError = null;
    update();
  }

  List<PurchaseInvoiceModel> get invoiceOptions => invoices
      .where(
        (invoice) =>
            (supplierPartyId == null ||
                invoice.supplierPartyId == supplierPartyId) &&
            invoice.companyId == companyId,
      )
      .toList(growable: false);

  List<PurchaseInvoiceModel> invoiceOptionsForAllocation(int index) {
    final currentInvoiceId = index >= 0 && index < allocations.length
        ? allocations[index].purchaseInvoiceId
        : null;
    return invoiceOptions
        .where((invoice) {
          final id = invoice.id;
          if (id == null) {
            return false;
          }
          if (id == currentInvoiceId) {
            return true;
          }
          final status = (invoice.invoiceStatus ?? '').toLowerCase();
          return const <String>{
                'posted',
                'overdue',
                'partially_paid',
                'partially_returned',
              }.contains(status) &&
              invoiceOutstanding(invoice) > 0;
        })
        .toList(growable: false);
  }

  void addAllocation() {
    if (isSelectedPaymentReadOnly && !canAllocateRemainingAdvance) {
      return;
    }
    final newlyAllocated = newRemainingAllocations.fold<double>(
      0,
      (sum, item) =>
          sum +
          (Validators.parseFlexibleNumber(item.amountController.text) ?? 0),
    );
    if (canAllocateRemainingAdvance &&
        newlyAllocated >= remainingUnallocatedAmount) {
      formError = 'The remaining advance is already fully allocated.';
      update();
      return;
    }
    allocations = List<PaymentAllocationDraft>.from(allocations)
      ..add(PaymentAllocationDraft());
    syncPaidAmountFromAllocations();
  }

  Future<void> autoAllocateOldestInvoices() async {
    if (isSelectedPaymentReadOnly || autoAllocating) {
      return;
    }
    if (allocations.isNotEmpty) {
      formError =
          'Remove the existing allocation lines before using Auto Allocate.';
      update();
      return;
    }

    final selectedCompanyId = companyId;
    final selectedSupplierId = supplierPartyId;
    final paidAmount =
        Validators.parseFlexibleNumber(paidAmountController.text) ?? 0;
    if (selectedCompanyId == null) {
      formError = 'Select a company context before auto allocation.';
      update();
      return;
    }
    if (selectedSupplierId == null) {
      formError = 'Select a supplier before auto allocation.';
      update();
      return;
    }
    if (paidAmount <= 0) {
      formError =
          'Enter a paid amount greater than zero before auto allocation.';
      update();
      return;
    }

    autoAllocating = true;
    formError = null;
    update();
    try {
      final response = await _purchaseService.previewPaymentAutoAllocation(
        companyId: selectedCompanyId,
        supplierPartyId: selectedSupplierId,
        paidAmount: paidAmount,
      );
      final data = response.data ?? const <String, dynamic>{};
      final previewLines = (data['allocations'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (line) => PaymentAllocationDraft.fromJson(
              Map<String, dynamic>.from(line),
            ),
          )
          .toList(growable: true);
      if (previewLines.isEmpty) {
        formError = 'No outstanding purchase invoices were found.';
      } else {
        _replaceAllocations(previewLines, notify: false);
        final allocated =
            Validators.parseFlexibleNumber(
              data['allocated_amount']?.toString(),
            ) ??
            0;
        final unallocated =
            Validators.parseFlexibleNumber(
              data['unallocated_amount']?.toString(),
            ) ??
            0;
        _showMessage(
          'Allocated ${allocated.appFixed()} to the oldest invoices. ${unallocated.appFixed()} remains on account.',
        );
      }
    } catch (errorValue) {
      formError = errorValue.toString();
    } finally {
      autoAllocating = false;
      update();
    }
  }

  void removeAllocation(int index) {
    if (isPersistedAllocation(index)) {
      return;
    }
    final updated = List<PaymentAllocationDraft>.from(allocations);
    final removed = updated.removeAt(index);
    allocations = updated;
    syncPaidAmountFromAllocations();
    disposeDraftEntriesNextFrame<PaymentAllocationDraft>([
      removed,
    ], (entry) => entry.dispose());
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

  Future<List<ErpLinkFieldOption<int>>> searchSupplierOptions(String query) =>
      searchPartyLinkOptions(
        service: _partiesService,
        query: query,
        currentRoleParties: suppliers,
        onDiscovered: (party) {
          if (!suppliers.any((item) => item.id == party.id)) {
            suppliers = <PartyModel>[...suppliers, party];
          }
        },
      );

  void setSupplierPartyId(int? value) {
    if (supplierPartyId != value && allocations.isNotEmpty) {
      _replaceAllocations(const <PaymentAllocationDraft>[], notify: false);
      syncPaidAmountFromAllocations();
      formError =
          'Existing allocations were cleared because the supplier changed.';
    }
    supplierPartyId = value;
    update();
  }

  void setPaymentMode(String value) {
    paymentMode = value;
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

  void setAllocationType(PaymentAllocationDraft allocation, String value) {
    allocation.allocationType = value;
    if (value == 'advance' || value == 'on_account') {
      allocation.purchaseInvoiceId = null;
    }
    update();
  }

  void _showMessage(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final messenger = appScaffoldMessengerKey.currentState;
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(trimmed)));
  }

  Future<void> save(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!formKey.currentState!.validate()) return;
    final paidAmount =
        Validators.parseFlexibleNumber(paidAmountController.text) ?? 0;
    final totalAllocated = totalAllocatedAmount();
    if (paidAmount <= 0) {
      formError = 'Paid amount must be greater than zero.';
      update();
      return;
    }
    if (allocations.isNotEmpty && paidAmount < totalAllocated) {
      formError = 'Paid amount cannot be less than the total allocated amount.';
      update();
      return;
    }
    final allocatedByInvoice = <int, double>{};
    for (var index = 0; index < allocations.length; index++) {
      final allocation = allocations[index];
      final lineNumber = index + 1;
      final allocatedAmount =
          Validators.parseFlexibleNumber(allocation.amountController.text) ?? 0;
      if (allocatedAmount <= 0) {
        formError = 'Allocation line $lineNumber must have an amount.';
        update();
        return;
      }

      final requiresInvoice =
          allocation.allocationType == 'against_invoice' ||
          allocation.allocationType == 'adjustment';
      final invoiceId = allocation.purchaseInvoiceId;
      if (requiresInvoice && invoiceId == null) {
        formError = 'Select an invoice for allocation line $lineNumber.';
        update();
        return;
      }
      if (!requiresInvoice && invoiceId != null) {
        formError =
            'Allocation line $lineNumber cannot contain an invoice for ${allocation.allocationType.replaceAll('_', ' ')}.';
        update();
        return;
      }
      if (invoiceId != null) {
        allocatedByInvoice[invoiceId] =
            (allocatedByInvoice[invoiceId] ?? 0) + allocatedAmount;
      }
    }
    for (final entry in allocatedByInvoice.entries) {
      final invoice = invoices.cast<PurchaseInvoiceModel?>().firstWhere(
        (item) => item?.id == entry.key,
        orElse: () => null,
      );
      if (invoice != null &&
          roundToDouble(entry.value, 2) >
              roundToDouble(invoiceOutstanding(invoice), 2)) {
        formError =
            'Total allocation for ${invoice.invoiceNo ?? 'invoice'} cannot exceed its outstanding amount.';
        update();
        return;
      }
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
      'payment_no': nullIfEmpty(paymentNoController.text),
      'payment_date': paymentDateController.text.trim(),
      'supplier_party_id': supplierPartyId,
      'payment_mode': paymentMode,
      'account_id': accountId,
      'reference_no': nullIfEmpty(referenceNoController.text),
      'reference_date': nullIfEmpty(referenceDateController.text),
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
          ? await _purchaseService.createPayment(
              PurchasePaymentModel.fromJson(normalizeDatePayload(payload)),
            )
          : await _purchaseService.updatePayment(
              intValue(selectedItem!.toJson(), 'id')!,
              PurchasePaymentModel.fromJson(normalizeDatePayload(payload)),
            );
      _showMessage(response.message);
      final saved = response.data;
      if (saved != null) {
        _upsertPayment(saved);
        await selectDocument(saved, notify: false);
        _refreshController.notifyChanged(source: 'purchase_payment');
        update();
      } else {
        await loadPage(
          selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
        );
        _refreshController.notifyChanged(source: 'purchase_payment');
      }
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  DocumentPrintDataModel purchasePaymentPrintData() {
    final companies = MasterDataCache.to.activeCompanies;
    final company = companies.cast<CompanyModel?>().firstWhere(
      (item) => item?.id == companyId,
      orElse: () => null,
    );
    final supplier = suppliers.cast<PartyModel?>().firstWhere(
      (item) => item?.id == supplierPartyId,
      orElse: () => null,
    );
    final address = supplier?.addresses.cast<PartyAddressModel?>().firstWhere(
      (item) => item?.isActive == true && item?.isDefault == true,
      orElse: () => supplier.addresses.cast<PartyAddressModel?>().firstWhere(
        (item) => item?.isActive == true,
        orElse: () => null,
      ),
    );
    final gst = supplier?.gstDetails.cast<PartyGstDetailModel?>().firstWhere(
      (item) => item?.isActive != false && item?.isDefault == true,
      orElse: () => null,
    );
    final paidAmount =
        Validators.parseFlexibleNumber(paidAmountController.text) ?? 0;
    final printLines = allocations.indexed
        .map((entry) {
          final index = entry.$1;
          final allocation = entry.$2;
          final invoice = invoices.cast<PurchaseInvoiceModel?>().firstWhere(
            (item) => item?.id == allocation.purchaseInvoiceId,
            orElse: () => null,
          );
          final amount =
              Validators.parseFlexibleNumber(
                allocation.amountController.text,
              ) ??
              0;
          return DocumentPrintLineModel(
            lineNo: index + 1,
            itemName:
                allocation.purchaseInvoiceNo ??
                invoice?.invoiceNo ??
                'Advance / Unallocated',
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
      documentNumber: paymentNoController.text.trim().isEmpty
          ? 'Draft'
          : paymentNoController.text.trim(),
      documentDate: paymentDateController.text.trim(),
      referenceNumber: referenceNoController.text.trim(),
      partyName: supplier?.displayName ?? supplier?.partyName ?? 'Not provided',
      partyAddress: formatPartyAddress(address),
      partyContact: resolvePartyContact(supplier),
      partyGstin: gst?.gstin ?? '',
      notes: notesController.text.trim(),
      subtotal: paidAmount,
      taxAmount: 0,
      totalAmount: paidAmount,
      currencyCode: 'INR',
      lines: printLines,
      extraData: <String, dynamic>{
        'payment_mode': paymentMode,
        'reference_date': referenceDateController.text.trim(),
        if (stringValue(selectedItem?.toJson() ?? const {}, 'payment_status') ==
            'draft')
          'watermark_text': 'DRAFT',
      },
    );
  }

  Future<void> openPrintPreview(BuildContext context) {
    final canOutput =
        stringValue(selectedItem?.toJson() ?? const {}, 'payment_status') !=
        'draft';
    return openManagedDocumentPrintPreview(
      context,
      documentType: 'purchase_payment',
      title: 'Purchase Payment',
      documentDataBuilder: purchasePaymentPrintData,
      documentId: selectedItem?.id,
      companyId: companyId,
      allowPrint: canOutput,
      allowDownload: canOutput,
      allowTemplateEditing: true,
    );
  }

  Future<void> saveRemainingAllocations(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final paymentId = intValue(
      selectedItem?.toJson() ?? const <String, dynamic>{},
      'id',
    );
    final newLines = newRemainingAllocations;
    if (paymentId == null || !canAllocateRemainingAdvance) {
      return;
    }
    if (newLines.isEmpty) {
      formError = 'Add at least one invoice allocation.';
      update();
      return;
    }

    final allocatedByInvoice = <int, double>{};
    var total = 0.0;
    for (var index = 0; index < newLines.length; index++) {
      final line = newLines[index];
      final lineNo = index + 1;
      final amount =
          Validators.parseFlexibleNumber(line.amountController.text) ?? 0;
      if (line.purchaseInvoiceId == null) {
        formError = 'Select an invoice for new allocation line $lineNo.';
        update();
        return;
      }
      if (amount <= 0) {
        formError = 'Enter an amount for new allocation line $lineNo.';
        update();
        return;
      }
      allocatedByInvoice[line.purchaseInvoiceId!] =
          (allocatedByInvoice[line.purchaseInvoiceId!] ?? 0) + amount;
      total += amount;
    }
    for (final entry in allocatedByInvoice.entries) {
      final invoice = invoices.cast<PurchaseInvoiceModel?>().firstWhere(
        (item) => item?.id == entry.key,
        orElse: () => null,
      );
      if (invoice != null &&
          roundToDouble(entry.value, 2) >
              roundToDouble(invoiceOutstanding(invoice), 2)) {
        formError =
            'Total allocation for ${invoice.invoiceNo ?? 'invoice'} cannot exceed its outstanding amount.';
        update();
        return;
      }
    }
    if (roundToDouble(total, 2) >
        roundToDouble(remainingUnallocatedAmount, 2)) {
      formError =
          'Total allocation cannot exceed the remaining advance of ${remainingUnallocatedAmount.appFixed()}.';
      update();
      return;
    }

    saving = true;
    formError = null;
    update();
    try {
      final response = await _purchaseService.allocateRemainingPayment(
        paymentId,
        newLines.map((line) => line.toJson()).toList(growable: false),
      );
      _showMessage(response.message);
      final updated = response.data;
      if (updated != null) {
        _upsertPayment(updated);
        await selectDocument(updated, notify: false);
      } else {
        await loadPage(selectId: paymentId);
      }
      _refreshController.notifyChanged(source: 'purchase_payment');
    } catch (errorValue) {
      formError = errorValue.toString();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> docAction(
    BuildContext context,
    Future<ApiResponse<PurchasePaymentModel>> Function() action,
  ) async {
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      final response = await action();
      _showMessage(response.message);
      final updated = response.data;
      if (updated != null) {
        _upsertPayment(updated);
        await selectDocument(updated, notify: false);
        _refreshController.notifyChanged(source: 'purchase_payment');
        update();
      } else {
        await loadPage(
          selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
        );
        _refreshController.notifyChanged(source: 'purchase_payment');
      }
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
    }
  }

  void _upsertPayment(PurchasePaymentModel payment, {bool notify = true}) {
    final id = intValue(payment.toJson(), 'id');
    if (id == null) {
      return;
    }
    final nextItems = List<PurchasePaymentModel>.from(items);
    final existingIndex = nextItems.indexWhere(
      (item) => intValue(item.toJson(), 'id') == id,
    );
    if (existingIndex >= 0) {
      nextItems[existingIndex] = payment;
    } else {
      nextItems.insert(0, payment);
    }
    items = nextItems;
    if (notify) {
      _applyFilters();
    } else {
      filteredItems = _filterItems(items, searchController.text, statusFilter);
    }
  }

  void _disposeAllocations(List<PaymentAllocationDraft> entries) {
    for (final allocation in entries) {
      allocation.dispose();
    }
  }

  void _replaceAllocations(
    List<PaymentAllocationDraft> nextAllocations, {
    bool notify = true,
  }) {
    final previous = allocations;
    allocations = List<PaymentAllocationDraft>.from(nextAllocations);
    disposeDraftEntriesNextFrame<PaymentAllocationDraft>(
      previous,
      (allocation) => allocation.dispose(),
    );
    if (notify) {
      update();
    }
  }
}
