class ErpReportRowModel {
  const ErpReportRowModel(this.data);

  final Map<String, dynamic> data;

  factory ErpReportRowModel.fromJson(Map<String, dynamic> json) {
    return ErpReportRowModel(json);
  }

  dynamic operator [](String key) => data[key];
}
