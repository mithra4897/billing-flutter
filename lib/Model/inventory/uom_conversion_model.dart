import '../common/json_model.dart';
import '../common/model_value.dart';

class UomConversionModel implements JsonModel {
  const UomConversionModel({
    this.id,
    this.fromUomId,
    this.toUomId,
    this.conversionFactor,
    this.isActive = true,
    this.fromUomCode = '',
    this.fromUomName = '',
    this.fromUomSymbol = '',
    this.toUomCode = '',
    this.toUomName = '',
    this.toUomSymbol = '',
    this.raw,
  });

  final int? id;
  final int? fromUomId;
  final int? toUomId;
  final double? conversionFactor;
  final bool isActive;
  final String fromUomCode;
  final String fromUomName;
  final String fromUomSymbol;
  final String toUomCode;
  final String toUomName;
  final String toUomSymbol;
  final Map<String, dynamic>? raw;

  factory UomConversionModel.fromJson(Map<String, dynamic> json) {
    final fromUom = json['from_uom'] as Map<String, dynamic>?;
    final toUom = json['to_uom'] as Map<String, dynamic>?;

    return UomConversionModel(
      id: ModelValue.nullableInt(json['id']),
      fromUomId: ModelValue.nullableInt(json['from_uom_id']),
      toUomId: ModelValue.nullableInt(json['to_uom_id']),
      conversionFactor: ModelValue.nullableDouble(json['conversion_factor']),
      isActive: json['is_active'] == null
          ? true
          : ModelValue.boolOf(json['is_active'], fallback: true),
      fromUomCode: ModelValue.stringOf(fromUom?['uom_code']),
      fromUomName: ModelValue.stringOf(fromUom?['uom_name']),
      fromUomSymbol: ModelValue.stringOf(fromUom?['symbol']),
      toUomCode: ModelValue.stringOf(toUom?['uom_code']),
      toUomName: ModelValue.stringOf(toUom?['uom_name']),
      toUomSymbol: ModelValue.stringOf(toUom?['symbol']),
      raw: json,
    );
  }

  @override
  String toString() {
    final fromLabel = fromDisplay.trim();
    final toLabel = toDisplay.trim();
    if (fromLabel.isNotEmpty && toLabel.isNotEmpty) {
      return '$fromLabel -> $toLabel';
    }

    return 'New UOM Conversion';
  }

  String get fromDisplay => fromUomName.isNotEmpty
      ? fromUomName
      : (fromUomSymbol.isNotEmpty ? fromUomSymbol : fromUomCode);

  String get toDisplay => toUomName.isNotEmpty
      ? toUomName
      : (toUomSymbol.isNotEmpty ? toUomSymbol : toUomCode);

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (fromUomId != null) 'from_uom_id': fromUomId,
      if (toUomId != null) 'to_uom_id': toUomId,
      if (conversionFactor != null) 'conversion_factor': conversionFactor,
      'is_active': isActive,
    };
  }
}
