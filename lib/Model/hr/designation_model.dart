import '../common/json_model.dart';

class DesignationModel implements JsonModel {
  const DesignationModel(this.data);

  final Map<String, dynamic> data;

  factory DesignationModel.fromJson(Map<String, dynamic> json) {
    return DesignationModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
