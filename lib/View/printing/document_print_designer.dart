import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../screen.dart';

const String _defaultPrintLogoAsset = 'assets/sakthicontroller logo.jpg';
const String _legacyPbsLogoAsset = 'assets/pbs_logo.png';

Future<void> openDocumentPrintDesigner(
  BuildContext context, {
  required String documentType,
  required String title,
  required Map<String, dynamic> documentData,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => DocumentPrintDesignerPage(
        documentType: documentType,
        title: title,
        documentData: documentData,
      ),
    ),
  );
}

class DocumentPrintDesignerPage extends StatefulWidget {
  const DocumentPrintDesignerPage({
    super.key,
    required this.documentType,
    required this.title,
    required this.documentData,
  });

  final String documentType;
  final String title;
  final Map<String, dynamic> documentData;

  @override
  State<DocumentPrintDesignerPage> createState() =>
      _DocumentPrintDesignerPageState();
}

class _DocumentPrintDesignerPageState extends State<DocumentPrintDesignerPage> {
  final _DocumentPrintTemplateRepository _repository =
      _DocumentPrintTemplateRepository();
  final GlobalKey _previewBoundaryKey = GlobalKey();
  final ScrollController _pageScrollController = ScrollController();
  _DocumentPrintTemplate? _template;
  String? _selectedShapeId;
  bool _editMode = false;
  bool _loading = true;
  bool _saving = false;
  bool _printingPdf = false;
  final FocusNode _designerFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _designerFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadTemplate() async {
    final template = await _repository.load(widget.documentType);
    if (!mounted) {
      return;
    }
    setState(() {
      _template = template;
      _loading = false;
    });
  }

  Future<void> _saveTemplate() async {
    final template = _template;
    if (template == null) {
      return;
    }
    setState(() => _saving = true);
    await _repository.save(widget.documentType, template);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Print template saved.')));
  }

  @override
  Widget build(BuildContext context) {
    return AppStandaloneShell(
      title: '${widget.title} Preview',
      scrollController: _pageScrollController,
      actions: _buildShellActions(),
      child: _buildContent(),
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

    actions.add(
      AdaptiveShellActionButton(
        onPressed: () => setState(() {
          _editMode = !_editMode;
          if (!_editMode) {
            _selectedShapeId = null;
          }
        }),
        icon: _editMode ? Icons.visibility_outlined : Icons.edit_outlined,
        label: _editMode ? 'Preview Mode' : 'Edit Template',
        filled: false,
      ),
    );

    if (_editMode) {
      actions.add(
        AdaptiveShellActionButton(
          onPressed: _saving ? null : _saveTemplate,
          icon: Icons.save_outlined,
          label: _saving ? 'Saving...' : 'Save Template',
        ),
      );
    }

    actions.add(
      AdaptiveShellActionButton(
        onPressed: _printingPdf ? null : _printPdf,
        icon: Icons.print_outlined,
        label: _printingPdf ? 'Printing...' : 'Print',
      ),
    );

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final showInspector = _editMode && constraints.maxWidth >= 980 + 420;

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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: AppSectionCard(
                        padding: const EdgeInsets.all(AppUiConstants.spacingMd),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(
                              AppUiConstants.panelRadius,
                            ),
                          ),
                          padding: const EdgeInsets.all(
                            AppUiConstants.spacingLg,
                          ),
                          alignment: Alignment.center,
                          child: KeyboardListener(
                            focusNode: _designerFocusNode,
                            autofocus: true,
                            onKeyEvent: (event) {
                              if (event is! KeyDownEvent) {
                                return;
                              }
                              final shapeId = _selectedShapeId;
                              if (shapeId == null) {
                                return;
                              }
                              final isShift =
                                  HardwareKeyboard.instance.isShiftPressed;
                              final delta = isShift ? 10.0 : 1.0;

                              if (event.logicalKey ==
                                  LogicalKeyboardKey.delete) {
                                _deleteSelectedShape();
                              } else if (event.logicalKey ==
                                  LogicalKeyboardKey.arrowLeft) {
                                _moveShape(shapeId, Offset(-delta, 0));
                              } else if (event.logicalKey ==
                                  LogicalKeyboardKey.arrowRight) {
                                _moveShape(shapeId, Offset(delta, 0));
                              } else if (event.logicalKey ==
                                  LogicalKeyboardKey.arrowUp) {
                                _moveShape(shapeId, Offset(0, -delta));
                              } else if (event.logicalKey ==
                                  LogicalKeyboardKey.arrowDown) {
                                _moveShape(shapeId, Offset(0, delta));
                              }
                            },
                            child: RepaintBoundary(
                              key: _previewBoundaryKey,
                              child: _DesignerCanvas(
                                template: template,
                                documentData: widget.documentData,
                                editMode: _editMode,
                                selectedShapeId: _selectedShapeId,
                                onSelectShape: (shapeId) {
                                  if (!_editMode) {
                                    return;
                                  }
                                  setState(() => _selectedShapeId = shapeId);
                                },
                                onMoveShape: _moveShape,
                                onResizeShape: _resizeShape,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_editMode && showInspector) ...[
                      const SizedBox(width: AppUiConstants.spacingLg),
                      SizedBox(width: 420, child: _buildInspector(template)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _toolbarButton(Icons.text_fields, 'Text', () => _addShape('text')),
          const SizedBox(width: AppUiConstants.spacingXs),
          _toolbarButton(
            Icons.crop_square_outlined,
            'Box',
            () => _addShape('rectangle'),
          ),
          const SizedBox(width: AppUiConstants.spacingXs),
          _toolbarButton(
            Icons.show_chart_outlined,
            'Line',
            () => _addShape('line'),
          ),
          const SizedBox(width: AppUiConstants.spacingXs),
          _toolbarButton(
            Icons.table_chart_outlined,
            'Table',
            () => _addShape('table'),
          ),
          const SizedBox(width: AppUiConstants.spacingXs),
          _toolbarButton(
            Icons.image_outlined,
            'Image',
            () => _addShape('image'),
          ),
          const SizedBox(width: AppUiConstants.spacingXs),
          _toolbarButton(Icons.qr_code, 'Barcode', () => _addShape('barcode')),
          const SizedBox(width: AppUiConstants.spacingMd),
          OutlinedButton.icon(
            onPressed: _resetTemplate,
            icon: const Icon(Icons.refresh_outlined),
            label: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Widget _toolbarButton(IconData icon, String label, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Widget _buildInspector(_DocumentPrintTemplate template) {
    final selected = template.shapeById(_selectedShapeId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        0,
        AppUiConstants.spacingMd,
        AppUiConstants.spacingMd,
        AppUiConstants.spacingMd,
      ),
      child: AppSectionCard(
        child: SingleChildScrollView(
          child: selected == null
              ? _PageInspector(
                  template: template,
                  onChanged: (next) => setState(() => _template = next),
                )
              : _ShapeInspector(
                  key: ValueKey(selected.id),
                  shape: selected,
                  bindings: _availableBindings(widget.documentData),
                  onChanged: _updateShape,
                  onDelete: _deleteSelectedShape,
                  onBringForward: _bringSelectedForward,
                  onSendBackward: _sendSelectedBackward,
                ),
        ),
      ),
    );
  }

  void _resetTemplate() {
    setState(() {
      _template = _DocumentPrintTemplate.defaults(
        widget.documentType,
        title: widget.title,
      );
      _selectedShapeId = null;
    });
  }

  void _addShape(String type) {
    final template = _template;
    if (template == null) {
      return;
    }
    final shape = _DocumentPrintShape.defaults(type, template.shapes.length);
    setState(() {
      _template = template.copyWith(shapes: [...template.shapes, shape]);
      _selectedShapeId = shape.id;
    });
  }

  void _updateShape(_DocumentPrintShape next) {
    final template = _template;
    if (template == null) {
      return;
    }
    final shapes = template.shapes
        .map((shape) => shape.id == next.id ? next : shape)
        .toList(growable: false);
    setState(() => _template = template.copyWith(shapes: shapes));
  }

  void _moveShape(String shapeId, Offset delta) {
    final template = _template;
    if (template == null) {
      return;
    }
    final shape = template.shapeById(shapeId);
    if (shape == null) {
      return;
    }
    var nextX = shape.x + delta.dx;
    var nextY = shape.y + delta.dy;

    if (template.showGrid) {
      nextX = (nextX / template.gridSize).round() * template.gridSize;
      nextY = (nextY / template.gridSize).round() * template.gridSize;
    }

    _updateShape(shape.copyWith(x: math.max(0, nextX), y: math.max(0, nextY)));
  }

  void _resizeShape(String shapeId, Offset delta) {
    final template = _template;
    if (template == null) {
      return;
    }
    final shape = template.shapeById(shapeId);
    if (shape == null) {
      return;
    }
    var nextW = shape.width + delta.dx;
    var nextH = shape.height + delta.dy;

    if (template.showGrid) {
      nextW = (nextW / template.gridSize).round() * template.gridSize;
      nextH = (nextH / template.gridSize).round() * template.gridSize;
    }

    _updateShape(
      shape.copyWith(width: math.max(16, nextW), height: math.max(16, nextH)),
    );
  }

  void _deleteSelectedShape() {
    final template = _template;
    final selectedShapeId = _selectedShapeId;
    if (template == null || selectedShapeId == null) {
      return;
    }
    setState(() {
      _template = template.copyWith(
        shapes: template.shapes
            .where((shape) => shape.id != selectedShapeId)
            .toList(growable: false),
      );
      _selectedShapeId = null;
    });
  }

  void _bringSelectedForward() {
    final template = _template;
    final selectedShapeId = _selectedShapeId;
    if (template == null || selectedShapeId == null) {
      return;
    }
    final shapes = [...template.shapes];
    final index = shapes.indexWhere((shape) => shape.id == selectedShapeId);
    if (index < 0 || index == shapes.length - 1) {
      return;
    }
    final shape = shapes.removeAt(index);
    shapes.insert(index + 1, shape);
    setState(() => _template = template.copyWith(shapes: shapes));
  }

  void _sendSelectedBackward() {
    final template = _template;
    final selectedShapeId = _selectedShapeId;
    if (template == null || selectedShapeId == null) {
      return;
    }
    final shapes = [...template.shapes];
    final index = shapes.indexWhere((shape) => shape.id == selectedShapeId);
    if (index <= 0) {
      return;
    }
    final shape = shapes.removeAt(index);
    shapes.insert(index - 1, shape);
    setState(() => _template = template.copyWith(shapes: shapes));
  }

  Future<Uint8List?> _capturePreviewPng() async {
    await SchedulerBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 32));
    await SchedulerBinding.instance.endOfFrame;
    final boundary =
        _previewBoundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      return null;
    }
    final pixelRatio = switch (defaultTargetPlatform) {
      TargetPlatform.macOS => 1.4,
      TargetPlatform.windows => 1.6,
      _ => 2.0,
    };
    final image = await boundary
        .toImage(pixelRatio: pixelRatio)
        .timeout(
          const Duration(seconds: 8),
          onTimeout: () => throw Exception(
            'Preview capture timed out. Please wait for the preview to finish rendering and try again.',
          ),
        );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  PdfPageFormat _pageFormatForTemplate(_DocumentPrintTemplate template) {
    return PdfPageFormat(template.pageWidth, template.pageHeight, marginAll: 0);
  }

  Future<Uint8List?> _buildPdfBytes() async {
    final template = _template;
    if (template == null) {
      return null;
    }
    final png = await _capturePreviewPng();
    if (png == null) {
      return null;
    }
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

  Future<void> _printPdf() async {
    setState(() => _printingPdf = true);
    try {
      final bytes = await _buildPdfBytes();
      if (bytes == null) {
        throw Exception('Unable to capture print preview.');
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
        setState(() => _printingPdf = false);
      }
    }
  }
}

class _DesignerCanvas extends StatelessWidget {
  const _DesignerCanvas({
    required this.template,
    required this.documentData,
    required this.editMode,
    required this.selectedShapeId,
    required this.onSelectShape,
    required this.onMoveShape,
    required this.onResizeShape,
  });

  final _DocumentPrintTemplate template;
  final Map<String, dynamic> documentData;
  final bool editMode;
  final String? selectedShapeId;
  final ValueChanged<String?> onSelectShape;
  final void Function(String shapeId, Offset delta) onMoveShape;
  final void Function(String shapeId, Offset delta) onResizeShape;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = math.max(
          0.35,
          math.min(
            (constraints.maxWidth - 24) / template.pageWidth,
            (constraints.maxHeight - 24) / template.pageHeight,
          ),
        );
        final canvasWidth = template.pageWidth * scale;
        final canvasHeight = template.pageHeight * scale;

        return SingleChildScrollView(
          child: Center(
            child: GestureDetector(
              onTap: () => onSelectShape(null),
              child: Container(
                width: canvasWidth,
                height: canvasHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DocumentCanvasPainter(
                          template: template,
                          documentData: documentData,
                          scale: scale,
                        ),
                      ),
                    ),
                    ...template.shapes
                        .where((shape) => shape.type == 'image')
                        .map(
                          (shape) => Positioned(
                            left: shape.x * scale,
                            top: shape.y * scale,
                            width: math.max(24, shape.width * scale),
                            height: math.max(24, shape.height * scale),
                            child: IgnorePointer(
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
                                  source: _resolveTemplateText(
                                    shape.assetPath,
                                    documentData,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    if (editMode)
                      ...template.shapes.map((shape) {
                        final isSelected = shape.id == selectedShapeId;
                        return Positioned(
                          left: shape.x * scale,
                          top: shape.y * scale,
                          width: math.max(24, shape.width * scale),
                          height: math.max(24, shape.height * scale),
                          child: _ShapeSelectionOverlay(
                            selected: isSelected,
                            onTap: () => onSelectShape(shape.id),
                            onMove: (delta) => onMoveShape(shape.id, delta),
                            onResize: (delta) => onResizeShape(shape.id, delta),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShapeSelectionOverlay extends StatelessWidget {
  const _ShapeSelectionOverlay({
    required this.selected,
    required this.onTap,
    required this.onMove,
    required this.onResize,
  });

  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<Offset> onMove;
  final ValueChanged<Offset> onResize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onTap,
            onPanStart: (_) => onTap(),
            onPanUpdate: (details) => onMove(details.delta),
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
              onPanUpdate: (details) => onResize(details.delta),
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

class _DocumentImageShape extends StatelessWidget {
  const _DocumentImageShape({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final resolved = _resolveImageSource(source);
    if (resolved == null || resolved.trim().isEmpty) {
      return _fallback();
    }
    if (resolved.startsWith('assets/')) {
      return Image.asset(
        resolved,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    return Image.network(
      resolved,
      fit: BoxFit.contain,
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

class _DocumentCanvasPainter extends CustomPainter {
  _DocumentCanvasPainter({
    required this.template,
    required this.documentData,
    required this.scale,
  });

  final _DocumentPrintTemplate template;
  final Map<String, dynamic> documentData;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
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

    if (template.showGrid) {
      _drawGrid(canvas, size);
    }

    for (final shape in template.shapes) {
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
        ..color = Color(shape.strokeColor)
        ..strokeWidth = math.max(1, shape.strokeWidth * scale);
      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = Color(shape.fillColor).withValues(alpha: shape.fillAlpha);

      switch (shape.type) {
        case 'rectangle':
          if (shape.fillAlpha > 0) {
            canvas.drawRRect(rrect, fill);
          }
          canvas.drawRRect(rrect, stroke);
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
  }

  void _paintText(Canvas canvas, Rect rect, _DocumentPrintShape shape) {
    final text = _resolveTemplateText(shape.text, documentData);
    final align = switch (shape.align) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      _ => TextAlign.left,
    };
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Color(shape.strokeColor),
          fontSize: shape.fontSize * scale,
          fontWeight: shape.bold ? FontWeight.w700 : FontWeight.w400,
          fontStyle: shape.italic ? FontStyle.italic : FontStyle.normal,
          decoration: shape.underline
              ? TextDecoration.underline
              : TextDecoration.none,
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

  void _paintTable(Canvas canvas, Rect rect, _DocumentPrintShape shape) {
    final rows =
        _resolvePath(documentData, shape.dataPath) as List<dynamic>? ??
        const <dynamic>[];
    final headerHeight = 32 * scale;
    final minRowHeight = math.max(24.0, shape.rowHeight * scale);
    final columns = shape.columns.isEmpty
        ? _DocumentPrintShape.defaultTableColumns()
        : shape.columns;
    final totalWeight = columns.fold<double>(
      0,
      (sum, column) => sum + column.widthFactor,
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = Color(shape.strokeColor)
      ..strokeWidth = 1;
    final headerFill = Paint()
      ..style = PaintingStyle.fill
      ..color = Color(shape.headerColor);

    canvas.drawRect(rect, stroke);
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
        TextAlign.left,
        TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12 * scale,
          color: Color(shape.headerTextColor),
        ),
        centerVertically: true,
      );
      canvas.drawLine(
        Offset(cursorX, rect.top),
        Offset(cursorX, rect.bottom),
        stroke,
      );
      cursorX += columnWidth;
    }

    canvas.drawLine(
      Offset(rect.left, rect.top + headerHeight),
      Offset(rect.right, rect.top + headerHeight),
      stroke,
    );

    var currentY = rect.top + headerHeight;
    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      if (row is! Map<String, dynamic>) {
        continue;
      }

      final rowHeight = _measureRowHeight(
        row,
        columns,
        rect.width,
        totalWeight,
        minRowHeight,
        scale,
        shape.strokeColor,
      );

      if (currentY + rowHeight > rect.bottom) {
        break;
      }

      var x = rect.left;
      for (final column in columns) {
        final columnWidth = rect.width * (column.widthFactor / totalWeight);
        final cellRect = Rect.fromLTWH(x, currentY, columnWidth, rowHeight);
        _paintTableCell(
          canvas,
          cellRect,
          _resolveCellValue(row, column.key),
          column.align == 'right' ? TextAlign.right : TextAlign.left,
          TextStyle(fontSize: 11 * scale, color: Color(shape.strokeColor)),
          centerVertically: true,
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
  }

  double _measureRowHeight(
    Map<String, dynamic> row,
    List<_DocumentPrintColumn> columns,
    double totalWidth,
    double totalWeight,
    double minHeight,
    double scale,
    int strokeColor,
  ) {
    double maxHeight = minHeight;
    for (final column in columns) {
      final weight = totalWeight > 0 ? column.widthFactor / totalWeight : 0.0;
      final columnWidth = totalWidth * weight;
      final text = _resolveCellValue(row, column.key);
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontSize: 11 * scale, color: Color(strokeColor)),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: math.max(0.0, columnWidth - 12));
      maxHeight = math.max(maxHeight, painter.height + 12);
    }
    return maxHeight;
  }

  void _paintBarcode(Canvas canvas, Rect rect, _DocumentPrintShape shape) {
    final value = _resolveTemplateText(shape.text, documentData);
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
        style: TextStyle(
          color: Color(shape.strokeColor),
          fontSize: shape.fontSize * scale,
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
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: math.max(0.0, rect.width - 12));
    final dx = switch (align) {
      TextAlign.right => rect.right - painter.width - 6,
      TextAlign.center => rect.left + ((rect.width - painter.width) / 2),
      _ => rect.left + 6,
    };
    final dy = centerVertically
        ? rect.top + ((rect.height - painter.height) / 2)
        : rect.top + 6;
    painter.paint(canvas, Offset(dx, dy));
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
  bool shouldRepaint(covariant _DocumentCanvasPainter oldDelegate) {
    return oldDelegate.template != template ||
        oldDelegate.documentData != documentData ||
        oldDelegate.scale != scale;
  }
}

class _PageInspector extends StatelessWidget {
  const _PageInspector({
    super.key,
    required this.template,
    required this.onChanged,
  });

  final _DocumentPrintTemplate template;
  final ValueChanged<_DocumentPrintTemplate> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Page', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppUiConstants.spacingSm),
        AppDropdownField<String>.fromMapped(
          labelText: 'Paper',
          initialValue: template.mediaPreset,
          mappedItems: const [
            AppDropdownItem(value: 'A4', label: 'A4'),
            AppDropdownItem(value: 'A5', label: 'A5'),
            AppDropdownItem(value: 'LETTER', label: 'Letter'),
            AppDropdownItem(value: 'CUSTOM', label: 'Custom'),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            onChanged(_applyPagePreset(template, mediaPreset: value));
          },
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        AppDropdownField<String>.fromMapped(
          labelText: 'Orientation',
          initialValue: template.orientation,
          mappedItems: const [
            AppDropdownItem(value: 'portrait', label: 'Portrait'),
            AppDropdownItem(value: 'landscape', label: 'Landscape'),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            onChanged(_applyPagePreset(template, orientation: value));
          },
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        _NumberField(
          label: 'Width',
          value: template.pageWidth,
          onChanged: (value) => onChanged(
            template.copyWith(
              pageWidth: math.max(320, value),
              mediaPreset: 'CUSTOM',
            ),
          ),
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        _NumberField(
          label: 'Height',
          value: template.pageHeight,
          onChanged: (value) => onChanged(
            template.copyWith(
              pageHeight: math.max(400, value),
              mediaPreset: 'CUSTOM',
            ),
          ),
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        AppSwitchTile(
          label: 'Show Grid',
          value: template.showGrid,
          onChanged: (value) => onChanged(template.copyWith(showGrid: value)),
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        _NumberField(
          label: 'Grid Size',
          value: template.gridSize,
          onChanged: (value) => onChanged(
            template.copyWith(gridSize: value.clamp(4, 64).toDouble()),
          ),
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        const SizedBox(height: AppUiConstants.spacingMd),
        Text(
          'Select a shape on the page to edit it.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ShapeInspector extends StatelessWidget {
  const _ShapeInspector({
    super.key,
    required this.shape,
    required this.bindings,
    required this.onChanged,
    required this.onDelete,
    required this.onBringForward,
    required this.onSendBackward,
  });

  final _DocumentPrintShape shape;
  final List<String> bindings;
  final ValueChanged<_DocumentPrintShape> onChanged;
  final VoidCallback onDelete;
  final VoidCallback onBringForward;
  final VoidCallback onSendBackward;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                shape.typeLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: 'Send backward',
              onPressed: onSendBackward,
              icon: const Icon(Icons.arrow_downward_outlined),
            ),
            IconButton(
              tooltip: 'Bring forward',
              onPressed: onBringForward,
              icon: const Icon(Icons.arrow_upward_outlined),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        Row(
          children: [
            Expanded(
              child: _NumberField(
                label: 'X',
                value: shape.x,
                onChanged: (value) =>
                    onChanged(shape.copyWith(x: math.max(0, value))),
              ),
            ),
            const SizedBox(width: AppUiConstants.spacingSm),
            Expanded(
              child: _NumberField(
                label: 'Y',
                value: shape.y,
                onChanged: (value) =>
                    onChanged(shape.copyWith(y: math.max(0, value))),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        Row(
          children: [
            Expanded(
              child: _NumberField(
                label: 'Width',
                value: shape.width,
                onChanged: (value) =>
                    onChanged(shape.copyWith(width: math.max(24, value))),
              ),
            ),
            const SizedBox(width: AppUiConstants.spacingSm),
            Expanded(
              child: _NumberField(
                label: 'Height',
                value: shape.height,
                onChanged: (value) =>
                    onChanged(shape.copyWith(height: math.max(16, value))),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        _NumberField(
          label: 'Stroke Width',
          value: shape.strokeWidth,
          onChanged: (value) =>
              onChanged(shape.copyWith(strokeWidth: math.max(1, value))),
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        _ColorField(
          label: switch (shape.type) {
            'text' => 'Text Color',
            'rectangle' => 'Border Color',
            'line' => 'Line Color',
            'table' => 'Grid Color',
            'barcode' => 'Barcode Color',
            _ => 'Stroke Color',
          },
          value: shape.strokeColor,
          onChanged: (value) => onChanged(shape.copyWith(strokeColor: value)),
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        _ColorField(
          label: 'Fill Color',
          value: shape.fillColor,
          onChanged: (value) {
            var next = shape.copyWith(fillColor: value);
            if (value != 0xFFFFFFFF && shape.fillAlpha == 0) {
              next = next.copyWith(fillAlpha: 1.0);
            }
            onChanged(next);
          },
        ),
        if (shape.type == 'table') ...[
          const SizedBox(height: AppUiConstants.spacingSm),
          _ColorField(
            label: 'Header Color',
            value: shape.headerColor,
            onChanged: (value) => onChanged(shape.copyWith(headerColor: value)),
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          _ColorField(
            label: 'Header Text Color',
            value: shape.headerTextColor,
            onChanged: (value) =>
                onChanged(shape.copyWith(headerTextColor: value)),
          ),
        ],
        const SizedBox(height: AppUiConstants.spacingSm),
        _NumberField(
          label: 'Fill Alpha (0-1)',
          value: shape.fillAlpha,
          fractionDigits: 2,
          onChanged: (value) => onChanged(
            shape.copyWith(fillAlpha: value.clamp(0, 1).toDouble()),
          ),
        ),
        if (shape.type == 'text') ...[
          const SizedBox(height: AppUiConstants.spacingSm),
          _StringField(
            label: 'Text',
            value: shape.text,
            maxLines: 4,
            onChanged: (value) =>
                onChanged(shape.copyWith(text: value, multiline: true)),
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          _NumberField(
            label: 'Font Size',
            value: shape.fontSize,
            onChanged: (value) =>
                onChanged(shape.copyWith(fontSize: math.max(8, value))),
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          AppDropdownField<String>.fromMapped(
            labelText: 'Alignment',
            initialValue: shape.align,
            mappedItems: const [
              AppDropdownItem(value: 'left', label: 'Left'),
              AppDropdownItem(value: 'center', label: 'Center'),
              AppDropdownItem(value: 'right', label: 'Right'),
            ],
            onChanged: (value) {
              if (value != null) {
                onChanged(shape.copyWith(align: value));
              }
            },
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          AppSwitchTile(
            label: 'Bold',
            value: shape.bold,
            onChanged: (value) => onChanged(shape.copyWith(bold: value)),
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          AppSwitchTile(
            label: 'Italic',
            value: shape.italic,
            onChanged: (value) => onChanged(shape.copyWith(italic: value)),
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          AppSwitchTile(
            label: 'Underline',
            value: shape.underline,
            onChanged: (value) => onChanged(shape.copyWith(underline: value)),
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          Text('Bindings', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppUiConstants.spacingXs),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: bindings
                .map(
                  (binding) => ActionChip(
                    label: Text('{{$binding}}'),
                    onPressed: () => onChanged(
                      shape.copyWith(
                        text: shape.text.isEmpty
                            ? '{{$binding}}'
                            : '${shape.text} {{$binding}}',
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
        if (shape.type == 'rectangle') ...[
          const SizedBox(height: AppUiConstants.spacingSm),
          _NumberField(
            label: 'Border Radius',
            value: shape.borderRadius,
            onChanged: (value) =>
                onChanged(shape.copyWith(borderRadius: math.max(0, value))),
          ),
        ],
        if (shape.type == 'table') ...[
          const SizedBox(height: AppUiConstants.spacingSm),
          _StringField(
            label: 'Rows Path',
            value: shape.dataPath,
            onChanged: (value) => onChanged(shape.copyWith(dataPath: value)),
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          _NumberField(
            label: 'Row Height',
            value: shape.rowHeight,
            onChanged: (value) =>
                onChanged(shape.copyWith(rowHeight: math.max(20, value))),
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          _TableColumnInspector(
            columns: shape.columns,
            onChanged: (columns) => onChanged(shape.copyWith(columns: columns)),
          ),
        ],
        if (shape.type == 'image') ...[
          const SizedBox(height: AppUiConstants.spacingSm),
          _StringField(
            label: 'Image Source',
            value: shape.assetPath,
            onChanged: (value) => onChanged(shape.copyWith(assetPath: value)),
          ),
        ],
        if (shape.type == 'barcode') ...[
          const SizedBox(height: AppUiConstants.spacingSm),
          _StringField(
            label: 'Barcode Value',
            value: shape.text,
            onChanged: (value) => onChanged(shape.copyWith(text: value)),
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          AppDropdownField<String>.fromMapped(
            labelText: 'Barcode Type',
            initialValue: shape.barcodeType,
            mappedItems: const [
              AppDropdownItem(value: 'code128', label: 'CODE128'),
              AppDropdownItem(value: 'qr', label: 'QR'),
            ],
            onChanged: (value) {
              if (value != null) {
                onChanged(shape.copyWith(barcodeType: value));
              }
            },
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          _NumberField(
            label: 'Font Size',
            value: shape.fontSize,
            onChanged: (value) =>
                onChanged(shape.copyWith(fontSize: math.max(8, value))),
          ),
        ],
      ],
    );
  }
}

class _StringField extends StatefulWidget {
  const _StringField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final int maxLines;

  @override
  State<_StringField> createState() => _StringFieldState();
}

class _StringFieldState extends State<_StringField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_StringField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFormTextField(
      controller: _controller,
      labelText: widget.label,
      maxLines: widget.maxLines,
      onChanged: widget.onChanged,
    );
  }
}

class _NumberField extends StatefulWidget {
  const _NumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.fractionDigits = 0,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final int fractionDigits;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller;

  String _formatValue(double value) {
    return widget.fractionDigits == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(widget.fractionDigits);
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatValue(widget.value));
  }

  @override
  void didUpdateWidget(_NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = _formatValue(widget.value);
    if (text != _controller.text && double.tryParse(_controller.text) != widget.value) {
      _controller.text = text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFormTextField(
      controller: _controller,
      labelText: widget.label,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (next) {
        final parsed = double.tryParse(next.trim());
        if (parsed != null) {
          widget.onChanged(parsed);
        }
      },
    );
  }
}

class _ColorField extends StatelessWidget {
  const _ColorField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  static const _palette = <String, int>{
    'Black': 0xFF111827,
    'Slate': 0xFF475569,
    'Blue': 0xFF2563EB,
    'Green': 0xFF059669,
    'Red': 0xFFDC2626,
    'Amber': 0xFFF59E0B,
    'Gray': 0xFFD1D5DB,
  };

  @override
  Widget build(BuildContext context) {
    final current = _palette.values.contains(value)
        ? value
        : _palette.values.first;
    return AppDropdownField<int>.fromMapped(
      labelText: label,
      initialValue: current,
      mappedItems: _palette.entries
          .map(
            (entry) =>
                AppDropdownItem<int>(value: entry.value, label: entry.key),
          )
          .toList(growable: false),
      onChanged: (next) {
        if (next != null) {
          onChanged(next);
        }
      },
    );
  }
}

class _TableColumnInspector extends StatelessWidget {
  const _TableColumnInspector({required this.columns, required this.onChanged});

  final List<_DocumentPrintColumn> columns;
  final ValueChanged<List<_DocumentPrintColumn>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Columns',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            IconButton(
              tooltip: 'Add column',
              onPressed: () {
                onChanged([
                  ...columns,
                  _DocumentPrintColumn(
                    key: 'new_key',
                    label: 'New Column',
                    widthFactor: 1.0,
                  ),
                ]);
              },
              icon: const Icon(Icons.add_circle_outline),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingXs),
        ...columns.asMap().entries.map((entry) {
          final index = entry.key;
          final column = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppUiConstants.spacingMd),
            child: AppSectionCard(
              padding: const EdgeInsets.all(AppUiConstants.spacingSm),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StringField(
                          key: ValueKey('col-$index-label'),
                          label: 'Label',
                          value: column.label,
                          onChanged: (val) =>
                              _updateColumn(index, column.copyWith(label: val)),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _deleteColumn(index),
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Theme.of(context).colorScheme.error,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppUiConstants.spacingXs),
                  Row(
                    children: [
                      Expanded(
                        child: _StringField(
                          key: ValueKey('col-$index-key'),
                          label: 'Key',
                          value: column.key,
                          onChanged: (val) =>
                              _updateColumn(index, column.copyWith(key: val)),
                        ),
                      ),
                      const SizedBox(width: AppUiConstants.spacingSm),
                      SizedBox(
                        width: 80,
                        child: _NumberField(
                          key: ValueKey('col-$index-weight'),
                          label: 'Weight',
                          value: column.widthFactor,
                          onChanged: (val) => _updateColumn(
                            index,
                            column.copyWith(widthFactor: val),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppUiConstants.spacingXs),
                  AppDropdownField<String>.fromMapped(
                    labelText: 'Align',
                    initialValue: column.align,
                    mappedItems: const [
                      AppDropdownItem(value: 'left', label: 'Left'),
                      AppDropdownItem(value: 'center', label: 'Center'),
                      AppDropdownItem(value: 'right', label: 'Right'),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _updateColumn(index, column.copyWith(align: val));
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _updateColumn(int index, _DocumentPrintColumn next) {
    final list = [...columns];
    list[index] = next;
    onChanged(list);
  }

  void _deleteColumn(int index) {
    final list = [...columns];
    list.removeAt(index);
    onChanged(list);
  }
}

class _DocumentPrintTemplateRepository {
  static const _prefix = 'document_print_template_v1_';

  Future<_DocumentPrintTemplate> load(String documentType) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$documentType');
    if (raw == null || raw.trim().isEmpty) {
      return _DocumentPrintTemplate.defaults(documentType);
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return _DocumentPrintTemplate.fromJson(
          decoded,
        ).withoutUnsupportedShapes().normalizedFor(documentType);
      }
    } catch (_) {}
    return _DocumentPrintTemplate.defaults(documentType);
  }

  Future<void> save(
    String documentType,
    _DocumentPrintTemplate template,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix$documentType',
      jsonEncode(template.toJson()),
    );
  }
}

class _DocumentPrintTemplate {
  const _DocumentPrintTemplate({
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
  final List<_DocumentPrintShape> shapes;
  final String? backgroundImagePath;
  final double backgroundOpacity;
  final String mediaPreset;
  final String orientation;
  final double gridSize;
  final bool showGrid;

  factory _DocumentPrintTemplate.fromJson(Map<String, dynamic> json) {
    return _DocumentPrintTemplate(
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
          .map(_DocumentPrintShape.fromJson)
          .toList(growable: false),
    );
  }

  factory _DocumentPrintTemplate.defaults(
    String documentType, {
    String? title,
  }) {
    final resolvedTitle = (title ?? _documentTitleForType(documentType))
        .toUpperCase();
    if (documentType == 'sales_quotation') {
      return _DocumentPrintTemplate(
        pageWidth: 595,
        pageHeight: 842,
        mediaPreset: 'A4',
        orientation: 'portrait',
        shapes: [
          const _DocumentPrintShape(
            id: 'company-logo',
            type: 'image',
            x: 28,
            y: 26,
            width: 72,
            height: 72,
            strokeWidth: 0,
            assetPath: '{{company_logo_url}}',
          ),
          _DocumentPrintShape(
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
          _DocumentPrintShape(
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
          _DocumentPrintShape(
            id: 'meta-text',
            type: 'text',
            x: 408,
            y: 30,
            width: 154,
            height: 56,
            text:
                'No: {{document_number}}\nDate: {{document_date}}\nRef: {{reference_number}}',
            fontSize: 10,
            multiline: true,
            align: 'right',
          ),
          const _DocumentPrintShape(
            id: 'header-divider',
            type: 'line',
            x: 28,
            y: 108,
            width: 538,
            height: 0,
            strokeColor: 0xFF111827,
          ),
          _DocumentPrintShape(
            id: 'party-text',
            type: 'text',
            x: 28,
            y: 122,
            width: 340,
            height: 56,
            text:
                'Party: {{party_name}}\nAddress: {{party_address}}\nContact: {{party_contact}}',
            fontSize: 10,
            multiline: true,
          ),
          _DocumentPrintShape(
            id: 'lines-table',
            type: 'table',
            x: 28,
            y: 196,
            width: 538,
            height: 470,
            dataPath: 'lines',
            rowHeight: 34,
            columns: _DocumentPrintShape.defaultTableColumns(),
          ),
          _DocumentPrintShape(
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
          _DocumentPrintShape(
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
          _DocumentPrintShape(
            id: 'totals-text',
            type: 'text',
            x: 386,
            y: 690,
            width: 180,
            height: 66,
            text:
                'Subtotal: {{subtotal}}\nTax: {{tax_amount}}\nTotal: {{total_amount}}',
            fontSize: 12,
            multiline: true,
            align: 'right',
            bold: true,
          ),
        ],
      );
    }

    return _DocumentPrintTemplate(
      pageWidth: 595,
      pageHeight: 842,
      mediaPreset: 'A4',
      orientation: 'portrait',
      shapes: [
        const _DocumentPrintShape(
          id: 'company-logo',
          type: 'image',
          x: 28,
          y: 28,
          width: 84,
          height: 84,
          strokeWidth: 0,
          assetPath: '{{company_logo_url}}',
        ),
        _DocumentPrintShape(
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
        _DocumentPrintShape(
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
        _DocumentPrintShape(
          id: 'meta-box',
          type: 'rectangle',
          x: 360,
          y: 28,
          width: 206,
          height: 88,
          strokeColor: 0xFFCBD5E1,
        ),
        _DocumentPrintShape(
          id: 'meta-text',
          type: 'text',
          x: 376,
          y: 40,
          width: 170,
          height: 60,
          text:
              'No: {{document_number}}\nDate: {{document_date}}\nRef: {{reference_number}}',
          fontSize: 11,
          multiline: true,
        ),
        _DocumentPrintShape(
          id: 'party-box',
          type: 'rectangle',
          x: 28,
          y: 132,
          width: 538,
          height: 88,
          strokeColor: 0xFFCBD5E1,
        ),
        _DocumentPrintShape(
          id: 'party-text',
          type: 'text',
          x: 40,
          y: 144,
          width: 514,
          height: 64,
          text:
              'Party: {{party_name}}\nAddress: {{party_address}}\nContact: {{party_contact}}',
          fontSize: 11,
          multiline: true,
        ),
        _DocumentPrintShape(
          id: 'lines-table',
          type: 'table',
          x: 28,
          y: 238,
          width: 538,
          height: 390,
          dataPath: 'lines',
          columns: _DocumentPrintShape.defaultTableColumns(),
        ),
        _DocumentPrintShape(
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
        _DocumentPrintShape(
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
        _DocumentPrintShape(
          id: 'totals-box',
          type: 'rectangle',
          x: 350,
          y: 648,
          width: 216,
          height: 108,
          strokeColor: 0xFFCBD5E1,
        ),
        _DocumentPrintShape(
          id: 'totals-text',
          type: 'text',
          x: 366,
          y: 662,
          width: 184,
          height: 80,
          text:
              'Subtotal: {{subtotal}}\nTax: {{tax_amount}}\nTotal: {{total_amount}}',
          fontSize: 12,
          multiline: true,
          align: 'right',
          bold: true,
        ),
      ],
    );
  }

  _DocumentPrintShape? shapeById(String? shapeId) {
    if (shapeId == null) {
      return null;
    }
    return shapes.cast<_DocumentPrintShape?>().firstWhere(
      (shape) => shape?.id == shapeId,
      orElse: () => null,
    );
  }

  _DocumentPrintTemplate withoutUnsupportedShapes() {
    return copyWith(
      shapes: shapes
          .where((shape) => shape.isSupported)
          .toList(growable: false),
    );
  }

  _DocumentPrintTemplate normalizedFor(String documentType) {
    if (documentType != 'sales_quotation') {
      return this;
    }

    final nextShapes = shapes
        .where(
          (shape) =>
              !const {'party-box', 'totals-box', 'meta-box'}.contains(shape.id),
        )
        .map((shape) {
          switch (shape.id) {
            case 'company-logo':
              return shape.copyWith(x: 28, y: 26, width: 72, height: 72);
            case 'text-title':
              return shape.copyWith(
                x: 112,
                y: 28,
                width: 250,
                height: 28,
                fontSize: 18,
              );
            case 'text-doc-type':
              return shape.copyWith(
                x: 112,
                y: 56,
                width: 180,
                height: 16,
                fontSize: 10,
              );
            case 'meta-text':
              return shape.copyWith(
                x: 408,
                y: 30,
                width: 154,
                height: 56,
                fontSize: 10,
                align: 'right',
                multiline: true,
              );
            case 'party-text':
              return shape.copyWith(
                x: 28,
                y: 122,
                width: 340,
                height: 56,
                fontSize: 10,
                multiline: true,
              );
            case 'lines-table':
              return shape.copyWith(
                x: 28,
                y: 196,
                width: 538,
                height: 470,
                rowHeight: math.max(34, shape.rowHeight),
                columns: shape.columns.isEmpty
                    ? _DocumentPrintShape.defaultTableColumns()
                    : shape.columns,
              );
            case 'notes-title':
              return shape.copyWith(x: 28, y: 684, width: 100, height: 16);
            case 'notes-text':
              return shape.copyWith(
                x: 28,
                y: 702,
                width: 320,
                height: 68,
                fontSize: 10,
              );
            case 'totals-text':
              return shape.copyWith(
                x: 386,
                y: 690,
                width: 180,
                height: 66,
                fontSize: 12,
                align: 'right',
                multiline: true,
                bold: true,
              );
            default:
              return shape;
          }
        })
        .toList(growable: false);

    final hasHeaderDivider = nextShapes.any(
      (shape) => shape.id == 'header-divider',
    );

    return copyWith(
      shapes: [
        ...nextShapes,
        if (!hasHeaderDivider)
          const _DocumentPrintShape(
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

  _DocumentPrintTemplate copyWith({
    double? pageWidth,
    double? pageHeight,
    List<_DocumentPrintShape>? shapes,
    String? backgroundImagePath,
    double? backgroundOpacity,
    String? mediaPreset,
    String? orientation,
    double? gridSize,
    bool? showGrid,
  }) {
    return _DocumentPrintTemplate(
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

class _DocumentPrintShape {
  const _DocumentPrintShape({
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
    this.columns = const <_DocumentPrintColumn>[],
    this.assetPath = _defaultPrintLogoAsset,
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
  final List<_DocumentPrintColumn> columns;
  final String assetPath;
  final int sides;
  final String barcodeType;

  factory _DocumentPrintShape.fromJson(Map<String, dynamic> json) {
    return _DocumentPrintShape(
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
      assetPath: _normalizeLegacyImageSource(
        stringValue(json, 'assetPath', _defaultPrintLogoAsset),
      ),
      sides: int.tryParse(json['sides']?.toString() ?? '') ?? 5,
      barcodeType: stringValue(json, 'barcodeType', 'code128'),
      columns: (json['columns'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(_DocumentPrintColumn.fromJson)
          .toList(growable: false),
    );
  }

  factory _DocumentPrintShape.defaults(String type, int index) {
    switch (type) {
      case 'rectangle':
        return _DocumentPrintShape(
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
        return _DocumentPrintShape(
          id: '$type-$index',
          type: type,
          x: 36,
          y: 36 + (index * 12),
          width: 220,
          height: 0,
        );
      case 'table':
        return _DocumentPrintShape(
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
        return _DocumentPrintShape(
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
        return _DocumentPrintShape(
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
        return _DocumentPrintShape(
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

  static List<_DocumentPrintColumn> defaultTableColumns() {
    return const [
      _DocumentPrintColumn(key: 'item_name', label: 'Item', widthFactor: 3.2),
      _DocumentPrintColumn(
        key: 'description',
        label: 'Description',
        widthFactor: 3,
      ),
      _DocumentPrintColumn(
        key: 'qty',
        label: 'Qty',
        widthFactor: 1.1,
        align: 'right',
      ),
      _DocumentPrintColumn(
        key: 'rate',
        label: 'Rate',
        widthFactor: 1.2,
        align: 'right',
      ),
      _DocumentPrintColumn(
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

  _DocumentPrintShape copyWith({
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
    List<_DocumentPrintColumn>? columns,
    String? assetPath,
    int? sides,
    String? barcodeType,
  }) {
    return _DocumentPrintShape(
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

  @override
  String toString() {
    if (type == 'text' && text.isNotEmpty) {
      return text.length > 20 ? '${text.substring(0, 20)}...' : text;
    }
    return '${type[0].toUpperCase()}${type.substring(1)}: $id';
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
}

class _DocumentPrintColumn {
  const _DocumentPrintColumn({
    required this.key,
    required this.label,
    required this.widthFactor,
    this.align = 'left',
  });

  final String key;
  final String label;
  final double widthFactor;
  final String align;

  factory _DocumentPrintColumn.fromJson(Map<String, dynamic> json) {
    return _DocumentPrintColumn(
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

  _DocumentPrintColumn copyWith({
    String? key,
    String? label,
    double? widthFactor,
    String? align,
  }) {
    return _DocumentPrintColumn(
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
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

_DocumentPrintTemplate _applyPagePreset(
  _DocumentPrintTemplate template, {
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

Object? _resolvePath(Map<String, dynamic> data, String path) {
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

String _resolveTemplateText(String input, Map<String, dynamic> data) {
  return input.replaceAllMapped(RegExp(r'\{\{([^}]+)\}\}'), (match) {
    final key = match.group(1)?.trim() ?? '';
    final value = _resolvePath(data, key);
    if (value == null) {
      return '';
    }
    if (value is num) {
      return _formatAmount(value.toDouble());
    }
    return value.toString();
  });
}

String _resolveCellValue(Map<String, dynamic> row, String key) {
  final value = _resolvePath(row, key);
  if (value == null) {
    return '';
  }
  if (value is num) {
    return _formatAmount(value.toDouble());
  }
  return value.toString();
}

String _formatAmount(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(2);
}

String? _resolveImageSource(String? source) {
  if (source == null || source.trim().isEmpty) {
    return null;
  }
  source = _normalizeLegacyImageSource(source);
  if (source.startsWith('assets/')) {
    return source;
  }
  if (source.startsWith('http://') || source.startsWith('https://')) {
    return source;
  }
  return AppConfig.resolvePublicFileUrl(source) ?? source;
}

String _normalizeLegacyImageSource(String source) {
  final trimmed = source.trim();
  if (trimmed == _legacyPbsLogoAsset) {
    return _defaultPrintLogoAsset;
  }
  return trimmed;
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
          .map(
            (part) =>
                '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
          )
          .join(' ');
  }
}

List<String> _availableBindings(
  Map<String, dynamic> data, [
  String prefix = '',
]) {
  final keys = <String>[];
  data.forEach((key, value) {
    if (value is Map<String, dynamic>) {
      keys.addAll(
        _availableBindings(value, prefix.isEmpty ? key : '$prefix.$key'),
      );
    } else if (value is! List) {
      keys.add(prefix.isEmpty ? key : '$prefix.$key');
    }
  });
  return keys;
}
