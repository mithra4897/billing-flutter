import '../common/json_model.dart';

class PartyAddressModel implements JsonModel {
  const PartyAddressModel({
    this.id,
    this.partyId,
    this.addressType,
    this.addressLine1,
    this.addressLine2,
    this.area,
    this.city,
    this.district,
    this.stateName,
    this.stateCode,
    this.postalCode,
    this.countryCode,
    this.isDefault = false,
    this.isActive = true,
    this.raw,
  });

  final int? id;
  final int? partyId;
  final String? addressType;
  final String? addressLine1;
  final String? addressLine2;
  final String? area;
  final String? city;
  final String? district;
  final String? stateName;
  final String? stateCode;
  final String? postalCode;
  final String? countryCode;
  final bool isDefault;
  final bool isActive;
  final Map<String, dynamic>? raw;

  factory PartyAddressModel.fromJson(Map<String, dynamic> json) {
    return PartyAddressModel(
      id: _parseInt(json['id']),
      partyId: _parseInt(json['party_id']),
      addressType: json['address_type']?.toString(),
      addressLine1: json['address_line1']?.toString(),
      addressLine2: json['address_line2']?.toString(),
      area: json['area']?.toString(),
      city: json['city']?.toString(),
      district: json['district']?.toString(),
      stateName: json['state_name']?.toString(),
      stateCode: json['state_code']?.toString(),
      postalCode: json['postal_code']?.toString(),
      countryCode: json['country_code']?.toString(),
      isDefault: json['is_default'] == true || json['is_default'] == 1,
      isActive: json['is_active'] != false && json['is_active'] != 0,
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (partyId != null) 'party_id': partyId,
      if (addressType != null) 'address_type': addressType,
      if (addressLine1 != null) 'address_line1': addressLine1,
      if (addressLine2 != null) 'address_line2': addressLine2,
      if (area != null) 'area': area,
      if (city != null) 'city': city,
      if (district != null) 'district': district,
      if (stateCode != null) 'state_code': stateCode,
      if (stateName != null) 'state_name': stateName,
      if (countryCode != null) 'country_code': countryCode,
      if (postalCode != null) 'postal_code': postalCode,
      'is_default': isDefault,
      'is_active': isActive,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return null;
    }

    return int.tryParse(value.toString());
  }
}
