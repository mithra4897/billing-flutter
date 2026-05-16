import 'dart:async';

import '../../model/sales/sales_delivery_model.dart';
import '../../model/sales/sales_order_model.dart';
import '../../screen.dart';
import '../printing/document_print_designer.dart';
import '../crm/crm_sales_pipeline_bar.dart';
import '../purchase/purchase_support.dart';
import 'sales_support.dart';

class SalesDeliveryPage extends StatefulWidget {
  const SalesDeliveryPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<SalesDeliveryPage> createState() => _SalesDeliveryPageState();
}

class _SalesDeliveryPageState extends State<SalesDeliveryPage> {
  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All'),
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'posted', label: 'Posted'),
        AppDropdownItem(
          value: 'partially_invoiced',
          label: 'Partially Invoiced',
        ),
        AppDropdownItem(value: 'fully_invoiced', label: 'Fully Invoiced'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  final SalesService _salesService = SalesService();
  final CrmService _crmService = CrmService();
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final InventoryService _inventoryService = InventoryService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _deliveryNoController = TextEditingController();
  final TextEditingController _deliveryDateController = TextEditingController();
  final TextEditingController _vehicleNoController = TextEditingController();
  final TextEditingController _lrNoController = TextEditingController();
  final TextEditingController _lrDateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  String _statusFilter = '';
  List<SalesDeliveryModel> _items = const <SalesDeliveryModel>[];
  List<SalesDeliveryModel> _filteredItems = const <SalesDeliveryModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<BranchModel> _branches = const <BranchModel>[];
  List<BusinessLocationModel> _locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> _financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> _documentSeries = const <DocumentSeriesModel>[];
  List<SalesOrderModel> _orders = const <SalesOrderModel>[];
  List<PartyModel> _customers = const <PartyModel>[];
  List<PartyModel> _allParties = const <PartyModel>[];
  List<WarehouseModel> _warehouses = const <WarehouseModel>[];
  List<ItemModel> _itemsLookup = const <ItemModel>[];
  List<UomModel> _uoms = const <UomModel>[];
  List<UomConversionModel> _uomConversions = const <UomConversionModel>[];
  final Map<String, List<Map<String, dynamic>>>
  _availableBatchesByItemWarehouse = <String, List<Map<String, dynamic>>>{};
  final Set<String> _batchOptionsLoadingKeys = <String>{};
  final Map<String, List<Map<String, dynamic>>>
  _availableSerialsByItemWarehouse = <String, List<Map<String, dynamic>>>{};
  final Set<String> _serialOptionsLoadingKeys = <String>{};
  SalesDeliveryModel? _selectedItem;
  int? _contextCompanyId;
  int? _contextBranchId;
  int? _contextLocationId;
  int? _contextFinancialYearId;
  int? _companyId;
  int? _branchId;
  int? _locationId;
  int? _financialYearId;
  int? _documentSeriesId;
  int? _salesOrderId;
  int? _customerPartyId;
  int? _transporterPartyId;
  bool _isActive = true;
  Map<String, dynamic>? _salesChain;
  List<_SalesDeliveryLineDraft> _lines = <_SalesDeliveryLineDraft>[];

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
    _deliveryNoController.dispose();
    _deliveryDateController.dispose();
    _vehicleNoController.dispose();
    _lrNoController.dispose();
    _lrDateController.dispose();
    _notesController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  ItemModel? _itemById(int? itemId) {
    if (itemId == null) {
      return null;
    }
    return _itemsLookup.cast<ItemModel?>().firstWhere(
      (item) => item?.id == itemId,
      orElse: () => null,
    );
  }

  bool _isSerialManagedItem(int? itemId) => _itemById(itemId)?.hasSerial == true;

  bool _isBatchManagedItem(int? itemId) => _itemById(itemId)?.hasBatch == true;

  String _batchCacheKey(int? itemId, int? warehouseId) =>
      '${itemId ?? 0}:${warehouseId ?? 0}:${_companyId ?? 0}';

  String _serialCacheKey(int? itemId, int? warehouseId, [int? batchId]) =>
      '${itemId ?? 0}:${warehouseId ?? 0}:${batchId ?? 0}:${_companyId ?? 0}';

  List<String> _lineSerialNumbers(_SalesDeliveryLineDraft line) {
    if (line.serialNumbers.isNotEmpty) {
      return List<String>.from(line.serialNumbers);
    }
    final serialNo = line.serialNoController.text.trim();
    return serialNo.isEmpty ? const <String>[] : <String>[serialNo];
  }

  void _setLineSerialNumbers(
    _SalesDeliveryLineDraft line,
    List<String> values,
  ) {
    final normalized = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    line.serialNumbers = List<String>.from(normalized);
    line.serialNoController.text = normalized.isEmpty ? '' : normalized.first;
    if (_isSerialManagedItem(line.itemId)) {
      line.deliveredQtyController.text = normalized.length.toString();
    }
  }

  List<Map<String, dynamic>> _batchOptionsForLine(_SalesDeliveryLineDraft line) {
    if (!_isBatchManagedItem(line.itemId) ||
        line.itemId == null ||
        line.warehouseId == null) {
      return const <Map<String, dynamic>>[];
    }
    return _availableBatchesByItemWarehouse[_batchCacheKey(
          line.itemId,
          line.warehouseId,
        )] ??
        const <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _serialOptionsForLine(
    _SalesDeliveryLineDraft line,
  ) {
    if (!_isSerialManagedItem(line.itemId) ||
        line.itemId == null ||
        line.warehouseId == null) {
      return const <Map<String, dynamic>>[];
    }
    return _availableSerialsByItemWarehouse[_serialCacheKey(
          line.itemId,
          line.warehouseId,
          line.batchId,
        )] ??
        const <Map<String, dynamic>>[];
  }

  Future<void> _syncBatchOptionsForLine(_SalesDeliveryLineDraft line) async {
    final itemId = line.itemId;
    final warehouseId = line.warehouseId;
    if (itemId == null || warehouseId == null || !_isBatchManagedItem(itemId)) {
      return;
    }
    final cacheKey = _batchCacheKey(itemId, warehouseId);
    final cachedBatches = _availableBatchesByItemWarehouse[cacheKey];
    if (cachedBatches != null) {
      if (!mounted) {
        return;
      }
      final hasSelectedBatch = cachedBatches.any(
        (batch) =>
            int.tryParse(batch['batch_id']?.toString() ?? '') == line.batchId,
      );
      if ((line.batchId != null && !hasSelectedBatch) ||
          (line.batchId == null && cachedBatches.length == 1)) {
        setState(() {
          line.batchId = cachedBatches.length == 1
              ? int.tryParse(cachedBatches.first['batch_id']?.toString() ?? '')
              : null;
        });
      }
      return;
    }
    if (_batchOptionsLoadingKeys.contains(cacheKey)) {
      return;
    }
    _batchOptionsLoadingKeys.add(cacheKey);
    try {
      final response = await _inventoryService.inquiryBatchWiseStock(
        itemId: itemId,
        warehouseId: warehouseId,
        companyId: _companyId,
      );
      final raw = response.data;
      final batches = raw is List
          ? raw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .where((batch) {
                  final qty =
                      double.tryParse(batch['balance_qty']?.toString() ?? '') ??
                      0;
                  return qty > 0;
                })
                .toList(growable: false)
          : const <Map<String, dynamic>>[];
      if (!mounted) {
        return;
      }
      setState(() {
        _availableBatchesByItemWarehouse[cacheKey] = batches;
        final hasSelectedBatch = batches.any(
          (batch) =>
              int.tryParse(batch['batch_id']?.toString() ?? '') == line.batchId,
        );
        if (line.itemId == itemId &&
            line.warehouseId == warehouseId &&
            line.batchId != null &&
            !hasSelectedBatch) {
          line.batchId = batches.length == 1
              ? int.tryParse(batches.first['batch_id']?.toString() ?? '')
              : null;
        } else if (line.itemId == itemId &&
            line.warehouseId == warehouseId &&
            line.batchId == null &&
            batches.length == 1) {
          line.batchId = int.tryParse(
            batches.first['batch_id']?.toString() ?? '',
          );
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _availableBatchesByItemWarehouse[cacheKey] =
            const <Map<String, dynamic>>[];
      });
    } finally {
      _batchOptionsLoadingKeys.remove(cacheKey);
    }
  }

  Future<void> _syncSerialOptionsForLine(_SalesDeliveryLineDraft line) async {
    final itemId = line.itemId;
    final warehouseId = line.warehouseId;
    if (itemId == null ||
        warehouseId == null ||
        !_isSerialManagedItem(itemId)) {
      return;
    }
    final cacheKey = _serialCacheKey(itemId, warehouseId, line.batchId);
    final cachedSerials = _availableSerialsByItemWarehouse[cacheKey];
    if (cachedSerials != null) {
      return;
    }
    if (_serialOptionsLoadingKeys.contains(cacheKey)) {
      return;
    }
    _serialOptionsLoadingKeys.add(cacheKey);
    try {
      final response = await _inventoryService.inquiryAvailableSerials(
        itemId: itemId,
        warehouseId: warehouseId,
        batchId: line.batchId,
      );
      final raw = response.data;
      final serials = raw is List
          ? raw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList(growable: false)
          : const <Map<String, dynamic>>[];
      if (!mounted) {
        return;
      }
      setState(() {
        _availableSerialsByItemWarehouse[cacheKey] = serials;
        final validLabels = serials
            .map(
              (serial) =>
                  (serial['serial_no']?.toString().trim().toLowerCase() ?? ''),
            )
            .where((value) => value.isNotEmpty)
            .toSet();
        final filtered = _lineSerialNumbers(line)
            .where((value) => validLabels.contains(value.toLowerCase()))
            .toList(growable: false);
        _setLineSerialNumbers(line, filtered);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _availableSerialsByItemWarehouse[cacheKey] =
            const <Map<String, dynamic>>[];
      });
    } finally {
      _serialOptionsLoadingKeys.remove(cacheKey);
    }
  }

  void _syncInventoryOptionsForLines(Iterable<_SalesDeliveryLineDraft> lines) {
    for (final line in lines) {
      unawaited(_syncBatchOptionsForLine(line));
      unawaited(_syncSerialOptionsForLine(line));
    }
  }

  List<Map<String, dynamic>> _linesForSave() {
    return _lines
        .expand((line) {
          final deliveredQty =
              double.tryParse(line.deliveredQtyController.text.trim()) ?? 0;
          final rate = double.tryParse(line.rateController.text.trim()) ?? 0;
          final description = nullIfEmpty(line.descriptionController.text);
          final remarks = nullIfEmpty(line.remarksController.text);

          if (_isSerialManagedItem(line.itemId)) {
            final serials = _lineSerialNumbers(line);
            return serials.map((serialNo) {
              final matched = _serialOptionsForLine(line)
                  .cast<Map<String, dynamic>?>()
                  .firstWhere(
                    (serial) =>
                        (serial?['serial_no']
                                ?.toString()
                                .trim()
                                .toLowerCase() ??
                            '') ==
                        serialNo.toLowerCase(),
                    orElse: () => null,
                  );
              return <String, dynamic>{
                if (line.salesOrderLineId != null)
                  'sales_order_line_id': line.salesOrderLineId,
                'item_id': line.itemId,
                'warehouse_id': line.warehouseId,
                'uom_id': line.uomId,
                if (line.batchId != null) 'batch_id': line.batchId,
                if (matched != null)
                  'serial_id': int.tryParse(
                    matched['serial_id']?.toString() ?? '',
                  ),
                'description': description,
                'delivered_qty': 1,
                'rate': rate,
                'remarks': remarks,
              };
            });
          }

          return <Map<String, dynamic>>[
            <String, dynamic>{
              if (line.salesOrderLineId != null)
                'sales_order_line_id': line.salesOrderLineId,
              'item_id': line.itemId,
              'warehouse_id': line.warehouseId,
              'uom_id': line.uomId,
              if (line.batchId != null) 'batch_id': line.batchId,
              'description': description,
              'delivered_qty': deliveredQty,
              'rate': rate,
              'remarks': remarks,
            },
          ];
        })
        .toList(growable: false);
  }

  Future<void> _loadPage({int? selectId}) async {
    setState(() {
      _initialLoading = _items.isEmpty;
      _pageError = null;
    });
    try {
      final responses = await Future.wait<dynamic>([
        _salesService.deliveries(
          filters: const {'per_page': 200, 'sort_by': 'delivery_date'},
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
        _salesService.ordersAll(filters: const {'sort_by': 'order_date'}),
        _partiesService.partyTypes(filters: const {'per_page': 100}),
        _partiesService.parties(
          filters: const {'per_page': 300, 'sort_by': 'party_name'},
        ),
        _masterService.warehouses(
          filters: const {'per_page': 200, 'sort_by': 'name'},
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
            (responses[0] as PaginatedResponse<SalesDeliveryModel>).data ??
            const <SalesDeliveryModel>[];
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
            (responses[6] as ApiResponse<List<SalesOrderModel>>).data ??
            const <SalesOrderModel>[];
        _allParties =
            (responses[8] as PaginatedResponse<PartyModel>).data ??
            const <PartyModel>[];
        _customers = salesCustomersOrFallback(
          parties: _allParties,
          partyTypes:
              (responses[7] as PaginatedResponse<PartyTypeModel>).data ??
              const <PartyTypeModel>[],
        );
        _warehouses =
            ((responses[9] as PaginatedResponse<WarehouseModel>).data ??
                    const <WarehouseModel>[])
                .where((item) => item.isActive)
                .toList();
        _itemsLookup =
            ((responses[10] as PaginatedResponse<ItemModel>).data ??
                    const <ItemModel>[])
                .where((item) => item.isActive)
                .toList();
        _uoms =
            ((responses[11] as PaginatedResponse<UomModel>).data ??
                    const <UomModel>[])
                .where((item) => item.isActive)
                .toList();
        _uomConversions =
            ((responses[12] as ApiResponse<List<UomConversionModel>>).data ??
                    const <UomConversionModel>[])
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
          ? _items.cast<SalesDeliveryModel?>().firstWhere(
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

  Future<void> _selectDocument(SalesDeliveryModel item) async {
    final id = intValue(item.toJson(), 'id');
    if (id == null) return;
    final response = await _salesService.delivery(id);
    final full = response.data ?? item;
    final data = full.toJson();
    final lines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(_SalesDeliveryLineDraft.fromJson)
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
      _salesOrderId = intValue(data, 'sales_order_id');
      _customerPartyId = intValue(data, 'customer_party_id');
      _transporterPartyId = intValue(data, 'transporter_party_id');
      _deliveryNoController.text = stringValue(data, 'delivery_no');
      _deliveryDateController.text = displayDate(
        nullableStringValue(data, 'delivery_date'),
      );
      _vehicleNoController.text = stringValue(data, 'vehicle_no');
      _lrNoController.text = stringValue(data, 'lr_no');
      _lrDateController.text = displayDate(
        nullableStringValue(data, 'lr_date'),
      );
      _notesController.text = stringValue(data, 'notes');
      _isActive = boolValue(data, 'is_active', fallback: true);
      _lines = lines.isEmpty
          ? <_SalesDeliveryLineDraft>[_SalesDeliveryLineDraft()]
          : lines;
      _formError = null;
    });
    _syncInventoryOptionsForLines(_lines);
    await _refreshSalesChain();
  }

  Future<void> _refreshSalesChain() async {
    final oid = _salesOrderId;
    try {
      if (oid != null) {
        final r = await _crmService.salesChain(orderId: oid);
        if (!mounted) {
          return;
        }
        setState(() => _salesChain = r.data);
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() => _salesChain = null);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _salesChain = null);
    }
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
      _salesOrderId = null;
      _customerPartyId = null;
      _transporterPartyId = null;
      _deliveryNoController.clear();
      _deliveryDateController.text = DateTime.now()
          .toIso8601String()
          .split('T')
          .first;
      _vehicleNoController.clear();
      _lrNoController.clear();
      _lrDateController.clear();
      _notesController.clear();
      _isActive = true;
      _lines = <_SalesDeliveryLineDraft>[_SalesDeliveryLineDraft()];
      _formError = null;
      _salesChain = null;
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
                stringValue(data, 'delivery_status') == _statusFilter;
            final searchOk =
                search.isEmpty ||
                [
                  stringValue(data, 'delivery_no'),
                  stringValue(data, 'delivery_status'),
                  quotationCustomerLabel(data),
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

  List<DocumentSeriesModel> _seriesOptions() {
    return _documentSeries
        .where((item) {
          final typeOk =
              item.documentType == null ||
              item.documentType == 'SALES_DELIVERY';
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

  int? _deliveryDocumentSeriesIdFrom(Map<String, dynamic> data) {
    final sid = intValue(data, 'document_series_id');
    if (sid != 0) {
      return sid;
    }
    final series = _seriesOptions();
    return series.isNotEmpty ? series.first.id : null;
  }

  void _applyDeliveryHeaderFromOrderJson(Map<String, dynamic> data) {
    _companyId = intValue(data, 'company_id');
    _branchId = intValue(data, 'branch_id');
    _locationId = intValue(data, 'location_id');
    _financialYearId = intValue(data, 'financial_year_id');
    _documentSeriesId = _deliveryDocumentSeriesIdFrom(data);
    final customerId = intValue(data, 'customer_party_id');
    _customerPartyId = customerId == 0 ? null : customerId;
    _notesController.text = stringValue(data, 'notes');
  }

  void _applyLinesFromOrderJson(Map<String, dynamic> data) {
    for (final line in _lines) {
      line.dispose();
    }
    final drafts = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map((line) {
          final ordered =
              double.tryParse(line['ordered_qty']?.toString() ?? '') ?? 0;
          final delivered =
              double.tryParse(line['delivered_qty']?.toString() ?? '') ?? 0;
          final pending = ordered - delivered;
          return _SalesDeliveryLineDraft(
            salesOrderLineId: intValue(line, 'id'),
            itemId: intValue(line, 'item_id'),
            warehouseId: intValue(line, 'warehouse_id'),
            batchId: intValue(line, 'batch_id'),
            serialNumbers: <String>[
              if (stringValue(line, 'serial_no').trim().isNotEmpty)
                stringValue(line, 'serial_no').trim(),
            ],
            serialNo: stringValue(line, 'serial_no'),
            uomId: intValue(line, 'uom_id'),
            description: stringValue(line, 'description'),
            deliveredQty: pending > 0 ? pending.toString() : '',
            rate: stringValue(line, 'rate'),
            remarks: stringValue(line, 'remarks'),
          );
        })
        .where((line) {
          final qty =
              double.tryParse(line.deliveredQtyController.text.trim()) ?? 0;
          return qty > 0;
        })
        .toList(growable: true);

    _lines = drafts.isEmpty
        ? <_SalesDeliveryLineDraft>[_SalesDeliveryLineDraft()]
        : drafts;
  }

  Map<String, dynamic> _salesDeliveryPrintData() {
    final company = _companies.cast<CompanyModel?>().firstWhere(
      (item) => item?.id == _companyId,
      orElse: () => null,
    );
    final customer = _customers.cast<PartyModel?>().firstWhere(
      (item) => item?.id == _customerPartyId,
      orElse: () => null,
    );
    var subtotal = 0.0;
    final lines = _lines
        .map((line) {
          final qty =
              double.tryParse(line.deliveredQtyController.text.trim()) ?? 0;
          final rate = double.tryParse(line.rateController.text.trim()) ?? 0;
          final total = qty * rate;
          subtotal += total;
          final item = _itemsLookup.cast<ItemModel?>().firstWhere(
            (entry) => entry?.id == line.itemId,
            orElse: () => null,
          );
          return <String, dynamic>{
            'item_name':
                item?.itemName ??
                item?.itemCode ??
                line.descriptionController.text.trim(),
            'description': line.descriptionController.text.trim(),
            'qty': qty,
            'rate': rate,
            'line_total': roundToDouble(total, 2),
          };
        })
        .toList(growable: false);

    return <String, dynamic>{
      'company_name': companyNameById(_companies, _companyId),
      'company_logo_url':
          AppConfig.resolvePublicFileUrl(company?.logoPath) ??
          'assets/sakthicontroller logo.jpg',
      'document_number': nullIfEmpty(_deliveryNoController.text) ?? 'Draft',
      'document_date': _deliveryDateController.text.trim(),
      'reference_number': '',
      'party_name': customer?.partyName ?? '',
      'party_address': '',
      'party_contact': '',
      'notes': _notesController.text.trim(),
      'subtotal': roundToDouble(subtotal, 2),
      'tax_amount': 0,
      'total_amount': roundToDouble(subtotal, 2),
      'lines': lines,
    };
  }

  Future<void> _openPrintPreview() {
    return openDocumentPrintDesigner(
      context,
      documentType: 'sales_delivery',
      title: 'Delivery Challan',
      documentData: _salesDeliveryPrintData(),
    );
  }

  Future<void> _applySalesOrderSelection(int? orderId) async {
    setState(() => _salesOrderId = orderId);
    if (orderId == null) {
      await _refreshSalesChain();
      return;
    }
    try {
      final response = await _salesService.order(orderId);
      final data = response.data?.toJson() ?? <String, dynamic>{};
      if (!mounted) {
        return;
      }
      setState(() {
        _applyDeliveryHeaderFromOrderJson(data);
        _applyLinesFromOrderJson(data);
        _formError = null;
      });
      _syncInventoryOptionsForLines(_lines);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _formError = error.toString());
    }
    await _refreshSalesChain();
  }

  void _addLine() => setState(
    () =>
        _lines = List<_SalesDeliveryLineDraft>.from(_lines)
          ..add(_SalesDeliveryLineDraft()),
  );

  void _removeLine(int index) {
    setState(() {
      final next = List<_SalesDeliveryLineDraft>.from(_lines);
      next.removeAt(index).dispose();
      _lines = next;
      if (_lines.isEmpty) _lines.add(_SalesDeliveryLineDraft());
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _syncInventoryOptionsForLines(_lines);
    if (_lines.any(
      (line) =>
          line.itemId == null ||
          line.uomId == null ||
          line.warehouseId == null ||
          (double.tryParse(line.deliveredQtyController.text.trim()) ?? 0) <= 0,
    )) {
      setState(
        () => _formError =
            'Each line needs item, warehouse, UOM, and delivered quantity.',
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
      'sales_order_id': _salesOrderId,
      'delivery_no': nullIfEmpty(_deliveryNoController.text),
      'delivery_date': _deliveryDateController.text.trim(),
      'customer_party_id': _customerPartyId,
      'transporter_party_id': _transporterPartyId,
      'vehicle_no': nullIfEmpty(_vehicleNoController.text),
      'lr_no': nullIfEmpty(_lrNoController.text),
      'lr_date': nullIfEmpty(_lrDateController.text),
      'notes': nullIfEmpty(_notesController.text),
      'is_active': _isActive,
      'lines': _linesForSave(),
    };
    try {
      final response = _selectedItem == null
          ? await _salesService.createDelivery(SalesDeliveryModel(payload))
          : await _salesService.updateDelivery(
              intValue(_selectedItem!.toJson(), 'id')!,
              SalesDeliveryModel(payload),
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
    Future<ApiResponse<SalesDeliveryModel>> Function() action,
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
        label: 'New Delivery',
      ),
    ];
    final content = _buildContent();
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'Sales Deliveries',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading sales deliveries...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load sales deliveries',
        message: _pageError!,
        onRetry: _loadPage,
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Sales Deliveries',
      editorTitle: _selectedItem == null
          ? 'New Sales Delivery'
          : stringValue(
              _selectedItem!.toJson(),
              'delivery_no',
              'Sales Delivery',
            ),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: PurchaseListCard<SalesDeliveryModel>(
        items: _filteredItems,
        selectedItem: _selectedItem,
        emptyMessage: 'No sales deliveries found.',
        searchController: _searchController,
        searchHint: 'Search deliveries',
        statusValue: _statusFilter,
        statusItems: _statusItems,
        onStatusChanged: (value) {
          _statusFilter = value ?? '';
          _applyFilters();
        },
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'delivery_no', 'Draft Delivery'),
            subtitle: [
              displayDate(nullableStringValue(data, 'delivery_date')),
              stringValue(data, 'delivery_status'),
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
            CrmSalesPipelineBar(data: _salesChain),
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
                  labelText: 'Delivery No',
                  controller: _deliveryNoController,
                  hintText: 'Auto-generated on save',
                  validator: Validators.optionalMaxLength(100, 'Delivery No'),
                ),
                AppFormTextField(
                  labelText: 'Delivery Date',
                  controller: _deliveryDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([
                    Validators.required('Delivery Date'),
                    Validators.date('Delivery Date'),
                  ]),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Customer',
                  doctypeLabel: 'Customer',
                  allowCreate: true,
                  onNavigateToCreateNew: (name) {
                    final uri = Uri(
                      path: '/parties',
                      queryParameters: {
                        'new': '1',
                        if (name.trim().isNotEmpty) 'party_name': name.trim(),
                      },
                    );
                    openModuleShellRoute(context, uri.toString());
                  },
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
                AppDropdownField<int>.fromMapped(
                  labelText: 'Sales Order',
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
                  initialValue: _salesOrderId,
                  onChanged: (value) {
                    unawaited(_applySalesOrderSelection(value));
                  },
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Transporter',
                  mappedItems: _allParties
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _transporterPartyId,
                  onChanged: (value) =>
                      setState(() => _transporterPartyId = value),
                ),
                AppFormTextField(
                  labelText: 'Vehicle No',
                  controller: _vehicleNoController,
                ),
                AppFormTextField(
                  labelText: 'LR No',
                  controller: _lrNoController,
                ),
                AppFormTextField(
                  labelText: 'LR Date',
                  controller: _lrDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDate('LR Date'),
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
                          line.batchId = null;
                          line.serialNumbers = <String>[];
                          line.serialNoController.clear();
                          final item = _itemsLookup
                              .cast<ItemModel?>()
                              .firstWhere(
                                (e) => e?.id == value,
                                orElse: () => null,
                              );
                          applySalesLineDefaultsFromItemMaster(
                            item: item,
                            uoms: _uoms,
                            conversions: _uomConversions,
                            rateController: line.rateController,
                            setUom: (u) => line.uomId = u,
                            currentUomId: line.uomId,
                            setWarehouseId: (w) => line.warehouseId = w,
                            currentWarehouseId: line.warehouseId,
                            warehouses: _warehouses,
                          );
                          if (_isSerialManagedItem(value)) {
                            line.deliveredQtyController.text = '';
                          }
                        }),
                        validator: (_) =>
                            line.itemId == null ? 'Item is required' : null,
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
                          setState(() {
                            line.warehouseId = value;
                            line.batchId = null;
                            line.serialNumbers = <String>[];
                            line.serialNoController.clear();
                          });
                          unawaited(_syncBatchOptionsForLine(line));
                          unawaited(_syncSerialOptionsForLine(line));
                        },
                        validator: Validators.requiredSelection('Warehouse'),
                      ),
                      if (_isBatchManagedItem(line.itemId))
                        AppDropdownField<int>.fromMapped(
                          labelText: 'Batch',
                          mappedItems: _batchOptionsForLine(line)
                              .map(
                                (batch) => AppDropdownItem<int>(
                                  value:
                                      int.tryParse(
                                        batch['batch_id']?.toString() ?? '',
                                      ) ??
                                      0,
                                  label: stringValue(
                                    batch,
                                    'batch_no',
                                    'Batch',
                                  ),
                                ),
                              )
                              .where((item) => item.value != 0)
                              .toList(growable: false),
                          initialValue: line.batchId,
                          onChanged: (value) {
                            setState(() {
                              line.batchId = value;
                              line.serialNumbers = <String>[];
                              line.serialNoController.clear();
                            });
                            unawaited(_syncSerialOptionsForLine(line));
                          },
                          validator: (_) {
                            if (!_isBatchManagedItem(line.itemId)) {
                              return null;
                            }
                            if (line.warehouseId == null) {
                              return 'Select warehouse first';
                            }
                            final batches = _batchOptionsForLine(line);
                            if (batches.isEmpty) {
                              return 'No batches found for the selected warehouse';
                            }
                            return line.batchId == null
                                ? 'Batch is required'
                                : null;
                          },
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
                      if (_isSerialManagedItem(line.itemId))
                        AppSerialNumbersField(
                          values: line.serialNumbers,
                          canOpen:
                              ((_isBatchManagedItem(line.itemId)
                                  ? line.batchId != null
                                  : line.warehouseId != null) ||
                              line.serialNumbers.isNotEmpty),
                          beforeOpen: () => _syncSerialOptionsForLine(line),
                          validator: (values) {
                            final serialOptions = _serialOptionsForLine(line);
                            if (line.warehouseId == null) {
                              return 'Select warehouse first';
                            }
                            if (_isBatchManagedItem(line.itemId) &&
                                line.batchId == null) {
                              return 'Select batch first';
                            }
                            if (serialOptions.isEmpty) {
                              return 'No serials found in backend for the selected warehouse.';
                            }
                            final serialLabelSet = serialOptions
                                .map(
                                  (serial) =>
                                      (serial['serial_no']
                                          ?.toString()
                                          .trim()
                                          .toLowerCase() ??
                                      ''),
                                )
                                .where((value) => value.isNotEmpty)
                                .toSet();
                            for (final value in values) {
                              if (!serialLabelSet.contains(
                                value.trim().toLowerCase(),
                              )) {
                                return 'Serial "$value" is not available for the selected warehouse/batch.';
                              }
                            }
                            return null;
                          },
                          onChanged: (values) {
                            setState(() {
                              _setLineSerialNumbers(line, values);
                            });
                          },
                        ),
                      AppFormTextField(
                        labelText: 'Delivered Qty',
                        controller: line.deliveredQtyController,
                        enabled: !_isSerialManagedItem(line.itemId),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (_) {
                          final text = line.deliveredQtyController.text.trim();
                          if (text.isEmpty) {
                            return 'Delivered Qty is required';
                          }
                          final qty = double.tryParse(text);
                          if (qty == null || qty < 0) {
                            return 'Delivered Qty must be a valid non-negative number';
                          }
                          if (qty <= 0) {
                            return 'Delivered Qty must be greater than zero';
                          }
                          if (_isSerialManagedItem(line.itemId)) {
                            final serialCount = _lineSerialNumbers(line).length;
                            if (serialCount == 0) {
                              return 'Add at least one serial number';
                            }
                            if (qty != serialCount) {
                              return 'Qty must match serial count';
                            }
                          }
                          return null;
                        },
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
                  icon: Icons.print_outlined,
                  label: 'Print',
                  filled: false,
                  onPressed: _openPrintPreview,
                ),
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: _selectedItem == null
                      ? 'Save Delivery'
                      : 'Update Delivery',
                  onPressed: _save,
                  busy: _saving,
                ),
                if (_selectedItem != null) ...[
                  AppActionButton(
                    icon: Icons.publish_outlined,
                    label: 'Post',
                    filled: false,
                    onPressed: () => _docAction(
                      () => _salesService.postDelivery(
                        intValue(_selectedItem!.toJson(), 'id')!,
                        SalesDeliveryModel(const <String, dynamic>{}),
                      ),
                    ),
                  ),
                  AppActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Cancel',
                    filled: false,
                    onPressed: () => _docAction(
                      () => _salesService.cancelDelivery(
                        intValue(_selectedItem!.toJson(), 'id')!,
                        SalesDeliveryModel(const <String, dynamic>{}),
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

class _SalesDeliveryLineDraft {
  _SalesDeliveryLineDraft({
    this.salesOrderLineId,
    this.itemId,
    this.warehouseId,
    this.batchId,
    this.uomId,
    List<String>? serialNumbers,
    String? serialNo,
    String? description,
    String? deliveredQty,
    String? rate,
    String? remarks,
  }) : descriptionController = TextEditingController(text: description ?? ''),
       deliveredQtyController = TextEditingController(text: deliveredQty ?? ''),
       rateController = TextEditingController(text: rate ?? ''),
       remarksController = TextEditingController(text: remarks ?? ''),
       serialNoController = TextEditingController(text: serialNo ?? ''),
       serialNumbers = List<String>.from(serialNumbers ?? const <String>[]);

  factory _SalesDeliveryLineDraft.fromJson(Map<String, dynamic> json) {
    return _SalesDeliveryLineDraft(
      salesOrderLineId: intValue(json, 'sales_order_line_id'),
      itemId: intValue(json, 'item_id'),
      warehouseId: intValue(json, 'warehouse_id'),
      batchId: intValue(json, 'batch_id'),
      uomId: intValue(json, 'uom_id'),
      serialNumbers: <String>[
        if (stringValue(json, 'serial_no').trim().isNotEmpty)
          stringValue(json, 'serial_no').trim(),
      ],
      serialNo: stringValue(json, 'serial_no'),
      description: stringValue(json, 'description'),
      deliveredQty: stringValue(json, 'delivered_qty'),
      rate: stringValue(json, 'rate'),
      remarks: stringValue(json, 'remarks'),
    );
  }

  int? salesOrderLineId;
  int? itemId;
  int? warehouseId;
  int? batchId;
  int? uomId;
  List<String> serialNumbers;
  final TextEditingController descriptionController;
  final TextEditingController deliveredQtyController;
  final TextEditingController rateController;
  final TextEditingController remarksController;
  final TextEditingController serialNoController;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (salesOrderLineId != null) 'sales_order_line_id': salesOrderLineId,
      'item_id': itemId,
      'warehouse_id': warehouseId,
      if (batchId != null) 'batch_id': batchId,
      'uom_id': uomId,
      'description': nullIfEmpty(descriptionController.text),
      'delivered_qty': double.tryParse(deliveredQtyController.text.trim()) ?? 0,
      'rate': double.tryParse(rateController.text.trim()) ?? 0,
      'remarks': nullIfEmpty(remarksController.text),
    };
  }

  void dispose() {
    descriptionController.dispose();
    deliveredQtyController.dispose();
    rateController.dispose();
    remarksController.dispose();
    serialNoController.dispose();
  }
}
