import '../common/json_model.dart';

class LeaveRequestModel implements JsonModel {
  const LeaveRequestModel(this.data);

  final Map<String, dynamic> data;

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
