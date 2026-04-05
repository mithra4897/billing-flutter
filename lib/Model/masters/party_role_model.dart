import '../common/json_model.dart';

class PartyRoleModel implements JsonModel {
  const PartyRoleModel(this.data);

  final Map<String, dynamic> data;

  factory PartyRoleModel.fromJson(Map<String, dynamic> json) {
    return PartyRoleModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
