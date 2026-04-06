import '../admin/permission_model.dart';
import '../common/json_model.dart';
import '../common/model_value.dart';

class RolePermissionModel implements JsonModel {
  const RolePermissionModel({
    this.id,
    this.permissionId,
    this.module,
    this.code,
    this.name,
    this.description,
    this.isSystemPermission,
    this.permissionIsActive,
    this.rolePermissionIsActive,
    this.allowView,
    this.allowCreate,
    this.allowUpdate,
    this.allowDelete,
    this.allowApprove,
    this.allowPrint,
    this.allowExport,
    this.permission,
  });

  final int? id;
  final int? permissionId;
  final String? module;
  final String? code;
  final String? name;
  final String? description;
  final bool? isSystemPermission;
  final bool? permissionIsActive;
  final bool? rolePermissionIsActive;
  final bool? allowView;
  final bool? allowCreate;
  final bool? allowUpdate;
  final bool? allowDelete;
  final bool? allowApprove;
  final bool? allowPrint;
  final bool? allowExport;
  final PermissionModel? permission;

  factory RolePermissionModel.fromJson(Map<String, dynamic> json) {
    final permissionJson = json['permission'] is Map<String, dynamic>
        ? json['permission'] as Map<String, dynamic>
        : null;
    final permission = permissionJson != null
        ? PermissionModel.fromJson(permissionJson)
        : null;

    return RolePermissionModel(
      id: ModelValue.nullableInt(json['id']),
      permissionId:
          ModelValue.nullableInt(json['permission_id']) ??
          ModelValue.nullableInt(json['id']),
      module: json['module']?.toString() ?? permission?.module,
      code: json['code']?.toString() ?? permission?.code,
      name: json['name']?.toString() ?? permission?.name,
      description: json['description']?.toString() ?? permission?.description,
      isSystemPermission: json['is_system_permission'] == null
          ? null
          : ModelValue.boolOf(json['is_system_permission']),
      permissionIsActive: json['permission_is_active'] == null
          ? (json['is_active'] == null
                ? null
                : ModelValue.boolOf(json['is_active']))
          : ModelValue.boolOf(json['permission_is_active']),
      rolePermissionIsActive: json['role_permission_is_active'] == null
          ? (json['is_active'] == null
                ? null
                : ModelValue.boolOf(json['is_active']))
          : ModelValue.boolOf(json['role_permission_is_active']),
      allowView: json['allow_view'] == null
          ? null
          : ModelValue.boolOf(json['allow_view']),
      allowCreate: json['allow_create'] == null
          ? null
          : ModelValue.boolOf(json['allow_create']),
      allowUpdate: json['allow_update'] == null
          ? null
          : ModelValue.boolOf(json['allow_update']),
      allowDelete: json['allow_delete'] == null
          ? null
          : ModelValue.boolOf(json['allow_delete']),
      allowApprove: json['allow_approve'] == null
          ? null
          : ModelValue.boolOf(json['allow_approve']),
      allowPrint: json['allow_print'] == null
          ? null
          : ModelValue.boolOf(json['allow_print']),
      allowExport: json['allow_export'] == null
          ? null
          : ModelValue.boolOf(json['allow_export']),
      permission: permission,
    );
  }

  RolePermissionModel copyWith({
    int? id,
    int? permissionId,
    String? module,
    String? code,
    String? name,
    String? description,
    bool? isSystemPermission,
    bool? permissionIsActive,
    bool? rolePermissionIsActive,
    bool? allowView,
    bool? allowCreate,
    bool? allowUpdate,
    bool? allowDelete,
    bool? allowApprove,
    bool? allowPrint,
    bool? allowExport,
    PermissionModel? permission,
  }) {
    return RolePermissionModel(
      id: id ?? this.id,
      permissionId: permissionId ?? this.permissionId,
      module: module ?? this.module,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      isSystemPermission: isSystemPermission ?? this.isSystemPermission,
      permissionIsActive: permissionIsActive ?? this.permissionIsActive,
      rolePermissionIsActive:
          rolePermissionIsActive ?? this.rolePermissionIsActive,
      allowView: allowView ?? this.allowView,
      allowCreate: allowCreate ?? this.allowCreate,
      allowUpdate: allowUpdate ?? this.allowUpdate,
      allowDelete: allowDelete ?? this.allowDelete,
      allowApprove: allowApprove ?? this.allowApprove,
      allowPrint: allowPrint ?? this.allowPrint,
      allowExport: allowExport ?? this.allowExport,
      permission: permission ?? this.permission,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (permissionId != null) 'permission_id': permissionId,
      'allow_view': allowView ?? false,
      'allow_create': allowCreate ?? false,
      'allow_update': allowUpdate ?? false,
      'allow_delete': allowDelete ?? false,
      'allow_approve': allowApprove ?? false,
      'allow_print': allowPrint ?? false,
      'allow_export': allowExport ?? false,
      'is_active': rolePermissionIsActive ?? true,
    };
  }
}
