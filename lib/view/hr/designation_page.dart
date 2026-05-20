import '../../controller/hr/designation_management_controller.dart';
import '../../screen.dart';

class DesignationManagementPage extends StatefulWidget {
  const DesignationManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<DesignationManagementPage> createState() =>
      _DesignationManagementPageState();
}

class _DesignationManagementPageState extends State<DesignationManagementPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        persistentControllerTag('DesignationManagementController');
    Get.put(DesignationManagementController(), tag: _controllerTag);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DesignationManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(controller);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () =>
                controller.startNew(isDesktop: Responsive.isDesktop(context)),
            icon: Icons.workspace_premium_outlined,
            label: 'New Designation',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'Designations',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(DesignationManagementController controller) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading designations...');
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load designations',
        message: controller.pageError!,
        onRetry: controller.loadDesignations,
      );
    }

    // Migrated page/form state now lives in DesignationManagementController.
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Designations',
      editorTitle: controller.selectedDesignation?.toString(),
      scrollController: controller.pageScrollController,
      wrapEditorInCard: false,
      list: SettingsListCard<DesignationModel>(
        searchController: controller.searchController,
        searchHint: 'Search designations',
        items: controller.filteredDesignations,
        selectedItem: controller.selectedDesignation,
        emptyMessage: 'No designation records found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.designationName ?? '-',
          subtitle: item.id?.toString() ?? '',
          selected: selected,
          onTap: () => controller.selectDesignation(item),
          trailing: SettingsStatusPill(
            label: item.isActive ? 'Active' : 'Inactive',
            active: item.isActive,
          ),
        ),
      ),
      editor: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionCard(
            child: Form(
              key: controller.designationFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (controller.formError != null) ...[
                    AppErrorStateView.inline(message: controller.formError!),
                    const SizedBox(height: AppUiConstants.spacingSm),
                  ],
                  SettingsFormWrap(
                    children: [
                      AppFormTextField(
                        labelText: 'Designation Name',
                        controller: controller.nameController,
                        validator: Validators.compose([
                          Validators.required('Designation Name'),
                          Validators.optionalMaxLength(100, 'Designation Name'),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppUiConstants.spacingMd),
                  AppSwitchTile(
                    label: 'Active',
                    value: controller.isActive,
                    onChanged: controller.setIsActive,
                  ),
                  const SizedBox(height: AppUiConstants.spacingLg),
                  Wrap(
                    spacing: AppUiConstants.spacingSm,
                    runSpacing: AppUiConstants.spacingSm,
                    children: [
                      AppActionButton(
                        icon: Icons.save_outlined,
                        label: controller.selectedDesignation == null
                            ? 'Save Designation'
                            : 'Update Designation',
                        onPressed: controller.saving ? null : controller.save,
                        busy: controller.saving,
                      ),
                      if (controller.selectedDesignation?.id != null)
                        AppActionButton(
                          icon: Icons.delete_outline,
                          label: 'Delete',
                          onPressed: controller.delete,
                          busy: controller.saving,
                          filled: false,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingLg),
          _buildEmployeeSection(controller),
        ],
      ),
    );
  }

  Widget _buildEmployeeSection(DesignationManagementController controller) {
    final selectedDesignation = controller.selectedDesignation;
    if (selectedDesignation?.id == null) {
      return const AppSectionCard(
        child: SettingsEmptyState(
          icon: Icons.badge_outlined,
          title: 'Employees Will Show Here',
          message:
              'Select or save a designation to view the employees assigned to it.',
          minHeight: 220,
        ),
      );
    }

    final employees = controller.designationEmployees;
    if (employees.isEmpty) {
      return const AppSectionCard(
        child: SettingsEmptyState(
          icon: Icons.groups_outlined,
          title: 'No Employees In This Designation',
          message: 'Employees assigned to this designation will appear here.',
          minHeight: 220,
        ),
      );
    }

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Employees',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: employees.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppUiConstants.spacingXs),
            itemBuilder: (context, index) => _EmployeeInfoRow(
              employee: employees[index],
              onTap: () => _openEmployee(employees[index]),
            ),
          ),
        ],
      ),
    );
  }

  void _openEmployee(EmployeeModel employee) {
    final id = employee.id;
    if (id == null) {
      return;
    }

    final route = '/hr/employees?employee_id=$id';
    final shellNavigate = ShellRouteScope.maybeOf(context);
    if (shellNavigate != null) {
      shellNavigate(route);
      return;
    }

    Navigator.of(context).pushNamed(route);
  }
}

class _EmployeeInfoRow extends StatelessWidget {
  const _EmployeeInfoRow({required this.employee, this.onTap});

  final EmployeeModel employee;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = <String>[
      if ((employee.employeeCode ?? '').trim().isNotEmpty)
        employee.employeeCode!,
      if ((employee.departmentName ?? '').trim().isNotEmpty)
        employee.departmentName!,
    ].join(' • ');

    final detail = <String>[
      if ((employee.mobile ?? '').trim().isNotEmpty) employee.mobile!,
      if ((employee.email ?? '').trim().isNotEmpty) employee.email!,
    ].join(' • ');

    return SettingsListTile(
      title: employee.employeeName ?? employee.employeeCode ?? 'Employee',
      subtitle: subtitle,
      detail: detail.isEmpty ? null : detail,
      selected: false,
      onTap: onTap ?? () {},
      trailing: SettingsStatusPill(
        label: (employee.status ?? 'active').toUpperCase(),
        active: (employee.status ?? 'active') == 'active',
      ),
    );
  }
}
