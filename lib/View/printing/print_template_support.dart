import '../../screen.dart';

String printTemplateTaxLabel(TaxCodeModel? taxCode, double taxPercent) {
  final name = (taxCode?.taxName ?? taxCode?.taxCode ?? '').trim();
  if (name.isNotEmpty) {
    return name;
  }
  if (taxPercent <= 0) {
    return 'GST';
  }
  final rate = taxPercent == taxPercent.roundToDouble()
      ? taxPercent.round().toString()
      : taxPercent.toStringAsFixed(2);
  return 'GST $rate%';
}

void accumulatePrintTemplateGstBreakup(
  Map<String, dynamic> groups, {
  required TaxCodeModel? taxCode,
  required double taxPercent,
  required double taxable,
  required double cgst,
  required double sgst,
  required double igst,
  double cess = 0,
}) {
  final label = printTemplateTaxLabel(taxCode, taxPercent);
  final key = '${label.trim()}|${taxPercent.toStringAsFixed(4)}';
  final row =
      groups.putIfAbsent(
            key,
            () => _PrintTaxBreakupAccumulator(
              label: label,
              taxPercent: taxPercent,
            ),
          )
          as _PrintTaxBreakupAccumulator;
  row.add(taxable: taxable, cgst: cgst, sgst: sgst, igst: igst, cess: cess);
}

List<DocumentPrintTaxBreakupRowModel> finalizePrintTemplateGstBreakup(
  Map<String, dynamic> groups,
) {
  final rows = groups.values
      .whereType<_PrintTaxBreakupAccumulator>()
      .map((row) => row.toModel())
      .where((row) => row.taxable > 0.0 || row.totalTax > 0.0)
      .toList(growable: false);
  rows.sort((a, b) {
    final left = a.taxName.toLowerCase();
    final right = b.taxName.toLowerCase();
    return left.compareTo(right);
  });
  return rows;
}

class _PrintTaxBreakupAccumulator {
  _PrintTaxBreakupAccumulator({required this.label, required this.taxPercent});

  final String label;
  final double taxPercent;
  double taxable = 0.0;
  double cgst = 0.0;
  double sgst = 0.0;
  double igst = 0.0;
  double cess = 0.0;

  void add({
    required double taxable,
    required double cgst,
    required double sgst,
    required double igst,
    required double cess,
  }) {
    this.taxable += taxable;
    this.cgst += cgst;
    this.sgst += sgst;
    this.igst += igst;
    this.cess += cess;
  }

  DocumentPrintTaxBreakupRowModel toModel() {
    final roundedCgst = _roundAmount(cgst);
    final roundedSgst = _roundAmount(sgst);
    final roundedIgst = _roundAmount(igst);
    final roundedCess = _roundAmount(cess);
    return DocumentPrintTaxBreakupRowModel(
      taxName: label,
      taxPercent: _roundAmount(taxPercent),
      taxable: _roundAmount(taxable),
      cgst: roundedCgst,
      sgst: roundedSgst,
      igst: roundedIgst,
      cess: roundedCess,
      totalTax: _roundAmount(
        roundedCgst + roundedSgst + roundedIgst + roundedCess,
      ),
    );
  }
}

double _roundAmount(dynamic value) {
  final number = value is num ? value.toDouble() : 0.0;
  return double.parse(number.toStringAsFixed(2));
}

// Helper to convert double amount to words for print templates
String printTemplateAmountInWords(double amount, String currencyCode) {
  final normalized = amount.isNegative ? 0.0 : amount;
  final whole = normalized.floor();
  final fraction = ((normalized - whole) * 100).round();
  final code = currencyCode.trim().toUpperCase();
  final majorUnit = code == 'INR' ? 'Rupees' : code;
  final minorUnit = code == 'INR' ? 'Paise' : 'Cents';
  final wholeWords = _integerToWords(whole);
  if (fraction == 0) {
    return '$wholeWords $majorUnit Only';
  }
  return '$wholeWords $majorUnit and ${_integerToWords(fraction)} $minorUnit Only';
}

const List<String> _ones = <String>[
  'Zero',
  'One',
  'Two',
  'Three',
  'Four',
  'Five',
  'Six',
  'Seven',
  'Eight',
  'Nine',
  'Ten',
  'Eleven',
  'Twelve',
  'Thirteen',
  'Fourteen',
  'Fifteen',
  'Sixteen',
  'Seventeen',
  'Eighteen',
  'Nineteen',
];

const List<String> _tens = <String>[
  '',
  '',
  'Twenty',
  'Thirty',
  'Forty',
  'Fifty',
  'Sixty',
  'Seventy',
  'Eighty',
  'Ninety',
];

String _twoDigitWords(int value) {
  if (value < 20) {
    return _ones[value];
  }
  final tensPart = _tens[value ~/ 10];
  final onesPart = value % 10;
  if (onesPart == 0) {
    return tensPart;
  }
  return '$tensPart ${_ones[onesPart]}';
}

String _threeDigitWords(int value) {
  if (value < 100) {
    return _twoDigitWords(value);
  }
  final hundreds = value ~/ 100;
  final remainder = value % 100;
  if (remainder == 0) {
    return '${_ones[hundreds]} Hundred';
  }
  return '${_ones[hundreds]} Hundred ${_twoDigitWords(remainder)}';
}

String _integerToWords(int value) {
  if (value == 0) {
    return _ones[0];
  }

  final parts = <String>[];
  final crore = value ~/ 10000000;
  final lakh = (value ~/ 100000) % 100;
  final thousand = (value ~/ 1000) % 100;
  final hundred = value % 1000;

  if (crore > 0) {
    parts.add('${_integerToWords(crore)} Crore');
  }
  if (lakh > 0) {
    parts.add('${_twoDigitWords(lakh)} Lakh');
  }
  if (thousand > 0) {
    parts.add('${_twoDigitWords(thousand)} Thousand');
  }
  if (hundred > 0) {
    parts.add(_threeDigitWords(hundred));
  }
  return parts.join(' ');
}
