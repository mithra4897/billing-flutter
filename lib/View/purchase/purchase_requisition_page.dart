import '../../screen.dart';
import 'purchase_support.dart';

class PurchaseRequisitionPage extends StatefulWidget {
  const PurchaseRequisitionPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<PurchaseRequisitionPage> createState() =>
      _PurchaseRequisitionPageState();
}

class _PurchaseRequisitionPageState extends State<PurchaseRequisitionPage> {
  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All'),
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'approved', label: 'Approved'),
        AppDropdownItem(value: 'partially_ordered', label: 'Partially Ordered'),
        AppDropdownItem(value: 'fully_ordered', label: 'Fully Ordered'),
        AppDropdownItem(value: 'closed', label: 'Closed'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  final PurchaseService _purchaseService = PurchaseService();
  final MasterService _masterService = MasterService();
  final AuthService _authService = AuthService();
  final HrService _hrService = HrService();
  final InventoryService _inventoryService = InventoryService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _requisitionNoController =
      TextEditingController();
  final TextEditingController _requisitionDateController =
      TextEditingController();
  final TextEditingController _requiredDateController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  String _statusFilter = '';
  List<PurchaseRequisitionModel> _items = const <PurchaseRequisitionModel>[];
  List<PurchaseRequisitionModel> _filteredItems =
      const <PurchaseRequisitionModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<BranchModel> _branches = const <BranchModel>[];
  List<BusinessLocationModel> _locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> _financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> _documentSeries = const <DocumentSeriesModel>[];
  List<UserModel> _users = const <UserModel>[];
  List<DepartmentModel> _departments = const <DepartmentModel>[];
  List<ItemModel> _itemsLookup = const <ItemModel>[];
  List<UomModel> _uoms = const <UomModel>[];
  List<UomConversionModel> _uomConversions = const <UomConversionModel>[];
  List<WarehouseModel> _warehouses = const <WarehouseModel>[];
  PurchaseRequisitionModel? _selectedItem;
  int? _contextCompanyId;
  int? _contextBranchId;
  int? _contextLocationId;
  int? _contextFinancialYearId;
  int? _companyId;
  int? _branchId;
  int? _locationId;
  int? _financialYearId;
  int? _documentSeriesId;
  int? _requestedById;
  String? _departmentName;
  bool _isActive = true;
  List<_RequisitionLineDraft> _lines = <_RequisitionLineDraft>[];

  bool get _canEditSelectedRequisition {
    if (_selectedItem == null) {
      return true;
    }
    return stringValue(_selectedItem!.toJson(), 'requisition_status') == 'draft';
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
    _requisitionNoController.dispose();
    _requisitionDateController.dispose();
    _requiredDateController.dispose();
    _purposeController.dispose();
    _notesController.dispose();
    _disposeLines(_lines);
    super.dispose();
  }

  Future<void> _loadPage({int? selectId}) async {
    setState(() {
      _initialLoading = _items.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait<dynamic>([
        _purchaseService.requisitions(
          filters: const {'per_page': 200, 'sort_by': 'requisition_date'},
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
        _authService.users(
          filters: const {'per_page': 200, 'sort_by': 'username'},
        ),
        _hrService.departments(
          filters: const {'per_page': 200, 'sort_by': 'department_name'},
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
      ]);

      final documents =
          (responses[0] as PaginatedResponse<PurchaseRequisitionModel>).data ??
          const <PurchaseRequisitionModel>[];
      final companies =
          (responses[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final branches =
          (responses[2] as PaginatedResponse<BranchModel>).data ??
          const <BranchModel>[];
      final locations =
          (responses[3] as PaginatedResponse<BusinessLocationModel>).data ??
          const <BusinessLocationModel>[];
      final financialYears =
          (responses[4] as PaginatedResponse<FinancialYearModel>).data ??
          const <FinancialYearModel>[];
      final documentSeries =
          (responses[5] as PaginatedResponse<DocumentSeriesModel>).data ??
          const <DocumentSeriesModel>[];
      final users =
          (responses[6] as PaginatedResponse<UserModel>).data ??
          const <UserModel>[];
      final departments =
          (responses[7] as PaginatedResponse<DepartmentModel>).data ??
          const <DepartmentModel>[];
      final items =
          (responses[8] as PaginatedResponse<ItemModel>).data ??
          const <ItemModel>[];
      final uoms =
          (responses[9] as PaginatedResponse<UomModel>).data ??
          const <UomModel>[];
      final conversions =
          (responses[10] as ApiResponse<List<UomConversionModel>>).data ??
          const <UomConversionModel>[];
      final warehouses =
          (responses[11] as PaginatedResponse<WarehouseModel>).data ??
          const <WarehouseModel>[];

      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: companies
                .where((item) => item.isActive)
                .toList(growable: false),
            branches: branches
                .where((item) => item.isActive)
                .toList(growable: false),
            locations: locations
                .where((item) => item.isActive)
                .toList(growable: false),
            financialYears: financialYears
                .where((item) => item.isActive)
                .toList(growable: false),
          );

      if (!mounted) return;

      setState(() {
        _items = documents;
        _companies = companies;
        _branches = branches;
        _locations = locations;
        _financialYears = financialYears;
        _documentSeries = documentSeries
            .where((item) => item.isActive)
            .toList();
        _users = users
            .where((item) => (item.status ?? 'active') == 'active')
            .toList();
        _departments = departments.where((item) => item.isActive).toList();
        _itemsLookup = items.where((item) => item.isActive).toList();
        _uoms = uoms.where((item) => item.isActive).toList();
        _uomConversions = conversions.where((item) => item.isActive).toList();
        _warehouses = warehouses.where((item) => item.isActive).toList();
        _contextCompanyId = contextSelection.companyId;
        _contextBranchId = contextSelection.branchId;
        _contextLocationId = contextSelection.locationId;
        _contextFinancialYearId = contextSelection.financialYearId;
        _initialLoading = false;
      });
      _applyFilters();

      final selected = selectId != null
          ? documents.cast<PurchaseRequisitionModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : (widget.editorOnly
                ? null
                : _selectedItem == null
                ? (documents.isNotEmpty ? documents.first : null)
                : documents.cast<PurchaseRequisitionModel?>().firstWhere(
                    (item) =>
                        intValue(item?.toJson() ?? const {}, 'id') ==
                        intValue(_selectedItem!.toJson(), 'id'),
                    orElse: () => documents.isNotEmpty ? documents.first : null,
                  ));

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

  Future<void> _selectDocument(PurchaseRequisitionModel model) async {
    final id = intValue(model.toJson(), 'id');
    if (id == null) {
      return;
    }
    final response = await _purchaseService.requisition(id);
    final full = response.data ?? model;
    final data = full.toJson();
    final lines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(_RequisitionLineDraft.fromJson)
        .toList(growable: true);

    setState(() {
      _disposeLines(_lines);
      _selectedItem = full;
      _companyId = intValue(data, 'company_id');
      _branchId = intValue(data, 'branch_id');
      _locationId = intValue(data, 'location_id');
      _financialYearId = intValue(data, 'financial_year_id');
      _documentSeriesId = intValue(data, 'document_series_id');
      _requestedById = intValue(data, 'requested_by');
      _requisitionNoController.text = stringValue(data, 'requisition_no');
      _requisitionDateController.text = displayDate(
        nullableStringValue(data, 'requisition_date'),
      );
      _requiredDateController.text = displayDate(
        nullableStringValue(data, 'required_date'),
      );
      _departmentName = nullableStringValue(data, 'department');
      _purposeController.text = stringValue(data, 'purpose');
      _notesController.text = stringValue(data, 'notes');
      _isActive = boolValue(data, 'is_active', fallback: true);
      _lines = lines.isEmpty
          ? <_RequisitionLineDraft>[_RequisitionLineDraft()]
          : lines;
      _formError = null;
    });
  }

  void _resetForm() {
    setState(() {
      _disposeLines(_lines);
      _selectedItem = null;
      _companyId = _contextCompanyId;
      _branchId = _contextBranchId;
      _locationId = _contextLocationId;
      _financialYearId = _contextFinancialYearId;
      final series = _documentSeriesForContext();
      _documentSeriesId = series.isNotEmpty ? series.first.id : null;
      _requestedById = null;
      _requisitionNoController.clear();
      _requisitionDateController.text = DateTime.now()
          .toIso8601String()
          .split('T')
          .first;
      _requiredDateController.clear();
      _departmentName = null;
      _purposeController.clear();
      _notesController.clear();
      _isActive = true;
      _lines = <_RequisitionLineDraft>[_RequisitionLineDraft()];
      _formError = null;
    });
  }

  void _applyFilters() {
    final search = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredItems = _items
          .where((item) {
            final data = item.toJson();
            final statusMatches =
                _statusFilter.isEmpty ||
                stringValue(data, 'requisition_status') == _statusFilter;
            final searchMatches =
                search.isEmpty ||
                [
                  stringValue(data, 'requisition_no'),
                  stringValue(data, 'purpose'),
                  stringValue(data, 'department'),
                  stringValue(data, 'requisition_status'),
                ].join(' ').toLowerCase().contains(search);
            return statusMatches && searchMatches;
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

  List<DocumentSeriesModel> _documentSeriesForContext() {
    return _documentSeries
        .where((item) {
          final documentTypeOk =
              item.documentType == null ||
              item.documentType == 'PURCHASE_REQUISITION';
          final companyOk = _companyId == null || item.companyId == _companyId;
          final fyOk =
              _financialYearId == null ||
              item.financialYearId == _financialYearId;
          return documentTypeOk && companyOk && fyOk;
        })
        .toList(growable: false);
  }

  List<BranchModel> get _branchOptions =>
      branchesForCompany(_branches, _companyId);
  List<BusinessLocationModel> get _locationOptions =>
      locationsForBranch(_locations, _branchId);
  List<AppDropdownItem<String>> get _departmentItems {
    final items = _departments
        .where((item) => item.departmentName != null)
        .map(
          (item) => AppDropdownItem(
            value: item.departmentName!,
            label: item.departmentName!,
          ),
        )
        .toList(growable: false);
    final selected = _departmentName?.trim();
    final hasSelected = selected != null && selected.isNotEmpty;
    final exists = hasSelected && items.any((item) => item.value == selected);
    if (hasSelected && !exists) {
      return <AppDropdownItem<String>>[
        AppDropdownItem(value: selected, label: selected),
        ...items,
      ];
    }
    return items;
  }

  void _disposeLines(List<_RequisitionLineDraft> lines) {
    for (final line in lines) {
      line.dispose();
    }
  }

  void _addLine() {
    setState(() {
      _lines = List<_RequisitionLineDraft>.from(_lines)
        ..add(_RequisitionLineDraft());
    });
  }

  void _removeLine(int index) {
    setState(() {
      final updatedLines = List<_RequisitionLineDraft>.from(_lines);
      final removed = updatedLines.removeAt(index);
      removed.dispose();
      _lines = updatedLines;
      if (_lines.isEmpty) {
        _lines.add(_RequisitionLineDraft());
      }
    });
  }

  Future<void> _save() async {
    if (!_canEditSelectedRequisition) {
      setState(() {
        _formError = 'Only draft purchase requisitions can be updated.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final invalidLine = _lines.any(
      (line) =>
          line.itemId == null ||
          line.uomId == null ||
          (double.tryParse(line.requestedQtyController.text.trim()) ?? 0) <= 0,
    );
    if (invalidLine) {
      setState(() => _formError = 'Each line needs item, UOM, and quantity.');
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
      'requisition_no': nullIfEmpty(_requisitionNoController.text),
      'requisition_date': _requisitionDateController.text.trim(),
      'required_date': nullIfEmpty(_requiredDateController.text),
      'requested_by': _requestedById,
      'department': _departmentName == null
          ? null
          : nullIfEmpty(_departmentName!),
      'purpose': nullIfEmpty(_purposeController.text),
      'notes': nullIfEmpty(_notesController.text),
      'is_active': _isActive,
      'lines': _lines.map((line) => line.toJson()).toList(growable: false),
    };

    try {
      final response = _selectedItem == null
          ? await _purchaseService.createRequisition(
              PurchaseRequisitionModel(payload),
            )
          : await _purchaseService.updateRequisition(
              intValue(_selectedItem!.toJson(), 'id')!,
              PurchaseRequisitionModel(payload),
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
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _executeAction(
    Future<ApiResponse<PurchaseRequisitionModel>> Function() action,
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
    final actions = widget.editorOnly
        ? const <Widget>[]
        : <Widget>[
            AdaptiveShellActionButton(
              onPressed: () {
                _resetForm();
                if (!Responsive.isDesktop(context)) {
                  _workspaceController.openEditor();
                }
              },
              icon: Icons.add_outlined,
              label: 'New Requisition',
            ),
          ];

    final content = _buildContent();
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'Purchase Requisitions',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading purchase requisitions...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load purchase requisitions',
        message: _pageError!,
        onRetry: _loadPage,
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Purchase Requisitions',
      editorTitle: _selectedItem == null
          ? 'New Purchase Requisition'
          : stringValue(
              _selectedItem!.toJson(),
              'requisition_no',
              'Purchase Requisition',
            ),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: PurchaseListCard<PurchaseRequisitionModel>(
        items: _filteredItems,
        selectedItem: _selectedItem,
        emptyMessage: 'No purchase requisitions found.',
        searchController: _searchController,
        searchHint: 'Search requisitions',
        statusValue: _statusFilter,
        statusItems: _statusItems,
        onStatusChanged: (value) {
          _statusFilter = value ?? '';
          _applyFilters();
        },
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'requisition_no', 'Draft Requisition'),
            subtitle: [
              displayDate(nullableStringValue(data, 'requisition_date')),
              stringValue(data, 'requisition_status'),
            ].where((value) => value.isNotEmpty).join(' · '),
            detail: stringValue(data, 'purpose'),
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
                    final series = _documentSeriesForContext();
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
                    final series = _documentSeriesForContext();
                    _documentSeriesId = series.isNotEmpty
                        ? series.first.id
                        : null;
                  }),
                  validator: Validators.requiredSelection('Financial Year'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Document Series',
                  mappedItems: _documentSeriesForContext()
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
                  labelText: 'Requisition No',
                  controller: _requisitionNoController,
                  hintText: 'Auto-generated on save',
                  validator: Validators.optionalMaxLength(
                    100,
                    'Requisition No',
                  ),
                ),
                AppFormTextField(
                  labelText: 'Requisition Date',
                  controller: _requisitionDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([
                    Validators.required('Requisition Date'),
                    Validators.date('Requisition Date'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Required Date',
                  controller: _requiredDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDate('Required Date'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Requested By',
                  mappedItems: _users
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _requestedById,
                  onChanged: (value) => setState(() => _requestedById = value),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Department',
                  mappedItems: _departmentItems,
                  initialValue: _departmentName,
                  onChanged: (value) => setState(() => _departmentName = value),
                ),
                AppFormTextField(
                  labelText: 'Purpose',
                  controller: _purposeController,
                  validator: Validators.optionalMaxLength(255, 'Purpose'),
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
                  child: _buildLineFields(line),
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
                      ? 'Save Requisition'
                      : 'Update Requisition',
                  onPressed: _canEditSelectedRequisition ? _save : null,
                  busy: _saving,
                ),
                if (_selectedItem != null) ...[
                  AppActionButton(
                    icon: Icons.check_circle_outline,
                    label: 'Approve',
                    onPressed: () => _executeAction(
                      () => _purchaseService.approveRequisition(
                        intValue(_selectedItem!.toJson(), 'id')!,
                        PurchaseRequisitionModel(const <String, dynamic>{}),
                      ),
                    ),
                    filled: false,
                  ),
                  AppActionButton(
                    icon: Icons.task_alt_outlined,
                    label: 'Close',
                    onPressed: () => _executeAction(
                      () => _purchaseService.closeRequisition(
                        intValue(_selectedItem!.toJson(), 'id')!,
                        PurchaseRequisitionModel(const <String, dynamic>{}),
                      ),
                    ),
                    filled: false,
                  ),
                  AppActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Cancel',
                    onPressed: () => _executeAction(
                      () => _purchaseService.cancelRequisition(
                        intValue(_selectedItem!.toJson(), 'id')!,
                        PurchaseRequisitionModel(const <String, dynamic>{}),
                      ),
                    ),
                    filled: false,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineFields(_RequisitionLineDraft line) {
    final itemPicker = AppSearchPickerField<int>(
      labelText: 'Item',
      selectedLabel: _itemsLookup
          .cast<ItemModel?>()
          .firstWhere((item) => item?.id == line.itemId, orElse: () => null)
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
        line.uomId = _resolveDefaultUom(value, line.uomId);
      }),
      validator: (_) => line.itemId == null ? 'Item is required' : null,
    );

    final uomOptions = _uomOptionsForItem(line.itemId);
    if (uomOptions.length <= 1) {
      final onlyId = uomOptions.isNotEmpty ? uomOptions.first.id : null;
      if (line.uomId != onlyId) {
        line.uomId = onlyId;
      }
    }

    final Widget uomField = uomOptions.length <= 1
        ? AppFormTextField(
            labelText: 'UOM',
            initialValue: uomOptions.isNotEmpty
                ? uomOptions.first.toString()
                : '',
            readOnly: true,
          )
        : AppDropdownField<int>.fromMapped(
            labelText: 'UOM',
            mappedItems: uomOptions
                .where((item) => item.id != null)
                .map(
                  (item) =>
                      AppDropdownItem(value: item.id!, label: item.toString()),
                )
                .toList(growable: false),
            initialValue: line.uomId,
            onChanged: (value) => setState(() => line.uomId = value),
            validator: Validators.requiredSelection('UOM'),
          );

    final lineFields = <Widget>[
      itemPicker,
      uomField,
      AppDropdownField<int>.fromMapped(
        labelText: 'Warehouse',
        mappedItems: _warehouses
            .where((item) => item.id != null)
            .map(
              (item) =>
                  AppDropdownItem(value: item.id!, label: item.toString()),
            )
            .toList(growable: false),
        initialValue: line.warehouseId,
        onChanged: (value) => setState(() => line.warehouseId = value),
      ),
      AppFormTextField(
        labelText: 'Requested Qty',
        controller: line.requestedQtyController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: Validators.compose([
          Validators.required('Requested Qty'),
          Validators.optionalNonNegativeNumber('Requested Qty'),
        ]),
      ),
      AppFormTextField(
        labelText: 'Estimated Rate',
        controller: line.estimatedRateController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: Validators.optionalNonNegativeNumber('Estimated Rate'),
      ),
      AppFormTextField(
        labelText: 'Description',
        controller: line.descriptionController,
        validator: Validators.optionalMaxLength(500, 'Description'),
      ),
      AppFormTextField(
        labelText: 'Remarks',
        controller: line.remarksController,
        maxLines: 2,
        validator: Validators.optionalMaxLength(500, 'Remarks'),
      ),
    ];

    return PurchaseCompactFieldGrid(children: lineFields);
  }
}

class _RequisitionLineDraft {
  _RequisitionLineDraft({
    this.itemId,
    this.warehouseId,
    this.uomId,
    String? description,
    String? requestedQty,
    String? estimatedRate,
    String? remarks,
  }) : descriptionController = TextEditingController(text: description ?? ''),
       requestedQtyController = TextEditingController(text: requestedQty ?? ''),
       estimatedRateController = TextEditingController(
         text: estimatedRate ?? '',
       ),
       remarksController = TextEditingController(text: remarks ?? '');

  factory _RequisitionLineDraft.fromJson(Map<String, dynamic> json) {
    return _RequisitionLineDraft(
      itemId: intValue(json, 'item_id'),
      warehouseId: intValue(json, 'warehouse_id'),
      uomId: intValue(json, 'uom_id'),
      description: stringValue(json, 'description'),
      requestedQty: stringValue(json, 'requested_qty'),
      estimatedRate: stringValue(json, 'estimated_rate'),
      remarks: stringValue(json, 'remarks'),
    );
  }

  int? itemId;
  int? warehouseId;
  int? uomId;
  final TextEditingController descriptionController;
  final TextEditingController requestedQtyController;
  final TextEditingController estimatedRateController;
  final TextEditingController remarksController;

  void dispose() {
    descriptionController.dispose();
    requestedQtyController.dispose();
    estimatedRateController.dispose();
    remarksController.dispose();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'item_id': itemId,
      'warehouse_id': warehouseId,
      'uom_id': uomId,
      'description': nullIfEmpty(descriptionController.text),
      'requested_qty': double.tryParse(requestedQtyController.text.trim()) ?? 0,
      'estimated_rate':
          double.tryParse(estimatedRateController.text.trim()) ?? 0,
      'remarks': nullIfEmpty(remarksController.text),
    };
  }
}
