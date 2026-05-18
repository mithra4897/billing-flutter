import '../../screen.dart';

class PartyRoleModel implements JsonModel {
  const PartyRoleModel({
    this.id,
    this.partyId,
    this.partyTypeId,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? partyId;
  final int? partyTypeId;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  factory PartyRoleModel.fromJson(Map<String, dynamic> json) {
    return PartyRoleModel(
      id: ModelValue.nullableInt(json['id']),
      partyId: ModelValue.nullableInt(json['party_id']),
      partyTypeId: ModelValue.nullableInt(json['party_type_id']),
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
    if (partyTypeId != null) 'party_type_id': partyTypeId,
    if (isActive != null) 'is_active': isActive,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
