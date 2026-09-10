import '../../controller/hr/department_management_controller.dart';
import '../../screen.dart';

class DepartmentManagementPage extends StatefulWidget {
  const DepartmentManagementPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<DepartmentManagementPage> createState() =>
      _DepartmentManagementPageState();
}

class _DepartmentManagementPageState extends State<DepartmentManagementPage> {
  late final String _controllerTag;
  final GlobalKey<FormState> _departmentFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('DepartmentManagementController');
    if (Get.isRegistered<DepartmentManagementController>(tag: _controllerTag)) {
      final controller = Get.find<DepartmentManagementController>(
        tag: _controllerTag,
      );
      if (widget.editorOnly && widget.initialId == null) {
        controller.startNew(isDesktop: true);
      } else {
        unawaited(controller.loadDepartments(selectId: widget.initialId));
      }
    } else {
      Get.put(
        DepartmentManagementController(
          initialSelectId: widget.initialId,
          startInNewMode: widget.editorOnly && widget.initialId == null,
        ),
        tag: _controllerTag,
      );
    }
  }

  @override
  void dispose() {
    if (Get.isRegistered<DepartmentManagementController>(tag: _controllerTag)) {
      Get.delete<DepartmentManagementController>(
        tag: _controllerTag,
        force: true,
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DepartmentManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          if (!widget.editorOnly)
            AdaptiveShellSearchField(
              controller: controller.searchController,
              hintText: 'Search departments',
            ),
          AdaptiveShellActionButton(
            onPressed: () =>
                openFormScreenRoute(context, '/hr/departments/new'),
            icon: Icons.apartment_outlined,
            label: 'New Department',
          ),
        ];

        if (!widget.editorOnly) {
          return _buildSharedRegister(controller, actions);
        }

        final content = _buildContent(controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'Departments',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildSharedRegister(
    DepartmentManagementController controller,
    List<Widget> actions,
  ) {
    return SharedRegisterList<DepartmentModel>(
      title: 'Departments',
      embedded: widget.embedded,
      loading: controller.initialLoading,
      errorMessage: controller.pageError,
      onRetry: controller.loadDepartments,
      actions: actions,
      rows: controller.filteredDepartments,
      emptyMessage: 'No department records found.',
      columns: [
        PurchaseRegisterColumn<DepartmentModel>(
          label: 'Department Name',
          flex: 2,
          valueBuilder: (row) => row.departmentName ?? '-',
        ),
        PurchaseRegisterColumn<DepartmentModel>(
          label: 'ID',
          valueBuilder: (row) => row.id?.toString() ?? '-',
        ),
        PurchaseRegisterColumn<DepartmentModel>(
          label: 'Status',
          valueBuilder: (row) => row.isActive ? 'Active' : 'Inactive',
        ),
      ],
      onRowTap: (row) {
        final id = row.id;
        if (id != null) {
          openFormScreenRoute(context, '/hr/departments/$id');
        }
      },
    );
  }

  Widget _buildContent(DepartmentManagementController controller) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading departments...');
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load departments',
        message: controller.pageError!,
        onRetry: controller.loadDepartments,
      );
    }

    // Migrated page/form state now lives in DepartmentManagementController.
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Departments',
      editorTitle: controller.selectedDepartment?.toString(),
      scrollController: controller.pageScrollController,
      editorOnly: widget.editorOnly,
      wrapEditorInCard: false,
      list: SettingsListCard<DepartmentModel>(
        searchController: controller.searchController,
        searchHint: 'Search departments',
        items: controller.filteredDepartments,
        selectedItem: controller.selectedDepartment,
        emptyMessage: 'No department records found.',
        paginationMeta: controller.paginationMeta,
        onPageChanged: controller.goToPage,
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.departmentName ?? '-',
          subtitle: item.id?.toString() ?? '',
          selected: selected,
          onTap: () {
            final id = item.id;
            if (id != null) {
              openFormScreenRoute(context, '/hr/departments/$id');
            }
          },
          trailing: SettingsStatusPill(
            label: item.isActive ? 'Active' : 'Inactive',
            active: item.isActive,
          ),
        ),
      ),
      editorBuilder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionCard(
            child: Form(
              key: _departmentFormKey,
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
                        labelText: 'Department Name',
                        controller: controller.nameController,
                        validator: Validators.compose([
                          Validators.required('Department Name'),
                          Validators.optionalMaxLength(100, 'Department Name'),
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
                        label: controller.selectedDepartment == null
                            ? 'Save Department'
                            : 'Update Department',
                        onPressed: controller.saving
                            ? null
                            : () => controller.save(
                                formState: _departmentFormKey.currentState,
                              ),
                        busy: controller.saving,
                      ),
                      if (controller.selectedDepartment?.id != null)
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

  Widget _buildEmployeeSection(DepartmentManagementController controller) {
    final selectedDepartment = controller.selectedDepartment;
    if (selectedDepartment?.id == null) {
      return const AppSectionCard(
        child: SettingsEmptyState(
          icon: Icons.badge_outlined,
          title: 'Employees Will Show Here',
          message:
              'Select or save a department to view the employees assigned to it.',
          minHeight: 220,
        ),
      );
    }

    final employees = controller.departmentEmployees;
    if (employees.isEmpty) {
      return const AppSectionCard(
        child: SettingsEmptyState(
          icon: Icons.groups_outlined,
          title: 'No Employees In This Department',
          message: 'Employees assigned to this department will appear here.',
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
      if ((employee.designationName ?? '').trim().isNotEmpty)
        employee.designationName!,
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
