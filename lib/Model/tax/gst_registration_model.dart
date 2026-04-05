import '../common/json_model.dart';

class GstRegistrationModel implements JsonModel {
  const GstRegistrationModel(this.data);

  final Map<String, dynamic> data;

  factory GstRegistrationModel.fromJson(Map<String, dynamic> json) {
    return GstRegistrationModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
