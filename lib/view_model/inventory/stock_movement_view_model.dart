import 'package:billing/screen.dart';
import 'package:billing/view/purchase/purchase_support.dart';

const List<AppDropdownItem<String>> stockMovementTypeItems =
    <AppDropdownItem<String>>[
  AppDropdownItem<String>(value: 'opening', label: 'Opening'),
  AppDropdownItem<String>(value: 'purchase', label: 'Purchase'),
  AppDropdownItem<String>(value: 'purchase_return', label: 'Purchase return'),
  AppDropdownItem<String>(value: 'sales', label: 'Sales'),
  AppDropdownItem<String>(value: 'sales_return', label: 'Sales return'),
  AppDropdownItem<String>(value: 'transfer_in', label: 'Transfer in'),
  AppDropdownItem<String>(value: 'transfer_out', label: 'Transfer out'),
  AppDropdownItem<String>(value: 'adjustment_in', label: 'Adjustment in'),
  AppDropdownItem<String>(value: 'adjustment_out', label: 'Adjustment out'),
  AppDropdownItem<String>(value: 'production_in', label: 'Production in'),
  AppDropdownItem<String>(value: 'production_out', label: 'Production out'),
  AppDropdownItem<String>(value: 'jobwork_in', label: 'Jobwork in'),
  AppDropdownItem<String>(value: 'jobwork_out', label: 'Jobwork out'),
];

const List<AppDropdownItem<String>> stockEffectItems = <AppDropdownItem<String>>[
  AppDropdownItem<String>(value: 'in', label: 'In'),
  AppDropdownItem<String>(value: 'out', label: 'Out'),
  AppDropdownItem<String>(value: 'none', label: 'None'),
];

class StockMovementViewModel extends ChangeNotifier {
  StockMovementViewModel({this.initialItemId}) {
    searchController.addListener(notifyListeners);
  }

  final int? initialItemId;
  final InventoryService _inventoryService = InventoryService();
  final MasterService _masterService = MasterService();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController referenceTypeController = TextEditingController();
  final TextEditingController referenceIdController = TextEditingController();
  final TextEditingController referenceNoController = TextEditingController();
  final TextEditingController voucherDateController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  List<StockMovementModel> rows = const <StockMovementModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<ItemModel> items = const <ItemModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];
  List<StockBatchModel> batches = const <StockBatchModel>[];
  List<StockSerialModel> serials = const <StockSerialModel>[];
  StockMovementModel? selected;
  StockMovementModel? selectedDetail;
  int? companyId;
  int? itemId;
  int? warehouseId;
  int? batchId;
  int? serialId;
  int? sourceWarehouseId;
  int? destinationWarehouseId;
  String movementType = 'opening';
  String stockEffect = 'in';

  bool get isTransferType => movementType == 'transfer_in' || movementType == 'transfer_out';

  List<ItemModel> get itemOptions => items.where((i) {
        if (i.id == null) return false;
        if (companyId != null && i.companyId != companyId) return false;
        return i.isActive;
      }).toList(growable: false);

  List<WarehouseModel> get warehouseOptions => warehouses.where((w) {
        if (w.id == null) return false;
        if (companyId != null && w.companyId != companyId) return false;
        return w.isActive;
      }).toList(growable: false);

  List<StockMovementModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows.where((row) {
      final data = row.toJson();
      if (q.isEmpty) return true;
      return [
        stringValue(data, 'movement_type'),
        stringValue(data, 'reference_no'),
        stringValue(data, 'reference_module'),
      ].join(' ').toLowerCase().contains(q);
    }).toList(growable: false);
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    notifyListeners();
    try {
      final responses = await Future.wait<dynamic>([
        _inventoryService.stockMovements(filters: const {'per_page': 200, 'sort_by': 'movement_date'}),
        _masterService.companies(filters: const {'per_page': 200}),
        _inventoryService.items(filters: const {'per_page': 500, 'sort_by': 'item_name'}),
        _masterService.warehouses(filters: const {'per_page': 300}),
        _inventoryService.stockBatches(filters: const {'per_page': 500}),
        _inventoryService.stockSerials(filters: const {'per_page': 500}),
      ]);
      rows = (responses[0] as PaginatedResponse<StockMovementModel>).data ?? const <StockMovementModel>[];
      companies = ((responses[1] as PaginatedResponse<CompanyModel>).data ?? const <CompanyModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      items = (responses[2] as PaginatedResponse<ItemModel>).data ?? const <ItemModel>[];
      warehouses = (responses[3] as PaginatedResponse<WarehouseModel>).data ?? const <WarehouseModel>[];
      batches = (responses[4] as PaginatedResponse<StockBatchModel>).data ?? const <StockBatchModel>[];
      serials = (responses[5] as PaginatedResponse<StockSerialModel>).data ?? const <StockSerialModel>[];
      loading = false;
      if (selectId != null) {
        final existing = rows.cast<StockMovementModel?>().firstWhere(
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
    selectedDetail = null;
    formError = null;
    final now = DateTime.now().toIso8601String().split('T').first;
    companyId = companies.isNotEmpty ? companies.first.id : null;
    itemId = initialItemId;
    warehouseId = warehouseOptions.isNotEmpty ? warehouseOptions.first.id : null;
    batchId = null;
    serialId = null;
    sourceWarehouseId = null;
    destinationWarehouseId = null;
    movementType = 'opening';
    stockEffect = 'in';
    referenceTypeController.clear();
    referenceIdController.clear();
    referenceNoController.clear();
    voucherDateController.text = now;
    qtyController.clear();
    rateController.clear();
    amountController.clear();
    remarksController.clear();
    notifyListeners();
  }

  Future<void> select(StockMovementModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) return;
    selected = row;
    detailLoading = true;
    formError = null;
    notifyListeners();
    try {
      final response = await _inventoryService.stockMovement(id);
      final data = (response.data ?? row).toJson();
      selectedDetail = response.data ?? row;
      companyId = intValue(data, 'company_id');
      itemId = intValue(data, 'item_id');
      warehouseId = intValue(data, 'warehouse_id');
      batchId = intValue(data, 'batch_id');
      serialId = intValue(data, 'serial_id');
      sourceWarehouseId = intValue(data, 'source_warehouse_id');
      destinationWarehouseId = intValue(data, 'destination_warehouse_id');
      movementType = stringValue(data, 'movement_type', 'opening');
      stockEffect = stringValue(data, 'stock_effect', 'in');
      referenceTypeController.text = stringValue(data, 'reference_type');
      referenceIdController.text = stringValue(data, 'reference_id');
      referenceNoController.text = stringValue(data, 'reference_no');
      voucherDateController.text = displayDate(nullableStringValue(data, 'voucher_date'));
      qtyController.text = stringValue(data, 'qty');
      rateController.text = stringValue(data, 'rate');
      amountController.text = stringValue(data, 'amount');
      remarksController.text = stringValue(data, 'remarks');
      detailLoading = false;
      notifyListeners();
    } catch (e) {
      detailLoading = false;
      formError = e.toString();
      notifyListeners();
    }
  }

  void onCompanyChanged(int? value) {
    companyId = value;
    itemId = null;
    warehouseId = warehouseOptions.isNotEmpty ? warehouseOptions.first.id : null;
    batchId = null;
    serialId = null;
    sourceWarehouseId = null;
    destinationWarehouseId = null;
    notifyListeners();
  }

  void onItemChanged(int? value) {
    itemId = value;
    batchId = null;
    serialId = null;
    notifyListeners();
  }

  void onWarehouseChanged(int? value) {
    warehouseId = value;
    batchId = null;
    serialId = null;
    notifyListeners();
  }

  void onBatchChanged(int? value) {
    batchId = value;
    serialId = null;
    notifyListeners();
  }

  void onSerialChanged(int? value) {
    serialId = value;
    notifyListeners();
  }

  void onMovementTypeChanged(String? value) {
    movementType = value ?? 'opening';
    if (!isTransferType) {
      sourceWarehouseId = null;
      destinationWarehouseId = null;
    }
    notifyListeners();
  }

  void onStockEffectChanged(String? value) {
    stockEffect = value ?? 'in';
    notifyListeners();
  }

  void onSourceWarehouseChanged(int? value) {
    sourceWarehouseId = value;
    notifyListeners();
  }

  void onDestinationWarehouseChanged(int? value) {
    destinationWarehouseId = value;
    notifyListeners();
  }

  List<Map<String, dynamic>> batchOptions() {
    return batches
        .map((e) => e.toJson())
        .where((b) {
          final itemOk = itemId == null || intValue(b, 'item_id') == itemId;
          final whOk = warehouseId == null || intValue(b, 'warehouse_id') == warehouseId;
          return itemOk && whOk;
        })
        .toList(growable: false);
  }

  List<Map<String, dynamic>> serialOptions() {
    return serials
        .map((e) => e.toJson())
        .where((s) {
          final itemOk = itemId == null || intValue(s, 'item_id') == itemId;
          final whOk = warehouseId == null || intValue(s, 'warehouse_id') == warehouseId;
          final batchOk = batchId == null || intValue(s, 'batch_id') == batchId;
          return itemOk && whOk && batchOk;
        })
        .toList(growable: false);
  }

  String? _validate() {
    if (companyId == null || itemId == null || warehouseId == null) {
      return 'Company, item, and warehouse are required.';
    }
    if (!stockMovementTypeItems.any((e) => e.value == movementType)) {
      return 'Invalid movement type.';
    }
    if (!stockEffectItems.any((e) => e.value == stockEffect)) {
      return 'Invalid stock effect.';
    }
    final qty = double.tryParse(qtyController.text.trim()) ?? 0;
    if (qty <= 0) return 'Quantity must be greater than zero.';
    final rate = double.tryParse(rateController.text.trim()) ?? 0;
    if (rate < 0) return 'Rate cannot be negative.';
    final amountText = amountController.text.trim();
    if (amountText.isNotEmpty) {
      final amount = double.tryParse(amountText);
      if (amount == null) return 'Amount must be a valid number.';
      if (amount < 0) return 'Amount cannot be negative.';
    }
    if (voucherDateController.text.trim().isEmpty) return 'Voucher date is required.';
    if (isTransferType) {
      if (sourceWarehouseId == null || destinationWarehouseId == null) {
        return 'Source and destination warehouse are required for transfer movement.';
      }
      if (sourceWarehouseId == destinationWarehouseId) {
        return 'Source and destination warehouse cannot be same.';
      }
    }
    if (serialId != null && qty != 1) {
      return 'Quantity must be exactly 1 for serial-based movement.';
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
    notifyListeners();
    final payload = <String, dynamic>{
      'company_id': companyId,
      'item_id': itemId,
      'warehouse_id': warehouseId,
      'batch_id': batchId,
      'serial_id': serialId,
      'movement_type': movementType,
      'reference_type': nullIfEmpty(referenceTypeController.text),
      'reference_id': int.tryParse(referenceIdController.text.trim()),
      'reference_no': nullIfEmpty(referenceNoController.text),
      'voucher_date': voucherDateController.text.trim(),
      'qty': double.tryParse(qtyController.text.trim()) ?? 0,
      'rate': double.tryParse(rateController.text.trim()) ?? 0,
      'amount': nullIfEmpty(amountController.text) == null
          ? null
          : double.tryParse(amountController.text.trim()),
      'stock_effect': stockEffect,
      'source_warehouse_id': sourceWarehouseId,
      'destination_warehouse_id': destinationWarehouseId,
      'remarks': nullIfEmpty(remarksController.text),
    };
    try {
      final response = selected == null
          ? await _inventoryService.createStockMovement(StockMovementModel(payload))
          : await _inventoryService.updateStockMovement(
              intValue(selected!.toJson(), 'id')!,
              StockMovementModel(payload),
            );
      final id = intValue(response.data?.toJson() ?? const <String, dynamic>{}, 'id');
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> delete() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) return;
    try {
      await _inventoryService.deleteStockMovement(id);
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
    referenceNoController.dispose();
    voucherDateController.dispose();
    qtyController.dispose();
    rateController.dispose();
    amountController.dispose();
    remarksController.dispose();
    super.dispose();
  }
}
