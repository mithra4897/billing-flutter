class BranchModel {
  const BranchModel({
    required this.id,
    required this.companyId,
    required this.code,
    required this.name,
    this.branchType,
    this.phone,
    this.email,
    this.city,
    this.isActive = true,
    this.raw,
  });

  final int id;
  final int companyId;
  final String code;
  final String name;
  final String? branchType;
  final String? phone;
  final String? email;
  final String? city;
  final bool isActive;
  final Map<String, dynamic>? raw;

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: _parseInt(json['id']),
      companyId: _parseInt(json['company_id']),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      branchType: json['branch_type']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
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
