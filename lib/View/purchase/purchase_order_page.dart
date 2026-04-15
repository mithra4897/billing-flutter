import '../../screen.dart';
import 'purchase_support.dart';

class PurchaseOrderPage extends StatefulWidget {
  const PurchaseOrderPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<PurchaseOrderPage> createState() => _PurchaseOrderPageState();
}

class _PurchaseOrderPageState extends State<PurchaseOrderPage> {
  static const List<AppDropdownItem<String>>
  _statusItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'confirmed', label: 'Confirmed'),
    AppDropdownItem(value: 'partially_received', label: 'Partially Received'),
    AppDropdownItem(value: 'fully_received', label: 'Fully Received'),
    AppDropdownItem(value: 'partially_invoiced', label: 'Partially Invoiced'),
    AppDropdownItem(value: 'fully_invoiced', label: 'Fully Invoiced'),
    AppDropdownItem(value: 'closed', label: 'Closed'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  final PurchaseService _purchaseService = PurchaseService();
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final InventoryService _inventoryService = InventoryService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _orderNoController = TextEditingController();
  final TextEditingController _orderDateController = TextEditingController();
  final TextEditingController _expectedReceiptDateController =
      TextEditingController();
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
  List<PurchaseOrderModel> _items = const <PurchaseOrderModel>[];
  List<PurchaseOrderModel> _filteredItems = const <PurchaseOrderModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<BranchModel> _branches = const <BranchModel>[];
  List<BusinessLocationModel> _locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> _financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> _documentSeries = const <DocumentSeriesModel>[];
  List<PurchaseRequisitionModel> _requisitions =
      const <PurchaseRequisitionModel>[];
  List<PartyModel> _suppliers = const <PartyModel>[];
  List<ItemModel> _itemsLookup = const <ItemModel>[];
  List<UomModel> _uoms = const <UomModel>[];
  List<UomConversionModel> _uomConversions = const <UomConversionModel>[];
  List<WarehouseModel> _warehouses = const <WarehouseModel>[];
  List<TaxCodeModel> _taxCodes = const <TaxCodeModel>[];
  PurchaseOrderModel? _selectedItem;
  int? _contextCompanyId;
  int? _contextBranchId;
  int? _contextLocationId;
  int? _contextFinancialYearId;
  int? _companyId;
  int? _branchId;
  int? _locationId;
  int? _financialYearId;
  int? _documentSeriesId;
  int? _purchaseRequisitionId;
  int? _supplierPartyId;
  bool _isActive = true;
  List<_PurchaseOrderLineDraft> _lines = <_PurchaseOrderLineDraft>[];

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
    _orderNoController.dispose();
    _orderDateController.dispose();
    _expectedReceiptDateController.dispose();
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
        _purchaseService.orders(
          filters: const {'per_page': 200, 'sort_by': 'order_date'},
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
        _purchaseService.requisitionsAll(
          filters: const {'sort_by': 'requisition_date'},
        ),
        _partiesService.partyTypes(filters: const {'per_page': 100}),
        _partiesService.parties(
          filters: const {'per_page': 300, 'sort_by': 'party_name'},
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
            (responses[0] as PaginatedResponse<PurchaseOrderModel>).data ??
            const <PurchaseOrderModel>[];
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
        _requisitions =
            (responses[6] as ApiResponse<List<PurchaseRequisitionModel>>)
                .data ??
            const <PurchaseRequisitionModel>[];
        _suppliers = purchaseSuppliers(
          parties:
              ((responses[8] as PaginatedResponse<PartyModel>).data ??
              const <PartyModel>[]),
          partyTypes:
              (responses[7] as PaginatedResponse<PartyTypeModel>).data ??
              const <PartyTypeModel>[],
        );
        _itemsLookup =
            ((responses[9] as PaginatedResponse<ItemModel>).data ??
                    const <ItemModel>[])
                .where((item) => item.isActive)
                .toList();
        _uoms =
            ((responses[10] as PaginatedResponse<UomModel>).data ??
                    const <UomModel>[])
                .where((item) => item.isActive)
                .toList();
        _uomConversions =
            ((responses[11] as ApiResponse<List<UomConversionModel>>).data ??
                    const <UomConversionModel>[])
                .where((item) => item.isActive)
                .toList();
        _warehouses =
            ((responses[12] as PaginatedResponse<WarehouseModel>).data ??
                    const <WarehouseModel>[])
                .where((item) => item.isActive)
                .toList();
        _taxCodes =
            ((responses[13] as PaginatedResponse<TaxCodeModel>).data ??
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
          ? _items.cast<PurchaseOrderModel?>().firstWhere(
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

  Future<void> _selectDocument(PurchaseOrderModel item) async {
    final id = intValue(item.toJson(), 'id');
    if (id == null) return;
    final response = await _purchaseService.order(id);
    final full = response.data ?? item;
    final data = full.toJson();
    final lines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(_PurchaseOrderLineDraft.fromJson)
        .toList(growable: true);
    setState(() {
      _selectedItem = full;
      _companyId = intValue(data, 'company_id');
      _branchId = intValue(data, 'branch_id');
      _locationId = intValue(data, 'location_id');
      _financialYearId = intValue(data, 'financial_year_id');
      _documentSeriesId = intValue(data, 'document_series_id');
      _purchaseRequisitionId = intValue(data, 'purchase_requisition_id');
      _supplierPartyId = intValue(data, 'supplier_party_id');
      _orderNoController.text = stringValue(data, 'order_no');
      _orderDateController.text = displayDate(
        nullableStringValue(data, 'order_date'),
      );
      _expectedReceiptDateController.text = displayDate(
        nullableStringValue(data, 'expected_receipt_date'),
      );
      _supplierReferenceNoController.text = stringValue(
        data,
        'supplier_reference_no',
      );
      _supplierReferenceDateController.text = displayDate(
        nullableStringValue(data, 'supplier_reference_date'),
      );
      _currencyCodeController.text = stringValue(data, 'currency_code', 'INR');
      _exchangeRateController.text = stringValue(data, 'exchange_rate', '1');
      _notesController.text = stringValue(data, 'notes');
      _termsController.text = stringValue(data, 'terms_conditions');
      _isActive = boolValue(data, 'is_active', fallback: true);
      _lines = lines.isEmpty
          ? <_PurchaseOrderLineDraft>[_PurchaseOrderLineDraft()]
          : lines;
      _formError = null;
    });
  }

  void _resetForm() {
    final seriesOptions = _seriesOptions();
    setState(() {
      _selectedItem = null;
      _companyId = _contextCompanyId;
      _branchId = _contextBranchId;
      _locationId = _contextLocationId;
      _financialYearId = _contextFinancialYearId;
      _documentSeriesId = seriesOptions.isNotEmpty
          ? seriesOptions.first.id
          : null;
      _purchaseRequisitionId = null;
      _supplierPartyId = null;
      _orderNoController.clear();
      _orderDateController.text = DateTime.now()
          .toIso8601String()
          .split('T')
          .first;
      _expectedReceiptDateController.clear();
      _supplierReferenceNoController.clear();
      _supplierReferenceDateController.clear();
      _currencyCodeController.text = 'INR';
      _exchangeRateController.text = '1';
      _notesController.clear();
      _termsController.clear();
      _isActive = true;
      _lines = <_PurchaseOrderLineDraft>[_PurchaseOrderLineDraft()];
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
                stringValue(data, 'order_status') == _statusFilter;
            final searchOk =
                search.isEmpty ||
                [
                  stringValue(data, 'order_no'),
                  stringValue(data, 'order_status'),
                  stringValue(data, 'supplier_name'),
                  stringValue(data, 'supplier_reference_no'),
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
              item.documentType == 'PURCHASE_ORDER';
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
      _lines = List<_PurchaseOrderLineDraft>.from(_lines)
        ..add(_PurchaseOrderLineDraft());
    });
  }

  void _removeLine(int index) {
    setState(() {
      _lines = List<_PurchaseOrderLineDraft>.from(_lines)..removeAt(index);
      if (_lines.isEmpty) _lines.add(_PurchaseOrderLineDraft());
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lines.any(
      (line) =>
          line.itemId == null ||
          line.uomId == null ||
          (double.tryParse(line.qtyController.text.trim()) ?? 0) <= 0,
    )) {
      setState(
        () => _formError = 'Each line needs item, UOM, and ordered quantity.',
      );
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
      'purchase_requisition_id': _purchaseRequisitionId,
      'order_no': nullIfEmpty(_orderNoController.text),
      'order_date': _orderDateController.text.trim(),
      'expected_receipt_date': nullIfEmpty(_expectedReceiptDateController.text),
      'supplier_party_id': _supplierPartyId,
      'supplier_reference_no': nullIfEmpty(_supplierReferenceNoController.text),
      'supplier_reference_date': nullIfEmpty(
        _supplierReferenceDateController.text,
      ),
      'currency_code': nullIfEmpty(_currencyCodeController.text) ?? 'INR',
      'exchange_rate':
          double.tryParse(_exchangeRateController.text.trim()) ?? 1,
      'notes': nullIfEmpty(_notesController.text),
      'terms_conditions': nullIfEmpty(_termsController.text),
      'is_active': _isActive,
      'lines': _lines.map((line) => line.toJson()).toList(growable: false),
    };

    try {
      final response = _selectedItem == null
          ? await _purchaseService.createOrder(PurchaseOrderModel(payload))
          : await _purchaseService.updateOrder(
              intValue(_selectedItem!.toJson(), 'id')!,
              PurchaseOrderModel(payload),
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
    Future<ApiResponse<PurchaseOrderModel>> Function() action,
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
        label: 'New Order',
      ),
    ];
    final content = _buildContent();
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'Purchase Orders',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading purchase orders...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load purchase orders',
        message: _pageError!,
        onRetry: _loadPage,
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Purchase Orders',
      editorTitle: _selectedItem == null
          ? 'New Purchase Order'
          : stringValue(_selectedItem!.toJson(), 'order_no', 'Purchase Order'),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: PurchaseListCard<PurchaseOrderModel>(
        items: _filteredItems,
        selectedItem: _selectedItem,
        emptyMessage: 'No purchase orders found.',
        searchController: _searchController,
        searchHint: 'Search orders',
        statusValue: _statusFilter,
        statusItems: _statusItems,
        onStatusChanged: (value) {
          _statusFilter = value ?? '';
          _applyFilters();
        },
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'order_no', 'Draft Order'),
            subtitle: [
              displayDate(nullableStringValue(data, 'order_date')),
              stringValue(data, 'order_status'),
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
                    final options = _seriesOptions();
                    _documentSeriesId = options.isNotEmpty
                        ? options.first.id
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
                    final options = _seriesOptions();
                    _documentSeriesId = options.isNotEmpty
                        ? options.first.id
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
                  labelText: 'Order No',
                  controller: _orderNoController,
                  hintText: 'Auto-generated on save',
                  validator: Validators.optionalMaxLength(100, 'Order No'),
                ),
                AppFormTextField(
                  labelText: 'Order Date',
                  controller: _orderDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([
                    Validators.required('Order Date'),
                    Validators.date('Order Date'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Expected Receipt Date',
                  controller: _expectedReceiptDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDate('Expected Receipt Date'),
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
                  labelText: 'Requisition',
                  mappedItems: _requisitions
                      .where((item) => intValue(item.toJson(), 'id') != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: intValue(item.toJson(), 'id')!,
                          label: stringValue(
                            item.toJson(),
                            'requisition_no',
                            'Requisition',
                          ),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _purchaseRequisitionId,
                  onChanged: (value) =>
                      setState(() => _purchaseRequisitionId = value),
                ),
                AppFormTextField(
                  labelText: 'Supplier Ref No',
                  controller: _supplierReferenceNoController,
                  validator: Validators.optionalMaxLength(
                    100,
                    'Supplier Ref No',
                  ),
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
                  validator: Validators.optionalMaxLength(10, 'Currency'),
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
                child: AppSectionCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('Line ${index + 1}'),
                          const Spacer(),
                          IconButton(
                            onPressed: _lines.length == 1
                                ? null
                                : () => _removeLine(index),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                      SettingsFormWrap(
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
                            onChanged: (value) => setState(() {
                              line.itemId = value;
                              line.uomId = _resolveDefaultUom(
                                value,
                                line.uomId,
                              );
                            }),
                            validator: (_) =>
                                line.itemId == null ? 'Item is required' : null,
                          ),
                          Builder(
                            builder: (context) {
                              final options = _uomOptionsForItem(line.itemId);
                              if (options.length <= 1) {
                                final onlyId = options.isNotEmpty
                                    ? options.first.id
                                    : null;
                                if (line.uomId != onlyId) {
                                  line.uomId = onlyId;
                                }
                                return const SizedBox.shrink();
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
                                initialValue: line.uomId,
                                onChanged: (value) =>
                                    setState(() => line.uomId = value),
                                validator: Validators.requiredSelection('UOM'),
                              );
                            },
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
                            onChanged: (value) =>
                                setState(() => line.warehouseId = value),
                          ),
                          AppFormTextField(
                            labelText: 'Ordered Qty',
                            controller: line.qtyController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: Validators.compose([
                              Validators.required('Ordered Qty'),
                              Validators.optionalNonNegativeNumber(
                                'Ordered Qty',
                              ),
                            ]),
                          ),
                          AppFormTextField(
                            labelText: 'Rate',
                            controller: line.rateController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: Validators.compose([
                              Validators.required('Rate'),
                              Validators.optionalNonNegativeNumber('Rate'),
                            ]),
                          ),
                          AppFormTextField(
                            labelText: 'Discount %',
                            controller: line.discountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: Validators.optionalNonNegativeNumber(
                              'Discount %',
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
                                setState(() => line.taxCodeId = value),
                          ),
                          AppFormTextField(
                            labelText: 'Description',
                            controller: line.descriptionController,
                          ),
                          AppFormTextField(
                            labelText: 'Remarks',
                            controller: line.remarksController,
                            maxLines: 2,
                          ),
                        ],
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
                  label: _selectedItem == null ? 'Save Order' : 'Update Order',
                  onPressed: _save,
                  busy: _saving,
                ),
                if (_selectedItem != null) ...[
                  AppActionButton(
                    icon: Icons.publish_outlined,
                    label: 'Post',
                    filled: false,
                    onPressed: () => _docAction(
                      () => _purchaseService.postOrder(
                        intValue(_selectedItem!.toJson(), 'id')!,
                        PurchaseOrderModel(const <String, dynamic>{}),
                      ),
                    ),
                  ),
                  AppActionButton(
                    icon: Icons.task_alt_outlined,
                    label: 'Close',
                    filled: false,
                    onPressed: () => _docAction(
                      () => _purchaseService.closeOrder(
                        intValue(_selectedItem!.toJson(), 'id')!,
                        PurchaseOrderModel(const <String, dynamic>{}),
                      ),
                    ),
                  ),
                  AppActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Cancel',
                    filled: false,
                    onPressed: () => _docAction(
                      () => _purchaseService.cancelOrder(
                        intValue(_selectedItem!.toJson(), 'id')!,
                        PurchaseOrderModel(const <String, dynamic>{}),
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

class _PurchaseOrderLineDraft {
  _PurchaseOrderLineDraft({
    this.itemId,
    this.warehouseId,
    this.uomId,
    this.taxCodeId,
    String? description,
    String? qty,
    String? rate,
    String? discountPercent,
    String? remarks,
  }) : descriptionController = TextEditingController(text: description ?? ''),
       qtyController = TextEditingController(text: qty ?? ''),
       rateController = TextEditingController(text: rate ?? ''),
       discountController = TextEditingController(text: discountPercent ?? ''),
       remarksController = TextEditingController(text: remarks ?? '');

  factory _PurchaseOrderLineDraft.fromJson(Map<String, dynamic> json) {
    return _PurchaseOrderLineDraft(
      itemId: intValue(json, 'item_id'),
      warehouseId: intValue(json, 'warehouse_id'),
      uomId: intValue(json, 'uom_id'),
      taxCodeId: intValue(json, 'tax_code_id'),
      description: stringValue(json, 'description'),
      qty: stringValue(json, 'ordered_qty'),
      rate: stringValue(json, 'rate'),
      discountPercent: stringValue(json, 'discount_percent'),
      remarks: stringValue(json, 'remarks'),
    );
  }

  int? itemId;
  int? warehouseId;
  int? uomId;
  int? taxCodeId;
  final TextEditingController descriptionController;
  final TextEditingController qtyController;
  final TextEditingController rateController;
  final TextEditingController discountController;
  final TextEditingController remarksController;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'item_id': itemId,
      'warehouse_id': warehouseId,
      'uom_id': uomId,
      'tax_code_id': taxCodeId,
      'description': nullIfEmpty(descriptionController.text),
      'ordered_qty': double.tryParse(qtyController.text.trim()) ?? 0,
      'rate': double.tryParse(rateController.text.trim()) ?? 0,
      'discount_percent': double.tryParse(discountController.text.trim()) ?? 0,
      'remarks': nullIfEmpty(remarksController.text),
    };
  }
}
