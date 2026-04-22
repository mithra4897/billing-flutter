import '../../screen.dart';
import '../purchase/purchase_support.dart';

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

  static const List<AppDropdownItem<String>> _addressTypeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'present', label: 'Present'),
        AppDropdownItem(value: 'permanent', label: 'Permanent'),
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
  final TextEditingController _esiNoController = TextEditingController();
  final TextEditingController _pfUanNoController = TextEditingController();
  final TextEditingController _pfAccountNoController = TextEditingController();
  final TextEditingController _passportNoController = TextEditingController();
  final TextEditingController _passportIssueDateController =
      TextEditingController();
  final TextEditingController _passportExpiryDateController =
      TextEditingController();
  final TextEditingController _passportPlaceOfIssueController =
      TextEditingController();
  final TextEditingController _personalInsuranceProviderController =
      TextEditingController();
  final TextEditingController _personalInsurancePolicyNoController =
      TextEditingController();
  final TextEditingController _personalInsuranceAmountController =
      TextEditingController();
  final TextEditingController _companyInsuranceProviderController =
      TextEditingController();
  final TextEditingController _companyInsurancePolicyNoController =
      TextEditingController();
  final TextEditingController _companyInsuranceAmountController =
      TextEditingController();

  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _addressLandmarkController =
      TextEditingController();
  final TextEditingController _addressCityController = TextEditingController();
  final TextEditingController _addressStateController = TextEditingController();
  final TextEditingController _addressPostalCodeController =
      TextEditingController();
  final TextEditingController _addressCountryController =
      TextEditingController();
  final TextEditingController _addressPhoneController = TextEditingController();

  final TextEditingController _relationNameController = TextEditingController();
  final TextEditingController _relationAgeController = TextEditingController();
  final TextEditingController _relationPhoneController = TextEditingController();
  final TextEditingController _relationRelationshipController =
      TextEditingController();

  final TextEditingController _structureEffectiveFromController =
      TextEditingController();
  final TextEditingController _structureBasicSalaryController =
      TextEditingController();
  final TextEditingController _structureGrossSalaryController =
      TextEditingController();
  final TextEditingController _structureNetSalaryController =
      TextEditingController();
  final TextEditingController _structureCtcMonthlyController =
      TextEditingController();

  final TextEditingController _componentNameController =
      TextEditingController();
  final TextEditingController _componentAmountController =
      TextEditingController();
  final TextEditingController _componentPercentController =
      TextEditingController();

  late final TabController _tabController;
  int _activeTabIndex = 0;
  bool _initialLoading = true;
  bool _saving = false;
  bool _uploadingPhoto = false;
  bool _showDraftStructureTile = false;
  bool _showDraftComponentTile = false;
  bool _showDraftAddressTile = false;
  bool _showDraftRelationTile = false;
  String? _pageError;
  String? _formError;
  String? _statutoryFormError;
  String? _structureFormError;
  String? _componentFormError;
  String? _addressFormError;
  String? _relationFormError;
  List<EmployeeModel> _employees = const <EmployeeModel>[];
  List<EmployeeModel> _filteredEmployees = const <EmployeeModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<DepartmentModel> _departments = const <DepartmentModel>[];
  List<DesignationModel> _designations = const <DesignationModel>[];
  List<CostCenterModel> _costCenters = const <CostCenterModel>[];
  List<ExpenseClaimModel> _employeeExpenseClaims = const <ExpenseClaimModel>[];
  String? _employeeClaimsLoadError;
  List<_EmployeeAddressDraft> _addresses = <_EmployeeAddressDraft>[];
  List<_EmployeeRelationDraft> _relations = <_EmployeeRelationDraft>[];
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
  String _addressType = 'present';
  int? _selectedAddressKey;
  int? _selectedRelationKey;
  int? _selectedStructureKey;
  bool _structureIsActive = true;
  int? _selectedComponentParentKey;
  int? _selectedComponentKey;
  String _componentType = 'earning';
  String _componentCalculationBasis = 'fixed';
  String _componentContributionRole = 'employee';

  static const List<AppDropdownItem<String>> _componentCalculationItems =
      <AppDropdownItem<String>>[
    AppDropdownItem(value: 'fixed', label: 'Fixed amount'),
    AppDropdownItem(value: 'percent_basic', label: '% of basic'),
    AppDropdownItem(value: 'percent_gross', label: '% of gross'),
    AppDropdownItem(value: 'percent_ctc', label: '% of CTC'),
  ];

  static const List<AppDropdownItem<String>> _contributionRoleItems =
      <AppDropdownItem<String>>[
    AppDropdownItem(value: 'employee', label: 'Employee (payslip)'),
    AppDropdownItem(value: 'employer', label: 'Employer (CTC cost)'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
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
    _esiNoController.dispose();
    _pfUanNoController.dispose();
    _pfAccountNoController.dispose();
    _passportNoController.dispose();
    _passportIssueDateController.dispose();
    _passportExpiryDateController.dispose();
    _passportPlaceOfIssueController.dispose();
    _personalInsuranceProviderController.dispose();
    _personalInsurancePolicyNoController.dispose();
    _personalInsuranceAmountController.dispose();
    _companyInsuranceProviderController.dispose();
    _companyInsurancePolicyNoController.dispose();
    _companyInsuranceAmountController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _addressLandmarkController.dispose();
    _addressCityController.dispose();
    _addressStateController.dispose();
    _addressPostalCodeController.dispose();
    _addressCountryController.dispose();
    _addressPhoneController.dispose();
    _relationNameController.dispose();
    _relationAgeController.dispose();
    _relationPhoneController.dispose();
    _relationRelationshipController.dispose();
    _structureEffectiveFromController.dispose();
    _structureBasicSalaryController.dispose();
    _structureGrossSalaryController.dispose();
    _structureNetSalaryController.dispose();
    _structureCtcMonthlyController.dispose();
    _componentNameController.dispose();
    _componentAmountController.dispose();
    _componentPercentController.dispose();
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
    _esiNoController.text = full.esiNo ?? '';
    _pfUanNoController.text = full.pfUanNo ?? '';
    _pfAccountNoController.text = full.pfAccountNo ?? '';
    _passportNoController.text = full.passportNo ?? '';
    _passportIssueDateController.text = full.passportIssueDate ?? '';
    _passportExpiryDateController.text = full.passportExpiryDate ?? '';
    _passportPlaceOfIssueController.text = full.passportPlaceOfIssue ?? '';
    _personalInsuranceProviderController.text =
        full.personalInsuranceProvider ?? '';
    _personalInsurancePolicyNoController.text =
        full.personalInsurancePolicyNo ?? '';
    _personalInsuranceAmountController.text = _decimalText(
      full.personalInsuranceAmount,
    );
    _companyInsuranceProviderController.text =
        full.companyInsuranceProvider ?? '';
    _companyInsurancePolicyNoController.text =
        full.companyInsurancePolicyNo ?? '';
    _companyInsuranceAmountController.text = _decimalText(
      full.companyInsuranceAmount,
    );
    _costCenterId = full.costCenterId;
    _employeeExpenseClaims = const <ExpenseClaimModel>[];
    _employeeClaimsLoadError = null;
    if (full.companyId != null && employee.id != null) {
      try {
        final claimsPage = await _hrService.expenseClaims(
          filters: <String, dynamic>{
            'company_id': full.companyId!,
            'employee_id': employee.id!,
            'per_page': 100,
          },
        );
        _employeeExpenseClaims =
            claimsPage.data ?? const <ExpenseClaimModel>[];
      } catch (error) {
        _employeeClaimsLoadError = error.toString();
      }
    }
    _addresses = full.addresses
        .map(_employeeAddressDraftFromModel)
        .toList(growable: true);
    _relations = full.relations
        .map(_employeeRelationDraftFromModel)
        .toList(growable: true);
    _salaryStructures =
        (salaryResponse.data ?? const <EmployeeSalaryStructureModel>[])
            .map(_salaryStructureDraftFromModel)
            .toList(growable: true);
    _resetAddressEditor(silent: true);
    _resetRelationEditor(silent: true);
    _resetStructureEditor(silent: true);
    _resetComponentEditor(silent: true);
    _statutoryFormError = null;
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
    _esiNoController.clear();
    _pfUanNoController.clear();
    _pfAccountNoController.clear();
    _passportNoController.clear();
    _passportIssueDateController.clear();
    _passportExpiryDateController.clear();
    _passportPlaceOfIssueController.clear();
    _personalInsuranceProviderController.clear();
    _personalInsurancePolicyNoController.clear();
    _personalInsuranceAmountController.clear();
    _companyInsuranceProviderController.clear();
    _companyInsurancePolicyNoController.clear();
    _companyInsuranceAmountController.clear();
    _costCenterId = null;
    _employeeExpenseClaims = const <ExpenseClaimModel>[];
    _employeeClaimsLoadError = null;
    _addresses = <_EmployeeAddressDraft>[];
    _relations = <_EmployeeRelationDraft>[];
    _salaryStructures = <_EmployeeSalaryStructureDraft>[];
    _resetAddressEditor(silent: true);
    _resetRelationEditor(silent: true);
    _resetStructureEditor(silent: true);
    _resetComponentEditor(silent: true);
    _statutoryFormError = null;
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
      esiNo: nullIfEmpty(_esiNoController.text.trim()),
      pfUanNo: nullIfEmpty(_pfUanNoController.text.trim()),
      pfAccountNo: nullIfEmpty(_pfAccountNoController.text.trim()),
      passportNo: nullIfEmpty(_passportNoController.text.trim()),
      passportIssueDate: nullIfEmpty(_passportIssueDateController.text.trim()),
      passportExpiryDate: nullIfEmpty(
        _passportExpiryDateController.text.trim(),
      ),
      passportPlaceOfIssue: nullIfEmpty(
        _passportPlaceOfIssueController.text.trim(),
      ),
      personalInsuranceProvider: nullIfEmpty(
        _personalInsuranceProviderController.text.trim(),
      ),
      personalInsurancePolicyNo: nullIfEmpty(
        _personalInsurancePolicyNoController.text.trim(),
      ),
      personalInsuranceAmount: double.tryParse(
        _personalInsuranceAmountController.text.trim(),
      ),
      companyInsuranceProvider: nullIfEmpty(
        _companyInsuranceProviderController.text.trim(),
      ),
      companyInsurancePolicyNo: nullIfEmpty(
        _companyInsurancePolicyNoController.text.trim(),
      ),
      companyInsuranceAmount: double.tryParse(
        _companyInsuranceAmountController.text.trim(),
      ),
      costCenterId: _costCenterId,
      addresses: _addresses
          .map((item) => item.toModel(employeeId: _selectedEmployee?.id))
          .toList(growable: false),
      relations: _relations
          .map((item) => item.toModel(employeeId: _selectedEmployee?.id))
          .toList(growable: false),
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

  Future<void> _persistEmployeeDetails({
    required String successMessage,
    required void Function(String message) onError,
  }) async {
    final employee = _selectedEmployee;
    if (employee?.id == null) {
      return;
    }

    setState(() {
      _saving = true;
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
      setState(() => onError(error.toString()));
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

  _EmployeeAddressDraft _employeeAddressDraftFromModel(
    EmployeeAddressModel model,
  ) {
    return _EmployeeAddressDraft(
      key: model.id ?? _nextDraftKey(),
      id: model.id,
      addressType: model.addressType ?? 'present',
      addressLine1: model.addressLine1 ?? '',
      addressLine2: model.addressLine2 ?? '',
      landmark: model.landmark ?? '',
      city: model.city ?? '',
      stateName: model.stateName ?? '',
      postalCode: model.postalCode ?? '',
      country: model.country ?? '',
      phoneNumber: model.phoneNumber ?? '',
    );
  }

  _EmployeeRelationDraft _employeeRelationDraftFromModel(
    EmployeeRelationModel model,
  ) {
    return _EmployeeRelationDraft(
      key: model.id ?? _nextDraftKey(),
      id: model.id,
      relationName: model.relationName ?? '',
      age: model.age?.toString() ?? '',
      phoneNumber: model.phoneNumber ?? '',
      relationship: model.relationship ?? '',
    );
  }

  void _resetAddressEditor({bool silent = false}) {
    _showDraftAddressTile = false;
    _selectedAddressKey = null;
    _addressType = 'present';
    _addressLine1Controller.clear();
    _addressLine2Controller.clear();
    _addressLandmarkController.clear();
    _addressCityController.clear();
    _addressStateController.clear();
    _addressPostalCodeController.clear();
    _addressCountryController.clear();
    _addressPhoneController.clear();
    _addressFormError = null;
    if (!silent && mounted) {
      setState(() {});
    }
  }

  void _startNewAddress() {
    _selectedAddressKey = null;
    _showDraftAddressTile = true;
    _addressType = _addresses.any((item) => item.addressType == 'present')
        ? 'permanent'
        : 'present';
    _addressLine1Controller.clear();
    _addressLine2Controller.clear();
    _addressLandmarkController.clear();
    _addressCityController.clear();
    _addressStateController.clear();
    _addressPostalCodeController.clear();
    _addressCountryController.clear();
    _addressPhoneController.clear();
    _addressFormError = null;
    setState(() {});
  }

  void _selectAddress(_EmployeeAddressDraft draft) {
    _showDraftAddressTile = false;
    _selectedAddressKey = draft.key;
    _addressType = draft.addressType;
    _addressLine1Controller.text = draft.addressLine1;
    _addressLine2Controller.text = draft.addressLine2;
    _addressLandmarkController.text = draft.landmark;
    _addressCityController.text = draft.city;
    _addressStateController.text = draft.stateName;
    _addressPostalCodeController.text = draft.postalCode;
    _addressCountryController.text = draft.country;
    _addressPhoneController.text = draft.phoneNumber;
    _addressFormError = null;
    setState(() {});
  }

  Future<void> _saveAddress() async {
    if (_addressLine1Controller.text.trim().isEmpty) {
      setState(() => _addressFormError = 'Address Line 1 is required.');
      return;
    }

    final draft = _EmployeeAddressDraft(
      key: _selectedAddressKey ?? _nextDraftKey(),
      id: _addresses
          .where((item) => item.key == _selectedAddressKey)
          .firstOrNull
          ?.id,
      addressType: _addressType,
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim(),
      landmark: _addressLandmarkController.text.trim(),
      city: _addressCityController.text.trim(),
      stateName: _addressStateController.text.trim(),
      postalCode: _addressPostalCodeController.text.trim(),
      country: _addressCountryController.text.trim(),
      phoneNumber: _addressPhoneController.text.trim(),
    );

    setState(() {
      var next = List<_EmployeeAddressDraft>.from(_addresses)
        ..removeWhere((item) => item.addressType == draft.addressType);
      final index = next.indexWhere((item) => item.key == draft.key);
      if (index >= 0) {
        next[index] = draft;
      } else {
        next.insert(0, draft);
      }
      _addresses = next;
    });
    _resetAddressEditor();
    await _persistEmployeeDetails(
      successMessage: 'Employee address saved successfully.',
      onError: (message) => _addressFormError = message,
    );
  }

  Future<void> _removeAddress(_EmployeeAddressDraft draft) async {
    setState(() {
      _addresses = _addresses.where((item) => item.key != draft.key).toList();
      if (_selectedAddressKey == draft.key) {
        _resetAddressEditor(silent: true);
      }
    });
    await _persistEmployeeDetails(
      successMessage: 'Employee address removed successfully.',
      onError: (message) => _addressFormError = message,
    );
  }

  void _resetRelationEditor({bool silent = false}) {
    _showDraftRelationTile = false;
    _selectedRelationKey = null;
    _relationNameController.clear();
    _relationAgeController.clear();
    _relationPhoneController.clear();
    _relationRelationshipController.clear();
    _relationFormError = null;
    if (!silent && mounted) {
      setState(() {});
    }
  }

  void _startNewRelation() {
    _selectedRelationKey = null;
    _showDraftRelationTile = true;
    _relationNameController.clear();
    _relationAgeController.clear();
    _relationPhoneController.clear();
    _relationRelationshipController.clear();
    _relationFormError = null;
    setState(() {});
  }

  void _selectRelation(_EmployeeRelationDraft draft) {
    _showDraftRelationTile = false;
    _selectedRelationKey = draft.key;
    _relationNameController.text = draft.relationName;
    _relationAgeController.text = draft.age;
    _relationPhoneController.text = draft.phoneNumber;
    _relationRelationshipController.text = draft.relationship;
    _relationFormError = null;
    setState(() {});
  }

  Future<void> _saveRelation() async {
    if (_relationNameController.text.trim().isEmpty) {
      setState(() => _relationFormError = 'Relation Name is required.');
      return;
    }
    if (_relationRelationshipController.text.trim().isEmpty) {
      setState(() => _relationFormError = 'Relationship is required.');
      return;
    }
    final ageText = _relationAgeController.text.trim();
    if (ageText.isNotEmpty && int.tryParse(ageText) == null) {
      setState(() => _relationFormError = 'Age must be a valid whole number.');
      return;
    }

    final draft = _EmployeeRelationDraft(
      key: _selectedRelationKey ?? _nextDraftKey(),
      id: _relations
          .where((item) => item.key == _selectedRelationKey)
          .firstOrNull
          ?.id,
      relationName: _relationNameController.text.trim(),
      age: ageText,
      phoneNumber: _relationPhoneController.text.trim(),
      relationship: _relationRelationshipController.text.trim(),
    );

    setState(() {
      final next = List<_EmployeeRelationDraft>.from(_relations);
      final index = next.indexWhere((item) => item.key == draft.key);
      if (index >= 0) {
        next[index] = draft;
      } else {
        next.insert(0, draft);
      }
      _relations = next;
    });
    _resetRelationEditor();
    await _persistEmployeeDetails(
      successMessage: 'Employee relation saved successfully.',
      onError: (message) => _relationFormError = message,
    );
  }

  Future<void> _removeRelation(_EmployeeRelationDraft draft) async {
    setState(() {
      _relations = _relations.where((item) => item.key != draft.key).toList();
      if (_selectedRelationKey == draft.key) {
        _resetRelationEditor(silent: true);
      }
    });
    await _persistEmployeeDetails(
      successMessage: 'Employee relation removed successfully.',
      onError: (message) => _relationFormError = message,
    );
  }

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
      ctcMonthly: _decimalText(model.ctcMonthly),
      isActive: model.isActive,
      components: model.components
          .map(
            (item) => _EmployeeSalaryComponentDraft(
              key: item.id ?? _nextDraftKey(),
              id: item.id,
              componentName: item.componentName ?? '',
              componentType: item.componentType ?? 'earning',
              amount: _decimalText(item.amount),
              calculationBasis: item.calculationBasis ?? 'fixed',
              percentValue: _decimalText(item.percentValue),
              contributionRole: item.contributionRole ?? 'employee',
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
    _structureCtcMonthlyController.clear();
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
    _structureCtcMonthlyController.clear();
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
    _structureCtcMonthlyController.text = draft.ctcMonthly;
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
      ctcMonthly: _structureCtcMonthlyController.text.trim(),
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
    _componentPercentController.clear();
    _componentType = 'earning';
    _componentCalculationBasis = 'fixed';
    _componentContributionRole = 'employee';
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
    _componentPercentController.clear();
    _componentType = 'earning';
    _componentCalculationBasis = 'fixed';
    _componentContributionRole = 'employee';
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
    _componentPercentController.text = component.percentValue;
    _componentType = component.componentType;
    _componentCalculationBasis = component.calculationBasis;
    _componentContributionRole = component.contributionRole;
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
    final percentText = _componentPercentController.text.trim();
    if (_componentCalculationBasis == 'fixed') {
      if (amountText.isEmpty ||
          double.tryParse(amountText) == null ||
          (double.tryParse(amountText) ?? 0) < 0) {
        setState(() => _componentFormError = 'Amount must be a valid number.');
        return;
      }
    } else {
      if (percentText.isEmpty ||
          double.tryParse(percentText) == null ||
          (double.tryParse(percentText) ?? 0) < 0) {
        setState(
          () => _componentFormError = 'Percentage must be a valid number.',
        );
        return;
      }
      if (amountText.isNotEmpty &&
          (double.tryParse(amountText) == null ||
              (double.tryParse(amountText) ?? 0) < 0)) {
        setState(() => _componentFormError = 'Amount must be a valid number.');
        return;
      }
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
      amount: _componentCalculationBasis == 'fixed'
          ? amountText
          : (amountText.isEmpty ? '0' : amountText),
      calculationBasis: _componentCalculationBasis,
      percentValue:
          _componentCalculationBasis == 'fixed' ? '' : percentText,
      contributionRole: _componentContributionRole,
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
              Tab(text: 'Statutory'),
              Tab(text: 'Addresses'),
              Tab(text: 'Relations'),
              Tab(text: 'Claims & pay'),
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
                tabLabel: 'Employee Statutory & Insurance',
                child: _buildStatutoryTab(),
              ),
              _buildSaveFirstTabMessage(
                tabLabel: 'Employee Addresses',
                child: _buildAddressesTab(),
              ),
              _buildSaveFirstTabMessage(
                tabLabel: 'Employee Relations',
                child: _buildRelationsTab(),
              ),
              _buildSaveFirstTabMessage(
                tabLabel: 'Claims & reimbursements',
                child: _buildExpenseClaimsTab(),
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
                labelText: 'Bank account no. (payout / salary)',
                hintText: 'Employee bank a/c for transfers — not a GL ledger',
                validator: Validators.optionalMaxLength(100, 'Bank Account No'),
              ),
              AppFormTextField(
                controller: _ifscCodeController,
                labelText: 'IFSC code',
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

  Map<String, int> _expenseClaimStatusCounts() {
    final counts = <String, int>{
      'draft': 0,
      'approved_unpaid': 0,
      'reimbursed': 0,
      'other': 0,
    };
    for (final ExpenseClaimModel row in _employeeExpenseClaims) {
      final data = row.toJson();
      final st = stringValue(data, 'claim_status').toLowerCase();
      final reimbId = intValue(data, 'reimbursement_voucher_id');
      if (st == 'draft') {
        counts['draft'] = (counts['draft'] ?? 0) + 1;
      } else if (st == 'approved' && reimbId == null) {
        counts['approved_unpaid'] = (counts['approved_unpaid'] ?? 0) + 1;
      } else if (st == 'reimbursed') {
        counts['reimbursed'] = (counts['reimbursed'] ?? 0) + 1;
      } else {
        counts['other'] = (counts['other'] ?? 0) + 1;
      }
    }
    return counts;
  }

  Widget _buildExpenseClaimsTab() {
    final theme = Theme.of(context);
    if (_employeeClaimsLoadError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppErrorStateView.inline(message: _employeeClaimsLoadError!),
          const SizedBox(height: AppUiConstants.spacingMd),
          Text(
            'Expense claims for this employee could not be loaded. You need '
            'permission to view all HR records (or open Expense claims and '
            'filter by this employee).',
            style: theme.textTheme.bodySmall,
          ),
        ],
      );
    }

    final counts = _expenseClaimStatusCounts();
    if (_employeeExpenseClaims.isEmpty) {
      return SettingsEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No expense claims',
        message:
            'There are no expense claims recorded for this employee in this '
            'company. Salary payables and payslips are handled under Payroll.\n\n'
            'Employee advances or other balances would appear in Accounting when '
            'that module is linked to this employee.',
        minHeight: 200,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expense reimbursements for this employee (from HR). '
          'Draft / submitted claims, approved amounts waiting for payment, and '
          'reimbursed (paid) items are summarized below.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppUiConstants.spacingMd),
        Wrap(
          spacing: AppUiConstants.spacingSm,
          runSpacing: AppUiConstants.spacingSm,
          children: [
            Chip(
              label: Text('Draft: ${counts['draft'] ?? 0}'),
            ),
            Chip(
              label: Text(
                'Approved (unpaid): ${counts['approved_unpaid'] ?? 0}',
              ),
            ),
            Chip(
              label: Text('Reimbursed: ${counts['reimbursed'] ?? 0}'),
            ),
            if ((counts['other'] ?? 0) > 0)
              Chip(
                label: Text('Other: ${counts['other'] ?? 0}'),
              ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingMd),
        ..._employeeExpenseClaims.map((ExpenseClaimModel row) {
          final data = row.toJson();
          final id = intValue(data, 'id');
          final claimNo = stringValue(data, 'claim_no');
          final title = claimNo.isEmpty
              ? (id != null ? 'Claim #$id' : 'Claim')
              : claimNo;
          final date = displayDate(nullableStringValue(data, 'claim_date'));
          final st = stringValue(data, 'claim_status');
          final amount = stringValue(data, 'total_amount');
          final reimbId = intValue(data, 'reimbursement_voucher_id');
          String payHint = '';
          if (st == 'approved' && reimbId == null) {
            payHint = ' · Awaiting reimbursement';
          } else if (st == 'reimbursed') {
            payHint = ' · Paid';
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: AppUiConstants.spacingXs),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(title),
              subtitle: Text(
                [date, st, amount].where((String s) => s.isNotEmpty).join(' · ') +
                    payHint,
              ),
              dense: true,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatutoryTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((_statutoryFormError ?? '').isNotEmpty) ...[
          AppErrorStateView.inline(message: _statutoryFormError!),
          const SizedBox(height: AppUiConstants.spacingSm),
        ],
        SettingsFormWrap(
          children: [
            AppFormTextField(
              controller: _esiNoController,
              labelText: 'ESI Number',
              validator: Validators.optionalMaxLength(100, 'ESI Number'),
            ),
            AppFormTextField(
              controller: _pfUanNoController,
              labelText: 'PF UAN Number',
              validator: Validators.optionalMaxLength(100, 'PF UAN Number'),
            ),
            AppFormTextField(
              controller: _pfAccountNoController,
              labelText: 'PF Account Number',
              validator: Validators.optionalMaxLength(100, 'PF Account Number'),
            ),
            AppFormTextField(
              controller: _passportNoController,
              labelText: 'Passport Number',
              validator: Validators.optionalMaxLength(100, 'Passport Number'),
            ),
            AppFormTextField(
              controller: _passportIssueDateController,
              labelText: 'Passport Issue Date',
              keyboardType: TextInputType.datetime,
              inputFormatters: const [DateInputFormatter()],
              validator: Validators.optionalDate('Passport Issue Date'),
            ),
            AppFormTextField(
              controller: _passportExpiryDateController,
              labelText: 'Passport Expiry Date',
              keyboardType: TextInputType.datetime,
              inputFormatters: const [DateInputFormatter()],
              validator: Validators.optionalDate('Passport Expiry Date'),
            ),
            AppFormTextField(
              controller: _passportPlaceOfIssueController,
              labelText: 'Passport Place of Issue',
              validator: Validators.optionalMaxLength(
                255,
                'Passport Place of Issue',
              ),
            ),
            AppFormTextField(
              controller: _personalInsuranceProviderController,
              labelText: 'Personal Insurance Provider',
              validator: Validators.optionalMaxLength(
                255,
                'Personal Insurance Provider',
              ),
            ),
            AppFormTextField(
              controller: _personalInsurancePolicyNoController,
              labelText: 'Personal Insurance Policy No',
              validator: Validators.optionalMaxLength(
                100,
                'Personal Insurance Policy No',
              ),
            ),
            AppFormTextField(
              controller: _personalInsuranceAmountController,
              labelText: 'Personal Insurance Amount',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.optionalNonNegativeNumber(
                'Personal Insurance Amount',
              ),
            ),
            AppFormTextField(
              controller: _companyInsuranceProviderController,
              labelText: 'Company Insurance Provider',
              validator: Validators.optionalMaxLength(
                255,
                'Company Insurance Provider',
              ),
            ),
            AppFormTextField(
              controller: _companyInsurancePolicyNoController,
              labelText: 'Company Insurance Policy No',
              validator: Validators.optionalMaxLength(
                100,
                'Company Insurance Policy No',
              ),
            ),
            AppFormTextField(
              controller: _companyInsuranceAmountController,
              labelText: 'Company Insurance Amount',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.optionalNonNegativeNumber(
                'Company Insurance Amount',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingMd),
        AppActionButton(
          icon: Icons.save_outlined,
          label: 'Save Statutory Details',
          onPressed: () async {
            setState(() => _statutoryFormError = null);
            final passportIssueDate = _passportIssueDateController.text.trim();
            final passportExpiryDate =
                _passportExpiryDateController.text.trim();
            final issueError = Validators.optionalDate(
              'Passport Issue Date',
            )(passportIssueDate);
            if (issueError != null) {
              setState(() => _statutoryFormError = issueError);
              return;
            }
            final expiryError = Validators.optionalDate(
              'Passport Expiry Date',
            )(passportExpiryDate);
            if (expiryError != null) {
              setState(() => _statutoryFormError = expiryError);
              return;
            }
            await _persistEmployeeDetails(
              successMessage: 'Employee statutory details saved successfully.',
              onError: (message) => _statutoryFormError = message,
            );
          },
          busy: _saving,
        ),
      ],
    );
  }

  Widget _buildAddressesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppActionButton(
          onPressed: _saving ? null : _startNewAddress,
          icon: Icons.add_outlined,
          label: 'New Address',
        ),
        const SizedBox(height: AppUiConstants.spacingMd),
        if ((_addressFormError ?? '').isNotEmpty) ...[
          AppErrorStateView.inline(message: _addressFormError!),
          const SizedBox(height: AppUiConstants.spacingSm),
        ],
        if (_addresses.isEmpty && !_showDraftAddressTile)
          const SettingsEmptyState(
            icon: Icons.home_work_outlined,
            title: 'No Employee Addresses',
            message: 'Add present and permanent address details.',
            minHeight: 180,
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showDraftAddressTile) ...[
                SettingsExpandableTile(
                  key: const ValueKey('employee-address-draft'),
                  title: 'New Address',
                  subtitle: 'Create an employee address record.',
                  expanded: true,
                  highlighted: true,
                  leadingIcon: Icons.add_outlined,
                  onToggle: _resetAddressEditor,
                  child: _buildAddressEditor(),
                ),
                if (_addresses.isNotEmpty)
                  const SizedBox(height: AppUiConstants.spacingSm),
              ],
              ..._addresses.map((item) {
                final expanded = item.key == _selectedAddressKey;
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppUiConstants.spacingSm,
                  ),
                  child: SettingsExpandableTile(
                    key: ValueKey('employee-address-${item.key}-$expanded'),
                    title: item.addressType == 'permanent'
                        ? 'Permanent Address'
                        : 'Present Address',
                    subtitle: [
                      item.addressLine1,
                      item.city,
                      item.stateName,
                    ].where((value) => value.isNotEmpty).join(' • '),
                    detail: item.phoneNumber,
                    expanded: expanded,
                    highlighted: expanded,
                    onToggle: () {
                      if (expanded) {
                        _resetAddressEditor();
                      } else {
                        _selectAddress(item);
                      }
                    },
                    child: _buildAddressEditor(current: item),
                  ),
                );
              }),
            ],
          ),
      ],
    );
  }

  Widget _buildAddressEditor({_EmployeeAddressDraft? current}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsFormWrap(
          children: [
            AppDropdownField<String>.fromMapped(
              labelText: 'Address Type',
              mappedItems: _addressTypeItems,
              initialValue: _addressType,
              onChanged: (value) =>
                  setState(() => _addressType = value ?? _addressType),
            ),
            AppFormTextField(
              controller: _addressLine1Controller,
              labelText: 'Address Line 1',
            ),
            AppFormTextField(
              controller: _addressLine2Controller,
              labelText: 'Address Line 2',
            ),
            AppFormTextField(
              controller: _addressLandmarkController,
              labelText: 'Landmark',
            ),
            AppFormTextField(
              controller: _addressCityController,
              labelText: 'City',
            ),
            AppFormTextField(
              controller: _addressStateController,
              labelText: 'State',
            ),
            AppFormTextField(
              controller: _addressPostalCodeController,
              labelText: 'Postal Code',
            ),
            AppFormTextField(
              controller: _addressCountryController,
              labelText: 'Country',
            ),
            AppFormTextField(
              controller: _addressPhoneController,
              labelText: 'Phone Number',
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
              label: current == null ? 'Save Address' : 'Update Address',
              onPressed: _saveAddress,
              busy: _saving,
            ),
            if (current != null)
              AppActionButton(
                icon: Icons.remove_circle_outline,
                label: 'Remove',
                onPressed: () => _removeAddress(current),
                busy: _saving,
                filled: false,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildRelationsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppActionButton(
          onPressed: _saving ? null : _startNewRelation,
          icon: Icons.add_outlined,
          label: 'New Relation',
        ),
        const SizedBox(height: AppUiConstants.spacingMd),
        if ((_relationFormError ?? '').isNotEmpty) ...[
          AppErrorStateView.inline(message: _relationFormError!),
          const SizedBox(height: AppUiConstants.spacingSm),
        ],
        if (_relations.isEmpty && !_showDraftRelationTile)
          const SettingsEmptyState(
            icon: Icons.family_restroom_outlined,
            title: 'No Employee Relations',
            message: 'Add family or emergency relation details.',
            minHeight: 180,
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showDraftRelationTile) ...[
                SettingsExpandableTile(
                  key: const ValueKey('employee-relation-draft'),
                  title: 'New Relation',
                  subtitle: 'Create an employee relation record.',
                  expanded: true,
                  highlighted: true,
                  leadingIcon: Icons.add_outlined,
                  onToggle: _resetRelationEditor,
                  child: _buildRelationEditor(),
                ),
                if (_relations.isNotEmpty)
                  const SizedBox(height: AppUiConstants.spacingSm),
              ],
              ..._relations.map((item) {
                final expanded = item.key == _selectedRelationKey;
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppUiConstants.spacingSm,
                  ),
                  child: SettingsExpandableTile(
                    key: ValueKey('employee-relation-${item.key}-$expanded'),
                    title: item.relationName.isNotEmpty
                        ? item.relationName
                        : 'Relation',
                    subtitle: [
                      item.relationship,
                      if (item.age.isNotEmpty) 'Age ${item.age}',
                    ].where((value) => value.isNotEmpty).join(' • '),
                    detail: item.phoneNumber,
                    expanded: expanded,
                    highlighted: expanded,
                    onToggle: () {
                      if (expanded) {
                        _resetRelationEditor();
                      } else {
                        _selectRelation(item);
                      }
                    },
                    child: _buildRelationEditor(current: item),
                  ),
                );
              }),
            ],
          ),
      ],
    );
  }

  Widget _buildRelationEditor({_EmployeeRelationDraft? current}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsFormWrap(
          children: [
            AppFormTextField(
              controller: _relationNameController,
              labelText: 'Relation Name',
            ),
            AppFormTextField(
              controller: _relationRelationshipController,
              labelText: 'Relationship',
            ),
            AppFormTextField(
              controller: _relationAgeController,
              labelText: 'Age',
              keyboardType: TextInputType.number,
            ),
            AppFormTextField(
              controller: _relationPhoneController,
              labelText: 'Phone Number',
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
              label: current == null ? 'Save Relation' : 'Update Relation',
              onPressed: _saveRelation,
              busy: _saving,
            ),
            if (current != null)
              AppActionButton(
                icon: Icons.remove_circle_outline,
                label: 'Remove',
                onPressed: () => _removeRelation(current),
                busy: _saving,
                filled: false,
              ),
          ],
        ),
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
                      if (item.ctcMonthly.isNotEmpty) 'CTC ${item.ctcMonthly}',
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
            AppFormTextField(
              controller: _structureCtcMonthlyController,
              labelText: 'CTC (monthly)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: Validators.optionalNonNegativeNumber('CTC (monthly)'),
            ),
            AppSwitchTile(
              label: 'Active',
              value: _structureIsActive,
              onChanged: (value) => setState(() => _structureIsActive = value),
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
                      item.component.contributionRole == 'employer'
                          ? 'Employer'
                          : 'Employee',
                    ].where((value) => value.isNotEmpty).join(' • '),
                    detail: item.component.listDetailLine,
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
            AppDropdownField<String>.fromMapped(
              labelText: 'Calculation',
              mappedItems: _componentCalculationItems,
              initialValue: _componentCalculationBasis,
              onChanged: (value) => setState(() {
                _componentCalculationBasis = value ?? 'fixed';
                if (_componentCalculationBasis == 'fixed') {
                  _componentPercentController.clear();
                }
              }),
            ),
            AppDropdownField<String>.fromMapped(
              labelText: 'Contribution',
              mappedItems: _contributionRoleItems,
              initialValue: _componentContributionRole,
              onChanged: (value) => setState(
                () => _componentContributionRole = value ?? 'employee',
              ),
            ),
            if (_componentCalculationBasis != 'fixed')
              AppFormTextField(
                controller: _componentPercentController,
                labelText: 'Percentage',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.compose([
                  Validators.required('Percentage'),
                  Validators.optionalNonNegativeNumber('Percentage'),
                ]),
              ),
            AppFormTextField(
              controller: _componentAmountController,
              labelText: _componentCalculationBasis == 'fixed'
                  ? 'Amount'
                  : 'Amount (optional; 0 = computed on payroll)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _componentCalculationBasis == 'fixed'
                  ? Validators.compose([
                      Validators.required('Amount'),
                      Validators.optionalNonNegativeNumber('Amount'),
                    ])
                  : Validators.optionalNonNegativeNumber('Amount'),
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
    required this.ctcMonthly,
    required this.isActive,
    required this.components,
  });

  final int key;
  final int? id;
  final String effectiveFrom;
  final String basicSalary;
  final String grossSalary;
  final String netSalary;
  final String ctcMonthly;
  final bool isActive;
  final List<_EmployeeSalaryComponentDraft> components;

  _EmployeeSalaryStructureDraft copyWith({
    int? key,
    int? id,
    String? effectiveFrom,
    String? basicSalary,
    String? grossSalary,
    String? netSalary,
    String? ctcMonthly,
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
      ctcMonthly: ctcMonthly ?? this.ctcMonthly,
      isActive: isActive ?? this.isActive,
      components: components ?? this.components,
    );
  }

  EmployeeSalaryStructureModel toModel({int? employeeId}) {
    final ctc = ctcMonthly.trim();
    return EmployeeSalaryStructureModel(
      id: id,
      employeeId: employeeId,
      effectiveFrom: effectiveFrom,
      basicSalary: double.tryParse(basicSalary),
      grossSalary: double.tryParse(grossSalary),
      netSalary: double.tryParse(netSalary),
      ctcMonthly: ctc.isEmpty ? null : double.tryParse(ctc),
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
    required this.calculationBasis,
    required this.percentValue,
    required this.contributionRole,
  });

  final int key;
  final int? id;
  final String componentName;
  final String componentType;
  final String amount;
  final String calculationBasis;
  final String percentValue;
  final String contributionRole;

  String get listDetailLine {
    if (calculationBasis == 'fixed') {
      return amount;
    }
    final basisLabel = switch (calculationBasis) {
      'percent_basic' => 'basic',
      'percent_gross' => 'gross',
      'percent_ctc' => 'CTC',
      _ => calculationBasis,
    };
    final pct = percentValue;
    final amt = amount.trim();
    final amtPart = amt.isNotEmpty && amt != '0' ? ' • Amt $amt' : '';
    return '$pct% of $basisLabel$amtPart';
  }

  _EmployeeSalaryComponentDraft copy() {
    return _EmployeeSalaryComponentDraft(
      key: key,
      id: id,
      componentName: componentName,
      componentType: componentType,
      amount: amount,
      calculationBasis: calculationBasis,
      percentValue: percentValue,
      contributionRole: contributionRole,
    );
  }

  EmployeeSalaryComponentModel toModel() {
    final pct = percentValue.trim();
    return EmployeeSalaryComponentModel(
      id: id,
      componentName: componentName,
      componentType: componentType,
      amount: double.tryParse(amount),
      calculationBasis: calculationBasis,
      percentValue:
          calculationBasis == 'fixed' || pct.isEmpty ? null : double.tryParse(pct),
      contributionRole: contributionRole,
    );
  }
}

class _EmployeeAddressDraft {
  _EmployeeAddressDraft({
    required this.key,
    this.id,
    required this.addressType,
    required this.addressLine1,
    required this.addressLine2,
    required this.landmark,
    required this.city,
    required this.stateName,
    required this.postalCode,
    required this.country,
    required this.phoneNumber,
  });

  final int key;
  final int? id;
  final String addressType;
  final String addressLine1;
  final String addressLine2;
  final String landmark;
  final String city;
  final String stateName;
  final String postalCode;
  final String country;
  final String phoneNumber;

  EmployeeAddressModel toModel({int? employeeId}) {
    return EmployeeAddressModel(
      id: id,
      employeeId: employeeId,
      addressType: addressType,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      landmark: landmark,
      city: city,
      stateName: stateName,
      postalCode: postalCode,
      country: country,
      phoneNumber: phoneNumber,
    );
  }
}

class _EmployeeRelationDraft {
  _EmployeeRelationDraft({
    required this.key,
    this.id,
    required this.relationName,
    required this.age,
    required this.phoneNumber,
    required this.relationship,
  });

  final int key;
  final int? id;
  final String relationName;
  final String age;
  final String phoneNumber;
  final String relationship;

  EmployeeRelationModel toModel({int? employeeId}) {
    return EmployeeRelationModel(
      id: id,
      employeeId: employeeId,
      relationName: relationName,
      age: int.tryParse(age),
      phoneNumber: phoneNumber,
      relationship: relationship,
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
