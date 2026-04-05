import '../common/json_model.dart';

class UserWarehousesSyncRequestModel implements JsonModel {
  const UserWarehousesSyncRequestModel(this.data);

  final Map<String, dynamic> data;

  factory UserWarehousesSyncRequestModel.fromJson(Map<String, dynamic> json) {
    return UserWarehousesSyncRequestModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
