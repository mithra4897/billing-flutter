import 'dart:async';

import '../../screen.dart';
import 'purchase_support.dart';

class PurchaseReceiptPage extends StatefulWidget {
  const PurchaseReceiptPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<PurchaseReceiptPage> createState() => _PurchaseReceiptPageState();
}

class _PurchaseReceiptPageState extends State<PurchaseReceiptPage> {
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

  final PurchaseService _purchaseService = PurchaseService();
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final InventoryService _inventoryService = InventoryService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _receiptNoController = TextEditingController();
  final TextEditingController _receiptDateController = TextEditingController();
  final TextEditingController _supplierInvoiceNoController =
      TextEditingController();
  final TextEditingController _supplierInvoiceDateController =
      TextEditingController();
  final TextEditingController _supplierDcNoController = TextEditingController();
  final TextEditingController _supplierDcDateController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  String _statusFilter = '';
  List<PurchaseReceiptModel> _items = const <PurchaseReceiptModel>[];
  List<PurchaseReceiptModel> _filteredItems = const <PurchaseReceiptModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<BranchModel> _branches = const <BranchModel>[];
  List<BusinessLocationModel> _locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> _financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> _documentSeries = const <DocumentSeriesModel>[];
  List<PurchaseOrderModel> _orders = const <PurchaseOrderModel>[];
  List<PartyModel> _suppliers = const <PartyModel>[];
  List<WarehouseModel> _warehouses = const <WarehouseModel>[];
  List<ItemModel> _itemsLookup = const <ItemModel>[];
  List<UomModel> _uoms = const <UomModel>[];
  List<UomConversionModel> _uomConversions = const <UomConversionModel>[];
  final Map<String, List<StockSerialModel>> _serialOptionsByItemWarehouse =
      <String, List<StockSerialModel>>{};
  final Set<String> _serialOptionsLoadingKeys = <String>{};
  PurchaseReceiptModel? _selectedItem;
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
  int? _supplierPartyId;
  int? _warehouseId;
  bool _isActive = true;
  List<_PurchaseReceiptLineDraft> _lines = <_PurchaseReceiptLineDraft>[];

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
    _receiptNoController.dispose();
    _receiptDateController.dispose();
    _supplierInvoiceNoController.dispose();
    _supplierInvoiceDateController.dispose();
    _supplierDcNoController.dispose();
    _supplierDcDateController.dispose();
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
        _purchaseService.receipts(
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
        _purchaseService.ordersAll(filters: const {'sort_by': 'order_date'}),
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
            (responses[0] as PaginatedResponse<PurchaseReceiptModel>).data ??
            const <PurchaseReceiptModel>[];
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
        _suppliers = purchaseSuppliers(
          parties:
              (responses[8] as PaginatedResponse<PartyModel>).data ??
              const <PartyModel>[],
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
          ? _items.cast<PurchaseReceiptModel?>().firstWhere(
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

  Future<void> _selectDocument(PurchaseReceiptModel item) async {
    final id = intValue(item.toJson(), 'id');
    if (id == null) return;
    final response = await _purchaseService.receipt(id);
    final full = response.data ?? item;
    final data = full.toJson();
    final lines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(_PurchaseReceiptLineDraft.fromJson)
        .toList(growable: true);
    setState(() {
      _selectedItem = full;
      _companyId = intValue(data, 'company_id');
      _branchId = intValue(data, 'branch_id');
      _locationId = intValue(data, 'location_id');
      _financialYearId = intValue(data, 'financial_year_id');
      _documentSeriesId = intValue(data, 'document_series_id');
      _purchaseOrderId = intValue(data, 'purchase_order_id');
      _supplierPartyId = intValue(data, 'supplier_party_id');
      _warehouseId = intValue(data, 'warehouse_id');
      _receiptNoController.text = stringValue(data, 'receipt_no');
      _receiptDateController.text = displayDate(
        nullableStringValue(data, 'receipt_date'),
      );
      _supplierInvoiceNoController.text = stringValue(
        data,
        'supplier_invoice_no',
      );
      _supplierInvoiceDateController.text = displayDate(
        nullableStringValue(data, 'supplier_invoice_date'),
      );
      _supplierDcNoController.text = stringValue(data, 'supplier_dc_no');
      _supplierDcDateController.text = displayDate(
        nullableStringValue(data, 'supplier_dc_date'),
      );
      _notesController.text = stringValue(data, 'notes');
      _isActive = boolValue(data, 'is_active', fallback: true);
      _lines = lines.isEmpty
          ? <_PurchaseReceiptLineDraft>[_PurchaseReceiptLineDraft()]
          : lines;
      _formError = null;
    });
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final line in _lines) {
        if (_isSerialManagedItem(line.itemId)) {
          unawaited(_syncSerialOptionsForLine(line));
        }
      }
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
      _supplierPartyId = null;
      _warehouseId = null;
      _receiptNoController.clear();
      _receiptDateController.text = DateTime.now()
          .toIso8601String()
          .split('T')
          .first;
      _supplierInvoiceNoController.clear();
      _supplierInvoiceDateController.clear();
      _supplierDcNoController.clear();
      _supplierDcDateController.clear();
      _notesController.clear();
      _isActive = true;
      _lines = <_PurchaseReceiptLineDraft>[_PurchaseReceiptLineDraft()];
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
                stringValue(data, 'receipt_status') == _statusFilter;
            final searchOk =
                search.isEmpty ||
                [
                  stringValue(data, 'receipt_no'),
                  stringValue(data, 'receipt_status'),
                  stringValue(data, 'supplier_name'),
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

  bool _isSerialManagedItem(int? itemId) {
    if (itemId == null) {
      return false;
    }
    final item = _itemsLookup.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == itemId,
      orElse: () => null,
    );
    return item?.hasSerial ?? false;
  }

  String _serialCacheKey(int? itemId, int? warehouseId) =>
      '${itemId ?? 0}:${warehouseId ?? 0}';

  List<StockSerialModel> _serialOptionsForLine(_PurchaseReceiptLineDraft line) {
    if (!_isSerialManagedItem(line.itemId) ||
        line.itemId == null ||
        line.warehouseId == null) {
      return const <StockSerialModel>[];
    }
    return _serialOptionsByItemWarehouse[_serialCacheKey(
          line.itemId,
          line.warehouseId,
        )] ??
        const <StockSerialModel>[];
  }

  Future<void> _syncSerialOptionsForLine(_PurchaseReceiptLineDraft line) async {
    final itemId = line.itemId;
    final warehouseId = line.warehouseId;
    if (itemId == null ||
        warehouseId == null ||
        !_isSerialManagedItem(itemId)) {
      return;
    }

    final cacheKey = _serialCacheKey(itemId, warehouseId);
    final cached = _serialOptionsByItemWarehouse[cacheKey];
    if (cached != null) {
      if (!mounted) return;
      final hasSelected = cached.any(
        (serial) => intValue(serial.toJson(), 'id') == line.serialId,
      );
      if ((line.serialId != null && !hasSelected) ||
          (line.serialId == null && cached.length == 1)) {
        setState(() {
          line.serialId = cached.length == 1
              ? intValue(cached.first.toJson(), 'id')
              : null;
        });
      }
      return;
    }

    if (_serialOptionsLoadingKeys.contains(cacheKey)) {
      return;
    }
    _serialOptionsLoadingKeys.add(cacheKey);
    try {
      final response = await _inventoryService.stockSerialsDropdown(
        filters: <String, dynamic>{
          'item_id': itemId,
          'warehouse_id': warehouseId,
        },
      );
      final serials = response.data ?? const <StockSerialModel>[];
      if (!mounted) return;
      setState(() {
        _serialOptionsByItemWarehouse[cacheKey] = serials;
        final hasSelected = serials.any(
          (serial) => intValue(serial.toJson(), 'id') == line.serialId,
        );
        if (line.itemId == itemId &&
            line.warehouseId == warehouseId &&
            line.serialId != null &&
            !hasSelected) {
          line.serialId = serials.length == 1
              ? intValue(serials.first.toJson(), 'id')
              : null;
        } else if (line.itemId == itemId &&
            line.warehouseId == warehouseId &&
            line.serialId == null &&
            serials.length == 1) {
          line.serialId = intValue(serials.first.toJson(), 'id');
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _serialOptionsByItemWarehouse[cacheKey] = const <StockSerialModel>[];
        if (line.itemId == itemId && line.warehouseId == warehouseId) {
          line.serialId = null;
        }
      });
    } finally {
      _serialOptionsLoadingKeys.remove(cacheKey);
    }
  }

  List<DocumentSeriesModel> _seriesOptions() {
    return _documentSeries
        .where((item) {
          final typeOk =
              item.documentType == null ||
              item.documentType == 'PURCHASE_RECEIPT';
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
              item.documentType == 'PURCHASE_RECEIPT';
          final companyOk = companyId == null || item.companyId == companyId;
          final fyOk =
              financialYearId == null ||
              item.financialYearId == financialYearId;
          return typeOk && companyOk && fyOk;
        })
        .toList(growable: false);
    return options.isNotEmpty ? options.first.id : null;
  }

  double _pendingReceiptQtyForOrderLine(Map<String, dynamic> line) {
    final orderedQty = double.tryParse(stringValue(line, 'ordered_qty')) ?? 0;
    final receivedQty = double.tryParse(stringValue(line, 'received_qty')) ?? 0;
    return (orderedQty - receivedQty).clamp(0, double.infinity).toDouble();
  }

  List<_PurchaseReceiptLineDraft> _buildReceiptLinesFromOrder(
    PurchaseOrderModel order,
  ) {
    final orderLines = (order.toJson()['lines'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();

    final drafts = orderLines
        .expand((line) {
          final pendingQty = _pendingReceiptQtyForOrderLine(line);
          if (pendingQty <= 0) {
            return const <_PurchaseReceiptLineDraft>[];
          }
          final itemId = intValue(line, 'item_id');
          if (_isSerialManagedItem(itemId)) {
            final units = pendingQty.floor();
            return List<_PurchaseReceiptLineDraft>.generate(
              units > 0 ? units : 1,
              (_) => _PurchaseReceiptLineDraft(
                purchaseOrderLineId: intValue(line, 'id'),
                itemId: itemId,
                warehouseId: intValue(line, 'warehouse_id'),
                uomId: intValue(line, 'uom_id'),
                description: stringValue(line, 'description'),
                receivedQty: '1',
                acceptedQty: '1',
                rejectedQty: '0',
                rate: stringValue(line, 'rate'),
                remarks: stringValue(line, 'remarks'),
              ),
              growable: false,
            );
          }

          return <_PurchaseReceiptLineDraft>[
            _PurchaseReceiptLineDraft(
              purchaseOrderLineId: intValue(line, 'id'),
              itemId: itemId,
              warehouseId: intValue(line, 'warehouse_id'),
              uomId: intValue(line, 'uom_id'),
              description: stringValue(line, 'description'),
              receivedQty: pendingQty.toString(),
              acceptedQty: pendingQty.toString(),
              rejectedQty: '0',
              rate: stringValue(line, 'rate'),
              remarks: stringValue(line, 'remarks'),
            ),
          ];
        })
        .toList(growable: false);

    return drafts.isEmpty
        ? <_PurchaseReceiptLineDraft>[_PurchaseReceiptLineDraft()]
        : drafts;
  }

  Future<void> _handlePurchaseOrderChanged(int? orderId) async {
    if (orderId == null) {
      setState(() {
        _purchaseOrderId = null;
        _supplierPartyId = null;
        _warehouseId = null;
        _lines = <_PurchaseReceiptLineDraft>[_PurchaseReceiptLineDraft()];
        _formError = null;
      });
      return;
    }

    final response = await _purchaseService.order(orderId);
    final order = response.data;
    if (!mounted || order == null) return;

    final data = order.toJson();
    final lines = _buildReceiptLinesFromOrder(order);
    final defaultWarehouseId = lines
        .map((line) => line.warehouseId)
        .whereType<int>()
        .cast<int?>()
        .firstWhere((value) => value != null, orElse: () => null);
    final companyId = intValue(data, 'company_id');
    final financialYearId = intValue(data, 'financial_year_id');

    setState(() {
      _purchaseOrderId = orderId;
      _companyId = companyId;
      _branchId = intValue(data, 'branch_id');
      _locationId = intValue(data, 'location_id');
      _financialYearId = financialYearId;
      _documentSeriesId = _defaultSeriesIdFor(
        companyId: companyId,
        financialYearId: financialYearId,
      );
      _supplierPartyId = intValue(data, 'supplier_party_id');
      _warehouseId = defaultWarehouseId;
      _receiptNoController.clear();
      _supplierInvoiceNoController.clear();
      _supplierInvoiceDateController.clear();
      _supplierDcNoController.clear();
      _supplierDcDateController.clear();
      _notesController.text = stringValue(data, 'notes');
      _lines = lines;
      _formError = lines.length == 1 && lines.first.itemId == null
          ? 'Selected purchase order has no pending receipt quantity.'
          : null;
    });
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final line in _lines) {
        if (_isSerialManagedItem(line.itemId)) {
          unawaited(_syncSerialOptionsForLine(line));
        }
      }
    });
  }

  List<BranchModel> get _branchOptions =>
      branchesForCompany(_branches, _companyId);
  List<BusinessLocationModel> get _locationOptions =>
      locationsForBranch(_locations, _branchId);

  void _addLine() => setState(
    () =>
        _lines = List<_PurchaseReceiptLineDraft>.from(_lines)
          ..add(_PurchaseReceiptLineDraft()),
  );

  void _removeLine(int index) {
    setState(() {
      _lines = List<_PurchaseReceiptLineDraft>.from(_lines)..removeAt(index);
      if (_lines.isEmpty) _lines.add(_PurchaseReceiptLineDraft());
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lines.any(
      (line) =>
          line.itemId == null ||
          line.uomId == null ||
          line.warehouseId == null ||
          (_isSerialManagedItem(line.itemId) && line.serialId == null) ||
          (double.tryParse(line.receivedQtyController.text.trim()) ?? 0) <= 0,
    )) {
      setState(
        () => _formError =
            'Each line needs item, warehouse, UOM, received quantity, and serial for serial-managed items.',
      );
      return;
    }
    for (var index = 0; index < _lines.length; index++) {
      final line = _lines[index];
      if (_isSerialManagedItem(line.itemId)) {
        final receivedQty =
            double.tryParse(line.receivedQtyController.text.trim()) ?? 0;
        final acceptedQty =
            double.tryParse(line.acceptedQtyController.text.trim()) ?? 0;
        if (receivedQty != 1 || acceptedQty != 1) {
          setState(
            () => _formError =
                'Serial-managed receipt lines must have received qty 1 and accepted qty 1 at line ${index + 1}.',
          );
          return;
        }
      }
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
      'purchase_order_id': _purchaseOrderId,
      'receipt_no': nullIfEmpty(_receiptNoController.text),
      'receipt_date': _receiptDateController.text.trim(),
      'supplier_party_id': _supplierPartyId,
      'warehouse_id': _warehouseId,
      'supplier_invoice_no': nullIfEmpty(_supplierInvoiceNoController.text),
      'supplier_invoice_date': nullIfEmpty(_supplierInvoiceDateController.text),
      'supplier_dc_no': nullIfEmpty(_supplierDcNoController.text),
      'supplier_dc_date': nullIfEmpty(_supplierDcDateController.text),
      'notes': nullIfEmpty(_notesController.text),
      'is_active': _isActive,
      'lines': _lines.map((line) => line.toJson()).toList(growable: false),
    };
    try {
      final response = _selectedItem == null
          ? await _purchaseService.createReceipt(PurchaseReceiptModel(payload))
          : await _purchaseService.updateReceipt(
              intValue(_selectedItem!.toJson(), 'id')!,
              PurchaseReceiptModel(payload),
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
    Future<ApiResponse<PurchaseReceiptModel>> Function() action,
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
      title: 'Purchase Receipts',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading purchase receipts...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load purchase receipts',
        message: _pageError!,
        onRetry: _loadPage,
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Purchase Receipts',
      editorTitle: _selectedItem == null
          ? 'New Purchase Receipt'
          : stringValue(
              _selectedItem!.toJson(),
              'receipt_no',
              'Purchase Receipt',
            ),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: PurchaseListCard<PurchaseReceiptModel>(
        items: _filteredItems,
        selectedItem: _selectedItem,
        emptyMessage: 'No purchase receipts found.',
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
                  onChanged: (value) async {
                    await _handlePurchaseOrderChanged(value);
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
                  initialValue: _warehouseId,
                  onChanged: (value) => setState(() => _warehouseId = value),
                  validator: Validators.requiredSelection('Warehouse'),
                ),
                AppFormTextField(
                  labelText: 'Supplier Invoice No',
                  controller: _supplierInvoiceNoController,
                ),
                AppFormTextField(
                  labelText: 'Supplier Invoice Date',
                  controller: _supplierInvoiceDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDate('Supplier Invoice Date'),
                ),
                AppFormTextField(
                  labelText: 'Supplier DC No',
                  controller: _supplierDcNoController,
                ),
                AppFormTextField(
                  labelText: 'Supplier DC Date',
                  controller: _supplierDcDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDate('Supplier DC Date'),
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
                        onChanged: (value) {
                          setState(() {
                            line.itemId = value;
                            line.uomId = _resolveDefaultUom(value, line.uomId);
                            line.serialId = null;
                          });
                          unawaited(_syncSerialOptionsForLine(line));
                        },
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
                            line.serialId = null;
                          });
                          unawaited(_syncSerialOptionsForLine(line));
                        },
                        validator: Validators.requiredSelection('Warehouse'),
                      ),
                      if (_isSerialManagedItem(line.itemId))
                        Builder(
                          builder: (context) {
                            final serialOptions = _serialOptionsForLine(line);
                            return AppDropdownField<int>.fromMapped(
                              labelText: 'Serial Number',
                              mappedItems: serialOptions
                                  .where(
                                    (serial) =>
                                        intValue(serial.toJson(), 'id') != null,
                                  )
                                  .map(
                                    (serial) => AppDropdownItem<int>(
                                      value: intValue(serial.toJson(), 'id')!,
                                      label: stringValue(
                                        serial.toJson(),
                                        'serial_no',
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                              initialValue: line.serialId,
                              onChanged: (value) =>
                                  setState(() => line.serialId = value),
                              validator: (_) {
                                if (line.warehouseId == null) {
                                  return 'Select warehouse first';
                                }
                                if (serialOptions.isEmpty) {
                                  return 'No serial is available for the selected warehouse';
                                }
                                return line.serialId == null
                                    ? 'Serial number is required'
                                    : null;
                              },
                            );
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
                      AppFormTextField(
                        labelText: 'Received Qty',
                        controller: line.receivedQtyController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.compose([
                          Validators.required('Received Qty'),
                          Validators.optionalNonNegativeNumber('Received Qty'),
                        ]),
                      ),
                      AppFormTextField(
                        labelText: 'Accepted Qty',
                        controller: line.acceptedQtyController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.optionalNonNegativeNumber(
                          'Accepted Qty',
                        ),
                      ),
                      AppFormTextField(
                        labelText: 'Rejected Qty',
                        controller: line.rejectedQtyController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.optionalNonNegativeNumber(
                          'Rejected Qty',
                        ),
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
                      () => _purchaseService.postReceipt(
                        intValue(_selectedItem!.toJson(), 'id')!,
                        PurchaseReceiptModel(const <String, dynamic>{}),
                      ),
                    ),
                  ),
                  AppActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Cancel',
                    filled: false,
                    onPressed: () => _docAction(
                      () => _purchaseService.cancelReceipt(
                        intValue(_selectedItem!.toJson(), 'id')!,
                        PurchaseReceiptModel(const <String, dynamic>{}),
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

class _PurchaseReceiptLineDraft {
  _PurchaseReceiptLineDraft({
    this.purchaseOrderLineId,
    this.itemId,
    this.warehouseId,
    this.uomId,
    this.serialId,
    String? description,
    String? receivedQty,
    String? acceptedQty,
    String? rejectedQty,
    String? rate,
    String? remarks,
  }) : descriptionController = TextEditingController(text: description ?? ''),
       receivedQtyController = TextEditingController(text: receivedQty ?? ''),
       acceptedQtyController = TextEditingController(text: acceptedQty ?? ''),
       rejectedQtyController = TextEditingController(text: rejectedQty ?? ''),
       rateController = TextEditingController(text: rate ?? ''),
       remarksController = TextEditingController(text: remarks ?? '');

  factory _PurchaseReceiptLineDraft.fromJson(Map<String, dynamic> json) {
    return _PurchaseReceiptLineDraft(
      purchaseOrderLineId: intValue(json, 'purchase_order_line_id'),
      itemId: intValue(json, 'item_id'),
      warehouseId: intValue(json, 'warehouse_id'),
      uomId: intValue(json, 'uom_id'),
      serialId: intValue(json, 'serial_id'),
      description: stringValue(json, 'description'),
      receivedQty: stringValue(json, 'received_qty'),
      acceptedQty: stringValue(json, 'accepted_qty'),
      rejectedQty: stringValue(json, 'rejected_qty'),
      rate: stringValue(json, 'rate'),
      remarks: stringValue(json, 'remarks'),
    );
  }

  int? purchaseOrderLineId;
  int? itemId;
  int? warehouseId;
  int? uomId;
  int? serialId;
  final TextEditingController descriptionController;
  final TextEditingController receivedQtyController;
  final TextEditingController acceptedQtyController;
  final TextEditingController rejectedQtyController;
  final TextEditingController rateController;
  final TextEditingController remarksController;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'purchase_order_line_id': purchaseOrderLineId,
      'item_id': itemId,
      'warehouse_id': warehouseId,
      'uom_id': uomId,
      'serial_id': serialId,
      'description': nullIfEmpty(descriptionController.text),
      'received_qty': double.tryParse(receivedQtyController.text.trim()) ?? 0,
      'accepted_qty': double.tryParse(acceptedQtyController.text.trim()) ?? 0,
      'rejected_qty': double.tryParse(rejectedQtyController.text.trim()) ?? 0,
      'rate': double.tryParse(rateController.text.trim()) ?? 0,
      'remarks': nullIfEmpty(remarksController.text),
    };
  }
}
