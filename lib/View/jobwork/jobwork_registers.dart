import '../../screen.dart';
import '../hr/hr_workflow_dialogs.dart';
import '../purchase/purchase_register_page.dart';
import '../purchase/purchase_support.dart';

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


// --- Registers ----------------------------------------------------------

class JobworkOrderRegisterPage extends StatefulWidget {
  const JobworkOrderRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<JobworkOrderRegisterPage> createState() =>
      _JobworkOrderRegisterPageState();
}

class _JobworkOrderRegisterPageState extends State<JobworkOrderRegisterPage> {
  final JobworkService _service = JobworkService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<JobworkOrderModel> _rows = const <JobworkOrderModel>[];

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
      final response = await _service.orders(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <JobworkOrderModel>[];
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

  List<JobworkOrderModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((JobworkOrderModel row) {
          if (q.isEmpty) {
            return true;
          }
          return [
            row.jobworkNo,
            row.processName,
            row.jobworkStatus,
            row.supplierLabel,
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<JobworkOrderModel>(
      title: 'Jobwork orders',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No jobwork orders found.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: () => _openJobworkShellRoute(context, '/jobwork/orders/new'),
          icon: Icons.add_outlined,
          label: 'New jobwork order',
        ),
      ],
      filters: _JwFilters(
        searchController: _searchController,
        searchHint: 'Search order no., process, supplier, status',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<JobworkOrderModel>(
          label: 'Order no.',
          valueBuilder: (JobworkOrderModel row) => row.jobworkNo,
        ),
        PurchaseRegisterColumn<JobworkOrderModel>(
          label: 'Date',
          valueBuilder: (JobworkOrderModel row) => displayDate(
            row.jobworkDate.isNotEmpty ? row.jobworkDate : null,
          ),
        ),
        PurchaseRegisterColumn<JobworkOrderModel>(
          label: 'Supplier',
          flex: 2,
          valueBuilder: (JobworkOrderModel row) => row.supplierLabel,
        ),
        PurchaseRegisterColumn<JobworkOrderModel>(
          label: 'Status',
          valueBuilder: (JobworkOrderModel row) => row.jobworkStatus,
        ),
      ],
      onRowTap: (JobworkOrderModel row) {
        final id = row.id;
        if (id == null) {
          return;
        }
        _openJobworkShellRoute(context, '/jobwork/orders/$id');
      },
    );
  }
}

class JobworkDispatchRegisterPage extends StatefulWidget {
  const JobworkDispatchRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<JobworkDispatchRegisterPage> createState() =>
      _JobworkDispatchRegisterPageState();
}

class _JobworkDispatchRegisterPageState
    extends State<JobworkDispatchRegisterPage> {
  final JobworkService _service = JobworkService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<JobworkDispatchModel> _rows = const <JobworkDispatchModel>[];

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
      final response = await _service.dispatches(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <JobworkDispatchModel>[];
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

  List<JobworkDispatchModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((JobworkDispatchModel row) {
          if (q.isEmpty) {
            return true;
          }
          return [
            row.dispatchNo,
            row.dispatchStatus,
            row.jobworkOrderNoLabel,
            row.supplierLabel,
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<JobworkDispatchModel>(
      title: 'Jobwork dispatches',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No jobwork dispatches found.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: () =>
              _openJobworkShellRoute(context, '/jobwork/dispatches/new'),
          icon: Icons.add_outlined,
          label: 'New dispatch',
        ),
      ],
      filters: _JwFilters(
        searchController: _searchController,
        searchHint: 'Search dispatch no., order, supplier, status',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<JobworkDispatchModel>(
          label: 'Dispatch no.',
          valueBuilder: (JobworkDispatchModel row) => row.dispatchNo,
        ),
        PurchaseRegisterColumn<JobworkDispatchModel>(
          label: 'Date',
          valueBuilder: (JobworkDispatchModel row) => displayDate(
            row.dispatchDate.isNotEmpty ? row.dispatchDate : null,
          ),
        ),
        PurchaseRegisterColumn<JobworkDispatchModel>(
          label: 'Jobwork order',
          flex: 2,
          valueBuilder: (JobworkDispatchModel row) => row.jobworkOrderNoLabel,
        ),
        PurchaseRegisterColumn<JobworkDispatchModel>(
          label: 'Status',
          valueBuilder: (JobworkDispatchModel row) => row.dispatchStatus,
        ),
      ],
      onRowTap: (JobworkDispatchModel row) {
        final id = row.id;
        if (id == null) {
          return;
        }
        _openJobworkShellRoute(context, '/jobwork/dispatches/$id');
      },
    );
  }
}

class JobworkReceiptRegisterPage extends StatefulWidget {
  const JobworkReceiptRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<JobworkReceiptRegisterPage> createState() =>
      _JobworkReceiptRegisterPageState();
}

class _JobworkReceiptRegisterPageState extends State<JobworkReceiptRegisterPage> {
  final JobworkService _service = JobworkService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<JobworkReceiptModel> _rows = const <JobworkReceiptModel>[];

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
      final response = await _service.receipts(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <JobworkReceiptModel>[];
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

  List<JobworkReceiptModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((JobworkReceiptModel row) {
          if (q.isEmpty) {
            return true;
          }
          return [
            row.receiptNo,
            row.receiptStatus,
            row.jobworkOrderNoLabel,
            row.supplierLabel,
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<JobworkReceiptModel>(
      title: 'Jobwork receipts',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No jobwork receipts found.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: () =>
              _openJobworkShellRoute(context, '/jobwork/receipts/new'),
          icon: Icons.add_outlined,
          label: 'New receipt',
        ),
      ],
      filters: _JwFilters(
        searchController: _searchController,
        searchHint: 'Search receipt no., order, supplier, status',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<JobworkReceiptModel>(
          label: 'Receipt no.',
          valueBuilder: (JobworkReceiptModel row) => row.receiptNo,
        ),
        PurchaseRegisterColumn<JobworkReceiptModel>(
          label: 'Date',
          valueBuilder: (JobworkReceiptModel row) => displayDate(
            row.receiptDate.isNotEmpty ? row.receiptDate : null,
          ),
        ),
        PurchaseRegisterColumn<JobworkReceiptModel>(
          label: 'Jobwork order',
          flex: 2,
          valueBuilder: (JobworkReceiptModel row) => row.jobworkOrderNoLabel,
        ),
        PurchaseRegisterColumn<JobworkReceiptModel>(
          label: 'Status',
          valueBuilder: (JobworkReceiptModel row) => row.receiptStatus,
        ),
      ],
      onRowTap: (JobworkReceiptModel row) {
        final id = row.id;
        if (id == null) {
          return;
        }
        _openJobworkShellRoute(context, '/jobwork/receipts/$id');
      },
    );
  }
}

class JobworkChargeRegisterPage extends StatefulWidget {
  const JobworkChargeRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<JobworkChargeRegisterPage> createState() =>
      _JobworkChargeRegisterPageState();
}

class _JobworkChargeRegisterPageState extends State<JobworkChargeRegisterPage> {
  final JobworkService _service = JobworkService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<JobworkChargeModel> _rows = const <JobworkChargeModel>[];

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
      final response = await _service.charges(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <JobworkChargeModel>[];
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

  List<JobworkChargeModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((JobworkChargeModel row) {
          if (q.isEmpty) {
            return true;
          }
          return [
            row.chargeNo,
            row.chargeStatus,
            row.jobworkOrderNoLabel,
            row.supplierLabel,
            row.totalAmount.toString(),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<JobworkChargeModel>(
      title: 'Jobwork charges',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No jobwork charges found.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: () =>
              _openJobworkShellRoute(context, '/jobwork/charges/new'),
          icon: Icons.add_outlined,
          label: 'New charge',
        ),
      ],
      filters: _JwFilters(
        searchController: _searchController,
        searchHint: 'Search charge no., order, supplier, amount, status',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<JobworkChargeModel>(
          label: 'Charge no.',
          valueBuilder: (JobworkChargeModel row) => row.chargeNo,
        ),
        PurchaseRegisterColumn<JobworkChargeModel>(
          label: 'Date',
          valueBuilder: (JobworkChargeModel row) => displayDate(
            row.chargeDate.isNotEmpty ? row.chargeDate : null,
          ),
        ),
        PurchaseRegisterColumn<JobworkChargeModel>(
          label: 'Jobwork order',
          flex: 2,
          valueBuilder: (JobworkChargeModel row) => row.jobworkOrderNoLabel,
        ),
        PurchaseRegisterColumn<JobworkChargeModel>(
          label: 'Status',
          valueBuilder: (JobworkChargeModel row) => row.chargeStatus,
        ),
      ],
      onRowTap: (JobworkChargeModel row) {
        final id = row.id;
        if (id == null) {
          return;
        }
        _openJobworkShellRoute(context, '/jobwork/charges/$id');
      },
    );
  }
}
