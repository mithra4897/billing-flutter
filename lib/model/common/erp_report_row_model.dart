import '../../screen.dart';

class ErpReportRowModel extends JsonModel {
  const ErpReportRowModel(this.data) : super(id: null);

  final Map<String, dynamic> data;

  factory ErpReportRowModel.fromJson(Map<String, dynamic> json) {
    return ErpReportRowModel(json);
  }
  @override
  String toString() => data['title']?.toString() ?? 'ERP Report Row';

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);

  dynamic operator [](String key) => data[key];
}
