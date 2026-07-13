import '../../model/inventory/inventory_inquiry_model.dart';
import '../../screen.dart';

class InventoryInquiryManagementController extends GetxController {
  InventoryInquiryManagementController();

  static const List<AppDropdownItem<String>> inquiryModes =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'summary', label: 'Stock summary'),
        AppDropdownItem(value: 'warehouse', label: 'Warehouse-wise'),
        AppDropdownItem(value: 'batch', label: 'Batch-wise'),
        AppDropdownItem(value: 'serials', label: 'Available serials'),
        AppDropdownItem(value: 'card', label: 'Stock card'),
        AppDropdownItem(value: 'reorder', label: 'Reorder status'),
      ];

  final InventoryService inventoryService = InventoryService();
  final ScrollController pageScrollController = ScrollController();

  bool loadingLookups = true;
  bool running = false;
  String? error;

  List<CompanyModel> companies = const <CompanyModel>[];
  List<ItemModel> items = const <ItemModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];

  int? companyId;
  int? itemId;
  int? warehouseId;
  String mode = 'summary';

  InventoryInquirySummaryModel? summaryResult;
  List<InventoryInquiryWarehouseRowModel> warehouseRows =
      const <InventoryInquiryWarehouseRowModel>[];
  List<InventoryInquiryBatchRowModel> batchRows =
      const <InventoryInquiryBatchRowModel>[];
  List<InventoryInquirySerialRowModel> serialRows =
      const <InventoryInquirySerialRowModel>[];
  InventoryInquiryStockCardModel? stockCardResult;
  InventoryInquiryReorderStatusModel? reorderResult;

  @override
  void onInit() {
    super.onInit();
    bootstrap();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    super.onClose();
  }

  Future<void> bootstrap() async {
    loadingLookups = true;
    error = null;
    update();
    try {
      await MasterDataCache.to.ensureLoaded();
      final cache = MasterDataCache.to;
      final activeCompanies = cache.activeCompanies;
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );

      companies = activeCompanies;
      items = cache.activeItems;
      warehouses = cache.activeWarehouses;
      companyId = contextSelection.companyId;
      loadingLookups = false;
    } catch (errorValue) {
      loadingLookups = false;
      error = errorValue.toString();
    }
    update();
  }

  Future<void> run() async {
    final selectedItemId = itemId;
    if (selectedItemId == null) {
      error = 'Item is required.';
      update();
      return;
    }

    running = true;
    error = null;
    _clearResults();
    update();

    try {
      final ApiResponse<dynamic> response = switch (mode) {
        'summary' => await inventoryService.inquiryItemStockSummary(
          itemId: selectedItemId,
          companyId: companyId,
        ),
        'warehouse' => await inventoryService.inquiryWarehouseWiseStock(
          itemId: selectedItemId,
          companyId: companyId,
        ),
        'batch' => await inventoryService.inquiryBatchWiseStock(
          itemId: selectedItemId,
          companyId: companyId,
          warehouseId: warehouseId,
        ),
        'serials' => await inventoryService.inquiryAvailableSerials(
          itemId: selectedItemId,
          warehouseId: warehouseId,
        ),
        'card' => await inventoryService.inquiryStockCard(
          itemId: selectedItemId,
          companyId: companyId,
        ),
        _ => await inventoryService.inquiryReorderStatus(
          itemId: selectedItemId,
          companyId: companyId,
        ),
      };

      if (response.success != true) {
        running = false;
        error = response.message;
        update();
        return;
      }

      _applyResult(response.data);
      running = false;
    } catch (errorValue) {
      running = false;
      error = errorValue.toString();
    }
    update();
  }

  void setMode(String? value) {
    mode = value ?? 'summary';
    if (mode != 'batch' && mode != 'serials') {
      warehouseId = null;
    }
    _clearResults();
    update();
  }

  void setCompanyId(int? value) {
    companyId = value;
    _clearResults();
    update();
  }

  void setItemId(int? value) {
    itemId = value;
    _clearResults();
    update();
  }

  void setWarehouseId(int? value) {
    warehouseId = value;
    _clearResults();
    update();
  }

  ItemModel? get selectedItem => items.cast<ItemModel?>().firstWhere(
    (item) => item?.id == itemId,
    orElse: () => null,
  );

  CompanyModel? get selectedCompany => companies
      .cast<CompanyModel?>()
      .firstWhere((company) => company?.id == companyId, orElse: () => null);

  void _clearResults() {
    summaryResult = null;
    warehouseRows = const <InventoryInquiryWarehouseRowModel>[];
    batchRows = const <InventoryInquiryBatchRowModel>[];
    serialRows = const <InventoryInquirySerialRowModel>[];
    stockCardResult = null;
    reorderResult = null;
  }

  void _applyResult(dynamic value) {
    switch (mode) {
      case 'summary':
        summaryResult = InventoryInquirySummaryModel.fromJson(
          JsonModel.mapOf(value) ?? const <String, dynamic>{},
        );
        break;
      case 'warehouse':
        warehouseRows = JsonModel.mapListOf(value)
            .map(InventoryInquiryWarehouseRowModel.fromJson)
            .toList(growable: false);
        break;
      case 'batch':
        batchRows = JsonModel.mapListOf(
          value,
        ).map(InventoryInquiryBatchRowModel.fromJson).toList(growable: false);
        break;
      case 'serials':
        serialRows = JsonModel.mapListOf(
          value,
        ).map(InventoryInquirySerialRowModel.fromJson).toList(growable: false);
        break;
      case 'card':
        stockCardResult = InventoryInquiryStockCardModel.fromJson(
          JsonModel.mapOf(value) ?? const <String, dynamic>{},
        );
        break;
      case 'reorder':
        reorderResult = InventoryInquiryReorderStatusModel.fromJson(
          JsonModel.mapOf(value) ?? const <String, dynamic>{},
        );
        break;
    }
  }
}
