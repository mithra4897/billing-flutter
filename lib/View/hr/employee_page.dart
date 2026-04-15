import '../../screen.dart';

class EmployeeManagementPage extends StatefulWidget {
  const EmployeeManagementPage({
    super.key,
    this.embedded = false,
    this.initialEmployeeId,
  });

  final bool embedded;
  final int? initialEmployeeId;

  @override
  State<EmployeeManagementPage> createState() => _EmployeeManagementPageState();
}

class _EmployeeManagementPageState extends State<EmployeeManagementPage>
    with SingleTickerProviderStateMixin {
  static const List<AppDropdownItem<String>> _employmentTypeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'permanent', label: 'Permanent'),
        AppDropdownItem(value: 'contract', label: 'Contract'),
        AppDropdownItem(value: 'trainee', label: 'Trainee'),
        AppDropdownItem(value: 'intern', label: 'Intern'),
      ];

  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'active', label: 'Active'),
        AppDropdownItem(value: 'inactive', label: 'Inactive'),
        AppDropdownItem(value: 'terminated', label: 'Terminated'),
      ];

  static const List<AppDropdownItem<String>> _salaryModeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'monthly', label: 'Monthly'),
        AppDropdownItem(value: 'daily', label: 'Daily'),
        AppDropdownItem(value: 'hourly', label: 'Hourly'),
      ];

  static const List<AppDropdownItem<String>> _componentTypeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'earning', label: 'Earning'),
        AppDropdownItem(value: 'deduction', label: 'Deduction'),
      ];

  final HrService _hrService = HrService();
  final MasterService _masterService = MasterService();
  final AssetsService _assetsService = AssetsService();
  final MediaService _mediaService = MediaService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _primaryFormKey = GlobalKey<FormState>();
  final TextEditingController _employeeCodeController = TextEditingController();
  final TextEditingController _employeeNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _joiningDateController = TextEditingController();
  final TextEditingController _relievingDateController =
      TextEditingController();
  final TextEditingController _bankAccountNoController =
      TextEditingController();
  final TextEditingController _ifscCodeController = TextEditingController();
  final TextEditingController _profilePhotoController = TextEditingController();

  final TextEditingController _structureEffectiveFromController =
      TextEditingController();
  final TextEditingController _structureBasicSalaryController =
      TextEditingController();
  final TextEditingController _structureGrossSalaryController =
      TextEditingController();
  final TextEditingController _structureNetSalaryController =
      TextEditingController();

  final TextEditingController _componentNameController =
      TextEditingController();
  final TextEditingController _componentAmountController =
      TextEditingController();

  late final TabController _tabController;
  int _activeTabIndex = 0;
  bool _initialLoading = true;
  bool _saving = false;
  bool _uploadingPhoto = false;
  bool _showDraftStructureTile = false;
  bool _showDraftComponentTile = false;
  String? _pageError;
  String? _formError;
  String? _structureFormError;
  String? _componentFormError;
  List<EmployeeModel> _employees = const <EmployeeModel>[];
  List<EmployeeModel> _filteredEmployees = const <EmployeeModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<DepartmentModel> _departments = const <DepartmentModel>[];
  List<DesignationModel> _designations = const <DesignationModel>[];
  List<CostCenterModel> _costCenters = const <CostCenterModel>[];
  List<EmployeeAccountModel> _employeeAccounts = const <EmployeeAccountModel>[];
  List<_EmployeeSalaryStructureDraft> _salaryStructures =
      <_EmployeeSalaryStructureDraft>[];
  EmployeeModel? _selectedEmployee;
  int? _contextCompanyId;
  int? _companyId;
  int? _departmentId;
  int? _designationId;
  int? _costCenterId;
  String _employmentType = 'permanent';
  String _status = 'active';
  String _salaryMode = 'monthly';
  int _draftKeySeed = -1;
  int? _selectedStructureKey;
  bool _structureIsActive = true;
  int? _selectedComponentParentKey;
  int? _selectedComponentKey;
  String _componentType = 'earning';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _activeTabIndex = _tabController.index;
    _tabController.addListener(() {
      if (!mounted || _tabController.indexIsChanging) {
        return;
      }
      _activeTabIndex = _tabController.index;
      setState(() {});
    });
    _searchController.addListener(_applySearch);
    _loadData(selectId: widget.initialEmployeeId);
  }

  @override
  void didUpdateWidget(covariant EmployeeManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialEmployeeId != widget.initialEmployeeId &&
        widget.initialEmployeeId != null) {
      _loadData(selectId: widget.initialEmployeeId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _employeeCodeController.dispose();
    _employeeNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _joiningDateController.dispose();
    _relievingDateController.dispose();
    _bankAccountNoController.dispose();
    _ifscCodeController.dispose();
    _profilePhotoController.dispose();
    _structureEffectiveFromController.dispose();
    _structureBasicSalaryController.dispose();
    _structureGrossSalaryController.dispose();
    _structureNetSalaryController.dispose();
    _componentNameController.dispose();
    _componentAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadData({int? selectId}) async {
    setState(() {
      _initialLoading = _employees.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait<dynamic>([
        _hrService.employees(
          filters: const {'per_page': 200, 'sort_by': 'employee_name'},
        ),
        _hrService.departments(
          filters: const {'per_page': 200, 'sort_by': 'department_name'},
        ),
        _hrService.designations(
          filters: const {'per_page': 200, 'sort_by': 'designation_name'},
        ),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
        _assetsService.costCenters(
          filters: const {'per_page': 200, 'sort_by': 'cost_center_name'},
        ),
      ]);

      final employees =
          (responses[0] as PaginatedResponse<EmployeeModel>).data ??
          const <EmployeeModel>[];
      final departments =
          (responses[1] as PaginatedResponse<DepartmentModel>).data ??
          const <DepartmentModel>[];
      final designations =
          (responses[2] as PaginatedResponse<DesignationModel>).data ??
          const <DesignationModel>[];
      final companies =
          (responses[3] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final costCenters =
          (responses[4] as PaginatedResponse<CostCenterModel>).data ??
          const <CostCenterModel>[];

      final activeCompanies = companies.where((item) => item.isActive).toList();
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );

      if (!mounted) return;

      setState(() {
        _employees = employees;
        _departments = departments;
        _designations = designations;
        _companies = companies;
        _costCenters = costCenters.where((item) => item.isActive).toList();
        _contextCompanyId = contextSelection.companyId;
        _filteredEmployees = _filterEmployees(
          employees,
          _searchController.text,
        );
        if (selectId != null) {
          final savedInAll = employees.cast<EmployeeModel?>().firstWhere(
            (item) => item?.id == selectId,
            orElse: () => null,
          );
          if (savedInAll != null &&
              !_filteredEmployees.any((item) => item.id == selectId)) {
            _filteredEmployees = <EmployeeModel>[
              savedInAll,
              ..._filteredEmployees,
            ];
          }
        }
        _initialLoading = false;
      });

      final selected = selectId != null
          ? employees.cast<EmployeeModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedEmployee == null
                ? (_filteredEmployees.isNotEmpty
                      ? _filteredEmployees.first
                      : null)
                : employees.cast<EmployeeModel?>().firstWhere(
                    (item) => item?.id == _selectedEmployee?.id,
                    orElse: () => _filteredEmployees.isNotEmpty
                        ? _filteredEmployees.first
                        : null,
                  ));

      if (selected != null) {
        await _selectEmployee(selected);
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

  List<EmployeeModel> _filterEmployees(
    List<EmployeeModel> source,
    String query,
  ) {
    final scoped = _contextCompanyId == null
        ? source
        : source.where((item) => item.companyId == _contextCompanyId).toList();

    return filterMasterList(scoped, query, (item) {
      return [
        item.employeeCode ?? '',
        item.employeeName ?? '',
        item.departmentName ?? '',
        item.designationName ?? '',
        item.mobile ?? '',
      ];
    });
  }

  void _applySearch() {
    setState(() {
      _filteredEmployees = _filterEmployees(_employees, _searchController.text);
    });
  }

  Future<void> _selectEmployee(EmployeeModel employee) async {
    final detailResponse = await _hrService.employee(employee.id!);
    final accountsResponse = await _hrService.employeeAccounts(employee.id!);
    final salaryResponse = await _hrService.employeeSalaryStructures(
      employee.id!,
    );
    final full = detailResponse.data ?? employee;

    _selectedEmployee = full;
    _companyId = full.companyId ?? _contextCompanyId;
    _setEmployeeCode(full.employeeCode ?? '');
    _employeeNameController.text = full.employeeName ?? '';
    _departmentId = full.departmentId;
    _designationId = full.designationId;
    _mobileController.text = full.mobile ?? '';
    _emailController.text = full.email ?? '';
    _joiningDateController.text = full.joiningDate ?? '';
    _relievingDateController.text = full.relievingDate ?? '';
    _employmentType = full.employmentType ?? 'permanent';
    _status = full.status ?? 'active';
    _salaryMode = full.salaryMode ?? 'monthly';
    _bankAccountNoController.text = full.bankAccountNo ?? '';
    _ifscCodeController.text = full.ifscCode ?? '';
    _profilePhotoController.text = full.profilePhotoPath ?? '';
    _costCenterId = full.costCenterId;
    _employeeAccounts = accountsResponse.data ?? const <EmployeeAccountModel>[];
    _salaryStructures =
        (salaryResponse.data ?? const <EmployeeSalaryStructureModel>[])
            .map(_salaryStructureDraftFromModel)
            .toList(growable: true);
    _resetStructureEditor(silent: true);
    _resetComponentEditor(silent: true);
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedEmployee = null;
    _companyId =
        _contextCompanyId ??
        (_companies.isNotEmpty ? _companies.first.id : null);
    _employeeNameController.clear();
    _departmentId = null;
    _designationId = null;
    _mobileController.clear();
    _emailController.clear();
    _joiningDateController.clear();
    _relievingDateController.clear();
    _employmentType = 'permanent';
    _status = 'active';
    _salaryMode = 'monthly';
    _bankAccountNoController.clear();
    _ifscCodeController.clear();
    _profilePhotoController.clear();
    _costCenterId = null;
    _employeeAccounts = const <EmployeeAccountModel>[];
    _salaryStructures = <_EmployeeSalaryStructureDraft>[];
    _resetStructureEditor(silent: true);
    _resetComponentEditor(silent: true);
    _primeEmployeeCodeSuggestion();
    _formError = null;
    setState(() {});
  }

  bool get _isNewEmployee => _selectedEmployee?.id == null;

  void _setEmployeeCode(String value) {
    _employeeCodeController.value = _employeeCodeController.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _primeEmployeeCodeSuggestion() {
    if (!_isNewEmployee) {
      return;
    }
    _setEmployeeCode(_generateEmployeeCode());
  }

  String _generateEmployeeCode() {
    const prefix = 'EMP';
    final companyId = _companyId;
    final pattern = RegExp('^${RegExp.escape(prefix)}/(\\d+)\$');
    var nextNumber = 1;
    for (final employee in _employees) {
      if (companyId != null && employee.companyId != companyId) {
        continue;
      }
      final match = pattern.firstMatch(
        (employee.employeeCode ?? '').trim().toUpperCase(),
      );
      if (match == null) continue;
      final value = int.tryParse(match.group(1) ?? '');
      if (value != null && value >= nextNumber) {
        nextNumber = value + 1;
      }
    }
    return '$prefix/${nextNumber.toString().padLeft(5, '0')}';
  }

  void _refreshEmployeeCode() {
    if (!_isNewEmployee) {
      return;
    }
    _setEmployeeCode(_generateEmployeeCode());
    setState(() {});
  }

  EmployeeModel _buildEmployeePayload() {
    return EmployeeModel(
      id: _selectedEmployee?.id,
      companyId: _companyId,
      employeeCode: nullIfEmpty(_employeeCodeController.text.trim()),
      employeeName: nullIfEmpty(_employeeNameController.text.trim()),
      departmentId: _departmentId,
      designationId: _designationId,
      mobile: nullIfEmpty(_mobileController.text.trim()),
      email: nullIfEmpty(_emailController.text.trim()),
      joiningDate: nullIfEmpty(_joiningDateController.text.trim()),
      relievingDate: nullIfEmpty(_relievingDateController.text.trim()),
      employmentType: _employmentType,
      status: _status,
      salaryMode: _salaryMode,
      bankAccountNo: nullIfEmpty(_bankAccountNoController.text.trim()),
      ifscCode: nullIfEmpty(_ifscCodeController.text.trim()),
      profilePhotoPath: nullIfEmpty(_profilePhotoController.text.trim()),
      costCenterId: _costCenterId,
      salaryStructures: _salaryStructures
          .map((item) => item.toModel(employeeId: _selectedEmployee?.id))
          .toList(growable: false),
    );
  }

  Future<void> _savePrimary() async {
    if (!_primaryFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final payload = _buildEmployeePayload();
      final response = _selectedEmployee == null
          ? await _hrService.createEmployee(payload)
          : await _hrService.updateEmployee(_selectedEmployee!.id!, payload);
      final saved = response.data;
      if (!mounted) return;
      if (saved == null) {
        setState(() => _formError = response.message);
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData(selectId: saved.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _deleteEmployee() async {
    final id = _selectedEmployee?.id;
    if (id == null) return;

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final response = await _hrService.deleteEmployee(id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData();
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _persistSalaryData(String successMessage) async {
    final employee = _selectedEmployee;
    if (employee?.id == null) {
      return;
    }

    setState(() {
      _saving = true;
      _structureFormError = null;
      _componentFormError = null;
      _formError = null;
    });

    try {
      final response = await _hrService.updateEmployee(
        employee!.id!,
        _buildEmployeePayload(),
      );
      final saved = response.data;
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
      await _loadData(selectId: saved?.id ?? employee.id);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _structureFormError = error.toString();
        _componentFormError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  int _nextDraftKey() => _draftKeySeed--;

  _EmployeeSalaryStructureDraft _salaryStructureDraftFromModel(
    EmployeeSalaryStructureModel model,
  ) {
    return _EmployeeSalaryStructureDraft(
      key: model.id ?? _nextDraftKey(),
      id: model.id,
      effectiveFrom: model.effectiveFrom ?? '',
      basicSalary: _decimalText(model.basicSalary),
      grossSalary: _decimalText(model.grossSalary),
      netSalary: _decimalText(model.netSalary),
      isActive: model.isActive,
      components: model.components
          .map(
            (item) => _EmployeeSalaryComponentDraft(
              key: item.id ?? _nextDraftKey(),
              id: item.id,
              componentName: item.componentName ?? '',
              componentType: item.componentType ?? 'earning',
              amount: _decimalText(item.amount),
            ),
          )
          .toList(growable: true),
    );
  }

  void _resetStructureEditor({bool silent = false}) {
    _showDraftStructureTile = false;
    _selectedStructureKey = null;
    _structureEffectiveFromController.clear();
    _structureBasicSalaryController.clear();
    _structureGrossSalaryController.clear();
    _structureNetSalaryController.clear();
    _structureIsActive = true;
    _structureFormError = null;
    if (!silent && mounted) {
      setState(() {});
    }
  }

  void _startNewStructure() {
    _resetComponentEditor(silent: true);
    _selectedStructureKey = null;
    _showDraftStructureTile = true;
    _structureEffectiveFromController.clear();
    _structureBasicSalaryController.clear();
    _structureGrossSalaryController.clear();
    _structureNetSalaryController.clear();
    _structureIsActive = true;
    _structureFormError = null;
    setState(() {});
  }

  void _selectStructure(_EmployeeSalaryStructureDraft draft) {
    _showDraftStructureTile = false;
    _selectedStructureKey = draft.key;
    _structureEffectiveFromController.text = draft.effectiveFrom;
    _structureBasicSalaryController.text = draft.basicSalary;
    _structureGrossSalaryController.text = draft.grossSalary;
    _structureNetSalaryController.text = draft.netSalary;
    _structureIsActive = draft.isActive;
    _structureFormError = null;
    _resetComponentEditor(silent: true);
    setState(() {});
  }

  Future<void> _saveStructure() async {
    final effectiveFrom = _structureEffectiveFromController.text.trim();
    if (effectiveFrom.isEmpty) {
      setState(() => _structureFormError = 'Effective From is required.');
      return;
    }
    if (Validators.date('Effective From')(effectiveFrom) != null) {
      setState(
        () => _structureFormError = 'Effective From must be a valid date.',
      );
      return;
    }

    final draft = _EmployeeSalaryStructureDraft(
      key: _selectedStructureKey ?? _nextDraftKey(),
      id: _salaryStructures
          .where((item) => item.key == _selectedStructureKey)
          .firstOrNull
          ?.id,
      effectiveFrom: effectiveFrom,
      basicSalary: _structureBasicSalaryController.text.trim(),
      grossSalary: _structureGrossSalaryController.text.trim(),
      netSalary: _structureNetSalaryController.text.trim(),
      isActive: _structureIsActive,
      components: _selectedStructureKey == null
          ? <_EmployeeSalaryComponentDraft>[]
          : _salaryStructures
                    .where((item) => item.key == _selectedStructureKey)
                    .firstOrNull
                    ?.components
                    .map((item) => item.copy())
                    .toList(growable: true) ??
                <_EmployeeSalaryComponentDraft>[],
    );

    setState(() {
      final next = List<_EmployeeSalaryStructureDraft>.from(_salaryStructures);
      final index = next.indexWhere((item) => item.key == draft.key);
      if (index >= 0) {
        next[index] = draft;
      } else {
        next.insert(0, draft);
      }
      _salaryStructures = next;
    });
    _resetStructureEditor();
    await _persistSalaryData('Employee salary structure saved successfully.');
  }

  Future<void> _removeStructure(_EmployeeSalaryStructureDraft draft) async {
    setState(() {
      _salaryStructures = _salaryStructures
          .where((item) => item.key != draft.key)
          .toList();
      if (_selectedStructureKey == draft.key) {
        _resetStructureEditor(silent: true);
      }
      if (_selectedComponentParentKey == draft.key) {
        _resetComponentEditor(silent: true);
      }
    });
    await _persistSalaryData('Employee salary structure removed successfully.');
  }

  void _resetComponentEditor({bool silent = false}) {
    _showDraftComponentTile = false;
    _selectedComponentKey = null;
    _selectedComponentParentKey = null;
    _componentNameController.clear();
    _componentAmountController.clear();
    _componentType = 'earning';
    _componentFormError = null;
    if (!silent && mounted) {
      setState(() {});
    }
  }

  void _startNewComponent() {
    _selectedComponentKey = null;
    _showDraftComponentTile = true;
    _selectedComponentParentKey = _salaryStructures.firstOrNull?.key;
    _componentNameController.clear();
    _componentAmountController.clear();
    _componentType = 'earning';
    _componentFormError = null;
    setState(() {});
  }

  void _selectComponent(
    _EmployeeSalaryStructureDraft parent,
    _EmployeeSalaryComponentDraft component,
  ) {
    _showDraftComponentTile = false;
    _selectedComponentParentKey = parent.key;
    _selectedComponentKey = component.key;
    _componentNameController.text = component.componentName;
    _componentAmountController.text = component.amount;
    _componentType = component.componentType;
    _componentFormError = null;
    setState(() {});
  }

  Future<void> _saveComponent() async {
    if (_selectedComponentParentKey == null) {
      setState(() => _componentFormError = 'Salary Structure is required.');
      return;
    }
    if (_componentNameController.text.trim().isEmpty) {
      setState(() => _componentFormError = 'Component Name is required.');
      return;
    }
    final amountText = _componentAmountController.text.trim();
    if (amountText.isEmpty ||
        double.tryParse(amountText) == null ||
        (double.tryParse(amountText) ?? 0) < 0) {
      setState(() => _componentFormError = 'Amount must be a valid number.');
      return;
    }

    final parentIndex = _salaryStructures.indexWhere(
      (item) => item.key == _selectedComponentParentKey,
    );
    if (parentIndex < 0) {
      setState(
        () => _componentFormError = 'Selected salary structure not found.',
      );
      return;
    }

    final nextStructures = List<_EmployeeSalaryStructureDraft>.from(
      _salaryStructures,
    );
    final parent = nextStructures[parentIndex];
    final nextComponents = List<_EmployeeSalaryComponentDraft>.from(
      parent.components,
    );
    final draft = _EmployeeSalaryComponentDraft(
      key: _selectedComponentKey ?? _nextDraftKey(),
      id: nextComponents
          .where((item) => item.key == _selectedComponentKey)
          .firstOrNull
          ?.id,
      componentName: _componentNameController.text.trim(),
      componentType: _componentType,
      amount: amountText,
    );
    final componentIndex = nextComponents.indexWhere(
      (item) => item.key == draft.key,
    );
    if (componentIndex >= 0) {
      nextComponents[componentIndex] = draft;
    } else {
      nextComponents.insert(0, draft);
    }

    nextStructures[parentIndex] = parent.copyWith(components: nextComponents);
    setState(() {
      _salaryStructures = nextStructures;
    });
    _resetComponentEditor();
    await _persistSalaryData('Employee salary component saved successfully.');
  }

  Future<void> _removeComponent(
    _EmployeeSalaryStructureDraft parent,
    _EmployeeSalaryComponentDraft component,
  ) async {
    final parentIndex = _salaryStructures.indexWhere(
      (item) => item.key == parent.key,
    );
    if (parentIndex < 0) {
      return;
    }

    final nextStructures = List<_EmployeeSalaryStructureDraft>.from(
      _salaryStructures,
    );
    final nextComponents = List<_EmployeeSalaryComponentDraft>.from(
      nextStructures[parentIndex].components,
    )..removeWhere((item) => item.key == component.key);

    nextStructures[parentIndex] = nextStructures[parentIndex].copyWith(
      components: nextComponents,
    );
    setState(() {
      _salaryStructures = nextStructures;
      if (_selectedComponentKey == component.key) {
        _resetComponentEditor(silent: true);
      }
    });
    await _persistSalaryData('Employee salary component removed successfully.');
  }

  Future<void> _openCreateDepartmentDialog() async {
    final nameController = TextEditingController();
    var isActive = true;
    String? errorText;

    final created = await showDialog<DepartmentModel>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Department'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppFormTextField(
                    controller: nameController,
                    labelText: 'Department Name',
                  ),
                  const SizedBox(height: AppUiConstants.spacingSm),
                  AppSwitchTile(
                    label: 'Active',
                    value: isActive,
                    onChanged: (value) =>
                        setDialogState(() => isActive = value),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: AppUiConstants.spacingSm),
                    Text(
                      errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      setDialogState(() {
                        errorText = 'Department Name is required.';
                      });
                      return;
                    }
                    try {
                      final response = await _hrService.createDepartment(
                        DepartmentModel(
                          departmentName: name,
                          isActive: isActive,
                        ),
                      );
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop(response.data);
                    } catch (error) {
                      setDialogState(() {
                        errorText = error.toString();
                      });
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created?.id == null || !mounted) {
      return;
    }

    final refreshed = await _hrService.departments(
      filters: const {'per_page': 200, 'sort_by': 'department_name'},
    );
    if (!mounted) return;
    final createdDepartment = created!;
    setState(() {
      _departments = refreshed.data ?? <DepartmentModel>[createdDepartment];
      _departmentId = createdDepartment.id;
    });
  }

  Future<void> _openCreateDesignationDialog() async {
    final nameController = TextEditingController();
    var isActive = true;
    String? errorText;

    final created = await showDialog<DesignationModel>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Designation'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppFormTextField(
                    controller: nameController,
                    labelText: 'Designation Name',
                  ),
                  const SizedBox(height: AppUiConstants.spacingSm),
                  AppSwitchTile(
                    label: 'Active',
                    value: isActive,
                    onChanged: (value) =>
                        setDialogState(() => isActive = value),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: AppUiConstants.spacingSm),
                    Text(
                      errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      setDialogState(() {
                        errorText = 'Designation Name is required.';
                      });
                      return;
                    }
                    try {
                      final response = await _hrService.createDesignation(
                        DesignationModel(
                          designationName: name,
                          isActive: isActive,
                        ),
                      );
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop(response.data);
                    } catch (error) {
                      setDialogState(() {
                        errorText = error.toString();
                      });
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created?.id == null || !mounted) {
      return;
    }

    final refreshed = await _hrService.designations(
      filters: const {'per_page': 200, 'sort_by': 'designation_name'},
    );
    if (!mounted) return;
    final createdDesignation = created!;
    setState(() {
      _designations = refreshed.data ?? <DesignationModel>[createdDesignation];
      _designationId = createdDesignation.id;
    });
  }

  Future<void> _uploadEmployeePhoto() async {
    await MediaUploadHelper.uploadImage(
      context: context,
      mediaService: _mediaService,
      onLoading: (isLoading) {
        if (mounted) {
          setState(() => _uploadingPhoto = isLoading);
        }
      },
      onSuccess: (filePath) {
        if (mounted) {
          setState(() {
            _profilePhotoController.text = filePath;
            _formError = null;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _formError = error);
        }
      },
      module: 'hr',
      documentType: 'employees',
      documentId: _selectedEmployee?.id,
      purpose: 'profile_photo',
      folder: 'hr/employees',
      isPublic: true,
    );
  }

  void _startNew() {
    _resetForm();
    if (!Responsive.isDesktop(context)) {
      _workspaceController.openEditor();
    }
  }

  List<CompanyModel> get _activeCompanies =>
      _companies.where((item) => item.isActive).toList(growable: false);

  List<CostCenterModel> get _companyCostCenters {
    return _costCenters
        .where((item) {
          return _companyId == null ||
              item.companyId == null ||
              item.companyId == _companyId;
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _startNew,
        icon: Icons.person_add_alt_1_outlined,
        label: 'New Employee',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Employees',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading employees...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load employees',
        message: _pageError!,
        onRetry: _loadData,
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Employees',
      editorTitle: _selectedEmployee?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<EmployeeModel>(
        searchController: _searchController,
        searchHint: 'Search employees',
        items: _filteredEmployees,
        selectedItem: _selectedEmployee,
        emptyMessage: 'No employees found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.employeeName ?? '-',
          subtitle: [
            item.employeeCode ?? '',
            item.departmentName ?? '',
            item.designationName ?? '',
          ].where((value) => value.isNotEmpty).join(' · '),
          detail: item.mobile ?? item.email ?? '',
          selected: selected,
          onTap: () => _selectEmployee(item),
        ),
      ),
      editor: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Primary'),
              Tab(text: 'Employee Accounts'),
              Tab(text: 'Salary Structures'),
              Tab(text: 'Salary Components'),
            ],
          ),
          const SizedBox(height: AppUiConstants.spacingLg),
          IndexedStack(
            index: _activeTabIndex,
            children: [
              _buildPrimaryTab(),
              _buildSaveFirstTabMessage(
                tabLabel: 'Employee Accounts',
                child: _buildAccountsTab(),
              ),
              _buildSaveFirstTabMessage(
                tabLabel: 'Employee Salary Structures',
                child: _buildSalaryStructuresTab(),
              ),
              _buildSaveFirstTabMessage(
                tabLabel: 'Employee Salary Components',
                child: _buildSalaryComponentsTab(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveFirstTabMessage({
    required String tabLabel,
    required Widget child,
  }) {
    if (_selectedEmployee?.id == null) {
      return SettingsEmptyState(
        icon: Icons.save_outlined,
        title: 'Save Employee First',
        message: 'Save the employee in Primary before opening $tabLabel.',
        minHeight: 220,
      );
    }
    return child;
  }

  Widget _buildPrimaryTab() {
    return Form(
      key: _primaryFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_formError != null) ...[
            AppErrorStateView.inline(message: _formError!),
            const SizedBox(height: AppUiConstants.spacingSm),
          ],
          SettingsFormWrap(
            children: [
              AppDropdownField<int>.fromMapped(
                labelText: 'Company',
                mappedItems: _activeCompanies
                    .where((item) => item.id != null)
                    .map(
                      (item) => AppDropdownItem(
                        value: item.id!,
                        label: item.toString(),
                      ),
                    )
                    .toList(growable: false),
                initialValue: _companyId,
                onChanged: (value) {
                  setState(() {
                    _companyId = value;
                    _costCenterId = null;
                  });
                  _refreshEmployeeCode();
                },
                validator: Validators.requiredSelection('Company'),
              ),
              AppFormTextField(
                controller: _employeeCodeController,
                labelText: 'Employee Code',
                readOnly: true,
                validator: Validators.compose([
                  Validators.required('Employee Code'),
                  Validators.optionalMaxLength(50, 'Employee Code'),
                ]),
              ),
              AppFormTextField(
                controller: _employeeNameController,
                labelText: 'Employee Name',
                validator: Validators.compose([
                  Validators.required('Employee Name'),
                  Validators.optionalMaxLength(255, 'Employee Name'),
                ]),
              ),
              InlineFieldAction(
                actionTooltip: 'Create department',
                onAddNew: _openCreateDepartmentDialog,
                field: AppDropdownField<int>.fromMapped(
                  labelText: 'Department',
                  mappedItems: _departments
                      .where((item) => item.id != null && item.isActive)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _departmentId,
                  onChanged: (value) => setState(() => _departmentId = value),
                ),
              ),
              InlineFieldAction(
                actionTooltip: 'Create designation',
                onAddNew: _openCreateDesignationDialog,
                field: AppDropdownField<int>.fromMapped(
                  labelText: 'Designation',
                  mappedItems: _designations
                      .where((item) => item.id != null && item.isActive)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _designationId,
                  onChanged: (value) => setState(() => _designationId = value),
                ),
              ),
              AppFormTextField(
                controller: _mobileController,
                labelText: 'Mobile',
                validator: Validators.optionalMaxLength(50, 'Mobile'),
              ),
              AppFormTextField(
                controller: _emailController,
                labelText: 'Email',
                validator: Validators.compose([
                  Validators.optionalEmail(fieldName: 'Email'),
                  Validators.optionalMaxLength(255, 'Email'),
                ]),
              ),
              AppFormTextField(
                controller: _joiningDateController,
                labelText: 'Joining Date',
                keyboardType: TextInputType.datetime,
                inputFormatters: const [DateInputFormatter()],
                validator: Validators.optionalDate('Joining Date'),
              ),
              AppFormTextField(
                controller: _relievingDateController,
                labelText: 'Relieving Date',
                keyboardType: TextInputType.datetime,
                inputFormatters: const [DateInputFormatter()],
                validator: Validators.compose([
                  Validators.optionalDate('Relieving Date'),
                  Validators.optionalDateOnOrAfter(
                    'Relieving Date',
                    () => _joiningDateController.text.trim(),
                    startFieldName: 'Joining Date',
                  ),
                ]),
              ),
              AppDropdownField<String>.fromMapped(
                labelText: 'Employment Type',
                mappedItems: _employmentTypeItems,
                initialValue: _employmentType,
                onChanged: (value) =>
                    setState(() => _employmentType = value ?? 'permanent'),
              ),
              AppDropdownField<String>.fromMapped(
                labelText: 'Status',
                mappedItems: _statusItems,
                initialValue: _status,
                onChanged: (value) =>
                    setState(() => _status = value ?? 'active'),
              ),
              AppDropdownField<String>.fromMapped(
                labelText: 'Salary Mode',
                mappedItems: _salaryModeItems,
                initialValue: _salaryMode,
                onChanged: (value) =>
                    setState(() => _salaryMode = value ?? 'monthly'),
              ),
              AppDropdownField<int>.fromMapped(
                labelText: 'Cost Center',
                mappedItems: _companyCostCenters
                    .where((item) => item.id != null)
                    .map(
                      (item) => AppDropdownItem(
                        value: item.id!,
                        label: item.toString(),
                      ),
                    )
                    .toList(growable: false),
                initialValue: _costCenterId,
                onChanged: (value) => setState(() => _costCenterId = value),
              ),
              AppFormTextField(
                controller: _bankAccountNoController,
                labelText: 'Bank Account No',
                validator: Validators.optionalMaxLength(100, 'Bank Account No'),
              ),
              AppFormTextField(
                controller: _ifscCodeController,
                labelText: 'IFSC Code',
                validator: Validators.optionalMaxLength(50, 'IFSC Code'),
              ),
              UploadPathField(
                controller: _profilePhotoController,
                labelText: 'Profile Photo Path',
                isUploading: _uploadingPhoto,
                onUpload: _uploadEmployeePhoto,
                previewUrl: AppConfig.resolvePublicFileUrl(
                  _profilePhotoController.text,
                ),
                previewIcon: Icons.person_outline,
              ),
            ],
          ),
          const SizedBox(height: AppUiConstants.spacingLg),
          Wrap(
            spacing: AppUiConstants.spacingSm,
            runSpacing: AppUiConstants.spacingSm,
            children: [
              AppActionButton(
                icon: Icons.save_outlined,
                label: _selectedEmployee == null
                    ? 'Save Employee'
                    : 'Update Employee',
                onPressed: _savePrimary,
                busy: _saving,
              ),
              if (_selectedEmployee?.id != null)
                AppActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  onPressed: _deleteEmployee,
                  busy: _saving,
                  filled: false,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsTab() {
    if (_employeeAccounts.isEmpty) {
      return const SettingsEmptyState(
        icon: Icons.account_balance_outlined,
        title: 'No Employee Accounts',
        message:
            'Employee ledgers will appear here after the employee is saved.',
        minHeight: 180,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'These accounts are generated by the backend from the employee profile.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppUiConstants.spacingMd),
        ..._employeeAccounts.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
            child: SettingsExpandableTile(
              title: item.accountName ?? item.accountCode ?? '-',
              subtitle: [
                item.accountPurpose ?? '',
                item.accountCode ?? '',
              ].where((value) => value.isNotEmpty).join(' • '),
              detail: [
                if (item.isDefault) 'Default',
                if (item.isActive) 'Active',
              ].join(' • '),
              expanded: false,
              onToggle: () {},
              child: SettingsFormWrap(
                children: [
                  AppFormTextField(
                    labelText: 'Account Purpose',
                    initialValue: item.accountPurpose ?? '',
                    readOnly: true,
                  ),
                  AppFormTextField(
                    labelText: 'Account Code',
                    initialValue: item.accountCode ?? '',
                    readOnly: true,
                  ),
                  AppFormTextField(
                    labelText: 'Account Name',
                    initialValue: item.accountName ?? '',
                    readOnly: true,
                  ),
                  AppFormTextField(
                    labelText: 'Purpose',
                    initialValue: item.accountPurpose ?? '',
                    readOnly: true,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSalaryStructuresTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppActionButton(
              onPressed: _saving ? null : _startNewStructure,
              icon: Icons.add_outlined,
              label: 'New Salary Structure',
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingMd),
        if ((_structureFormError ?? '').isNotEmpty) ...[
          AppErrorStateView.inline(message: _structureFormError!),
          const SizedBox(height: AppUiConstants.spacingSm),
        ],
        if (_salaryStructures.isEmpty && !_showDraftStructureTile)
          const SettingsEmptyState(
            icon: Icons.payments_outlined,
            title: 'No Salary Structures',
            message: 'Add a salary structure for this employee.',
            minHeight: 180,
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showDraftStructureTile) ...[
                SettingsExpandableTile(
                  key: const ValueKey('employee-structure-draft'),
                  title: 'New Salary Structure',
                  subtitle: 'Create salary structure for this employee.',
                  expanded: true,
                  highlighted: true,
                  leadingIcon: Icons.add_outlined,
                  onToggle: _resetStructureEditor,
                  child: _buildStructureEditor(),
                ),
                if (_salaryStructures.isNotEmpty)
                  const SizedBox(height: AppUiConstants.spacingSm),
              ],
              ..._salaryStructures.map((item) {
                final expanded = item.key == _selectedStructureKey;
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppUiConstants.spacingSm,
                  ),
                  child: SettingsExpandableTile(
                    key: ValueKey('employee-structure-${item.key}-$expanded'),
                    title: item.effectiveFrom.isNotEmpty
                        ? item.effectiveFrom
                        : 'Salary Structure',
                    subtitle: [
                      if (item.basicSalary.isNotEmpty)
                        'Basic ${item.basicSalary}',
                      if (item.grossSalary.isNotEmpty)
                        'Gross ${item.grossSalary}',
                      if (item.netSalary.isNotEmpty) 'Net ${item.netSalary}',
                    ].join(' • '),
                    detail: [
                      '${item.components.length} Components',
                      if (item.isActive) 'Active',
                    ].join(' • '),
                    expanded: expanded,
                    highlighted: expanded,
                    onToggle: () {
                      if (expanded) {
                        _resetStructureEditor();
                      } else {
                        _selectStructure(item);
                      }
                    },
                    child: _buildStructureEditor(current: item),
                  ),
                );
              }),
            ],
          ),
      ],
    );
  }

  Widget _buildStructureEditor({_EmployeeSalaryStructureDraft? current}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsFormWrap(
          children: [
            AppFormTextField(
              controller: _structureEffectiveFromController,
              labelText: 'Effective From',
              keyboardType: TextInputType.datetime,
              inputFormatters: const [DateInputFormatter()],
            ),
            AppFormTextField(
              controller: _structureBasicSalaryController,
              labelText: 'Basic Salary',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: Validators.optionalNonNegativeNumber('Basic Salary'),
            ),
            AppFormTextField(
              controller: _structureGrossSalaryController,
              labelText: 'Gross Salary',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: Validators.optionalNonNegativeNumber('Gross Salary'),
            ),
            AppFormTextField(
              controller: _structureNetSalaryController,
              labelText: 'Net Salary',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: Validators.optionalNonNegativeNumber('Net Salary'),
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingMd),
        AppSwitchTile(
          label: 'Active',
          value: _structureIsActive,
          onChanged: (value) => setState(() => _structureIsActive = value),
        ),
        const SizedBox(height: AppUiConstants.spacingMd),
        Wrap(
          spacing: AppUiConstants.spacingSm,
          runSpacing: AppUiConstants.spacingSm,
          children: [
            AppActionButton(
              icon: Icons.save_outlined,
              label: current == null
                  ? 'Save Salary Structure'
                  : 'Update Salary Structure',
              onPressed: _saveStructure,
              busy: _saving,
            ),
            if (current != null)
              AppActionButton(
                icon: Icons.remove_circle_outline,
                label: 'Remove',
                onPressed: () => _removeStructure(current),
                busy: _saving,
                filled: false,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSalaryComponentsTab() {
    if (_salaryStructures.isEmpty) {
      return const SettingsEmptyState(
        icon: Icons.functions_outlined,
        title: 'Add Salary Structure First',
        message:
            'Create at least one salary structure before adding salary components.',
        minHeight: 180,
      );
    }

    final componentItems = <_ComponentEntry>[];
    for (final structure in _salaryStructures) {
      for (final component in structure.components) {
        componentItems.add(
          _ComponentEntry(structure: structure, component: component),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppActionButton(
              onPressed: _saving ? null : _startNewComponent,
              icon: Icons.add_outlined,
              label: 'New Salary Component',
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingMd),
        if ((_componentFormError ?? '').isNotEmpty) ...[
          AppErrorStateView.inline(message: _componentFormError!),
          const SizedBox(height: AppUiConstants.spacingSm),
        ],
        if (componentItems.isEmpty && !_showDraftComponentTile)
          const SettingsEmptyState(
            icon: Icons.functions_outlined,
            title: 'No Salary Components',
            message: 'Add earning or deduction components for this employee.',
            minHeight: 180,
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showDraftComponentTile) ...[
                SettingsExpandableTile(
                  key: const ValueKey('employee-component-draft'),
                  title: 'New Salary Component',
                  subtitle: 'Create a component under a salary structure.',
                  expanded: true,
                  highlighted: true,
                  leadingIcon: Icons.add_outlined,
                  onToggle: _resetComponentEditor,
                  child: _buildComponentEditor(),
                ),
                if (componentItems.isNotEmpty)
                  const SizedBox(height: AppUiConstants.spacingSm),
              ],
              ...componentItems.map((item) {
                final expanded = item.component.key == _selectedComponentKey;
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppUiConstants.spacingSm,
                  ),
                  child: SettingsExpandableTile(
                    key: ValueKey(
                      'employee-component-${item.component.key}-$expanded',
                    ),
                    title: item.component.componentName,
                    subtitle: [
                      item.structure.effectiveFrom,
                      item.component.componentType,
                    ].where((value) => value.isNotEmpty).join(' • '),
                    detail: item.component.amount,
                    expanded: expanded,
                    highlighted: expanded,
                    onToggle: () {
                      if (expanded) {
                        _resetComponentEditor();
                      } else {
                        _selectComponent(item.structure, item.component);
                      }
                    },
                    child: _buildComponentEditor(
                      currentParent: item.structure,
                      current: item.component,
                    ),
                  ),
                );
              }),
            ],
          ),
      ],
    );
  }

  Widget _buildComponentEditor({
    _EmployeeSalaryStructureDraft? currentParent,
    _EmployeeSalaryComponentDraft? current,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsFormWrap(
          children: [
            AppDropdownField<int>.fromMapped(
              labelText: 'Salary Structure',
              mappedItems: _salaryStructures
                  .map(
                    (item) => AppDropdownItem(
                      value: item.key,
                      label: item.effectiveFrom.isNotEmpty
                          ? item.effectiveFrom
                          : 'Salary Structure',
                    ),
                  )
                  .toList(growable: false),
              initialValue: _selectedComponentParentKey,
              onChanged: (value) =>
                  setState(() => _selectedComponentParentKey = value),
              validator: Validators.requiredSelection('Salary Structure'),
            ),
            AppFormTextField(
              controller: _componentNameController,
              labelText: 'Component Name',
              validator: Validators.compose([
                Validators.required('Component Name'),
                Validators.optionalMaxLength(100, 'Component Name'),
              ]),
            ),
            AppDropdownField<String>.fromMapped(
              labelText: 'Component Type',
              mappedItems: _componentTypeItems,
              initialValue: _componentType,
              onChanged: (value) =>
                  setState(() => _componentType = value ?? 'earning'),
            ),
            AppFormTextField(
              controller: _componentAmountController,
              labelText: 'Amount',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: Validators.compose([
                Validators.required('Amount'),
                Validators.optionalNonNegativeNumber('Amount'),
              ]),
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
              label: current == null
                  ? 'Save Salary Component'
                  : 'Update Salary Component',
              onPressed: _saveComponent,
              busy: _saving,
            ),
            if (current != null && currentParent != null)
              AppActionButton(
                icon: Icons.remove_circle_outline,
                label: 'Remove',
                onPressed: () => _removeComponent(currentParent, current),
                busy: _saving,
                filled: false,
              ),
          ],
        ),
      ],
    );
  }
}

class _EmployeeSalaryStructureDraft {
  _EmployeeSalaryStructureDraft({
    required this.key,
    this.id,
    required this.effectiveFrom,
    required this.basicSalary,
    required this.grossSalary,
    required this.netSalary,
    required this.isActive,
    required this.components,
  });

  final int key;
  final int? id;
  final String effectiveFrom;
  final String basicSalary;
  final String grossSalary;
  final String netSalary;
  final bool isActive;
  final List<_EmployeeSalaryComponentDraft> components;

  _EmployeeSalaryStructureDraft copyWith({
    int? key,
    int? id,
    String? effectiveFrom,
    String? basicSalary,
    String? grossSalary,
    String? netSalary,
    bool? isActive,
    List<_EmployeeSalaryComponentDraft>? components,
  }) {
    return _EmployeeSalaryStructureDraft(
      key: key ?? this.key,
      id: id ?? this.id,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      basicSalary: basicSalary ?? this.basicSalary,
      grossSalary: grossSalary ?? this.grossSalary,
      netSalary: netSalary ?? this.netSalary,
      isActive: isActive ?? this.isActive,
      components: components ?? this.components,
    );
  }

  EmployeeSalaryStructureModel toModel({int? employeeId}) {
    return EmployeeSalaryStructureModel(
      id: id,
      employeeId: employeeId,
      effectiveFrom: effectiveFrom,
      basicSalary: double.tryParse(basicSalary),
      grossSalary: double.tryParse(grossSalary),
      netSalary: double.tryParse(netSalary),
      isActive: isActive,
      components: components
          .map((item) => item.toModel())
          .toList(growable: false),
    );
  }
}

class _EmployeeSalaryComponentDraft {
  _EmployeeSalaryComponentDraft({
    required this.key,
    this.id,
    required this.componentName,
    required this.componentType,
    required this.amount,
  });

  final int key;
  final int? id;
  final String componentName;
  final String componentType;
  final String amount;

  _EmployeeSalaryComponentDraft copy() {
    return _EmployeeSalaryComponentDraft(
      key: key,
      id: id,
      componentName: componentName,
      componentType: componentType,
      amount: amount,
    );
  }

  EmployeeSalaryComponentModel toModel() {
    return EmployeeSalaryComponentModel(
      id: id,
      componentName: componentName,
      componentType: componentType,
      amount: double.tryParse(amount),
    );
  }
}

class _ComponentEntry {
  const _ComponentEntry({required this.structure, required this.component});

  final _EmployeeSalaryStructureDraft structure;
  final _EmployeeSalaryComponentDraft component;
}

String _decimalText(double? value) {
  if (value == null) {
    return '';
  }
  return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
}
