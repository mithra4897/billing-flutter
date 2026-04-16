class EmployeeAddressModel {
  const EmployeeAddressModel({
    this.id,
    this.employeeId,
    this.addressType,
    this.addressLine1,
    this.addressLine2,
    this.landmark,
    this.city,
    this.stateName,
    this.postalCode,
    this.country,
    this.phoneNumber,
  });

  final int? id;
  final int? employeeId;
  final String? addressType;
  final String? addressLine1;
  final String? addressLine2;
  final String? landmark;
  final String? city;
  final String? stateName;
  final String? postalCode;
  final String? country;
  final String? phoneNumber;

  factory EmployeeAddressModel.fromJson(Map<String, dynamic> json) {
    return EmployeeAddressModel(
      id: _nullableInt(json['id']),
      employeeId: _nullableInt(json['employee_id']),
      addressType: json['address_type']?.toString(),
      addressLine1: json['address_line1']?.toString(),
      addressLine2: json['address_line2']?.toString(),
      landmark: json['landmark']?.toString(),
      city: json['city']?.toString(),
      stateName: json['state_name']?.toString(),
      postalCode: json['postal_code']?.toString(),
      country: json['country']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (employeeId != null) 'employee_id': employeeId,
      if (addressType != null) 'address_type': addressType,
      if (addressLine1 != null) 'address_line1': addressLine1,
      if (addressLine2 != null) 'address_line2': addressLine2,
      if (landmark != null) 'landmark': landmark,
      if (city != null) 'city': city,
      if (stateName != null) 'state_name': stateName,
      if (postalCode != null) 'postal_code': postalCode,
      if (country != null) 'country': country,
      if (phoneNumber != null) 'phone_number': phoneNumber,
    };
  }

  static int? _nullableInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '');
}
