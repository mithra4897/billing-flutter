import '../../screen.dart';

class UserWarehousesSyncRequestModel extends JsonModel {
  const UserWarehousesSyncRequestModel({
    this.warehouses = const <Map<String, dynamic>>[],
  }) : super(id: null);

  final List<Map<String, dynamic>> warehouses;

  factory UserWarehousesSyncRequestModel.fromJson(Map<String, dynamic> json) {
    return UserWarehousesSyncRequestModel(
      warehouses: _mapList(json['warehouses']),
    );
  }
  @override
  String toString() => 'User Warehouses Sync Request';


  @override
  Map<String, dynamic> toJson() => {'warehouses': warehouses};

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
}
