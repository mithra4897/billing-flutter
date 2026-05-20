import '../../screen.dart';

class PartyCreditLimitModel extends JsonModel {
  const PartyCreditLimitModel({
    super.id,
    this.partyId,
    this.creditLimit,
    this.creditDays,
    this.effectiveFrom,
    this.effectiveTo,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });
  final int? partyId;
  final double? creditLimit;
  final int? creditDays;
  final String? effectiveFrom;
  final String? effectiveTo;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  factory PartyCreditLimitModel.fromJson(Map<String, dynamic> json) {
    return PartyCreditLimitModel(
      id: JsonModel.nullableInt(json['id']),
      partyId: JsonModel.nullableInt(json['party_id']),
      creditLimit: JsonModel.nullableDouble(json['credit_limit']),
      creditDays: JsonModel.nullableInt(json['credit_days']),
      effectiveFrom: json['effective_from']?.toString(),
      effectiveTo: json['effective_to']?.toString(),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    creditLimit,
    creditDays,
    effectiveFrom,
    effectiveTo,
  ], defaultValue: 'Party Credit Limit');


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (partyId != null) 'party_id': partyId,
    if (creditLimit != null) 'credit_limit': creditLimit,
    if (creditDays != null) 'credit_days': creditDays,
    if (effectiveFrom != null) 'effective_from': effectiveFrom,
    if (effectiveTo != null) 'effective_to': effectiveTo,
    if (isActive != null) 'is_active': isActive,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
