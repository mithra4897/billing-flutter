import '../common/json_model.dart';

class PartyBankAccountModel implements JsonModel {
  const PartyBankAccountModel(this.data);

  final Map<String, dynamic> data;

  factory PartyBankAccountModel.fromJson(Map<String, dynamic> json) {
    return PartyBankAccountModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
