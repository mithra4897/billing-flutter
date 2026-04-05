import '../common/json_model.dart';

class PlanningCalendarModel implements JsonModel {
  const PlanningCalendarModel(this.data);

  final Map<String, dynamic> data;

  factory PlanningCalendarModel.fromJson(Map<String, dynamic> json) {
    return PlanningCalendarModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
