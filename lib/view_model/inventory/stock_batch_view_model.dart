import 'package:billing/screen.dart';
import 'package:billing/view/purchase/purchase_support.dart';

class StockBatchViewModel extends ChangeNotifier {
  StockBatchViewModel({this.initialItemId}) {
    searchController.addListener(notifyListeners);
  }

  final int? initialItemId;
  final InventoryService _inventoryService = InventoryService();
  final MasterService _masterService = MasterService();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController batchNoController = TextEditingController();
  final TextEditingController mfgDateController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController inwardQtyController = TextEditingController();
  final TextEditingController outwardQtyController = TextEditingController();
  final TextEditingController balanceQtyController = TextEditingController();
  final TextEditingController purchaseRateController = TextEditingController();
  final TextEditingController salesRateController = TextEditingController();
  final TextEditingController mrpController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  List<StockBatchModel> rows = const <StockBatchModel>[];
  List<ItemModel> items = const <ItemModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];
  StockBatchModel? selected;
  StockBatchModel? selectedDetail;
  int? itemId;
  int? warehouseId;
  bool isActive = true;

  List<ItemModel> get itemOptions =>
      items.where((item) => item.hasBatch).toList(growable: false);

  ItemModel? get selectedItem {
    return itemOptions.cast<ItemModel?>().firstWhere(
      (item) => item?.id == itemId,
      orElse: () => null,
    );
  }

  List<WarehouseModel> get warehouseOptions {
    final itemCompanyId = selectedItem?.companyId;
    return warehouses.where((warehouse) {
      if (warehouse.id == null) {
        return false;
      }
      if (itemCompanyId != null && warehouse.companyId != itemCompanyId) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  List<StockBatchModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows.where((row) {
      final data = row.toJson();
      if (q.isEmpty) return true;
      return [
        stringValue(data, 'batch_no'),
        stringValue(data, 'item_code'),
        stringValue(data, 'item_name'),
      ].join(' ').toLowerCase().contains(q);
    }).toList(growable: false);
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    notifyListeners();
    try {
      final responses = await Future.wait<dynamic>([
        _inventoryService.stockBatches(filters: const {'per_page': 200, 'sort_by': 'batch_no'}),
        _inventoryService.items(filters: const {'per_page': 500, 'sort_by': 'item_name'}),
        _masterService.warehouses(filters: const {'per_page': 300}),
      ]);
      rows = (responses[0] as PaginatedResponse<StockBatchModel>).data ?? const <StockBatchModel>[];
      items = ((responses[1] as PaginatedResponse<ItemModel>).data ?? const <ItemModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      warehouses = ((responses[2] as PaginatedResponse<WarehouseModel>).data ?? const <WarehouseModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      loading = false;
      if (selectId != null) {
        final existing = rows.cast<StockBatchModel?>().firstWhere(
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
    batchNoController.clear();
    mfgDateController.clear();
    expiryDateController.clear();
    inwardQtyController.text = '0';
    outwardQtyController.text = '0';
    balanceQtyController.text = '0';
    purchaseRateController.clear();
    salesRateController.clear();
    mrpController.clear();
    remarksController.clear();
    itemId = (initialItemId != null &&
            itemOptions.any((item) => item.id == initialItemId))
        ? initialItemId
        : (itemOptions.isNotEmpty ? itemOptions.first.id : null);
    warehouseId = warehouseOptions.isNotEmpty ? warehouseOptions.first.id : null;
    isActive = true;
    notifyListeners();
  }

  Future<void> select(StockBatchModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) return;
    selected = row;
    detailLoading = true;
    formError = null;
    notifyListeners();
    try {
      final response = await _inventoryService.stockBatch(id);
      final data = (response.data ?? row).toJson();
      selectedDetail = response.data ?? row;
      itemId = intValue(data, 'item_id');
      warehouseId = intValue(data, 'warehouse_id');
      batchNoController.text = stringValue(data, 'batch_no');
      mfgDateController.text = displayDate(nullableStringValue(data, 'mfg_date'));
      expiryDateController.text = displayDate(nullableStringValue(data, 'expiry_date'));
      inwardQtyController.text = stringValue(data, 'inward_qty', '0');
      outwardQtyController.text = stringValue(data, 'outward_qty', '0');
      balanceQtyController.text = stringValue(data, 'balance_qty', '0');
      purchaseRateController.text = stringValue(data, 'purchase_rate');
      salesRateController.text = stringValue(data, 'sales_rate');
      mrpController.text = stringValue(data, 'mrp');
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
    if (!warehouseOptions.any((warehouse) => warehouse.id == warehouseId)) {
      warehouseId = warehouseOptions.isNotEmpty ? warehouseOptions.first.id : null;
    }
    notifyListeners();
  }

  void onWarehouseChanged(int? value) {
    warehouseId = value;
    notifyListeners();
  }

  String? _validate() {
    if (itemId == null || warehouseId == null) {
      return 'Item and warehouse are required.';
    }
    if (batchNoController.text.trim().isEmpty) {
      return 'Batch no is required.';
    }
    final inward = double.tryParse(inwardQtyController.text.trim()) ?? 0;
    final outward = double.tryParse(outwardQtyController.text.trim()) ?? 0;
    final balance = double.tryParse(balanceQtyController.text.trim()) ?? 0;
    final purchaseRate = double.tryParse(purchaseRateController.text.trim());
    final salesRate = double.tryParse(salesRateController.text.trim());
    final mrp = double.tryParse(mrpController.text.trim());
    if (inward < 0 || outward < 0 || balance < 0) {
      return 'Quantities cannot be negative.';
    }
    if (outward > inward) {
      return 'Outward quantity cannot be greater than inward quantity.';
    }
    if (purchaseRate != null && purchaseRate < 0) return 'Purchase rate cannot be negative.';
    if (salesRate != null && salesRate < 0) return 'Sales rate cannot be negative.';
    if (mrp != null && mrp < 0) return 'MRP cannot be negative.';
    if (salesRate != null && mrp != null && salesRate > mrp) {
      return 'Sales rate cannot be greater than MRP.';
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
      'batch_no': batchNoController.text.trim(),
      'mfg_date': nullIfEmpty(mfgDateController.text),
      'expiry_date': nullIfEmpty(expiryDateController.text),
      'inward_qty': double.tryParse(inwardQtyController.text.trim()) ?? 0,
      'outward_qty': double.tryParse(outwardQtyController.text.trim()) ?? 0,
      'balance_qty': double.tryParse(balanceQtyController.text.trim()) ?? 0,
      'purchase_rate': nullIfEmpty(purchaseRateController.text) == null
          ? null
          : double.tryParse(purchaseRateController.text.trim()),
      'sales_rate': nullIfEmpty(salesRateController.text) == null
          ? null
          : double.tryParse(salesRateController.text.trim()),
      'mrp': nullIfEmpty(mrpController.text) == null
          ? null
          : double.tryParse(mrpController.text.trim()),
      'is_active': isActive,
      'remarks': nullIfEmpty(remarksController.text),
    };
    try {
      final response = selected == null
          ? await _inventoryService.createStockBatch(StockBatchModel(payload))
          : await _inventoryService.updateStockBatch(
              intValue(selected!.toJson(), 'id')!,
              StockBatchModel(payload),
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
      await _inventoryService.deleteStockBatch(id);
      await load();
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    batchNoController.dispose();
    mfgDateController.dispose();
    expiryDateController.dispose();
    inwardQtyController.dispose();
    outwardQtyController.dispose();
    balanceQtyController.dispose();
    purchaseRateController.dispose();
    salesRateController.dispose();
    mrpController.dispose();
    remarksController.dispose();
    super.dispose();
  }
}
