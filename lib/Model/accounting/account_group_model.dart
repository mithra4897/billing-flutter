import '../common/json_model.dart';

class AccountGroupModel implements JsonModel {
  const AccountGroupModel({
    this.id,
    this.groupCode,
    this.groupName,
    this.parentGroupId,
    this.groupNature,
    this.groupCategory,
    this.affectsProfitLoss = true,
    this.isSystemGroup = false,
    this.isActive = true,
    this.remarks,
    this.parentGroupCode,
    this.parentGroupName,
    this.raw,
  });

  final int? id;
  final String? groupCode;
  final String? groupName;
  final int? parentGroupId;
  final String? groupNature;
  final String? groupCategory;
  final bool affectsProfitLoss;
  final bool isSystemGroup;
  final bool isActive;
  final String? remarks;
  final String? parentGroupCode;
  final String? parentGroupName;
  final Map<String, dynamic>? raw;

  @override
  String toString() => groupName ?? groupCode ?? 'New Account Group';

  factory AccountGroupModel.fromJson(Map<String, dynamic> json) {
    final parent = _asMap(json['parent']);
    return AccountGroupModel(
      id: _nullableInt(json['id']),
      groupCode: json['group_code']?.toString(),
      groupName: json['group_name']?.toString(),
      parentGroupId: _nullableInt(json['parent_group_id'] ?? parent['id']),
      groupNature: json['group_nature']?.toString(),
      groupCategory: json['group_category']?.toString(),
      affectsProfitLoss: _bool(json['affects_profit_loss'], fallback: true),
      isSystemGroup: _bool(json['is_system_group']),
      isActive: _bool(json['is_active'], fallback: true),
      remarks: json['remarks']?.toString(),
      parentGroupCode: parent['group_code']?.toString(),
      parentGroupName: parent['group_name']?.toString(),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (groupCode != null) 'group_code': groupCode,
      if (groupName != null) 'group_name': groupName,
      'parent_group_id': parentGroupId,
      if (groupNature != null) 'group_nature': groupNature,
      if (groupCategory != null) 'group_category': groupCategory,
      'affects_profit_loss': affectsProfitLoss,
      'is_system_group': isSystemGroup,
      'is_active': isActive,
      if (remarks != null) 'remarks': remarks,
    };
  }

  static int? _nullableInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '');

  static bool _bool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    return value == true || value == 1 || value.toString() == '1';
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return <String, dynamic>{};
  }
}
