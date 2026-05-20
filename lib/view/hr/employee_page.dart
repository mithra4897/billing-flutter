import '../../controller/hr/employee_management_controller.dart';
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

  late final TabController _tabController;
  late final String _controllerTag;

  bool _employeeEditorRouteBumpScheduled = false;

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

  EmployeeManagementController get _employeeController =>
      Get.find<EmployeeManagementController>(tag: _controllerTag);

  HrService get _hrService => _employeeController.hrService;
  AuthService get _authService => _employeeController.authService;
  MasterService get _masterService => _employeeController.masterService;
  AssetsService get _assetsService => _employeeController.assetsService;
  MediaService get _mediaService => _employeeController.mediaService;
  ScrollController get _pageScrollController =>
      _employeeController.pageScrollController;
  GlobalKey<FormState> get _primaryEmployeeFormKey =>
      _employeeController.primaryEmployeeFormKey;
  SettingsWorkspaceController get _workspaceController =>
      _employeeController.workspaceController;
  TextEditingController get _searchController =>
      _employeeController.searchController;
  TextEditingController get _employeeCodeController =>
      _employeeController.employeeCodeController;
  TextEditingController get _employeeNameController =>
      _employeeController.employeeNameController;
  TextEditingController get _mobileController =>
      _employeeController.mobileController;
  TextEditingController get _emailController =>
      _employeeController.emailController;
  TextEditingController get _joiningDateController =>
      _employeeController.joiningDateController;
  TextEditingController get _relievingDateController =>
      _employeeController.relievingDateController;
  TextEditingController get _bankAccountNoController =>
      _employeeController.bankAccountNoController;
  TextEditingController get _ifscCodeController =>
      _employeeController.ifscCodeController;
  TextEditingController get _profilePhotoController =>
      _employeeController.profilePhotoController;
  TextEditingController get _esiNoController =>
      _employeeController.esiNoController;
  TextEditingController get _pfUanNoController =>
      _employeeController.pfUanNoController;
  TextEditingController get _pfAccountNoController =>
      _employeeController.pfAccountNoController;
  TextEditingController get _passportNoController =>
      _employeeController.passportNoController;
  TextEditingController get _passportIssueDateController =>
      _employeeController.passportIssueDateController;
  TextEditingController get _passportExpiryDateController =>
      _employeeController.passportExpiryDateController;
  TextEditingController get _passportPlaceOfIssueController =>
      _employeeController.passportPlaceOfIssueController;
  TextEditingController get _personalInsuranceProviderController =>
      _employeeController.personalInsuranceProviderController;
  TextEditingController get _personalInsurancePolicyNoController =>
      _employeeController.personalInsurancePolicyNoController;
  TextEditingController get _personalInsuranceAmountController =>
      _employeeController.personalInsuranceAmountController;
  TextEditingController get _companyInsuranceProviderController =>
      _employeeController.companyInsuranceProviderController;
  TextEditingController get _companyInsurancePolicyNoController =>
      _employeeController.companyInsurancePolicyNoController;
  TextEditingController get _companyInsuranceAmountController =>
      _employeeController.companyInsuranceAmountController;
  TextEditingController get _addressLine1Controller =>
      _employeeController.addressLine1Controller;
  TextEditingController get _addressLine2Controller =>
      _employeeController.addressLine2Controller;
  TextEditingController get _addressLandmarkController =>
      _employeeController.addressLandmarkController;
  TextEditingController get _addressCityController =>
      _employeeController.addressCityController;
  TextEditingController get _addressStateController =>
      _employeeController.addressStateController;
  TextEditingController get _addressPostalCodeController =>
      _employeeController.addressPostalCodeController;
  TextEditingController get _addressCountryController =>
      _employeeController.addressCountryController;
  TextEditingController get _addressPhoneController =>
      _employeeController.addressPhoneController;
  TextEditingController get _relationNameController =>
      _employeeController.relationNameController;
  TextEditingController get _relationAgeController =>
      _employeeController.relationAgeController;
  TextEditingController get _relationPhoneController =>
      _employeeController.relationPhoneController;
  TextEditingController get _relationRelationshipController =>
      _employeeController.relationRelationshipController;
  TextEditingController get _structureEffectiveFromController =>
      _employeeController.structureEffectiveFromController;
  TextEditingController get _structureBasicSalaryController =>
      _employeeController.structureBasicSalaryController;
  TextEditingController get _structureGrossSalaryController =>
      _employeeController.structureGrossSalaryController;
  TextEditingController get _structureNetSalaryController =>
      _employeeController.structureNetSalaryController;
  TextEditingController get _structureCtcMonthlyController =>
      _employeeController.structureCtcMonthlyController;
  TextEditingController get _componentNameController =>
      _employeeController.componentNameController;
  TextEditingController get _componentAmountController =>
      _employeeController.componentAmountController;
  TextEditingController get _componentPercentController =>
      _employeeController.componentPercentController;

  bool get _employeeCodeManuallyEdited =>
      _employeeController.employeeCodeManuallyEdited;
  set _employeeCodeManuallyEdited(bool value) =>
      _employeeController.employeeCodeManuallyEdited = value;
  bool get _suppressEmployeeCodeListener =>
      _employeeController.suppressEmployeeCodeListener;
  set _suppressEmployeeCodeListener(bool value) =>
      _employeeController.suppressEmployeeCodeListener = value;
  bool get _initialLoading => _employeeController.initialLoading;
  set _initialLoading(bool value) => _employeeController.initialLoading = value;
  bool get _saving => _employeeController.saving;
  set _saving(bool value) => _employeeController.saving = value;
  bool get _uploadingPhoto => _employeeController.uploadingPhoto;
  set _uploadingPhoto(bool value) => _employeeController.uploadingPhoto = value;
  bool get _showDraftStructureTile =>
      _employeeController.showDraftStructureTile;
  set _showDraftStructureTile(bool value) =>
      _employeeController.showDraftStructureTile = value;
  bool get _showDraftComponentTile =>
      _employeeController.showDraftComponentTile;
  set _showDraftComponentTile(bool value) =>
      _employeeController.showDraftComponentTile = value;
  bool get _showDraftAddressTile => _employeeController.showDraftAddressTile;
  set _showDraftAddressTile(bool value) =>
      _employeeController.showDraftAddressTile = value;
  bool get _showDraftRelationTile => _employeeController.showDraftRelationTile;
  set _showDraftRelationTile(bool value) =>
      _employeeController.showDraftRelationTile = value;
  String? get _pageError => _employeeController.pageError;
  set _pageError(String? value) => _employeeController.pageError = value;
  String? get _formError => _employeeController.formError;
  set _formError(String? value) => _employeeController.formError = value;
  String? get _statutoryFormError => _employeeController.statutoryFormError;
  set _statutoryFormError(String? value) =>
      _employeeController.statutoryFormError = value;
  String? get _structureFormError => _employeeController.structureFormError;
  set _structureFormError(String? value) =>
      _employeeController.structureFormError = value;
  String? get _componentFormError => _employeeController.componentFormError;
  set _componentFormError(String? value) =>
      _employeeController.componentFormError = value;
  String? get _addressFormError => _employeeController.addressFormError;
  set _addressFormError(String? value) =>
      _employeeController.addressFormError = value;
  String? get _relationFormError => _employeeController.relationFormError;
  set _relationFormError(String? value) =>
      _employeeController.relationFormError = value;
  List<EmployeeModel> get _employees => _employeeController.employees;
  set _employees(List<EmployeeModel> value) =>
      _employeeController.employees = value;
  List<EmployeeModel> get _filteredEmployees =>
      _employeeController.filteredEmployees;
  set _filteredEmployees(List<EmployeeModel> value) =>
      _employeeController.filteredEmployees = value;
  List<CompanyModel> get _companies => _employeeController.companies;
  set _companies(List<CompanyModel> value) =>
      _employeeController.companies = value;
  List<DepartmentModel> get _departments => _employeeController.departments;
  set _departments(List<DepartmentModel> value) =>
      _employeeController.departments = value;
  List<DesignationModel> get _designations => _employeeController.designations;
  set _designations(List<DesignationModel> value) =>
      _employeeController.designations = value;
  List<CostCenterModel> get _costCenters => _employeeController.costCenters;
  set _costCenters(List<CostCenterModel> value) =>
      _employeeController.costCenters = value;
  List<ExpenseClaimModel> get _employeeExpenseClaims =>
      _employeeController.employeeExpenseClaims;
  set _employeeExpenseClaims(List<ExpenseClaimModel> value) =>
      _employeeController.employeeExpenseClaims = value;
  String? get _employeeClaimsLoadError =>
      _employeeController.employeeClaimsLoadError;
  set _employeeClaimsLoadError(String? value) =>
      _employeeController.employeeClaimsLoadError = value;
  List<EmployeeAddressDraft> get _addresses => _employeeController.addresses;
  set _addresses(List<EmployeeAddressDraft> value) =>
      _employeeController.addresses = value;
  List<EmployeeRelationDraft> get _relations => _employeeController.relations;
  set _relations(List<EmployeeRelationDraft> value) =>
      _employeeController.relations = value;
  List<EmployeeSalaryStructureDraft> get _salaryStructures =>
      _employeeController.salaryStructures;
  set _salaryStructures(List<EmployeeSalaryStructureDraft> value) =>
      _employeeController.salaryStructures = value;
  EmployeeModel? get _selectedEmployee => _employeeController.selectedEmployee;
  set _selectedEmployee(EmployeeModel? value) =>
      _employeeController.selectedEmployee = value;
  int? get _contextCompanyId => _employeeController.contextCompanyId;
  set _contextCompanyId(int? value) =>
      _employeeController.contextCompanyId = value;
  int? get _companyId => _employeeController.companyId;
  set _companyId(int? value) => _employeeController.companyId = value;
  int? get _departmentId => _employeeController.departmentId;
  set _departmentId(int? value) => _employeeController.departmentId = value;
  int? get _designationId => _employeeController.designationId;
  set _designationId(int? value) => _employeeController.designationId = value;
  int? get _costCenterId => _employeeController.costCenterId;
  set _costCenterId(int? value) => _employeeController.costCenterId = value;
  String get _employmentType => _employeeController.employmentType;
  set _employmentType(String value) =>
      _employeeController.employmentType = value;
  String get _status => _employeeController.status;
  set _status(String value) => _employeeController.status = value;
  String get _salaryMode => _employeeController.salaryMode;
  set _salaryMode(String value) => _employeeController.salaryMode = value;
  int get _draftKeySeed => _employeeController.draftKeySeed;
  set _draftKeySeed(int value) => _employeeController.draftKeySeed = value;
  String get _addressType => _employeeController.addressType;
  set _addressType(String value) => _employeeController.addressType = value;
  int? get _selectedAddressKey => _employeeController.selectedAddressKey;
  set _selectedAddressKey(int? value) =>
      _employeeController.selectedAddressKey = value;
  int? get _selectedRelationKey => _employeeController.selectedRelationKey;
  set _selectedRelationKey(int? value) =>
      _employeeController.selectedRelationKey = value;
  int? get _selectedStructureKey => _employeeController.selectedStructureKey;
  set _selectedStructureKey(int? value) =>
      _employeeController.selectedStructureKey = value;
  bool get _structureIsActive => _employeeController.structureIsActive;
  set _structureIsActive(bool value) =>
      _employeeController.structureIsActive = value;
  int? get _selectedComponentParentKey =>
      _employeeController.selectedComponentParentKey;
  set _selectedComponentParentKey(int? value) =>
      _employeeController.selectedComponentParentKey = value;
  int? get _selectedComponentKey => _employeeController.selectedComponentKey;
  set _selectedComponentKey(int? value) =>
      _employeeController.selectedComponentKey = value;
  String get _componentType => _employeeController.componentType;
  set _componentType(String value) => _employeeController.componentType = value;
  String get _componentCalculationBasis =>
      _employeeController.componentCalculationBasis;
  set _componentCalculationBasis(String value) =>
      _employeeController.componentCalculationBasis = value;
  String get _componentContributionRole =>
      _employeeController.componentContributionRole;
  set _componentContributionRole(String value) =>
      _employeeController.componentContributionRole = value;

  void _updateController(VoidCallback action) {
    action();
    if (mounted) {
      _employeeController.update();
    }
  }

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('EmployeeManagementController');
    Get.put(
      EmployeeManagementController(),
      tag: _controllerTag,
      permanent: true,
    );
    _tabController = TabController(length: 7, vsync: this);
    _employeeController.setActiveEditorTabIndex(_tabController.index);
    _tabController.addListener(() {
      if (!mounted || _tabController.indexIsChanging) {
        return;
      }
      _updateController(() {});
      _employeeController.setActiveEditorTabIndex(_tabController.index);
      _bumpEmployeeEditorRoute();
    });
    _searchController.addListener(_applySearch);
    _employeeCodeController.addListener(_handleEmployeeCodeChanged);
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
    _searchController.removeListener(_applySearch);
    _employeeCodeController.removeListener(_handleEmployeeCodeChanged);
    super.dispose();
  }

  void _bumpEmployeeEditorRoute() {
    if (_employeeEditorRouteBumpScheduled) {
      return;
    }
    _employeeEditorRouteBumpScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _employeeEditorRouteBumpScheduled = false;
      if (!mounted) {
        return;
      }
      _employeeController.bumpEditorTabBody();
    });
  }

  Future<void> _loadData({int? selectId}) async {
    _updateController(() {
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

      _updateController(() {
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
      _updateController(() {
        _pageError = error.toString();
        _initialLoading = false;
      });
    }
  }

  /// Refresh employee rows after save with a single list fetch (not full [_loadData]).
  ///
  /// When [reloadDetail] is true (desktop inline editor), loads full employee + tabs via
  /// [_selectEmployee]. When false (e.g. before closing the mobile fullscreen editor),
  /// only updates the list and [selectedEmployee] from list row - avoids heavy async work
  /// on top of [Navigator] while the pushed route is still visible (which caused freezes).
  Future<void> _reloadEmployeeListAndSelect(
    int employeeId, {
    bool reloadDetail = true,
  }) async {
    try {
      final employeesResp = await _hrService.employees(
        filters: const {'per_page': 200, 'sort_by': 'employee_name'},
      );
      if (!mounted) return;
      final employees = employeesResp.data ?? const <EmployeeModel>[];
      final idx = employees.indexWhere((EmployeeModel e) => e.id == employeeId);
      final EmployeeModel? row = idx >= 0 ? employees[idx] : null;

      _updateController(() {
        _employees = employees;
        _filteredEmployees = _filterEmployees(
          employees,
          _searchController.text,
        );
        if (row != null &&
            !_filteredEmployees.any((EmployeeModel e) => e.id == employeeId)) {
          _filteredEmployees = <EmployeeModel>[row, ..._filteredEmployees];
        }
        if (row != null && !reloadDetail) {
          _selectedEmployee = row;
        }
      });

      if (!mounted) return;
      if (reloadDetail && row != null) {
        _bumpEmployeeEditorRoute();
        await _selectEmployee(row);
      }
    } catch (_) {
      if (mounted) {
        await _loadData(selectId: employeeId);
      }
    }
  }

  /// Full-screen editor (narrow layout): return to list after save/delete.
  void _popEmployeeEditorIfFullscreen() {
    if (!mounted) {
      return;
    }
    if (Responsive.isDesktop(context)) {
      return;
    }
    final NavigatorState nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
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
    _updateController(() {
      _filteredEmployees = _filterEmployees(_employees, _searchController.text);
    });
  }

  Future<void> _selectEmployee(EmployeeModel employee) async {
    final int employeeId = employee.id!;
    final List<dynamic> detailAndSalary =
        await Future.wait<dynamic>(<Future<dynamic>>[
          _hrService.employee(employeeId),
          _hrService.employeeSalaryStructures(employeeId),
        ]);
    final ApiResponse<EmployeeModel> detailResponse =
        detailAndSalary[0] as ApiResponse<EmployeeModel>;
    final ApiResponse<List<EmployeeSalaryStructureModel>> salaryResponse =
        detailAndSalary[1] as ApiResponse<List<EmployeeSalaryStructureModel>>;
    final full = detailResponse.data ?? employee;

    _selectedEmployee = full;
    _companyId = full.companyId ?? _contextCompanyId;
    _setEmployeeCode(full.employeeCode ?? '', autoGenerated: false);
    _employeeCodeManuallyEdited = true;
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
    _personalInsuranceAmountController.text = employeeDecimalText(
      full.personalInsuranceAmount,
    );
    _companyInsuranceProviderController.text =
        full.companyInsuranceProvider ?? '';
    _companyInsurancePolicyNoController.text =
        full.companyInsurancePolicyNo ?? '';
    _companyInsuranceAmountController.text = employeeDecimalText(
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
        _employeeExpenseClaims = claimsPage.data ?? const <ExpenseClaimModel>[];
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
    _salaryStructures = _mergeSalaryStructureModels(
      primary: salaryResponse.data ?? const <EmployeeSalaryStructureModel>[],
      fallback: full.salaryStructures,
    ).map(_salaryStructureDraftFromModel).toList(growable: true);
    _resetAddressEditor(silent: true);
    _resetRelationEditor(silent: true);
    _resetStructureEditor(silent: true);
    _resetComponentEditor(silent: true);
    _statutoryFormError = null;
    _formError = null;
    _updateController(() {});
    _bumpEmployeeEditorRoute();
  }

  void _resetForm() {
    _selectedEmployee = null;
    _setEmployeeCode('', autoGenerated: true);
    _employeeCodeManuallyEdited = false;
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
    _addresses = <EmployeeAddressDraft>[];
    _relations = <EmployeeRelationDraft>[];
    _salaryStructures = <EmployeeSalaryStructureDraft>[];
    _resetAddressEditor(silent: true);
    _resetRelationEditor(silent: true);
    _resetStructureEditor(silent: true);
    _resetComponentEditor(silent: true);
    _statutoryFormError = null;
    _formError = null;
    _updateController(() {});
    _primeEmployeeCodeSuggestion();
    _bumpEmployeeEditorRoute();
  }

  bool get _isNewEmployee => _selectedEmployee?.id == null;

  void _handleEmployeeCodeChanged() {
    if (_suppressEmployeeCodeListener || !_isNewEmployee) {
      return;
    }

    _employeeCodeManuallyEdited = _employeeCodeController.text
        .trim()
        .isNotEmpty;
  }

  void _setEmployeeCode(String value, {required bool autoGenerated}) {
    _suppressEmployeeCodeListener = true;
    _employeeCodeController.value = _employeeCodeController.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _suppressEmployeeCodeListener = false;
    _employeeCodeManuallyEdited = !autoGenerated && value.trim().isNotEmpty;
  }

  Future<void> _primeEmployeeCodeSuggestion() async {
    if (!_isNewEmployee || _employeeCodeManuallyEdited) {
      return;
    }

    try {
      final suggestedCode = await _authService.nextEmployeeCode();
      if (!mounted ||
          !_isNewEmployee ||
          _employeeCodeManuallyEdited ||
          (suggestedCode ?? '').trim().isEmpty) {
        return;
      }

      _setEmployeeCode(suggestedCode!.trim(), autoGenerated: true);
      _updateController(() {});
    } catch (_) {}
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
    final FormState? primaryForm = _primaryEmployeeFormKey.currentState;
    if (primaryForm == null || !primaryForm.validate()) {
      return;
    }

    _updateController(() {
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
        _updateController(() => _formError = response.message);
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      final int? sid = saved.id;
      if (sid == null) {
        await _loadData();
      } else if (Responsive.isDesktop(context)) {
        await _reloadEmployeeListAndSelect(sid);
      } else {
        await _reloadEmployeeListAndSelect(sid, reloadDetail: false);
        _popEmployeeEditorIfFullscreen();
      }
    } catch (error) {
      if (!mounted) return;
      _updateController(() => _formError = error.toString());
      _bumpEmployeeEditorRoute();
    } finally {
      if (mounted) {
        _updateController(() => _saving = false);
        _bumpEmployeeEditorRoute();
      }
    }
  }

  Future<void> _deleteEmployee() async {
    final id = _selectedEmployee?.id;
    if (id == null) return;

    _updateController(() {
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
      _popEmployeeEditorIfFullscreen();
    } catch (error) {
      if (!mounted) return;
      _updateController(() => _formError = error.toString());
      _bumpEmployeeEditorRoute();
    } finally {
      if (mounted) {
        _updateController(() => _saving = false);
        _bumpEmployeeEditorRoute();
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

    _updateController(() {
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
      final int sid = saved?.id ?? employee.id!;
      if (Responsive.isDesktop(context)) {
        await _reloadEmployeeListAndSelect(sid);
      } else {
        await _reloadEmployeeListAndSelect(sid, reloadDetail: false);
        _popEmployeeEditorIfFullscreen();
      }
    } catch (error) {
      if (!mounted) return;
      _updateController(() => onError(error.toString()));
      _bumpEmployeeEditorRoute();
    } finally {
      if (mounted) {
        _updateController(() => _saving = false);
        _bumpEmployeeEditorRoute();
      }
    }
  }

  Future<void> _persistSalaryData(String successMessage) async {
    final employee = _selectedEmployee;
    if (employee?.id == null) {
      return;
    }

    _updateController(() {
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
      final int sid = saved?.id ?? employee.id!;
      if (Responsive.isDesktop(context)) {
        await _reloadEmployeeListAndSelect(sid);
      } else {
        await _reloadEmployeeListAndSelect(sid, reloadDetail: false);
        _popEmployeeEditorIfFullscreen();
      }
    } catch (error) {
      if (!mounted) return;
      _updateController(() {
        _structureFormError = error.toString();
        _componentFormError = error.toString();
      });
      _bumpEmployeeEditorRoute();
    } finally {
      if (mounted) {
        _updateController(() => _saving = false);
        _bumpEmployeeEditorRoute();
      }
    }
  }

  int _nextDraftKey() => _draftKeySeed--;

  EmployeeAddressDraft _employeeAddressDraftFromModel(
    EmployeeAddressModel model,
  ) {
    return EmployeeAddressDraft(
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

  EmployeeRelationDraft _employeeRelationDraftFromModel(
    EmployeeRelationModel model,
  ) {
    return EmployeeRelationDraft(
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
      _updateController(() {});
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
    _updateController(() {});
  }

  void _selectAddress(EmployeeAddressDraft draft) {
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
    _updateController(() {});
  }

  Future<void> _saveAddress() async {
    if (_addressLine1Controller.text.trim().isEmpty) {
      _updateController(
        () => _addressFormError = 'Address Line 1 is required.',
      );
      return;
    }

    final draft = EmployeeAddressDraft(
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

    _updateController(() {
      var next = List<EmployeeAddressDraft>.from(_addresses)
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

  Future<void> _removeAddress(EmployeeAddressDraft draft) async {
    _updateController(() {
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
      _updateController(() {});
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
    _updateController(() {});
  }

  void _selectRelation(EmployeeRelationDraft draft) {
    _showDraftRelationTile = false;
    _selectedRelationKey = draft.key;
    _relationNameController.text = draft.relationName;
    _relationAgeController.text = draft.age;
    _relationPhoneController.text = draft.phoneNumber;
    _relationRelationshipController.text = draft.relationship;
    _relationFormError = null;
    _updateController(() {});
  }

  Future<void> _saveRelation() async {
    if (_relationNameController.text.trim().isEmpty) {
      _updateController(
        () => _relationFormError = 'Relation Name is required.',
      );
      return;
    }
    if (_relationRelationshipController.text.trim().isEmpty) {
      _updateController(() => _relationFormError = 'Relationship is required.');
      return;
    }
    final ageText = _relationAgeController.text.trim();
    if (ageText.isNotEmpty && int.tryParse(ageText) == null) {
      _updateController(
        () => _relationFormError = 'Age must be a valid whole number.',
      );
      return;
    }

    final draft = EmployeeRelationDraft(
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

    _updateController(() {
      final next = List<EmployeeRelationDraft>.from(_relations);
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

  Future<void> _removeRelation(EmployeeRelationDraft draft) async {
    _updateController(() {
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

  EmployeeSalaryStructureDraft _salaryStructureDraftFromModel(
    EmployeeSalaryStructureModel model,
  ) {
    return EmployeeSalaryStructureDraft(
      key: model.id ?? _nextDraftKey(),
      id: model.id,
      effectiveFrom: model.effectiveFrom ?? '',
      basicSalary: employeeDecimalText(model.basicSalary),
      grossSalary: employeeDecimalText(model.grossSalary),
      netSalary: employeeDecimalText(model.netSalary),
      ctcMonthly: employeeDecimalText(model.ctcMonthly),
      isActive: model.isActive,
      components: model.components
          .map(
            (item) => EmployeeSalaryComponentDraft(
              key: item.id ?? _nextDraftKey(),
              id: item.id,
              componentName: item.componentName ?? '',
              componentType: item.componentType ?? 'earning',
              amount: employeeDecimalText(item.amount),
              calculationBasis: item.calculationBasis ?? 'fixed',
              percentValue: employeeDecimalText(item.percentValue),
              contributionRole: item.contributionRole ?? 'employee',
            ),
          )
          .toList(growable: true),
    );
  }

  List<EmployeeSalaryStructureModel> _mergeSalaryStructureModels({
    required List<EmployeeSalaryStructureModel> primary,
    required List<EmployeeSalaryStructureModel> fallback,
  }) {
    if (primary.isEmpty) {
      return fallback;
    }
    if (fallback.isEmpty) {
      return primary;
    }

    EmployeeSalaryStructureModel? findFallback(
      EmployeeSalaryStructureModel item,
    ) {
      final byId = item.id == null
          ? null
          : fallback.where((candidate) => candidate.id == item.id).firstOrNull;
      if (byId != null) {
        return byId;
      }

      return fallback
          .where(
            (candidate) =>
                candidate.effectiveFrom == item.effectiveFrom &&
                candidate.basicSalary == item.basicSalary &&
                candidate.grossSalary == item.grossSalary &&
                candidate.netSalary == item.netSalary,
          )
          .firstOrNull;
    }

    return primary
        .map((item) {
          final fallbackItem = findFallback(item);
          if (fallbackItem == null) {
            return item;
          }

          return item.copyWith(
            ctcMonthly: item.ctcMonthly ?? fallbackItem.ctcMonthly,
            components: item.components.isNotEmpty
                ? item.components
                : fallbackItem.components,
          );
        })
        .toList(growable: false);
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
      _updateController(() {});
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
    _updateController(() {});
  }

  void _selectStructure(EmployeeSalaryStructureDraft draft) {
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
    _updateController(() {});
  }

  Future<void> _saveStructure() async {
    final effectiveFrom = _structureEffectiveFromController.text.trim();
    if (effectiveFrom.isEmpty) {
      _updateController(
        () => _structureFormError = 'Effective From is required.',
      );
      return;
    }
    if (Validators.date('Effective From')(effectiveFrom) != null) {
      _updateController(
        () => _structureFormError = 'Effective From must be a valid date.',
      );
      return;
    }

    final draft = EmployeeSalaryStructureDraft(
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
          ? <EmployeeSalaryComponentDraft>[]
          : _salaryStructures
                    .where((item) => item.key == _selectedStructureKey)
                    .firstOrNull
                    ?.components
                    .map((item) => item.copy())
                    .toList(growable: true) ??
                <EmployeeSalaryComponentDraft>[],
    );

    _updateController(() {
      final next = List<EmployeeSalaryStructureDraft>.from(_salaryStructures);
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

  Future<void> _removeStructure(EmployeeSalaryStructureDraft draft) async {
    _updateController(() {
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
      _updateController(() {});
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
    _updateController(() {});
  }

  void _selectComponent(
    EmployeeSalaryStructureDraft parent,
    EmployeeSalaryComponentDraft component,
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
    _updateController(() {});
  }

  Future<void> _saveComponent() async {
    if (_selectedComponentParentKey == null) {
      _updateController(
        () => _componentFormError = 'Salary Structure is required.',
      );
      return;
    }
    if (_componentNameController.text.trim().isEmpty) {
      _updateController(
        () => _componentFormError = 'Component Name is required.',
      );
      return;
    }
    final amountText = _componentAmountController.text.trim();
    final percentText = _componentPercentController.text.trim();
    if (_componentCalculationBasis == 'fixed') {
      if (amountText.isEmpty ||
          double.tryParse(amountText) == null ||
          (double.tryParse(amountText) ?? 0) < 0) {
        _updateController(
          () => _componentFormError = 'Amount must be a valid number.',
        );
        return;
      }
    } else {
      if (percentText.isEmpty ||
          double.tryParse(percentText) == null ||
          (double.tryParse(percentText) ?? 0) < 0) {
        _updateController(
          () => _componentFormError = 'Percentage must be a valid number.',
        );
        return;
      }
      if (amountText.isNotEmpty &&
          (double.tryParse(amountText) == null ||
              (double.tryParse(amountText) ?? 0) < 0)) {
        _updateController(
          () => _componentFormError = 'Amount must be a valid number.',
        );
        return;
      }
    }

    final parentIndex = _salaryStructures.indexWhere(
      (item) => item.key == _selectedComponentParentKey,
    );
    if (parentIndex < 0) {
      _updateController(
        () => _componentFormError = 'Selected salary structure not found.',
      );
      return;
    }

    final nextStructures = List<EmployeeSalaryStructureDraft>.from(
      _salaryStructures,
    );
    final parent = nextStructures[parentIndex];
    final nextComponents = List<EmployeeSalaryComponentDraft>.from(
      parent.components,
    );
    final draft = EmployeeSalaryComponentDraft(
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
      percentValue: _componentCalculationBasis == 'fixed' ? '' : percentText,
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
    _updateController(() {
      _salaryStructures = nextStructures;
    });
    _resetComponentEditor();
    await _persistSalaryData('Employee salary component saved successfully.');
  }

  Future<void> _removeComponent(
    EmployeeSalaryStructureDraft parent,
    EmployeeSalaryComponentDraft component,
  ) async {
    final parentIndex = _salaryStructures.indexWhere(
      (item) => item.key == parent.key,
    );
    if (parentIndex < 0) {
      return;
    }

    final nextStructures = List<EmployeeSalaryStructureDraft>.from(
      _salaryStructures,
    );
    final nextComponents = List<EmployeeSalaryComponentDraft>.from(
      nextStructures[parentIndex].components,
    )..removeWhere((item) => item.key == component.key);

    nextStructures[parentIndex] = nextStructures[parentIndex].copyWith(
      components: nextComponents,
    );
    _updateController(() {
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
    _updateController(() {
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
    _updateController(() {
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
          _updateController(() => _uploadingPhoto = isLoading);
        }
      },
      onSuccess: (filePath) {
        if (mounted) {
          _updateController(() {
            _profilePhotoController.text = filePath;
            _formError = null;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          _updateController(() => _formError = error);
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
    return GetBuilder<EmployeeManagementController>(
      tag: _controllerTag,
      builder: (_) {
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
      },
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
      editor: _buildEmployeeWorkspaceEditor(),
    );
  }

  /// Only the visible tab is built. [IndexedStack] kept all seven forms alive and
  /// rebuilt them together after each [_selectEmployee], which froze web/desktop.
  Widget _buildEmployeeEditorTabBody(int index) {
    switch (index) {
      case 0:
        return _buildPrimaryTab();
      case 1:
        return _buildSaveFirstTabMessage(
          tabLabel: 'Employee Statutory & Insurance',
          child: _buildStatutoryTab(),
        );
      case 2:
        return _buildSaveFirstTabMessage(
          tabLabel: 'Employee Addresses',
          child: _buildAddressesTab(),
        );
      case 3:
        return _buildSaveFirstTabMessage(
          tabLabel: 'Employee Relations',
          child: _buildRelationsTab(),
        );
      case 4:
        return _buildSaveFirstTabMessage(
          tabLabel: 'Claims & reimbursements',
          child: _buildExpenseClaimsTab(),
        );
      case 5:
        return _buildSaveFirstTabMessage(
          tabLabel: 'Employee Salary Structures',
          child: _buildSalaryStructuresTab(),
        );
      case 6:
        return _buildSaveFirstTabMessage(
          tabLabel: 'Employee Salary Components',
          child: _buildSalaryComponentsTab(),
        );
      default:
        return _buildPrimaryTab();
    }
  }

  Widget _buildEmployeeWorkspaceEditor() {
    return Column(
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
        GetBuilder<EmployeeManagementController>(
          tag: _controllerTag,
          builder: (controller) {
            final _ = controller.editorTabRevision;
            return _buildEmployeeEditorTabBody(controller.activeEditorTabIndex);
          },
        ),
      ],
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
      key: _primaryEmployeeFormKey,
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
                  onChanged: (value) =>
                      _updateController(() => _departmentId = value),
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
                  onChanged: (value) =>
                      _updateController(() => _designationId = value),
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
                onChanged: (value) => _updateController(
                  () => _employmentType = value ?? 'permanent',
                ),
              ),
              AppDropdownField<String>.fromMapped(
                labelText: 'Status',
                mappedItems: _statusItems,
                initialValue: _status,
                onChanged: (value) =>
                    _updateController(() => _status = value ?? 'active'),
              ),
              AppDropdownField<String>.fromMapped(
                labelText: 'Salary Mode',
                mappedItems: _salaryModeItems,
                initialValue: _salaryMode,
                onChanged: (value) =>
                    _updateController(() => _salaryMode = value ?? 'monthly'),
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
                onChanged: (value) =>
                    _updateController(() => _costCenterId = value),
              ),
              AppFormTextField(
                controller: _bankAccountNoController,
                labelText: 'Bank account no. (payout / salary)',
                hintText: 'Employee bank a/c for transfers - not a GL ledger',
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
                onPressed: _saving ? null : _savePrimary,
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
      final reimbursementVoucherId = intValue(data, 'reimbursement_voucher_id');
      if (st == 'draft') {
        counts['draft'] = (counts['draft'] ?? 0) + 1;
      } else if (st == 'approved' && reimbursementVoucherId == null) {
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
            Chip(label: Text('Draft: ${counts['draft'] ?? 0}')),
            Chip(
              label: Text(
                'Approved (unpaid): ${counts['approved_unpaid'] ?? 0}',
              ),
            ),
            Chip(label: Text('Reimbursed: ${counts['reimbursed'] ?? 0}')),
            if ((counts['other'] ?? 0) > 0)
              Chip(label: Text('Other: ${counts['other'] ?? 0}')),
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
          final reimbursementVoucherId = intValue(
            data,
            'reimbursement_voucher_id',
          );
          String payHint = '';
          if (st == 'approved' && reimbursementVoucherId == null) {
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
                [
                      date,
                      st,
                      amount,
                    ].where((String s) => s.isNotEmpty).join(' · ') +
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
            _updateController(() => _statutoryFormError = null);
            final passportIssueDate = _passportIssueDateController.text.trim();
            final passportExpiryDate = _passportExpiryDateController.text
                .trim();
            final issueError = Validators.optionalDate('Passport Issue Date')(
              passportIssueDate,
            );
            if (issueError != null) {
              _updateController(() => _statutoryFormError = issueError);
              return;
            }
            final expiryError = Validators.optionalDate('Passport Expiry Date')(
              passportExpiryDate,
            );
            if (expiryError != null) {
              _updateController(() => _statutoryFormError = expiryError);
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

  Widget _buildAddressEditor({EmployeeAddressDraft? current}) {
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
                  _updateController(() => _addressType = value ?? _addressType),
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

  Widget _buildRelationEditor({EmployeeRelationDraft? current}) {
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

  Widget _buildStructureEditor({EmployeeSalaryStructureDraft? current}) {
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
              onChanged: (value) =>
                  _updateController(() => _structureIsActive = value),
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

    final componentItems = <EmployeeComponentEntry>[];
    for (final structure in _salaryStructures) {
      for (final component in structure.components) {
        componentItems.add(
          EmployeeComponentEntry(structure: structure, component: component),
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
    EmployeeSalaryStructureDraft? currentParent,
    EmployeeSalaryComponentDraft? current,
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
                  _updateController(() => _selectedComponentParentKey = value),
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
                  _updateController(() => _componentType = value ?? 'earning'),
            ),
            AppDropdownField<String>.fromMapped(
              labelText: 'Calculation',
              mappedItems: _componentCalculationItems,
              initialValue: _componentCalculationBasis,
              onChanged: (value) => _updateController(() {
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
              onChanged: (value) => _updateController(
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
