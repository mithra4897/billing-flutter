import '../common/json_model.dart';

class JobworkOrderModel implements JsonModel {
  const JobworkOrderModel(this.data);

  final Map<String, dynamic> data;

  factory JobworkOrderModel.fromJson(Map<String, dynamic> json) {
    return JobworkOrderModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
