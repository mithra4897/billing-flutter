class AccountModel {
  const AccountModel({
    required this.id,
    required this.accountCode,
    required this.accountName,
    this.companyId,
    this.accountType,
    this.accountGroupId,
    this.isActive = true,
    this.raw,
  });

  final int id;
  final String accountCode;
  final String accountName;
  final int? companyId;
  final String? accountType;
  final int? accountGroupId;
  final bool isActive;
  final Map<String, dynamic>? raw;

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: _parseInt(json['id']),
      accountCode: json['account_code']?.toString() ?? '',
      accountName: json['account_name']?.toString() ?? '',
      companyId: _nullableInt(json['company_id']),
      accountType: json['account_type']?.toString(),
      accountGroupId: _nullableInt(json['account_group_id']),
      isActive: json['is_active'] != false && json['is_active'] != 0,
      raw: json,
    );
  }

  static int _parseInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;

  static int? _nullableInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '');
}
