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

String _outputItemLabel(Map<String, dynamic> data) {
  final item = _asJsonMap(data['outputItem']) ??
      _asJsonMap(data['output_item']);
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

String _productionOrderNo(Map<String, dynamic> data) {
  final po = _asJsonMap(data['productionOrder']) ??
      _asJsonMap(data['production_order']);
  if (po == null) {
    return '';
  }
  return stringValue(po, 'production_no');
}

class _MfgFilters extends StatelessWidget {
  const _MfgFilters({
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
                    'Session company: $companyBanner. Lists are filtered by '
                    'company when the API supports it.',
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
                    'to scope manufacturing lists.',
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

class _BomDetailDialog extends StatefulWidget {
  const _BomDetailDialog({required this.bomId});

  final int bomId;

  @override
  State<_BomDetailDialog> createState() => _BomDetailDialogState();
}

class _BomDetailDialogState extends State<_BomDetailDialog> {
  final ManufacturingService _service = ManufacturingService();
  bool _loading = true;
  String? _error;
  BomModel? _model;
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
      final response = await _service.bom(widget.bomId);
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

  Future<void> _act(Future<ApiResponse<dynamic>> Function() fn) async {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('BOM updated.')));
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
        title: const Text('Delete BOM'),
        content: const Text(
          'Only non-approved BOMs can be deleted. Continue?',
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
      final response = await _service.deleteBom(widget.bomId);
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
        const SnackBar(content: Text('BOM deleted.')),
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
        title: const Text('BOM'),
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
    final approval = stringValue(data, 'approval_status');
    final canApprove = approval != 'approved';
    final canDelete = approval != 'approved';
    final text = const JsonEncoder.withIndent('  ').convert(data);

    return AlertDialog(
      title: Text('BOM #${widget.bomId}'),
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
                if (canApprove)
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.approveBom(
                                widget.bomId,
                                BomModel(<String, dynamic>{}),
                              ),
                            ),
                    child: const Text('Approve'),
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

class _ProductionOrderDetailDialog extends StatefulWidget {
  const _ProductionOrderDetailDialog({required this.orderId});

  final int orderId;

  @override
  State<_ProductionOrderDetailDialog> createState() =>
      _ProductionOrderDetailDialogState();
}

class _ProductionOrderDetailDialogState
    extends State<_ProductionOrderDetailDialog> {
  final ManufacturingService _service = ManufacturingService();
  bool _loading = true;
  String? _error;
  ProductionOrderModel? _model;
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
      final response = await _service.productionOrder(widget.orderId);
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
    Future<ApiResponse<ProductionOrderModel>> Function() fn,
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
        const SnackBar(content: Text('Production order updated.')),
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
        title: const Text('Delete production order'),
        content: const Text(
          'Only draft production orders can be deleted. Continue?',
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
      final response = await _service.deleteProductionOrder(widget.orderId);
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
        const SnackBar(content: Text('Production order deleted.')),
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
        title: const Text('Production order'),
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
    final st = stringValue(data, 'production_status');
    final canRelease = st == 'draft';
    final canClose = st == 'completed' || st == 'partially_completed';
    final canCancel = st != 'completed' && st != 'closed';
    final canDelete = st == 'draft';
    final text = const JsonEncoder.withIndent('  ').convert(data);

    return AlertDialog(
      title: Text('Production order #${widget.orderId}'),
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
                              () => _service.releaseProductionOrder(
                                widget.orderId,
                                ProductionOrderModel(<String, dynamic>{}),
                              ),
                            ),
                    child: const Text('Release'),
                  ),
                if (canClose)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.closeProductionOrder(
                                widget.orderId,
                                ProductionOrderModel(<String, dynamic>{}),
                              ),
                            ),
                    child: const Text('Close'),
                  ),
                if (canCancel)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.cancelProductionOrder(
                                widget.orderId,
                                ProductionOrderModel(<String, dynamic>{}),
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

class _MaterialIssueDetailDialog extends StatefulWidget {
  const _MaterialIssueDetailDialog({required this.issueId});

  final int issueId;

  @override
  State<_MaterialIssueDetailDialog> createState() =>
      _MaterialIssueDetailDialogState();
}

class _MaterialIssueDetailDialogState extends State<_MaterialIssueDetailDialog> {
  final ManufacturingService _service = ManufacturingService();
  bool _loading = true;
  String? _error;
  ProductionMaterialIssueModel? _model;
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
      final response = await _service.productionMaterialIssue(widget.issueId);
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
    Future<ApiResponse<ProductionMaterialIssueModel>> Function() fn,
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
        const SnackBar(content: Text('Material issue updated.')),
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
        title: const Text('Delete material issue'),
        content: const Text(
          'Only draft material issues can be deleted. Continue?',
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
      final response = await _service.deleteProductionMaterialIssue(
        widget.issueId,
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
        const SnackBar(content: Text('Material issue deleted.')),
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
        title: const Text('Material issue'),
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
    final st = stringValue(data, 'issue_status');
    final canPost = st == 'draft';
    final canCancel = st == 'draft';
    final canDelete = st == 'draft';
    final text = const JsonEncoder.withIndent('  ').convert(data);

    return AlertDialog(
      title: Text('Material issue #${widget.issueId}'),
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
                              () => _service.postProductionMaterialIssue(
                                widget.issueId,
                                ProductionMaterialIssueModel(
                                  <String, dynamic>{},
                                ),
                              ),
                            ),
                    child: const Text('Post'),
                  ),
                if (canCancel)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.cancelProductionMaterialIssue(
                                widget.issueId,
                                ProductionMaterialIssueModel(
                                  <String, dynamic>{},
                                ),
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

class _ProductionReceiptDetailDialog extends StatefulWidget {
  const _ProductionReceiptDetailDialog({required this.receiptId});

  final int receiptId;

  @override
  State<_ProductionReceiptDetailDialog> createState() =>
      _ProductionReceiptDetailDialogState();
}

class _ProductionReceiptDetailDialogState
    extends State<_ProductionReceiptDetailDialog> {
  final ManufacturingService _service = ManufacturingService();
  bool _loading = true;
  String? _error;
  ProductionReceiptModel? _model;
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
      final response = await _service.productionReceipt(widget.receiptId);
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
    Future<ApiResponse<ProductionReceiptModel>> Function() fn,
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
        const SnackBar(content: Text('Production receipt updated.')),
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
        title: const Text('Delete production receipt'),
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
      final response = await _service.deleteProductionReceipt(widget.receiptId);
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
        title: const Text('Production receipt'),
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
      title: Text('Production receipt #${widget.receiptId}'),
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
                              () => _service.postProductionReceipt(
                                widget.receiptId,
                                ProductionReceiptModel(<String, dynamic>{}),
                              ),
                            ),
                    child: const Text('Post'),
                  ),
                if (canCancel)
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _service.cancelProductionReceipt(
                                widget.receiptId,
                                ProductionReceiptModel(<String, dynamic>{}),
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

class BomRegisterPage extends StatefulWidget {
  const BomRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<BomRegisterPage> createState() => _BomRegisterPageState();
}

class _BomRegisterPageState extends State<BomRegisterPage> {
  final ManufacturingService _service = ManufacturingService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<BomModel> _rows = const <BomModel>[];

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
      final response = await _service.boms(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <BomModel>[];
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

  List<BomModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((BomModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'bom_code'),
            stringValue(data, 'bom_name'),
            stringValue(data, 'approval_status'),
            stringValue(data, 'version_no'),
            _outputItemLabel(data),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<BomModel>(
      title: 'Bills of material',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No BOMs found.',
      actions: const <Widget>[],
      filters: _MfgFilters(
        searchController: _searchController,
        searchHint: 'Search code, name, output item, status',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<BomModel>(
          label: 'Code',
          valueBuilder: (BomModel row) => stringValue(row.toJson(), 'bom_code'),
        ),
        PurchaseRegisterColumn<BomModel>(
          label: 'Name',
          flex: 2,
          valueBuilder: (BomModel row) => stringValue(row.toJson(), 'bom_name'),
        ),
        PurchaseRegisterColumn<BomModel>(
          label: 'Output',
          flex: 2,
          valueBuilder: (BomModel row) => _outputItemLabel(row.toJson()),
        ),
        PurchaseRegisterColumn<BomModel>(
          label: 'Approval',
          valueBuilder: (BomModel row) =>
              stringValue(row.toJson(), 'approval_status'),
        ),
      ],
      onRowTap: (BomModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        showDialog<void>(
          context: context,
          builder: (ctx) => _BomDetailDialog(bomId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
      },
    );
  }
}

class ProductionOrderRegisterPage extends StatefulWidget {
  const ProductionOrderRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProductionOrderRegisterPage> createState() =>
      _ProductionOrderRegisterPageState();
}

class _ProductionOrderRegisterPageState
    extends State<ProductionOrderRegisterPage> {
  final ManufacturingService _service = ManufacturingService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<ProductionOrderModel> _rows = const <ProductionOrderModel>[];

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
      final response = await _service.productionOrders(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <ProductionOrderModel>[];
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

  List<ProductionOrderModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((ProductionOrderModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'production_no'),
            stringValue(data, 'production_status'),
            _outputItemLabel(data),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<ProductionOrderModel>(
      title: 'Production orders',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No production orders found.',
      actions: const <Widget>[],
      filters: _MfgFilters(
        searchController: _searchController,
        searchHint: 'Search document no., status, output item',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<ProductionOrderModel>(
          label: 'No.',
          valueBuilder: (ProductionOrderModel row) =>
              stringValue(row.toJson(), 'production_no'),
        ),
        PurchaseRegisterColumn<ProductionOrderModel>(
          label: 'Date',
          valueBuilder: (ProductionOrderModel row) => displayDate(
            nullableStringValue(row.toJson(), 'production_date'),
          ),
        ),
        PurchaseRegisterColumn<ProductionOrderModel>(
          label: 'Output',
          flex: 2,
          valueBuilder: (ProductionOrderModel row) =>
              _outputItemLabel(row.toJson()),
        ),
        PurchaseRegisterColumn<ProductionOrderModel>(
          label: 'Status',
          valueBuilder: (ProductionOrderModel row) =>
              stringValue(row.toJson(), 'production_status'),
        ),
      ],
      onRowTap: (ProductionOrderModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        showDialog<void>(
          context: context,
          builder: (ctx) => _ProductionOrderDetailDialog(orderId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
      },
    );
  }
}

class ProductionMaterialIssueRegisterPage extends StatefulWidget {
  const ProductionMaterialIssueRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProductionMaterialIssueRegisterPage> createState() =>
      _ProductionMaterialIssueRegisterPageState();
}

class _ProductionMaterialIssueRegisterPageState
    extends State<ProductionMaterialIssueRegisterPage> {
  final ManufacturingService _service = ManufacturingService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<ProductionMaterialIssueModel> _rows =
      const <ProductionMaterialIssueModel>[];

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
      final response = await _service.productionMaterialIssues(
        filters: filters,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <ProductionMaterialIssueModel>[];
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

  List<ProductionMaterialIssueModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((ProductionMaterialIssueModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'issue_no'),
            stringValue(data, 'issue_status'),
            _productionOrderNo(data),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<ProductionMaterialIssueModel>(
      title: 'Production material issues',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No material issues found.',
      actions: const <Widget>[],
      filters: _MfgFilters(
        searchController: _searchController,
        searchHint: 'Search issue no., status, production order',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<ProductionMaterialIssueModel>(
          label: 'Issue no.',
          valueBuilder: (ProductionMaterialIssueModel row) =>
              stringValue(row.toJson(), 'issue_no'),
        ),
        PurchaseRegisterColumn<ProductionMaterialIssueModel>(
          label: 'Date',
          valueBuilder: (ProductionMaterialIssueModel row) => displayDate(
            nullableStringValue(row.toJson(), 'issue_date'),
          ),
        ),
        PurchaseRegisterColumn<ProductionMaterialIssueModel>(
          label: 'Prod. order',
          flex: 2,
          valueBuilder: (ProductionMaterialIssueModel row) =>
              _productionOrderNo(row.toJson()),
        ),
        PurchaseRegisterColumn<ProductionMaterialIssueModel>(
          label: 'Status',
          valueBuilder: (ProductionMaterialIssueModel row) =>
              stringValue(row.toJson(), 'issue_status'),
        ),
      ],
      onRowTap: (ProductionMaterialIssueModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        showDialog<void>(
          context: context,
          builder: (ctx) => _MaterialIssueDetailDialog(issueId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
      },
    );
  }
}

class ProductionReceiptRegisterPage extends StatefulWidget {
  const ProductionReceiptRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProductionReceiptRegisterPage> createState() =>
      _ProductionReceiptRegisterPageState();
}

class _ProductionReceiptRegisterPageState
    extends State<ProductionReceiptRegisterPage> {
  final ManufacturingService _service = ManufacturingService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<ProductionReceiptModel> _rows = const <ProductionReceiptModel>[];

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
      final response = await _service.productionReceipts(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <ProductionReceiptModel>[];
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

  List<ProductionReceiptModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((ProductionReceiptModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'receipt_no'),
            stringValue(data, 'receipt_status'),
            _productionOrderNo(data),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<ProductionReceiptModel>(
      title: 'Production receipts',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No production receipts found.',
      actions: const <Widget>[],
      filters: _MfgFilters(
        searchController: _searchController,
        searchHint: 'Search receipt no., status, production order',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<ProductionReceiptModel>(
          label: 'Receipt no.',
          valueBuilder: (ProductionReceiptModel row) =>
              stringValue(row.toJson(), 'receipt_no'),
        ),
        PurchaseRegisterColumn<ProductionReceiptModel>(
          label: 'Date',
          valueBuilder: (ProductionReceiptModel row) => displayDate(
            nullableStringValue(row.toJson(), 'receipt_date'),
          ),
        ),
        PurchaseRegisterColumn<ProductionReceiptModel>(
          label: 'Prod. order',
          flex: 2,
          valueBuilder: (ProductionReceiptModel row) =>
              _productionOrderNo(row.toJson()),
        ),
        PurchaseRegisterColumn<ProductionReceiptModel>(
          label: 'Status',
          valueBuilder: (ProductionReceiptModel row) =>
              stringValue(row.toJson(), 'receipt_status'),
        ),
      ],
      onRowTap: (ProductionReceiptModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        showDialog<void>(
          context: context,
          builder: (ctx) => _ProductionReceiptDetailDialog(receiptId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
      },
    );
  }
}
