import '../common/json_model.dart';

class EmployeeAccountModel implements JsonModel {
  const EmployeeAccountModel(this.data);

  final Map<String, dynamic> data;

  factory EmployeeAccountModel.fromJson(Map<String, dynamic> json) {
    return EmployeeAccountModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
