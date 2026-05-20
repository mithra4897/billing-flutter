import '../../../controller/settings/master/business_location_management_controller.dart';
import '../../../screen.dart';

class BusinessLocationManagementPage extends StatefulWidget {
  const BusinessLocationManagementPage({
    super.key,
    this.embedded = false,
    this.fixedCompanyId,
    this.fixedBranchId,
  });

  final bool embedded;
  final int? fixedCompanyId;
  final int? fixedBranchId;

  @override
  State<BusinessLocationManagementPage> createState() =>
      _BusinessLocationManagementPageState();
}

class _BusinessLocationManagementPageState
    extends State<BusinessLocationManagementPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'BusinessLocationManagementController'
      '-${widget.fixedCompanyId ?? 'all'}-${widget.fixedBranchId ?? 'all'}',
    );
    Get.put(
      BusinessLocationManagementController(
        fixedCompanyId: widget.fixedCompanyId,
        fixedBranchId: widget.fixedBranchId,
      ),
      tag: _controllerTag,
    );
  }

  @override
  void didUpdateWidget(covariant BusinessLocationManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fixedCompanyId != widget.fixedCompanyId ||
        oldWidget.fixedBranchId != widget.fixedBranchId) {
      Get.find<BusinessLocationManagementController>(
        tag: _controllerTag,
      ).reloadForScope(
        nextFixedCompanyId: widget.fixedCompanyId,
        nextFixedBranchId: widget.fixedBranchId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BusinessLocationManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () => controller.startNewLocation(
              isDesktop: Responsive.isDesktop(context),
            ),
            icon: Icons.add_location_alt_outlined,
            label: 'New Location',
          ),
        ];

        if (widget.embedded) {
          return _buildEmbeddedContent(context, controller);
        }

        return AppStandaloneShell(
          title: 'Business Locations',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: _buildContent(context, controller),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    BusinessLocationManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading business locations...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load business locations',
        message: controller.pageError!,
        onRetry: controller.loadData,
      );
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Business Locations',
      editorTitle: controller.selectedLocation?.toString(),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<BusinessLocationModel>(
        searchController: controller.searchController,
        searchHint: 'Search locations',
        items: controller.filteredLocations,
        selectedItem: controller.selectedLocation,
        emptyMessage: 'No business locations found.',
        itemBuilder: (location, selected) => SettingsListTile(
          title: location.name ?? '',
          subtitle: [
            location.code ?? '',
            branchNameById(controller.branches, location.branchId),
            location.city ?? '',
          ].where((item) => item.isNotEmpty).join(' • '),
          selected: selected,
          trailing: SettingsStatusPill(
            label: location.isActive ? 'Active' : 'Inactive',
            active: location.isActive,
          ),
          onTap: () => controller.selectLocation(location),
        ),
      ),
      editor: _buildEditor(context, controller),
    );
  }

  Widget _buildEditor(
    BuildContext context,
    BusinessLocationManagementController controller,
  ) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsFormWrap(
            children: [
              if (widget.fixedCompanyId == null)
                AppDropdownField<int>.fromMapped(
                  initialValue: controller.companyId,
                  labelText: 'Company',
                  mappedItems: controller.companies
                      .where((company) => company.id != null)
                      .map(
                        (company) => AppDropdownItem<int>(
                          value: company.id!,
                          label: company.legalName ?? '',
                        ),
                      )
                      .toList(growable: false),
                  onChanged: controller.setCompanyId,
                  validator: (value) =>
                      value == null ? 'Company is required' : null,
                ),
              if (widget.fixedBranchId == null)
                AppDropdownField<int>.fromMapped(
                  initialValue: controller.branchId,
                  labelText: 'Branch',
                  mappedItems: controller.filteredBranches
                      .where((branch) => branch.id != null)
                      .map(
                        (branch) => AppDropdownItem<int>(
                          value: branch.id!,
                          label: branch.name ?? '',
                        ),
                      )
                      .toList(growable: false),
                  onChanged: controller.setBranchId,
                  validator: (value) =>
                      value == null ? 'Branch is required' : null,
                ),
              AppFormTextField(
                controller: controller.codeController,
                labelText: 'Code',
                readOnly: true,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Code is required'
                    : null,
              ),
              AppFormTextField(
                controller: controller.nameController,
                labelText: 'Name',
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Name is required'
                    : null,
              ),
              AppDropdownField<String>.fromMapped(
                initialValue: controller.locationType,
                labelText: 'Location Type',
                mappedItems: const [
                  AppDropdownItem(value: 'billing', label: 'Billing'),
                  AppDropdownItem(value: 'office', label: 'Office'),
                  AppDropdownItem(value: 'factory', label: 'Factory'),
                  AppDropdownItem(value: 'retail', label: 'Retail'),
                  AppDropdownItem(value: 'service', label: 'Service'),
                  AppDropdownItem(value: 'jobwork', label: 'Jobwork'),
                  AppDropdownItem(value: 'warehouse', label: 'Warehouse Site'),
                  AppDropdownItem(value: 'other', label: 'Other'),
                ],
                onChanged: controller.setLocationType,
              ),
              AppFormTextField(
                controller: controller.contactController,
                labelText: 'Contact Person',
              ),
              AppFormTextField(
                controller: controller.phoneController,
                labelText: 'Phone',
              ),
              AppFormTextField(
                controller: controller.emailController,
                labelText: 'Email',
              ),
              AppFormTextField(
                controller: controller.cityController,
                labelText: 'City',
              ),
              AppFormTextField(
                controller: controller.stateController,
                labelText: 'State',
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppFormTextField(
            controller: controller.addressController,
            maxLines: 2,
            labelText: 'Address Line 1',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AppToggleChip(
                label: 'Sales',
                value: controller.allowSales,
                onChanged: controller.setAllowSales,
              ),
              AppToggleChip(
                label: 'Purchase',
                value: controller.allowPurchase,
                onChanged: controller.setAllowPurchase,
              ),
              AppToggleChip(
                label: 'Stock',
                value: controller.allowStock,
                onChanged: controller.setAllowStock,
              ),
              AppToggleChip(
                label: 'Accounts',
                value: controller.allowAccounts,
                onChanged: controller.setAllowAccounts,
              ),
              AppToggleChip(
                label: 'HR',
                value: controller.allowHr,
                onChanged: controller.setAllowHr,
              ),
            ],
          ),
          AppSwitchTile(
            label: 'Default Location',
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
            maxLines: 3,
            labelText: 'Remarks',
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
            children: [
              AppActionButton(
                onPressed: controller.saving ? null : controller.save,
                icon: controller.selectedLocation == null
                    ? Icons.add
                    : Icons.save,
                label: controller.saving ? 'Saving...' : 'Save Location',
                busy: controller.saving,
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
      ),
    );
  }

  Widget _buildEmbeddedContent(
    BuildContext context,
    BusinessLocationManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading business locations...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView.inline(message: controller.pageError!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppActionButton(
              onPressed: controller.saving
                  ? null
                  : () => controller.startNewLocation(isDesktop: false),
              icon: Icons.add_location_alt_outlined,
              label: 'New Location',
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (controller.filteredLocations.isEmpty &&
            !controller.showDraftTile &&
            controller.selectedLocation == null)
          const SettingsEmptyState(
            icon: Icons.add_location_alt_outlined,
            title: 'No Branch Locations',
            message: 'No branch locations found.',
            minHeight: 160,
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (controller.showDraftTile &&
                  controller.selectedLocation == null) ...[
                SettingsExpandableTile(
                  key: const ValueKey('location-draft'),
                  title: 'New Location',
                  subtitle: 'Create a branch-associated location.',
                  expanded: true,
                  highlighted: true,
                  leadingIcon: Icons.add_outlined,
                  onToggle: controller.hideDraftTile,
                  child: _buildEditor(context, controller),
                ),
                if (controller.filteredLocations.isNotEmpty)
                  const SizedBox(height: AppUiConstants.spacingSm),
              ],
              ...controller.filteredLocations.map((item) {
                final expanded = identical(item, controller.selectedLocation);
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppUiConstants.spacingSm,
                  ),
                  child: SettingsExpandableTile(
                    key: ValueKey('location-${item.id}-$expanded'),
                    title: item.name ?? '-',
                    subtitle: [
                      item.code ?? '',
                      item.city ?? '',
                      item.locationType?.replaceAll('_', ' ') ?? '',
                    ].where((value) => value.isNotEmpty).join(' • '),
                    detail: [
                      if (item.isDefault) 'Default',
                      if (item.isActive) 'Active',
                    ].join(' • '),
                    expanded: expanded,
                    highlighted: expanded,
                    onToggle: () {
                      if (expanded) {
                        controller.resetForm();
                      } else {
                        controller.selectLocation(item);
                      }
                    },
                    child: expanded
                        ? _buildEditor(context, controller)
                        : const SizedBox.shrink(),
                  ),
                );
              }),
            ],
          ),
      ],
    );
  }
}
