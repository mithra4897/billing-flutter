import '../../screen.dart';

class StateModel extends JsonModel {
  const StateModel({
    super.id,
    this.countryCode = '',
    this.stateCode = '',
    this.stateName = '',
    this.gstStateCode = '',
    this.isUnionTerritory = false,
    this.isActive = true,
  });
  final String countryCode;
  final String stateCode;
  final String stateName;
  final String gstStateCode;
  final bool isUnionTerritory;
  final bool isActive;

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      id: JsonModel.nullableInt(json['id']),
      countryCode: JsonModel.stringOf(json['country_code']),
      stateCode: JsonModel.stringOf(json['state_code']),
      stateName: JsonModel.stringOf(json['state_name']),
      gstStateCode: JsonModel.stringOf(json['gst_state_code']),
      isUnionTerritory: JsonModel.boolOf(json['is_union_territory']),
      isActive: json['is_active'] == null
          ? true
          : JsonModel.boolOf(json['is_active'], fallback: true),
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
