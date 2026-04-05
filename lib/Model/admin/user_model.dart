import '../common/json_model.dart';
import '../common/model_value.dart';
import 'role_model.dart';
import '../auth/user_permission_model.dart';
import '../auth/user_role_model.dart';

class UserModel implements JsonModel {
  const UserModel({
    this.id,
    this.employeeCode,
    this.username,
    this.password,
    this.firstName,
    this.lastName,
    this.displayName,
    this.email,
    this.mobile,
    this.gender,
    this.dateOfBirth,
    this.profilePhotoPath,
    this.isSuperAdmin,
    this.isSystemUser,
    this.mustChangePassword,
    this.status,
    this.remarks,
    this.roleIds = const [],
    this.roles = const [],
    this.userRoles = const [],
    this.extraPermissions = const [],
    this.raw,
  });

  final int? id;
  final String? employeeCode;
  final String? username;
  final String? password;
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String? email;
  final String? mobile;
  final String? gender;
  final String? dateOfBirth;
  final String? profilePhotoPath;
  final bool? isSuperAdmin;
  final bool? isSystemUser;
  final bool? mustChangePassword;
  final String? status;
  final String? remarks;
  final List<int> roleIds;
  final List<RoleModel> roles;
  final List<UserRoleModel> userRoles;
  final List<UserPermissionModel> extraPermissions;
  final Map<String, dynamic>? raw;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: ModelValue.nullableInt(json['id']),
      employeeCode: json['employee_code']?.toString(),
      username: json['username']?.toString(),
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      displayName: json['display_name']?.toString(),
      email: json['email']?.toString(),
      mobile: json['mobile']?.toString(),
      gender: json['gender']?.toString(),
      dateOfBirth: json['date_of_birth']?.toString(),
      profilePhotoPath: json['profile_photo_path']?.toString(),
      isSuperAdmin: json['is_super_admin'] == null
          ? null
          : ModelValue.boolOf(json['is_super_admin']),
      isSystemUser: json['is_system_user'] == null
          ? null
          : ModelValue.boolOf(json['is_system_user']),
      mustChangePassword: json['must_change_password'] == null
          ? null
          : ModelValue.boolOf(json['must_change_password']),
      status: json['status']?.toString(),
      remarks: json['remarks']?.toString(),
      roleIds: _roleIds(json['role_ids']),
      roles: _roles(json['roles']),
      userRoles: _userRoles(json['user_roles']),
      extraPermissions: _extraPermissions(json['user_permissions']),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (employeeCode != null) 'employee_code': employeeCode,
      if (username != null) 'username': username,
      if (password != null && password!.isNotEmpty) 'password': password,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (displayName != null) 'display_name': displayName,
      if (email != null) 'email': email,
      if (mobile != null) 'mobile': mobile,
      if (gender != null) 'gender': gender,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (profilePhotoPath != null) 'profile_photo_path': profilePhotoPath,
      if (isSuperAdmin != null) 'is_super_admin': isSuperAdmin,
      if (isSystemUser != null) 'is_system_user': isSystemUser,
      if (mustChangePassword != null)
        'must_change_password': mustChangePassword,
      if (status != null) 'status': status,
      if (remarks != null) 'remarks': remarks,
      if (roleIds.isNotEmpty)
        'roles': roleIds
            .asMap()
            .entries
            .map(
              (entry) => {
                'role_id': entry.value,
                'is_primary_role': entry.key == 0,
                'is_active': true,
              },
            )
            .toList(growable: false),
      if (extraPermissions.isNotEmpty)
        'extra_permissions': extraPermissions
            .map((item) => item.toJson())
            .toList(growable: false),
    };
  }

  static List<RoleModel> _roles(dynamic value) {
    if (value is! List) {
      return const <RoleModel>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(RoleModel.fromJson)
        .toList(growable: false);
  }

  static List<int> _roleIds(dynamic value) {
    if (value is! List) {
      return const <int>[];
    }

    return value.map(ModelValue.intOf).toList(growable: false);
  }

  static List<UserRoleModel> _userRoles(dynamic value) {
    if (value is! List) {
      return const <UserRoleModel>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(UserRoleModel.fromJson)
        .toList(growable: false);
  }

  static List<UserPermissionModel> _extraPermissions(dynamic value) {
    if (value is! List) {
      return const <UserPermissionModel>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(UserPermissionModel.fromJson)
        .toList(growable: false);
  }
}
