import '../../screen.dart';

class UserLocationsSyncRequestModel extends JsonModel {
  const UserLocationsSyncRequestModel({
    this.locations = const <Map<String, dynamic>>[],
  }) : super(id: null);

  final List<Map<String, dynamic>> locations;

  factory UserLocationsSyncRequestModel.fromJson(Map<String, dynamic> json) {
    return UserLocationsSyncRequestModel(
      locations: _mapList(json['locations']),
    );
  }
  @override
  String toString() => 'User Locations Sync Request';


  @override
  Map<String, dynamic> toJson() => {'locations': locations};

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
}
