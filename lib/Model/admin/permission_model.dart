import '../../screen.dart';

class PermissionModel extends JsonModel {
  const PermissionModel({
    super.id,
    this.module,
    this.code,
    this.name,
    this.description,
    this.isSystemPermission,
    this.isActive,
  });
  final String? module;
  final String? code;
  final String? name;
  final String? description;
  final bool? isSystemPermission;
  final bool? isActive;

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      id: JsonModel.nullableInt(json['id']),
      module: json['module']?.toString(),
      code: json['code']?.toString(),
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      isSystemPermission: json['is_system_permission'] == null
          ? null
          : JsonModel.boolOf(json['is_system_permission']),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
    );
  }
  @override
  String toString() => 'Permission';


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
