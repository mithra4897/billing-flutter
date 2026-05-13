import '../../model/sales/sales_invoice_line_model.dart';
import '../../model/sales/sales_return_model.dart';
import '../../screen.dart';
import '../purchase/purchase_support.dart';
import 'sales_support.dart';

class SalesReturnPage extends StatefulWidget {
  const SalesReturnPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<SalesReturnPage> createState() => _SalesReturnPageState();
}

class _SalesReturnPageState extends State<SalesReturnPage> {
  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All'),
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'posted', label: 'Posted'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  final SalesService _salesService = SalesService();
  final MasterService _masterService = MasterService();
  final InventoryService _inventoryService = InventoryService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _returnNoController = TextEditingController();
  final TextEditingController _returnDateController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  String _statusFilter = '';
  List<SalesReturnModel> _items = const <SalesReturnModel>[];
  List<SalesReturnModel> _filteredItems = const <SalesReturnModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<BranchModel> _branches = const <BranchModel>[];
  List<BusinessLocationModel> _locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> _financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> _documentSeries = const <DocumentSeriesModel>[];
  List<SalesInvoiceModel> _invoices = const <SalesInvoiceModel>[];
  List<SalesInvoiceLineModel> _invoiceLines = const <SalesInvoiceLineModel>[];
  List<ItemModel> _itemsLookup = const <ItemModel>[];
  List<UomModel> _uoms = const <UomModel>[];
  List<WarehouseModel> _warehouses = const <WarehouseModel>[];
  List<TaxCodeModel> _taxCodes = const <TaxCodeModel>[];
  SalesReturnModel? _selectedItem;
  int? _contextCompanyId;
  int? _contextBranchId;
  int? _contextLocationId;
  int? _contextFinancialYearId;
  int? _companyId;
  int? _branchId;
  int? _locationId;
  int? _financialYearId;
  int? _documentSeriesId;
  int? _salesInvoiceId;
  int? _customerPartyId;
  bool _isActive = true;
  List<_SalesReturnLineDraft> _lines = <_SalesReturnLineDraft>[];

  @override
  void initState() {
    super.initState();
    WorkingContextService.version.addListener(_handleWorkingContextChanged);
    _searchController.addListener(_applyFilters);
    _loadPage(selectId: widget.initialId);
  }

  void _handleWorkingContextChanged() {
    _loadPage(selectId: intValue(_selectedItem?.toJson() ?? const {}, 'id'));
  }

  @override
  void dispose() {
    WorkingContextService.version.removeListener(_handleWorkingContextChanged);
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _returnNoController.dispose();
    _returnDateController.dispose();
    _reasonController.dispose();
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
        _salesService.returns(
          filters: const {'per_page': 200, 'sort_by': 'return_date'},
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
        _salesService.invoices(
          filters: const {'per_page': 300, 'sort_by': 'invoice_date'},
        ),
        _inventoryService.items(
          filters: const {'per_page': 300, 'sort_by': 'item_name'},
        ),
        _inventoryService.uoms(
          filters: const {'per_page': 200, 'sort_by': 'name'},
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
            (responses[0] as PaginatedResponse<SalesReturnModel>).data ??
            const <SalesReturnModel>[];
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
        _invoices =
            (responses[6] as PaginatedResponse<SalesInvoiceModel>).data ??
            const <SalesInvoiceModel>[];
        _itemsLookup =
            ((responses[7] as PaginatedResponse<ItemModel>).data ??
                    const <ItemModel>[])
                .where((item) => item.isActive)
                .toList();
        _uoms =
            ((responses[8] as PaginatedResponse<UomModel>).data ??
                    const <UomModel>[])
                .where((item) => item.isActive)
                .toList();
        _warehouses =
            ((responses[9] as PaginatedResponse<WarehouseModel>).data ??
                    const <WarehouseModel>[])
                .where((item) => item.isActive)
                .toList();
        _taxCodes =
            ((responses[10] as PaginatedResponse<TaxCodeModel>).data ??
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
          ? _items.cast<SalesReturnModel?>().firstWhere(
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
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pageError = error.toString();
        _initialLoading = false;
      });
    }
  }

  Future<void> _selectDocument(SalesReturnModel item) async {
    final id = intValue(item.toJson(), 'id');
    if (id == null) return;
    final response = await _salesService.returnDoc(id);
    final full = response.data ?? item;
    final data = full.toJson();
    final lines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(_SalesReturnLineDraft.fromJson)
        .toList(growable: true);
    final invoiceId = intValue(data, 'sales_invoice_id');
    final invoiceResponse = invoiceId == null
        ? null
        : await _salesService.invoice(invoiceId);
    final invoiceLines =
        invoiceResponse?.data?.lines ?? const <SalesInvoiceLineModel>[];
    setState(() {
      _selectedItem = full;
      _companyId = intValue(data, 'company_id');
      _branchId = intValue(data, 'branch_id');
      _locationId = intValue(data, 'location_id');
      _financialYearId = intValue(data, 'financial_year_id');
      _documentSeriesId = intValue(data, 'document_series_id');
      _salesInvoiceId = invoiceId;
      _customerPartyId = intValue(data, 'customer_party_id');
      _returnNoController.text = stringValue(data, 'return_no');
      _returnDateController.text = displayDate(
        nullableStringValue(data, 'return_date'),
      );
      _reasonController.text = stringValue(data, 'reason');
      _notesController.text = stringValue(data, 'notes');
      _isActive = boolValue(data, 'is_active', fallback: true);
      _invoiceLines = invoiceLines;
      _lines = lines.isEmpty
          ? <_SalesReturnLineDraft>[_SalesReturnLineDraft()]
          : lines;
      _formError = null;
    });
    _syncLineDisplayNames();
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
      _salesInvoiceId = null;
      _customerPartyId = null;
      _returnNoController.clear();
      _returnDateController.text = DateTime.now()
          .toIso8601String()
          .split('T')
          .first;
      _reasonController.clear();
      _notesController.clear();
      _isActive = true;
      _invoiceLines = const <SalesInvoiceLineModel>[];
      _lines = <_SalesReturnLineDraft>[_SalesReturnLineDraft()];
      _formError = null;
    });
  }

  void _applyFilters() {
    final search = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredItems = _items
          .where((item) {
            final data = item.toJson();
            final statusOk =
                _statusFilter.isEmpty ||
                stringValue(data, 'return_status') == _statusFilter;
            final searchOk =
                search.isEmpty ||
                [
                  stringValue(data, 'return_no'),
                  stringValue(data, 'return_status'),
                  stringValue(data, 'reason'),
                  quotationCustomerLabel(data),
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
              item.documentType == null || item.documentType == 'SALES_RETURN';
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
      .where((item) {
        if (item.id == _salesInvoiceId) {
          return true;
        }
        final status = (item.invoiceStatus ?? '').trim().toLowerCase();
        final statusOk = status == 'partially_paid' || status == 'paid';
        final companyOk = _companyId == null || item.companyId == _companyId;
        final branchOk = _branchId == null || item.branchId == _branchId;
        final locationOk =
            _locationId == null || item.locationId == _locationId;
        final customerOk =
            _customerPartyId == null ||
            item.customerPartyId == _customerPartyId;
        final returnableOk = item.lines.any(_invoiceLineIsReturnable);
        return statusOk &&
            companyOk &&
            branchOk &&
            locationOk &&
            customerOk &&
            returnableOk;
      })
      .toList(growable: false);

  List<SalesInvoiceLineModel> get _invoiceLineOptions => _invoiceLines
      .where((item) {
        if (item.id == null || _selectedInvoiceLineIds.contains(item.id)) {
          return true;
        }
        return _invoiceLineIsReturnable(item);
      })
      .toList(growable: false);

  Set<int> get _selectedInvoiceLineIds =>
      _lines.map((line) => line.salesInvoiceLineId).whereType<int>().toSet();

  bool _invoiceLineIsReturnable(SalesInvoiceLineModel line) {
    final returnedQty = line.returnedQty ?? 0;
    return line.invoicedQty > returnedQty;
  }

  String _itemName(int? id) {
    if (id == null) {
      return '';
    }
    final item = _itemsLookup.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == id,
      orElse: () => null,
    );
    return item?.toString() ?? 'Item #$id';
  }

  String _warehouseName(int? id) {
    if (id == null) {
      return '';
    }
    final warehouse = _warehouses.cast<WarehouseModel?>().firstWhere(
      (entry) => entry?.id == id,
      orElse: () => null,
    );
    return warehouse?.toString() ?? 'Warehouse #$id';
  }

  String _uomName(int? id) {
    if (id == null) {
      return '';
    }
    final uom = _uoms.cast<UomModel?>().firstWhere(
      (entry) => entry?.id == id,
      orElse: () => null,
    );
    return uom?.toString() ?? 'UOM #$id';
  }

  Future<void> _handleInvoiceChanged(int? value) async {
    setState(() {
      _salesInvoiceId = value;
      _customerPartyId = null;
      _invoiceLines = const <SalesInvoiceLineModel>[];
      _lines = <_SalesReturnLineDraft>[_SalesReturnLineDraft()];
    });
    if (value == null) {
      return;
    }
    final response = await _salesService.invoice(value);
    if (!mounted) {
      return;
    }
    final invoice = response.data;
    setState(() {
      _customerPartyId = invoice?.customerPartyId;
      _invoiceLines = invoice?.lines ?? const <SalesInvoiceLineModel>[];
      _lines = _invoiceLines.isEmpty
          ? <_SalesReturnLineDraft>[_SalesReturnLineDraft()]
          : <_SalesReturnLineDraft>[
              _SalesReturnLineDraft.fromInvoiceLine(_invoiceLines.first),
            ];
    });
    _syncLineDisplayNames();
  }

  void _clearInvoiceSelection() {
    _salesInvoiceId = null;
    _customerPartyId = null;
    _invoiceLines = const <SalesInvoiceLineModel>[];
    _lines = <_SalesReturnLineDraft>[_SalesReturnLineDraft()];
  }

  void _syncLineDisplayNames() {
    for (final line in _lines) {
      line.itemNameController.text = _itemName(line.itemId);
      line.warehouseNameController.text = _warehouseName(line.warehouseId);
      line.uomNameController.text = _uomName(line.uomId);
    }
  }

  String get _currencyCodeForTaxSummary {
    final invoice = _invoices.cast<SalesInvoiceModel?>().firstWhere(
      (item) => item?.id == _salesInvoiceId,
      orElse: () => null,
    );
    final currency = invoice?.currencyCode?.trim() ?? '';
    return currency.isEmpty ? 'INR' : currency;
  }

  SalesLineTaxBreakdown _taxBreakdownForLine(_SalesReturnLineDraft line) {
    return computeSalesLineTaxBreakdown(
      qty: double.tryParse(line.returnQtyController.text.trim()) ?? 0,
      rate: double.tryParse(line.rateController.text.trim()) ?? 0,
      discountPercent: line.discountPercent ?? 0,
      taxCode: salesTaxCodeById(_taxCodes, line.taxCodeId),
      taxPercent: line.taxPercent,
      taxType: line.taxType,
    );
  }

  SalesDocumentTaxSummary _taxSummary() {
    return summarizeSalesLineTaxes(_lines.map(_taxBreakdownForLine));
  }

  Widget _buildTaxSummaryCard(BuildContext context) {
    final summary = _taxSummary();
    return SalesGstSummaryCard(
      taxable: summary.taxable,
      cgst: summary.cgst,
      sgst: summary.sgst,
      igst: summary.igst,
      cess: summary.cess,
      total: summary.total,
      currencyCode: _currencyCodeForTaxSummary,
    );
  }

  Map<String, dynamic> _linePayload(_SalesReturnLineDraft line) {
    final payload = line.toJson();
    final breakdown = _taxBreakdownForLine(line);
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

  void _addLine() => setState(
    () =>
        _lines = List<_SalesReturnLineDraft>.from(_lines)
          ..add(_SalesReturnLineDraft()),
  );

  void _removeLine(int index) {
    setState(() {
      _lines = List<_SalesReturnLineDraft>.from(_lines)..removeAt(index);
      if (_lines.isEmpty) _lines.add(_SalesReturnLineDraft());
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_salesInvoiceId == null) {
      setState(() => _formError = 'Sales invoice is required.');
      return;
    }
    if (_lines.any(
      (line) =>
          line.salesInvoiceLineId == null ||
          (double.tryParse(line.returnQtyController.text.trim()) ?? 0) <= 0,
    )) {
      setState(
        () => _formError = 'Each line needs invoice line and return quantity.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _formError = null;
    });
    final invoice = _invoices.cast<SalesInvoiceModel?>().firstWhere(
      (item) => item?.id == _salesInvoiceId,
      orElse: () => null,
    );
    final taxSummary = _taxSummary();
    final payload = <String, dynamic>{
      'company_id': _companyId,
      'branch_id': _branchId,
      'location_id': _locationId,
      'financial_year_id': _financialYearId,
      'document_series_id': _documentSeriesId,
      'sales_invoice_id': _salesInvoiceId,
      'customer_party_id': _customerPartyId ?? invoice?.customerPartyId,
      'return_no': nullIfEmpty(_returnNoController.text),
      'return_date': _returnDateController.text.trim(),
      'reason': nullIfEmpty(_reasonController.text),
      'taxable_amount': roundToDouble(taxSummary.taxable, 2),
      'cgst_amount': roundToDouble(taxSummary.cgst, 2),
      'sgst_amount': roundToDouble(taxSummary.sgst, 2),
      'igst_amount': roundToDouble(taxSummary.igst, 2),
      'cess_amount': roundToDouble(taxSummary.cess, 2),
      'total_amount': roundToDouble(taxSummary.total, 2),
      'notes': nullIfEmpty(_notesController.text),
      'is_active': _isActive,
      'lines': _lines.map(_linePayload).toList(growable: false),
    };
    try {
      final response = _selectedItem == null
          ? await _salesService.createReturn(SalesReturnModel(payload))
          : await _salesService.updateReturn(
              intValue(_selectedItem!.toJson(), 'id')!,
              SalesReturnModel(payload),
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
    Future<ApiResponse<SalesReturnModel>> Function() action,
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
        label: 'New Return',
      ),
    ];
    final content = _buildContent();
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'Sales Returns',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading sales returns...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load sales returns',
        message: _pageError!,
        onRetry: _loadPage,
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Sales Returns',
      editorTitle: _selectedItem == null
          ? 'New Sales Return'
          : stringValue(_selectedItem!.toJson(), 'return_no', 'Sales Return'),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: PurchaseListCard<SalesReturnModel>(
        items: _filteredItems,
        selectedItem: _selectedItem,
        emptyMessage: 'No sales returns found.',
        searchController: _searchController,
        searchHint: 'Search returns',
        statusValue: _statusFilter,
        statusItems: _statusItems,
        onStatusChanged: (value) {
          _statusFilter = value ?? '';
          _applyFilters();
        },
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'return_no', 'Draft Return'),
            subtitle: [
              displayDate(nullableStringValue(data, 'return_date')),
              stringValue(data, 'return_status'),
            ].where((value) => value.isNotEmpty).join(' · '),
            detail: stringValue(data, 'reason'),
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
                  labelText: 'Return No',
                  controller: _returnNoController,
                  hintText: 'Auto-generated on save',
                  validator: Validators.optionalMaxLength(100, 'Return No'),
                ),
                AppFormTextField(
                  labelText: 'Return Date',
                  controller: _returnDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([
                    Validators.required('Return Date'),
                    Validators.date('Return Date'),
                  ]),
                ),
                AppSearchPickerField<int>(
                  labelText: 'Sales Invoice',
                  selectedLabel: _invoiceOptions
                      .cast<SalesInvoiceModel?>()
                      .firstWhere(
                        (item) => item?.id == _salesInvoiceId,
                        orElse: () => null,
                      )
                      ?.invoiceNo,
                  options: _invoiceOptions
                      .map(
                        (item) => AppSearchPickerOption<int>(
                          value: item.id,
                          label: item.invoiceNo ?? 'Invoice',
                          subtitle: [
                            displayDate(
                              item.invoiceDate.isEmpty
                                  ? null
                                  : item.invoiceDate,
                            ),
                            item.invoiceStatus ?? '',
                            item.totalAmount == null
                                ? ''
                                : item.totalAmount!.toStringAsFixed(2),
                          ].where((part) => part.isNotEmpty).join(' · '),
                          searchText: [
                            item.invoiceNo ?? '',
                            item.invoiceStatus ?? '',
                            item.totalAmount?.toString() ?? '',
                          ].join(' '),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _handleInvoiceChanged,
                  validator: Validators.required('Sales Invoice'),
                ),
                AppFormTextField(
                  labelText: 'Reason',
                  controller: _reasonController,
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
              final breakdown = _taxBreakdownForLine(line);
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: AppUiConstants.spacingSm,
                ),
                child: PurchaseCompactLineCard(
                  index: index,
                  total: _lines.length,
                  removeEnabled: _lines.length > 1,
                  onRemove: () => _removeLine(index),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PurchaseCompactFieldGrid(
                        children: [
                          AppSearchPickerField<int>(
                            labelText: 'Sales Invoice Line',
                            selectedLabel: (() {
                              final selected = _invoiceLineOptions
                                  .cast<SalesInvoiceLineModel?>()
                                  .firstWhere(
                                    (item) =>
                                        item?.id == line.salesInvoiceLineId,
                                    orElse: () => null,
                                  );
                              if (selected == null) {
                                return null;
                              }
                              return '${_itemName(selected.itemId)} · Qty ${selected.invoicedQty}';
                            })(),
                            options: _invoiceLineOptions
                                .where((item) => item.id != null)
                                .map(
                                  (item) => AppSearchPickerOption<int>(
                                    value: item.id!,
                                    label:
                                        '${_itemName(item.itemId)} · Qty ${item.invoicedQty}',
                                    subtitle:
                                        '${_warehouseName(item.warehouseId)} · ${_uomName(item.uomId)}',
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) => setState(() {
                              final selected = _invoiceLineOptions
                                  .cast<SalesInvoiceLineModel?>()
                                  .firstWhere(
                                    (item) => item?.id == value,
                                    orElse: () => null,
                                  );
                              if (selected == null) {
                                line.applyInvoiceLine(null);
                                return;
                              }
                              line.applyInvoiceLine(selected);
                              line.itemNameController.text = _itemName(
                                selected.itemId,
                              );
                              line.warehouseNameController.text =
                                  _warehouseName(selected.warehouseId);
                              line.uomNameController.text = _uomName(
                                selected.uomId,
                              );
                            }),
                            validator: (_) => line.salesInvoiceLineId == null
                                ? 'Sales invoice line is required'
                                : null,
                          ),
                          AppFormTextField(
                            labelText: 'Item',
                            controller: line.itemNameController,
                            readOnly: true,
                          ),
                          AppFormTextField(
                            labelText: 'Warehouse',
                            controller: line.warehouseNameController,
                            readOnly: true,
                          ),
                          AppFormTextField(
                            labelText: 'UOM',
                            controller: line.uomNameController,
                            readOnly: true,
                          ),
                          AppFormTextField(
                            labelText: 'Return Qty',
                            controller: line.returnQtyController,
                            onChanged: (_) => setState(() {}),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: Validators.compose([
                              Validators.required('Return Qty'),
                              Validators.optionalNonNegativeNumber(
                                'Return Qty',
                              ),
                            ]),
                          ),
                          AppFormTextField(
                            labelText: 'Rate',
                            controller: line.rateController,
                            onChanged: (_) => setState(() {}),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: Validators.optionalNonNegativeNumber(
                              'Rate',
                            ),
                          ),
                          AppFormTextField(
                            labelText: 'Remarks',
                            controller: line.remarksController,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppUiConstants.spacingSm),
                      SalesLineTaxPreview(
                        gross: breakdown.gross,
                        taxable: breakdown.taxable,
                        cgst: breakdown.cgst,
                        sgst: breakdown.sgst,
                        igst: breakdown.igst,
                        cess: breakdown.cess,
                        total: breakdown.total,
                        currencyCode: _currencyCodeForTaxSummary,
                        taxCodeLabel: salesTaxCodeById(
                          _taxCodes,
                          line.taxCodeId,
                        )?.toString(),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppUiConstants.spacingMd),
            _buildTaxSummaryCard(context),
            const SizedBox(height: AppUiConstants.spacingMd),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: _selectedItem == null
                      ? 'Save Return'
                      : 'Update Return',
                  onPressed: _save,
                  busy: _saving,
                ),
                if (_selectedItem != null) ...[
                  AppActionButton(
                    icon: Icons.publish_outlined,
                    label: 'Post',
                    filled: false,
                    onPressed: () => _docAction(
                      () => _salesService.postReturn(
                        intValue(_selectedItem!.toJson(), 'id')!,
                        SalesReturnModel(const <String, dynamic>{}),
                      ),
                    ),
                  ),
                  AppActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Cancel',
                    filled: false,
                    onPressed: () => _docAction(
                      () => _salesService.cancelReturn(
                        intValue(_selectedItem!.toJson(), 'id')!,
                        SalesReturnModel(const <String, dynamic>{}),
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

class _SalesReturnLineDraft {
  _SalesReturnLineDraft({
    this.salesInvoiceLineId,
    this.taxCodeId,
    this.taxPercent,
    this.taxType,
    this.discountPercent,
    String? itemName,
    String? warehouseName,
    String? uomName,
    String? returnQty,
    String? rate,
    String? remarks,
  }) : itemNameController = TextEditingController(text: itemName ?? ''),
       warehouseNameController = TextEditingController(
         text: warehouseName ?? '',
       ),
       uomNameController = TextEditingController(text: uomName ?? ''),
       returnQtyController = TextEditingController(text: returnQty ?? ''),
       rateController = TextEditingController(text: rate ?? ''),
       remarksController = TextEditingController(text: remarks ?? '');

  factory _SalesReturnLineDraft.fromInvoiceLine(SalesInvoiceLineModel line) {
    return _SalesReturnLineDraft(
      salesInvoiceLineId: line.id,
      returnQty: line.invoicedQty.toString(),
      rate: line.rate.toString(),
    )..applyInvoiceLine(line);
  }

  factory _SalesReturnLineDraft.fromJson(Map<String, dynamic> json) {
    final draft = _SalesReturnLineDraft(
      salesInvoiceLineId: intValue(json, 'sales_invoice_line_id'),
      taxCodeId: intValue(json, 'tax_code_id'),
      taxPercent: double.tryParse(json['tax_percent']?.toString() ?? ''),
      taxType: stringValue(json, 'tax_type'),
      discountPercent: double.tryParse(
        json['discount_percent']?.toString() ?? '',
      ),
      returnQty: stringValue(json, 'return_qty'),
      rate: stringValue(json, 'rate'),
      remarks: stringValue(json, 'remarks'),
    );
    draft.itemId = intValue(json, 'item_id');
    draft.warehouseId = intValue(json, 'warehouse_id');
    draft.uomId = intValue(json, 'uom_id');
    return draft;
  }

  int? salesInvoiceLineId;
  int? itemId;
  int? warehouseId;
  int? uomId;
  int? taxCodeId;
  double? taxPercent;
  String? taxType;
  double? discountPercent;
  final TextEditingController itemNameController;
  final TextEditingController warehouseNameController;
  final TextEditingController uomNameController;
  final TextEditingController returnQtyController;
  final TextEditingController rateController;
  final TextEditingController remarksController;

  void applyInvoiceLine(SalesInvoiceLineModel? line) {
    salesInvoiceLineId = line?.id;
    itemId = line?.itemId;
    warehouseId = line?.warehouseId;
    uomId = line?.uomId;
    taxCodeId = line?.taxCodeId;
    taxPercent = line?.taxPercent;
    taxType = line?.taxType;
    discountPercent = line?.discountPercent;
    itemNameController.text = '';
    warehouseNameController.text = '';
    uomNameController.text = '';
    if (line != null) {
      rateController.text = line.rate.toString();
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sales_invoice_line_id': salesInvoiceLineId,
      'item_id': itemId,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      'uom_id': uomId,
      if (taxCodeId != null) 'tax_code_id': taxCodeId,
      if (discountPercent != null) 'discount_percent': discountPercent,
      if (taxPercent != null) 'tax_percent': taxPercent,
      'return_qty': double.tryParse(returnQtyController.text.trim()) ?? 0,
      'rate': double.tryParse(rateController.text.trim()) ?? 0,
      'remarks': nullIfEmpty(remarksController.text),
    };
  }
}
