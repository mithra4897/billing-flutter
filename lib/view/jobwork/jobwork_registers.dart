import '../../screen.dart';
import '../../view_model/jobwork/jobwork_module_refresh_controller.dart';

typedef JobworkRegisterLoader<T> =
    Future<ApiResponse<List<T>>> Function(
      JobworkService service,
      int? companyId,
    );
typedef JobworkRegisterMatcher<T> = bool Function(T row, String query);

void _openJobworkShellRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}

class _JwFilters extends StatelessWidget {
  const _JwFilters({
    required this.searchController,
    required this.searchHint,
    required this.companyBanner,
  });

  final TextEditingController searchController;
  final String searchHint;
  final String? companyBanner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (companyBanner != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.apartment_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppUiConstants.spacingSm),
                Expanded(
                  child: Text(
                    'Session company: $companyBanner. Lists use company_id '
                    'when loading from the API.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 20,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: AppUiConstants.spacingSm),
                Expanded(
                  child: Text(
                    'No company in session. Select a company in the header '
                    'to scope jobwork lists.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        AppFormTextField(
          labelText: 'Search',
          controller: searchController,
          hintText: searchHint,
        ),
      ],
    );
  }
}

class JobworkRegisterController<T> extends GetxController {
  JobworkRegisterController({required this.loader, required this.matches});

  final JobworkRegisterLoader<T> loader;
  final JobworkRegisterMatcher<T> matches;
  final JobworkService _service = JobworkService();
  final JobworkModuleRefreshController _refreshController =
      JobworkModuleRefreshController.ensureRegistered();
  final TextEditingController searchController = TextEditingController();

  bool loading = true;
  String? error;
  String? companyBanner;
  List<T> rows = <T>[];
  Worker? _refreshWorker;

  List<T> get filteredRows {
    final query = searchController.text.trim().toLowerCase();
    return rows
        .where((row) => query.isEmpty || matches(row, query))
        .toList(growable: false);
  }

  @override
  void onInit() {
    super.onInit();
    WorkingContextService.version.addListener(_onContextChanged);
    searchController.addListener(update);
    _refreshWorker = ever<JobworkModuleRefreshEvent?>(
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
    WorkingContextService.version.removeListener(_onContextChanged);
    searchController
      ..removeListener(update)
      ..dispose();
    super.onClose();
  }

  void _onContextChanged() {
    unawaited(load());
  }

  Future<void> load() async {
    loading = true;
    error = null;
    update();
    try {
      final info = await hrSessionCompanyInfo();
      final response = await loader(_service, info.companyId);
      companyBanner = info.banner;
      rows = response.data ?? <T>[];
      loading = false;
      update();
    } catch (err) {
      error = err.toString();
      loading = false;
      update();
    }
  }
}

class _JobworkRegisterShell<T> extends StatefulWidget {
  const _JobworkRegisterShell({
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
  });

  final String controllerName;
  final String title;
  final bool embedded;
  final JobworkRegisterLoader<T> loader;
  final JobworkRegisterMatcher<T> matches;
  final String emptyMessage;
  final String newRoute;
  final String newLabel;
  final String searchHint;
  final List<PurchaseRegisterColumn<T>> columns;
  final String Function(T row) rowRoute;

  @override
  State<_JobworkRegisterShell<T>> createState() =>
      _JobworkRegisterShellState<T>();
}

class _JobworkRegisterShellState<T> extends State<_JobworkRegisterShell<T>> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(widget.controllerName);
    if (!Get.isRegistered<JobworkRegisterController<T>>(tag: _controllerTag)) {
      Get.put(
        JobworkRegisterController<T>(
          loader: widget.loader,
          matches: widget.matches,
        ),
        tag: _controllerTag,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<JobworkRegisterController<T>>(
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
              onPressed: () => _openJobworkShellRoute(context, widget.newRoute),
              icon: Icons.add_outlined,
              label: widget.newLabel,
            ),
          ],
          filters: _JwFilters(
            searchController: controller.searchController,
            searchHint: widget.searchHint,
            companyBanner: controller.companyBanner,
          ),
          rows: controller.filteredRows,
          columns: widget.columns,
          onRowTap: (row) =>
              _openJobworkShellRoute(context, widget.rowRoute(row)),
        );
      },
    );
  }
}

class JobworkOrderRegisterPage extends StatelessWidget {
  const JobworkOrderRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _JobworkRegisterShell<JobworkOrderModel>(
      controllerName: 'JobworkOrderRegisterController',
      title: 'Jobwork orders',
      embedded: embedded,
      loader: (service, companyId) {
        final filters = <String, dynamic>{'per_page': 200};
        if (companyId != null) {
          filters['company_id'] = companyId;
        }
        return service.orders(filters: filters);
      },
      matches: (row, query) {
        return [
          row.jobworkNo,
          row.processName,
          row.jobworkStatus,
          row.supplierLabel,
        ].join(' ').toLowerCase().contains(query);
      },
      emptyMessage: 'No jobwork orders found.',
      newRoute: '/jobwork/orders/new',
      newLabel: 'New jobwork order',
      searchHint: 'Search order no., process, supplier, status',
      columns: [
        PurchaseRegisterColumn<JobworkOrderModel>(
          label: 'Order no.',
          valueBuilder: (row) => row.jobworkNo,
        ),
        PurchaseRegisterColumn<JobworkOrderModel>(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(row.jobworkDate.isNotEmpty ? row.jobworkDate : null),
        ),
        PurchaseRegisterColumn<JobworkOrderModel>(
          label: 'Supplier',
          flex: 2,
          valueBuilder: (row) => row.supplierLabel,
        ),
        PurchaseRegisterColumn<JobworkOrderModel>(
          label: 'Status',
          valueBuilder: (row) => row.jobworkStatus,
        ),
      ],
      rowRoute: (row) => '/jobwork/orders/${row.id}',
    );
  }
}

class JobworkDispatchRegisterPage extends StatelessWidget {
  const JobworkDispatchRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _JobworkRegisterShell<JobworkDispatchModel>(
      controllerName: 'JobworkDispatchRegisterController',
      title: 'Jobwork dispatches',
      embedded: embedded,
      loader: (service, companyId) {
        final filters = <String, dynamic>{'per_page': 200};
        if (companyId != null) {
          filters['company_id'] = companyId;
        }
        return service.dispatches(filters: filters);
      },
      matches: (row, query) {
        return [
          row.dispatchNo,
          row.dispatchStatus,
          row.jobworkOrderNoLabel,
          row.supplierLabel,
        ].join(' ').toLowerCase().contains(query);
      },
      emptyMessage: 'No jobwork dispatches found.',
      newRoute: '/jobwork/dispatches/new',
      newLabel: 'New dispatch',
      searchHint: 'Search dispatch no., order, supplier, status',
      columns: [
        PurchaseRegisterColumn<JobworkDispatchModel>(
          label: 'Dispatch no.',
          valueBuilder: (row) => row.dispatchNo,
        ),
        PurchaseRegisterColumn<JobworkDispatchModel>(
          label: 'Date',
          valueBuilder: (row) => displayDate(
            row.dispatchDate.isNotEmpty ? row.dispatchDate : null,
          ),
        ),
        PurchaseRegisterColumn<JobworkDispatchModel>(
          label: 'Jobwork order',
          flex: 2,
          valueBuilder: (row) => row.jobworkOrderNoLabel,
        ),
        PurchaseRegisterColumn<JobworkDispatchModel>(
          label: 'Status',
          valueBuilder: (row) => row.dispatchStatus,
        ),
      ],
      rowRoute: (row) => '/jobwork/dispatches/${row.id}',
    );
  }
}

class JobworkReceiptRegisterPage extends StatelessWidget {
  const JobworkReceiptRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _JobworkRegisterShell<JobworkReceiptModel>(
      controllerName: 'JobworkReceiptRegisterController',
      title: 'Jobwork receipts',
      embedded: embedded,
      loader: (service, companyId) {
        final filters = <String, dynamic>{'per_page': 200};
        if (companyId != null) {
          filters['company_id'] = companyId;
        }
        return service.receipts(filters: filters);
      },
      matches: (row, query) {
        return [
          row.receiptNo,
          row.receiptStatus,
          row.jobworkOrderNoLabel,
          row.supplierLabel,
        ].join(' ').toLowerCase().contains(query);
      },
      emptyMessage: 'No jobwork receipts found.',
      newRoute: '/jobwork/receipts/new',
      newLabel: 'New receipt',
      searchHint: 'Search receipt no., order, supplier, status',
      columns: [
        PurchaseRegisterColumn<JobworkReceiptModel>(
          label: 'Receipt no.',
          valueBuilder: (row) => row.receiptNo,
        ),
        PurchaseRegisterColumn<JobworkReceiptModel>(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(row.receiptDate.isNotEmpty ? row.receiptDate : null),
        ),
        PurchaseRegisterColumn<JobworkReceiptModel>(
          label: 'Jobwork order',
          flex: 2,
          valueBuilder: (row) => row.jobworkOrderNoLabel,
        ),
        PurchaseRegisterColumn<JobworkReceiptModel>(
          label: 'Status',
          valueBuilder: (row) => row.receiptStatus,
        ),
      ],
      rowRoute: (row) => '/jobwork/receipts/${row.id}',
    );
  }
}

class JobworkChargeRegisterPage extends StatelessWidget {
  const JobworkChargeRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _JobworkRegisterShell<JobworkChargeModel>(
      controllerName: 'JobworkChargeRegisterController',
      title: 'Jobwork charges',
      embedded: embedded,
      loader: (service, companyId) {
        final filters = <String, dynamic>{'per_page': 200};
        if (companyId != null) {
          filters['company_id'] = companyId;
        }
        return service.charges(filters: filters);
      },
      matches: (row, query) {
        return [
          row.chargeNo,
          row.chargeStatus,
          row.jobworkOrderNoLabel,
          row.supplierLabel,
          row.totalAmount.toString(),
        ].join(' ').toLowerCase().contains(query);
      },
      emptyMessage: 'No jobwork charges found.',
      newRoute: '/jobwork/charges/new',
      newLabel: 'New charge',
      searchHint: 'Search charge no., order, supplier, amount, status',
      columns: [
        PurchaseRegisterColumn<JobworkChargeModel>(
          label: 'Charge no.',
          valueBuilder: (row) => row.chargeNo,
        ),
        PurchaseRegisterColumn<JobworkChargeModel>(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(row.chargeDate.isNotEmpty ? row.chargeDate : null),
        ),
        PurchaseRegisterColumn<JobworkChargeModel>(
          label: 'Jobwork order',
          flex: 2,
          valueBuilder: (row) => row.jobworkOrderNoLabel,
        ),
        PurchaseRegisterColumn<JobworkChargeModel>(
          label: 'Status',
          valueBuilder: (row) => row.chargeStatus,
        ),
      ],
      rowRoute: (row) => '/jobwork/charges/${row.id}',
    );
  }
}
