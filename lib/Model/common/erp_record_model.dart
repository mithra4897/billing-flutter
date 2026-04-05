class ErpRecordModel {
  const ErpRecordModel(this.data);

  final Map<String, dynamic> data;

  factory ErpRecordModel.fromJson(Map<String, dynamic> json) {
    return ErpRecordModel(json);
  }

  int get id => int.tryParse(data['id']?.toString() ?? '') ?? 0;

  String get code =>
      data['code']?.toString() ??
      data['item_code']?.toString() ??
      data['project_code']?.toString() ??
      data['account_code']?.toString() ??
      '';

  String get name =>
      data['name']?.toString() ??
      data['display_name']?.toString() ??
      data['party_name']?.toString() ??
      data['item_name']?.toString() ??
      data['project_name']?.toString() ??
      data['account_name']?.toString() ??
      '';

  String? get status =>
      data['status']?.toString() ??
      data['invoice_status']?.toString() ??
      data['order_status']?.toString() ??
      data['request_status']?.toString() ??
      data['work_order_status']?.toString();

  dynamic operator [](String key) => data[key];
}
