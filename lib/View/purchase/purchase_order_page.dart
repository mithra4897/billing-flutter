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
  static const int _allSelectionId = -1;
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
  List<ItemSupplierMapModel> _itemSupplierMaps = const <ItemSupplierMapModel>[];
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
  String? _selectionInfo;
  List<_PurchaseOrderLineDraft> _lines = <_PurchaseOrderLineDraft>[];
  final Map<int, PurchaseRequisitionModel> _requisitionDetailCache =
      <int, PurchaseRequisitionModel>{};
  _PurchaseOrderLinkDriver _linkDriver = _PurchaseOrderLinkDriver.none;

  bool get _canEditSelectedOrder {
    if (_selectedItem == null) {
      return true;
    }
    return stringValue(_selectedItem!.toJson(), 'order_status') == 'draft';
  }

  bool get _isAllSupplierSelected => _supplierPartyId == _allSelectionId;
  bool get _isAllRequisitionSelected =>
      _purchaseRequisitionId == _allSelectionId;
  bool get _hasSpecificSupplierSelection =>
      _supplierPartyId != null && !_isAllSupplierSelected;
  bool get _hasSpecificRequisitionSelection =>
      _purchaseRequisitionId != null && !_isAllRequisitionSelected;

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
        _inventoryService.itemSupplierMaps(
          filters: const {'per_page': 1000, 'is_active': 1},
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
        _itemSupplierMaps =
            ((responses[14] as PaginatedResponse<ItemSupplierMapModel>).data ??
                    const <ItemSupplierMapModel>[])
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
      _selectionInfo = null;
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
      _selectionInfo = null;
      _linkDriver = _PurchaseOrderLinkDriver.none;
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

  ItemModel? _itemById(int? itemId) {
    return _itemsLookup.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == itemId,
      orElse: () => null,
    );
  }

  String _itemDescription(ItemModel? item, {String? fallback}) {
    final itemName = item?.itemName.trim() ?? '';
    if (itemName.isNotEmpty) {
      return itemName;
    }
    final itemCode = item?.itemCode.trim() ?? '';
    if (itemCode.isNotEmpty) {
      return itemCode;
    }
    return fallback?.trim() ?? '';
  }

  Future<void> _primeAllRequisitionDetails() async {
    final idsToLoad = _requisitions
        .map((item) => intValue(item.toJson(), 'id'))
        .whereType<int>()
        .where((id) => !_requisitionDetailCache.containsKey(id))
        .toList(growable: false);

    if (idsToLoad.isEmpty) {
      return;
    }

    final responses = await Future.wait<PurchaseRequisitionModel?>(
      idsToLoad.map(_loadRequisitionDetail),
    );
    for (final doc in responses) {
      final id = intValue(doc?.toJson() ?? const <String, dynamic>{}, 'id');
      if (id != null && doc != null) {
        _requisitionDetailCache[id] = doc;
      }
    }
  }

  Future<PurchaseRequisitionModel?> _loadRequisitionDetail(int id) async {
    final cached = _requisitionDetailCache[id];
    if (cached != null) {
      return cached;
    }
    final response = await _purchaseService.requisition(id);
    final doc = response.data;
    if (doc != null) {
      _requisitionDetailCache[id] = doc;
    }
    return doc;
  }

  List<Map<String, dynamic>> _requisitionLineMaps(
    PurchaseRequisitionModel? doc,
  ) {
    final data = doc?.toJson() ?? const <String, dynamic>{};
    return (data['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  Set<int> _supplierItemIds(int supplierId) {
    return _itemSupplierMaps
        .where((entry) => entry.isActive && entry.supplierId == supplierId)
        .map((entry) => entry.itemId)
        .whereType<int>()
        .toSet();
  }

  List<ItemSupplierMapModel> _supplierMaps(int supplierId) {
    return _itemSupplierMaps
        .where((entry) => entry.isActive && entry.supplierId == supplierId)
        .toList(growable: false);
  }

  void _applyItemAndSupplierDefaults(
    _PurchaseOrderLineDraft draft, {
    int? supplierId,
    String? fallbackDescription,
    String? fallbackRemarks,
  }) {
    final item = _itemById(draft.itemId);

    draft.uomId = _resolveDefaultUom(draft.itemId, draft.uomId);
    draft.taxCodeId = item?.taxCodeId;

    if (draft.descriptionController.text.trim().isEmpty) {
      draft.descriptionController.text = _itemDescription(
        item,
        fallback: fallbackDescription,
      );
    }

    final currentRate = double.tryParse(draft.rateController.text.trim()) ?? 0;
    if (currentRate <= 0 && item?.standardCost != null) {
      draft.rateController.text = item!.standardCost!.toString();
    }

    if (draft.remarksController.text.trim().isEmpty &&
        (fallbackRemarks?.trim().isNotEmpty ?? false)) {
      draft.remarksController.text = fallbackRemarks!.trim();
    } else if (draft.remarksController.text.trim().isEmpty &&
        (item?.remarks?.trim().isNotEmpty ?? false)) {
      draft.remarksController.text = item!.remarks!.trim();
    }

    if (supplierId != null) {
      final supplierMap = _supplierMaps(supplierId)
          .cast<ItemSupplierMapModel?>()
          .firstWhere(
            (entry) => entry?.itemId == draft.itemId,
            orElse: () => null,
          );
      if (supplierMap != null) {
        draft.uomId =
            supplierMap.purchaseUomId ??
            _resolveDefaultUom(draft.itemId, draft.uomId);
        draft.rateController.text =
            supplierMap.supplierRate?.toString() ?? draft.rateController.text;
        draft.taxCodeId = item?.taxCodeId;
        if (draft.descriptionController.text.trim().isEmpty) {
          draft.descriptionController.text = _itemDescription(
            item,
            fallback: supplierMap.supplierItemName ?? supplierMap.itemName,
          );
        }
        if (draft.remarksController.text.trim().isEmpty &&
            (supplierMap.remarks?.trim().isNotEmpty ?? false)) {
          draft.remarksController.text = supplierMap.remarks!.trim();
        }
      }
    }
  }

  bool _isOpenDemandRequisition(PurchaseRequisitionModel? requisition) {
    final status = stringValue(
      requisition?.toJson() ?? const <String, dynamic>{},
      'requisition_status',
    );
    return status == 'approved' || status == 'partially_ordered';
  }

  bool _isOpenDemandRequisitionLine(Map<String, dynamic> line) {
    final pendingQty = double.tryParse(stringValue(line, 'pending_qty')) ?? 0;
    final status = stringValue(line, 'line_status');
    if (pendingQty <= 0) {
      return false;
    }
    return status != 'cancelled' && status != 'fully_ordered';
  }

  List<Map<String, dynamic>> _openDemandLinesForSupplier(int supplierId) {
    final supplierItemIds = _supplierItemIds(supplierId);
    if (supplierItemIds.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final demandLines = <Map<String, dynamic>>[];
    for (final requisition in _requisitionDetailCache.values) {
      if (!_isOpenDemandRequisition(requisition)) {
        continue;
      }
      final requisitionData = requisition.toJson();
      final requisitionId = intValue(requisitionData, 'id');
      final requisitionNo = stringValue(requisitionData, 'requisition_no');

      for (final line in _requisitionLineMaps(requisition)) {
        final itemId = intValue(line, 'item_id');
        if (itemId == null || !supplierItemIds.contains(itemId)) {
          continue;
        }
        if (!_isOpenDemandRequisitionLine(line)) {
          continue;
        }

        demandLines.add(<String, dynamic>{
          ...line,
          'requisition_id': requisitionId,
          if (requisitionNo.isNotEmpty) 'requisition_no': requisitionNo,
        });
      }
    }

    demandLines.sort((left, right) {
      final leftRequisitionId = intValue(left, 'requisition_id') ?? 0;
      final rightRequisitionId = intValue(right, 'requisition_id') ?? 0;
      if (leftRequisitionId != rightRequisitionId) {
        return leftRequisitionId.compareTo(rightRequisitionId);
      }
      final leftLineId = intValue(left, 'id') ?? 0;
      final rightLineId = intValue(right, 'id') ?? 0;
      return leftLineId.compareTo(rightLineId);
    });

    return demandLines;
  }

  List<_PurchaseOrderLineDraft> _linesFromSupplierDemand(int supplierId) {
    return _openDemandLinesForSupplier(supplierId)
        .map((line) {
          final draft = _PurchaseOrderLineDraft.fromRequisitionLine(line);
          draft.purchaseRequisitionLineId = null;
          _applyItemAndSupplierDefaults(
            draft,
            supplierId: supplierId,
            fallbackDescription: stringValue(
              line,
              'requisition_no',
              stringValue(line, 'description'),
            ),
            fallbackRemarks: stringValue(line, 'remarks'),
          );
          return draft;
        })
        .where((line) => line.itemId != null)
        .toList(growable: false);
  }

  List<_PurchaseOrderLineDraft> _linesFromSupplierMaps(int supplierId) {
    return _supplierMaps(supplierId)
        .map((map) {
          final draft = _PurchaseOrderLineDraft(
            itemId: map.itemId,
            warehouseId: null,
            uomId: map.purchaseUomId,
            description: map.supplierItemName ?? map.itemName,
            qty: '',
            rate: map.supplierRate?.toString() ?? '',
            remarks: map.remarks,
          );
          _applyItemAndSupplierDefaults(
            draft,
            supplierId: supplierId,
            fallbackDescription: map.supplierItemName ?? map.itemName,
            fallbackRemarks: map.remarks,
          );
          return draft;
        })
        .where((line) => line.itemId != null)
        .toList(growable: false);
  }

  List<_PurchaseOrderLineDraft> _linesFromAllSupplierMaps() {
    return _itemSupplierMaps
        .where((map) => map.isActive)
        .map((map) {
          final draft = _PurchaseOrderLineDraft(
            itemId: map.itemId,
            warehouseId: null,
            uomId: map.purchaseUomId,
            description: map.supplierItemName ?? map.itemName,
            qty: '',
            rate: map.supplierRate?.toString() ?? '',
            remarks: map.remarks,
          );
          _applyItemAndSupplierDefaults(
            draft,
            supplierId: map.supplierId,
            fallbackDescription: map.supplierItemName ?? map.itemName,
            fallbackRemarks: map.remarks,
          );
          return draft;
        })
        .where((line) => line.itemId != null)
        .toList(growable: false);
  }

  ({List<_PurchaseOrderLineDraft> lines, int excluded}) _linesFromRequisition(
    PurchaseRequisitionModel requisition, {
    int? supplierId,
  }) {
    final lineMaps = _requisitionLineMaps(requisition);
    final allowedItemIds = supplierId != null
        ? _supplierItemIds(supplierId)
        : null;
    final filtered = allowedItemIds == null
        ? lineMaps
        : lineMaps
              .where(
                (line) => allowedItemIds.contains(intValue(line, 'item_id')),
              )
              .toList(growable: false);

    final lines = filtered
        .map((line) {
          final draft = _PurchaseOrderLineDraft.fromRequisitionLine(line);
          _applyItemAndSupplierDefaults(
            draft,
            supplierId: supplierId,
            fallbackDescription: stringValue(line, 'description'),
            fallbackRemarks: stringValue(line, 'remarks'),
          );
          return draft;
        })
        .where((line) => line.itemId != null)
        .toList(growable: false);

    return (lines: lines, excluded: lineMaps.length - filtered.length);
  }

  List<_PurchaseOrderLineDraft> _linesFromAllRequisitions({int? supplierId}) {
    final requisitions = _requisitionDetailCache.values.toList(growable: false)
      ..sort((left, right) {
        final leftId = intValue(left.toJson(), 'id') ?? 0;
        final rightId = intValue(right.toJson(), 'id') ?? 0;
        return leftId.compareTo(rightId);
      });

    return requisitions
        .expand(
          (requisition) =>
              _linesFromRequisition(requisition, supplierId: supplierId).lines,
        )
        .toList(growable: false);
  }

  Future<void> _primeRequisitionDetailsForSupplier(int supplierId) async {
    final supplierItemIds = _supplierItemIds(supplierId);
    if (supplierItemIds.isEmpty) {
      return;
    }

    final idsToLoad = _requisitions
        .map((item) => intValue(item.toJson(), 'id'))
        .whereType<int>()
        .where((id) => !_requisitionDetailCache.containsKey(id))
        .toList(growable: false);

    if (idsToLoad.isEmpty) {
      return;
    }

    final responses = await Future.wait<PurchaseRequisitionModel?>(
      idsToLoad.map(_loadRequisitionDetail),
    );
    for (final doc in responses) {
      final id = intValue(doc?.toJson() ?? const <String, dynamic>{}, 'id');
      if (id != null && doc != null) {
        _requisitionDetailCache[id] = doc;
      }
    }
  }

  List<PartyModel> get _filteredSupplierOptions {
    if (_linkDriver != _PurchaseOrderLinkDriver.requisition ||
        !_hasSpecificRequisitionSelection) {
      return _suppliers;
    }
    final requisition = _requisitionDetailCache[_purchaseRequisitionId!];
    if (requisition == null) {
      return _suppliers;
    }
    final itemIds = _requisitionLineMaps(
      requisition,
    ).map((line) => intValue(line, 'item_id')).whereType<int>().toSet();
    if (itemIds.isEmpty) {
      return _suppliers;
    }
    final allowedSupplierIds = _itemSupplierMaps
        .where((entry) => entry.isActive && itemIds.contains(entry.itemId))
        .map((entry) => entry.supplierId)
        .whereType<int>()
        .toSet();
    return _suppliers
        .where(
          (entry) => entry.id != null && allowedSupplierIds.contains(entry.id),
        )
        .toList(growable: false);
  }

  List<PurchaseRequisitionModel> get _filteredRequisitionOptions {
    if (_linkDriver != _PurchaseOrderLinkDriver.supplier ||
        !_hasSpecificSupplierSelection) {
      return _requisitions;
    }
    final supplierItemIds = _supplierItemIds(_supplierPartyId!);
    if (supplierItemIds.isEmpty) {
      return const <PurchaseRequisitionModel>[];
    }
    return _requisitions
        .where((req) {
          final id = intValue(req.toJson(), 'id');
          final detail = id != null ? _requisitionDetailCache[id] : null;
          if (detail == null) {
            return true;
          }
          if (!_isOpenDemandRequisition(detail)) {
            return false;
          }
          return _requisitionLineMaps(detail).any((line) {
            final itemId = intValue(line, 'item_id');
            return itemId != null &&
                supplierItemIds.contains(itemId) &&
                _isOpenDemandRequisitionLine(line);
          });
        })
        .toList(growable: false);
  }

  Future<void> _handleRequisitionChanged(int? requisitionId) async {
    if (requisitionId == null) {
      setState(() {
        _purchaseRequisitionId = null;
        _selectionInfo = null;
        if (_supplierPartyId == null) {
          _linkDriver = _PurchaseOrderLinkDriver.none;
        } else if (_linkDriver == _PurchaseOrderLinkDriver.requisition) {
          _linkDriver = _PurchaseOrderLinkDriver.none;
        }
      });
      return;
    }

    setState(() {
      if (_linkDriver == _PurchaseOrderLinkDriver.none &&
          _supplierPartyId == null) {
        _linkDriver = _PurchaseOrderLinkDriver.requisition;
      }
      _purchaseRequisitionId = requisitionId;
      _formError = null;
      _selectionInfo = null;
    });

    try {
      if (requisitionId == _allSelectionId) {
        await _primeAllRequisitionDetails();
        if (!mounted) return;

        final supplierId = _hasSpecificSupplierSelection
            ? _supplierPartyId
            : null;
        final mappedLines = _linesFromAllRequisitions(supplierId: supplierId);

        setState(() {
          _lines = mappedLines.isEmpty
              ? <_PurchaseOrderLineDraft>[_PurchaseOrderLineDraft()]
              : mappedLines;
          _formError = mappedLines.isEmpty
              ? 'No requisition lines found to copy.'
              : null;
          _selectionInfo = mappedLines.isEmpty
              ? null
              : 'Loaded lines from all requisitions.';
        });
        return;
      }

      final requisition = await _loadRequisitionDetail(requisitionId);
      if (!mounted) return;
      final data = requisition?.toJson() ?? const <String, dynamic>{};
      if (requisition == null) {
        setState(
          () => _formError = 'Selected requisition could not be loaded.',
        );
        return;
      }
      final result = _linesFromRequisition(
        requisition,
        supplierId: _hasSpecificSupplierSelection ? _supplierPartyId : null,
      );
      final mappedLines = result.lines;

      if (_linkDriver == _PurchaseOrderLinkDriver.requisition &&
          _hasSpecificSupplierSelection &&
          !_filteredSupplierOptions.any(
            (item) => item.id == _supplierPartyId,
          )) {
        setState(() {
          _supplierPartyId = null;
        });
      }

      if (mappedLines.isEmpty) {
        setState(() {
          _formError = !_hasSpecificSupplierSelection
              ? 'Selected requisition has no lines to copy.'
              : 'No common items found between selected requisition and supplier.';
          _lines = <_PurchaseOrderLineDraft>[_PurchaseOrderLineDraft()];
        });
        return;
      }

      setState(() {
        _companyId = intValue(data, 'company_id') ?? _companyId;
        _branchId = intValue(data, 'branch_id') ?? _branchId;
        _locationId = intValue(data, 'location_id') ?? _locationId;
        _financialYearId =
            intValue(data, 'financial_year_id') ?? _financialYearId;
        _lines = mappedLines;
        _selectionInfo = result.excluded > 0
            ? '${result.excluded} requisition item(s) excluded because they are not mapped to the selected supplier.'
            : null;
        final options = _seriesOptions();
        if (options.isNotEmpty &&
            !_seriesOptions().any((item) => item.id == _documentSeriesId)) {
          _documentSeriesId = options.first.id;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.toString());
    }
  }

  Future<void> _handleSupplierChanged(int? supplierId) async {
    if (supplierId == null) {
      setState(() {
        _supplierPartyId = null;
        _selectionInfo = null;
        if (_purchaseRequisitionId == null) {
          _linkDriver = _PurchaseOrderLinkDriver.none;
        } else if (_linkDriver == _PurchaseOrderLinkDriver.supplier) {
          _linkDriver = _PurchaseOrderLinkDriver.none;
        }
      });
      return;
    }

    setState(() {
      if (_linkDriver == _PurchaseOrderLinkDriver.none &&
          _purchaseRequisitionId == null) {
        _linkDriver = _PurchaseOrderLinkDriver.supplier;
      }
      _supplierPartyId = supplierId;
      _formError = null;
      _selectionInfo = null;
    });

    try {
      if (supplierId == _allSelectionId) {
        await _primeAllRequisitionDetails();
      } else {
        await _primeRequisitionDetailsForSupplier(supplierId);
      }
      if (!mounted) return;

      if (_linkDriver == _PurchaseOrderLinkDriver.supplier &&
          _hasSpecificRequisitionSelection &&
          !_filteredRequisitionOptions.any(
            (req) => intValue(req.toJson(), 'id') == _purchaseRequisitionId,
          )) {
        setState(() {
          _purchaseRequisitionId = null;
        });
      }

      final supplierDemandLines = !_hasSpecificRequisitionSelection
          ? (_isAllSupplierSelected
                ? _linesFromAllRequisitions()
                : _linesFromSupplierDemand(supplierId))
          : const <_PurchaseOrderLineDraft>[];
      final mappedLines = _hasSpecificRequisitionSelection
          ? _linesFromRequisition(
              _requisitionDetailCache[_purchaseRequisitionId!]!,
              supplierId: _hasSpecificSupplierSelection ? supplierId : null,
            ).lines
          : (supplierDemandLines.isNotEmpty
                ? supplierDemandLines
                : (_isAllSupplierSelected
                      ? _linesFromAllSupplierMaps()
                      : _linesFromSupplierMaps(supplierId)));

      if (mappedLines.isEmpty) {
        setState(() {
          _formError = !_hasSpecificRequisitionSelection
              ? 'No supplier item mappings found for selected supplier.'
              : 'No common items found between selected supplier and requisition.';
          _lines = <_PurchaseOrderLineDraft>[_PurchaseOrderLineDraft()];
        });
        return;
      }

      setState(() {
        _lines = mappedLines;
        if (_hasSpecificRequisitionSelection) {
          final result = _linesFromRequisition(
            _requisitionDetailCache[_purchaseRequisitionId!]!,
            supplierId: _hasSpecificSupplierSelection ? supplierId : null,
          );
          _selectionInfo = result.excluded > 0
              ? '${result.excluded} requisition item(s) excluded because they are not mapped to the selected supplier.'
              : null;
        } else {
          _selectionInfo = _isAllSupplierSelected
              ? 'Loaded lines for all suppliers.'
              : supplierDemandLines.isNotEmpty
              ? 'Loaded open requisition demand for the selected supplier. Select a requisition to keep direct line linkage.'
              : 'No open requisition demand found for this supplier, so item defaults were loaded from supplier mapping.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.toString());
    }
  }

  Future<void> _save() async {
    if (!_canEditSelectedOrder) {
      setState(() {
        _formError = 'Only draft purchase orders can be updated.';
      });
      return;
    }

    if (_isAllSupplierSelected) {
      setState(() {
        _formError =
            'Select a specific supplier before saving the purchase order.';
      });
      return;
    }

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
      'purchase_requisition_id': _isAllRequisitionSelected
          ? null
          : _purchaseRequisitionId,
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
            if (_selectionInfo != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppUiConstants.spacingSm),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(
                    AppUiConstants.cardRadius,
                  ),
                ),
                child: Text(_selectionInfo!),
              ),
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
                  validator: Validators.compose([
                    Validators.optionalDate('Expected Receipt Date'),
                    Validators.optionalDateOnOrAfter(
                      'Expected Receipt Date',
                      () => _orderDateController.text.trim(),
                      startFieldName: 'Order Date',
                    ),
                  ]),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Supplier',
                  mappedItems: <AppDropdownItem<int>>[
                    const AppDropdownItem(value: _allSelectionId, label: 'All'),
                    ..._filteredSupplierOptions
                        .where((item) => item.id != null)
                        .map(
                          (item) => AppDropdownItem(
                            value: item.id!,
                            label: item.toString(),
                          ),
                        ),
                  ],
                  initialValue: _supplierPartyId,
                  onChanged: (value) => _handleSupplierChanged(value),
                  validator: Validators.requiredSelection('Supplier'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Requisition',
                  mappedItems: <AppDropdownItem<int>>[
                    const AppDropdownItem(value: _allSelectionId, label: 'All'),
                    ..._filteredRequisitionOptions
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
                        ),
                  ],
                  initialValue: _purchaseRequisitionId,
                  onChanged: (value) => _handleRequisitionChanged(value),
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
                        onChanged: (value) => setState(() {
                          line.itemId = value;
                          line.uomId = _resolveDefaultUom(value, line.uomId);
                        }),
                        validator: (_) =>
                            line.itemId == null ? 'Item is required' : null,
                      ),
                      Builder(
                        builder: (context) {
                          final options = _uomOptionsForItem(line.itemId);
                          if (options.length == 1) {
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
                            onChanged: (value) =>
                                setState(() => line.uomId = value),
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
                          Validators.optionalNonNegativeNumber('Ordered Qty'),
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
                  onPressed: _canEditSelectedOrder ? _save : null,
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
    this.purchaseRequisitionLineId,
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

  factory _PurchaseOrderLineDraft.fromRequisitionLine(
    Map<String, dynamic> json,
  ) {
    final pendingQty = double.tryParse(stringValue(json, 'pending_qty'));
    final requestedQty = double.tryParse(stringValue(json, 'requested_qty'));
    final effectiveQty = pendingQty != null && pendingQty > 0
        ? pendingQty
        : (requestedQty ?? 0);

    return _PurchaseOrderLineDraft(
      purchaseRequisitionLineId: intValue(json, 'id'),
      itemId: intValue(json, 'item_id'),
      warehouseId: intValue(json, 'warehouse_id'),
      uomId: intValue(json, 'uom_id'),
      description: stringValue(json, 'description'),
      qty: effectiveQty > 0 ? effectiveQty.toString() : '',
      rate: stringValue(json, 'estimated_rate'),
      remarks: stringValue(json, 'remarks'),
    );
  }

  factory _PurchaseOrderLineDraft.fromJson(Map<String, dynamic> json) {
    return _PurchaseOrderLineDraft(
      purchaseRequisitionLineId: intValue(json, 'purchase_requisition_line_id'),
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

  int? purchaseRequisitionLineId;
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
      'purchase_requisition_line_id': purchaseRequisitionLineId,
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

enum _PurchaseOrderLinkDriver { none, supplier, requisition }
