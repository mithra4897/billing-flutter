import '../../screen.dart';

void _openServiceShellRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}

Map<String, dynamic>? _asJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

String _customerName(Map<String, dynamic> data) {
  final c = _asJsonMap(data['customer']);
  if (c == null) {
    return '';
  }
  final d = stringValue(c, 'display_name');
  if (d.isNotEmpty) {
    return d;
  }
  return stringValue(c, 'party_name');
}

String _nestedTicketNo(Map<String, dynamic> data) {
  final t = _asJsonMap(data['ticket']);
  if (t == null) {
    return '';
  }
  return stringValue(t, 'ticket_no');
}

int? _feedbackTicketCompanyId(Map<String, dynamic> data) {
  final t = _asJsonMap(data['ticket']);
  if (t == null) {
    return null;
  }
  return intValue(t, 'company_id');
}

class _SvcFilters extends StatelessWidget {
  const _SvcFilters({
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
                    'Session company: $companyBanner. Use header company '
                    'for API-scoped lists; feedback uses ticket company '
                    'client-side.',
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
                    'No company in session. Select a company to scope lists.',
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

// --- Registers ----------------------------------------------------------

typedef ServiceRegisterLoader<T> =
    Future<dynamic> Function(
      ServiceModuleService service,
      ({int? companyId, String? banner}) info,
    );
typedef ServiceRegisterMatcher<T> = bool Function(T row, String query);

class ServiceRegisterController<T> extends GetxController {
  ServiceRegisterController({required this.loader, required this.matches});

  final ServiceRegisterLoader<T> loader;
  final ServiceRegisterMatcher<T> matches;
  final ServiceModuleService _service = ServiceModuleService();
  final TextEditingController searchController = TextEditingController();

  bool loading = true;
  String? error;
  String? companyBanner;
  List<T> rows = <T>[];

  @override
  void onInit() {
    super.onInit();
    WorkingContextService.version.addListener(_onContextChanged);
    searchController.addListener(update);
    unawaited(load());
  }

  @override
  void onClose() {
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
      final response = await loader(_service, info);
      final data = response.data;
      companyBanner = info.banner;
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

  List<T> get filteredRows {
    final query = searchController.text.trim().toLowerCase();
    return rows.where((row) => matches(row, query)).toList(growable: false);
  }
}

class _ServiceRegisterShell<T> extends StatefulWidget {
  const _ServiceRegisterShell({
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
  final ServiceRegisterLoader<T> loader;
  final ServiceRegisterMatcher<T> matches;
  final String emptyMessage;
  final String newRoute;
  final String newLabel;
  final String searchHint;
  final List<PurchaseRegisterColumn<T>> columns;
  final String Function(T row) rowRoute;

  @override
  State<_ServiceRegisterShell<T>> createState() =>
      _ServiceRegisterShellState<T>();
}

class _ServiceRegisterShellState<T> extends State<_ServiceRegisterShell<T>> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(widget.controllerName);
    if (!Get.isRegistered<ServiceRegisterController<T>>(tag: _controllerTag)) {
      Get.put(
        ServiceRegisterController<T>(
          loader: widget.loader,
          matches: widget.matches,
        ),
        tag: _controllerTag,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ServiceRegisterController<T>>(
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
              onPressed: () => _openServiceShellRoute(context, widget.newRoute),
              icon: Icons.add_outlined,
              label: widget.newLabel,
            ),
          ],
          filters: _SvcFilters(
            searchController: controller.searchController,
            searchHint: widget.searchHint,
            companyBanner: controller.companyBanner,
          ),
          rows: controller.filteredRows,
          columns: widget.columns,
          onRowTap: (row) =>
              _openServiceShellRoute(context, widget.rowRoute(row)),
        );
      },
    );
  }
}

class ServiceContractRegisterPage extends StatelessWidget {
  const ServiceContractRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _ServiceRegisterShell<ServiceContractModel>(
      controllerName: 'ServiceContractRegisterController',
      title: 'Service contracts',
      embedded: embedded,
      loader: (service, info) {
        final filters = <String, dynamic>{'per_page': 200};
        if (info.companyId != null) {
          filters['company_id'] = info.companyId;
        }
        return service.contracts(filters: filters);
      },
      matches: (row, query) {
        final data = row.toJson();
        if (query.isEmpty) {
          return true;
        }
        return [
          stringValue(data, 'contract_no'),
          stringValue(data, 'contract_status'),
          stringValue(data, 'contract_type'),
          _customerName(data),
        ].join(' ').toLowerCase().contains(query);
      },
      emptyMessage: 'No service contracts found.',
      newRoute: '/service/contracts/new',
      newLabel: 'New service contract',
      searchHint: 'Search contract no., customer, status, type',
      columns: [
        PurchaseRegisterColumn<ServiceContractModel>(
          label: 'Contract no.',
          valueBuilder: (ServiceContractModel row) =>
              stringValue(row.toJson(), 'contract_no'),
        ),
        PurchaseRegisterColumn<ServiceContractModel>(
          label: 'Date',
          valueBuilder: (ServiceContractModel row) =>
              displayDate(nullableStringValue(row.toJson(), 'contract_date')),
        ),
        PurchaseRegisterColumn<ServiceContractModel>(
          label: 'Customer',
          flex: 2,
          valueBuilder: (ServiceContractModel row) =>
              _customerName(row.toJson()),
        ),
        PurchaseRegisterColumn<ServiceContractModel>(
          label: 'Status',
          valueBuilder: (ServiceContractModel row) =>
              stringValue(row.toJson(), 'contract_status'),
        ),
      ],
      rowRoute: (ServiceContractModel row) =>
          '/service/contracts/${intValue(row.toJson(), 'id')}',
    );
  }
}

class ServiceTicketRegisterPage extends StatelessWidget {
  const ServiceTicketRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _ServiceRegisterShell<ServiceTicketModel>(
      controllerName: 'ServiceTicketRegisterController',
      title: 'Service tickets',
      embedded: embedded,
      loader: (service, info) async {
        final filters = <String, dynamic>{'per_page': 200};
        if (info.companyId != null) {
          filters['company_id'] = info.companyId;
        }
        final response = await service.tickets(filters: filters);
        final rows = (response.data ?? const <ServiceTicketModel>[])
            .where(
              (r) => stringValue(r.toJson(), 'ticket_type') != 'warranty_claim',
            )
            .toList(growable: false);
        return ApiResponse<List<ServiceTicketModel>>(
          success: response.success,
          message: response.message,
          data: rows,
        );
      },
      matches: (row, query) {
        final data = row.toJson();
        if (query.isEmpty) {
          return true;
        }
        return [
          stringValue(data, 'ticket_no'),
          stringValue(data, 'issue_title'),
          stringValue(data, 'ticket_status'),
          stringValue(data, 'ticket_type'),
          _customerName(data),
        ].join(' ').toLowerCase().contains(query);
      },
      emptyMessage: 'No service tickets found.',
      newRoute: '/service/tickets/new',
      newLabel: 'New ticket',
      searchHint: 'Search ticket no., title, customer, status',
      columns: [
        PurchaseRegisterColumn<ServiceTicketModel>(
          label: 'Ticket no.',
          valueBuilder: (ServiceTicketModel row) =>
              stringValue(row.toJson(), 'ticket_no'),
        ),
        PurchaseRegisterColumn<ServiceTicketModel>(
          label: 'Title',
          flex: 2,
          valueBuilder: (ServiceTicketModel row) =>
              stringValue(row.toJson(), 'issue_title'),
        ),
        PurchaseRegisterColumn<ServiceTicketModel>(
          label: 'Customer',
          flex: 2,
          valueBuilder: (ServiceTicketModel row) => _customerName(row.toJson()),
        ),
        PurchaseRegisterColumn<ServiceTicketModel>(
          label: 'Status',
          valueBuilder: (ServiceTicketModel row) =>
              stringValue(row.toJson(), 'ticket_status'),
        ),
      ],
      rowRoute: (ServiceTicketModel row) =>
          '/service/tickets/${intValue(row.toJson(), 'id')}',
    );
  }
}

class WarrantyClaimRegisterPage extends StatelessWidget {
  const WarrantyClaimRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _ServiceRegisterShell<ServiceTicketModel>(
      controllerName: 'WarrantyClaimRegisterController',
      title: 'Warranty claims',
      embedded: embedded,
      loader: (service, info) {
        final filters = <String, dynamic>{'per_page': 200};
        if (info.companyId != null) {
          filters['company_id'] = info.companyId;
        }
        return service.warrantyClaims(filters: filters);
      },
      matches: (row, query) {
        final data = row.toJson();
        if (query.isEmpty) {
          return true;
        }
        return [
          stringValue(data, 'ticket_no'),
          stringValue(data, 'issue_title'),
          stringValue(data, 'ticket_status'),
          _customerName(data),
        ].join(' ').toLowerCase().contains(query);
      },
      emptyMessage: 'No warranty claims found.',
      newRoute: '/service/warranty-claims/new',
      newLabel: 'New warranty claim',
      searchHint: 'Search claim no., title, customer, status',
      columns: [
        PurchaseRegisterColumn<ServiceTicketModel>(
          label: 'Claim no.',
          valueBuilder: (ServiceTicketModel row) =>
              stringValue(row.toJson(), 'ticket_no'),
        ),
        PurchaseRegisterColumn<ServiceTicketModel>(
          label: 'Title',
          flex: 2,
          valueBuilder: (ServiceTicketModel row) =>
              stringValue(row.toJson(), 'issue_title'),
        ),
        PurchaseRegisterColumn<ServiceTicketModel>(
          label: 'Customer',
          flex: 2,
          valueBuilder: (ServiceTicketModel row) => _customerName(row.toJson()),
        ),
        PurchaseRegisterColumn<ServiceTicketModel>(
          label: 'Status',
          valueBuilder: (ServiceTicketModel row) =>
              stringValue(row.toJson(), 'ticket_status'),
        ),
      ],
      rowRoute: (ServiceTicketModel row) =>
          '/service/warranty-claims/${intValue(row.toJson(), 'id')}',
    );
  }
}

class ServiceWorkOrderRegisterPage extends StatelessWidget {
  const ServiceWorkOrderRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _ServiceRegisterShell<ServiceWorkOrderModel>(
      controllerName: 'ServiceWorkOrderRegisterController',
      title: 'Service work orders',
      embedded: embedded,
      loader: (service, info) {
        final filters = <String, dynamic>{'per_page': 200};
        if (info.companyId != null) {
          filters['company_id'] = info.companyId;
        }
        return service.workOrders(filters: filters);
      },
      matches: (row, query) {
        final data = row.toJson();
        if (query.isEmpty) {
          return true;
        }
        return [
          stringValue(data, 'work_order_no'),
          stringValue(data, 'work_order_status'),
          _nestedTicketNo(data),
          _customerName(data),
        ].join(' ').toLowerCase().contains(query);
      },
      emptyMessage: 'No service work orders found.',
      newRoute: '/service/work-orders/new',
      newLabel: 'New work order',
      searchHint: 'Search WO no., ticket, customer, status',
      columns: [
        PurchaseRegisterColumn<ServiceWorkOrderModel>(
          label: 'WO no.',
          valueBuilder: (ServiceWorkOrderModel row) =>
              stringValue(row.toJson(), 'work_order_no'),
        ),
        PurchaseRegisterColumn<ServiceWorkOrderModel>(
          label: 'Date',
          valueBuilder: (ServiceWorkOrderModel row) =>
              displayDate(nullableStringValue(row.toJson(), 'work_order_date')),
        ),
        PurchaseRegisterColumn<ServiceWorkOrderModel>(
          label: 'Ticket',
          valueBuilder: (ServiceWorkOrderModel row) =>
              _nestedTicketNo(row.toJson()),
        ),
        PurchaseRegisterColumn<ServiceWorkOrderModel>(
          label: 'Status',
          valueBuilder: (ServiceWorkOrderModel row) =>
              stringValue(row.toJson(), 'work_order_status'),
        ),
      ],
      rowRoute: (ServiceWorkOrderModel row) =>
          '/service/work-orders/${intValue(row.toJson(), 'id')}',
    );
  }
}

class ServiceFeedbackRegisterPage extends StatelessWidget {
  const ServiceFeedbackRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _ServiceRegisterShell<ServiceFeedbackModel>(
      controllerName: 'ServiceFeedbackRegisterController',
      title: 'Service feedback',
      embedded: embedded,
      loader: (service, info) async {
        final response = await service.feedbacks(
          filters: const {'per_page': 200},
        );
        var rows = response.data ?? const <ServiceFeedbackModel>[];
        final cid = info.companyId;
        if (cid != null) {
          rows = rows
              .where((r) => _feedbackTicketCompanyId(r.toJson()) == cid)
              .toList(growable: false);
        }
        return ApiResponse<List<ServiceFeedbackModel>>(
          success: response.success,
          message: response.message,
          data: rows,
        );
      },
      matches: (row, query) {
        final data = row.toJson();
        if (query.isEmpty) {
          return true;
        }
        return [
          stringValue(data, 'rating_overall'),
          _nestedTicketNo(data),
          stringValue(data, 'customer_feedback'),
        ].join(' ').toLowerCase().contains(query);
      },
      emptyMessage: 'No feedback records found.',
      newRoute: '/service/feedbacks/new',
      newLabel: 'New feedback',
      searchHint: 'Search ticket, ratings, feedback text',
      columns: [
        PurchaseRegisterColumn<ServiceFeedbackModel>(
          label: 'Date',
          valueBuilder: (ServiceFeedbackModel row) =>
              displayDate(nullableStringValue(row.toJson(), 'feedback_date')),
        ),
        PurchaseRegisterColumn<ServiceFeedbackModel>(
          label: 'Ticket',
          valueBuilder: (ServiceFeedbackModel row) =>
              _nestedTicketNo(row.toJson()),
        ),
        PurchaseRegisterColumn<ServiceFeedbackModel>(
          label: 'Overall',
          valueBuilder: (ServiceFeedbackModel row) =>
              stringValue(row.toJson(), 'rating_overall'),
        ),
        PurchaseRegisterColumn<ServiceFeedbackModel>(
          label: 'Confirmed',
          valueBuilder: (ServiceFeedbackModel row) =>
              stringValue(row.toJson(), 'resolution_confirmed'),
        ),
      ],
      rowRoute: (ServiceFeedbackModel row) =>
          '/service/feedbacks/${intValue(row.toJson(), 'id')}',
    );
  }
}
