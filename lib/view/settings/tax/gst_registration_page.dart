import '../../../controller/settings/tax/gst_registration_management_controller.dart';
import '../../../screen.dart';

class GstRegistrationManagementPage extends StatefulWidget {
  const GstRegistrationManagementPage({
    super.key,
    this.embedded = false,
    this.fixedCompanyId,
    this.fixedBranchId,
  });

  final bool embedded;
  final int? fixedCompanyId;
  final int? fixedBranchId;

  @override
  State<GstRegistrationManagementPage> createState() =>
      _GstRegistrationManagementPageState();
}

class _GstRegistrationManagementPageState
    extends State<GstRegistrationManagementPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'GstRegistrationManagementController'
      '-${widget.embedded}-${widget.fixedCompanyId ?? 0}-${widget.fixedBranchId ?? 0}',
    );
    Get.put(
      GstRegistrationManagementController(
        embedded: widget.embedded,
        fixedCompanyId: widget.fixedCompanyId,
        fixedBranchId: widget.fixedBranchId,
      ),
      tag: _controllerTag,
    );
  }

  Future<void> _save(
    BuildContext formContext,
    GstRegistrationManagementController controller,
  ) async {
    if (!Form.of(formContext).validate()) {
      return;
    }
    final message = await controller.save();
    if (!mounted || message == null) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _delete(GstRegistrationManagementController controller) async {
    final message = await controller.delete();
    if (!mounted || message == null) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildListCard(GstRegistrationManagementController controller) {
    return SettingsListCard<GstRegistrationModel>(
      searchController: controller.searchController,
      searchHint: 'Search GST registrations',
      items: controller.filteredItems,
      selectedItem: controller.selectedItem,
      emptyMessage: 'No GST registrations found.',
      itemBuilder: (item, selected) => SettingsListTile(
        title: item.registrationName,
        subtitle: [
          item.gstin,
          companyNameById(controller.companies, item.companyId),
        ].where((part) => part.trim().isNotEmpty).join(' · '),
        selected: selected,
        trailing: SettingsStatusPill(
          label: item.isActive ? 'Active' : 'Inactive',
          active: item.isActive,
        ),
        onTap: () => controller.selectItem(item),
      ),
    );
  }

  Widget _buildEmbeddedContent(GstRegistrationManagementController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.filteredItems.isEmpty &&
              !controller.showDraftTile &&
              controller.selectedItem == null)
            const SettingsEmptyState(
              icon: Icons.assignment_ind_outlined,
              title: 'No GST Registrations',
              message: 'No GST registrations found.',
              minHeight: 160,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (controller.showDraftTile &&
                    controller.selectedItem == null) ...[
                  SettingsExpandableTile(
                    key: const ValueKey('gst-registration-draft'),
                    title: 'New GST Registration',
                    subtitle: 'Create a branch-associated GST registration.',
                    expanded: true,
                    highlighted: true,
                    leadingIcon: Icons.add_outlined,
                    onToggle: controller.hideDraftAndReset,
                    child: _buildInlineEditor(controller),
                  ),
                  if (controller.filteredItems.isNotEmpty)
                    const SizedBox(height: AppUiConstants.spacingSm),
                ],
                ...controller.filteredItems.map((item) {
                  final expanded = identical(item, controller.selectedItem);
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppUiConstants.spacingSm,
                    ),
                    child: SettingsExpandableTile(
                      key: ValueKey('gst-registration-${item.id}-$expanded'),
                      title: item.registrationName.isNotEmpty
                          ? item.registrationName
                          : (item.gstin.isNotEmpty ? item.gstin : '-'),
                      subtitle: [
                        item.gstin,
                        locationNameById(controller.locations, item.locationId),
                        item.registrationType.replaceAll('_', ' '),
                      ].where((value) => value.trim().isNotEmpty).join(' • '),
                      detail: [
                        if (item.isDefault) 'Default',
                        if (item.isActive) 'Active',
                      ].join(' • '),
                      expanded: expanded,
                      highlighted: expanded,
                      trailing: SettingsStatusPill(
                        label: item.isActive ? 'Active' : 'Inactive',
                        active: item.isActive,
                      ),
                      onToggle: () {
                        if (expanded) {
                          controller.resetForm();
                        } else {
                          controller.selectItem(item);
                        }
                      },
                      child: _buildInlineEditor(controller),
                    ),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<GstRegistrationManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () =>
                controller.startNew(isDesktop: Responsive.isDesktop(context)),
            icon: Icons.add_outlined,
            label: 'New GST Registration',
          ),
        ];
        if (controller.initialLoading) {
          return const AppLoadingView(message: 'Loading GST registrations...');
        }
        if (controller.pageError != null) {
          return AppErrorStateView(
            title: 'Unable to load GST registrations',
            message: controller.pageError!,
            onRetry: controller.loadData,
          );
        }

        if (widget.embedded) {
          return ShellPageActions(
            actions: actions,
            child: _buildEmbeddedContent(controller),
          );
        }

        return AppStandaloneShell(
          title: 'GST Registrations',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: SettingsWorkspace(
            controller: controller.workspaceController,
            title: 'GST Registrations',
            editorTitle: controller.selectedItem?.toString(),
            scrollController: controller.pageScrollController,
            list: _buildListCard(controller),
            editor: _buildInlineEditor(controller),
          ),
        );
      },
    );
  }

  Widget _buildInlineEditor(GstRegistrationManagementController controller) {
    final stateValue =
        controller.states.any((state) => state.id == controller.stateId)
        ? controller.stateId
        : null;

    return Form(
      child: Builder(
        builder: (formContext) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((controller.formError ?? '').isNotEmpty) ...[
                AppErrorStateView.inline(message: controller.formError!),
                const SizedBox(height: 16),
              ],
              SettingsFormWrap(
                children: [
                  if (widget.fixedCompanyId == null)
                    if (widget.fixedBranchId == null)
                      AppFormTextField(
                        controller: controller.nameController,
                        labelText: 'Registration Name',
                        validator: Validators.compose([
                          Validators.required('Registration Name'),
                          Validators.optionalMaxLength(
                            255,
                            'Registration Name',
                          ),
                        ]),
                      ),
                  AppDropdownField<int>.fromMapped(
                    initialValue: stateValue,
                    labelText: 'State',
                    mappedItems: controller.states
                        .where((state) => state.id != null)
                        .map(
                          (state) => AppDropdownItem<int>(
                            value: state.id!,
                            label: state.stateName,
                          ),
                        )
                        .toList(growable: false),
                    onChanged: controller.setStateId,
                    validator: (value) =>
                        Validators.requiredSelectionField(value, 'State'),
                  ),
                  AppDropdownField<String>.fromMapped(
                    initialValue: controller.registrationType,
                    labelText: 'Registration Type',
                    mappedItems:
                        GstRegistrationManagementController.registrationTypes,
                    onChanged: controller.setRegistrationType,
                    validator: (value) => Validators.requiredSelectionField(
                      value,
                      'Registration Type',
                    ),
                  ),
                  AppFormTextField(
                    controller: controller.gstinController,
                    labelText: 'GSTIN',
                    validator: Validators.optionalMaxLength(20, 'GSTIN'),
                  ),
                  AppFormTextField(
                    controller: controller.panController,
                    labelText: 'PAN No',
                    validator: Validators.optionalMaxLength(20, 'PAN No'),
                  ),
                  AppFormTextField(
                    controller: controller.legalNameController,
                    labelText: 'Legal Name',
                    validator: Validators.optionalMaxLength(255, 'Legal Name'),
                  ),
                  AppFormTextField(
                    controller: controller.tradeNameController,
                    labelText: 'Trade Name',
                    validator: Validators.optionalMaxLength(255, 'Trade Name'),
                  ),
                  AppFormTextField(
                    controller: controller.effectiveFromController,
                    labelText: 'Effective From',
                    validator: Validators.optionalDate('Effective From'),
                  ),
                  AppFormTextField(
                    controller: controller.effectiveToController,
                    labelText: 'Effective To',
                    validator: Validators.optionalDateOnOrAfter(
                      'Effective To',
                      () => controller.effectiveFromController.text,
                      startFieldName: 'Effective From',
                    ),
                  ),
                ],
              ),
              AppSwitchTile(
                label: 'Default Registration',
                value: controller.isDefault,
                onChanged: controller.setIsDefault,
              ),
              AppSwitchTile(
                label: 'Active',
                value: controller.isActive,
                onChanged: controller.setIsActive,
              ),
              AppFormTextField(
                controller: controller.remarksController,
                labelText: 'Remarks',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  AppActionButton(
                    icon: controller.selectedItem == null
                        ? Icons.add_outlined
                        : Icons.save_outlined,
                    label: controller.selectedItem == null
                        ? 'Create GST Registration'
                        : 'Update GST Registration',
                    onPressed: controller.saving
                        ? null
                        : () => _save(formContext, controller),
                    busy: controller.saving,
                  ),
                  if (controller.selectedItem?.id != null)
                    AppActionButton(
                      onPressed: controller.saving
                          ? null
                          : () => _delete(controller),
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      filled: false,
                    ),
                  AppActionButton(
                    onPressed: controller.saving ? null : controller.resetForm,
                    icon: Icons.refresh,
                    label: 'Reset',
                    filled: false,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
