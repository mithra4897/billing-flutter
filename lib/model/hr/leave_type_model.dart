import '../../screen.dart';

class LeaveTypeModel extends JsonModel {
  const LeaveTypeModel({
    super.id,
    this.leaveName,
    this.leaveCode,
    this.maxDaysPerYear,
    this.isPaid = true,
  });
  final String? leaveName;
  final String? leaveCode;
  final double? maxDaysPerYear;
  final bool isPaid;

  @override
  String toString() => leaveName ?? 'New Leave Type';

  factory LeaveTypeModel.fromJson(Map<String, dynamic> json) {
    return LeaveTypeModel(
      id: _nullableInt(json['id']),
      leaveName: json['leave_name']?.toString(),
      leaveCode: json['leave_code']?.toString(),
      maxDaysPerYear: _double(json['max_days_per_year']),
      isPaid: _bool(json['is_paid'], fallback: true),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (leaveName != null) 'leave_name': leaveName,
      if (leaveCode != null) 'leave_code': leaveCode,
      if (maxDaysPerYear != null) 'max_days_per_year': maxDaysPerYear,
      'is_paid': isPaid,
    };
  }

  static int? _nullableInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '');

  static double? _double(dynamic value) =>
      double.tryParse(value?.toString() ?? '');

  static bool _bool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    return value == true || value == 1 || value.toString() == '1';
  }
}
