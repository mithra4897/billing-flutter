import '../../screen.dart';
import 'purchase_support.dart';

class PurchaseInvoicePage extends StatefulWidget {
  const PurchaseInvoicePage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<PurchaseInvoicePage> createState() => _PurchaseInvoicePageState();
}

class _PurchaseInvoicePageState extends State<PurchaseInvoicePage> {
  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All'),
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'posted', label: 'Posted'),
        AppDropdownItem(value: 'partially_paid', label: 'Partially Paid'),
        AppDropdownItem(value: 'paid', label: 'Paid'),
        AppDropdownItem(
          value: 'partially_returned',
          label: 'Partially Returned',
        ),
        AppDropdownItem(value: 'returned', label: 'Returned'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  final PurchaseService _purchaseService = PurchaseService();
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final AccountsService _accountsService = AccountsService();
  final InventoryService _inventoryService = InventoryService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _invoiceNoController = TextEditingController();
  final TextEditingController _invoiceDateController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _supplierReferenceNoController =
      TextEditingController();
  final TextEditingController _supplierReferenceDateController =
      TextEditingController();
  final TextEditingController _currencyCodeController = TextEditingController();
  final TextEditingController _exchangeRateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _termsController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  String _statusFilter = '';
  List<PurchaseInvoiceModel> _items = const <PurchaseInvoiceModel>[];
  List<PurchaseInvoiceModel> _filteredItems = const <PurchaseInvoiceModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<BranchModel> _branches = const <BranchModel>[];
  List<BusinessLocationModel> _locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> _financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> _documentSeries = const <DocumentSeriesModel>[];
  List<PurchaseOrderModel> _orders = const <PurchaseOrderModel>[];
  List<PurchaseReceiptModel> _receipts = const <PurchaseReceiptModel>[];
  List<PartyModel> _suppliers = const <PartyModel>[];
  List<AccountModel> _accounts = const <AccountModel>[];
  List<ItemModel> _itemsLookup = const <ItemModel>[];
  List<UomModel> _uoms = const <UomModel>[];
  List<UomConversionModel> _uomConversions = const <UomConversionModel>[];
  List<WarehouseModel> _warehouses = const <WarehouseModel>[];
  List<TaxCodeModel> _taxCodes = const <TaxCodeModel>[];
  PurchaseInvoiceModel? _selectedItem;
  int? _contextCompanyId;
  int? _contextBranchId;
  int? _contextLocationId;
  int? _contextFinancialYearId;
  int? _companyId;
  int? _branchId;
  int? _locationId;
  int? _financialYearId;
  int? _documentSeriesId;
  int? _purchaseOrderId;
  int? _purchaseReceiptId;
  int? _supplierPartyId;
  int? _adjustmentAccountId;
  List<PurchaseInvoiceLineModel> _lines = <PurchaseInvoiceLineModel>[];
  bool _isActive = true;

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
    _invoiceNoController.dispose();
    _invoiceDateController.dispose();
    _dueDateController.dispose();
    _supplierReferenceNoController.dispose();
    _supplierReferenceDateController.dispose();
    _currencyCodeController.dispose();
    _exchangeRateController.dispose();
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _loadPage({int? selectId}) async {
    setState(() {
      _initialLoading = _items.isEmpty;
      _pageError = null;
    });
    try {
      final responses = await Future.wait<dynamic>([
        _purchaseService.invoices(
          filters: const {'per_page': 200, 'sort_by': 'invoice_date'},
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
        _purchaseService.ordersAll(filters: const {'sort_by': 'order_date'}),
        _purchaseService.receiptsAll(
          filters: const {'sort_by': 'receipt_date'},
        ),
        _partiesService.partyTypes(filters: const {'per_page': 100}),
        _partiesService.parties(
          filters: const {'per_page': 300, 'sort_by': 'party_name'},
        ),
        _accountsService.accountsAll(
          filters: const {'sort_by': 'account_name'},
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
            (responses[0] as PaginatedResponse<PurchaseInvoiceModel>).data ??
            const <PurchaseInvoiceModel>[];
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
        _orders =
            (responses[6] as ApiResponse<List<PurchaseOrderModel>>).data ??
            const <PurchaseOrderModel>[];
        _receipts =
            (responses[7] as ApiResponse<List<PurchaseReceiptModel>>).data ??
            const <PurchaseReceiptModel>[];
        _suppliers = purchaseSuppliers(
          parties:
              (responses[9] as PaginatedResponse<PartyModel>).data ??
              const <PartyModel>[],
          partyTypes:
              (responses[8] as PaginatedResponse<PartyTypeModel>).data ??
              const <PartyTypeModel>[],
        );
        _accounts =
            ((responses[10] as ApiResponse<List<AccountModel>>).data ??
                    const <AccountModel>[])
                .where((item) => item.isActive)
                .toList();
        _itemsLookup =
            ((responses[11] as PaginatedResponse<ItemModel>).data ??
                    const <ItemModel>[])
                .where((item) => item.isActive)
                .toList();
        _uoms =
            ((responses[12] as PaginatedResponse<UomModel>).data ??
                    const <UomModel>[])
                .where((item) => item.isActive)
                .toList();
        _uomConversions =
            ((responses[13] as ApiResponse<List<UomConversionModel>>).data ??
                    const <UomConversionModel>[])
                .where((item) => item.isActive)
                .toList();
        _warehouses =
            ((responses[14] as PaginatedResponse<WarehouseModel>).data ??
                    const <WarehouseModel>[])
                .where((item) => item.isActive)
                .toList();
        _taxCodes =
            ((responses[15] as PaginatedResponse<TaxCodeModel>).data ??
                    const <TaxCodeModel>[])
                .where((item) => item.isActive)
                .toList();
        _contextCompanyId = contextSelection.companyId;
        _contextBranchId = contextSelection.branchId;
        _contextLocationId = contextSelection.locationId;
        _contextFinancialYearId = contextSelection.financialYearId;
        _initialLoading = false;
      });
      _applyFilters();
      final selected = selectId != null
          ? _items.cast<PurchaseInvoiceModel?>().firstWhere(
              (item) => item?.id == selectId,
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
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pageError = error.toString();
        _initialLoading = false;
      });
    }
  }

  Future<void> _selectDocument(PurchaseInvoiceModel item) async {
    final response = await _purchaseService.invoice(item.id);
    final full = response.data ?? item;
    setState(() {
      _selectedItem = full;
      _companyId = full.companyId;
      _branchId = full.branchId;
      _locationId = full.locationId;
      _financialYearId = full.financialYearId;
      _documentSeriesId = full.documentSeriesId;
      _purchaseOrderId = full.purchaseOrderId;
      _purchaseReceiptId = full.purchaseReceiptId;
      _supplierPartyId = full.supplierPartyId;
      _adjustmentAccountId = full.adjustmentAccountId;
      _invoiceNoController.text = full.invoiceNo ?? '';
      _invoiceDateController.text = displayDate(full.invoiceDate);
      _dueDateController.text = displayDate(full.dueDate);
      _supplierReferenceNoController.text =
          full.raw?['supplier_reference_no']?.toString() ?? '';
      _supplierReferenceDateController.text = displayDate(
        full.raw?['supplier_reference_date']?.toString(),
      );
      _currencyCodeController.text = full.currencyCode ?? 'INR';
      _exchangeRateController.text = full.exchangeRate?.toString() ?? '1';
      _notesController.text = full.notes ?? '';
      _termsController.text = full.termsConditions ?? '';
      _lines = full.lines.isEmpty
          ? <PurchaseInvoiceLineModel>[
              PurchaseInvoiceLineModel(
                itemId: 0,
                uomId: 0,
                invoicedQty: 0,
                rate: 0,
              ),
            ]
          : full.lines;
      _isActive = full.raw?['is_active'] == null
          ? true
          : boolValue(full.raw!, 'is_active', fallback: true);
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
      _purchaseOrderId = null;
      _purchaseReceiptId = null;
      _supplierPartyId = null;
      _adjustmentAccountId = null;
      _invoiceNoController.clear();
      _invoiceDateController.text = DateTime.now()
          .toIso8601String()
          .split('T')
          .first;
      _dueDateController.clear();
      _supplierReferenceNoController.clear();
      _supplierReferenceDateController.clear();
      _currencyCodeController.text = 'INR';
      _exchangeRateController.text = '1';
      _notesController.clear();
      _termsController.clear();
      _lines = <PurchaseInvoiceLineModel>[
        PurchaseInvoiceLineModel(itemId: 0, uomId: 0, invoicedQty: 0, rate: 0),
      ];
      _isActive = true;
      _formError = null;
    });
  }

  void _applyFilters() {
    final search = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredItems = _items
          .where((item) {
            final statusOk =
                _statusFilter.isEmpty || item.invoiceStatus == _statusFilter;
            final searchOk =
                search.isEmpty ||
                [
                  item.invoiceNo ?? '',
                  item.invoiceStatus ?? '',
                  item.raw?['supplier_name']?.toString() ?? '',
                ].join(' ').toLowerCase().contains(search);
            return statusOk && searchOk;
          })
          .toList(growable: false);
    });
  }

  List<UomModel> _uomOptionsForItem(int? itemId) {
    final item = _itemsLookup.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == itemId,
      orElse: () => null,
    );
    return allowedUomsForItem(item, _uoms, _uomConversions);
  }

  int? _resolveDefaultUom(int? itemId, int? currentUomId) {
    final item = _itemsLookup.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == itemId,
      orElse: () => null,
    );
    return defaultUomIdForItem(
      item,
      _uoms,
      _uomConversions,
      current: currentUomId,
    );
  }

  List<DocumentSeriesModel> _seriesOptions() {
    return _documentSeries
        .where((item) {
          final typeOk =
              item.documentType == null ||
              item.documentType == 'PURCHASE_INVOICE';
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

  void _addLine() {
    setState(() {
      _lines = List<PurchaseInvoiceLineModel>.from(_lines)
        ..add(
          PurchaseInvoiceLineModel(
            itemId: 0,
            uomId: 0,
            invoicedQty: 0,
            rate: 0,
          ),
        );
    });
  }

  void _updateLine(int index, PurchaseInvoiceLineModel line) {
    setState(() {
      final next = List<PurchaseInvoiceLineModel>.from(_lines);
      next[index] = line;
      _lines = next;
    });
  }

  void _removeLine(int index) {
    setState(() {
      _lines = List<PurchaseInvoiceLineModel>.from(_lines)..removeAt(index);
      if (_lines.isEmpty) {
        _lines.add(
          PurchaseInvoiceLineModel(
            itemId: 0,
            uomId: 0,
            invoicedQty: 0,
            rate: 0,
          ),
        );
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lines.any(
      (line) => line.itemId <= 0 || line.uomId <= 0 || line.invoicedQty <= 0,
    )) {
      setState(
        () => _formError = 'Each line needs item, UOM, and invoiced quantity.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _formError = null;
    });
    final invoice = PurchaseInvoiceModel(
      id: _selectedItem?.id ?? 0,
      companyId: _companyId ?? 0,
      branchId: _branchId ?? 0,
      locationId: _locationId ?? 0,
      financialYearId: _financialYearId ?? 0,
      supplierPartyId: _supplierPartyId ?? 0,
      invoiceDate: _invoiceDateController.text.trim(),
      documentSeriesId: _documentSeriesId,
      purchaseOrderId: _purchaseOrderId,
      purchaseReceiptId: _purchaseReceiptId,
      invoiceNo: nullIfEmpty(_invoiceNoController.text),
      dueDate: nullIfEmpty(_dueDateController.text),
      currencyCode: nullIfEmpty(_currencyCodeController.text),
      exchangeRate: double.tryParse(_exchangeRateController.text.trim()),
      adjustmentAccountId: _adjustmentAccountId,
      notes: nullIfEmpty(_notesController.text),
      termsConditions: nullIfEmpty(_termsController.text),
      lines: _lines,
      raw: <String, dynamic>{
        'supplier_reference_no': nullIfEmpty(
          _supplierReferenceNoController.text,
        ),
        'supplier_reference_date': nullIfEmpty(
          _supplierReferenceDateController.text,
        ),
        'is_active': _isActive,
      },
    );
    try {
      final response = _selectedItem == null
          ? await _purchaseService.createInvoice(invoice)
          : await _purchaseService.updateInvoice(_selectedItem!.id, invoice);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage(selectId: response.data?.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _docAction(
    Future<ApiResponse<PurchaseInvoiceModel>> Function() action,
  ) async {
    try {
      final response = await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage(selectId: response.data?.id);
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
        label: 'New Invoice',
      ),
    ];
    final content = _buildContent();
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'Purchase Invoices',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading purchase invoices...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load purchase invoices',
        message: _pageError!,
        onRetry: _loadPage,
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Purchase Invoices',
      editorTitle: _selectedItem == null
          ? 'New Purchase Invoice'
          : (_selectedItem!.invoiceNo ?? 'Purchase Invoice'),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: PurchaseListCard<PurchaseInvoiceModel>(
        items: _filteredItems,
        selectedItem: _selectedItem,
        emptyMessage: 'No purchase invoices found.',
        searchController: _searchController,
        searchHint: 'Search invoices',
        statusValue: _statusFilter,
        statusItems: _statusItems,
        onStatusChanged: (value) {
          _statusFilter = value ?? '';
          _applyFilters();
        },
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.invoiceNo ?? 'Draft Invoice',
          subtitle: [
            displayDate(item.invoiceDate),
            item.invoiceStatus ?? '',
          ].where((value) => value.isNotEmpty).join(' · '),
          detail: item.raw?['supplier_name']?.toString() ?? '',
          selected: selected,
          onTap: () => _selectDocument(item),
        ),
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
                  labelText: 'Invoice No',
                  controller: _invoiceNoController,
                  hintText: 'Auto-generated on save',
                  validator: Validators.optionalMaxLength(100, 'Invoice No'),
                ),
                AppFormTextField(
                  labelText: 'Invoice Date',
                  controller: _invoiceDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([
                    Validators.required('Invoice Date'),
                    Validators.date('Invoice Date'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Due Date',
                  controller: _dueDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDate('Due Date'),
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
                AppDropdownField<int>.fromMapped(
                  labelText: 'Purchase Order',
                  mappedItems: _orders
                      .where((item) => intValue(item.toJson(), 'id') != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: intValue(item.toJson(), 'id')!,
                          label: stringValue(
                            item.toJson(),
                            'order_no',
                            'Order',
                          ),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _purchaseOrderId,
                  onChanged: (value) =>
                      setState(() => _purchaseOrderId = value),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Purchase Receipt',
                  mappedItems: _receipts
                      .where((item) => intValue(item.toJson(), 'id') != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: intValue(item.toJson(), 'id')!,
                          label: stringValue(
                            item.toJson(),
                            'receipt_no',
                            'Receipt',
                          ),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _purchaseReceiptId,
                  onChanged: (value) =>
                      setState(() => _purchaseReceiptId = value),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Adjustment Account',
                  mappedItems: _accounts
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _adjustmentAccountId,
                  onChanged: (value) =>
                      setState(() => _adjustmentAccountId = value),
                ),
                AppFormTextField(
                  labelText: 'Supplier Ref No',
                  controller: _supplierReferenceNoController,
                ),
                AppFormTextField(
                  labelText: 'Supplier Ref Date',
                  controller: _supplierReferenceDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDate('Supplier Ref Date'),
                ),
                AppFormTextField(
                  labelText: 'Currency',
                  controller: _currencyCodeController,
                ),
                AppFormTextField(
                  labelText: 'Exchange Rate',
                  controller: _exchangeRateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Exchange Rate',
                  ),
                ),
                AppFormTextField(
                  labelText: 'Notes',
                  controller: _notesController,
                  maxLines: 3,
                ),
                AppFormTextField(
                  labelText: 'Terms & Conditions',
                  controller: _termsController,
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
                  'Lines',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                AppActionButton(
                  icon: Icons.add_outlined,
                  label: 'Add Line',
                  onPressed: _addLine,
                  filled: false,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            ...List<Widget>.generate(_lines.length, (index) {
              final line = _lines[index];
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: AppUiConstants.spacingSm,
                ),
                child: PurchaseCompactLineCard(
                  index: index,
                  total: _lines.length,
                  removeEnabled: _lines.length > 1,
                  onRemove: () => _removeLine(index),
                  child: PurchaseCompactFieldGrid(
                    children: [
                      AppSearchPickerField<int>(
                        labelText: 'Item',
                        selectedLabel: _itemsLookup
                            .cast<ItemModel?>()
                            .firstWhere(
                              (item) => item?.id == line.itemId,
                              orElse: () => null,
                            )
                            ?.toString(),
                        options: _itemsLookup
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppSearchPickerOption<int>(
                                value: item.id!,
                                label: item.toString(),
                                subtitle: item.itemCode,
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) => _updateLine(
                          index,
                          line.copyWith(
                            itemId: value ?? 0,
                            uomId:
                                _resolveDefaultUom(value, line.uomId) ??
                                line.uomId,
                          ),
                        ),
                        validator: (_) =>
                            line.itemId <= 0 ? 'Item is required' : null,
                      ),
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Warehouse',
                        mappedItems: _warehouses
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppDropdownItem(
                                value: item.id!,
                                label: item.toString(),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: line.warehouseId,
                        onChanged: (value) => _updateLine(
                          index,
                          line.copyWith(warehouseId: value),
                        ),
                      ),
                      Builder(
                        builder: (context) {
                          final options = _uomOptionsForItem(line.itemId);
                          if (options.length == 1) {
                            final onlyId = options.first.id;
                            if (line.uomId != onlyId) {
                              _updateLine(index, line.copyWith(uomId: onlyId));
                            }
                          }
                          return AppDropdownField<int>.fromMapped(
                            labelText: 'UOM',
                            mappedItems: options
                                .where((item) => item.id != null)
                                .map(
                                  (item) => AppDropdownItem(
                                    value: item.id!,
                                    label: item.toString(),
                                  ),
                                )
                                .toList(growable: false),
                            initialValue: line.uomId == 0 ? null : line.uomId,
                            onChanged: (value) => _updateLine(
                              index,
                              line.copyWith(uomId: value ?? 0),
                            ),
                            validator: (_) {
                              return (line.uomId == 0)
                                  ? 'UOM is required'
                                  : null;
                            },
                          );
                        },
                      ),
                      TextFormField(
                        initialValue: line.invoicedQty.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Invoiced Qty',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) => _updateLine(
                          index,
                          line.copyWith(
                            invoicedQty:
                                double.tryParse(value.trim()) ??
                                line.invoicedQty,
                          ),
                        ),
                        validator: Validators.compose([
                          Validators.required('Invoiced Qty'),
                          Validators.optionalNonNegativeNumber('Invoiced Qty'),
                        ]),
                      ),
                      TextFormField(
                        initialValue: line.rate.toString(),
                        decoration: const InputDecoration(labelText: 'Rate'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) => _updateLine(
                          index,
                          line.copyWith(
                            rate: double.tryParse(value.trim()) ?? line.rate,
                          ),
                        ),
                        validator: Validators.compose([
                          Validators.required('Rate'),
                          Validators.optionalNonNegativeNumber('Rate'),
                        ]),
                      ),
                      TextFormField(
                        initialValue: (line.discountPercent ?? 0).toString(),
                        decoration: const InputDecoration(
                          labelText: 'Discount %',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) => _updateLine(
                          index,
                          line.copyWith(
                            discountPercent: nullIfEmpty(value) == null
                                ? null
                                : double.tryParse(value.trim()),
                          ),
                        ),
                      ),
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Tax Code',
                        mappedItems: _taxCodes
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppDropdownItem(
                                value: item.id!,
                                label: item.toString(),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: line.taxCodeId,
                        onChanged: (value) =>
                            _updateLine(index, line.copyWith(taxCodeId: value)),
                      ),
                      TextFormField(
                        initialValue: line.description ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        maxLines: 2,
                        onChanged: (value) => _updateLine(
                          index,
                          line.copyWith(description: nullIfEmpty(value)),
                        ),
                      ),
                      TextFormField(
                        initialValue: line.remarks ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Remarks',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 2,
                        onChanged: (value) => _updateLine(
                          index,
                          line.copyWith(remarks: nullIfEmpty(value)),
                        ),
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
                      ? 'Save Invoice'
                      : 'Update Invoice',
                  onPressed: _save,
                  busy: _saving,
                ),
                if (_selectedItem != null) ...[
                  AppActionButton(
                    icon: Icons.publish_outlined,
                    label: 'Post',
                    filled: false,
                    onPressed: () => _docAction(
                      () => _purchaseService.postInvoice(_selectedItem!.id),
                    ),
                  ),
                  AppActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Cancel',
                    filled: false,
                    onPressed: () => _docAction(
                      () => _purchaseService.cancelInvoice(_selectedItem!.id),
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
