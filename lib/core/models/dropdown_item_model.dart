class DropdownItemModel {
  const DropdownItemModel({
    required this.id,
    required this.label,
    this.code,
    this.extra,
  });

  final int id;
  final String label;
  final String? code;
  final Map<String, dynamic>? extra;

  factory DropdownItemModel.fromJson(Map<String, dynamic> json) {
    return DropdownItemModel(
      id: _parseInt(json['id']),
      label:
          json['label']?.toString() ??
          json['name']?.toString() ??
          json['display_name']?.toString() ??
          json['party_name']?.toString() ??
          '',
      code: json['code']?.toString() ?? json['item_code']?.toString(),
      extra: json,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
