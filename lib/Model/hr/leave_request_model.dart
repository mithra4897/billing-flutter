import '../common/json_model.dart';

class LeaveRequestModel implements JsonModel {
  const LeaveRequestModel({
    this.id,
    this.employeeId,
    this.leaveTypeId,
    this.fromDate,
    this.toDate,
    this.reason,
    this.clApprovedDays,
    this.lopDays,
    this.status,
    this.approvedBy,
    this.employeeCode,
    this.employeeName,
    this.leaveTypeName,
    this.approverName,
    this.raw,
  });

  final int? id;
  final int? employeeId;
  final int? leaveTypeId;
  final String? fromDate;
  final String? toDate;
  final String? reason;
  final double? clApprovedDays;
  final double? lopDays;
  final String? status;
  final int? approvedBy;
  final String? employeeCode;
  final String? employeeName;
  final String? leaveTypeName;
  final String? approverName;
  final Map<String, dynamic>? raw;

  @override
  String toString() => employeeName ?? employeeCode ?? 'New Leave Request';

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    final employee = _asMap(json['employee']);
    final leaveType = _asMap(json['leave_type'] ?? json['leaveType']);
    final approver = _asMap(json['approver']);
    return LeaveRequestModel(
      id: _nullableInt(json['id']),
      employeeId: _nullableInt(json['employee_id'] ?? employee['id']),
      leaveTypeId: _nullableInt(json['leave_type_id'] ?? leaveType['id']),
      fromDate: _dateString(json['from_date']),
      toDate: _dateString(json['to_date']),
      reason: json['reason']?.toString(),
      clApprovedDays: _double(json['cl_approved_days']),
      lopDays: _double(json['lop_days']),
      status: json['status']?.toString(),
      approvedBy: _nullableInt(json['approved_by'] ?? approver['id']),
      employeeCode: employee['employee_code']?.toString(),
      employeeName: employee['employee_name']?.toString(),
      leaveTypeName: leaveType['leave_name']?.toString(),
      approverName:
          approver['display_name']?.toString() ??
          approver['username']?.toString(),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (employeeId != null) 'employee_id': employeeId,
      if (leaveTypeId != null) 'leave_type_id': leaveTypeId,
      if (fromDate != null) 'from_date': fromDate,
      if (toDate != null) 'to_date': toDate,
      if (reason != null) 'reason': reason,
      if (status != null) 'status': status,
      'approved_by': approvedBy,
    };
  }

  static int? _nullableInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '');

  static double? _double(dynamic value) {
    if (value == null) {
      return null;
    }
    return double.tryParse(value.toString());
  }

  static String? _dateString(dynamic value) =>
      value?.toString().split('T').first.split(' ').first;

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return <String, dynamic>{};
  }
}
