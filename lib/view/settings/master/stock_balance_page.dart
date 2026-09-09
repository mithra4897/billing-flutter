import '../../../controller/settings/master/stock_balance_management_controller.dart';
import '../../../screen.dart';

class StockBalancePage extends StatefulWidget {
  const StockBalancePage({
    super.key,
    this.embedded = false,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final Map<String, String> queryParameters;

  @override
  State<StockBalancePage> createState() => _StockBalancePageState();
}

class _StockBalancePageState extends State<StockBalancePage> {
  late String _controllerTag;
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  String _statusFilter = '';
  String _categoryFilter = '';

  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All status'),
      ];

  Future<void> _openFilterPanel(
    BuildContext context,
    StockBalanceManagementController controller,
  ) {
    return openInventorySearchStatusCategoryFilterPanel(
      context: context,
      title: 'Filter Stock Balances',
      searchController: controller.searchController,
      dateFromController: _dateFromController,
      dateToController: _dateToController,
      searchHint: 'Item, warehouse, batch, or serial',
      status: _statusFilter,
      statusItems: _statusItems,
      category: _categoryFilter,
      categoryItems: _buildCategoryItems(controller),
      onApply: (search, status, dateFrom, dateTo, category) {
        setState(() {
          controller.searchController.text = search;
          _dateFromController.text = dateFrom;
          _dateToController.text = dateTo;
          _statusFilter = status;
          _categoryFilter = category;
        });
        controller.setListFilters(
          category: category,
          dateFrom: dateFrom,
          dateTo: dateTo,
        );
      },
      onClear: () {
        setState(() {
          controller.searchController.clear();
          _dateFromController.clear();
          _dateToController.clear();
          _statusFilter = '';
          _categoryFilter = '';
        });
        controller.setListFilters(category: '', dateFrom: '', dateTo: '');
      },
    );
  }

  List<AppDropdownItem<String>> _buildCategoryItems(
    StockBalanceManagementController controller,
  ) {
    final seen = <String>{};
    final values = controller.filteredItems
        .map((item) => (item.categoryName ?? item.categoryCode ?? '').trim())
        .where((value) => value.isNotEmpty && seen.add(value))
        .toList(growable: false);
    return <AppDropdownItem<String>>[
      const AppDropdownItem<String>(value: '', label: 'All categories'),
      ...values.map(
        (value) => AppDropdownItem<String>(value: value, label: value),
      ),
    ];
  }

  List<StockBalanceModel> _visibleItems(
    StockBalanceManagementController controller,
  ) {
    return controller.filteredItems;
  }

  void _applyDashboardFilter() {
    if (!mounted ||
        !Get.isRegistered<StockBalanceManagementController>(
          tag: _controllerTag,
        )) {
      return;
    }
    final controller = Get.find<StockBalanceManagementController>(
      tag: _controllerTag,
    );
    controller.setDashboardFilter(
      lowStock: widget.queryParameters['dashboard_filter'] == 'low_stock',
      itemId: int.tryParse(widget.queryParameters['item_id'] ?? ''),
      warehouseId: int.tryParse(widget.queryParameters['warehouse_id'] ?? ''),
    );
  }

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('StockBalanceManagementController');
    bool isNew = false;
    if (!Get.isRegistered<StockBalanceManagementController>(tag: _controllerTag)) {
      Get.put(
        StockBalanceManagementController(
          lowStockFilter:
              widget.queryParameters['dashboard_filter'] == 'low_stock',
          itemIdFilter: int.tryParse(widget.queryParameters['item_id'] ?? ''),
          warehouseIdFilter: int.tryParse(
            widget.queryParameters['warehouse_id'] ?? '',
          ),
        ),
        tag: _controllerTag,
      );
      isNew = true;
    }
    if (!isNew) {
      _applyDashboardFilter();
    }
  }

  @override
  void didUpdateWidget(covariant StockBalancePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(oldWidget.queryParameters, widget.queryParameters)) {
      _applyDashboardFilter();
    }
  }

  @override
  void dispose() {
    _dateFromController.dispose();
    _dateToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StockBalanceManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(context, controller);
        final actions = <Widget>[
          if (controller.lowStockFilter)
            AdaptiveShellActionButton(
              onPressed: () => controller.setLowStockFilter(false),
              icon: Icons.filter_alt_outlined,
              label: 'Low stock',
              filled: true,
            ),
          AdaptiveShellActionButton(
            onPressed: () => _openFilterPanel(context, controller),
            icon: Icons.filter_alt_outlined,
            label: 'Filter',
            filled: false,
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'Stock Balances',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    StockBalanceManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading stock balances...');
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load stock balances',
        message: controller.pageError!,
        onRetry: controller.loadData,
      );
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Stock Balances',
      editorTitle: controller.selectedItem?.toString(),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<StockBalanceModel>(
        searchController: controller.searchController,
        searchHint: 'Search stock balances',
        items: _visibleItems(controller),
        selectedItem: controller.selectedItem,
        emptyMessage: 'No stock balance records found.',
        paginationMeta: controller.paginationMeta,
        onPageChanged: controller.goToPage,
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.itemName.isNotEmpty ? item.itemName : item.itemCode,
          subtitle: [
            item.warehouseName ?? item.warehouseCode ?? '',
            'Available ${item.qtyAvailable ?? 0}',
          ].where((value) => value.trim().isNotEmpty).join(' · '),
          selected: selected,
          onTap: () => controller.selectItem(item),
        ),
      ),
      editor: controller.selectedItem == null
          ? const SettingsEmptyState(
              icon: Icons.pie_chart_outline,
              title: 'Select Stock Balance',
              message: 'Choose a stock balance row from the left to inspect.',
            )
          : Column(
              key: ValueKey<int?>(controller.selectedItem!.id),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsFormWrap(
                  children: [
                    AppFormTextField(
                      labelText: 'Item Code',
                      initialValue: controller.selectedItem!.itemCode,
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'Warehouse',
                      initialValue:
                          controller.selectedItem!.warehouseName ??
                          controller.selectedItem!.warehouseCode,
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'Batch',
                      initialValue: controller.selectedItem!.batchNo ?? '',
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'Serial',
                      initialValue: controller.selectedItem!.serialNo ?? '',
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'Qty On Hand',
                      initialValue:
                          controller.selectedItem!.qtyOnHand?.toString() ?? '0',
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'Qty Reserved',
                      initialValue:
                          controller.selectedItem!.qtyReserved?.toString() ??
                          '0',
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'Qty Available',
                      initialValue:
                          controller.selectedItem!.qtyAvailable?.toString() ??
                          '0',
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'Average Cost',
                      initialValue:
                          controller.selectedItem!.avgCost?.toString() ?? '',
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'Last Purchase Rate',
                      initialValue:
                          controller.selectedItem!.lastPurchaseRate
                              ?.toString() ??
                          '',
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'Last Sales Rate',
                      initialValue:
                          controller.selectedItem!.lastSalesRate?.toString() ??
                          '',
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'Last Movement At',
                      initialValue:
                          controller.selectedItem!.lastMovementAt ?? '',
                      readOnly: true,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
