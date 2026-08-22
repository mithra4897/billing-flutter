import '../../screen.dart';

class UserPermissionModel extends JsonModel {
  static const Object _unset = Object();

  const UserPermissionModel({
    super.id,
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
    this.overrideAllowView,
    this.overrideAllowCreate,
    this.overrideAllowUpdate,
    this.overrideAllowDelete,
    this.overrideAllowApprove,
    this.overrideAllowPrint,
    this.overrideAllowExport,
    this.isActive,
    this.permission,
  });
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
  final bool? overrideAllowView;
  final bool? overrideAllowCreate;
  final bool? overrideAllowUpdate;
  final bool? overrideAllowDelete;
  final bool? overrideAllowApprove;
  final bool? overrideAllowPrint;
  final bool? overrideAllowExport;
  final bool? isActive;
  final PermissionModel? permission;

  factory UserPermissionModel.fromJson(Map<String, dynamic> json) {
    return UserPermissionModel(
      id: JsonModel.nullableInt(json['id']),
      permissionId:
          JsonModel.nullableInt(json['permission_id']) ??
          JsonModel.nullableInt(json['id']),
      module: json['module']?.toString(),
      code: json['code']?.toString(),
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      source: json['source']?.toString(),
      allowView: json['allow_view'] == null
          ? null
          : JsonModel.boolOf(json['allow_view']),
      allowCreate: json['allow_create'] == null
          ? null
          : JsonModel.boolOf(json['allow_create']),
      allowUpdate: json['allow_update'] == null
          ? null
          : JsonModel.boolOf(json['allow_update']),
      allowDelete: json['allow_delete'] == null
          ? null
          : JsonModel.boolOf(json['allow_delete']),
      allowApprove: json['allow_approve'] == null
          ? null
          : JsonModel.boolOf(json['allow_approve']),
      allowPrint: json['allow_print'] == null
          ? null
          : JsonModel.boolOf(json['allow_print']),
      allowExport: json['allow_export'] == null
          ? null
          : JsonModel.boolOf(json['allow_export']),
      overrideAllowView: json['override_allow_view'] == null
          ? null
          : JsonModel.boolOf(json['override_allow_view']),
      overrideAllowCreate: json['override_allow_create'] == null
          ? null
          : JsonModel.boolOf(json['override_allow_create']),
      overrideAllowUpdate: json['override_allow_update'] == null
          ? null
          : JsonModel.boolOf(json['override_allow_update']),
      overrideAllowDelete: json['override_allow_delete'] == null
          ? null
          : JsonModel.boolOf(json['override_allow_delete']),
      overrideAllowApprove: json['override_allow_approve'] == null
          ? null
          : JsonModel.boolOf(json['override_allow_approve']),
      overrideAllowPrint: json['override_allow_print'] == null
          ? null
          : JsonModel.boolOf(json['override_allow_print']),
      overrideAllowExport: json['override_allow_export'] == null
          ? null
          : JsonModel.boolOf(json['override_allow_export']),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
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
    Object? overrideAllowView = _unset,
    Object? overrideAllowCreate = _unset,
    Object? overrideAllowUpdate = _unset,
    Object? overrideAllowDelete = _unset,
    Object? overrideAllowApprove = _unset,
    Object? overrideAllowPrint = _unset,
    Object? overrideAllowExport = _unset,
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
      overrideAllowView: identical(overrideAllowView, _unset)
          ? this.overrideAllowView
          : overrideAllowView as bool?,
      overrideAllowCreate: identical(overrideAllowCreate, _unset)
          ? this.overrideAllowCreate
          : overrideAllowCreate as bool?,
      overrideAllowUpdate: identical(overrideAllowUpdate, _unset)
          ? this.overrideAllowUpdate
          : overrideAllowUpdate as bool?,
      overrideAllowDelete: identical(overrideAllowDelete, _unset)
          ? this.overrideAllowDelete
          : overrideAllowDelete as bool?,
      overrideAllowApprove: identical(overrideAllowApprove, _unset)
          ? this.overrideAllowApprove
          : overrideAllowApprove as bool?,
      overrideAllowPrint: identical(overrideAllowPrint, _unset)
          ? this.overrideAllowPrint
          : overrideAllowPrint as bool?,
      overrideAllowExport: identical(overrideAllowExport, _unset)
          ? this.overrideAllowExport
          : overrideAllowExport as bool?,
      isActive: isActive ?? this.isActive,
      permission: permission ?? this.permission,
    );
  }

  @override
  String toString() =>
      JsonModel.combineValues([name, code], defaultValue: 'User Permission');

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
      if (overrideAllowView != null) 'override_allow_view': overrideAllowView,
      if (overrideAllowCreate != null)
        'override_allow_create': overrideAllowCreate,
      if (overrideAllowUpdate != null)
        'override_allow_update': overrideAllowUpdate,
      if (overrideAllowDelete != null)
        'override_allow_delete': overrideAllowDelete,
      if (overrideAllowApprove != null)
        'override_allow_approve': overrideAllowApprove,
      if (overrideAllowPrint != null)
        'override_allow_print': overrideAllowPrint,
      if (overrideAllowExport != null)
        'override_allow_export': overrideAllowExport,
      'is_active': isActive ?? true,
    };
  }
}
