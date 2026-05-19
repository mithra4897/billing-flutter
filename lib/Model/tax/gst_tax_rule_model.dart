import '../../screen.dart';

class GstTaxRuleModel extends JsonModel {
  const GstTaxRuleModel({
    super.id,
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
  });
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

  factory GstTaxRuleModel.fromJson(Map<String, dynamic> json) {
    return GstTaxRuleModel(
      id: JsonModel.nullableInt(json['id']),
      ruleCode: JsonModel.stringOf(json['rule_code']),
      ruleName: JsonModel.stringOf(json['rule_name']),
      transactionType: JsonModel.stringOf(json['transaction_type']),
      itemType: JsonModel.stringOf(json['item_type']),
      taxCodeId: JsonModel.nullableInt(json['tax_code_id']),
      placeOfSupplyResult: JsonModel.stringOf(json['place_of_supply_result']),
      taxApplication: JsonModel.stringOf(json['tax_application']),
      reverseChargeApplicable: JsonModel.boolOf(
        json['reverse_charge_applicable'],
      ),
      inputTaxCreditAllowed: json['input_tax_credit_allowed'] == null
          ? true
          : JsonModel.boolOf(json['input_tax_credit_allowed'], fallback: true),
      priorityOrder: JsonModel.nullableInt(json['priority_order']),
      isActive: json['is_active'] == null
          ? true
          : JsonModel.boolOf(json['is_active'], fallback: true),
      remarks: json['remarks']?.toString(),
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
