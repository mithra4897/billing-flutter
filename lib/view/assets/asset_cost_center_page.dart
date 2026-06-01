import '../../controller/assets/asset_cost_center_management_controller.dart';
import '../../screen.dart';

class AssetCostCenterPage extends StatefulWidget {
  const AssetCostCenterPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<AssetCostCenterPage> createState() => _AssetCostCenterPageState();
}

class _AssetCostCenterPageState extends State<AssetCostCenterPage> {
  late final String _controllerTag;
  late final AssetCostCenterManagementController _controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'AssetCostCenterManagementController-${widget.initialId ?? 'new'}',
    );
    _controller = Get.put(
      AssetCostCenterManagementController(initialId: widget.initialId),
      tag: _controllerTag,
      permanent: true,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _snack() {
    final msg = _controller.consumeActionMessage();
    if (!mounted || msg == null || msg.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AssetCostCenterManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: controller.loading
                ? null
                : () => controller.startNew(
                    isDesktop: Responsive.isDesktop(context),
                  ),
            icon: Icons.add_outlined,
            label: 'New cost center',
          ),
        ];

        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Cost centers',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    AssetCostCenterManagementController controller,
  ) {
    if (controller.loading) {
      return const AppLoadingView(message: 'Loading cost centers...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load cost centers',
        message: controller.pageError!,
        onRetry: () => controller.load(selectId: widget.initialId),
      );
    }

    final editorTitle = controller.selected == null
        ? 'New cost center'
        : controller.listTitle(controller.selected!);

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Cost centers',
      editorTitle: editorTitle,
      editorOnly: widget.editorOnly,
      scrollController: controller.pageScrollController,
      list: SettingsListCard<CostCenterModel>(
        searchController: controller.searchController,
        searchHint: 'Search code, name, type, parent',
        items: controller.filteredRows,
        selectedItem: controller.selected,
        emptyMessage: 'No cost centers found.',
        itemBuilder: (item, selected) {
          return SettingsListTile(
            title: controller.listTitle(item),
            subtitle: controller.listSubtitle(item),
            selected: selected,
            onTap: () async {
              final isDesktop = Responsive.isDesktop(context);
              await controller.select(item);
              if (!mounted) {
                return;
              }
              if (!isDesktop) {
                controller.workspaceController.openEditor();
              }
            },
          );
        },
      ),
      editor: controller.detailLoading
          ? const AppLoadingView(message: 'Loading cost center...')
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (controller.formError != null) ...[
                    AppErrorStateView.inline(message: controller.formError!),
                    const SizedBox(height: AppUiConstants.spacingSm),
                  ],
                  if (controller.saving) const LinearProgressIndicator(),
                  SettingsFormWrap(
                    children: [
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Company',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: controller.companyId,
                        items: controller.companies
                            .where((company) => company.id != null)
                            .map(
                              (company) => DropdownMenuItem<int>(
                                value: company.id,
                                child: Text(company.toString()),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: controller.saving
                            ? null
                            : controller.setCompanyId,
                      ),
                      AppFormTextField(
                        labelText: 'Cost center code',
                        controller: controller.codeController,
                      ),
                      AppFormTextField(
                        labelText: 'Cost center name',
                        controller: controller.nameController,
                      ),
                      DropdownButtonFormField<int?>(
                        decoration: const InputDecoration(
                          labelText: 'Parent cost center',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: controller.parentId,
                        items: <DropdownMenuItem<int?>>[
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('None'),
                          ),
                          ...controller.parentOptions.map(
                            (row) => DropdownMenuItem<int?>(
                              value: row.id,
                              child: Text(controller.listTitle(row)),
                            ),
                          ),
                        ],
                        onChanged: controller.saving
                            ? null
                            : controller.setParentId,
                      ),
                      AppFormTextField(
                        labelText: 'Cost center type',
                        controller: controller.typeController,
                      ),
                    ],
                  ),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: controller.isActive,
                    onChanged: controller.saving
                        ? null
                        : controller.setIsActive,
                  ),
                  const SizedBox(height: AppUiConstants.spacingMd),
                  Wrap(
                    spacing: AppUiConstants.spacingSm,
                    runSpacing: AppUiConstants.spacingSm,
                    children: [
                      AppActionButton(
                        icon: Icons.save_outlined,
                        label: controller.selected == null ? 'Save' : 'Update',
                        busy: controller.saving,
                        onPressed: () async {
                          final id = await controller.save();
                          if (!context.mounted) {
                            return;
                          }
                          if (id != null) {
                            _snack();
                            if (controller.selected == null) {
                              return;
                            }
                            final detailId = controller.detail?.id;
                            if (detailId != null &&
                                ModalRoute.of(context)?.settings.name !=
                                    '/assets/cost-centers/$detailId') {
                              openAssetShellRoute(
                                context,
                                '/assets/cost-centers/$detailId',
                              );
                            }
                          }
                        },
                      ),
                      if (controller.selected != null)
                        AppActionButton(
                          icon: Icons.delete_outline,
                          label: 'Delete',
                          filled: false,
                          onPressed: controller.saving
                              ? null
                              : () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete cost center'),
                                      content: const Text(
                                        'Only cost centers without children '
                                        'or linked assets can be deleted.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok != true || !context.mounted) {
                                    return;
                                  }
                                  final deleted = await controller
                                      .deleteCurrent();
                                  if (!context.mounted) {
                                    return;
                                  }
                                  if (deleted) {
                                    _snack();
                                    openAssetShellRoute(
                                      context,
                                      '/assets/cost-centers',
                                    );
                                  }
                                },
                        ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
