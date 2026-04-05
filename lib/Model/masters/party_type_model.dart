import '../common/json_model.dart';

class PartyTypeModel implements JsonModel {
  const PartyTypeModel(this.data);

  final Map<String, dynamic> data;

  factory PartyTypeModel.fromJson(Map<String, dynamic> json) {
    return PartyTypeModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
