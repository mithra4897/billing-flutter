import '../common/json_model.dart';

class ProjectDashboardModel implements JsonModel {
  const ProjectDashboardModel(this.data);

  final Map<String, dynamic> data;

  factory ProjectDashboardModel.fromJson(Map<String, dynamic> json) {
    return ProjectDashboardModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
