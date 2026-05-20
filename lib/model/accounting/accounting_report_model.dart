import '../../screen.dart';

class AccountingReportModel extends JsonModel {
  const AccountingReportModel(this.data) : super(id: null);

  final Map<String, dynamic> data;

  factory AccountingReportModel.fromJson(Map<String, dynamic> json) {
    return AccountingReportModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);

  @override
  String toString() => data['title']?.toString() ?? 'Accounting Report';
}
