import '../common/json_model.dart';

class CompanyModel implements JsonModel {
  const CompanyModel({
    this.id,
    this.code,
    this.legalName,
    this.tradeName,
    this.companyType,
    this.gstin,
    this.pan,
    this.tan,
    this.cin,
    this.phone,
    this.email,
    this.website,
    this.addressLine1,
    this.addressLine2,
    this.area,
    this.city,
    this.district,
    this.stateCode,
    this.stateName,
    this.baseCurrency,
    this.timezone,
    this.logoPath,
    this.sealPath,
    this.letterHeadPath,
    this.postalCode,
    this.countryCode,
    this.remarks,
    this.isActive = true,
    this.raw,
  });

  final int? id;
  final String? code;
  final String? legalName;
  final String? tradeName;
  final String? companyType;
  final String? gstin;
  final String? pan;
  final String? tan;
  final String? cin;
  final String? phone;
  final String? email;
  final String? website;
  final String? addressLine1;
  final String? addressLine2;
  final String? area;
  final String? city;
  final String? district;
  final String? stateCode;
  final String? stateName;
  final String? baseCurrency;
  final String? timezone;
  final String? logoPath;
  final String? sealPath;
  final String? letterHeadPath;
  final String? postalCode;
  final String? countryCode;
  final String? remarks;
  final bool isActive;
  final Map<String, dynamic>? raw;

  @override
  String toString() => tradeName ?? legalName ?? code ?? 'New Company';

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: _parseInt(json['id']),
      code: json['code']?.toString() ?? json['company_code']?.toString() ?? '',
      legalName:
          json['legal_name']?.toString() ??
          json['company_name']?.toString() ??
          '',
      tradeName: json['trade_name']?.toString(),
      companyType: json['company_type']?.toString(),
      gstin: json['gstin']?.toString(),
      pan: json['pan']?.toString(),
      tan: json['tan']?.toString(),
      cin: json['cin']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      website: json['website']?.toString(),
      addressLine1: json['address_line1']?.toString(),
      addressLine2: json['address_line2']?.toString(),
      area: json['area']?.toString(),
      city: json['city']?.toString(),
      district: json['district']?.toString(),
      stateCode: json['state_code']?.toString(),
      stateName: json['state_name']?.toString(),
      baseCurrency: json['base_currency']?.toString(),
      timezone: json['timezone']?.toString(),
      logoPath: json['logo_path']?.toString(),
      sealPath: json['seal_path']?.toString(),
      letterHeadPath: json['letter_head_path']?.toString(),
      postalCode: json['postal_code']?.toString(),
      countryCode: json['country_code']?.toString(),
      remarks: json['remarks']?.toString(),
      isActive: json['is_active'] != false && json['is_active'] != 0,
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (legalName != null) 'legal_name': legalName,
      if (tradeName != null) 'trade_name': tradeName,
      if (companyType != null) 'company_type': companyType,
      if (gstin != null) 'gstin': gstin,
      if (pan != null) 'pan': pan,
      if (tan != null) 'tan': tan,
      if (cin != null) 'cin': cin,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (website != null) 'website': website,
      if (addressLine1 != null) 'address_line1': addressLine1,
      if (addressLine2 != null) 'address_line2': addressLine2,
      if (area != null) 'area': area,
      if (city != null) 'city': city,
      if (district != null) 'district': district,
      if (stateCode != null) 'state_code': stateCode,
      if (stateName != null) 'state_name': stateName,
      if (baseCurrency != null) 'base_currency': baseCurrency,
      if (timezone != null) 'timezone': timezone,
      if (logoPath != null) 'logo_path': logoPath,
      if (sealPath != null) 'seal_path': sealPath,
      if (letterHeadPath != null) 'letter_head_path': letterHeadPath,
      if (postalCode != null) 'postal_code': postalCode,
      if (countryCode != null) 'country_code': countryCode,
      'is_active': isActive,
      if (remarks != null) 'remarks': remarks,
    };
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
