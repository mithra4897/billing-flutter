import '../common/json_model.dart';
import '../common/model_value.dart';

class StateModel implements JsonModel {
  const StateModel({
    this.id,
    this.countryCode = '',
    this.stateCode = '',
    this.stateName = '',
    this.gstStateCode = '',
    this.isUnionTerritory = false,
    this.isActive = true,
    this.raw,
  });

  final int? id;
  final String countryCode;
  final String stateCode;
  final String stateName;
  final String gstStateCode;
  final bool isUnionTerritory;
  final bool isActive;
  final Map<String, dynamic>? raw;

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      id: ModelValue.nullableInt(json['id']),
      countryCode: ModelValue.stringOf(json['country_code']),
      stateCode: ModelValue.stringOf(json['state_code']),
      stateName: ModelValue.stringOf(json['state_name']),
      gstStateCode: ModelValue.stringOf(json['gst_state_code']),
      isUnionTerritory: ModelValue.boolOf(json['is_union_territory']),
      isActive: json['is_active'] == null
          ? true
          : ModelValue.boolOf(json['is_active'], fallback: true),
      raw: json,
    );
  }

  @override
  String toString() => stateName.isNotEmpty ? stateName : 'New State';

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'country_code': countryCode,
      'state_code': stateCode,
      'state_name': stateName,
      if (gstStateCode.trim().isNotEmpty) 'gst_state_code': gstStateCode,
      'is_union_territory': isUnionTerritory,
      'is_active': isActive,
    };
  }
}
