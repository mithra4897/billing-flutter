import '../../../controller/settings/master/stock_balance_management_controller.dart';
import '../../../screen.dart';

class StockBalancePage extends StatefulWidget {
  const StockBalancePage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<StockBalancePage> createState() => _StockBalancePageState();
}

class _StockBalancePageState extends State<StockBalancePage> {
  late final String _controllerTag;
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
      },
      onClear: () {
        setState(() {
          controller.searchController.clear();
          _dateFromController.clear();
          _dateToController.clear();
          _statusFilter = '';
          _categoryFilter = '';
        });
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
    return controller.filteredItems
        .where((item) {
          final matchesCategory =
              _categoryFilter.isEmpty ||
              (item.categoryName ?? item.categoryCode ?? '').trim() ==
                  _categoryFilter;
          final matchesDate = matchesDateValueRange(
            item.lastMovementAt,
            fromValue: _dateFromController.text,
            toValue: _dateToController.text,
          );
          return matchesCategory && matchesDate;
        })
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'StockBalanceManagementController',
    );
    Get.put(StockBalanceManagementController(), tag: _controllerTag);
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
