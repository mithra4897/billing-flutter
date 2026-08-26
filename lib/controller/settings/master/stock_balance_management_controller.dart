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
  PaginationMeta? paginationMeta;
  Timer? _searchDebounce;
  String categoryFilter = '';
  String dateFromFilter = '';
  String dateToFilter = '';

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_scheduleListReload);
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
      ..removeListener(_scheduleListReload)
      ..dispose();
    _searchDebounce?.cancel();
    workspaceController.dispose();
    super.onClose();
  }

  Future<void> loadData({int? selectId, int page = 1}) async {
    initialLoading = items.isEmpty;
    pageError = null;
    update();

    try {
      final response = await _inventoryService.stockBalances(
        filters: {
          'page': page,
          'per_page': 50,
          'sort_by': 'qty_available',
          'sort_order': 'desc',
          if (searchController.text.trim().isNotEmpty)
            'search': searchController.text.trim(),
          if (categoryFilter.isNotEmpty) 'categories': categoryFilter,
          if (dateFromFilter.isNotEmpty) 'last_movement_from': dateFromFilter,
          if (dateToFilter.isNotEmpty) 'last_movement_to': dateToFilter,
        },
      );
      final nextItems = response.data ?? const <StockBalanceModel>[];

      items = nextItems;
      filteredItems = nextItems;
      paginationMeta = response.meta;
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

  void _scheduleListReload() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 450),
      () => unawaited(loadData(page: 1)),
    );
  }

  void setListFilters({
    required String category,
    required String dateFrom,
    required String dateTo,
  }) {
    categoryFilter = category;
    dateFromFilter = dateFrom;
    dateToFilter = dateTo;
    unawaited(loadData(page: 1));
  }

  void goToPage(int page) {
    if (page >= 1 && page != paginationMeta?.currentPage) {
      unawaited(loadData(page: page));
    }
  }

  void selectItem(StockBalanceModel item) {
    selectedItem = item;
    update();
  }
}
