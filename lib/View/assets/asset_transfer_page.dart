import '../../screen.dart';
import '../../view_model/assets/asset_transfer_view_model.dart';
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

String _entityName(Map<String, dynamic>? m) {
  if (m == null) {
    return '—';
  }
  final name = stringValue(m, 'name');
  if (name.isNotEmpty) {
    return name;
  }
  final code = stringValue(m, 'code');
  return code.isNotEmpty ? code : '—';
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

class AssetTransferPage extends StatefulWidget {
  const AssetTransferPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<AssetTransferPage> createState() => _AssetTransferPageState();
}

class _AssetTransferPageState extends State<AssetTransferPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final AssetTransferViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = AssetTransferViewModel()..load(selectId: widget.initialId);
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
              _openRoute('/assets/transfers/new');
              if (!Responsive.isDesktop(context)) {
                _workspaceController.openEditor();
              }
            },
            icon: Icons.add_outlined,
            label: 'New transfer',
          ),
        ];
        final content = _buildContent(context);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Asset transfers',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_vm.loading) {
      return const AppLoadingView(message: 'Loading transfers...');
    }
    if (_vm.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load transfers',
        message: _vm.pageError!,
        onRetry: () => _vm.load(selectId: widget.initialId),
      );
    }

    final editorTitle = _vm.detail != null
        ? () {
            final data = _vm.detail!.toJson();
            final no = stringValue(data, 'transfer_no');
            final id = intValue(data, 'id');
            if (no.isNotEmpty) {
              return no;
            }
            return id != null ? 'Transfer #$id' : 'Transfer';
          }()
        : 'New asset transfer';

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Asset transfers',
      editorTitle: editorTitle,
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<AssetTransferModel>(
        searchController: _vm.searchController,
        searchHint: 'Search no., branches, status',
        items: _vm.filteredRows,
        selectedItem: _vm.selected,
        emptyMessage: 'No transfers found.',
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
                _openRoute('/assets/transfers/$id');
              }
              if (!isDesktop) {
                _workspaceController.openEditor();
              }
            },
          );
        },
      ),
      editor: _vm.detailLoading
          ? const AppLoadingView(message: 'Loading transfer...')
          : _AssetTransferEditor(
              vm: _vm,
              onApprove: () async {
                await _vm.approve();
                _snack();
              },
              onComplete: () async {
                await _vm.complete();
                _snack();
              },
              onCancel: () async {
                await _vm.cancel();
                _snack();
              },
              onDelete: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete transfer'),
                    content: const Text('Only draft transfers can be deleted.'),
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
                final deleted = await _vm.deleteTransfer();
                if (!context.mounted) {
                  return;
                }
                if (deleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transfer deleted.')),
                  );
                  openAssetShellRoute(context, '/assets/transfers');
                } else {
                  _snack();
                }
              },
              onRefresh: () async {
                await _vm.refreshDetail();
                _snack();
              },
            ),
    );
  }
}

class _AssetTransferEditor extends StatelessWidget {
  const _AssetTransferEditor({
    required this.vm,
    required this.onApprove,
    required this.onComplete,
    required this.onCancel,
    required this.onDelete,
    required this.onRefresh,
  });

  final AssetTransferViewModel vm;
  final Future<void> Function() onApprove;
  final Future<void> Function() onComplete;
  final Future<void> Function() onCancel;
  final Future<void> Function() onDelete;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (vm.detail == null && vm.selected == null) {
      return SingleChildScrollView(
        child: AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'New asset transfer',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              Text(
                'Creating a transfer requires at least one asset line and '
                'branch details. Use the ERP web app or API until a mobile '
                'create form is added.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppUiConstants.spacingLg),
              OutlinedButton(
                onPressed: () =>
                    openAssetShellRoute(context, '/assets/transfers'),
                child: const Text('Back to transfers'),
              ),
            ],
          ),
        ),
      );
    }
    final detail = vm.detail;
    if (detail == null) {
      return const SettingsEmptyState(
        icon: Icons.swap_horiz_outlined,
        title: 'Select a transfer',
        message: 'Choose a row from the list or create a new transfer.',
      );
    }

    final data = detail.toJson();
    final st = stringValue(data, 'transfer_status');
    final canApprove = st == 'draft';
    final canComplete = st == 'draft' || st == 'approved';
    final canCancel = st != 'completed' && st != 'cancelled';
    final canDelete = st == 'draft';
    final theme = Theme.of(context);
    final fromBranch = _jsonMap(data['fromBranch']);
    final toBranch = _jsonMap(data['toBranch']);
    final fromLoc = _jsonMap(data['fromLocation']);
    final toLoc = _jsonMap(data['toLocation']);
    final voucher = _jsonMap(data['voucher']);
    final approver = _jsonMap(data['approver']);
    final creator = _jsonMap(data['creator']);
    final updater = _jsonMap(data['updater']);
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
                    if (canApprove)
                      FilledButton(
                        onPressed: busy ? null : () => onApprove(),
                        child: const Text('Approve'),
                      ),
                    if (canComplete)
                      FilledButton.tonal(
                        onPressed: busy ? null : () => onComplete(),
                        child: const Text('Complete'),
                      ),
                    if (canCancel)
                      FilledButton.tonal(
                        onPressed: busy ? null : () => onCancel(),
                        child: const Text('Cancel'),
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
                      labelText: 'Transfer no.',
                      initialValue: stringValue(data, 'transfer_no'),
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'Status',
                      initialValue: stringValue(data, 'transfer_status'),
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'Transfer date',
                      initialValue: displayDate(
                        nullableStringValue(data, 'transfer_date'),
                      ),
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'From branch',
                      initialValue: _entityName(fromBranch),
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'To branch',
                      initialValue: _entityName(toBranch),
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'From location',
                      initialValue: _entityName(fromLoc),
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'To location',
                      initialValue: _entityName(toLoc),
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'From department',
                      initialValue: stringValue(data, 'from_department_name'),
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'To department',
                      initialValue: stringValue(data, 'to_department_name'),
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'From employee',
                      initialValue: stringValue(data, 'from_employee_name'),
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'To employee',
                      initialValue: stringValue(data, 'to_employee_name'),
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'Approved by',
                      initialValue: _personName(approver),
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'Created by',
                      initialValue: _personName(creator),
                      readOnly: true,
                    ),
                    AppFormTextField(
                      labelText: 'Updated by',
                      initialValue: _personName(updater),
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
                        labelText: 'Posting',
                        initialValue: stringValue(voucher, 'posting_status'),
                        readOnly: true,
                      ),
                      AppFormTextField(
                        labelText: 'Source module',
                        initialValue: stringValue(voucher, 'source_module'),
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
                        _TransferLineCard(line: line),
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

class _TransferLineCard extends StatelessWidget {
  const _TransferLineCard({required this.line});

  final Map<String, dynamic> line;

  @override
  Widget build(BuildContext context) {
    final asset = _jsonMap(line['asset']);
    final code = asset != null ? stringValue(asset, 'asset_code') : '';
    final name = asset != null ? stringValue(asset, 'asset_name') : '';
    final assetLabel = [
      if (code.isNotEmpty) code,
      if (name.isNotEmpty) name,
    ].join(' — ');
    final lineNo = intValue(line, 'line_no')?.toString() ?? '—';
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
                labelText: 'Line no.',
                initialValue: lineNo,
                readOnly: true,
              ),
              AppFormTextField(
                labelText: 'Asset',
                initialValue: assetLabel.isNotEmpty ? assetLabel : '—',
                readOnly: true,
              ),
              AppFormTextField(
                labelText: 'Asset status',
                initialValue:
                    asset != null ? stringValue(asset, 'asset_status') : '—',
                readOnly: true,
              ),
              AppFormTextField(
                labelText: 'From branch id',
                initialValue:
                    intValue(line, 'from_branch_id')?.toString() ?? '—',
                readOnly: true,
              ),
              AppFormTextField(
                labelText: 'To branch id',
                initialValue:
                    intValue(line, 'to_branch_id')?.toString() ?? '—',
                readOnly: true,
              ),
              AppFormTextField(
                labelText: 'From location id',
                initialValue:
                    intValue(line, 'from_location_id')?.toString() ?? '—',
                readOnly: true,
              ),
              AppFormTextField(
                labelText: 'To location id',
                initialValue:
                    intValue(line, 'to_location_id')?.toString() ?? '—',
                readOnly: true,
              ),
              AppFormTextField(
                labelText: 'From department',
                initialValue: stringValue(line, 'from_department_name'),
                readOnly: true,
              ),
              AppFormTextField(
                labelText: 'To department',
                initialValue: stringValue(line, 'to_department_name'),
                readOnly: true,
              ),
              AppFormTextField(
                labelText: 'From employee',
                initialValue: stringValue(line, 'from_employee_name'),
                readOnly: true,
              ),
              AppFormTextField(
                labelText: 'To employee',
                initialValue: stringValue(line, 'to_employee_name'),
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
