import '../../screen.dart';

class PartyRoleModel extends JsonModel {
  const PartyRoleModel({
    super.id,
    this.partyId,
    this.partyTypeId,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });
  final int? partyId;
  final int? partyTypeId;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  factory PartyRoleModel.fromJson(Map<String, dynamic> json) {
    return PartyRoleModel(
      id: JsonModel.nullableInt(json['id']),
      partyId: JsonModel.nullableInt(json['party_id']),
      partyTypeId: JsonModel.nullableInt(json['party_type_id']),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Party Role';


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
