import '../../screen.dart';
import 'purchase_support.dart';

class PurchaseReturnPage extends StatefulWidget {
  const PurchaseReturnPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<PurchaseReturnPage> createState() => _PurchaseReturnPageState();
}

class _PurchaseReturnPageState extends State<PurchaseReturnPage> {
  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All'),
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'posted', label: 'Posted'),
        AppDropdownItem(value: 'debited', label: 'Debited'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  final PurchaseService _purchaseService = PurchaseService();
  final MasterService _masterService = MasterService();
  final InventoryService _inventoryService = InventoryService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _returnNoController = TextEditingController();
  final TextEditingController _returnDateController = TextEditingController();
  final TextEditingController _returnReasonController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  String _statusFilter = '';
  List<PurchaseReturnModel> _items = const <PurchaseReturnModel>[];
  List<PurchaseReturnModel> _filteredItems = const <PurchaseReturnModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<BranchModel> _branches = const <BranchModel>[];
  List<BusinessLocationModel> _locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> _financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> _documentSeries = const <DocumentSeriesModel>[];
  List<PurchaseInvoiceModel> _invoices = const <PurchaseInvoiceModel>[];
  List<PurchaseInvoiceLineModel> _invoiceLines =
      const <PurchaseInvoiceLineModel>[];
  List<ItemModel> _itemsLookup = const <ItemModel>[];
  List<UomModel> _uoms = const <UomModel>[];
  List<WarehouseModel> _warehouses = const <WarehouseModel>[];
  PurchaseReturnModel? _selectedItem;
  int? _contextCompanyId;
  int? _contextBranchId;
  int? _contextLocationId;
  int? _contextFinancialYearId;
  int? _companyId;
  int? _branchId;
  int? _locationId;
  int? _financialYearId;
  int? _documentSeriesId;
  int? _purchaseInvoiceId;
  int? _supplierPartyId;
  bool _isActive = true;
  List<_PurchaseReturnLineDraft> _lines = <_PurchaseReturnLineDraft>[];

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
    _returnReasonController.dispose();
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
        _purchaseService.returns(
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
        _purchaseService.invoices(
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
            (responses[0] as PaginatedResponse<PurchaseReturnModel>).data ??
            const <PurchaseReturnModel>[];
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
            (responses[6] as PaginatedResponse<PurchaseInvoiceModel>).data ??
            const <PurchaseInvoiceModel>[];
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
        _contextCompanyId = contextSelection.companyId;
        _contextBranchId = contextSelection.branchId;
        _contextLocationId = contextSelection.locationId;
        _contextFinancialYearId = contextSelection.financialYearId;
        _initialLoading = false;
      });
      _applyFilters();
      final selected = selectId != null
          ? _items.cast<PurchaseReturnModel?>().firstWhere(
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

  Future<void> _selectDocument(PurchaseReturnModel item) async {
    final id = intValue(item.toJson(), 'id');
    if (id == null) return;
    final response = await _purchaseService.returnDoc(id);
    final full = response.data ?? item;
    final data = full.toJson();
    final lines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(_PurchaseReturnLineDraft.fromJson)
        .toList(growable: true);
    final invoiceId = intValue(data, 'purchase_invoice_id');
    final invoiceResponse = invoiceId == null
        ? null
        : await _purchaseService.invoice(invoiceId);
    final invoiceLines =
        invoiceResponse?.data?.lines ?? const <PurchaseInvoiceLineModel>[];
    setState(() {
      _selectedItem = full;
      _companyId = intValue(data, 'company_id');
      _branchId = intValue(data, 'branch_id');
      _locationId = intValue(data, 'location_id');
      _financialYearId = intValue(data, 'financial_year_id');
      _documentSeriesId = intValue(data, 'document_series_id');
      _purchaseInvoiceId = invoiceId;
      _supplierPartyId = intValue(data, 'supplier_party_id');
      _returnNoController.text = stringValue(data, 'return_no');
      _returnDateController.text = displayDate(
        nullableStringValue(data, 'return_date'),
      );
      _returnReasonController.text = stringValue(data, 'return_reason');
      _notesController.text = stringValue(data, 'notes');
      _isActive = boolValue(data, 'is_active', fallback: true);
      _invoiceLines = invoiceLines;
      _lines = lines.isEmpty
          ? <_PurchaseReturnLineDraft>[_PurchaseReturnLineDraft()]
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
      _purchaseInvoiceId = null;
      _supplierPartyId = null;
      _returnNoController.clear();
      _returnDateController.text = DateTime.now()
          .toIso8601String()
          .split('T')
          .first;
      _returnReasonController.clear();
      _notesController.clear();
      _isActive = true;
      _invoiceLines = const <PurchaseInvoiceLineModel>[];
      _lines = <_PurchaseReturnLineDraft>[_PurchaseReturnLineDraft()];
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
              item.documentType == 'PURCHASE_RETURN';
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
  List<PurchaseInvoiceModel> get _invoiceOptions => _invoices
      .where((item) => (_companyId == null || item.companyId == _companyId))
      .toList(growable: false);

  List<PurchaseInvoiceLineModel> get _invoiceLineOptions => _invoiceLines;

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
      _purchaseInvoiceId = value;
      _supplierPartyId = null;
      _invoiceLines = const <PurchaseInvoiceLineModel>[];
      _lines = <_PurchaseReturnLineDraft>[_PurchaseReturnLineDraft()];
    });
    if (value == null) {
      return;
    }
    final response = await _purchaseService.invoice(value);
    if (!mounted) {
      return;
    }
    final invoice = response.data;
    setState(() {
      _supplierPartyId = invoice?.supplierPartyId;
      _invoiceLines = invoice?.lines ?? const <PurchaseInvoiceLineModel>[];
      _lines = _invoiceLines.isEmpty
          ? <_PurchaseReturnLineDraft>[_PurchaseReturnLineDraft()]
          : <_PurchaseReturnLineDraft>[
              _PurchaseReturnLineDraft.fromInvoiceLine(_invoiceLines.first),
            ];
    });
    _syncLineDisplayNames();
  }

  void _syncLineDisplayNames() {
    for (final line in _lines) {
      line.itemNameController.text = _itemName(line.itemId);
      line.warehouseNameController.text = _warehouseName(line.warehouseId);
      line.uomNameController.text = _uomName(line.uomId);
    }
  }

  void _addLine() => setState(
    () =>
        _lines = List<_PurchaseReturnLineDraft>.from(_lines)
          ..add(_PurchaseReturnLineDraft()),
  );

  void _removeLine(int index) {
    setState(() {
      _lines = List<_PurchaseReturnLineDraft>.from(_lines)..removeAt(index);
      if (_lines.isEmpty) _lines.add(_PurchaseReturnLineDraft());
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_purchaseInvoiceId == null) {
      setState(() => _formError = 'Purchase invoice is required.');
      return;
    }
    if (_lines.any(
      (line) =>
          line.purchaseInvoiceLineId == null ||
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
    final invoice = _invoiceOptions.cast<PurchaseInvoiceModel?>().firstWhere(
      (item) => item?.id == _purchaseInvoiceId,
      orElse: () => null,
    );
    final payload = <String, dynamic>{
      'company_id': _companyId,
      'branch_id': _branchId,
      'location_id': _locationId,
      'financial_year_id': _financialYearId,
      'document_series_id': _documentSeriesId,
      'purchase_invoice_id': _purchaseInvoiceId,
      'supplier_party_id': _supplierPartyId ?? invoice?.supplierPartyId,
      'return_no': nullIfEmpty(_returnNoController.text),
      'return_date': _returnDateController.text.trim(),
      'return_reason': nullIfEmpty(_returnReasonController.text),
      'notes': nullIfEmpty(_notesController.text),
      'is_active': _isActive,
      'lines': _lines.map((item) => item.toJson()).toList(growable: false),
    };
    try {
      final response = _selectedItem == null
          ? await _purchaseService.createReturn(PurchaseReturnModel(payload))
          : await _purchaseService.updateReturn(
              intValue(_selectedItem!.toJson(), 'id')!,
              PurchaseReturnModel(payload),
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
    Future<ApiResponse<PurchaseReturnModel>> Function() action,
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
      title: 'Purchase Returns',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading purchase returns...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load purchase returns',
        message: _pageError!,
        onRetry: _loadPage,
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Purchase Returns',
      editorTitle: _selectedItem == null
          ? 'New Purchase Return'
          : stringValue(
              _selectedItem!.toJson(),
              'return_no',
              'Purchase Return',
            ),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: PurchaseListCard<PurchaseReturnModel>(
        items: _filteredItems,
        selectedItem: _selectedItem,
        emptyMessage: 'No purchase returns found.',
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
            detail: stringValue(data, 'return_reason'),
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
                AppDropdownField<int>.fromMapped(
                  labelText: 'Purchase Invoice',
                  mappedItems: _invoiceOptions
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id,
                          label: item.invoiceNo ?? 'Invoice',
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _purchaseInvoiceId,
                  onChanged: _handleInvoiceChanged,
                  validator: Validators.requiredSelection('Purchase Invoice'),
                ),
                AppFormTextField(
                  labelText: 'Return Reason',
                  controller: _returnReasonController,
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
                        labelText: 'Purchase Invoice Line',
                        selectedLabel: (() {
                          final selected = _invoiceLineOptions
                              .cast<PurchaseInvoiceLineModel?>()
                              .firstWhere(
                                (item) =>
                                    item?.id == line.purchaseInvoiceLineId,
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
                              .cast<PurchaseInvoiceLineModel?>()
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
                          line.warehouseNameController.text = _warehouseName(
                            selected.warehouseId,
                          );
                          line.uomNameController.text = _uomName(
                            selected.uomId,
                          );
                        }),
                        validator: (_) => line.purchaseInvoiceLineId == null
                            ? 'Purchase Invoice Line is required'
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
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.compose([
                          Validators.required('Return Qty'),
                          Validators.optionalNonNegativeNumber('Return Qty'),
                        ]),
                      ),
                      AppFormTextField(
                        labelText: 'Rate',
                        controller: line.rateController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.optionalNonNegativeNumber('Rate'),
                      ),
                      AppFormTextField(
                        labelText: 'Return Reason',
                        controller: line.returnReasonController,
                      ),
                      AppFormTextField(
                        labelText: 'Remarks',
                        controller: line.remarksController,
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
                      () => _purchaseService.postReturn(
                        intValue(_selectedItem!.toJson(), 'id')!,
                        PurchaseReturnModel(const <String, dynamic>{}),
                      ),
                    ),
                  ),
                  AppActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Cancel',
                    filled: false,
                    onPressed: () => _docAction(
                      () => _purchaseService.cancelReturn(
                        intValue(_selectedItem!.toJson(), 'id')!,
                        PurchaseReturnModel(const <String, dynamic>{}),
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

class _PurchaseReturnLineDraft {
  _PurchaseReturnLineDraft({
    this.purchaseInvoiceLineId,
    String? itemName,
    String? warehouseName,
    String? uomName,
    String? returnQty,
    String? rate,
    String? returnReason,
    String? remarks,
  }) : itemNameController = TextEditingController(text: itemName ?? ''),
       warehouseNameController = TextEditingController(
         text: warehouseName ?? '',
       ),
       uomNameController = TextEditingController(text: uomName ?? ''),
       returnQtyController = TextEditingController(text: returnQty ?? ''),
       rateController = TextEditingController(text: rate ?? ''),
       returnReasonController = TextEditingController(text: returnReason ?? ''),
       remarksController = TextEditingController(text: remarks ?? '');

  factory _PurchaseReturnLineDraft.fromInvoiceLine(
    PurchaseInvoiceLineModel line,
  ) {
    return _PurchaseReturnLineDraft(
      purchaseInvoiceLineId: line.id,
      returnQty: line.invoicedQty.toString(),
      rate: line.rate.toString(),
    )..applyInvoiceLine(line);
  }

  factory _PurchaseReturnLineDraft.fromJson(Map<String, dynamic> json) {
    return _PurchaseReturnLineDraft(
      purchaseInvoiceLineId: intValue(json, 'purchase_invoice_line_id'),
      returnQty: stringValue(json, 'return_qty'),
      rate: stringValue(json, 'rate'),
      returnReason: stringValue(json, 'return_reason'),
      remarks: stringValue(json, 'remarks'),
    );
  }

  int? purchaseInvoiceLineId;
  int? itemId;
  int? warehouseId;
  int? uomId;
  final TextEditingController itemNameController;
  final TextEditingController warehouseNameController;
  final TextEditingController uomNameController;
  final TextEditingController returnQtyController;
  final TextEditingController rateController;
  final TextEditingController returnReasonController;
  final TextEditingController remarksController;

  void applyInvoiceLine(PurchaseInvoiceLineModel? line) {
    purchaseInvoiceLineId = line?.id;
    itemId = line?.itemId;
    warehouseId = line?.warehouseId;
    uomId = line?.uomId;
    itemNameController.text = '';
    warehouseNameController.text = '';
    uomNameController.text = '';
    if (line != null) {
      rateController.text = line.rate.toString();
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'purchase_invoice_line_id': purchaseInvoiceLineId,
      'item_id': itemId,
      'warehouse_id': warehouseId,
      'uom_id': uomId,
      'return_qty': double.tryParse(returnQtyController.text.trim()) ?? 0,
      'rate': double.tryParse(rateController.text.trim()) ?? 0,
      'return_reason': nullIfEmpty(returnReasonController.text),
      'remarks': nullIfEmpty(remarksController.text),
    };
  }
}
