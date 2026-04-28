import '../../screen.dart';
import 'purchase_support.dart';

class PurchasePaymentPage extends StatefulWidget {
  const PurchasePaymentPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
    this.initialPurchaseInvoiceId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;
  final int? initialPurchaseInvoiceId;

  @override
  State<PurchasePaymentPage> createState() => _PurchasePaymentPageState();
}

class _PurchasePaymentPageState extends State<PurchasePaymentPage> {
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

  static const List<AppDropdownItem<String>> _paymentModeItems =
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
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final AccountsService _accountsService = AccountsService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _paymentNoController = TextEditingController();
  final TextEditingController _paymentDateController = TextEditingController();
  final TextEditingController _referenceNoController = TextEditingController();
  final TextEditingController _referenceDateController =
      TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  String _statusFilter = '';
  String _paymentMode = 'bank';
  List<PurchasePaymentModel> _items = const <PurchasePaymentModel>[];
  List<PurchasePaymentModel> _filteredItems = const <PurchasePaymentModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<BranchModel> _branches = const <BranchModel>[];
  List<BusinessLocationModel> _locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> _financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> _documentSeries = const <DocumentSeriesModel>[];
  List<PartyModel> _suppliers = const <PartyModel>[];
  List<AccountModel> _accounts = const <AccountModel>[];
  List<PurchaseInvoiceModel> _invoices = const <PurchaseInvoiceModel>[];
  PurchasePaymentModel? _selectedItem;
  int? _contextCompanyId;
  int? _contextBranchId;
  int? _contextLocationId;
  int? _contextFinancialYearId;
  int? _companyId;
  int? _branchId;
  int? _locationId;
  int? _financialYearId;
  int? _documentSeriesId;
  int? _supplierPartyId;
  int? _accountId;
  bool _isActive = true;
  List<_PaymentAllocationDraft> _allocations = <_PaymentAllocationDraft>[];

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
    _paymentNoController.dispose();
    _paymentDateController.dispose();
    _referenceNoController.dispose();
    _referenceDateController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPage({int? selectId}) async {
    setState(() {
      _initialLoading = _items.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait<dynamic>([
        _purchaseService.payments(
          filters: const {'per_page': 200, 'sort_by': 'payment_date'},
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

      if (!mounted) return;
      setState(() {
        _items =
            (responses[0] as PaginatedResponse<PurchasePaymentModel>).data ??
            const <PurchasePaymentModel>[];
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
        _suppliers = purchaseSuppliers(
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
            (responses[9] as PaginatedResponse<PurchaseInvoiceModel>).data ??
            const <PurchaseInvoiceModel>[];
        _contextCompanyId = contextSelection.companyId;
        _contextBranchId = contextSelection.branchId;
        _contextLocationId = contextSelection.locationId;
        _contextFinancialYearId = contextSelection.financialYearId;
        _initialLoading = false;
      });
      _applyFilters();
      final selected = selectId != null
          ? _items.cast<PurchasePaymentModel?>().firstWhere(
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
        final invoiceBoot = widget.initialPurchaseInvoiceId;
        if (invoiceBoot != null && widget.editorOnly) {
          await _bootstrapNewPaymentFromInvoice(invoiceBoot);
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

  Future<void> _selectDocument(PurchasePaymentModel item) async {
    final id = intValue(item.toJson(), 'id');
    if (id == null) return;
    final response = await _purchaseService.payment(id);
    final full = response.data ?? item;
    final data = full.toJson();
    final allocations =
        (data['allocations'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(_PaymentAllocationDraft.fromJson)
            .toList(growable: true);
    setState(() {
      _selectedItem = full;
      _companyId = intValue(data, 'company_id');
      _branchId = intValue(data, 'branch_id');
      _locationId = intValue(data, 'location_id');
      _financialYearId = intValue(data, 'financial_year_id');
      _documentSeriesId = intValue(data, 'document_series_id');
      _supplierPartyId = intValue(data, 'supplier_party_id');
      _accountId = intValue(data, 'account_id');
      _paymentMode = stringValue(data, 'payment_mode', 'bank');
      _paymentNoController.text = stringValue(data, 'payment_no');
      _paymentDateController.text = displayDate(
        nullableStringValue(data, 'payment_date'),
      );
      _referenceNoController.text = stringValue(data, 'reference_no');
      _referenceDateController.text = displayDate(
        nullableStringValue(data, 'reference_date'),
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
    setState(() {
      _selectedItem = null;
      _companyId = _contextCompanyId;
      _branchId = _contextBranchId;
      _locationId = _contextLocationId;
      _financialYearId = _contextFinancialYearId;
      _documentSeriesId = series.isNotEmpty ? series.first.id : null;
      _supplierPartyId = null;
      _accountId = null;
      _paymentMode = 'bank';
      _paymentNoController.clear();
      _paymentDateController.text = DateTime.now()
          .toIso8601String()
          .split('T')
          .first;
      _referenceNoController.clear();
      _referenceDateController.clear();
      _paidAmountController.clear();
      _notesController.clear();
      _isActive = true;
      _allocations = <_PaymentAllocationDraft>[];
      _formError = null;
    });
  }

  Future<void> _bootstrapNewPaymentFromInvoice(int invoiceId) async {
    try {
      final response = await _purchaseService.invoice(invoiceId);
      final invoice = response.data;
      if (invoice == null || !mounted) {
        return;
      }

      final outstanding = _invoiceOutstanding(invoice);
      if (outstanding <= 0) {
        if (mounted) {
          setState(() {
            _formError =
                'This purchase invoice has no outstanding balance to pay.';
          });
        }
        return;
      }

      final allocAmount = outstanding == outstanding.roundToDouble()
          ? outstanding.round().toString()
          : outstanding.toStringAsFixed(2);

      setState(() {
        _companyId = invoice.companyId;
        _branchId = invoice.branchId;
        _locationId = invoice.locationId;
        _financialYearId = invoice.financialYearId;
        _documentSeriesId = _defaultSeriesIdFor(
          companyId: invoice.companyId,
          financialYearId: invoice.financialYearId,
        );
        _supplierPartyId = invoice.supplierPartyId;
        _referenceNoController.text = invoice.invoiceNo ?? '';
        _referenceDateController.text = displayDate(invoice.invoiceDate);
        _paidAmountController.text = allocAmount;
        _notesController.text = invoice.notes ?? '';
        if (!_invoices.any((entry) => entry.id == invoice.id)) {
          _invoices = <PurchaseInvoiceModel>[invoice, ..._invoices];
        }
        _allocations = <_PaymentAllocationDraft>[
          _PaymentAllocationDraft(
            purchaseInvoiceId: invoice.id,
            allocationType: 'against_invoice',
            allocatedAmount: allocAmount,
            remarks: 'Against ${invoice.invoiceNo ?? 'invoice #${invoice.id}'}',
          ),
        ];
        _formError = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _formError = error.toString());
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
                stringValue(data, 'payment_status') == _statusFilter;
            final searchOk =
                search.isEmpty ||
                [
                  stringValue(data, 'payment_no'),
                  stringValue(data, 'payment_status'),
                  stringValue(data, 'supplier_name'),
                  stringValue(data, 'reference_no'),
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
              item.documentType == 'PURCHASE_PAYMENT';
          final companyOk = _companyId == null || item.companyId == _companyId;
          final fyOk =
              _financialYearId == null ||
              item.financialYearId == _financialYearId;
          return typeOk && companyOk && fyOk;
        })
        .toList(growable: false);
  }

  int? _defaultSeriesIdFor({
    required int? companyId,
    required int? financialYearId,
  }) {
    final options = _documentSeries
        .where((item) {
          final typeOk =
              item.documentType == null ||
              item.documentType == 'PURCHASE_PAYMENT';
          final companyOk = companyId == null || item.companyId == companyId;
          final fyOk =
              financialYearId == null || item.financialYearId == financialYearId;
          return typeOk && companyOk && fyOk;
        })
        .toList(growable: false);
    return options.isNotEmpty ? options.first.id : null;
  }

  double _invoiceOutstanding(PurchaseInvoiceModel invoice) {
    final rawBalance = invoice.raw?['balance_amount'];
    final balance = double.tryParse(rawBalance?.toString() ?? '');
    if (balance != null) {
      return balance;
    }

    final rawTotal = invoice.raw?['total_amount'];
    if (rawTotal is num) {
      return rawTotal.toDouble();
    }

    return double.tryParse(rawTotal?.toString() ?? '') ?? 0;
  }

  String _nestedInvoiceSubtitle(PurchaseInvoiceModel invoice) {
    final supplierName =
        invoice.raw?['supplier_name']?.toString() ??
        ((invoice.raw?['supplier'] is Map<String, dynamic>)
            ? stringValue(
                invoice.raw!['supplier'] as Map<String, dynamic>,
                'party_name',
              )
            : '');
    final outstanding = _invoiceOutstanding(invoice);
    final parts = <String>[
      if (supplierName.trim().isNotEmpty) supplierName.trim(),
      if (outstanding > 0) 'Outstanding ${outstanding.toStringAsFixed(2)}',
    ];
    return parts.join(' · ');
  }

  void _syncPaidAmountFromAllocations() {
    final total = _allocations.fold<double>(
      0,
      (sum, allocation) =>
          sum + (double.tryParse(allocation.amountController.text.trim()) ?? 0),
    );
    _paidAmountController.text = total > 0 ? total.toStringAsFixed(2) : '';
  }

  Future<void> _handleAllocationInvoiceChanged(
    int index,
    int? purchaseInvoiceId,
  ) async {
    if (index < 0 || index >= _allocations.length) {
      return;
    }

    if (purchaseInvoiceId == null) {
      setState(() {
        _allocations[index].purchaseInvoiceId = null;
        _allocations[index].amountController.clear();
        _syncPaidAmountFromAllocations();
      });
      return;
    }

    final response = await _purchaseService.invoice(purchaseInvoiceId);
    final invoice = response.data;
    if (!mounted || invoice == null) return;

    final outstanding = _invoiceOutstanding(invoice);
    setState(() {
      _allocations[index].purchaseInvoiceId = purchaseInvoiceId;
      _allocations[index].allocationType = 'against_invoice';
      if (_allocations[index].amountController.text.trim().isEmpty ||
          (double.tryParse(_allocations[index].amountController.text.trim()) ??
                  0) <=
              0) {
        _allocations[index].amountController.text = outstanding > 0
            ? outstanding.toStringAsFixed(2)
            : '';
      }
      _companyId = invoice.companyId;
      _branchId = invoice.branchId;
      _locationId = invoice.locationId;
      _financialYearId = invoice.financialYearId;
      _documentSeriesId = _defaultSeriesIdFor(
        companyId: invoice.companyId,
        financialYearId: invoice.financialYearId,
      );
      _supplierPartyId = invoice.supplierPartyId;
      _referenceNoController.text =
          _referenceNoController.text.trim().isEmpty
          ? (invoice.invoiceNo ?? '')
          : _referenceNoController.text;
      _referenceDateController.text =
          _referenceDateController.text.trim().isEmpty
          ? displayDate(invoice.invoiceDate)
          : _referenceDateController.text;
      _notesController.text = _notesController.text.trim().isEmpty
          ? (invoice.notes ?? '')
          : _notesController.text;
      _syncPaidAmountFromAllocations();
      _formError = null;
    });
  }

  List<BranchModel> get _branchOptions =>
      branchesForCompany(_branches, _companyId);

  List<BusinessLocationModel> get _locationOptions =>
      locationsForBranch(_locations, _branchId);

  List<PurchaseInvoiceModel> get _invoiceOptions => _invoices
      .where(
        (invoice) =>
            (_supplierPartyId == null ||
                invoice.supplierPartyId == _supplierPartyId) &&
            invoice.companyId == _companyId,
      )
      .toList(growable: false);

  void _addAllocation() {
    setState(() {
      _allocations = List<_PaymentAllocationDraft>.from(_allocations)
        ..add(_PaymentAllocationDraft());
    });
  }

  void _removeAllocation(int index) {
    setState(() {
      _allocations = List<_PaymentAllocationDraft>.from(_allocations)
        ..removeAt(index);
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
      'payment_no': nullIfEmpty(_paymentNoController.text),
      'payment_date': _paymentDateController.text.trim(),
      'supplier_party_id': _supplierPartyId,
      'payment_mode': _paymentMode,
      'account_id': _accountId,
      'reference_no': nullIfEmpty(_referenceNoController.text),
      'reference_date': nullIfEmpty(_referenceDateController.text),
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
          ? await _purchaseService.createPayment(PurchasePaymentModel(payload))
          : await _purchaseService.updatePayment(
              intValue(_selectedItem!.toJson(), 'id')!,
              PurchasePaymentModel(payload),
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
    Future<ApiResponse<PurchasePaymentModel>> Function() action,
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
        label: 'New Payment',
      ),
    ];
    final content = _buildContent();
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'Purchase Payments',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading purchase payments...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load purchase payments',
        message: _pageError!,
        onRetry: _loadPage,
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Purchase Payments',
      editorTitle: _selectedItem == null
          ? 'New Purchase Payment'
          : stringValue(
              _selectedItem!.toJson(),
              'payment_no',
              'Purchase Payment',
            ),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: PurchaseListCard<PurchasePaymentModel>(
        items: _filteredItems,
        selectedItem: _selectedItem,
        emptyMessage: 'No purchase payments found.',
        searchController: _searchController,
        searchHint: 'Search payments',
        statusValue: _statusFilter,
        statusItems: _statusItems,
        onStatusChanged: (value) {
          _statusFilter = value ?? '';
          _applyFilters();
        },
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'payment_no', 'Draft Payment'),
            subtitle: [
              displayDate(nullableStringValue(data, 'payment_date')),
              stringValue(data, 'payment_status'),
            ].where((value) => value.isNotEmpty).join(' · '),
            detail: stringValue(data, 'supplier_name'),
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
                  labelText: 'Payment No',
                  controller: _paymentNoController,
                  hintText: 'Auto-generated on save',
                  validator: Validators.optionalMaxLength(100, 'Payment No'),
                ),
                AppFormTextField(
                  labelText: 'Payment Date',
                  controller: _paymentDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([
                    Validators.required('Payment Date'),
                    Validators.date('Payment Date'),
                  ]),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Supplier',
                  mappedItems: _suppliers
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _supplierPartyId,
                  onChanged: (value) =>
                      setState(() => _supplierPartyId = value),
                  validator: Validators.requiredSelection('Supplier'),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Payment Mode',
                  mappedItems: _paymentModeItems,
                  initialValue: _paymentMode,
                  onChanged: (value) =>
                      setState(() => _paymentMode = value ?? 'bank'),
                  validator: Validators.requiredSelection('Payment Mode'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Account',
                  mappedItems: _accounts
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
                  validator: Validators.requiredSelection('Account'),
                ),
                AppFormTextField(
                  labelText: 'Reference No',
                  controller: _referenceNoController,
                  validator: Validators.optionalMaxLength(100, 'Reference No'),
                ),
                AppFormTextField(
                  labelText: 'Reference Date',
                  controller: _referenceDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDate('Reference Date'),
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
                'This payment can stay on-account, or allocate it to one or more purchase invoices.',
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
                          labelText: 'Purchase Invoice',
                          selectedLabel: _invoiceOptions
                              .cast<PurchaseInvoiceModel?>()
                              .firstWhere(
                                (item) =>
                                    item?.id == allocation.purchaseInvoiceId,
                                orElse: () => null,
                              )
                              ?.invoiceNo,
                          options: _invoiceOptions
                              .map(
                                (item) => AppSearchPickerOption<int>(
                                  value: item.id,
                                  label: item.invoiceNo ?? 'Invoice',
                                  subtitle: _nestedInvoiceSubtitle(item),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) async {
                            await _handleAllocationInvoiceChanged(
                              index,
                              value,
                            );
                          },
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
                      ? 'Save Payment'
                      : 'Update Payment',
                  onPressed: _save,
                  busy: _saving,
                ),
                if (_selectedItem != null) ...[
                  AppActionButton(
                    icon: Icons.publish_outlined,
                    label: 'Post',
                    filled: false,
                    onPressed: () => _docAction(
                      () => _purchaseService.postPayment(
                        intValue(_selectedItem!.toJson(), 'id')!,
                        PurchasePaymentModel(const <String, dynamic>{}),
                      ),
                    ),
                  ),
                  AppActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Cancel',
                    filled: false,
                    onPressed: () => _docAction(
                      () => _purchaseService.cancelPayment(
                        intValue(_selectedItem!.toJson(), 'id')!,
                        PurchasePaymentModel(const <String, dynamic>{}),
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

class _PaymentAllocationDraft {
  _PaymentAllocationDraft({
    this.purchaseInvoiceId,
    this.allocationType = 'against_invoice',
    String? allocatedAmount,
    String? remarks,
  }) : amountController = TextEditingController(text: allocatedAmount ?? ''),
       remarksController = TextEditingController(text: remarks ?? '');

  factory _PaymentAllocationDraft.fromJson(Map<String, dynamic> json) {
    return _PaymentAllocationDraft(
      purchaseInvoiceId: intValue(json, 'purchase_invoice_id'),
      allocationType: stringValue(json, 'allocation_type', 'against_invoice'),
      allocatedAmount: stringValue(json, 'allocated_amount'),
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
      'allocated_amount': double.tryParse(amountController.text.trim()) ?? 0,
      'allocation_type': allocationType,
      'remarks': nullIfEmpty(remarksController.text),
    };
  }
}
