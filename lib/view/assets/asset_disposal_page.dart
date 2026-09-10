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
    if (!widget.editorOnly) {
      return AssetDisposalRegisterPage(embedded: widget.embedded);
    }
    return GetBuilder<AssetDisposalManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          if (!widget.editorOnly)
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

  static const List<ErpLinkFieldOption<String>> _disposalTypeOptions = [
    ErpLinkFieldOption(value: 'sale', label: 'Sale'),
    ErpLinkFieldOption(value: 'scrap', label: 'Scrap'),
    ErpLinkFieldOption(value: 'write_off', label: 'Write off'),
    ErpLinkFieldOption(value: 'retirement', label: 'Retirement'),
    ErpLinkFieldOption(value: 'loss', label: 'Loss'),
    ErpLinkFieldOption(value: 'theft', label: 'Theft'),
  ];

  static ErpLinkFieldOption<T>? _selectedOption<T>(
    T? value,
    List<ErpLinkFieldOption<T>> options,
  ) {
    if (value == null) {
      return null;
    }
    for (final option in options) {
      if (option.value == value) {
        return option;
      }
    }
    return null;
  }

  static ErpLinkFieldOption<String>? _selectedTextOption(
    String text,
    List<ErpLinkFieldOption<String>> options,
  ) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    for (final option in options) {
      if (option.value.toLowerCase() == trimmed.toLowerCase()) {
        return option;
      }
    }
    return ErpLinkFieldOption<String>(value: trimmed, label: trimmed);
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

    final assetOptions = controller.assetsList
        .where((asset) => intValue(asset.toJson(), 'id') != null)
        .map(
          (asset) => ErpLinkFieldOption<int>(
            value: intValue(asset.toJson(), 'id')!,
            label: controller.listAssetOption(asset),
          ),
        )
        .toList(growable: false);

    final partyOptions = controller.parties
        .where((party) => party.id != null)
        .map(
          (party) => ErpLinkFieldOption<int>(
            value: party.id!,
            label: party.toString(),
          ),
        )
        .toList(growable: false);

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
                      ErpLinkField<int>(
                        labelText: 'Asset',
                        doctypeLabel: 'Asset',
                        enabled:
                            !controller.saving && !controller.actionBusy,
                        isRequired: true,
                        initialSelection: _selectedOption(
                          controller.assetId,
                          assetOptions,
                        ),
                        options: assetOptions,
                        onChanged: controller.setAssetId,
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
                      GeneratedDocumentNumberField(
                        labelText: 'Disposal no.',
                        controller: controller.disposalNoController,
                        documentSeries: controller.seriesOptions,
                        documentSeriesId: controller.documentSeriesId,
                      ),
                      AppFormTextField(
                        labelText: 'Disposal date',
                        controller: controller.disposalDateController,
                        hintText: dateFormatHint(),
                        isRequired: true,
                        inputFormatters: const [DateInputFormatter()],
                      ),
                      ErpLinkField<String>(
                        labelText: 'Disposal type',
                        doctypeLabel: 'Disposal type',
                        enabled:
                            !controller.saving && !controller.actionBusy,
                        isRequired: true,
                        initialSelection: _selectedTextOption(
                          controller.disposalTypeController.text,
                          _disposalTypeOptions,
                        ),
                        options: _disposalTypeOptions,
                        onChanged: (val) =>
                            controller.disposalTypeController.text = val ?? '',
                        onClear: () =>
                            controller.disposalTypeController.clear(),
                      ),
                      ErpLinkField<int>(
                        labelText: 'Sale party',
                        doctypeLabel: 'Party',
                        enabled:
                            !controller.saving && !controller.actionBusy,
                        initialSelection: _selectedOption(
                          controller.salePartyId,
                          partyOptions,
                        ),
                        options: partyOptions,
                        onChanged: controller.setSalePartyId,
                        onClear: () => controller.setSalePartyId(null),
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
