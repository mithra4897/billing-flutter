import '../common/json_model.dart';

class BranchModel implements JsonModel {
  const BranchModel({
    this.id,
    this.companyId,
    this.code,
    this.name,
    this.branchType,
    this.isHeadOffice = false,
    this.isActive = true,
    this.remarks,
    this.raw,
  });

  final int? id;
  final int? companyId;
  final String? code;
  final String? name;
  final String? branchType;
  final bool isHeadOffice;
  final bool isActive;
  final String? remarks;
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
      remarks: json['remarks']?.toString(),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (branchType != null) 'branch_type': branchType,
      'is_head_office': isHeadOffice,
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
