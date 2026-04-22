import '../../model/sales/sales_receipt_model.dart';
import '../../screen.dart';
import '../purchase/purchase_support.dart';
import 'sales_support.dart';

class SalesReceiptPage extends StatefulWidget {
  const SalesReceiptPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
    this.initialSalesInvoiceId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;
  /// From `/sales/receipts/new?invoice_id=…` — prefills customer, amount, allocation.
  final int? initialSalesInvoiceId;

  @override
  State<SalesReceiptPage> createState() => _SalesReceiptPageState();
}

class _SalesReceiptPageState extends State<SalesReceiptPage> {
  static const List<AppDropdownItem<String>> _statusItems =
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
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final AccountsService _accountsService = AccountsService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _receiptNoController = TextEditingController();
  final TextEditingController _receiptDateController = TextEditingController();
  final TextEditingController _paymentReferenceNoController =
      TextEditingController();
  final TextEditingController _paymentReferenceDateController =
      TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  String _statusFilter = '';
  String _paymentMode = 'bank';
  List<SalesReceiptModel> _items = const <SalesReceiptModel>[];
  List<SalesReceiptModel> _filteredItems = const <SalesReceiptModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<BranchModel> _branches = const <BranchModel>[];
  List<BusinessLocationModel> _locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> _financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> _documentSeries = const <DocumentSeriesModel>[];
  List<PartyModel> _customers = const <PartyModel>[];
  List<AccountModel> _accounts = const <AccountModel>[];
  List<SalesInvoiceModel> _invoices = const <SalesInvoiceModel>[];
  SalesReceiptModel? _selectedItem;
  int? _contextCompanyId;
  int? _contextBranchId;
  int? _contextLocationId;
  int? _contextFinancialYearId;
  int? _companyId;
  int? _branchId;
  int? _locationId;
  int? _financialYearId;
  int? _documentSeriesId;
  int? _customerPartyId;
  int? _accountId;
  bool _isActive = true;
  List<_SalesReceiptAllocationDraft> _allocations =
      <_SalesReceiptAllocationDraft>[];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    _loadPage(selectId: widget.initialId);
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _receiptNoController.dispose();
    _receiptDateController.dispose();
    _paymentReferenceNoController.dispose();
    _paymentReferenceDateController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    for (final a in _allocations) {
      a.dispose();
    }
    super.dispose();
  }

  List<AppDropdownItem<String>> _paymentModeDropdownItems() {
    const core = <AppDropdownItem<String>>[
      AppDropdownItem(value: 'cash', label: 'Cash'),
      AppDropdownItem(value: 'bank', label: 'Bank'),
    ];
    final mode = _paymentMode.toLowerCase();
    if (mode != 'cash' && mode != 'bank') {
      final raw = _paymentMode;
      final label = raw.isEmpty
          ? 'Other (legacy)'
          : '${raw[0].toUpperCase()}${raw.length > 1 ? raw.substring(1) : ''} (legacy)';
      return <AppDropdownItem<String>>[...core, AppDropdownItem(value: raw, label: label)];
    }
    return core;
  }

  bool _accountEligibleForReceipt(AccountModel a) {
    final t = (a.accountType ?? '').toLowerCase();
    if (t != 'cash' && t != 'bank') return false;
    if (_companyId != null && a.companyId != _companyId) return false;
    final mode = _paymentMode.toLowerCase();
    if (mode == 'cash') return t == 'cash';
    if (mode == 'bank') return t == 'bank';
    return true;
  }

  List<AccountModel> get _receiptLedgerOptions =>
      _accounts.where(_accountEligibleForReceipt).toList(growable: false);

  void _clearAccountIfInvalidForReceipt() {
    final id = _accountId;
    if (id == null) return;
    if (!_receiptLedgerOptions.any((a) => a.id == id)) {
      _accountId = null;
    }
  }

  Future<void> _loadPage({int? selectId}) async {
    setState(() {
      _initialLoading = _items.isEmpty;
      _pageError = null;
    });

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

      if (!mounted) return;
      setState(() {
        _items =
            (responses[0] as PaginatedResponse<SalesReceiptModel>).data ??
            const <SalesReceiptModel>[];
        _companies =
            (responses[1] as PaginatedResponse<CompanyModel>).data ??
            const <CompanyModel>[];
        _branches =
            (responses[2] as PaginatedResponse<BranchModel>).data ??
            const <BranchModel>[];
        _locations =
            (responses[3] as PaginatedResponse<BusinessLocationModel>).data ??
            const <BusinessLocationModel>[];
        _financialYears =
            (responses[4] as PaginatedResponse<FinancialYearModel>).data ??
            const <FinancialYearModel>[];
        _documentSeries =
            ((responses[5] as PaginatedResponse<DocumentSeriesModel>).data ??
                    const <DocumentSeriesModel>[])
                .where((item) => item.isActive)
                .toList();
        _customers = salesCustomersOrFallback(
          parties:
              (responses[7] as PaginatedResponse<PartyModel>).data ??
              const <PartyModel>[],
          partyTypes:
              (responses[6] as PaginatedResponse<PartyTypeModel>).data ??
              const <PartyTypeModel>[],
        );
        _accounts =
            ((responses[8] as ApiResponse<List<AccountModel>>).data ??
                    const <AccountModel>[])
                .where((item) => item.isActive)
                .toList();
        _invoices =
            (responses[9] as PaginatedResponse<SalesInvoiceModel>).data ??
            const <SalesInvoiceModel>[];
        _contextCompanyId = contextSelection.companyId;
        _contextBranchId = contextSelection.branchId;
        _contextLocationId = contextSelection.locationId;
        _contextFinancialYearId = contextSelection.financialYearId;
        _initialLoading = false;
      });
      _applyFilters();
      final selected = selectId != null
          ? _items.cast<SalesReceiptModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : (widget.editorOnly
                ? null
                : (_selectedItem == null
                      ? (_items.isNotEmpty ? _items.first : null)
                      : null));
      if (selected != null) {
        await _selectDocument(selected);
      } else {
        _resetForm();
        final invBoot = widget.initialSalesInvoiceId;
        if (invBoot != null && widget.editorOnly) {
          await _bootstrapNewReceiptFromInvoice(invBoot);
        }
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pageError = error.toString();
        _initialLoading = false;
      });
    }
  }

  Future<void> _selectDocument(SalesReceiptModel item) async {
    final id = intValue(item.toJson(), 'id');
    if (id == null) return;
    final response = await _salesService.receipt(id);
    final full = response.data ?? item;
    final data = full.toJson();
    final allocations =
        (data['allocations'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(_SalesReceiptAllocationDraft.fromJson)
            .toList(growable: true);
    for (final a in _allocations) {
      a.dispose();
    }
    setState(() {
      _selectedItem = full;
      _companyId = intValue(data, 'company_id');
      _branchId = intValue(data, 'branch_id');
      _locationId = intValue(data, 'location_id');
      _financialYearId = intValue(data, 'financial_year_id');
      _documentSeriesId = intValue(data, 'document_series_id');
      _customerPartyId = intValue(data, 'customer_party_id');
      _accountId = intValue(data, 'account_id');
      _paymentMode = stringValue(data, 'payment_mode', 'bank');
      _receiptNoController.text = stringValue(data, 'receipt_no');
      _receiptDateController.text = displayDate(
        nullableStringValue(data, 'receipt_date'),
      );
      _paymentReferenceNoController.text =
          stringValue(data, 'payment_reference_no');
      _paymentReferenceDateController.text = displayDate(
        nullableStringValue(data, 'payment_reference_date'),
      );
      _paidAmountController.text = stringValue(data, 'paid_amount', '0');
      _notesController.text = stringValue(data, 'notes');
      _isActive = boolValue(data, 'is_active', fallback: true);
      _allocations = allocations;
      _formError = null;
    });
  }

  void _resetForm() {
    final series = _seriesOptions();
    for (final a in _allocations) {
      a.dispose();
    }
    setState(() {
      _selectedItem = null;
      _companyId = _contextCompanyId;
      _branchId = _contextBranchId;
      _locationId = _contextLocationId;
      _financialYearId = _contextFinancialYearId;
      _documentSeriesId = series.isNotEmpty ? series.first.id : null;
      _customerPartyId = null;
      _accountId = null;
      _paymentMode = 'bank';
      _receiptNoController.clear();
      _receiptDateController.text = DateTime.now()
          .toIso8601String()
          .split('T')
          .first;
      _paymentReferenceNoController.clear();
      _paymentReferenceDateController.clear();
      _paidAmountController.clear();
      _notesController.clear();
      _isActive = true;
      _allocations = <_SalesReceiptAllocationDraft>[];
      _formError = null;
    });
  }

  Future<void> _bootstrapNewReceiptFromInvoice(int invoiceId) async {
    try {
      final r = await _salesService.invoice(invoiceId);
      final inv = r.data;
      if (inv == null || !mounted) {
        return;
      }
      final data = inv.raw ?? <String, dynamic>{};
      final balance =
          double.tryParse(data['balance_amount']?.toString() ?? '') ?? 0;
      if (balance <= 0) {
        if (mounted) {
          setState(
            () => _formError =
                'This invoice has no outstanding balance to receive.',
          );
        }
        return;
      }
      final allocAmount = balance == balance.roundToDouble()
          ? balance.round().toString()
          : balance.toStringAsFixed(2);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyId = inv.companyId;
        _branchId = inv.branchId;
        _locationId = inv.locationId;
        _financialYearId = inv.financialYearId;
        final series = _seriesOptions();
        _documentSeriesId = inv.documentSeriesId ??
            (series.isNotEmpty ? series.first.id : null);
        _customerPartyId = inv.customerPartyId;
        _paidAmountController.text = allocAmount;
        if (!_invoices.any((e) => e.id == inv.id)) {
          _invoices = <SalesInvoiceModel>[inv, ..._invoices];
        }
        for (final a in _allocations) {
          a.dispose();
        }
        _allocations = <_SalesReceiptAllocationDraft>[
          _SalesReceiptAllocationDraft(
            salesInvoiceId: inv.id,
            allocationType: 'against_invoice',
            allocatedAmount: allocAmount,
            remarks: 'Against ${inv.invoiceNo ?? 'invoice #${inv.id}'}',
          ),
        ];
        _formError = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _formError = e.toString());
      }
    }
  }

  void _applyFilters() {
    final search = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredItems = _items
          .where((item) {
            final data = item.toJson();
            final statusOk =
                _statusFilter.isEmpty ||
                stringValue(data, 'receipt_status') == _statusFilter;
            final searchOk =
                search.isEmpty ||
                [
                  stringValue(data, 'receipt_no'),
                  stringValue(data, 'receipt_status'),
                  quotationCustomerLabel(data),
                  stringValue(data, 'payment_reference_no'),
                ].join(' ').toLowerCase().contains(search);
            return statusOk && searchOk;
          })
          .toList(growable: false);
    });
  }

  List<DocumentSeriesModel> _seriesOptions() {
    return _documentSeries
        .where((item) {
          final typeOk =
              item.documentType == null ||
              item.documentType == 'SALES_RECEIPT';
          final companyOk = _companyId == null || item.companyId == _companyId;
          final fyOk =
              _financialYearId == null ||
              item.financialYearId == _financialYearId;
          return typeOk && companyOk && fyOk;
        })
        .toList(growable: false);
  }

  List<BranchModel> get _branchOptions =>
      branchesForCompany(_branches, _companyId);

  List<BusinessLocationModel> get _locationOptions =>
      locationsForBranch(_locations, _branchId);

  List<SalesInvoiceModel> get _invoiceOptions => _invoices
      .where(
        (invoice) =>
            (_customerPartyId == null ||
                invoice.customerPartyId == _customerPartyId) &&
            invoice.companyId == _companyId,
      )
      .toList(growable: false);

  void _addAllocation() {
    setState(() {
      _allocations = List<_SalesReceiptAllocationDraft>.from(_allocations)
        ..add(_SalesReceiptAllocationDraft());
    });
  }

  void _removeAllocation(int index) {
    setState(() {
      final next = List<_SalesReceiptAllocationDraft>.from(_allocations);
      next.removeAt(index).dispose();
      _allocations = next;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if ((double.tryParse(_paidAmountController.text.trim()) ?? 0) <= 0) {
      setState(() => _formError = 'Paid amount must be greater than zero.');
      return;
    }
    setState(() {
      _saving = true;
      _formError = null;
    });
    final payload = <String, dynamic>{
      'company_id': _companyId,
      'branch_id': _branchId,
      'location_id': _locationId,
      'financial_year_id': _financialYearId,
      'document_series_id': _documentSeriesId,
      'receipt_no': nullIfEmpty(_receiptNoController.text),
      'receipt_date': _receiptDateController.text.trim(),
      'customer_party_id': _customerPartyId,
      'payment_mode': _paymentMode,
      'account_id': _accountId,
      'payment_reference_no': nullIfEmpty(_paymentReferenceNoController.text),
      'payment_reference_date':
          nullIfEmpty(_paymentReferenceDateController.text),
      'paid_amount': double.tryParse(_paidAmountController.text.trim()) ?? 0,
      'notes': nullIfEmpty(_notesController.text),
      'is_active': _isActive,
      if (_allocations.isNotEmpty)
        'allocations': _allocations
            .map((item) => item.toJson())
            .toList(growable: false),
    };
    try {
      final response = _selectedItem == null
          ? await _salesService.createReceipt(SalesReceiptModel(payload))
          : await _salesService.updateReceipt(
              intValue(_selectedItem!.toJson(), 'id')!,
              SalesReceiptModel(payload),
            );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage(
        selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _docAction(
    Future<ApiResponse<SalesReceiptModel>> Function() action,
  ) async {
    try {
      final response = await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage(
        selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: () {
          _resetForm();
          if (!Responsive.isDesktop(context)) _workspaceController.openEditor();
        },
        icon: Icons.add_outlined,
        label: 'New Receipt',
      ),
    ];
    final content = _buildContent();
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'Sales Receipts',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading sales receipts...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load sales receipts',
        message: _pageError!,
        onRetry: _loadPage,
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Sales Receipts',
      editorTitle: _selectedItem == null
          ? 'New Sales Receipt'
          : stringValue(
              _selectedItem!.toJson(),
              'receipt_no',
              'Sales Receipt',
            ),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: PurchaseListCard<SalesReceiptModel>(
        items: _filteredItems,
        selectedItem: _selectedItem,
        emptyMessage: 'No sales receipts found.',
        searchController: _searchController,
        searchHint: 'Search receipts',
        statusValue: _statusFilter,
        statusItems: _statusItems,
        onStatusChanged: (value) {
          _statusFilter = value ?? '';
          _applyFilters();
        },
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'receipt_no', 'Draft Receipt'),
            subtitle: [
              displayDate(nullableStringValue(data, 'receipt_date')),
              stringValue(data, 'receipt_status'),
            ].where((value) => value.isNotEmpty).join(' · '),
            detail: quotationCustomerLabel(data),
            selected: selected,
            onTap: () => _selectDocument(item),
          );
        },
      ),
      editor: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_formError != null) ...[
              AppErrorStateView.inline(message: _formError!),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            SettingsFormWrap(
              children: [
                AppDropdownField<int>.fromMapped(
                  labelText: 'Company',
                  mappedItems: _companies
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _companyId,
                  onChanged: (value) => setState(() {
                    _companyId = value;
                    _branchId = null;
                    _locationId = null;
                    final series = _seriesOptions();
                    _documentSeriesId = series.isNotEmpty
                        ? series.first.id
                        : null;
                    _clearAccountIfInvalidForReceipt();
                  }),
                  validator: Validators.requiredSelection('Company'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Branch',
                  mappedItems: _branchOptions
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _branchId,
                  onChanged: (value) => setState(() {
                    _branchId = value;
                    _locationId = null;
                  }),
                  validator: Validators.requiredSelection('Branch'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Location',
                  mappedItems: _locationOptions
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _locationId,
                  onChanged: (value) => setState(() => _locationId = value),
                  validator: Validators.requiredSelection('Location'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Financial Year',
                  mappedItems: _financialYears
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _financialYearId,
                  onChanged: (value) => setState(() {
                    _financialYearId = value;
                    final series = _seriesOptions();
                    _documentSeriesId = series.isNotEmpty
                        ? series.first.id
                        : null;
                  }),
                  validator: Validators.requiredSelection('Financial Year'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Document Series',
                  mappedItems: _seriesOptions()
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _documentSeriesId,
                  onChanged: (value) =>
                      setState(() => _documentSeriesId = value),
                ),
                AppFormTextField(
                  labelText: 'Receipt No',
                  controller: _receiptNoController,
                  hintText: 'Auto-generated on save',
                  validator: Validators.optionalMaxLength(100, 'Receipt No'),
                ),
                AppFormTextField(
                  labelText: 'Receipt Date',
                  controller: _receiptDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([
                    Validators.required('Receipt Date'),
                    Validators.date('Receipt Date'),
                  ]),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Customer',
                  mappedItems: _customers
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _customerPartyId,
                  onChanged: (value) =>
                      setState(() => _customerPartyId = value),
                  validator: Validators.requiredSelection('Customer'),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Payment Mode',
                  mappedItems: _paymentModeDropdownItems(),
                  initialValue: _paymentMode,
                  onChanged: (value) => setState(() {
                    _paymentMode = value ?? 'bank';
                    _clearAccountIfInvalidForReceipt();
                  }),
                  validator: Validators.requiredSelection('Payment Mode'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Cash / bank ledger',
                  mappedItems: _receiptLedgerOptions
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _accountId,
                  onChanged: (value) => setState(() => _accountId = value),
                  validator: Validators.requiredSelection('Cash / bank ledger'),
                ),
                AppFormTextField(
                  labelText: 'Payment Reference No',
                  controller: _paymentReferenceNoController,
                  validator:
                      Validators.optionalMaxLength(100, 'Payment Reference No'),
                ),
                AppFormTextField(
                  labelText: 'Payment Reference Date',
                  controller: _paymentReferenceDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator:
                      Validators.optionalDate('Payment Reference Date'),
                ),
                AppFormTextField(
                  labelText: 'Paid Amount',
                  controller: _paidAmountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.compose([
                    Validators.required('Paid Amount'),
                    Validators.optionalNonNegativeNumber('Paid Amount'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Notes',
                  controller: _notesController,
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSwitchTile(
              label: 'Active',
              subtitle:
                  'Turn off to mark this receipt inactive. Inactive records are kept for audit but excluded from normal lists and day-to-day use.',
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: AppUiConstants.spacingLg),
            Row(
              children: [
                Text(
                  'Allocations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                AppActionButton(
                  icon: Icons.add_outlined,
                  label: 'Add Allocation',
                  onPressed: _addAllocation,
                  filled: false,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            if (_allocations.isEmpty)
              const Text(
                'This receipt can stay on-account, or allocate it to one or more sales invoices.',
              )
            else
              ...List<Widget>.generate(_allocations.length, (index) {
                final allocation = _allocations[index];
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppUiConstants.spacingSm,
                  ),
                  child: PurchaseCompactLineCard(
                    index: index,
                    total: _allocations.length,
                    onRemove: () => _removeAllocation(index),
                    child: PurchaseCompactFieldGrid(
                      children: [
                        AppSearchPickerField<int>(
                          labelText: 'Sales Invoice',
                          selectedLabel: _invoiceOptions
                              .cast<SalesInvoiceModel?>()
                              .firstWhere(
                                (item) => item?.id == allocation.salesInvoiceId,
                                orElse: () => null,
                              )
                              ?.invoiceNo,
                          options: _invoiceOptions
                              .map(
                                (item) => AppSearchPickerOption<int>(
                                  value: item.id,
                                  label: item.invoiceNo ?? 'Invoice',
                                  subtitle: quotationCustomerLabel(
                                    item.raw ?? <String, dynamic>{},
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) => setState(
                            () => allocation.salesInvoiceId = value,
                          ),
                        ),
                        AppFormTextField(
                          labelText: 'Allocated Amount',
                          controller: allocation.amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: Validators.optionalNonNegativeNumber(
                            'Allocated Amount',
                          ),
                        ),
                        AppDropdownField<String>.fromMapped(
                          labelText: 'Allocation Type',
                          mappedItems: const <AppDropdownItem<String>>[
                            AppDropdownItem(
                              value: 'against_invoice',
                              label: 'Against Invoice',
                            ),
                            AppDropdownItem(value: 'advance', label: 'Advance'),
                            AppDropdownItem(
                              value: 'on_account',
                              label: 'On Account',
                            ),
                            AppDropdownItem(
                              value: 'adjustment',
                              label: 'Adjustment',
                            ),
                          ],
                          initialValue: allocation.allocationType,
                          onChanged: (value) => setState(
                            () => allocation.allocationType =
                                value ?? 'against_invoice',
                          ),
                        ),
                        AppFormTextField(
                          labelText: 'Remarks',
                          controller: allocation.remarksController,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: AppUiConstants.spacingMd),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: _selectedItem == null
                      ? 'Save Receipt'
                      : 'Update Receipt',
                  onPressed: _save,
                  busy: _saving,
                ),
                if (_selectedItem != null) ...[
                  AppActionButton(
                    icon: Icons.publish_outlined,
                    label: 'Post',
                    filled: false,
                    onPressed: () => _docAction(
                      () => _salesService.postReceipt(
                        intValue(_selectedItem!.toJson(), 'id')!,
                        SalesReceiptModel(const <String, dynamic>{}),
                      ),
                    ),
                  ),
                  AppActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Cancel',
                    filled: false,
                    onPressed: () => _docAction(
                      () => _salesService.cancelReceipt(
                        intValue(_selectedItem!.toJson(), 'id')!,
                        SalesReceiptModel(const <String, dynamic>{}),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesReceiptAllocationDraft {
  _SalesReceiptAllocationDraft({
    this.salesInvoiceId,
    this.allocationType = 'against_invoice',
    String? allocatedAmount,
    String? remarks,
  }) : amountController = TextEditingController(text: allocatedAmount ?? ''),
       remarksController = TextEditingController(text: remarks ?? '');

  factory _SalesReceiptAllocationDraft.fromJson(Map<String, dynamic> json) {
    return _SalesReceiptAllocationDraft(
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
