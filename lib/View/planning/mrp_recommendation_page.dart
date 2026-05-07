import '../../screen.dart';
import '../../view_model/planning/mrp_recommendation_view_model.dart';

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
  late final MrpRecommendationViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MrpRecommendationViewModel()..load(selectId: widget.initialId);
  }

  @override
  void dispose() {
    _viewModel.dispose();
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
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
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
            title: stringValue(data, 'recommendation_type', 'Recommendation'),
            subtitle: [
              stringValue(data, 'recommendation_status'),
              stringValue(data, 'recommended_qty'),
            ].where((x) => x.trim().isNotEmpty).join(' · '),
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
                SingleChildScrollView(child: Text(_viewModel.detailText)),
              ],
            ),
    );
  }
}
