import '../common/json_model.dart';
import '../common/model_value.dart';

class GstRegistrationModel implements JsonModel {
  const GstRegistrationModel({
    this.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.registrationName = '',
    this.gstin = '',
    this.panNo = '',
    this.stateId,
    this.legalName = '',
    this.tradeName = '',
    this.registrationType = '',
    this.effectiveFrom = '',
    this.effectiveTo = '',
    this.isDefault = false,
    this.isActive = true,
    this.remarks,
    this.raw,
  });

  final int? id;
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final String registrationName;
  final String gstin;
  final String panNo;
  final int? stateId;
  final String legalName;
  final String tradeName;
  final String registrationType;
  final String effectiveFrom;
  final String effectiveTo;
  final bool isDefault;
  final bool isActive;
  final String? remarks;
  final Map<String, dynamic>? raw;

  factory GstRegistrationModel.fromJson(Map<String, dynamic> json) {
    return GstRegistrationModel(
      id: ModelValue.nullableInt(json['id']),
      companyId: ModelValue.nullableInt(json['company_id']),
      branchId: ModelValue.nullableInt(json['branch_id']),
      locationId: ModelValue.nullableInt(json['location_id']),
      registrationName: ModelValue.stringOf(json['registration_name']),
      gstin: ModelValue.stringOf(json['gstin']),
      panNo: ModelValue.stringOf(json['pan_no']),
      stateId: ModelValue.nullableInt(json['state_id']),
      legalName: ModelValue.stringOf(json['legal_name']),
      tradeName: ModelValue.stringOf(json['trade_name']),
      registrationType: ModelValue.stringOf(json['registration_type']),
      effectiveFrom: ModelValue.stringOf(json['effective_from']),
      effectiveTo: ModelValue.stringOf(json['effective_to']),
      isDefault: ModelValue.boolOf(json['is_default']),
      isActive: json['is_active'] == null
          ? true
          : ModelValue.boolOf(json['is_active'], fallback: true),
      remarks: json['remarks']?.toString(),
      raw: json,
    );
  }

  @override
  String toString() => registrationName.isNotEmpty
      ? registrationName
      : (gstin.isNotEmpty ? gstin : 'New GST Registration');

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (branchId != null) 'branch_id': branchId,
      if (locationId != null) 'location_id': locationId,
      'registration_name': registrationName,
      if (gstin.trim().isNotEmpty) 'gstin': gstin,
      if (panNo.trim().isNotEmpty) 'pan_no': panNo,
      if (stateId != null) 'state_id': stateId,
      if (legalName.trim().isNotEmpty) 'legal_name': legalName,
      if (tradeName.trim().isNotEmpty) 'trade_name': tradeName,
      if (registrationType.trim().isNotEmpty)
        'registration_type': registrationType,
      if (effectiveFrom.trim().isNotEmpty) 'effective_from': effectiveFrom,
      if (effectiveTo.trim().isNotEmpty) 'effective_to': effectiveTo,
      'is_default': isDefault,
      'is_active': isActive,
      if (remarks != null && remarks!.trim().isNotEmpty) 'remarks': remarks,
    };
  }
}
