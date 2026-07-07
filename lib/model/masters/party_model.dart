import '../../screen.dart';

class PartyModel extends JsonModel {
  const PartyModel({
    super.id,
    this.companyId,
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
    this.gstDetails = const [],
  });
  final int? companyId;
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
  final List<PartyGstDetailModel> gstDetails;

  @override
  String toString() => displayName ?? partyName ?? partyCode ?? 'New Party';

  PartyModel copyWith({
    int? companyId,
    String? partyCode,
    String? partyName,
    String? displayName,
    int? partyTypeId,
    String? partyType,
    bool? isCompany,
    String? website,
    String? pan,
    String? aadhaar,
    String? defaultCurrency,
    double? openingBalance,
    String? openingBalanceType,
    String? remarks,
    bool? isActive,
    List<PartyAddressModel>? addresses,
    List<PartyContactModel>? contacts,
    List<PartyGstDetailModel>? gstDetails,
  }) {
    return PartyModel(
      id: id,
      companyId: companyId ?? this.companyId,
      partyCode: partyCode ?? this.partyCode,
      partyName: partyName ?? this.partyName,
      displayName: displayName ?? this.displayName,
      partyTypeId: partyTypeId ?? this.partyTypeId,
      partyType: partyType ?? this.partyType,
      isCompany: isCompany ?? this.isCompany,
      website: website ?? this.website,
      pan: pan ?? this.pan,
      aadhaar: aadhaar ?? this.aadhaar,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      openingBalance: openingBalance ?? this.openingBalance,
      openingBalanceType: openingBalanceType ?? this.openingBalanceType,
      remarks: remarks ?? this.remarks,
      isActive: isActive ?? this.isActive,
      addresses: addresses ?? this.addresses,
      contacts: contacts ?? this.contacts,
      gstDetails: gstDetails ?? this.gstDetails,
    );
  }

  factory PartyModel.fromJson(Map<String, dynamic> json) {
    final partyTypeData = json['party_type'];
    final partyTypeRelation =
        partyTypeData is Map<String, dynamic> ? partyTypeData : null;
    final partyTypeName =
        json['party_type_name']?.toString() ??
        partyTypeRelation?['name']?.toString() ??
        json['party_type']?.toString();

    return PartyModel(
      id: _parseInt(json['id']),
      companyId: _parseInt(json['company_id']),
      partyCode: json['party_code']?.toString() ?? '',
      partyName: json['party_name']?.toString() ?? '',
      displayName: json['display_name']?.toString(),
      partyTypeId: _parseInt(json['party_type_id']),
      partyType: partyTypeName,
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
      gstDetails: _mapList(
        json['gst_details'],
        (item) => PartyGstDetailModel.fromJson(item),
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
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
      if (addresses.isNotEmpty)
        'addresses': addresses
            .map((address) => address.toJson())
            .toList(growable: false),
      if (contacts.isNotEmpty)
        'contacts': contacts
            .map((contact) => contact.toJson())
            .toList(growable: false),
      if (gstDetails.isNotEmpty)
        'gst_details': gstDetails
            .map((detail) => detail.toJson())
            .toList(growable: false),
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
