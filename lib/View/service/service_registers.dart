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

Future<ServiceTicketModel?> _promptAssigneeBody(BuildContext context) async {
  final controller = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Assign'),
      content: SizedBox(
        width: 400,
        child: AppFormTextField(
          labelText: 'Assign to user ID',
          controller: controller,
          hintText: 'Leave blank to assign to yourself',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Assign'),
        ),
      ],
    ),
  );
  if (ok != true) {
    return null;
  }
  final raw = controller.text.trim();
  if (raw.isEmpty) {
    return ServiceTicketModel(<String, dynamic>{});
  }
  final id = int.tryParse(raw);
  if (id == null) {
    return ServiceTicketModel(<String, dynamic>{});
  }
  return ServiceTicketModel(<String, dynamic>{'assigned_to_user_id': id});
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

class _ServiceContractDetailDialog extends StatefulWidget {
  const _ServiceContractDetailDialog({required this.contractId});

  final int contractId;

  @override
  State<_ServiceContractDetailDialog> createState() =>
      _ServiceContractDetailDialogState();
}

class _ServiceContractDetailDialogState extends State<_ServiceContractDetailDialog> {
  final ServiceModuleService _service = ServiceModuleService();
  bool _loading = true;
  String? _error;
  ServiceContractModel? _model;
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
      final response = await _service.contract(widget.contractId);
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

  Future<void> _act(Future<ApiResponse<ServiceContractModel>> Function() fn) async {
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
        title: const Text('Delete contract'),
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
      final response = await _service.deleteContract(widget.contractId);
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
        title: const Text('Service contract'),
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
    final b = ServiceContractModel(<String, dynamic>{});
    final canApprove = st == 'draft';
    final canTerminate = st == 'draft' || st == 'active';
    final canCancel = st != 'active';
    final canDelete = st == 'draft';
    final text = const JsonEncoder.withIndent('  ').convert(data);

    return AlertDialog(
      title: Text('Contract #${widget.contractId}'),
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
                              () => _service.approveContract(
                                widget.contractId,
                                b,
                              ),
                            ),
                    child: const Text('Approve'),
                  ),
                if (canTerminate)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.terminateContract(
                                widget.contractId,
                                b,
                              ),
                            ),
                    child: const Text('Terminate'),
                  ),
                if (canCancel)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.cancelContract(
                                widget.contractId,
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

class _ServiceTicketDetailDialog extends StatefulWidget {
  const _ServiceTicketDetailDialog({required this.ticketId});

  final int ticketId;

  @override
  State<_ServiceTicketDetailDialog> createState() =>
      _ServiceTicketDetailDialogState();
}

class _ServiceTicketDetailDialogState extends State<_ServiceTicketDetailDialog> {
  final ServiceModuleService _service = ServiceModuleService();
  bool _loading = true;
  String? _error;
  ServiceTicketModel? _model;
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
      final response = await _service.ticket(widget.ticketId);
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

  Future<void> _act(Future<ApiResponse<ServiceTicketModel>> Function() fn) async {
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
        const SnackBar(content: Text('Ticket updated.')),
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

  Future<void> _assign() async {
    final body = await _promptAssigneeBody(context);
    if (body == null || !mounted) {
      return;
    }
    await _act(
      () => _service.assignTicket(widget.ticketId, body),
    );
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete ticket'),
        content: const Text(
          'Only draft or open tickets can be deleted. Continue?',
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
      final response = await _service.deleteTicket(widget.ticketId);
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
        const SnackBar(content: Text('Ticket deleted.')),
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
        title: const Text('Service ticket'),
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
    final st = stringValue(data, 'ticket_status');
    final b = ServiceTicketModel(<String, dynamic>{});
    final canAssign =
        !['closed', 'cancelled', 'rejected'].contains(st);
    final canResolve =
        !['closed', 'cancelled', 'rejected', 'resolved'].contains(st);
    final canClose = ['resolved', 'open', 'assigned', 'in_progress'].contains(
      st,
    );
    final canCancel = st != 'closed';
    final canDelete = st == 'draft' || st == 'open';
    final text = const JsonEncoder.withIndent('  ').convert(data);

    return AlertDialog(
      title: Text('Ticket #${widget.ticketId}'),
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
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                if (canAssign)
                  FilledButton(
                    onPressed: _busy ? null : _assign,
                    child: const Text('Assign'),
                  ),
                if (canResolve)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.resolveTicket(
                                widget.ticketId,
                                b,
                              ),
                            ),
                    child: const Text('Resolve'),
                  ),
                if (canClose)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.closeTicket(widget.ticketId, b),
                            ),
                    child: const Text('Close'),
                  ),
                if (canCancel)
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.cancelTicket(widget.ticketId, b),
                            ),
                    child: const Text('Cancel ticket'),
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

class _WarrantyClaimDetailDialog extends StatefulWidget {
  const _WarrantyClaimDetailDialog({required this.claimId});

  final int claimId;

  @override
  State<_WarrantyClaimDetailDialog> createState() =>
      _WarrantyClaimDetailDialogState();
}

class _WarrantyClaimDetailDialogState extends State<_WarrantyClaimDetailDialog> {
  final ServiceModuleService _service = ServiceModuleService();
  bool _loading = true;
  String? _error;
  ServiceTicketModel? _model;
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
      final response = await _service.warrantyClaim(widget.claimId);
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

  Future<void> _act(Future<ApiResponse<ServiceTicketModel>> Function() fn) async {
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
        const SnackBar(content: Text('Warranty claim updated.')),
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

  Future<void> _assign() async {
    final body = await _promptAssigneeBody(context);
    if (body == null || !mounted) {
      return;
    }
    await _act(() => _service.assignWarrantyClaim(widget.claimId, body));
  }

  Future<void> _createWorkOrder() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create work order'),
        content: const Text(
          'Create a service work order from this claim using server defaults?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      final response = await _service.createWorkOrderFromWarrantyClaim(
        widget.claimId,
        ServiceTicketModel(<String, dynamic>{}),
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
        const SnackBar(content: Text('Work order created.')),
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
        title: const Text('Delete claim'),
        content: const Text(
          'Only draft or open claims can be deleted. Continue?',
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
      final response = await _service.deleteWarrantyClaim(widget.claimId);
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
        const SnackBar(content: Text('Claim deleted.')),
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
        title: const Text('Warranty claim'),
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
    final st = stringValue(data, 'ticket_status');
    final b = ServiceTicketModel(<String, dynamic>{});
    final canAssign =
        !['closed', 'cancelled', 'rejected'].contains(st);
    final canResolve =
        !['closed', 'cancelled', 'rejected', 'resolved'].contains(st);
    final canClose = ['resolved', 'open', 'assigned', 'in_progress'].contains(
      st,
    );
    final canCancel = st != 'closed';
    final canDelete = st == 'draft' || st == 'open';
    final text = const JsonEncoder.withIndent('  ').convert(data);

    return AlertDialog(
      title: Text('Warranty claim #${widget.claimId}'),
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
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                if (canAssign)
                  FilledButton(
                    onPressed: _busy ? null : _assign,
                    child: const Text('Assign'),
                  ),
                if (canResolve)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.resolveWarrantyClaim(
                                widget.claimId,
                                b,
                              ),
                            ),
                    child: const Text('Resolve'),
                  ),
                if (canClose)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.closeWarrantyClaim(
                                widget.claimId,
                                b,
                              ),
                            ),
                    child: const Text('Close'),
                  ),
                if (canCancel)
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.cancelWarrantyClaim(
                                widget.claimId,
                                b,
                              ),
                            ),
                    child: const Text('Cancel claim'),
                  ),
                FilledButton.tonal(
                  onPressed: _busy ? null : _createWorkOrder,
                  child: const Text('Create work order'),
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

class _ServiceWorkOrderDetailDialog extends StatefulWidget {
  const _ServiceWorkOrderDetailDialog({required this.workOrderId});

  final int workOrderId;

  @override
  State<_ServiceWorkOrderDetailDialog> createState() =>
      _ServiceWorkOrderDetailDialogState();
}

class _ServiceWorkOrderDetailDialogState
    extends State<_ServiceWorkOrderDetailDialog> {
  final ServiceModuleService _service = ServiceModuleService();
  bool _loading = true;
  String? _error;
  ServiceWorkOrderModel? _model;
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
      final response = await _service.workOrder(widget.workOrderId);
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
    Future<ApiResponse<ServiceWorkOrderModel>> Function() fn,
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
      final response = await _service.deleteWorkOrder(widget.workOrderId);
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
        title: const Text('Service work order'),
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
    final b = ServiceWorkOrderModel(<String, dynamic>{});
    final canStart = st == 'draft' || st == 'assigned';
    final canComplete = [
      'assigned',
      'in_progress',
      'waiting_parts',
      'waiting_customer',
    ].contains(st);
    final canClose = st == 'completed';
    final canCancel = st != 'completed' && st != 'closed';
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
                if (canStart)
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.startWorkOrder(
                                widget.workOrderId,
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
                              () => _service.completeWorkOrder(
                                widget.workOrderId,
                                b,
                              ),
                            ),
                    child: const Text('Complete'),
                  ),
                if (canClose)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.closeWorkOrder(
                                widget.workOrderId,
                                b,
                              ),
                            ),
                    child: const Text('Close'),
                  ),
                if (canCancel)
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.cancelWorkOrder(
                                widget.workOrderId,
                                b,
                              ),
                            ),
                    child: const Text('Cancel WO'),
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

class _ServiceFeedbackDetailDialog extends StatefulWidget {
  const _ServiceFeedbackDetailDialog({required this.feedbackId});

  final int feedbackId;

  @override
  State<_ServiceFeedbackDetailDialog> createState() =>
      _ServiceFeedbackDetailDialogState();
}

class _ServiceFeedbackDetailDialogState extends State<_ServiceFeedbackDetailDialog> {
  final ServiceModuleService _service = ServiceModuleService();
  bool _loading = true;
  String? _error;
  ServiceFeedbackModel? _model;
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
      final response = await _service.feedback(widget.feedbackId);
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
        title: const Text('Delete feedback'),
        content: const Text('Delete this feedback record?'),
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
      final response = await _service.deleteFeedback(widget.feedbackId);
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
        const SnackBar(content: Text('Feedback deleted.')),
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
        title: const Text('Feedback'),
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

    return AlertDialog(
      title: Text('Feedback #${widget.feedbackId}'),
      content: SizedBox(
        width: 560,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppUiConstants.spacingSm,
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
      actions: const <Widget>[],
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
        showDialog<void>(
          context: context,
          builder: (ctx) => _ServiceContractDetailDialog(contractId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
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
      actions: const <Widget>[],
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
        showDialog<void>(
          context: context,
          builder: (ctx) => _ServiceTicketDetailDialog(ticketId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
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
      actions: const <Widget>[],
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
        showDialog<void>(
          context: context,
          builder: (ctx) => _WarrantyClaimDetailDialog(claimId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
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
      actions: const <Widget>[],
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
        showDialog<void>(
          context: context,
          builder: (ctx) => _ServiceWorkOrderDetailDialog(workOrderId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
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
      actions: const <Widget>[],
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
        showDialog<void>(
          context: context,
          builder: (ctx) => _ServiceFeedbackDetailDialog(feedbackId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
      },
    );
  }
}
