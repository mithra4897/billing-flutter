import '../../screen.dart';

class MonthlyAttendanceSheetModel {
  const MonthlyAttendanceSheetModel({
    required this.year,
    required this.month,
    required this.daysInMonth,
    required this.today,
    required this.weeklyOffDays,
    required this.employees,
    required this.attendance,
  });

  final int year;
  final int month;
  final int daysInMonth;
  final String today;
  final List<int> weeklyOffDays;
  final List<MonthlyAttendanceEmployeeModel> employees;
  final List<AttendanceRecordModel> attendance;

  factory MonthlyAttendanceSheetModel.fromJson(Map<String, dynamic> json) {
    return MonthlyAttendanceSheetModel(
      year: JsonModel.nullableInt(json['year']) ?? DateTime.now().year,
      month: JsonModel.nullableInt(json['month']) ?? DateTime.now().month,
      daysInMonth: JsonModel.nullableInt(json['days_in_month']) ?? 31,
      today: json['today']?.toString() ?? '',
      weeklyOffDays: (json['weekly_off_days'] as List? ?? const <dynamic>[])
          .map(JsonModel.nullableInt)
          .whereType<int>()
          .toList(growable: false),
      employees: (json['employees'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (value) => MonthlyAttendanceEmployeeModel.fromJson(
              Map<String, dynamic>.from(value),
            ),
          )
          .toList(growable: false),
      attendance: (json['attendance'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (value) => AttendanceRecordModel.fromJson(
              Map<String, dynamic>.from(value),
            ),
          )
          .toList(growable: false),
    );
  }
}

class MonthlyAttendanceEmployeeModel {
  const MonthlyAttendanceEmployeeModel({
    required this.id,
    required this.employeeName,
    this.employeeCode,
    this.joiningDate,
    this.relievingDate,
    required this.hasSystemAccess,
  });

  final int id;
  final String employeeName;
  final String? employeeCode;
  final String? joiningDate;
  final String? relievingDate;
  final bool hasSystemAccess;

  factory MonthlyAttendanceEmployeeModel.fromJson(Map<String, dynamic> json) {
    return MonthlyAttendanceEmployeeModel(
      id: JsonModel.nullableInt(json['id']) ?? 0,
      employeeName: json['employee_name']?.toString() ?? 'Employee',
      employeeCode: json['employee_code']?.toString(),
      joiningDate: json['joining_date']?.toString(),
      relievingDate: json['relieving_date']?.toString(),
      hasSystemAccess:
          json['has_system_access'] == true || json['has_system_access'] == 1,
    );
  }
}
