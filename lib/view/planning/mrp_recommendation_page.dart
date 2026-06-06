import '../../screen.dart';
import 'mrp_detail_widgets.dart';

class MrpRecommendationPage extends StatefulWidget {
  const MrpRecommendationPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<MrpRecommendationPage> createState() => _MrpRecommendationPageState();
}

class _MrpRecommendationPageState extends State<MrpRecommendationPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final String _controllerTag;
  late final MrpRecommendationViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('MrpRecommendationViewModel');
    _viewModel = Get.put(
      MrpRecommendationViewModel()..load(selectId: widget.initialId),
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

  void _snack() {
    final msg = _viewModel.consumeActionMessage();
    if (!mounted || msg == null || msg.trim().isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MrpRecommendationViewModel>(
      tag: _controllerTag,
      builder: (_) {
        final content = _buildContent();
        if (widget.embedded) return content;
        return AppStandaloneShell(
          title: 'MRP Recommendations',
          scrollController: _pageScrollController,
          actions: const <Widget>[],
          child: content,
        );
      },
    );
  }

  Widget _buildContent() {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading MRP recommendations...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load MRP recommendations',
        message: _viewModel.pageError!,
        onRetry: _viewModel.load,
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'MRP Recommendations',
      editorTitle: 'MRP Recommendation',
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<MrpRecommendationModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search MRP recommendations',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No MRP recommendations found.',
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: [
              stringValue(data, 'recommendation_type', 'Recommendation'),
              'Qty ${stringValue(data, 'recommended_qty', '0')}',
            ].where((x) => x.trim().isNotEmpty).join(' · '),
            subtitle: [
              stringValue(data, 'recommendation_status'),
              _shortDate(stringValue(data, 'recommended_date')),
              stringValue(data, 'converted_document_type'),
            ].where((x) => x.trim().isNotEmpty).join(' · '),
            detail: [
              if (nullableStringValue(data, 'priority_level') != null)
                'Priority ${stringValue(data, 'priority_level')}',
              if (nullableStringValue(data, 'warehouse_id') != null)
                'Warehouse #${stringValue(data, 'warehouse_id')}',
            ].join(' · '),
            selected: selected,
            onTap: () async {
              final id = intValue(data, 'id');
              final isDesktop = Responsive.isDesktop(context);
              await _viewModel.select(item);
              if (!mounted || id == null) return;
              if (widget.editorOnly || !isDesktop) {
                _openRoute('/planning/mrp-recommendations/$id');
              }
              if (!isDesktop) _workspaceController.openEditor();
            },
          );
        },
      ),
      editor: _viewModel.detailLoading
          ? const AppLoadingView(message: 'Loading recommendation...')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_viewModel.formError != null) ...[
                  AppErrorStateView.inline(message: _viewModel.formError!),
                  const SizedBox(height: AppUiConstants.spacingSm),
                ],
                Wrap(
                  spacing: AppUiConstants.spacingSm,
                  runSpacing: AppUiConstants.spacingSm,
                  children: [
                    if (_viewModel.selected != null &&
                        _viewModel.status == 'open')
                      AppActionButton(
                        icon: Icons.check_outlined,
                        label: 'Approve',
                        onPressed: () async {
                          await _viewModel.approve();
                          _snack();
                        },
                      ),
                    if (_viewModel.selected != null &&
                        (_viewModel.status == 'open' ||
                            _viewModel.status == 'approved'))
                      AppActionButton(
                        icon: Icons.close_outlined,
                        label: 'Reject',
                        filled: false,
                        onPressed: () async {
                          await _viewModel.reject();
                          _snack();
                        },
                      ),
                    if (_viewModel.selected != null &&
                        (_viewModel.status == 'open' ||
                            _viewModel.status == 'approved'))
                      AppActionButton(
                        icon: Icons.transform_outlined,
                        label: 'Convert',
                        filled: false,
                        onPressed: () async {
                          await _viewModel.convert();
                          _snack();
                        },
                      ),
                    if (_viewModel.selected != null &&
                        _viewModel.status != 'converted')
                      AppActionButton(
                        icon: Icons.cancel_outlined,
                        label: 'Cancel',
                        filled: false,
                        onPressed: () async {
                          await _viewModel.cancel();
                          _snack();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppUiConstants.spacingMd),
                _MrpRecommendationDetail(record: _viewModel.selected),
              ],
            ),
    );
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

class _MrpRecommendationDetail extends StatelessWidget {
  const _MrpRecommendationDetail({required this.record});

  final MrpRecommendationModel? record;

  @override
  Widget build(BuildContext context) {
    if (record == null) {
      return const SettingsEmptyState(
        icon: Icons.recommend_outlined,
        title: 'No recommendation selected',
        message: 'Choose a recommendation from the list to view details.',
        minHeight: 240,
      );
    }

    final data = record!.toJson();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_title(data), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppUiConstants.spacingXs),
          Text(
            _subtitle(data),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).extension<AppThemeExtension>()!.mutedText,
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          MrpDetailSection(
            title: 'Overview',
            hideEmptyFields: false,
            fields: <MrpDetailFieldData>[
              MrpDetailFieldData(
                labelText: 'Recommendation Type',
                value: stringValue(data, 'recommendation_type', '-'),
              ),
              MrpDetailFieldData(
                labelText: 'Status',
                value: stringValue(data, 'recommendation_status', '-'),
              ),
              MrpDetailFieldData(
                labelText: 'Recommended Qty',
                value: stringValue(data, 'recommended_qty', '0'),
              ),
              MrpDetailFieldData(
                labelText: 'Recommended Date',
                value: stringValue(data, 'recommended_date', '-'),
              ),
              MrpDetailFieldData(
                labelText: 'Priority',
                value: stringValue(data, 'priority_level', '-'),
              ),
              MrpDetailFieldData(
                labelText: 'MRP Run',
                value: stringValue(data, 'mrp_run_id', '-'),
              ),
            ],
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          MrpDetailSection(
            title: 'Source',
            hideEmptyFields: false,
            fields: <MrpDetailFieldData>[
              MrpDetailFieldData(
                labelText: 'Net Requirement',
                value: stringValue(data, 'mrp_net_requirement_id', '-'),
              ),
              MrpDetailFieldData(
                labelText: 'Item',
                value: stringValue(data, 'item_id', '-'),
              ),
              MrpDetailFieldData(
                labelText: 'Warehouse',
                value: stringValue(data, 'warehouse_id', '-'),
              ),
              MrpDetailFieldData(
                labelText: 'Source Warehouse',
                value: stringValue(data, 'source_warehouse_id', '-'),
              ),
              MrpDetailFieldData(
                labelText: 'Supplier',
                value: stringValue(data, 'supplier_party_id', '-'),
              ),
              MrpDetailFieldData(
                labelText: 'BOM',
                value: stringValue(data, 'bom_id', '-'),
              ),
            ],
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          MrpDetailSection(
            title: 'Approval & Conversion',
            hideEmptyFields: false,
            fields: <MrpDetailFieldData>[
              MrpDetailFieldData(
                labelText: 'Approved By',
                value: stringValue(data, 'approved_by', '-'),
              ),
              MrpDetailFieldData(
                labelText: 'Approved At',
                value: stringValue(data, 'approved_at', '-'),
              ),
              MrpDetailFieldData(
                labelText: 'Converted Document Type',
                value: stringValue(data, 'converted_document_type', '-'),
              ),
              MrpDetailFieldData(
                labelText: 'Converted Document No',
                value: stringValue(data, 'converted_document_id', '-'),
              ),
              MrpDetailFieldData(
                labelText: 'Created At',
                value: stringValue(data, 'created_at', '-'),
              ),
              MrpDetailFieldData(
                labelText: 'Updated At',
                value: stringValue(data, 'updated_at', '-'),
              ),
              MrpDetailFieldData(
                labelText: 'Notes',
                value: stringValue(data, 'notes', '-'),
                large: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _title(Map<String, dynamic> data) {
    return [
      stringValue(data, 'recommendation_type', 'Recommendation'),
      'Qty ${stringValue(data, 'recommended_qty', '0')}',
    ].where((value) => value.trim().isNotEmpty).join(' · ');
  }

  String _subtitle(Map<String, dynamic> data) {
    final parts = <String>[
      stringValue(data, 'recommendation_status'),
      stringValue(data, 'recommended_date'),
      stringValue(data, 'converted_document_type'),
    ].where((value) => value.trim().isNotEmpty).toList(growable: false);
    return parts.isEmpty ? 'Recommendation detail' : parts.join(' · ');
  }
}
