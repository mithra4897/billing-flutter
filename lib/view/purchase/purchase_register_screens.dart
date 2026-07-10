import '../../screen.dart';
import '../../controller/purchase/purchase_module_refresh_controller.dart';

typedef PurchaseRegisterLoader<T> =
    Future<dynamic> Function(PurchaseService service);
typedef PurchaseRegisterMatcher<T> =
    bool Function(T row, String query, Set<String> statuses);
typedef PurchaseRegisterDashboardMatcher<T> =
    bool Function(T row, String dashboardFilter);
typedef PurchaseRegisterDateValue<T> = String? Function(T row);
typedef PurchaseRegisterDocumentValue<T> = String Function(T row);
typedef PurchaseRegisterBalanceValue<T> = double? Function(T row);

Set<T> _purchaseSelectedSet<T>(dynamic value) {
  if (value is Set<T>) {
    return value;
  }
  if (value is Set) {
    return value.whereType<T>().toSet();
  }
  return <T>{};
}

bool _purchaseMatchesSelectedValue<T>(T? value, Set<T> selectedValues) {
  if (selectedValues.isEmpty) {
    return true;
  }
  return value != null && selectedValues.contains(value);
}

bool _purchaseMatchesSelectedStatus(
  String? value,
  Set<String> selectedStatuses,
) {
  if (selectedStatuses.isEmpty) {
    return true;
  }
  final normalized = (value ?? '').trim().toLowerCase();
  return normalized.isNotEmpty && selectedStatuses.contains(normalized);
}

const _purchaseRegisterSortItems = <AppDropdownItem<String>>[
  AppDropdownItem(value: '', label: 'Default order'),
  AppDropdownItem(value: 'date_desc', label: 'Newest first'),
  AppDropdownItem(value: 'date_asc', label: 'Oldest first'),
  AppDropdownItem(value: 'doc_asc', label: 'Number A-Z'),
  AppDropdownItem(value: 'doc_desc', label: 'Number Z-A'),
];

const _purchaseInvoiceRegisterSortItems = <AppDropdownItem<String>>[
  AppDropdownItem(value: '', label: 'Default order'),
  AppDropdownItem(value: 'date_desc', label: 'Newest first'),
  AppDropdownItem(value: 'date_asc', label: 'Oldest first'),
  AppDropdownItem(value: 'doc_asc', label: 'Number A-Z'),
  AppDropdownItem(value: 'doc_desc', label: 'Number Z-A'),
  AppDropdownItem(value: 'balance_desc', label: 'High outstanding to low'),
];

int _comparePurchaseRegisterStrings(String? left, String? right) {
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

void _openShellRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}

String _nestedName(
  Map<String, dynamic> data,
  String flatKey,
  String relationKey,
  String nestedKey,
) {
  final flat = stringValue(data, flatKey);
  if (flat.isNotEmpty) {
    return flat;
  }
  final relation = data[relationKey];
  if (relation is Map<String, dynamic>) {
    return stringValue(relation, nestedKey);
  }
  return '';
}

class PurchaseListRegisterController<T> extends GetxController {
  PurchaseListRegisterController({
    required this.loader,
    required this.matches,
    required this.dashboardMatches,
    required this.dateValueOf,
    required this.documentValueOf,
    this.balanceValueOf,
  });

  final PurchaseRegisterLoader<T> loader;
  final PurchaseRegisterMatcher<T> matches;
  final PurchaseRegisterDashboardMatcher<T> dashboardMatches;
  final PurchaseRegisterDateValue<T> dateValueOf;
  final PurchaseRegisterDocumentValue<T> documentValueOf;
  final PurchaseRegisterBalanceValue<T>? balanceValueOf;
  final PurchaseService _service = PurchaseService();
  final PurchaseModuleRefreshController _refreshController =
      PurchaseModuleRefreshController.ensureRegistered();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController dateFromController = TextEditingController();
  final TextEditingController dateToController = TextEditingController();

  bool loading = true;
  String? error;
  Set<String> selectedStatuses = <String>{};
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
              matches(row, query, selectedStatuses) &&
              dashboardMatches(row, dashboardFilter),
        )
        .toList(growable: false);
    filtered.sort(_compareRows);
    return filtered;
  }

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(update);
    dateFromController.addListener(update);
    dateToController.addListener(update);
    _refreshWorker = ever<PurchaseModuleRefreshEvent?>(
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
    searchController
      ..removeListener(update)
      ..dispose();
    dateFromController
      ..removeListener(update)
      ..dispose();
    dateToController
      ..removeListener(update)
      ..dispose();
    super.onClose();
  }

  void setStatuses(Set<String> values) {
    selectedStatuses = Set<String>.from(values);
    update();
  }

  void setSort(String value) {
    sort = value;
    update();
  }

  void applyDashboardFilter(String value, {String statusOverride = ''}) {
    dashboardFilter = value.trim();
    selectedStatuses = statusOverride
        .split(',')
        .map((status) => status.trim().toLowerCase())
        .where((status) => status.isNotEmpty)
        .toSet();
    searchController.clear();
    dateFromController.clear();
    dateToController.clear();
    update();
  }

  void setCustomFilter(String key, dynamic value) {
    if (value == null) {
      customFilters.remove(key);
    } else if (value is Set && value.isEmpty) {
      customFilters.remove(key);
    } else {
      customFilters[key] = value;
    }
    update();
  }

  int _compareRows(T left, T right) {
    switch (sort) {
      case 'date_desc':
        return _comparePurchaseRegisterStrings(
          dateValueOf(right),
          dateValueOf(left),
        );
      case 'date_asc':
        return _comparePurchaseRegisterStrings(
          dateValueOf(left),
          dateValueOf(right),
        );
      case 'doc_asc':
        return _comparePurchaseRegisterStrings(
          documentValueOf(left),
          documentValueOf(right),
        );
      case 'doc_desc':
        return _comparePurchaseRegisterStrings(
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

class _PurchaseRegisterShell<T> extends StatefulWidget {
  const _PurchaseRegisterShell({
    required this.controllerName,
    required this.title,
    required this.embedded,
    required this.loader,
    required this.matches,
    required this.dashboardMatches,
    required this.dateValueOf,
    required this.documentValueOf,
    this.balanceValueOf,
    required this.emptyMessage,
    required this.newRoute,
    required this.newLabel,
    required this.searchHint,
    required this.statusItems,
    required this.columns,
    required this.rowRoute,
    this.queryParameters = const <String, String>{},
    this.dashboardStatusForFilter,
    this.customFiltersBuilder,
    this.extraActionsBuilder,
    this.filterFieldsBuilder,
    this.filterTrailingActionsBuilder,
    this.filtersMaxWidth,
    this.footerBuilder,
  });

  final String controllerName;
  final String title;
  final bool embedded;
  final PurchaseRegisterLoader<T> loader;
  final PurchaseRegisterMatcher<T> matches;
  final PurchaseRegisterDashboardMatcher<T> dashboardMatches;
  final PurchaseRegisterDateValue<T> dateValueOf;
  final PurchaseRegisterDocumentValue<T> documentValueOf;
  final PurchaseRegisterBalanceValue<T>? balanceValueOf;
  final String emptyMessage;
  final String newRoute;
  final String newLabel;
  final String searchHint;
  final List<AppDropdownItem<String>> statusItems;
  final List<PurchaseRegisterColumn<T>> columns;
  final String Function(T row) rowRoute;
  final Map<String, String> queryParameters;
  final String Function(String dashboardFilter)? dashboardStatusForFilter;
  final Widget Function(
    BuildContext context,
    PurchaseListRegisterController<T> controller,
  )?
  customFiltersBuilder;
  final List<Widget> Function(
    BuildContext context,
    PurchaseListRegisterController<T> controller,
  )?
  extraActionsBuilder;
  final List<Widget> Function(
    BuildContext context,
    PurchaseListRegisterController<T> controller,
  )?
  filterFieldsBuilder;
  final List<Widget> Function(
    BuildContext context,
    PurchaseListRegisterController<T> controller,
  )?
  filterTrailingActionsBuilder;
  final double? filtersMaxWidth;
  final Widget Function(
    BuildContext context,
    PurchaseListRegisterController<T> controller,
  )?
  footerBuilder;

  @override
  State<_PurchaseRegisterShell<T>> createState() =>
      _PurchaseRegisterShellState<T>();
}

class _PurchaseRegisterShellState<T> extends State<_PurchaseRegisterShell<T>> {
  late final String _controllerTag;

  String _dashboardFilterValue() =>
      (widget.queryParameters['dashboard_filter'] ?? '').trim();

  String _queryDateValue(String key) =>
      normalizeDateValue(widget.queryParameters[key]);

  String _querySortValue() => (widget.queryParameters['sort'] ?? '').trim();

  void _applyDashboardFilter(PurchaseListRegisterController<T> controller) {
    final dashboardFilter = _dashboardFilterValue();
    final statusOverride =
        widget.dashboardStatusForFilter?.call(dashboardFilter) ?? '';
    controller.applyDashboardFilter(
      dashboardFilter,
      statusOverride: statusOverride,
    );
    final sort = _querySortValue();
    if (sort.isNotEmpty && controller.sort != sort) {
      controller.setSort(sort);
    }
    final dateFrom = _queryDateValue('date_from');
    final dateTo = _queryDateValue('date_to');
    if (controller.dateFromController.text != dateFrom) {
      controller.dateFromController.text = dateFrom;
    }
    if (controller.dateToController.text != dateTo) {
      controller.dateToController.text = dateTo;
    }
  }

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(widget.controllerName);
    if (!Get.isRegistered<PurchaseListRegisterController<T>>(
      tag: _controllerTag,
    )) {
      Get.put(
        PurchaseListRegisterController<T>(
          loader: widget.loader,
          matches: widget.matches,
          dashboardMatches: widget.dashboardMatches,
          dateValueOf: widget.dateValueOf,
          documentValueOf: widget.documentValueOf,
          balanceValueOf: widget.balanceValueOf,
        ),
        tag: _controllerTag,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !Get.isRegistered<PurchaseListRegisterController<T>>(
            tag: _controllerTag,
          )) {
        return;
      }
      _applyDashboardFilter(
        Get.find<PurchaseListRegisterController<T>>(tag: _controllerTag),
      );
    });
  }

  @override
  void didUpdateWidget(covariant _PurchaseRegisterShell<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(oldWidget.queryParameters, widget.queryParameters)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            !Get.isRegistered<PurchaseListRegisterController<T>>(
              tag: _controllerTag,
            )) {
          return;
        }
        _applyDashboardFilter(
          Get.find<PurchaseListRegisterController<T>>(tag: _controllerTag),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PurchaseListRegisterController<T>>(
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
            if (widget.extraActionsBuilder != null)
              ...widget.extraActionsBuilder!(context, controller),
            AdaptiveShellActionButton(
              onPressed: () => _openShellRoute(context, widget.newRoute),
              icon: Icons.add_outlined,
              label: widget.newLabel,
            ),
          ],
          filters:
              widget.customFiltersBuilder?.call(context, controller) ??
              _RegisterFilters(
                searchController: controller.searchController,
                searchHint: widget.searchHint,
                filterFields: widget.filterFieldsBuilder?.call(
                  context,
                  controller,
                ),
                trailingActions: widget.filterTrailingActionsBuilder?.call(
                  context,
                  controller,
                ),
                maxWidth: widget.filtersMaxWidth,
                selectedStatuses: controller.selectedStatuses,
                statusItems: widget.statusItems,
                onStatusChanged: controller.setStatuses,
              ),
          rows: controller.filteredRows,
          columns: widget.columns,
          onRowTap: (row) => _openShellRoute(context, widget.rowRoute(row)),
          footer: widget.footerBuilder?.call(context, controller),
        );
      },
    );
  }
}

class _PurchaseRegisterFooterCell {
  const _PurchaseRegisterFooterCell({
    required this.flex,
    this.text = '',
    this.alignRight = false,
  });

  final int flex;
  final String text;
  final bool alignRight;
}

class _PurchaseRegisterSummaryFooter extends StatelessWidget {
  const _PurchaseRegisterSummaryFooter({required this.cells});

  final List<_PurchaseRegisterFooterCell> cells;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppUiConstants.spacingSm,
        vertical: AppUiConstants.spacingMd,
      ),
      decoration: BoxDecoration(
        color: appTheme.subtleFill.withValues(alpha: 0.55),
        border: const Border(
          top: BorderSide(color: Color(0x11000000)),
          bottom: BorderSide(color: Color(0x11000000)),
        ),
      ),
      child: Row(
        children: cells
            .map(
              (cell) => Expanded(
                flex: cell.flex,
                child: Text(
                  cell.text,
                  textAlign: cell.alignRight ? TextAlign.right : TextAlign.left,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

double _purchaseRequisitionEstimatedTotal(PurchaseRequisitionModel row) {
  return row.lines.fold<double>(
    0,
    (sum, line) => sum + (line.estimatedAmount ?? 0),
  );
}

double _purchaseReceiptTotal(PurchaseReceiptModel row) {
  return row.lines.fold<double>(0, (sum, line) => sum + (line.amount ?? 0));
}

class PurchaseRequisitionRegisterPage extends StatelessWidget {
  const PurchaseRequisitionRegisterPage({
    super.key,
    this.embedded = false,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final Map<String, String> queryParameters;

  static const _statusItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All Status'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'approved', label: 'Approved'),
    AppDropdownItem(value: 'partially_ordered', label: 'Partially Ordered'),
    AppDropdownItem(value: 'fully_ordered', label: 'Fully Ordered'),
    AppDropdownItem(value: 'closed', label: 'Closed'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return _PurchaseRegisterShell<PurchaseRequisitionModel>(
      controllerName: 'PurchaseRequisitionRegisterController',
      title: 'Purchase Requisitions',
      embedded: embedded,
      queryParameters: queryParameters,
      loader: (service) => service.requisitions(
        filters: {'per_page': 200, 'sort_by': 'requisition_date'},
      ),
      dashboardMatches: (row, dashboardFilter) {
        switch (dashboardFilter.trim()) {
          case 'pending_request':
            final status = stringValue(
              row.toJson(),
              'requisition_status',
            ).trim().toLowerCase();
            return status.isNotEmpty &&
                !<String>{'approved', 'closed', 'cancelled'}.contains(status);
          default:
            return true;
        }
      },
      dateValueOf: (row) =>
          nullableStringValue(row.toJson(), 'requisition_date'),
      documentValueOf: (row) => stringValue(row.toJson(), 'requisition_no'),
      matches: (row, query, statuses) {
        final controller =
            Get.find<PurchaseListRegisterController<PurchaseRequisitionModel>>(
              tag: persistentControllerTag(
                'PurchaseRequisitionRegisterController',
              ),
            );
        final data = row.toJson();
        final statusOk = _purchaseMatchesSelectedStatus(
          stringValue(data, 'requisition_status'),
          statuses,
        );
        final searchOk =
            query.isEmpty ||
            [
              stringValue(data, 'requisition_no'),
              purchaseStatusLabel(
                nullableStringValue(data, 'requisition_status'),
              ),
              stringValue(data, 'purpose'),
              stringValue(data, 'department'),
            ].join(' ').toLowerCase().contains(query);
        final dateOk = matchesDateValueRange(
          nullableStringValue(data, 'requisition_date'),
          fromValue: controller.dateFromController.text,
          toValue: controller.dateToController.text,
        );
        return statusOk && searchOk && dateOk;
      },
      emptyMessage: 'No purchase requisitions found.',
      customFiltersBuilder: (context, controller) => _PurchaseRegisterFilters(
        controller: controller,
        statusItems: _statusItems,
        title: 'Find Requisitions',
        searchHint: 'Requisition no, purpose, department',
      ),
      newRoute: '/purchase/requisitions/new',
      newLabel: 'New Requisition',
      searchHint: 'Search requisitions',
      statusItems: _statusItems,
      dashboardStatusForFilter: (dashboardFilter) {
        switch (dashboardFilter.trim()) {
          case 'pending_request':
            return 'draft';
          default:
            return '';
        }
      },
      columns: [
        PurchaseRegisterColumn(
          label: 'No',
          valueBuilder: (row) => stringValue(row.toJson(), 'requisition_no'),
        ),
        PurchaseRegisterColumn(
          label: 'Date',
          valueBuilder: (row) => displayDate(
            nullableStringValue(row.toJson(), 'requisition_date'),
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Department',
          valueBuilder: (row) => stringValue(row.toJson(), 'department'),
        ),
        PurchaseRegisterColumn(
          label: 'Purpose',
          flex: 3,
          valueBuilder: (row) => stringValue(row.toJson(), 'purpose'),
        ),
        PurchaseRegisterColumn(
          label: 'Status',
          valueBuilder: (row) => purchaseStatusLabel(
            nullableStringValue(row.toJson(), 'requisition_status'),
          ),
          widgetBuilder: (context, row) => purchaseStatusBadge(
            context,
            nullableStringValue(row.toJson(), 'requisition_status'),
          ),
          detailBuilder: (row) => purchaseRegisterCancelReasonDetail(
            row.toJson(),
            statusKey: 'requisition_status',
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Estimated Total',
          alignRight: true,
          valueBuilder: (row) =>
              formatAmount(_purchaseRequisitionEstimatedTotal(row)),
          showPlaceholderWhenEmpty: false,
        ),
      ],
      footerBuilder: (context, controller) {
        final rows = controller.filteredRows;
        final estimatedTotal = rows.fold<double>(
          0,
          (sum, row) => sum + _purchaseRequisitionEstimatedTotal(row),
        );
        return _PurchaseRegisterSummaryFooter(
          cells: <_PurchaseRegisterFooterCell>[
            const _PurchaseRegisterFooterCell(flex: 2, text: 'Total'),
            const _PurchaseRegisterFooterCell(flex: 2),
            const _PurchaseRegisterFooterCell(flex: 2),
            const _PurchaseRegisterFooterCell(flex: 3),
            const _PurchaseRegisterFooterCell(flex: 2),
            _PurchaseRegisterFooterCell(
              flex: 2,
              text: formatAmount(estimatedTotal),
              alignRight: true,
            ),
          ],
        );
      },
      rowRoute: (row) =>
          '/purchase/requisitions/${intValue(row.toJson(), 'id')}',
    );
  }
}

class PurchaseOrderRegisterPage extends StatelessWidget {
  const PurchaseOrderRegisterPage({
    super.key,
    this.embedded = false,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final Map<String, String> queryParameters;

  static const _statusItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All Status'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'confirmed', label: 'Confirmed'),
    AppDropdownItem(value: 'partially_received', label: 'Partially Received'),
    AppDropdownItem(value: 'fully_received', label: 'Fully Received'),
    AppDropdownItem(value: 'partially_invoiced', label: 'Partially Invoiced'),
    AppDropdownItem(value: 'fully_invoiced', label: 'Fully Invoiced'),
    AppDropdownItem(value: 'closed', label: 'Closed'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return _PurchaseRegisterShell<PurchaseOrderModel>(
      controllerName: 'PurchaseOrderRegisterController',
      title: 'Purchase Orders',
      embedded: embedded,
      queryParameters: queryParameters,
      loader: (service) =>
          service.ordersAll(filters: {'sort_by': 'order_date'}),
      dashboardMatches: (row, dashboardFilter) {
        switch (dashboardFilter.trim()) {
          case 'submitted':
            final status = stringValue(
              row.toJson(),
              'order_status',
            ).trim().toLowerCase();
            return status.isNotEmpty &&
                !<String>{'draft', 'cancelled'}.contains(status);
          default:
            return true;
        }
      },
      dateValueOf: (row) => nullableStringValue(row.toJson(), 'order_date'),
      documentValueOf: (row) => stringValue(row.toJson(), 'order_no'),
      matches: (row, query, statuses) {
        final controller =
            Get.find<PurchaseListRegisterController<PurchaseOrderModel>>(
              tag: persistentControllerTag('PurchaseOrderRegisterController'),
            );
        final data = row.toJson();
        final statusOk = _purchaseMatchesSelectedStatus(
          stringValue(data, 'order_status'),
          statuses,
        );
        final searchOk =
            query.isEmpty ||
            [
              stringValue(data, 'order_no'),
              stringValue(data, 'supplier_name'),
              purchaseStatusLabel(nullableStringValue(data, 'order_status')),
            ].join(' ').toLowerCase().contains(query);
        final filterSupplierIds = _purchaseSelectedSet<int>(
          controller.customFilters['supplier_ids'],
        );
        final supplierOk = _purchaseMatchesSelectedValue(
          intValue(data, 'supplier_party_id'),
          filterSupplierIds,
        );
        final dateOk = matchesDateValueRange(
          nullableStringValue(data, 'order_date'),
          fromValue: controller.dateFromController.text,
          toValue: controller.dateToController.text,
        );
        return statusOk && searchOk && supplierOk && dateOk;
      },
      emptyMessage: 'No purchase orders found.',
      customFiltersBuilder: (context, controller) => _PurchaseRegisterFilters(
        controller: controller,
        statusItems: _statusItems,
        title: 'Find Orders',
        searchHint: 'Order no or supplier name',
        supplierItemsBuilder: _mappedSupplierItems,
      ),
      newRoute: '/purchase/orders/new',
      newLabel: 'New Order',
      searchHint: 'Search orders',
      statusItems: _statusItems,
      dashboardStatusForFilter: (dashboardFilter) {
        switch (dashboardFilter.trim()) {
          case 'submitted':
            return 'confirmed,partially_received,fully_received,partially_invoiced,fully_invoiced,closed';
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
          label: 'Supplier',
          flex: 3,
          valueBuilder: (row) => _nestedName(
            row.toJson(),
            'supplier_name',
            'supplier',
            'party_name',
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Expected Receipt',
          valueBuilder: (row) => displayDate(
            nullableStringValue(row.toJson(), 'expected_receipt_date'),
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Status',
          valueBuilder: (row) => purchaseStatusLabel(
            nullableStringValue(row.toJson(), 'order_status'),
          ),
          widgetBuilder: (context, row) => purchaseStatusBadge(
            context,
            nullableStringValue(row.toJson(), 'order_status'),
          ),
          detailBuilder: (row) => purchaseRegisterCancelReasonDetail(
            row.toJson(),
            statusKey: 'order_status',
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Total',
          alignRight: true,
          valueBuilder: (row) => formatAmount(row.totalAmount ?? 0),
          showPlaceholderWhenEmpty: false,
        ),
      ],
      footerBuilder: (context, controller) {
        final rows = controller.filteredRows;
        final totalAmount = rows.fold<double>(
          0,
          (sum, row) => sum + (row.totalAmount ?? 0),
        );
        return _PurchaseRegisterSummaryFooter(
          cells: <_PurchaseRegisterFooterCell>[
            const _PurchaseRegisterFooterCell(flex: 2, text: 'Total'),
            const _PurchaseRegisterFooterCell(flex: 2),
            const _PurchaseRegisterFooterCell(flex: 3),
            const _PurchaseRegisterFooterCell(flex: 2),
            const _PurchaseRegisterFooterCell(flex: 2),
            _PurchaseRegisterFooterCell(
              flex: 2,
              text: formatAmount(totalAmount),
              alignRight: true,
            ),
          ],
        );
      },
      rowRoute: (row) => '/purchase/orders/${intValue(row.toJson(), 'id')}',
    );
  }
}

class PurchaseReceiptRegisterPage extends StatelessWidget {
  const PurchaseReceiptRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  static const _statusItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All Status'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'posted', label: 'Posted'),
    AppDropdownItem(value: 'partially_invoiced', label: 'Partially Invoiced'),
    AppDropdownItem(value: 'fully_invoiced', label: 'Fully Invoiced'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return _PurchaseRegisterShell<PurchaseReceiptModel>(
      controllerName: 'PurchaseReceiptRegisterController',
      title: 'Purchase Receipts',
      embedded: embedded,
      loader: (service) => service.receipts(
        filters: {'per_page': 200, 'sort_by': 'receipt_date'},
      ),
      dashboardMatches: (row, dashboardFilter) => true,
      dateValueOf: (row) => nullableStringValue(row.toJson(), 'receipt_date'),
      documentValueOf: (row) => stringValue(row.toJson(), 'receipt_no'),
      matches: (row, query, statuses) {
        final controller =
            Get.find<PurchaseListRegisterController<PurchaseReceiptModel>>(
              tag: persistentControllerTag('PurchaseReceiptRegisterController'),
            );
        final data = row.toJson();
        final statusOk = _purchaseMatchesSelectedStatus(
          stringValue(data, 'receipt_status'),
          statuses,
        );
        final searchOk =
            query.isEmpty ||
            [
              stringValue(data, 'receipt_no'),
              stringValue(data, 'supplier_name'),
              purchaseStatusLabel(nullableStringValue(data, 'receipt_status')),
            ].join(' ').toLowerCase().contains(query);
        final filterSupplierIds = _purchaseSelectedSet<int>(
          controller.customFilters['supplier_ids'],
        );
        final supplierOk = _purchaseMatchesSelectedValue(
          intValue(data, 'supplier_party_id'),
          filterSupplierIds,
        );
        final dateOk = matchesDateValueRange(
          nullableStringValue(data, 'receipt_date'),
          fromValue: controller.dateFromController.text,
          toValue: controller.dateToController.text,
        );
        return statusOk && searchOk && supplierOk && dateOk;
      },
      emptyMessage: 'No purchase receipts found.',
      customFiltersBuilder: (context, controller) => _PurchaseRegisterFilters(
        controller: controller,
        statusItems: _statusItems,
        title: 'Find Receipts',
        searchHint: 'Receipt no or supplier name',
        supplierItemsBuilder: _mappedSupplierItems,
      ),
      newRoute: '/purchase/receipts/new',
      newLabel: 'New Receipt',
      searchHint: 'Search receipts',
      statusItems: _statusItems,
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
          label: 'Supplier',
          flex: 3,
          valueBuilder: (row) => _nestedName(
            row.toJson(),
            'supplier_name',
            'supplier',
            'party_name',
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Supplier Invoice',
          valueBuilder: (row) =>
              stringValue(row.toJson(), 'supplier_invoice_no'),
        ),
        PurchaseRegisterColumn(
          label: 'Status',
          valueBuilder: (row) => purchaseStatusLabel(
            nullableStringValue(row.toJson(), 'receipt_status'),
          ),
          widgetBuilder: (context, row) => purchaseStatusBadge(
            context,
            nullableStringValue(row.toJson(), 'receipt_status'),
          ),
          detailBuilder: (row) => purchaseRegisterCancelReasonDetail(
            row.toJson(),
            statusKey: 'receipt_status',
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Total',
          alignRight: true,
          valueBuilder: (row) => formatAmount(_purchaseReceiptTotal(row)),
          showPlaceholderWhenEmpty: false,
        ),
      ],
      footerBuilder: (context, controller) {
        final rows = controller.filteredRows;
        final totalAmount = rows.fold<double>(
          0,
          (sum, row) => sum + _purchaseReceiptTotal(row),
        );
        return _PurchaseRegisterSummaryFooter(
          cells: <_PurchaseRegisterFooterCell>[
            const _PurchaseRegisterFooterCell(flex: 2, text: 'Total'),
            const _PurchaseRegisterFooterCell(flex: 2),
            const _PurchaseRegisterFooterCell(flex: 3),
            const _PurchaseRegisterFooterCell(flex: 2),
            const _PurchaseRegisterFooterCell(flex: 2),
            _PurchaseRegisterFooterCell(
              flex: 2,
              text: formatAmount(totalAmount),
              alignRight: true,
            ),
          ],
        );
      },
      rowRoute: (row) => '/purchase/receipts/${intValue(row.toJson(), 'id')}',
    );
  }
}

class PurchaseInvoiceRegisterPage extends StatelessWidget {
  const PurchaseInvoiceRegisterPage({
    super.key,
    this.embedded = false,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final Map<String, String> queryParameters;

  static const _statusItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All Status'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'posted', label: 'Posted'),
    AppDropdownItem(value: 'overdue', label: 'Overdue'),
    AppDropdownItem(value: 'partially_paid', label: 'Partially Paid'),
    AppDropdownItem(value: 'paid', label: 'Paid'),
    AppDropdownItem(value: 'partially_returned', label: 'Partially Returned'),
    AppDropdownItem(value: 'returned', label: 'Returned'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return _PurchaseRegisterShell<PurchaseInvoiceModel>(
      controllerName: 'PurchaseInvoiceRegisterController',
      title: 'Purchase Invoices',
      embedded: embedded,
      queryParameters: queryParameters,
      loader: (service) => service.invoices(
        filters: {'per_page': 200, 'sort_by': 'invoice_date'},
      ),
      dateValueOf: (row) => row.invoiceDate,
      documentValueOf: (row) => row.invoiceNo ?? '',
      balanceValueOf: (row) => row.balanceAmount,
      matches: (row, query, statuses) {
        final statusOk = _purchaseMatchesSelectedStatus(
          row.invoiceStatus,
          statuses,
        );
        final searchOk =
            query.isEmpty ||
            [
              row.invoiceNo ?? '',
              _nestedName(
                row.toJson(),
                'supplier_name',
                'supplier',
                'party_name',
              ),
            ].join(' ').toLowerCase().contains(query);
        final controller =
            Get.find<PurchaseListRegisterController<PurchaseInvoiceModel>>(
              tag: persistentControllerTag('PurchaseInvoiceRegisterController'),
            );

        final filterSupplierIds = _purchaseSelectedSet<int>(
          controller.customFilters['supplier_ids'],
        );
        final supplierOk = _purchaseMatchesSelectedValue(
          row.supplierPartyId,
          filterSupplierIds,
        );

        final dateOk = matchesDateValueRange(
          row.invoiceDate,
          fromValue: controller.dateFromController.text,
          toValue: controller.dateToController.text,
        );

        return statusOk && searchOk && supplierOk && dateOk;
      },
      dashboardMatches: (row, dashboardFilter) {
        switch (dashboardFilter.trim()) {
          case 'open':
            final status = (row.invoiceStatus ?? '').trim().toLowerCase();
            final outstanding = row.balanceAmount ?? row.totalAmount ?? 0.0;
            return status.isNotEmpty &&
                !<String>{'draft', 'cancelled'}.contains(status) &&
                outstanding > 0;
          case 'overdue':
            final status = (row.invoiceStatus ?? '').trim().toLowerCase();
            return status == 'overdue';
          case 'draft':
            final status = (row.invoiceStatus ?? '').trim().toLowerCase();
            return status == 'draft';
          case 'partially_paid':
            final status = (row.invoiceStatus ?? '').trim().toLowerCase();
            final outstanding = row.balanceAmount ?? row.totalAmount ?? 0.0;
            return status == 'partially_paid' && outstanding > 0;
          default:
            return true;
        }
      },
      emptyMessage: 'No purchase invoices found.',
      customFiltersBuilder: (context, controller) => _PurchaseInvoiceFilters(
        controller: controller,
        statusItems: _statusItems,
      ),
      newRoute: '/purchase/invoices/new',
      newLabel: 'New Invoice',
      searchHint: 'Search invoices',
      statusItems: _statusItems,
      dashboardStatusForFilter: (dashboardFilter) {
        switch (dashboardFilter.trim()) {
          case 'open':
            return 'posted,overdue,partially_paid';
          case 'overdue':
            return 'overdue';
          case 'draft':
            return 'draft';
          case 'partially_paid':
            return 'partially_paid';
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
          valueBuilder: (row) => displayDate(row.invoiceDate),
        ),
        PurchaseRegisterColumn(
          label: 'Supplier',
          flex: 3,
          valueBuilder: (row) => _nestedName(
            row.toJson(),
            'supplier_name',
            'supplier',
            'party_name',
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Due',
          valueBuilder: (row) => displayDate(row.dueDate),
        ),
        PurchaseRegisterColumn(
          label: 'Status',
          valueBuilder: (row) => purchaseStatusLabel(row.invoiceStatus),
          widgetBuilder: (context, row) => purchaseStatusBadge(
            context,
            row.invoiceStatus,
            dueDate: row.dueDate,
          ),
          detailBuilder: (row) => purchaseRegisterCancelReasonDetail(
            row.toJson(),
            statusKey: 'invoice_status',
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Total',
          alignRight: true,
          valueBuilder: (row) => formatAmount(row.totalAmount ?? 0),
          showPlaceholderWhenEmpty: false,
        ),
        PurchaseRegisterColumn(
          label: 'Outstanding',
          alignRight: true,
          valueBuilder: (row) => formatAmount(row.balanceAmount ?? 0),
          showPlaceholderWhenEmpty: false,
        ),
      ],
      footerBuilder: (context, controller) {
        final rows = controller.filteredRows;
        final totalAmount = rows.fold<double>(
          0,
          (sum, row) => sum + (row.totalAmount ?? 0),
        );
        final outstandingAmount = rows.fold<double>(
          0,
          (sum, row) => sum + (row.balanceAmount ?? 0),
        );
        return _PurchaseRegisterSummaryFooter(
          cells: <_PurchaseRegisterFooterCell>[
            const _PurchaseRegisterFooterCell(flex: 2, text: 'Total'),
            const _PurchaseRegisterFooterCell(flex: 2),
            const _PurchaseRegisterFooterCell(flex: 3),
            const _PurchaseRegisterFooterCell(flex: 2),
            const _PurchaseRegisterFooterCell(flex: 2),
            _PurchaseRegisterFooterCell(
              flex: 2,
              text: formatAmount(totalAmount),
              alignRight: true,
            ),
            _PurchaseRegisterFooterCell(
              flex: 2,
              text: formatAmount(outstandingAmount),
              alignRight: true,
            ),
          ],
        );
      },
      rowRoute: (row) => '/purchase/invoices/${row.id}',
    );
  }
}

class PurchasePaymentRegisterPage extends StatelessWidget {
  const PurchasePaymentRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  static const _statusItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All Status'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'posted', label: 'Posted'),
    AppDropdownItem(value: 'partially_allocated', label: 'Partially Completed'),
    AppDropdownItem(value: 'fully_allocated', label: 'Completed'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return _PurchaseRegisterShell<PurchasePaymentModel>(
      controllerName: 'PurchasePaymentRegisterController',
      title: 'Purchase Payments',
      embedded: embedded,
      loader: (service) => service.payments(
        filters: {'per_page': 200, 'sort_by': 'payment_date'},
      ),
      dashboardMatches: (row, dashboardFilter) => true,
      dateValueOf: (row) => nullableStringValue(row.toJson(), 'payment_date'),
      documentValueOf: (row) => stringValue(row.toJson(), 'payment_no'),
      matches: (row, query, statuses) {
        final controller =
            Get.find<PurchaseListRegisterController<PurchasePaymentModel>>(
              tag: persistentControllerTag('PurchasePaymentRegisterController'),
            );
        final data = row.toJson();
        final statusOk = _purchaseMatchesSelectedStatus(
          stringValue(data, 'payment_status'),
          statuses,
        );
        final searchOk =
            query.isEmpty ||
            [
              stringValue(data, 'payment_no'),
              stringValue(data, 'supplier_name'),
              stringValue(data, 'reference_no'),
              purchaseStatusLabel(nullableStringValue(data, 'payment_status')),
            ].join(' ').toLowerCase().contains(query);
        final filterSupplierIds = _purchaseSelectedSet<int>(
          controller.customFilters['supplier_ids'],
        );
        final supplierOk = _purchaseMatchesSelectedValue(
          intValue(data, 'supplier_party_id'),
          filterSupplierIds,
        );
        final dateOk = matchesDateValueRange(
          nullableStringValue(data, 'payment_date'),
          fromValue: controller.dateFromController.text,
          toValue: controller.dateToController.text,
        );
        return statusOk && searchOk && supplierOk && dateOk;
      },
      emptyMessage: 'No purchase payments found.',
      customFiltersBuilder: (context, controller) => _PurchaseRegisterFilters(
        controller: controller,
        statusItems: _statusItems,
        title: 'Find Payments',
        searchHint: 'Payment no, reference no, supplier',
        supplierItemsBuilder: _mappedSupplierItems,
      ),
      newRoute: '/purchase/payments/new',
      newLabel: 'New Payment',
      searchHint: 'Search payments',
      statusItems: _statusItems,
      columns: [
        PurchaseRegisterColumn(
          label: 'No',
          valueBuilder: (row) => stringValue(row.toJson(), 'payment_no'),
        ),
        PurchaseRegisterColumn(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'payment_date')),
        ),
        PurchaseRegisterColumn(
          label: 'Supplier',
          flex: 3,
          valueBuilder: (row) => _nestedName(
            row.toJson(),
            'supplier_name',
            'supplier',
            'party_name',
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Mode',
          valueBuilder: (row) => stringValue(row.toJson(), 'payment_mode'),
        ),
        PurchaseRegisterColumn(
          label: 'Status',
          valueBuilder: (row) => purchaseStatusLabel(
            nullableStringValue(row.toJson(), 'payment_status'),
          ),
          widgetBuilder: (context, row) => purchaseStatusBadge(
            context,
            nullableStringValue(row.toJson(), 'payment_status'),
          ),
          detailBuilder: (row) => purchaseRegisterCancelReasonDetail(
            row.toJson(),
            statusKey: 'payment_status',
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Paid Amount',
          alignRight: true,
          valueBuilder: (row) => formatAmount(row.paidAmount ?? 0),
          showPlaceholderWhenEmpty: false,
        ),
        PurchaseRegisterColumn(
          label: 'Unallocated',
          alignRight: true,
          valueBuilder: (row) => formatAmount(row.unallocatedAmount ?? 0),
          showPlaceholderWhenEmpty: false,
        ),
      ],
      footerBuilder: (context, controller) {
        final rows = controller.filteredRows;
        final paidAmount = rows.fold<double>(
          0,
          (sum, row) => sum + (row.paidAmount ?? 0),
        );
        final unallocatedAmount = rows.fold<double>(
          0,
          (sum, row) => sum + (row.unallocatedAmount ?? 0),
        );
        return _PurchaseRegisterSummaryFooter(
          cells: <_PurchaseRegisterFooterCell>[
            const _PurchaseRegisterFooterCell(flex: 2, text: 'Total'),
            const _PurchaseRegisterFooterCell(flex: 2),
            const _PurchaseRegisterFooterCell(flex: 3),
            const _PurchaseRegisterFooterCell(flex: 2),
            const _PurchaseRegisterFooterCell(flex: 2),
            _PurchaseRegisterFooterCell(
              flex: 2,
              text: formatAmount(paidAmount),
              alignRight: true,
            ),
            _PurchaseRegisterFooterCell(
              flex: 2,
              text: formatAmount(unallocatedAmount),
              alignRight: true,
            ),
          ],
        );
      },
      rowRoute: (row) => '/purchase/payments/${intValue(row.toJson(), 'id')}',
    );
  }
}

class PurchaseReturnRegisterPage extends StatelessWidget {
  const PurchaseReturnRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  static const _statusItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All Status'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'posted', label: 'Posted'),
    AppDropdownItem(value: 'debited', label: 'Debited'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return _PurchaseRegisterShell<PurchaseReturnModel>(
      controllerName: 'PurchaseReturnRegisterController',
      title: 'Purchase Returns',
      embedded: embedded,
      loader: (service) =>
          service.returns(filters: {'per_page': 200, 'sort_by': 'return_date'}),
      dashboardMatches: (row, dashboardFilter) => true,
      dateValueOf: (row) => nullableStringValue(row.toJson(), 'return_date'),
      documentValueOf: (row) => stringValue(row.toJson(), 'return_no'),
      matches: (row, query, statuses) {
        final controller =
            Get.find<PurchaseListRegisterController<PurchaseReturnModel>>(
              tag: persistentControllerTag('PurchaseReturnRegisterController'),
            );
        final data = row.toJson();
        final statusOk = _purchaseMatchesSelectedStatus(
          stringValue(data, 'return_status'),
          statuses,
        );
        final searchOk =
            query.isEmpty ||
            [
              stringValue(data, 'return_no'),
              stringValue(data, 'supplier_name'),
              stringValue(data, 'return_reason'),
              purchaseStatusLabel(nullableStringValue(data, 'return_status')),
            ].join(' ').toLowerCase().contains(query);
        final filterSupplierIds = _purchaseSelectedSet<int>(
          controller.customFilters['supplier_ids'],
        );
        final supplierOk = _purchaseMatchesSelectedValue(
          intValue(data, 'supplier_party_id'),
          filterSupplierIds,
        );
        final dateOk = matchesDateValueRange(
          nullableStringValue(data, 'return_date'),
          fromValue: controller.dateFromController.text,
          toValue: controller.dateToController.text,
        );
        return statusOk && searchOk && supplierOk && dateOk;
      },
      emptyMessage: 'No purchase returns found.',
      customFiltersBuilder: (context, controller) => _PurchaseRegisterFilters(
        controller: controller,
        statusItems: _statusItems,
        title: 'Find Returns',
        searchHint: 'Return no or supplier name',
        supplierItemsBuilder: _mappedSupplierItems,
      ),
      newRoute: '/purchase/returns/new',
      newLabel: 'New Return',
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
          label: 'Purchase Invoice',
          valueBuilder: (row) => _nestedName(
            row.toJson(),
            'purchase_invoice_no',
            'purchase_invoice',
            'invoice_no',
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Reason',
          flex: 3,
          valueBuilder: (row) => stringValue(row.toJson(), 'return_reason'),
        ),
        PurchaseRegisterColumn(
          label: 'Status',
          valueBuilder: (row) => purchaseStatusLabel(
            nullableStringValue(row.toJson(), 'return_status'),
          ),
          widgetBuilder: (context, row) => purchaseStatusBadge(
            context,
            nullableStringValue(row.toJson(), 'return_status'),
          ),
          detailBuilder: (row) => purchaseRegisterCancelReasonDetail(
            row.toJson(),
            statusKey: 'return_status',
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Total',
          alignRight: true,
          valueBuilder: (row) => formatAmount(row.totalAmount ?? 0),
          showPlaceholderWhenEmpty: false,
        ),
      ],
      footerBuilder: (context, controller) {
        final rows = controller.filteredRows;
        final totalAmount = rows.fold<double>(
          0,
          (sum, row) => sum + (row.totalAmount ?? 0),
        );
        return _PurchaseRegisterSummaryFooter(
          cells: <_PurchaseRegisterFooterCell>[
            const _PurchaseRegisterFooterCell(flex: 2, text: 'Total'),
            const _PurchaseRegisterFooterCell(flex: 2),
            const _PurchaseRegisterFooterCell(flex: 2),
            const _PurchaseRegisterFooterCell(flex: 3),
            const _PurchaseRegisterFooterCell(flex: 2),
            _PurchaseRegisterFooterCell(
              flex: 2,
              text: formatAmount(totalAmount),
              alignRight: true,
            ),
          ],
        );
      },
      rowRoute: (row) => '/purchase/returns/${intValue(row.toJson(), 'id')}',
    );
  }
}

class _RegisterFilters extends StatelessWidget {
  const _RegisterFilters({
    required this.searchController,
    required this.searchHint,
    this.filterFields,
    this.trailingActions,
    this.maxWidth,
    required this.selectedStatuses,
    required this.statusItems,
    required this.onStatusChanged,
  });

  final TextEditingController searchController;
  final String searchHint;
  final List<Widget>? filterFields;
  final List<Widget>? trailingActions;
  final double? maxWidth;
  final Set<String> selectedStatuses;
  final List<AppDropdownItem<String>> statusItems;
  final ValueChanged<Set<String>> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsFormWrap(
      maxWidth: maxWidth ?? 300,
      children: [
        ...(filterFields ??
            <Widget>[
              AppFormTextField(
                labelText: 'Search',
                controller: searchController,
                hintText: searchHint,
              ),
            ]),
        AppDropdownField<String>.fromMapped(
          labelText: 'Status',
          mappedItems: statusItems
              .where((item) => item.value.trim().isNotEmpty)
              .toList(growable: false),
          multiInitialValues: selectedStatuses,
          multiHintText: 'Select statuses',
          onMultiChanged: onStatusChanged,
        ),
        ...?trailingActions,
      ],
    );
  }
}

List<AppDropdownItem<int>> _mappedSupplierItems<T>(
  PurchaseListRegisterController<T> controller,
) {
  final uniqueSuppliers = <int, String>{};
  for (final row in controller.rows) {
    if (row is! JsonModel) {
      continue;
    }
    final data = row.toJson();
    final id = intValue(data, 'supplier_party_id');
    final name = _nestedName(data, 'supplier_name', 'supplier', 'party_name');
    if (id != null && name.isNotEmpty) {
      uniqueSuppliers[id] = name;
    }
  }
  return <AppDropdownItem<int>>[
    ...uniqueSuppliers.entries.map(
      (entry) => AppDropdownItem<int>(value: entry.key, label: entry.value),
    ),
  ];
}

class _PurchaseRegisterFilters<T> extends StatelessWidget {
  const _PurchaseRegisterFilters({
    required this.controller,
    required this.statusItems,
    required this.title,
    required this.searchHint,
    this.supplierItemsBuilder,
  });

  final PurchaseListRegisterController<T> controller;
  final List<AppDropdownItem<String>> statusItems;
  final String title;
  final String searchHint;
  final List<AppDropdownItem<int>> Function(
    PurchaseListRegisterController<T> controller,
  )?
  supplierItemsBuilder;

  void _clearFilters() {
    controller.searchController.clear();
    controller.dateFromController.clear();
    controller.dateToController.clear();
    controller.setCustomFilter('supplier_ids', <int>{});
    controller.setCustomFilter('balance_filter', '');
    controller.setStatuses(<String>{});
    controller.setSort('');
  }

  Widget _searchField() {
    return AppFormTextField(
      labelText: 'Search',
      controller: controller.searchController,
      hintText: searchHint,
    );
  }

  Widget _statusField() {
    return AppDropdownField<String>.fromMapped(
      labelText: 'Status',
      mappedItems: statusItems
          .where((item) => item.value.trim().isNotEmpty)
          .toList(growable: false),
      multiInitialValues: controller.selectedStatuses,
      multiHintText: 'Select statuses',
      onMultiChanged: controller.setStatuses,
    );
  }

  Widget _sortField() {
    return AppDropdownField<String>.fromMapped(
      labelText: 'Sort',
      mappedItems: _purchaseRegisterSortItems,
      initialValue: controller.sort,
      onChanged: (value) => controller.setSort(value ?? ''),
    );
  }

  Widget _supplierField() {
    return AppDropdownField<int>.fromMapped(
      labelText: 'Supplier',
      mappedItems: supplierItemsBuilder!(controller),
      multiInitialValues: _purchaseSelectedSet<int>(
        controller.customFilters['supplier_ids'],
      ),
      multiHintText: 'Select suppliers',
      onMultiChanged: (values) =>
          controller.setCustomFilter('supplier_ids', values),
    );
  }

  Widget _dateField({
    required String label,
    required TextEditingController textController,
  }) {
    return AppFormTextField(
      labelText: label,
      controller: textController,
      hintText: dateFormatHint(),
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
    final hasSupplier = supplierItemsBuilder != null;

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
              if (hasSupplier) ...[
                Expanded(child: _supplierField()),
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
                  if (hasSupplier) ...[
                    Expanded(child: _supplierField()),
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
                if (hasSupplier) _supplierField(),
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

class _PurchaseInvoiceFilters extends StatelessWidget {
  const _PurchaseInvoiceFilters({
    required this.controller,
    required this.statusItems,
  });

  final PurchaseListRegisterController<PurchaseInvoiceModel> controller;
  final List<AppDropdownItem<String>> statusItems;

  List<AppDropdownItem<int>> _supplierItems() {
    final Map<int, String> uniqueSuppliers = <int, String>{};
    for (final row in controller.rows) {
      final name = _nestedName(
        row.toJson(),
        'supplier_name',
        'supplier',
        'party_name',
      );
      if (name.isNotEmpty) {
        uniqueSuppliers[row.supplierPartyId] = name;
      }
    }

    return <AppDropdownItem<int>>[
      ...uniqueSuppliers.entries.map(
        (entry) => AppDropdownItem<int>(value: entry.key, label: entry.value),
      ),
    ];
  }

  void _clearFilters() {
    controller.searchController.clear();
    controller.dateFromController.clear();
    controller.dateToController.clear();
    controller.setCustomFilter('supplier_ids', <int>{});
    controller.setStatuses(<String>{});
    controller.setSort('');
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

  Widget _searchField() {
    return AppFormTextField(
      labelText: 'Search',
      controller: controller.searchController,
      hintText: 'Bill no or supplier name',
    );
  }

  Widget _supplierField() {
    return AppDropdownField<int>.fromMapped(
      labelText: 'Supplier',
      mappedItems: _supplierItems(),
      multiInitialValues: _purchaseSelectedSet<int>(
        controller.customFilters['supplier_ids'],
      ),
      multiHintText: 'Select suppliers',
      onMultiChanged: (values) =>
          controller.setCustomFilter('supplier_ids', values),
    );
  }

  Widget _statusField() {
    return AppDropdownField<String>.fromMapped(
      labelText: 'Status',
      mappedItems: statusItems
          .where((item) => item.value.trim().isNotEmpty)
          .toList(growable: false),
      multiInitialValues: controller.selectedStatuses,
      multiHintText: 'Select statuses',
      onMultiChanged: controller.setStatuses,
    );
  }

  Widget _sortField() {
    return AppDropdownField<String>.fromMapped(
      labelText: 'Sort',
      mappedItems: _purchaseInvoiceRegisterSortItems,
      initialValue: controller.sort,
      onChanged: (value) => controller.setSort(value ?? ''),
    );
  }

  Widget _dateFromField() {
    return AppFormTextField(
      labelText: 'Date From',
      controller: controller.dateFromController,
      hintText: dateFormatHint(),
      keyboardType: TextInputType.datetime,
      inputFormatters: const [DateInputFormatter()],
      validator: Validators.optionalDate('Date From'),
    );
  }

  Widget _dateToField() {
    return AppFormTextField(
      labelText: 'Date To',
      controller: controller.dateToController,
      hintText: dateFormatHint(),
      keyboardType: TextInputType.datetime,
      inputFormatters: const [DateInputFormatter()],
      validator: Validators.optionalDate('Date To'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isWide = width >= 1320;
        final isMedium = width >= 920 && width < 1320;

        if (isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _searchField()),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  Expanded(child: _supplierField()),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  Expanded(child: _statusField()),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  Expanded(child: _sortField()),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  Expanded(child: _dateFromField()),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  Expanded(child: _dateToField()),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  SizedBox(width: 160, child: _actionField(context)),
                ],
              ),
            ],
          );
        }

        if (isMedium) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Find Invoices',
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
                  Expanded(child: _supplierField()),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  Expanded(child: _statusField()),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  Expanded(child: _sortField()),
                ],
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _dateFromField()),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  Expanded(child: _dateToField()),
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
              'Find Invoices',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            SettingsFormWrap(
              maxWidth: double.infinity,
              children: [
                _searchField(),
                _supplierField(),
                _statusField(),
                _sortField(),
                _dateFromField(),
                _dateToField(),
                _actionField(context),
              ],
            ),
          ],
        );
      },
    );
  }
}
