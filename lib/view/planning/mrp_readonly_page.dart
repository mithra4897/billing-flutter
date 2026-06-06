import '../../screen.dart';
import 'mrp_detail_widgets.dart';

class MrpReadonlyPage extends StatefulWidget {
  const MrpReadonlyPage({
    super.key,
    required this.module,
    required this.title,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final MrpReadonlyModule module;
  final String title;
  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<MrpReadonlyPage> createState() => _MrpReadonlyPageState();
}

class _MrpReadonlyPageState extends State<MrpReadonlyPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final String _controllerTag;
  late final MrpReadonlyViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'MrpReadonlyViewModel',
      scope: <String, Object?>{'module': widget.module.name},
    );
    _viewModel = Get.put(
      MrpReadonlyViewModel(widget.module)..load(selectId: widget.initialId),
      tag: _controllerTag,
      permanent: true,
    );
  }

  @override
  void dispose() {
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

  String _baseRoute() {
    switch (widget.module) {
      case MrpReadonlyModule.demand:
        return '/planning/mrp-demands';
      case MrpReadonlyModule.supply:
        return '/planning/mrp-supplies';
      case MrpReadonlyModule.netRequirement:
        return '/planning/mrp-net-requirements';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MrpReadonlyViewModel>(
      tag: _controllerTag,
      builder: (_) {
        final content = _buildContent();
        if (widget.embedded) return content;
        return AppStandaloneShell(
          title: widget.title,
          scrollController: _pageScrollController,
          actions: const <Widget>[],
          child: content,
        );
      },
    );
  }

  Widget _buildContent() {
    if (_viewModel.loading) {
      return AppLoadingView(
        message: 'Loading ${widget.title.toLowerCase()}...',
      );
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load ${widget.title.toLowerCase()}',
        message: _viewModel.pageError!,
        onRetry: _viewModel.load,
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: widget.title,
      editorTitle: widget.title,
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.module != MrpReadonlyModule.demand) ...[
            AppDropdownField<int?>.fromMapped(
              labelText: 'MRP Run',
              mappedItems: <AppDropdownItem<int?>>[
                const AppDropdownItem<int?>(value: null, label: 'All Runs'),
                ..._viewModel.runs
                    .where((run) => run.id != null)
                    .map(
                      (run) => AppDropdownItem<int?>(
                        value: run.id,
                        label: [
                          stringValue(run.toJson(), 'run_no', 'MRP Run'),
                          stringValue(run.toJson(), 'run_status'),
                        ].where((value) => value.trim().isNotEmpty).join(' · '),
                      ),
                    ),
              ],
              initialValue: _viewModel.selectedRunId,
              onChanged: (value) => _viewModel.onRunChanged(value),
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
          ],
          SettingsListCard<JsonModel>(
            searchController: _viewModel.searchController,
            searchHint: 'Search ${widget.title.toLowerCase()}',
            items: _viewModel.filteredRows,
            selectedItem: _viewModel.selected,
            emptyMessage: 'No records found.',
            itemBuilder: (item, selected) {
              final data = item.toJson();
              return SettingsListTile(
                title: _listTitle(data),
                subtitle: _listSubtitle(data),
                selected: selected,
                onTap: () async {
                  final id = intValue(data, 'id');
                  final isDesktop = Responsive.isDesktop(context);
                  await _viewModel.select(item);
                  if (!mounted || id == null) return;
                  if (widget.editorOnly || !isDesktop) {
                    _openRoute('${_baseRoute()}/$id');
                  }
                  if (!isDesktop) _workspaceController.openEditor();
                },
              );
            },
          ),
        ],
      ),
      editor: _viewModel.detailLoading
          ? const AppLoadingView(message: 'Loading record...')
          : _MrpReadonlyDetail(
              module: widget.module,
              record: _viewModel.selected,
            ),
    );
  }

  String _listTitle(Map<String, dynamic> data) {
    final item = data['item'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(data['item'] as Map<String, dynamic>)
        : const <String, dynamic>{};
    final itemCode = stringValue(item, 'item_code');
    final itemName = stringValue(item, 'item_name');
    return _compactJoined(<String>[
      itemCode,
      itemName,
    ], fallback: 'Record #${intValue(data, 'id') ?? ''}');
  }

  String _listSubtitle(Map<String, dynamic> data) {
    switch (widget.module) {
      case MrpReadonlyModule.demand:
        return _compactJoined(<String>[
          stringValue(data, 'demand_source'),
          'Pending ${stringValue(data, 'pending_qty', '0')}',
          _shortDate(stringValue(data, 'required_date')),
        ]);
      case MrpReadonlyModule.supply:
        return _compactJoined(<String>[
          stringValue(data, 'supply_source'),
          'Avail ${stringValue(data, 'available_qty', '0')}',
          _shortDate(stringValue(data, 'available_date')),
        ]);
      case MrpReadonlyModule.netRequirement:
        return _compactJoined(<String>[
          'Short ${stringValue(data, 'shortage_qty', '0')}',
          stringValue(data, 'recommended_action'),
          'Rec ${stringValue(data, 'recommended_qty', '0')}',
        ]);
    }
  }

  String _compactJoined(List<String> values, {String fallback = ''}) {
    final parts = values
        .where((value) => value.trim().isNotEmpty)
        .take(3)
        .toList(growable: false);
    if (parts.isEmpty) {
      return fallback;
    }
    return parts.join(' · ');
  }

  String _shortDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final tIndex = trimmed.indexOf('T');
    return tIndex > 0 ? trimmed.substring(0, tIndex) : trimmed;
  }
}

class _MrpReadonlyDetail extends StatelessWidget {
  const _MrpReadonlyDetail({required this.module, required this.record});

  final MrpReadonlyModule module;
  final JsonModel? record;

  @override
  Widget build(BuildContext context) {
    if (record == null) {
      return const SettingsEmptyState(
        icon: Icons.analytics_outlined,
        title: 'No record selected',
        message: 'Choose a record from the list to view planning details.',
        minHeight: 240,
      );
    }

    final data = record?.toJson() ?? const <String, dynamic>{};
    final item = data['item'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(data['item'] as Map<String, dynamic>)
        : const <String, dynamic>{};
    final warehouse = data['warehouse'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(data['warehouse'] as Map<String, dynamic>)
        : const <String, dynamic>{};
    final run = data['run'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(data['run'] as Map<String, dynamic>)
        : const <String, dynamic>{};

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title(data, item),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppUiConstants.spacingXs),
          Text(
            _subtitle(data, warehouse, run),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).extension<AppThemeExtension>()!.mutedText,
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          MrpDetailSection(
            title: 'Overview',
            fields: <MrpDetailFieldData>[
              MrpDetailFieldData(
                labelText: 'MRP Run',
                value: stringValue(run, 'run_no'),
              ),
              MrpDetailFieldData(
                labelText: 'Status',
                value: stringValue(run, 'run_status'),
              ),
              MrpDetailFieldData(
                labelText: 'Item',
                value: [
                  stringValue(item, 'item_code'),
                  stringValue(item, 'item_name'),
                ].where((value) => value.trim().isNotEmpty).join(' · '),
                large: true,
              ),
              MrpDetailFieldData(
                labelText: 'Warehouse',
                value: stringValue(warehouse, 'name'),
              ),
              MrpDetailFieldData(
                labelText: 'Document Type',
                value: stringValue(data, 'source_document_type'),
              ),
              MrpDetailFieldData(
                labelText: 'Document No',
                value: _documentValue(data),
              ),
              MrpDetailFieldData(
                labelText: 'Line Reference',
                value: stringValue(data, 'source_line_id'),
              ),
              MrpDetailFieldData(
                labelText: 'Remarks',
                value: stringValue(data, 'remarks'),
                large: true,
              ),
            ],
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          MrpDetailSection(title: _sectionTitle(), fields: _moduleFields(data)),
        ],
      ),
    );
  }

  String _title(Map<String, dynamic> data, Map<String, dynamic> item) {
    final itemCode = stringValue(item, 'item_code');
    final itemName = stringValue(item, 'item_name');
    if (itemCode.isEmpty && itemName.isEmpty) {
      return 'Record #${intValue(data, 'id') ?? '-'}';
    }
    if (itemCode.isEmpty) {
      return itemName;
    }
    if (itemName.isEmpty) {
      return itemCode;
    }
    return '$itemCode · $itemName';
  }

  String _subtitle(
    Map<String, dynamic> data,
    Map<String, dynamic> warehouse,
    Map<String, dynamic> run,
  ) {
    final parts = <String>[
      stringValue(run, 'run_no'),
      stringValue(warehouse, 'name'),
      stringValue(data, 'demand_source'),
      stringValue(data, 'supply_source'),
      stringValue(data, 'recommended_action'),
    ].where((value) => value.trim().isNotEmpty).toList(growable: false);
    return parts.isEmpty ? 'Planning detail' : parts.join(' · ');
  }

  String _documentValue(Map<String, dynamic> data) {
    final id = intValue(data, 'source_document_id');
    return id == null ? '' : id.toString();
  }

  String _sectionTitle() {
    switch (module) {
      case MrpReadonlyModule.demand:
        return 'Demand Summary';
      case MrpReadonlyModule.supply:
        return 'Supply Summary';
      case MrpReadonlyModule.netRequirement:
        return 'Requirement Summary';
    }
  }

  List<MrpDetailFieldData> _moduleFields(Map<String, dynamic> data) {
    switch (module) {
      case MrpReadonlyModule.demand:
        return <MrpDetailFieldData>[
          MrpDetailFieldData(
            labelText: 'Demand Source',
            value: stringValue(data, 'demand_source'),
          ),
          MrpDetailFieldData(
            labelText: 'Demand Qty',
            value: stringValue(data, 'demand_qty', '0'),
          ),
          MrpDetailFieldData(
            labelText: 'Pending Qty',
            value: stringValue(data, 'pending_qty', '0'),
          ),
          MrpDetailFieldData(
            labelText: 'Priority',
            value: stringValue(data, 'priority_level'),
          ),
          MrpDetailFieldData(
            labelText: 'Demand Date',
            value: stringValue(data, 'demand_date'),
          ),
          MrpDetailFieldData(
            labelText: 'Required Date',
            value: stringValue(data, 'required_date'),
          ),
        ];
      case MrpReadonlyModule.supply:
        return <MrpDetailFieldData>[
          MrpDetailFieldData(
            labelText: 'Supply Source',
            value: stringValue(data, 'supply_source'),
          ),
          MrpDetailFieldData(
            labelText: 'Supply Qty',
            value: stringValue(data, 'supply_qty', '0'),
          ),
          MrpDetailFieldData(
            labelText: 'Available Qty',
            value: stringValue(data, 'available_qty', '0'),
          ),
          MrpDetailFieldData(
            labelText: 'Allocated Qty',
            value: stringValue(data, 'allocated_qty', '0'),
          ),
          MrpDetailFieldData(
            labelText: 'Available Date',
            value: stringValue(data, 'available_date'),
          ),
        ];
      case MrpReadonlyModule.netRequirement:
        return <MrpDetailFieldData>[
          MrpDetailFieldData(
            labelText: 'Gross Demand',
            value: stringValue(data, 'gross_demand_qty', '0'),
          ),
          MrpDetailFieldData(
            labelText: 'Available Supply',
            value: stringValue(data, 'available_supply_qty', '0'),
          ),
          MrpDetailFieldData(
            labelText: 'Shortage Qty',
            value: stringValue(data, 'shortage_qty', '0'),
          ),
          MrpDetailFieldData(
            labelText: 'Net Required Qty',
            value: stringValue(data, 'net_required_qty', '0'),
          ),
          MrpDetailFieldData(
            labelText: 'Excess Qty',
            value: stringValue(data, 'excess_qty', '0'),
          ),
          MrpDetailFieldData(
            labelText: 'Safety Stock Qty',
            value: stringValue(data, 'safety_stock_qty', '0'),
          ),
          MrpDetailFieldData(
            labelText: 'Recommended Action',
            value: stringValue(data, 'recommended_action'),
          ),
          MrpDetailFieldData(
            labelText: 'Recommended Qty',
            value: stringValue(data, 'recommended_qty', '0'),
          ),
          MrpDetailFieldData(
            labelText: 'Recommended Date',
            value: stringValue(data, 'recommended_date'),
          ),
          MrpDetailFieldData(
            labelText: 'Planning Method',
            value: stringValue(data, 'planning_method'),
          ),
          MrpDetailFieldData(
            labelText: 'Procurement Type',
            value: stringValue(data, 'procurement_type'),
          ),
          MrpDetailFieldData(
            labelText: 'Lead Time (days)',
            value: stringValue(data, 'lead_time_days'),
          ),
          MrpDetailFieldData(
            labelText: 'Reorder Triggered',
            value: boolValue(data, 'reorder_triggered') ? 'Yes' : 'No',
          ),
        ];
    }
  }
}
