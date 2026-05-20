import '../../../controller/settings/master/branch_management_controller.dart';
import '../../../screen.dart';

class BranchManagementPage extends StatefulWidget {
  const BranchManagementPage({
    super.key,
    this.embedded = false,
    this.initialTabIndex = 0,
  });

  final bool embedded;
  final int initialTabIndex;

  @override
  State<BranchManagementPage> createState() => _BranchManagementPageState();
}

class _BranchManagementPageState extends State<BranchManagementPage>
    with SingleTickerProviderStateMixin {
  late final String _controllerTag;
  late final BranchManagementController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        persistentControllerTag('BranchManagementController');
    _controller = Get.put(
      BranchManagementController(initialTabIndex: widget.initialTabIndex),
      tag: _controllerTag,
    permanent: true,
    );
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _controller.setActiveTabIndex(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BranchManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(context, controller);
        final actions = [
          AdaptiveShellActionButton(
            onPressed: () =>
                controller.startNewBranch(isDesktop: Responsive.isDesktop(context)),
            icon: Icons.add,
            label: 'New Branch',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'Branches',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    BranchManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading branches...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load branches',
        message: controller.pageError!,
        onRetry: controller.loadData,
      );
    }

    // Migrated page/form state now lives in BranchManagementController.
    if (_tabController.index != controller.activeTabIndex) {
      _tabController.index = controller.activeTabIndex;
    }

    return SettingsWorkspace(
        controller: controller.workspaceController,
        title: 'Branches',
        editorTitle: controller.selectedBranch?.toString(),
        scrollController: controller.pageScrollController,
        list: SettingsListCard<BranchModel>(
          searchController: controller.searchController,
          searchHint: 'Search branches',
          items: controller.filteredBranches,
          selectedItem: controller.selectedBranch,
          emptyMessage: 'No branches found.',
          itemBuilder: (branch, selected) => SettingsListTile(
            title: branch.name ?? '',
            subtitle: [
              branch.code ?? '',
              companyNameById(controller.companies, branch.companyId),
              branch.branchType?.replaceAll('_', ' ') ?? '',
            ].where((item) => item.isNotEmpty).join(' • '),
            selected: selected,
            trailing: SettingsStatusPill(
              label: branch.isActive ? 'Active' : 'Inactive',
              active: branch.isActive,
            ),
            onTap: () => controller.selectBranch(branch),
          ),
        ),
        editor: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TabBar(
              controller: _tabController,
              onTap: controller.setActiveTabIndex,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Primary'),
                Tab(text: 'Branch Location'),
                Tab(text: 'Warehouse'),
                Tab(text: 'GST Registrations'),
              ],
            ),
            const SizedBox(height: 20),
            IndexedStack(
              index: controller.activeTabIndex,
              children: [
                _buildPrimaryTab(context, controller),
                controller.selectedBranch?.id == null
                    ? _buildDependentTabPlaceholder(
                        title: 'Branch Location',
                        message:
                            'Select an existing branch or save this branch first to manage business locations.',
                      )
                    : BusinessLocationManagementPage(
                        key: ValueKey<String>(
                          'branch-location-${controller.selectedBranch!.id}',
                        ),
                        embedded: true,
                        fixedCompanyId: controller.selectedBranch!.companyId,
                        fixedBranchId: controller.selectedBranch!.id,
                      ),
                controller.selectedBranch?.id == null
                    ? _buildDependentTabPlaceholder(
                        title: 'Warehouse',
                        message:
                            'Select an existing branch or save this branch first to manage warehouses.',
                      )
                    : WarehouseManagementPage(
                        key: ValueKey<String>(
                          'branch-warehouse-${controller.selectedBranch!.id}',
                        ),
                        embedded: true,
                        fixedCompanyId: controller.selectedBranch!.companyId,
                        fixedBranchId: controller.selectedBranch!.id,
                      ),
                controller.selectedBranch?.id == null
                    ? _buildDependentTabPlaceholder(
                        title: 'GST Registrations',
                        message:
                            'Select an existing branch or save this branch first to manage GST registrations.',
                      )
                    : GstRegistrationManagementPage(
                        key: ValueKey<String>(
                          'branch-gst-${controller.selectedBranch!.id}',
                        ),
                        embedded: true,
                        fixedCompanyId: controller.selectedBranch!.companyId,
                        fixedBranchId: controller.selectedBranch!.id,
                      ),
              ],
            ),
          ],
        ),
    );
  }

  Widget _buildPrimaryTab(
    BuildContext context,
    BranchManagementController controller,
  ) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsFormWrap(
            children: [
              AppDropdownField<int>.fromMapped(
                labelText: 'Company',
                initialValue: controller.companyId,
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
                validator: (value) => value == null ? 'Company is required' : null,
              ),
              AppFormTextField(
                controller: controller.codeController,
                labelText: 'Code',
                readOnly: true,
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Code is required' : null,
              ),
              AppFormTextField(
                controller: controller.nameController,
                labelText: 'Name',
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Name is required' : null,
              ),
              AppDropdownField<String>.fromMapped(
                initialValue: controller.branchType,
                labelText: 'Branch Type',
                mappedItems: BranchManagementController.branchTypeItems,
                onChanged: controller.setBranchType,
              ),
            ],
          ),
          AppSwitchTile(
            label: 'Head Office',
            subtitle: 'Mark only one branch per company as head office.',
            value: controller.isHeadOffice,
            onChanged: controller.setIsHeadOffice,
          ),
          AppSwitchTile(
            label: 'Active',
            value: controller.isActive,
            onChanged: controller.setIsActive,
          ),
          const SizedBox(height: 8),
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
                icon: controller.selectedBranch == null ? Icons.add : Icons.save,
                label: controller.saving ? 'Saving...' : 'Save Branch',
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

  Widget _buildDependentTabPlaceholder({
    required String title,
    required String message,
  }) {
    return SettingsEmptyState(
      icon: Icons.link_outlined,
      title: title,
      message: message,
      minHeight: 240,
    );
  }
}
