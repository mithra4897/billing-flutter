import '../../screen.dart';

const Object _documentPrintTemplateUnset = Object();

class DocumentPrintTemplate {
  const DocumentPrintTemplate({
    required this.pageWidth,
    required this.pageHeight,
    required this.shapes,
    this.fontFamily = defaultDocumentPrintFontFamily,
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
  final String fontFamily;
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
      fontFamily: normalizeDocumentPrintFontFamily(
        stringValue(json, 'fontFamily', defaultDocumentPrintFontFamily),
      ),
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

    if (_usesSalesPurchaseDefaultPrintTemplate(documentType)) {
      return _defaultDocumentPrintTemplate(resolvedTitle);
    }

    if (documentType == '__legacy_default_template__') {
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
                key: 'discount_label',
                label: 'Disc',
                widthFactor: 1.0,
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
                'Subtotal   : {{subtotal}}\nTax        : {{tax_amount}}\nRound Off  : {{round_off_amount}}\nAdjustment : {{adjustment_amount}}\nTotal      : \u20B9{{total_amount}}',
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
            text: '\u20B9{{total_amount}}',
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

    return _defaultDocumentPrintTemplate(resolvedTitle);
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
    String? fontFamily,
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
      fontFamily: normalizeDocumentPrintFontFamily(
        fontFamily ?? this.fontFamily,
      ),
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
      'fontFamily': fontFamily,
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

DocumentPrintTemplate _defaultDocumentPrintTemplate(String resolvedTitle) {
  final template = DocumentPrintTemplate.fromJson(
    jsonDecode(_defaultDocumentPrintTemplateJson) as Map<String, dynamic>,
  );
  return template.copyWith(
    shapes: template.shapes
        .map((shape) {
          switch (shape.id) {
            case 'text-doc-type':
              return shape.copyWith(text: resolvedTitle);
            case 'company-logo':
              return shape.copyWith(assetPath: '{{company_logo_url}}');
            default:
              return shape;
          }
        })
        .toList(growable: false),
  );
}

const String _defaultDocumentPrintTemplateJson = r'''{
  "pageWidth": 595,
  "pageHeight": 842,
  "fontFamily": "arial",
  "backgroundImagePath": null,
  "backgroundOpacity": 0.18,
  "mediaPreset": "A4",
  "orientation": "portrait",
  "gridSize": 8,
  "showGrid": false,
  "shapes": [
    {
      "id": "pbs-outer-border",
      "type": "rectangle",
      "x": 29,
      "y": 28,
      "width": 537,
      "height": 786,
      "text": "",
      "align": "left",
      "fontSize": 12,
      "bold": false,
      "italic": false,
      "underline": false,
      "multiline": false,
      "strokeColor": 4282156725,
      "bodyTextColor": 4282156725,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 0.5,
      "borderRadius": 8,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "text-doc-type",
      "type": "text",
      "x": 102.35546875,
      "y": 34.40234375,
      "width": 160,
      "height": 18,
      "text": "QUOTATION",
      "align": "center",
      "fontSize": 11,
      "bold": true,
      "italic": false,
      "underline": false,
      "multiline": false,
      "strokeColor": 4279310375,
      "bodyTextColor": 4279310375,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 1,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "gstin-label",
      "type": "text",
      "x": 377.140625,
      "y": 34.63671875,
      "width": 42,
      "height": 18,
      "text": "GSTIN :",
      "align": "left",
      "fontSize": 9,
      "bold": true,
      "italic": false,
      "underline": false,
      "multiline": false,
      "strokeColor": 4279310375,
      "bodyTextColor": 4281811281,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 1,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "gstin-value",
      "type": "text",
      "x": 410.30859375,
      "y": 35.109375,
      "width": 148,
      "height": 18,
      "text": "{{company_gstin}}",
      "align": "left",
      "fontSize": 9,
      "bold": true,
      "italic": false,
      "underline": false,
      "multiline": false,
      "strokeColor": 4279310375,
      "bodyTextColor": 4279310375,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 0.5,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "header-top-divider",
      "type": "line",
      "x": 29,
      "y": 54,
      "width": 537,
      "height": 0,
      "text": "",
      "align": "left",
      "fontSize": 12,
      "bold": false,
      "italic": false,
      "underline": false,
      "multiline": false,
      "strokeColor": 4289111718,
      "bodyTextColor": 4289111718,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 0.5,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "company-logo",
      "type": "image",
      "x": 35.31640625,
      "y": 63.86328125,
      "width": 68.8515625,
      "height": 65.453125,
      "text": "",
      "align": "left",
      "fontSize": 12,
      "bold": false,
      "italic": false,
      "underline": false,
      "multiline": false,
      "strokeColor": 4279310375,
      "bodyTextColor": 4279310375,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 0,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "http://bill.local:8000/api/v1/public/media/file?path=uploads%2Fprint-templates%2F2026%2F06%2F1169e278-a1e0-44ab-89b3-7699c7e4c08a.png",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "company-address",
      "type": "text",
      "x": 108.38671875,
      "y": 117.4921875,
      "width": 208.05859375,
      "height": 17.8125,
      "text": "Cell : 9443036233, 9597773302",
      "align": "left",
      "fontSize": 9,
      "bold": false,
      "italic": false,
      "underline": false,
      "multiline": true,
      "strokeColor": 4281811281,
      "bodyTextColor": 4281811281,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 1,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "header-vertical-divider",
      "type": "line",
      "x": 326.52734375,
      "y": 28,
      "width": 0,
      "height": 152,
      "text": "",
      "align": "left",
      "fontSize": 12,
      "bold": false,
      "italic": false,
      "underline": false,
      "multiline": false,
      "strokeColor": 4289111718,
      "bodyTextColor": 4289111718,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 0.5,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "customer-label",
      "type": "text",
      "x": 334,
      "y": 58,
      "width": 230,
      "height": 16,
      "text": "Customer",
      "align": "left",
      "fontSize": 9,
      "bold": true,
      "italic": false,
      "underline": false,
      "multiline": false,
      "strokeColor": 4281811281,
      "bodyTextColor": 4281811281,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 1,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "party-text",
      "type": "text",
      "x": 334,
      "y": 76,
      "width": 228,
      "height": 64,
      "text": "{{party_name}}\n{{party_address}}\nCell: {{party_contact}}",
      "align": "left",
      "fontSize": 9,
      "bold": false,
      "italic": false,
      "underline": false,
      "multiline": true,
      "strokeColor": 4279310375,
      "bodyTextColor": 4279310375,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 1,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "customer-gstn-label",
      "type": "text",
      "x": 334,
      "y": 145.21875,
      "width": 186.5859375,
      "height": 16.8125,
      "text": "Customer GSTN :{{party_gstin}}",
      "align": "left",
      "fontSize": 9,
      "bold": true,
      "italic": false,
      "underline": false,
      "multiline": true,
      "strokeColor": 4281811281,
      "bodyTextColor": 4281811281,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 1,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "header-divider",
      "type": "line",
      "x": 29,
      "y": 180,
      "width": 537,
      "height": 0,
      "text": "",
      "align": "left",
      "fontSize": 12,
      "bold": false,
      "italic": false,
      "underline": false,
      "multiline": false,
      "strokeColor": 4289111718,
      "bodyTextColor": 4289111718,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 0.5,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "doc-no-label",
      "type": "text",
      "x": 47.73828125,
      "y": 185.20703125,
      "width": 50,
      "height": 16,
      "text": "Doc No :",
      "align": "left",
      "fontSize": 9,
      "bold": false,
      "italic": false,
      "underline": false,
      "multiline": false,
      "strokeColor": 4281811281,
      "bodyTextColor": 4281811281,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 1,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "doc-no-value",
      "type": "text",
      "x": 89.390625,
      "y": 186.2109375,
      "width": 110,
      "height": 16,
      "text": "{{document_number}}",
      "align": "left",
      "fontSize": 9,
      "bold": true,
      "italic": false,
      "underline": false,
      "multiline": false,
      "strokeColor": 4279310375,
      "bodyTextColor": 4279310375,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 1,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "date-label",
      "type": "text",
      "x": 222,
      "y": 186.03125,
      "width": 35,
      "height": 16,
      "text": "Date :",
      "align": "left",
      "fontSize": 9,
      "bold": false,
      "italic": false,
      "underline": false,
      "multiline": false,
      "strokeColor": 4281811281,
      "bodyTextColor": 4281811281,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 1,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "date-value",
      "type": "text",
      "x": 251.26171875,
      "y": 186.4296875,
      "width": 78,
      "height": 16,
      "text": "{{document_date}}",
      "align": "left",
      "fontSize": 9,
      "bold": true,
      "italic": false,
      "underline": false,
      "multiline": false,
      "strokeColor": 4279310375,
      "bodyTextColor": 4279310375,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 1,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "ref-label",
      "type": "text",
      "x": 355.015625,
      "y": 185.5625,
      "width": 37,
      "height": 17,
      "text": "Ref No :",
      "align": "left",
      "fontSize": 9,
      "bold": false,
      "italic": false,
      "underline": false,
      "multiline": true,
      "strokeColor": 4281811281,
      "bodyTextColor": 4281811281,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 1,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "ref-value",
      "type": "text",
      "x": 395.3828125,
      "y": 185.33984375,
      "width": 75.3359375,
      "height": 17,
      "text": "{{reference_number}}",
      "align": "left",
      "fontSize": 9,
      "bold": false,
      "italic": false,
      "underline": false,
      "multiline": false,
      "strokeColor": 4279310375,
      "bodyTextColor": 4279310375,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 1,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "lines-table",
      "type": "table",
      "x": 29,
      "y": 204,
      "width": 537,
      "height": 366,
      "text": "",
      "align": "left",
      "fontSize": 12,
      "bold": false,
      "italic": false,
      "underline": false,
      "multiline": false,
      "strokeColor": 4282156725,
      "bodyTextColor": 4279310375,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 1,
      "borderRadius": 0,
      "headerColor": 4289581296,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 26,
      "titleHeight": 22,
      "cellGap": 4,
      "printHeader": true,
      "printTotal": true,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": [
        {
          "key": "line_no",
          "align": "center",
          "label": "S.No",
          "titleAlign": "center",
          "totalColumn": false,
          "widthFactor": 0.9,
          "numberFormat": "default"
        },
        {
          "key": "item_name",
          "align": "left",
          "label": "Item",
          "titleAlign": "center",
          "totalColumn": false,
          "widthFactor": 4.5,
          "numberFormat": "default"
        },
        {
          "key": "hsn",
          "align": "center",
          "label": "HSN",
          "titleAlign": "center",
          "totalColumn": false,
          "widthFactor": 1.6,
          "numberFormat": "default"
        },
        {
          "key": "qty",
          "align": "center",
          "label": "Qty",
          "titleAlign": "center",
          "totalColumn": false,
          "widthFactor": 1,
          "numberFormat": "default"
        },
        {
          "key": "rate",
          "align": "right",
          "label": "Price",
          "titleAlign": "center",
          "totalColumn": false,
          "widthFactor": 1.5,
          "numberFormat": "default"
        },
        {
          "key": "tax_amount",
          "align": "right",
          "label": "Tax",
          "titleAlign": "center",
          "totalColumn": true,
          "widthFactor": 1.5,
          "numberFormat": "default"
        },
        {
          "key": "line_total",
          "align": "center",
          "label": "Amount",
          "titleAlign": "right",
          "totalColumn": true,
          "widthFactor": 1.5,
          "numberFormat": "default"
        }
      ]
    },
    {
      "id": "amount-words-label",
      "type": "text",
      "x": 33.859375,
      "y": 577.37890625,
      "width": 89,
      "height": 14,
      "text": "Amount in Words:",
      "align": "left",
      "fontSize": 9,
      "bold": false,
      "italic": false,
      "underline": false,
      "multiline": false,
      "strokeColor": 4281811281,
      "bodyTextColor": 4281811281,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 1,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "amount-words-value",
      "type": "text",
      "x": 109.953125,
      "y": 578.08984375,
      "width": 240,
      "height": 28,
      "text": "{{amount_in_words}}",
      "align": "left",
      "fontSize": 9,
      "bold": false,
      "italic": true,
      "underline": false,
      "multiline": true,
      "strokeColor": 4279310375,
      "bodyTextColor": 4279310375,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 1,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "gst-breakup-table",
      "type": "table",
      "x": 35.20703125,
      "y": 614.80078125,
      "width": 318,
      "height": 45,
      "text": "",
      "align": "left",
      "fontSize": 12,
      "bold": false,
      "italic": false,
      "underline": false,
      "multiline": false,
      "strokeColor": 4282156725,
      "bodyTextColor": 4279310375,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 1,
      "borderRadius": 0,
      "headerColor": 4289581296,
      "headerTextColor": 4279310375,
      "dataPath": "gst_breakup",
      "rowHeight": 18,
      "titleHeight": 18,
      "cellGap": 3,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": [
        {
          "key": "tax_name",
          "align": "center",
          "label": "Tax",
          "titleAlign": "center",
          "totalColumn": false,
          "widthFactor": 2.5,
          "numberFormat": "default"
        },
        {
          "key": "taxable",
          "align": "center",
          "label": "Taxable Val",
          "titleAlign": "center",
          "totalColumn": false,
          "widthFactor": 2.5,
          "numberFormat": "default"
        },
        {
          "key": "cgst",
          "align": "center",
          "label": "CGST",
          "titleAlign": "center",
          "totalColumn": false,
          "widthFactor": 2,
          "numberFormat": "default"
        },
        {
          "key": "sgst",
          "align": "center",
          "label": "SGST",
          "titleAlign": "center",
          "totalColumn": false,
          "widthFactor": 2,
          "numberFormat": "default"
        }
      ]
    },
    {
      "id": "total-amount-label",
      "type": "text",
      "x": 381.58203125,
      "y": 630.51953125,
      "width": 92.375,
      "height": 16,
      "text": "Total Amount :",
      "align": "left",
      "fontSize": 14,
      "bold": false,
      "italic": false,
      "underline": false,
      "multiline": true,
      "strokeColor": 4281811281,
      "bodyTextColor": 4281811281,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 1,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "total-amount-value",
      "type": "text",
      "x": 437.6796875,
      "y": 631.171875,
      "width": 111.73828125,
      "height": 16,
      "text": "\u20B9{{total_amount}}",
      "align": "right",
      "fontSize": 15,
      "bold": true,
      "italic": false,
      "underline": false,
      "multiline": true,
      "strokeColor": 4279310375,
      "bodyTextColor": 4279310375,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 1,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "terms-title",
      "type": "text",
      "x": 33.78125,
      "y": 673.26171875,
      "width": 130,
      "height": 14,
      "text": "Terms and Condition",
      "align": "left",
      "fontSize": 9,
      "bold": true,
      "italic": false,
      "underline": false,
      "multiline": false,
      "strokeColor": 4281811281,
      "bodyTextColor": 4281811281,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 1,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "terms-text",
      "type": "text",
      "x": 33.8515625,
      "y": 691.41015625,
      "width": 320,
      "height": 38,
      "text": "{{terms_conditions}}",
      "align": "left",
      "fontSize": 9,
      "bold": false,
      "italic": false,
      "underline": false,
      "multiline": true,
      "strokeColor": 4281811281,
      "bodyTextColor": 4281811281,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 1,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "banking-label",
      "type": "text",
      "x": 33.8203125,
      "y": 758.421875,
      "width": 140,
      "height": 14,
      "text": "Our Banking Details",
      "align": "left",
      "fontSize": 9,
      "bold": true,
      "italic": false,
      "underline": false,
      "multiline": true,
      "strokeColor": 4281811281,
      "bodyTextColor": 4281811281,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 1,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "auth-signatory",
      "type": "text",
      "x": 352.97265625,
      "y": 785.78515625,
      "width": 198,
      "height": 14,
      "text": "Authorised Signatory",
      "align": "right",
      "fontSize": 9,
      "bold": false,
      "italic": false,
      "underline": false,
      "multiline": false,
      "strokeColor": 4281811281,
      "bodyTextColor": 4281811281,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 1,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "text-29",
      "type": "text",
      "x": 108.38671875,
      "y": 70.61328125,
      "width": 219.93359375,
      "height": 23.19140625,
      "text": "Sakthi Controller ",
      "align": "left",
      "fontSize": 15,
      "bold": true,
      "italic": false,
      "underline": false,
      "multiline": true,
      "strokeColor": 4279310375,
      "bodyTextColor": 4279310375,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 1,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "text-30",
      "type": "text",
      "x": 108.38671875,
      "y": 95.61328125,
      "width": 197.296875,
      "height": 35.03515625,
      "text": "153, Karunai Nagar, K. Sevoor Katpadi Taluk, Tamil Nadu 632106",
      "align": "left",
      "fontSize": 10,
      "bold": false,
      "italic": false,
      "underline": false,
      "multiline": true,
      "strokeColor": 4279310375,
      "bodyTextColor": 4279310375,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 1,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    },
    {
      "id": "text-31",
      "type": "text",
      "x": 33.78125,
      "y": 772.5078125,
      "width": 200,
      "height": 33,
      "text": "A/C No: 000041004790019\nIFSC: DEUT0401PBC\nBank Name/Branch: Deutsche Bank - vellore",
      "align": "left",
      "fontSize": 9,
      "bold": false,
      "italic": false,
      "underline": false,
      "multiline": true,
      "strokeColor": 4279310375,
      "bodyTextColor": 4279310375,
      "fillColor": 4294967295,
      "fillAlpha": 0,
      "strokeWidth": 1,
      "borderRadius": 0,
      "headerColor": 4294047225,
      "headerTextColor": 4279310375,
      "dataPath": "lines",
      "rowHeight": 30,
      "titleHeight": 30,
      "cellGap": 6,
      "printHeader": true,
      "printTotal": false,
      "assetPath": "{{company_logo_url}}",
      "sides": 5,
      "barcodeType": "code128",
      "columns": []
    }
  ]
}''';

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
    this.fontFamily = defaultDocumentPrintShapeFontFamily,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.multiline = false,
    this.visible = true,
    this.letterSpacing = 0,
    this.lineHeight = 1.2,
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
    this.imageFit = 'contain',
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
  final String fontFamily;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool multiline;
  final bool visible;
  final double letterSpacing;
  final double lineHeight;
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
  final String imageFit;
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
      fontFamily: normalizeDocumentPrintShapeFontFamily(
        stringValue(
          json,
          'fontFamily',
          defaultDocumentPrintShapeFontFamily,
        ),
      ),
      bold: boolValue(json, 'bold'),
      italic: boolValue(json, 'italic'),
      underline: boolValue(json, 'underline'),
      multiline: boolValue(json, 'multiline'),
      visible: json.containsKey('visible') ? boolValue(json, 'visible') : true,
      letterSpacing: _toDouble(json['letterSpacing'], 0),
      lineHeight: _toDouble(json['lineHeight'], 1.2),
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
      imageFit: normalizeDocumentPrintImageFit(
        stringValue(json, 'imageFit', 'contain'),
      ),
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
        widthFactor: 1.0,
        align: 'right',
      ),
      DocumentPrintColumn(
        key: 'discount_label',
        label: 'Disc %',
        widthFactor: 1.0,
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
    String? fontFamily,
    bool? bold,
    bool? italic,
    bool? underline,
    bool? multiline,
    bool? visible,
    double? letterSpacing,
    double? lineHeight,
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
    String? imageFit,
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
      fontFamily: normalizeDocumentPrintShapeFontFamily(
        fontFamily ?? this.fontFamily,
      ),
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      multiline: multiline ?? this.multiline,
      visible: visible ?? this.visible,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      lineHeight: lineHeight ?? this.lineHeight,
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
      imageFit: normalizeDocumentPrintImageFit(imageFit ?? this.imageFit),
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
      'fontFamily': fontFamily,
      'bold': bold,
      'italic': italic,
      'underline': underline,
      'multiline': multiline,
      'visible': visible,
      'letterSpacing': letterSpacing,
      'lineHeight': lineHeight,
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
      'imageFit': imageFit,
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
    this.includeGst = true,
    this.numberFormat = 'default',
  });

  final String key;
  final String label;
  final double widthFactor;
  final String align;
  final String titleAlign;
  final bool totalColumn;
  final bool includeGst;
  final String numberFormat;

  factory DocumentPrintColumn.fromJson(Map<String, dynamic> json) {
    return DocumentPrintColumn(
      key: stringValue(json, 'key'),
      label: stringValue(json, 'label'),
      widthFactor: _toDouble(json['widthFactor'], 1),
      align: stringValue(json, 'align', 'left'),
      titleAlign: stringValue(json, 'titleAlign', 'center'),
      totalColumn: boolValue(json, 'totalColumn'),
      includeGst: json.containsKey('includeGst')
          ? boolValue(json, 'includeGst', fallback: true)
          : true,
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
      'includeGst': includeGst,
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
    bool? includeGst,
    String? numberFormat,
  }) {
    return DocumentPrintColumn(
      key: key ?? this.key,
      label: label ?? this.label,
      widthFactor: widthFactor ?? this.widthFactor,
      align: align ?? this.align,
      titleAlign: titleAlign ?? this.titleAlign,
      totalColumn: totalColumn ?? this.totalColumn,
      includeGst: includeGst ?? this.includeGst,
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
    case 'sales_order':
      return 'Sales Order';
    case 'sales_invoice':
      return 'Invoice';
    case 'sales_delivery':
      return 'Delivery';
    case 'sales_receipt':
      return 'Receipt';
    case 'sales_return':
      return 'Sales Return';
    case 'purchase_order':
      return 'Purchase Order';
    case 'purchase_invoice':
      return 'Purchase Invoice';
    case 'purchase_receipt':
      return 'Purchase Receipt';
    case 'purchase_return':
      return 'Purchase Return';
    case 'purchase_requisition':
      return 'Purchase Requisition';
    case 'purchase_payment':
      return 'Purchase Payment';
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

bool _usesSalesPurchaseDefaultPrintTemplate(String documentType) {
  return documentType.startsWith('sales_') ||
      documentType.startsWith('purchase_');
}
