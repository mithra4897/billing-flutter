import '../common/json_model.dart';

class MrpRecommendationModel implements JsonModel {
  const MrpRecommendationModel(this.data);

  final Map<String, dynamic> data;

  factory MrpRecommendationModel.fromJson(Map<String, dynamic> json) {
    return MrpRecommendationModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
