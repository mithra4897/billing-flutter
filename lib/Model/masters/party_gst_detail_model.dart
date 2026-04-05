import '../common/json_model.dart';

class PartyGstDetailModel implements JsonModel {
  const PartyGstDetailModel(this.data);

  final Map<String, dynamic> data;

  factory PartyGstDetailModel.fromJson(Map<String, dynamic> json) {
    return PartyGstDetailModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
