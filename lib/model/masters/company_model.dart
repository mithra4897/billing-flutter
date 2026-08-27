import '../../screen.dart';

class CompanyModel extends JsonModel {
  const CompanyModel({
    super.id,
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
    this.dateFormat,
    this.amountGrouping,
    this.decimalPlaces,
    this.lopMultiplier = 1,
    this.lopCalculationBasis = 'working_days',
    this.lopPercentage = 100,
    this.leavePolicies = const <CompanyLeavePolicyModel>[],
  });
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

  final String? dateFormat;
  final String? amountGrouping;
  final int? decimalPlaces;
  final double lopMultiplier;
  final String lopCalculationBasis;
  final double lopPercentage;
  final List<CompanyLeavePolicyModel> leavePolicies;

  @override
  String toString() => tradeName ?? legalName ?? code ?? 'New Company';

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: _parseInt(json['id']),
      code: json['code']?.toString() ?? '',
      legalName: json['legal_name']?.toString() ?? '',
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
      dateFormat: json['date_format']?.toString(),
      amountGrouping: json['amount_grouping']?.toString(),
      decimalPlaces: json['decimal_places'] is int
          ? json['decimal_places'] as int
          : int.tryParse(json['decimal_places']?.toString() ?? ''),
      lopMultiplier:
          double.tryParse(json['lop_multiplier']?.toString() ?? '') ?? 1,
      lopCalculationBasis:
          json['lop_calculation_basis']?.toString() ?? 'working_days',
      lopPercentage:
          double.tryParse(json['lop_percentage']?.toString() ?? '') ?? 100,
      leavePolicies: (json['leave_policies'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (item) => CompanyLeavePolicyModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
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
      if (dateFormat != null) 'date_format': dateFormat,
      if (amountGrouping != null) 'amount_grouping': amountGrouping,
      if (decimalPlaces != null) 'decimal_places': decimalPlaces,
      'lop_multiplier': lopMultiplier,
      'lop_calculation_basis': lopCalculationBasis,
      'lop_percentage': lopPercentage,
      if (leavePolicies.isNotEmpty)
        'leave_policies': leavePolicies
            .map((policy) => policy.toJson())
            .toList(growable: false),
    };
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class CompanyLeavePolicyModel extends JsonModel {
  const CompanyLeavePolicyModel({
    super.id,
    required this.leaveTypeId,
    required this.leaveName,
    required this.leaveCode,
    required this.annualEntitlement,
    required this.accrualMethod,
    required this.excessAction,
    required this.isActive,
    required this.isPaid,
  });

  final int leaveTypeId;
  final String leaveName;
  final String leaveCode;
  final double annualEntitlement;
  final String accrualMethod;
  final String excessAction;
  final bool isActive;
  final bool isPaid;

  factory CompanyLeavePolicyModel.fromJson(Map<String, dynamic> json) {
    final leaveType = json['leave_type'] is Map
        ? Map<String, dynamic>.from(json['leave_type'] as Map)
        : const <String, dynamic>{};
    return CompanyLeavePolicyModel(
      id: _policyInt(json['id']),
      leaveTypeId: _policyInt(json['leave_type_id']) ?? 0,
      leaveName: leaveType['leave_name']?.toString() ?? '',
      leaveCode: leaveType['leave_code']?.toString() ?? '',
      annualEntitlement:
          double.tryParse(json['annual_entitlement']?.toString() ?? '') ?? 0,
      accrualMethod: json['accrual_method']?.toString() ?? 'annual_upfront',
      excessAction: json['excess_action']?.toString() ?? 'convert_to_lop',
      isActive: _policyBool(json['is_active'], fallback: true),
      isPaid: _policyBool(leaveType['is_paid'], fallback: true),
    );
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'leave_type_id': leaveTypeId,
    'annual_entitlement': annualEntitlement,
    'accrual_method': accrualMethod,
    'excess_action': excessAction,
    'is_active': isActive,
  };

  static int? _policyInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '');

  static bool _policyBool(dynamic value, {required bool fallback}) {
    if (value == null) return fallback;
    return value == true || value == 1 || value.toString() == '1';
  }
}
