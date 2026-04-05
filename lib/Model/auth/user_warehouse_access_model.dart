import '../common/json_model.dart';

class UserWarehouseAccessModel implements JsonModel {
  const UserWarehouseAccessModel(this.data);

  final Map<String, dynamic> data;

  factory UserWarehouseAccessModel.fromJson(Map<String, dynamic> json) {
    return UserWarehouseAccessModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
