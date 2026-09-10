import '../../screen.dart';
import '../../controller/settings/accounting/settings_accounting_module_refresh_controller.dart';

typedef AccountsRegisterLoader<T> =
    Future<PaginatedResponse<T>> Function(
      AccountsService service,
      Map<String, dynamic> filters,
    );
typedef AccountsRegisterMatcher<T> = bool Function(T row, String query);
typedef AccountsRegisterValueGetter<T> = String? Function(T row);
typedef AccountsRegisterValuesGetter<T> = List<String> Function(T row);
typedef AccountsRegisterDropdownLoader =
    Future<List<AppDropdownItem<String>>> Function(AccountsService service);
typedef AccountsRegisterFilterOptionsLoader =
    Future<AccountsRegisterFilterOptions> Function();
typedef AccountsRegisterFooterBuilder<T> =
    Widget? Function(
      BuildContext context,
      AccountsRegisterController<T> controller,
      int currentPage,
    );

class AccountsRegisterFilterOptions {
  const AccountsRegisterFilterOptions({
    this.accountGroupItems = const <AppDropdownItem<int>>[],
    this.voucherTypeItems = const <AppDropdownItem<int>>[],
    this.partyItems = const <AppDropdownItem<int>>[],
    this.secondaryPartyItems = const <AppDropdownItem<int>>[],
    this.statusItems = const <AppDropdownItem<String>>[],
    this.typeItems = const <AppDropdownItem<String>>[],
    this.categoryItems = const <AppDropdownItem<String>>[],
    this.suggestions = const <AppRegisterFilterSuggestion>[],
  });

  final List<AppDropdownItem<int>> accountGroupItems;
  final List<AppDropdownItem<int>> voucherTypeItems;
  final List<AppDropdownItem<int>> partyItems;
  final List<AppDropdownItem<int>> secondaryPartyItems;
  final List<AppDropdownItem<String>> statusItems;
  final List<AppDropdownItem<String>> typeItems;
  final List<AppDropdownItem<String>> categoryItems;
  final List<AppRegisterFilterSuggestion> suggestions;
}

List<AppDropdownItem<String>> _accountingStatusItems(List<String> values) =>
    values
        .map(
          (value) => AppDropdownItem<String>(
            value: value.toLowerCase(),
            label: value.replaceAll('_', ' ').titleCase,
          ),
        )
        .toList(growable: false);

void _openAccountsShellRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}

class AccountsRegisterController<T> extends GetxController {
  AccountsRegisterController({
    required this.loader,
    required this.matches,
    this.statusValue,
    this.statusFilterItems,
    this.dateValue,
    this.typeValues,
    this.typeFilterItems,
    this.categoryValues,
    this.categoryFilterItems,
    this.categoryItemsLoader,
    this.filterOptionsLoader,
    this.initialDashboardFilter,
    this.onDashboardFilter,
  });

  final String? initialDashboardFilter;
  final void Function(AccountsRegisterController<T> controller, String filter)?
  onDashboardFilter;

  final AccountsRegisterLoader<T> loader;
  final AccountsRegisterMatcher<T> matches;
  final AccountsRegisterValueGetter<T>? statusValue;
  final List<AppDropdownItem<String>>? statusFilterItems;
  final AccountsRegisterValueGetter<T>? dateValue;
  final AccountsRegisterValuesGetter<T>? typeValues;
  final List<AppDropdownItem<String>>? typeFilterItems;
  final AccountsRegisterValuesGetter<T>? categoryValues;
  final List<AppDropdownItem<String>>? categoryFilterItems;
  final AccountsRegisterDropdownLoader? categoryItemsLoader;
  final AccountsRegisterFilterOptionsLoader? filterOptionsLoader;

  final AccountsService _service = AccountsService();
  final SettingsAccountingModuleRefreshController _refreshController =
      SettingsAccountingModuleRefreshController.ensureRegistered();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController dateFromController = TextEditingController();
  final TextEditingController dateToController = TextEditingController();
  final TextEditingController asOfDateController = TextEditingController();

  bool loading = true;
  String? error;
  List<T> rows = <T>[];
  Set<String> statuses = <String>{};
  Set<String> types = <String>{};
  Set<String> categories = <String>{};
  Set<int> partyIds = <int>{};
  Set<int> secondaryPartyIds = <int>{};
  Set<int> itemIds = <int>{};
  String sort = '';

  AccountsRegisterFilterOptions filterOptions =
      const AccountsRegisterFilterOptions();
  List<AppDropdownItem<String>> loadedCategoryItems =
      const <AppDropdownItem<String>>[];
  Worker? _refreshWorker;
  PaginationMeta? pagination;
  Timer? _filterDebounce;
  int _loadSequence = 0;
  bool _categoryItemsRequested = false;
  bool _filterOptionsRequested = false;
  String dashboardFilter = '';

  List<T> get filteredRows => rows;

  List<AppDropdownItem<String>> get statusItems {
    if (statusFilterItems != null) {
      return statusFilterItems!;
    }
    if (statusValue == null) {
      return const <AppDropdownItem<String>>[];
    }
    final seen = <String>{};
    final items = <AppDropdownItem<String>>[
      const AppDropdownItem<String>(value: '', label: 'All'),
    ];
    for (final row in rows) {
      final value = (statusValue?.call(row) ?? '').trim();
      if (value.isEmpty) {
        continue;
      }
      final normalized = value.toLowerCase();
      if (!seen.add(normalized)) {
        continue;
      }
      items.add(
        AppDropdownItem<String>(
          value: normalized,
          label: value.replaceAll('_', ' ').titleCase,
        ),
      );
    }
    return items;
  }

  List<AppDropdownItem<String>> get typeItems {
    if (typeFilterItems != null) {
      return typeFilterItems!;
    }
    if (filterOptions.typeItems.isNotEmpty) {
      return filterOptions.typeItems;
    }
    if (typeValues == null) {
      return const <AppDropdownItem<String>>[];
    }
    final seen = <String>{};
    final items = <AppDropdownItem<String>>[
      const AppDropdownItem<String>(value: '', label: 'All'),
    ];
    for (final row in rows) {
      for (final raw in typeValues?.call(row) ?? const <String>[]) {
        final value = raw.trim();
        if (value.isEmpty) continue;
        final normalized = value.toLowerCase();
        if (!seen.add(normalized)) continue;
        items.add(
          AppDropdownItem<String>(
            value: normalized,
            label: value.replaceAll('_', ' ').titleCase,
          ),
        );
      }
    }
    return items;
  }

  List<AppDropdownItem<String>> get categoryItems {
    if (categoryFilterItems != null) {
      return categoryFilterItems!;
    }
    if (loadedCategoryItems.isNotEmpty) {
      return loadedCategoryItems;
    }
    if (filterOptions.categoryItems.isNotEmpty) {
      return filterOptions.categoryItems;
    }
    if (categoryValues == null) {
      return const <AppDropdownItem<String>>[];
    }
    final seen = <String>{};
    final items = <AppDropdownItem<String>>[
      const AppDropdownItem<String>(value: '', label: 'All'),
    ];
    for (final row in rows) {
      for (final raw in categoryValues?.call(row) ?? const <String>[]) {
        final value = raw.trim();
        if (value.isEmpty) continue;
        final normalized = value.toLowerCase();
        if (!seen.add(normalized)) continue;
        items.add(
          AppDropdownItem<String>(
            value: normalized,
            label: value.replaceAll('_', ' ').titleCase,
          ),
        );
      }
    }
    return items;
  }

  bool get supportsDateFilter => dateValue != null;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_scheduleReload);
    dateFromController.addListener(_scheduleReload);
    dateToController.addListener(_scheduleReload);
    asOfDateController.addListener(_scheduleReload);
    _refreshWorker = ever<SettingsAccountingModuleRefreshEvent?>(
      _refreshController.lastEvent,
      (event) {
        if (event == null) return;
        unawaited(load());
      },
    );
    unawaited(_loadCategoryItemsOnce());
    unawaited(_loadFilterOptionsOnce());
    if (initialDashboardFilter != null &&
        initialDashboardFilter!.isNotEmpty &&
        onDashboardFilter != null) {
      dashboardFilter = initialDashboardFilter!;
      onDashboardFilter!(this, initialDashboardFilter!);
      _filterDebounce?.cancel();
    }
    unawaited(load());
  }

  void applyDashboardFilter(String filter) {
    if (onDashboardFilter != null) {
      dashboardFilter = filter.trim();
      onDashboardFilter!(this, filter);
      _filterDebounce?.cancel();
      unawaited(load(page: 1));
    }
  }

  @override
  void onClose() {
    _refreshWorker?.dispose();
    _filterDebounce?.cancel();
    searchController
      ..removeListener(_scheduleReload)
      ..dispose();
    dateFromController
      ..removeListener(_scheduleReload)
      ..dispose();
    dateToController
      ..removeListener(_scheduleReload)
      ..dispose();
    asOfDateController
      ..removeListener(_scheduleReload)
      ..dispose();
    super.onClose();
  }

  void setStatuses(Set<String> values) {
    statuses = values
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();
    update();
    _scheduleReload();
  }

  void setTypes(Set<String> values) {
    types = values
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();
    update();
    _scheduleReload();
  }

  void setCategories(Set<String> values) {
    categories = values
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();
    update();
    _scheduleReload();
  }

  void setPartyIds(Set<int> values) {
    partyIds = Set<int>.from(values);
    update();
    _scheduleReload();
  }

  void setSecondaryPartyIds(Set<int> values) {
    secondaryPartyIds = Set<int>.from(values);
    update();
    _scheduleReload();
  }

  void setItemIds(Set<int> values) {
    itemIds = Set<int>.from(values);
    update();
    _scheduleReload();
  }

  void setSort(String? value) {
    sort = (value ?? '').trim();
    update();
    _scheduleReload();
  }

  void clearFilters() {
    searchController.clear();
    dateFromController.clear();
    dateToController.clear();
    asOfDateController.clear();
    statuses = <String>{};
    types = <String>{};
    categories = <String>{};
    partyIds = <int>{};
    secondaryPartyIds = <int>{};
    itemIds = <int>{};
    sort = '';
    update();
    unawaited(load(page: 1));
  }

  void _scheduleReload() {
    _filterDebounce?.cancel();
    _filterDebounce = Timer(
      const Duration(milliseconds: 450),
      () => unawaited(load(page: 1)),
    );
  }

  void goToPage(int page) {
    if (page >= 1 && page != pagination?.currentPage) {
      unawaited(load(page: page));
    }
  }

  Future<void> load({int page = 1}) async {
    _filterDebounce?.cancel();
    final loadSequence = ++_loadSequence;
    loading = true;
    error = null;
    update();
    try {
      final filters = <String, dynamic>{
        'page': page,
        'per_page': 50,
        'sort_order': 'desc',
        if (searchController.text.trim().isNotEmpty)
          'search': searchController.text.trim(),
        if (dateFromController.text.trim().isNotEmpty)
          'date_from': dateFromController.text.trim(),
        if (dateToController.text.trim().isNotEmpty)
          'date_to': dateToController.text.trim(),
        if (asOfDateController.text.trim().isNotEmpty)
          'as_of_date': asOfDateController.text.trim(),
        if (statuses.length == 1) 'status': statuses.single,
        if (statuses.length > 1) 'statuses': statuses.join(','),
        if (types.length == 1) 'type': types.single,
        if (types.length > 1) 'types': types.join(','),
        if (categories.isNotEmpty) 'categories': categories.join(','),
        if (partyIds.isNotEmpty) 'party_ids': partyIds.join(','),
        if (secondaryPartyIds.isNotEmpty)
          'secondary_party_ids': secondaryPartyIds.join(','),
        if (itemIds.isNotEmpty) 'item_ids': itemIds.join(','),
        if (sort.isNotEmpty) 'sort_by': sort,
        if (dashboardFilter.isNotEmpty) 'dashboard_filter': dashboardFilter,
      };
      final response = await loader(_service, filters);
      if (loadSequence != _loadSequence) return;
      rows = response.data ?? <T>[];
      pagination = response.meta;
      loading = false;
      update();
    } catch (err) {
      if (loadSequence != _loadSequence) return;
      error = err.toString();
      loading = false;
      update();
    }
  }

  Future<void> _loadCategoryItemsOnce() async {
    if (categoryItemsLoader == null || _categoryItemsRequested) return;
    _categoryItemsRequested = true;
    try {
      loadedCategoryItems = await categoryItemsLoader!(_service);
      update();
    } catch (_) {}
  }

  Future<void> _loadFilterOptionsOnce() async {
    if (_filterOptionsRequested) return;
    _filterOptionsRequested = true;
    try {
      if (filterOptionsLoader != null) {
        filterOptions = await filterOptionsLoader!();
        update();
      }
    } catch (_) {}
  }
}

class _AccountsRegisterShell<T> extends StatefulWidget {
  const _AccountsRegisterShell({
    required this.controllerName,
    required this.title,
    required this.embedded,
    required this.loader,
    required this.matches,
    required this.emptyMessage,
    required this.newRoute,
    required this.newLabel,
    required this.searchHint,
    required this.columns,
    required this.rowRoute,
    this.showNewAction = true,
    this.statusValue,
    this.statusFilterItems,
    this.dateValue,
    this.typeValues,
    this.typeFilterItems,
    this.typeLabel = 'Type',
    this.categoryValues,
    this.categoryFilterItems,
    this.categoryItemsLoader,
    this.categoryLabel = 'Category',
    this.partyLabel,
    this.secondaryPartyLabel,
    this.filterOptionsLoader,
    this.suggestions = const <AppRegisterFilterSuggestion>[],
    this.footerBuilder,
    this.queryParameters = const <String, String>{},
    this.onDashboardFilter,
  });

  final String controllerName;
  final String title;
  final bool embedded;
  final AccountsRegisterLoader<T> loader;
  final AccountsRegisterMatcher<T> matches;
  final String emptyMessage;
  final String newRoute;
  final String newLabel;
  final String searchHint;
  final List<PurchaseRegisterColumn<T>> columns;
  final String Function(T row) rowRoute;
  final bool showNewAction;
  final AccountsRegisterValueGetter<T>? statusValue;
  final List<AppDropdownItem<String>>? statusFilterItems;
  final AccountsRegisterValueGetter<T>? dateValue;
  final AccountsRegisterValuesGetter<T>? typeValues;
  final List<AppDropdownItem<String>>? typeFilterItems;
  final String typeLabel;
  final AccountsRegisterValuesGetter<T>? categoryValues;
  final List<AppDropdownItem<String>>? categoryFilterItems;
  final AccountsRegisterDropdownLoader? categoryItemsLoader;
  final String categoryLabel;
  final String? partyLabel;
  final String? secondaryPartyLabel;
  final AccountsRegisterFilterOptionsLoader? filterOptionsLoader;
  final List<AppRegisterFilterSuggestion> suggestions;
  final AccountsRegisterFooterBuilder<T>? footerBuilder;
  final Map<String, String> queryParameters;
  final void Function(
    AccountsRegisterController<T> controller,
    String dashboardFilter,
  )?
  onDashboardFilter;

  @override
  State<_AccountsRegisterShell<T>> createState() =>
      _AccountsRegisterShellState<T>();
}

class _AccountsRegisterShellState<T> extends State<_AccountsRegisterShell<T>> {
  late final String _controllerTag;
  bool _filtersVisible = false;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(widget.controllerName);
    bool isNew = false;
    if (!Get.isRegistered<AccountsRegisterController<T>>(tag: _controllerTag)) {
      Get.put(
        AccountsRegisterController<T>(
          loader: widget.loader,
          matches: widget.matches,
          statusValue: widget.statusValue,
          statusFilterItems: widget.statusFilterItems,
          dateValue: widget.dateValue,
          typeValues: widget.typeValues,
          typeFilterItems: widget.typeFilterItems,
          categoryValues: widget.categoryValues,
          categoryFilterItems: widget.categoryFilterItems,
          categoryItemsLoader: widget.categoryItemsLoader,
          filterOptionsLoader: widget.filterOptionsLoader,
          initialDashboardFilter:
              (widget.queryParameters['dashboard_filter'] ?? '').trim(),
          onDashboardFilter: widget.onDashboardFilter,
        ),
        tag: _controllerTag,
      );
      isNew = true;
    }
    if (!isNew) {
      _applyDashboardFilter();
    }
  }

  void _applyDashboardFilter() {
    if (!mounted ||
        !Get.isRegistered<AccountsRegisterController<T>>(tag: _controllerTag)) {
      return;
    }
    final dashboardFilter = (widget.queryParameters['dashboard_filter'] ?? '')
        .trim();
    final controller = Get.find<AccountsRegisterController<T>>(
      tag: _controllerTag,
    );
    controller.applyDashboardFilter(dashboardFilter);
  }

  @override
  void didUpdateWidget(covariant _AccountsRegisterShell<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(oldWidget.queryParameters, widget.queryParameters)) {
      _applyDashboardFilter();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AccountsRegisterController<T>>(
      tag: _controllerTag,
      builder: (controller) {
        return SharedRegisterList<T>(
          title: widget.title,
          embedded: widget.embedded,
          loading: controller.loading,
          errorMessage: controller.error,
          onRetry: controller.load,
          emptyMessage: widget.emptyMessage,
          actions: [
            AdaptiveShellSearchField(
              controller: controller.searchController,
              hintText: widget.searchHint,
            ),
            AdaptiveShellActionButton(
              onPressed: () {
                setState(() {
                  _filtersVisible = !_filtersVisible;
                });
              },
              icon: Icons.filter_alt_outlined,
              label: 'Filter',
              filled: _filtersVisible,
            ),
            if (widget.showNewAction)
              AdaptiveShellActionButton(
                onPressed: () =>
                    _openAccountsShellRoute(context, widget.newRoute),
                icon: Icons.add_outlined,
                label: widget.newLabel,
              ),
          ],
          filters: _filtersVisible
              ? SharedFilterBar(
                  dateFromController: controller.supportsDateFilter
                      ? controller.dateFromController
                      : null,
                  dateToController: controller.supportsDateFilter
                      ? controller.dateToController
                      : null,
                  showDateFilters: controller.supportsDateFilter,
                  statusItems: controller.statusItems,
                  selectedStatuses: controller.statuses,
                  onStatusesChanged: controller.setStatuses,
                  typeLabel: widget.typeLabel,
                  typeItems: controller.typeItems,
                  selectedTypes: controller.types,
                  onTypesChanged: controller.setTypes,
                  categoryLabel: widget.categoryLabel,
                  categoryItems: controller.categoryItems,
                  selectedCategories: controller.categories,
                  onCategoriesChanged: controller.setCategories,
                  partyLabel: widget.partyLabel,
                  partyItems: controller.filterOptions.partyItems,
                  selectedPartyIds: controller.partyIds,
                  onPartyChanged: controller.setPartyIds,
                  secondaryPartyLabel: widget.secondaryPartyLabel,
                  secondaryPartyItems:
                      controller.filterOptions.secondaryPartyItems,
                  selectedSecondaryPartyIds: controller.secondaryPartyIds,
                  onSecondaryPartyChanged: controller.setSecondaryPartyIds,
                  suggestions: const [],
                  onClear: controller.clearFilters,
                )
              : null,
          rows: controller.filteredRows,
          columns: widget.columns,
          onRowTap: (row) =>
              _openAccountsShellRoute(context, widget.rowRoute(row)),
          remoteTotalItems: controller.pagination?.total,
          remoteCurrentPage: controller.pagination?.currentPage,
          remotePerPage: controller.pagination?.perPage,
          onRemotePageChanged: controller.goToPage,
          footerBuilder: (context, currentPage) =>
              widget.footerBuilder?.call(context, controller, currentPage),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// 1. Voucher Register Screen
// -----------------------------------------------------------------------------
class VoucherRegisterPage extends StatelessWidget {
  const VoucherRegisterPage({
    super.key,
    this.embedded = false,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final Map<String, String> queryParameters;

  @override
  Widget build(BuildContext context) {
    return _AccountsRegisterShell<VoucherModel>(
      controllerName: 'VoucherRegisterController',
      title: 'Vouchers',
      embedded: embedded,
      queryParameters: queryParameters,
      newRoute: '/accounting/vouchers?view=manage&new=1',
      newLabel: 'New Voucher',
      searchHint: 'Search voucher no, narration, reference...',
      emptyMessage: 'No vouchers found.',
      dateValue: (row) => row.voucherDate,
      statusValue: (row) => row.postingStatus ?? 'draft',
      statusFilterItems: _accountingStatusItems(const [
        'draft',
        'posted',
        'cancelled',
      ]),
      typeLabel: 'Approval',
      typeFilterItems: _accountingStatusItems(const [
        'draft',
        'pending',
        'approved',
        'rejected',
      ]),
      suggestions: <AppRegisterFilterSuggestion>[
        AppRegisterFilterSuggestion(
          label: 'Posted',
          onSelected: () {
            final c = Get.find<AccountsRegisterController<VoucherModel>>(
              tag: persistentControllerTag('VoucherRegisterController'),
            );
            c.setStatuses({'posted'});
          },
        ),
        AppRegisterFilterSuggestion(
          label: 'Drafts',
          onSelected: () {
            final c = Get.find<AccountsRegisterController<VoucherModel>>(
              tag: persistentControllerTag('VoucherRegisterController'),
            );
            c.setStatuses({'draft'});
          },
        ),
        AppRegisterFilterSuggestion(
          label: 'Pending approval',
          onSelected: () {
            final c = Get.find<AccountsRegisterController<VoucherModel>>(
              tag: persistentControllerTag('VoucherRegisterController'),
            );
            c.setTypes({'pending'});
          },
        ),
      ],
      loader: (service, filters) => service.vouchers(
        filters:
            <String, dynamic>{
                ...filters,
                if (filters['date_from'] != null)
                  'voucher_date_from': filters['date_from'],
                if (filters['date_to'] != null)
                  'voucher_date_to': filters['date_to'],
                if (filters['status'] != null)
                  'posting_status': filters['status'],
                if (filters['type'] != null) 'approval_status': filters['type'],
              }
              ..remove('date_from')
              ..remove('date_to'),
      ),
      matches: (row, query) {
        final text =
            '${row.voucherNo} ${row.narration} ${row.referenceNo} ${row.voucherTypeName}'
                .toLowerCase();
        return text.contains(query);
      },
      columns: [
        PurchaseRegisterColumn<VoucherModel>(
          label: 'Voucher No',
          flex: 3,
          valueBuilder: (row) => row.voucherNo ?? '-',
        ),
        PurchaseRegisterColumn<VoucherModel>(
          label: 'Date',
          flex: 2,
          valueBuilder: (row) => displayDate(row.voucherDate),
        ),
        PurchaseRegisterColumn<VoucherModel>(
          label: 'Type',
          flex: 2,
          valueBuilder: (row) => row.voucherTypeName ?? '-',
        ),
        PurchaseRegisterColumn<VoucherModel>(
          label: 'Ref No / Narration',
          flex: 4,
          valueBuilder: (row) =>
              (row.referenceNo != null && row.referenceNo!.trim().isNotEmpty)
                  ? row.referenceNo!
                  : (row.narration != null && row.narration!.trim().isNotEmpty)
                      ? row.narration!
                      : '-',
        ),
        PurchaseRegisterColumn<VoucherModel>(
          label: 'Amount',
          flex: 2,
          alignRight: true,
          padding: const EdgeInsets.only(right: 8),
          valueBuilder: (row) => formatAmount(
            row.totalDebit > 0 ? row.totalDebit : row.totalCredit,
          ),
        ),
        PurchaseRegisterColumn<VoucherModel>(
          label: 'Posting',
          flex: 2,
          valueBuilder: (row) => row.postingStatus ?? 'draft',
          widgetBuilder: (context, row) => AppStatusBadge(
            label: (row.postingStatus ?? 'draft').titleCase,
            color: appStatusColor(row.postingStatus),
          ),
        ),
      ],
      rowRoute: (row) => '/accounting/vouchers?view=manage&id=${row.id}',
    );
  }
}

// -----------------------------------------------------------------------------
// 2. Account Register Screen (Chart of Accounts)
// -----------------------------------------------------------------------------
class AccountRegisterPage extends StatelessWidget {
  const AccountRegisterPage({
    super.key,
    this.embedded = false,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final Map<String, String> queryParameters;

  @override
  Widget build(BuildContext context) {
    return _AccountsRegisterShell<AccountModel>(
      controllerName: 'AccountRegisterController',
      title: 'Accounts',
      embedded: embedded,
      queryParameters: queryParameters,
      newRoute: '/accounting/accounts?view=manage&new=1',
      newLabel: 'New Account',
      searchHint: 'Search account code, name, group...',
      emptyMessage: 'No accounts found.',
      statusValue: (row) => row.isActive ? 'active' : 'inactive',
      statusFilterItems: _accountingStatusItems(const ['active', 'inactive']),
      typeLabel: 'Account Type',
      typeFilterItems: _accountingStatusItems(const [
        'asset',
        'liability',
        'equity',
        'income',
        'expense',
      ]),
      categoryLabel: 'Currency',
      categoryFilterItems: const [
        AppDropdownItem(value: '', label: 'All'),
        AppDropdownItem(value: 'INR', label: 'INR'),
        AppDropdownItem(value: 'USD', label: 'USD'),
        AppDropdownItem(value: 'EUR', label: 'EUR'),
      ],
      suggestions: <AppRegisterFilterSuggestion>[
        AppRegisterFilterSuggestion(
          label: 'Active only',
          onSelected: () {
            final c = Get.find<AccountsRegisterController<AccountModel>>(
              tag: persistentControllerTag('AccountRegisterController'),
            );
            c.setStatuses({'active'});
          },
        ),
        AppRegisterFilterSuggestion(
          label: 'Assets',
          onSelected: () {
            final c = Get.find<AccountsRegisterController<AccountModel>>(
              tag: persistentControllerTag('AccountRegisterController'),
            );
            c.setTypes({'asset'});
          },
        ),
        AppRegisterFilterSuggestion(
          label: 'Liabilities',
          onSelected: () {
            final c = Get.find<AccountsRegisterController<AccountModel>>(
              tag: persistentControllerTag('AccountRegisterController'),
            );
            c.setTypes({'liability'});
          },
        ),
        AppRegisterFilterSuggestion(
          label: 'Expenses',
          onSelected: () {
            final c = Get.find<AccountsRegisterController<AccountModel>>(
              tag: persistentControllerTag('AccountRegisterController'),
            );
            c.setTypes({'expense'});
          },
        ),
      ],
      loader: (service, filters) => service.accounts(
        filters: <String, dynamic>{
          ...filters,
          if (filters['status'] == 'active') 'is_active': 1,
          if (filters['status'] == 'inactive') 'is_active': 0,
          if (filters['type'] != null) 'account_type': filters['type'],
          if (filters['categories'] != null)
            'currency_code': filters['categories'],
        },
      ),
      matches: (row, query) {
        final text =
            '${row.accountCode} ${row.accountName} ${row.accountGroupName}'
                .toLowerCase();
        return text.contains(query);
      },
      columns: [
        PurchaseRegisterColumn<AccountModel>(
          label: 'Code',
          flex: 2,
          valueBuilder: (row) => row.accountCode ?? '-',
        ),
        PurchaseRegisterColumn<AccountModel>(
          label: 'Account Name',
          flex: 4,
          valueBuilder: (row) => row.accountName ?? '-',
        ),
        PurchaseRegisterColumn<AccountModel>(
          label: 'Group',
          flex: 3,
          valueBuilder: (row) => row.accountGroupName ?? '-',
        ),
        PurchaseRegisterColumn<AccountModel>(
          label: 'Type',
          flex: 2,
          valueBuilder: (row) => (row.accountType ?? '-').titleCase,
        ),
        PurchaseRegisterColumn<AccountModel>(
          label: 'Opening Balance',
          flex: 3,
          alignRight: true,
          padding: const EdgeInsets.only(right: 8),
          valueBuilder: (row) => formatAmount(row.openingBalance ?? 0),
        ),
        PurchaseRegisterColumn<AccountModel>(
          label: 'Status',
          flex: 2,
          valueBuilder: (row) => row.isActive ? 'Active' : 'Inactive',
          widgetBuilder: (context, row) => AppStatusBadge(
            label: row.isActive ? 'Active' : 'Inactive',
            color: row.isActive ? appStatusColorSuccess : appStatusColorDanger,
          ),
        ),
      ],
      rowRoute: (row) => '/accounting/accounts?view=manage&id=${row.id}',
    );
  }
}

// -----------------------------------------------------------------------------
// 3. Account Group Register Screen
// -----------------------------------------------------------------------------
class AccountGroupRegisterPage extends StatelessWidget {
  const AccountGroupRegisterPage({
    super.key,
    this.embedded = false,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final Map<String, String> queryParameters;

  @override
  Widget build(BuildContext context) {
    return _AccountsRegisterShell<AccountGroupModel>(
      controllerName: 'AccountGroupRegisterController',
      title: 'Account Groups',
      embedded: embedded,
      queryParameters: queryParameters,
      newRoute: '/accounting/account-groups?view=manage&new=1',
      newLabel: 'New Group',
      searchHint: 'Search group code, name...',
      emptyMessage: 'No account groups found.',
      statusValue: (row) => row.isActive ? 'active' : 'inactive',
      statusFilterItems: _accountingStatusItems(const ['active', 'inactive']),
      typeLabel: 'Nature',
      typeFilterItems: _accountingStatusItems(const [
        'asset',
        'liability',
        'equity',
        'income',
        'expense',
      ]),
      categoryLabel: 'Category',
      categoryFilterItems: _accountingStatusItems(const [
        'balance_sheet',
        'profit_and_loss',
      ]),
      suggestions: <AppRegisterFilterSuggestion>[
        AppRegisterFilterSuggestion(
          label: 'Active only',
          onSelected: () {
            final c = Get.find<AccountsRegisterController<AccountGroupModel>>(
              tag: persistentControllerTag('AccountGroupRegisterController'),
            );
            c.setStatuses({'active'});
          },
        ),
        AppRegisterFilterSuggestion(
          label: 'Balance sheet',
          onSelected: () {
            final c = Get.find<AccountsRegisterController<AccountGroupModel>>(
              tag: persistentControllerTag('AccountGroupRegisterController'),
            );
            c.setCategories({'balance_sheet'});
          },
        ),
        AppRegisterFilterSuggestion(
          label: 'P&L',
          onSelected: () {
            final c = Get.find<AccountsRegisterController<AccountGroupModel>>(
              tag: persistentControllerTag('AccountGroupRegisterController'),
            );
            c.setCategories({'profit_and_loss'});
          },
        ),
      ],
      loader: (service, filters) => service.accountGroups(
        filters: <String, dynamic>{
          ...filters,
          if (filters['status'] == 'active') 'is_active': 1,
          if (filters['status'] == 'inactive') 'is_active': 0,
          if (filters['type'] != null) 'group_nature': filters['type'],
          if (filters['categories'] != null)
            'group_category': filters['categories'],
        },
      ),
      matches: (row, query) {
        final text = '${row.groupCode} ${row.groupName} ${row.parentGroupName}'
            .toLowerCase();
        return text.contains(query);
      },
      columns: [
        PurchaseRegisterColumn<AccountGroupModel>(
          label: 'Code',
          valueBuilder: (row) => row.groupCode ?? '-',
        ),
        PurchaseRegisterColumn<AccountGroupModel>(
          label: 'Group Name',
          flex: 4,
          valueBuilder: (row) => row.groupName ?? '-',
        ),
        PurchaseRegisterColumn<AccountGroupModel>(
          label: 'Parent Group',
          flex: 3,
          valueBuilder: (row) => row.parentGroupName ?? '-',
        ),
        PurchaseRegisterColumn<AccountGroupModel>(
          label: 'Nature',
          valueBuilder: (row) => (row.groupNature ?? '-').titleCase,
        ),
        PurchaseRegisterColumn<AccountGroupModel>(
          label: 'Category',
          valueBuilder: (row) => (row.groupCategory ?? '-').titleCase,
        ),
        PurchaseRegisterColumn<AccountGroupModel>(
          label: 'Status',
          valueBuilder: (row) => row.isActive ? 'Active' : 'Inactive',
          widgetBuilder: (context, row) => AppStatusBadge(
            label: row.isActive ? 'Active' : 'Inactive',
            color: row.isActive ? appStatusColorSuccess : appStatusColorDanger,
          ),
        ),
      ],
      rowRoute: (row) => '/accounting/account-groups?view=manage&id=${row.id}',
    );
  }
}

// -----------------------------------------------------------------------------
// 4. Voucher Type Register Screen
// -----------------------------------------------------------------------------
class VoucherTypeRegisterPage extends StatelessWidget {
  const VoucherTypeRegisterPage({
    super.key,
    this.embedded = false,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final Map<String, String> queryParameters;

  @override
  Widget build(BuildContext context) {
    return _AccountsRegisterShell<VoucherTypeModel>(
      controllerName: 'VoucherTypeRegisterController',
      title: 'Voucher Types',
      embedded: embedded,
      queryParameters: queryParameters,
      newRoute: '/accounting/voucher-types?view=manage&new=1',
      newLabel: 'New Type',
      searchHint: 'Search voucher type code, name...',
      emptyMessage: 'No voucher types found.',
      statusValue: (row) => row.isActive ? 'active' : 'inactive',
      statusFilterItems: _accountingStatusItems(const ['active', 'inactive']),
      typeLabel: 'Category',
      typeFilterItems: _accountingStatusItems(const [
        'payment',
        'receipt',
        'journal',
        'contra',
        'sales',
        'purchase',
      ]),
      categoryLabel: 'Approval',
      categoryFilterItems: _accountingStatusItems(const [
        'required',
        'not_required',
      ]),
      suggestions: <AppRegisterFilterSuggestion>[
        AppRegisterFilterSuggestion(
          label: 'Payment',
          onSelected: () {
            final c = Get.find<AccountsRegisterController<VoucherTypeModel>>(
              tag: persistentControllerTag('VoucherTypeRegisterController'),
            );
            c.setTypes({'payment'});
          },
        ),
        AppRegisterFilterSuggestion(
          label: 'Receipt',
          onSelected: () {
            final c = Get.find<AccountsRegisterController<VoucherTypeModel>>(
              tag: persistentControllerTag('VoucherTypeRegisterController'),
            );
            c.setTypes({'receipt'});
          },
        ),
        AppRegisterFilterSuggestion(
          label: 'Journal',
          onSelected: () {
            final c = Get.find<AccountsRegisterController<VoucherTypeModel>>(
              tag: persistentControllerTag('VoucherTypeRegisterController'),
            );
            c.setTypes({'journal'});
          },
        ),
      ],
      loader: (service, filters) => service.voucherTypes(
        filters: <String, dynamic>{
          ...filters,
          if (filters['status'] == 'active') 'is_active': 1,
          if (filters['status'] == 'inactive') 'is_active': 0,
          if (filters['type'] != null) 'voucher_category': filters['type'],
        },
      ),
      matches: (row, query) {
        final text = '${row.code} ${row.name} ${row.voucherCategory}'
            .toLowerCase();
        return text.contains(query);
      },
      columns: [
        PurchaseRegisterColumn<VoucherTypeModel>(
          label: 'Code',
          valueBuilder: (row) => row.code ?? '-',
        ),
        PurchaseRegisterColumn<VoucherTypeModel>(
          label: 'Name',
          flex: 4,
          valueBuilder: (row) => row.name ?? '-',
        ),
        PurchaseRegisterColumn<VoucherTypeModel>(
          label: 'Category',
          valueBuilder: (row) => (row.voucherCategory ?? '-').titleCase,
        ),
        PurchaseRegisterColumn<VoucherTypeModel>(
          label: 'Auto Post',
          valueBuilder: (row) => row.autoPost ? 'Yes' : 'No',
        ),
        PurchaseRegisterColumn<VoucherTypeModel>(
          label: 'Approval Req.',
          valueBuilder: (row) => row.requiresApproval ? 'Yes' : 'No',
        ),
        PurchaseRegisterColumn<VoucherTypeModel>(
          label: 'Status',
          valueBuilder: (row) => row.isActive ? 'Active' : 'Inactive',
          widgetBuilder: (context, row) => AppStatusBadge(
            label: row.isActive ? 'Active' : 'Inactive',
            color: row.isActive ? appStatusColorSuccess : appStatusColorDanger,
          ),
        ),
      ],
      rowRoute: (row) => '/accounting/voucher-types?view=manage&id=${row.id}',
    );
  }
}

// -----------------------------------------------------------------------------
// 5. Document Posting Register Screen
// -----------------------------------------------------------------------------
class DocumentPostingRegisterPage extends StatelessWidget {
  const DocumentPostingRegisterPage({
    super.key,
    this.embedded = false,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final Map<String, String> queryParameters;

  @override
  Widget build(BuildContext context) {
    return _AccountsRegisterShell<DocumentPostingModel>(
      controllerName: 'DocumentPostingRegisterController',
      title: 'Document Postings',
      embedded: embedded,
      queryParameters: queryParameters,
      showNewAction: false,
      newRoute: '/accounting/document-postings',
      newLabel: 'Postings',
      searchHint: 'Search document no, remarks, error...',
      emptyMessage: 'No document postings found.',
      dateValue: (row) => row.documentDate,
      statusValue: (row) => row.postingStatus ?? 'draft',
      statusFilterItems: _accountingStatusItems(const [
        'draft',
        'posted',
        'failed',
        'reversed',
      ]),
      typeLabel: 'Module',
      typeFilterItems: _accountingStatusItems(const [
        'sales',
        'purchase',
        'inventory',
        'hr',
        'maintenance',
      ]),
      suggestions: <AppRegisterFilterSuggestion>[
        AppRegisterFilterSuggestion(
          label: 'Posted',
          onSelected: () {
            final c =
                Get.find<AccountsRegisterController<DocumentPostingModel>>(
                  tag: persistentControllerTag(
                    'DocumentPostingRegisterController',
                  ),
                );
            c.setStatuses({'posted'});
          },
        ),
        AppRegisterFilterSuggestion(
          label: 'Failed',
          onSelected: () {
            final c =
                Get.find<AccountsRegisterController<DocumentPostingModel>>(
                  tag: persistentControllerTag(
                    'DocumentPostingRegisterController',
                  ),
                );
            c.setStatuses({'failed'});
          },
        ),
      ],
      loader: (service, filters) => service.documentPostings(
        filters:
            <String, dynamic>{
                ...filters,
                if (filters['date_from'] != null)
                  'document_date_from': filters['date_from'],
                if (filters['date_to'] != null)
                  'document_date_to': filters['date_to'],
                if (filters['status'] != null)
                  'posting_status': filters['status'],
                if (filters['type'] != null) 'document_module': filters['type'],
              }
              ..remove('date_from')
              ..remove('date_to'),
      ),
      matches: (row, query) {
        final text =
            '${row.documentNo} ${row.documentModule} ${row.remarks} ${row.errorMessage}'
                .toLowerCase();
        return text.contains(query);
      },
      columns: [
        PurchaseRegisterColumn<DocumentPostingModel>(
          label: 'Document No',
          flex: 3,
          valueBuilder: (row) => row.documentNo ?? '-',
        ),
        PurchaseRegisterColumn<DocumentPostingModel>(
          label: 'Date',
          flex: 2,
          valueBuilder: (row) => displayDate(row.documentDate),
        ),
        PurchaseRegisterColumn<DocumentPostingModel>(
          label: 'Module',
          flex: 2,
          valueBuilder: (row) => (row.documentModule ?? '-').titleCase,
        ),
        PurchaseRegisterColumn<DocumentPostingModel>(
          label: 'Voucher ID',
          flex: 2,
          valueBuilder: (row) =>
              row.voucherId != null ? '#${row.voucherId}' : '-',
        ),
        PurchaseRegisterColumn<DocumentPostingModel>(
          label: 'Remarks / Error',
          flex: 4,
          valueBuilder: (row) => row.errorMessage ?? row.remarks ?? '-',
        ),
        PurchaseRegisterColumn<DocumentPostingModel>(
          label: 'Status',
          flex: 2,
          valueBuilder: (row) => row.postingStatus ?? 'draft',
          widgetBuilder: (context, row) => AppStatusBadge(
            label: (row.postingStatus ?? 'draft').titleCase,
            color: appStatusColor(row.postingStatus),
          ),
        ),
      ],
      rowRoute: (row) =>
          '/accounting/document-postings?view=manage&id=${row.id}',
    );
  }
}

// -----------------------------------------------------------------------------
// 6. Budget Register Screen
// -----------------------------------------------------------------------------
class BudgetRegisterPage extends StatelessWidget {
  const BudgetRegisterPage({
    super.key,
    this.embedded = false,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final Map<String, String> queryParameters;

  @override
  Widget build(BuildContext context) {
    return _AccountsRegisterShell<BudgetModel>(
      controllerName: 'BudgetRegisterController',
      title: 'Budgets',
      embedded: embedded,
      queryParameters: queryParameters,
      newRoute: '/accounting/budgets?view=manage&new=1',
      newLabel: 'New Budget',
      searchHint: 'Search budget code, name...',
      emptyMessage: 'No budgets found.',
      dateValue: (row) => row.dateFrom,
      statusValue: (row) => row.budgetStatus ?? 'draft',
      statusFilterItems: _accountingStatusItems(const [
        'draft',
        'approved',
        'active',
        'closed',
      ]),
      typeLabel: 'Active',
      typeFilterItems: _accountingStatusItems(const ['active', 'inactive']),
      suggestions: <AppRegisterFilterSuggestion>[
        AppRegisterFilterSuggestion(
          label: 'Active budgets',
          onSelected: () {
            final c = Get.find<AccountsRegisterController<BudgetModel>>(
              tag: persistentControllerTag('BudgetRegisterController'),
            );
            c.setStatuses({'active'});
          },
        ),
        AppRegisterFilterSuggestion(
          label: 'Approved',
          onSelected: () {
            final c = Get.find<AccountsRegisterController<BudgetModel>>(
              tag: persistentControllerTag('BudgetRegisterController'),
            );
            c.setStatuses({'approved'});
          },
        ),
      ],
      loader: (service, filters) => service.budgets(
        filters: <String, dynamic>{
          ...filters,
          if (filters['status'] != null) 'budget_status': filters['status'],
          if (filters['type'] == 'active') 'is_active': 1,
          if (filters['type'] == 'inactive') 'is_active': 0,
        },
      ),
      matches: (row, query) {
        final text = '${row.budgetCode} ${row.budgetName} ${row.budgetStatus}'
            .toLowerCase();
        return text.contains(query);
      },
      columns: [
        PurchaseRegisterColumn<BudgetModel>(
          label: 'Code',
          flex: 2,
          valueBuilder: (row) => row.budgetCode ?? '-',
        ),
        PurchaseRegisterColumn<BudgetModel>(
          label: 'Budget Name',
          flex: 4,
          valueBuilder: (row) => row.budgetName ?? '-',
        ),
        PurchaseRegisterColumn<BudgetModel>(
          label: 'From Date',
          flex: 2,
          valueBuilder: (row) => displayDate(row.dateFrom),
        ),
        PurchaseRegisterColumn<BudgetModel>(
          label: 'To Date',
          flex: 2,
          valueBuilder: (row) => displayDate(row.dateTo),
        ),
        PurchaseRegisterColumn<BudgetModel>(
          label: 'Status',
          flex: 2,
          valueBuilder: (row) => row.budgetStatus ?? 'draft',
          widgetBuilder: (context, row) => AppStatusBadge(
            label: (row.budgetStatus ?? 'draft').titleCase,
            color: appStatusColor(row.budgetStatus),
          ),
        ),
        PurchaseRegisterColumn<BudgetModel>(
          label: 'Active',
          flex: 2,
          valueBuilder: (row) => (row.isActive ?? true) ? 'Active' : 'Inactive',
          widgetBuilder: (context, row) => AppStatusBadge(
            label: (row.isActive ?? true) ? 'Active' : 'Inactive',
            color: (row.isActive ?? true)
                ? appStatusColorSuccess
                : appStatusColorDanger,
          ),
        ),
      ],
      rowRoute: (row) => '/accounting/budgets?view=manage&id=${row.id}',
    );
  }
}

// -----------------------------------------------------------------------------
// 7. Cash Session Register Screen
// -----------------------------------------------------------------------------
class CashSessionRegisterPage extends StatelessWidget {
  const CashSessionRegisterPage({
    super.key,
    this.embedded = false,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final Map<String, String> queryParameters;

  @override
  Widget build(BuildContext context) {
    return _AccountsRegisterShell<CashSessionModel>(
      controllerName: 'CashSessionRegisterController',
      title: 'Cash Sessions',
      embedded: embedded,
      queryParameters: queryParameters,
      newRoute: '/accounting/cash-sessions?view=manage&new=1',
      newLabel: 'Open Session',
      searchHint: 'Search user, cash account, remarks...',
      emptyMessage: 'No cash sessions found.',
      dateValue: (row) => row.openingDatetime,
      statusValue: (row) => row.status ?? 'open',
      statusFilterItems: _accountingStatusItems(const [
        'open',
        'closed',
        'cancelled',
      ]),
      suggestions: <AppRegisterFilterSuggestion>[
        AppRegisterFilterSuggestion(
          label: 'Open sessions',
          onSelected: () {
            final c = Get.find<AccountsRegisterController<CashSessionModel>>(
              tag: persistentControllerTag('CashSessionRegisterController'),
            );
            c.setStatuses({'open'});
          },
        ),
        AppRegisterFilterSuggestion(
          label: 'Closed sessions',
          onSelected: () {
            final c = Get.find<AccountsRegisterController<CashSessionModel>>(
              tag: persistentControllerTag('CashSessionRegisterController'),
            );
            c.setStatuses({'closed'});
          },
        ),
      ],
      loader: (service, filters) => service.cashSessions(
        filters: <String, dynamic>{
          ...filters,
          if (filters['status'] != null) 'status': filters['status'],
        },
      ),
      matches: (row, query) {
        final text =
            '${row.username} ${row.cashAccountName} ${row.cashAccountCode} ${row.remarks}'
                .toLowerCase();
        return text.contains(query);
      },
      columns: [
        PurchaseRegisterColumn<CashSessionModel>(
          label: 'User',
          flex: 3,
          valueBuilder: (row) => row.userDisplayName ?? row.username ?? '-',
        ),
        PurchaseRegisterColumn<CashSessionModel>(
          label: 'Cash Account',
          flex: 3,
          valueBuilder: (row) => row.cashAccountName ?? '-',
        ),
        PurchaseRegisterColumn<CashSessionModel>(
          label: 'Opened',
          flex: 3,
          valueBuilder: (row) => displayDateTime(row.openingDatetime),
        ),
        PurchaseRegisterColumn<CashSessionModel>(
          label: 'Opening Bal',
          flex: 2,
          alignRight: true,
          padding: const EdgeInsets.only(right: 8),
          valueBuilder: (row) => formatAmount(row.openingBalance ?? 0),
        ),
        PurchaseRegisterColumn<CashSessionModel>(
          label: 'Closing Bal',
          flex: 2,
          alignRight: true,
          padding: const EdgeInsets.only(right: 8),
          valueBuilder: (row) => formatAmount(row.actualClosingBalance ?? 0),
        ),
        PurchaseRegisterColumn<CashSessionModel>(
          label: 'Status',
          flex: 2,
          valueBuilder: (row) => row.status ?? 'open',
          widgetBuilder: (context, row) => AppStatusBadge(
            label: (row.status ?? 'open').titleCase,
            color: appStatusColor(row.status),
          ),
        ),
      ],
      rowRoute: (row) => '/accounting/cash-sessions?view=manage&id=${row.id}',
    );
  }
}

// -----------------------------------------------------------------------------
// 8. Bank Reconciliation Register Screen
// -----------------------------------------------------------------------------
class BankReconciliationRegisterPage extends StatelessWidget {
  const BankReconciliationRegisterPage({
    super.key,
    this.embedded = false,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final Map<String, String> queryParameters;

  @override
  Widget build(BuildContext context) {
    return _AccountsRegisterShell<BankReconciliationModel>(
      controllerName: 'BankReconciliationRegisterController',
      title: 'Bank Reconciliation',
      embedded: embedded,
      queryParameters: queryParameters,
      newRoute: '/accounting/bank-reconciliation?view=manage&new=1',
      newLabel: 'Reconcile',
      searchHint: 'Search bank reference, remarks, voucher...',
      emptyMessage: 'No reconciliation entries found.',
      dateValue: (row) => row.bankDate,
      statusValue: (row) => row.reconciliationStatus ?? 'pending',
      statusFilterItems: _accountingStatusItems(const [
        'pending',
        'reconciled',
        'rejected',
      ]),
      typeLabel: 'Entry',
      typeFilterItems: _accountingStatusItems(const ['debit', 'credit']),
      suggestions: <AppRegisterFilterSuggestion>[
        AppRegisterFilterSuggestion(
          label: 'Pending',
          onSelected: () {
            final c =
                Get.find<AccountsRegisterController<BankReconciliationModel>>(
                  tag: persistentControllerTag(
                    'BankReconciliationRegisterController',
                  ),
                );
            c.setStatuses({'pending'});
          },
        ),
        AppRegisterFilterSuggestion(
          label: 'Reconciled',
          onSelected: () {
            final c =
                Get.find<AccountsRegisterController<BankReconciliationModel>>(
                  tag: persistentControllerTag(
                    'BankReconciliationRegisterController',
                  ),
                );
            c.setStatuses({'reconciled'});
          },
        ),
      ],
      loader: (service, filters) => service.bankReconciliation(
        filters:
            <String, dynamic>{
                ...filters,
                if (filters['date_from'] != null)
                  'bank_date_from': filters['date_from'],
                if (filters['date_to'] != null)
                  'bank_date_to': filters['date_to'],
                if (filters['status'] != null)
                  'reconciliation_status': filters['status'],
              }
              ..remove('date_from')
              ..remove('date_to'),
      ),
      matches: (row, query) {
        final text =
            '${row.bankReferenceNo} ${row.voucherNo} ${row.accountName} ${row.remarks}'
                .toLowerCase();
        return text.contains(query);
      },
      columns: [
        PurchaseRegisterColumn<BankReconciliationModel>(
          label: 'Bank Account',
          flex: 3,
          valueBuilder: (row) => row.accountName ?? '-',
        ),
        PurchaseRegisterColumn<BankReconciliationModel>(
          label: 'Voucher No',
          flex: 3,
          valueBuilder: (row) => row.voucherNo ?? '-',
        ),
        PurchaseRegisterColumn<BankReconciliationModel>(
          label: 'Bank Date',
          flex: 2,
          valueBuilder: (row) => displayDate(row.bankDate),
        ),
        PurchaseRegisterColumn<BankReconciliationModel>(
          label: 'Ref No',
          flex: 2,
          valueBuilder: (row) => row.bankReferenceNo ?? '-',
        ),
        PurchaseRegisterColumn<BankReconciliationModel>(
          label: 'Amount',
          flex: 2,
          alignRight: true,
          padding: const EdgeInsets.only(right: 8),
          valueBuilder: (row) => formatAmount(row.voucherAmount ?? 0),
        ),
        PurchaseRegisterColumn<BankReconciliationModel>(
          label: 'Status',
          flex: 2,
          valueBuilder: (row) => row.reconciliationStatus ?? 'pending',
          widgetBuilder: (context, row) => AppStatusBadge(
            label: (row.reconciliationStatus ?? 'pending').titleCase,
            color: appStatusColor(row.reconciliationStatus),
          ),
        ),
      ],
      rowRoute: (row) =>
          '/accounting/bank-reconciliation?view=manage&id=${row.id}',
    );
  }
}

// -----------------------------------------------------------------------------
// 9. Posting Rule Register Screen
// -----------------------------------------------------------------------------
class PostingRuleRegisterPage extends StatelessWidget {
  const PostingRuleRegisterPage({
    super.key,
    this.embedded = false,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final Map<String, String> queryParameters;

  @override
  Widget build(BuildContext context) {
    return _AccountsRegisterShell<PostingRuleModel>(
      controllerName: 'PostingRuleRegisterController',
      title: 'Posting Rules',
      embedded: embedded,
      queryParameters: queryParameters,
      newRoute: '/accounting/posting-rules?view=manage&new=1',
      newLabel: 'New Rule',
      searchHint: 'Search narration template, source...',
      emptyMessage: 'No posting rules found.',
      statusValue: (row) => (row.isActive ?? true) ? 'active' : 'inactive',
      statusFilterItems: _accountingStatusItems(const ['active', 'inactive']),
      typeLabel: 'Side',
      typeFilterItems: _accountingStatusItems(const ['debit', 'credit']),
      categoryLabel: 'Account Source',
      categoryFilterItems: _accountingStatusItems(const [
        'customer',
        'supplier',
        'fixed_account',
        'item',
        'tax',
      ]),
      suggestions: <AppRegisterFilterSuggestion>[
        AppRegisterFilterSuggestion(
          label: 'Debits',
          onSelected: () {
            final c = Get.find<AccountsRegisterController<PostingRuleModel>>(
              tag: persistentControllerTag('PostingRuleRegisterController'),
            );
            c.setTypes({'debit'});
          },
        ),
        AppRegisterFilterSuggestion(
          label: 'Credits',
          onSelected: () {
            final c = Get.find<AccountsRegisterController<PostingRuleModel>>(
              tag: persistentControllerTag('PostingRuleRegisterController'),
            );
            c.setTypes({'credit'});
          },
        ),
      ],
      loader: (service, filters) => service.postingRules(
        filters: <String, dynamic>{
          ...filters,
          if (filters['status'] == 'active') 'is_active': 1,
          if (filters['status'] == 'inactive') 'is_active': 0,
          if (filters['type'] != null) 'entry_side': filters['type'],
          if (filters['categories'] != null)
            'account_source_type': filters['categories'],
        },
      ),
      matches: (row, query) {
        final text =
            '${row.narrationTemplate} ${row.accountSourceType} ${row.amountSource}'
                .toLowerCase();
        return text.contains(query);
      },
      columns: [
        PurchaseRegisterColumn<PostingRuleModel>(
          label: 'Line',
          flex: 1,
          valueBuilder: (row) => '#${row.lineNo ?? 1}',
        ),
        PurchaseRegisterColumn<PostingRuleModel>(
          label: 'Side',
          flex: 2,
          valueBuilder: (row) => (row.entrySide ?? '-').titleCase,
          widgetBuilder: (context, row) => AppStatusBadge(
            label: (row.entrySide ?? '-').titleCase,
            color: row.entrySide == 'debit'
                ? appStatusColorInfo
                : appStatusColorSuccess,
          ),
        ),
        PurchaseRegisterColumn<PostingRuleModel>(
          label: 'Account Source',
          flex: 3,
          valueBuilder: (row) => (row.accountSourceType ?? '-').titleCase,
        ),
        PurchaseRegisterColumn<PostingRuleModel>(
          label: 'Amount Source',
          flex: 3,
          valueBuilder: (row) => (row.amountSource ?? '-').titleCase,
        ),
        PurchaseRegisterColumn<PostingRuleModel>(
          label: 'Narration Template',
          flex: 4,
          valueBuilder: (row) => row.narrationTemplate ?? '-',
        ),
        PurchaseRegisterColumn<PostingRuleModel>(
          label: 'Status',
          flex: 2,
          valueBuilder: (row) => (row.isActive ?? true) ? 'Active' : 'Inactive',
          widgetBuilder: (context, row) => AppStatusBadge(
            label: (row.isActive ?? true) ? 'Active' : 'Inactive',
            color: (row.isActive ?? true)
                ? appStatusColorSuccess
                : appStatusColorDanger,
          ),
        ),
      ],
      rowRoute: (row) => '/accounting/posting-rules?view=manage&id=${row.id}',
    );
  }
}

// -----------------------------------------------------------------------------
// 10. Posting Rule Group Register Screen
// -----------------------------------------------------------------------------
class PostingRuleGroupRegisterPage extends StatelessWidget {
  const PostingRuleGroupRegisterPage({
    super.key,
    this.embedded = false,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final Map<String, String> queryParameters;

  @override
  Widget build(BuildContext context) {
    return _AccountsRegisterShell<PostingRuleGroupModel>(
      controllerName: 'PostingRuleGroupRegisterController',
      title: 'Posting Rule Groups',
      embedded: embedded,
      queryParameters: queryParameters,
      newRoute: '/accounting/posting-rule-groups?view=manage&new=1',
      newLabel: 'New Rule Group',
      searchHint: 'Search group code, name, description...',
      emptyMessage: 'No posting rule groups found.',
      statusValue: (row) => (row.isActive ?? true) ? 'active' : 'inactive',
      statusFilterItems: _accountingStatusItems(const ['active', 'inactive']),
      typeLabel: 'Trigger',
      typeFilterItems: _accountingStatusItems(const [
        'on_save',
        'on_post',
        'on_cancel',
      ]),
      categoryLabel: 'Document Type',
      categoryFilterItems: _accountingStatusItems(const [
        'sales_invoice',
        'purchase_invoice',
        'payment',
        'receipt',
      ]),
      suggestions: <AppRegisterFilterSuggestion>[
        AppRegisterFilterSuggestion(
          label: 'Active only',
          onSelected: () {
            final c =
                Get.find<AccountsRegisterController<PostingRuleGroupModel>>(
                  tag: persistentControllerTag(
                    'PostingRuleGroupRegisterController',
                  ),
                );
            c.setStatuses({'active'});
          },
        ),
      ],
      loader: (service, filters) => service.postingRuleGroups(
        filters: <String, dynamic>{
          ...filters,
          if (filters['status'] == 'active') 'is_active': 1,
          if (filters['status'] == 'inactive') 'is_active': 0,
          if (filters['type'] != null) 'trigger_event': filters['type'],
          if (filters['categories'] != null)
            'document_type': filters['categories'],
        },
      ),
      matches: (row, query) {
        final text = '${row.groupCode} ${row.groupName} ${row.description}'
            .toLowerCase();
        return text.contains(query);
      },
      columns: [
        PurchaseRegisterColumn<PostingRuleGroupModel>(
          label: 'Code',
          flex: 2,
          valueBuilder: (row) => row.groupCode ?? '-',
        ),
        PurchaseRegisterColumn<PostingRuleGroupModel>(
          label: 'Name',
          flex: 4,
          valueBuilder: (row) => row.groupName ?? '-',
        ),
        PurchaseRegisterColumn<PostingRuleGroupModel>(
          label: 'Description',
          flex: 4,
          valueBuilder: (row) => row.description ?? '-',
        ),
        PurchaseRegisterColumn<PostingRuleGroupModel>(
          label: 'Document Type',
          flex: 3,
          valueBuilder: (row) => (row.documentType ?? '-').titleCase,
        ),
        PurchaseRegisterColumn<PostingRuleGroupModel>(
          label: 'Trigger',
          flex: 2,
          valueBuilder: (row) => (row.triggerEvent ?? '-').titleCase,
        ),
        PurchaseRegisterColumn<PostingRuleGroupModel>(
          label: 'Status',
          flex: 2,
          valueBuilder: (row) => (row.isActive ?? true) ? 'Active' : 'Inactive',
          widgetBuilder: (context, row) => AppStatusBadge(
            label: (row.isActive ?? true) ? 'Active' : 'Inactive',
            color: (row.isActive ?? true)
                ? appStatusColorSuccess
                : appStatusColorDanger,
          ),
        ),
      ],
      rowRoute: (row) =>
          '/accounting/posting-rule-groups?view=manage&id=${row.id}',
    );
  }
}

// -----------------------------------------------------------------------------
// 11. Party Account Register Screen
// -----------------------------------------------------------------------------
class AccountsPartyAccountRegisterPage extends StatelessWidget {
  const AccountsPartyAccountRegisterPage({
    super.key,
    this.embedded = false,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final Map<String, String> queryParameters;

  @override
  Widget build(BuildContext context) {
    return _AccountsRegisterShell<PartyAccountModel>(
      controllerName: 'AccountsPartyAccountRegisterController',
      title: 'Party Accounts',
      embedded: embedded,
      queryParameters: queryParameters,
      newRoute: '/accounting/party-accounts?view=manage&new=1',
      newLabel: 'New Mapping',
      searchHint: 'Search party, account code, remarks...',
      emptyMessage: 'No party accounts found.',
      statusValue: (row) => row.isActive ? 'active' : 'inactive',
      statusFilterItems: _accountingStatusItems(const ['active', 'inactive']),
      typeLabel: 'Purpose',
      typeFilterItems: _accountingStatusItems(const [
        'primary',
        'receivable',
        'payable',
        'advance',
        'salary',
        'commission',
        'other',
      ]),
      suggestions: <AppRegisterFilterSuggestion>[
        AppRegisterFilterSuggestion(
          label: 'Receivables',
          onSelected: () {
            final c = Get.find<AccountsRegisterController<PartyAccountModel>>(
              tag: persistentControllerTag(
                'AccountsPartyAccountRegisterController',
              ),
            );
            c.setTypes({'receivable'});
          },
        ),
        AppRegisterFilterSuggestion(
          label: 'Payables',
          onSelected: () {
            final c = Get.find<AccountsRegisterController<PartyAccountModel>>(
              tag: persistentControllerTag(
                'AccountsPartyAccountRegisterController',
              ),
            );
            c.setTypes({'payable'});
          },
        ),
      ],
      loader: (service, filters) => service.partyAccountsRegister(
        filters: <String, dynamic>{
          ...filters,
          if (filters['status'] == 'active') 'is_active': 1,
          if (filters['status'] == 'inactive') 'is_active': 0,
          if (filters['type'] != null) 'account_purpose': filters['type'],
        },
      ),
      matches: (row, query) {
        final text =
            '${row.partyName} ${row.accountCode} ${row.accountName} ${row.accountPurpose}'
                .toLowerCase();
        return text.contains(query);
      },
      columns: [
        PurchaseRegisterColumn<PartyAccountModel>(
          label: 'Party',
          flex: 3,
          valueBuilder: (row) => row.partyName ?? 'Party #${row.partyId}',
        ),
        PurchaseRegisterColumn<PartyAccountModel>(
          label: 'Account Code',
          flex: 2,
          valueBuilder: (row) => row.accountCode ?? '-',
        ),
        PurchaseRegisterColumn<PartyAccountModel>(
          label: 'Account Name',
          flex: 3,
          valueBuilder: (row) => row.accountName ?? '-',
        ),
        PurchaseRegisterColumn<PartyAccountModel>(
          label: 'Purpose',
          flex: 2,
          valueBuilder: (row) => (row.accountPurpose ?? '-').titleCase,
        ),
        PurchaseRegisterColumn<PartyAccountModel>(
          label: 'Default',
          flex: 2,
          valueBuilder: (row) => row.isDefault ? 'Yes' : 'No',
        ),
        PurchaseRegisterColumn<PartyAccountModel>(
          label: 'Status',
          flex: 2,
          valueBuilder: (row) => row.isActive ? 'Active' : 'Inactive',
          widgetBuilder: (context, row) => AppStatusBadge(
            label: row.isActive ? 'Active' : 'Inactive',
            color: row.isActive ? appStatusColorSuccess : appStatusColorDanger,
          ),
        ),
      ],
      rowRoute: (row) => '/accounting/party-accounts?view=manage&id=${row.id}',
    );
  }
}
