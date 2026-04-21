import '../../model/sales/sales_quotation_model.dart';
import '../../screen.dart';
import '../purchase/purchase_support.dart';
import 'sales_support.dart';

class SalesQuotationPage extends StatefulWidget {
  const SalesQuotationPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<SalesQuotationPage> createState() => _SalesQuotationPageState();
}

class _SalesQuotationPageState extends State<SalesQuotationPage> {
  static const List<AppDropdownItem<String>> _listStatusFilter =
      <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'sent', label: 'Sent'),
    AppDropdownItem(value: 'accepted', label: 'Accepted'),
    AppDropdownItem(value: 'rejected', label: 'Rejected'),
    AppDropdownItem(value: 'expired', label: 'Expired'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  final SalesService _salesService = SalesService();
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final InventoryService _inventoryService = InventoryService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _quotationNoController = TextEditingController();
  final TextEditingController _quotationDateController =
      TextEditingController();
  final TextEditingController _validUntilController = TextEditingController();
  final TextEditingController _customerRefNoController =
      TextEditingController();
  final TextEditingController _customerRefDateController =
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
  List<SalesQuotationModel> _items = const <SalesQuotationModel>[];
  List<SalesQuotationModel> _filteredItems = const <SalesQuotationModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<BranchModel> _branches = const <BranchModel>[];
  List<BusinessLocationModel> _locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> _financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> _documentSeries = const <DocumentSeriesModel>[];
  List<PartyModel> _customers = const <PartyModel>[];
  List<ItemModel> _itemsLookup = const <ItemModel>[];
  List<UomModel> _uoms = const <UomModel>[];
  List<UomConversionModel> _uomConversions = const <UomConversionModel>[];
  List<WarehouseModel> _warehouses = const <WarehouseModel>[];
  List<TaxCodeModel> _taxCodes = const <TaxCodeModel>[];
  SalesQuotationModel? _selectedItem;
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
  bool _isActive = true;
  List<_QuotationLineDraft> _lines = <_QuotationLineDraft>[];

  bool get _canEdit {
    if (_selectedItem == null) {
      return true;
    }
    return stringValue(_selectedItem!.toJson(), 'quotation_status') ==
        'draft';
  }

  String get _status =>
      stringValue(_selectedItem?.toJson() ?? const {}, 'quotation_status', 'draft');

  List<BranchModel> get _branchOptions =>
      branchesForCompany(_branches, _companyId);
  List<BusinessLocationModel> get _locationOptions =>
      locationsForBranch(_locations, _branchId);

  List<DocumentSeriesModel> _seriesOptions() {
    return _documentSeries
        .where((item) {
          final typeOk =
              item.documentType == null ||
              item.documentType == 'SALES_QUOTATION';
          final companyOk = _companyId == null || item.companyId == _companyId;
          final fyOk =
              _financialYearId == null ||
              item.financialYearId == _financialYearId;
          return typeOk && companyOk && fyOk;
        })
        .toList(growable: false);
  }

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
    _quotationNoController.dispose();
    _quotationDateController.dispose();
    _validUntilController.dispose();
    _customerRefNoController.dispose();
    _customerRefDateController.dispose();
    _currencyCodeController.dispose();
    _exchangeRateController.dispose();
    _notesController.dispose();
    _termsController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPage({int? selectId}) async {
    setState(() {
      _initialLoading = _items.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait<dynamic>([
        _salesService.quotations(
          filters: const {'per_page': 200, 'sort_by': 'quotation_date'},
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
          filters: const {'per_page': 400, 'sort_by': 'party_name'},
        ),
        _inventoryService.items(
          filters: const {'per_page': 400, 'sort_by': 'item_name'},
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

      if (!mounted) {
        return;
      }

      setState(() {
        _items =
            (responses[0] as PaginatedResponse<SalesQuotationModel>).data ??
            const <SalesQuotationModel>[];
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
              ((responses[7] as PaginatedResponse<PartyModel>).data ??
              const <PartyModel>[]),
          partyTypes:
              (responses[6] as PaginatedResponse<PartyTypeModel>).data ??
              const <PartyTypeModel>[],
        );
        _itemsLookup =
            ((responses[8] as PaginatedResponse<ItemModel>).data ??
                    const <ItemModel>[])
                .where((item) => item.isActive)
                .toList();
        _uoms =
            ((responses[9] as PaginatedResponse<UomModel>).data ??
                    const <UomModel>[])
                .where((item) => item.isActive)
                .toList();
        _uomConversions =
            ((responses[10] as PaginatedResponse<UomConversionModel>).data ??
                    const <UomConversionModel>[])
                .where((item) => item.isActive)
                .toList();
        _warehouses =
            ((responses[11] as PaginatedResponse<WarehouseModel>).data ??
                    const <WarehouseModel>[])
                .where((item) => item.isActive)
                .toList();
        _taxCodes =
            ((responses[12] as PaginatedResponse<TaxCodeModel>).data ??
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
          ? _items.cast<SalesQuotationModel?>().firstWhere(
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
      if (!mounted) {
        return;
      }
      setState(() {
        _pageError = error.toString();
        _initialLoading = false;
      });
    }
  }

  Future<void> _selectDocument(SalesQuotationModel item) async {
    final id = intValue(item.toJson(), 'id');
    if (id == null) {
      return;
    }
    final response = await _salesService.quotation(id);
    final full = response.data ?? item;
    final data = full.toJson();
    final lines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(_QuotationLineDraft.fromJson)
        .toList(growable: true);
    for (final old in _lines) {
      old.dispose();
    }
    setState(() {
      _selectedItem = full;
      _companyId = intValue(data, 'company_id');
      _branchId = intValue(data, 'branch_id');
      _locationId = intValue(data, 'location_id');
      _financialYearId = intValue(data, 'financial_year_id');
      _documentSeriesId = intValue(data, 'document_series_id');
      _customerPartyId = intValue(data, 'customer_party_id');
      _quotationNoController.text = stringValue(data, 'quotation_no');
      _quotationDateController.text = displayDate(
        nullableStringValue(data, 'quotation_date'),
      );
      _validUntilController.text = displayDate(
        nullableStringValue(data, 'valid_until'),
      );
      _customerRefNoController.text = stringValue(data, 'customer_reference_no');
      _customerRefDateController.text = displayDate(
        nullableStringValue(data, 'customer_reference_date'),
      );
      _currencyCodeController.text = stringValue(data, 'currency_code', 'INR');
      _exchangeRateController.text = stringValue(data, 'exchange_rate', '1');
      _notesController.text = stringValue(data, 'notes');
      _termsController.text = stringValue(data, 'terms_conditions');
      _isActive = boolValue(data, 'is_active', fallback: true);
      _lines = lines.isEmpty ? <_QuotationLineDraft>[_QuotationLineDraft()] : lines;
      _formError = null;
    });
  }

  void _resetForm() {
    for (final line in _lines) {
      line.dispose();
    }
    final series = _seriesOptions();
    setState(() {
      _selectedItem = null;
      _companyId = _contextCompanyId;
      _branchId = _contextBranchId;
      _locationId = _contextLocationId;
      _financialYearId = _contextFinancialYearId;
      _documentSeriesId = series.isNotEmpty ? series.first.id : null;
      _customerPartyId = null;
      _quotationNoController.clear();
      _quotationDateController.text = DateTime.now()
          .toIso8601String()
          .split('T')
          .first;
      _validUntilController.clear();
      _customerRefNoController.clear();
      _customerRefDateController.clear();
      _currencyCodeController.text = 'INR';
      _exchangeRateController.text = '1';
      _notesController.clear();
      _termsController.clear();
      _isActive = true;
      _lines = <_QuotationLineDraft>[_QuotationLineDraft()];
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
                stringValue(data, 'quotation_status') == _statusFilter;
            final cust = quotationCustomerLabel(data);
            final searchOk =
                search.isEmpty ||
                [
                  stringValue(data, 'quotation_no'),
                  stringValue(data, 'quotation_status'),
                  cust,
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
    return defaultSalesUomIdForItem(
      item,
      _uoms,
      _uomConversions,
      current: currentUomId,
    );
  }

  void _addLine() {
    setState(() {
      _lines = List<_QuotationLineDraft>.from(_lines)..add(_QuotationLineDraft());
    });
  }

  void _removeLine(int index) {
    setState(() {
      final next = List<_QuotationLineDraft>.from(_lines);
      next.removeAt(index).dispose();
      _lines = next.isEmpty ? <_QuotationLineDraft>[_QuotationLineDraft()] : next;
    });
  }

  Future<void> _save() async {
    if (!_canEdit) {
      setState(() {
        _formError = 'Only draft quotations can be updated.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_lines.any(
      (line) =>
          line.itemId == null ||
          line.uomId == null ||
          (double.tryParse(line.qtyController.text.trim()) ?? 0) <= 0,
    )) {
      setState(
        () => _formError = 'Each line needs item, UOM, and quantity.',
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
      'quotation_no': nullIfEmpty(_quotationNoController.text),
      'quotation_date': _quotationDateController.text.trim(),
      'valid_until': nullIfEmpty(_validUntilController.text),
      'customer_party_id': _customerPartyId,
      'customer_reference_no': nullIfEmpty(_customerRefNoController.text),
      'customer_reference_date': nullIfEmpty(_customerRefDateController.text),
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
          ? await _salesService.createQuotation(SalesQuotationModel(payload))
          : await _salesService.updateQuotation(
              intValue(_selectedItem!.toJson(), 'id')!,
              SalesQuotationModel(payload),
            );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage(
        selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _docAction(
    Future<ApiResponse<SalesQuotationModel>> Function() action,
  ) async {
    try {
      final response = await action();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage(
        selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _formError = error.toString());
    }
  }

  Future<void> _delete() async {
    final id = intValue(_selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) {
      return;
    }
    try {
      final response = await _salesService.deleteQuotation(id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _formError = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: () {
          _resetForm();
          if (!Responsive.isDesktop(context)) {
            _workspaceController.openEditor();
          }
        },
        icon: Icons.add_outlined,
        label: 'New Quote',
      ),
    ];
    final content = _buildContent();
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'Sales Quotations',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading quotations...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load quotations',
        message: _pageError!,
        onRetry: _loadPage,
      );
    }

    final sel = _selectedItem?.toJson() ?? const {};
    final totalStr = stringValue(sel, 'total_amount');

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Sales Quotations',
      editorTitle: _selectedItem == null
          ? 'New Quotation'
          : stringValue(sel, 'quotation_no', 'Quotation'),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: PurchaseListCard<SalesQuotationModel>(
        items: _filteredItems,
        selectedItem: _selectedItem,
        emptyMessage: 'No quotations yet.',
        searchController: _searchController,
        searchHint: 'Search by number or customer',
        statusValue: _statusFilter,
        statusItems: _listStatusFilter,
        onStatusChanged: (value) {
          _statusFilter = value ?? '';
          _applyFilters();
        },
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'quotation_no', 'Draft'),
            subtitle: [
              displayDate(nullableStringValue(data, 'quotation_date')),
              stringValue(data, 'quotation_status'),
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
            if (_selectedItem != null && totalStr.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
                child: Text(
                  'Total: $totalStr ${_currencyCodeController.text.trim().isEmpty ? 'INR' : _currencyCodeController.text.trim()} · Status: ${_status.toUpperCase()}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
                  onChanged: (value) {
                    if (!_canEdit) {
                      return;
                    }
                    setState(() {
                      _companyId = value;
                      _branchId = null;
                      _locationId = null;
                      final options = _seriesOptions();
                      _documentSeriesId =
                          options.isNotEmpty ? options.first.id : null;
                    });
                  },
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
                  onChanged: (value) {
                    if (!_canEdit) {
                      return;
                    }
                    setState(() {
                      _branchId = value;
                      _locationId = null;
                    });
                  },
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
                  onChanged: (value) {
                    if (!_canEdit) {
                      return;
                    }
                    setState(() => _locationId = value);
                  },
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
                  onChanged: (value) {
                    if (!_canEdit) {
                      return;
                    }
                    setState(() {
                      _financialYearId = value;
                      final options = _seriesOptions();
                      _documentSeriesId =
                          options.isNotEmpty ? options.first.id : null;
                    });
                  },
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
                  onChanged: (value) {
                    if (!_canEdit) {
                      return;
                    }
                    setState(() => _documentSeriesId = value);
                  },
                ),
                AppFormTextField(
                  labelText: 'Quotation No',
                  controller: _quotationNoController,
                  hintText: 'Leave blank if your series fills this in',
                  enabled: _canEdit,
                  validator: Validators.optionalMaxLength(100, 'Quotation No'),
                ),
                AppFormTextField(
                  labelText: 'Quotation Date',
                  controller: _quotationDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  enabled: _canEdit,
                  validator: Validators.compose([
                    Validators.required('Quotation Date'),
                    Validators.date('Quotation Date'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Valid Until',
                  controller: _validUntilController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  enabled: _canEdit,
                  validator: Validators.optionalDate('Valid Until'),
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
                  onChanged: (value) {
                    if (!_canEdit) {
                      return;
                    }
                    setState(() => _customerPartyId = value);
                  },
                  validator: Validators.requiredSelection('Customer'),
                ),
                AppFormTextField(
                  labelText: 'Customer PO / Ref',
                  controller: _customerRefNoController,
                  enabled: _canEdit,
                  validator: Validators.optionalMaxLength(100, 'Reference'),
                ),
                AppFormTextField(
                  labelText: 'Customer Ref Date',
                  controller: _customerRefDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  enabled: _canEdit,
                  validator: Validators.optionalDate('Customer Ref Date'),
                ),
                AppFormTextField(
                  labelText: 'Currency',
                  controller: _currencyCodeController,
                  enabled: _canEdit,
                  validator: Validators.optionalMaxLength(10, 'Currency'),
                ),
                AppFormTextField(
                  labelText: 'Exchange Rate',
                  controller: _exchangeRateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  enabled: _canEdit,
                  validator: Validators.optionalNonNegativeNumber('Exchange Rate'),
                ),
                AppFormTextField(
                  labelText: 'Notes (shown to customer)',
                  controller: _notesController,
                  maxLines: 3,
                  enabled: _canEdit,
                ),
                AppFormTextField(
                  labelText: 'Terms & Conditions',
                  controller: _termsController,
                  maxLines: 3,
                  enabled: _canEdit,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSwitchTile(
              label: 'Active',
              value: _isActive,
              onChanged: _canEdit
                  ? (value) => setState(() => _isActive = value)
                  : null,
            ),
            const SizedBox(height: AppUiConstants.spacingLg),
            Row(
              children: [
                Text(
                  'Line items',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                AppActionButton(
                  icon: Icons.add_outlined,
                  label: 'Add line',
                  onPressed: _canEdit ? _addLine : null,
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
                  removeEnabled: _canEdit && _lines.length > 1,
                  onRemove: _canEdit ? () => _removeLine(index) : null,
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
                        onChanged: (value) {
                          if (!_canEdit) {
                            return;
                          }
                          setState(() {
                            line.itemId = value;
                            line.uomId = _resolveDefaultUom(
                              value,
                              line.uomId,
                            );
                          });
                        },
                        validator: (_) =>
                            line.itemId == null ? 'Item is required' : null,
                      ),
                      Builder(
                        builder: (context) {
                          final options = _uomOptionsForItem(line.itemId);
                          if (_canEdit && options.length == 1) {
                            final onlyId = options.first.id;
                            if (line.uomId != onlyId) {
                              line.uomId = onlyId;
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
                            initialValue: line.uomId,
                            onChanged: (value) {
                              if (!_canEdit) {
                                return;
                              }
                              setState(() => line.uomId = value);
                            },
                            validator: (_) {
                              if (line.itemId == null) {
                                return 'Select item first';
                              }
                              return line.uomId == null
                                  ? 'UOM is required'
                                  : null;
                            },
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
                        onChanged: (value) {
                          if (!_canEdit) {
                            return;
                          }
                          setState(() => line.warehouseId = value);
                        },
                      ),
                      AppFormTextField(
                        labelText: 'Qty',
                        controller: line.qtyController,
                        enabled: _canEdit,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.compose([
                          Validators.required('Qty'),
                          Validators.optionalNonNegativeNumber('Qty'),
                        ]),
                      ),
                      AppFormTextField(
                        labelText: 'Rate',
                        controller: line.rateController,
                        enabled: _canEdit,
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
                        enabled: _canEdit,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.optionalNonNegativeNumber(
                          'Discount %',
                        ),
                      ),
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Tax code',
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
                        onChanged: (value) {
                          if (!_canEdit) {
                            return;
                          }
                          setState(() => line.taxCodeId = value);
                        },
                      ),
                      AppFormTextField(
                        labelText: 'Description',
                        controller: line.descriptionController,
                        enabled: _canEdit,
                      ),
                      AppFormTextField(
                        labelText: 'Remarks',
                        controller: line.remarksController,
                        enabled: _canEdit,
                        maxLines: 2,
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
                  label: _selectedItem == null ? 'Save quote' : 'Update quote',
                  onPressed: _canEdit ? _save : null,
                  busy: _saving,
                ),
                if (_selectedItem != null) ...[
                  if (_status == 'draft') ...[
                    AppActionButton(
                      icon: Icons.send_outlined,
                      label: 'Send to customer',
                      filled: false,
                      onPressed: () => _docAction(
                        () => _salesService.sendQuotation(
                          intValue(_selectedItem!.toJson(), 'id')!,
                          SalesQuotationModel(const <String, dynamic>{}),
                        ),
                      ),
                    ),
                    AppActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      filled: false,
                      onPressed: _delete,
                    ),
                  ],
                  if (_status == 'sent') ...[
                    AppActionButton(
                      icon: Icons.check_circle_outline,
                      label: 'Mark accepted',
                      filled: false,
                      onPressed: () => _docAction(
                        () => _salesService.acceptQuotation(
                          intValue(_selectedItem!.toJson(), 'id')!,
                          SalesQuotationModel(const <String, dynamic>{}),
                        ),
                      ),
                    ),
                    AppActionButton(
                      icon: Icons.cancel_outlined,
                      label: 'Reject',
                      filled: false,
                      onPressed: () => _docAction(
                        () => _salesService.rejectQuotation(
                          intValue(_selectedItem!.toJson(), 'id')!,
                          SalesQuotationModel(const <String, dynamic>{}),
                        ),
                      ),
                    ),
                    AppActionButton(
                      icon: Icons.timer_off_outlined,
                      label: 'Expire',
                      filled: false,
                      onPressed: () => _docAction(
                        () => _salesService.expireQuotation(
                          intValue(_selectedItem!.toJson(), 'id')!,
                          SalesQuotationModel(const <String, dynamic>{}),
                        ),
                      ),
                    ),
                  ],
                  if (const {'draft', 'sent'}.contains(_status))
                    AppActionButton(
                      icon: Icons.block_outlined,
                      label: 'Cancel quote',
                      filled: false,
                      onPressed: () => _docAction(
                        () => _salesService.cancelQuotation(
                          intValue(_selectedItem!.toJson(), 'id')!,
                          SalesQuotationModel(const <String, dynamic>{}),
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

class _QuotationLineDraft {
  _QuotationLineDraft({
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

  factory _QuotationLineDraft.fromJson(Map<String, dynamic> json) {
    return _QuotationLineDraft(
      itemId: intValue(json, 'item_id'),
      warehouseId: intValue(json, 'warehouse_id'),
      uomId: intValue(json, 'uom_id'),
      taxCodeId: intValue(json, 'tax_code_id'),
      description: stringValue(json, 'description'),
      qty: stringValue(json, 'qty'),
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
      'qty': double.tryParse(qtyController.text.trim()) ?? 0,
      'rate': double.tryParse(rateController.text.trim()) ?? 0,
      'discount_percent': double.tryParse(discountController.text.trim()) ?? 0,
      'remarks': nullIfEmpty(remarksController.text),
    };
  }

  void dispose() {
    descriptionController.dispose();
    qtyController.dispose();
    rateController.dispose();
    discountController.dispose();
    remarksController.dispose();
  }
}
