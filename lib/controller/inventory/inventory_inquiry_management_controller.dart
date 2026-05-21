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
  final MasterService masterService = MasterService();
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
  String? resultText;

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
      final results = await Future.wait<dynamic>([
        masterService.companies(
          filters: const {'per_page': 200, 'sort_by': 'legal_name'},
        ),
        inventoryService.items(filters: const {'per_page': 500}),
        masterService.warehouses(filters: const {'per_page': 500}),
      ]);
      final nextCompanies =
          (results[0] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final nextItems =
          (results[1] as PaginatedResponse<ItemModel>).data ??
          const <ItemModel>[];
      final nextWarehouses =
          (results[2] as PaginatedResponse<WarehouseModel>).data ??
          const <WarehouseModel>[];

      final activeCompanies = nextCompanies
          .where((CompanyModel company) => company.isActive)
          .toList(growable: false);
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );

      companies = activeCompanies;
      items = nextItems
          .where((ItemModel item) => item.isActive)
          .toList(growable: false);
      warehouses = nextWarehouses
          .where((WarehouseModel warehouse) => warehouse.isActive)
          .toList(growable: false);
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
    resultText = null;
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

      final encoded = const JsonEncoder.withIndent(
        '  ',
      ).convert(toEncodable(response.data));
      resultText = encoded;
      running = false;
    } catch (errorValue) {
      running = false;
      error = errorValue.toString();
    }
    update();
  }

  dynamic toEncodable(dynamic value) {
    if (value is Map) {
      return value.map(
        (dynamic key, dynamic item) =>
            MapEntry<String, dynamic>(key.toString(), toEncodable(item)),
      );
    }
    if (value is List) {
      return value.map(toEncodable).toList();
    }
    return value;
  }

  void setMode(String? value) {
    mode = value ?? 'summary';
    update();
  }

  void setCompanyId(int? value) {
    companyId = value;
    update();
  }

  void setItemId(int? value) {
    itemId = value;
    update();
  }

  void setWarehouseId(int? value) {
    warehouseId = value;
    update();
  }
}
