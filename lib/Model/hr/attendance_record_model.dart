import '../../screen.dart';

class AttendanceRecordModel implements JsonModel {
  const AttendanceRecordModel({
    this.id,
    this.employeeId,
    this.attendanceDate,
    this.checkIn,
    this.checkOut,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? employeeId;
  final String? attendanceDate;
  final String? checkIn;
  final String? checkOut;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: ModelValue.nullableInt(json['id']),
      employeeId: ModelValue.nullableInt(json['employee_id']),
      attendanceDate: json['attendance_date']?.toString(),
      checkIn: json['check_in']?.toString(),
      checkOut: json['check_out']?.toString(),
      status: json['status']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (employeeId != null) 'employee_id': employeeId,
    if (attendanceDate != null) 'attendance_date': attendanceDate,
    if (checkIn != null) 'check_in': checkIn,
    if (checkOut != null) 'check_out': checkOut,
    if (status != null) 'status': status,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
