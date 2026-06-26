import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../screen.dart';
import '../../core/files/pdf_web_actions.dart';

Future<void> openDocumentPrintDesigner(
  BuildContext context, {
  required String documentType,
  required String title,
  required DocumentPrintDataModel documentData,
  bool allowPrint = true,
  bool allowDownload = true,
  bool allowTemplateEditing = true,
  String? pdfActionLabel,
  Future<void> Function(Uint8List pdfBytes)? onPdfReady,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => DocumentPrintDesignerPage(
        documentType: documentType,
        title: title,
        documentData: documentData,
        allowPrint: allowPrint,
        allowDownload: allowDownload,
        allowTemplateEditing: allowTemplateEditing,
        pdfActionLabel: pdfActionLabel,
        onPdfReady: onPdfReady,
      ),
    ),
  );
}

class _DocumentPrintDesignerController extends GetxController {
  DocumentPrintTemplate? template;
  String? selectedShapeId;
  Set<String> selectedShapeIds = <String>{};
  final List<_DesignerHistoryEntry> undoStack = <_DesignerHistoryEntry>[];
  final List<_DesignerHistoryEntry> redoStack = <_DesignerHistoryEntry>[];
  _DesignerHistoryEntry? pendingHistoryEntry;
  double canvasZoom = 1.0;
  bool uploadingImage = false;
  bool uploadingBackground = false;
  bool editMode = false;
  bool loading = true;
  bool saving = false;
  bool printingPdf = false;
  bool downloadingPdf = false;
  bool emailingPdf = false;
  _DesignerOperation operation = _DesignerOperation.select;
  Offset? drawStart;
  Offset? drawCurrent;

  void updateState(VoidCallback mutate) {
    mutate();
    update();
  }
}

class _DesignerHistoryEntry {
  const _DesignerHistoryEntry({
    required this.template,
    required this.selectedShapeId,
    required this.selectedShapeIds,
  });

  final DocumentPrintTemplate template;
  final String? selectedShapeId;
  final Set<String> selectedShapeIds;
}

class _PdfFontBundle {
  const _PdfFontBundle({
    required this.regular,
    required this.bold,
    required this.italic,
    required this.boldItalic,
  });

  final pw.Font? regular;
  final pw.Font? bold;
  final pw.Font? italic;
  final pw.Font? boldItalic;
}

class DocumentPrintDesignerPage extends StatefulWidget {
  const DocumentPrintDesignerPage({
    super.key,
    required this.documentType,
    required this.title,
    required this.documentData,
    this.allowPrint = true,
    this.allowDownload = true,
    this.allowTemplateEditing = true,
    this.pdfActionLabel,
    this.onPdfReady,
  });

  final String documentType;
  final String title;
  final DocumentPrintDataModel documentData;
  final bool allowPrint;
  final bool allowDownload;
  final bool allowTemplateEditing;
  final String? pdfActionLabel;
  final Future<void> Function(Uint8List pdfBytes)? onPdfReady;

  @override
  State<DocumentPrintDesignerPage> createState() =>
      _DocumentPrintDesignerPageState();
}

class _DocumentPrintDesignerPageState extends State<DocumentPrintDesignerPage> {
  static const int _historyLimit = 100;
  final PrintTemplateService _service = PrintTemplateService();
  final MediaService _mediaService = MediaService();
  final GlobalKey _previewBoundaryKey = GlobalKey();
  final GlobalKey _pdfPreviewBoundaryKey = GlobalKey();
  final ScrollController _pageScrollController = ScrollController();
  final ScrollController _toolbarScrollController = ScrollController();
  final FocusNode _designerFocusNode = FocusNode();
  final Map<String, Future<_PdfFontBundle>> _pdfFontBundleCache =
      <String, Future<_PdfFontBundle>>{};
  Future<pw.Font>? _pdfUnicodeFallbackFont;
  late final String _controllerTag;
  late final _DocumentPrintDesignerController _controller;

  DocumentPrintTemplate? get _template => _controller.template;
  set _template(DocumentPrintTemplate? value) => _controller.template = value;
  String? get _selectedShapeId => _controller.selectedShapeId;
  set _selectedShapeId(String? value) => _controller.selectedShapeId = value;
  Set<String> get _selectedShapeIds => _controller.selectedShapeIds;
  set _selectedShapeIds(Set<String> value) =>
      _controller.selectedShapeIds = value;
  double get _canvasZoom => _controller.canvasZoom;
  set _canvasZoom(double value) => _controller.canvasZoom = value;
  bool get _uploadingImage => _controller.uploadingImage;
  set _uploadingImage(bool value) => _controller.uploadingImage = value;
  bool get _uploadingBackground => _controller.uploadingBackground;
  set _uploadingBackground(bool value) =>
      _controller.uploadingBackground = value;
  bool get _editMode => _controller.editMode;
  set _editMode(bool value) => _controller.editMode = value;
  bool get _loading => _controller.loading;
  set _loading(bool value) => _controller.loading = value;
  bool get _saving => _controller.saving;
  set _saving(bool value) => _controller.saving = value;
  bool get _printingPdf => _controller.printingPdf;
  set _printingPdf(bool value) => _controller.printingPdf = value;
  bool get _downloadingPdf => _controller.downloadingPdf;
  set _downloadingPdf(bool value) => _controller.downloadingPdf = value;
  bool get _sendingPdf => _controller.emailingPdf;
  set _sendingPdf(bool value) => _controller.emailingPdf = value;
  _DesignerOperation get _operation => _controller.operation;
  set _operation(_DesignerOperation value) => _controller.operation = value;
  Offset? get _drawStart => _controller.drawStart;
  set _drawStart(Offset? value) => _controller.drawStart = value;
  Offset? get _drawCurrent => _controller.drawCurrent;
  set _drawCurrent(Offset? value) => _controller.drawCurrent = value;

  Map<String, dynamic> get _documentDataJson => widget.documentData.toJson();
  String get _watermarkText => widget.documentData.watermarkText.trim();

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'DocumentPrintDesignerController',
      scope: <String, Object?>{
        'documentType': widget.documentType,
        'title': widget.title,
      },
    );
    _controller = Get.put(
      _DocumentPrintDesignerController(),
      tag: _controllerTag,
    );
    _loadTemplate();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _toolbarScrollController.dispose();
    _designerFocusNode.dispose();
    Get.delete<_DocumentPrintDesignerController>(
      tag: _controllerTag,
      force: true,
    );
    super.dispose();
  }

  Future<void> _loadTemplate() async {
    try {
      final response = await _service.getTemplate(widget.documentType);
      if (!mounted) {
        return;
      }
      if (response.success && response.data != null) {
        _controller.updateState(() {
          _template = _prepareTemplate(response.data!);
          _clearHistory();
          _loading = false;
        });
      } else {
        _controller.updateState(() {
          _template = _prepareTemplate(
            DocumentPrintTemplate.defaults(
              widget.documentType,
              title: widget.title,
            ),
          );
          _clearHistory();
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      _controller.updateState(() {
        _template = _prepareTemplate(
          DocumentPrintTemplate.defaults(
            widget.documentType,
            title: widget.title,
          ),
        );
        _clearHistory();
        _loading = false;
      });
    }
  }

  DocumentPrintTemplate _cloneTemplate(DocumentPrintTemplate template) {
    return DocumentPrintTemplate.fromJson(
      Map<String, dynamic>.from(template.toJson()),
    );
  }

  _DesignerHistoryEntry? _captureHistoryEntry() {
    final template = _template;
    if (template == null) {
      return null;
    }
    return _DesignerHistoryEntry(
      template: _cloneTemplate(template),
      selectedShapeId: _selectedShapeId,
      selectedShapeIds: Set<String>.from(_selectedShapeIds),
    );
  }

  bool _historyEntriesEqual(
    _DesignerHistoryEntry left,
    _DesignerHistoryEntry right,
  ) {
    return jsonEncode(left.template.toJson()) ==
            jsonEncode(right.template.toJson()) &&
        left.selectedShapeId == right.selectedShapeId &&
        setEquals(left.selectedShapeIds, right.selectedShapeIds);
  }

  void _clearHistory() {
    _controller.undoStack.clear();
    _controller.redoStack.clear();
    _controller.pendingHistoryEntry = null;
  }

  void _pushUndoEntry(_DesignerHistoryEntry entry) {
    final undoStack = _controller.undoStack;
    if (undoStack.isNotEmpty && _historyEntriesEqual(undoStack.last, entry)) {
      return;
    }
    undoStack.add(entry);
    if (undoStack.length > _historyLimit) {
      undoStack.removeAt(0);
    }
    _controller.redoStack.clear();
  }

  void _restoreHistoryEntry(_DesignerHistoryEntry entry) {
    final template = _cloneTemplate(entry.template);
    final validShapeIds = template.shapes.map((shape) => shape.id).toSet();
    final selectedIds = entry.selectedShapeIds
        .where(validShapeIds.contains)
        .toSet();

    _template = template;
    _selectedShapeIds = selectedIds;
    _selectedShapeId = selectedIds.contains(entry.selectedShapeId)
        ? entry.selectedShapeId
        : (selectedIds.isEmpty ? null : selectedIds.last);
    _operation = _DesignerOperation.select;
    _drawStart = null;
    _drawCurrent = null;
  }

  void _applyTemplateMutation(VoidCallback mutate, {bool trackHistory = true}) {
    final before = trackHistory ? _captureHistoryEntry() : null;
    _controller.updateState(() {
      mutate();
      if (before != null) {
        final after = _captureHistoryEntry();
        if (after != null && !_historyEntriesEqual(before, after)) {
          _pushUndoEntry(before);
        }
      }
    });
  }

  void _beginHistoryGesture() {
    _controller.pendingHistoryEntry ??= _captureHistoryEntry();
  }

  void _endHistoryGesture() {
    final before = _controller.pendingHistoryEntry;
    if (before == null) {
      return;
    }
    _controller.updateState(() {
      _controller.pendingHistoryEntry = null;
      final after = _captureHistoryEntry();
      if (after != null && !_historyEntriesEqual(before, after)) {
        _pushUndoEntry(before);
      }
    });
  }

  bool get _canUndo => _controller.undoStack.isNotEmpty;
  bool get _canRedo => _controller.redoStack.isNotEmpty;

  void _undoTemplateChange() {
    _endHistoryGesture();
    final current = _captureHistoryEntry();
    if (current == null || _controller.undoStack.isEmpty) {
      return;
    }
    _controller.updateState(() {
      final previous = _controller.undoStack.removeLast();
      _controller.redoStack.add(current);
      _restoreHistoryEntry(previous);
    });
  }

  void _redoTemplateChange() {
    _endHistoryGesture();
    final current = _captureHistoryEntry();
    if (current == null || _controller.redoStack.isEmpty) {
      return;
    }
    _controller.updateState(() {
      final next = _controller.redoStack.removeLast();
      _controller.undoStack.add(current);
      if (_controller.undoStack.length > _historyLimit) {
        _controller.undoStack.removeAt(0);
      }
      _restoreHistoryEntry(next);
    });
  }

  DocumentPrintTemplate _prepareTemplate(DocumentPrintTemplate template) {
    final normalized = _ensureTermsBlock(
      template.normalizedFor(widget.documentType),
    );

    final shapes = normalized.shapes.map((shape) {
      if (_isGstBreakupTableShape(shape)) {
        final columns = _normalizeGstBreakupColumns(
          shape.columns.isEmpty ? defaultGstBreakupTableColumns : shape.columns,
          widget.documentData.gstBreakup,
        );
        final tableHeight = measurePrintTableHeight(
          shape: shape,
          rows: widget.documentData.gstBreakup,
          columns: columns,
          fontFamily: effectiveDocumentPrintFontFamily(
            normalized.fontFamily,
            shape.fontFamily,
          ),
        );
        return shape.copyWith(
          dataPath: 'gst_breakup',
          height: tableHeight,
          columns: columns,
        );
      } else if (isPrintLinesTableShape(shape)) {
        return _normalizeLinesTableColumns(shape.copyWith(dataPath: 'lines'));
      }
      return shape;
    }).toList();

    return _normalizeFooterLayout(normalized.copyWith(shapes: shapes));
  }

  DocumentPrintTemplate _normalizeFooterLayout(DocumentPrintTemplate template) {
    final linesTableIndex = template.shapes.indexWhere(
      (shape) => isPrintLinesTableShape(shape),
    );
    final amountWordsLabelIndex = template.shapes.indexWhere(
      (shape) => shape.id == 'amount-words-label',
    );
    final amountWordsValueIndex = template.shapes.indexWhere(
      (shape) =>
          shape.id == 'amount-words-value' || shape.id == 'amount-words-text',
    );
    final gstBreakupIndex = template.shapes.indexWhere(
      (shape) => isPrintGstBreakupTableShape(shape),
    );
    final totalAmountLabelIndex = template.shapes.indexWhere(
      (shape) => shape.id == 'total-amount-label',
    );
    final totalAmountValueIndex = template.shapes.indexWhere(
      (shape) => shape.id == 'total-amount-value',
    );
    final termsTitleIndex = template.shapes.indexWhere(
      (shape) => shape.id == 'terms-title',
    );
    final termsTextIndex = template.shapes.indexWhere(
      (shape) => shape.id == 'terms-text',
    );
    final bankingLabelIndex = template.shapes.indexWhere(
      (shape) => shape.id == 'banking-label',
    );
    final bankingTextIndex = template.shapes.indexWhere(
      (shape) =>
          shape.id == 'banking-details' ||
          shape.id == 'text-31' ||
          shape.text.toLowerCase().contains('a/c no:'),
    );
    final authIndex = template.shapes.indexWhere(
      (shape) => shape.id == 'auth-signatory',
    );

    final requiredIndexes = <int>[
      linesTableIndex,
      amountWordsLabelIndex,
      amountWordsValueIndex,
      gstBreakupIndex,
      termsTitleIndex,
      termsTextIndex,
      bankingLabelIndex,
      bankingTextIndex,
      authIndex,
    ];
    if (requiredIndexes.any((index) => index < 0)) {
      return template;
    }

    final shapes = [...template.shapes];
    var linesTable = shapes[linesTableIndex];
    var amountWordsLabel = shapes[amountWordsLabelIndex];
    var amountWordsValue = shapes[amountWordsValueIndex];
    var gstBreakup = shapes[gstBreakupIndex];
    var totalAmountLabel = totalAmountLabelIndex >= 0
        ? shapes[totalAmountLabelIndex]
        : null;
    var totalAmountValue = totalAmountValueIndex >= 0
        ? shapes[totalAmountValueIndex]
        : null;
    var termsTitle = shapes[termsTitleIndex];
    var termsText = shapes[termsTextIndex];
    var bankingLabel = shapes[bankingLabelIndex];
    var bankingText = shapes[bankingTextIndex];
    var authSignatory = shapes[authIndex];

    final amountWordsHeight = _measureShapeTextHeight(amountWordsValue);
    final termsHeight = _measureShapeTextHeight(termsText);
    final bankingTextHeight = _measureShapeTextHeight(bankingText);

    final baseTableBottom = linesTable.y + linesTable.height;
    final baseFooterStart = amountWordsLabel.y;
    final tableToFooterGap = baseFooterStart - baseTableBottom;
    final amountWordsValueDelta = amountWordsValue.y - amountWordsLabel.y;
    final amountSectionGap =
        gstBreakup.y -
        math.max(
          amountWordsLabel.y + amountWordsLabel.height,
          amountWordsValue.y + amountWordsValue.height,
        );
    final termsTitleGap =
        termsTitle.y -
        math.max(
          gstBreakup.y + gstBreakup.height,
          math.max(
                totalAmountLabel?.y ?? gstBreakup.y,
                totalAmountValue?.y ?? gstBreakup.y,
              ) +
              math.max(
                totalAmountLabel?.height ?? 0,
                totalAmountValue?.height ?? 0,
              ),
        );
    final termsTextGap = termsText.y - (termsTitle.y + termsTitle.height);
    final bankingLabelGap = bankingLabel.y - (termsText.y + termsText.height);
    final bankingTextGap =
        bankingText.y - (bankingLabel.y + bankingLabel.height);
    final authBaseY = authSignatory.y;
    final authGap = authBaseY - (bankingText.y + bankingText.height);
    final totalAmountLabelDelta = totalAmountLabel != null
        ? totalAmountLabel.y - gstBreakup.y
        : 0.0;
    final totalAmountValueDelta = totalAmountValue != null
        ? totalAmountValue.y - gstBreakup.y
        : 0.0;
    final footerBottomLimit = template.pageHeight - 28;

    double rebuildFooter(double footerStartY, {bool commit = false}) {
      final nextAmountLabel = amountWordsLabel.copyWith(y: footerStartY);
      final nextAmountValue = amountWordsValue.copyWith(
        y: footerStartY + amountWordsValueDelta,
        height: math.max(amountWordsValue.height, amountWordsHeight),
      );
      final amountBottom = math.max(
        nextAmountLabel.y + nextAmountLabel.height,
        nextAmountValue.y + nextAmountValue.height,
      );

      final nextGstBreakup = gstBreakup.copyWith(
        y: amountBottom + amountSectionGap,
      );
      final nextTotalAmountLabel = totalAmountLabel?.copyWith(
        y: nextGstBreakup.y + totalAmountLabelDelta,
      );
      final nextTotalAmountValue = totalAmountValue?.copyWith(
        y: nextGstBreakup.y + totalAmountValueDelta,
      );
      final nextTermsTitleY =
          math.max(
            nextGstBreakup.y + nextGstBreakup.height,
            math.max(
                  nextTotalAmountLabel?.y ?? nextGstBreakup.y,
                  nextTotalAmountValue?.y ?? nextGstBreakup.y,
                ) +
                math.max(
                  nextTotalAmountLabel?.height ?? 0,
                  nextTotalAmountValue?.height ?? 0,
                ),
          ) +
          termsTitleGap;
      final nextTermsTitle = termsTitle.copyWith(y: nextTermsTitleY);
      final nextTermsText = termsText.copyWith(
        y: nextTermsTitle.y + nextTermsTitle.height + termsTextGap,
        height: math.max(termsText.height, termsHeight),
      );
      final nextBankingLabel = bankingLabel.copyWith(
        y: nextTermsText.y + nextTermsText.height + bankingLabelGap,
      );
      final nextBankingText = bankingText.copyWith(
        y: nextBankingLabel.y + nextBankingLabel.height + bankingTextGap,
        height: math.max(bankingText.height, bankingTextHeight),
      );
      final nextAuthSignatory = authSignatory.copyWith(
        y: math.max(
          authBaseY,
          nextBankingText.y + nextBankingText.height + authGap,
        ),
      );

      if (commit) {
        amountWordsLabel = nextAmountLabel;
        amountWordsValue = nextAmountValue;
        gstBreakup = nextGstBreakup;
        totalAmountLabel = nextTotalAmountLabel;
        totalAmountValue = nextTotalAmountValue;
        termsTitle = nextTermsTitle;
        termsText = nextTermsText;
        bankingLabel = nextBankingLabel;
        bankingText = nextBankingText;
        authSignatory = nextAuthSignatory;
      }

      return math.max(
        nextAuthSignatory.y + nextAuthSignatory.height,
        nextBankingText.y + nextBankingText.height,
      );
    }

    final initialFooterBottom = rebuildFooter(baseFooterStart);
    final overflow = math.max(0.0, initialFooterBottom - footerBottomLimit);
    if (overflow > 0) {
      final minimumLinesHeight = math.max(
        120.0,
        (linesTable.printHeader ? linesTable.titleHeight : 0) +
            (linesTable.printTotal ? linesTable.titleHeight : 0) +
            48.0,
      );
      final nextTableHeight = math.max(
        minimumLinesHeight,
        linesTable.height - overflow,
      );
      linesTable = linesTable.copyWith(height: nextTableHeight);
    }

    final nextFooterStart = linesTable.y + linesTable.height + tableToFooterGap;
    rebuildFooter(nextFooterStart, commit: true);

    shapes[linesTableIndex] = linesTable;
    shapes[amountWordsLabelIndex] = amountWordsLabel;
    shapes[amountWordsValueIndex] = amountWordsValue;
    shapes[gstBreakupIndex] = gstBreakup;
    if (totalAmountLabelIndex >= 0 && totalAmountLabel != null) {
      shapes[totalAmountLabelIndex] = totalAmountLabel!;
    }
    if (totalAmountValueIndex >= 0 && totalAmountValue != null) {
      shapes[totalAmountValueIndex] = totalAmountValue!;
    }
    shapes[termsTitleIndex] = termsTitle;
    shapes[termsTextIndex] = termsText;
    shapes[bankingLabelIndex] = bankingLabel;
    shapes[bankingTextIndex] = bankingText;
    shapes[authIndex] = authSignatory;
    return template.copyWith(shapes: shapes);
  }

  double _measureShapeTextHeight(DocumentPrintShape shape) {
    final resolvedText = resolvePrintTemplateText(
      shape.text,
      _documentDataJson,
    );
    if (resolvedText.trim().isEmpty) {
      return shape.height;
    }
    final painter = TextPainter(
      text: TextSpan(
        text: resolvedText,
        style: TextStyle(
          fontSize: shape.fontSize,
          fontWeight: shape.bold ? FontWeight.w700 : FontWeight.w400,
          fontStyle: shape.italic ? FontStyle.italic : FontStyle.normal,
          decoration: shape.underline
              ? TextDecoration.underline
              : TextDecoration.none,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: switch (shape.align) {
        'center' => TextAlign.center,
        'right' => TextAlign.right,
        _ => TextAlign.left,
      },
      maxLines: shape.multiline ? null : 1,
    )..layout(maxWidth: shape.width);
    return math.max(shape.height, painter.height);
  }

  List<DocumentPrintColumn> _normalizeGstBreakupColumns(
    List<DocumentPrintColumn> columns,
    List<DocumentPrintTaxBreakupRowModel> rows,
  ) {
    if (rows.isEmpty) {
      return columns;
    }
    final hideIgst = rows.every((row) => row.igst.abs() < 0.005);
    final hideCgstSgst = rows.every(
      (row) => row.cgst.abs() < 0.005 && row.sgst.abs() < 0.005,
    );

    var normalized = List<DocumentPrintColumn>.from(columns);

    if (!hideIgst && !normalized.any((c) => c.key == 'igst')) {
      final defaultIgst =
          defaultGstBreakupTableColumns.firstWhere((c) => c.key == 'igst');
      normalized.add(defaultIgst);
    }
    if (!hideCgstSgst && !normalized.any((c) => c.key == 'cgst')) {
      final defaultCgst =
          defaultGstBreakupTableColumns.firstWhere((c) => c.key == 'cgst');
      final igstIndex = normalized.indexWhere((c) => c.key == 'igst');
      if (igstIndex >= 0) {
        normalized.insert(igstIndex, defaultCgst);
      } else {
        normalized.add(defaultCgst);
      }
    }
    if (!hideCgstSgst && !normalized.any((c) => c.key == 'sgst')) {
      final defaultSgst =
          defaultGstBreakupTableColumns.firstWhere((c) => c.key == 'sgst');
      final igstIndex = normalized.indexWhere((c) => c.key == 'igst');
      if (igstIndex >= 0) {
        normalized.insert(igstIndex, defaultSgst);
      } else {
        normalized.add(defaultSgst);
      }
    }

    if (hideIgst) {
      normalized.removeWhere((c) => c.key == 'igst');
    }
    if (hideCgstSgst) {
      normalized.removeWhere((c) => c.key == 'cgst' || c.key == 'sgst');
    }

    return normalized;
  }

  DocumentPrintShape _normalizeLinesTableColumns(DocumentPrintShape shape) {
    const hsnEnabledDocumentTypes = <String>{
      'sales_invoice',
      'sales_quotation',
      'sales_order',
      'sales_delivery',
      'sales_returnable_delivery',
      'purchase_order',
      'purchase_invoice',
    };
    if (!hsnEnabledDocumentTypes.contains(widget.documentType)) {
      return shape;
    }
    if (shape.columns.isEmpty) {
      return shape;
    }

    var changed = false;
    final updatedColumns = shape.columns
        .map((column) {
          if (column.key == 'line_no') {
            changed = true;
            return column.copyWith(
              label: column.label.trim().isEmpty ? 'S.No' : column.label,
              widthFactor: column.widthFactor <= 0 ? 0.9 : column.widthFactor,
              align: 'center',
              titleAlign: 'center',
            );
          }
          if (column.key == 'hsn') {
            changed = true;
            return column.copyWith(
              label: column.label.trim().isEmpty ? 'HSN' : column.label,
              widthFactor: column.widthFactor <= 0 ? 1.6 : column.widthFactor,
              align: 'center',
              titleAlign: 'center',
            );
          }
          return column;
        })
        .toList(growable: true);

    if (!updatedColumns.any((column) => column.key == 'line_no')) {
      updatedColumns.insert(
        0,
        const DocumentPrintColumn(
          key: 'line_no',
          label: 'S.No',
          widthFactor: 0.9,
          align: 'center',
          titleAlign: 'center',
        ),
      );
      changed = true;
    }
    if (!updatedColumns.any((column) => column.key == 'hsn')) {
      final itemIndex = updatedColumns.indexWhere(
        (column) => column.key == 'item_name',
      );
      final insertAt = itemIndex >= 0 ? itemIndex + 1 : updatedColumns.length;
      updatedColumns.insert(
        insertAt,
        const DocumentPrintColumn(
          key: 'hsn',
          label: 'HSN',
          widthFactor: 1.6,
          align: 'center',
          titleAlign: 'center',
        ),
      );
      changed = true;
    }

    return changed ? shape.copyWith(columns: updatedColumns) : shape;
  }

  bool _isGstBreakupTableShape(DocumentPrintShape shape) {
    return isPrintGstBreakupTableShape(shape);
  }

  DocumentPrintTemplate _ensureTermsBlock(DocumentPrintTemplate template) {
    final hasTermsBinding = template.shapes.any(
      (shape) =>
          shape.type == 'text' &&
          shape.text.toLowerCase().contains('{{terms_conditions}}'),
    );
    if (hasTermsBinding) {
      return template;
    }

    final shapes = [...template.shapes];
    final notesIndex = shapes.indexWhere((shape) => shape.id == 'notes-text');
    if (notesIndex >= 0) {
      final notes = shapes[notesIndex];
      shapes[notesIndex] = notes.copyWith(height: math.min(notes.height, 34));
      shapes.add(
        DocumentPrintShape(
          id: 'terms-title',
          type: 'text',
          x: notes.x,
          y: notes.y + math.min(notes.height, 34.0) + 6.0,
          width: 160,
          height: 16,
          text: 'Terms & Conditions',
          fontSize: math.max(9.0, notes.fontSize).toDouble(),
          bold: true,
        ),
      );
      shapes.add(
        DocumentPrintShape(
          id: 'terms-text',
          type: 'text',
          x: notes.x,
          y: notes.y + math.min(notes.height, 34.0) + 24.0,
          width: notes.width,
          height: math.max(24.0, notes.height - 24.0).toDouble(),
          text: '{{terms_conditions}}',
          fontSize: math.max(8.0, notes.fontSize - 1.0).toDouble(),
          multiline: true,
        ),
      );
      return template.copyWith(shapes: shapes);
    }

    shapes.add(
      const DocumentPrintShape(
        id: 'terms-title',
        type: 'text',
        x: 28,
        y: 708,
        width: 160,
        height: 16,
        text: 'Terms & Conditions',
        fontSize: 10,
        bold: true,
      ),
    );
    shapes.add(
      const DocumentPrintShape(
        id: 'terms-text',
        type: 'text',
        x: 28,
        y: 726,
        width: 300,
        height: 30,
        text: '{{terms_conditions}}',
        fontSize: 9,
        multiline: true,
      ),
    );
    return template.copyWith(shapes: shapes);
  }

  Future<void> _saveTemplate() async {
    final template = _template;
    if (template == null) {
      return;
    }
    _controller.updateState(() => _saving = true);
    try {
      final response = await _service.saveTemplate(
        widget.documentType,
        template,
      );
      if (!mounted) {
        return;
      }
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Print template saved successfully.')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving template: $e')));
    } finally {
      if (mounted) {
        _controller.updateState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<_DocumentPrintDesignerController>(
      tag: _controllerTag,
      builder: (_) => AppStandaloneShell(
        title: '${widget.title} Preview',
        scrollController: _pageScrollController,
        actions: _buildShellActions(),
        child: _buildContent(),
      ),
    );
  }

  List<Widget> _buildShellActions() {
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icons.close,
        label: 'Close',
        filled: false,
      ),
    ];

    if (_loading) {
      return actions;
    }

    if (widget.allowTemplateEditing) {
      actions.add(
        AdaptiveShellActionButton(
          onPressed: () => _controller.updateState(() {
            _editMode = !_editMode;
            if (!_editMode) {
              _selectedShapeId = null;
              _selectedShapeIds = <String>{};
            }
            _drawStart = null;
            _drawCurrent = null;
          }),
          icon: _editMode ? Icons.visibility_outlined : Icons.edit_outlined,
          label: _editMode ? 'Preview Mode' : 'Edit Template',
          filled: false,
          iconOnly: !_editMode,
        ),
      );
    }

    if (_editMode) {
      actions.add(
        AdaptiveShellActionButton(
          onPressed: _saving ? null : _saveTemplate,
          icon: Icons.save_outlined,
          label: _saving ? 'Saving...' : 'Save Template',
        ),
      );
      actions.add(
        AdaptiveShellActionButton(
          onPressed: _importTemplate,
          icon: Icons.file_open_outlined,
          label: 'Import',
          filled: false,
        ),
      );
      actions.add(
        AdaptiveShellActionButton(
          onPressed: _exportTemplate,
          icon: Icons.download_outlined,
          label: 'Export Template',
          filled: false,
        ),
      );
    }

    if (widget.allowDownload) {
      actions.add(
        AdaptiveShellActionButton(
          onPressed: _downloadingPdf ? null : _downloadPdf,
          icon: Icons.download_outlined,
          label: _downloadingPdf ? 'Preparing PDF...' : 'Download PDF',
          filled: false,
        ),
      );
    }

    if (widget.onPdfReady != null) {
      actions.add(
        AdaptiveShellActionButton(
          onPressed: _sendingPdf ? null : _sendPdf,
          icon: Icons.attach_email_outlined,
          label: _sendingPdf
              ? 'Sending PDF...'
              : (widget.pdfActionLabel ?? 'Email PDF'),
          filled: false,
        ),
      );
    }

    if (widget.allowPrint) {
      actions.add(
        AdaptiveShellActionButton(
          onPressed: _printingPdf ? null : _printPdf,
          icon: Icons.print_outlined,
          label: _printingPdf ? 'Printing...' : 'Print',
        ),
      );
    }

    return actions;
  }

  Widget _buildContent() {
    final template = _template;
    if (_loading) {
      return const AppLoadingView(message: 'Loading print designer...');
    }
    if (template == null) {
      return const AppErrorStateView(
        title: 'Unable to open designer',
        message: 'Print template could not be loaded.',
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final showSideInspector = _editMode && constraints.maxWidth >= 1400;

            return Padding(
              padding: const EdgeInsets.all(AppUiConstants.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_editMode) ...[
                    AppSectionCard(
                      padding: const EdgeInsets.all(AppUiConstants.spacingMd),
                      child: _buildToolbar(),
                    ),
                    const SizedBox(height: AppUiConstants.spacingLg),
                  ],
                  Expanded(
                    child: showSideInspector
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _buildCanvasCard(template)),
                              const SizedBox(width: AppUiConstants.spacingLg),
                              SizedBox(
                                width: 420,
                                child: _buildInspector(
                                  template,
                                  padding: const EdgeInsets.all(
                                    AppUiConstants.spacingSm,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _buildCanvasCard(template)),
                              if (_editMode) ...[
                                const SizedBox(
                                  height: AppUiConstants.spacingLg,
                                ),
                                SizedBox(
                                  height: 320,
                                  child: _buildInspector(
                                    template,
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        ),
        Positioned(
          left: 0,
          top: 0,
          child: SizedBox(
            width: 0,
            height: 0,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: 0,
              minHeight: 0,
              maxWidth: template.pageWidth,
              maxHeight: template.pageHeight,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.01,
                  child: RepaintBoundary(
                    key: _pdfPreviewBoundaryKey,
                    child: _DocumentPageSurface(
                      template: template,
                      documentData: _documentDataJson,
                      watermarkText: _watermarkText,
                      scale: 1,
                      editMode: false,
                      selectedShapeId: null,
                      selectedShapeIds: const <String>{},
                      showDecoration: false,
                      onSelectShape: (_) {},
                      onMoveShape: (shapeId, delta) {},
                      onResizeShape: (shapeId, delta) {},
                      onMoveStart: () {},
                      onMoveEnd: () {},
                      onResizeStart: () {},
                      onResizeEnd: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Scrollbar(
      controller: _toolbarScrollController,
      thumbVisibility: true,
      notificationPredicate: (notification) =>
          notification.metrics.axis == Axis.horizontal,
      child: SingleChildScrollView(
        controller: _toolbarScrollController,
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                _modeButton(
                  Icons.ads_click_outlined,
                  'Select',
                  _DesignerOperation.select,
                ),
                const SizedBox(width: AppUiConstants.spacingMd),
                _toolbarButton(
                  Icons.text_fields,
                  'Text',
                  () => _insertShapeFromToolbar(_DesignerOperation.drawText),
                ),
                const SizedBox(width: AppUiConstants.spacingXs),
                _toolbarButton(
                  Icons.crop_square_outlined,
                  'Box',
                  () => _insertShapeFromToolbar(_DesignerOperation.drawRect),
                ),
                const SizedBox(width: AppUiConstants.spacingXs),
                _toolbarButton(
                  Icons.circle_outlined,
                  'Oval',
                  () => _insertShapeFromToolbar(_DesignerOperation.drawEllipse),
                ),
                const SizedBox(width: AppUiConstants.spacingXs),
                _toolbarButton(
                  Icons.pentagon_outlined,
                  'Polygon',
                  () => _insertShapeFromToolbar(_DesignerOperation.drawPolygon),
                ),
                const SizedBox(width: AppUiConstants.spacingXs),
                _toolbarButton(
                  Icons.show_chart_outlined,
                  'Line',
                  () => _insertShapeFromToolbar(_DesignerOperation.drawLine),
                ),
                const SizedBox(width: AppUiConstants.spacingXs),
                _toolbarButton(
                  Icons.table_chart_outlined,
                  'Table',
                  () => _insertShapeFromToolbar(_DesignerOperation.drawTable),
                ),
                const SizedBox(width: AppUiConstants.spacingXs),
                _toolbarButton(
                  Icons.image_outlined,
                  'Image',
                  () => _insertShapeFromToolbar(_DesignerOperation.drawImage),
                ),
                const SizedBox(width: AppUiConstants.spacingXs),
                _toolbarButton(
                  Icons.qr_code,
                  'Barcode',
                  () => _insertShapeFromToolbar(_DesignerOperation.drawBarcode),
                ),
                const SizedBox(width: AppUiConstants.spacingMd),
                OutlinedButton.icon(
                  onPressed: _canUndo ? _undoTemplateChange : null,
                  icon: const Icon(Icons.undo_outlined),
                  label: const Text('Undo'),
                ),
                const SizedBox(width: AppUiConstants.spacingXs),
                OutlinedButton.icon(
                  onPressed: _canRedo ? _redoTemplateChange : null,
                  icon: const Icon(Icons.redo_outlined),
                  label: const Text('Redo'),
                ),
                const SizedBox(width: AppUiConstants.spacingMd),
                OutlinedButton.icon(
                  onPressed: _resetTemplate,
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Reset'),
                ),
                const SizedBox(width: AppUiConstants.spacingXs),
                OutlinedButton.icon(
                  onPressed: _canvasZoom <= 0.7
                      ? null
                      : () => _controller.updateState(
                          () => _canvasZoom = (_canvasZoom - 0.15).clamp(
                            0.55,
                            2.5,
                          ),
                        ),
                  icon: const Icon(Icons.zoom_out_outlined),
                  label: const Text('Zoom -'),
                ),
                const SizedBox(width: AppUiConstants.spacingXs),
                OutlinedButton(
                  onPressed: () =>
                      _controller.updateState(() => _canvasZoom = 1.0),
                  child: const Text('Fit'),
                ),
                const SizedBox(width: AppUiConstants.spacingXs),
                OutlinedButton.icon(
                  onPressed: _canvasZoom >= 2.5
                      ? null
                      : () => _controller.updateState(
                          () => _canvasZoom = (_canvasZoom + 0.15).clamp(
                            0.55,
                            2.5,
                          ),
                        ),
                  icon: const Icon(Icons.zoom_in_outlined),
                  label: const Text('Zoom +'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeButton(IconData icon, String label, _DesignerOperation mode) {
    final selected = _operation == mode;
    return FilledButton.tonalIcon(
      onPressed: () => _controller.updateState(() {
        _operation = mode;
        _drawStart = null;
        _drawCurrent = null;
      }),
      icon: Icon(icon),
      label: Text(label),
      style: selected
          ? FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            )
          : FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
    );
  }

  void _insertShapeFromToolbar(_DesignerOperation tool) {
    final template = _template;
    if (template == null) {
      return;
    }
    final type = tool.shapeType;
    if (type == null) {
      return;
    }
    final shape = DocumentPrintShape.defaults(type, template.shapes.length);
    final placed = shape.copyWith(
      x: math.min(
        math.max(24.0, (template.pageWidth - shape.width) / 2),
        math.max(0.0, template.pageWidth - shape.width - 24),
      ),
      y: math.min(
        math.max(24.0, (template.pageHeight - shape.height) / 2),
        math.max(0.0, template.pageHeight - shape.height - 24),
      ),
    );
    _applyTemplateMutation(() {
      _template = template.copyWith(shapes: [...template.shapes, placed]);
      _selectedShapeId = placed.id;
      _selectedShapeIds = <String>{placed.id};
      _operation = _DesignerOperation.select;
      _drawStart = null;
      _drawCurrent = null;
    });
  }

  Widget _toolbarButton(IconData icon, String label, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildCanvasCard(DocumentPrintTemplate template) {
    return AppSectionCard(
      padding: const EdgeInsets.all(AppUiConstants.spacingMd),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppUiConstants.panelRadius),
        ),
        padding: const EdgeInsets.all(AppUiConstants.spacingLg),
        alignment: Alignment.center,
        child: KeyboardListener(
          focusNode: _designerFocusNode,
          autofocus: true,
          onKeyEvent: (event) {
            if (event is! KeyDownEvent) {
              return;
            }
            final isCommand =
                HardwareKeyboard.instance.isMetaPressed ||
                HardwareKeyboard.instance.isControlPressed;
            final isShift = HardwareKeyboard.instance.isShiftPressed;
            if (isCommand && event.logicalKey == LogicalKeyboardKey.keyZ) {
              if (isShift) {
                _redoTemplateChange();
              } else {
                _undoTemplateChange();
              }
              return;
            }
            if (isCommand && event.logicalKey == LogicalKeyboardKey.keyY) {
              _redoTemplateChange();
              return;
            }
            final selectedIds = _selectedShapeIds;
            final shapeId = _selectedShapeId;
            if (selectedIds.isEmpty || shapeId == null) {
              return;
            }
            final delta = isShift ? 10.0 : 1.0;

            if (event.logicalKey == LogicalKeyboardKey.delete) {
              _deleteSelectedShape();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _beginHistoryGesture();
              _moveShape(shapeId, Offset(-delta, 0));
              _endHistoryGesture();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _beginHistoryGesture();
              _moveShape(shapeId, Offset(delta, 0));
              _endHistoryGesture();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _beginHistoryGesture();
              _moveShape(shapeId, Offset(0, -delta));
              _endHistoryGesture();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _beginHistoryGesture();
              _moveShape(shapeId, Offset(0, delta));
              _endHistoryGesture();
            }
          },
          child: RepaintBoundary(
            key: _previewBoundaryKey,
            child: _DesignerCanvas(
              template: template,
              documentData: _documentDataJson,
              watermarkText: _watermarkText,
              editMode: _editMode,
              selectedShapeId: _selectedShapeId,
              selectedShapeIds: _selectedShapeIds,
              zoom: _canvasZoom,
              onSelectShape: (shapeId) {
                if (!_editMode) {
                  return;
                }
                _handleShapeSelection(shapeId);
              },
              onMoveShape: _moveShape,
              onResizeShape: _resizeShape,
              onMoveStart: _beginHistoryGesture,
              onMoveEnd: _endHistoryGesture,
              onResizeStart: _beginHistoryGesture,
              onResizeEnd: _endHistoryGesture,
              operation: _operation,
              draftShape: _activeDraftShape(template),
              onDrawStart: _handleDrawStart,
              onDrawUpdate: _handleDrawUpdate,
              onDrawEnd: () => _handleDrawEnd(template),
              onDrawTap: (point) => _handleDrawTap(template, point),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInspector(
    DocumentPrintTemplate template, {
    required EdgeInsets padding,
  }) {
    final selected = template.shapeById(_selectedShapeId);
    final multiSelected = _selectedShapeIds.length > 1;
    return Padding(
      padding: padding,
      child: AppSectionCard(
        child: SingleChildScrollView(
          child: multiSelected
              ? _MultiSelectionInspector(
                  count: _selectedShapeIds.length,
                  onDelete: _deleteSelectedShape,
                  onBringForward: _bringSelectedForward,
                  onSendBackward: _sendSelectedBackward,
                  onBringToFront: _bringSelectedToFront,
                  onSendToBack: _sendSelectedToBack,
                  onDuplicate: _duplicateSelectedShapes,
                )
              : selected == null
              ? DocumentDesignerPageInspector(
                  template: template,
                  onChanged: _updateTemplate,
                  isUploadingBackground: _uploadingBackground,
                  onUploadBackground: _uploadBackgroundImage,
                )
              : DocumentDesignerShapeInspector(
                  key: ValueKey(selected.id),
                  shape: selected,
                  bindings: availablePrintBindings(_documentDataJson),
                  listBindings: availablePrintListBindings(_documentDataJson),
                  rowBindings: availablePrintRowKeysForPath(
                    _documentDataJson,
                    selected.dataPath,
                  ),
                  isUploadingImage: _uploadingImage,
                  onChanged: _updateShape,
                  onUploadImage: () => _uploadImageForShape(selected),
                  onDelete: _deleteSelectedShape,
                  onBringForward: _bringSelectedForward,
                  onSendBackward: _sendSelectedBackward,
                  onBringToFront: _bringSelectedToFront,
                  onSendToBack: _sendSelectedToBack,
                  onDuplicate: _duplicateSelectedShapes,
                ),
        ),
      ),
    );
  }

  void _resetTemplate() {
    _applyTemplateMutation(() {
      _template = _prepareTemplate(
        DocumentPrintTemplate.defaults(
          widget.documentType,
          title: widget.title,
        ),
      );
      _selectedShapeId = null;
      _selectedShapeIds = <String>{};
      _drawStart = null;
      _drawCurrent = null;
      _operation = _DesignerOperation.select;
    });
  }

  void _handleDrawStart(Offset point) {
    if (!_operation.isDrawTool) {
      return;
    }
    _controller.updateState(() {
      _drawStart = point;
      _drawCurrent = point;
    });
  }

  void _handleDrawUpdate(Offset point) {
    if (!_operation.isDrawTool || _drawStart == null) {
      return;
    }
    _controller.updateState(() => _drawCurrent = point);
  }

  void _handleDrawEnd(DocumentPrintTemplate template) {
    if (!_operation.isDrawTool) {
      return;
    }
    final draft = _activeDraftShape(template);
    _applyTemplateMutation(() {
      if (draft != null) {
        _template = template.copyWith(shapes: [...template.shapes, draft]);
        _selectedShapeId = draft.id;
        _selectedShapeIds = <String>{draft.id};
      }
      _drawStart = null;
      _drawCurrent = null;
      _operation = _DesignerOperation.select;
    });
  }

  void _handleDrawTap(DocumentPrintTemplate template, Offset point) {
    if (!_operation.isDrawTool || _drawStart != null) {
      return;
    }
    final type = _operation.shapeType;
    if (type == null) {
      return;
    }
    final base = DocumentPrintShape.defaults(type, template.shapes.length);
    final draft = base.copyWith(
      x: point.dx.clamp(0.0, math.max(0.0, template.pageWidth - base.width)),
      y: point.dy.clamp(0.0, math.max(0.0, template.pageHeight - base.height)),
    );
    _applyTemplateMutation(() {
      _template = template.copyWith(shapes: [...template.shapes, draft]);
      _selectedShapeId = draft.id;
      _selectedShapeIds = <String>{draft.id};
      _operation = _DesignerOperation.select;
      _drawStart = null;
      _drawCurrent = null;
    });
  }

  DocumentPrintShape? _activeDraftShape(DocumentPrintTemplate template) {
    final start = _drawStart;
    final current = _drawCurrent;
    if (start == null || current == null || !_operation.isDrawTool) {
      return null;
    }
    final type = _operation.shapeType;
    if (type == null) {
      return null;
    }
    final rect = Rect.fromPoints(start, current);
    final shape = DocumentPrintShape.defaults(type, template.shapes.length);
    return shape.copyWith(
      x: rect.left,
      y: rect.top,
      width: math.max(type == 'line' ? 8 : 24, rect.width),
      height: type == 'line' ? rect.height : math.max(16, rect.height),
    );
  }

  Future<void> _importTemplate() async {
    final picked = await pickSingleFile(accept: '.json,application/json');
    if (picked == null) {
      return;
    }
    try {
      final decoded = jsonDecode(utf8.decode(picked.bytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid template JSON');
      }
      final next = _prepareTemplate(
        DocumentPrintTemplate.fromJson(decoded).withoutUnsupportedShapes(),
      );
      if (!mounted) {
        return;
      }
      _applyTemplateMutation(() {
        _template = next;
        _selectedShapeId = null;
        _selectedShapeIds = <String>{};
        _operation = _DesignerOperation.select;
        _drawStart = null;
        _drawCurrent = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported template: ${picked.name}')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $error')));
    }
  }

  Future<void> _exportTemplate() async {
    final template = _template;
    if (template == null) {
      return;
    }
    final exportable = _prepareTemplate(template).toJson();
    final text = const JsonEncoder.withIndent('  ').convert(exportable);
    final safeType = widget.documentType.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
    final saved = await saveTextFile(
      suggestedName: '${safeType}_print_template.json',
      text: text,
      mimeType: 'application/json',
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Template exported successfully.'
              : 'Template export cancelled.',
        ),
      ),
    );
  }

  void _updateTemplate(DocumentPrintTemplate next) {
    _applyTemplateMutation(() => _template = next);
  }

  void _updateShape(DocumentPrintShape next) {
    final template = _template;
    if (template == null) {
      return;
    }
    final shapes = template.shapes
        .map((shape) => shape.id == next.id ? next : shape)
        .toList(growable: false);
    _applyTemplateMutation(() => _template = template.copyWith(shapes: shapes));
  }

  void _handleShapeSelection(String? shapeId) {
    final additive =
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isShiftPressed;
    _controller.updateState(() {
      if (shapeId == null) {
        _selectedShapeId = null;
        _selectedShapeIds = <String>{};
        return;
      }
      if (!additive) {
        _selectedShapeId = shapeId;
        _selectedShapeIds = <String>{shapeId};
        return;
      }
      final next = <String>{..._selectedShapeIds};
      if (next.contains(shapeId)) {
        next.remove(shapeId);
        _selectedShapeId = next.isEmpty ? null : next.last;
      } else {
        next.add(shapeId);
        _selectedShapeId = shapeId;
      }
      _selectedShapeIds = next;
    });
  }

  Future<void> _uploadImageForShape(DocumentPrintShape shape) async {
    if (shape.type != 'image') {
      return;
    }
    await MediaUploadHelper.uploadImage(
      context: context,
      mediaService: _mediaService,
      module: 'printing',
      documentType: widget.documentType,
      purpose: 'print_template_image',
      folder: 'print-templates',
      isPublic: true,
      preferFilePath: true,
      onLoading: (loading) {
        if (mounted) {
          _controller.updateState(() => _uploadingImage = loading);
        }
      },
      onSuccess: (filePath) {
        _updateShape(shape.copyWith(assetPath: filePath));
      },
      onError: (message) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  Future<void> _uploadBackgroundImage() async {
    final template = _template;
    if (template == null) {
      return;
    }
    await MediaUploadHelper.uploadImage(
      context: context,
      mediaService: _mediaService,
      module: 'printing',
      documentType: widget.documentType,
      purpose: 'print_template_background',
      folder: 'print-templates',
      isPublic: true,
      preferFilePath: true,
      onLoading: (loading) {
        if (mounted) {
          _controller.updateState(() => _uploadingBackground = loading);
        }
      },
      onSuccess: (filePath) {
        if (!mounted) {
          return;
        }
        _applyTemplateMutation(() {
          _template = template.copyWith(backgroundImagePath: filePath);
        });
      },
      onError: (message) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  void _moveShape(String shapeId, Offset delta) {
    final template = _template;
    if (template == null) {
      return;
    }
    final targetIds = _selectedShapeIds.contains(shapeId)
        ? _selectedShapeIds
        : <String>{shapeId};
    final shapes = template.shapes
        .map((shape) {
          if (!targetIds.contains(shape.id)) {
            return shape;
          }
          var nextX = shape.x + delta.dx;
          var nextY = shape.y + delta.dy;

          if (template.showGrid) {
            nextX = (nextX / template.gridSize).round() * template.gridSize;
            nextY = (nextY / template.gridSize).round() * template.gridSize;
          }
          return shape.copyWith(x: math.max(0, nextX), y: math.max(0, nextY));
        })
        .toList(growable: false);
    _applyTemplateMutation(
      () => _template = template.copyWith(shapes: shapes),
      trackHistory: false,
    );
  }

  void _resizeShape(String shapeId, Offset delta) {
    final template = _template;
    if (template == null) {
      return;
    }
    final targetIds = _selectedShapeIds.contains(shapeId)
        ? _selectedShapeIds
        : <String>{shapeId};
    final shapes = template.shapes
        .map((shape) {
          if (!targetIds.contains(shape.id)) {
            return shape;
          }
          var nextW = shape.width + delta.dx;
          var nextH = shape.height + delta.dy;

          if (template.showGrid) {
            nextW = (nextW / template.gridSize).round() * template.gridSize;
            nextH = (nextH / template.gridSize).round() * template.gridSize;
          }
          return shape.copyWith(
            width: math.max(16, nextW),
            height: math.max(16, nextH),
          );
        })
        .toList(growable: false);
    _applyTemplateMutation(
      () => _template = template.copyWith(shapes: shapes),
      trackHistory: false,
    );
  }

  void _deleteSelectedShape() {
    final template = _template;
    if (template == null || _selectedShapeIds.isEmpty) {
      return;
    }
    _applyTemplateMutation(() {
      _template = template.copyWith(
        shapes: template.shapes
            .where((shape) => !_selectedShapeIds.contains(shape.id))
            .toList(growable: false),
      );
      _selectedShapeId = null;
      _selectedShapeIds = <String>{};
    });
  }

  void _bringSelectedForward() {
    final template = _template;
    if (template == null || _selectedShapeIds.isEmpty) {
      return;
    }
    final shapes = [...template.shapes];
    for (var index = shapes.length - 2; index >= 0; index--) {
      final current = shapes[index];
      final next = shapes[index + 1];
      if (_selectedShapeIds.contains(current.id) &&
          !_selectedShapeIds.contains(next.id)) {
        shapes[index] = next;
        shapes[index + 1] = current;
      }
    }
    _applyTemplateMutation(() => _template = template.copyWith(shapes: shapes));
  }

  void _sendSelectedBackward() {
    final template = _template;
    if (template == null || _selectedShapeIds.isEmpty) {
      return;
    }
    final shapes = [...template.shapes];
    for (var index = 1; index < shapes.length; index++) {
      final current = shapes[index];
      final previous = shapes[index - 1];
      if (_selectedShapeIds.contains(current.id) &&
          !_selectedShapeIds.contains(previous.id)) {
        shapes[index] = previous;
        shapes[index - 1] = current;
      }
    }
    _applyTemplateMutation(() => _template = template.copyWith(shapes: shapes));
  }

  void _bringSelectedToFront() {
    final template = _template;
    if (template == null || _selectedShapeIds.isEmpty) {
      return;
    }
    final unselected = template.shapes
        .where((shape) => !_selectedShapeIds.contains(shape.id))
        .toList(growable: false);
    final selected = template.shapes
        .where((shape) => _selectedShapeIds.contains(shape.id))
        .toList(growable: false);
    _applyTemplateMutation(() {
      _template = template.copyWith(shapes: [...unselected, ...selected]);
    });
  }

  void _sendSelectedToBack() {
    final template = _template;
    if (template == null || _selectedShapeIds.isEmpty) {
      return;
    }
    final selected = template.shapes
        .where((shape) => _selectedShapeIds.contains(shape.id))
        .toList(growable: false);
    final unselected = template.shapes
        .where((shape) => !_selectedShapeIds.contains(shape.id))
        .toList(growable: false);
    _applyTemplateMutation(() {
      _template = template.copyWith(shapes: [...selected, ...unselected]);
    });
  }

  void _duplicateSelectedShapes() {
    final template = _template;
    if (template == null || _selectedShapeIds.isEmpty) {
      return;
    }
    final duplicates = template.shapes
        .where((shape) => _selectedShapeIds.contains(shape.id))
        .map(
          (shape) => shape.copyWith(
            id: '${shape.id}-${DateTime.now().microsecondsSinceEpoch}-${shape.hashCode}',
            x: shape.x + 12,
            y: shape.y + 12,
          ),
        )
        .toList(growable: false);
    _applyTemplateMutation(() {
      _template = template.copyWith(
        shapes: [...template.shapes, ...duplicates],
      );
      _selectedShapeIds = duplicates.map((shape) => shape.id).toSet();
      _selectedShapeId = duplicates.isEmpty ? null : duplicates.last.id;
    });
  }

  Future<Uint8List?> _capturePreviewPng({double? pixelRatio}) async {
    await SchedulerBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 32));
    await SchedulerBinding.instance.endOfFrame;
    final boundary =
        _pdfPreviewBoundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      return null;
    }
    final resolvedPixelRatio =
        pixelRatio ??
        switch (defaultTargetPlatform) {
          // ~300 DPI output for screenshot fallback PDFs.
          TargetPlatform.macOS => 4.2,
          TargetPlatform.windows => 4.2,
          _ => 4.5,
        };
    final image = await boundary
        .toImage(pixelRatio: resolvedPixelRatio)
        .timeout(
          const Duration(seconds: 8),
          onTimeout: () => throw Exception(
            'Preview capture timed out. Please wait for the preview to finish rendering and try again.',
          ),
        );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  PdfPageFormat _pageFormatForTemplate(DocumentPrintTemplate template) {
    return PdfPageFormat(template.pageWidth, template.pageHeight, marginAll: 0);
  }

  Future<Uint8List?> _buildPdfBytes() async {
    final template = _template;
    if (template == null) {
      return null;
    }

    try {
      final vector = await _buildTemplateVectorPdfBytes(template);
      if (vector != null) {
        return vector;
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Vector PDF generation failed, using high-res fallback: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }

    final png = await _capturePreviewPng();
    if (png != null) {
      final document = pw.Document();
      final image = pw.MemoryImage(png);
      final format = _pageFormatForTemplate(template);
      document.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.zero,
          build: (_) =>
              pw.SizedBox.expand(child: pw.Image(image, fit: pw.BoxFit.fill)),
        ),
      );
      return document.save();
    }

    return _buildTemplateVectorPdfBytes(template);
  }

  Future<Uint8List?> _buildTemplateVectorPdfBytes(
    DocumentPrintTemplate template,
  ) async {
    final data = _documentDataJson;
    final pdf = pw.Document();
    final imageCache = <String, pw.ImageProvider?>{};
    final pageFormat = _pageFormatForTemplate(template);
    pw.ImageProvider? backgroundImage;
    final backgroundPath = resolvePrintTemplateText(
      template.backgroundImagePath ?? '',
      data,
    );
    if (backgroundPath.trim().isNotEmpty) {
      backgroundImage = await _pdfImageProviderForSource(
        backgroundPath,
        imageCache,
      );
    }

    final children = <pw.Widget>[];
    if (backgroundImage != null) {
      children.add(
        pw.Positioned.fill(
          child: pw.Opacity(
            opacity: template.backgroundOpacity.clamp(0.0, 1.0),
            child: pw.Image(backgroundImage, fit: pw.BoxFit.cover),
          ),
        ),
      );
    }

    for (final shape in template.shapes) {
      if (!shape.visible) {
        continue;
      }
      final shapeWidget = await _buildPdfShapeWidget(
        shape,
        data,
        imageCache,
        template: template,
      );
      if (shapeWidget == null) {
        continue;
      }
      children.add(
        pw.Positioned(
          left: shape.x,
          top: shape.y,
          child: pw.SizedBox(
            width: math.max(1, shape.width),
            height: math.max(1, shape.height),
            child: shapeWidget,
          ),
        ),
      );
    }

    final watermarkText = _watermarkText;
    if (watermarkText.isNotEmpty) {
      children.add(
        pw.Positioned.fill(
          child: pw.Center(
            child: pw.Transform.rotate(
              angle: -math.pi / 5,
              child: pw.Opacity(
                opacity: 0.18,
                child: pw.Text(
                  watermarkText,
                  style: pw.TextStyle(
                    fontSize: math.max(
                      72,
                      math.min(template.pageWidth, template.pageHeight) * 0.16,
                    ),
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red300,
                    letterSpacing: 8,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Stack(children: children),
      ),
    );

    return pdf.save();
  }

  Future<_PdfFontBundle> _pdfFontBundleForFamily(String? fontFamily) {
    final family = normalizeDocumentPrintFontFamily(fontFamily);
    return _pdfFontBundleCache.putIfAbsent(
      family,
      () => switch (family) {
        'times_new_roman' => _loadPdfFontBundle(
          regular: 'assets/fonts/Times New Roman.ttf',
          bold: 'assets/fonts/Times New Roman Bold.ttf',
          italic: 'assets/fonts/Times New Roman Italic.ttf',
          boldItalic: 'assets/fonts/Times New Roman Bold Italic.ttf',
        ),
        'verdana' => _loadPdfFontBundle(
          regular: 'assets/fonts/Verdana.ttf',
          bold: 'assets/fonts/Verdana Bold.ttf',
          italic: 'assets/fonts/Verdana Italic.ttf',
          boldItalic: 'assets/fonts/Verdana Bold Italic.ttf',
        ),
        'trebuchet_ms' => _loadPdfFontBundle(
          regular: 'assets/fonts/Trebuchet MS.ttf',
          bold: 'assets/fonts/Trebuchet MS Bold.ttf',
          italic: 'assets/fonts/Trebuchet MS Italic.ttf',
          boldItalic: 'assets/fonts/Trebuchet MS Bold Italic.ttf',
        ),
        'georgia' => _loadPdfFontBundle(
          regular: 'assets/fonts/Georgia.ttf',
          bold: 'assets/fonts/Georgia Bold.ttf',
          italic: 'assets/fonts/Georgia Italic.ttf',
          boldItalic: 'assets/fonts/Georgia Bold Italic.ttf',
        ),
        'default' => Future.value(
          const _PdfFontBundle(
            regular: null,
            bold: null,
            italic: null,
            boldItalic: null,
          ),
        ),
        _ => _loadPdfFontBundle(
          regular: 'assets/fonts/Arial.ttf',
          bold: 'assets/fonts/Arial Bold.ttf',
          italic: 'assets/fonts/Arial Italic.ttf',
          boldItalic: 'assets/fonts/Arial Bold Italic.ttf',
        ),
      },
    );
  }

  Future<_PdfFontBundle> _loadPdfFontBundle({
    required String regular,
    required String bold,
    required String italic,
    required String boldItalic,
  }) async {
    final fonts = await Future.wait<pw.Font>([
      _loadPdfFontAsset(regular),
      _loadPdfFontAsset(bold),
      _loadPdfFontAsset(italic),
      _loadPdfFontAsset(boldItalic),
    ]);
    return _PdfFontBundle(
      regular: fonts[0],
      bold: fonts[1],
      italic: fonts[2],
      boldItalic: fonts[3],
    );
  }

  Future<pw.Font> _loadPdfFontAsset(String path) async {
    final data = await rootBundle.load(path);
    return pw.Font.ttf(data);
  }

  Future<pw.Font> _loadPdfUnicodeFallbackFont() {
    return _pdfUnicodeFallbackFont ??= _loadPdfFontAsset(
      'assets/fonts/Arial Unicode.ttf',
    );
  }

  pw.Font _pdfFontForTemplate(
    _PdfFontBundle fontBundle, {
    bool bold = false,
    bool italic = false,
  }) {
    if (bold && italic) {
      return fontBundle.boldItalic ?? pw.Font.helveticaBoldOblique();
    }
    if (bold) {
      return fontBundle.bold ?? pw.Font.helveticaBold();
    }
    if (italic) {
      return fontBundle.italic ?? pw.Font.helveticaOblique();
    }
    return fontBundle.regular ?? pw.Font.helvetica();
  }

  pw.TextStyle _pdfTextStyleForTemplate(
    _PdfFontBundle fontBundle, {
    required double fontSize,
    required PdfColor color,
    List<pw.Font> fontFallback = const <pw.Font>[],
    bool bold = false,
    bool italic = false,
    double letterSpacing = 0,
    double lineHeight = 1.0,
    pw.TextDecoration decoration = pw.TextDecoration.none,
  }) {
    return pw.TextStyle(
      font: _pdfFontForTemplate(fontBundle, bold: bold, italic: italic),
      fontSize: fontSize,
      color: color,
      fontFallback: fontFallback,
      letterSpacing: letterSpacing,
      height: lineHeight,
      decoration: decoration,
    );
  }

  Future<pw.Widget?> _buildPdfShapeWidget(
    DocumentPrintShape shape,
    Map<String, dynamic> data,
    Map<String, pw.ImageProvider?> imageCache, {
    required DocumentPrintTemplate template,
  }) async {
    final fontBundle = await _pdfFontBundleForFamily(
      _shapeFontFamily(template, shape),
    );
    final unicodeFallbackFont = await _loadPdfUnicodeFallbackFont();
    switch (shape.type) {
      case 'rectangle':
        return pw.Container(
          decoration: pw.BoxDecoration(
            color: _pdfFillColor(shape),
            border: pw.Border.all(
              color: _pdfColor(shape.strokeColor),
              width: math.max(0, shape.strokeWidth),
            ),
            borderRadius: pw.BorderRadius.circular(shape.borderRadius),
          ),
        );
      case 'ellipse':
        return pw.Container(
          child: pw.CustomPaint(
            size: PdfPoint(shape.width, shape.height),
            painter: (canvas, size) {
              canvas
                ..saveContext()
                ..setLineWidth(math.max(0, shape.strokeWidth))
                ..setStrokeColor(_pdfColor(shape.strokeColor));
              final fill = _pdfFillColor(shape);
              if (fill != null) {
                canvas.setFillColor(fill);
              }
              canvas.drawEllipse(
                size.x / 2,
                size.y / 2,
                size.x / 2,
                size.y / 2,
              );
              if (fill != null) {
                canvas.fillAndStrokePath();
              } else {
                canvas.strokePath();
              }
              canvas.restoreContext();
            },
          ),
        );
      case 'polygon':
        return pw.CustomPaint(
          size: PdfPoint(shape.width, shape.height),
          painter: (canvas, size) {
            final points = _pdfPolygonPoints(size, shape.sides);
            canvas
              ..saveContext()
              ..setLineWidth(math.max(0, shape.strokeWidth))
              ..setStrokeColor(_pdfColor(shape.strokeColor));
            final fill = _pdfFillColor(shape);
            if (fill != null) {
              canvas.setFillColor(fill);
            }
            canvas.moveTo(points.first.x, size.y - points.first.y);
            for (final point in points.skip(1)) {
              canvas.lineTo(point.x, size.y - point.y);
            }
            canvas.closePath();
            if (fill != null) {
              canvas.fillAndStrokePath();
            } else {
              canvas.strokePath();
            }
            canvas.restoreContext();
          },
        );
      case 'line':
        return pw.CustomPaint(
          size: PdfPoint(shape.width, shape.height == 0 ? 1 : shape.height),
          painter: (canvas, size) {
            canvas
              ..saveContext()
              ..setLineWidth(math.max(0, shape.strokeWidth))
              ..setStrokeColor(_pdfColor(shape.strokeColor))
              ..drawLine(0, 0, size.x, size.y)
              ..strokePath()
              ..restoreContext();
          },
        );
      case 'table':
        return _buildPdfTableWidget(
          shape,
          data,
          template: template,
          fontBundle: fontBundle,
        );
      case 'image':
        final source = resolvePrintTemplateText(shape.assetPath, data);
        final image = await _pdfImageProviderForSource(source, imageCache);
        if (image == null) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F8FAFC'),
              border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
            ),
            child: pw.Center(
              child: pw.Text(
                'Image',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ),
          );
        }
        return pw.Container(
          decoration: shape.strokeWidth > 0
              ? pw.BoxDecoration(
                  border: pw.Border.all(
                    color: _pdfColor(shape.strokeColor),
                    width: math.max(0, shape.strokeWidth),
                  ),
                )
              : null,
          child: pw.Image(image, fit: _pdfImageFit(shape.imageFit)),
        );
      case 'barcode':
        final value = resolvePrintTemplateText(shape.text, data).trim();
        if (value.isEmpty) {
          return null;
        }
        return pw.BarcodeWidget(
          data: value,
          barcode: shape.barcodeType == 'qr'
              ? pw.Barcode.qrCode()
              : pw.Barcode.code128(),
          color: _pdfColor(shape.strokeColor),
          backgroundColor: _pdfFillColor(shape),
          width: shape.width,
          height: shape.height,
          drawText: shape.barcodeType != 'qr',
          textStyle: _pdfTextStyleForTemplate(
            fontBundle,
            fontSize: math.max(7, shape.fontSize),
            color: _pdfColor(shape.strokeColor),
            fontFallback: <pw.Font>[unicodeFallbackFont],
            letterSpacing: shape.letterSpacing,
            lineHeight: shape.lineHeight,
          ),
        );
      case 'text':
      default:
        final text = resolvePrintTemplateText(shape.text, data);
        return pw.Container(
          padding: pw.EdgeInsets.zero,
          decoration: shape.fillAlpha > 0
              ? pw.BoxDecoration(
                  color: _pdfFillColor(shape),
                  borderRadius: pw.BorderRadius.circular(shape.borderRadius),
                )
              : null,
          alignment: _pdfAlignment(shape.align),
          child: pw.Text(
            text,
            textAlign: _pdfTextAlign(shape.align),
            maxLines: shape.multiline ? null : 1,
            style: _pdfTextStyleForTemplate(
              fontBundle,
              color: _pdfColor(shape.strokeColor),
              fontSize: math.max(6, shape.fontSize),
              fontFallback: <pw.Font>[unicodeFallbackFont],
              bold: shape.bold,
              italic: shape.italic,
              letterSpacing: shape.letterSpacing,
              lineHeight: shape.lineHeight,
              decoration: shape.underline
                  ? pw.TextDecoration.underline
                  : pw.TextDecoration.none,
            ),
          ),
        );
    }
  }

  pw.Widget _buildPdfTableWidget(
    DocumentPrintShape shape,
    Map<String, dynamic> data, {
    required DocumentPrintTemplate template,
    required _PdfFontBundle fontBundle,
  }) {
    final rawRows =
        resolvePrintPath(data, shape.dataPath) as List<dynamic>? ??
        const <dynamic>[];
    final columns = shape.columns.isEmpty
        ? DocumentPrintShape.defaultTableColumns()
        : shape.columns;
    final visibleRows = <Map<String, dynamic>>[];
    final double headerHeight = shape.printHeader
        ? math.max(8.0, shape.titleHeight)
        : 0.0;
    final totalWeight = columns.fold<double>(
      0,
      (sum, column) => sum + column.widthFactor,
    );
    final bool useFullHeight = isPrintLinesTableShape(shape);
    final double availableBottomLimit = shape.printTotal && useFullHeight
        ? shape.height - headerHeight
        : shape.height;
    var usedHeight = headerHeight;

    for (final row in rawRows) {
      if (row is! Map<String, dynamic>) {
        continue;
      }
      if (!printTableRowHasVisibleValues(row, columns)) {
        continue;
      }
      final rowHeight = measurePrintTableRowHeight(
        row,
        columns,
        shape.width,
        shape,
        fontFamily: _shapeFontFamily(template, shape),
      );
      if (usedHeight + rowHeight > availableBottomLimit + 1.0) {
        break;
      }
      visibleRows.add(row);
      usedHeight += rowHeight;
    }

    final double strokeWidth = math.max(0, shape.strokeWidth);
    final columnWidths = <double>[
      for (final column in columns)
        shape.width *
            (totalWeight > 0 ? column.widthFactor / totalWeight : 0.0),
    ];
    final totals = shape.printTotal
        ? _calculatePdfColumnTotals(visibleRows, columns)
        : const <String, double>{};
    final double totalRowTop = useFullHeight
        ? shape.height - headerHeight
        : usedHeight;
    final double contentBottom = useFullHeight
        ? shape.height
        : (totals.isNotEmpty
              ? totalRowTop + headerHeight
              : math.max(usedHeight, shape.printHeader ? headerHeight : 0.0));
    final children = <pw.Widget>[];

    final fillColor = _pdfFillColor(shape);
    if (fillColor != null) {
      children.add(pw.Positioned.fill(child: pw.Container(color: fillColor)));
    }

    if (shape.printHeader) {
      children.add(
        pw.Positioned(
          left: 0,
          top: 0,
          child: pw.SizedBox(
            width: shape.width,
            height: headerHeight,
            child: pw.Container(color: _pdfColor(shape.headerColor)),
          ),
        ),
      );
      children.add(
        _buildPdfTableRowLayer(
          shape: shape,
          fontBundle: fontBundle,
          top: 0,
          height: headerHeight.toDouble(),
          columns: columns,
          columnWidths: columnWidths,
          values: columns.map((column) => column.label).toList(growable: false),
          textColor: _pdfColor(shape.headerTextColor),
          fontSize: math.max(7, shape.fontSize + 1),
          bold: true,
          padding: math.max(2.0, shape.cellGap),
          alignments: columns
              .map((column) => column.titleAlign)
              .toList(growable: false),
        ),
      );
      children.add(
        _buildPdfHorizontalRule(
          top: headerHeight,
          width: shape.width,
          color: _pdfColor(shape.strokeColor),
          strokeWidth: strokeWidth,
        ),
      );
    }

    var currentTop = headerHeight;
    for (final row in visibleRows) {
      final rowHeight = measurePrintTableRowHeight(
        row,
        columns,
        shape.width,
        shape,
        fontFamily: _shapeFontFamily(template, shape),
      );
      children.add(
        _buildPdfTableRowLayer(
          shape: shape,
          fontBundle: fontBundle,
          top: currentTop,
          height: rowHeight.toDouble(),
          columns: columns,
          columnWidths: columnWidths,
          values: columns
              .map(
                (column) =>
                    resolvePrintCellValueForColumn(row, column, column.key),
              )
              .toList(growable: false),
          textColor: _pdfColor(shape.bodyTextColor),
          fontSize: math.max(6, shape.fontSize),
          padding: math.max(2.0, shape.cellGap),
          alignments: columns
              .map((column) => column.align)
              .toList(growable: false),
        ),
      );
      currentTop += rowHeight;
      children.add(
        _buildPdfHorizontalRule(
          top: currentTop,
          width: shape.width,
          color: _pdfColor(shape.strokeColor),
          strokeWidth: strokeWidth,
        ),
      );
    }

    if (totals.isNotEmpty) {
      children.add(
        pw.Positioned(
          left: 0,
          top: totalRowTop,
          child: pw.SizedBox(
            width: shape.width,
            height: headerHeight,
            child: pw.Container(color: _pdfColor(shape.headerColor)),
          ),
        ),
      );
      children.add(
        _buildPdfHorizontalRule(
          top: totalRowTop,
          width: shape.width,
          color: _pdfColor(shape.strokeColor),
          strokeWidth: strokeWidth,
        ),
      );
      children.add(
        _buildPdfTableRowLayer(
          shape: shape,
          fontBundle: fontBundle,
          top: totalRowTop,
          height: headerHeight.toDouble(),
          columns: columns,
          columnWidths: columnWidths,
          values: [
            for (var i = 0; i < columns.length; i++)
              i == 0
                  ? 'Total'
                  : (totals[columns[i].key] == null
                        ? ''
                        : formatPrintValueForKey(
                            columns[i].key,
                            totals[columns[i].key]!,
                            columnNumberFormat: columns[i].numberFormat,
                          )),
          ],
          textColor: _pdfColor(shape.headerTextColor),
          fontSize: math.max(6, shape.fontSize),
          bold: true,
          padding: math.max(2.0, shape.cellGap),
          alignments: [
            'left',
            ...columns.skip(1).map((column) => column.align),
          ],
        ),
      );
      children.add(
        _buildPdfHorizontalRule(
          top: totalRowTop + headerHeight,
          width: shape.width,
          color: _pdfColor(shape.strokeColor),
          strokeWidth: strokeWidth,
        ),
      );
    }

    var cursorX = 0.0;
    for (var i = 0; i < columnWidths.length; i++) {
      if (i > 0) {
        children.add(
          _buildPdfVerticalRule(
            left: cursorX,
            top: 0,
            height: contentBottom,
            color: _pdfColor(shape.strokeColor),
            strokeWidth: strokeWidth,
          ),
        );
      }
      cursorX += columnWidths[i];
    }

    children.add(
      pw.Positioned(
        left: 0,
        top: 0,
        child: pw.SizedBox(
          width: shape.width,
          height: contentBottom,
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: _pdfColor(shape.strokeColor),
                width: strokeWidth,
              ),
            ),
          ),
        ),
      ),
    );

    return pw.ClipRect(
      child: pw.SizedBox(
        width: shape.width,
        height: shape.height,
        child: pw.Stack(children: children),
      ),
    );
  }

  pw.Widget _buildPdfTableRowLayer({
    required DocumentPrintShape shape,
    required _PdfFontBundle fontBundle,
    required double top,
    required double height,
    required List<DocumentPrintColumn> columns,
    required List<double> columnWidths,
    required List<String> values,
    required PdfColor textColor,
    required double fontSize,
    required double padding,
    List<String>? alignments,
    bool bold = false,
  }) {
    var cursorX = 0.0;
    final children = <pw.Widget>[];
    for (var i = 0; i < columns.length; i++) {
      final columnWidth = columnWidths[i];
      children.add(
        pw.Positioned(
          left: cursorX,
          top: top,
          child: pw.SizedBox(
            width: columnWidth,
            height: height,
            child: pw.Padding(
              padding: pw.EdgeInsets.symmetric(horizontal: padding),
              child: pw.Align(
                alignment: _pdfTableCellAlignment(
                  alignments == null ? columns[i].align : alignments[i],
                ),
                child: pw.Text(
                  i < values.length ? values[i] : '',
                  textAlign: _pdfTextAlign(
                    alignments == null ? columns[i].align : alignments[i],
                  ),
                  style: _pdfTextStyleForTemplate(
                    fontBundle,
                    fontSize: fontSize,
                    color: textColor,
                    bold: bold,
                    letterSpacing: shape.letterSpacing,
                    lineHeight: shape.lineHeight,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      cursorX += columnWidth;
    }
    return pw.Stack(children: children);
  }

  pw.Widget _buildPdfHorizontalRule({
    required double top,
    required double width,
    required PdfColor color,
    required double strokeWidth,
  }) {
    return pw.Positioned(
      left: 0,
      top: math.max(0, top - (strokeWidth / 2)),
      child: pw.SizedBox(
        width: width,
        height: strokeWidth,
        child: pw.Container(color: color),
      ),
    );
  }

  pw.Widget _buildPdfVerticalRule({
    required double left,
    required double top,
    required double height,
    required PdfColor color,
    required double strokeWidth,
  }) {
    return pw.Positioned(
      left: math.max(0, left - (strokeWidth / 2)),
      top: top,
      child: pw.SizedBox(
        width: strokeWidth,
        height: height,
        child: pw.Container(color: color),
      ),
    );
  }

  Future<pw.ImageProvider?> _pdfImageProviderForSource(
    String source,
    Map<String, pw.ImageProvider?> cache,
  ) async {
    final resolved = resolvePrintImageSource(source);
    if (resolved == null || resolved.trim().isEmpty) {
      return null;
    }
    if (cache.containsKey(resolved)) {
      return cache[resolved];
    }

    pw.ImageProvider? image;
    try {
      if (resolved.startsWith('assets/')) {
        final bytes = await rootBundle.load(resolved);
        image = pw.MemoryImage(bytes.buffer.asUint8List());
      } else {
        image = await networkImage(resolved);
      }
    } catch (_) {
      image = null;
    }

    cache[resolved] = image;
    return image;
  }

  PdfColor _pdfColor(int color) {
    final a = ((color >> 24) & 0xFF) / 255.0;
    final r = ((color >> 16) & 0xFF) / 255.0;
    final g = ((color >> 8) & 0xFF) / 255.0;
    final b = (color & 0xFF) / 255.0;
    return PdfColor(r, g, b, a);
  }

  PdfColor? _pdfFillColor(DocumentPrintShape shape) {
    if (shape.fillAlpha <= 0) {
      return null;
    }
    final base = _pdfColor(shape.fillColor);
    return PdfColor(base.red, base.green, base.blue, shape.fillAlpha);
  }

  List<PdfPoint> _pdfPolygonPoints(PdfPoint size, int sides) {
    final safeSides = sides.clamp(3, 12);
    final center = PdfPoint(size.x / 2, size.y / 2);
    final radius = math.min(size.x, size.y) / 2;
    return List<PdfPoint>.generate(safeSides, (index) {
      final angle = (-math.pi / 2) + ((math.pi * 2 * index) / safeSides);
      return PdfPoint(
        center.x + (radius * math.cos(angle)),
        center.y + (radius * math.sin(angle)),
      );
    }, growable: false);
  }

  pw.Alignment _pdfAlignment(String align) {
    switch (align) {
      case 'center':
        return pw.Alignment.topCenter;
      case 'right':
        return pw.Alignment.topRight;
      default:
        return pw.Alignment.topLeft;
    }
  }

  pw.TextAlign _pdfTextAlign(String align) {
    switch (align) {
      case 'center':
        return pw.TextAlign.center;
      case 'right':
        return pw.TextAlign.right;
      default:
        return pw.TextAlign.left;
    }
  }

  String _shapeFontFamily(
    DocumentPrintTemplate template,
    DocumentPrintShape shape,
  ) {
    return effectiveDocumentPrintFontFamily(
      template.fontFamily,
      shape.fontFamily,
    );
  }

  pw.BoxFit _pdfImageFit(String value) {
    switch (normalizeDocumentPrintImageFit(value)) {
      case 'cover':
        return pw.BoxFit.cover;
      case 'fill':
        return pw.BoxFit.fill;
      case 'contain':
      default:
        return pw.BoxFit.contain;
    }
  }

  pw.Alignment _pdfTableCellAlignment(String align) {
    switch (align) {
      case 'right':
        return pw.Alignment.centerRight;
      case 'center':
        return pw.Alignment.center;
      default:
        return pw.Alignment.centerLeft;
    }
  }

  Map<String, double> _calculatePdfColumnTotals(
    List<Map<String, dynamic>> rows,
    List<DocumentPrintColumn> columns,
  ) {
    final totals = <String, double>{};
    final totalColumns = columns.where((column) => column.totalColumn);
    for (final row in rows) {
      for (final column in totalColumns) {
        final value = resolvePrintPath(row, column.key);
        if (value is num) {
          totals[column.key] = (totals[column.key] ?? 0) + value.toDouble();
        } else {
          final parsed = double.tryParse(value?.toString() ?? '');
          if (parsed != null) {
            totals[column.key] = (totals[column.key] ?? 0) + parsed;
          }
        }
      }
    }
    return totals;
  }

  Future<void> _printPdf() async {
    _controller.updateState(() => _printingPdf = true);
    try {
      final bytes = await _buildPdfBytes();
      if (bytes == null) {
        throw Exception('Unable to capture print preview.');
      }
      if (kIsWeb) {
        await printPdfBytes(bytes, title: widget.title);
        return;
      }
      await Printing.layoutPdf(
        name: '${widget.title}.pdf',
        onLayout: (_) async => bytes,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception(
          'Print dialog timed out. Please check macOS printer access and try again.',
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Print failed: $error')));
      }
    } finally {
      if (mounted) {
        _controller.updateState(() => _printingPdf = false);
      }
    }
  }

  Future<void> _downloadPdf() async {
    _controller.updateState(() => _downloadingPdf = true);
    try {
      final bytes = await _buildPdfBytes();
      if (bytes == null) {
        throw Exception('Unable to generate PDF from preview.');
      }
      if (kIsWeb) {
        final saved = await saveBytesFile(
          suggestedName: '${widget.title}.pdf',
          bytes: bytes,
          mimeType: 'application/pdf',
        );
        if (!saved) {
          throw Exception('PDF download was cancelled.');
        }
        return;
      }
      await Printing.sharePdf(bytes: bytes, filename: '${widget.title}.pdf');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF download failed: $error')));
      }
    } finally {
      if (mounted) {
        _controller.updateState(() => _downloadingPdf = false);
      }
    }
  }

  Future<void> _sendPdf() async {
    if (widget.onPdfReady == null) {
      return;
    }
    _controller.updateState(() => _sendingPdf = true);
    try {
      final bytes = await _buildPdfBytes();
      if (bytes == null) {
        throw Exception('Unable to generate PDF from preview.');
      }
      await widget.onPdfReady!(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF email request completed.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF email failed: $error')));
      }
    } finally {
      if (mounted) {
        _controller.updateState(() => _sendingPdf = false);
      }
    }
  }
}

class _DesignerCanvas extends StatefulWidget {
  const _DesignerCanvas({
    required this.template,
    required this.documentData,
    required this.watermarkText,
    required this.editMode,
    required this.selectedShapeId,
    required this.selectedShapeIds,
    required this.zoom,
    required this.onSelectShape,
    required this.onMoveShape,
    required this.onResizeShape,
    required this.onMoveStart,
    required this.onMoveEnd,
    required this.onResizeStart,
    required this.onResizeEnd,
    required this.operation,
    required this.draftShape,
    required this.onDrawStart,
    required this.onDrawUpdate,
    required this.onDrawEnd,
    required this.onDrawTap,
  });

  final DocumentPrintTemplate template;
  final Map<String, dynamic> documentData;
  final String watermarkText;
  final bool editMode;
  final String? selectedShapeId;
  final Set<String> selectedShapeIds;
  final double zoom;
  final ValueChanged<String?> onSelectShape;
  final void Function(String shapeId, Offset delta) onMoveShape;
  final void Function(String shapeId, Offset delta) onResizeShape;
  final VoidCallback onMoveStart;
  final VoidCallback onMoveEnd;
  final VoidCallback onResizeStart;
  final VoidCallback onResizeEnd;
  final _DesignerOperation operation;
  final DocumentPrintShape? draftShape;
  final ValueChanged<Offset> onDrawStart;
  final ValueChanged<Offset> onDrawUpdate;
  final VoidCallback onDrawEnd;
  final ValueChanged<Offset> onDrawTap;

  @override
  State<_DesignerCanvas> createState() => _DesignerCanvasState();
}

class _DesignerCanvasState extends State<_DesignerCanvas> {
  late final ScrollController _horizontalController;
  late final ScrollController _verticalController;

  @override
  void initState() {
    super.initState();
    _horizontalController = ScrollController();
    _verticalController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fitScale = math.min(
          (constraints.maxWidth - 24) / widget.template.pageWidth,
          (constraints.maxHeight - 24) / widget.template.pageHeight,
        );
        final baseScale = math.max(0.45, fitScale);
        final scale = (baseScale * widget.zoom).clamp(0.45, 2.5);

        return Scrollbar(
          controller: _verticalController,
          thumbVisibility: true,
          child: Scrollbar(
            controller: _horizontalController,
            thumbVisibility: true,
            notificationPredicate: (notification) =>
                notification.metrics.axis == Axis.horizontal,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                controller: _verticalController,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: math.max(0, constraints.maxWidth - 24),
                    minHeight: math.max(0, constraints.maxHeight - 24),
                  ),
                  child: Center(
                    child: GestureDetector(
                      onTap: () => widget.onSelectShape(null),
                      child: _DocumentPageSurface(
                        template: widget.template,
                        documentData: widget.documentData,
                        watermarkText: widget.watermarkText,
                        scale: scale,
                        editMode: widget.editMode,
                        selectedShapeId: widget.selectedShapeId,
                        selectedShapeIds: widget.selectedShapeIds,
                        onSelectShape: widget.onSelectShape,
                        onMoveShape: widget.onMoveShape,
                        onResizeShape: widget.onResizeShape,
                        onMoveStart: widget.onMoveStart,
                        onMoveEnd: widget.onMoveEnd,
                        onResizeStart: widget.onResizeStart,
                        onResizeEnd: widget.onResizeEnd,
                        operation: widget.operation,
                        draftShape: widget.draftShape,
                        onDrawStart: widget.onDrawStart,
                        onDrawUpdate: widget.onDrawUpdate,
                        onDrawEnd: widget.onDrawEnd,
                        onDrawTap: widget.onDrawTap,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DocumentPageSurface extends StatelessWidget {
  const _DocumentPageSurface({
    required this.template,
    required this.documentData,
    required this.watermarkText,
    required this.scale,
    required this.editMode,
    required this.selectedShapeId,
    required this.selectedShapeIds,
    required this.onSelectShape,
    required this.onMoveShape,
    required this.onResizeShape,
    required this.onMoveStart,
    required this.onMoveEnd,
    required this.onResizeStart,
    required this.onResizeEnd,
    this.showDecoration = true,
    this.operation = _DesignerOperation.select,
    this.draftShape,
    this.onDrawStart,
    this.onDrawUpdate,
    this.onDrawEnd,
    this.onDrawTap,
  });

  final DocumentPrintTemplate template;
  final Map<String, dynamic> documentData;
  final String watermarkText;
  final double scale;
  final bool editMode;
  final String? selectedShapeId;
  final Set<String> selectedShapeIds;
  final ValueChanged<String?> onSelectShape;
  final void Function(String shapeId, Offset delta) onMoveShape;
  final void Function(String shapeId, Offset delta) onResizeShape;
  final VoidCallback onMoveStart;
  final VoidCallback onMoveEnd;
  final VoidCallback onResizeStart;
  final VoidCallback onResizeEnd;
  final bool showDecoration;
  final _DesignerOperation operation;
  final DocumentPrintShape? draftShape;
  final ValueChanged<Offset>? onDrawStart;
  final ValueChanged<Offset>? onDrawUpdate;
  final VoidCallback? onDrawEnd;
  final ValueChanged<Offset>? onDrawTap;

  @override
  Widget build(BuildContext context) {
    final canvasWidth = template.pageWidth * scale;
    final canvasHeight = template.pageHeight * scale;

    return Container(
      width: canvasWidth,
      height: canvasHeight,
      decoration: showDecoration
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            )
          : const BoxDecoration(color: Colors.white),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: operation.isDrawTool
            ? (details) =>
                  onDrawStart?.call(_toDocumentOffset(details.localPosition))
            : null,
        onPanUpdate: operation.isDrawTool
            ? (details) =>
                  onDrawUpdate?.call(_toDocumentOffset(details.localPosition))
            : null,
        onPanEnd: operation.isDrawTool ? (_) => onDrawEnd?.call() : null,
        onTapUp: operation.isDrawTool
            ? (details) =>
                  onDrawTap?.call(_toDocumentOffset(details.localPosition))
            : null,
        child: Stack(
          children: [
            if ((template.backgroundImagePath ?? '').trim().isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: template.backgroundOpacity.clamp(0.0, 1.0),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: _DocumentImageShape(
                        source: resolvePrintTemplateText(
                          template.backgroundImagePath ?? '',
                          documentData,
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: CustomPaint(
                painter: DocumentCanvasPainter(
                  template: template,
                  documentData: documentData,
                  scale: scale,
                  showPageChrome: showDecoration,
                  showHiddenPlaceholders: editMode,
                  draftShape: draftShape,
                ),
              ),
            ),
            ...template.shapes
                .where(
                  (shape) =>
                      shape.type == 'image' && (shape.visible || editMode),
                )
                .map(
                  (shape) => Positioned(
                    left: shape.x * scale,
                    top: shape.y * scale,
                    width: math.max(24, shape.width * scale),
                    height: math.max(24, shape.height * scale),
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: shape.visible ? 1.0 : 0.2,
                        child: DecoratedBox(
                          decoration: shape.strokeWidth > 0
                              ? BoxDecoration(
                                  border: Border.all(
                                    color: Color(shape.strokeColor),
                                    width: shape.strokeWidth * scale,
                                  ),
                                )
                              : const BoxDecoration(),
                          child: _DocumentImageShape(
                            source: resolvePrintTemplateText(
                              shape.assetPath,
                              documentData,
                            ),
                            fit: flutterDocumentPrintImageFit(shape.imageFit),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            if (watermarkText.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Transform.rotate(
                      angle: -math.pi / 5,
                      child: Opacity(
                        opacity: 0.18,
                        child: Text(
                          watermarkText,
                          style: TextStyle(
                            color: const Color(0xFFD32F2F),
                            fontSize: math.max(
                              48,
                              math.min(
                                    template.pageWidth,
                                    template.pageHeight,
                                  ) *
                                  scale *
                                  0.16,
                            ),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (editMode)
              ...template.shapes.map((shape) {
                final isSelected =
                    selectedShapeIds.contains(shape.id) ||
                    shape.id == selectedShapeId;
                return Positioned(
                  left: shape.x * scale,
                  top: shape.y * scale,
                  width: math.max(24, shape.width * scale),
                  height: math.max(24, shape.height * scale),
                  child: _ShapeSelectionOverlay(
                    selected: isSelected,
                    operation: operation,
                    onTap: () => onSelectShape(shape.id),
                    onMove: (delta) => onMoveShape(shape.id, delta),
                    onResize: (delta) => onResizeShape(shape.id, delta),
                    onMoveStart: onMoveStart,
                    onMoveEnd: onMoveEnd,
                    onResizeStart: onResizeStart,
                    onResizeEnd: onResizeEnd,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Offset _toDocumentOffset(Offset point) {
    return Offset(
      (point.dx / scale).clamp(0.0, template.pageWidth),
      (point.dy / scale).clamp(0.0, template.pageHeight),
    );
  }
}

class _ShapeSelectionOverlay extends StatelessWidget {
  const _ShapeSelectionOverlay({
    required this.selected,
    required this.operation,
    required this.onTap,
    required this.onMove,
    required this.onResize,
    required this.onMoveStart,
    required this.onMoveEnd,
    required this.onResizeStart,
    required this.onResizeEnd,
  });

  final bool selected;
  final _DesignerOperation operation;
  final VoidCallback onTap;
  final ValueChanged<Offset> onMove;
  final ValueChanged<Offset> onResize;
  final VoidCallback onMoveStart;
  final VoidCallback onMoveEnd;
  final VoidCallback onResizeStart;
  final VoidCallback onResizeEnd;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onTap,
            onPanStart: (_) {
              onTap();
              if (operation == _DesignerOperation.select ||
                  operation == _DesignerOperation.move) {
                onMoveStart();
              } else if (operation == _DesignerOperation.resize) {
                onResizeStart();
              }
            },
            onPanUpdate: (details) {
              switch (operation) {
                case _DesignerOperation.select:
                case _DesignerOperation.move:
                  onMove(details.delta);
                  break;
                case _DesignerOperation.resize:
                  onResize(details.delta);
                  break;
                case _DesignerOperation.delete:
                case _DesignerOperation.drawText:
                case _DesignerOperation.drawRect:
                case _DesignerOperation.drawEllipse:
                case _DesignerOperation.drawPolygon:
                case _DesignerOperation.drawLine:
                case _DesignerOperation.drawTable:
                case _DesignerOperation.drawImage:
                case _DesignerOperation.drawBarcode:
                  break;
              }
            },
            onPanEnd: (_) {
              if (operation == _DesignerOperation.select ||
                  operation == _DesignerOperation.move) {
                onMoveEnd();
              } else if (operation == _DesignerOperation.resize) {
                onResizeEnd();
              }
            },
            onPanCancel: () {
              if (operation == _DesignerOperation.select ||
                  operation == _DesignerOperation.move) {
                onMoveEnd();
              } else if (operation == _DesignerOperation.resize) {
                onResizeEnd();
              }
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 1.5,
                ),
                color: selected
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.06)
                    : Colors.transparent,
              ),
            ),
          ),
        ),
        if (selected)
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onPanStart: (_) => onResizeStart(),
              onPanUpdate: (details) => onResize(details.delta),
              onPanEnd: (_) => onResizeEnd(),
              onPanCancel: onResizeEnd,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MultiSelectionInspector extends StatelessWidget {
  const _MultiSelectionInspector({
    required this.count,
    required this.onDelete,
    required this.onBringForward,
    required this.onSendBackward,
    required this.onBringToFront,
    required this.onSendToBack,
    required this.onDuplicate,
  });

  final int count;
  final VoidCallback onDelete;
  final VoidCallback onBringForward;
  final VoidCallback onSendBackward;
  final VoidCallback onBringToFront;
  final VoidCallback onSendToBack;
  final VoidCallback onDuplicate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Multiple Shapes', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppUiConstants.spacingSm),
        Text(
          '$count shapes selected',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppUiConstants.spacingMd),
        Wrap(
          spacing: AppUiConstants.spacingSm,
          runSpacing: AppUiConstants.spacingSm,
          children: [
            OutlinedButton.icon(
              onPressed: onSendBackward,
              icon: const Icon(Icons.arrow_downward_outlined),
              label: const Text('Send Backward'),
            ),
            OutlinedButton.icon(
              onPressed: onBringForward,
              icon: const Icon(Icons.arrow_upward_outlined),
              label: const Text('Bring Forward'),
            ),
            OutlinedButton.icon(
              onPressed: onSendToBack,
              icon: const Icon(Icons.vertical_align_bottom_outlined),
              label: const Text('Send To Back'),
            ),
            OutlinedButton.icon(
              onPressed: onBringToFront,
              icon: const Icon(Icons.vertical_align_top_outlined),
              label: const Text('Bring To Front'),
            ),
            OutlinedButton.icon(
              onPressed: onDuplicate,
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Duplicate'),
            ),
            OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingMd),
        Text(
          'Move and resize actions apply to the full selection, closer to PBS group editing.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        Text(
          'Use Cmd, Ctrl, or Shift while clicking shapes to add or remove them from the selection.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

enum _DesignerOperation {
  select,
  move,
  resize,
  delete,
  drawText,
  drawRect,
  drawEllipse,
  drawPolygon,
  drawLine,
  drawTable,
  drawImage,
  drawBarcode;

  bool get isDrawTool => shapeType != null;

  String? get shapeType {
    switch (this) {
      case _DesignerOperation.drawText:
        return 'text';
      case _DesignerOperation.drawRect:
        return 'rectangle';
      case _DesignerOperation.drawEllipse:
        return 'ellipse';
      case _DesignerOperation.drawPolygon:
        return 'polygon';
      case _DesignerOperation.drawLine:
        return 'line';
      case _DesignerOperation.drawTable:
        return 'table';
      case _DesignerOperation.drawImage:
        return 'image';
      case _DesignerOperation.drawBarcode:
        return 'barcode';
      case _DesignerOperation.select:
      case _DesignerOperation.move:
      case _DesignerOperation.resize:
      case _DesignerOperation.delete:
        return null;
    }
  }
}

class _DocumentImageShape extends StatelessWidget {
  const _DocumentImageShape({required this.source, this.fit = BoxFit.contain});

  final String source;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final resolved = resolvePrintImageSource(source);
    if (resolved == null || resolved.trim().isEmpty) {
      return _fallback();
    }
    if (resolved.startsWith('assets/')) {
      return Image.asset(
        resolved,
        fit: fit,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    return Image.network(
      resolved,
      fit: fit,
      errorBuilder: (_, _, _) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: Color(0xFF94A3B8),
        size: 28,
      ),
    );
  }
}

class DocumentCanvasPainter extends CustomPainter {
  DocumentCanvasPainter({
    required this.template,
    required this.documentData,
    required this.scale,
    this.showPageChrome = true,
    this.showHiddenPlaceholders = false,
    this.draftShape,
  });

  final DocumentPrintTemplate template;
  final Map<String, dynamic> documentData;
  final double scale;
  final bool showPageChrome;
  final bool showHiddenPlaceholders;
  final DocumentPrintShape? draftShape;

  @override
  void paint(Canvas canvas, Size size) {
    if (showPageChrome) {
      final borderPaint = Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawRect(
        (Offset.zero & size).translate(4, 4),
        Paint()
          ..color = const Color(0x0D000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4)),
        Paint()..color = Colors.white,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4)),
        borderPaint,
      );
    } else {
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    }

    if (template.showGrid) {
      _drawGrid(canvas, size);
    }

    for (final shape in template.shapes) {
      if (!shape.visible && !showHiddenPlaceholders) {
        continue;
      }
      _paintShape(canvas, shape);
    }

    if (draftShape != null) {
      _paintShape(canvas, draftShape!, draft: true);
    }
  }

  void _paintShape(
    Canvas canvas,
    DocumentPrintShape shape, {
    bool draft = false,
  }) {
    final hiddenPlaceholder =
        !shape.visible && showHiddenPlaceholders && !draft;
    final rect = Rect.fromLTWH(
      shape.x * scale,
      shape.y * scale,
      shape.width * scale,
      shape.height * scale,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(shape.borderRadius * scale),
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = hiddenPlaceholder
          ? Color(shape.strokeColor).withValues(alpha: 0.28)
          : draft
          ? Color(shape.strokeColor).withValues(alpha: 0.75)
          : Color(shape.strokeColor)
      ..strokeWidth = math.max(0, shape.strokeWidth * scale);
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = Color(shape.fillColor).withValues(
        alpha: hiddenPlaceholder
            ? math.min(0.12, math.max(0.04, shape.fillAlpha))
            : draft
            ? math.max(0.08, math.min(0.24, shape.fillAlpha + 0.12))
            : shape.fillAlpha,
      );

    switch (shape.type) {
      case 'rectangle':
        if (shape.fillAlpha > 0) {
          canvas.drawRRect(rrect, fill);
        }
        canvas.drawRRect(rrect, stroke);
        break;
      case 'ellipse':
        if (shape.fillAlpha > 0) {
          canvas.drawOval(rect, fill);
        }
        canvas.drawOval(rect, stroke);
        break;
      case 'polygon':
        final path = _polygonPath(rect, shape.sides);
        if (shape.fillAlpha > 0) {
          canvas.drawPath(path, fill);
        }
        canvas.drawPath(path, stroke);
        break;
      case 'line':
        canvas.drawLine(rect.topLeft, rect.bottomRight, stroke);
        break;
      case 'table':
        if (shape.fillAlpha > 0) {
          canvas.drawRRect(rrect, fill);
        }
        _paintTable(canvas, rect, shape);
        break;
      case 'image':
        break;
      case 'barcode':
        if (shape.fillAlpha > 0) {
          canvas.drawRRect(rrect, fill);
        }
        _paintBarcode(canvas, rect, shape);
        break;
      case 'text':
      default:
        if (shape.fillAlpha > 0) {
          canvas.drawRRect(rrect, fill);
        }
        _paintText(canvas, rect, shape);
        break;
    }
  }

  Path _polygonPath(Rect rect, int sides) {
    final safeSides = sides.clamp(3, 12);
    final center = rect.center;
    final radius = math.min(rect.width, rect.height) / 2;
    final path = Path();
    for (var index = 0; index < safeSides; index++) {
      final angle = (-math.pi / 2) + ((math.pi * 2 * index) / safeSides);
      final point = Offset(
        center.dx + (radius * math.cos(angle)),
        center.dy + (radius * math.sin(angle)),
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  void _paintText(Canvas canvas, Rect rect, DocumentPrintShape shape) {
    final text = resolvePrintTemplateText(shape.text, documentData);
    final align = switch (shape.align) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      _ => TextAlign.left,
    };
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: applyDocumentPrintFontStyle(
          TextStyle(
            color: !shape.visible
                ? Color(shape.strokeColor).withValues(alpha: 0.35)
                : Color(shape.strokeColor),
            fontSize: shape.fontSize * scale,
            fontWeight: shape.bold ? FontWeight.w700 : FontWeight.w400,
            fontStyle: shape.italic ? FontStyle.italic : FontStyle.normal,
            decoration: shape.underline
                ? TextDecoration.underline
                : TextDecoration.none,
            letterSpacing: shape.letterSpacing * scale,
            height: shape.lineHeight,
          ),
          effectiveDocumentPrintFontFamily(
            template.fontFamily,
            shape.fontFamily,
          ),
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
      maxLines: shape.multiline ? null : 1,
    )..layout(maxWidth: rect.width);
    final dx = switch (shape.align) {
      'center' => rect.left + ((rect.width - painter.width) / 2),
      'right' => rect.right - painter.width,
      _ => rect.left,
    };
    painter.paint(canvas, Offset(dx, rect.top));
  }

  void _paintTable(Canvas canvas, Rect rect, DocumentPrintShape shape) {
    final rows =
        resolvePrintPath(documentData, shape.dataPath) as List<dynamic>? ??
        const <dynamic>[];
    final headerHeight = math.max(8.0, shape.titleHeight * scale);
    final cellGap = math.max(1.0, shape.cellGap * scale);
    final columns = shape.columns.isEmpty
        ? DocumentPrintShape.defaultTableColumns()
        : shape.columns;
    final totalWeight = columns.fold<double>(
      0,
      (sum, column) => sum + column.widthFactor,
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = Color(shape.strokeColor)
      ..strokeWidth = math.max(0, shape.strokeWidth * scale);
    final bodyFill = Paint()
      ..style = PaintingStyle.fill
      ..color = Color(shape.fillColor).withValues(alpha: shape.fillAlpha);
    final headerFill = Paint()
      ..style = PaintingStyle.fill
      ..color = Color(shape.headerColor);

    if (shape.fillAlpha > 0) {
      canvas.drawRect(rect, bodyFill);
    }

    var currentY = rect.top;
    if (shape.printHeader) {
      canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.top, rect.width, headerHeight),
        headerFill,
      );

      var cursorX = rect.left;
      for (final column in columns) {
        final columnWidth = rect.width * (column.widthFactor / totalWeight);
        final headerRect = Rect.fromLTWH(
          cursorX,
          rect.top,
          columnWidth,
          headerHeight,
        );
        _paintTableCell(
          canvas,
          headerRect,
          column.label,
          _textAlignForColumn(column.titleAlign),
          applyDocumentPrintFontStyle(
            TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: math.max(7, shape.fontSize + 1) * scale,
              color: Color(shape.headerTextColor),
              letterSpacing: shape.letterSpacing * scale,
              height: shape.lineHeight,
            ),
            effectiveDocumentPrintFontFamily(
              template.fontFamily,
              shape.fontFamily,
            ),
          ),
          centerVertically: true,
          cellGap: cellGap,
        );
        cursorX += columnWidth;
      }

      canvas.drawLine(
        Offset(rect.left, rect.top + headerHeight),
        Offset(rect.right, rect.top + headerHeight),
        stroke,
      );
      currentY = rect.top + headerHeight;
    }

    final useFullHeight = isPrintLinesTableShape(shape);
    final double availableBottomLimit = shape.printTotal && useFullHeight
        ? rect.bottom - headerHeight
        : rect.bottom;

    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      if (row is! Map<String, dynamic>) {
        continue;
      }
      final hasVisibleValue = printTableRowHasVisibleValues(row, columns);
      if (!hasVisibleValue) {
        continue;
      }

      final rowHeight = measurePrintTableRowHeight(
        row,
        columns,
        rect.width,
        shape,
        scale: scale,
        fontFamily: effectiveDocumentPrintFontFamily(
          template.fontFamily,
          shape.fontFamily,
        ),
      );

      if (currentY + rowHeight > availableBottomLimit + 1.0) {
        break;
      }

      var x = rect.left;
      for (final column in columns) {
        final columnWidth = rect.width * (column.widthFactor / totalWeight);
        final cellRect = Rect.fromLTWH(x, currentY, columnWidth, rowHeight);
        _paintTableCell(
          canvas,
          cellRect,
          resolvePrintCellValueForColumn(row, column, column.key),
          _textAlignForColumn(column.align),
          applyDocumentPrintFontStyle(
            TextStyle(
              fontSize: math.max(6, shape.fontSize) * scale,
              color: Color(shape.bodyTextColor),
              letterSpacing: shape.letterSpacing * scale,
              height: shape.lineHeight,
            ),
            effectiveDocumentPrintFontFamily(
              template.fontFamily,
              shape.fontFamily,
            ),
          ),
          centerVertically: true,
          cellGap: cellGap,
        );
        x += columnWidth;
      }

      canvas.drawLine(
        Offset(rect.left, currentY + rowHeight),
        Offset(rect.right, currentY + rowHeight),
        stroke,
      );
      currentY += rowHeight;
    }

    if (shape.printTotal) {
      final totals = _calculateColumnTotals(rows, columns);
      if (totals.isNotEmpty) {
        final totalRowTop = useFullHeight
            ? rect.bottom - headerHeight
            : currentY;
        canvas.drawRect(
          Rect.fromLTWH(rect.left, totalRowTop, rect.width, headerHeight),
          headerFill,
        );
        var x = rect.left;
        for (var index = 0; index < columns.length; index++) {
          final column = columns[index];
          final columnWidth = rect.width * (column.widthFactor / totalWeight);
          final cellRect = Rect.fromLTWH(
            x,
            totalRowTop,
            columnWidth,
            headerHeight,
          );
          final value = index == 0
              ? 'Total'
              : totals[column.key] == null
              ? ''
              : formatPrintValueForKey(
                  column.key,
                  totals[column.key]!,
                  columnNumberFormat: column.numberFormat,
                );
          _paintTableCell(
            canvas,
            cellRect,
            value,
            index == 0 ? TextAlign.left : _textAlignForColumn(column.align),
            applyDocumentPrintFontStyle(
              TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: math.max(6, shape.fontSize) * scale,
                color: Color(shape.headerTextColor),
                letterSpacing: shape.letterSpacing * scale,
                height: shape.lineHeight,
              ),
              effectiveDocumentPrintFontFamily(
                template.fontFamily,
                shape.fontFamily,
              ),
            ),
            centerVertically: true,
            cellGap: cellGap,
          );
          x += columnWidth;
        }
        canvas.drawLine(
          Offset(rect.left, totalRowTop),
          Offset(rect.right, totalRowTop),
          stroke,
        );
        canvas.drawLine(
          Offset(rect.left, totalRowTop + headerHeight),
          Offset(rect.right, totalRowTop + headerHeight),
          stroke,
        );
        currentY = totalRowTop + headerHeight;
      }
    }

    final contentBottom = useFullHeight
        ? rect.bottom
        : math.max(
            currentY,
            shape.printHeader ? rect.top + headerHeight : rect.top,
          );

    var cursorX = rect.left;
    for (var i = 0; i < columns.length; i++) {
      final column = columns[i];
      final columnWidth = rect.width * (column.widthFactor / totalWeight);
      if (i > 0) {
        canvas.drawLine(
          Offset(cursorX, rect.top),
          Offset(cursorX, contentBottom),
          stroke,
        );
      }
      cursorX += columnWidth;
    }

    canvas.drawRect(
      Rect.fromLTRB(rect.left, rect.top, rect.right, contentBottom),
      stroke,
    );
  }

  void _paintBarcode(Canvas canvas, Rect rect, DocumentPrintShape shape) {
    final value = resolvePrintTemplateText(shape.text, documentData);
    if (value.trim().isEmpty) {
      return;
    }
    final stroke = Paint()
      ..style = PaintingStyle.fill
      ..color = Color(shape.strokeColor);
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = Color(shape.fillColor).withValues(alpha: shape.fillAlpha);

    if (shape.fillAlpha > 0) {
      canvas.drawRect(rect, fill);
    }

    if (shape.barcodeType == 'qr') {
      final grid = 21;
      final cell = math.min(rect.width, rect.height) / grid;
      final seed = value.codeUnits.fold<int>(0, (sum, code) => sum + code);
      for (var y = 0; y < grid; y++) {
        for (var x = 0; x < grid; x++) {
          final finder =
              ((x < 7 && y < 7) ||
              (x >= grid - 7 && y < 7) ||
              (x < 7 && y >= grid - 7));
          final bit = finder || (((x * 31 + y * 17 + seed) % 7) < 3);
          if (bit) {
            canvas.drawRect(
              Rect.fromLTWH(
                rect.left + (x * cell),
                rect.top + (y * cell),
                cell,
                cell,
              ),
              stroke,
            );
          }
        }
      }
      return;
    }

    final top = rect.top;
    final barHeight = math.max(12.0, rect.height - (shape.fontSize + 8));
    var cursor = rect.left;
    final units = value.codeUnits.isEmpty ? [1] : value.codeUnits;
    for (var i = 0; i < units.length * 3 && cursor < rect.right; i++) {
      final unit = units[i % units.length];
      final width = ((unit + i) % 4 + 1) * 1.6 * scale;
      final shouldDraw = (unit + i).isEven;
      if (shouldDraw) {
        canvas.drawRect(
          Rect.fromLTWH(
            cursor,
            top,
            math.min(width, rect.right - cursor),
            barHeight,
          ),
          stroke,
        );
      }
      cursor += width;
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: value,
        style: applyDocumentPrintFontStyle(
          TextStyle(
            color: Color(shape.strokeColor),
            fontSize: shape.fontSize * scale,
            letterSpacing: shape.letterSpacing * scale,
            height: shape.lineHeight,
          ),
          effectiveDocumentPrintFontFamily(
            template.fontFamily,
            shape.fontFamily,
          ),
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: rect.width);
    textPainter.paint(
      canvas,
      Offset(
        rect.left + ((rect.width - textPainter.width) / 2),
        rect.bottom - textPainter.height,
      ),
    );
  }

  void _paintTableCell(
    Canvas canvas,
    Rect rect,
    String text,
    TextAlign align,
    TextStyle style, {
    bool centerVertically = false,
    double cellGap = 6,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: math.max(0.0, rect.width - (cellGap * 2)));
    final dx = switch (align) {
      TextAlign.right => rect.right - painter.width - cellGap,
      TextAlign.center => rect.left + ((rect.width - painter.width) / 2),
      _ => rect.left + cellGap,
    };
    final dy = centerVertically
        ? rect.top + ((rect.height - painter.height) / 2)
        : rect.top + cellGap;
    painter.paint(canvas, Offset(dx, dy));
  }

  Map<String, double> _calculateColumnTotals(
    List<dynamic> rows,
    List<DocumentPrintColumn> columns,
  ) {
    final totals = <String, double>{};
    final totalColumns = columns.where((column) => column.totalColumn).toList();
    if (totalColumns.isEmpty) {
      return totals;
    }
    for (final row in rows) {
      if (row is! Map<String, dynamic>) {
        continue;
      }
      for (final column in totalColumns) {
        final value = resolvePrintPath(row, column.key);
        if (value is num) {
          totals[column.key] = (totals[column.key] ?? 0) + value.toDouble();
        } else {
          final parsed = double.tryParse(value?.toString() ?? '');
          if (parsed != null) {
            totals[column.key] = (totals[column.key] ?? 0) + parsed;
          }
        }
      }
    }
    return totals;
  }

  TextAlign _textAlignForColumn(String align) {
    switch (align) {
      case 'right':
        return TextAlign.right;
      case 'center':
        return TextAlign.center;
      default:
        return TextAlign.left;
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0x12000000)
      ..strokeWidth = 0.5;
    final step = template.gridSize * scale;

    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(DocumentCanvasPainter oldDelegate) {
    return oldDelegate.template != template ||
        oldDelegate.documentData != documentData ||
        oldDelegate.scale != scale ||
        oldDelegate.showPageChrome != showPageChrome ||
        oldDelegate.draftShape != draftShape;
  }
}
