import '../common/json_model.dart';

class AccountGroupModel implements JsonModel {
  const AccountGroupModel(this.data);

  final Map<String, dynamic> data;

  factory AccountGroupModel.fromJson(Map<String, dynamic> json) {
    return AccountGroupModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
