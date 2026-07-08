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
    );
  }

  int? salesInvoiceId;
  String allocationType;
  final TextEditingController amountController;
  final TextEditingController remarksController;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sales_invoice_id': salesInvoiceId,
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
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final AccountsService _accountsService = AccountsService();
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
    isDirectCustomer = false;
    accountId = null;
    paymentMode = 'bank';
    receiptNoController.clear();
    receiptDateController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    paymentReferenceNoController.clear();
    paymentReferenceDateController.clear();
    directCustomerDetailsController.clear();
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

  List<SalesInvoiceModel> get invoiceOptions => invoices
      .where((invoice) {
        if (invoice.companyId != companyId) {
          return false;
        }
        if (isDirectCustomer) {
          return invoice.isDirectCustomer;
        }
        return !invoice.isDirectCustomer &&
            (customerPartyId == null || invoice.customerPartyId == customerPartyId);
      })
      .toList(growable: false);

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

  void syncPaidAmountFromAllocations({bool notify = true}) {
    if (allocations.isEmpty) {
      if (notify) {
        update();
      }
      return;
    }
    final total = allocations.fold<double>(0, (sum, allocation) {
      return sum +
          (Validators.parseFlexibleNumber(allocation.amountController.text) ??
              0);
    });
    paidAmountController.text = total <= 0 ? '' : formatReceiptAmount(total);
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

  void setDirectCustomer(bool value) {
    isDirectCustomer = value;
    if (value) {
      customerPartyId = null;
      directCustomerDetailsController.text =
          directCustomerDetailsController.text.trim();
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
    allocations = List<SalesReceiptAllocationDraft>.from(allocations)
      ..add(SalesReceiptAllocationDraft());
    update();
  }

  void removeAllocation(int index) {
    final nextAllocations = List<SalesReceiptAllocationDraft>.from(allocations);
    final removed = nextAllocations.removeAt(index);
    allocations = nextAllocations;
    syncPaidAmountFromAllocations();
    disposeDraftEntriesNextFrame<SalesReceiptAllocationDraft>([
      removed,
    ], (entry) => entry.dispose());
  }

  void setAllocationSalesInvoiceId(int index, int? value) {
    final allocation = allocations[index];
    allocation.salesInvoiceId = value;
    final invoice = invoiceById(value);
    final balance = invoiceOutstandingAmount(invoice);
    allocation.amountController.text = balance <= 0
        ? ''
        : formatReceiptAmount(balance);
    if ((allocation.remarksController.text).trim().isEmpty && invoice != null) {
      allocation.remarksController.text =
          'Against ${invoice.invoiceNo ?? 'invoice #${invoice.id}'}';
    }
    syncPaidAmountFromAllocations(notify: false);
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
    if ((Validators.parseFlexibleNumber(paidAmountController.text) ?? 0) <= 0) {
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
      'is_direct_customer': isDirectCustomer,
      'direct_customer_details': directCustomerDetails,
      'payment_mode': paymentMode,
      'account_id': accountId,
      'payment_reference_no': nullIfEmpty(paymentReferenceNoController.text),
      'payment_reference_date': nullIfEmpty(
        paymentReferenceDateController.text,
      ),
      'paid_amount':
          Validators.parseFlexibleNumber(paidAmountController.text) ?? 0,
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
    syncPaidAmountFromAllocations(notify: false);
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
    syncPaidAmountFromAllocations(notify: false);
    disposeDraftEntriesNextFrame<SalesReceiptAllocationDraft>(
      removedAllocations,
      (allocation) => allocation.dispose(),
    );
  }
}
