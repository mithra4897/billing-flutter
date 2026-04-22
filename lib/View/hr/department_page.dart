import '../../screen.dart';

class DepartmentManagementPage extends StatefulWidget {
  const DepartmentManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<DepartmentManagementPage> createState() =>
      _DepartmentManagementPageState();
}

class _DepartmentManagementPageState extends State<DepartmentManagementPage> {
  final HrService _hrService = HrService();
  final ScrollController _pageScrollController = ScrollController();
  final GlobalKey<FormState> _departmentFormKey = GlobalKey<FormState>();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<DepartmentModel> _departments = const <DepartmentModel>[];
  List<DepartmentModel> _filteredDepartments = const <DepartmentModel>[];
  List<EmployeeModel> _employees = const <EmployeeModel>[];
  DepartmentModel? _selectedDepartment;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadDepartments();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments({int? selectId}) async {
    setState(() {
      _initialLoading = _departments.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait<dynamic>([
        _hrService.departments(
          filters: const {'per_page': 200, 'sort_by': 'department_name'},
        ),
        _hrService.employees(
          filters: const {'per_page': 300, 'sort_by': 'employee_name'},
        ),
      ]);
      final items =
          (responses[0] as PaginatedResponse<DepartmentModel>).data ??
          const <DepartmentModel>[];
      final employees =
          (responses[1] as PaginatedResponse<EmployeeModel>).data ??
          const <EmployeeModel>[];
      if (!mounted) return;

      setState(() {
        _departments = items;
        _employees = employees;
        _filteredDepartments = _filterDepartments(
          items,
          _searchController.text,
        );
        _initialLoading = false;
      });

      final selected = selectId != null
          ? items.cast<DepartmentModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedDepartment == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<DepartmentModel?>().firstWhere(
                    (item) => item?.id == _selectedDepartment?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected != null) {
        _selectDepartment(selected);
      } else {
        _resetForm();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pageError = error.toString();
        _initialLoading = false;
      });
    }
  }

  List<DepartmentModel> _filterDepartments(
    List<DepartmentModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (item) {
      return [item.departmentName ?? ''];
    });
  }

  void _applySearch() {
    setState(() {
      _filteredDepartments = _filterDepartments(
        _departments,
        _searchController.text,
      );
    });
  }

  void _selectDepartment(DepartmentModel item) {
    _selectedDepartment = item;
    _nameController.text = item.departmentName ?? '';
    _isActive = item.isActive;
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedDepartment = null;
    _nameController.clear();
    _isActive = true;
    _formError = null;
    setState(() {});
  }

  void _startNew() {
    _resetForm();
    if (!Responsive.isDesktop(context)) {
      _workspaceController.openEditor();
    }
  }

  List<EmployeeModel> get _departmentEmployees {
    final departmentId = _selectedDepartment?.id;
    if (departmentId == null) {
      return const <EmployeeModel>[];
    }

    return _employees
        .where((item) => item.departmentId == departmentId)
        .toList(growable: false);
  }

  Future<void> _save() async {
    final FormState? form = _departmentFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final model = DepartmentModel(
      id: _selectedDepartment?.id,
      departmentName: _nameController.text.trim(),
      isActive: _isActive,
    );

    try {
      final response = _selectedDepartment == null
          ? await _hrService.createDepartment(model)
          : await _hrService.updateDepartment(_selectedDepartment!.id!, model);
      final saved = response.data;
      if (!mounted) return;
      if (saved == null) {
        setState(() => _formError = response.message);
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadDepartments(selectId: saved.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final id = _selectedDepartment?.id;
    if (id == null) return;

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final response = await _hrService.deleteDepartment(id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadDepartments();
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _startNew,
        icon: Icons.apartment_outlined,
        label: 'New Department',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Departments',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading departments...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load departments',
        message: _pageError!,
        onRetry: _loadDepartments,
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Departments',
      editorTitle: _selectedDepartment?.toString(),
      scrollController: _pageScrollController,
      wrapEditorInCard: false,
      list: SettingsListCard<DepartmentModel>(
        searchController: _searchController,
        searchHint: 'Search departments',
        items: _filteredDepartments,
        selectedItem: _selectedDepartment,
        emptyMessage: 'No department records found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.departmentName ?? '-',
          subtitle: item.id?.toString() ?? '',
          selected: selected,
          onTap: () => _selectDepartment(item),
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
              key: _departmentFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                      if (_formError != null) ...[
                        AppErrorStateView.inline(message: _formError!),
                        const SizedBox(height: AppUiConstants.spacingSm),
                      ],
                      SettingsFormWrap(
                        children: [
                          AppFormTextField(
                            labelText: 'Department Name',
                            controller: _nameController,
                            validator: Validators.compose([
                              Validators.required('Department Name'),
                              Validators.optionalMaxLength(
                                100,
                                'Department Name',
                              ),
                            ]),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppUiConstants.spacingMd),
                      AppSwitchTile(
                        label: 'Active',
                        value: _isActive,
                        onChanged: (value) =>
                            setState(() => _isActive = value),
                      ),
                      const SizedBox(height: AppUiConstants.spacingLg),
                      Wrap(
                        spacing: AppUiConstants.spacingSm,
                        runSpacing: AppUiConstants.spacingSm,
                        children: [
                          AppActionButton(
                            icon: Icons.save_outlined,
                            label: _selectedDepartment == null
                                ? 'Save Department'
                                : 'Update Department',
                            onPressed: _saving ? null : _save,
                            busy: _saving,
                          ),
                          if (_selectedDepartment?.id != null)
                            AppActionButton(
                              icon: Icons.delete_outline,
                              label: 'Delete',
                              onPressed: _delete,
                              busy: _saving,
                              filled: false,
                            ),
                        ],
                      ),
                    ],
                  ),
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingLg),
          _buildEmployeeSection(),
        ],
      ),
    );
  }

  Widget _buildEmployeeSection() {
    final selectedDepartment = _selectedDepartment;
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

    final employees = _departmentEmployees;
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
