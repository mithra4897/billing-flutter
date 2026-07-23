import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../screen.dart';

class SalesInvoiceExportButton extends StatefulWidget {
  const SalesInvoiceExportButton({super.key, required this.invoices});

  final List<SalesInvoiceModel> invoices;

  @override
  State<SalesInvoiceExportButton> createState() =>
      _SalesInvoiceExportButtonState();
}

class _SalesInvoiceExportButtonState extends State<SalesInvoiceExportButton> {
  static final RegExp _gstinPattern = RegExp(
    r'\b\d{2}[A-Z]{5}\d{4}[A-Z][1-9A-Z]Z[A-Z0-9]\b',
    caseSensitive: false,
  );

  static const List<String> _headers = <String>[
    '',
    'Date',
    'Customer',
    'State',
    'GSTIN',
    'Invoice No',
    'HSN',
    'GST%',
    'Qty',
    'Taxable Amount',
    'IGST',
    'CGST',
    'SGST',
    'Amount',
  ];

  final SalesService _salesService = SalesService();

  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    return AdaptiveShellActionButton(
      onPressed: _exporting ? null : _exportInvoices,
      icon: Icons.file_download_outlined,
      label: 'Export',
      filled: false,
    );
  }

  Future<void> _exportInvoices() async {
    if (widget.invoices.isEmpty) {
      _showMessage('No sales invoices to export.');
      return;
    }

    setState(() {
      _exporting = true;
    });

    try {
      final exportData = await _loadInvoiceDetails(widget.invoices);
      if (exportData.invoiceDetails.isEmpty) {
        final reason = exportData.failures.isNotEmpty
            ? exportData.failures.first.error
            : 'No invoice details were available.';
        throw reason;
      }
      final workbook = _buildWorkbook(exportData.invoiceDetails);
      final saved = await saveBytesFile(
        suggestedName: _suggestedFileName(),
        bytes: workbook,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (saved) {
        final failures = exportData.failures;
        if (failures.isEmpty) {
          _showMessage('Sales invoices exported successfully.');
        } else {
          final labels = failures
              .take(3)
              .map((failure) => failure.label)
              .where((label) => label.isNotEmpty)
              .join(', ');
          final suffix = failures.length > 3 ? ' and more' : '';
          _showMessage(
            'Sales invoices exported with ${failures.length} skipped: $labels$suffix.',
          );
        }
      } else {
        _showMessage('Sales invoice export cancelled.');
      }
    } catch (error) {
      _showMessage('Sales invoice export failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
        });
      }
    }
  }

  Future<_InvoiceExportLoadResult> _loadInvoiceDetails(
    List<SalesInvoiceModel> invoices,
  ) async {
    final invoiceIds = invoices
        .map((invoice) => invoice.id ?? 0)
        .where((id) => id > 0)
        .toList(growable: false);
    if (invoiceIds.isEmpty) {
      return const _InvoiceExportLoadResult(
        invoiceDetails: <Map<String, dynamic>>[],
        failures: <_InvoiceExportFailure>[],
      );
    }

    final response = await _salesService.invoiceExportData(invoiceIds);
    final details = response.data ?? const <Map<String, dynamic>>[];
    final returnedIds = details
        .map((item) => intValue(item, 'id') ?? 0)
        .where((id) => id > 0)
        .toSet();
    final failures = invoices
        .where((invoice) => (invoice.id ?? 0) > 0)
        .where((invoice) => !returnedIds.contains(invoice.id ?? 0))
        .map(
          (invoice) => _InvoiceExportFailure(
            label: _invoiceLabel(invoice),
            error: 'Invoice details were not returned by the export service.',
          ),
        )
        .toList(growable: false);

    return _InvoiceExportLoadResult(
      invoiceDetails: details,
      failures: failures,
    );
  }

  void _showMessage(String message) {
    final messenger =
        ScaffoldMessenger.maybeOf(context) ??
        appScaffoldMessengerKey.currentState;
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  String _suggestedFileName() {
    final now = DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final time =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return 'sales_invoices_${date}_$time.xlsx';
  }

  String _invoiceLabel(SalesInvoiceModel invoice) {
    final invoiceNo = invoice.invoiceNo?.trim() ?? '';
    if (invoiceNo.isNotEmpty) {
      return invoiceNo;
    }
    final id = invoice.id ?? 0;
    return id > 0 ? 'Invoice #$id' : 'Invoice';
  }

  Uint8List _buildWorkbook(List<Map<String, dynamic>> invoiceDetails) {
    final rows = <List<_ExcelCell>>[
      List<_ExcelCell>.filled(_headers.length, _ExcelCell.text('')),
      <_ExcelCell>[
        _ExcelCell.text(''),
        _ExcelCell.text(
          invoiceDetails.isNotEmpty
              ? displayDate(
                  nullableStringValue(invoiceDetails.first, 'invoice_date'),
                )
              : '',
        ),
        _ExcelCell.text(_companyLabel(invoiceDetails.firstOrNull)),
      ],
      _headers.map(_ExcelCell.header).toList(growable: false),
    ];

    for (final invoice in invoiceDetails) {
      rows.addAll(_buildInvoiceRows(invoice));
    }

    final archive = Archive()
      ..addFile(ArchiveFile.string('[Content_Types].xml', _contentTypesXml()))
      ..addFile(ArchiveFile.string('_rels/.rels', _rootRelsXml()))
      ..addFile(ArchiveFile.string('docProps/app.xml', _appXml()))
      ..addFile(ArchiveFile.string('docProps/core.xml', _coreXml()))
      ..addFile(ArchiveFile.string('xl/workbook.xml', _workbookXml()))
      ..addFile(
        ArchiveFile.string('xl/_rels/workbook.xml.rels', _workbookRelsXml()),
      )
      ..addFile(ArchiveFile.string('xl/styles.xml', _stylesXml()))
      ..addFile(
        ArchiveFile.string('xl/worksheets/sheet1.xml', _worksheetXml(rows)),
      );

    final bytes = ZipEncoder().encode(archive);
    return Uint8List.fromList(bytes);
  }

  List<List<_ExcelCell>> _buildInvoiceRows(Map<String, dynamic> invoice) {
    final customer = _asMap(invoice['customer']);
    final directCustomerDetails = nullableStringValue(
      invoice,
      'direct_customer_details',
    );
    final customerName = _firstNonEmpty(<String?>[
      _formatDirectCustomerDetails(directCustomerDetails),
      stringValue(customer, 'party_name'),
      nullableStringValue(invoice, 'customer_name'),
    ]);
    final gstin = _resolveCustomerGstin(invoice, customer);
    final state = _resolveCustomerState(invoice, customer, gstin);
    final invoiceNo = _firstNonEmpty(<String?>[
      nullableStringValue(invoice, 'invoice_no'),
      nullableStringValue(invoice, 'document_no'),
      if ((intValue(invoice, 'id') ?? 0) > 0)
        'Draft #${intValue(invoice, 'id') ?? 0}',
    ]);
    final invoiceDate = displayDate(
      nullableStringValue(invoice, 'invoice_date'),
    );
    final isInterState = _resolveIsInterState(invoice, gstin);
    final lines = _asListOfMaps(invoice['lines']);
    if (lines.isEmpty) {
      return <List<_ExcelCell>>[
        <_ExcelCell>[
          _ExcelCell.text(''),
          _ExcelCell.text(invoiceDate),
          _ExcelCell.text(customerName),
          _ExcelCell.text(state),
          _ExcelCell.text(gstin),
          _ExcelCell.text(invoiceNo),
          _ExcelCell.text(''),
          _ExcelCell.number(0),
          _ExcelCell.number(0),
          _ExcelCell.number(0),
          _ExcelCell.number(0),
          _ExcelCell.number(0),
          _ExcelCell.number(0),
          _ExcelCell.number(0),
        ],
      ];
    }

    final hsnValues = <String>{};
    final gstPercentValues = <String>{};
    var totalQty = 0.0;
    var totalTaxable = 0.0;
    var totalIgst = 0.0;
    var totalCgst = 0.0;
    var totalSgst = 0.0;
    var totalAmount = 0.0;

    for (final line in lines) {
      final item = _asMap(line['item']);
      final taxCode = _asMap(line['tax_code']);
      final taxCodeModel = taxCode.isEmpty
          ? null
          : TaxCodeModel.fromJson(taxCode);
      final qty =
          Validators.parseFlexibleNumber(line['invoiced_qty']?.toString()) ??
          Validators.parseFlexibleNumber(line['qty']?.toString()) ??
          0;
      final rate =
          Validators.parseFlexibleNumber(line['rate']?.toString()) ?? 0;
      final discount =
          Validators.parseFlexibleNumber(
            line['discount_percent']?.toString(),
          ) ??
          0;
      final rawTaxPercent =
          Validators.parseFlexibleNumber(line['tax_percent']?.toString()) ??
          Validators.parseFlexibleNumber(taxCode['rate']?.toString()) ??
          Validators.parseFlexibleNumber(taxCode['tax_percent']?.toString()) ??
          0;
      final breakdown = computeSalesLineTaxBreakdown(
        qty: qty,
        rate: rate,
        discountPercent: discount,
        taxCode: taxCodeModel,
        isInterState: isInterState,
      );
      final taxable =
          Validators.parseFlexibleNumber(line['taxable_amount']?.toString()) ??
          breakdown.taxable;
      final igst =
          Validators.parseFlexibleNumber(line['igst_amount']?.toString()) ??
          breakdown.igst;
      final cgst =
          Validators.parseFlexibleNumber(line['cgst_amount']?.toString()) ??
          breakdown.cgst;
      final sgst =
          Validators.parseFlexibleNumber(line['sgst_amount']?.toString()) ??
          breakdown.sgst;
      final amount =
          Validators.parseFlexibleNumber(line['line_total']?.toString()) ??
          roundToDouble(taxable + igst + cgst + sgst, 2);
      final hsn = _firstNonEmpty(<String?>[
        nullableStringValue(item, 'hsn_sac_code'),
        nullableStringValue(item, 'hsn_code'),
        nullableStringValue(item, 'sac_code'),
      ]);

      if (hsn.isNotEmpty) {
        hsnValues.add(hsn);
      }
      gstPercentValues.add(_formatExportNumber(rawTaxPercent));
      totalQty += qty;
      totalTaxable += taxable;
      totalIgst += igst;
      totalCgst += cgst;
      totalSgst += sgst;
      totalAmount += amount;
    }

    return <List<_ExcelCell>>[
      <_ExcelCell>[
        _ExcelCell.text(''),
        _ExcelCell.text(invoiceDate),
        _ExcelCell.text(customerName),
        _ExcelCell.text(state),
        _ExcelCell.text(gstin),
        _ExcelCell.text(invoiceNo),
        _ExcelCell.text(hsnValues.join(', ')),
        _ExcelCell.text(gstPercentValues.join(', ')),
        _ExcelCell.number(roundToDouble(totalQty, 2)),
        _ExcelCell.number(roundToDouble(totalTaxable, 2)),
        _ExcelCell.number(roundToDouble(totalIgst, 2)),
        _ExcelCell.number(roundToDouble(totalCgst, 2)),
        _ExcelCell.number(roundToDouble(totalSgst, 2)),
        _ExcelCell.number(roundToDouble(totalAmount, 2)),
      ],
    ];
  }

  String _formatExportNumber(double value) {
    final decimals = AppFormatSettings.resolvedDecimalPlaces();
    return value == value.roundToDouble()
        ? value.roundToDouble().toStringAsFixed(0)
        : AppFormatSettings.fixedNumber(value, decimals: decimals);
  }

  String _companyLabel(Map<String, dynamic>? invoice) {
    if (invoice == null) {
      return 'SALES INVOICE';
    }
    final company = _asMap(invoice['company']);
    final branch = _asMap(invoice['branch']);
    final location = _asMap(invoice['location']);
    final parts = <String>[
      _firstNonEmpty(<String?>[
        nullableStringValue(company, 'company_name'),
        nullableStringValue(company, 'name'),
      ]),
      _firstNonEmpty(<String?>[
        nullableStringValue(branch, 'branch_name'),
        nullableStringValue(branch, 'name'),
      ]),
      _firstNonEmpty(<String?>[
        nullableStringValue(location, 'location_name'),
        nullableStringValue(location, 'name'),
      ]),
    ].where((value) => value.trim().isNotEmpty).toList(growable: false);
    return parts.isEmpty ? 'SALES INVOICE' : parts.join(' / ');
  }

  String _resolveCustomerGstin(
    Map<String, dynamic> invoice,
    Map<String, dynamic> customer,
  ) {
    final preferredGstDetail = _preferredGstDetail(invoice, customer);
    return _firstNonEmpty(<String?>[
      nullableStringValue(_preferredAddress(invoice, customer), 'gstin'),
      nullableStringValue(preferredGstDetail, 'gstin'),
      nullableStringValue(invoice, 'party_gstin'),
      nullableStringValue(invoice, 'customer_gstin'),
      nullableStringValue(invoice, 'gstin'),
      nullableStringValue(customer, 'gstin'),
      nullableStringValue(customer, 'party_gstin'),
      nullableStringValue(customer, 'gst_no'),
      nullableStringValue(customer, 'customer_gstin'),
      _gstinFromDirectCustomerDetails(
        nullableStringValue(invoice, 'direct_customer_details'),
      ),
    ]).toUpperCase();
  }

  String _formatDirectCustomerDetails(String? details) {
    final value = details?.trim() ?? '';
    if (value.isEmpty) {
      return '';
    }
    return formatDirectCustomerDetailsLines(value).firstOrNull?.trim() ?? '';
  }

  String _gstinFromDirectCustomerDetails(String? details) {
    return _gstinPattern.firstMatch(details ?? '')?.group(0)?.trim() ?? '';
  }

  String _resolveCustomerState(
    Map<String, dynamic> invoice,
    Map<String, dynamic> customer,
    String gstin,
  ) {
    final preferredAddress = _preferredAddress(invoice, customer);
    final preferredGstDetail = _preferredGstDetail(invoice, customer);
    final state = _firstNonEmpty(<String?>[
      nullableStringValue(preferredAddress, 'state_name'),
      nullableStringValue(preferredGstDetail, 'state_name'),
      nullableStringValue(invoice, 'state_name'),
      nullableStringValue(customer, 'state_name'),
    ]);
    if (state.isNotEmpty) {
      return state;
    }
    return _stateNameFromGstin(gstin);
  }

  bool? _resolveIsInterState(
    Map<String, dynamic> invoice,
    String customerGstin,
  ) {
    final company = _asMap(invoice['company']);
    final location = _asMap(invoice['location']);
    final customer = _asMap(invoice['customer']);
    final preferredGstDetail = _preferredGstDetail(invoice, customer);
    final companyCode = _firstNonEmpty(<String?>[
      nullableStringValue(location, 'state_code'),
      nullableStringValue(company, 'state_code'),
      _gstStateFromGstin(nullableStringValue(company, 'gstin')),
    ]);
    final customerCode = _firstNonEmpty(<String?>[
      nullableStringValue(_preferredAddress(invoice, customer), 'state_code'),
      nullableStringValue(preferredGstDetail, 'state_code'),
      nullableStringValue(invoice, 'state_code'),
      nullableStringValue(customer, 'state_code'),
      _gstStateFromGstin(customerGstin),
    ]);
    if (companyCode.isEmpty || customerCode.isEmpty) {
      return null;
    }
    return companyCode != customerCode;
  }

  Map<String, dynamic> _preferredAddress(
    Map<String, dynamic> invoice,
    Map<String, dynamic> customer,
  ) {
    for (final key in <String>[
      'billing_address',
      'shipping_address',
      'address',
    ]) {
      final nested = _asMap(invoice[key]);
      if (nested.isNotEmpty) {
        return nested;
      }
    }

    for (final key in <String>[
      'addresses',
      'party_addresses',
      'customer_addresses',
    ]) {
      final values = _asListOfMaps(customer[key]);
      if (values.isNotEmpty) {
        final active = values.where((item) => item['is_active'] != false);
        for (final candidate in active) {
          if (candidate['is_default'] == true) {
            return candidate;
          }
        }
        return active.isNotEmpty ? active.first : values.first;
      }
    }

    return const <String, dynamic>{};
  }

  Map<String, dynamic> _preferredGstDetail(
    Map<String, dynamic> invoice,
    Map<String, dynamic> customer,
  ) {
    for (final key in <String>[
      'gst_detail',
      'gst_details',
      'party_gst_details',
      'customer_gst_details',
    ]) {
      final nested = _asMap(invoice[key]);
      if (nested.isNotEmpty) {
        return nested;
      }
    }

    for (final key in <String>[
      'gst_details',
      'gstDetails',
      'party_gst_details',
      'customer_gst_details',
    ]) {
      final values = _asListOfMaps(customer[key]);
      if (values.isNotEmpty) {
        final active = values.where((item) => item['is_active'] != false);
        for (final candidate in active) {
          if (candidate['is_default'] == true) {
            return candidate;
          }
        }
        return active.isNotEmpty ? active.first : values.first;
      }
    }

    return const <String, dynamic>{};
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(
        value.map((key, item) => MapEntry(key.toString(), item)),
      );
    }
    return const <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asListOfMaps(dynamic value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }
    return value
        .map(_asMap)
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final normalized = (value ?? '').trim();
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return '';
  }

  String _gstStateFromGstin(String? gstin) {
    final normalized = (gstin ?? '').trim().toUpperCase();
    if (normalized.length < 2) {
      return '';
    }
    final prefix = normalized.substring(0, 2);
    return RegExp(r'^\d{2}$').hasMatch(prefix) ? prefix : '';
  }

  String _stateNameFromGstin(String? gstin) {
    switch (_gstStateFromGstin(gstin)) {
      case '01':
        return 'Jammu & Kashmir';
      case '02':
        return 'Himachal Pradesh';
      case '03':
        return 'Punjab';
      case '04':
        return 'Chandigarh';
      case '05':
        return 'Uttarakhand';
      case '06':
        return 'Haryana';
      case '07':
        return 'Delhi';
      case '08':
        return 'Rajasthan';
      case '09':
        return 'Uttar Pradesh';
      case '10':
        return 'Bihar';
      case '11':
        return 'Sikkim';
      case '12':
        return 'Arunachal Pradesh';
      case '13':
        return 'Nagaland';
      case '14':
        return 'Manipur';
      case '15':
        return 'Mizoram';
      case '16':
        return 'Tripura';
      case '17':
        return 'Meghalaya';
      case '18':
        return 'Assam';
      case '19':
        return 'West Bengal';
      case '20':
        return 'Jharkhand';
      case '21':
        return 'Odisha';
      case '22':
        return 'Chhattisgarh';
      case '23':
        return 'Madhya Pradesh';
      case '24':
        return 'Gujarat';
      case '26':
        return 'Dadra & Nagar Haveli and Daman & Diu';
      case '27':
        return 'Maharashtra';
      case '28':
        return 'Andhra Pradesh';
      case '29':
        return 'Karnataka';
      case '30':
        return 'Goa';
      case '31':
        return 'Lakshadweep';
      case '32':
        return 'Kerala';
      case '33':
        return 'Tamil Nadu';
      case '34':
        return 'Puducherry';
      case '35':
        return 'Andaman & Nicobar Islands';
      case '36':
        return 'Telangana';
      case '37':
        return 'Andhra Pradesh';
      case '38':
        return 'Ladakh';
      case '97':
        return 'Other Territory';
      default:
        return '';
    }
  }

  String _contentTypesXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>''';
  }

  String _rootRelsXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>''';
  }

  String _appXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>Billing ERP</Application>
</Properties>''';
  }

  String _coreXml() {
    final created = DateTime.now().toUtc().toIso8601String();
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:creator>Billing ERP</dc:creator>
  <cp:lastModifiedBy>Billing ERP</cp:lastModifiedBy>
  <dcterms:created xsi:type="dcterms:W3CDTF">$created</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">$created</dcterms:modified>
</cp:coreProperties>''';
  }

  String _workbookXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="Sales Invoices" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>''';
  }

  String _workbookRelsXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';
  }

  String _stylesXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="2">
    <font>
      <sz val="11"/>
      <name val="Calibri"/>
    </font>
    <font>
      <b/>
      <sz val="11"/>
      <name val="Calibri"/>
    </font>
  </fonts>
  <fills count="3">
    <fill><patternFill patternType="none"/></fill>
    <fill><patternFill patternType="gray125"/></fill>
    <fill><patternFill patternType="solid"><fgColor rgb="FFE9EEF7"/><bgColor indexed="64"/></patternFill></fill>
  </fills>
  <borders count="1">
    <border><left/><right/><top/><bottom/><diagonal/></border>
  </borders>
  <cellStyleXfs count="1">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>
  </cellStyleXfs>
  <cellXfs count="3">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
    <xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"/>
    <xf numFmtId="4" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>
  </cellXfs>
  <cellStyles count="1">
    <cellStyle name="Normal" xfId="0" builtinId="0"/>
  </cellStyles>
</styleSheet>''';
  }

  String _worksheetXml(List<List<_ExcelCell>> rows) {
    final builder = XmlBuilder();
    builder.processing(
      'xml',
      'version="1.0" encoding="UTF-8" standalone="yes"',
    );
    builder.element(
      'worksheet',
      namespaces: <String, String>{
        'http://schemas.openxmlformats.org/spreadsheetml/2006/main': '',
      },
      nest: () {
        builder.element(
          'sheetViews',
          nest: () {
            builder.element('sheetView', attributes: {'workbookViewId': '0'});
          },
        );
        builder.element(
          'sheetFormatPr',
          attributes: {'defaultRowHeight': '15'},
        );
        builder.element(
          'cols',
          nest: () {
            final widths = <double>[
              4,
              14,
              28,
              20,
              20,
              18,
              12,
              10,
              10,
              16,
              14,
              14,
              14,
              16,
            ];
            for (var i = 0; i < widths.length; i++) {
              builder.element(
                'col',
                attributes: {
                  'min': '${i + 1}',
                  'max': '${i + 1}',
                  'width': widths[i].toStringAsFixed(2),
                  'customWidth': '1',
                },
              );
            }
          },
        );
        builder.element(
          'sheetData',
          nest: () {
            for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
              final row = rows[rowIndex];
              builder.element(
                'row',
                attributes: {'r': '${rowIndex + 1}'},
                nest: () {
                  for (
                    var columnIndex = 0;
                    columnIndex < row.length;
                    columnIndex++
                  ) {
                    final cell = row[columnIndex];
                    final ref =
                        '${_columnName(columnIndex + 1)}${rowIndex + 1}';
                    builder.element(
                      'c',
                      attributes: {
                        'r': ref,
                        's': cell.styleIndex.toString(),
                        if (cell.isNumber) 't': 'n' else 't': 'inlineStr',
                      },
                      nest: () {
                        if (cell.isNumber) {
                          builder.element('v', nest: cell.value);
                        } else {
                          builder.element(
                            'is',
                            nest: () {
                              builder.element('t', nest: cell.value);
                            },
                          );
                        }
                      },
                    );
                  }
                },
              );
            }
          },
        );
      },
    );
    return builder.buildDocument().toXmlString(pretty: false);
  }

  String _columnName(int index) {
    var value = index;
    final buffer = StringBuffer();
    while (value > 0) {
      final remainder = (value - 1) % 26;
      buffer.writeCharCode(65 + remainder);
      value = (value - 1) ~/ 26;
    }
    return buffer.toString().split('').reversed.join();
  }
}

class _InvoiceExportLoadResult {
  const _InvoiceExportLoadResult({
    required this.invoiceDetails,
    required this.failures,
  });

  final List<Map<String, dynamic>> invoiceDetails;
  final List<_InvoiceExportFailure> failures;
}

class _InvoiceExportFailure {
  const _InvoiceExportFailure({required this.label, required this.error});

  final String label;
  final String error;
}

class _ExcelCell {
  const _ExcelCell._({
    required this.value,
    required this.isNumber,
    required this.styleIndex,
  });

  factory _ExcelCell.text(String value) =>
      _ExcelCell._(value: value, isNumber: false, styleIndex: 0);

  factory _ExcelCell.header(String value) =>
      _ExcelCell._(value: value, isNumber: false, styleIndex: 1);

  factory _ExcelCell.number(num value) => _ExcelCell._(
    value: AppFormatSettings.fixedNumber(value.toDouble()),
    isNumber: true,
    styleIndex: 2,
  );

  final String value;
  final bool isNumber;
  final int styleIndex;
}
