import 'dart:convert';

import '../../screen.dart';
import '../../view_model/planning/mrp_readonly_view_model.dart';

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
  late final MrpReadonlyViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MrpReadonlyViewModel(widget.module)
      ..load(selectId: widget.initialId);
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
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
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
      list: SettingsListCard<JsonModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search ${widget.title.toLowerCase()}',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No records found.',
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'id', 'Record'),
            subtitle: [
              stringValue(data, 'demand_source'),
              stringValue(data, 'supply_source'),
              stringValue(data, 'recommended_action'),
            ].where((x) => x.trim().isNotEmpty).join(' · '),
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
      editor: _viewModel.detailLoading
          ? const AppLoadingView(message: 'Loading record...')
          : SingleChildScrollView(
              child: Text(
                const JsonEncoder.withIndent('  ').convert(
                  _viewModel.selected?.toJson() ?? const <String, dynamic>{},
                ),
              ),
            ),
    );
  }
}
