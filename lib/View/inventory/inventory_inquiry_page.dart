import 'dart:convert';

import '../../screen.dart';

class InventoryInquiryPage extends StatefulWidget {
  const InventoryInquiryPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<InventoryInquiryPage> createState() => _InventoryInquiryPageState();
}

class _InventoryInquiryPageState extends State<InventoryInquiryPage> {
  final InventoryService _inventoryService = InventoryService();
  final MasterService _masterService = MasterService();
  final ScrollController _scrollController = ScrollController();

  bool _loadingLookups = true;
  bool _running = false;
  String? _error;

  List<CompanyModel> _companies = const <CompanyModel>[];
  List<ItemModel> _items = const <ItemModel>[];
  List<WarehouseModel> _warehouses = const <WarehouseModel>[];

  int? _companyId;
  int? _itemId;
  int? _warehouseId;

  static const List<AppDropdownItem<String>> _inquiryModes =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'summary', label: 'Stock summary'),
        AppDropdownItem(value: 'warehouse', label: 'Warehouse-wise'),
        AppDropdownItem(value: 'batch', label: 'Batch-wise'),
        AppDropdownItem(value: 'serials', label: 'Available serials'),
        AppDropdownItem(value: 'card', label: 'Stock card'),
        AppDropdownItem(value: 'reorder', label: 'Reorder status'),
      ];

  String _mode = 'summary';
  String? _resultText;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loadingLookups = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _masterService.companies(
          filters: const {'per_page': 200, 'sort_by': 'legal_name'},
        ),
        _inventoryService.items(filters: const {'per_page': 500}),
        _masterService.warehouses(filters: const {'per_page': 500}),
      ]);
      final companies =
          (results[0] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final items =
          (results[1] as PaginatedResponse<ItemModel>).data ??
          const <ItemModel>[];
      final warehouses =
          (results[2] as PaginatedResponse<WarehouseModel>).data ??
          const <WarehouseModel>[];

      final activeCompanies = companies
          .where((CompanyModel c) => c.isActive)
          .toList(growable: false);
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );

      if (!mounted) {
        return;
      }
      setState(() {
        _companies = activeCompanies;
        _items = items.where((ItemModel i) => i.isActive).toList(growable: false);
        _warehouses = warehouses
            .where((WarehouseModel w) => w.isActive)
            .toList(growable: false);
        _companyId = contextSelection.companyId;
        _loadingLookups = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingLookups = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _run() async {
    final itemId = _itemId;
    if (itemId == null) {
      setState(() => _error = 'Item is required.');
      return;
    }

    setState(() {
      _running = true;
      _error = null;
      _resultText = null;
    });

    try {
      final ApiResponse<dynamic> response = switch (_mode) {
        'summary' => await _inventoryService.inquiryItemStockSummary(
            itemId: itemId,
            companyId: _companyId,
          ),
        'warehouse' => await _inventoryService.inquiryWarehouseWiseStock(
            itemId: itemId,
            companyId: _companyId,
          ),
        'batch' => await _inventoryService.inquiryBatchWiseStock(
            itemId: itemId,
            companyId: _companyId,
            warehouseId: _warehouseId,
          ),
        'serials' => await _inventoryService.inquiryAvailableSerials(
            itemId: itemId,
            warehouseId: _warehouseId,
          ),
        'card' => await _inventoryService.inquiryStockCard(
            itemId: itemId,
            companyId: _companyId,
          ),
        _ => await _inventoryService.inquiryReorderStatus(
            itemId: itemId,
            companyId: _companyId,
          ),
      };

      if (!mounted) {
        return;
      }

      if (response.success != true) {
        setState(() {
          _running = false;
          _error = response.message;
        });
        return;
      }

      final encoded = const JsonEncoder.withIndent(
        '  ',
      ).convert(_toEncodable(response.data));
      setState(() {
        _resultText = encoded;
        _running = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _running = false;
        _error = error.toString();
      });
    }
  }

  dynamic _toEncodable(dynamic value) {
    if (value is Map) {
      return value.map(
        (dynamic k, dynamic v) =>
            MapEntry<String, dynamic>(k.toString(), _toEncodable(v)),
      );
    }
    if (value is List) {
      return value.map(_toEncodable).toList();
    }
    return value;
  }

  List<Widget> _shellActions() {
    return [
      AdaptiveShellActionButton(
        onPressed: _running ? null : _run,
        icon: Icons.play_arrow_outlined,
        label: 'Run inquiry',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (widget.embedded) {
      return ShellPageActions(actions: _shellActions(), child: body);
    }
    return AppStandaloneShell(
      title: 'Inventory inquiry',
      scrollController: _scrollController,
      actions: _shellActions(),
      child: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loadingLookups) {
      return const AppLoadingView(message: 'Loading inquiry data...');
    }
    if (_error != null && _items.isEmpty) {
      return AppErrorStateView(
        title: 'Unable to load inquiry',
        message: _error!,
        onRetry: _bootstrap,
      );
    }

    final companyItems = _companies
        .map(
          (CompanyModel c) => AppDropdownItem<int?>(
            value: c.id,
            label: c.toString(),
          ),
        )
        .toList(growable: false);

    final itemItems = _items
        .where((ItemModel i) => i.id != null)
        .map(
          (ItemModel i) => AppDropdownItem<int>(
            value: i.id!,
            label: i.toString(),
          ),
        )
        .toList(growable: false);

    final warehouseItems = <AppDropdownItem<int?>>[
      const AppDropdownItem<int?>(value: null, label: 'All warehouses'),
      ..._warehouses.map(
        (WarehouseModel w) => AppDropdownItem<int?>(
          value: w.id,
          label: w.toString(),
        ),
      ),
    ];

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) ...[
            AppErrorStateView.inline(message: _error!),
            const SizedBox(height: AppUiConstants.spacingMd),
          ],
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parameters',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppUiConstants.spacingSm),
                Text(
                  'Inquiries are scoped to an item. Optional company and warehouse '
                  'filters apply to the APIs that support them.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppUiConstants.spacingMd),
                Wrap(
                  spacing: AppUiConstants.spacingMd,
                  runSpacing: AppUiConstants.spacingMd,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppDropdownField<String>.fromMapped(
                      labelText: 'Inquiry',
                      mappedItems: _inquiryModes,
                      initialValue: _mode,
                      width: 240,
                      onChanged: (value) =>
                          setState(() => _mode = value ?? 'summary'),
                    ),
                    AppDropdownField<int?>.fromMapped(
                      labelText: 'Company (optional)',
                      mappedItems: <AppDropdownItem<int?>>[
                        const AppDropdownItem<int?>(
                          value: null,
                          label: 'Any / default',
                        ),
                        ...companyItems,
                      ],
                      initialValue: _companyId,
                      width: 260,
                      onChanged: (value) => setState(() => _companyId = value),
                    ),
                    AppDropdownField<int>.fromMapped(
                      labelText: 'Item',
                      mappedItems: itemItems,
                      initialValue: _itemId,
                      width: 320,
                      onChanged: (value) => setState(() => _itemId = value),
                    ),
                    if (_mode == 'batch' ||
                        _mode == 'serials') ...[
                      AppDropdownField<int?>.fromMapped(
                        labelText: 'Warehouse',
                        mappedItems: warehouseItems,
                        initialValue: _warehouseId,
                        width: 240,
                        onChanged: (value) =>
                            setState(() => _warehouseId = value),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          AppSectionCard(
            child: _running
                ? const AppLoadingView(message: 'Running inquiry...')
                : _resultText == null
                ? const Text('Run an inquiry to see JSON results here.')
                : SelectableText(_resultText!),
          ),
        ],
      ),
    );
  }
}
