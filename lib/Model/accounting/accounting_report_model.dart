import '../common/json_model.dart';

class AccountingReportModel implements JsonModel {
  const AccountingReportModel(this.data);

  final Map<String, dynamic> data;

  factory AccountingReportModel.fromJson(Map<String, dynamic> json) {
    return AccountingReportModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);

  @override
  String toString() => data['title']?.toString() ?? 'Accounting Report';
}
