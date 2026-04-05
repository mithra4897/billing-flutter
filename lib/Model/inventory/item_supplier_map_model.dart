import '../common/json_model.dart';

class ItemSupplierMapModel implements JsonModel {
  const ItemSupplierMapModel(this.data);

  final Map<String, dynamic> data;

  factory ItemSupplierMapModel.fromJson(Map<String, dynamic> json) {
    return ItemSupplierMapModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
