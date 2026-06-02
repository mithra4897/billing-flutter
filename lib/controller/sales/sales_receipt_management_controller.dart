import '../../screen.dart';
import '../../helper/sales_register_reload_helper.dart';

class SalesReceiptAllocationDraft {
  SalesReceiptAllocationDraft({
    this.salesInvoiceId,
    this.allocationType = 'against_invoice',
    String? allocatedAmount,
    String? remarks,
  }) : amountController = TextEditingController(text: allocatedAmount ?? ''),
       remarksController = TextEditingController(text: remarks ?? '');

  factory SalesReceiptAllocationDraft.fromJson(Map<String, dynamic> json) {
    return SalesReceiptAllocationDraft(
      salesInvoiceId: intValue(json, 'sales_invoice_id'),
      allocationType: stringValue(json, 'allocation_type', 'against_invoice'),
      allocatedAmount: stringValue(json, 'allocated_amount'),
      remarks: stringValue(json, 'remarks'),
    );
  }

  int? salesInvoiceId;
  String allocationType;
  final TextEditingController amountController;
  final TextEditingController remarksController;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sales_invoice_id': salesInvoiceId,
      'allocated_amount': double.tryParse(amountController.text.trim()) ?? 0,
      'allocation_type': allocationType,
      'remarks': nullIfEmpty(remarksController.text),
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
        AppDropdownItem(value: 'posted', label: 'Posted'),
        AppDropdownItem(
          value: 'partially_allocated',
          label: 'Partially Allocated',
        ),
        AppDropdownItem(value: 'fully_allocated', label: 'Fully Allocated'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  final SalesService _salesService = SalesService();
  final CrmService _crmService = CrmService();
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final AccountsService _accountsService = AccountsService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController receiptNoController = TextEditingController();
  final TextEditingController receiptDateController = TextEditingController();
  final TextEditingController paymentReferenceNoController =
      TextEditingController();
  final TextEditingController paymentReferenceDateController =
      TextEditingController();
  final TextEditingController paidAmountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
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
  bool isActive = true;
  Map<String, dynamic>? salesChain;
  List<SalesReceiptAllocationDraft> allocations =
      <SalesReceiptAllocationDraft>[];

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
    receiptNoController.dispose();
    receiptDateController.dispose();
    paymentReferenceNoController.dispose();
    paymentReferenceDateController.dispose();
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
      final responses = await Future.wait<dynamic>([
        _salesService.receipts(
          filters: const {'per_page': 200, 'sort_by': 'receipt_date'},
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
        _salesService.invoices(
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
          (responses[9] as PaginatedResponse<SalesInvoiceModel>).data ??
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
    customerPartyId = intValue(data, 'customer_party_id');
    accountId = intValue(data, 'account_id');
    paymentMode = stringValue(data, 'payment_mode', 'bank');
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
    paidAmountController.text = stringValue(data, 'paid_amount', '0');
    notesController.text = stringValue(data, 'notes');
    isActive = boolValue(data, 'is_active', fallback: true);
    _replaceAllocations(nextAllocations, notify: false);
    formError = null;
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
    accountId = null;
    paymentMode = 'bank';
    receiptNoController.clear();
    receiptDateController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    paymentReferenceNoController.clear();
    paymentReferenceDateController.clear();
    paidAmountController.clear();
    notesController.clear();
    isActive = true;
    _replaceAllocations(const <SalesReceiptAllocationDraft>[], notify: false);
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
          double.tryParse(data['balance_amount']?.toString() ?? '') ?? 0;
      if (balance <= 0) {
        formError = 'This invoice has no outstanding balance to receive.';
        update();
        return;
      }
      final allocationAmount = balance == balance.roundToDouble()
          ? balance.round().toString()
          : balance.toStringAsFixed(2);
      companyId = invoice.companyId;
      branchId = invoice.branchId;
      locationId = invoice.locationId;
      financialYearId = invoice.financialYearId;
      final series = seriesOptions();
      documentSeriesId =
          invoice.documentSeriesId ??
          (series.isNotEmpty ? series.first.id : null);
      customerPartyId = invoice.customerPartyId;
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
      formError = null;
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
    );
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

  List<SalesInvoiceModel> get invoiceOptions => invoices
      .where((invoice) {
        return (customerPartyId == null ||
                invoice.customerPartyId == customerPartyId) &&
            invoice.companyId == companyId;
      })
      .toList(growable: false);

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
    allocations = List<SalesReceiptAllocationDraft>.from(allocations)
      ..add(SalesReceiptAllocationDraft());
    update();
  }

  void removeAllocation(int index) {
    final nextAllocations = List<SalesReceiptAllocationDraft>.from(allocations);
    final removed = nextAllocations.removeAt(index);
    allocations = nextAllocations;
    update();
    disposeDraftEntriesNextFrame<SalesReceiptAllocationDraft>([
      removed,
    ], (entry) => entry.dispose());
  }

  void setAllocationSalesInvoiceId(int index, int? value) {
    allocations[index].salesInvoiceId = value;
    unawaited(refreshSalesChain(invoiceId: value));
    update();
  }

  void setAllocationType(int index, String? value) {
    allocations[index].allocationType = value ?? 'against_invoice';
    update();
  }

  Future<void> save(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    if ((double.tryParse(paidAmountController.text.trim()) ?? 0) <= 0) {
      formError = 'Paid amount must be greater than zero.';
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
      'payment_mode': paymentMode,
      'account_id': accountId,
      'payment_reference_no': nullIfEmpty(paymentReferenceNoController.text),
      'payment_reference_date': nullIfEmpty(
        paymentReferenceDateController.text,
      ),
      'paid_amount': double.tryParse(paidAmountController.text.trim()) ?? 0,
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
              SalesReceiptModel.fromJson(payload),
            )
          : await _salesService.updateReceipt(
              intValue(selectedItem!.toJson(), 'id')!,
              SalesReceiptModel.fromJson(payload),
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
      reloadSalesReceiptRegister();
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
      reloadSalesReceiptRegister();
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

  Future<void> cancelSelected(BuildContext context) async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) {
      return;
    }
    await docAction(
      context,
      () => _salesService.cancelReceipt(
        id,
        SalesReceiptModel.fromJson(const <String, dynamic>{}),
      ),
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
        allocations.cast<SalesReceiptAllocationDraft?>().firstWhere(
              (allocation) => allocation?.salesInvoiceId != null,
              orElse: () => null,
            )?.salesInvoiceId;
    try {
      if (receiptId != null) {
        final response = await _crmService.salesChain(receiptId: receiptId);
        salesChain = response.data;
      } else if (sourceInvoiceId != null) {
        final response = await _crmService.salesChain(invoiceId: sourceInvoiceId);
        salesChain = response.data;
      } else {
        salesChain = null;
      }
    } catch (_) {
      salesChain = null;
    }
    update();
  }
}
