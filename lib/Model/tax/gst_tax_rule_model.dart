import '../common/json_model.dart';
import '../common/model_value.dart';

class GstTaxRuleModel implements JsonModel {
  const GstTaxRuleModel({
    this.id,
    this.ruleCode = '',
    this.ruleName = '',
    this.transactionType = '',
    this.itemType = '',
    this.taxCodeId,
    this.placeOfSupplyResult = '',
    this.taxApplication = '',
    this.reverseChargeApplicable = false,
    this.inputTaxCreditAllowed = true,
    this.priorityOrder,
    this.isActive = true,
    this.remarks,
    this.raw,
  });

  final int? id;
  final String ruleCode;
  final String ruleName;
  final String transactionType;
  final String itemType;
  final int? taxCodeId;
  final String placeOfSupplyResult;
  final String taxApplication;
  final bool reverseChargeApplicable;
  final bool inputTaxCreditAllowed;
  final int? priorityOrder;
  final bool isActive;
  final String? remarks;
  final Map<String, dynamic>? raw;

  factory GstTaxRuleModel.fromJson(Map<String, dynamic> json) {
    return GstTaxRuleModel(
      id: ModelValue.nullableInt(json['id']),
      ruleCode: ModelValue.stringOf(json['rule_code']),
      ruleName: ModelValue.stringOf(json['rule_name']),
      transactionType: ModelValue.stringOf(json['transaction_type']),
      itemType: ModelValue.stringOf(json['item_type']),
      taxCodeId: ModelValue.nullableInt(json['tax_code_id']),
      placeOfSupplyResult: ModelValue.stringOf(json['place_of_supply_result']),
      taxApplication: ModelValue.stringOf(json['tax_application']),
      reverseChargeApplicable: ModelValue.boolOf(
        json['reverse_charge_applicable'],
      ),
      inputTaxCreditAllowed: json['input_tax_credit_allowed'] == null
          ? true
          : ModelValue.boolOf(json['input_tax_credit_allowed'], fallback: true),
      priorityOrder: ModelValue.nullableInt(json['priority_order']),
      isActive: json['is_active'] == null
          ? true
          : ModelValue.boolOf(json['is_active'], fallback: true),
      remarks: json['remarks']?.toString(),
      raw: json,
    );
  }

  @override
  String toString() => ruleName.isNotEmpty ? ruleName : 'New GST Tax Rule';

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'rule_code': ruleCode,
      'rule_name': ruleName,
      if (transactionType.trim().isNotEmpty)
        'transaction_type': transactionType,
      if (itemType.trim().isNotEmpty) 'item_type': itemType,
      if (taxCodeId != null) 'tax_code_id': taxCodeId,
      if (placeOfSupplyResult.trim().isNotEmpty)
        'place_of_supply_result': placeOfSupplyResult,
      if (taxApplication.trim().isNotEmpty) 'tax_application': taxApplication,
      'reverse_charge_applicable': reverseChargeApplicable,
      'input_tax_credit_allowed': inputTaxCreditAllowed,
      if (priorityOrder != null) 'priority_order': priorityOrder,
      'is_active': isActive,
      if (remarks != null && remarks!.trim().isNotEmpty) 'remarks': remarks,
    };
  }
}
