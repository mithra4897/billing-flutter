import '../common/json_model.dart';
import '../common/model_value.dart';
import '../admin/permission_model.dart';

class UserPermissionModel implements JsonModel {
  const UserPermissionModel({
    this.id,
    this.permissionId,
    this.module,
    this.code,
    this.name,
    this.description,
    this.source,
    this.allowView,
    this.allowCreate,
    this.allowUpdate,
    this.allowDelete,
    this.allowApprove,
    this.allowPrint,
    this.allowExport,
    this.isActive,
    this.permission,
  });

  final int? id;
  final int? permissionId;
  final String? module;
  final String? code;
  final String? name;
  final String? description;
  final String? source;
  final bool? allowView;
  final bool? allowCreate;
  final bool? allowUpdate;
  final bool? allowDelete;
  final bool? allowApprove;
  final bool? allowPrint;
  final bool? allowExport;
  final bool? isActive;
  final PermissionModel? permission;

  factory UserPermissionModel.fromJson(Map<String, dynamic> json) {
    return UserPermissionModel(
      id: ModelValue.nullableInt(json['id']),
      permissionId:
          ModelValue.nullableInt(json['permission_id']) ??
          ModelValue.nullableInt(json['id']),
      module: json['module']?.toString(),
      code: json['code']?.toString(),
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      source: json['source']?.toString(),
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
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
      permission: json['permission'] is Map<String, dynamic>
          ? PermissionModel.fromJson(json['permission'] as Map<String, dynamic>)
          : null,
    );
  }

  UserPermissionModel copyWith({
    int? id,
    int? permissionId,
    String? module,
    String? code,
    String? name,
    String? description,
    String? source,
    bool? allowView,
    bool? allowCreate,
    bool? allowUpdate,
    bool? allowDelete,
    bool? allowApprove,
    bool? allowPrint,
    bool? allowExport,
    bool? isActive,
    PermissionModel? permission,
  }) {
    return UserPermissionModel(
      id: id ?? this.id,
      permissionId: permissionId ?? this.permissionId,
      module: module ?? this.module,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      source: source ?? this.source,
      allowView: allowView ?? this.allowView,
      allowCreate: allowCreate ?? this.allowCreate,
      allowUpdate: allowUpdate ?? this.allowUpdate,
      allowDelete: allowDelete ?? this.allowDelete,
      allowApprove: allowApprove ?? this.allowApprove,
      allowPrint: allowPrint ?? this.allowPrint,
      allowExport: allowExport ?? this.allowExport,
      isActive: isActive ?? this.isActive,
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
      'is_active': isActive ?? true,
    };
  }
}
