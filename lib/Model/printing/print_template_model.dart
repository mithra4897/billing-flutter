import 'dart:math' as math;
import '../../screen.dart';

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

  factory DocumentPrintTemplate.defaults(
    String documentType, {
    String? title,
  }) {
    final resolvedTitle = (title ?? _documentTitleForType(documentType)).toUpperCase();
    
    if (documentType == 'sales_quotation') {
      return DocumentPrintTemplate(
        pageWidth: 595,
        pageHeight: 842,
        mediaPreset: 'A4',
        orientation: 'portrait',
        shapes: [
          const DocumentPrintShape(
            id: 'company-logo',
            type: 'image',
            x: 28,
            y: 26,
            width: 72,
            height: 72,
            strokeWidth: 0,
            assetPath: '{{company_logo_url}}',
          ),
          DocumentPrintShape(
            id: 'text-title',
            type: 'text',
            x: 112,
            y: 28,
            width: 250,
            height: 28,
            text: '{{company_name}}',
            fontSize: 18,
            bold: true,
          ),
          DocumentPrintShape(
            id: 'text-doc-type',
            type: 'text',
            x: 112,
            y: 56,
            width: 180,
            height: 16,
            text: resolvedTitle,
            fontSize: 10,
            strokeColor: 0xFF475569,
          ),
          DocumentPrintShape(
            id: 'meta-text',
            type: 'text',
            x: 408,
            y: 30,
            width: 154,
            height: 56,
            text: 'No: {{document_number}}\nDate: {{document_date}}\nRef: {{reference_number}}',
            fontSize: 10,
            multiline: true,
            align: 'right',
          ),
          const DocumentPrintShape(
            id: 'header-divider',
            type: 'line',
            x: 28,
            y: 108,
            width: 538,
            height: 0,
            strokeColor: 0xFF111827,
          ),
          DocumentPrintShape(
            id: 'party-text',
            type: 'text',
            x: 28,
            y: 122,
            width: 340,
            height: 56,
            text: 'Party: {{party_name}}\nAddress: {{party_address}}\nContact: {{party_contact}}',
            fontSize: 10,
            multiline: true,
          ),
          DocumentPrintShape(
            id: 'lines-table',
            type: 'table',
            x: 28,
            y: 196,
            width: 538,
            height: 470,
            dataPath: 'lines',
            rowHeight: 34,
            columns: DocumentPrintShape.defaultTableColumns(),
          ),
          DocumentPrintShape(
            id: 'notes-title',
            type: 'text',
            x: 28,
            y: 684,
            width: 100,
            height: 16,
            text: 'Notes',
            fontSize: 10,
            bold: true,
          ),
          DocumentPrintShape(
            id: 'notes-text',
            type: 'text',
            x: 28,
            y: 702,
            width: 320,
            height: 68,
            text: '{{notes}}',
            fontSize: 10,
            multiline: true,
          ),
          DocumentPrintShape(
            id: 'totals-text',
            type: 'text',
            x: 386,
            y: 690,
            width: 180,
            height: 66,
            text: 'Subtotal: {{subtotal}}\nTax: {{tax_amount}}\nTotal: {{total_amount}}',
            fontSize: 12,
            multiline: true,
            align: 'right',
            bold: true,
          ),
        ],
      );
    }

    return DocumentPrintTemplate(
      pageWidth: 595,
      pageHeight: 842,
      mediaPreset: 'A4',
      orientation: 'portrait',
      shapes: [
        const DocumentPrintShape(
          id: 'company-logo',
          type: 'image',
          x: 28,
          y: 28,
          width: 84,
          height: 84,
          strokeWidth: 0,
          assetPath: '{{company_logo_url}}',
        ),
        DocumentPrintShape(
          id: 'text-title',
          type: 'text',
          x: 126,
          y: 28,
          width: 220,
          height: 32,
          text: '{{company_name}}',
          fontSize: 20,
          bold: true,
        ),
        DocumentPrintShape(
          id: 'text-doc-type',
          type: 'text',
          x: 126,
          y: 60,
          width: 210,
          height: 18,
          text: resolvedTitle,
          fontSize: 11,
          strokeColor: 0xFF475569,
        ),
        DocumentPrintShape(
          id: 'meta-box',
          type: 'rectangle',
          x: 360,
          y: 28,
          width: 206,
          height: 88,
          strokeColor: 0xFFCBD5E1,
        ),
        DocumentPrintShape(
          id: 'meta-text',
          type: 'text',
          x: 376,
          y: 40,
          width: 170,
          height: 60,
          text: 'No: {{document_number}}\nDate: {{document_date}}\nRef: {{reference_number}}',
          fontSize: 11,
          multiline: true,
        ),
        DocumentPrintShape(
          id: 'party-box',
          type: 'rectangle',
          x: 28,
          y: 132,
          width: 538,
          height: 88,
          strokeColor: 0xFFCBD5E1,
        ),
        DocumentPrintShape(
          id: 'party-text',
          type: 'text',
          x: 40,
          y: 144,
          width: 514,
          height: 64,
          text: 'Party: {{party_name}}\nAddress: {{party_address}}\nContact: {{party_contact}}',
          fontSize: 11,
          multiline: true,
        ),
        DocumentPrintShape(
          id: 'lines-table',
          type: 'table',
          x: 28,
          y: 238,
          width: 538,
          height: 390,
          dataPath: 'lines',
          columns: DocumentPrintShape.defaultTableColumns(),
        ),
        DocumentPrintShape(
          id: 'notes-title',
          type: 'text',
          x: 28,
          y: 648,
          width: 100,
          height: 16,
          text: 'Notes',
          fontSize: 11,
          bold: true,
        ),
        DocumentPrintShape(
          id: 'notes-text',
          type: 'text',
          x: 28,
          y: 668,
          width: 300,
          height: 88,
          text: '{{notes}}',
          fontSize: 10,
          multiline: true,
        ),
        DocumentPrintShape(
          id: 'totals-box',
          type: 'rectangle',
          x: 350,
          y: 648,
          width: 216,
          height: 108,
          strokeColor: 0xFFCBD5E1,
        ),
        DocumentPrintShape(
          id: 'totals-text',
          type: 'text',
          x: 366,
          y: 662,
          width: 184,
          height: 80,
          text: 'Subtotal: {{subtotal}}\nTax: {{tax_amount}}\nTotal: {{total_amount}}',
          fontSize: 12,
          multiline: true,
          align: 'right',
          bold: true,
        ),
      ],
    );
  }

  DocumentPrintTemplate normalizedFor(String documentType) {
    if (documentType != 'sales_quotation') {
      return this;
    }

    final nextShapes = shapes
        .where((shape) => !const {'party-box', 'totals-box', 'meta-box'}.contains(shape.id))
        .map((shape) {
          switch (shape.id) {
            case 'company-logo':
              return shape.copyWith(x: 28, y: 26, width: 72, height: 72);
            case 'text-title':
              return shape.copyWith(x: 112, y: 28, width: 250, height: 28, fontSize: 18);
            case 'text-doc-type':
              return shape.copyWith(x: 112, y: 56, width: 180, height: 16, fontSize: 10);
            case 'meta-text':
              return shape.copyWith(x: 408, y: 30, width: 154, height: 56, fontSize: 10, align: 'right', multiline: true);
            case 'party-text':
              return shape.copyWith(x: 28, y: 122, width: 340, height: 56, fontSize: 10, multiline: true);
            case 'lines-table':
              return shape.copyWith(
                x: 28,
                y: 196,
                width: 538,
                height: 470,
                rowHeight: math.max(34, shape.rowHeight),
                columns: shape.columns.isEmpty ? DocumentPrintShape.defaultTableColumns() : shape.columns,
              );
            case 'notes-title':
              return shape.copyWith(x: 28, y: 684, width: 100, height: 16);
            case 'notes-text':
              return shape.copyWith(x: 28, y: 702, width: 320, height: 68, fontSize: 10);
            case 'totals-text':
              return shape.copyWith(x: 386, y: 690, width: 180, height: 66, fontSize: 12, align: 'right', multiline: true, bold: true);
            default:
              return shape;
          }
        })
        .toList(growable: false);

    final hasHeaderDivider = nextShapes.any((shape) => shape.id == 'header-divider');

    return copyWith(
      shapes: [
        ...nextShapes,
        if (!hasHeaderDivider)
          const DocumentPrintShape(
            id: 'header-divider',
            type: 'line',
            x: 28,
            y: 108,
            width: 538,
            height: 0,
            strokeColor: 0xFF111827,
          ),
      ],
    );
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
    String? backgroundImagePath,
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
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
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
    this.fillColor = 0xFFFFFFFF,
    this.fillAlpha = 0,
    this.strokeWidth = 1,
    this.borderRadius = 0,
    this.headerColor = 0xFFF1F5F9,
    this.headerTextColor = 0xFF111827,
    this.dataPath = 'lines',
    this.rowHeight = 30,
    this.columns = const <DocumentPrintColumn>[],
    this.assetPath = 'assets/sakthicontroller logo.jpg',
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
  final int fillColor;
  final double fillAlpha;
  final double strokeWidth;
  final double borderRadius;
  final int headerColor;
  final int headerTextColor;
  final String dataPath;
  final double rowHeight;
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
      fillColor: _toInt(json['fillColor'], 0xFFFFFFFF),
      fillAlpha: _toDouble(json['fillAlpha'], 0),
      strokeWidth: _toDouble(json['strokeWidth'], 1),
      borderRadius: _toDouble(json['borderRadius'], 0),
      headerColor: _toInt(json['headerColor'], 0xFFF1F5F9),
      headerTextColor: _toInt(json['headerTextColor'], 0xFF111827),
      dataPath: stringValue(json, 'dataPath', 'lines'),
      rowHeight: _toDouble(json['rowHeight'], 30),
      assetPath: stringValue(json, 'assetPath', 'assets/sakthicontroller logo.jpg'),
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
      case 'table':
        return DocumentPrintShape(
          id: '$type-$index',
          type: type,
          x: 36,
          y: 36 + (index * 12),
          width: 500,
          height: 240,
          strokeColor: 0xFF94A3B8,
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
      DocumentPrintColumn(key: 'item_name', label: 'Item', widthFactor: 3.2),
      DocumentPrintColumn(
        key: 'description',
        label: 'Description',
        widthFactor: 3,
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
        widthFactor: 1.5,
        align: 'right',
      ),
    ];
  }

  String get typeLabel {
    switch (type) {
      case 'rectangle':
        return 'Rectangle';
      case 'line':
        return 'Line';
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
    int? fillColor,
    double? fillAlpha,
    double? strokeWidth,
    double? borderRadius,
    int? headerColor,
    int? headerTextColor,
    String? dataPath,
    double? rowHeight,
    List<DocumentPrintColumn>? columns,
    String? assetPath,
    int? sides,
    String? barcodeType,
  }) {
    return DocumentPrintShape(
      id: id,
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
      fillColor: fillColor ?? this.fillColor,
      fillAlpha: fillAlpha ?? this.fillAlpha,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      headerColor: headerColor ?? this.headerColor,
      headerTextColor: headerTextColor ?? this.headerTextColor,
      dataPath: dataPath ?? this.dataPath,
      rowHeight: rowHeight ?? this.rowHeight,
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
      'fillColor': fillColor,
      'fillAlpha': fillAlpha,
      'strokeWidth': strokeWidth,
      'borderRadius': borderRadius,
      'headerColor': headerColor,
      'headerTextColor': headerTextColor,
      'dataPath': dataPath,
      'rowHeight': rowHeight,
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
  });

  final String key;
  final String label;
  final double widthFactor;
  final String align;

  factory DocumentPrintColumn.fromJson(Map<String, dynamic> json) {
    return DocumentPrintColumn(
      key: stringValue(json, 'key'),
      label: stringValue(json, 'label'),
      widthFactor: _toDouble(json['widthFactor'], 1),
      align: stringValue(json, 'align', 'left'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'widthFactor': widthFactor,
      'align': align,
    };
  }

  DocumentPrintColumn copyWith({
    String? key,
    String? label,
    double? widthFactor,
    String? align,
  }) {
    return DocumentPrintColumn(
      key: key ?? this.key,
      label: label ?? this.label,
      widthFactor: widthFactor ?? this.widthFactor,
      align: align ?? this.align,
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
    default:
      return documentType
          .split('_')
          .where((part) => part.trim().isNotEmpty)
          .map((part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
          .join(' ');
  }
}
