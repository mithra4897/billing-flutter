import '../../screen.dart';

const Object _documentPrintTemplateUnset = Object();

class DocumentPrintTemplate {
  const DocumentPrintTemplate({
    required this.pageWidth,
    required this.pageHeight,
    required this.shapes,
    this.backgroundImagePath,
    this.backgroundOpacity = 0.18,
    this.mediaPreset = 'A4',
    this.orientation = 'portrait',
    this.gridSize = 8,
    this.showGrid = false,
  });

  final double pageWidth;
  final double pageHeight;
  final List<DocumentPrintShape> shapes;
  final String? backgroundImagePath;
  final double backgroundOpacity;
  final String mediaPreset;
  final String orientation;
  final double gridSize;
  final bool showGrid;

  factory DocumentPrintTemplate.fromJson(Map<String, dynamic> json) {
    return DocumentPrintTemplate(
      pageWidth: _toDouble(json['pageWidth'], 595),
      pageHeight: _toDouble(json['pageHeight'], 842),
      backgroundImagePath: nullableStringValue(json, 'backgroundImagePath'),
      backgroundOpacity: _toDouble(json['backgroundOpacity'], 0.18),
      mediaPreset: stringValue(json, 'mediaPreset', 'A4'),
      orientation: stringValue(json, 'orientation', 'portrait'),
      gridSize: _toDouble(json['gridSize'], 8),
      showGrid: boolValue(json, 'showGrid'),
      shapes: (json['shapes'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(DocumentPrintShape.fromJson)
          .toList(growable: false),
    );
  }

  factory DocumentPrintTemplate.defaults(String documentType, {String? title}) {
    final resolvedTitle = (title ?? _documentTitleForType(documentType))
        .toUpperCase();

    if (documentType == 'hr_payslip') {
      return _defaultPayslipPrintTemplate(resolvedTitle);
    }

    return DocumentPrintTemplate(
      pageWidth: 595,
      pageHeight: 842,
      mediaPreset: 'A4',
      orientation: 'portrait',
      shapes: [
        const DocumentPrintShape(
          id: 'pbs-outer-border',
          type: 'rectangle',
          x: 29,
          y: 28,
          width: 537,
          height: 786,
          strokeColor: 0xFF3C86B5,
          strokeWidth: 1,
        ),

        DocumentPrintShape(
          id: 'text-doc-type',
          type: 'text',
          x: 160,
          y: 32,
          width: 160,
          height: 18,
          text: resolvedTitle,
          fontSize: 11,
          bold: true,
          align: 'center',
          strokeColor: 0xFF111827,
        ),

        const DocumentPrintShape(
          id: 'gstin-label',
          type: 'text',
          x: 368,
          y: 32,
          width: 42,
          height: 18,
          text: 'GSTIN :',
          fontSize: 9,
          strokeColor: 0xFF374151,
        ),

        const DocumentPrintShape(
          id: 'gstin-value',
          type: 'text',
          x: 412,
          y: 32,
          width: 148,
          height: 18,
          text: '{{company_gstin}}',
          fontSize: 9,
          bold: true,
          strokeColor: 0xFF111827,
        ),

        const DocumentPrintShape(
          id: 'header-top-divider',
          type: 'line',
          x: 29,
          y: 54,
          width: 537,
          height: 0,
          strokeColor: 0xFFA6A6A6,
        ),

        const DocumentPrintShape(
          id: 'company-logo',
          type: 'image',
          x: 159,
          y: 58,
          width: 38,
          height: 38,
          strokeWidth: 0,
          assetPath: '{{company_logo_url}}',
        ),

        const DocumentPrintShape(
          id: 'company-address',
          type: 'text',
          x: 56,
          y: 100,
          width: 257,
          height: 54,
          text: 'Cell : {{party_contact}}',
          fontSize: 9,
          multiline: true,
          strokeColor: 0xFF374151,
        ),

        const DocumentPrintShape(
          id: 'header-vertical-divider',
          type: 'line',
          x: 327,
          y: 28,
          width: 0,
          height: 152,
          strokeColor: 0xFFA6A6A6,
        ),

        const DocumentPrintShape(
          id: 'customer-label',
          type: 'text',
          x: 334,
          y: 58,
          width: 230,
          height: 16,
          text: 'Customer',
          fontSize: 9,
          bold: true,
          strokeColor: 0xFF374151,
        ),

        DocumentPrintShape(
          id: 'party-text',
          type: 'text',
          x: 334,
          y: 76,
          width: 228,
          height: 64,
          text: '{{party_name}}\n{{party_address}}\n{{party_contact}}',
          fontSize: 9,
          multiline: true,
          strokeColor: 0xFF111827,
        ),

        const DocumentPrintShape(
          id: 'customer-gstn-label',
          type: 'text',
          x: 329,
          y: 148,
          width: 84,
          height: 14,
          text: 'Customer GSTN :',
          fontSize: 9,
          strokeColor: 0xFF374151,
        ),

        const DocumentPrintShape(
          id: 'customer-gstn-value',
          type: 'text',
          x: 414,
          y: 148,
          width: 148,
          height: 14,
          text: '{{party_gstin}}',
          fontSize: 9,
          strokeColor: 0xFF111827,
        ),

        const DocumentPrintShape(
          id: 'header-divider',
          type: 'line',
          x: 29,
          y: 180,
          width: 537,
          height: 0,
          strokeColor: 0xFFA6A6A6,
        ),

        const DocumentPrintShape(
          id: 'doc-no-label',
          type: 'text',
          x: 37,
          y: 184,
          width: 50,
          height: 16,
          text: 'Doc No :',
          fontSize: 9,
          strokeColor: 0xFF374151,
        ),
        const DocumentPrintShape(
          id: 'doc-no-value',
          type: 'text',
          x: 89,
          y: 184,
          width: 110,
          height: 16,
          text: '{{document_number}}',
          fontSize: 9,
          bold: true,
          strokeColor: 0xFF111827,
        ),
        const DocumentPrintShape(
          id: 'date-label',
          type: 'text',
          x: 222,
          y: 184,
          width: 35,
          height: 16,
          text: 'Date :',
          fontSize: 9,
          strokeColor: 0xFF374151,
        ),
        const DocumentPrintShape(
          id: 'date-value',
          type: 'text',
          x: 258,
          y: 184,
          width: 78,
          height: 16,
          text: '{{document_date}}',
          fontSize: 9,
          bold: true,
          strokeColor: 0xFF111827,
        ),
        const DocumentPrintShape(
          id: 'ref-label',
          type: 'text',
          x: 354,
          y: 184,
          width: 30,
          height: 16,
          text: 'Ref :',
          fontSize: 9,
          strokeColor: 0xFF374151,
        ),
        const DocumentPrintShape(
          id: 'ref-value',
          type: 'text',
          x: 386,
          y: 184,
          width: 178,
          height: 16,
          text: '{{reference_number}}',
          fontSize: 9,
          strokeColor: 0xFF111827,
        ),

        DocumentPrintShape(
          id: 'lines-table',
          type: 'table',
          x: 29,
          y: 204,
          width: 537,
          height: 365,
          dataPath: 'lines',
          rowHeight: 26,
          titleHeight: 22,
          cellGap: 4,
          strokeColor: 0xFF3C86B5,
          headerColor: 0xFFADD0F0,
          headerTextColor: 0xFF111827,
          printHeader: true,
          printTotal: true,
          columns: const [
            DocumentPrintColumn(
              key: 'line_no',
              label: 'S.No',
              widthFactor: 0.9,
              align: 'center',
              titleAlign: 'center',
            ),
            DocumentPrintColumn(
              key: 'item_name',
              label: 'Item',
              widthFactor: 3.6,
            ),
            DocumentPrintColumn(
              key: 'hsn',
              label: 'HSN',
              widthFactor: 1.6,
              align: 'center',
              titleAlign: 'center',
            ),
            DocumentPrintColumn(
              key: 'qty',
              label: 'Qty',
              widthFactor: 1.0,
              align: 'center',
              titleAlign: 'center',
            ),
            DocumentPrintColumn(
              key: 'rate',
              label: 'Price',
              widthFactor: 1.5,
              align: 'right',
              titleAlign: 'center',
            ),
            DocumentPrintColumn(
              key: 'tax_amount',
              label: 'Tax',
              widthFactor: 1.2,
              align: 'right',
              titleAlign: 'center',
              totalColumn: true,
            ),
            DocumentPrintColumn(
              key: 'line_total',
              label: 'Amount',
              widthFactor: 1.3,
              align: 'right',
              titleAlign: 'center',
              totalColumn: true,
            ),
          ],
        ),

        const DocumentPrintShape(
          id: 'amount-words-label',
          type: 'text',
          x: 30,
          y: 578,
          width: 89,
          height: 14,
          text: 'Amount in Words:',
          fontSize: 9,
          strokeColor: 0xFF374151,
        ),
        const DocumentPrintShape(
          id: 'amount-words-value',
          type: 'text',
          x: 122,
          y: 578,
          width: 240,
          height: 28,
          text: '{{amount_in_words}}',
          fontSize: 9,
          italic: true,
          multiline: true,
          strokeColor: 0xFF111827,
        ),

        DocumentPrintShape(
          id: 'gst-breakup-table',
          type: 'table',
          x: 30,
          y: 614,
          width: 318,
          height: 72,
          dataPath: 'gst_breakup',
          rowHeight: 18,
          titleHeight: 18,
          cellGap: 3,
          strokeColor: 0xFF3C86B5,
          headerColor: 0xFFADD0F0,
          headerTextColor: 0xFF111827,
          printHeader: true,
          printTotal: false,
          columns: const [
            DocumentPrintColumn(
              key: 'tax_name',
              label: 'Tax',
              widthFactor: 2.5,
            ),
            DocumentPrintColumn(
              key: 'taxable',
              label: 'Taxable Val',
              widthFactor: 2.5,
              align: 'right',
              titleAlign: 'center',
            ),
            DocumentPrintColumn(
              key: 'cgst',
              label: 'CGST',
              widthFactor: 2.0,
              align: 'right',
              titleAlign: 'center',
            ),
            DocumentPrintColumn(
              key: 'sgst',
              label: 'SGST',
              widthFactor: 2.0,
              align: 'right',
              titleAlign: 'center',
            ),
            DocumentPrintColumn(
              key: 'igst',
              label: 'IGST',
              widthFactor: 2.0,
              align: 'right',
              titleAlign: 'center',
            ),
          ],
        ),

        const DocumentPrintShape(
          id: 'totals-box',
          type: 'rectangle',
          x: 366,
          y: 578,
          width: 198,
          height: 80,
          strokeColor: 0xFF3C86B5,
          strokeWidth: 1,
        ),
        DocumentPrintShape(
          id: 'totals-text',
          type: 'text',
          x: 370,
          y: 582,
          width: 190,
          height: 72,
          text:
              'Subtotal : {{subtotal}}\nTax      : {{tax_amount}}\nTotal    : {{total_amount}}',
          fontSize: 10,
          bold: true,
          multiline: true,
          align: 'right',
          strokeColor: 0xFF111827,
        ),

        const DocumentPrintShape(
          id: 'total-amount-label',
          type: 'text',
          x: 366,
          y: 666,
          width: 68,
          height: 18,
          text: 'Total Amount',
          fontSize: 9,
          strokeColor: 0xFF374151,
        ),
        const DocumentPrintShape(
          id: 'total-amount-value',
          type: 'text',
          x: 436,
          y: 662,
          width: 128,
          height: 26,
          text: '{{total_amount}}',
          fontSize: 20,
          bold: true,
          align: 'right',
          strokeColor: 0xFF111827,
        ),

        const DocumentPrintShape(
          id: 'terms-title',
          type: 'text',
          x: 31,
          y: 696,
          width: 130,
          height: 14,
          text: 'Terms and Condition',
          fontSize: 9,
          bold: true,
          strokeColor: 0xFF374151,
        ),
        const DocumentPrintShape(
          id: 'terms-text',
          type: 'text',
          x: 37,
          y: 712,
          width: 320,
          height: 38,
          text: '{{terms_conditions}}',
          fontSize: 8,
          multiline: true,
          strokeColor: 0xFF374151,
        ),

        const DocumentPrintShape(
          id: 'banking-label',
          type: 'text',
          x: 30,
          y: 754,
          width: 140,
          height: 14,
          text: 'Our Banking Details',
          fontSize: 9,
          bold: true,
          strokeColor: 0xFF374151,
        ),
        const DocumentPrintShape(
          id: 'banking-details',
          type: 'text',
          x: 36,
          y: 770,
          width: 240,
          height: 40,
          text: '{{notes}}',
          fontSize: 8,
          multiline: true,
          strokeColor: 0xFF374151,
        ),

        DocumentPrintShape(
          id: 'for-company-text',
          type: 'text',
          x: 366,
          y: 696,
          width: 198,
          height: 16,
          text: 'For {{company_name}}',
          fontSize: 9,
          bold: true,
          align: 'right',
          strokeColor: 0xFF111827,
        ),
        const DocumentPrintShape(
          id: 'auth-signatory',
          type: 'text',
          x: 366,
          y: 800,
          width: 198,
          height: 14,
          text: 'Authorised Signatory',
          fontSize: 9,
          align: 'right',
          strokeColor: 0xFF374151,
        ),
      ],
    );
  }

  DocumentPrintTemplate normalizedFor(String documentType) {
    return this;
  }

  DocumentPrintShape? shapeById(String? shapeId) {
    if (shapeId == null) {
      return null;
    }
    return shapes.cast<DocumentPrintShape?>().firstWhere(
      (shape) => shape?.id == shapeId,
      orElse: () => null,
    );
  }

  DocumentPrintTemplate withoutUnsupportedShapes() {
    return copyWith(
      shapes: shapes
          .where((shape) => shape.isSupported)
          .toList(growable: false),
    );
  }

  DocumentPrintTemplate copyWith({
    double? pageWidth,
    double? pageHeight,
    List<DocumentPrintShape>? shapes,
    Object? backgroundImagePath = _documentPrintTemplateUnset,
    double? backgroundOpacity,
    String? mediaPreset,
    String? orientation,
    double? gridSize,
    bool? showGrid,
  }) {
    return DocumentPrintTemplate(
      pageWidth: pageWidth ?? this.pageWidth,
      pageHeight: pageHeight ?? this.pageHeight,
      shapes: shapes ?? this.shapes,
      backgroundImagePath:
          identical(backgroundImagePath, _documentPrintTemplateUnset)
          ? this.backgroundImagePath
          : backgroundImagePath as String?,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      mediaPreset: mediaPreset ?? this.mediaPreset,
      orientation: orientation ?? this.orientation,
      gridSize: gridSize ?? this.gridSize,
      showGrid: showGrid ?? this.showGrid,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pageWidth': pageWidth,
      'pageHeight': pageHeight,
      'backgroundImagePath': backgroundImagePath,
      'backgroundOpacity': backgroundOpacity,
      'mediaPreset': mediaPreset,
      'orientation': orientation,
      'gridSize': gridSize,
      'showGrid': showGrid,
      'shapes': shapes.map((shape) => shape.toJson()).toList(growable: false),
    };
  }
}

DocumentPrintTemplate _defaultPayslipPrintTemplate(String resolvedTitle) {
  return DocumentPrintTemplate(
    pageWidth: 595,
    pageHeight: 842,
    mediaPreset: 'A4',
    orientation: 'portrait',
    shapes: [
      const DocumentPrintShape(
        id: 'payslip-border',
        type: 'rectangle',
        x: 24,
        y: 24,
        width: 547,
        height: 794,
        strokeColor: 0xFF2563EB,
        strokeWidth: 1,
      ),
      const DocumentPrintShape(
        id: 'company-logo',
        type: 'image',
        x: 38,
        y: 36,
        width: 42,
        height: 42,
        strokeWidth: 0,
        assetPath: '{{company_logo_url}}',
      ),
      const DocumentPrintShape(
        id: 'company-name',
        type: 'text',
        x: 90,
        y: 38,
        width: 240,
        height: 18,
        text: '{{company_name}}',
        fontSize: 16,
        bold: true,
      ),
      const DocumentPrintShape(
        id: 'company-address',
        type: 'text',
        x: 90,
        y: 58,
        width: 250,
        height: 74,
        text: '{{party_address}}\n{{party_contact}}\nGSTIN: {{company_gstin}}',
        fontSize: 8.5,
        multiline: true,
      ),
      const DocumentPrintShape(
        id: 'meta-box',
        type: 'rectangle',
        x: 360,
        y: 34,
        width: 195,
        height: 94,
        strokeColor: 0xFF93C5FD,
        fillColor: 0xFFEFF6FF,
        fillAlpha: 1,
        borderRadius: 8,
      ),
      DocumentPrintShape(
        id: 'doc-title',
        type: 'text',
        x: 376,
        y: 44,
        width: 160,
        height: 18,
        text: resolvedTitle,
        fontSize: 16,
        bold: true,
        align: 'center',
        strokeColor: 0xFF1D4ED8,
      ),
      const DocumentPrintShape(
        id: 'doc-no',
        type: 'text',
        x: 374,
        y: 70,
        width: 170,
        height: 14,
        text: 'Payslip No: {{document_number}}',
        fontSize: 9,
      ),
      const DocumentPrintShape(
        id: 'doc-period',
        type: 'text',
        x: 374,
        y: 86,
        width: 170,
        height: 14,
        text: 'Payroll Period: {{reference_number}}',
        fontSize: 9,
      ),
      const DocumentPrintShape(
        id: 'doc-date',
        type: 'text',
        x: 374,
        y: 102,
        width: 170,
        height: 14,
        text: 'Payslip Date: {{document_date}}',
        fontSize: 9,
      ),
      const DocumentPrintShape(
        id: 'employee-box',
        type: 'rectangle',
        x: 34,
        y: 164,
        width: 256,
        height: 128,
        strokeColor: 0xFFBFDBFE,
        borderRadius: 8,
      ),
      const DocumentPrintShape(
        id: 'employee-box-title',
        type: 'text',
        x: 46,
        y: 174,
        width: 160,
        height: 16,
        text: 'Employee Details',
        fontSize: 11,
        bold: true,
      ),
      const DocumentPrintShape(
        id: 'employee-box-text',
        type: 'text',
        x: 46,
        y: 196,
        width: 228,
        height: 88,
        text:
            'Employee: {{employee_profile.employee_name}}\n'
            'Code: {{employee_profile.employee_code}}\n'
            'Department: {{employee_profile.department_name}}\n'
            'Designation: {{employee_profile.designation_name}}\n'
            'Joining Date: {{employee_profile.joining_date}}',
        fontSize: 9,
        multiline: true,
      ),
      const DocumentPrintShape(
        id: 'payment-box',
        type: 'rectangle',
        x: 304,
        y: 164,
        width: 252,
        height: 128,
        strokeColor: 0xFFBFDBFE,
        borderRadius: 8,
      ),
      const DocumentPrintShape(
        id: 'payment-box-title',
        type: 'text',
        x: 316,
        y: 174,
        width: 160,
        height: 16,
        text: 'Payment Details',
        fontSize: 11,
        bold: true,
      ),
      const DocumentPrintShape(
        id: 'payment-box-text',
        type: 'text',
        x: 316,
        y: 196,
        width: 228,
        height: 88,
        text:
            'Mode: {{employee_profile.salary_mode}}\n'
            'Bank A/C: {{employee_profile.bank_account_no}}\n'
            'IFSC: {{employee_profile.ifsc_code}}\n'
            'PF UAN: {{employee_profile.pf_uan_no}}\n'
            'ESI No: {{employee_profile.esi_no}}',
        fontSize: 9,
        multiline: true,
      ),
      const DocumentPrintShape(
        id: 'attendance-box',
        type: 'rectangle',
        x: 34,
        y: 306,
        width: 522,
        height: 64,
        strokeColor: 0xFFBFDBFE,
        borderRadius: 8,
      ),
      const DocumentPrintShape(
        id: 'attendance-title',
        type: 'text',
        x: 46,
        y: 316,
        width: 160,
        height: 16,
        text: 'Attendance Summary',
        fontSize: 11,
        bold: true,
      ),
      const DocumentPrintShape(
        id: 'attendance-text',
        type: 'text',
        x: 46,
        y: 338,
        width: 494,
        height: 20,
        text:
            'Working Days: {{attendance.working_days}}    '
            'Present Days: {{attendance.present_days}}    '
            'Leave Days: {{attendance.leave_days}}    '
            'Paid Days: {{attendance.paid_days}}    '
            'LOP Days: {{attendance.lop_days}}',
        fontSize: 9,
      ),
      DocumentPrintShape(
        id: 'earnings-table',
        type: 'table',
        x: 34,
        y: 386,
        width: 248,
        height: 220,
        dataPath: 'earnings',
        rowHeight: 20,
        titleHeight: 22,
        cellGap: 4,
        strokeColor: 0xFF2563EB,
        headerColor: 0xFFADD0F0,
        printHeader: true,
        printTotal: false,
        columns: const [
          DocumentPrintColumn(
            key: 'label',
            label: 'Earnings',
            widthFactor: 3.2,
          ),
          DocumentPrintColumn(
            key: 'amount',
            label: 'Amount',
            widthFactor: 1.5,
            align: 'right',
            titleAlign: 'center',
          ),
        ],
      ),
      DocumentPrintShape(
        id: 'deductions-table',
        type: 'table',
        x: 308,
        y: 386,
        width: 248,
        height: 220,
        dataPath: 'deductions',
        rowHeight: 20,
        titleHeight: 22,
        cellGap: 4,
        strokeColor: 0xFF2563EB,
        headerColor: 0xFFADD0F0,
        printHeader: true,
        printTotal: false,
        columns: const [
          DocumentPrintColumn(
            key: 'label',
            label: 'Deductions',
            widthFactor: 3.2,
          ),
          DocumentPrintColumn(
            key: 'amount',
            label: 'Amount',
            widthFactor: 1.5,
            align: 'right',
            titleAlign: 'center',
          ),
        ],
      ),
      const DocumentPrintShape(
        id: 'summary-box',
        type: 'rectangle',
        x: 308,
        y: 618,
        width: 248,
        height: 90,
        strokeColor: 0xFF93C5FD,
        fillColor: 0xFFEFF6FF,
        fillAlpha: 1,
        borderRadius: 8,
      ),
      const DocumentPrintShape(
        id: 'summary-text',
        type: 'text',
        x: 322,
        y: 632,
        width: 220,
        height: 62,
        text:
            'Gross Salary: {{salary_summary.gross_salary}}\n'
            'Total Deductions: {{salary_summary.total_deductions}}\n'
            'Net Salary: {{salary_summary.net_salary}}',
        fontSize: 10,
        multiline: true,
      ),
      const DocumentPrintShape(
        id: 'amount-words-title',
        type: 'text',
        x: 34,
        y: 618,
        width: 120,
        height: 14,
        text: 'Net Salary in Words',
        fontSize: 10,
        bold: true,
      ),
      const DocumentPrintShape(
        id: 'amount-words-text',
        type: 'text',
        x: 34,
        y: 638,
        width: 252,
        height: 52,
        text: '{{amount_in_words}}',
        fontSize: 9,
        multiline: true,
        italic: true,
      ),
      const DocumentPrintShape(
        id: 'notes-text',
        type: 'text',
        x: 34,
        y: 710,
        width: 522,
        height: 42,
        text: '{{notes}}',
        fontSize: 9,
        multiline: true,
      ),
      const DocumentPrintShape(
        id: 'terms-text',
        type: 'text',
        x: 34,
        y: 762,
        width: 522,
        height: 24,
        text: '{{terms_conditions}}',
        fontSize: 8.5,
        multiline: true,
      ),
    ],
  );
}

class DocumentPrintShape {
  const DocumentPrintShape({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.text = '',
    this.align = 'left',
    this.fontSize = 12,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.multiline = false,
    this.strokeColor = 0xFF111827,
    this.bodyTextColor = 0xFF111827,
    this.fillColor = 0xFFFFFFFF,
    this.fillAlpha = 0,
    this.strokeWidth = 1,
    this.borderRadius = 0,
    this.headerColor = 0xFFF1F5F9,
    this.headerTextColor = 0xFF111827,
    this.dataPath = 'lines',
    this.rowHeight = 30,
    this.titleHeight = 30,
    this.cellGap = 6,
    this.printHeader = true,
    this.printTotal = false,
    this.columns = const <DocumentPrintColumn>[],
    this.assetPath = '{{company_logo_url}}',
    this.sides = 5,
    this.barcodeType = 'code128',
  });

  final String id;
  final String type;
  final double x;
  final double y;
  final double width;
  final double height;
  final String text;
  final String align;
  final double fontSize;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool multiline;
  final int strokeColor;
  final int bodyTextColor;
  final int fillColor;
  final double fillAlpha;
  final double strokeWidth;
  final double borderRadius;
  final int headerColor;
  final int headerTextColor;
  final String dataPath;
  final double rowHeight;
  final double titleHeight;
  final double cellGap;
  final bool printHeader;
  final bool printTotal;
  final List<DocumentPrintColumn> columns;
  final String assetPath;
  final int sides;
  final String barcodeType;

  factory DocumentPrintShape.fromJson(Map<String, dynamic> json) {
    return DocumentPrintShape(
      id: stringValue(json, 'id'),
      type: stringValue(json, 'type', 'text'),
      x: _toDouble(json['x'], 0),
      y: _toDouble(json['y'], 0),
      width: _toDouble(json['width'], 120),
      height: _toDouble(json['height'], 24),
      text: stringValue(json, 'text'),
      align: stringValue(json, 'align', 'left'),
      fontSize: _toDouble(json['fontSize'], 12),
      bold: boolValue(json, 'bold'),
      italic: boolValue(json, 'italic'),
      underline: boolValue(json, 'underline'),
      multiline: boolValue(json, 'multiline'),
      strokeColor: _toInt(json['strokeColor'], 0xFF111827),
      bodyTextColor: _toInt(
        json['bodyTextColor'],
        _toInt(json['strokeColor'], 0xFF111827),
      ),
      fillColor: _toInt(json['fillColor'], 0xFFFFFFFF),
      fillAlpha: _toDouble(json['fillAlpha'], 0),
      strokeWidth: _toDouble(json['strokeWidth'], 1),
      borderRadius: _toDouble(json['borderRadius'], 0),
      headerColor: _toInt(json['headerColor'], 0xFFF1F5F9),
      headerTextColor: _toInt(json['headerTextColor'], 0xFF111827),
      dataPath: stringValue(json, 'dataPath', 'lines'),
      rowHeight: _toDouble(json['rowHeight'], 30),
      titleHeight: _toDouble(json['titleHeight'], 30),
      cellGap: _toDouble(json['cellGap'], 6),
      printHeader: json.containsKey('printHeader')
          ? boolValue(json, 'printHeader')
          : true,
      printTotal: boolValue(json, 'printTotal'),
      assetPath: stringValue(json, 'assetPath', '{{company_logo_url}}'),
      sides: int.tryParse(json['sides']?.toString() ?? '') ?? 5,
      barcodeType: stringValue(json, 'barcodeType', 'code128'),
      columns: (json['columns'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(DocumentPrintColumn.fromJson)
          .toList(growable: false),
    );
  }

  factory DocumentPrintShape.defaults(String type, int index) {
    switch (type) {
      case 'rectangle':
        return DocumentPrintShape(
          id: '$type-$index',
          type: type,
          x: 36,
          y: 36 + (index * 12),
          width: 180,
          height: 72,
          strokeColor: 0xFF94A3B8,
          fillAlpha: 1.0,
        );
      case 'line':
        return DocumentPrintShape(
          id: '$type-$index',
          type: type,
          x: 36,
          y: 36 + (index * 12),
          width: 220,
          height: 0,
        );
      case 'ellipse':
        return DocumentPrintShape(
          id: '$type-$index',
          type: type,
          x: 36,
          y: 36 + (index * 12),
          width: 180,
          height: 72,
          strokeColor: 0xFF94A3B8,
          fillAlpha: 0.0,
        );
      case 'polygon':
        return DocumentPrintShape(
          id: '$type-$index',
          type: type,
          x: 36,
          y: 36 + (index * 12),
          width: 140,
          height: 120,
          strokeColor: 0xFF94A3B8,
          fillAlpha: 0.0,
          sides: 5,
        );
      case 'table':
        return DocumentPrintShape(
          id: '$type-$index',
          type: type,
          x: 36,
          y: 36 + (index * 12),
          width: 500,
          height: 240,
          strokeColor: 0xFF94A3B8,
          bodyTextColor: 0xFF111827,
          columns: defaultTableColumns(),
          fillAlpha: 0.0,
        );
      case 'image':
        return DocumentPrintShape(
          id: '$type-$index',
          type: 'image',
          x: 36,
          y: 36,
          width: 84,
          height: 84,
          strokeWidth: 0,
          assetPath: '{{company_logo_url}}',
        );
      case 'barcode':
        return DocumentPrintShape(
          id: '$type-$index',
          type: 'barcode',
          x: 36,
          y: 36 + (index * 12),
          width: 180,
          height: 72,
          text: '{{document_number}}',
          fontSize: 11,
          barcodeType: 'code128',
          fillAlpha: 0.0,
        );
      case 'text':
      default:
        return DocumentPrintShape(
          id: '$type-$index',
          type: 'text',
          x: 36,
          y: 36 + (index * 12),
          width: 200,
          height: 28,
          text: 'Text {{document_number}}',
          fillAlpha: 0.0,
        );
    }
  }

  static List<DocumentPrintColumn> defaultTableColumns() {
    return const [
      DocumentPrintColumn(
        key: 'line_no',
        label: 'S.No',
        widthFactor: 0.9,
        align: 'center',
        titleAlign: 'center',
      ),
      DocumentPrintColumn(key: 'item_name', label: 'Item', widthFactor: 2.8),
      DocumentPrintColumn(
        key: 'hsn',
        label: 'HSN',
        widthFactor: 1.6,
        align: 'center',
        titleAlign: 'center',
      ),
      DocumentPrintColumn(
        key: 'description',
        label: 'Description',
        widthFactor: 2.2,
      ),
      DocumentPrintColumn(
        key: 'qty',
        label: 'Qty',
        widthFactor: 1.1,
        align: 'right',
      ),
      DocumentPrintColumn(
        key: 'rate',
        label: 'Rate',
        widthFactor: 1.2,
        align: 'right',
      ),
      DocumentPrintColumn(
        key: 'line_total',
        label: 'Amount',
        widthFactor: 1.3,
        align: 'right',
        totalColumn: true,
      ),
    ];
  }

  String get typeLabel {
    switch (type) {
      case 'rectangle':
        return 'Rectangle';
      case 'line':
        return 'Line';
      case 'ellipse':
        return 'Ellipse';
      case 'polygon':
        return 'Polygon';
      case 'table':
        return 'Table';
      case 'image':
        return 'Image';
      case 'barcode':
        return 'Barcode';
      default:
        return 'Text';
    }
  }

  bool get isSupported {
    return const {
      'text',
      'rectangle',
      'line',
      'ellipse',
      'polygon',
      'table',
      'image',
      'barcode',
    }.contains(type);
  }

  @override
  String toString() {
    if (type == 'text' && text.isNotEmpty) {
      return text.length > 20 ? '${text.substring(0, 20)}...' : text;
    }
    return '${type[0].toUpperCase()}${type.substring(1)}: $id';
  }

  DocumentPrintShape copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    String? text,
    String? align,
    double? fontSize,
    bool? bold,
    bool? italic,
    bool? underline,
    bool? multiline,
    int? strokeColor,
    int? bodyTextColor,
    int? fillColor,
    double? fillAlpha,
    double? strokeWidth,
    double? borderRadius,
    int? headerColor,
    int? headerTextColor,
    String? dataPath,
    double? rowHeight,
    double? titleHeight,
    double? cellGap,
    bool? printHeader,
    bool? printTotal,
    List<DocumentPrintColumn>? columns,
    String? assetPath,
    int? sides,
    String? barcodeType,
  }) {
    return DocumentPrintShape(
      id: id ?? this.id,
      type: type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      text: text ?? this.text,
      align: align ?? this.align,
      fontSize: fontSize ?? this.fontSize,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      multiline: multiline ?? this.multiline,
      strokeColor: strokeColor ?? this.strokeColor,
      bodyTextColor: bodyTextColor ?? this.bodyTextColor,
      fillColor: fillColor ?? this.fillColor,
      fillAlpha: fillAlpha ?? this.fillAlpha,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      headerColor: headerColor ?? this.headerColor,
      headerTextColor: headerTextColor ?? this.headerTextColor,
      dataPath: dataPath ?? this.dataPath,
      rowHeight: rowHeight ?? this.rowHeight,
      titleHeight: titleHeight ?? this.titleHeight,
      cellGap: cellGap ?? this.cellGap,
      printHeader: printHeader ?? this.printHeader,
      printTotal: printTotal ?? this.printTotal,
      columns: columns ?? this.columns,
      assetPath: assetPath ?? this.assetPath,
      sides: sides ?? this.sides,
      barcodeType: barcodeType ?? this.barcodeType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'text': text,
      'align': align,
      'fontSize': fontSize,
      'bold': bold,
      'italic': italic,
      'underline': underline,
      'multiline': multiline,
      'strokeColor': strokeColor,
      'bodyTextColor': bodyTextColor,
      'fillColor': fillColor,
      'fillAlpha': fillAlpha,
      'strokeWidth': strokeWidth,
      'borderRadius': borderRadius,
      'headerColor': headerColor,
      'headerTextColor': headerTextColor,
      'dataPath': dataPath,
      'rowHeight': rowHeight,
      'titleHeight': titleHeight,
      'cellGap': cellGap,
      'printHeader': printHeader,
      'printTotal': printTotal,
      'assetPath': assetPath,
      'sides': sides,
      'barcodeType': barcodeType,
      'columns': columns
          .map((column) => column.toJson())
          .toList(growable: false),
    };
  }
}

class DocumentPrintColumn {
  const DocumentPrintColumn({
    required this.key,
    required this.label,
    required this.widthFactor,
    this.align = 'left',
    this.titleAlign = 'center',
    this.totalColumn = false,
    this.numberFormat = 'default',
  });

  final String key;
  final String label;
  final double widthFactor;
  final String align;
  final String titleAlign;
  final bool totalColumn;
  final String numberFormat;

  factory DocumentPrintColumn.fromJson(Map<String, dynamic> json) {
    return DocumentPrintColumn(
      key: stringValue(json, 'key'),
      label: stringValue(json, 'label'),
      widthFactor: _toDouble(json['widthFactor'], 1),
      align: stringValue(json, 'align', 'left'),
      titleAlign: stringValue(json, 'titleAlign', 'center'),
      totalColumn: boolValue(json, 'totalColumn'),
      numberFormat: stringValue(json, 'numberFormat', 'default'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'widthFactor': widthFactor,
      'align': align,
      'titleAlign': titleAlign,
      'totalColumn': totalColumn,
      'numberFormat': numberFormat,
    };
  }

  DocumentPrintColumn copyWith({
    String? key,
    String? label,
    double? widthFactor,
    String? align,
    String? titleAlign,
    bool? totalColumn,
    String? numberFormat,
  }) {
    return DocumentPrintColumn(
      key: key ?? this.key,
      label: label ?? this.label,
      widthFactor: widthFactor ?? this.widthFactor,
      align: align ?? this.align,
      titleAlign: titleAlign ?? this.titleAlign,
      totalColumn: totalColumn ?? this.totalColumn,
      numberFormat: numberFormat ?? this.numberFormat,
    );
  }
}

double _toDouble(dynamic value, double fallback) {
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

int _toInt(dynamic value, int fallback) {
  if (value == null) {
    return fallback;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }

  final raw = value.toString().trim();
  if (raw.isEmpty) {
    return fallback;
  }

  if (raw.startsWith('0x') || raw.startsWith('0X')) {
    return int.tryParse(raw.substring(2), radix: 16) ?? fallback;
  }

  return int.tryParse(raw) ?? double.tryParse(raw)?.round() ?? fallback;
}

String _documentTitleForType(String documentType) {
  switch (documentType) {
    case 'sales_quotation':
      return 'Quotation';
    case 'sales_invoice':
      return 'Invoice';
    case 'sales_delivery':
      return 'Delivery';
    case 'purchase_invoice':
      return 'Purchase Invoice';
    case 'hr_payslip':
      return 'Payslip';
    default:
      return documentType
          .split('_')
          .where((part) => part.trim().isNotEmpty)
          .map(
            (part) =>
                '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
          )
          .join(' ');
  }
}
