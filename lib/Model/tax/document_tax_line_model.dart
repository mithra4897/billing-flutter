import '../../screen.dart';

class DocumentTaxLineModel implements JsonModel {
  const DocumentTaxLineModel({
    this.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentModule,
    this.documentTable,
    this.documentId,
    this.documentNo,
    this.documentDate,
    this.lineTable,
    this.lineId,
    this.itemId,
    this.taxCodeId,
    this.hsnSacCode,
    this.taxableAmount,
    this.cgstPercent,
    this.cgstAmount,
    this.sgstPercent,
    this.sgstAmount,
    this.igstPercent,
    this.igstAmount,
    this.cessPercent,
    this.cessAmount,
    this.taxApplication,
    this.reverseChargeApplicable,
    this.inputTaxCreditAllowed,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
  final String? documentModule;
  final String? documentTable;
  final int? documentId;
  final String? documentNo;
  final String? documentDate;
  final String? lineTable;
  final int? lineId;
  final int? itemId;
  final int? taxCodeId;
  final String? hsnSacCode;
  final double? taxableAmount;
  final double? cgstPercent;
  final double? cgstAmount;
  final double? sgstPercent;
  final double? sgstAmount;
  final double? igstPercent;
  final double? igstAmount;
  final double? cessPercent;
  final double? cessAmount;
  final String? taxApplication;
  final bool? reverseChargeApplicable;
  final bool? inputTaxCreditAllowed;
  final String? createdAt;
  final String? updatedAt;

  factory DocumentTaxLineModel.fromJson(Map<String, dynamic> json) {
    return DocumentTaxLineModel(
      id: ModelValue.nullableInt(json['id']),
      companyId: ModelValue.nullableInt(json['company_id']),
      branchId: ModelValue.nullableInt(json['branch_id']),
      locationId: ModelValue.nullableInt(json['location_id']),
      financialYearId: ModelValue.nullableInt(json['financial_year_id']),
      documentModule: json['document_module']?.toString(),
      documentTable: json['document_table']?.toString(),
      documentId: ModelValue.nullableInt(json['document_id']),
      documentNo: json['document_no']?.toString(),
      documentDate: json['document_date']?.toString(),
      lineTable: json['line_table']?.toString(),
      lineId: ModelValue.nullableInt(json['line_id']),
      itemId: ModelValue.nullableInt(json['item_id']),
      taxCodeId: ModelValue.nullableInt(json['tax_code_id']),
      hsnSacCode: json['hsn_sac_code']?.toString(),
      taxableAmount: ModelValue.nullableDouble(json['taxable_amount']),
      cgstPercent: ModelValue.nullableDouble(json['cgst_percent']),
      cgstAmount: ModelValue.nullableDouble(json['cgst_amount']),
      sgstPercent: ModelValue.nullableDouble(json['sgst_percent']),
      sgstAmount: ModelValue.nullableDouble(json['sgst_amount']),
      igstPercent: ModelValue.nullableDouble(json['igst_percent']),
      igstAmount: ModelValue.nullableDouble(json['igst_amount']),
      cessPercent: ModelValue.nullableDouble(json['cess_percent']),
      cessAmount: ModelValue.nullableDouble(json['cess_amount']),
      taxApplication: json['tax_application']?.toString(),
      reverseChargeApplicable: json['reverse_charge_applicable'] == null
          ? null
          : ModelValue.boolOf(json['reverse_charge_applicable']),
      inputTaxCreditAllowed: json['input_tax_credit_allowed'] == null
          ? null
          : ModelValue.boolOf(json['input_tax_credit_allowed']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (financialYearId != null) 'financial_year_id': financialYearId,
    if (documentModule != null) 'document_module': documentModule,
    if (documentTable != null) 'document_table': documentTable,
    if (documentId != null) 'document_id': documentId,
    if (documentNo != null) 'document_no': documentNo,
    if (documentDate != null) 'document_date': documentDate,
    if (lineTable != null) 'line_table': lineTable,
    if (lineId != null) 'line_id': lineId,
    if (itemId != null) 'item_id': itemId,
    if (taxCodeId != null) 'tax_code_id': taxCodeId,
    if (hsnSacCode != null) 'hsn_sac_code': hsnSacCode,
    if (taxableAmount != null) 'taxable_amount': taxableAmount,
    if (cgstPercent != null) 'cgst_percent': cgstPercent,
    if (cgstAmount != null) 'cgst_amount': cgstAmount,
    if (sgstPercent != null) 'sgst_percent': sgstPercent,
    if (sgstAmount != null) 'sgst_amount': sgstAmount,
    if (igstPercent != null) 'igst_percent': igstPercent,
    if (igstAmount != null) 'igst_amount': igstAmount,
    if (cessPercent != null) 'cess_percent': cessPercent,
    if (cessAmount != null) 'cess_amount': cessAmount,
    if (taxApplication != null) 'tax_application': taxApplication,
    if (reverseChargeApplicable != null)
      'reverse_charge_applicable': reverseChargeApplicable,
    if (inputTaxCreditAllowed != null)
      'input_tax_credit_allowed': inputTaxCreditAllowed,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
