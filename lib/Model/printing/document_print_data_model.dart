import '../../screen.dart';

class DocumentPrintDataModel extends JsonModel {
  const DocumentPrintDataModel({
    this.companyName = '',
    this.companyLogoUrl = '',
    this.companyGstin = '',
    this.documentNumber = '',
    this.documentDate = '',
    this.referenceNumber = '',
    this.partyName = '',
    this.partyAddress = '',
    this.partyContact = '',
    this.partyGstin = '',
    this.notes = '',
    this.termsConditions = '',
    this.subtotal = 0,
    this.taxAmount = 0,
    this.totalAmount = 0,
    this.amountInWords = '',
    this.lines = const <DocumentPrintLineModel>[],
    this.gstBreakup = const <DocumentPrintTaxBreakupRowModel>[],
  }) : super(id: null);

  final String companyName;
  final String companyLogoUrl;
  final String companyGstin;
  final String documentNumber;
  final String documentDate;
  final String referenceNumber;
  final String partyName;
  final String partyAddress;
  final String partyContact;
  final String partyGstin;
  final String notes;
  final String termsConditions;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final String amountInWords;
  final List<DocumentPrintLineModel> lines;
  final List<DocumentPrintTaxBreakupRowModel> gstBreakup;

  factory DocumentPrintDataModel.fromJson(Map<String, dynamic> json) {
    return DocumentPrintDataModel(
      companyName: json['company_name']?.toString() ?? '',
      companyLogoUrl: json['company_logo_url']?.toString() ?? '',
      companyGstin: json['company_gstin']?.toString() ?? '',
      documentNumber: json['document_number']?.toString() ?? '',
      documentDate: json['document_date']?.toString() ?? '',
      referenceNumber: json['reference_number']?.toString() ?? '',
      partyName: json['party_name']?.toString() ?? '',
      partyAddress: json['party_address']?.toString() ?? '',
      partyContact: json['party_contact']?.toString() ?? '',
      partyGstin: json['party_gstin']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      termsConditions: json['terms_conditions']?.toString() ?? '',
      subtotal: _toDouble(json['subtotal']),
      taxAmount: _toDouble(json['tax_amount']),
      totalAmount: _toDouble(json['total_amount']),
      amountInWords: json['amount_in_words']?.toString() ?? '',
      lines: (json['lines'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(DocumentPrintLineModel.fromJson)
          .toList(growable: false),
      gstBreakup: (json['gst_breakup'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(DocumentPrintTaxBreakupRowModel.fromJson)
          .toList(growable: false),
    );
  }

  @override
  String toString() =>
      documentNumber.isEmpty ? 'Print Document' : documentNumber;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'company_name': companyName,
      'company_logo_url': companyLogoUrl,
      'company_gstin': companyGstin,
      'document_number': documentNumber,
      'document_date': documentDate,
      'reference_number': referenceNumber,
      'party_name': partyName,
      'party_address': partyAddress,
      'party_contact': partyContact,
      'party_gstin': partyGstin,
      'notes': notes,
      'terms_conditions': termsConditions,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'amount_in_words': amountInWords,
      'lines': lines.map((line) => line.toJson()).toList(growable: false),
      'gst_breakup': gstBreakup
          .map((row) => row.toJson())
          .toList(growable: false),
    };
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}

class DocumentPrintLineModel extends JsonModel {
  const DocumentPrintLineModel({
    this.itemName = '',
    this.description = '',
    this.qty = 0,
    this.rate = 0,
    this.taxAmount,
    this.lineTotal = 0,
  }) : super(id: null);

  final String itemName;
  final String description;
  final double qty;
  final double rate;
  final double? taxAmount;
  final double lineTotal;

  factory DocumentPrintLineModel.fromJson(Map<String, dynamic> json) {
    return DocumentPrintLineModel(
      itemName: json['item_name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      qty: DocumentPrintDataModel._toDouble(json['qty']),
      rate: DocumentPrintDataModel._toDouble(json['rate']),
      taxAmount: json['tax_amount'] == null
          ? null
          : DocumentPrintDataModel._toDouble(json['tax_amount']),
      lineTotal: DocumentPrintDataModel._toDouble(json['line_total']),
    );
  }

  @override
  String toString() => itemName.isEmpty ? 'Print Line' : itemName;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'item_name': itemName,
      'description': description,
      'qty': qty,
      'rate': rate,
      if (taxAmount != null) 'tax_amount': taxAmount,
      'line_total': lineTotal,
    };
  }
}

class DocumentPrintTaxBreakupRowModel extends JsonModel {
  const DocumentPrintTaxBreakupRowModel({
    this.taxName = '',
    this.taxPercent = 0,
    this.taxable = 0,
    this.cgst = 0,
    this.sgst = 0,
    this.igst = 0,
    this.cess = 0,
    this.totalTax = 0,
  }) : super(id: null);

  final String taxName;
  final double taxPercent;
  final double taxable;
  final double cgst;
  final double sgst;
  final double igst;
  final double cess;
  final double totalTax;

  factory DocumentPrintTaxBreakupRowModel.fromJson(Map<String, dynamic> json) {
    return DocumentPrintTaxBreakupRowModel(
      taxName: json['tax_name']?.toString() ?? '',
      taxPercent: DocumentPrintDataModel._toDouble(json['tax_percent']),
      taxable: DocumentPrintDataModel._toDouble(json['taxable']),
      cgst: DocumentPrintDataModel._toDouble(json['cgst']),
      sgst: DocumentPrintDataModel._toDouble(json['sgst']),
      igst: DocumentPrintDataModel._toDouble(json['igst']),
      cess: DocumentPrintDataModel._toDouble(json['cess']),
      totalTax: DocumentPrintDataModel._toDouble(json['total_tax']),
    );
  }

  @override
  String toString() => taxName.isEmpty ? 'Tax Row' : taxName;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tax_name': taxName,
      'tax_percent': taxPercent,
      'taxable': taxable,
      'cgst': cgst,
      'sgst': sgst,
      'igst': igst,
      'cess': cess,
      'total_tax': totalTax,
    };
  }
}
