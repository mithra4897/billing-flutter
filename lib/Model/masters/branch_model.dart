class BranchModel {
  const BranchModel({
    required this.id,
    required this.companyId,
    required this.code,
    required this.name,
    this.branchType,
    this.isHeadOffice = false,
    this.isActive = true,
    this.raw,
  });

  final int id;
  final int companyId;
  final String code;
  final String name;
  final String? branchType;
  final bool isHeadOffice;
  final bool isActive;
  final Map<String, dynamic>? raw;

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: _parseInt(json['id']),
      companyId: _parseInt(json['company_id']),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      branchType: json['branch_type']?.toString(),
      isHeadOffice:
          json['is_head_office'] == true || json['is_head_office'] == 1,
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
