import '../../screen.dart';

class PartyPaymentTermModel implements JsonModel {
  const PartyPaymentTermModel({
    this.id,
    this.partyId,
    this.termName,
    this.days,
    this.dueBasis,
    this.remarks,
    this.isDefault,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    Map<String, dynamic>? raw,
  }) : _raw = raw;

  final int? id;
  final int? partyId;
  final String? termName;
  final int? days;
  final String? dueBasis;
  final String? remarks;
  final bool? isDefault;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  factory PartyPaymentTermModel.fromJson(Map<String, dynamic> json) {
    return PartyPaymentTermModel(
      id: ModelValue.nullableInt(json['id']),
      partyId: ModelValue.nullableInt(json['party_id']),
      termName: json['term_name']?.toString(),
      days: ModelValue.nullableInt(json['days']),
      dueBasis: json['due_basis']?.toString(),
      remarks: json['remarks']?.toString(),
      isDefault: json['is_default'] == null
          ? null
          : ModelValue.boolOf(json['is_default']),
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (partyId != null) 'party_id': partyId,
    if (termName != null) 'term_name': termName,
    if (days != null) 'days': days,
    if (dueBasis != null) 'due_basis': dueBasis,
    if (remarks != null) 'remarks': remarks,
    if (isDefault != null) 'is_default': isDefault,
    if (isActive != null) 'is_active': isActive,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
