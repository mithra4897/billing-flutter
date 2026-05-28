import '../../screen.dart';

class EmployeeManagementController extends GetxController {
  EmployeeManagementController();

  final HrService hrService = HrService();
  final AuthService authService = AuthService();
  final MasterService masterService = MasterService();
  final AssetsService assetsService = AssetsService();
  final MediaService mediaService = MediaService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController employeeCodeController = TextEditingController();
  final TextEditingController employeeNameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController joiningDateController = TextEditingController();
  final TextEditingController relievingDateController = TextEditingController();
  final TextEditingController bankAccountNoController = TextEditingController();
  final TextEditingController ifscCodeController = TextEditingController();
  final TextEditingController profilePhotoController = TextEditingController();
  final TextEditingController esiNoController = TextEditingController();
  final TextEditingController pfUanNoController = TextEditingController();
  final TextEditingController pfAccountNoController = TextEditingController();
  final TextEditingController passportNoController = TextEditingController();
  final TextEditingController passportIssueDateController =
      TextEditingController();
  final TextEditingController passportExpiryDateController =
      TextEditingController();
  final TextEditingController passportPlaceOfIssueController =
      TextEditingController();
  final TextEditingController personalInsuranceProviderController =
      TextEditingController();
  final TextEditingController personalInsurancePolicyNoController =
      TextEditingController();
  final TextEditingController personalInsuranceAmountController =
      TextEditingController();
  final TextEditingController companyInsuranceProviderController =
      TextEditingController();
  final TextEditingController companyInsurancePolicyNoController =
      TextEditingController();
  final TextEditingController companyInsuranceAmountController =
      TextEditingController();
  final TextEditingController addressLine1Controller = TextEditingController();
  final TextEditingController addressLine2Controller = TextEditingController();
  final TextEditingController addressLandmarkController =
      TextEditingController();
  final TextEditingController addressCityController = TextEditingController();
  final TextEditingController addressStateController = TextEditingController();
  final TextEditingController addressPostalCodeController =
      TextEditingController();
  final TextEditingController addressCountryController =
      TextEditingController();
  final TextEditingController addressPhoneController = TextEditingController();
  final TextEditingController relationNameController = TextEditingController();
  final TextEditingController relationAgeController = TextEditingController();
  final TextEditingController relationPhoneController = TextEditingController();
  final TextEditingController relationRelationshipController =
      TextEditingController();
  final TextEditingController structureEffectiveFromController =
      TextEditingController();
  final TextEditingController structureBasicSalaryController =
      TextEditingController();
  final TextEditingController structureGrossSalaryController =
      TextEditingController();
  final TextEditingController structureNetSalaryController =
      TextEditingController();
  final TextEditingController structureCtcMonthlyController =
      TextEditingController();
  final TextEditingController componentNameController = TextEditingController();
  final TextEditingController componentAmountController =
      TextEditingController();
  final TextEditingController componentPercentController =
      TextEditingController();

  int activeEditorTabIndex = 0;
  int editorTabRevision = 0;
  bool employeeCodeManuallyEdited = false;
  bool suppressEmployeeCodeListener = false;
  bool initialLoading = true;
  bool saving = false;
  bool uploadingPhoto = false;
  bool showDraftStructureTile = false;
  bool showDraftComponentTile = false;
  bool showDraftAddressTile = false;
  bool showDraftRelationTile = false;
  String? pageError;
  String? formError;
  String? statutoryFormError;
  String? structureFormError;
  String? componentFormError;
  String? addressFormError;
  String? relationFormError;
  List<EmployeeModel> employees = const <EmployeeModel>[];
  List<EmployeeModel> filteredEmployees = const <EmployeeModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<DepartmentModel> departments = const <DepartmentModel>[];
  List<DesignationModel> designations = const <DesignationModel>[];
  List<CostCenterModel> costCenters = const <CostCenterModel>[];
  List<ExpenseClaimModel> employeeExpenseClaims = const <ExpenseClaimModel>[];
  String? employeeClaimsLoadError;
  List<EmployeeAddressDraft> addresses = <EmployeeAddressDraft>[];
  List<EmployeeRelationDraft> relations = <EmployeeRelationDraft>[];
  List<EmployeeSalaryStructureDraft> salaryStructures =
      <EmployeeSalaryStructureDraft>[];
  EmployeeModel? selectedEmployee;
  int? contextCompanyId;
  int? companyId;
  int? departmentId;
  int? designationId;
  int? costCenterId;
  String employmentType = 'permanent';
  String status = 'active';
  String salaryMode = 'monthly';
  int draftKeySeed = -1;
  String addressType = 'present';
  int? selectedAddressKey;
  int? selectedRelationKey;
  int? selectedStructureKey;
  bool structureIsActive = true;
  int? selectedComponentParentKey;
  int? selectedComponentKey;
  String componentType = 'earning';
  String componentCalculationBasis = 'fixed';
  String componentContributionRole = 'employee';

  void setActiveEditorTabIndex(int index, {bool notify = true}) {
    if (activeEditorTabIndex == index) {
      return;
    }
    activeEditorTabIndex = index;
    if (notify) {
      update();
    }
  }

  void bumpEditorTabBody({bool notify = true}) {
    editorTabRevision++;
    if (notify) {
      update();
    }
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController.dispose();
    employeeCodeController.dispose();
    employeeNameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    joiningDateController.dispose();
    relievingDateController.dispose();
    bankAccountNoController.dispose();
    ifscCodeController.dispose();
    profilePhotoController.dispose();
    esiNoController.dispose();
    pfUanNoController.dispose();
    pfAccountNoController.dispose();
    passportNoController.dispose();
    passportIssueDateController.dispose();
    passportExpiryDateController.dispose();
    passportPlaceOfIssueController.dispose();
    personalInsuranceProviderController.dispose();
    personalInsurancePolicyNoController.dispose();
    personalInsuranceAmountController.dispose();
    companyInsuranceProviderController.dispose();
    companyInsurancePolicyNoController.dispose();
    companyInsuranceAmountController.dispose();
    addressLine1Controller.dispose();
    addressLine2Controller.dispose();
    addressLandmarkController.dispose();
    addressCityController.dispose();
    addressStateController.dispose();
    addressPostalCodeController.dispose();
    addressCountryController.dispose();
    addressPhoneController.dispose();
    relationNameController.dispose();
    relationAgeController.dispose();
    relationPhoneController.dispose();
    relationRelationshipController.dispose();
    structureEffectiveFromController.dispose();
    structureBasicSalaryController.dispose();
    structureGrossSalaryController.dispose();
    structureNetSalaryController.dispose();
    structureCtcMonthlyController.dispose();
    componentNameController.dispose();
    componentAmountController.dispose();
    componentPercentController.dispose();
    super.onClose();
  }
}

class EmployeeSalaryStructureDraft {
  EmployeeSalaryStructureDraft({
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
  final List<EmployeeSalaryComponentDraft> components;

  EmployeeSalaryStructureDraft copyWith({
    int? key,
    int? id,
    String? effectiveFrom,
    String? basicSalary,
    String? grossSalary,
    String? netSalary,
    String? ctcMonthly,
    bool? isActive,
    List<EmployeeSalaryComponentDraft>? components,
  }) {
    return EmployeeSalaryStructureDraft(
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

class EmployeeSalaryComponentDraft {
  EmployeeSalaryComponentDraft({
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
    final percentage = percentValue;
    final amountValue = amount.trim();
    final amountPart = amountValue.isNotEmpty && amountValue != '0'
        ? ' • Amt $amountValue'
        : '';
    return '$percentage% of $basisLabel$amountPart';
  }

  EmployeeSalaryComponentDraft copy() {
    return EmployeeSalaryComponentDraft(
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
    final percentage = percentValue.trim();
    return EmployeeSalaryComponentModel(
      id: id,
      componentName: componentName,
      componentType: componentType,
      amount: double.tryParse(amount),
      calculationBasis: calculationBasis,
      percentValue: calculationBasis == 'fixed' || percentage.isEmpty
          ? null
          : double.tryParse(percentage),
      contributionRole: contributionRole,
    );
  }
}

class EmployeeAddressDraft {
  EmployeeAddressDraft({
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

class EmployeeRelationDraft {
  EmployeeRelationDraft({
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

class EmployeeComponentEntry {
  const EmployeeComponentEntry({
    required this.structure,
    required this.component,
  });

  final EmployeeSalaryStructureDraft structure;
  final EmployeeSalaryComponentDraft component;
}

String employeeDecimalText(double? value) {
  if (value == null) {
    return '';
  }
  return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
}
