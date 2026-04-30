import 'package:billing/screen.dart';
import 'package:billing/view/purchase/purchase_support.dart';

const List<AppDropdownItem<String>> stockSerialStatusItems =
    <AppDropdownItem<String>>[
      AppDropdownItem<String>(value: 'available', label: 'Available'),
      AppDropdownItem<String>(value: 'sold', label: 'Sold'),
      AppDropdownItem<String>(value: 'issued', label: 'Issued'),
      AppDropdownItem<String>(value: 'returned', label: 'Returned'),
      AppDropdownItem<String>(value: 'damaged', label: 'Damaged'),
      AppDropdownItem<String>(value: 'blocked', label: 'Blocked'),
    ];

class StockSerialViewModel extends ChangeNotifier {
  StockSerialViewModel({this.initialItemId}) {
    searchController.addListener(notifyListeners);
  }

  final int? initialItemId;
  final InventoryService _inventoryService = InventoryService();
  final MasterService _masterService = MasterService();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController serialNoController = TextEditingController();
  final TextEditingController inwardDateController = TextEditingController();
  final TextEditingController outwardDateController = TextEditingController();
  final TextEditingController purchaseRateController = TextEditingController();
  final TextEditingController salesRateController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  bool batchLoading = false;
  String? pageError;
  String? formError;
  List<StockSerialModel> rows = const <StockSerialModel>[];
  List<ItemModel> items = const <ItemModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];
  List<StockBatchModel> batches = const <StockBatchModel>[];
  StockSerialModel? selected;
  StockSerialModel? selectedDetail;
  int? itemId;
  int? warehouseId;
  int? batchId;
  String status = 'available';
  bool isActive = true;

  List<StockSerialModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows
        .where((row) {
          final data = row.toJson();
          if (q.isEmpty) return true;
          return [
            stringValue(data, 'serial_no'),
            stringValue(data, 'status'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  ItemModel? get selectedItem {
    return items.cast<ItemModel?>().firstWhere(
      (item) => item?.id == itemId,
      orElse: () => null,
    );
  }

  List<ItemModel> get itemOptions =>
      items.where((item) => item.hasSerial).toList(growable: false);

  List<WarehouseModel> get warehouseOptions {
    final itemCompanyId = selectedItem?.companyId;
    return warehouses
        .where((warehouse) {
          if (warehouse.id == null) {
            return false;
          }
          if (itemCompanyId != null && warehouse.companyId != itemCompanyId) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  List<StockBatchModel> get batchOptions {
    // Keep batch picker always open to all batches so users can reselect
    // another batch even after item/warehouse are auto-filled from first pick.
    final serialItemIds = itemOptions
        .where((item) => item.id != null)
        .map((item) => item.id!)
        .toSet();
    return batches.where((batch) {
      final itemId = intValue(batch.toJson(), 'item_id');
      return itemId != null && serialItemIds.contains(itemId);
    }).toList(growable: false);
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    notifyListeners();
    try {
      final responses = await Future.wait<dynamic>([
        _inventoryService.stockSerials(
          filters: const {'per_page': 200, 'sort_by': 'serial_no'},
        ),
        _inventoryService.items(
          filters: const {'per_page': 500, 'sort_by': 'item_name'},
        ),
        _masterService.warehouses(filters: const {'per_page': 300}),
        _inventoryService.stockBatches(filters: const {'per_page': 500}),
      ]);
      rows =
          (responses[0] as PaginatedResponse<StockSerialModel>).data ??
          const <StockSerialModel>[];
      items =
          ((responses[1] as PaginatedResponse<ItemModel>).data ??
                  const <ItemModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      warehouses =
          ((responses[2] as PaginatedResponse<WarehouseModel>).data ??
                  const <WarehouseModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      batches =
          (responses[3] as PaginatedResponse<StockBatchModel>).data ??
          const <StockBatchModel>[];
      loading = false;
      if (selectId != null) {
        final existing = rows.cast<StockSerialModel?>().firstWhere(
          (x) =>
              intValue(x?.toJson() ?? const <String, dynamic>{}, 'id') ==
              selectId,
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
    serialNoController.clear();
    inwardDateController.clear();
    outwardDateController.clear();
    purchaseRateController.clear();
    salesRateController.clear();
    remarksController.clear();
    // Allow selecting batch first; item/warehouse will be derived from batch.
    itemId = null;
    warehouseId = null;
    batchId = null;
    status = 'available';
    isActive = true;
    notifyListeners();
  }

  Future<void> select(StockSerialModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) return;
    selected = row;
    detailLoading = true;
    formError = null;
    notifyListeners();
    try {
      final response = await _inventoryService.stockSerial(id);
      final data = (response.data ?? row).toJson();
      selectedDetail = response.data ?? row;
      itemId = intValue(data, 'item_id');
      warehouseId = intValue(data, 'warehouse_id');
      batchId = intValue(data, 'batch_id');
      serialNoController.text = stringValue(data, 'serial_no');
      status = stringValue(data, 'status', 'available');
      inwardDateController.text = displayDate(
        nullableStringValue(data, 'inward_date'),
      );
      outwardDateController.text = displayDate(
        nullableStringValue(data, 'outward_date'),
      );
      purchaseRateController.text = stringValue(data, 'purchase_rate');
      salesRateController.text = stringValue(data, 'sales_rate');
      remarksController.text = stringValue(data, 'remarks');
      isActive = boolValue(data, 'is_active');
      detailLoading = false;
      notifyListeners();
    } catch (e) {
      detailLoading = false;
      formError = e.toString();
      notifyListeners();
    }
  }

  void onItemChanged(int? value) {
    itemId = value;
    final validWarehouses = warehouseOptions;
    if (!validWarehouses.any((warehouse) => warehouse.id == warehouseId)) {
      warehouseId = validWarehouses.isNotEmpty
          ? validWarehouses.first.id
          : null;
    }
    batchId = null;
    notifyListeners();
  }

  void onWarehouseChanged(int? value) {
    warehouseId = value;
    batchId = null;
    notifyListeners();
  }

  void onBatchChanged(int? value) {
    batchId = value;
    final selectedBatch = batches.cast<StockBatchModel?>().firstWhere(
      (batch) =>
          intValue(batch?.toJson() ?? const <String, dynamic>{}, 'id') == value,
      orElse: () => null,
    );

    if (selectedBatch != null &&
        intValue(selectedBatch.toJson(), 'item_id') != null &&
        intValue(selectedBatch.toJson(), 'warehouse_id') != null) {
      final batchJson = selectedBatch.toJson();
      // Auto-fill parent fields from selected batch.
      itemId = intValue(batchJson, 'item_id');
      warehouseId = intValue(batchJson, 'warehouse_id');
      final purchaseRate = nullableStringValue(batchJson, 'purchase_rate');
      final salesRate = nullableStringValue(batchJson, 'sales_rate');
      if ((purchaseRateController.text.trim()).isEmpty && purchaseRate != null) {
        purchaseRateController.text = purchaseRate;
      }
      if ((salesRateController.text.trim()).isEmpty && salesRate != null) {
        salesRateController.text = salesRate;
      }
    }
    notifyListeners();
    _hydrateBatchFromBackend(value);
  }

  Future<void> _hydrateBatchFromBackend(int? id) async {
    if (id == null) {
      return;
    }
    batchLoading = true;
    notifyListeners();
    try {
      final response = await _inventoryService.stockBatch(id);
      final batch = response.data;
      if (batch == null || batchId != id) {
        return;
      }
      final batchJson = batch.toJson();
      itemId = intValue(batchJson, 'item_id');
      warehouseId = intValue(batchJson, 'warehouse_id');
      final purchaseRate = nullableStringValue(batchJson, 'purchase_rate');
      final salesRate = nullableStringValue(batchJson, 'sales_rate');
      if ((purchaseRateController.text.trim()).isEmpty && purchaseRate != null) {
        purchaseRateController.text = purchaseRate;
      }
      if ((salesRateController.text.trim()).isEmpty && salesRate != null) {
        salesRateController.text = salesRate;
      }
    } catch (_) {
      // Keep list-level autofill values if detail fetch fails.
    } finally {
      if (batchId == id) {
        batchLoading = false;
      }
      notifyListeners();
    }
  }

  void onStatusChanged(String? value) {
    status = value ?? 'available';
    notifyListeners();
  }

  String? _validate() {
    if (itemId == null || warehouseId == null) {
      return 'Item and warehouse are required.';
    }
    if (serialNoController.text.trim().isEmpty) return 'Serial no is required.';
    if (!stockSerialStatusItems.any((e) => e.value == status)) {
      return 'Invalid status.';
    }
    final purchaseRate = double.tryParse(purchaseRateController.text.trim());
    final salesRate = double.tryParse(salesRateController.text.trim());
    if (purchaseRate != null && purchaseRate < 0) {
      return 'Purchase rate cannot be negative.';
    }
    if (salesRate != null && salesRate < 0) {
      return 'Sales rate cannot be negative.';
    }
    final inward = inwardDateController.text.trim();
    final outward = outwardDateController.text.trim();
    if (inward.isNotEmpty && outward.isNotEmpty) {
      final inwardDate = DateTime.tryParse(inward);
      final outwardDate = DateTime.tryParse(outward);
      if (inwardDate != null &&
          outwardDate != null &&
          outwardDate.isBefore(inwardDate)) {
        return 'Outward date cannot be earlier than inward date.';
      }
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
      'item_id': itemId,
      'warehouse_id': warehouseId,
      'batch_id': batchId,
      'serial_no': serialNoController.text.trim(),
      'status': status,
      'inward_date': nullIfEmpty(inwardDateController.text),
      'outward_date': nullIfEmpty(outwardDateController.text),
      'purchase_rate': nullIfEmpty(purchaseRateController.text) == null
          ? null
          : double.tryParse(purchaseRateController.text.trim()),
      'sales_rate': nullIfEmpty(salesRateController.text) == null
          ? null
          : double.tryParse(salesRateController.text.trim()),
      'is_active': isActive,
      'remarks': nullIfEmpty(remarksController.text),
    };
    try {
      final response = selected == null
          ? await _inventoryService.createStockSerial(StockSerialModel(payload))
          : await _inventoryService.updateStockSerial(
              intValue(selected!.toJson(), 'id')!,
              StockSerialModel(payload),
            );
      final id = intValue(
        response.data?.toJson() ?? const <String, dynamic>{},
        'id',
      );
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
      await _inventoryService.deleteStockSerial(id);
      await load();
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    serialNoController.dispose();
    inwardDateController.dispose();
    outwardDateController.dispose();
    purchaseRateController.dispose();
    salesRateController.dispose();
    remarksController.dispose();
    super.dispose();
  }
}
