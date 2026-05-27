import '../../controller/assets/asset_disposal_management_controller.dart';
import '../../screen.dart';

class AssetDisposalPage extends StatefulWidget {
  const AssetDisposalPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<AssetDisposalPage> createState() => _AssetDisposalPageState();
}

class _AssetDisposalPageState extends State<AssetDisposalPage> {
  late final String _controllerTag;
  late final AssetDisposalManagementController _controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'AssetDisposalManagementController-${widget.initialId ?? 'new'}',
    );
    _controller = Get.put(
      AssetDisposalManagementController(initialId: widget.initialId),
      tag: _controllerTag,
      permanent: true,
    );
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
    return GetBuilder<AssetDisposalManagementController>(
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
            label: 'New disposal',
          ),
        ];

        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Asset disposals',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    AssetDisposalManagementController controller,
  ) {
    if (controller.loading) {
      return const AppLoadingView(message: 'Loading disposals...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load disposals',
        message: controller.pageError!,
        onRetry: () => controller.load(selectId: widget.initialId),
      );
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Asset disposals',
      editorTitle: controller.selected == null
          ? 'New asset disposal'
          : controller.listTitle(controller.selected!),
      editorOnly: widget.editorOnly,
      scrollController: controller.pageScrollController,
      list: SettingsListCard<AssetDisposalModel>(
        searchController: controller.searchController,
        searchHint: 'Search no., asset, party, status',
        items: controller.filteredRows,
        selectedItem: controller.selected,
        emptyMessage: 'No disposals found.',
        itemBuilder: (item, selected) {
          return SettingsListTile(
            title: controller.listTitle(item),
            subtitle: controller.listSubtitle(item),
            selected: selected,
            onTap: () async {
              final isDesktop = Responsive.isDesktop(context);
              await controller.select(item);
              if (!context.mounted) {
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
          ? const AppLoadingView(message: 'Loading disposal...')
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (controller.formError != null) ...[
                    AppErrorStateView.inline(message: controller.formError!),
                    const SizedBox(height: AppUiConstants.spacingSm),
                  ],
                  Text(
                    controller.selected == null
                        ? 'New asset disposal'
                        : 'Edit disposal',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppUiConstants.spacingMd),
                  if (controller.saving || controller.actionBusy)
                    const LinearProgressIndicator(),
                  if (controller.companyBanner != null &&
                      controller.selected == null) ...[
                    Text(
                      'Session company: ${controller.companyBanner}. ${controller.scopeHint}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppUiConstants.spacingMd),
                  ],
                  SettingsFormWrap(
                    children: [
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Asset',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: controller.assetId,
                        items: controller.assetsList
                            .where(
                              (asset) => intValue(asset.toJson(), 'id') != null,
                            )
                            .map(
                              (asset) => DropdownMenuItem<int>(
                                value: intValue(asset.toJson(), 'id'),
                                child: Text(controller.listAssetOption(asset)),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: controller.saving || controller.actionBusy
                            ? null
                            : controller.setAssetId,
                      ),
                      DocumentSeriesSelector<int>(
                        labelText: 'Document series',
                        mappedItems: controller.seriesOptions
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppDropdownItem<int>(
                                value: item.id!,
                                label: item.toString(),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: controller.documentSeriesId,
                        onChanged: controller.saving || controller.actionBusy
                            ? (_) {}
                            : controller.setDocumentSeriesId,
                      ),
                      AppFormTextField(
                        labelText: 'Disposal no.',
                        controller: controller.disposalNoController,
                      ),
                      AppFormTextField(
                        labelText: 'Disposal date',
                        controller: controller.disposalDateController,
                        hintText: 'YYYY-MM-DD',
                      ),
                      AppFormTextField(
                        labelText: 'Disposal type',
                        controller: controller.disposalTypeController,
                        hintText: 'sale, scrap, write_off',
                      ),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Sale party',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: controller.salePartyId,
                        items: controller.parties
                            .where((party) => party.id != null)
                            .map(
                              (party) => DropdownMenuItem<int>(
                                value: party.id,
                                child: Text(party.toString()),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: controller.saving || controller.actionBusy
                            ? null
                            : controller.setSalePartyId,
                      ),
                      AppFormTextField(
                        labelText: 'Disposal value',
                        controller: controller.disposalValueController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      AppFormTextField(
                        labelText: 'Disposal expense',
                        controller: controller.expenseController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      AppFormTextField(
                        labelText: 'Book value at disposal',
                        controller: controller.bookValueController,
                        readOnly: true,
                      ),
                      AppFormTextField(
                        labelText: 'Gain / loss',
                        controller: controller.gainLossController,
                        readOnly: true,
                      ),
                      AppFormTextField(
                        labelText: 'Remarks',
                        controller: controller.remarksController,
                        maxLines: 3,
                      ),
                    ],
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
                        onPressed: controller.actionBusy
                            ? null
                            : () async {
                                final id = await controller.save();
                                if (!context.mounted) {
                                  return;
                                }
                                if (id != null) {
                                  _snack();
                                }
                              },
                      ),
                      if (controller.selected != null)
                        AppActionButton(
                          icon: Icons.check_circle_outline,
                          label: 'Approve',
                          filled: false,
                          onPressed: controller.saving || controller.actionBusy
                              ? null
                              : () async {
                                  await controller.approve();
                                  if (!context.mounted) {
                                    return;
                                  }
                                  _snack();
                                },
                        ),
                      if (controller.selected != null)
                        AppActionButton(
                          icon: Icons.publish_outlined,
                          label: 'Post',
                          filled: false,
                          onPressed: controller.saving || controller.actionBusy
                              ? null
                              : () async {
                                  await controller.post();
                                  if (!context.mounted) {
                                    return;
                                  }
                                  _snack();
                                },
                        ),
                      if (controller.selected != null)
                        AppActionButton(
                          icon: Icons.cancel_outlined,
                          label: 'Cancel',
                          filled: false,
                          onPressed: controller.saving || controller.actionBusy
                              ? null
                              : () async {
                                  await controller.cancel();
                                  if (!context.mounted) {
                                    return;
                                  }
                                  _snack();
                                },
                        ),
                      if (controller.selected != null)
                        AppActionButton(
                          icon: Icons.delete_outline,
                          label: 'Delete',
                          filled: false,
                          onPressed: controller.saving || controller.actionBusy
                              ? null
                              : () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete disposal'),
                                      content: const Text(
                                        'Only draft disposals can be deleted.',
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
