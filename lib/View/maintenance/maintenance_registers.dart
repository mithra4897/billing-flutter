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

String _assetLabel(Map<String, dynamic> data) {
  final a = _asJsonMap(data['asset']);
  if (a == null) {
    return '';
  }
  final code = stringValue(a, 'asset_code');
  final name = stringValue(a, 'asset_name');
  if (code.isNotEmpty && name.isNotEmpty) {
    return '$code — $name';
  }
  return code.isNotEmpty ? code : name;
}

String _vendorDisplay(Map<String, dynamic> data) {
  final v = _asJsonMap(data['vendor']);
  if (v == null) {
    return '';
  }
  final d = stringValue(v, 'display_name');
  if (d.isNotEmpty) {
    return d;
  }
  return stringValue(v, 'party_name');
}

String _planBrief(Map<String, dynamic> data) {
  final p = _asJsonMap(data['maintenancePlan']);
  if (p == null) {
    return '';
  }
  final code = stringValue(p, 'plan_code');
  final name = stringValue(p, 'plan_name');
  if (code.isNotEmpty && name.isNotEmpty) {
    return '$code — $name';
  }
  return code.isNotEmpty ? code : name;
}

String _nestedWorkOrderNo(Map<String, dynamic> data) {
  final w = _asJsonMap(data['workOrder']);
  if (w == null) {
    return '';
  }
  return stringValue(w, 'work_order_no');
}

int? _assetCompanyId(Map<String, dynamic> data) {
  final a = _asJsonMap(data['asset']);
  if (a == null) {
    return null;
  }
  return intValue(a, 'company_id');
}

class _MaintFilters extends StatelessWidget {
  const _MaintFilters({
    required this.searchController,
    required this.searchHint,
    required this.companyBanner,
    required this.scopeHint,
  });

  final TextEditingController searchController;
  final String searchHint;
  final String? companyBanner;
  final String scopeHint;

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
                    'Session company: $companyBanner. $scopeHint',
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

// --- Maintenance plan --------------------------------------------------

class _MaintenancePlanDetailDialog extends StatefulWidget {
  const _MaintenancePlanDetailDialog({required this.planId});

  final int planId;

  @override
  State<_MaintenancePlanDetailDialog> createState() =>
      _MaintenancePlanDetailDialogState();
}

class _MaintenancePlanDetailDialogState
    extends State<_MaintenancePlanDetailDialog> {
  final MaintenanceService _api = MaintenanceService();
  bool _loading = true;
  String? _error;
  MaintenancePlanModel? _model;
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
      final response = await _api.plan(widget.planId);
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

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete maintenance plan'),
        content: const Text(
          'This removes the plan and its asset links. Continue?',
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
      final response = await _api.deletePlan(widget.planId);
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
        const SnackBar(content: Text('Plan deleted.')),
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
        title: const Text('Maintenance plan'),
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
    final text = const JsonEncoder.withIndent('  ').convert(data);

    return AlertDialog(
      title: Text('Plan #${widget.planId}'),
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

// --- Maintenance request -----------------------------------------------

class _MaintenanceRequestDetailDialog extends StatefulWidget {
  const _MaintenanceRequestDetailDialog({required this.requestId});

  final int requestId;

  @override
  State<_MaintenanceRequestDetailDialog> createState() =>
      _MaintenanceRequestDetailDialogState();
}

class _MaintenanceRequestDetailDialogState
    extends State<_MaintenanceRequestDetailDialog> {
  final MaintenanceService _api = MaintenanceService();
  bool _loading = true;
  String? _error;
  MaintenanceRequestModel? _model;
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
      final response = await _api.request(widget.requestId);
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
    Future<ApiResponse<MaintenanceRequestModel>> Function() fn,
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
        const SnackBar(content: Text('Request updated.')),
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
        title: const Text('Delete request'),
        content: const Text(
          'Only draft or open requests can be deleted. Continue?',
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
      final response = await _api.deleteRequest(widget.requestId);
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
        const SnackBar(content: Text('Request deleted.')),
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
        title: const Text('Maintenance request'),
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
    final st = stringValue(data, 'request_status');
    final empty = MaintenanceRequestModel(<String, dynamic>{});
    final canApprove = st == 'draft' || st == 'open';
    final canCancel = st != 'completed' && st != 'cancelled';
    final canDelete = st == 'draft' || st == 'open';
    final text = const JsonEncoder.withIndent('  ').convert(data);

    return AlertDialog(
      title: Text('Request #${widget.requestId}'),
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
                              () => _api.approveRequest(
                                widget.requestId,
                                empty,
                              ),
                            ),
                    child: const Text('Approve'),
                  ),
                if (canCancel)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _api.cancelRequest(
                                widget.requestId,
                                empty,
                              ),
                            ),
                    child: const Text('Cancel request'),
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

// --- Maintenance work order --------------------------------------------

class _MaintenanceWorkOrderDetailDialog extends StatefulWidget {
  const _MaintenanceWorkOrderDetailDialog({required this.workOrderId});

  final int workOrderId;

  @override
  State<_MaintenanceWorkOrderDetailDialog> createState() =>
      _MaintenanceWorkOrderDetailDialogState();
}

class _MaintenanceWorkOrderDetailDialogState
    extends State<_MaintenanceWorkOrderDetailDialog> {
  final MaintenanceService _api = MaintenanceService();
  bool _loading = true;
  String? _error;
  MaintenanceWorkOrderModel? _model;
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
      final response = await _api.workOrder(widget.workOrderId);
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
    Future<ApiResponse<MaintenanceWorkOrderModel>> Function() fn,
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
        const SnackBar(content: Text('Work order updated.')),
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
        title: const Text('Delete work order'),
        content: const Text('Only draft work orders can be deleted. Continue?'),
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
      final response = await _api.deleteWorkOrder(widget.workOrderId);
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
        const SnackBar(content: Text('Work order deleted.')),
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
        title: const Text('Maintenance work order'),
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
    final st = stringValue(data, 'work_order_status');
    final empty = MaintenanceWorkOrderModel(<String, dynamic>{});
    final canApprove = st == 'draft';
    final canStart =
        st == 'draft' || st == 'approved' || st == 'assigned';
    final canComplete = [
      'approved',
      'assigned',
      'in_progress',
      'waiting_parts',
      'waiting_vendor',
    ].contains(st);
    final canClose = st == 'completed';
    final canCancel =
        st != 'completed' && st != 'closed' && st != 'cancelled';
    final canDelete = st == 'draft';
    final text = const JsonEncoder.withIndent('  ').convert(data);

    return AlertDialog(
      title: Text('Work order #${widget.workOrderId}'),
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
                              () => _api.approveWorkOrder(
                                widget.workOrderId,
                                empty,
                              ),
                            ),
                    child: const Text('Approve'),
                  ),
                if (canStart)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _api.startWorkOrder(
                                widget.workOrderId,
                                empty,
                              ),
                            ),
                    child: const Text('Start'),
                  ),
                if (canComplete)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _api.completeWorkOrder(
                                widget.workOrderId,
                                empty,
                              ),
                            ),
                    child: const Text('Complete'),
                  ),
                if (canClose)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _api.closeWorkOrder(
                                widget.workOrderId,
                                empty,
                              ),
                            ),
                    child: const Text('Close'),
                  ),
                if (canCancel)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _api.cancelWorkOrder(
                                widget.workOrderId,
                                empty,
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

// --- Downtime log ------------------------------------------------------

class _AssetDowntimeLogDetailDialog extends StatefulWidget {
  const _AssetDowntimeLogDetailDialog({required this.logId});

  final int logId;

  @override
  State<_AssetDowntimeLogDetailDialog> createState() =>
      _AssetDowntimeLogDetailDialogState();
}

class _AssetDowntimeLogDetailDialogState
    extends State<_AssetDowntimeLogDetailDialog> {
  final MaintenanceService _api = MaintenanceService();
  bool _loading = true;
  String? _error;
  AssetDowntimeLogModel? _model;
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
      final response = await _api.downtimeLog(widget.logId);
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

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete downtime log'),
        content: const Text('Delete this downtime log?'),
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
      final response = await _api.deleteDowntimeLog(widget.logId);
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
        const SnackBar(content: Text('Downtime log deleted.')),
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
        title: const Text('Downtime log'),
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
    final text = const JsonEncoder.withIndent('  ').convert(data);

    return AlertDialog(
      title: Text('Downtime #${widget.logId}'),
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

// --- AMC contract ------------------------------------------------------

class _AmcContractDetailDialog extends StatefulWidget {
  const _AmcContractDetailDialog({required this.contractId});

  final int contractId;

  @override
  State<_AmcContractDetailDialog> createState() =>
      _AmcContractDetailDialogState();
}

class _AmcContractDetailDialogState extends State<_AmcContractDetailDialog> {
  final MaintenanceService _api = MaintenanceService();
  bool _loading = true;
  String? _error;
  AmcContractModel? _model;
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
      final response = await _api.amcContract(widget.contractId);
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

  Future<void> _act(Future<ApiResponse<AmcContractModel>> Function() fn) async {
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
        const SnackBar(content: Text('Contract updated.')),
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
        title: const Text('Delete AMC contract'),
        content: const Text('Only draft contracts can be deleted. Continue?'),
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
      final response = await _api.deleteAmcContract(widget.contractId);
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
        const SnackBar(content: Text('Contract deleted.')),
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
        title: const Text('AMC contract'),
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
    final st = stringValue(data, 'contract_status');
    final empty = AmcContractModel(<String, dynamic>{});
    final canApprove = st == 'draft';
    final canTerminate = st == 'draft' || st == 'active';
    final canCancel = st != 'active';
    final canDelete = st == 'draft';
    final text = const JsonEncoder.withIndent('  ').convert(data);

    return AlertDialog(
      title: Text('AMC #${widget.contractId}'),
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
                              () => _api.approveAmcContract(
                                widget.contractId,
                                empty,
                              ),
                            ),
                    child: const Text('Approve'),
                  ),
                if (canTerminate)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _api.terminateAmcContract(
                                widget.contractId,
                                empty,
                              ),
                            ),
                    child: const Text('Terminate'),
                  ),
                if (canCancel)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _api.cancelAmcContract(
                                widget.contractId,
                                empty,
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

// --- Register pages ----------------------------------------------------

class MaintenancePlanRegisterPage extends StatefulWidget {
  const MaintenancePlanRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MaintenancePlanRegisterPage> createState() =>
      _MaintenancePlanRegisterPageState();
}

class _MaintenancePlanRegisterPageState extends State<MaintenancePlanRegisterPage> {
  final MaintenanceService _api = MaintenanceService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<MaintenancePlanModel> _rows = const <MaintenancePlanModel>[];

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
      final response = await _api.plans(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <MaintenancePlanModel>[];
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

  List<MaintenancePlanModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((MaintenancePlanModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'plan_code'),
            stringValue(data, 'plan_name'),
            stringValue(data, 'maintenance_type'),
            stringValue(data, 'schedule_basis'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<MaintenancePlanModel>(
      title: 'Maintenance plans',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No maintenance plans found.',
      actions: const <Widget>[],
      filters: _MaintFilters(
        searchController: _searchController,
        searchHint: 'Search code, name, type, schedule',
        companyBanner: _companyBanner,
        scopeHint: 'Lists are filtered by company_id when a session company is set.',
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<MaintenancePlanModel>(
          label: 'Code',
          valueBuilder: (MaintenancePlanModel row) =>
              stringValue(row.toJson(), 'plan_code'),
        ),
        PurchaseRegisterColumn<MaintenancePlanModel>(
          label: 'Name',
          flex: 2,
          valueBuilder: (MaintenancePlanModel row) =>
              stringValue(row.toJson(), 'plan_name'),
        ),
        PurchaseRegisterColumn<MaintenancePlanModel>(
          label: 'Type',
          valueBuilder: (MaintenancePlanModel row) =>
              stringValue(row.toJson(), 'maintenance_type'),
        ),
        PurchaseRegisterColumn<MaintenancePlanModel>(
          label: 'Assets',
          valueBuilder: (MaintenancePlanModel row) =>
              intValue(row.toJson(), 'assets_count')?.toString() ?? '—',
        ),
      ],
      onRowTap: (MaintenancePlanModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        showDialog<void>(
          context: context,
          builder: (ctx) => _MaintenancePlanDetailDialog(planId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
      },
    );
  }
}

class MaintenanceRequestRegisterPage extends StatefulWidget {
  const MaintenanceRequestRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MaintenanceRequestRegisterPage> createState() =>
      _MaintenanceRequestRegisterPageState();
}

class _MaintenanceRequestRegisterPageState
    extends State<MaintenanceRequestRegisterPage> {
  final MaintenanceService _api = MaintenanceService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<MaintenanceRequestModel> _rows = const <MaintenanceRequestModel>[];

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
      final response = await _api.requests(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <MaintenanceRequestModel>[];
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

  List<MaintenanceRequestModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((MaintenanceRequestModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'request_no'),
            stringValue(data, 'issue_title'),
            stringValue(data, 'request_status'),
            stringValue(data, 'request_type'),
            _assetLabel(data),
            _planBrief(data),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<MaintenanceRequestModel>(
      title: 'Maintenance requests',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No maintenance requests found.',
      actions: const <Widget>[],
      filters: _MaintFilters(
        searchController: _searchController,
        searchHint: 'Search no., title, asset, plan, status',
        companyBanner: _companyBanner,
        scopeHint: 'Lists are filtered by company_id when a session company is set.',
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<MaintenanceRequestModel>(
          label: 'Request no.',
          valueBuilder: (MaintenanceRequestModel row) =>
              stringValue(row.toJson(), 'request_no'),
        ),
        PurchaseRegisterColumn<MaintenanceRequestModel>(
          label: 'Date',
          valueBuilder: (MaintenanceRequestModel row) => displayDate(
            nullableStringValue(row.toJson(), 'request_date'),
          ),
        ),
        PurchaseRegisterColumn<MaintenanceRequestModel>(
          label: 'Asset',
          flex: 2,
          valueBuilder: (MaintenanceRequestModel row) =>
              _assetLabel(row.toJson()),
        ),
        PurchaseRegisterColumn<MaintenanceRequestModel>(
          label: 'Status',
          valueBuilder: (MaintenanceRequestModel row) =>
              stringValue(row.toJson(), 'request_status'),
        ),
      ],
      onRowTap: (MaintenanceRequestModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        showDialog<void>(
          context: context,
          builder: (ctx) => _MaintenanceRequestDetailDialog(requestId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
      },
    );
  }
}

class MaintenanceWorkOrderRegisterPage extends StatefulWidget {
  const MaintenanceWorkOrderRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MaintenanceWorkOrderRegisterPage> createState() =>
      _MaintenanceWorkOrderRegisterPageState();
}

class _MaintenanceWorkOrderRegisterPageState
    extends State<MaintenanceWorkOrderRegisterPage> {
  final MaintenanceService _api = MaintenanceService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<MaintenanceWorkOrderModel> _rows = const <MaintenanceWorkOrderModel>[];

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
      final response = await _api.workOrders(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <MaintenanceWorkOrderModel>[];
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

  List<MaintenanceWorkOrderModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((MaintenanceWorkOrderModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'work_order_no'),
            stringValue(data, 'work_order_status'),
            stringValue(data, 'work_order_type'),
            _assetLabel(data),
            _vendorDisplay(data),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<MaintenanceWorkOrderModel>(
      title: 'Maintenance work orders',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No maintenance work orders found.',
      actions: const <Widget>[],
      filters: _MaintFilters(
        searchController: _searchController,
        searchHint: 'Search no., asset, vendor, status',
        companyBanner: _companyBanner,
        scopeHint: 'Lists are filtered by company_id when a session company is set.',
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<MaintenanceWorkOrderModel>(
          label: 'WO no.',
          valueBuilder: (MaintenanceWorkOrderModel row) =>
              stringValue(row.toJson(), 'work_order_no'),
        ),
        PurchaseRegisterColumn<MaintenanceWorkOrderModel>(
          label: 'Date',
          valueBuilder: (MaintenanceWorkOrderModel row) => displayDate(
            nullableStringValue(row.toJson(), 'work_order_date'),
          ),
        ),
        PurchaseRegisterColumn<MaintenanceWorkOrderModel>(
          label: 'Asset',
          flex: 2,
          valueBuilder: (MaintenanceWorkOrderModel row) =>
              _assetLabel(row.toJson()),
        ),
        PurchaseRegisterColumn<MaintenanceWorkOrderModel>(
          label: 'Status',
          valueBuilder: (MaintenanceWorkOrderModel row) =>
              stringValue(row.toJson(), 'work_order_status'),
        ),
      ],
      onRowTap: (MaintenanceWorkOrderModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        showDialog<void>(
          context: context,
          builder: (ctx) => _MaintenanceWorkOrderDetailDialog(workOrderId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
      },
    );
  }
}

class AssetDowntimeLogRegisterPage extends StatefulWidget {
  const AssetDowntimeLogRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AssetDowntimeLogRegisterPage> createState() =>
      _AssetDowntimeLogRegisterPageState();
}

class _AssetDowntimeLogRegisterPageState extends State<AssetDowntimeLogRegisterPage> {
  final MaintenanceService _api = MaintenanceService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  int? _sessionCompanyId;
  List<AssetDowntimeLogModel> _rows = const <AssetDowntimeLogModel>[];

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
      final response = await _api.downtimeLogs(
        filters: <String, dynamic>{'per_page': 200},
      );
      if (!mounted) {
        return;
      }
      var rows = response.data ?? const <AssetDowntimeLogModel>[];
      if (info.companyId != null) {
        final cid = info.companyId!;
        rows = rows
            .where((AssetDowntimeLogModel r) {
              final ac = _assetCompanyId(r.toJson());
              return ac == cid;
            })
            .toList(growable: false);
      }
      setState(() {
        _companyBanner = info.banner;
        _sessionCompanyId = info.companyId;
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

  List<AssetDowntimeLogModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((AssetDowntimeLogModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            _assetLabel(data),
            _nestedWorkOrderNo(data),
            stringValue(data, 'downtime_reason'),
            displayDateTime(nullableStringValue(data, 'downtime_start')),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final scopeHint = _sessionCompanyId != null
        ? 'Downtime list is filtered client-side by nested asset.company_id.'
        : 'Without a session company, downtime logs are not company-scoped.';

    return PurchaseRegisterPage<AssetDowntimeLogModel>(
      title: 'Asset downtime logs',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No downtime logs found.',
      actions: const <Widget>[],
      filters: _MaintFilters(
        searchController: _searchController,
        searchHint: 'Search asset, WO, reason, start time',
        companyBanner: _companyBanner,
        scopeHint: scopeHint,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<AssetDowntimeLogModel>(
          label: 'Asset',
          flex: 2,
          valueBuilder: (AssetDowntimeLogModel row) =>
              _assetLabel(row.toJson()),
        ),
        PurchaseRegisterColumn<AssetDowntimeLogModel>(
          label: 'Start',
          valueBuilder: (AssetDowntimeLogModel row) => displayDateTime(
            nullableStringValue(row.toJson(), 'downtime_start'),
          ),
        ),
        PurchaseRegisterColumn<AssetDowntimeLogModel>(
          label: 'End',
          valueBuilder: (AssetDowntimeLogModel row) => displayDateTime(
            nullableStringValue(row.toJson(), 'downtime_end'),
          ),
        ),
        PurchaseRegisterColumn<AssetDowntimeLogModel>(
          label: 'WO',
          valueBuilder: (AssetDowntimeLogModel row) =>
              _nestedWorkOrderNo(row.toJson()),
        ),
      ],
      onRowTap: (AssetDowntimeLogModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        showDialog<void>(
          context: context,
          builder: (ctx) => _AssetDowntimeLogDetailDialog(logId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
      },
    );
  }
}

class AmcContractRegisterPage extends StatefulWidget {
  const AmcContractRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AmcContractRegisterPage> createState() =>
      _AmcContractRegisterPageState();
}

class _AmcContractRegisterPageState extends State<AmcContractRegisterPage> {
  final MaintenanceService _api = MaintenanceService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<AmcContractModel> _rows = const <AmcContractModel>[];

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
      final response = await _api.amcContracts(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <AmcContractModel>[];
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

  List<AmcContractModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((AmcContractModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'contract_no'),
            stringValue(data, 'contract_status'),
            stringValue(data, 'contract_type'),
            _vendorDisplay(data),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<AmcContractModel>(
      title: 'AMC contracts',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No AMC contracts found.',
      actions: const <Widget>[],
      filters: _MaintFilters(
        searchController: _searchController,
        searchHint: 'Search contract no., vendor, status',
        companyBanner: _companyBanner,
        scopeHint: 'Lists are filtered by company_id when a session company is set.',
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<AmcContractModel>(
          label: 'Contract no.',
          valueBuilder: (AmcContractModel row) =>
              stringValue(row.toJson(), 'contract_no'),
        ),
        PurchaseRegisterColumn<AmcContractModel>(
          label: 'Start',
          valueBuilder: (AmcContractModel row) => displayDate(
            nullableStringValue(row.toJson(), 'start_date'),
          ),
        ),
        PurchaseRegisterColumn<AmcContractModel>(
          label: 'Vendor',
          flex: 2,
          valueBuilder: (AmcContractModel row) => _vendorDisplay(row.toJson()),
        ),
        PurchaseRegisterColumn<AmcContractModel>(
          label: 'Status',
          valueBuilder: (AmcContractModel row) =>
              stringValue(row.toJson(), 'contract_status'),
        ),
      ],
      onRowTap: (AmcContractModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        showDialog<void>(
          context: context,
          builder: (ctx) => _AmcContractDetailDialog(contractId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
      },
    );
  }
}
