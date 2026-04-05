class PartyAddressModel {
  const PartyAddressModel({
    required this.id,
    required this.partyId,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.stateName,
    this.stateCode,
    this.postalCode,
    this.countryCode,
    this.raw,
  });

  final int id;
  final int partyId;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? stateName;
  final String? stateCode;
  final String? postalCode;
  final String? countryCode;
  final Map<String, dynamic>? raw;

  factory PartyAddressModel.fromJson(Map<String, dynamic> json) {
    return PartyAddressModel(
      id: _parseInt(json['id']),
      partyId: _parseInt(json['party_id']),
      addressLine1: json['address_line1']?.toString(),
      addressLine2: json['address_line2']?.toString(),
      city: json['city']?.toString(),
      stateName: json['state_name']?.toString(),
      stateCode: json['state_code']?.toString(),
      postalCode: json['postal_code']?.toString(),
      countryCode: json['country_code']?.toString(),
      raw: json,
    );
  }

  static int _parseInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;
}
