import '../../screen.dart';

class ProjectModel extends JsonModel {
  const ProjectModel({
    super.id,
    this.companyId,
    this.customerPartyId,
    this.projectCode,
    this.projectName,
    this.projectType,
    this.billingMethod,
    this.expectedStartDate,
    this.expectedEndDate,
    this.actualStartDate,
    this.actualEndDate,
    this.budgetAmount,
    this.percentCompletion,
    this.imagePath,
    this.projectStatus,
    this.notes,
    this.isActive,
    this.tasks = const [],
    this.milestones = const [],
    this.timesheets = const [],
    this.expenses = const [],
    this.resourceUsages = const [],
    this.vendorWorks = const [],
    this.billings = const [],
  });
  final int? companyId;
  final int? customerPartyId;
  final String? projectCode;
  final String? projectName;
  final String? projectType;
  final String? billingMethod;
  final String? expectedStartDate;
  final String? expectedEndDate;
  final String? actualStartDate;
  final String? actualEndDate;
  final double? budgetAmount;
  final double? percentCompletion;
  final String? imagePath;
  final String? projectStatus;
  final String? notes;
  final bool? isActive;
  final List<ProjectTaskModel> tasks;
  final List<ProjectMilestoneModel> milestones;
  final List<ProjectTimesheetModel> timesheets;
  final List<ProjectExpenseModel> expenses;
  final List<ProjectResourceUsageModel> resourceUsages;
  final List<ProjectVendorWorkModel> vendorWorks;
  final List<ProjectBillingModel> billings;

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      customerPartyId: JsonModel.nullableInt(json['customer_party_id']),
      projectCode: json['project_code']?.toString(),
      projectName: json['project_name']?.toString(),
      projectType: json['project_type']?.toString(),
      billingMethod: json['billing_method']?.toString(),
      expectedStartDate: json['expected_start_date']?.toString(),
      expectedEndDate: json['expected_end_date']?.toString(),
      actualStartDate: json['actual_start_date']?.toString(),
      actualEndDate: json['actual_end_date']?.toString(),
      budgetAmount: JsonModel.nullableDouble(json['budget_amount']),
      percentCompletion: JsonModel.nullableDouble(json['percent_completion']),
      imagePath: json['image_path']?.toString(),
      projectStatus: json['project_status']?.toString(),
      notes: json['notes']?.toString(),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      tasks: _list(json['tasks'], ProjectTaskModel.fromJson),
      milestones: _list(json['milestones'], ProjectMilestoneModel.fromJson),
      timesheets: _list(json['timesheets'], ProjectTimesheetModel.fromJson),
      expenses: _list(json['expenses'], ProjectExpenseModel.fromJson),
      resourceUsages: _list(
        json['resource_usages'],
        ProjectResourceUsageModel.fromJson,
      ),
      vendorWorks: _list(json['vendor_works'], ProjectVendorWorkModel.fromJson),
      billings: _list(json['billings'], ProjectBillingModel.fromJson),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    projectName,
    projectCode,
    expectedStartDate,
  ], defaultValue: 'Project');


  @override
  Map<String, dynamic> toJson() => {
    if (companyId != null) 'company_id': companyId,
    if (customerPartyId != null) 'customer_party_id': customerPartyId,
    if (projectCode != null) 'project_code': projectCode,
    if (projectName != null) 'project_name': projectName,
    if (projectType != null) 'project_type': projectType,
    if (billingMethod != null) 'billing_method': billingMethod,
    if (expectedStartDate != null) 'expected_start_date': expectedStartDate,
    if (expectedEndDate != null) 'expected_end_date': expectedEndDate,
    if (actualStartDate != null) 'actual_start_date': actualStartDate,
    if (actualEndDate != null) 'actual_end_date': actualEndDate,
    if (budgetAmount != null) 'budget_amount': budgetAmount,
    if (percentCompletion != null) 'percent_completion': percentCompletion,
    if (imagePath != null) 'image_path': imagePath,
    if (projectStatus != null) 'project_status': projectStatus,
    if (notes != null) 'notes': notes,
    if (isActive != null) 'is_active': isActive,
  };

  static List<T> _list<T>(
    dynamic value,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    if (value is! List) {
      return <T>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }
}
