import '../../screen.dart';
import '../../controller/sales/sales_module_refresh_controller.dart';

typedef SalesRegisterLoader<T> = Future<dynamic> Function(SalesService service);
typedef SalesRegisterMatcher<T> =
    bool Function(T row, String query, String status);
typedef SalesRegisterDashboardMatcher<T> =
    bool Function(T row, String dashboardFilter);
typedef SalesRegisterDateValue<T> = String? Function(T row);
typedef SalesRegisterDocumentValue<T> = String Function(T row);
typedef SalesRegisterBalanceValue<T> = double? Function(T row);

const _salesRegisterSortItems = <AppDropdownItem<String>>[
  AppDropdownItem(value: '', label: 'Default order'),
  AppDropdownItem(value: 'date_desc', label: 'Newest first'),
  AppDropdownItem(value: 'date_asc', label: 'Oldest first'),
  AppDropdownItem(value: 'doc_asc', label: 'Number A-Z'),
  AppDropdownItem(value: 'doc_desc', label: 'Number Z-A'),
];

const _salesInvoiceRegisterSortItems = <AppDropdownItem<String>>[
  AppDropdownItem(value: '', label: 'Default order'),
  AppDropdownItem(value: 'date_desc', label: 'Newest first'),
  AppDropdownItem(value: 'date_asc', label: 'Oldest first'),
  AppDropdownItem(value: 'doc_asc', label: 'Number A-Z'),
  AppDropdownItem(value: 'doc_desc', label: 'Number Z-A'),
  AppDropdownItem(value: 'balance_desc', label: 'High outstanding'),
];

int _compareRegisterStrings(String? left, String? right) {
  final leftValue = (left ?? '').trim().toLowerCase();
  final rightValue = (right ?? '').trim().toLowerCase();
  if (leftValue.isEmpty && rightValue.isEmpty) {
    return 0;
  }
  if (leftValue.isEmpty) {
    return 1;
  }
  if (rightValue.isEmpty) {
    return -1;
  }
  return leftValue.compareTo(rightValue);
}

void _openSalesShellRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}

String _salesCustomerName(Map<String, dynamic> data) {
  final customer = data['customer'];
  if (customer is Map) {
    return stringValue(Map<String, dynamic>.from(customer), 'party_name');
  }
  return stringValue(data, 'customer_name');
}

class SalesRegisterController<T> extends GetxController {
  SalesRegisterController({
    required this.loader,
    required this.matches,
    required this.dashboardMatches,
    required this.dateValueOf,
    required this.documentValueOf,
    this.balanceValueOf,
    this.initialSort = '',
  });

  final SalesRegisterLoader<T> loader;
  final SalesRegisterMatcher<T> matches;
  final SalesRegisterDashboardMatcher<T> dashboardMatches;
  final SalesRegisterDateValue<T> dateValueOf;
  final SalesRegisterDocumentValue<T> documentValueOf;
  final SalesRegisterBalanceValue<T>? balanceValueOf;
  final String initialSort;
  final SalesService _service = SalesService();
  final SalesModuleRefreshController _refreshController =
      SalesModuleRefreshController.ensureRegistered();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController dateFromController = TextEditingController();
  final TextEditingController dateToController = TextEditingController();

  bool loading = true;
  String? error;
  String status = '';
  String sort = '';
  String dashboardFilter = '';
  Map<String, dynamic> customFilters = <String, dynamic>{};
  List<T> rows = <T>[];
  Worker? _refreshWorker;

  List<T> get filteredRows {
    final query = searchController.text.trim().toLowerCase();
    final filtered = rows
        .where(
          (row) =>
              matches(row, query, status) &&
              matchesDateValueRange(
                dateValueOf(row),
                fromValue: dateFromController.text,
                toValue: dateToController.text,
              ) &&
              dashboardMatches(row, dashboardFilter),
        )
        .toList(growable: false);
    filtered.sort(_compareRows);
    return filtered;
  }

  @override
  void onInit() {
    super.onInit();
    sort = initialSort;
    searchController.addListener(update);
    dateFromController.addListener(update);
    dateToController.addListener(update);
    _refreshWorker = ever<SalesModuleRefreshEvent?>(
      _refreshController.lastEvent,
      (event) {
        if (event == null) {
          return;
        }
        unawaited(load());
      },
    );
    unawaited(load());
  }

  @override
  void onClose() {
    _refreshWorker?.dispose();
    dateFromController
      ..removeListener(update)
      ..dispose();
    dateToController
      ..removeListener(update)
      ..dispose();
    searchController
      ..removeListener(update)
      ..dispose();
    super.onClose();
  }

  void setStatus(String value) {
    status = value;
    update();
  }

  void setSort(String value) {
    sort = value;
    update();
  }

  void setCustomFilter(String key, dynamic value) {
    customFilters[key] = value;
    update();
  }

  void applyDashboardFilter(String value, {String statusOverride = ''}) {
    dashboardFilter = value.trim();
    status = statusOverride;
    sort = initialSort;
    searchController.clear();
    dateFromController.clear();
    dateToController.clear();
    update();
  }

  int _compareRows(T left, T right) {
    switch (sort) {
      case 'date_desc':
        return _compareRegisterStrings(dateValueOf(right), dateValueOf(left));
      case 'date_asc':
        return _compareRegisterStrings(dateValueOf(left), dateValueOf(right));
      case 'doc_asc':
        return _compareRegisterStrings(
          documentValueOf(left),
          documentValueOf(right),
        );
      case 'doc_desc':
        return _compareRegisterStrings(
          documentValueOf(right),
          documentValueOf(left),
        );
      case 'balance_desc':
        return _compareBalanceValues(
          balanceValueOf?.call(right),
          balanceValueOf?.call(left),
        );
      case 'balance_asc':
        return _compareBalanceValues(
          balanceValueOf?.call(left),
          balanceValueOf?.call(right),
        );
      default:
        return 0;
    }
  }

  int _compareBalanceValues(double? left, double? right) {
    final leftValue = left ?? -1;
    final rightValue = right ?? -1;
    return leftValue.compareTo(rightValue);
  }

  Future<void> load() async {
    loading = true;
    error = null;
    update();
    try {
      final response = await loader(_service);
      final data = response.data;
      rows = data is List<T>
          ? data
          : data is List
          ? data.whereType<T>().toList(growable: false)
          : <T>[];
      loading = false;
      update();
    } catch (err) {
      error = err.toString();
      loading = false;
      update();
    }
  }
}

class _SalesRegisterShell<T> extends StatefulWidget {
  const _SalesRegisterShell({
    required this.controllerName,
    required this.title,
    required this.embedded,
    required this.loader,
    required this.matches,
    required this.dashboardMatches,
    required this.dateValueOf,
    required this.documentValueOf,
    this.balanceValueOf,
    this.initialSort = '',
    required this.emptyMessage,
    required this.newRoute,
    required this.newLabel,
    required this.searchHint,
    required this.statusItems,
    required this.columns,
    required this.rowRoute,
    this.queryParameters = const <String, String>{},
    this.dashboardStatusForFilter,
    this.extraActionsBuilder,
    this.customFiltersBuilder,
  });

  final String controllerName;
  final String title;
  final bool embedded;
  final SalesRegisterLoader<T> loader;
  final SalesRegisterMatcher<T> matches;
  final SalesRegisterDashboardMatcher<T> dashboardMatches;
  final SalesRegisterDateValue<T> dateValueOf;
  final SalesRegisterDocumentValue<T> documentValueOf;
  final SalesRegisterBalanceValue<T>? balanceValueOf;
  final String initialSort;
  final String emptyMessage;
  final String newRoute;
  final String newLabel;
  final String searchHint;
  final List<AppDropdownItem<String>> statusItems;
  final List<PurchaseRegisterColumn<T>> columns;
  final String Function(T row) rowRoute;
  final Map<String, String> queryParameters;
  final String Function(String dashboardFilter)? dashboardStatusForFilter;
  final List<Widget> Function(
    BuildContext context,
    SalesRegisterController<T> controller,
  )?
  extraActionsBuilder;
  final Widget Function(
    BuildContext context,
    SalesRegisterController<T> controller,
  )?
  customFiltersBuilder;

  @override
  State<_SalesRegisterShell<T>> createState() => _SalesRegisterShellState<T>();
}

class _SalesRegisterShellState<T> extends State<_SalesRegisterShell<T>> {
  late final String _controllerTag;

  String _dashboardFilterValue() =>
      (widget.queryParameters['dashboard_filter'] ?? '').trim();

  void _applyDashboardFilter(SalesRegisterController<T> controller) {
    final dashboardFilter = _dashboardFilterValue();
    final statusOverride =
        widget.dashboardStatusForFilter?.call(dashboardFilter) ?? '';
    controller.applyDashboardFilter(
      dashboardFilter,
      statusOverride: statusOverride,
    );
  }

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(widget.controllerName);
    if (!Get.isRegistered<SalesRegisterController<T>>(tag: _controllerTag)) {
      Get.put(
        SalesRegisterController<T>(
          loader: widget.loader,
          matches: widget.matches,
          dashboardMatches: widget.dashboardMatches,
          dateValueOf: widget.dateValueOf,
          documentValueOf: widget.documentValueOf,
          balanceValueOf: widget.balanceValueOf,
          initialSort: widget.initialSort,
        ),
        tag: _controllerTag,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !Get.isRegistered<SalesRegisterController<T>>(tag: _controllerTag)) {
        return;
      }
      _applyDashboardFilter(
        Get.find<SalesRegisterController<T>>(tag: _controllerTag),
      );
    });
  }

  @override
  void didUpdateWidget(covariant _SalesRegisterShell<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(oldWidget.queryParameters, widget.queryParameters)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            !Get.isRegistered<SalesRegisterController<T>>(
              tag: _controllerTag,
            )) {
          return;
        }
        _applyDashboardFilter(
          Get.find<SalesRegisterController<T>>(tag: _controllerTag),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SalesRegisterController<T>>(
      tag: _controllerTag,
      builder: (controller) {
        final extraActions =
            widget.extraActionsBuilder?.call(context, controller) ??
            const <Widget>[];
        return PurchaseRegisterPage<T>(
          title: widget.title,
          embedded: widget.embedded,
          loading: controller.loading,
          errorMessage: controller.error,
          onRetry: controller.load,
          emptyMessage: widget.emptyMessage,
          filters:
              widget.customFiltersBuilder?.call(context, controller) ??
              _SalesRegisterFilters<T>(
                controller: controller,
                statusItems: widget.statusItems,
                title: 'Find ${widget.title}',
                searchHint: widget.searchHint,
              ),
          actions: [
            ...extraActions,
            AdaptiveShellActionButton(
              onPressed: () => _openSalesShellRoute(context, widget.newRoute),
              icon: Icons.add_outlined,
              label: widget.newLabel,
            ),
          ],
          rows: controller.filteredRows,
          columns: widget.columns,
          onRowTap: (row) =>
              _openSalesShellRoute(context, widget.rowRoute(row)),
        );
      },
    );
  }
}

List<AppDropdownItem<int?>> _mappedCustomerItems<T>(
  SalesRegisterController<T> controller,
) {
  final uniqueCustomers = <int, String>{};
  for (final row in controller.rows) {
    if (row is! JsonModel) {
      continue;
    }
    final data = row.toJson();
    final id = intValue(data, 'customer_party_id');
    final name = _salesCustomerName(data);
    if (id != null && name.isNotEmpty) {
      uniqueCustomers[id] = name;
    }
  }
  return <AppDropdownItem<int?>>[
    const AppDropdownItem<int?>(value: null, label: 'All Customers'),
    ...uniqueCustomers.entries.map(
      (entry) => AppDropdownItem<int?>(value: entry.key, label: entry.value),
    ),
  ];
}

class _SalesRegisterFilters<T> extends StatelessWidget {
  const _SalesRegisterFilters({
    required this.controller,
    required this.statusItems,
    required this.title,
    required this.searchHint,
    this.customerItemsBuilder,
    this.sortItems = _salesRegisterSortItems,
  });

  final SalesRegisterController<T> controller;
  final List<AppDropdownItem<String>> statusItems;
  final String title;
  final String searchHint;
  final List<AppDropdownItem<int?>> Function(SalesRegisterController<T>)?
  customerItemsBuilder;
  final List<AppDropdownItem<String>> sortItems;

  void _clearFilters() {
    controller.searchController.clear();
    controller.dateFromController.clear();
    controller.dateToController.clear();
    controller.setCustomFilter('customer_id', null);
    controller.setStatus('');
    controller.setSort('');
  }

  Widget _searchField() {
    return AppFormTextField(
      labelText: 'Search',
      controller: controller.searchController,
      hintText: searchHint,
    );
  }

  Widget _customerField() {
    return AppDropdownField<int?>.fromMapped(
      labelText: 'Customer',
      mappedItems: customerItemsBuilder!(controller),
      initialValue: controller.customFilters['customer_id'] as int?,
      onChanged: (value) => controller.setCustomFilter('customer_id', value),
    );
  }

  Widget _statusField() {
    return AppDropdownField<String>.fromMapped(
      labelText: 'Status',
      mappedItems: statusItems,
      initialValue: controller.status,
      onChanged: (value) => controller.setStatus(value ?? ''),
    );
  }

  Widget _sortField() {
    return AppDropdownField<String>.fromMapped(
      labelText: 'Sort',
      mappedItems: sortItems,
      initialValue: controller.sort,
      onChanged: (value) => controller.setSort(value ?? ''),
    );
  }

  Widget _dateField({
    required String label,
    required TextEditingController textController,
  }) {
    return AppFormTextField(
      labelText: label,
      controller: textController,
      hintText: 'YYYY-MM-DD',
      keyboardType: TextInputType.datetime,
      inputFormatters: const [DateInputFormatter()],
      validator: Validators.optionalDate(label),
    );
  }

  Widget _actionField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppUiConstants.spacingXs),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.clear_outlined),
            label: const Text('Clear'),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppUiConstants.buttonRadius,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCustomer = customerItemsBuilder != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isWide = width >= 1480;
        final isMedium = width >= 920 && width < 1480;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _searchField()),
              const SizedBox(width: AppUiConstants.spacingMd),
              if (hasCustomer) ...[
                Expanded(child: _customerField()),
                const SizedBox(width: AppUiConstants.spacingMd),
              ],
              Expanded(child: _statusField()),
              const SizedBox(width: AppUiConstants.spacingMd),
              Expanded(child: _sortField()),
              const SizedBox(width: AppUiConstants.spacingMd),
              Expanded(
                child: _dateField(
                  label: 'Date From',
                  textController: controller.dateFromController,
                ),
              ),
              const SizedBox(width: AppUiConstants.spacingMd),
              Expanded(
                child: _dateField(
                  label: 'Date To',
                  textController: controller.dateToController,
                ),
              ),
              const SizedBox(width: AppUiConstants.spacingMd),
              SizedBox(width: 160, child: _actionField(context)),
            ],
          );
        }

        if (isMedium) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _searchField()),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  if (hasCustomer) ...[
                    Expanded(child: _customerField()),
                    const SizedBox(width: AppUiConstants.spacingMd),
                  ],
                  Expanded(child: _statusField()),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  Expanded(child: _sortField()),
                ],
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _dateField(
                      label: 'Date From',
                      textController: controller.dateFromController,
                    ),
                  ),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  Expanded(
                    child: _dateField(
                      label: 'Date To',
                      textController: controller.dateToController,
                    ),
                  ),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  Expanded(child: _actionField(context)),
                ],
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            SettingsFormWrap(
              maxWidth: double.infinity,
              children: [
                _searchField(),
                if (hasCustomer) _customerField(),
                _statusField(),
                _sortField(),
                _dateField(
                  label: 'Date From',
                  textController: controller.dateFromController,
                ),
                _dateField(
                  label: 'Date To',
                  textController: controller.dateToController,
                ),
                _actionField(context),
              ],
            ),
          ],
        );
      },
    );
  }
}

class SalesQuotationRegisterPage extends StatelessWidget {
  const SalesQuotationRegisterPage({
    super.key,
    this.embedded = false,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final Map<String, String> queryParameters;

  static const _statusItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All status'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'posted', label: 'Posted'),
    AppDropdownItem(value: 'sent', label: 'Sent'),
    AppDropdownItem(value: 'accepted', label: 'Accepted'),
    AppDropdownItem(value: 'rejected', label: 'Rejected'),
    AppDropdownItem(value: 'expired', label: 'Expired'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return _SalesRegisterShell<SalesQuotationModel>(
      controllerName: 'SalesQuotationRegisterController',
      title: 'Quotations',
      embedded: embedded,
      queryParameters: queryParameters,
      loader: (service) => service.quotations(
        filters: const {'per_page': 200, 'sort_by': 'quotation_date'},
      ),
      documentValueOf: (row) => stringValue(row.toJson(), 'quotation_no'),
      matches: (row, query, status) {
        final data = row.toJson();
        final rowStatus = stringValue(data, 'quotation_status');
        final searchText = [
          stringValue(data, 'quotation_no'),
          rowStatus,
          _salesCustomerName(data),
        ].join(' ').toLowerCase();
        final controller =
            Get.find<SalesRegisterController<SalesQuotationModel>>(
              tag: persistentControllerTag('SalesQuotationRegisterController'),
            );
        final filterCustomerId =
            controller.customFilters['customer_id'] as int?;
        final customerOk =
            filterCustomerId == null || row.customerPartyId == filterCustomerId;
        return (status.isEmpty || rowStatus == status) &&
            (query.isEmpty || searchText.contains(query)) &&
            customerOk;
      },
      dashboardMatches: (row, dashboardFilter) {
        switch (dashboardFilter.trim()) {
          case 'open':
            final status = stringValue(
              row.toJson(),
              'quotation_status',
            ).trim().toLowerCase();
            return !<String>{
              'accepted',
              'rejected',
              'expired',
              'cancelled',
            }.contains(status);
          default:
            return true;
        }
      },
      dateValueOf: (row) => nullableStringValue(row.toJson(), 'quotation_date'),
      emptyMessage: 'No quotations yet. Create a quote for your customer.',
      customFiltersBuilder: (context, controller) => _SalesRegisterFilters(
        controller: controller,
        statusItems: _statusItems,
        title: 'Find Quotations',
        searchHint: 'Quotation no or customer name',
        customerItemsBuilder: _mappedCustomerItems,
      ),
      newRoute: '/sales/quotations/new',
      newLabel: 'New quotation',
      searchHint: 'Search number or customer',
      statusItems: _statusItems,
      dashboardStatusForFilter: (dashboardFilter) {
        switch (dashboardFilter.trim()) {
          case 'open':
            return '';
          default:
            return '';
        }
      },
      columns: [
        PurchaseRegisterColumn(
          label: 'No',
          valueBuilder: (row) => stringValue(row.toJson(), 'quotation_no'),
        ),
        PurchaseRegisterColumn(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'quotation_date')),
        ),
        PurchaseRegisterColumn(
          label: 'Customer',
          flex: 3,
          valueBuilder: (row) => _salesCustomerName(row.toJson()),
        ),
        PurchaseRegisterColumn(
          label: 'Valid until',
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'valid_until')),
        ),
        PurchaseRegisterColumn(
          label: 'Status',
          valueBuilder: (row) =>
              salesStatusLabel(stringValue(row.toJson(), 'quotation_status')),
          widgetBuilder: (context, row) => salesStatusBadge(
            context,
            stringValue(row.toJson(), 'quotation_status'),
          ),
          detailBuilder: (row) => salesRegisterCancelReasonDetail(
            row.toJson(),
            statusKey: 'quotation_status',
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Total',
          alignRight: true,
          valueBuilder: (row) {
            final raw = row.toJson()['total_amount'];
            final amount = raw is num
                ? raw.toDouble()
                : double.tryParse(raw?.toString() ?? '');
            if (amount == null) return '-';
            return amount.toStringAsFixed(2);
          },
        ),
      ],
      rowRoute: (row) => '/sales/quotations/${intValue(row.toJson(), 'id')}',
    );
  }
}

class SalesOrderRegisterPage extends StatelessWidget {
  const SalesOrderRegisterPage({
    super.key,
    this.embedded = false,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final Map<String, String> queryParameters;

  static const _statusItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All status'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'confirmed', label: 'Confirmed'),
    AppDropdownItem(value: 'partially_delivered', label: 'Partially delivered'),
    AppDropdownItem(value: 'fully_delivered', label: 'Fully delivered'),
    AppDropdownItem(value: 'partially_invoiced', label: 'Partially invoiced'),
    AppDropdownItem(value: 'fully_invoiced', label: 'Fully invoiced'),
    AppDropdownItem(value: 'closed', label: 'Closed'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return _SalesRegisterShell<SalesOrderModel>(
      controllerName: 'SalesOrderRegisterController',
      title: 'Orders',
      embedded: embedded,
      queryParameters: queryParameters,
      loader: (service) => service.orders(
        filters: const {'per_page': 200, 'sort_by': 'order_date'},
      ),
      documentValueOf: (row) => stringValue(row.toJson(), 'order_no'),
      matches: (row, query, status) {
        final data = row.toJson();
        final rowStatus = stringValue(data, 'order_status');
        final searchText = [
          stringValue(data, 'order_no'),
          rowStatus,
          _salesCustomerName(data),
        ].join(' ').toLowerCase();
        final controller = Get.find<SalesRegisterController<SalesOrderModel>>(
          tag: persistentControllerTag('SalesOrderRegisterController'),
        );
        final filterCustomerId =
            controller.customFilters['customer_id'] as int?;
        final customerOk =
            filterCustomerId == null || row.customerPartyId == filterCustomerId;
        return (status.isEmpty || rowStatus == status) &&
            (query.isEmpty || searchText.contains(query)) &&
            customerOk;
      },
      dashboardMatches: (row, dashboardFilter) {
        switch (dashboardFilter.trim()) {
          case 'pending':
            final status = stringValue(
              row.toJson(),
              'order_status',
            ).trim().toLowerCase();
            return status.isNotEmpty &&
                !<String>{
                  'fully_delivered',
                  'fully_invoiced',
                  'closed',
                  'cancelled',
                }.contains(status);
          case 'due_today':
            final data = row.toJson();
            final raw =
                nullableStringValue(data, 'expected_delivery_date') ??
                nullableStringValue(data, 'delivery_date') ??
                nullableStringValue(data, 'order_date');
            final parsed = raw == null ? null : DateTime.tryParse(raw);
            if (parsed == null) {
              return false;
            }
            final now = DateTime.now();
            return parsed.year == now.year &&
                parsed.month == now.month &&
                parsed.day == now.day;
          case 'delayed':
            final status = stringValue(
              row.toJson(),
              'order_status',
            ).trim().toLowerCase();
            final isClosed = status.isEmpty ||
                const <String>{
                  'fully_delivered',
                  'fully_invoiced',
                  'closed',
                  'cancelled',
                }.contains(status);
            if (isClosed) return false;
            final raw = nullableStringValue(row.toJson(), 'expected_delivery_date');
            final parsed = raw == null ? null : DateTime.tryParse(raw);
            if (parsed == null) return false;
            final today = DateTime.now();
            final normalizedToday = DateTime(today.year, today.month, today.day);
            final normalizedDelivery = DateTime(parsed.year, parsed.month, parsed.day);
            return normalizedDelivery.isBefore(normalizedToday);
          default:
            return true;
        }
      },
      dateValueOf: (row) => nullableStringValue(row.toJson(), 'order_date'),
      emptyMessage:
          'No sales orders yet. Create an order from a quote or directly.',
      customFiltersBuilder: (context, controller) => _SalesRegisterFilters(
        controller: controller,
        statusItems: _statusItems,
        title: 'Find Orders',
        searchHint: 'Order no or customer name',
        customerItemsBuilder: _mappedCustomerItems,
      ),
      newRoute: '/sales/orders/new',
      newLabel: 'New order',
      searchHint: 'Search number or customer',
      statusItems: _statusItems,
      dashboardStatusForFilter: (dashboardFilter) {
        switch (dashboardFilter.trim()) {
          case 'pending':
          case 'due_today':
            return '';
          default:
            return '';
        }
      },
      columns: [
        PurchaseRegisterColumn(
          label: 'No',
          valueBuilder: (row) => stringValue(row.toJson(), 'order_no'),
        ),
        PurchaseRegisterColumn(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'order_date')),
        ),
        PurchaseRegisterColumn(
          label: 'Customer',
          flex: 3,
          valueBuilder: (row) => _salesCustomerName(row.toJson()),
        ),
        PurchaseRegisterColumn(
          label: 'Expected',
          valueBuilder: (row) => displayDate(
            nullableStringValue(row.toJson(), 'expected_delivery_date'),
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Status',
          valueBuilder: (row) =>
              salesStatusLabel(stringValue(row.toJson(), 'order_status')),
          widgetBuilder: (context, row) => salesStatusBadge(
            context,
            stringValue(row.toJson(), 'order_status'),
          ),
          detailBuilder: (row) => salesRegisterCancelReasonDetail(
            row.toJson(),
            statusKey: 'order_status',
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Total',
          alignRight: true,
          valueBuilder: (row) {
            final raw = row.toJson()['total_amount'];
            final amount = raw is num
                ? raw.toDouble()
                : double.tryParse(raw?.toString() ?? '');
            if (amount == null) return '-';
            return amount.toStringAsFixed(2);
          },
        ),
      ],
      rowRoute: (row) => '/sales/orders/${intValue(row.toJson(), 'id')}',
    );
  }
}

class SalesInvoiceRegisterPage extends StatelessWidget {
  const SalesInvoiceRegisterPage({
    super.key,
    this.embedded = false,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final Map<String, String> queryParameters;

  static const _statusItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All status'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'posted', label: 'Posted'),
    AppDropdownItem(value: 'overdue', label: 'Overdue'),
    AppDropdownItem(value: 'partially_paid', label: 'Partially paid'),
    AppDropdownItem(value: 'paid', label: 'Paid'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return _SalesRegisterShell<SalesInvoiceModel>(
      controllerName: 'SalesInvoiceRegisterController',
      title: 'Invoices',
      embedded: embedded,
      queryParameters: queryParameters,
      loader: (service) => service.invoices(
        filters: const {'per_page': 200, 'sort_by': 'invoice_date'},
      ),
      initialSort: 'balance_desc',
      documentValueOf: (row) => row.invoiceNo ?? '',
      balanceValueOf: (row) => row.balanceAmount,
      matches: (row, query, status) {
        final data = row.toJson();
        final rowStatus = row.invoiceStatus ?? '';
        final searchText = [
          row.invoiceNo ?? '',
          rowStatus,
          _salesCustomerName(data),
        ].join(' ').toLowerCase();

        final statusOk = status.isEmpty || rowStatus == status;
        final searchOk = query.isEmpty || searchText.contains(query);

        final controller = Get.find<SalesRegisterController<SalesInvoiceModel>>(
          tag: persistentControllerTag('SalesInvoiceRegisterController'),
        );

        final filterCustomerId =
            controller.customFilters['customer_id'] as int?;

        final customerOk =
            filterCustomerId == null || row.customerPartyId == filterCustomerId;

        return statusOk && searchOk && customerOk;
      },
      dashboardMatches: (row, dashboardFilter) {
        switch (dashboardFilter.trim()) {
          case 'open':
            final status = (row.invoiceStatus ?? '').trim().toLowerCase();
            return status.isNotEmpty &&
                !<String>{'paid', 'cancelled'}.contains(status);
          case 'overdue':
            final status = (row.invoiceStatus ?? '').trim().toLowerCase();
            if (status == 'paid' || status == 'cancelled') return false;
            final dueDateStr = row.dueDate;
            if (dueDateStr == null) return false;
            final dueDate = DateTime.tryParse(dueDateStr);
            if (dueDate == null) return false;
            final today = DateTime.now();
            final normalizedToday = DateTime(today.year, today.month, today.day);
            final normalizedDue = DateTime(dueDate.year, dueDate.month, dueDate.day);
            return normalizedDue.isBefore(normalizedToday);
          case 'draft':
            final status = (row.invoiceStatus ?? '').trim().toLowerCase();
            return status == 'draft';
          default:
            return true;
        }
      },
      dateValueOf: (row) => row.invoiceDate,
      emptyMessage: 'No invoices yet. Create an invoice for your customer.',
      newRoute: '/sales/invoices/new',
      newLabel: 'New invoice',
      searchHint: 'Search number or customer',
      statusItems: _statusItems,
      extraActionsBuilder: (context, controller) => <Widget>[
        SalesInvoiceExportButton(invoices: controller.filteredRows),
      ],
      customFiltersBuilder: (context, controller) => _SalesRegisterFilters(
        controller: controller,
        statusItems: _statusItems,
        title: 'Find Invoices',
        searchHint: 'Invoice no or customer name',
        customerItemsBuilder: _mappedCustomerItems,
        sortItems: _salesInvoiceRegisterSortItems,
      ),
      dashboardStatusForFilter: (dashboardFilter) {
        switch (dashboardFilter.trim()) {
          case 'open':
            return '';
          default:
            return '';
        }
      },
      columns: [
        PurchaseRegisterColumn(
          label: 'No',
          valueBuilder: (row) => row.invoiceNo ?? '',
        ),
        PurchaseRegisterColumn(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(row.invoiceDate.isEmpty ? null : row.invoiceDate),
        ),
        PurchaseRegisterColumn(
          label: 'Customer',
          flex: 3,
          valueBuilder: (row) => _salesCustomerName(row.toJson()),
        ),
        PurchaseRegisterColumn(
          label: 'Status',
          valueBuilder: (row) => salesStatusLabel(row.invoiceStatus),
          widgetBuilder: (context, row) => salesStatusBadge(
            context,
            row.invoiceStatus,
            dueDate: row.dueDate,
          ),
          detailBuilder: (row) => salesRegisterCancelReasonDetail(
            row.toJson(),
            statusKey: 'invoice_status',
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Total',
          alignRight: true,
          valueBuilder: (row) {
            final amount = row.totalAmount;
            if (amount == null) return '-';
            return amount.toStringAsFixed(2);
          },
        ),
        PurchaseRegisterColumn(
          label: 'Balance',
          alignRight: true,
          valueBuilder: (row) {
            final amount = row.balanceAmount;
            if (amount == null) return '-';
            return amount.toStringAsFixed(2);
          },
        ),
      ],
      rowRoute: (row) => '/sales/invoices/${intValue(row.toJson(), 'id')}',
    );
  }
}

class SalesDeliveryRegisterPage extends StatelessWidget {
  const SalesDeliveryRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  static const _statusItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All status'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'posted', label: 'Posted'),
    AppDropdownItem(value: 'partially_invoiced', label: 'Partially invoiced'),
    AppDropdownItem(value: 'fully_invoiced', label: 'Fully invoiced'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return _SalesRegisterShell<SalesDeliveryModel>(
      controllerName: 'SalesDeliveryRegisterController',
      title: 'Deliveries',
      embedded: embedded,
      loader: (service) => service.deliveries(
        filters: const {'per_page': 200, 'sort_by': 'delivery_date'},
      ),
      documentValueOf: (row) => stringValue(row.toJson(), 'delivery_no'),
      matches: (row, query, status) {
        final data = row.toJson();
        final rowStatus = stringValue(data, 'delivery_status');
        final searchText = [
          stringValue(data, 'delivery_no'),
          rowStatus,
          _salesCustomerName(data),
        ].join(' ').toLowerCase();
        final controller =
            Get.find<SalesRegisterController<SalesDeliveryModel>>(
              tag: persistentControllerTag('SalesDeliveryRegisterController'),
            );
        final filterCustomerId =
            controller.customFilters['customer_id'] as int?;
        final customerOk =
            filterCustomerId == null || row.customerPartyId == filterCustomerId;
        return (status.isEmpty || rowStatus == status) &&
            (query.isEmpty || searchText.contains(query)) &&
            customerOk;
      },
      dashboardMatches: (row, dashboardFilter) => true,
      dateValueOf: (row) => nullableStringValue(row.toJson(), 'delivery_date'),
      emptyMessage: 'No deliveries yet.',
      customFiltersBuilder: (context, controller) => _SalesRegisterFilters(
        controller: controller,
        statusItems: _statusItems,
        title: 'Find Deliveries',
        searchHint: 'Delivery no or customer name',
        customerItemsBuilder: _mappedCustomerItems,
      ),
      newRoute: '/sales/deliveries/new',
      newLabel: 'New delivery',
      searchHint: 'Search number or customer',
      statusItems: _statusItems,
      columns: [
        PurchaseRegisterColumn(
          label: 'No',
          valueBuilder: (row) => stringValue(row.toJson(), 'delivery_no'),
        ),
        PurchaseRegisterColumn(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'delivery_date')),
        ),
        PurchaseRegisterColumn(
          label: 'Customer',
          flex: 3,
          valueBuilder: (row) => _salesCustomerName(row.toJson()),
        ),
        PurchaseRegisterColumn(
          label: 'Status',
          valueBuilder: (row) => salesStatusLabel(row.deliveryStatus),
          widgetBuilder: (context, row) =>
              salesStatusBadge(context, row.deliveryStatus),
          detailBuilder: (row) => salesRegisterCancelReasonDetail(
            row.toJson(),
            statusKey: 'delivery_status',
          ),
        ),
      ],
      rowRoute: (row) => '/sales/deliveries/${intValue(row.toJson(), 'id')}',
    );
  }
}

class SalesReceiptRegisterPage extends StatelessWidget {
  const SalesReceiptRegisterPage({
    super.key,
    this.embedded = false,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final Map<String, String> queryParameters;

  static const _statusItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All status'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'posted', label: 'Posted'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return _SalesRegisterShell<SalesReceiptModel>(
      controllerName: 'SalesReceiptRegisterController',
      title: 'Receipts',
      embedded: embedded,
      queryParameters: queryParameters,
      loader: (service) => service.receipts(
        filters: const {'per_page': 200, 'sort_by': 'receipt_date'},
      ),
      documentValueOf: (row) => stringValue(row.toJson(), 'receipt_no'),
      matches: (row, query, status) {
        final data = row.toJson();
        final rowStatus = stringValue(data, 'receipt_status');
        final searchText = [
          stringValue(data, 'receipt_no'),
          rowStatus,
          _salesCustomerName(data),
        ].join(' ').toLowerCase();
        final controller = Get.find<SalesRegisterController<SalesReceiptModel>>(
          tag: persistentControllerTag('SalesReceiptRegisterController'),
        );
        final filterCustomerId =
            controller.customFilters['customer_id'] as int?;
        final customerOk =
            filterCustomerId == null || row.customerPartyId == filterCustomerId;
        return (status.isEmpty || rowStatus == status) &&
            (query.isEmpty || searchText.contains(query)) &&
            customerOk;
      },
      dashboardMatches: (row, dashboardFilter) {
        switch (dashboardFilter.trim()) {
          case 'posted':
            final status = stringValue(
              row.toJson(),
              'receipt_status',
            ).trim().toLowerCase();
            return status == 'posted';
          default:
            return true;
        }
      },
      dateValueOf: (row) => nullableStringValue(row.toJson(), 'receipt_date'),
      emptyMessage: 'No receipts yet.',
      customFiltersBuilder: (context, controller) => _SalesRegisterFilters(
        controller: controller,
        statusItems: _statusItems,
        title: 'Find Receipts',
        searchHint: 'Receipt no or customer name',
        customerItemsBuilder: _mappedCustomerItems,
      ),
      newRoute: '/sales/receipts/new',
      newLabel: 'New receipt',
      searchHint: 'Search receipts',
      statusItems: _statusItems,
      dashboardStatusForFilter: (dashboardFilter) {
        switch (dashboardFilter.trim()) {
          case 'posted':
            return '';
          default:
            return '';
        }
      },
      columns: [
        PurchaseRegisterColumn(
          label: 'No',
          valueBuilder: (row) => stringValue(row.toJson(), 'receipt_no'),
        ),
        PurchaseRegisterColumn(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'receipt_date')),
        ),
        PurchaseRegisterColumn(
          label: 'Customer',
          flex: 3,
          valueBuilder: (row) => _salesCustomerName(row.toJson()),
        ),
        PurchaseRegisterColumn(
          label: 'Status',
          valueBuilder: (row) =>
              salesStatusLabel(stringValue(row.toJson(), 'receipt_status')),
          widgetBuilder: (context, row) => salesStatusBadge(
            context,
            stringValue(row.toJson(), 'receipt_status'),
          ),
          detailBuilder: (row) => salesRegisterCancelReasonDetail(
            row.toJson(),
            statusKey: 'receipt_status',
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Amount',
          alignRight: true,
          valueBuilder: (row) {
            final raw = row.toJson()['paid_amount'];
            final amount = raw is num
                ? raw.toDouble()
                : double.tryParse(raw?.toString() ?? '');
            if (amount == null) return '-';
            return amount.toStringAsFixed(2);
          },
        ),
      ],
      rowRoute: (row) => '/sales/receipts/${intValue(row.toJson(), 'id')}',
    );
  }
}

class SalesReturnRegisterPage extends StatelessWidget {
  const SalesReturnRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  static const _statusItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All status'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'posted', label: 'Posted'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return _SalesRegisterShell<SalesReturnModel>(
      controllerName: 'SalesReturnRegisterController',
      title: 'Returns',
      embedded: embedded,
      loader: (service) => service.returns(
        filters: const {'per_page': 200, 'sort_by': 'return_date'},
      ),
      documentValueOf: (row) => stringValue(row.toJson(), 'return_no'),
      matches: (row, query, status) {
        final data = row.toJson();
        final rowStatus = stringValue(data, 'return_status');
        final searchText = [
          stringValue(data, 'return_no'),
          rowStatus,
          _salesCustomerName(data),
        ].join(' ').toLowerCase();
        final controller = Get.find<SalesRegisterController<SalesReturnModel>>(
          tag: persistentControllerTag('SalesReturnRegisterController'),
        );
        final filterCustomerId =
            controller.customFilters['customer_id'] as int?;
        final customerOk =
            filterCustomerId == null || row.customerPartyId == filterCustomerId;
        return (status.isEmpty || rowStatus == status) &&
            (query.isEmpty || searchText.contains(query)) &&
            customerOk;
      },
      dashboardMatches: (row, dashboardFilter) => true,
      dateValueOf: (row) => nullableStringValue(row.toJson(), 'return_date'),
      emptyMessage: 'No returns yet.',
      customFiltersBuilder: (context, controller) => _SalesRegisterFilters(
        controller: controller,
        statusItems: _statusItems,
        title: 'Find Returns',
        searchHint: 'Return no or customer name',
        customerItemsBuilder: _mappedCustomerItems,
      ),
      newRoute: '/sales/returns/new',
      newLabel: 'New return',
      searchHint: 'Search returns',
      statusItems: _statusItems,
      columns: [
        PurchaseRegisterColumn(
          label: 'No',
          valueBuilder: (row) => stringValue(row.toJson(), 'return_no'),
        ),
        PurchaseRegisterColumn(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'return_date')),
        ),
        PurchaseRegisterColumn(
          label: 'Customer',
          flex: 3,
          valueBuilder: (row) => _salesCustomerName(row.toJson()),
        ),
        PurchaseRegisterColumn(
          label: 'Status',
          valueBuilder: (row) =>
              salesStatusLabel(stringValue(row.toJson(), 'return_status')),
          widgetBuilder: (context, row) => salesStatusBadge(
            context,
            stringValue(row.toJson(), 'return_status'),
          ),
          detailBuilder: (row) => salesRegisterCancelReasonDetail(
            row.toJson(),
            statusKey: 'return_status',
          ),
        ),
      ],
      rowRoute: (row) => '/sales/returns/${intValue(row.toJson(), 'id')}',
    );
  }
}
