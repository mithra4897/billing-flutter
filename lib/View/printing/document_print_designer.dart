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
import '../../model/printing/print_template_model.dart';
import '../../service/printing/print_template_service.dart';

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
  final PrintTemplateService _service = PrintTemplateService();
  final GlobalKey _previewBoundaryKey = GlobalKey();
  final ScrollController _pageScrollController = ScrollController();
  DocumentPrintTemplate? _template;
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
    try {
      final response = await _service.getTemplate(widget.documentType);
      if (!mounted) {
        return;
      }
      if (response.success && response.data != null) {
        setState(() {
          _template = response.data;
          _loading = false;
        });
      } else {
        setState(() {
          _template = DocumentPrintTemplate.defaults(
            widget.documentType,
            title: widget.title,
          );
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _template = DocumentPrintTemplate.defaults(
          widget.documentType,
          title: widget.title,
        );
        _loading = false;
      });
    }
  }

  Future<void> _saveTemplate() async {
    final template = _template;
    if (template == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      final response = await _service.saveTemplate(widget.documentType, template);
      if (!mounted) {
        return;
      }
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Print template saved successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Failed to save template.')),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving template: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
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

  Widget _buildInspector(DocumentPrintTemplate template) {
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
      _template = DocumentPrintTemplate.defaults(
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
    final shape = DocumentPrintShape.defaults(type, template.shapes.length);
    setState(() {
      _template = template.copyWith(shapes: [...template.shapes, shape]);
      _selectedShapeId = shape.id;
    });
  }

  void _updateShape(DocumentPrintShape next) {
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

  PdfPageFormat _pageFormatForTemplate(DocumentPrintTemplate template) {
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

  final DocumentPrintTemplate template;
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
                        painter: DocumentCanvasPainter(
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

class DocumentCanvasPainter extends CustomPainter {
  DocumentCanvasPainter({
    required this.template,
    required this.documentData,
    required this.scale,
  });

  final DocumentPrintTemplate template;
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

  void _paintText(Canvas canvas, Rect rect, DocumentPrintShape shape) {
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

  void _paintTable(Canvas canvas, Rect rect, DocumentPrintShape shape) {
    final rows =
        _resolvePath(documentData, shape.dataPath) as List<dynamic>? ??
        const <dynamic>[];
    final headerHeight = 32 * scale;
    final minRowHeight = math.max(24.0, shape.rowHeight * scale);
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
    List<DocumentPrintColumn> columns,
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

  void _paintBarcode(Canvas canvas, Rect rect, DocumentPrintShape shape) {
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
  bool shouldRepaint(covariant DocumentCanvasPainter oldDelegate) {
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

  final DocumentPrintTemplate template;
  final ValueChanged<DocumentPrintTemplate> onChanged;

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

  final DocumentPrintShape shape;
  final List<String> bindings;
  final ValueChanged<DocumentPrintShape> onChanged;
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
    'Transparent': 0x00000000,
    'White': 0xFFFFFFFF,
    'Default Gray': 0xFFF1F5F9,
    'Slate': 0xFF475569,
    'Black': 0xFF111827,
    'Blue': 0xFF2563EB,
    'Green': 0xFF059669,
    'Red': 0xFFDC2626,
    'Amber': 0xFFF59E0B,
    'Orange': 0xFFEA580C,
    'Gray': 0xFFD1D5DB,
  };

  @override
  Widget build(BuildContext context) {
    // Ensure the current value is visible in the dropdown even if not in palette
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

  final List<DocumentPrintColumn> columns;
  final ValueChanged<List<DocumentPrintColumn>> onChanged;

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
                  DocumentPrintColumn(
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

  void _updateColumn(int index, DocumentPrintColumn next) {
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






double _toDouble(dynamic value, double fallback) {
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

int _toInt(dynamic value, int fallback) {
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DocumentPrintTemplate _applyPagePreset(
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
