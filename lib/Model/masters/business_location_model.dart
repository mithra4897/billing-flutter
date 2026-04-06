import '../common/json_model.dart';

class BusinessLocationModel implements JsonModel {
  const BusinessLocationModel({
    this.id,
    this.companyId,
    this.branchId,
    this.code,
    this.name,
    this.locationType,
    this.contactPerson,
    this.phone,
    this.email,
    this.addressLine1,
    this.addressLine2,
    this.area,
    this.city,
    this.district,
    this.stateCode,
    this.stateName,
    this.countryCode,
    this.postalCode,
    this.allowSales = true,
    this.allowPurchase = true,
    this.allowStock = true,
    this.allowAccounts = true,
    this.allowHr = true,
    this.isDefault = false,
    this.isActive = true,
    this.remarks,
    this.raw,
  });

  final int? id;
  final int? companyId;
  final int? branchId;
  final String? code;
  final String? name;
  final String? locationType;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? addressLine1;
  final String? addressLine2;
  final String? area;
  final String? city;
  final String? district;
  final String? stateCode;
  final String? stateName;
  final String? countryCode;
  final String? postalCode;
  final bool allowSales;
  final bool allowPurchase;
  final bool allowStock;
  final bool allowAccounts;
  final bool allowHr;
  final bool isDefault;
  final bool isActive;
  final String? remarks;
  final Map<String, dynamic>? raw;

  factory BusinessLocationModel.fromJson(Map<String, dynamic> json) {
    return BusinessLocationModel(
      id: _parseInt(json['id']),
      companyId: _parseInt(json['company_id']),
      branchId: _parseInt(json['branch_id']),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      locationType: json['location_type']?.toString(),
      contactPerson: json['contact_person']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      addressLine1: json['address_line1']?.toString(),
      addressLine2: json['address_line2']?.toString(),
      area: json['area']?.toString(),
      city: json['city']?.toString(),
      district: json['district']?.toString(),
      stateCode: json['state_code']?.toString(),
      stateName: json['state_name']?.toString(),
      countryCode: json['country_code']?.toString(),
      postalCode: json['postal_code']?.toString(),
      allowSales: json['allow_sales'] != false && json['allow_sales'] != 0,
      allowPurchase:
          json['allow_purchase'] != false && json['allow_purchase'] != 0,
      allowStock: json['allow_stock'] != false && json['allow_stock'] != 0,
      allowAccounts:
          json['allow_accounts'] != false && json['allow_accounts'] != 0,
      allowHr: json['allow_hr'] != false && json['allow_hr'] != 0,
      isDefault: json['is_default'] == true || json['is_default'] == 1,
      isActive: json['is_active'] != false && json['is_active'] != 0,
      remarks: json['remarks']?.toString(),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (branchId != null) 'branch_id': branchId,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (locationType != null) 'location_type': locationType,
      if (contactPerson != null) 'contact_person': contactPerson,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (addressLine1 != null) 'address_line1': addressLine1,
      if (addressLine2 != null) 'address_line2': addressLine2,
      if (area != null) 'area': area,
      if (city != null) 'city': city,
      if (district != null) 'district': district,
      if (stateCode != null) 'state_code': stateCode,
      if (stateName != null) 'state_name': stateName,
      if (countryCode != null) 'country_code': countryCode,
      if (postalCode != null) 'postal_code': postalCode,
      'allow_sales': allowSales,
      'allow_purchase': allowPurchase,
      'allow_stock': allowStock,
      'allow_accounts': allowAccounts,
      'allow_hr': allowHr,
      'is_default': isDefault,
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
