import '../common/json_model.dart';

class ModuleModel implements JsonModel {
  const ModuleModel(this.data);

  final Map<String, dynamic> data;

  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    return ModuleModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
