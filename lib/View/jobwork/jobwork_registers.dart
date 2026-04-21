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

String _supplierName(Map<String, dynamic> data) {
  final s = _asJsonMap(data['supplier']);
  if (s == null) {
    return '';
  }
  final d = stringValue(s, 'display_name');
  if (d.isNotEmpty) {
    return d;
  }
  return stringValue(s, 'party_name');
}

String _jobworkOrderNo(Map<String, dynamic> data) {
  final jo = _asJsonMap(data['jobworkOrder']) ??
      _asJsonMap(data['jobwork_order']);
  if (jo == null) {
    return '';
  }
  return stringValue(jo, 'jobwork_no');
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

class _JobworkOrderDetailDialog extends StatefulWidget {
  const _JobworkOrderDetailDialog({required this.orderId});

  final int orderId;

  @override
  State<_JobworkOrderDetailDialog> createState() =>
      _JobworkOrderDetailDialogState();
}

class _JobworkOrderDetailDialogState extends State<_JobworkOrderDetailDialog> {
  final JobworkService _service = JobworkService();
  bool _loading = true;
  String? _error;
  JobworkOrderModel? _model;
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
      final response = await _service.order(widget.orderId);
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
    Future<ApiResponse<JobworkOrderModel>> Function() fn,
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
        const SnackBar(content: Text('Jobwork order updated.')),
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
        title: const Text('Delete jobwork order'),
        content: const Text(
          'Only draft jobwork orders can be deleted. Continue?',
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
      final response = await _service.deleteOrder(widget.orderId);
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
        const SnackBar(content: Text('Jobwork order deleted.')),
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
        title: const Text('Jobwork order'),
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
    final st = stringValue(data, 'jobwork_status');
    final canRelease = st == 'draft';
    final canClose = st == 'fully_received' || st == 'partially_received';
    final canCancel = st != 'closed';
    final canDelete = st == 'draft';
    final text = const JsonEncoder.withIndent('  ').convert(data);

    return AlertDialog(
      title: Text('Jobwork order #${widget.orderId}'),
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
                if (canRelease)
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.releaseOrder(
                                widget.orderId,
                                JobworkOrderModel(<String, dynamic>{}),
                              ),
                            ),
                    child: const Text('Release'),
                  ),
                if (canClose)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.closeOrder(
                                widget.orderId,
                                JobworkOrderModel(<String, dynamic>{}),
                              ),
                            ),
                    child: const Text('Close'),
                  ),
                if (canCancel)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.cancelOrder(
                                widget.orderId,
                                JobworkOrderModel(<String, dynamic>{}),
                              ),
                            ),
                    child: const Text('Cancel order'),
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

class _JobworkDispatchDetailDialog extends StatefulWidget {
  const _JobworkDispatchDetailDialog({required this.dispatchId});

  final int dispatchId;

  @override
  State<_JobworkDispatchDetailDialog> createState() =>
      _JobworkDispatchDetailDialogState();
}

class _JobworkDispatchDetailDialogState
    extends State<_JobworkDispatchDetailDialog> {
  final JobworkService _service = JobworkService();
  bool _loading = true;
  String? _error;
  JobworkDispatchModel? _model;
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
      final response = await _service.dispatch(widget.dispatchId);
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
    Future<ApiResponse<JobworkDispatchModel>> Function() fn,
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
        const SnackBar(content: Text('Dispatch updated.')),
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
        title: const Text('Delete dispatch'),
        content: const Text(
          'Only draft dispatches can be deleted. Continue?',
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
      final response = await _service.deleteDispatch(widget.dispatchId);
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
        const SnackBar(content: Text('Dispatch deleted.')),
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
        title: const Text('Jobwork dispatch'),
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
    final st = stringValue(data, 'dispatch_status');
    final canPost = st == 'draft';
    final canCancel = st == 'draft';
    final canDelete = st == 'draft';
    final text = const JsonEncoder.withIndent('  ').convert(data);

    return AlertDialog(
      title: Text('Dispatch #${widget.dispatchId}'),
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
                if (canPost)
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.postDispatch(
                                widget.dispatchId,
                                JobworkDispatchModel(<String, dynamic>{}),
                              ),
                            ),
                    child: const Text('Post'),
                  ),
                if (canCancel)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.cancelDispatch(
                                widget.dispatchId,
                                JobworkDispatchModel(<String, dynamic>{}),
                              ),
                            ),
                    child: const Text('Cancel doc'),
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

class _JobworkReceiptDetailDialog extends StatefulWidget {
  const _JobworkReceiptDetailDialog({required this.receiptId});

  final int receiptId;

  @override
  State<_JobworkReceiptDetailDialog> createState() =>
      _JobworkReceiptDetailDialogState();
}

class _JobworkReceiptDetailDialogState
    extends State<_JobworkReceiptDetailDialog> {
  final JobworkService _service = JobworkService();
  bool _loading = true;
  String? _error;
  JobworkReceiptModel? _model;
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
      final response = await _service.receipt(widget.receiptId);
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
    Future<ApiResponse<JobworkReceiptModel>> Function() fn,
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
        const SnackBar(content: Text('Receipt updated.')),
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
        title: const Text('Delete receipt'),
        content: const Text(
          'Only draft receipts can be deleted. Continue?',
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
      final response = await _service.deleteReceipt(widget.receiptId);
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
        const SnackBar(content: Text('Receipt deleted.')),
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
        title: const Text('Jobwork receipt'),
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
    final st = stringValue(data, 'receipt_status');
    final canPost = st == 'draft';
    final canCancel = st == 'draft';
    final canDelete = st == 'draft';
    final text = const JsonEncoder.withIndent('  ').convert(data);

    return AlertDialog(
      title: Text('Receipt #${widget.receiptId}'),
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
                if (canPost)
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.postReceipt(
                                widget.receiptId,
                                JobworkReceiptModel(<String, dynamic>{}),
                              ),
                            ),
                    child: const Text('Post'),
                  ),
                if (canCancel)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.cancelReceipt(
                                widget.receiptId,
                                JobworkReceiptModel(<String, dynamic>{}),
                              ),
                            ),
                    child: const Text('Cancel doc'),
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

class _JobworkChargeDetailDialog extends StatefulWidget {
  const _JobworkChargeDetailDialog({required this.chargeId});

  final int chargeId;

  @override
  State<_JobworkChargeDetailDialog> createState() =>
      _JobworkChargeDetailDialogState();
}

class _JobworkChargeDetailDialogState extends State<_JobworkChargeDetailDialog> {
  final JobworkService _service = JobworkService();
  bool _loading = true;
  String? _error;
  JobworkChargeModel? _model;
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
      final response = await _service.charge(widget.chargeId);
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
    Future<ApiResponse<JobworkChargeModel>> Function() fn,
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
        const SnackBar(content: Text('Charge updated.')),
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
        title: const Text('Delete charge'),
        content: const Text(
          'Only draft charges can be deleted. Continue?',
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
      final response = await _service.deleteCharge(widget.chargeId);
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
        const SnackBar(content: Text('Charge deleted.')),
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
        title: const Text('Jobwork charge'),
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
    final st = stringValue(data, 'charge_status');
    final canPost = st == 'draft';
    final canCancel = st != 'invoiced' && st != 'cancelled';
    final canDelete = st == 'draft';
    final text = const JsonEncoder.withIndent('  ').convert(data);

    return AlertDialog(
      title: Text('Charge #${widget.chargeId}'),
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
                if (canPost)
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.postCharge(
                                widget.chargeId,
                                JobworkChargeModel(<String, dynamic>{}),
                              ),
                            ),
                    child: const Text('Post'),
                  ),
                if (canCancel)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.cancelCharge(
                                widget.chargeId,
                                JobworkChargeModel(<String, dynamic>{}),
                              ),
                            ),
                    child: const Text('Cancel doc'),
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
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'jobwork_no'),
            stringValue(data, 'process_name'),
            stringValue(data, 'jobwork_status'),
            _supplierName(data),
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
      actions: const <Widget>[],
      filters: _JwFilters(
        searchController: _searchController,
        searchHint: 'Search order no., process, supplier, status',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<JobworkOrderModel>(
          label: 'Order no.',
          valueBuilder: (JobworkOrderModel row) =>
              stringValue(row.toJson(), 'jobwork_no'),
        ),
        PurchaseRegisterColumn<JobworkOrderModel>(
          label: 'Date',
          valueBuilder: (JobworkOrderModel row) => displayDate(
            nullableStringValue(row.toJson(), 'jobwork_date'),
          ),
        ),
        PurchaseRegisterColumn<JobworkOrderModel>(
          label: 'Supplier',
          flex: 2,
          valueBuilder: (JobworkOrderModel row) =>
              _supplierName(row.toJson()),
        ),
        PurchaseRegisterColumn<JobworkOrderModel>(
          label: 'Status',
          valueBuilder: (JobworkOrderModel row) =>
              stringValue(row.toJson(), 'jobwork_status'),
        ),
      ],
      onRowTap: (JobworkOrderModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        showDialog<void>(
          context: context,
          builder: (ctx) => _JobworkOrderDetailDialog(orderId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
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
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'dispatch_no'),
            stringValue(data, 'dispatch_status'),
            _jobworkOrderNo(data),
            _supplierName(data),
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
      actions: const <Widget>[],
      filters: _JwFilters(
        searchController: _searchController,
        searchHint: 'Search dispatch no., order, supplier, status',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<JobworkDispatchModel>(
          label: 'Dispatch no.',
          valueBuilder: (JobworkDispatchModel row) =>
              stringValue(row.toJson(), 'dispatch_no'),
        ),
        PurchaseRegisterColumn<JobworkDispatchModel>(
          label: 'Date',
          valueBuilder: (JobworkDispatchModel row) => displayDate(
            nullableStringValue(row.toJson(), 'dispatch_date'),
          ),
        ),
        PurchaseRegisterColumn<JobworkDispatchModel>(
          label: 'Jobwork order',
          flex: 2,
          valueBuilder: (JobworkDispatchModel row) =>
              _jobworkOrderNo(row.toJson()),
        ),
        PurchaseRegisterColumn<JobworkDispatchModel>(
          label: 'Status',
          valueBuilder: (JobworkDispatchModel row) =>
              stringValue(row.toJson(), 'dispatch_status'),
        ),
      ],
      onRowTap: (JobworkDispatchModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        showDialog<void>(
          context: context,
          builder: (ctx) => _JobworkDispatchDetailDialog(dispatchId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
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
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'receipt_no'),
            stringValue(data, 'receipt_status'),
            _jobworkOrderNo(data),
            _supplierName(data),
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
      actions: const <Widget>[],
      filters: _JwFilters(
        searchController: _searchController,
        searchHint: 'Search receipt no., order, supplier, status',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<JobworkReceiptModel>(
          label: 'Receipt no.',
          valueBuilder: (JobworkReceiptModel row) =>
              stringValue(row.toJson(), 'receipt_no'),
        ),
        PurchaseRegisterColumn<JobworkReceiptModel>(
          label: 'Date',
          valueBuilder: (JobworkReceiptModel row) => displayDate(
            nullableStringValue(row.toJson(), 'receipt_date'),
          ),
        ),
        PurchaseRegisterColumn<JobworkReceiptModel>(
          label: 'Jobwork order',
          flex: 2,
          valueBuilder: (JobworkReceiptModel row) =>
              _jobworkOrderNo(row.toJson()),
        ),
        PurchaseRegisterColumn<JobworkReceiptModel>(
          label: 'Status',
          valueBuilder: (JobworkReceiptModel row) =>
              stringValue(row.toJson(), 'receipt_status'),
        ),
      ],
      onRowTap: (JobworkReceiptModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        showDialog<void>(
          context: context,
          builder: (ctx) => _JobworkReceiptDetailDialog(receiptId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
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
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'charge_no'),
            stringValue(data, 'charge_status'),
            _jobworkOrderNo(data),
            _supplierName(data),
            stringValue(data, 'total_amount'),
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
      actions: const <Widget>[],
      filters: _JwFilters(
        searchController: _searchController,
        searchHint: 'Search charge no., order, supplier, amount, status',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<JobworkChargeModel>(
          label: 'Charge no.',
          valueBuilder: (JobworkChargeModel row) =>
              stringValue(row.toJson(), 'charge_no'),
        ),
        PurchaseRegisterColumn<JobworkChargeModel>(
          label: 'Date',
          valueBuilder: (JobworkChargeModel row) => displayDate(
            nullableStringValue(row.toJson(), 'charge_date'),
          ),
        ),
        PurchaseRegisterColumn<JobworkChargeModel>(
          label: 'Jobwork order',
          flex: 2,
          valueBuilder: (JobworkChargeModel row) =>
              _jobworkOrderNo(row.toJson()),
        ),
        PurchaseRegisterColumn<JobworkChargeModel>(
          label: 'Status',
          valueBuilder: (JobworkChargeModel row) =>
              stringValue(row.toJson(), 'charge_status'),
        ),
      ],
      onRowTap: (JobworkChargeModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        showDialog<void>(
          context: context,
          builder: (ctx) => _JobworkChargeDetailDialog(chargeId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
      },
    );
  }
}
