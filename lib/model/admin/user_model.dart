import '../../screen.dart';

class UserModel extends JsonModel {
  const UserModel({
    super.id,
    this.employeeId,
    this.employeeCode,
    this.employeeName,
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
    this.companyAccess = const [],
    this.branchAccess = const [],
    this.locationAccess = const [],
    this.warehouseAccess = const [],
  });
  final int? employeeId;
  final String? employeeCode;
  final String? employeeName;
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
  final List<UserCompanyAccessModel> companyAccess;
  final List<UserBranchAccessModel> branchAccess;
  final List<UserLocationAccessModel> locationAccess;
  final List<UserWarehouseAccessModel> warehouseAccess;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final employeeJson = json['employee'] is Map<String, dynamic>
        ? json['employee'] as Map<String, dynamic>
        : null;

    return UserModel(
      id: JsonModel.nullableInt(json['id']),
      employeeId:
          JsonModel.nullableInt(json['employee_id']) ??
          JsonModel.nullableInt(employeeJson?['id']),
      employeeCode:
          employeeJson?['employee_code']?.toString() ??
          json['employee_code']?.toString(),
      employeeName:
          employeeJson?['employee_name']?.toString() ??
          json['employee_name']?.toString(),
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
          : JsonModel.boolOf(json['is_super_admin']),
      isSystemUser: json['is_system_user'] == null
          ? null
          : JsonModel.boolOf(json['is_system_user']),
      mustChangePassword: json['must_change_password'] == null
          ? null
          : JsonModel.boolOf(json['must_change_password']),
      status: json['status']?.toString(),
      remarks: json['remarks']?.toString(),
      roleIds: _roleIds(json['role_ids']),
      roles: _roles(json['roles']),
      userRoles: _userRoles(json['user_roles']),
      extraPermissions: _extraPermissions(json['user_permissions']),
      companyAccess: _companyAccess(json['company_access']),
      branchAccess: _branchAccess(json['branch_access']),
      locationAccess: _locationAccess(json['location_access']),
      warehouseAccess: _warehouseAccess(json['warehouse_access']),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    displayName,
    employeeName,
    email,
  ], defaultValue: 'User');

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (employeeId != null) 'employee_id': employeeId,
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
      if (companyAccess.isNotEmpty)
        'company_access': companyAccess
            .map((item) => item.toJson())
            .toList(growable: false),
      if (branchAccess.isNotEmpty)
        'branch_access': branchAccess
            .map((item) => item.toJson())
            .toList(growable: false),
      if (locationAccess.isNotEmpty)
        'location_access': locationAccess
            .map((item) => item.toJson())
            .toList(growable: false),
      if (warehouseAccess.isNotEmpty)
        'warehouse_access': warehouseAccess
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

    return value.map(JsonModel.intOf).toList(growable: false);
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

  static List<UserCompanyAccessModel> _companyAccess(dynamic value) {
    if (value is! List) {
      return const <UserCompanyAccessModel>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(UserCompanyAccessModel.fromJson)
        .toList(growable: false);
  }

  static List<UserBranchAccessModel> _branchAccess(dynamic value) {
    if (value is! List) {
      return const <UserBranchAccessModel>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(UserBranchAccessModel.fromJson)
        .toList(growable: false);
  }

  static List<UserLocationAccessModel> _locationAccess(dynamic value) {
    if (value is! List) {
      return const <UserLocationAccessModel>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(UserLocationAccessModel.fromJson)
        .toList(growable: false);
  }

  static List<UserWarehouseAccessModel> _warehouseAccess(dynamic value) {
    if (value is! List) {
      return const <UserWarehouseAccessModel>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(UserWarehouseAccessModel.fromJson)
        .toList(growable: false);
  }
}
