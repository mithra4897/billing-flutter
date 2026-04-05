import '../common/json_model.dart';

class SalesDeliveryLineModel implements JsonModel {
  const SalesDeliveryLineModel(this.data);

  final Map<String, dynamic> data;

  factory SalesDeliveryLineModel.fromJson(Map<String, dynamic> json) {
    return SalesDeliveryLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
