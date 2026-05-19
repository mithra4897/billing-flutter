import '../../screen.dart';

class ErpRecordModel extends JsonModel {
  const ErpRecordModel({super.id, this.code, this.name, this.status});
  final String? code;
  final String? name;
  final String? status;
  factory ErpRecordModel.fromJson(Map<String, dynamic> json) {
    return ErpRecordModel(
      id: JsonModel.nullableInt(json['id']),
      code:
          json['code']?.toString() ??
          json['item_code']?.toString() ??
          json['project_code']?.toString() ??
          json['account_code']?.toString(),
      name:
          json['name']?.toString() ??
          json['display_name']?.toString() ??
          json['party_name']?.toString() ??
          json['item_name']?.toString() ??
          json['project_name']?.toString() ??
          json['account_name']?.toString(),
      status:
          json['status']?.toString() ??
          json['invoice_status']?.toString() ??
          json['order_status']?.toString() ??
          json['request_status']?.toString() ??
          json['work_order_status']?.toString(),
    );
  }
  @override
  String toString() => 'Erp Record';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (code != null) 'code': code,
    if (name != null) 'name': name,
    if (status != null) 'status': status,
  };
}
