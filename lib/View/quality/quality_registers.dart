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

String _qcInspectionNo(Map<String, dynamic> data) {
  final i = _asJsonMap(data['inspection']);
  if (i == null) {
    return '';
  }
  return stringValue(i, 'inspection_no');
}

int? _inspectionCompanyId(Map<String, dynamic> data) {
  final i = _asJsonMap(data['inspection']);
  if (i == null) {
    return null;
  }
  return intValue(i, 'company_id');
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

class _QcPlanDetailDialog extends StatefulWidget {
  const _QcPlanDetailDialog({required this.planId});

  final int planId;

  @override
  State<_QcPlanDetailDialog> createState() => _QcPlanDetailDialogState();
}

class _QcPlanDetailDialogState extends State<_QcPlanDetailDialog> {
  final QualityService _service = QualityService();
  bool _loading = true;
  String? _error;
  QcPlanModel? _model;
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
      final response = await _service.qcPlan(widget.planId);
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

  Future<void> _act(Future<ApiResponse<QcPlanModel>> Function() fn) async {
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
        const SnackBar(content: Text('QC plan updated.')),
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

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete QC plan'),
        content: const Text(
          'Approved QC plans cannot be deleted. Continue?',
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
    setState(() => _busy = true);
    try {
      final response = await _service.deleteQcPlan(widget.planId);
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
        const SnackBar(content: Text('QC plan deleted.')),
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
        title: const Text('QC plan'),
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
    final st = stringValue(data, 'approval_status');
    final emptyBody = QcPlanModel(<String, dynamic>{});
    final canApprove = st != 'approved' && st != 'obsolete';
    final canDeactivate =
        st != 'inactive' && st != 'obsolete';
    final canObsolete = st != 'obsolete';
    final canDelete = st != 'approved';
    final text = const JsonEncoder.withIndent('  ').convert(data);

    return AlertDialog(
      title: Text('QC plan #${widget.planId}'),
      content: SizedBox(
        width: 560,
        height: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_busy)
              const LinearProgressIndicator()
            else
              const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: AppUiConstants.spacingSm,
                  runSpacing: AppUiConstants.spacingSm,
                  children: [
                    if (canApprove)
                      FilledButton(
                        onPressed: _busy
                            ? null
                            : () => _act(
                                  () => _service.approveQcPlan(
                                    widget.planId,
                                    emptyBody,
                                  ),
                                ),
                        child: const Text('Approve'),
                      ),
                    if (canDeactivate)
                      FilledButton.tonal(
                        onPressed: _busy
                            ? null
                            : () => _act(
                                  () => _service.deactivateQcPlan(
                                    widget.planId,
                                    emptyBody,
                                  ),
                                ),
                        child: const Text('Deactivate'),
                      ),
                    if (canObsolete)
                      FilledButton.tonal(
                        onPressed: _busy
                            ? null
                            : () => _act(
                                  () => _service.obsoleteQcPlan(
                                    widget.planId,
                                    emptyBody,
                                  ),
                                ),
                        child: const Text('Obsolete'),
                      ),
                    if (canDelete)
                      OutlinedButton(
                        onPressed: _busy ? null : _delete,
                        child: const Text('Delete'),
                      ),
                    OutlinedButton(
                      onPressed: _busy ? null : _load,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            SizedBox(
              height: 280,
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

class _QcInspectionDetailDialog extends StatefulWidget {
  const _QcInspectionDetailDialog({required this.inspectionId});

  final int inspectionId;

  @override
  State<_QcInspectionDetailDialog> createState() =>
      _QcInspectionDetailDialogState();
}

class _QcInspectionDetailDialogState extends State<_QcInspectionDetailDialog> {
  final QualityService _service = QualityService();
  bool _loading = true;
  String? _error;
  QcInspectionModel? _model;
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
      final response = await _service.qcInspection(widget.inspectionId);
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
    Future<ApiResponse<QcInspectionModel>> Function() fn,
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
        const SnackBar(content: Text('QC inspection updated.')),
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

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete QC inspection'),
        content: const Text(
          'Only draft inspections can be deleted. Continue?',
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
    setState(() => _busy = true);
    try {
      final response = await _service.deleteQcInspection(widget.inspectionId);
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
        const SnackBar(content: Text('Inspection deleted.')),
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
        title: const Text('QC inspection'),
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
    final st = stringValue(data, 'inspection_status');
    final b = QcInspectionModel(<String, dynamic>{});
    final canStart = st == 'draft';
    final canComplete = st == 'draft' || st == 'in_progress';
    final canApprove = st == 'completed';
    final canReject = st == 'completed' || st == 'approved';
    final canCancel = st != 'approved';
    final canDelete = st == 'draft';
    final text = const JsonEncoder.withIndent('  ').convert(data);

    return AlertDialog(
      title: Text('QC inspection #${widget.inspectionId}'),
      content: SizedBox(
        width: 560,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_busy)
              const LinearProgressIndicator()
            else
              const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: AppUiConstants.spacingSm,
                  runSpacing: AppUiConstants.spacingSm,
                  children: [
                    if (canStart)
                      FilledButton(
                        onPressed: _busy
                            ? null
                            : () => _act(
                                  () => _service.startQcInspection(
                                    widget.inspectionId,
                                    b,
                                  ),
                                ),
                        child: const Text('Start'),
                      ),
                    if (canComplete)
                      FilledButton.tonal(
                        onPressed: _busy
                            ? null
                            : () => _act(
                                  () => _service.completeQcInspection(
                                    widget.inspectionId,
                                    b,
                                  ),
                                ),
                        child: const Text('Complete'),
                      ),
                    if (canApprove)
                      FilledButton(
                        onPressed: _busy
                            ? null
                            : () => _act(
                                  () => _service.approveQcInspection(
                                    widget.inspectionId,
                                    b,
                                  ),
                                ),
                        child: const Text('Approve'),
                      ),
                    if (canReject)
                      FilledButton.tonal(
                        onPressed: _busy
                            ? null
                            : () => _act(
                                  () => _service.rejectQcInspection(
                                    widget.inspectionId,
                                    b,
                                  ),
                                ),
                        child: const Text('Reject'),
                      ),
                    if (canCancel)
                      OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => _act(
                                  () => _service.cancelQcInspection(
                                    widget.inspectionId,
                                    b,
                                  ),
                                ),
                        child: const Text('Cancel'),
                      ),
                    if (canDelete)
                      OutlinedButton(
                        onPressed: _busy ? null : _delete,
                        child: const Text('Delete'),
                      ),
                    OutlinedButton(
                      onPressed: _busy ? null : _load,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            SizedBox(
              height: 260,
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

class _QcResultActionDetailDialog extends StatefulWidget {
  const _QcResultActionDetailDialog({required this.actionId});

  final int actionId;

  @override
  State<_QcResultActionDetailDialog> createState() =>
      _QcResultActionDetailDialogState();
}

class _QcResultActionDetailDialogState extends State<_QcResultActionDetailDialog> {
  final QualityService _service = QualityService();
  bool _loading = true;
  String? _error;
  QcResultActionModel? _model;
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
      final response = await _service.qcResultAction(widget.actionId);
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
    Future<ApiResponse<QcResultActionModel>> Function() fn,
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
        const SnackBar(content: Text('Result action updated.')),
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

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete result action'),
        content: const Text(
          'Only pending actions can be deleted. Continue?',
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
      final response = await _service.deleteQcResultAction(widget.actionId);
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
        const SnackBar(content: Text('Action deleted.')),
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
        title: const Text('QC result action'),
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
    final st = stringValue(data, 'action_status');
    final b = QcResultActionModel(<String, dynamic>{});
    final canComplete = st == 'pending';
    final canCancel = st != 'completed';
    final canDelete = st == 'pending';
    final text = const JsonEncoder.withIndent('  ').convert(data);

    return AlertDialog(
      title: Text('Result action #${widget.actionId}'),
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
                if (canComplete)
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.completeQcResultAction(
                                widget.actionId,
                                b,
                              ),
                            ),
                    child: const Text('Complete'),
                  ),
                if (canCancel)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.cancelQcResultAction(
                                widget.actionId,
                                b,
                              ),
                            ),
                    child: const Text('Cancel action'),
                  ),
                if (canDelete)
                  OutlinedButton(
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

class _QcNonConformanceDetailDialog extends StatefulWidget {
  const _QcNonConformanceDetailDialog({required this.logId});

  final int logId;

  @override
  State<_QcNonConformanceDetailDialog> createState() =>
      _QcNonConformanceDetailDialogState();
}

class _QcNonConformanceDetailDialogState
    extends State<_QcNonConformanceDetailDialog> {
  final QualityService _service = QualityService();
  bool _loading = true;
  String? _error;
  QcNonConformanceLogModel? _model;
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
      final response = await _service.qcNonConformanceLog(widget.logId);
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
    Future<ApiResponse<QcNonConformanceLogModel>> Function() fn,
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
        const SnackBar(content: Text('NCR updated.')),
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

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete NCR log'),
        content: const Text(
          'Closed or waived logs cannot be deleted. Continue?',
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
      final response = await _service.deleteQcNonConformanceLog(widget.logId);
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
        const SnackBar(content: Text('NCR deleted.')),
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
        title: const Text('Non-conformance'),
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
    final st = stringValue(data, 'closure_status');
    final b = QcNonConformanceLogModel(<String, dynamic>{});
    final canClose = st != 'closed' && st != 'waived';
    final canWaive = st != 'closed' && st != 'waived';
    final canDelete = st != 'closed' && st != 'waived';
    final text = const JsonEncoder.withIndent('  ').convert(data);

    return AlertDialog(
      title: Text('NCR #${widget.logId}'),
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
                if (canClose)
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.closeQcNonConformanceLog(
                                widget.logId,
                                b,
                              ),
                            ),
                    child: const Text('Close'),
                  ),
                if (canWaive)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.waiveQcNonConformanceLog(
                                widget.logId,
                                b,
                              ),
                            ),
                    child: const Text('Waive'),
                  ),
                if (canDelete)
                  OutlinedButton(
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
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'plan_code'),
            stringValue(data, 'plan_name'),
            stringValue(data, 'approval_status'),
            stringValue(data, 'qc_scope'),
            _itemLabel(data),
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
      actions: const <Widget>[],
      filters: _QualityFilters(
        searchController: _searchController,
        searchHint: 'Search code, name, scope, item, status',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<QcPlanModel>(
          label: 'Code',
          valueBuilder: (QcPlanModel row) =>
              stringValue(row.toJson(), 'plan_code'),
        ),
        PurchaseRegisterColumn<QcPlanModel>(
          label: 'Name',
          flex: 2,
          valueBuilder: (QcPlanModel row) =>
              stringValue(row.toJson(), 'plan_name'),
        ),
        PurchaseRegisterColumn<QcPlanModel>(
          label: 'Scope',
          valueBuilder: (QcPlanModel row) =>
              stringValue(row.toJson(), 'qc_scope'),
        ),
        PurchaseRegisterColumn<QcPlanModel>(
          label: 'Status',
          valueBuilder: (QcPlanModel row) =>
              stringValue(row.toJson(), 'approval_status'),
        ),
      ],
      onRowTap: (QcPlanModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        showDialog<void>(
          context: context,
          builder: (ctx) => _QcPlanDetailDialog(planId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
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
      actions: const <Widget>[],
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
        showDialog<void>(
          context: context,
          builder: (ctx) => _QcInspectionDetailDialog(inspectionId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
      },
    );
  }
}

class QcResultActionRegisterPage extends StatefulWidget {
  const QcResultActionRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<QcResultActionRegisterPage> createState() =>
      _QcResultActionRegisterPageState();
}

class _QcResultActionRegisterPageState extends State<QcResultActionRegisterPage> {
  final QualityService _service = QualityService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<QcResultActionModel> _rows = const <QcResultActionModel>[];

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
      final response = await _service.qcResultActions(
        filters: const {'per_page': 200},
      );
      if (!mounted) {
        return;
      }
      var rows = response.data ?? const <QcResultActionModel>[];
      final cid = info.companyId;
      if (cid != null) {
        rows = rows
            .where((r) => _inspectionCompanyId(r.toJson()) == cid)
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

  List<QcResultActionModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((QcResultActionModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'action_type'),
            stringValue(data, 'action_status'),
            _qcInspectionNo(data),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<QcResultActionModel>(
      title: 'QC result actions',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No QC result actions found.',
      actions: const <Widget>[],
      filters: _QualityFilters(
        searchController: _searchController,
        searchHint: 'Search inspection, action type, status',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<QcResultActionModel>(
          label: 'Inspection',
          flex: 2,
          valueBuilder: (QcResultActionModel row) =>
              _qcInspectionNo(row.toJson()),
        ),
        PurchaseRegisterColumn<QcResultActionModel>(
          label: 'Type',
          valueBuilder: (QcResultActionModel row) =>
              stringValue(row.toJson(), 'action_type'),
        ),
        PurchaseRegisterColumn<QcResultActionModel>(
          label: 'Status',
          valueBuilder: (QcResultActionModel row) =>
              stringValue(row.toJson(), 'action_status'),
        ),
      ],
      onRowTap: (QcResultActionModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        showDialog<void>(
          context: context,
          builder: (ctx) => _QcResultActionDetailDialog(actionId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
      },
    );
  }
}

class QcNonConformanceLogRegisterPage extends StatefulWidget {
  const QcNonConformanceLogRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<QcNonConformanceLogRegisterPage> createState() =>
      _QcNonConformanceLogRegisterPageState();
}

class _QcNonConformanceLogRegisterPageState
    extends State<QcNonConformanceLogRegisterPage> {
  final QualityService _service = QualityService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<QcNonConformanceLogModel> _rows = const <QcNonConformanceLogModel>[];

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
      final response = await _service.qcNonConformanceLogs(
        filters: const {'per_page': 200},
      );
      if (!mounted) {
        return;
      }
      var rows = response.data ?? const <QcNonConformanceLogModel>[];
      final cid = info.companyId;
      if (cid != null) {
        rows = rows
            .where((r) => _inspectionCompanyId(r.toJson()) == cid)
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

  List<QcNonConformanceLogModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((QcNonConformanceLogModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'defect_code'),
            stringValue(data, 'defect_name'),
            stringValue(data, 'severity'),
            stringValue(data, 'closure_status'),
            _qcInspectionNo(data),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<QcNonConformanceLogModel>(
      title: 'Non-conformance logs',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No non-conformance logs found.',
      actions: const <Widget>[],
      filters: _QualityFilters(
        searchController: _searchController,
        searchHint: 'Search defect, inspection, severity, closure',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<QcNonConformanceLogModel>(
          label: 'Defect',
          flex: 2,
          valueBuilder: (QcNonConformanceLogModel row) =>
              stringValue(row.toJson(), 'defect_name'),
        ),
        PurchaseRegisterColumn<QcNonConformanceLogModel>(
          label: 'Inspection',
          valueBuilder: (QcNonConformanceLogModel row) =>
              _qcInspectionNo(row.toJson()),
        ),
        PurchaseRegisterColumn<QcNonConformanceLogModel>(
          label: 'Severity',
          valueBuilder: (QcNonConformanceLogModel row) =>
              stringValue(row.toJson(), 'severity'),
        ),
        PurchaseRegisterColumn<QcNonConformanceLogModel>(
          label: 'Closure',
          valueBuilder: (QcNonConformanceLogModel row) =>
              stringValue(row.toJson(), 'closure_status'),
        ),
      ],
      onRowTap: (QcNonConformanceLogModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        showDialog<void>(
          context: context,
          builder: (ctx) => _QcNonConformanceDetailDialog(logId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
      },
    );
  }
}
