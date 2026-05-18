import '../../screen.dart';

class UserRolesSyncRequestModel implements JsonModel {
  const UserRolesSyncRequestModel({
    this.roles = const <Map<String, dynamic>>[],
  });

  final List<Map<String, dynamic>> roles;

  factory UserRolesSyncRequestModel.fromJson(Map<String, dynamic> json) {
    return UserRolesSyncRequestModel(roles: _mapList(json['roles']));
  }

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
