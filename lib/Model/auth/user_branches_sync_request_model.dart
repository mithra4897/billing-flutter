import '../../screen.dart';

class UserBranchesSyncRequestModel implements JsonModel {
  const UserBranchesSyncRequestModel({
    this.branches = const <Map<String, dynamic>>[],
  });

  final List<Map<String, dynamic>> branches;

  factory UserBranchesSyncRequestModel.fromJson(Map<String, dynamic> json) {
    return UserBranchesSyncRequestModel(branches: _mapList(json['branches']));
  }

  @override
  Map<String, dynamic> toJson() => {'branches': branches};

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
}
