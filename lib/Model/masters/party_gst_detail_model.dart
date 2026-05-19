import '../../screen.dart';

class PartyGstDetailModel extends JsonModel {
  const PartyGstDetailModel({
    super.id,
    this.partyId,
    this.gstin,
    this.registrationType,
    this.legalName,
    this.tradeName,
    this.stateCode,
    this.stateName,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.district,
    this.postalCode,
    this.isDefault,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });
  final int? partyId;
  final String? gstin;
  final String? registrationType;
  final String? legalName;
  final String? tradeName;
  final String? stateCode;
  final String? stateName;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? district;
  final String? postalCode;
  final bool? isDefault;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  factory PartyGstDetailModel.fromJson(Map<String, dynamic> json) {
    return PartyGstDetailModel(
      id: ModelValue.nullableInt(json['id']),
      partyId: ModelValue.nullableInt(json['party_id']),
      gstin: json['gstin']?.toString(),
      registrationType: json['registration_type']?.toString(),
      legalName: json['legal_name']?.toString(),
      tradeName: json['trade_name']?.toString(),
      stateCode: json['state_code']?.toString(),
      stateName: json['state_name']?.toString(),
      addressLine1: json['address_line1']?.toString(),
      addressLine2: json['address_line2']?.toString(),
      city: json['city']?.toString(),
      district: json['district']?.toString(),
      postalCode: json['postal_code']?.toString(),
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
  String toString() => 'Party Gst Detail';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (partyId != null) 'party_id': partyId,
    if (gstin != null) 'gstin': gstin,
    if (registrationType != null) 'registration_type': registrationType,
    if (legalName != null) 'legal_name': legalName,
    if (tradeName != null) 'trade_name': tradeName,
    if (stateCode != null) 'state_code': stateCode,
    if (stateName != null) 'state_name': stateName,
    if (addressLine1 != null) 'address_line1': addressLine1,
    if (addressLine2 != null) 'address_line2': addressLine2,
    if (city != null) 'city': city,
    if (district != null) 'district': district,
    if (postalCode != null) 'postal_code': postalCode,
    if (isDefault != null) 'is_default': isDefault,
    if (isActive != null) 'is_active': isActive,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
