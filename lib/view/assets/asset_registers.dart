import '../../screen.dart';

typedef AssetCompanyInfo = ({int? companyId, String? banner});
typedef AssetRegisterLoader<T> =
    Future<List<T>> Function(AssetsService service, AssetCompanyInfo info);
typedef AssetRegisterMatcher<T> = bool Function(T row, String query);
typedef AssetRegisterCompanyFilter<T> =
    List<T> Function(List<T> rows, AssetCompanyInfo info);
typedef AssetRegisterScopeHintBuilder = String Function(AssetCompanyInfo info);

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
    return '$code - $name';
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
    return '$code - $name';
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

void _showAssetSnack(String message) {
  appScaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(content: Text(message)),
  );
}

Future<bool> _confirmAssetAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
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

class AssetRegisterController<T> extends GetxController {
  AssetRegisterController({
    required this.loader,
    required this.matches,
    required this.scopeHintBuilder,
    this.companyFilter,
  });

  final AssetRegisterLoader<T> loader;
  final AssetRegisterMatcher<T> matches;
  final AssetRegisterScopeHintBuilder scopeHintBuilder;
  final AssetRegisterCompanyFilter<T>? companyFilter;
  final AssetsService _service = AssetsService();
  final TextEditingController searchController = TextEditingController();

  bool loading = true;
  String? error;
  String? companyBanner;
  int? sessionCompanyId;
  String scopeHint = '';
  List<T> rows = <T>[];

  List<T> get filteredRows {
    final query = searchController.text.trim().toLowerCase();
    return rows
        .where((row) => query.isEmpty || matches(row, query))
        .toList(growable: false);
  }

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(update);
    WorkingContextService.version.addListener(_onContextChanged);
    unawaited(load());
  }

  @override
  void onClose() {
    searchController
      ..removeListener(update)
      ..dispose();
    WorkingContextService.version.removeListener(_onContextChanged);
    super.onClose();
  }

  void _onContextChanged() {
    unawaited(load());
  }

  Future<void> load() async {
    loading = true;
    error = null;
    update();
    try {
      final info = await hrSessionCompanyInfo();
      var nextRows = await loader(_service, info);
      if (companyFilter != null) {
        nextRows = companyFilter!(nextRows, info);
      }
      companyBanner = info.banner;
      sessionCompanyId = info.companyId;
      scopeHint = scopeHintBuilder(info);
      rows = nextRows;
      loading = false;
      update();
    } catch (err) {
      error = err.toString();
      loading = false;
      update();
    }
  }
}

class _CostCenterDetailController extends GetxController {
  _CostCenterDetailController({required this.costCenterId});

  final int costCenterId;
  final AssetsService _api = AssetsService();

  bool loading = true;
  bool busy = false;
  String? error;
  CostCenterModel? model;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    loading = true;
    error = null;
    update();
    try {
      final response = await _api.costCenter(costCenterId);
      if (response.success != true || response.data == null) {
        error = response.message;
      } else {
        model = response.data;
      }
    } catch (err) {
      error = err.toString();
    } finally {
      loading = false;
      update();
    }
  }

  Future<bool> delete() async {
    busy = true;
    update();
    try {
      final response = await _api.deleteCostCenter(costCenterId);
      if (response.success != true) {
        _showAssetSnack(response.message);
        return false;
      }
      _showAssetSnack('Cost center deleted.');
      return true;
    } catch (err) {
      _showAssetSnack(err.toString());
      return false;
    } finally {
      busy = false;
      update();
    }
  }
}

class _AssetBooksDialogController extends GetxController {
  _AssetBooksDialogController({required this.assetId});

  final int assetId;
  final AssetsService _api = AssetsService();

  bool loading = true;
  bool busy = false;
  String? error;
  List<AssetBookModel> books = const <AssetBookModel>[];

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    loading = true;
    error = null;
    update();
    try {
      final response = await _api.assetBooks(
        assetId,
        filters: const <String, dynamic>{'per_page': 100},
      );
      books = response.data ?? const <AssetBookModel>[];
    } catch (err) {
      error = err.toString();
    } finally {
      loading = false;
      update();
    }
  }

  Future<void> deleteBook(int bookId) async {
    busy = true;
    update();
    try {
      final response = await _api.deleteAssetBook(assetId, bookId);
      if (response.success != true) {
        _showAssetSnack(response.message);
        return;
      }
      await load();
    } catch (err) {
      _showAssetSnack(err.toString());
    } finally {
      busy = false;
      update();
    }
  }
}

class _FixedAssetDetailController extends GetxController {
  _FixedAssetDetailController({required this.assetId});

  final int assetId;
  final AssetsService _api = AssetsService();

  bool loading = true;
  bool busy = false;
  String? error;
  AssetModel? model;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    loading = true;
    error = null;
    update();
    try {
      final response = await _api.asset(assetId);
      if (response.success != true || response.data == null) {
        error = response.message;
      } else {
        model = response.data;
      }
    } catch (err) {
      error = err.toString();
    } finally {
      loading = false;
      update();
    }
  }

  Future<void> activate() async {
    await _runAction(
      () =>
          _api.activateAsset(assetId, AssetModel.fromJson(<String, dynamic>{})),
      successMessage: 'Asset updated.',
      reloadOnSuccess: true,
    );
  }

  Future<bool> delete() async {
    return _runAction(
      () => _api.deleteAsset(assetId),
      successMessage: 'Asset deleted.',
      reloadOnSuccess: false,
    );
  }

  Future<bool> _runAction(
    Future<ApiResponse<dynamic>> Function() request, {
    required String successMessage,
    required bool reloadOnSuccess,
  }) async {
    busy = true;
    update();
    try {
      final response = await request();
      if (response.success != true) {
        _showAssetSnack(response.message);
        return false;
      }
      _showAssetSnack(successMessage);
      if (reloadOnSuccess) {
        await load();
      }
      return true;
    } catch (err) {
      _showAssetSnack(err.toString());
      return false;
    } finally {
      busy = false;
      update();
    }
  }
}

enum _AssetReportTab { register, depreciation, disposal }

class _AssetReportsHubController extends GetxController {
  final AssetsService _api = AssetsService();

  _AssetReportTab tab = _AssetReportTab.register;
  bool loading = false;
  String? error;
  String? companyBanner;
  Map<String, dynamic>? payload;

  @override
  void onInit() {
    super.onInit();
    WorkingContextService.version.addListener(_onContextChanged);
    unawaited(loadBanner());
  }

  @override
  void onClose() {
    WorkingContextService.version.removeListener(_onContextChanged);
    super.onClose();
  }

  void _onContextChanged() {
    unawaited(loadBanner());
  }

  Future<void> loadBanner() async {
    final info = await hrSessionCompanyInfo();
    companyBanner = info.banner;
    update();
  }

  void setTab(_AssetReportTab next) {
    if (tab == next) {
      return;
    }
    tab = next;
    payload = null;
    error = null;
    update();
  }

  Future<void> fetch() async {
    loading = true;
    error = null;
    payload = null;
    update();
    try {
      final info = await hrSessionCompanyInfo();
      companyBanner = info.banner;
      final filters = <String, dynamic>{};
      if (info.companyId != null) {
        filters['company_id'] = info.companyId;
      }
      final ApiResponse<Map<String, dynamic>> response;
      switch (tab) {
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
      if (response.success != true || response.data == null) {
        error = response.message;
      } else {
        payload = response.data;
      }
    } catch (err) {
      error = err.toString();
    } finally {
      loading = false;
      update();
    }
  }
}

List<DataColumn> _buildReportColumns(List<Map<String, dynamic>> lines) {
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

List<DataRow> _buildReportRows(List<Map<String, dynamic>> lines) {
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

class _AssetRegisterShell<T> extends StatefulWidget {
  const _AssetRegisterShell({
    required this.controllerName,
    required this.title,
    required this.embedded,
    required this.loader,
    required this.matches,
    required this.scopeHintBuilder,
    required this.emptyMessage,
    required this.searchHint,
    required this.columns,
    required this.onRowTap,
    required this.actionsBuilder,
    this.companyFilter,
  });

  final String controllerName;
  final String title;
  final bool embedded;
  final AssetRegisterLoader<T> loader;
  final AssetRegisterMatcher<T> matches;
  final AssetRegisterScopeHintBuilder scopeHintBuilder;
  final AssetRegisterCompanyFilter<T>? companyFilter;
  final String emptyMessage;
  final String searchHint;
  final List<PurchaseRegisterColumn<T>> columns;
  final void Function(BuildContext, AssetRegisterController<T>, T) onRowTap;
  final List<Widget> Function(BuildContext, AssetRegisterController<T>)
  actionsBuilder;

  @override
  State<_AssetRegisterShell<T>> createState() => _AssetRegisterShellState<T>();
}

class _AssetRegisterShellState<T> extends State<_AssetRegisterShell<T>> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(widget.controllerName);
    if (!Get.isRegistered<AssetRegisterController<T>>(tag: _controllerTag)) {
      Get.put(
        AssetRegisterController<T>(
          loader: widget.loader,
          matches: widget.matches,
          scopeHintBuilder: widget.scopeHintBuilder,
          companyFilter: widget.companyFilter,
        ),
        tag: _controllerTag,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AssetRegisterController<T>>(
      tag: _controllerTag,
      builder: (controller) {
        return PurchaseRegisterPage<T>(
          title: widget.title,
          embedded: widget.embedded,
          loading: controller.loading,
          errorMessage: controller.error,
          onRetry: controller.load,
          emptyMessage: widget.emptyMessage,
          actions: widget.actionsBuilder(context, controller),
          filters: _AssetFilters(
            searchController: controller.searchController,
            searchHint: widget.searchHint,
            companyBanner: controller.companyBanner,
            scopeHint: controller.scopeHint,
          ),
          rows: controller.filteredRows,
          columns: widget.columns,
          onRowTap: (row) => widget.onRowTap(context, controller, row),
        );
      },
    );
  }
}

class _CostCenterDetailDialog extends StatefulWidget {
  const _CostCenterDetailDialog({required this.costCenterId});

  final int costCenterId;

  @override
  State<_CostCenterDetailDialog> createState() =>
      _CostCenterDetailDialogState();
}

class _CostCenterDetailDialogState extends State<_CostCenterDetailDialog> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'AssetCostCenterDetailController',
      scope: <String, Object?>{'costCenterId': widget.costCenterId},
    );
    Get.put(
      _CostCenterDetailController(costCenterId: widget.costCenterId),
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    Get.delete<_CostCenterDetailController>(tag: _controllerTag, force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<_CostCenterDetailController>(
      tag: _controllerTag,
      builder: (controller) {
        if (controller.loading) {
          return const AlertDialog(
            content: SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (controller.error != null) {
          return AlertDialog(
            title: const Text('Cost center'),
            content: Text(controller.error!),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        }
        final raw = controller.model!.toJson();
        final text = const JsonEncoder.withIndent('  ').convert(raw);
        return AlertDialog(
          title: Text('Cost center #${widget.costCenterId}'),
          content: SizedBox(
            width: 560,
            height: 440,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (controller.busy)
                  const LinearProgressIndicator()
                else
                  const SizedBox(height: 4),
                Wrap(
                  spacing: AppUiConstants.spacingSm,
                  children: [
                    OutlinedButton(
                      onPressed: controller.busy
                          ? null
                          : () async {
                              final ok = await _confirmAssetAction(
                                context,
                                title: 'Delete cost center',
                                message:
                                    'Only cost centers without children '
                                    'or linked assets can be deleted.',
                              );
                              if (!ok || !context.mounted) {
                                return;
                              }
                              final deleted = await controller.delete();
                              if (deleted && context.mounted) {
                                Navigator.pop(context, true);
                              }
                            },
                      child: const Text('Delete'),
                    ),
                    OutlinedButton(
                      onPressed: controller.busy ? null : controller.load,
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
              onPressed: controller.busy ? null : () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _AssetBooksDialog extends StatefulWidget {
  const _AssetBooksDialog({required this.assetId});

  final int assetId;

  @override
  State<_AssetBooksDialog> createState() => _AssetBooksDialogState();
}

class _AssetBooksDialogState extends State<_AssetBooksDialog> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'AssetBooksDialogController',
      scope: <String, Object?>{'assetId': widget.assetId},
    );
    Get.put(
      _AssetBooksDialogController(assetId: widget.assetId),
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    Get.delete<_AssetBooksDialogController>(tag: _controllerTag, force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<_AssetBooksDialogController>(
      tag: _controllerTag,
      builder: (controller) {
        return AlertDialog(
          title: Text('Books - asset #${widget.assetId}'),
          content: SizedBox(
            width: 480,
            height: 360,
            child: controller.loading
                ? const Center(child: CircularProgressIndicator())
                : controller.error != null
                ? Text(controller.error!)
                : controller.busy
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: controller.books.length,
                    itemBuilder: (ctx, i) {
                      final b = controller.books[i].toJson();
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
                                onPressed: () async {
                                  final ok = await _confirmAssetAction(
                                    context,
                                    title: 'Delete asset book',
                                    message: 'Delete this book for the asset?',
                                  );
                                  if (!ok) {
                                    return;
                                  }
                                  await controller.deleteBook(id);
                                },
                              ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: controller.load,
              child: const Text('Refresh'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _FixedAssetDetailDialog extends StatefulWidget {
  const _FixedAssetDetailDialog({required this.assetId});

  final int assetId;

  @override
  State<_FixedAssetDetailDialog> createState() =>
      _FixedAssetDetailDialogState();
}

class _FixedAssetDetailDialogState extends State<_FixedAssetDetailDialog> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'FixedAssetDetailController',
      scope: <String, Object?>{'assetId': widget.assetId},
    );
    Get.put(
      _FixedAssetDetailController(assetId: widget.assetId),
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    Get.delete<_FixedAssetDetailController>(tag: _controllerTag, force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<_FixedAssetDetailController>(
      tag: _controllerTag,
      builder: (controller) {
        if (controller.loading) {
          return const AlertDialog(
            content: SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (controller.error != null) {
          return AlertDialog(
            title: const Text('Asset'),
            content: Text(controller.error!),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        }
        final data = controller.model!.toJson();
        final st = stringValue(data, 'asset_status');
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
                if (controller.busy)
                  const LinearProgressIndicator()
                else
                  const SizedBox(height: 4),
                Wrap(
                  spacing: AppUiConstants.spacingSm,
                  runSpacing: AppUiConstants.spacingSm,
                  children: [
                    if (canActivate)
                      FilledButton(
                        onPressed: controller.busy ? null : controller.activate,
                        child: const Text('Activate'),
                      ),
                    FilledButton.tonal(
                      onPressed: controller.busy
                          ? null
                          : () async {
                              await showDialog<void>(
                                context: context,
                                builder: (ctx) =>
                                    _AssetBooksDialog(assetId: widget.assetId),
                              );
                              await controller.load();
                            },
                      child: const Text('Books'),
                    ),
                    OutlinedButton(
                      onPressed: controller.busy
                          ? null
                          : () async {
                              final ok = await _confirmAssetAction(
                                context,
                                title: 'Delete asset',
                                message:
                                    'Requires all asset books to be '
                                    'removed first. Continue?',
                              );
                              if (!ok || !context.mounted) {
                                return;
                              }
                              final deleted = await controller.delete();
                              if (deleted && context.mounted) {
                                Navigator.pop(context, true);
                              }
                            },
                      child: const Text('Delete'),
                    ),
                    OutlinedButton(
                      onPressed: controller.busy ? null : controller.load,
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
              onPressed: controller.busy ? null : () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class AssetReportsHubPage extends StatefulWidget {
  const AssetReportsHubPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AssetReportsHubPage> createState() => _AssetReportsHubPageState();
}

class _AssetReportsHubPageState extends State<AssetReportsHubPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('AssetReportsHubController');
    if (!Get.isRegistered<_AssetReportsHubController>(tag: _controllerTag)) {
      Get.put(_AssetReportsHubController(), tag: _controllerTag);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<_AssetReportsHubController>(
      tag: _controllerTag,
      builder: (controller) {
        final theme = Theme.of(context);
        final lines = _reportLines(controller.payload);
        final summaryEntries =
            controller.payload?.entries
                .where((e) => e.key != 'lines')
                .toList(growable: false) ??
            const <MapEntry<String, dynamic>>[];

        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller.companyBanner != null)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: AppUiConstants.spacingSm,
                ),
                child: Text(
                  'Session company: ${controller.companyBanner}. '
                  'Reports use company_id when set.',
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
              selected: <_AssetReportTab>{controller.tab},
              onSelectionChanged: (Set<_AssetReportTab> s) =>
                  controller.setTab(s.first),
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            FilledButton.icon(
              onPressed: controller.loading ? null : controller.fetch,
              icon: controller.loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
              label: const Text('Load report'),
            ),
            if (controller.error != null) ...[
              const SizedBox(height: AppUiConstants.spacingSm),
              Text(
                controller.error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            if (controller.payload != null && controller.error == null) ...[
              const SizedBox(height: AppUiConstants.spacingMd),
              Wrap(
                spacing: AppUiConstants.spacingMd,
                runSpacing: AppUiConstants.spacingSm,
                children: summaryEntries
                    .map((e) => Chip(label: Text('${e.key}: ${e.value}')))
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
                              columns: _buildReportColumns(lines),
                              rows: _buildReportRows(lines),
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
      },
    );
  }
}

class AssetCategoryRegisterPage extends StatelessWidget {
  const AssetCategoryRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _AssetRegisterShell<AssetCategoryModel>(
      controllerName: 'AssetCategoryRegisterController',
      title: 'Asset categories',
      embedded: embedded,
      loader: (service, info) async {
        final filters = <String, dynamic>{'per_page': 200};
        if (info.companyId != null) {
          filters['company_id'] = info.companyId;
        }
        final response = await service.categories(filters: filters);
        return response.data ?? const <AssetCategoryModel>[];
      },
      matches: (row, query) {
        final data = row.toJson();
        return [
          stringValue(data, 'category_code'),
          stringValue(data, 'category_name'),
          stringValue(data, 'asset_type'),
          _parentCategoryName(data),
        ].join(' ').toLowerCase().contains(query);
      },
      scopeHintBuilder: (_) =>
          'Lists use company_id when a session company is set.',
      emptyMessage: 'No categories found.',
      searchHint: 'Search code, name, type, parent',
      actionsBuilder: (context, controller) => [
        AdaptiveShellActionButton(
          onPressed: () =>
              openAssetShellRoute(context, '/assets/categories/new'),
          icon: Icons.add_outlined,
          label: 'New category',
        ),
      ],
      columns: [
        PurchaseRegisterColumn<AssetCategoryModel>(
          label: 'Code',
          valueBuilder: (row) => stringValue(row.toJson(), 'category_code'),
        ),
        PurchaseRegisterColumn<AssetCategoryModel>(
          label: 'Name',
          flex: 2,
          valueBuilder: (row) => stringValue(row.toJson(), 'category_name'),
        ),
        PurchaseRegisterColumn<AssetCategoryModel>(
          label: 'Type',
          valueBuilder: (row) => stringValue(row.toJson(), 'asset_type'),
        ),
        PurchaseRegisterColumn<AssetCategoryModel>(
          label: 'Parent',
          valueBuilder: (row) => _parentCategoryName(row.toJson()),
        ),
      ],
      onRowTap: (context, controller, row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        openAssetShellRoute(context, '/assets/categories/$id');
      },
    );
  }
}

class AssetCostCenterRegisterPage extends StatelessWidget {
  const AssetCostCenterRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _AssetRegisterShell<CostCenterModel>(
      controllerName: 'AssetCostCenterRegisterController',
      title: 'Cost centers',
      embedded: embedded,
      loader: (service, info) async {
        final filters = <String, dynamic>{'per_page': 200};
        if (info.companyId != null) {
          filters['company_id'] = info.companyId;
        }
        final response = await service.costCenters(filters: filters);
        return response.data ?? const <CostCenterModel>[];
      },
      matches: (row, query) {
        final raw = row.toJson();
        return [
          row.costCenterCode ?? '',
          row.costCenterName ?? '',
          stringValue(raw, 'cost_center_type'),
          _costCenterParentName(raw),
        ].join(' ').toLowerCase().contains(query);
      },
      scopeHintBuilder: (_) =>
          'Lists use company_id when a session company is set.',
      emptyMessage: 'No cost centers found.',
      searchHint: 'Search code, name, type, parent',
      actionsBuilder: (context, controller) => const <Widget>[],
      columns: [
        PurchaseRegisterColumn<CostCenterModel>(
          label: 'Code',
          valueBuilder: (row) => row.costCenterCode ?? '',
        ),
        PurchaseRegisterColumn<CostCenterModel>(
          label: 'Name',
          flex: 2,
          valueBuilder: (row) => row.costCenterName ?? '',
        ),
        PurchaseRegisterColumn<CostCenterModel>(
          label: 'Type',
          valueBuilder: (row) => stringValue(row.toJson(), 'cost_center_type'),
        ),
        PurchaseRegisterColumn<CostCenterModel>(
          label: 'Parent',
          valueBuilder: (row) => _costCenterParentName(row.toJson()),
        ),
      ],
      onRowTap: (context, controller, row) async {
        final id = row.id;
        if (id == null) {
          return;
        }
        await showDialog<void>(
          context: context,
          builder: (ctx) => _CostCenterDetailDialog(costCenterId: id),
        );
        await controller.load();
      },
    );
  }
}

class FixedAssetRegisterPage extends StatelessWidget {
  const FixedAssetRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _AssetRegisterShell<AssetModel>(
      controllerName: 'FixedAssetRegisterController',
      title: 'Fixed assets',
      embedded: embedded,
      loader: (service, info) async {
        final filters = <String, dynamic>{'per_page': 200};
        if (info.companyId != null) {
          filters['company_id'] = info.companyId;
        }
        final response = await service.assets(filters: filters);
        return response.data ?? const <AssetModel>[];
      },
      matches: (row, query) {
        final data = row.toJson();
        return [
          stringValue(data, 'asset_code'),
          stringValue(data, 'asset_name'),
          stringValue(data, 'asset_status'),
          _categoryLabel(data),
        ].join(' ').toLowerCase().contains(query);
      },
      scopeHintBuilder: (_) =>
          'Lists use company_id when a session company is set.',
      emptyMessage: 'No assets found.',
      searchHint: 'Search code, name, category, status',
      actionsBuilder: (context, controller) => const <Widget>[],
      columns: [
        PurchaseRegisterColumn<AssetModel>(
          label: 'Code',
          valueBuilder: (row) => stringValue(row.toJson(), 'asset_code'),
        ),
        PurchaseRegisterColumn<AssetModel>(
          label: 'Name',
          flex: 2,
          valueBuilder: (row) => stringValue(row.toJson(), 'asset_name'),
        ),
        PurchaseRegisterColumn<AssetModel>(
          label: 'Category',
          valueBuilder: (row) => _categoryLabel(row.toJson()),
        ),
        PurchaseRegisterColumn<AssetModel>(
          label: 'Status',
          valueBuilder: (row) => stringValue(row.toJson(), 'asset_status'),
        ),
        PurchaseRegisterColumn<AssetModel>(
          label: 'Books',
          valueBuilder: (row) =>
              intValue(row.toJson(), 'books_count')?.toString() ?? '-',
        ),
      ],
      onRowTap: (context, controller, row) async {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        await showDialog<void>(
          context: context,
          builder: (ctx) => _FixedAssetDetailDialog(assetId: id),
        );
        await controller.load();
      },
    );
  }
}

class AssetDepreciationRunRegisterPage extends StatelessWidget {
  const AssetDepreciationRunRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _AssetRegisterShell<AssetDepreciationRunModel>(
      controllerName: 'AssetDepreciationRunRegisterController',
      title: 'Depreciation runs',
      embedded: embedded,
      loader: (service, info) async {
        final filters = <String, dynamic>{'per_page': 200};
        if (info.companyId != null) {
          filters['company_id'] = info.companyId;
        }
        final response = await service.depreciationRuns(filters: filters);
        return response.data ?? const <AssetDepreciationRunModel>[];
      },
      matches: (row, query) {
        final data = row.toJson();
        return [
          stringValue(data, 'run_no'),
          stringValue(data, 'run_status'),
          stringValue(data, 'book_type'),
        ].join(' ').toLowerCase().contains(query);
      },
      scopeHintBuilder: (_) =>
          'Lists use company_id when a session company is set.',
      emptyMessage: 'No depreciation runs found.',
      searchHint: 'Search run no., status, book type',
      actionsBuilder: (context, controller) => [
        AdaptiveShellActionButton(
          onPressed: () =>
              openAssetShellRoute(context, '/assets/depreciation-runs/new'),
          icon: Icons.add_outlined,
          label: 'New depreciation run',
        ),
      ],
      columns: [
        PurchaseRegisterColumn<AssetDepreciationRunModel>(
          label: 'Run no.',
          valueBuilder: (row) => stringValue(row.toJson(), 'run_no'),
        ),
        PurchaseRegisterColumn<AssetDepreciationRunModel>(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'run_date')),
        ),
        PurchaseRegisterColumn<AssetDepreciationRunModel>(
          label: 'Status',
          valueBuilder: (row) => stringValue(row.toJson(), 'run_status'),
        ),
        PurchaseRegisterColumn<AssetDepreciationRunModel>(
          label: 'Lines',
          valueBuilder: (row) =>
              intValue(row.toJson(), 'lines_count')?.toString() ?? '-',
        ),
      ],
      onRowTap: (context, controller, row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        openAssetShellRoute(context, '/assets/depreciation-runs/$id');
      },
    );
  }
}

class AssetTransferRegisterPage extends StatelessWidget {
  const AssetTransferRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _AssetRegisterShell<AssetTransferModel>(
      controllerName: 'AssetTransferRegisterController',
      title: 'Asset transfers',
      embedded: embedded,
      loader: (service, info) async {
        final filters = <String, dynamic>{'per_page': 200};
        if (info.companyId != null) {
          filters['company_id'] = info.companyId;
        }
        final response = await service.transfers(filters: filters);
        return response.data ?? const <AssetTransferModel>[];
      },
      matches: (row, query) {
        final data = row.toJson();
        return [
          stringValue(data, 'transfer_no'),
          stringValue(data, 'transfer_status'),
          _branchPair(data),
        ].join(' ').toLowerCase().contains(query);
      },
      scopeHintBuilder: (_) =>
          'Lists use company_id when a session company is set.',
      emptyMessage: 'No transfers found.',
      searchHint: 'Search no., branches, status',
      actionsBuilder: (context, controller) => [
        AdaptiveShellActionButton(
          onPressed: () =>
              openAssetShellRoute(context, '/assets/transfers/new'),
          icon: Icons.add_outlined,
          label: 'New transfer',
        ),
      ],
      columns: [
        PurchaseRegisterColumn<AssetTransferModel>(
          label: 'Transfer no.',
          valueBuilder: (row) => stringValue(row.toJson(), 'transfer_no'),
        ),
        PurchaseRegisterColumn<AssetTransferModel>(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'transfer_date')),
        ),
        PurchaseRegisterColumn<AssetTransferModel>(
          label: 'Branches',
          flex: 2,
          valueBuilder: (row) => _branchPair(row.toJson()),
        ),
        PurchaseRegisterColumn<AssetTransferModel>(
          label: 'Status',
          valueBuilder: (row) => stringValue(row.toJson(), 'transfer_status'),
        ),
      ],
      onRowTap: (context, controller, row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        openAssetShellRoute(context, '/assets/transfers/$id');
      },
    );
  }
}

class AssetDisposalRegisterPage extends StatelessWidget {
  const AssetDisposalRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _AssetRegisterShell<AssetDisposalModel>(
      controllerName: 'AssetDisposalRegisterController',
      title: 'Asset disposals',
      embedded: embedded,
      loader: (service, info) async {
        final response = await service.disposals(
          filters: const <String, dynamic>{'per_page': 200},
        );
        return response.data ?? const <AssetDisposalModel>[];
      },
      companyFilter: (rows, info) {
        if (info.companyId == null) {
          return rows;
        }
        return rows
            .where(
              (row) => _disposalAssetCompanyId(row.toJson()) == info.companyId,
            )
            .toList(growable: false);
      },
      matches: (row, query) {
        final data = row.toJson();
        return [
          stringValue(data, 'disposal_no'),
          stringValue(data, 'disposal_status'),
          _assetFromDisposal(data),
          _salePartyName(data),
        ].join(' ').toLowerCase().contains(query);
      },
      scopeHintBuilder: (info) => info.companyId != null
          ? 'Disposals are filtered client-side by nested asset.company_id.'
          : 'API list is not company-scoped; select a session company to filter.',
      emptyMessage: 'No disposals found.',
      searchHint: 'Search no., asset, party, status',
      actionsBuilder: (context, controller) => [
        AdaptiveShellActionButton(
          onPressed: () =>
              openAssetShellRoute(context, '/assets/disposals/new'),
          icon: Icons.add_outlined,
          label: 'New disposal',
        ),
      ],
      columns: [
        PurchaseRegisterColumn<AssetDisposalModel>(
          label: 'Disposal no.',
          valueBuilder: (row) => stringValue(row.toJson(), 'disposal_no'),
        ),
        PurchaseRegisterColumn<AssetDisposalModel>(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'disposal_date')),
        ),
        PurchaseRegisterColumn<AssetDisposalModel>(
          label: 'Asset',
          flex: 2,
          valueBuilder: (row) => _assetFromDisposal(row.toJson()),
        ),
        PurchaseRegisterColumn<AssetDisposalModel>(
          label: 'Status',
          valueBuilder: (row) => stringValue(row.toJson(), 'disposal_status'),
        ),
      ],
      onRowTap: (context, controller, row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        openAssetShellRoute(context, '/assets/disposals/$id');
      },
    );
  }
}
