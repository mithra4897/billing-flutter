class BusinessLocationModel {
  const BusinessLocationModel({
    required this.id,
    required this.companyId,
    required this.branchId,
    required this.code,
    required this.name,
    this.city,
    this.isActive = true,
    this.raw,
  });

  final int id;
  final int companyId;
  final int branchId;
  final String code;
  final String name;
  final String? city;
  final bool isActive;
  final Map<String, dynamic>? raw;

  factory BusinessLocationModel.fromJson(Map<String, dynamic> json) {
    return BusinessLocationModel(
      id: _parseInt(json['id']),
      companyId: _parseInt(json['company_id']),
      branchId: _parseInt(json['branch_id']),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      city: json['city']?.toString(),
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
