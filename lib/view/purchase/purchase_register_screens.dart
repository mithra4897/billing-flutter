import '../../screen.dart';
import '../../controller/purchase/purchase_module_refresh_controller.dart';
import '../../controller/purchase/purchase_invoice_management_controller.dart';
import '../../controller/purchase/purchase_order_management_controller.dart';
import '../../controller/purchase/purchase_payment_management_controller.dart';
import '../../controller/purchase/purchase_receipt_management_controller.dart';

typedef PurchaseRegisterLoader<T> =
    Future<dynamic> Function(
      PurchaseService service,
      Map<String, dynamic> filters,
    );
typedef PurchaseRegisterAllLoader<T> =
    Future<dynamic> Function(
      PurchaseService service,
      Map<String, dynamic> filters,
    );
typedef PurchaseRegisterMatcher<T> =
    bool Function(
      T row,
      String query,
      Set<String> statuses,
      PurchaseListRegisterController<T> controller,
    );
typedef PurchaseRegisterDashboardMatcher<T> =
    bool Function(T row, String dashboardFilter);
typedef PurchaseRegisterDateValue<T> = String? Function(T row);
typedef PurchaseRegisterDocumentValue<T> = String Function(T row);
typedef PurchaseRegisterBalanceValue<T> = double? Function(T row);

Future<void> _sendPurchaseRegisterEmailPdf<T extends GetxController>({
  required BuildContext context,
  required int documentId,
  required String controllerName,
  required T Function() createController,
  required Future<void> Function(T controller) initialize,
  required bool Function(T controller) canEmail,
  required Future<void> Function(T controller, BuildContext context) send,
}) async {
  final controllerTag = persistentControllerTag(
    controllerName,
    scope: <String, Object?>{'documentId': documentId},
  );
  final controller = Get.put(createController(), tag: controllerTag);
  try {
    await initialize(controller);
    if (!context.mounted) return;
    if (!canEmail(controller)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email PDF is available after posting the document.'),
        ),
      );
      return;
    }
    await send(controller, context);
  } finally {
    if (Get.isRegistered<T>(tag: controllerTag)) {
      Get.delete<T>(tag: controllerTag);
    }
  }
}

class _PurchaseRegisterEmailPdfButton extends StatefulWidget {
  const _PurchaseRegisterEmailPdfButton({
    required this.canEmail,
    required this.onOpen,
  });

  final bool canEmail;
  final Future<void> Function() onOpen;

  @override
  State<_PurchaseRegisterEmailPdfButton> createState() =>
      _PurchaseRegisterEmailPdfButtonState();
}

class _PurchaseRegisterEmailPdfButtonState
    extends State<_PurchaseRegisterEmailPdfButton> {
  bool _isOpening = false;

  Future<void> _open() async {
    if (_isOpening || !widget.canEmail) return;
    setState(() => _isOpening = true);
    try {
      await widget.onOpen();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(printableDocumentEmailFailureMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: widget.canEmail
        ? 'Email PDF'
        : 'Email PDF is available after posting the document',
    child: IconButton(
      onPressed: widget.canEmail && !_isOpening ? _open : null,
      icon: _isOpening
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.attach_email_outlined),
    ),
  );
}

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
  kPendingRedFirstSortItem,
];

const _purchaseInvoiceRegisterSortItems = <AppDropdownItem<String>>[
  AppDropdownItem(value: '', label: 'Default order'),
  AppDropdownItem(value: 'date_desc', label: 'Newest first'),
  AppDropdownItem(value: 'date_asc', label: 'Oldest first'),
  AppDropdownItem(value: 'doc_asc', label: 'Number A-Z'),
  AppDropdownItem(value: 'doc_desc', label: 'Number Z-A'),
  AppDropdownItem(value: 'balance_desc', label: 'High outstanding to low'),
  kPendingRedFirstSortItem,
];

Map<String, dynamic> _purchaseServerFilters(
  Map<String, dynamic> filters, {
  required String dateField,
  required String documentField,
  String? balanceField,
}) {
  final requested = filters['sort_by']?.toString();
  final sortField = switch (requested) {
    'document' => documentField,
    'balance_amount' when balanceField != null => balanceField,
    _ => dateField,
  };
  return <String, dynamic>{...filters, 'sort_by': sortField};
}

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

String _purchaseInvoiceEffectiveStatus(PurchaseInvoiceModel invoice) {
  final stored = (invoice.invoiceStatus ?? '').trim().toLowerCase();
  if (<String>{
    'draft',
    'cancelled',
    'returned',
    'partially_returned',
  }.contains(stored)) {
    return stored;
  }
  final balance = invoice.balanceAmount ?? invoice.totalAmount ?? 0;
  if (balance <= 0 && (invoice.totalAmount ?? 0) > 0) return 'paid';
  final paid = doubleValue(invoice.toJson(), 'paid_amount') ?? 0;
  final dueDate = DateTime.tryParse(invoice.dueDate ?? '');
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  if (dueDate != null &&
      DateTime(dueDate.year, dueDate.month, dueDate.day).isBefore(today)) {
    return 'overdue';
  }
  if (paid > 0) return 'partially_paid';
  return 'posted';
}

class PurchaseListRegisterController<T> extends GetxController {
  PurchaseListRegisterController({
    required this.loader,
    required this.allLoader,
    required this.matches,
    required this.dashboardMatches,
    required this.dateValueOf,
    required this.documentValueOf,
    this.balanceValueOf,
    this.isPending,
    this.initialSort = 'date_asc',
    this.initialStatuses = const <String>{},
    required this.statusFilterKey,
  });

  final PurchaseRegisterLoader<T> loader;
  final PurchaseRegisterAllLoader<T> allLoader;
  final PurchaseRegisterMatcher<T> matches;
  final PurchaseRegisterDashboardMatcher<T> dashboardMatches;
  final PurchaseRegisterDateValue<T> dateValueOf;
  final PurchaseRegisterDocumentValue<T> documentValueOf;
  final PurchaseRegisterBalanceValue<T>? balanceValueOf;
  final bool Function(T row)? isPending;
  final String initialSort;
  final Set<String> initialStatuses;
  final String statusFilterKey;
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
  List<T> allRows = <T>[];
  final Map<int, String> supplierOptions = <int, String>{};
  PaginationMeta? pagination;
  Worker? _refreshWorker;
  Timer? _filterDebounce;

  List<T> get filteredRows {
    return _filterRows(rows);
  }

  List<T> get allFilteredRows => _filterRows(allRows);

  List<T> _filterRows(List<T> source) {
    final query = searchController.text.trim().toLowerCase();
    final filtered = source
        .where(
          (row) =>
              matches(row, query, selectedStatuses, this) &&
              dashboardMatches(row, dashboardFilter) &&
              (sort != kPendingRedFirstSort ||
                  isPending == null ||
                  isPending!(row)),
        )
        .toList(growable: false);
    filtered.sort(_compareRows);
    return filtered;
  }

  @override
  void onInit() {
    super.onInit();
    sort = initialSort;
    selectedStatuses = Set<String>.from(initialStatuses);
    searchController.addListener(_scheduleFilterReload);
    dateFromController.addListener(_scheduleFilterReload);
    dateToController.addListener(_scheduleFilterReload);
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
    _filterDebounce?.cancel();
    searchController
      ..removeListener(_scheduleFilterReload)
      ..dispose();
    dateFromController
      ..removeListener(_scheduleFilterReload)
      ..dispose();
    dateToController
      ..removeListener(_scheduleFilterReload)
      ..dispose();
    super.onClose();
  }

  void setStatuses(Set<String> values) {
    selectedStatuses = Set<String>.from(values);
    update();
    _scheduleFilterReload();
  }

  void setSort(String value) {
    sort = value;
    update();
    _scheduleFilterReload();
  }

  void applyDashboardFilter(String value, {String statusOverride = ''}) {
    dashboardFilter = value.trim();
    selectedStatuses = dashboardFilter.isEmpty && statusOverride.trim().isEmpty
        ? Set<String>.from(initialStatuses)
        : statusOverride
              .split(',')
              .map((status) => status.trim().toLowerCase())
              .where((status) => status.isNotEmpty)
              .toSet();
    sort = initialSort;
    searchController.clear();
    dateFromController.clear();
    dateToController.clear();
    update();
    unawaited(load(page: 1));
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
    _scheduleFilterReload();
  }

  void _scheduleFilterReload() {
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
      case kPendingRedFirstSort:
        if (isPending != null) {
          final leftPending = isPending!(left);
          final rightPending = isPending!(right);
          if (leftPending && !rightPending) return -1;
          if (!leftPending && rightPending) return 1;
        }
        return _comparePurchaseRegisterStrings(
          dateValueOf(left),
          dateValueOf(right),
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

  Future<void> load({int page = 1}) async {
    _filterDebounce?.cancel();
    loading = true;
    error = null;
    update();
    try {
      final filters = <String, dynamic>{
        'per_page': 50,
        'page': page,
        if (searchController.text.trim().isNotEmpty)
          'search': searchController.text.trim(),
        if (dateFromController.text.trim().isNotEmpty)
          'date_from': dateFromController.text.trim(),
        if (dateToController.text.trim().isNotEmpty)
          'date_to': dateToController.text.trim(),
      };
      if (selectedStatuses.isNotEmpty) {
        if (selectedStatuses.length == 1) {
          filters[statusFilterKey] = selectedStatuses.single;
        } else {
          filters['${statusFilterKey}es'] = selectedStatuses.join(',');
        }
      }
      final supplierIds = _purchaseSelectedSet<int>(
        customFilters['supplier_ids'],
      );
      if (supplierIds.length == 1) {
        filters['supplier_party_id'] = supplierIds.single;
      }
      final sortValues = _serverSortValues();
      filters
        ..['sort_by'] = sortValues.$1
        ..['sort_order'] = sortValues.$2;
      final responses = await Future.wait<dynamic>([
        loader(_service, filters),
        if (page == 1) allLoader(_service, filters),
      ]);
      final response = responses.first;
      final data = response.data;
      pagination = response.meta as PaginationMeta?;
      rows = data is List<T>
          ? data
          : data is List
          ? data.whereType<T>().toList(growable: false)
          : <T>[];
      if (page == 1) {
        final allData = responses[1].data;
        allRows = allData is List<T>
            ? allData
            : allData is List
            ? allData.whereType<T>().toList(growable: false)
            : <T>[];
        for (final row in allRows) {
          if (row is! JsonModel) continue;
          final json = row.toJson();
          final id = intValue(json, 'supplier_party_id');
          final name = _nestedName(
            json,
            'supplier_name',
            'supplier',
            'party_name',
          );
          if (id != null && name.isNotEmpty) supplierOptions[id] = name;
        }
      }
      loading = false;
      update();
    } catch (err) {
      error = err.toString();
      loading = false;
      update();
    }
  }

  (String, String) _serverSortValues() {
    return switch (sort) {
      'date_asc' => ('date', 'asc'),
      'doc_asc' => ('document', 'asc'),
      'doc_desc' => ('document', 'desc'),
      'balance_desc' => ('balance_amount', 'desc'),
      'balance_asc' => ('balance_amount', 'asc'),
      kPendingRedFirstSort => ('date', 'asc'),
      _ => ('date', 'desc'),
    };
  }
}

class _PurchaseRegisterShell<T> extends StatefulWidget {
  const _PurchaseRegisterShell({
    required this.controllerName,
    required this.title,
    required this.embedded,
    required this.loader,
    required this.allLoader,
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
    this.isPending,
    this.initialSort = 'date_asc',
    this.initialStatuses = const <String>{},
    required this.statusFilterKey,
  });

  final String controllerName;
  final String title;
  final bool embedded;
  final PurchaseRegisterLoader<T> loader;
  final PurchaseRegisterAllLoader<T> allLoader;
  final PurchaseRegisterMatcher<T> matches;
  final PurchaseRegisterDashboardMatcher<T> dashboardMatches;
  final PurchaseRegisterDateValue<T> dateValueOf;
  final PurchaseRegisterDocumentValue<T> documentValueOf;
  final PurchaseRegisterBalanceValue<T>? balanceValueOf;
  final String initialSort;
  final Set<String> initialStatuses;
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
    int currentPage,
  )?
  footerBuilder;
  final bool Function(T row)? isPending;
  final String statusFilterKey;

  @override
  State<_PurchaseRegisterShell<T>> createState() =>
      _PurchaseRegisterShellState<T>();
}

class _PurchaseRegisterShellState<T> extends State<_PurchaseRegisterShell<T>> {
  late final String _controllerTag;
  bool _filtersVisible = false;

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
          allLoader: widget.allLoader,
          matches: widget.matches,
          dashboardMatches: widget.dashboardMatches,
          dateValueOf: widget.dateValueOf,
          documentValueOf: widget.documentValueOf,
          balanceValueOf: widget.balanceValueOf,
          isPending: widget.isPending,
          initialSort: widget.initialSort,
          initialStatuses: widget.initialStatuses,
          statusFilterKey: widget.statusFilterKey,
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
          emphasizeRows: true,
          loading: controller.loading,
          errorMessage: controller.error,
          onRetry: controller.load,
          emptyMessage: widget.emptyMessage,
          actions: [
            if (widget.extraActionsBuilder != null)
              ...widget.extraActionsBuilder!(context, controller),
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
            AdaptiveShellActionButton(
              onPressed: () => _openShellRoute(context, widget.newRoute),
              icon: Icons.add_outlined,
              label: widget.newLabel,
            ),
          ],
          filters: _filtersVisible
              ? widget.customFiltersBuilder?.call(context, controller) ??
                    _RegisterFilters(
                      searchController: controller.searchController,
                      searchHint: widget.searchHint,
                      filterFields: widget.filterFieldsBuilder?.call(
                        context,
                        controller,
                      ),
                      trailingActions: widget.filterTrailingActionsBuilder
                          ?.call(context, controller),
                      maxWidth: widget.filtersMaxWidth,
                      selectedStatuses: controller.selectedStatuses,
                      statusItems: widget.statusItems,
                      onStatusChanged: controller.setStatuses,
                    )
              : null,
          rows: controller.filteredRows,
          columns: widget.columns,
          onRowTap: (row) => _openShellRoute(context, widget.rowRoute(row)),
          rowColorBuilder: widget.isPending != null
              ? (_, row) => documentAgeZoneColor(
                  row is JsonModel
                      ? (row.toJson()['created_at']?.toString() ??
                            widget.dateValueOf(row))
                      : widget.dateValueOf(row),
                  isPending: widget.isPending!(row),
                )
              : null,
          footerBuilder: (context, currentPage) =>
              widget.footerBuilder?.call(context, controller, currentPage),
          remoteTotalItems: controller.pagination?.total,
          remoteCurrentPage: controller.pagination?.currentPage,
          remotePerPage: controller.pagination?.perPage,
          onRemotePageChanged: controller.goToPage,
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
            .map((cell) {
              final textStyle = theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              );
              final displayText = cell.text == 'Total'
                  ? 'Page total:\nOverall total:'
                  : cell.text;
              final isSummary = displayText.contains('\n');
              return Expanded(
                flex: cell.flex,
                child: isSummary
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: displayText
                            .split('\n')
                            .expand(
                              (line) => <Widget>[
                                if (line != displayText.split('\n').first)
                                  Divider(
                                    height: 8,
                                    thickness: 1,
                                    color: theme.dividerColor,
                                  ),
                                Text(
                                  line,
                                  textAlign: cell.text.contains('\n')
                                      ? TextAlign.right
                                      : TextAlign.left,
                                  style: textStyle,
                                ),
                              ],
                            )
                            .toList(growable: false),
                      )
                    : Text(
                        displayText,
                        textAlign: cell.alignRight
                            ? TextAlign.right
                            : TextAlign.left,
                        style: textStyle,
                      ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

String _purchaseTotalSummary(double overall, double page) =>
    '${formatAmount(page)}\n${formatAmount(overall)}';

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
      loader: (service, filters) => service.requisitions(
        filters: _purchaseServerFilters(
          filters,
          dateField: 'requisition_date',
          documentField: 'requisition_no',
        ),
      ),
      allLoader: (service, filters) => service.requisitionsAll(
        filters: _purchaseServerFilters(
          filters,
          dateField: 'requisition_date',
          documentField: 'requisition_no',
        ),
      ),
      statusFilterKey: 'requisition_status',
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
      isPending: (row) {
        final status = stringValue(
          row.toJson(),
          'requisition_status',
        ).trim().toLowerCase();
        return status.isNotEmpty &&
            !const {'approved', 'closed', 'cancelled'}.contains(status);
      },
      matches: (row, query, statuses, controller) {
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
      footerBuilder: (context, controller, currentPage) {
        final rows = controller.allFilteredRows;
        final pageRows = controller.filteredRows;
        final estimatedTotal = rows.fold<double>(
          0,
          (sum, row) => sum + _purchaseRequisitionEstimatedTotal(row),
        );
        final pageEstimatedTotal = pageRows.fold<double>(
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
              text: _purchaseTotalSummary(estimatedTotal, pageEstimatedTotal),
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
      loader: (service, filters) => service.orders(
        filters: _purchaseServerFilters(
          filters,
          dateField: 'order_date',
          documentField: 'order_no',
        ),
      ),
      allLoader: (service, filters) => service.ordersAll(
        filters: _purchaseServerFilters(
          filters,
          dateField: 'order_date',
          documentField: 'order_no',
        ),
      ),
      statusFilterKey: 'order_status',
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
      isPending: (row) {
        final status = stringValue(
          row.toJson(),
          'order_status',
        ).trim().toLowerCase();
        return status.isNotEmpty &&
            !const {'closed', 'cancelled', 'fully_invoiced'}.contains(status);
      },
      matches: (row, query, statuses, controller) {
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
          label: 'Email PDF',
          flex: 1,
          center: true,
          valueBuilder: (_) => '',
          widgetBuilder: (context, row) => _PurchaseRegisterEmailPdfButton(
            canEmail: purchaseOrderCanOpenEmailPdf(row),
            onOpen: () => _sendPurchaseRegisterEmailPdf(
              context: context,
              documentId: row.id!,
              controllerName: 'PurchaseOrderRegisterEmailPdfController',
              createController: PurchaseOrderManagementController.new,
              initialize: (controller) =>
                  controller.initialize(initialId: row.id, editorOnly: true),
              canEmail: (controller) =>
                  purchaseOrderCanOpenEmailPdf(controller.selectedItem),
              send: (controller, context) =>
                  controller.sendEmailPdfDirectly(context),
            ),
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Total',
          alignRight: true,
          valueBuilder: (row) => formatAmount(row.totalAmount ?? 0),
          showPlaceholderWhenEmpty: false,
        ),
      ],
      footerBuilder: (context, controller, currentPage) {
        final rows = controller.allFilteredRows;
        final pageRows = controller.filteredRows;
        final totalAmount = rows.fold<double>(
          0,
          (sum, row) => sum + (row.totalAmount ?? 0),
        );
        final pageTotalAmount = pageRows.fold<double>(
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
            const _PurchaseRegisterFooterCell(flex: 1),
            _PurchaseRegisterFooterCell(
              flex: 2,
              text: _purchaseTotalSummary(totalAmount, pageTotalAmount),
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
    AppDropdownItem(value: 'posted', label: 'Submitted'),
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
      loader: (service, filters) => service.receipts(
        filters: _purchaseServerFilters(
          filters,
          dateField: 'receipt_date',
          documentField: 'receipt_no',
        ),
      ),
      allLoader: (service, filters) => service.receiptsAll(
        filters: _purchaseServerFilters(
          filters,
          dateField: 'receipt_date',
          documentField: 'receipt_no',
        ),
      ),
      statusFilterKey: 'receipt_status',
      dashboardMatches: (row, dashboardFilter) => true,
      dateValueOf: (row) => nullableStringValue(row.toJson(), 'receipt_date'),
      documentValueOf: (row) => stringValue(row.toJson(), 'receipt_no'),
      matches: (row, query, statuses, controller) {
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
          label: 'Email PDF',
          flex: 1,
          center: true,
          valueBuilder: (_) => '',
          widgetBuilder: (context, row) => _PurchaseRegisterEmailPdfButton(
            canEmail: purchaseReceiptCanOpenEmailPdf(row),
            onOpen: () => _sendPurchaseRegisterEmailPdf(
              context: context,
              documentId: row.id!,
              controllerName: 'PurchaseReceiptRegisterEmailPdfController',
              createController: PurchaseReceiptManagementController.new,
              initialize: (controller) =>
                  controller.initialize(initialId: row.id, editorOnly: true),
              canEmail: (controller) =>
                  purchaseReceiptCanOpenEmailPdf(controller.selectedItem),
              send: (controller, context) =>
                  controller.sendEmailPdfDirectly(context),
            ),
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Total',
          alignRight: true,
          valueBuilder: (row) => formatAmount(_purchaseReceiptTotal(row)),
          showPlaceholderWhenEmpty: false,
        ),
      ],
      footerBuilder: (context, controller, currentPage) {
        final rows = controller.allFilteredRows;
        final pageRows = controller.filteredRows;
        final totalAmount = rows.fold<double>(
          0,
          (sum, row) => sum + _purchaseReceiptTotal(row),
        );
        final pageTotalAmount = pageRows.fold<double>(
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
              text: _purchaseTotalSummary(totalAmount, pageTotalAmount),
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
    AppDropdownItem(value: 'posted', label: 'Payment pending'),
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
      loader: (service, filters) => service.invoices(
        filters: _purchaseServerFilters(
          filters,
          dateField: 'invoice_date',
          documentField: 'invoice_no',
          balanceField: 'balance_amount',
        ),
      ),
      allLoader: (service, filters) => service.invoicesAll(
        filters: _purchaseServerFilters(
          filters,
          dateField: 'invoice_date',
          documentField: 'invoice_no',
          balanceField: 'balance_amount',
        ),
      ),
      statusFilterKey: 'invoice_status',
      initialStatuses: const <String>{
        'draft',
        'posted',
        'partially_paid',
        'overdue',
      },
      dateValueOf: (row) => row.invoiceDate,
      documentValueOf: (row) => row.invoiceNo ?? '',
      balanceValueOf: (row) => row.balanceAmount,
      isPending: (row) {
        final status = (row.invoiceStatus ?? '').trim().toLowerCase();
        return status != 'cancelled' &&
            (row.balanceAmount ?? row.totalAmount ?? 0) > 0;
      },
      matches: (row, query, statuses, controller) {
        final effectiveStatus = _purchaseInvoiceEffectiveStatus(row);
        final statusOk = _purchaseMatchesSelectedStatus(
          effectiveStatus,
          statuses,
        );
        final searchOk =
            query.isEmpty ||
            [
              row.invoiceNo ?? '',
              purchaseInvoiceStatusLabel(effectiveStatus),
              _nestedName(
                row.toJson(),
                'supplier_name',
                'supplier',
                'party_name',
              ),
            ].join(' ').toLowerCase().contains(query);
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
          valueBuilder: (row) => purchaseInvoiceStatusLabel(row.invoiceStatus),
          widgetBuilder: (context, row) => purchaseStatusBadge(
            context,
            row.invoiceStatus,
            dueDate: row.dueDate,
            labelBuilder: purchaseInvoiceStatusLabel,
          ),
          detailBuilder: (row) => purchaseRegisterCancelReasonDetail(
            row.toJson(),
            statusKey: 'invoice_status',
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Email PDF',
          flex: 1,
          center: true,
          valueBuilder: (_) => '',
          widgetBuilder: (context, row) => _PurchaseRegisterEmailPdfButton(
            canEmail: purchaseInvoiceCanOpenEmailPdf(row),
            onOpen: () => _sendPurchaseRegisterEmailPdf(
              context: context,
              documentId: row.id!,
              controllerName: 'PurchaseInvoiceRegisterEmailPdfController',
              createController: PurchaseInvoiceManagementController.new,
              initialize: (controller) =>
                  controller.initialize(initialId: row.id, editorOnly: true),
              canEmail: (controller) =>
                  purchaseInvoiceCanOpenEmailPdf(controller.selectedItem),
              send: (controller, context) =>
                  controller.sendEmailPdfDirectly(context),
            ),
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
      footerBuilder: (context, controller, currentPage) {
        final rows = controller.allFilteredRows;
        final pageRows = controller.filteredRows;
        final totalAmount = rows.fold<double>(
          0,
          (sum, row) => sum + (row.totalAmount ?? 0),
        );
        final outstandingAmount = rows.fold<double>(
          0,
          (sum, row) => sum + (row.balanceAmount ?? 0),
        );
        final pageTotalAmount = pageRows.fold<double>(
          0,
          (sum, row) => sum + (row.totalAmount ?? 0),
        );
        final pageOutstandingAmount = pageRows.fold<double>(
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
            const _PurchaseRegisterFooterCell(flex: 1),
            _PurchaseRegisterFooterCell(
              flex: 2,
              text: _purchaseTotalSummary(totalAmount, pageTotalAmount),
              alignRight: true,
            ),
            _PurchaseRegisterFooterCell(
              flex: 2,
              text: _purchaseTotalSummary(
                outstandingAmount,
                pageOutstandingAmount,
              ),
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
    AppDropdownItem(value: 'posted', label: 'Submitted'),
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
      loader: (service, filters) => service.payments(
        filters: _purchaseServerFilters(
          filters,
          dateField: 'payment_date',
          documentField: 'payment_no',
        ),
      ),
      allLoader: (service, filters) => service.paymentsAll(
        filters: _purchaseServerFilters(
          filters,
          dateField: 'payment_date',
          documentField: 'payment_no',
        ),
      ),
      statusFilterKey: 'payment_status',
      dashboardMatches: (row, dashboardFilter) => true,
      dateValueOf: (row) => nullableStringValue(row.toJson(), 'payment_date'),
      documentValueOf: (row) => stringValue(row.toJson(), 'payment_no'),
      matches: (row, query, statuses, controller) {
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
          label: 'Email PDF',
          flex: 1,
          center: true,
          valueBuilder: (_) => '',
          widgetBuilder: (context, row) => _PurchaseRegisterEmailPdfButton(
            canEmail: purchasePaymentCanOpenEmailPdf(row),
            onOpen: () => _sendPurchaseRegisterEmailPdf(
              context: context,
              documentId: row.id!,
              controllerName: 'PurchasePaymentRegisterEmailPdfController',
              createController: PurchasePaymentManagementController.new,
              initialize: (controller) =>
                  controller.initialize(initialId: row.id, editorOnly: true),
              canEmail: (controller) =>
                  purchasePaymentCanOpenEmailPdf(controller.selectedItem),
              send: (controller, context) =>
                  controller.sendEmailPdfDirectly(context),
            ),
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
      footerBuilder: (context, controller, currentPage) {
        final rows = controller.allFilteredRows;
        final pageRows = controller.filteredRows;
        final paidAmount = rows.fold<double>(
          0,
          (sum, row) => sum + (row.paidAmount ?? 0),
        );
        final unallocatedAmount = rows.fold<double>(
          0,
          (sum, row) => sum + (row.unallocatedAmount ?? 0),
        );
        final pagePaidAmount = pageRows.fold<double>(
          0,
          (sum, row) => sum + (row.paidAmount ?? 0),
        );
        final pageUnallocatedAmount = pageRows.fold<double>(
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
            const _PurchaseRegisterFooterCell(flex: 1),
            _PurchaseRegisterFooterCell(
              flex: 2,
              text: _purchaseTotalSummary(paidAmount, pagePaidAmount),
              alignRight: true,
            ),
            _PurchaseRegisterFooterCell(
              flex: 2,
              text: _purchaseTotalSummary(
                unallocatedAmount,
                pageUnallocatedAmount,
              ),
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
    AppDropdownItem(value: 'posted', label: 'Submitted'),
    AppDropdownItem(value: 'debited', label: 'Debited'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return _PurchaseRegisterShell<PurchaseReturnModel>(
      controllerName: 'PurchaseReturnRegisterController',
      title: 'Purchase Returns',
      embedded: embedded,
      loader: (service, filters) => service.returns(
        filters: _purchaseServerFilters(
          filters,
          dateField: 'return_date',
          documentField: 'return_no',
        ),
      ),
      allLoader: (service, filters) => service.returnsAll(
        filters: _purchaseServerFilters(
          filters,
          dateField: 'return_date',
          documentField: 'return_no',
        ),
      ),
      statusFilterKey: 'return_status',
      dashboardMatches: (row, dashboardFilter) => true,
      dateValueOf: (row) => nullableStringValue(row.toJson(), 'return_date'),
      documentValueOf: (row) => stringValue(row.toJson(), 'return_no'),
      matches: (row, query, statuses, controller) {
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
      footerBuilder: (context, controller, currentPage) {
        final rows = controller.allFilteredRows;
        final pageRows = controller.filteredRows;
        final totalAmount = rows.fold<double>(
          0,
          (sum, row) => sum + (row.totalAmount ?? 0),
        );
        final pageTotalAmount = pageRows.fold<double>(
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
              text: _purchaseTotalSummary(totalAmount, pageTotalAmount),
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
      maxColumns: 6,
      expandChildren: true,
      children: [
        ...?filterFields,
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
  return <AppDropdownItem<int>>[
    ...controller.supplierOptions.entries.map(
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
    controller.setSort('date_asc');
  }

  @override
  Widget build(BuildContext context) {
    return AppRegisterFilters(
      dateFromController: controller.dateFromController,
      dateToController: controller.dateToController,
      statusItems: statusItems,
      selectedStatuses: controller.selectedStatuses,
      onStatusesChanged: controller.setStatuses,
      sortItems: _purchaseRegisterSortItems,
      sort: controller.sort,
      onSortChanged: (value) => controller.setSort(value ?? ''),
      partyLabel: supplierItemsBuilder != null ? 'Supplier' : null,
      partyItems: supplierItemsBuilder?.call(controller),
      selectedPartyIds: _purchaseSelectedSet<int>(
        controller.customFilters['supplier_ids'],
      ),
      onPartyChanged: (values) =>
          controller.setCustomFilter('supplier_ids', values),
      onClear: _clearFilters,
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
    return <AppDropdownItem<int>>[
      ...controller.supplierOptions.entries.map(
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
    controller.setSort('date_asc');
  }

  @override
  Widget build(BuildContext context) {
    return AppRegisterFilters(
      dateFromController: controller.dateFromController,
      dateToController: controller.dateToController,
      statusItems: statusItems,
      selectedStatuses: controller.selectedStatuses,
      onStatusesChanged: controller.setStatuses,
      sortItems: _purchaseInvoiceRegisterSortItems,
      sort: controller.sort,
      onSortChanged: (value) => controller.setSort(value ?? ''),
      partyLabel: 'Supplier',
      partyItems: _supplierItems(),
      selectedPartyIds: _purchaseSelectedSet<int>(
        controller.customFilters['supplier_ids'],
      ),
      onPartyChanged: (values) =>
          controller.setCustomFilter('supplier_ids', values),
      onClear: _clearFilters,
    );
  }
}
