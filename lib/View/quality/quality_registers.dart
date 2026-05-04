import '../../screen.dart';
import '../hr/hr_workflow_dialogs.dart';
import '../purchase/purchase_register_page.dart';
import '../purchase/purchase_support.dart';

Map<String, dynamic>? _asJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

String _itemLabel(Map<String, dynamic> data) {
  final item = _asJsonMap(data['item']);
  if (item == null) {
    return '';
  }
  final code = stringValue(item, 'item_code');
  final name = stringValue(item, 'item_name');
  if (code.isEmpty) {
    return name;
  }
  if (name.isEmpty) {
    return code;
  }
  return '$code · $name';
}

String _qcPlanLabel(Map<String, dynamic> data) {
  final p = _asJsonMap(data['qcPlan']) ?? _asJsonMap(data['qc_plan']);
  if (p == null) {
    return '';
  }
  final c = stringValue(p, 'plan_code');
  final n = stringValue(p, 'plan_name');
  if (c.isEmpty) {
    return n;
  }
  if (n.isEmpty) {
    return c;
  }
  return '$c · $n';
}

void _openQualityShellRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}

class _QualityFilters extends StatelessWidget {
  const _QualityFilters({
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
                    'Session company: $companyBanner. Plans and inspections '
                    'use API company_id; other lists may filter by inspection '
                    'company client-side.',
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
                    'to scope quality lists.',
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

class QcPlanRegisterPage extends StatefulWidget {
  const QcPlanRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<QcPlanRegisterPage> createState() => _QcPlanRegisterPageState();
}

class _QcPlanRegisterPageState extends State<QcPlanRegisterPage> {
  final QualityService _service = QualityService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<QcPlanModel> _rows = const <QcPlanModel>[];

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
      final response = await _service.qcPlans(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <QcPlanModel>[];
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

  List<QcPlanModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((QcPlanModel row) {
          if (q.isEmpty) {
            return true;
          }
          return [
            row.planCode,
            row.planName,
            row.approvalStatus,
            row.qcScope,
            row.itemLabel,
            row.categoryLabel,
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<QcPlanModel>(
      title: 'QC plans',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No QC plans found.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: () =>
              _openQualityShellRoute(context, '/quality/qc-plans/new'),
          icon: Icons.add_outlined,
          label: 'New QC plan',
        ),
      ],
      filters: _QualityFilters(
        searchController: _searchController,
        searchHint: 'Search code, name, scope, item, status',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<QcPlanModel>(
          label: 'Code',
          valueBuilder: (QcPlanModel row) => row.planCode,
        ),
        PurchaseRegisterColumn<QcPlanModel>(
          label: 'Name',
          flex: 2,
          valueBuilder: (QcPlanModel row) => row.planName,
        ),
        PurchaseRegisterColumn<QcPlanModel>(
          label: 'Scope',
          valueBuilder: (QcPlanModel row) => row.qcScope,
        ),
        PurchaseRegisterColumn<QcPlanModel>(
          label: 'Status',
          valueBuilder: (QcPlanModel row) => row.approvalStatus,
        ),
      ],
      onRowTap: (QcPlanModel row) {
        final id = row.id;
        if (id == null) {
          return;
        }
        _openQualityShellRoute(context, '/quality/qc-plans/$id');
      },
    );
  }
}

class QcInspectionRegisterPage extends StatefulWidget {
  const QcInspectionRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<QcInspectionRegisterPage> createState() =>
      _QcInspectionRegisterPageState();
}

class _QcInspectionRegisterPageState extends State<QcInspectionRegisterPage> {
  final QualityService _service = QualityService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<QcInspectionModel> _rows = const <QcInspectionModel>[];

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
      final response = await _service.qcInspections(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <QcInspectionModel>[];
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

  List<QcInspectionModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((QcInspectionModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'inspection_no'),
            stringValue(data, 'inspection_status'),
            _qcPlanLabel(data),
            _itemLabel(data),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<QcInspectionModel>(
      title: 'QC inspections',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No QC inspections found.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: () => _openQualityShellRoute(
            context,
            '/quality/qc-inspections/new',
          ),
          icon: Icons.add_outlined,
          label: 'New QC inspection',
        ),
      ],
      filters: _QualityFilters(
        searchController: _searchController,
        searchHint: 'Search inspection no., plan, item, status',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<QcInspectionModel>(
          label: 'Inspection no.',
          valueBuilder: (QcInspectionModel row) =>
              stringValue(row.toJson(), 'inspection_no'),
        ),
        PurchaseRegisterColumn<QcInspectionModel>(
          label: 'Date',
          valueBuilder: (QcInspectionModel row) => displayDate(
            nullableStringValue(row.toJson(), 'inspection_date'),
          ),
        ),
        PurchaseRegisterColumn<QcInspectionModel>(
          label: 'Plan',
          flex: 2,
          valueBuilder: (QcInspectionModel row) =>
              _qcPlanLabel(row.toJson()),
        ),
        PurchaseRegisterColumn<QcInspectionModel>(
          label: 'Status',
          valueBuilder: (QcInspectionModel row) =>
              stringValue(row.toJson(), 'inspection_status'),
        ),
      ],
      onRowTap: (QcInspectionModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        _openQualityShellRoute(context, '/quality/qc-inspections/$id');
      },
    );
  }
}
