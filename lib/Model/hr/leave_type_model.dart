import '../common/json_model.dart';

class LeaveTypeModel implements JsonModel {
  const LeaveTypeModel({
    this.id,
    this.leaveName,
    this.maxDaysPerYear,
    this.isPaid = true,
    this.raw,
  });

  final int? id;
  final String? leaveName;
  final double? maxDaysPerYear;
  final bool isPaid;
  final Map<String, dynamic>? raw;

  @override
  String toString() => leaveName ?? 'New Leave Type';

  factory LeaveTypeModel.fromJson(Map<String, dynamic> json) {
    return LeaveTypeModel(
      id: _nullableInt(json['id']),
      leaveName: json['leave_name']?.toString(),
      maxDaysPerYear: _double(json['max_days_per_year']),
      isPaid: _bool(json['is_paid'], fallback: true),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (leaveName != null) 'leave_name': leaveName,
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
