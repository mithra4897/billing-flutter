class SalesInvoiceExportTaxTotals {
  const SalesInvoiceExportTaxTotals({
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.usedPersistedSnapshot,
  });

  final double cgst;
  final double sgst;
  final double igst;
  final bool usedPersistedSnapshot;
}

SalesInvoiceExportTaxTotals resolveSalesInvoiceExportTaxTotals({
  required Map<String, dynamic> document,
  required double calculatedCgst,
  required double calculatedSgst,
  required double calculatedIgst,
  required bool? isInterState,
}) {
  final persistedCgst = _parseStoredAmount(document['cgst_amount']);
  final persistedSgst = _parseStoredAmount(document['sgst_amount']);
  final persistedIgst = _parseStoredAmount(document['igst_amount']);
  final hasPersistedSnapshot =
      persistedCgst != null || persistedSgst != null || persistedIgst != null;

  final source = !hasPersistedSnapshot
      ? SalesInvoiceExportTaxTotals(
          cgst: calculatedCgst,
          sgst: calculatedSgst,
          igst: calculatedIgst,
          usedPersistedSnapshot: false,
        )
      : SalesInvoiceExportTaxTotals(
          cgst: persistedCgst ?? 0,
          sgst: persistedSgst ?? 0,
          igst: persistedIgst ?? 0,
          usedPersistedSnapshot: true,
        );

  if (isInterState == null) {
    return source;
  }

  final totalTax = source.cgst + source.sgst + source.igst;
  if (isInterState) {
    return SalesInvoiceExportTaxTotals(
      cgst: 0,
      sgst: 0,
      igst: _roundAmount(totalTax),
      usedPersistedSnapshot: source.usedPersistedSnapshot,
    );
  }

  final cgst = _roundAmount(totalTax / 2);
  return SalesInvoiceExportTaxTotals(
    cgst: cgst,
    sgst: _roundAmount(totalTax - cgst),
    igst: 0,
    usedPersistedSnapshot: source.usedPersistedSnapshot,
  );
}

double _roundAmount(double value) => (value * 100).roundToDouble() / 100;

String normalizeIndianGstStateCode(String? value) {
  final normalized = (value ?? '').trim().toUpperCase();
  if (normalized.isEmpty) {
    return '';
  }
  if (RegExp(r'^\d{1,2}$').hasMatch(normalized)) {
    return normalized.padLeft(2, '0');
  }
  final name = normalized.replaceAll(RegExp(r'[^A-Z]'), '');
  return const <String, String>{
        'JAMMUANDKASHMIR': '01',
        'JAMMUKASHMIR': '01',
        'HIMACHALPRADESH': '02',
        'PUNJAB': '03',
        'CHANDIGARH': '04',
        'UTTARAKHAND': '05',
        'HARYANA': '06',
        'DELHI': '07',
        'RAJASTHAN': '08',
        'UTTARPRADESH': '09',
        'BIHAR': '10',
        'SIKKIM': '11',
        'ARUNACHALPRADESH': '12',
        'NAGALAND': '13',
        'MANIPUR': '14',
        'MIZORAM': '15',
        'TRIPURA': '16',
        'MEGHALAYA': '17',
        'ASSAM': '18',
        'WESTBENGAL': '19',
        'JHARKHAND': '20',
        'ODISHA': '21',
        'ORISSA': '21',
        'CHHATTISGARH': '22',
        'MADHYAPRADESH': '23',
        'GUJARAT': '24',
        'DADRAANDNAGARHAVELIANDDAMANANDDIU': '26',
        'MAHARASHTRA': '27',
        'ANDHRAPRADESH': '37',
        'KARNATAKA': '29',
        'GOA': '30',
        'LAKSHADWEEP': '31',
        'KERALA': '32',
        'TAMILNADU': '33',
        'PUDUCHERRY': '34',
        'PONDICHERRY': '34',
        'ANDAMANANDNICOBARISLANDS': '35',
        'TELANGANA': '36',
        'LADAKH': '38',
        'OTHERTERRITORY': '97',
      }[name] ??
      '';
}

double? _parseStoredAmount(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  final normalized = value?.toString().trim().replaceAll(',', '') ?? '';
  return normalized.isEmpty ? null : double.tryParse(normalized);
}
