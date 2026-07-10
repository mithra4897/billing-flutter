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
    );
  }

  int? purchaseInvoiceId;
  String allocationType;
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
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final AccountsService _accountsService = AccountsService();
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
      final responses = await Future.wait<dynamic>([
        _purchaseService.paymentsAll(
          filters: const {'sort_by': 'payment_date'},
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
          filters: const {'per_page': 300, 'sort_by': 'party_name'},
        ),
        _accountsService.accountsAll(
          filters: const {'sort_by': 'account_name'},
        ),
        _purchaseService.invoices(
          filters: const {'per_page': 300, 'sort_by': 'invoice_date'},
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
          (responses[0] as ApiResponse<List<PurchasePaymentModel>>).data ??
          const <PurchasePaymentModel>[];
      financialYears =
          (responses[4] as PaginatedResponse<FinancialYearModel>).data ??
          const <FinancialYearModel>[];
      documentSeries =
          ((responses[5] as PaginatedResponse<DocumentSeriesModel>).data ??
                  const <DocumentSeriesModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      suppliers = purchaseSuppliers(
        parties:
            (responses[7] as PaginatedResponse<PartyModel>).data ??
            const <PartyModel>[],
        partyTypes:
            (responses[6] as PaginatedResponse<PartyTypeModel>).data ??
            const <PartyTypeModel>[],
      );
      accounts =
          ((responses[8] as ApiResponse<List<AccountModel>>).data ??
                  const <AccountModel>[])
              .where((item) => item.isActive)
              .toList(growable: false);
      invoices =
          (responses[9] as PaginatedResponse<PurchaseInvoiceModel>).data ??
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
    final total = totalAllocatedAmount();
    final current =
        Validators.parseFlexibleNumber(paidAmountController.text) ?? 0;
    final nextAmount = _paidAmountManuallyEdited && current > total
        ? current
        : total;
    _syncingPaidAmountController = true;
    paidAmountController.text = nextAmount > 0
        ? nextAmount.appFixed()
        : '';
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
    allocations[index].purchaseInvoiceId = purchaseInvoiceId;
    allocations[index].allocationType = 'against_invoice';
    final currentAllocated =
        Validators.parseFlexibleNumber(
          allocations[index].amountController.text,
        ) ??
        0;
    final nextAllocated = currentAllocated <= 0
        ? outstanding
        : (currentAllocated > outstanding ? outstanding : currentAllocated);
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

  void addAllocation() {
    allocations = List<PaymentAllocationDraft>.from(allocations)
      ..add(PaymentAllocationDraft());
    syncPaidAmountFromAllocations();
  }

  void removeAllocation(int index) {
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

  void setSupplierPartyId(int? value) {
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
