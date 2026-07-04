import 'dart:math' as math;

import '../../screen.dart';

const String defaultPrintLogoAsset = 'assets/sakthi-logo.jpg';
const String legacyPbsLogoAsset = 'assets/pbs_logo.png';
const String defaultDocumentPrintFontFamily = 'default';
const String documentPrintSansAssetFamily = 'PrintSans';
const String documentPrintSerifAssetFamily = 'PrintSerif';
const String documentPrintMonoAssetFamily = 'PrintMono';
const String documentPrintVerdanaAssetFamily = 'PrintVerdana';
const String documentPrintTrebuchetAssetFamily = 'PrintTrebuchet';
const String documentPrintGeorgiaAssetFamily = 'PrintGeorgia';
const String defaultDocumentPrintShapeFontFamily = 'inherit';

const List<String> documentPrintFontFamilyOptions = <String>[
  'default',
  'arial',
  'verdana',
  'trebuchet_ms',
  'georgia',
  'times_new_roman',
];

const List<String> documentPrintShapeFontFamilyOptions = <String>[
  defaultDocumentPrintShapeFontFamily,
  ...documentPrintFontFamilyOptions,
];

const List<String> documentPrintImageFitOptions = <String>[
  'contain',
  'cover',
  'fill',
];

String normalizeDocumentPrintFontFamily(String? value) {
  switch ((value ?? defaultDocumentPrintFontFamily).trim().toLowerCase()) {
    case '':
    case 'default':
      return defaultDocumentPrintFontFamily;
    case 'sans':
    case 'arial':
      return 'arial';
    case 'serif':
    case 'times':
    case 'times_new_roman':
      return 'times_new_roman';
    case 'monospace':
    case 'courier':
    case 'courier_new':
      return 'arial';
    case 'verdana':
      return 'verdana';
    case 'trebuchet':
    case 'trebuchet_ms':
      return 'trebuchet_ms';
    case 'georgia':
      return 'georgia';
    default:
      return 'arial';
  }
}

String documentPrintFontFamilyLabel(String value) {
  switch (normalizeDocumentPrintFontFamily(value)) {
    case 'default':
      return 'Default';
    case 'verdana':
      return 'Verdana';
    case 'trebuchet_ms':
      return 'Trebuchet MS';
    case 'georgia':
      return 'Georgia';
    case 'times_new_roman':
      return 'Times New Roman';
    case 'arial':
    default:
      return 'Arial';
  }
}

String normalizeDocumentPrintShapeFontFamily(String? value) {
  final normalized = (value ?? defaultDocumentPrintShapeFontFamily)
      .trim()
      .toLowerCase();
  if (normalized.isEmpty || normalized == 'inherit' || normalized == 'global') {
    return defaultDocumentPrintShapeFontFamily;
  }
  return normalizeDocumentPrintFontFamily(normalized);
}

String documentPrintShapeFontFamilyLabel(String value) {
  final normalized = normalizeDocumentPrintShapeFontFamily(value);
  if (normalized == defaultDocumentPrintShapeFontFamily) {
    return 'Use Global';
  }
  return documentPrintFontFamilyLabel(normalized);
}

String effectiveDocumentPrintFontFamily(
  String? templateFontFamily,
  String? shapeFontFamily,
) {
  final normalizedShape = normalizeDocumentPrintShapeFontFamily(
    shapeFontFamily,
  );
  if (normalizedShape == defaultDocumentPrintShapeFontFamily) {
    return normalizeDocumentPrintFontFamily(templateFontFamily);
  }
  return normalizedShape;
}

String? flutterDocumentPrintFontFamily(String? value) {
  switch (normalizeDocumentPrintFontFamily(value)) {
    case 'default':
      return null;
    case 'verdana':
      return documentPrintVerdanaAssetFamily;
    case 'trebuchet_ms':
      return documentPrintTrebuchetAssetFamily;
    case 'georgia':
      return documentPrintGeorgiaAssetFamily;
    case 'times_new_roman':
      return documentPrintSerifAssetFamily;
    case 'arial':
    default:
      return documentPrintSansAssetFamily;
  }
}

TextStyle applyDocumentPrintFontStyle(TextStyle style, String? value) {
  return style.copyWith(fontFamily: flutterDocumentPrintFontFamily(value));
}

String normalizeDocumentPrintImageFit(String? value) {
  switch ((value ?? 'contain').trim().toLowerCase()) {
    case 'cover':
      return 'cover';
    case 'fill':
      return 'fill';
    case 'contain':
    default:
      return 'contain';
  }
}

String documentPrintImageFitLabel(String value) {
  switch (normalizeDocumentPrintImageFit(value)) {
    case 'cover':
      return 'Cover';
    case 'fill':
      return 'Stretch';
    case 'contain':
    default:
      return 'Contain';
  }
}

BoxFit flutterDocumentPrintImageFit(String? value) {
  switch (normalizeDocumentPrintImageFit(value)) {
    case 'cover':
      return BoxFit.cover;
    case 'fill':
      return BoxFit.fill;
    case 'contain':
    default:
      return BoxFit.contain;
  }
}

DocumentPrintDataModel buildManagedDocumentPrintData({
  required List<CompanyModel> companies,
  required int? companyId,
  required CompanyModel? company,
  required String documentNumber,
  required String documentDate,
  String referenceNumber = '',
  required String partyName,
  String partyAddress = '',
  String partyContact = '',
  String partyGstin = '',
  String notes = '',
  String termsConditions = '',
  required double subtotal,
  required double taxAmount,
  required double totalAmount,
  required String currencyCode,
  required List<DocumentPrintLineModel> lines,
  List<DocumentPrintTaxBreakupRowModel> gstBreakup =
      const <DocumentPrintTaxBreakupRowModel>[],
  Map<String, dynamic> extraData = const <String, dynamic>{},
}) {
  return DocumentPrintDataModel(
    companyName: companyNameById(companies, companyId),
    companyLogoUrl: AppConfig.resolvePublicFileUrl(company?.logoPath) ?? '',
    companyGstin: company?.gstin ?? '',
    documentNumber: documentNumber,
    documentDate: documentDate,
    referenceNumber: referenceNumber,
    partyName: partyName,
    partyAddress: partyAddress,
    partyContact: partyContact,
    partyGstin: partyGstin,
    notes: notes,
    termsConditions: termsConditions,
    subtotal: subtotal,
    taxAmount: taxAmount,
    totalAmount: totalAmount,
    amountInWords: printTemplateAmountInWords(totalAmount, currencyCode),
    lines: lines,
    gstBreakup: gstBreakup,
    extraData: extraData,
  );
}

Future<void> openManagedDocumentPrintPreview(
  BuildContext context, {
  Future<void> Function()? prepare,
  required String documentType,
  required String title,
  required DocumentPrintDataModel Function() documentDataBuilder,
  bool allowPrint = true,
  bool allowDownload = true,
  bool allowTemplateEditing = true,
}) async {
  await prepare?.call();
  if (!context.mounted) {
    return;
  }
  final documentData = documentDataBuilder();
  await openDocumentPrintDesigner(
    context,
    documentType: documentType,
    title: title,
    documentData: documentData,
    allowPrint: allowPrint,
    allowDownload: allowDownload,
    allowTemplateEditing: allowTemplateEditing,
  );
}

DocumentPrintTemplate applyPrintPagePreset(
  DocumentPrintTemplate template, {
  String? mediaPreset,
  String? orientation,
}) {
  final nextPreset = mediaPreset ?? template.mediaPreset;
  final nextOrientation = orientation ?? template.orientation;
  if (nextPreset == 'CUSTOM') {
    return template.copyWith(
      mediaPreset: nextPreset,
      orientation: nextOrientation,
    );
  }
  final size = switch (nextPreset) {
    'A5' => const Size(420, 595),
    'LETTER' => const Size(612, 792),
    _ => const Size(595, 842),
  };
  final width = nextOrientation == 'landscape' ? size.height : size.width;
  final height = nextOrientation == 'landscape' ? size.width : size.height;
  return template.copyWith(
    mediaPreset: nextPreset,
    orientation: nextOrientation,
    pageWidth: width,
    pageHeight: height,
  );
}

Object? resolvePrintPath(Map<String, dynamic> data, String path) {
  if (path.trim().isEmpty) {
    return null;
  }
  Object? current = data;
  for (final segment in path.split('.')) {
    if (current is Map<String, dynamic>) {
      current = current[segment];
    } else {
      return null;
    }
  }
  return current;
}

String resolvePrintTemplateText(String input, Map<String, dynamic> data) {
  final hasPlaceholders = input.contains('{{');
  var resolved = input.replaceAllMapped(RegExp(r'\{\{([^}]+)\}\}'), (match) {
    final key = match.group(1)?.trim() ?? '';
    final value = resolvePrintPath(data, key);
    if (value == null) {
      return '';
    }
    if (value is num) {
      return formatPrintValueForKey(key, value.toDouble());
    }
    return value.toString();
  });

  // Dynamically replace hardcoded legacy company names with the selected company's name
  final companyName = data['company_name']?.toString() ?? '';
  if (companyName.isNotEmpty) {
    resolved = resolved.replaceAll(
      'Sakthi Controller OPC Pvt Ltd',
      companyName,
    );
    resolved = resolved.replaceAll(
      'Sakthi Controller OPC Pvt. Ltd.',
      companyName,
    );
    resolved = resolved.replaceAll('Sakthi Controller', companyName);
  }
  if (hasPlaceholders && resolved.contains('\n')) {
    resolved = resolved
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => line.trim().isNotEmpty)
        .join('\n');
  }
  return resolved;
}

String resolvePrintCellValue(Map<String, dynamic> row, String key) {
  return resolvePrintCellValueForColumn(row, null, key);
}

String resolvePrintCellValueForColumn(
  Map<String, dynamic> row,
  DocumentPrintColumn? column,
  String key,
) {
  final value = resolvePrintPath(row, key);
  if (value == null) {
    return '';
  }
  if (value is num) {
    if (_shouldHideZeroPrintValue(key, value.toDouble())) {
      return '';
    }
    return formatPrintValueForKey(
      key,
      value.toDouble(),
      columnNumberFormat: column?.numberFormat,
    );
  }
  return value.toString();
}

String formatPrintValueForKey(
  String key,
  double value, {
  String? columnNumberFormat,
}) {
  final normalizedFormat = (columnNumberFormat ?? 'default')
      .trim()
      .toLowerCase();
  if (normalizedFormat == 'auto') {
    return formatPrintAmount(value);
  }
  if (normalizedFormat == 'fixed_2') {
    return _formatPrintAmount(value, fixedDecimals: 2);
  }
  return _isPrintAmountLikeKey(key)
      ? _formatPrintAmount(value, fixedDecimals: 2)
      : formatPrintAmount(value);
}

String formatPrintAmount(double value) {
  return _formatPrintAmount(value);
}

String _formatPrintAmount(double value, {int? fixedDecimals}) {
  final decimals =
      fixedDecimals ??
      (Get.isRegistered<AppFormatSettings>()
          ? AppFormatSettings.to.decimalPlaces.value
          : null);
  final raw = fixedDecimals != null
      ? value.toStringAsFixed(fixedDecimals)
      : value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(decimals ?? 2);
  final negative = raw.startsWith('-');
  final unsigned = negative ? raw.substring(1) : raw;
  final parts = unsigned.split('.');
  final whole = parts.first;
  final decimal = parts.length > 1 ? '.${parts.last}' : '';
  return '${negative ? '-' : ''}${_groupIndianDigits(whole)}$decimal';
}

bool _isPrintAmountLikeKey(String key) {
  const amountKeys = <String>{
    'rate',
    'tax_amount',
    'line_total',
    'subtotal',
    'taxable',
    'total_amount',
    'total_tax',
    'cgst',
    'sgst',
    'igst',
    'cess',
    'discount_amount',
    'gross_amount',
    'taxable_amount',
    'cgst_amount',
    'sgst_amount',
    'igst_amount',
    'cess_amount',
    'round_off_amount',
    'adjustment_amount',
  };
  return amountKeys.contains(key.trim().toLowerCase());
}

bool _shouldHideZeroPrintValue(String key, double value) {
  const hideZeroKeys = <String>{'cgst', 'sgst', 'igst', 'cess'};
  return hideZeroKeys.contains(key.trim().toLowerCase()) && value.abs() < 0.005;
}

String _groupIndianDigits(String digits) {
  if (digits.length <= 3) {
    return digits;
  }

  final lastThree = digits.substring(digits.length - 3);
  var remaining = digits.substring(0, digits.length - 3);
  final groups = <String>[];

  while (remaining.length > 2) {
    groups.insert(0, remaining.substring(remaining.length - 2));
    remaining = remaining.substring(0, remaining.length - 2);
  }
  if (remaining.isNotEmpty) {
    groups.insert(0, remaining);
  }

  return '${groups.join(',')},$lastThree';
}

bool printTableRowHasVisibleValues(
  Map<String, dynamic> row,
  List<DocumentPrintColumn> columns,
) {
  return columns.any(
    (column) => resolvePrintCellValueForColumn(
      row,
      column,
      column.key,
    ).trim().isNotEmpty,
  );
}

double measurePrintTableRowHeight(
  Map<String, dynamic> row,
  List<DocumentPrintColumn> columns,
  double tableWidth,
  DocumentPrintShape shape, {
  double scale = 1.0,
  String? fontFamily,
}) {
  final totalWeight = columns.fold<double>(
    0,
    (sum, column) => sum + column.widthFactor,
  );
  final minHeight = math.max(8.0, shape.rowHeight * scale);
  var maxHeight = minHeight;
  for (final column in columns) {
    final weight = totalWeight > 0 ? column.widthFactor / totalWeight : 0.0;
    final columnWidth = tableWidth * weight;
    final text = resolvePrintCellValueForColumn(row, column, column.key);
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: applyDocumentPrintFontStyle(
          TextStyle(
            fontSize: math.max(6, shape.fontSize) * scale,
            color: Color(shape.strokeColor),
            letterSpacing: shape.letterSpacing * scale,
            height: shape.lineHeight,
          ),
          fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: math.max(0.0, columnWidth - 12));
    maxHeight = math.max(maxHeight, painter.height + 12);
  }
  return maxHeight;
}

double measurePrintTableHeight({
  required DocumentPrintShape shape,
  required Iterable<dynamic> rows,
  required List<DocumentPrintColumn> columns,
  double scale = 1.0,
  String? fontFamily,
}) {
  final headerHeight = shape.printHeader
      ? math.max(8.0, shape.titleHeight * scale)
      : 0.0;
  final tableWidth = shape.width * scale;

  var bodyHeight = 0.0;
  for (final entry in rows) {
    final row = entry is JsonModel
        ? entry.toJson()
        : entry is Map<String, dynamic>
        ? entry
        : null;
    if (row == null) {
      continue;
    }
    if (!printTableRowHasVisibleValues(row, columns)) {
      continue;
    }
    bodyHeight += measurePrintTableRowHeight(
      row,
      columns,
      tableWidth,
      shape,
      scale: scale,
      fontFamily: fontFamily,
    );
  }

  if (shape.printTotal) {
    bodyHeight += headerHeight;
  }

  return headerHeight + bodyHeight + 2;
}

bool isPrintLinesTableShape(DocumentPrintShape shape) {
  if (shape.type != 'table') {
    return false;
  }
  if (shape.id == 'lines-table') {
    return true;
  }
  return shape.dataPath.trim() == 'lines';
}

bool isPrintGstBreakupTableShape(DocumentPrintShape shape) {
  if (shape.type != 'table') {
    return false;
  }
  if (shape.id == 'gst-breakup-table' ||
      shape.dataPath.trim() == 'gst_breakup') {
    return true;
  }
  final keys = shape.columns
      .map((column) => column.key.trim().toLowerCase())
      .toSet();
  return keys.contains('tax_name') &&
      keys.contains('taxable') &&
      keys.contains('cgst') &&
      keys.contains('sgst') &&
      keys.contains('igst');
}

const List<DocumentPrintColumn> defaultGstBreakupTableColumns =
    <DocumentPrintColumn>[
      DocumentPrintColumn(key: 'tax_name', label: 'Tax', widthFactor: 2.5),
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
    ];

String? resolvePrintImageSource(String? source) {
  if (source == null || source.trim().isEmpty) {
    return null;
  }
  source = normalizePortablePrintImageSource(source);
  source = normalizeLegacyPrintImageSource(source);
  if (source.startsWith('assets/')) {
    return source;
  }
  if (source.startsWith('http://') || source.startsWith('https://')) {
    return source;
  }
  return AppConfig.resolvePublicFileUrl(source) ?? source;
}

String normalizePortablePrintImageSource(String source) {
  final trimmed = source.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri == null) {
    return trimmed;
  }
  final path = uri.path;
  if (!path.endsWith('/public/media/file')) {
    return trimmed;
  }
  final filePath = uri.queryParameters['path'];
  if (filePath == null || filePath.trim().isEmpty) {
    return trimmed;
  }
  return filePath.trim();
}

String normalizeLegacyPrintImageSource(String source) {
  final trimmed = source.trim();
  if (trimmed == legacyPbsLogoAsset) {
    return defaultPrintLogoAsset;
  }
  return trimmed;
}

List<String> availablePrintBindings(
  Map<String, dynamic> data, [
  String prefix = '',
]) {
  final keys = <String>[];
  data.forEach((key, value) {
    if (value is Map<String, dynamic>) {
      keys.addAll(
        availablePrintBindings(value, prefix.isEmpty ? key : '$prefix.$key'),
      );
    } else if (value is! List) {
      keys.add(prefix.isEmpty ? key : '$prefix.$key');
    }
  });
  return keys;
}

List<String> availablePrintListBindings(
  Map<String, dynamic> data, [
  String prefix = '',
]) {
  final keys = <String>[];
  data.forEach((key, value) {
    final path = prefix.isEmpty ? key : '$prefix.$key';
    if (value is List) {
      keys.add(path);
      if (value.isNotEmpty && value.first is Map<String, dynamic>) {
        keys.addAll(
          availablePrintListBindings(
            Map<String, dynamic>.from(value.first as Map<String, dynamic>),
            path,
          ),
        );
      }
    } else if (value is Map<String, dynamic>) {
      keys.addAll(availablePrintListBindings(value, path));
    }
  });
  return keys;
}

List<String> availablePrintRowKeysForPath(
  Map<String, dynamic> data,
  String path,
) {
  final rows = resolvePrintPath(data, path);
  if (rows is! List || rows.isEmpty) {
    return const <String>[];
  }
  final firstRow = rows.first;
  if (firstRow is! Map<String, dynamic>) {
    return const <String>[];
  }
  return flattenPrintRowKeys(firstRow);
}

List<String> flattenPrintRowKeys(
  Map<String, dynamic> row, [
  String prefix = '',
]) {
  final keys = <String>[];
  row.forEach((key, value) {
    final path = prefix.isEmpty ? key : '$prefix.$key';
    if (value is Map<String, dynamic>) {
      keys.addAll(flattenPrintRowKeys(value, path));
    } else if (value is! List) {
      keys.add(path);
    }
  });
  return keys;
}

String printColumnLabelFromKey(String key) {
  return key
      .split('.')
      .last
      .split('_')
      .where((part) => part.trim().isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
