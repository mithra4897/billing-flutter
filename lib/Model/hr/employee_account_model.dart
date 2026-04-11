import '../common/json_model.dart';

class EmployeeAccountModel implements JsonModel {
  const EmployeeAccountModel({
    this.id,
    this.employeeId,
    this.accountId,
    this.accountPurpose,
    this.isDefault = false,
    this.isActive = true,
    this.accountCode,
    this.accountName,
    this.raw,
  });

  final int? id;
  final int? employeeId;
  final int? accountId;
  final String? accountPurpose;
  final bool isDefault;
  final bool isActive;
  final String? accountCode;
  final String? accountName;
  final Map<String, dynamic>? raw;

  @override
  String toString() => accountName ?? accountCode ?? 'Employee Account';

  factory EmployeeAccountModel.fromJson(Map<String, dynamic> json) {
    final account = _asMap(json['account']);
    return EmployeeAccountModel(
      id: _nullableInt(json['id']),
      employeeId: _nullableInt(json['employee_id']),
      accountId: _nullableInt(json['account_id'] ?? account['id']),
      accountPurpose: json['account_purpose']?.toString(),
      isDefault: _bool(json['is_default']),
      isActive: _bool(json['is_active'], fallback: true),
      accountCode: account['account_code']?.toString(),
      accountName: account['account_name']?.toString(),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (employeeId != null) 'employee_id': employeeId,
      if (accountId != null) 'account_id': accountId,
      if (accountPurpose != null) 'account_purpose': accountPurpose,
      'is_default': isDefault,
      'is_active': isActive,
    };
  }

  static int? _nullableInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '');

  static bool _bool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    return value == true || value == 1 || value.toString() == '1';
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return <String, dynamic>{};
  }
}
