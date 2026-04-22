import '../common/json_model.dart';

class AccountModel implements JsonModel {
  const AccountModel({
    this.id,
    this.companyId,
    this.branchId,
    this.accountCode,
    this.accountName,
    this.accountGroupId,
    this.accountType,
    this.openingBalance,
    this.openingBalanceType,
    this.currencyCode,
    this.allowManualEntries = true,
    this.allowReconciliation = false,
    this.isControlAccount = false,
    this.isSystemAccount = false,
    this.isActive = true,
    this.remarks,
    this.companyCode,
    this.companyName,
    this.branchCode,
    this.branchName,
    this.accountGroupCode,
    this.accountGroupName,
    this.accountGroupNature,
    this.accountGroupCategory,
    this.raw,
  });

  final int? id;
  final int? companyId;
  final int? branchId;
  final String? accountCode;
  final String? accountName;
  final int? accountGroupId;
  final String? accountType;
  final double? openingBalance;
  final String? openingBalanceType;
  final String? currencyCode;
  final bool allowManualEntries;
  final bool allowReconciliation;
  final bool isControlAccount;
  final bool isSystemAccount;
  final bool isActive;
  final String? remarks;
  final String? companyCode;
  final String? companyName;
  final String? branchCode;
  final String? branchName;
  final String? accountGroupCode;
  final String? accountGroupName;
  final String? accountGroupNature;
  final String? accountGroupCategory;
  final Map<String, dynamic>? raw;

  @override
  String toString() => accountName ?? accountCode ?? 'New Account';

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    final company = _asMap(json['company']);
    final branch = _asMap(json['branch']);
    final accountGroup = _asMap(json['account_group'] ?? json['accountGroup']);
    return AccountModel(
      id: _nullableInt(json['id']),
      companyId: _nullableInt(json['company_id'] ?? company['id']),
      branchId: _nullableInt(json['branch_id'] ?? branch['id']),
      accountCode: json['account_code']?.toString(),
      accountName: json['account_name']?.toString(),
      accountGroupId: _nullableInt(
        json['account_group_id'] ?? accountGroup['id'],
      ),
      accountType: json['account_type']?.toString(),
      openingBalance: _double(json['opening_balance']),
      openingBalanceType: json['opening_balance_type']?.toString(),
      currencyCode: json['currency_code']?.toString(),
      allowManualEntries: _bool(json['allow_manual_entries'], fallback: true),
      allowReconciliation: _bool(json['allow_reconciliation']),
      isControlAccount: _bool(json['is_control_account']),
      isSystemAccount: _bool(json['is_system_account']),
      isActive: _bool(json['is_active'], fallback: true),
      remarks: json['remarks']?.toString(),
      companyCode: company['code']?.toString(),
      companyName:
          company['trade_name']?.toString() ??
          company['legal_name']?.toString() ??
          company['code']?.toString(),
      branchCode: branch['code']?.toString(),
      branchName: branch['name']?.toString(),
      accountGroupCode: accountGroup['group_code']?.toString(),
      accountGroupName: accountGroup['group_name']?.toString(),
      accountGroupNature: accountGroup['group_nature']?.toString(),
      accountGroupCategory: accountGroup['group_category']?.toString(),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      'branch_id': branchId,
      if (accountCode != null) 'account_code': accountCode,
      if (accountName != null) 'account_name': accountName,
      if (accountGroupId != null) 'account_group_id': accountGroupId,
      if (accountType != null) 'account_type': accountType,
      if (openingBalance != null) 'opening_balance': openingBalance,
      if (openingBalanceType != null)
        'opening_balance_type': openingBalanceType,
      if (currencyCode != null) 'currency_code': currencyCode,
      'allow_manual_entries': allowManualEntries,
      'allow_reconciliation': allowReconciliation,
      'is_control_account': isControlAccount,
      'is_system_account': isSystemAccount,
      'is_active': isActive,
      if (remarks != null) 'remarks': remarks,
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

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return <String, dynamic>{};
  }
}
