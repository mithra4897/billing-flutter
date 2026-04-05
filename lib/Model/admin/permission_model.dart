import '../common/json_model.dart';
import '../common/model_value.dart';

class PermissionModel implements JsonModel {
  const PermissionModel({
    this.id,
    this.module,
    this.code,
    this.name,
    this.description,
    this.isSystemPermission,
    this.isActive,
    this.raw,
  });

  final int? id;
  final String? module;
  final String? code;
  final String? name;
  final String? description;
  final bool? isSystemPermission;
  final bool? isActive;
  final Map<String, dynamic>? raw;

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      id: ModelValue.nullableInt(json['id']),
      module: json['module']?.toString(),
      code: json['code']?.toString(),
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      isSystemPermission: json['is_system_permission'] == null
          ? null
          : ModelValue.boolOf(json['is_system_permission']),
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (module != null) 'module': module,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (isSystemPermission != null)
        'is_system_permission': isSystemPermission,
      if (isActive != null) 'is_active': isActive,
    };
  }
}
