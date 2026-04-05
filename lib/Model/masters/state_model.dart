import '../common/json_model.dart';

class StateModel implements JsonModel {
  const StateModel(this.data);

  final Map<String, dynamic> data;

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
