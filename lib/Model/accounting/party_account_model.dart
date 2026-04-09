import '../common/json_model.dart';

class PartyAccountModel implements JsonModel {
  const PartyAccountModel({
    this.id,
    this.partyId,
    this.accountId,
    this.accountPurpose,
    this.isDefault = true,
    this.isActive = true,
    this.remarks,
    this.partyCode,
    this.partyName,
    this.accountCode,
    this.accountName,
    this.accountType,
    this.raw,
  });

  final int? id;
  final int? partyId;
  final int? accountId;
  final String? accountPurpose;
  final bool isDefault;
  final bool isActive;
  final String? remarks;
  final String? partyCode;
  final String? partyName;
  final String? accountCode;
  final String? accountName;
  final String? accountType;
  final Map<String, dynamic>? raw;

  @override
  String toString() => accountName ?? accountCode ?? 'New Party Account';

  factory PartyAccountModel.fromJson(Map<String, dynamic> json) {
    final party = _asMap(json['party']);
    final account = _asMap(json['account']);
    return PartyAccountModel(
      id: _nullableInt(json['id']),
      partyId: _nullableInt(json['party_id'] ?? party['id']),
      accountId: _nullableInt(json['account_id'] ?? account['id']),
      accountPurpose: json['account_purpose']?.toString(),
      isDefault: _bool(json['is_default'], fallback: true),
      isActive: _bool(json['is_active'], fallback: true),
      remarks: json['remarks']?.toString(),
      partyCode: party['party_code']?.toString(),
      partyName:
          party['display_name']?.toString() ??
          party['party_name']?.toString() ??
          party['name']?.toString(),
      accountCode: account['account_code']?.toString(),
      accountName: account['account_name']?.toString(),
      accountType: account['account_type']?.toString(),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (partyId != null) 'party_id': partyId,
      if (accountId != null) 'account_id': accountId,
      if (accountPurpose != null) 'account_purpose': accountPurpose,
      'is_default': isDefault,
      'is_active': isActive,
      if (remarks != null) 'remarks': remarks,
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
