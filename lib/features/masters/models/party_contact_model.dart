class PartyContactModel {
  const PartyContactModel({
    required this.id,
    required this.partyId,
    this.contactName,
    this.mobile,
    this.email,
    this.isPrimary = false,
    this.raw,
  });

  final int id;
  final int partyId;
  final String? contactName;
  final String? mobile;
  final String? email;
  final bool isPrimary;
  final Map<String, dynamic>? raw;

  factory PartyContactModel.fromJson(Map<String, dynamic> json) {
    return PartyContactModel(
      id: _parseInt(json['id']),
      partyId: _parseInt(json['party_id']),
      contactName: json['contact_name']?.toString() ?? json['name']?.toString(),
      mobile: json['mobile']?.toString(),
      email: json['email']?.toString(),
      isPrimary: json['is_primary'] == true || json['is_primary'] == 1,
      raw: json,
    );
  }

  static int _parseInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;
}
