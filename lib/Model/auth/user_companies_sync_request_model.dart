import '../../screen.dart';

class UserCompaniesSyncRequestModel implements JsonModel {
  const UserCompaniesSyncRequestModel({
    this.companies = const <Map<String, dynamic>>[],
  });

  final List<Map<String, dynamic>> companies;

  factory UserCompaniesSyncRequestModel.fromJson(Map<String, dynamic> json) {
    return UserCompaniesSyncRequestModel(
      companies: _mapList(json['companies']),
    );
  }

  @override
  Map<String, dynamic> toJson() => {'companies': companies};

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
}
