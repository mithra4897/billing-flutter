import '../common/json_model.dart';
import 'employee_salary_structure_model.dart';

class EmployeeModel implements JsonModel {
  const EmployeeModel({
    this.id,
    this.companyId,
    this.employeeCode,
    this.employeeName,
    this.departmentId,
    this.designationId,
    this.mobile,
    this.email,
    this.joiningDate,
    this.relievingDate,
    this.employmentType,
    this.status,
    this.salaryMode,
    this.bankAccountNo,
    this.ifscCode,
    this.profilePhotoPath,
    this.costCenterId,
    this.departmentName,
    this.designationName,
    this.companyName,
    this.costCenterName,
    this.salaryStructures = const <EmployeeSalaryStructureModel>[],
    this.salaryStructuresCount,
    this.raw,
  });

  final int? id;
  final int? companyId;
  final String? employeeCode;
  final String? employeeName;
  final int? departmentId;
  final int? designationId;
  final String? mobile;
  final String? email;
  final String? joiningDate;
  final String? relievingDate;
  final String? employmentType;
  final String? status;
  final String? salaryMode;
  final String? bankAccountNo;
  final String? ifscCode;
  final String? profilePhotoPath;
  final int? costCenterId;
  final String? departmentName;
  final String? designationName;
  final String? companyName;
  final String? costCenterName;
  final List<EmployeeSalaryStructureModel> salaryStructures;
  final int? salaryStructuresCount;
  final Map<String, dynamic>? raw;

  @override
  String toString() => employeeName ?? employeeCode ?? 'New Employee';

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    final department = _asMap(json['department']);
    final designation = _asMap(json['designation']);
    final company = _asMap(json['company']);
    final costCenter = _asMap(json['cost_center'] ?? json['costCenter']);
    final structures =
        _asList(json['salary_structures'] ?? json['salaryStructures'])
            .map((item) => EmployeeSalaryStructureModel.fromJson(item))
            .toList(growable: false);

    return EmployeeModel(
      id: _nullableInt(json['id']),
      companyId: _nullableInt(json['company_id'] ?? company['id']),
      employeeCode: json['employee_code']?.toString(),
      employeeName: json['employee_name']?.toString(),
      departmentId: _nullableInt(json['department_id'] ?? department['id']),
      designationId: _nullableInt(json['designation_id'] ?? designation['id']),
      mobile: json['mobile']?.toString(),
      email: json['email']?.toString(),
      joiningDate: _dateString(json['joining_date']),
      relievingDate: _dateString(json['relieving_date']),
      employmentType: json['employment_type']?.toString(),
      status: json['status']?.toString(),
      salaryMode: json['salary_mode']?.toString(),
      bankAccountNo: json['bank_account_no']?.toString(),
      ifscCode: json['ifsc_code']?.toString(),
      profilePhotoPath: json['profile_photo_path']?.toString(),
      costCenterId: _nullableInt(json['cost_center_id'] ?? costCenter['id']),
      departmentName: department['department_name']?.toString(),
      designationName: designation['designation_name']?.toString(),
      companyName:
          company['trade_name']?.toString() ??
          company['legal_name']?.toString() ??
          company['code']?.toString(),
      costCenterName:
          costCenter['cost_center_name']?.toString() ??
          costCenter['cost_center_code']?.toString(),
      salaryStructures: structures,
      salaryStructuresCount:
          _nullableInt(json['salary_structures_count']) ?? structures.length,
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (employeeCode != null) 'employee_code': employeeCode,
      if (employeeName != null) 'employee_name': employeeName,
      'department_id': departmentId,
      'designation_id': designationId,
      if (mobile != null) 'mobile': mobile,
      if (email != null) 'email': email,
      if (joiningDate != null) 'joining_date': joiningDate,
      'relieving_date': relievingDate,
      if (employmentType != null) 'employment_type': employmentType,
      if (status != null) 'status': status,
      if (salaryMode != null) 'salary_mode': salaryMode,
      if (bankAccountNo != null) 'bank_account_no': bankAccountNo,
      if (ifscCode != null) 'ifsc_code': ifscCode,
      if (profilePhotoPath != null) 'profile_photo_path': profilePhotoPath,
      'cost_center_id': costCenterId,
      if (salaryStructures.isNotEmpty ||
          raw?.containsKey('salary_structures') == true)
        'salary_structures': salaryStructures
            .map((item) => item.toJson())
            .toList(growable: false),
    };
  }

  EmployeeModel copyWith({
    int? id,
    int? companyId,
    String? employeeCode,
    String? employeeName,
    int? departmentId,
    int? designationId,
    String? mobile,
    String? email,
    String? joiningDate,
    String? relievingDate,
    String? employmentType,
    String? status,
    String? salaryMode,
    String? bankAccountNo,
    String? ifscCode,
    String? profilePhotoPath,
    int? costCenterId,
    List<EmployeeSalaryStructureModel>? salaryStructures,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      employeeCode: employeeCode ?? this.employeeCode,
      employeeName: employeeName ?? this.employeeName,
      departmentId: departmentId ?? this.departmentId,
      designationId: designationId ?? this.designationId,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      joiningDate: joiningDate ?? this.joiningDate,
      relievingDate: relievingDate ?? this.relievingDate,
      employmentType: employmentType ?? this.employmentType,
      status: status ?? this.status,
      salaryMode: salaryMode ?? this.salaryMode,
      bankAccountNo: bankAccountNo ?? this.bankAccountNo,
      ifscCode: ifscCode ?? this.ifscCode,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      costCenterId: costCenterId ?? this.costCenterId,
      departmentName: departmentName,
      designationName: designationName,
      companyName: companyName,
      costCenterName: costCenterName,
      salaryStructures: salaryStructures ?? this.salaryStructures,
      salaryStructuresCount: salaryStructures?.length ?? salaryStructuresCount,
      raw: raw,
    );
  }

  static int? _nullableInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '');

  static String? _dateString(dynamic value) =>
      value?.toString().split('T').first.split(' ').first;

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _asList(dynamic value) {
    if (value is List) {
      return value.whereType<Map<String, dynamic>>().toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }
}
