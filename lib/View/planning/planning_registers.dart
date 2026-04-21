import 'dart:convert';

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

int? _nestedItemCompanyId(Map<String, dynamic> data) {
  final item = _asJsonMap(data['item']);
  if (item == null) {
    return null;
  }
  return intValue(item, 'company_id');
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

String _runNo(Map<String, dynamic> data) {
  final run = _asJsonMap(data['run']);
  if (run == null) {
    return '';
  }
  return stringValue(run, 'run_no');
}

Future<void> _showJsonModelDialog<T extends JsonModel>(
  BuildContext context,
  String title,
  Future<ApiResponse<T>> Function() fetch,
) async {
  try {
    final response = await fetch();
    if (!context.mounted) {
      return;
    }
    if (response.success != true || response.data == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      return;
    }
    final text = const JsonEncoder.withIndent(
      '  ',
    ).convert(response.data!.toJson());
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(child: SelectableText(text)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _PlanningFilters extends StatelessWidget {
  const _PlanningFilters({
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
                    'Session company: $companyBanner. Lists use this company '
                    'when the API supports it; otherwise rows are filtered by '
                    'item company when possible.',
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
                    'to scope planning lists.',
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

class _StockReservationDetailDialog extends StatefulWidget {
  const _StockReservationDetailDialog({required this.reservationId});

  final int reservationId;

  @override
  State<_StockReservationDetailDialog> createState() =>
      _StockReservationDetailDialogState();
}

class _StockReservationDetailDialogState
    extends State<_StockReservationDetailDialog> {
  final PlanningService _service = PlanningService();
  bool _loading = true;
  String? _error;
  StockReservationModel? _model;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _service.stockReservation(widget.reservationId);
      if (!mounted) {
        return;
      }
      if (response.success != true || response.data == null) {
        setState(() {
          _error = response.message;
          _loading = false;
        });
        return;
      }
      setState(() {
        _model = response.data;
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

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete reservation'),
        content: const Text(
          'Delete this stock reservation? Any remaining reserved quantity '
          'will be released on the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    try {
      final response = await _service.deleteStockReservation(
        widget.reservationId,
      );
      if (!mounted) {
        return;
      }
      if (response.success != true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservation deleted.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _promptRelease() async {
    final data = _model?.toJson() ?? const <String, dynamic>{};
    final balanceStr = stringValue(data, 'balance_reserved_qty');
    final balance = double.tryParse(balanceStr) ?? 0;
    final qtyController = TextEditingController(
      text: balance > 0 ? balance.toString() : '',
    );
    final remarksController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Release quantity'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Balance reserved: $balance'),
              const SizedBox(height: AppUiConstants.spacingSm),
              AppFormTextField(
                labelText: 'Released qty',
                controller: qtyController,
                hintText: 'Quantity to release',
              ),
              const SizedBox(height: AppUiConstants.spacingSm),
              AppFormTextField(
                labelText: 'Remarks (optional)',
                controller: remarksController,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Release'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    final qty = double.tryParse(qtyController.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid released quantity.')),
      );
      return;
    }
    try {
      final body = StockReservationModel(<String, dynamic>{
        'released_qty': qty,
        if (remarksController.text.trim().isNotEmpty)
          'remarks': remarksController.text.trim(),
      });
      final response = await _service.releaseStockReservation(
        widget.reservationId,
        body,
      );
      if (!mounted) {
        return;
      }
      if (response.success != true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservation released.')),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AlertDialog(
        content: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_error != null) {
      return AlertDialog(
        title: const Text('Reservation'),
        content: Text(_error!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    }
    final text = const JsonEncoder.withIndent(
      '  ',
    ).convert(_model!.toJson());
    final status = stringValue(_model!.toJson(), 'status');
    final canRelease = status.isEmpty || status == 'active';

    return AlertDialog(
      title: Text('Reservation #${widget.reservationId}'),
      content: SizedBox(
        width: 560,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                if (canRelease)
                  FilledButton.tonal(
                    onPressed: _promptRelease,
                    child: const Text('Release qty'),
                  ),
                FilledButton.tonal(
                  onPressed: _confirmDelete,
                  child: const Text('Delete'),
                ),
                OutlinedButton(
                  onPressed: _load,
                  child: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            Expanded(
              child: SingleChildScrollView(child: SelectableText(text)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _MrpRunDetailDialog extends StatefulWidget {
  const _MrpRunDetailDialog({required this.runId});

  final int runId;

  @override
  State<_MrpRunDetailDialog> createState() => _MrpRunDetailDialogState();
}

class _MrpRunDetailDialogState extends State<_MrpRunDetailDialog> {
  final PlanningService _service = PlanningService();
  bool _loading = true;
  String? _error;
  MrpRunModel? _model;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _service.mrpRun(widget.runId);
      if (!mounted) {
        return;
      }
      if (response.success != true || response.data == null) {
        setState(() {
          _error = response.message;
          _loading = false;
        });
        return;
      }
      setState(() {
        _model = response.data;
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

  Future<void> _runAction(Future<ApiResponse<MrpRunModel>> Function() fn) async {
    setState(() => _busy = true);
    try {
      final response = await fn();
      if (!mounted) {
        return;
      }
      if (response.success != true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('MRP run updated.')),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _process() => _runAction(
    () => _service.processMrpRun(widget.runId, MrpRunModel(<String, dynamic>{})),
  );

  Future<void> _cancel() => _runAction(
    () => _service.cancelMrpRun(widget.runId, MrpRunModel(<String, dynamic>{})),
  );

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete MRP run'),
        content: const Text(
          'Only draft, failed, or cancelled runs can be deleted. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      final response = await _service.deleteMrpRun(widget.runId);
      if (!mounted) {
        return;
      }
      if (response.success != true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('MRP run deleted.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AlertDialog(
        content: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_error != null) {
      return AlertDialog(
        title: const Text('MRP run'),
        content: Text(_error!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    }
    final data = _model!.toJson();
    final status = stringValue(data, 'run_status');
    final canProcess = status == 'draft' || status == 'failed';
    final canCancel = status != 'cancelled';
    final canDelete =
        status == 'draft' || status == 'failed' || status == 'cancelled';
    final text = const JsonEncoder.withIndent('  ').convert(data);

    return AlertDialog(
      title: Text('MRP run #${widget.runId}'),
      content: SizedBox(
        width: 560,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_busy)
              const LinearProgressIndicator()
            else
              const SizedBox(height: 4),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                if (canProcess)
                  FilledButton(
                    onPressed: _busy ? null : _process,
                    child: const Text('Process'),
                  ),
                if (canCancel)
                  FilledButton.tonal(
                    onPressed: _busy ? null : _cancel,
                    child: const Text('Cancel run'),
                  ),
                if (canDelete)
                  FilledButton.tonal(
                    onPressed: _busy ? null : _delete,
                    child: const Text('Delete'),
                  ),
                OutlinedButton(
                  onPressed: _busy ? null : _load,
                  child: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            Expanded(
              child: SingleChildScrollView(child: SelectableText(text)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _MrpRecommendationDetailDialog extends StatefulWidget {
  const _MrpRecommendationDetailDialog({required this.recommendationId});

  final int recommendationId;

  @override
  State<_MrpRecommendationDetailDialog> createState() =>
      _MrpRecommendationDetailDialogState();
}

class _MrpRecommendationDetailDialogState
    extends State<_MrpRecommendationDetailDialog> {
  final PlanningService _service = PlanningService();
  bool _loading = true;
  String? _error;
  MrpRecommendationModel? _model;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _service.mrpRecommendation(
        widget.recommendationId,
      );
      if (!mounted) {
        return;
      }
      if (response.success != true || response.data == null) {
        setState(() {
          _error = response.message;
          _loading = false;
        });
        return;
      }
      setState(() {
        _model = response.data;
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

  Future<void> _act(
    Future<ApiResponse<MrpRecommendationModel>> Function() fn,
  ) async {
    setState(() => _busy = true);
    try {
      final response = await fn();
      if (!mounted) {
        return;
      }
      if (response.success != true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recommendation updated.')),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AlertDialog(
        content: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_error != null) {
      return AlertDialog(
        title: const Text('MRP recommendation'),
        content: Text(_error!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    }
    final data = _model!.toJson();
    final st = stringValue(data, 'recommendation_status');
    final canApprove = st == 'open';
    final canReject = st == 'open' || st == 'approved';
    final canConvert = st == 'open' || st == 'approved';
    final canCancel = st != 'converted';
    final text = const JsonEncoder.withIndent('  ').convert(data);

    return AlertDialog(
      title: Text('Recommendation #${widget.recommendationId}'),
      content: SizedBox(
        width: 560,
        height: 440,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_busy)
              const LinearProgressIndicator()
            else
              const SizedBox(height: 4),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                if (canApprove)
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.approveMrpRecommendation(
                                widget.recommendationId,
                                MrpRecommendationModel(<String, dynamic>{}),
                              ),
                            ),
                    child: const Text('Approve'),
                  ),
                if (canReject)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.rejectMrpRecommendation(
                                widget.recommendationId,
                                MrpRecommendationModel(<String, dynamic>{}),
                              ),
                            ),
                    child: const Text('Reject'),
                  ),
                if (canConvert)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.convertMrpRecommendation(
                                widget.recommendationId,
                                MrpRecommendationModel(<String, dynamic>{}),
                              ),
                            ),
                    child: const Text('Convert'),
                  ),
                if (canCancel)
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.cancelMrpRecommendation(
                                widget.recommendationId,
                                MrpRecommendationModel(<String, dynamic>{}),
                              ),
                            ),
                    child: const Text('Cancel'),
                  ),
                OutlinedButton(
                  onPressed: _busy ? null : _load,
                  child: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            Expanded(
              child: SingleChildScrollView(child: SelectableText(text)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// --- Register pages -------------------------------------------------

class StockReservationRegisterPage extends StatefulWidget {
  const StockReservationRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<StockReservationRegisterPage> createState() =>
      _StockReservationRegisterPageState();
}

class _StockReservationRegisterPageState
    extends State<StockReservationRegisterPage> {
  final PlanningService _service = PlanningService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<StockReservationModel> _rows = const <StockReservationModel>[];

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

  void _onContextChanged() {
    _load();
  }

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
      final response = await _service.stockReservations(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <StockReservationModel>[];
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

  List<StockReservationModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((StockReservationModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          final blob = [
            stringValue(data, 'reference_type'),
            '${intValue(data, 'reference_id') ?? ''}',
            stringValue(data, 'status'),
            _itemLabel(data),
          ].join(' ').toLowerCase();
          return blob.contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<StockReservationModel>(
      title: 'Stock reservations',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No stock reservations found.',
      actions: const <Widget>[],
      filters: _PlanningFilters(
        searchController: _searchController,
        searchHint: 'Search reference, item, status',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<StockReservationModel>(
          label: 'Ref',
          flex: 3,
          valueBuilder: (StockReservationModel row) {
            final data = row.toJson();
            return '${stringValue(data, 'reference_type')} '
                '#${intValue(data, 'reference_id') ?? '—'}';
          },
        ),
        PurchaseRegisterColumn<StockReservationModel>(
          label: 'Item',
          flex: 3,
          valueBuilder: (StockReservationModel row) =>
              _itemLabel(row.toJson()),
        ),
        PurchaseRegisterColumn<StockReservationModel>(
          label: 'Qty',
          valueBuilder: (StockReservationModel row) =>
              stringValue(row.toJson(), 'reserved_qty'),
        ),
        PurchaseRegisterColumn<StockReservationModel>(
          label: 'Status',
          valueBuilder: (StockReservationModel row) =>
              stringValue(row.toJson(), 'status'),
        ),
      ],
      onRowTap: (StockReservationModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        showDialog<void>(
          context: context,
          builder: (ctx) => _StockReservationDetailDialog(reservationId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
      },
    );
  }
}

class ItemPlanningPolicyRegisterPage extends StatefulWidget {
  const ItemPlanningPolicyRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ItemPlanningPolicyRegisterPage> createState() =>
      _ItemPlanningPolicyRegisterPageState();
}

class _ItemPlanningPolicyRegisterPageState
    extends State<ItemPlanningPolicyRegisterPage> {
  final PlanningService _service = PlanningService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<ItemPlanningPolicyModel> _rows = const <ItemPlanningPolicyModel>[];

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
      final response = await _service.itemPolicies(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <ItemPlanningPolicyModel>[];
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

  List<ItemPlanningPolicyModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((ItemPlanningPolicyModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return _itemLabel(data).toLowerCase().contains(q) ||
              stringValue(data, 'planning_method').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<ItemPlanningPolicyModel>(
      title: 'Item planning policies',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No item planning policies found.',
      actions: const <Widget>[],
      filters: _PlanningFilters(
        searchController: _searchController,
        searchHint: 'Search item, planning method',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<ItemPlanningPolicyModel>(
          label: 'Item',
          flex: 3,
          valueBuilder: (ItemPlanningPolicyModel row) =>
              _itemLabel(row.toJson()),
        ),
        PurchaseRegisterColumn<ItemPlanningPolicyModel>(
          label: 'Method',
          valueBuilder: (ItemPlanningPolicyModel row) =>
              stringValue(row.toJson(), 'planning_method'),
        ),
        PurchaseRegisterColumn<ItemPlanningPolicyModel>(
          label: 'Reorder lvl.',
          valueBuilder: (ItemPlanningPolicyModel row) =>
              stringValue(row.toJson(), 'reorder_level_qty'),
        ),
      ],
      onRowTap: (ItemPlanningPolicyModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        _showJsonModelDialog<ItemPlanningPolicyModel>(
          context,
          'Item policy #$id',
          () => _service.itemPolicy(id),
        );
      },
    );
  }
}

class PlanningCalendarRegisterPage extends StatefulWidget {
  const PlanningCalendarRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PlanningCalendarRegisterPage> createState() =>
      _PlanningCalendarRegisterPageState();
}

class _PlanningCalendarRegisterPageState
    extends State<PlanningCalendarRegisterPage> {
  final PlanningService _service = PlanningService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<PlanningCalendarModel> _rows = const <PlanningCalendarModel>[];

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
      final response = await _service.calendars(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <PlanningCalendarModel>[];
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

  List<PlanningCalendarModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((PlanningCalendarModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'calendar_code'),
            stringValue(data, 'calendar_name'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<PlanningCalendarModel>(
      title: 'Planning calendars',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No planning calendars found.',
      actions: const <Widget>[],
      filters: _PlanningFilters(
        searchController: _searchController,
        searchHint: 'Search code or name',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<PlanningCalendarModel>(
          label: 'Code',
          valueBuilder: (PlanningCalendarModel row) =>
              stringValue(row.toJson(), 'calendar_code'),
        ),
        PurchaseRegisterColumn<PlanningCalendarModel>(
          label: 'Name',
          flex: 3,
          valueBuilder: (PlanningCalendarModel row) =>
              stringValue(row.toJson(), 'calendar_name'),
        ),
      ],
      onRowTap: (PlanningCalendarModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        _showJsonModelDialog<PlanningCalendarModel>(
          context,
          'Planning calendar #$id',
          () => _service.calendar(id),
        );
      },
    );
  }
}

class MrpRunRegisterPage extends StatefulWidget {
  const MrpRunRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MrpRunRegisterPage> createState() => _MrpRunRegisterPageState();
}

class _MrpRunRegisterPageState extends State<MrpRunRegisterPage> {
  final PlanningService _service = PlanningService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<MrpRunModel> _rows = const <MrpRunModel>[];

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
      final response = await _service.mrpRuns(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <MrpRunModel>[];
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

  List<MrpRunModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((MrpRunModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'run_no'),
            stringValue(data, 'run_status'),
            stringValue(data, 'run_mode'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<MrpRunModel>(
      title: 'MRP runs',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No MRP runs found.',
      actions: const <Widget>[],
      filters: _PlanningFilters(
        searchController: _searchController,
        searchHint: 'Search run no., status, mode',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<MrpRunModel>(
          label: 'Run no.',
          valueBuilder: (MrpRunModel row) =>
              stringValue(row.toJson(), 'run_no'),
        ),
        PurchaseRegisterColumn<MrpRunModel>(
          label: 'Run date',
          valueBuilder: (MrpRunModel row) => displayDate(
            nullableStringValue(row.toJson(), 'run_date'),
          ),
        ),
        PurchaseRegisterColumn<MrpRunModel>(
          label: 'Status',
          valueBuilder: (MrpRunModel row) =>
              stringValue(row.toJson(), 'run_status'),
        ),
      ],
      onRowTap: (MrpRunModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        showDialog<void>(
          context: context,
          builder: (ctx) => _MrpRunDetailDialog(runId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
      },
    );
  }
}

class MrpDemandRegisterPage extends StatefulWidget {
  const MrpDemandRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MrpDemandRegisterPage> createState() => _MrpDemandRegisterPageState();
}

class _MrpDemandRegisterPageState extends State<MrpDemandRegisterPage> {
  final PlanningService _service = PlanningService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<MrpDemandModel> _rows = const <MrpDemandModel>[];

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
      final response = await _service.mrpDemands(
        filters: const {'per_page': 200},
      );
      if (!mounted) {
        return;
      }
      var rows = response.data ?? const <MrpDemandModel>[];
      final cid = info.companyId;
      if (cid != null) {
        rows = rows
            .where((r) => _nestedItemCompanyId(r.toJson()) == cid)
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

  List<MrpDemandModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((MrpDemandModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            _runNo(data),
            _itemLabel(data),
            stringValue(data, 'demand_source'),
            stringValue(data, 'demand_qty'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<MrpDemandModel>(
      title: 'MRP demands',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No MRP demands found.',
      actions: const <Widget>[],
      filters: _PlanningFilters(
        searchController: _searchController,
        searchHint: 'Search run, item, source, qty',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<MrpDemandModel>(
          label: 'Run',
          valueBuilder: (MrpDemandModel row) => _runNo(row.toJson()),
        ),
        PurchaseRegisterColumn<MrpDemandModel>(
          label: 'Item',
          flex: 3,
          valueBuilder: (MrpDemandModel row) => _itemLabel(row.toJson()),
        ),
        PurchaseRegisterColumn<MrpDemandModel>(
          label: 'Source',
          valueBuilder: (MrpDemandModel row) =>
              stringValue(row.toJson(), 'demand_source'),
        ),
        PurchaseRegisterColumn<MrpDemandModel>(
          label: 'Qty',
          valueBuilder: (MrpDemandModel row) =>
              stringValue(row.toJson(), 'demand_qty'),
        ),
      ],
      onRowTap: (MrpDemandModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        _showJsonModelDialog<MrpDemandModel>(
          context,
          'MRP demand #$id',
          () => _service.mrpDemand(id),
        );
      },
    );
  }
}

class MrpSupplyRegisterPage extends StatefulWidget {
  const MrpSupplyRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MrpSupplyRegisterPage> createState() => _MrpSupplyRegisterPageState();
}

class _MrpSupplyRegisterPageState extends State<MrpSupplyRegisterPage> {
  final PlanningService _service = PlanningService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<MrpSupplyModel> _rows = const <MrpSupplyModel>[];

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
      final response = await _service.mrpSupplies(
        filters: const {'per_page': 200},
      );
      if (!mounted) {
        return;
      }
      var rows = response.data ?? const <MrpSupplyModel>[];
      final cid = info.companyId;
      if (cid != null) {
        rows = rows
            .where((r) => _nestedItemCompanyId(r.toJson()) == cid)
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

  List<MrpSupplyModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((MrpSupplyModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            _runNo(data),
            _itemLabel(data),
            stringValue(data, 'supply_source'),
            stringValue(data, 'supply_qty'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<MrpSupplyModel>(
      title: 'MRP supplies',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No MRP supplies found.',
      actions: const <Widget>[],
      filters: _PlanningFilters(
        searchController: _searchController,
        searchHint: 'Search run, item, source, qty',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<MrpSupplyModel>(
          label: 'Run',
          valueBuilder: (MrpSupplyModel row) => _runNo(row.toJson()),
        ),
        PurchaseRegisterColumn<MrpSupplyModel>(
          label: 'Item',
          flex: 3,
          valueBuilder: (MrpSupplyModel row) => _itemLabel(row.toJson()),
        ),
        PurchaseRegisterColumn<MrpSupplyModel>(
          label: 'Source',
          valueBuilder: (MrpSupplyModel row) =>
              stringValue(row.toJson(), 'supply_source'),
        ),
        PurchaseRegisterColumn<MrpSupplyModel>(
          label: 'Qty',
          valueBuilder: (MrpSupplyModel row) =>
              stringValue(row.toJson(), 'supply_qty'),
        ),
      ],
      onRowTap: (MrpSupplyModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        _showJsonModelDialog<MrpSupplyModel>(
          context,
          'MRP supply #$id',
          () => _service.mrpSupply(id),
        );
      },
    );
  }
}

class MrpNetRequirementRegisterPage extends StatefulWidget {
  const MrpNetRequirementRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MrpNetRequirementRegisterPage> createState() =>
      _MrpNetRequirementRegisterPageState();
}

class _MrpNetRequirementRegisterPageState
    extends State<MrpNetRequirementRegisterPage> {
  final PlanningService _service = PlanningService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<MrpNetRequirementModel> _rows = const <MrpNetRequirementModel>[];

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
      final response = await _service.mrpNetRequirements(
        filters: const {'per_page': 200},
      );
      if (!mounted) {
        return;
      }
      var rows = response.data ?? const <MrpNetRequirementModel>[];
      final cid = info.companyId;
      if (cid != null) {
        rows = rows
            .where((r) => _nestedItemCompanyId(r.toJson()) == cid)
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

  List<MrpNetRequirementModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((MrpNetRequirementModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            _runNo(data),
            _itemLabel(data),
            stringValue(data, 'shortage_qty'),
            stringValue(data, 'recommended_action'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<MrpNetRequirementModel>(
      title: 'MRP net requirements',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No MRP net requirements found.',
      actions: const <Widget>[],
      filters: _PlanningFilters(
        searchController: _searchController,
        searchHint: 'Search run, item, shortage, action',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<MrpNetRequirementModel>(
          label: 'Run',
          valueBuilder: (MrpNetRequirementModel row) => _runNo(row.toJson()),
        ),
        PurchaseRegisterColumn<MrpNetRequirementModel>(
          label: 'Item',
          flex: 3,
          valueBuilder: (MrpNetRequirementModel row) =>
              _itemLabel(row.toJson()),
        ),
        PurchaseRegisterColumn<MrpNetRequirementModel>(
          label: 'Shortage',
          valueBuilder: (MrpNetRequirementModel row) =>
              stringValue(row.toJson(), 'shortage_qty'),
        ),
        PurchaseRegisterColumn<MrpNetRequirementModel>(
          label: 'Action',
          valueBuilder: (MrpNetRequirementModel row) =>
              stringValue(row.toJson(), 'recommended_action'),
        ),
      ],
      onRowTap: (MrpNetRequirementModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        _showJsonModelDialog<MrpNetRequirementModel>(
          context,
          'MRP net requirement #$id',
          () => _service.mrpNetRequirement(id),
        );
      },
    );
  }
}

class MrpRecommendationRegisterPage extends StatefulWidget {
  const MrpRecommendationRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MrpRecommendationRegisterPage> createState() =>
      _MrpRecommendationRegisterPageState();
}

class _MrpRecommendationRegisterPageState
    extends State<MrpRecommendationRegisterPage> {
  final PlanningService _service = PlanningService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<MrpRecommendationModel> _rows = const <MrpRecommendationModel>[];

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
      final response = await _service.mrpRecommendations(
        filters: const {'per_page': 200},
      );
      if (!mounted) {
        return;
      }
      var rows = response.data ?? const <MrpRecommendationModel>[];
      final cid = info.companyId;
      if (cid != null) {
        rows = rows
            .where((r) => _nestedItemCompanyId(r.toJson()) == cid)
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

  List<MrpRecommendationModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((MrpRecommendationModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            _runNo(data),
            _itemLabel(data),
            stringValue(data, 'recommendation_type'),
            stringValue(data, 'recommendation_status'),
            stringValue(data, 'recommended_qty'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<MrpRecommendationModel>(
      title: 'MRP recommendations',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No MRP recommendations found.',
      actions: const <Widget>[],
      filters: _PlanningFilters(
        searchController: _searchController,
        searchHint: 'Search run, item, type, status',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<MrpRecommendationModel>(
          label: 'Run',
          valueBuilder: (MrpRecommendationModel row) => _runNo(row.toJson()),
        ),
        PurchaseRegisterColumn<MrpRecommendationModel>(
          label: 'Item',
          flex: 3,
          valueBuilder: (MrpRecommendationModel row) =>
              _itemLabel(row.toJson()),
        ),
        PurchaseRegisterColumn<MrpRecommendationModel>(
          label: 'Type',
          valueBuilder: (MrpRecommendationModel row) =>
              stringValue(row.toJson(), 'recommendation_type'),
        ),
        PurchaseRegisterColumn<MrpRecommendationModel>(
          label: 'Status',
          valueBuilder: (MrpRecommendationModel row) =>
              stringValue(row.toJson(), 'recommendation_status'),
        ),
      ],
      onRowTap: (MrpRecommendationModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        showDialog<void>(
          context: context,
          builder: (ctx) =>
              _MrpRecommendationDetailDialog(recommendationId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
      },
    );
  }
}
