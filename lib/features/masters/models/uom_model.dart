class UomModel {
  const UomModel({
    required this.id,
    required this.uomCode,
    required this.uomName,
    this.isActive = true,
    this.raw,
  });

  final int id;
  final String uomCode;
  final String uomName;
  final bool isActive;
  final Map<String, dynamic>? raw;

  factory UomModel.fromJson(Map<String, dynamic> json) {
    return UomModel(
      id: _parseInt(json['id']),
      uomCode: json['uom_code']?.toString() ?? '',
      uomName: json['uom_name']?.toString() ?? '',
      isActive: json['is_active'] != false && json['is_active'] != 0,
      raw: json,
    );
  }

  static int _parseInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;
}
