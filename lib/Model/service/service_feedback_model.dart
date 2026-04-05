import '../common/json_model.dart';

class ServiceFeedbackModel implements JsonModel {
  const ServiceFeedbackModel(this.data);

  final Map<String, dynamic> data;

  factory ServiceFeedbackModel.fromJson(Map<String, dynamic> json) {
    return ServiceFeedbackModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
