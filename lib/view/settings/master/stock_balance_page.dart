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

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'StockBalanceManagementController',
    );
    Get.put(StockBalanceManagementController(), tag: _controllerTag);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StockBalanceManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(context, controller);

        if (widget.embedded) {
          return ShellPageActions(actions: const <Widget>[], child: content);
        }

        return AppStandaloneShell(
          title: 'Stock Balances',
          scrollController: controller.pageScrollController,
          actions: const <Widget>[],
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
        items: controller.filteredItems,
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
      editor: AppSectionCard(
        child: controller.selectedItem == null
            ? const SettingsEmptyState(
                icon: Icons.pie_chart_outline,
                title: 'Select Stock Balance',
                message: 'Choose a stock balance row from the left to inspect.',
              )
            : Column(
                key: ValueKey<int?>(controller.selectedItem!.id),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.selectedItem.toString(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
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
                            controller.selectedItem!.qtyOnHand?.toString() ??
                            '0',
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
                            controller.selectedItem!.lastSalesRate
                                ?.toString() ??
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
      ),
    );
  }
}
