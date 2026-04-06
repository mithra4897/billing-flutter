import '../common/json_model.dart';

class UomModel implements JsonModel {
  const UomModel({
    this.id,
    this.uomCode,
    this.uomName,
    this.symbol,
    this.isFractionAllowed = false,
    this.isActive = true,
    this.raw,
  });

  final int? id;
  final String? uomCode;
  final String? uomName;
  final String? symbol;
  final bool isFractionAllowed;
  final bool isActive;
  final Map<String, dynamic>? raw;

  factory UomModel.fromJson(Map<String, dynamic> json) {
    return UomModel(
      id: _parseInt(json['id']),
      uomCode: json['uom_code']?.toString() ?? '',
      uomName: json['uom_name']?.toString() ?? '',
      symbol: json['symbol']?.toString(),
      isFractionAllowed:
          json['is_fraction_allowed'] == true ||
          json['is_fraction_allowed'] == 1,
      isActive: json['is_active'] != false && json['is_active'] != 0,
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (uomCode != null) 'uom_code': uomCode,
      if (uomName != null) 'uom_name': uomName,
      if (symbol != null) 'symbol': symbol,
      'is_fraction_allowed': isFractionAllowed,
      'is_active': isActive,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return null;
    }

    return int.tryParse(value.toString());
  }
}
