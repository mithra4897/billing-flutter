import '../../../screen.dart';

class StockBalancePage extends StatefulWidget {
  const StockBalancePage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<StockBalancePage> createState() => _StockBalancePageState();
}

class _StockBalancePageState extends State<StockBalancePage> {
  final InventoryService _inventoryService = InventoryService();
  final ScrollController _pageScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();

  bool _initialLoading = true;
  String? _pageError;
  List<StockBalanceModel> _items = const <StockBalanceModel>[];
  List<StockBalanceModel> _filteredItems = const <StockBalanceModel>[];
  StockBalanceModel? _selectedItem;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadData();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _searchController.dispose();
    _workspaceController.dispose();
    super.dispose();
  }

  Future<void> _loadData({int? selectId}) async {
    setState(() {
      _initialLoading = _items.isEmpty;
      _pageError = null;
    });

    try {
      final response = await _inventoryService.stockBalances(
        filters: const {'per_page': 300, 'sort_by': 'qty_available'},
      );
      final items = response.data ?? const <StockBalanceModel>[];
      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
        _filteredItems = _filterItems(items, _searchController.text);
        _initialLoading = false;
      });

      final selected = selectId != null
          ? items.cast<StockBalanceModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedItem == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<StockBalanceModel?>().firstWhere(
                    (item) => item?.id == _selectedItem?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      setState(() {
        _selectedItem = selected;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _initialLoading = false;
        _pageError = error.toString();
      });
    }
  }

  List<StockBalanceModel> _filterItems(
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
    setState(() {
      _filteredItems = _filterItems(_items, _searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();

    if (widget.embedded) {
      return ShellPageActions(actions: const <Widget>[], child: content);
    }

    return AppStandaloneShell(
      title: 'Stock Balances',
      scrollController: _pageScrollController,
      actions: const <Widget>[],
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading stock balances...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load stock balances',
        message: _pageError!,
        onRetry: _loadData,
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Stock Balances',
      editorTitle: _selectedItem?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<StockBalanceModel>(
        searchController: _searchController,
        searchHint: 'Search stock balances',
        items: _filteredItems,
        selectedItem: _selectedItem,
        emptyMessage: 'No stock balance records found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.itemName.isNotEmpty ? item.itemName : item.itemCode,
          subtitle: [
            item.warehouseName ?? item.warehouseCode ?? '',
            'Available ${item.qtyAvailable ?? 0}',
          ].where((value) => value.trim().isNotEmpty).join(' · '),
          selected: selected,
          onTap: () => setState(() => _selectedItem = item),
        ),
      ),
      editor: AppSectionCard(
        child: _selectedItem == null
            ? const SettingsEmptyState(
                icon: Icons.pie_chart_outline,
                title: 'Select Stock Balance',
                message: 'Choose a stock balance row from the left to inspect.',
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedItem.toString(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  SettingsFormWrap(
                    children: [
                      AppFormTextField(
                        labelText: 'Item Code',
                        initialValue: _selectedItem!.itemCode,
                        readOnly: true,
                      ),
                      AppFormTextField(
                        labelText: 'Warehouse',
                        initialValue:
                            _selectedItem!.warehouseName ??
                            _selectedItem!.warehouseCode,
                        readOnly: true,
                      ),
                      AppFormTextField(
                        labelText: 'Batch',
                        initialValue: _selectedItem!.batchNo ?? '',
                        readOnly: true,
                      ),
                      AppFormTextField(
                        labelText: 'Serial',
                        initialValue: _selectedItem!.serialNo ?? '',
                        readOnly: true,
                      ),
                      AppFormTextField(
                        labelText: 'Qty On Hand',
                        initialValue:
                            _selectedItem!.qtyOnHand?.toString() ?? '0',
                        readOnly: true,
                      ),
                      AppFormTextField(
                        labelText: 'Qty Reserved',
                        initialValue:
                            _selectedItem!.qtyReserved?.toString() ?? '0',
                        readOnly: true,
                      ),
                      AppFormTextField(
                        labelText: 'Qty Available',
                        initialValue:
                            _selectedItem!.qtyAvailable?.toString() ?? '0',
                        readOnly: true,
                      ),
                      AppFormTextField(
                        labelText: 'Average Cost',
                        initialValue: _selectedItem!.avgCost?.toString() ?? '',
                        readOnly: true,
                      ),
                      AppFormTextField(
                        labelText: 'Last Purchase Rate',
                        initialValue:
                            _selectedItem!.lastPurchaseRate?.toString() ?? '',
                        readOnly: true,
                      ),
                      AppFormTextField(
                        labelText: 'Last Sales Rate',
                        initialValue:
                            _selectedItem!.lastSalesRate?.toString() ?? '',
                        readOnly: true,
                      ),
                      AppFormTextField(
                        labelText: 'Last Movement At',
                        initialValue: _selectedItem!.lastMovementAt ?? '',
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
