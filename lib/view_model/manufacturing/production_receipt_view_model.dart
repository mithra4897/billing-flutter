import 'package:billing/screen.dart';
import 'package:billing/view/purchase/purchase_support.dart';

class ProductionReceiptLineDraft {
  ProductionReceiptLineDraft({
    this.itemId,
    this.uomId,
    this.warehouseId,
    String? receiptQty,
    String? acceptedQty,
    String? rejectedQty,
    String? unitCost,
    String? remarks,
  }) : receiptQtyController = TextEditingController(text: receiptQty ?? ''),
       acceptedQtyController = TextEditingController(text: acceptedQty ?? ''),
       rejectedQtyController = TextEditingController(text: rejectedQty ?? ''),
       unitCostController = TextEditingController(text: unitCost ?? ''),
       remarksController = TextEditingController(text: remarks ?? '');

  factory ProductionReceiptLineDraft.fromJson(Map<String, dynamic> json) {
    return ProductionReceiptLineDraft(
      itemId: intValue(json, 'item_id'),
      uomId: intValue(json, 'uom_id'),
      warehouseId: intValue(json, 'warehouse_id'),
      receiptQty: stringValue(json, 'receipt_qty'),
      acceptedQty: stringValue(json, 'accepted_qty'),
      rejectedQty: stringValue(json, 'rejected_qty'),
      unitCost: stringValue(json, 'unit_cost'),
      remarks: stringValue(json, 'remarks'),
    );
  }

  int? itemId;
  int? uomId;
  int? warehouseId;
  final TextEditingController receiptQtyController;
  final TextEditingController acceptedQtyController;
  final TextEditingController rejectedQtyController;
  final TextEditingController unitCostController;
  final TextEditingController remarksController;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'item_id': itemId,
    'uom_id': uomId,
    'warehouse_id': warehouseId,
    'receipt_qty': double.tryParse(receiptQtyController.text.trim()) ?? 0,
    'accepted_qty': double.tryParse(acceptedQtyController.text.trim()) ?? 0,
    'rejected_qty': double.tryParse(rejectedQtyController.text.trim()) ?? 0,
    'unit_cost': double.tryParse(unitCostController.text.trim()) ?? 0,
    'remarks': nullIfEmpty(remarksController.text),
  };

  void dispose() {
    receiptQtyController.dispose();
    acceptedQtyController.dispose();
    rejectedQtyController.dispose();
    unitCostController.dispose();
    remarksController.dispose();
  }
}

class ProductionReceiptViewModel extends ChangeNotifier {
  final ManufacturingService _service = ManufacturingService();
  final MasterService _masterService = MasterService();
  final InventoryService _inventoryService = InventoryService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController receiptNoController = TextEditingController();
  final TextEditingController receiptDateController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;

  List<ProductionReceiptModel> rows = const <ProductionReceiptModel>[];
  List<ProductionOrderModel> productionOrders = const <ProductionOrderModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<ItemModel> items = const <ItemModel>[];
  List<UomModel> uoms = const <UomModel>[];
  List<UomConversionModel> uomConversions = const <UomConversionModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];

  ProductionReceiptModel? selected;
  int? companyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? documentSeriesId;
  int? productionOrderId;
  int? warehouseId;
  bool isActive = true;
  List<ProductionReceiptLineDraft> lines = <ProductionReceiptLineDraft>[];

  ProductionReceiptViewModel() {
    searchController.addListener(notifyListeners);
  }

  bool get isDraft =>
      stringValue(selected?.toJson() ?? const {}, 'receipt_status', 'draft') ==
      'draft';

  List<ProductionReceiptModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows.where((row) {
      final data = row.toJson();
      if (q.isEmpty) return true;
      return [
        stringValue(data, 'receipt_no'),
        stringValue(data, 'receipt_status'),
      ].join(' ').toLowerCase().contains(q);
    }).toList(growable: false);
  }

  String? consumeActionMessage() {
    final message = actionMessage;
    actionMessage = null;
    return message;
  }

  void setProductionOrderId(int? value) {
    if (!isDraft && selected != null) return;
    productionOrderId = value;
    final order = productionOrders.cast<ProductionOrderModel?>().firstWhere(
      (row) => intValue(row?.toJson() ?? const <String, dynamic>{}, 'id') == value,
      orElse: () => null,
    );
    if (order != null) {
      final data = order.toJson();
      companyId = intValue(data, 'company_id');
      branchId = intValue(data, 'branch_id');
      locationId = intValue(data, 'location_id');
      financialYearId = intValue(data, 'financial_year_id');
      warehouseId = intValue(data, 'warehouse_id') ?? warehouseId;
    }
    notifyListeners();
  }

  void setLineWarehouseId(int index, int? value) {
    if ((!isDraft && selected != null) || index < 0 || index >= lines.length) {
      return;
    }
    lines[index].warehouseId = value;
    notifyListeners();
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    notifyListeners();
    try {
      final responses = await Future.wait<dynamic>([
        _service.productionReceipts(
          filters: const {'per_page': 200, 'sort_by': 'receipt_date'},
        ),
        _service.productionOrders(filters: const {'per_page': 200}),
        _masterService.documentSeries(filters: const {'per_page': 300}),
        _inventoryService.items(filters: const {'per_page': 500}),
        _inventoryService.uoms(filters: const {'per_page': 300}),
        _inventoryService.uomConversionsAll(
          filters: const {'per_page': 500, 'sort_by': 'from_uom_id'},
        ),
        _masterService.warehouses(filters: const {'per_page': 300}),
      ]);
      rows = (responses[0] as PaginatedResponse<ProductionReceiptModel>).data ??
          const <ProductionReceiptModel>[];
      productionOrders = (responses[1] as PaginatedResponse<ProductionOrderModel>).data ??
          const <ProductionOrderModel>[];
      documentSeries = ((responses[2] as PaginatedResponse<DocumentSeriesModel>).data ??
              const <DocumentSeriesModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      items = ((responses[3] as PaginatedResponse<ItemModel>).data ??
              const <ItemModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      uoms = ((responses[4] as PaginatedResponse<UomModel>).data ??
              const <UomModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      uomConversions = ((responses[5] as PaginatedResponse<UomConversionModel>).data ??
              const <UomConversionModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      warehouses = ((responses[6] as PaginatedResponse<WarehouseModel>).data ??
              const <WarehouseModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      loading = false;

      if (selectId != null) {
        final existing = rows.cast<ProductionReceiptModel?>().firstWhere(
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
    for (final line in lines) {
      line.dispose();
    }
    selected = null;
    formError = null;
    receiptNoController.clear();
    receiptDateController.text = DateTime.now().toIso8601String().split('T').first;
    remarksController.clear();
    productionOrderId = null;
    documentSeriesId = documentSeries
        .cast<DocumentSeriesModel?>()
        .firstWhere(
          (s) => s?.documentType == 'PRODUCTION_RECEIPT',
          orElse: () => null,
        )
        ?.id;
    warehouseId = warehouses.isNotEmpty ? warehouses.first.id : null;
    isActive = true;
    lines = <ProductionReceiptLineDraft>[ProductionReceiptLineDraft()];
    notifyListeners();
  }

  Future<void> select(ProductionReceiptModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) return;
    selected = row;
    detailLoading = true;
    notifyListeners();
    try {
      final response = await _service.productionReceipt(id);
      final data = (response.data ?? row).toJson();
      companyId = intValue(data, 'company_id');
      branchId = intValue(data, 'branch_id');
      locationId = intValue(data, 'location_id');
      financialYearId = intValue(data, 'financial_year_id');
      documentSeriesId = intValue(data, 'document_series_id');
      productionOrderId = intValue(data, 'production_order_id');
      warehouseId = intValue(data, 'warehouse_id');
      receiptNoController.text = stringValue(data, 'receipt_no');
      receiptDateController.text =
          displayDate(nullableStringValue(data, 'receipt_date'));
      remarksController.text = stringValue(data, 'remarks');
      isActive = boolValue(data, 'is_active', fallback: true);
      for (final line in lines) {
        line.dispose();
      }
      final rawLines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      lines = rawLines.isEmpty
          ? <ProductionReceiptLineDraft>[ProductionReceiptLineDraft()]
          : rawLines.map(ProductionReceiptLineDraft.fromJson).toList(growable: true);
    } catch (e) {
      formError = e.toString();
    } finally {
      detailLoading = false;
      notifyListeners();
    }
  }

  void addLine() {
    if (!isDraft && selected != null) return;
    lines = List<ProductionReceiptLineDraft>.from(lines)
      ..add(ProductionReceiptLineDraft(warehouseId: warehouseId));
    notifyListeners();
  }

  void removeLine(int index) {
    if ((!isDraft && selected != null) || index < 0 || index >= lines.length) {
      return;
    }
    final next = List<ProductionReceiptLineDraft>.from(lines);
    next.removeAt(index).dispose();
    lines = next.isEmpty
        ? <ProductionReceiptLineDraft>[ProductionReceiptLineDraft()]
        : next;
    notifyListeners();
  }

  void setLineItemId(int index, int? value) {
    if ((!isDraft && selected != null) || index < 0 || index >= lines.length) return;
    lines[index].itemId = value;
    final item = items.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == value,
      orElse: () => null,
    );
    lines[index].uomId = defaultUomIdForItem(
      item,
      uoms,
      uomConversions,
      current: lines[index].uomId,
    );
    notifyListeners();
  }

  void setLineUomId(int index, int? value) {
    if ((!isDraft && selected != null) || index < 0 || index >= lines.length) return;
    lines[index].uomId = value;
    notifyListeners();
  }

  List<UomModel> uomOptionsForItem(int? itemId) {
    if (itemId == null) return const <UomModel>[];
    final item = items.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == itemId,
      orElse: () => null,
    );
    return allowedUomsForItem(item, uoms, uomConversions);
  }

  String? _validate() {
    if (productionOrderId == null) {
      return 'Production order is required.';
    }
    if (lines.isEmpty) {
      return 'At least one line is required.';
    }
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.itemId == null || line.uomId == null || line.warehouseId == null) {
        return 'Line ${i + 1}: item, UOM and warehouse are required.';
      }
      if ((double.tryParse(line.receiptQtyController.text.trim()) ?? 0) <= 0) {
        return 'Line ${i + 1}: receipt qty must be > 0.';
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
    actionMessage = null;
    notifyListeners();
    final payload = <String, dynamic>{
      'company_id': companyId,
      'branch_id': branchId,
      'location_id': locationId,
      'financial_year_id': financialYearId,
      'document_series_id': documentSeriesId,
      'receipt_no': nullIfEmpty(receiptNoController.text),
      'receipt_date': receiptDateController.text.trim(),
      'production_order_id': productionOrderId,
      'warehouse_id': warehouseId,
      'remarks': nullIfEmpty(remarksController.text),
      'is_active': isActive ? 1 : 0,
      'lines': lines.map((line) => line.toJson()).toList(growable: false),
    };
    try {
      final response = selected == null
          ? await _service.createProductionReceipt(ProductionReceiptModel(payload))
          : await _service.updateProductionReceipt(
              intValue(selected!.toJson(), 'id')!,
              ProductionReceiptModel(payload),
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

  Future<void> post() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) return;
    try {
      final response = await _service.postProductionReceipt(
        id,
        const ProductionReceiptModel(<String, dynamic>{}),
      );
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> cancel() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) return;
    try {
      final response = await _service.cancelProductionReceipt(
        id,
        const ProductionReceiptModel(<String, dynamic>{}),
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
      await _service.deleteProductionReceipt(id);
      actionMessage = 'Production receipt deleted successfully.';
      await load();
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    receiptNoController.dispose();
    receiptDateController.dispose();
    remarksController.dispose();
    for (final line in lines) {
      line.dispose();
    }
    super.dispose();
  }
}
