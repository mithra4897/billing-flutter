import '../common/json_model.dart';

class CashSessionModel implements JsonModel {
  const CashSessionModel({
    this.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.userId,
    this.cashAccountId,
    this.openingDatetime,
    this.closingDatetime,
    this.openingBalance,
    this.expectedClosingBalance,
    this.actualClosingBalance,
    this.varianceAmount,
    this.status,
    this.remarks,
    this.companyName,
    this.branchName,
    this.locationName,
    this.username,
    this.userDisplayName,
    this.cashAccountCode,
    this.cashAccountName,
    this.raw,
  });

  final int? id;
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? userId;
  final int? cashAccountId;
  final String? openingDatetime;
  final String? closingDatetime;
  final double? openingBalance;
  final double? expectedClosingBalance;
  final double? actualClosingBalance;
  final double? varianceAmount;
  final String? status;
  final String? remarks;
  final String? companyName;
  final String? branchName;
  final String? locationName;
  final String? username;
  final String? userDisplayName;
  final String? cashAccountCode;
  final String? cashAccountName;
  final Map<String, dynamic>? raw;

  @override
  String toString() => cashAccountName ?? cashAccountCode ?? 'Cash Session';

  factory CashSessionModel.fromJson(Map<String, dynamic> json) {
    final company = _asMap(json['company']);
    final branch = _asMap(json['branch']);
    final location = _asMap(json['location']);
    final user = _asMap(json['user']);
    final cashAccount = _asMap(json['cash_account'] ?? json['cashAccount']);
    return CashSessionModel(
      id: _nullableInt(json['id']),
      companyId: _nullableInt(json['company_id'] ?? company['id']),
      branchId: _nullableInt(json['branch_id'] ?? branch['id']),
      locationId: _nullableInt(json['location_id'] ?? location['id']),
      userId: _nullableInt(json['user_id'] ?? user['id']),
      cashAccountId: _nullableInt(json['cash_account_id'] ?? cashAccount['id']),
      openingDatetime: json['opening_datetime']?.toString(),
      closingDatetime: json['closing_datetime']?.toString(),
      openingBalance: _double(json['opening_balance']),
      expectedClosingBalance: _double(json['expected_closing_balance']),
      actualClosingBalance: _double(json['actual_closing_balance']),
      varianceAmount: _double(json['variance_amount']),
      status: json['status']?.toString(),
      remarks: json['remarks']?.toString(),
      companyName:
          company['trade_name']?.toString() ??
          company['legal_name']?.toString() ??
          company['code']?.toString(),
      branchName: branch['name']?.toString(),
      locationName: location['name']?.toString(),
      username: user['username']?.toString(),
      userDisplayName: user['display_name']?.toString(),
      cashAccountCode: cashAccount['account_code']?.toString(),
      cashAccountName: cashAccount['account_name']?.toString(),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (branchId != null) 'branch_id': branchId,
      if (locationId != null) 'location_id': locationId,
      if (userId != null) 'user_id': userId,
      if (cashAccountId != null) 'cash_account_id': cashAccountId,
      if (openingDatetime != null) 'opening_datetime': openingDatetime,
      if (closingDatetime != null) 'closing_datetime': closingDatetime,
      if (openingBalance != null) 'opening_balance': openingBalance,
      if (expectedClosingBalance != null)
        'expected_closing_balance': expectedClosingBalance,
      if (actualClosingBalance != null)
        'actual_closing_balance': actualClosingBalance,
      if (status != null) 'status': status,
      if (remarks != null) 'remarks': remarks,
    };
  }

  static int? _nullableInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '');

  static double? _double(dynamic value) =>
      double.tryParse(value?.toString() ?? '');

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return <String, dynamic>{};
  }
}
