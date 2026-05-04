import '../../screen.dart';
import '../../view_model/assets/asset_depreciation_run_view_model.dart';
import '../purchase/purchase_support.dart';
import 'asset_shell_route.dart';

Map<String, dynamic>? _jsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

String _personName(Map<String, dynamic>? m) {
  if (m == null) {
    return '—';
  }
  final d = stringValue(m, 'display_name');
  if (d.isNotEmpty) {
    return d;
  }
  final u = stringValue(m, 'username');
  return u.isNotEmpty ? u : '—';
}

class AssetDepreciationRunPage extends StatefulWidget {
  const AssetDepreciationRunPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<AssetDepreciationRunPage> createState() =>
      _AssetDepreciationRunPageState();
}

class _AssetDepreciationRunPageState extends State<AssetDepreciationRunPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final AssetDepreciationRunViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = AssetDepreciationRunViewModel()
      ..load(selectId: widget.initialId);
  }

  @override
  void dispose() {
    _vm.dispose();
    _pageScrollController.dispose();
    _workspaceController.dispose();
    super.dispose();
  }

  void _openRoute(String route) {
    final navigate = ShellRouteScope.maybeOf(context);
    if (navigate != null) {
      navigate(route);
      return;
    }
    Navigator.of(context).pushNamed(route);
  }

  void _snack() {
    final msg = _vm.consumeActionMessage();
    if (!mounted || msg == null || msg.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _vm,
      builder: (context, _) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () {
              _vm.resetDraft();
              _openRoute('/assets/depreciation-runs/new');
              if (!Responsive.isDesktop(context)) {
                _workspaceController.openEditor();
              }
            },
            icon: Icons.add_outlined,
            label: 'New depreciation run',
          ),
        ];
        final content = _buildContent(context);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Depreciation runs',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_vm.loading) {
      return const AppLoadingView(message: 'Loading depreciation runs...');
    }
    if (_vm.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load depreciation runs',
        message: _vm.pageError!,
        onRetry: () => _vm.load(selectId: widget.initialId),
      );
    }

    final editorTitle = _vm.detail != null
        ? () {
            final data = _vm.detail!.toJson();
            final no = stringValue(data, 'run_no');
            final id = intValue(data, 'id');
            if (no.isNotEmpty) {
              return no;
            }
            return id != null ? 'Run #$id' : 'Depreciation run';
          }()
        : 'New depreciation run';

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Depreciation runs',
      editorTitle: editorTitle,
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<AssetDepreciationRunModel>(
        searchController: _vm.searchController,
        searchHint: 'Search run no., status, book type',
        items: _vm.filteredRows,
        selectedItem: _vm.selected,
        emptyMessage: 'No depreciation runs found.',
        itemBuilder: (item, selected) {
          return SettingsListTile(
            title: _vm.listTitle(item),
            subtitle: _vm.listSubtitle(item),
            selected: selected,
            onTap: () async {
              final isDesktop = Responsive.isDesktop(context);
              await _vm.select(item);
              if (!mounted) {
                return;
              }
              final id = intValue(item.toJson(), 'id');
              if (id != null) {
                _openRoute('/assets/depreciation-runs/$id');
              }
              if (!isDesktop) {
                _workspaceController.openEditor();
              }
            },
          );
        },
      ),
      editor: _vm.detailLoading
          ? const AppLoadingView(message: 'Loading depreciation run...')
          : _AssetDepreciationRunEditor(
              vm: _vm,
              onProcess: () async {
                await _vm.runProcess();
                _snack();
              },
              onPost: () async {
                await _vm.runPost();
                _snack();
              },
              onCancelRun: () async {
                await _vm.runCancel();
                _snack();
              },
              onDelete: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete depreciation run'),
                    content: const Text(
                      'Only draft, failed, or cancelled runs can be deleted.',
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
                if (ok != true) {
                  return;
                }
                final deleted = await _vm.runDelete();
                if (!context.mounted) {
                  return;
                }
                if (deleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Run deleted.')),
                  );
                  openAssetShellRoute(context, '/assets/depreciation-runs');
                } else {
                  _snack();
                }
              },
              onRefresh: () async {
                await _vm.refreshDetail();
                _snack();
              },
              onCreate: () async {
                final id = await _vm.createDraft();
                if (!context.mounted) {
                  return;
                }
                if (id != null) {
                  openAssetShellRoute(context, '/assets/depreciation-runs/$id');
                } else {
                  _snack();
                }
              },
            ),
    );
  }
}

class _AssetDepreciationRunEditor extends StatelessWidget {
  const _AssetDepreciationRunEditor({
    required this.vm,
    required this.onProcess,
    required this.onPost,
    required this.onCancelRun,
    required this.onDelete,
    required this.onRefresh,
    required this.onCreate,
  });

  final AssetDepreciationRunViewModel vm;
  final Future<void> Function() onProcess;
  final Future<void> Function() onPost;
  final Future<void> Function() onCancelRun;
  final Future<void> Function() onDelete;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onCreate;

  @override
  Widget build(BuildContext context) {
    if (vm.detail == null && vm.selected == null) {
      return _CreateDepreciationRunForm(
        vm: vm,
        onCreate: onCreate,
      );
    }
    final detail = vm.detail;
    if (detail == null) {
      return const SettingsEmptyState(
        icon: Icons.trending_down_outlined,
        title: 'Select a depreciation run',
        message:
            'Choose a row from the list or create a new depreciation run.',
      );
    }

    final data = detail.toJson();
    final st = stringValue(data, 'run_status');
    final vid = intValue(data, 'voucher_id');
    final canProcess = st == 'draft' || st == 'failed';
    final canPost = st == 'completed' && (vid == null || vid == 0);
    final canCancel = st != 'posted';
    final canDelete =
        st == 'draft' || st == 'failed' || st == 'cancelled';
    final theme = Theme.of(context);
    final voucher = _jsonMap(data['voucher']);
    final creator = _jsonMap(data['creator']);
    final poster = _jsonMap(data['poster']);
    final rawLines = data['lines'];
    final lineMaps = <Map<String, dynamic>>[];
    if (rawLines is List) {
      for (final dynamic item in rawLines) {
        final m = _jsonMap(item);
        if (m != null) {
          lineMaps.add(m);
        }
      }
    }
    final busy = vm.actionBusy;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (busy) const LinearProgressIndicator(),
                Wrap(
                  spacing: AppUiConstants.spacingSm,
                  runSpacing: AppUiConstants.spacingSm,
                  children: [
                    if (canProcess)
                      FilledButton(
                        onPressed: busy ? null : () => onProcess(),
                        child: const Text('Process'),
                      ),
                    if (canPost)
                      FilledButton.tonal(
                        onPressed: busy ? null : () => onPost(),
                        child: const Text('Post'),
                      ),
                    if (canCancel)
                      FilledButton.tonal(
                        onPressed: busy ? null : () => onCancelRun(),
                        child: const Text('Cancel run'),
                      ),
                    if (canDelete)
                      OutlinedButton(
                        onPressed: busy ? null : () => onDelete(),
                        child: const Text('Delete'),
                      ),
                    OutlinedButton(
                      onPressed: busy ? null : () => onRefresh(),
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
                const SizedBox(height: AppUiConstants.spacingLg),
                SettingsFormWrap(
                  children: [
                    AppFormTextField(
                      labelText: 'Run no.',
                      initialValue: stringValue(data, 'run_no'),
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'Status',
                      initialValue: stringValue(data, 'run_status'),
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'Book type',
                      initialValue: stringValue(data, 'book_type'),
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'Run date',
                      initialValue: displayDate(
                        nullableStringValue(data, 'run_date'),
                      ),
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'Depreciation from',
                      initialValue: displayDate(
                        nullableStringValue(data, 'depreciation_from_date'),
                      ),
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'Depreciation to',
                      initialValue: displayDate(
                        nullableStringValue(data, 'depreciation_to_date'),
                      ),
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'Total depreciation',
                      initialValue:
                          stringValue(data, 'total_depreciation_amount'),
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'Assets processed',
                      initialValue:
                          intValue(data, 'total_assets_processed')
                              ?.toString() ??
                          '—',
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'Notes',
                      initialValue: stringValue(data, 'notes'),
                      maxLines: 3,
                      readOnly: true,
                    ),
                    if (stringValue(data, 'error_message').isNotEmpty)
                      AppFormTextField(
                        labelText: 'Error',
                        initialValue: stringValue(data, 'error_message'),
                        maxLines: 3,
                        readOnly: true,
                      ),
                    AppFormTextField(
                      labelText: 'Created by',
                      initialValue: _personName(creator),
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'Posted by',
                      initialValue: _personName(poster),
                      readOnly: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (voucher != null) ...[
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Voucher', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppUiConstants.spacingMd),
                  SettingsFormWrap(
                    children: [
                      AppFormTextField(
                        labelText: 'Voucher no.',
                        initialValue: stringValue(voucher, 'voucher_no'),
                        readOnly: true,
                      ),
                      AppFormTextField(
                        labelText: 'Voucher date',
                        initialValue: displayDate(
                          nullableStringValue(voucher, 'voucher_date'),
                        ),
                        readOnly: true,
                      ),
                      AppFormTextField(
                        labelText: 'Approval',
                        initialValue: stringValue(
                          voucher,
                          'approval_status',
                        ),
                        readOnly: true,
                      ),
                      AppFormTextField(
                        labelText: 'Posting',
                        initialValue: stringValue(
                          voucher,
                          'posting_status',
                        ),
                        readOnly: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (lineMaps.isNotEmpty) ...[
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Lines (${lineMaps.length})',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppUiConstants.spacingMd),
                  ...lineMaps.map(
                    (Map<String, dynamic> line) =>
                        _DepreciationLineCard(line: line),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DepreciationLineCard extends StatelessWidget {
  const _DepreciationLineCard({required this.line});

  final Map<String, dynamic> line;

  @override
  Widget build(BuildContext context) {
    final asset = _jsonMap(line['asset']);
    final book = _jsonMap(line['book']);
    final code = asset != null ? stringValue(asset, 'asset_code') : '';
    final name = asset != null ? stringValue(asset, 'asset_name') : '';
    final assetLabel = [
      if (code.isNotEmpty) code,
      if (name.isNotEmpty) name,
    ].join(' — ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppUiConstants.spacingMd),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppUiConstants.spacingMd),
          child: SettingsFormWrap(
            children: [
              AppFormTextField(
                labelText: 'Asset',
                initialValue: assetLabel.isNotEmpty ? assetLabel : '—',
                readOnly: true,
              ),
              AppFormTextField(
                labelText: 'Depreciation amount',
                initialValue: stringValue(line, 'depreciation_amount'),
                readOnly: true,
              ),
              AppFormTextField(
                labelText: 'Line status',
                initialValue: stringValue(line, 'line_status'),
                readOnly: true,
              ),
              AppFormTextField(
                labelText: 'Opening book value',
                initialValue: stringValue(line, 'opening_book_value'),
                readOnly: true,
              ),
              AppFormTextField(
                labelText: 'Closing book value',
                initialValue: stringValue(line, 'closing_book_value'),
                readOnly: true,
              ),
              if (book != null)
                AppFormTextField(
                  labelText: 'Book (type / NBV)',
                  initialValue: [
                    stringValue(book, 'book_type'),
                    stringValue(book, 'net_book_value'),
                  ].where((s) => s.isNotEmpty).join(' · '),
                  readOnly: true,
                ),
              AppFormTextField(
                labelText: 'Remarks',
                initialValue: stringValue(line, 'remarks'),
                maxLines: 2,
                readOnly: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateDepreciationRunForm extends StatelessWidget {
  const _CreateDepreciationRunForm({
    required this.vm,
    required this.onCreate,
  });

  final AssetDepreciationRunViewModel vm;
  final Future<void> Function() onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: AppSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'New depreciation run',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            if (vm.sessionCompanyId == null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
                child: Text(
                  'Select a session company in the header.',
                  style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                ),
              ),
            AppFormTextField(
              labelText: 'Run date',
              controller: vm.runDateController,
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            AppFormTextField(
              labelText: 'Depreciation from',
              controller: vm.fromDateController,
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            AppFormTextField(
              labelText: 'Depreciation to',
              controller: vm.toDateController,
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Book type',
                border: OutlineInputBorder(),
              ),
              initialValue: vm.bookType,
              items: const [
                DropdownMenuItem(value: 'financial', child: Text('financial')),
                DropdownMenuItem(value: 'tax', child: Text('tax')),
              ],
              onChanged: vm.createBusy
                  ? null
                  : (String? v) {
                      if (v != null) {
                        vm.setBookType(v);
                      }
                    },
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            if (vm.seriesOptions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
                child: Text(
                  'No ASSET_DEPRECIATION_RUN document series found for this '
                  'company.',
                  style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                ),
              )
            else
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Document series',
                  border: OutlineInputBorder(),
                ),
                initialValue: vm.documentSeriesId,
                items: vm.seriesOptions
                    .map(
                      (DocumentSeriesModel s) => DropdownMenuItem<int>(
                        value: s.id,
                        child: Text(s.toString()),
                      ),
                    )
                    .toList(growable: false),
                onChanged: vm.createBusy
                    ? null
                    : (int? v) => vm.setDocumentSeriesId(v),
              ),
            const SizedBox(height: AppUiConstants.spacingLg),
            FilledButton(
              onPressed: vm.createBusy ? null : () => onCreate(),
              child: vm.createBusy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create draft run'),
            ),
          ],
        ),
      ),
    );
  }
}
