import '../common/json_model.dart';

class MrpRunModel implements JsonModel {
  const MrpRunModel(this.data);

  final Map<String, dynamic> data;

  factory MrpRunModel.fromJson(Map<String, dynamic> json) {
    return MrpRunModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
