import '../../screen.dart';

typedef SalesRegisterLoader<T> = Future<dynamic> Function(SalesService service);
typedef SalesRegisterMatcher<T> =
    bool Function(T row, String query, String status);
typedef SalesRegisterDashboardMatcher<T> =
    bool Function(T row, String dashboardFilter);

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
  });

  final SalesRegisterLoader<T> loader;
  final SalesRegisterMatcher<T> matches;
  final SalesRegisterDashboardMatcher<T> dashboardMatches;
  final SalesService _service = SalesService();
  final TextEditingController searchController = TextEditingController();

  bool loading = true;
  String? error;
  String status = '';
  String dashboardFilter = '';
  List<T> rows = <T>[];

  List<T> get filteredRows {
    final query = searchController.text.trim().toLowerCase();
    return rows
        .where(
          (row) =>
              matches(row, query, status) &&
              dashboardMatches(row, dashboardFilter),
        )
        .toList(growable: false);
  }

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(update);
    unawaited(load());
  }

  @override
  void onClose() {
    searchController
      ..removeListener(update)
      ..dispose();
    super.onClose();
  }

  void setStatus(String value) {
    status = value;
    update();
  }

  void applyDashboardFilter(String value, {String statusOverride = ''}) {
    dashboardFilter = value.trim();
    status = statusOverride;
    searchController.clear();
    update();
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
    required this.emptyMessage,
    required this.newRoute,
    required this.newLabel,
    required this.searchHint,
    required this.statusItems,
    required this.columns,
    required this.rowRoute,
    this.queryParameters = const <String, String>{},
    this.dashboardStatusForFilter,
  });

  final String controllerName;
  final String title;
  final bool embedded;
  final SalesRegisterLoader<T> loader;
  final SalesRegisterMatcher<T> matches;
  final SalesRegisterDashboardMatcher<T> dashboardMatches;
  final String emptyMessage;
  final String newRoute;
  final String newLabel;
  final String searchHint;
  final List<AppDropdownItem<String>> statusItems;
  final List<PurchaseRegisterColumn<T>> columns;
  final String Function(T row) rowRoute;
  final Map<String, String> queryParameters;
  final String Function(String dashboardFilter)? dashboardStatusForFilter;

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
        return PurchaseRegisterPage<T>(
          title: widget.title,
          embedded: widget.embedded,
          loading: controller.loading,
          errorMessage: controller.error,
          onRetry: controller.load,
          emptyMessage: widget.emptyMessage,
          actions: [
            AdaptiveShellActionButton(
              onPressed: () => _openSalesShellRoute(context, widget.newRoute),
              icon: Icons.add_outlined,
              label: widget.newLabel,
            ),
          ],
          filters: _SalesRegisterFilters(
            searchController: controller.searchController,
            searchHint: widget.searchHint,
            status: controller.status,
            statusItems: widget.statusItems,
            onStatusChanged: (value) => controller.setStatus(value ?? ''),
          ),
          rows: controller.filteredRows,
          columns: widget.columns,
          onRowTap: (row) =>
              _openSalesShellRoute(context, widget.rowRoute(row)),
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
      matches: (row, query, status) {
        final data = row.toJson();
        final rowStatus = stringValue(data, 'quotation_status');
        final searchText = [
          stringValue(data, 'quotation_no'),
          rowStatus,
          _salesCustomerName(data),
        ].join(' ').toLowerCase();
        return (status.isEmpty || rowStatus == status) &&
            (query.isEmpty || searchText.contains(query));
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
      emptyMessage: 'No quotations yet. Create a quote for your customer.',
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
          valueBuilder: (row) => stringValue(row.toJson(), 'quotation_status'),
        ),
        PurchaseRegisterColumn(
          label: 'Total',
          valueBuilder: (row) => stringValue(row.toJson(), 'total_amount'),
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
      matches: (row, query, status) {
        final data = row.toJson();
        final rowStatus = stringValue(data, 'order_status');
        final searchText = [
          stringValue(data, 'order_no'),
          rowStatus,
          _salesCustomerName(data),
        ].join(' ').toLowerCase();
        return (status.isEmpty || rowStatus == status) &&
            (query.isEmpty || searchText.contains(query));
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
          default:
            return true;
        }
      },
      emptyMessage:
          'No sales orders yet. Create an order from a quote or directly.',
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
          valueBuilder: (row) => stringValue(row.toJson(), 'order_status'),
        ),
        PurchaseRegisterColumn(
          label: 'Total',
          valueBuilder: (row) => stringValue(row.toJson(), 'total_amount'),
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
      matches: (row, query, status) {
        final data = row.toJson();
        final rowStatus = row.invoiceStatus ?? '';
        final searchText = [
          row.invoiceNo ?? '',
          rowStatus,
          _salesCustomerName(data),
        ].join(' ').toLowerCase();
        return (status.isEmpty || rowStatus == status) &&
            (query.isEmpty || searchText.contains(query));
      },
      dashboardMatches: (row, dashboardFilter) {
        switch (dashboardFilter.trim()) {
          case 'open':
            final status = (row.invoiceStatus ?? '').trim().toLowerCase();
            return status.isNotEmpty &&
                !<String>{'paid', 'cancelled'}.contains(status);
          default:
            return true;
        }
      },
      emptyMessage: 'No invoices yet. Create an invoice for your customer.',
      newRoute: '/sales/invoices/new',
      newLabel: 'New invoice',
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
          valueBuilder: (row) => row.invoiceStatus ?? '',
        ),
        PurchaseRegisterColumn(
          label: 'Total',
          valueBuilder: (row) => row.totalAmount?.toString() ?? '',
        ),
        PurchaseRegisterColumn(
          label: 'Balance',
          valueBuilder: (row) => row.balanceAmount?.toString() ?? '',
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
      matches: (row, query, status) {
        final data = row.toJson();
        final rowStatus = stringValue(data, 'delivery_status');
        final searchText = [
          stringValue(data, 'delivery_no'),
          rowStatus,
          _salesCustomerName(data),
        ].join(' ').toLowerCase();
        return (status.isEmpty || rowStatus == status) &&
            (query.isEmpty || searchText.contains(query));
      },
      dashboardMatches: (row, dashboardFilter) => true,
      emptyMessage: 'No deliveries yet.',
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
          valueBuilder: (row) => stringValue(row.toJson(), 'delivery_status'),
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
      matches: (row, query, status) {
        final data = row.toJson();
        final rowStatus = stringValue(data, 'receipt_status');
        final searchText = [
          stringValue(data, 'receipt_no'),
          rowStatus,
          _salesCustomerName(data),
        ].join(' ').toLowerCase();
        return (status.isEmpty || rowStatus == status) &&
            (query.isEmpty || searchText.contains(query));
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
      emptyMessage: 'No receipts yet.',
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
          label: 'Amount',
          valueBuilder: (row) => stringValue(row.toJson(), 'paid_amount'),
        ),
        PurchaseRegisterColumn(
          label: 'Status',
          valueBuilder: (row) => stringValue(row.toJson(), 'receipt_status'),
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
      matches: (row, query, status) {
        final data = row.toJson();
        final rowStatus = stringValue(data, 'return_status');
        final searchText = [
          stringValue(data, 'return_no'),
          rowStatus,
          _salesCustomerName(data),
        ].join(' ').toLowerCase();
        return (status.isEmpty || rowStatus == status) &&
            (query.isEmpty || searchText.contains(query));
      },
      dashboardMatches: (row, dashboardFilter) => true,
      emptyMessage: 'No returns yet.',
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
          valueBuilder: (row) => stringValue(row.toJson(), 'return_status'),
        ),
      ],
      rowRoute: (row) => '/sales/returns/${intValue(row.toJson(), 'id')}',
    );
  }
}

class _SalesRegisterFilters extends StatelessWidget {
  const _SalesRegisterFilters({
    required this.searchController,
    required this.searchHint,
    required this.status,
    required this.statusItems,
    required this.onStatusChanged,
  });

  final TextEditingController searchController;
  final String searchHint;
  final String status;
  final List<AppDropdownItem<String>> statusItems;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppUiConstants.spacingMd),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final children = <Widget>[
            AppFormTextField(
              labelText: searchHint,
              controller: searchController,
              prefixIcon: const Icon(Icons.search_outlined),
            ),
            AppDropdownField<String>.fromMapped(
              labelText: 'Status',
              mappedItems: statusItems,
              initialValue: status,
              onChanged: onStatusChanged,
            ),
          ];
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children
                  .map(
                    (child) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppUiConstants.spacingSm,
                      ),
                      child: child,
                    ),
                  )
                  .toList(growable: false),
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: children[0]),
              const SizedBox(width: AppUiConstants.spacingSm),
              Expanded(child: children[1]),
            ],
          );
        },
      ),
    );
  }
}
