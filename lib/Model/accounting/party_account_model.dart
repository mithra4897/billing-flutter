import '../common/json_model.dart';

class PartyAccountModel implements JsonModel {
  const PartyAccountModel(this.data);

  final Map<String, dynamic> data;

  factory PartyAccountModel.fromJson(Map<String, dynamic> json) {
    return PartyAccountModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
