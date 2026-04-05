import '../common/json_model.dart';

class LeaveTypeModel implements JsonModel {
  const LeaveTypeModel(this.data);

  final Map<String, dynamic> data;

  factory LeaveTypeModel.fromJson(Map<String, dynamic> json) {
    return LeaveTypeModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
