import '../../screen.dart';
import '../hr/hr_workflow_dialogs.dart';
import '../purchase/purchase_register_page.dart';
import '../purchase/purchase_support.dart';

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

class ServiceContractRegisterPage extends StatefulWidget {
  const ServiceContractRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ServiceContractRegisterPage> createState() =>
      _ServiceContractRegisterPageState();
}

class _ServiceContractRegisterPageState extends State<ServiceContractRegisterPage> {
  final ServiceModuleService _service = ServiceModuleService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<ServiceContractModel> _rows = const <ServiceContractModel>[];

  @override
  void initState() {
    super.initState();
    WorkingContextService.version.addListener(_onContextChanged);
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    WorkingContextService.version.removeListener(_onContextChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onContextChanged() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await hrSessionCompanyInfo();
      final filters = <String, dynamic>{'per_page': 200};
      if (info.companyId != null) {
        filters['company_id'] = info.companyId;
      }
      final response = await _service.contracts(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <ServiceContractModel>[];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<ServiceContractModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((ServiceContractModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'contract_no'),
            stringValue(data, 'contract_status'),
            stringValue(data, 'contract_type'),
            _customerName(data),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<ServiceContractModel>(
      title: 'Service contracts',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No service contracts found.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: () =>
              _openServiceShellRoute(context, '/service/contracts/new'),
          icon: Icons.add_outlined,
          label: 'New service contract',
        ),
      ],
      filters: _SvcFilters(
        searchController: _searchController,
        searchHint: 'Search contract no., customer, status, type',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<ServiceContractModel>(
          label: 'Contract no.',
          valueBuilder: (ServiceContractModel row) =>
              stringValue(row.toJson(), 'contract_no'),
        ),
        PurchaseRegisterColumn<ServiceContractModel>(
          label: 'Date',
          valueBuilder: (ServiceContractModel row) => displayDate(
            nullableStringValue(row.toJson(), 'contract_date'),
          ),
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
      onRowTap: (ServiceContractModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        _openServiceShellRoute(context, '/service/contracts/$id');
      },
    );
  }
}

class ServiceTicketRegisterPage extends StatefulWidget {
  const ServiceTicketRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ServiceTicketRegisterPage> createState() =>
      _ServiceTicketRegisterPageState();
}

class _ServiceTicketRegisterPageState extends State<ServiceTicketRegisterPage> {
  final ServiceModuleService _service = ServiceModuleService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<ServiceTicketModel> _rows = const <ServiceTicketModel>[];

  @override
  void initState() {
    super.initState();
    WorkingContextService.version.addListener(_onContextChanged);
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    WorkingContextService.version.removeListener(_onContextChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onContextChanged() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await hrSessionCompanyInfo();
      final filters = <String, dynamic>{'per_page': 200};
      if (info.companyId != null) {
        filters['company_id'] = info.companyId;
      }
      final response = await _service.tickets(filters: filters);
      if (!mounted) {
        return;
      }
      var rows = response.data ?? const <ServiceTicketModel>[];
      rows = rows
          .where(
            (r) => stringValue(r.toJson(), 'ticket_type') != 'warranty_claim',
          )
          .toList(growable: false);
      setState(() {
        _companyBanner = info.banner;
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<ServiceTicketModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((ServiceTicketModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'ticket_no'),
            stringValue(data, 'issue_title'),
            stringValue(data, 'ticket_status'),
            stringValue(data, 'ticket_type'),
            _customerName(data),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<ServiceTicketModel>(
      title: 'Service tickets',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No service tickets found.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: () =>
              _openServiceShellRoute(context, '/service/tickets/new'),
          icon: Icons.add_outlined,
          label: 'New ticket',
        ),
      ],
      filters: _SvcFilters(
        searchController: _searchController,
        searchHint: 'Search ticket no., title, customer, status',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
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
          valueBuilder: (ServiceTicketModel row) =>
              _customerName(row.toJson()),
        ),
        PurchaseRegisterColumn<ServiceTicketModel>(
          label: 'Status',
          valueBuilder: (ServiceTicketModel row) =>
              stringValue(row.toJson(), 'ticket_status'),
        ),
      ],
      onRowTap: (ServiceTicketModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        _openServiceShellRoute(context, '/service/tickets/$id');
      },
    );
  }
}

class WarrantyClaimRegisterPage extends StatefulWidget {
  const WarrantyClaimRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<WarrantyClaimRegisterPage> createState() =>
      _WarrantyClaimRegisterPageState();
}

class _WarrantyClaimRegisterPageState extends State<WarrantyClaimRegisterPage> {
  final ServiceModuleService _service = ServiceModuleService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<ServiceTicketModel> _rows = const <ServiceTicketModel>[];

  @override
  void initState() {
    super.initState();
    WorkingContextService.version.addListener(_onContextChanged);
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    WorkingContextService.version.removeListener(_onContextChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onContextChanged() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await hrSessionCompanyInfo();
      final filters = <String, dynamic>{'per_page': 200};
      if (info.companyId != null) {
        filters['company_id'] = info.companyId;
      }
      final response = await _service.warrantyClaims(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <ServiceTicketModel>[];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<ServiceTicketModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((ServiceTicketModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'ticket_no'),
            stringValue(data, 'issue_title'),
            stringValue(data, 'ticket_status'),
            _customerName(data),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<ServiceTicketModel>(
      title: 'Warranty claims',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No warranty claims found.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: () =>
              _openServiceShellRoute(context, '/service/warranty-claims/new'),
          icon: Icons.add_outlined,
          label: 'New warranty claim',
        ),
      ],
      filters: _SvcFilters(
        searchController: _searchController,
        searchHint: 'Search claim no., title, customer, status',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
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
          valueBuilder: (ServiceTicketModel row) =>
              _customerName(row.toJson()),
        ),
        PurchaseRegisterColumn<ServiceTicketModel>(
          label: 'Status',
          valueBuilder: (ServiceTicketModel row) =>
              stringValue(row.toJson(), 'ticket_status'),
        ),
      ],
      onRowTap: (ServiceTicketModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        _openServiceShellRoute(context, '/service/warranty-claims/$id');
      },
    );
  }
}

class ServiceWorkOrderRegisterPage extends StatefulWidget {
  const ServiceWorkOrderRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ServiceWorkOrderRegisterPage> createState() =>
      _ServiceWorkOrderRegisterPageState();
}

class _ServiceWorkOrderRegisterPageState extends State<ServiceWorkOrderRegisterPage> {
  final ServiceModuleService _service = ServiceModuleService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<ServiceWorkOrderModel> _rows = const <ServiceWorkOrderModel>[];

  @override
  void initState() {
    super.initState();
    WorkingContextService.version.addListener(_onContextChanged);
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    WorkingContextService.version.removeListener(_onContextChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onContextChanged() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await hrSessionCompanyInfo();
      final filters = <String, dynamic>{'per_page': 200};
      if (info.companyId != null) {
        filters['company_id'] = info.companyId;
      }
      final response = await _service.workOrders(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <ServiceWorkOrderModel>[];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<ServiceWorkOrderModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((ServiceWorkOrderModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'work_order_no'),
            stringValue(data, 'work_order_status'),
            _nestedTicketNo(data),
            _customerName(data),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<ServiceWorkOrderModel>(
      title: 'Service work orders',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No service work orders found.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: () =>
              _openServiceShellRoute(context, '/service/work-orders/new'),
          icon: Icons.add_outlined,
          label: 'New work order',
        ),
      ],
      filters: _SvcFilters(
        searchController: _searchController,
        searchHint: 'Search WO no., ticket, customer, status',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<ServiceWorkOrderModel>(
          label: 'WO no.',
          valueBuilder: (ServiceWorkOrderModel row) =>
              stringValue(row.toJson(), 'work_order_no'),
        ),
        PurchaseRegisterColumn<ServiceWorkOrderModel>(
          label: 'Date',
          valueBuilder: (ServiceWorkOrderModel row) => displayDate(
            nullableStringValue(row.toJson(), 'work_order_date'),
          ),
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
      onRowTap: (ServiceWorkOrderModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        _openServiceShellRoute(context, '/service/work-orders/$id');
      },
    );
  }
}

class ServiceFeedbackRegisterPage extends StatefulWidget {
  const ServiceFeedbackRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ServiceFeedbackRegisterPage> createState() =>
      _ServiceFeedbackRegisterPageState();
}

class _ServiceFeedbackRegisterPageState extends State<ServiceFeedbackRegisterPage> {
  final ServiceModuleService _service = ServiceModuleService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<ServiceFeedbackModel> _rows = const <ServiceFeedbackModel>[];

  @override
  void initState() {
    super.initState();
    WorkingContextService.version.addListener(_onContextChanged);
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    WorkingContextService.version.removeListener(_onContextChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onContextChanged() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await hrSessionCompanyInfo();
      final response = await _service.feedbacks(
        filters: const {'per_page': 200},
      );
      if (!mounted) {
        return;
      }
      var rows = response.data ?? const <ServiceFeedbackModel>[];
      final cid = info.companyId;
      if (cid != null) {
        rows = rows
            .where((r) => _feedbackTicketCompanyId(r.toJson()) == cid)
            .toList(growable: false);
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<ServiceFeedbackModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((ServiceFeedbackModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'rating_overall'),
            _nestedTicketNo(data),
            stringValue(data, 'customer_feedback'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<ServiceFeedbackModel>(
      title: 'Service feedback',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No feedback records found.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: () =>
              _openServiceShellRoute(context, '/service/feedbacks/new'),
          icon: Icons.add_outlined,
          label: 'New feedback',
        ),
      ],
      filters: _SvcFilters(
        searchController: _searchController,
        searchHint: 'Search ticket, ratings, feedback text',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<ServiceFeedbackModel>(
          label: 'Date',
          valueBuilder: (ServiceFeedbackModel row) => displayDate(
            nullableStringValue(row.toJson(), 'feedback_date'),
          ),
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
      onRowTap: (ServiceFeedbackModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        _openServiceShellRoute(context, '/service/feedbacks/$id');
      },
    );
  }
}
