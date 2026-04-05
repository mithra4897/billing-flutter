import '../common/json_model.dart';

class AttendanceRecordModel implements JsonModel {
  const AttendanceRecordModel(this.data);

  final Map<String, dynamic> data;

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
