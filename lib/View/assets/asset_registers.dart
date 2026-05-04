import 'dart:convert';

import '../../screen.dart';
import '../hr/hr_workflow_dialogs.dart';
import '../purchase/purchase_register_page.dart';
import '../purchase/purchase_support.dart';
import 'asset_shell_route.dart';

Map<String, dynamic>? _asJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

String _categoryLabel(Map<String, dynamic> data) {
  final c = _asJsonMap(data['category']);
  if (c == null) {
    return '';
  }
  final code = stringValue(c, 'category_code');
  final name = stringValue(c, 'category_name');
  if (code.isNotEmpty && name.isNotEmpty) {
    return '$code — $name';
  }
  return code.isNotEmpty ? code : name;
}

String _parentCategoryName(Map<String, dynamic> data) {
  final p = _asJsonMap(data['parent']);
  if (p == null) {
    return '';
  }
  return stringValue(p, 'category_name').isNotEmpty
      ? stringValue(p, 'category_name')
      : stringValue(p, 'category_code');
}

String _costCenterParentName(Map<String, dynamic> data) {
  final p = _asJsonMap(data['parent']);
  if (p == null) {
    return '';
  }
  return stringValue(p, 'cost_center_name').isNotEmpty
      ? stringValue(p, 'cost_center_name')
      : stringValue(p, 'cost_center_code');
}

String _assetFromDisposal(Map<String, dynamic> data) {
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

int? _disposalAssetCompanyId(Map<String, dynamic> data) {
  final a = _asJsonMap(data['asset']);
  if (a == null) {
    return null;
  }
  return intValue(a, 'company_id');
}

String _salePartyName(Map<String, dynamic> data) {
  final p = _asJsonMap(data['saleParty']);
  if (p == null) {
    return '';
  }
  final d = stringValue(p, 'display_name');
  if (d.isNotEmpty) {
    return d;
  }
  return stringValue(p, 'party_name');
}

String _branchPair(Map<String, dynamic> data) {
  final from = _asJsonMap(data['fromBranch']);
  final to = _asJsonMap(data['toBranch']);
  final a = from != null ? stringValue(from, 'name') : '';
  final b = to != null ? stringValue(to, 'name') : '';
  if (a.isEmpty && b.isEmpty) {
    return '';
  }
  return '$a → $b';
}

List<Map<String, dynamic>> _reportLines(Map<String, dynamic>? payload) {
  if (payload == null) {
    return const <Map<String, dynamic>>[];
  }
  final raw = payload['lines'];
  if (raw is! List) {
    return const <Map<String, dynamic>>[];
  }
  return raw
      .map((e) => _asJsonMap(e))
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
}

class _AssetFilters extends StatelessWidget {
  const _AssetFilters({
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

// --- Cost center -------------------------------------------------------

class _CostCenterDetailDialog extends StatefulWidget {
  const _CostCenterDetailDialog({required this.costCenterId});

  final int costCenterId;

  @override
  State<_CostCenterDetailDialog> createState() =>
      _CostCenterDetailDialogState();
}

class _CostCenterDetailDialogState extends State<_CostCenterDetailDialog> {
  final AssetsService _api = AssetsService();
  bool _loading = true;
  String? _error;
  CostCenterModel? _model;
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
      final response = await _api.costCenter(widget.costCenterId);
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
        title: const Text('Delete cost center'),
        content: const Text(
          'Only cost centers without children or linked assets can be deleted.',
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
      final response = await _api.deleteCostCenter(widget.costCenterId);
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
        const SnackBar(content: Text('Cost center deleted.')),
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
        title: const Text('Cost center'),
        content: Text(_error!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    }
    final raw = _model!.raw ?? _model!.toJson();
    final text = const JsonEncoder.withIndent('  ').convert(raw);

    return AlertDialog(
      title: Text('Cost center #${widget.costCenterId}'),
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

// --- Asset books sub-dialog -------------------------------------------

class _AssetBooksDialog extends StatefulWidget {
  const _AssetBooksDialog({required this.assetId});

  final int assetId;

  @override
  State<_AssetBooksDialog> createState() => _AssetBooksDialogState();
}

class _AssetBooksDialogState extends State<_AssetBooksDialog> {
  final AssetsService _api = AssetsService();
  bool _loading = true;
  String? _error;
  List<AssetBookModel> _books = const <AssetBookModel>[];
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
      final response = await _api.assetBooks(
        widget.assetId,
        filters: <String, dynamic>{'per_page': 100},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _books = response.data ?? const <AssetBookModel>[];
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

  Future<void> _deleteBook(int bookId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete asset book'),
        content: const Text('Delete this book for the asset?'),
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
      final response = await _api.deleteAssetBook(widget.assetId, bookId);
      if (!mounted) {
        return;
      }
      if (response.success != true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
        return;
      }
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
    return AlertDialog(
      title: Text('Books — asset #${widget.assetId}'),
      content: SizedBox(
        width: 480,
        height: 360,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Text(_error!)
                : _busy
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _books.length,
                        itemBuilder: (ctx, i) {
                          final b = _books[i].toJson();
                          final id = intValue(b, 'id');
                          final type = stringValue(b, 'book_type');
                          final nbv = b['net_book_value']?.toString() ?? '';
                          return ListTile(
                            title: Text(type.isEmpty ? 'Book' : type),
                            subtitle: Text('NBV: $nbv'),
                            trailing: id == null
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _deleteBook(id),
                                  ),
                          );
                        },
                      ),
      ),
      actions: [
        TextButton(onPressed: _load, child: const Text('Refresh')),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// --- Fixed asset -------------------------------------------------------

class _FixedAssetDetailDialog extends StatefulWidget {
  const _FixedAssetDetailDialog({required this.assetId});

  final int assetId;

  @override
  State<_FixedAssetDetailDialog> createState() =>
      _FixedAssetDetailDialogState();
}

class _FixedAssetDetailDialogState extends State<_FixedAssetDetailDialog> {
  final AssetsService _api = AssetsService();
  bool _loading = true;
  String? _error;
  AssetModel? _model;
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
      final response = await _api.asset(widget.assetId);
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

  Future<void> _act(Future<ApiResponse<AssetModel>> Function() fn) async {
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
        const SnackBar(content: Text('Asset updated.')),
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
        title: const Text('Delete asset'),
        content: const Text(
          'Requires all asset books to be removed first. Continue?',
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
      final response = await _api.deleteAsset(widget.assetId);
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
        const SnackBar(content: Text('Asset deleted.')),
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

  void _openBooks() {
    showDialog<void>(
      context: context,
      builder: (ctx) => _AssetBooksDialog(assetId: widget.assetId),
    ).then((_) {
      if (mounted) {
        _load();
      }
    });
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
        title: const Text('Asset'),
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
    final st = stringValue(data, 'asset_status');
    final empty = AssetModel(<String, dynamic>{});
    final canActivate = st != 'disposed';
    final text = const JsonEncoder.withIndent('  ').convert(data);

    return AlertDialog(
      title: Text('Asset #${widget.assetId}'),
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
                if (canActivate)
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _act(
                              () => _api.activateAsset(widget.assetId, empty),
                            ),
                    child: const Text('Activate'),
                  ),
                FilledButton.tonal(
                  onPressed: _busy ? null : _openBooks,
                  child: const Text('Books'),
                ),
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


// --- Reports hub -------------------------------------------------------

enum _AssetReportTab { register, depreciation, disposal }

class AssetReportsHubPage extends StatefulWidget {
  const AssetReportsHubPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AssetReportsHubPage> createState() => _AssetReportsHubPageState();
}

class _AssetReportsHubPageState extends State<AssetReportsHubPage> {
  final AssetsService _api = AssetsService();
  _AssetReportTab _tab = _AssetReportTab.register;
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _payload;
  String? _companyBanner;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  Future<void> _loadBanner() async {
    final info = await hrSessionCompanyInfo();
    if (mounted) {
      setState(() => _companyBanner = info.banner);
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
      _payload = null;
    });
    try {
      final info = await hrSessionCompanyInfo();
      final filters = <String, dynamic>{};
      if (info.companyId != null) {
        filters['company_id'] = info.companyId;
      }
      final ApiResponse<Map<String, dynamic>> response;
      switch (_tab) {
        case _AssetReportTab.register:
          response = await _api.fetchAssetRegisterReport(filters: filters);
          break;
        case _AssetReportTab.depreciation:
          response = await _api.fetchDepreciationSummaryReport(
            filters: filters,
          );
          break;
        case _AssetReportTab.disposal:
          response = await _api.fetchDisposalSummaryReport(filters: filters);
          break;
      }
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
        _payload = response.data;
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

  List<DataColumn> _buildColumns(List<Map<String, dynamic>> lines) {
    if (lines.isEmpty) {
      return const <DataColumn>[];
    }
    final keys = lines.first.keys.toList()..sort();
    return keys
        .map(
          (k) => DataColumn(
            label: Text(
              k,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList(growable: false);
  }

  List<DataRow> _buildRows(List<Map<String, dynamic>> lines) {
    if (lines.isEmpty) {
      return const <DataRow>[];
    }
    final keys = lines.first.keys.toList()..sort();
    return lines
        .map(
          (row) => DataRow(
            cells: keys
                .map(
                  (k) => DataCell(
                    SelectableText(
                      row[k]?.toString() ?? '',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = _reportLines(_payload);
    final summaryEntries = _payload?.entries
            .where((e) => e.key != 'lines')
            .toList(growable: false) ??
        const <MapEntry<String, dynamic>>[];

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_companyBanner != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
            child: Text(
              'Session company: $_companyBanner. Reports use company_id when set.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        SegmentedButton<_AssetReportTab>(
          segments: const <ButtonSegment<_AssetReportTab>>[
            ButtonSegment(
              value: _AssetReportTab.register,
              label: Text('Register'),
              icon: Icon(Icons.list_alt_outlined),
            ),
            ButtonSegment(
              value: _AssetReportTab.depreciation,
              label: Text('Depreciation'),
              icon: Icon(Icons.trending_down_outlined),
            ),
            ButtonSegment(
              value: _AssetReportTab.disposal,
              label: Text('Disposals'),
              icon: Icon(Icons.delete_sweep_outlined),
            ),
          ],
          selected: <_AssetReportTab>{_tab},
          onSelectionChanged: (Set<_AssetReportTab> s) {
            setState(() {
              _tab = s.first;
              _payload = null;
              _error = null;
            });
          },
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        FilledButton.icon(
          onPressed: _loading ? null : _fetch,
          icon: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_outlined),
          label: const Text('Load report'),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppUiConstants.spacingSm),
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
        ],
        if (_payload != null && _error == null) ...[
          const SizedBox(height: AppUiConstants.spacingMd),
          Wrap(
            spacing: AppUiConstants.spacingMd,
            runSpacing: AppUiConstants.spacingSm,
            children: summaryEntries
                .map(
                  (e) => Chip(
                    label: Text('${e.key}: ${e.value}'),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          Expanded(
            child: lines.isEmpty
                ? const Center(child: Text('No lines in report.'))
                : Scrollbar(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: _buildColumns(lines),
                          rows: _buildRows(lines),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ],
    );

    if (widget.embedded) {
      return Padding(
        padding: const EdgeInsets.all(AppUiConstants.spacingMd),
        child: body,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Asset reports')),
      body: Padding(
        padding: const EdgeInsets.all(AppUiConstants.spacingMd),
        child: body,
      ),
    );
  }
}

// --- Registers ---------------------------------------------------------

class AssetCategoryRegisterPage extends StatefulWidget {
  const AssetCategoryRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AssetCategoryRegisterPage> createState() =>
      _AssetCategoryRegisterPageState();
}

class _AssetCategoryRegisterPageState extends State<AssetCategoryRegisterPage> {
  final AssetsService _api = AssetsService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<AssetCategoryModel> _rows = const <AssetCategoryModel>[];

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
      final response = await _api.categories(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <AssetCategoryModel>[];
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

  List<AssetCategoryModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((AssetCategoryModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'category_code'),
            stringValue(data, 'category_name'),
            stringValue(data, 'asset_type'),
            _parentCategoryName(data),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<AssetCategoryModel>(
      title: 'Asset categories',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No categories found.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: () =>
              openAssetShellRoute(context, '/assets/categories/new'),
          icon: Icons.add_outlined,
          label: 'New category',
        ),
      ],
      filters: _AssetFilters(
        searchController: _searchController,
        searchHint: 'Search code, name, type, parent',
        companyBanner: _companyBanner,
        scopeHint: 'Lists use company_id when a session company is set.',
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<AssetCategoryModel>(
          label: 'Code',
          valueBuilder: (AssetCategoryModel row) =>
              stringValue(row.toJson(), 'category_code'),
        ),
        PurchaseRegisterColumn<AssetCategoryModel>(
          label: 'Name',
          flex: 2,
          valueBuilder: (AssetCategoryModel row) =>
              stringValue(row.toJson(), 'category_name'),
        ),
        PurchaseRegisterColumn<AssetCategoryModel>(
          label: 'Type',
          valueBuilder: (AssetCategoryModel row) =>
              stringValue(row.toJson(), 'asset_type'),
        ),
        PurchaseRegisterColumn<AssetCategoryModel>(
          label: 'Parent',
          valueBuilder: (AssetCategoryModel row) =>
              _parentCategoryName(row.toJson()),
        ),
      ],
      onRowTap: (AssetCategoryModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        openAssetShellRoute(context, '/assets/categories/$id');
      },
    );
  }
}

class AssetCostCenterRegisterPage extends StatefulWidget {
  const AssetCostCenterRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AssetCostCenterRegisterPage> createState() =>
      _AssetCostCenterRegisterPageState();
}

class _AssetCostCenterRegisterPageState extends State<AssetCostCenterRegisterPage> {
  final AssetsService _api = AssetsService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<CostCenterModel> _rows = const <CostCenterModel>[];

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
      final response = await _api.costCenters(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <CostCenterModel>[];
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

  List<CostCenterModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((CostCenterModel row) {
          final raw = row.raw ?? row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            row.costCenterCode ?? '',
            row.costCenterName ?? '',
            stringValue(raw, 'cost_center_type'),
            _costCenterParentName(raw),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<CostCenterModel>(
      title: 'Cost centers',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No cost centers found.',
      actions: const <Widget>[],
      filters: _AssetFilters(
        searchController: _searchController,
        searchHint: 'Search code, name, type, parent',
        companyBanner: _companyBanner,
        scopeHint: 'Lists use company_id when a session company is set.',
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<CostCenterModel>(
          label: 'Code',
          valueBuilder: (CostCenterModel row) => row.costCenterCode ?? '',
        ),
        PurchaseRegisterColumn<CostCenterModel>(
          label: 'Name',
          flex: 2,
          valueBuilder: (CostCenterModel row) => row.costCenterName ?? '',
        ),
        PurchaseRegisterColumn<CostCenterModel>(
          label: 'Type',
          valueBuilder: (CostCenterModel row) =>
              stringValue(row.raw ?? row.toJson(), 'cost_center_type'),
        ),
        PurchaseRegisterColumn<CostCenterModel>(
          label: 'Parent',
          valueBuilder: (CostCenterModel row) =>
              _costCenterParentName(row.raw ?? row.toJson()),
        ),
      ],
      onRowTap: (CostCenterModel row) {
        final id = row.id;
        if (id == null) {
          return;
        }
        showDialog<void>(
          context: context,
          builder: (ctx) => _CostCenterDetailDialog(costCenterId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
      },
    );
  }
}

class FixedAssetRegisterPage extends StatefulWidget {
  const FixedAssetRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<FixedAssetRegisterPage> createState() => _FixedAssetRegisterPageState();
}

class _FixedAssetRegisterPageState extends State<FixedAssetRegisterPage> {
  final AssetsService _api = AssetsService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<AssetModel> _rows = const <AssetModel>[];

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
      final response = await _api.assets(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <AssetModel>[];
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

  List<AssetModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((AssetModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'asset_code'),
            stringValue(data, 'asset_name'),
            stringValue(data, 'asset_status'),
            _categoryLabel(data),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<AssetModel>(
      title: 'Fixed assets',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No assets found.',
      actions: const <Widget>[],
      filters: _AssetFilters(
        searchController: _searchController,
        searchHint: 'Search code, name, category, status',
        companyBanner: _companyBanner,
        scopeHint: 'Lists use company_id when a session company is set.',
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<AssetModel>(
          label: 'Code',
          valueBuilder: (AssetModel row) =>
              stringValue(row.toJson(), 'asset_code'),
        ),
        PurchaseRegisterColumn<AssetModel>(
          label: 'Name',
          flex: 2,
          valueBuilder: (AssetModel row) =>
              stringValue(row.toJson(), 'asset_name'),
        ),
        PurchaseRegisterColumn<AssetModel>(
          label: 'Category',
          valueBuilder: (AssetModel row) => _categoryLabel(row.toJson()),
        ),
        PurchaseRegisterColumn<AssetModel>(
          label: 'Status',
          valueBuilder: (AssetModel row) =>
              stringValue(row.toJson(), 'asset_status'),
        ),
        PurchaseRegisterColumn<AssetModel>(
          label: 'Books',
          valueBuilder: (AssetModel row) =>
              intValue(row.toJson(), 'books_count')?.toString() ?? '—',
        ),
      ],
      onRowTap: (AssetModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        showDialog<void>(
          context: context,
          builder: (ctx) => _FixedAssetDetailDialog(assetId: id),
        ).then((_) {
          if (mounted) {
            _load();
          }
        });
      },
    );
  }
}

class AssetDepreciationRunRegisterPage extends StatefulWidget {
  const AssetDepreciationRunRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AssetDepreciationRunRegisterPage> createState() =>
      _AssetDepreciationRunRegisterPageState();
}

class _AssetDepreciationRunRegisterPageState
    extends State<AssetDepreciationRunRegisterPage> {
  final AssetsService _api = AssetsService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<AssetDepreciationRunModel> _rows =
      const <AssetDepreciationRunModel>[];

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
      final response = await _api.depreciationRuns(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <AssetDepreciationRunModel>[];
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

  List<AssetDepreciationRunModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((AssetDepreciationRunModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'run_no'),
            stringValue(data, 'run_status'),
            stringValue(data, 'book_type'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<AssetDepreciationRunModel>(
      title: 'Depreciation runs',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No depreciation runs found.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: () => openAssetShellRoute(
            context,
            '/assets/depreciation-runs/new',
          ),
          icon: Icons.add_outlined,
          label: 'New depreciation run',
        ),
      ],
      filters: _AssetFilters(
        searchController: _searchController,
        searchHint: 'Search run no., status, book type',
        companyBanner: _companyBanner,
        scopeHint: 'Lists use company_id when a session company is set.',
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<AssetDepreciationRunModel>(
          label: 'Run no.',
          valueBuilder: (AssetDepreciationRunModel row) =>
              stringValue(row.toJson(), 'run_no'),
        ),
        PurchaseRegisterColumn<AssetDepreciationRunModel>(
          label: 'Date',
          valueBuilder: (AssetDepreciationRunModel row) => displayDate(
            nullableStringValue(row.toJson(), 'run_date'),
          ),
        ),
        PurchaseRegisterColumn<AssetDepreciationRunModel>(
          label: 'Status',
          valueBuilder: (AssetDepreciationRunModel row) =>
              stringValue(row.toJson(), 'run_status'),
        ),
        PurchaseRegisterColumn<AssetDepreciationRunModel>(
          label: 'Lines',
          valueBuilder: (AssetDepreciationRunModel row) =>
              intValue(row.toJson(), 'lines_count')?.toString() ?? '—',
        ),
      ],
      onRowTap: (AssetDepreciationRunModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        openAssetShellRoute(context, '/assets/depreciation-runs/$id');
      },
    );
  }
}

class AssetTransferRegisterPage extends StatefulWidget {
  const AssetTransferRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AssetTransferRegisterPage> createState() =>
      _AssetTransferRegisterPageState();
}

class _AssetTransferRegisterPageState extends State<AssetTransferRegisterPage> {
  final AssetsService _api = AssetsService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<AssetTransferModel> _rows = const <AssetTransferModel>[];

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
      final response = await _api.transfers(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <AssetTransferModel>[];
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

  List<AssetTransferModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((AssetTransferModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'transfer_no'),
            stringValue(data, 'transfer_status'),
            _branchPair(data),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<AssetTransferModel>(
      title: 'Asset transfers',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No transfers found.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: () =>
              openAssetShellRoute(context, '/assets/transfers/new'),
          icon: Icons.add_outlined,
          label: 'New transfer',
        ),
      ],
      filters: _AssetFilters(
        searchController: _searchController,
        searchHint: 'Search no., branches, status',
        companyBanner: _companyBanner,
        scopeHint: 'Lists use company_id when a session company is set.',
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<AssetTransferModel>(
          label: 'Transfer no.',
          valueBuilder: (AssetTransferModel row) =>
              stringValue(row.toJson(), 'transfer_no'),
        ),
        PurchaseRegisterColumn<AssetTransferModel>(
          label: 'Date',
          valueBuilder: (AssetTransferModel row) => displayDate(
            nullableStringValue(row.toJson(), 'transfer_date'),
          ),
        ),
        PurchaseRegisterColumn<AssetTransferModel>(
          label: 'Branches',
          flex: 2,
          valueBuilder: (AssetTransferModel row) =>
              _branchPair(row.toJson()),
        ),
        PurchaseRegisterColumn<AssetTransferModel>(
          label: 'Status',
          valueBuilder: (AssetTransferModel row) =>
              stringValue(row.toJson(), 'transfer_status'),
        ),
      ],
      onRowTap: (AssetTransferModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        openAssetShellRoute(context, '/assets/transfers/$id');
      },
    );
  }
}

class AssetDisposalRegisterPage extends StatefulWidget {
  const AssetDisposalRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AssetDisposalRegisterPage> createState() =>
      _AssetDisposalRegisterPageState();
}

class _AssetDisposalRegisterPageState extends State<AssetDisposalRegisterPage> {
  final AssetsService _api = AssetsService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  int? _sessionCompanyId;
  List<AssetDisposalModel> _rows = const <AssetDisposalModel>[];

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
      final response = await _api.disposals(
        filters: <String, dynamic>{'per_page': 200},
      );
      if (!mounted) {
        return;
      }
      var rows = response.data ?? const <AssetDisposalModel>[];
      if (info.companyId != null) {
        final cid = info.companyId!;
        rows = rows
            .where((AssetDisposalModel r) {
              return _disposalAssetCompanyId(r.toJson()) == cid;
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

  List<AssetDisposalModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((AssetDisposalModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'disposal_no'),
            stringValue(data, 'disposal_status'),
            _assetFromDisposal(data),
            _salePartyName(data),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final scopeHint = _sessionCompanyId != null
        ? 'Disposals are filtered client-side by nested asset.company_id.'
        : 'API list is not company-scoped; select a session company to filter.';

    return PurchaseRegisterPage<AssetDisposalModel>(
      title: 'Asset disposals',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No disposals found.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: () =>
              openAssetShellRoute(context, '/assets/disposals/new'),
          icon: Icons.add_outlined,
          label: 'New disposal',
        ),
      ],
      filters: _AssetFilters(
        searchController: _searchController,
        searchHint: 'Search no., asset, party, status',
        companyBanner: _companyBanner,
        scopeHint: scopeHint,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<AssetDisposalModel>(
          label: 'Disposal no.',
          valueBuilder: (AssetDisposalModel row) =>
              stringValue(row.toJson(), 'disposal_no'),
        ),
        PurchaseRegisterColumn<AssetDisposalModel>(
          label: 'Date',
          valueBuilder: (AssetDisposalModel row) => displayDate(
            nullableStringValue(row.toJson(), 'disposal_date'),
          ),
        ),
        PurchaseRegisterColumn<AssetDisposalModel>(
          label: 'Asset',
          flex: 2,
          valueBuilder: (AssetDisposalModel row) =>
              _assetFromDisposal(row.toJson()),
        ),
        PurchaseRegisterColumn<AssetDisposalModel>(
          label: 'Status',
          valueBuilder: (AssetDisposalModel row) =>
              stringValue(row.toJson(), 'disposal_status'),
        ),
      ],
      onRowTap: (AssetDisposalModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        openAssetShellRoute(context, '/assets/disposals/$id');
      },
    );
  }
}
