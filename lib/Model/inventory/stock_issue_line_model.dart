import '../common/json_model.dart';

class StockIssueLineModel implements JsonModel {
  const StockIssueLineModel(this.data);

  final Map<String, dynamic> data;

  factory StockIssueLineModel.fromJson(Map<String, dynamic> json) {
    return StockIssueLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
