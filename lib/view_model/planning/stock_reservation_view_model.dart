import 'package:billing/screen.dart';

class StockReservationViewModel extends ChangeNotifier {
  final PlanningService _service = PlanningService();
  final MasterService _masterService = MasterService();
  final InventoryService _inventoryService = InventoryService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController referenceTypeController = TextEditingController();
  final TextEditingController referenceIdController = TextEditingController();
  final TextEditingController referenceLineIdController = TextEditingController();
  final TextEditingController reservedQtyController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController releaseQtyController = TextEditingController();
  final TextEditingController releaseRemarksController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;

  List<StockReservationModel> rows = const <StockReservationModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<ItemModel> items = const <ItemModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];
  List<StockBatchModel> batches = const <StockBatchModel>[];
  List<StockSerialModel> serials = const <StockSerialModel>[];

  StockReservationModel? selected;
  int? companyId;
  int? itemId;
  int? warehouseId;
  int? batchId;
  int? serialId;
  String status = 'active';

  StockReservationViewModel() {
    searchController.addListener(notifyListeners);
  }

  bool get isLocked {
    final current = stringValue(
      selected?.toJson() ?? const <String, dynamic>{},
      'status',
      'active',
    );
    return current == 'released' || current == 'cancelled';
  }

  List<StockReservationModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows.where((row) {
      final data = row.toJson();
      if (q.isEmpty) return true;
      return [
        stringValue(data, 'reference_type'),
        '${intValue(data, 'reference_id') ?? ''}',
        stringValue(data, 'status'),
        _itemLabel(data),
      ].join(' ').toLowerCase().contains(q);
    }).toList(growable: false);
  }

  List<ItemModel> get itemOptions => items.where((x) {
    if (!x.isActive || x.id == null) return false;
    if (companyId != null && x.companyId != companyId) return false;
    return true;
  }).toList(growable: false);

  List<WarehouseModel> get warehouseOptions => warehouses.where((x) {
    if (!x.isActive || x.id == null) return false;
    if (companyId != null && x.companyId != companyId) return false;
    return true;
  }).toList(growable: false);

  List<StockBatchModel> get batchOptions => batches.where((x) {
    final data = x.toJson();
    if (intValue(data, 'id') == null) return false;
    if (itemId != null && intValue(data, 'item_id') != itemId) return false;
    if (warehouseId != null && intValue(data, 'warehouse_id') != warehouseId) {
      return false;
    }
    if (x.balanceQty <= 0) {
      return false;
    }
    return true;
  }).toList(growable: false);

  List<StockSerialModel> get serialOptions => serials.where((x) {
    final data = x.toJson();
    if (intValue(data, 'id') == null) return false;
    if (itemId != null && intValue(data, 'item_id') != itemId) return false;
    if (warehouseId != null && intValue(data, 'warehouse_id') != warehouseId) {
      return false;
    }
    if (batchId != null) {
      final serialBatchId = intValue(data, 'batch_id');
      if (serialBatchId != null && serialBatchId != batchId) return false;
    }
    return true;
  }).toList(growable: false);

  String? consumeActionMessage() {
    final message = actionMessage;
    actionMessage = null;
    return message;
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    notifyListeners();
    try {
      final responses = await Future.wait<dynamic>([
        _service.stockReservations(filters: const {'per_page': 200}),
        _masterService.companies(filters: const {'per_page': 200}),
        _inventoryService.items(filters: const {'per_page': 500}),
        _masterService.warehouses(filters: const {'per_page': 300}),
        _inventoryService.stockBatches(filters: const {'per_page': 500}),
        _inventoryService.stockSerials(filters: const {'per_page': 500}),
      ]);
      rows = (responses[0] as PaginatedResponse<StockReservationModel>).data ??
          const <StockReservationModel>[];
      companies = ((responses[1] as PaginatedResponse<CompanyModel>).data ??
              const <CompanyModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      items = ((responses[2] as PaginatedResponse<ItemModel>).data ??
              const <ItemModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      warehouses = ((responses[3] as PaginatedResponse<WarehouseModel>).data ??
              const <WarehouseModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      batches = (responses[4] as PaginatedResponse<StockBatchModel>).data ??
          const <StockBatchModel>[];
      serials = (responses[5] as PaginatedResponse<StockSerialModel>).data ??
          const <StockSerialModel>[];
      loading = false;

      if (selectId != null) {
        final existing = rows.cast<StockReservationModel?>().firstWhere(
          (x) => intValue(x?.toJson() ?? const <String, dynamic>{}, 'id') == selectId,
          orElse: () => null,
        );
        if (existing != null) {
          await select(existing);
          return;
        }
      }
      resetDraft();
      notifyListeners();
    } catch (e) {
      pageError = e.toString();
      loading = false;
      notifyListeners();
    }
  }

  void resetDraft() {
    selected = null;
    formError = null;
    companyId ??= companies.isNotEmpty ? companies.first.id : null;
    itemId = null;
    warehouseId = warehouseOptions.isNotEmpty ? warehouseOptions.first.id : null;
    batchId = null;
    serialId = null;
    referenceTypeController.clear();
    referenceIdController.clear();
    referenceLineIdController.clear();
    reservedQtyController.text = '1';
    remarksController.clear();
    releaseQtyController.clear();
    releaseRemarksController.clear();
    status = 'active';
    notifyListeners();
  }

  Future<void> select(StockReservationModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) return;
    selected = row;
    detailLoading = true;
    formError = null;
    notifyListeners();
    try {
      final response = await _service.stockReservation(id);
      final data = (response.data ?? row).toJson();
      companyId = intValue(data, 'company_id');
      itemId = intValue(data, 'item_id');
      warehouseId = intValue(data, 'warehouse_id');
      batchId = intValue(data, 'batch_id');
      serialId = intValue(data, 'serial_id');
      referenceTypeController.text = stringValue(data, 'reference_type');
      referenceIdController.text = stringValue(data, 'reference_id');
      referenceLineIdController.text = stringValue(data, 'reference_line_id');
      reservedQtyController.text = stringValue(data, 'reserved_qty', '0');
      remarksController.text = stringValue(data, 'remarks');
      releaseQtyController.text = '';
      releaseRemarksController.clear();
      status = stringValue(data, 'status', 'active');
    } catch (e) {
      formError = e.toString();
    } finally {
      detailLoading = false;
      notifyListeners();
    }
  }

  void onCompanyChanged(int? value) {
    if (isLocked) return;
    companyId = value;
    itemId = null;
    warehouseId = warehouseOptions.isNotEmpty ? warehouseOptions.first.id : null;
    batchId = null;
    serialId = null;
    notifyListeners();
  }

  void setItemId(int? value) {
    if (isLocked) return;
    itemId = value;
    batchId = null;
    serialId = null;
    notifyListeners();
  }

  void setWarehouseId(int? value) {
    if (isLocked) return;
    warehouseId = value;
    batchId = null;
    serialId = null;
    notifyListeners();
  }

  void setBatchId(int? value) {
    if (isLocked) return;
    batchId = value;
    final serialPresent = serialOptions.any((s) => intValue(s.toJson(), 'id') == serialId);
    if (!serialPresent) {
      serialId = null;
    }
    notifyListeners();
  }

  void setSerialId(int? value) {
    if (isLocked) return;
    serialId = value;
    notifyListeners();
  }

  String _itemLabel(Map<String, dynamic> data) {
    final item = data['item'];
    final map = item is Map<String, dynamic> ? item : const <String, dynamic>{};
    final code = stringValue(map, 'item_code');
    final name = stringValue(map, 'item_name');
    if (code.isEmpty) return name;
    if (name.isEmpty) return code;
    return '$code · $name';
  }

  String? _validate() {
    if (companyId == null) return 'Company is required.';
    if (itemId == null) return 'Item is required.';
    if (warehouseId == null) return 'Warehouse is required.';
    if (referenceTypeController.text.trim().isEmpty) {
      return 'Reference type is required.';
    }
    if ((int.tryParse(referenceIdController.text.trim()) ?? 0) <= 0) {
      return 'Reference id is required.';
    }
    if ((double.tryParse(reservedQtyController.text.trim()) ?? 0) <= 0) {
      return 'Reserved quantity must be greater than zero.';
    }
    return null;
  }

  Future<void> save() async {
    final validationError = _validate();
    if (validationError != null) {
      formError = validationError;
      notifyListeners();
      return;
    }
    saving = true;
    formError = null;
    actionMessage = null;
    notifyListeners();
    final payload = <String, dynamic>{
      'company_id': companyId,
      'item_id': itemId,
      'warehouse_id': warehouseId,
      'batch_id': batchId,
      'serial_id': serialId,
      'reference_type': referenceTypeController.text.trim(),
      'reference_id': int.tryParse(referenceIdController.text.trim()),
      'reference_line_id': nullIfEmpty(referenceLineIdController.text) == null
          ? null
          : int.tryParse(referenceLineIdController.text.trim()),
      'reserved_qty': double.tryParse(reservedQtyController.text.trim()) ?? 0,
      'status': status,
      'remarks': nullIfEmpty(remarksController.text),
    };
    try {
      final response = selected == null
          ? await _service.createStockReservation(StockReservationModel(payload))
          : await _service.updateStockReservation(
              intValue(selected!.toJson(), 'id')!,
              StockReservationModel(payload),
            );
      actionMessage = response.message;
      await load(
        selectId: intValue(response.data?.toJson() ?? const <String, dynamic>{}, 'id'),
      );
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> release() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) return;
    final qty = double.tryParse(releaseQtyController.text.trim()) ?? 0;
    if (qty <= 0) {
      formError = 'Released quantity must be greater than zero.';
      notifyListeners();
      return;
    }
    try {
      final response = await _service.releaseStockReservation(
        id,
        StockReservationModel(<String, dynamic>{
          'released_qty': qty,
          'remarks': nullIfEmpty(releaseRemarksController.text),
        }),
      );
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> delete() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) return;
    try {
      await _service.deleteStockReservation(id);
      actionMessage = 'Stock reservation deleted successfully.';
      await load();
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    referenceTypeController.dispose();
    referenceIdController.dispose();
    referenceLineIdController.dispose();
    reservedQtyController.dispose();
    remarksController.dispose();
    releaseQtyController.dispose();
    releaseRemarksController.dispose();
    super.dispose();
  }
}
