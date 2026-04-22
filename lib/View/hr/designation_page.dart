import '../../screen.dart';

class DesignationManagementPage extends StatefulWidget {
  const DesignationManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<DesignationManagementPage> createState() =>
      _DesignationManagementPageState();
}

class _DesignationManagementPageState extends State<DesignationManagementPage> {
  final HrService _hrService = HrService();
  final ScrollController _pageScrollController = ScrollController();
  final GlobalKey<FormState> _designationFormKey = GlobalKey<FormState>();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<DesignationModel> _designations = const <DesignationModel>[];
  List<DesignationModel> _filteredDesignations = const <DesignationModel>[];
  List<EmployeeModel> _employees = const <EmployeeModel>[];
  DesignationModel? _selectedDesignation;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadDesignations();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadDesignations({int? selectId}) async {
    setState(() {
      _initialLoading = _designations.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait<dynamic>([
        _hrService.designations(
          filters: const {'per_page': 200, 'sort_by': 'designation_name'},
        ),
        _hrService.employees(
          filters: const {'per_page': 300, 'sort_by': 'employee_name'},
        ),
      ]);
      final items =
          (responses[0] as PaginatedResponse<DesignationModel>).data ??
          const <DesignationModel>[];
      final employees =
          (responses[1] as PaginatedResponse<EmployeeModel>).data ??
          const <EmployeeModel>[];
      if (!mounted) return;

      setState(() {
        _designations = items;
        _employees = employees;
        _filteredDesignations = _filterDesignations(
          items,
          _searchController.text,
        );
        _initialLoading = false;
      });

      final selected = selectId != null
          ? items.cast<DesignationModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedDesignation == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<DesignationModel?>().firstWhere(
                    (item) => item?.id == _selectedDesignation?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected != null) {
        _selectDesignation(selected);
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

  List<DesignationModel> _filterDesignations(
    List<DesignationModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (item) {
      return [item.designationName ?? ''];
    });
  }

  void _applySearch() {
    setState(() {
      _filteredDesignations = _filterDesignations(
        _designations,
        _searchController.text,
      );
    });
  }

  void _selectDesignation(DesignationModel item) {
    _selectedDesignation = item;
    _nameController.text = item.designationName ?? '';
    _isActive = item.isActive;
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedDesignation = null;
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

  List<EmployeeModel> get _designationEmployees {
    final designationId = _selectedDesignation?.id;
    if (designationId == null) {
      return const <EmployeeModel>[];
    }

    return _employees
        .where((item) => item.designationId == designationId)
        .toList(growable: false);
  }

  Future<void> _save() async {
    final FormState? form = _designationFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final model = DesignationModel(
      id: _selectedDesignation?.id,
      designationName: _nameController.text.trim(),
      isActive: _isActive,
    );

    try {
      final response = _selectedDesignation == null
          ? await _hrService.createDesignation(model)
          : await _hrService.updateDesignation(
              _selectedDesignation!.id!,
              model,
            );
      final saved = response.data;
      if (!mounted) return;
      if (saved == null) {
        setState(() => _formError = response.message);
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadDesignations(selectId: saved.id);
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
    final id = _selectedDesignation?.id;
    if (id == null) return;

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final response = await _hrService.deleteDesignation(id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadDesignations();
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
        icon: Icons.workspace_premium_outlined,
        label: 'New Designation',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Designations',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading designations...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load designations',
        message: _pageError!,
        onRetry: _loadDesignations,
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Designations',
      editorTitle: _selectedDesignation?.toString(),
      scrollController: _pageScrollController,
      wrapEditorInCard: false,
      list: SettingsListCard<DesignationModel>(
        searchController: _searchController,
        searchHint: 'Search designations',
        items: _filteredDesignations,
        selectedItem: _selectedDesignation,
        emptyMessage: 'No designation records found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.designationName ?? '-',
          subtitle: item.id?.toString() ?? '',
          selected: selected,
          onTap: () => _selectDesignation(item),
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
              key: _designationFormKey,
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
                            labelText: 'Designation Name',
                            controller: _nameController,
                            validator: Validators.compose([
                              Validators.required('Designation Name'),
                              Validators.optionalMaxLength(
                                100,
                                'Designation Name',
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
                            label: _selectedDesignation == null
                                ? 'Save Designation'
                                : 'Update Designation',
                            onPressed: _saving ? null : _save,
                            busy: _saving,
                          ),
                          if (_selectedDesignation?.id != null)
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
    final selectedDesignation = _selectedDesignation;
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

    final employees = _designationEmployees;
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
