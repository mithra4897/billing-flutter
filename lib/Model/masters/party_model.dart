import 'party_address_model.dart';
import 'party_contact_model.dart';

class PartyModel {
  const PartyModel({
    required this.id,
    required this.partyCode,
    required this.partyName,
    this.displayName,
    this.partyType,
    this.mobile,
    this.email,
    this.gstin,
    this.pan,
    this.isActive = true,
    this.addresses = const [],
    this.contacts = const [],
    this.raw,
  });

  final int id;
  final String partyCode;
  final String partyName;
  final String? displayName;
  final String? partyType;
  final String? mobile;
  final String? email;
  final String? gstin;
  final String? pan;
  final bool isActive;
  final List<PartyAddressModel> addresses;
  final List<PartyContactModel> contacts;
  final Map<String, dynamic>? raw;

  factory PartyModel.fromJson(Map<String, dynamic> json) {
    return PartyModel(
      id: _parseInt(json['id']),
      partyCode: json['party_code']?.toString() ?? '',
      partyName: json['party_name']?.toString() ?? '',
      displayName: json['display_name']?.toString(),
      partyType: json['party_type']?.toString(),
      mobile: json['mobile']?.toString(),
      email: json['email']?.toString(),
      gstin: json['gstin']?.toString(),
      pan: json['pan']?.toString(),
      isActive: json['is_active'] != false && json['is_active'] != 0,
      addresses: _mapList(
        json['addresses'],
        (item) => PartyAddressModel.fromJson(item),
      ),
      contacts: _mapList(
        json['contacts'],
        (item) => PartyContactModel.fromJson(item),
      ),
      raw: json,
    );
  }

  static List<T> _mapList<T>(
    dynamic value,
    T Function(Map<String, dynamic> json) mapper,
  ) {
    if (value is! List) {
      return <T>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(mapper)
        .toList(growable: false);
  }

  static int _parseInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;
}
