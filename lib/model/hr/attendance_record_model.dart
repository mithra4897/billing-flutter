import '../../screen.dart';

class AttendanceRecordModel extends JsonModel {
  const AttendanceRecordModel({
    super.id,
    this.employeeId,
    this.employeeName,
    this.employeeCode,
    this.attendanceDate,
    this.checkIn,
    this.checkOut,
    this.status,
    this.source,
    this.submissionStatus,
    this.sourceUserId,
    this.createdAt,
    this.updatedAt,
  });
  final int? employeeId;
  final String? employeeName;
  final String? employeeCode;
  final String? attendanceDate;
  final String? checkIn;
  final String? checkOut;
  final String? status;
  final String? source;
  final String? submissionStatus;
  final int? sourceUserId;
  final String? createdAt;
  final String? updatedAt;

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'] is Map
        ? Map<String, dynamic>.from(json['employee'] as Map)
        : const <String, dynamic>{};
    return AttendanceRecordModel(
      id: JsonModel.nullableInt(json['id']),
      employeeId: JsonModel.nullableInt(json['employee_id'] ?? employee['id']),
      employeeName:
          employee['employee_name']?.toString() ??
          json['employee_name']?.toString(),
      employeeCode:
          employee['employee_code']?.toString() ??
          json['employee_code']?.toString(),
      attendanceDate: json['attendance_date']?.toString(),
      checkIn: json['check_in']?.toString(),
      checkOut: json['check_out']?.toString(),
      status: json['status']?.toString(),
      source: json['source']?.toString(),
      submissionStatus: json['submission_status']?.toString(),
      sourceUserId: JsonModel.nullableInt(json['source_user_id']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    attendanceDate,
  ], defaultValue: 'Attendance Record');

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (employeeId != null) 'employee_id': employeeId,
    if (employeeName != null) 'employee_name': employeeName,
    if (employeeCode != null) 'employee_code': employeeCode,
    if (attendanceDate != null) 'attendance_date': attendanceDate,
    if (checkIn != null) 'check_in': checkIn,
    if (checkOut != null) 'check_out': checkOut,
    if (status != null) 'status': status,
    if (source != null) 'source': source,
    if (submissionStatus != null) 'submission_status': submissionStatus,
    if (sourceUserId != null) 'source_user_id': sourceUserId,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
