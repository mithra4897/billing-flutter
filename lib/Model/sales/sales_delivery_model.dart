import '../common/json_model.dart';

class SalesDeliveryModel implements JsonModel {
  const SalesDeliveryModel(this.data);

  final Map<String, dynamic> data;

  factory SalesDeliveryModel.fromJson(Map<String, dynamic> json) {
    return SalesDeliveryModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
