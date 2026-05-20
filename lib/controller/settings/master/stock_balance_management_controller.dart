import '../../../screen.dart';

class StockBalanceManagementController extends GetxController {
  StockBalanceManagementController();

  final InventoryService _inventoryService = InventoryService();
  final ScrollController pageScrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();

  bool initialLoading = true;
  String? pageError;
  List<StockBalanceModel> items = const <StockBalanceModel>[];
  List<StockBalanceModel> filteredItems = const <StockBalanceModel>[];
  StockBalanceModel? selectedItem;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    loadData();
  }

  @override
  void onClose() {
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
