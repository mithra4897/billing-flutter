import '../../controller/project/project_vendor_work_management_controller.dart';
import '../../screen.dart';

class ProjectVendorWorkManagementPage extends StatefulWidget {
  const ProjectVendorWorkManagementPage({
    super.key,
    this.embedded = false,
    this.constrainedProjectId,
    this.controllerScope = const <String, Object?>{},
    this.useShellActions = true,
  });

  final bool embedded;
  final int? constrainedProjectId;
  final Map<String, Object?> controllerScope;
  final bool useShellActions;

  @override
  State<ProjectVendorWorkManagementPage> createState() =>
      _ProjectVendorWorkManagementPageState();
}

class _ProjectVendorWorkManagementPageState
    extends State<ProjectVendorWorkManagementPage> {
  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'open', label: 'Open'),
        AppDropdownItem(value: 'ordered', label: 'Ordered'),
        AppDropdownItem(value: 'in_progress', label: 'In Progress'),
        AppDropdownItem(value: 'completed', label: 'Completed'),
      ];

  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'ProjectVendorWorkManagementController',
      scope: widget.controllerScope,
    );
    if (!Get.isRegistered<ProjectVendorWorkManagementController>(
      tag: _controllerTag,
    )) {
      Get.put(
        ProjectVendorWorkManagementController(
          constrainedProjectId: widget.constrainedProjectId,
        ),
        tag: _controllerTag,
      );
    }
  }

  @override
  void didUpdateWidget(covariant ProjectVendorWorkManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.constrainedProjectId != widget.constrainedProjectId) {
      unawaited(_controller.applyProjectConstraint(widget.constrainedProjectId));
    }
  }

  ProjectVendorWorkManagementController get _controller =>
      Get.find<ProjectVendorWorkManagementController>(tag: _controllerTag);

  Future<void> _openFilterPanel(
    BuildContext context,
    ProjectVendorWorkManagementController controller,
  ) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 600 ? 12.0 : 24.0;
    final dialogPadding = screenWidth < 600 ? 16.0 : AppUiConstants.cardPadding;

    final applied = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final appTheme = Theme.of(
          dialogContext,
        ).extension<AppThemeExtension>()!;

        return GetBuilder<ProjectVendorWorkManagementController>(
          tag: _controllerTag,
          builder: (dialogController) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    dialogPadding,
                    dialogPadding,
                    dialogPadding,
                    MediaQuery.of(dialogContext).viewInsets.bottom +
                        dialogPadding,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Filter Vendor Work',
                              style: Theme.of(dialogContext)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            tooltip: 'Close',
                            icon: const Icon(Icons.close),
                            color: appTheme.mutedText,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _filterBox(
                            child: TextField(
                              controller: dialogController.searchController,
                              decoration: const InputDecoration(
                                labelText: 'Search',
                              ),
                            ),
                          ),
                          _filterBox(
                            child: AppDropdownField<int>.fromMapped(
                              initialValue: dialogController.filterProjectId,
                              labelText: 'Project',
                              mappedItems: dialogController.filterProjectItems,
                              onChanged: dialogController.setFilterProjectId,
                            ),
                          ),
                          _filterBox(
                            child: AppDropdownField<int>.fromMapped(
                              initialValue: dialogController.filterTaskId,
                              labelText: 'Task',
                              mappedItems: dialogController.filterTaskItems,
                              onChanged: dialogController.setFilterTaskId,
                            ),
                          ),
                          _filterBox(
                            child: AppDropdownField<int>.fromMapped(
                              initialValue:
                                  dialogController.filterVendorPartyId,
                              labelText: 'Vendor',
                              mappedItems: dialogController.partyItems,
                              onChanged:
                                  dialogController.setFilterVendorPartyId,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            icon: const Icon(Icons.search),
                            label: const Text('Apply Filters'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              dialogController.clearFilters();
                              Navigator.of(dialogContext).pop(true);
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (applied == true) {
      controller.applyFilters();
    }
  }

  Widget _filterBox({required Widget child}) {
    return SizedBox(width: 220, child: child);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProjectVendorWorkManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          if (!controller.isProjectConstrained)
            AdaptiveShellActionButton(
              onPressed: () => _openFilterPanel(context, controller),
              icon: Icons.filter_alt_outlined,
              label: 'Filter',
              filled: false,
            ),
          AdaptiveShellActionButton(
            onPressed: () => controller.startNewVendorWork(
              isDesktop: Responsive.isDesktop(context),
            ),
            icon: Icons.handyman_outlined,
            label: 'New Vendor Work',
          ),
        ];

        final content = _buildContent(context, controller);
        if (widget.embedded && widget.useShellActions) {
          return ShellPageActions(actions: actions, child: content);
        }
        if (widget.embedded) {
          return content;
        }
        return AppStandaloneShell(
          title: 'Project Vendor Works',
          actions: actions,
          scrollController: controller.pageScrollController,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProjectVendorWorkManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading project vendor works...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load project vendor works',
        message: controller.pageError!,
        onRetry: controller.loadData,
      );
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Project Vendor Works',
      editorTitle: controller.partyName(
        controller.selectedRow?.work.vendorPartyId,
      ),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<ProjectVendorWorkRow>(
        items: controller.filteredRows,
        selectedItem: controller.selectedRow,
        emptyMessage: 'No vendor works found.',
        itemBuilder: (row, selected) => SettingsListTile(
          title: controller.partyName(row.work.vendorPartyId).isNotEmpty
              ? controller.partyName(row.work.vendorPartyId)
              : 'Vendor Work',
          subtitle: [
            row.project.projectName ?? '',
            row.work.workStatus ?? '',
            controller.decimalText(row.work.amount),
          ].where((item) => item.isNotEmpty).join(' • '),
          selected: selected,
          onTap: () => controller.selectRow(row),
        ),
      ),
      editorBuilder: (_) => Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsFormWrap(
              children: [
                if (!controller.isProjectConstrained)
                  AppDropdownField<int>.fromMapped(
                    initialValue: controller.projectId,
                    labelText: 'Project',
                    mappedItems: controller.projectItems,
                    onChanged: controller.setProjectId,
                    validator: Validators.requiredSelection('Project'),
                  ),
                AppDropdownField<int>.fromMapped(
                  initialValue: controller.taskId,
                  labelText: 'Task',
                  mappedItems: controller.taskItems,
                  onChanged: controller.setTaskId,
                ),
                AppDropdownField<int>.fromMapped(
                  initialValue: controller.vendorPartyId,
                  labelText: 'Vendor',
                  mappedItems: controller.partyItems,
                  onChanged: controller.setVendorPartyId,
                  validator: Validators.requiredSelection('Vendor'),
                ),
                AppDropdownField<int>.fromMapped(
                  initialValue: controller.purchaseOrderId,
                  labelText: 'Purchase Order',
                  mappedItems: controller.purchaseOrderItems,
                  onChanged: controller.setPurchaseOrderId,
                ),
                AppDropdownField<int>.fromMapped(
                  initialValue: controller.purchaseInvoiceId,
                  labelText: 'Purchase Invoice',
                  mappedItems: controller.purchaseInvoiceItems,
                  onChanged: controller.setPurchaseInvoiceId,
                ),
                AppDropdownField<String>.fromMapped(
                  initialValue: controller.status,
                  labelText: 'Work Status',
                  mappedItems: _statusItems,
                  onChanged: (value) =>
                      controller.setStatus(value ?? controller.status),
                ),
                AppFormTextField(
                  controller: controller.amountController,
                  labelText: 'Amount',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.compose([
                    Validators.required('Amount'),
                    Validators.optionalNonNegativeNumber('Amount'),
                  ]),
                ),
                AppFormTextField(
                  controller: controller.voucherIdController,
                  labelText: 'Voucher ID',
                  keyboardType: TextInputType.number,
                ),
                AppFormTextField(
                  controller: controller.descriptionController,
                  labelText: 'Work Description',
                  maxLines: 3,
                  validator: Validators.compose([
                    Validators.required('Work Description'),
                    Validators.optionalMaxLength(500, 'Work Description'),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppFormTextField(
              controller: controller.remarksController,
              labelText: 'Remarks',
              maxLines: 3,
              validator: Validators.optionalMaxLength(500, 'Remarks'),
            ),
            if ((controller.formError ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                controller.formError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AppActionButton(
                  onPressed: controller.saving
                      ? null
                      : () async {
                          final message = await controller.saveVendorWork();
                          if (!mounted || message == null) {
                            return;
                          }
                          appScaffoldMessengerKey.currentState
                            ?..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(content: Text(message)));
                        },
                  icon: controller.selectedRow?.work.id == null
                      ? Icons.add
                      : Icons.save_outlined,
                  label: controller.saving ? 'Saving...' : 'Save Vendor Work',
                  busy: controller.saving,
                ),
                AppActionButton(
                  onPressed: controller.saving
                      ? null
                      : () => controller.startNewVendorWork(
                          isDesktop: Responsive.isDesktop(context),
                        ),
                  icon: Icons.refresh,
                  label: 'New',
                  filled: false,
                ),
                if (controller.selectedRow?.work.id != null)
                  AppActionButton(
                    onPressed: controller.saving
                        ? null
                        : () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Vendor Work'),
                                content: const Text(
                                  'Remove this vendor work entry?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton.tonal(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true) {
                              return;
                            }
                            final message = await controller.deleteVendorWork();
                            if (!mounted || message == null) {
                              return;
                            }
                            appScaffoldMessengerKey.currentState
                              ?..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(content: Text(message)));
                          },
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    filled: false,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
