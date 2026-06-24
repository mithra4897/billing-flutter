import '../../../view_model/inventory/inventory_module_refresh_controller.dart';
import '../../../screen.dart';

class StockBalanceManagementController extends GetxController {
  StockBalanceManagementController();

  final InventoryService _inventoryService = InventoryService();
  final InventoryModuleRefreshController _refreshController =
      InventoryModuleRefreshController.ensureRegistered();
  final ScrollController pageScrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  late final Worker _refreshWorker;

  bool initialLoading = true;
  String? pageError;
  List<StockBalanceModel> items = const <StockBalanceModel>[];
  List<StockBalanceModel> filteredItems = const <StockBalanceModel>[];
  StockBalanceModel? selectedItem;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    _refreshWorker = ever<InventoryModuleRefreshEvent?>(
      _refreshController.lastEvent,
      _handleInventoryRefresh,
    );
    loadData();
  }

  @override
  void onClose() {
    _refreshWorker.dispose();
    pageScrollController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    workspaceController.dispose();
    super.onClose();
  }

  Future<void> loadData({int? selectId}) async {
    initialLoading = items.isEmpty;
    pageError = null;
    update();

    try {
      final response = await _inventoryService.stockBalances(
        filters: const {'per_page': 300, 'sort_by': 'qty_available'},
      );
      final nextItems = response.data ?? const <StockBalanceModel>[];

      items = nextItems;
      filteredItems = filterItems(nextItems, searchController.text);
      initialLoading = false;

      final selected = selectId != null
          ? nextItems.cast<StockBalanceModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedItem == null
                ? (nextItems.isNotEmpty ? nextItems.first : null)
                : nextItems.cast<StockBalanceModel?>().firstWhere(
                    (item) => item?.id == selectedItem?.id,
                    orElse: () => nextItems.isNotEmpty ? nextItems.first : null,
                  ));

      selectedItem = selected;
    } catch (errorValue) {
      initialLoading = false;
      pageError = errorValue.toString();
    }

    update();
  }

  void _handleInventoryRefresh(InventoryModuleRefreshEvent? event) {
    if (event == null) {
      return;
    }

    loadData(selectId: selectedItem?.id);
  }

  List<StockBalanceModel> filterItems(
    List<StockBalanceModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (item) {
      return [
        item.itemCode,
        item.itemName,
        item.warehouseCode ?? '',
        item.warehouseName ?? '',
        item.batchNo ?? '',
        item.serialNo ?? '',
      ];
    });
  }

  void _applySearch() {
    filteredItems = filterItems(items, searchController.text);
    update();
  }

  void selectItem(StockBalanceModel item) {
    selectedItem = item;
    update();
  }
}
