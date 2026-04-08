import '../common/json_model.dart';
import 'party_address_model.dart';
import 'party_contact_model.dart';

class PartyModel implements JsonModel {
  const PartyModel({
    this.id,
    this.partyCode,
    this.partyName,
    this.displayName,
    this.partyTypeId,
    this.partyType,
    this.isCompany = false,
    this.website,
    this.pan,
    this.aadhaar,
    this.defaultCurrency,
    this.openingBalance,
    this.openingBalanceType,
    this.remarks,
    this.isActive = true,
    this.addresses = const [],
    this.contacts = const [],
    this.raw,
  });

  final int? id;
  final String? partyCode;
  final String? partyName;
  final String? displayName;
  final int? partyTypeId;
  final String? partyType;
  final bool isCompany;
  final String? website;
  final String? pan;
  final String? aadhaar;
  final String? defaultCurrency;
  final double? openingBalance;
  final String? openingBalanceType;
  final String? remarks;
  final bool isActive;
  final List<PartyAddressModel> addresses;
  final List<PartyContactModel> contacts;
  final Map<String, dynamic>? raw;

  @override
  String toString() => displayName ?? partyName ?? partyCode ?? 'New Party';

  factory PartyModel.fromJson(Map<String, dynamic> json) {
    return PartyModel(
      id: _parseInt(json['id']),
      partyCode: json['party_code']?.toString() ?? '',
      partyName: json['party_name']?.toString() ?? '',
      displayName: json['display_name']?.toString(),
      partyTypeId: _parseInt(json['party_type_id']),
      partyType: json['party_type_id']?.toString(),
      isCompany: json['is_company'] == true || json['is_company'] == 1,
      website: json['website']?.toString(),
      pan: json['pan']?.toString(),
      aadhaar: json['aadhaar']?.toString(),
      defaultCurrency: json['default_currency']?.toString(),
      openingBalance: _parseDouble(json['opening_balance']),
      openingBalanceType: json['opening_balance_type']?.toString(),
      remarks: json['remarks']?.toString(),
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

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (partyCode != null) 'party_code': partyCode,
      if (partyName != null) 'party_name': partyName,
      if (displayName != null) 'display_name': displayName,
      if (partyTypeId != null) 'party_type_id': partyTypeId,
      'is_company': isCompany,
      if (website != null) 'website': website,
      if (pan != null) 'pan': pan,
      if (aadhaar != null) 'aadhaar': aadhaar,
      if (defaultCurrency != null) 'default_currency': defaultCurrency,
      if (openingBalance != null) 'opening_balance': openingBalance,
      if (openingBalanceType != null)
        'opening_balance_type': openingBalanceType,
      if (remarks != null) 'remarks': remarks,
      'is_active': isActive,
    };
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

  static int? _parseInt(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return null;
    }

    return int.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '');
}
