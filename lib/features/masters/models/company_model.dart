class CompanyModel {
  const CompanyModel({
    required this.id,
    required this.code,
    required this.legalName,
    this.tradeName,
    this.gstin,
    this.pan,
    this.phone,
    this.email,
    this.city,
    this.stateName,
    this.baseCurrency,
    this.logoPath,
    this.sealPath,
    this.letterHeadPath,
    this.isActive = true,
    this.raw,
  });

  final int id;
  final String code;
  final String legalName;
  final String? tradeName;
  final String? gstin;
  final String? pan;
  final String? phone;
  final String? email;
  final String? city;
  final String? stateName;
  final String? baseCurrency;
  final String? logoPath;
  final String? sealPath;
  final String? letterHeadPath;
  final bool isActive;
  final Map<String, dynamic>? raw;

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: _parseInt(json['id']),
      code: json['code']?.toString() ?? json['company_code']?.toString() ?? '',
      legalName:
          json['legal_name']?.toString() ??
          json['company_name']?.toString() ??
          '',
      tradeName: json['trade_name']?.toString(),
      gstin: json['gstin']?.toString(),
      pan: json['pan']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      city: json['city']?.toString(),
      stateName: json['state_name']?.toString(),
      baseCurrency: json['base_currency']?.toString(),
      logoPath: json['logo_path']?.toString(),
      sealPath: json['seal_path']?.toString(),
      letterHeadPath: json['letter_head_path']?.toString(),
      isActive: json['is_active'] != false && json['is_active'] != 0,
      raw: json,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
