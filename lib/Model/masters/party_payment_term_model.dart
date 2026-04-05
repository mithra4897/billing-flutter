import '../common/json_model.dart';

class PartyPaymentTermModel implements JsonModel {
  const PartyPaymentTermModel(this.data);

  final Map<String, dynamic> data;

  factory PartyPaymentTermModel.fromJson(Map<String, dynamic> json) {
    return PartyPaymentTermModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
