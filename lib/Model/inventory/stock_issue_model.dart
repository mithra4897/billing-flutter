import '../common/json_model.dart';

class StockIssueModel implements JsonModel {
  const StockIssueModel(this.data);

  final Map<String, dynamic> data;

  factory StockIssueModel.fromJson(Map<String, dynamic> json) {
    return StockIssueModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
