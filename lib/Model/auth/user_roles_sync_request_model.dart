import '../../screen.dart';

class UserRolesSyncRequestModel extends JsonModel {
  const UserRolesSyncRequestModel({
    this.roles = const <Map<String, dynamic>>[],
  }) : super(id: null);

  final List<Map<String, dynamic>> roles;

  factory UserRolesSyncRequestModel.fromJson(Map<String, dynamic> json) {
    return UserRolesSyncRequestModel(roles: _mapList(json['roles']));
  }
  @override
  String toString() => 'User Roles Sync Request';


  @override
  Map<String, dynamic> toJson() => {'roles': roles};

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
}
