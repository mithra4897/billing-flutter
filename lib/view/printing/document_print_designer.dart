import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../screen.dart';

Future<void> openDocumentPrintDesigner(
  BuildContext context, {
  required String documentType,
  required String title,
  required DocumentPrintDataModel documentData,
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

class _DocumentPrintDesignerController extends GetxController {
  DocumentPrintTemplate? template;
  String? selectedShapeId;
  Set<String> selectedShapeIds = <String>{};
  double canvasZoom = 1.0;
  bool uploadingImage = false;
  bool uploadingBackground = false;
  bool editMode = false;
  bool loading = true;
  bool saving = false;
  bool printingPdf = false;
  bool downloadingPdf = false;
  _DesignerOperation operation = _DesignerOperation.select;
  Offset? drawStart;
  Offset? drawCurrent;

  void updateState(VoidCallback mutate) {
    mutate();
    update();
  }
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
  final DocumentPrintDataModel documentData;

  @override
  State<DocumentPrintDesignerPage> createState() =>
      _DocumentPrintDesignerPageState();
}

class _DocumentPrintDesignerPageState extends State<DocumentPrintDesignerPage> {
  final PrintTemplateService _service = PrintTemplateService();
  final MediaService _mediaService = MediaService();
  final GlobalKey _previewBoundaryKey = GlobalKey();
  final GlobalKey _pdfPreviewBoundaryKey = GlobalKey();
  final ScrollController _pageScrollController = ScrollController();
  final ScrollController _toolbarScrollController = ScrollController();
  final FocusNode _designerFocusNode = FocusNode();
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
  _DesignerOperation get _operation => _controller.operation;
  set _operation(_DesignerOperation value) => _controller.operation = value;
  Offset? get _drawStart => _controller.drawStart;
  set _drawStart(Offset? value) => _controller.drawStart = value;
  Offset? get _drawCurrent => _controller.drawCurrent;
  set _drawCurrent(Offset? value) => _controller.drawCurrent = value;

  Map<String, dynamic> get _documentDataJson => widget.documentData.toJson();

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
        _loading = false;
      });
    }
  }

  DocumentPrintTemplate _prepareTemplate(DocumentPrintTemplate template) {
    final normalized = _ensureTermsBlock(
      template.normalizedFor(widget.documentType),
    );

    final shapes = normalized.shapes.map((shape) {
      if (_isGstBreakupTableShape(shape)) {
        const columns = defaultGstBreakupTableColumns;
        final tableHeight = measurePrintTableHeight(
          shape: shape,
          rows: widget.documentData.gstBreakup,
          columns: columns,
        );
        return shape.copyWith(
          dataPath: 'gst_breakup',
          height: tableHeight,
          columns: columns,
        );
      } else if (isPrintLinesTableShape(shape)) {
        return shape.copyWith(dataPath: 'lines');
      }
      return shape;
    }).toList();

    return normalized.copyWith(shapes: shapes);
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

    actions.add(
      AdaptiveShellActionButton(
        onPressed: _downloadingPdf ? null : _downloadPdf,
        icon: Icons.download_outlined,
        label: _downloadingPdf ? 'Preparing PDF...' : 'Download PDF',
        filled: false,
      ),
    );

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
                                    AppUiConstants.spacingMd,
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
                      scale: 1,
                      editMode: false,
                      selectedShapeId: null,
                      selectedShapeIds: const <String>{},
                      showDecoration: false,
                      onSelectShape: (_) {},
                      onMoveShape: (shapeId, delta) {},
                      onResizeShape: (shapeId, delta) {},
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
              onPressed: _resetTemplate,
              icon: const Icon(Icons.refresh_outlined),
              label: const Text('Reset'),
            ),
            const SizedBox(width: AppUiConstants.spacingXs),
            OutlinedButton.icon(
              onPressed: _canvasZoom <= 0.7
                  ? null
                  : () => _controller.updateState(
                      () => _canvasZoom = (_canvasZoom - 0.15).clamp(0.55, 2.5),
                    ),
              icon: const Icon(Icons.zoom_out_outlined),
              label: const Text('Zoom -'),
            ),
            const SizedBox(width: AppUiConstants.spacingXs),
            OutlinedButton(
              onPressed: () => _controller.updateState(() => _canvasZoom = 1.0),
              child: const Text('Fit'),
            ),
            const SizedBox(width: AppUiConstants.spacingXs),
            OutlinedButton.icon(
              onPressed: _canvasZoom >= 2.5
                  ? null
                  : () => _controller.updateState(
                      () => _canvasZoom = (_canvasZoom + 0.15).clamp(0.55, 2.5),
                    ),
              icon: const Icon(Icons.zoom_in_outlined),
              label: const Text('Zoom +'),
            ),
          ],
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
          ? null
          : FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
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
    _controller.updateState(() {
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
            final selectedIds = _selectedShapeIds;
            final shapeId = _selectedShapeId;
            if (selectedIds.isEmpty || shapeId == null) {
              return;
            }
            final isShift = HardwareKeyboard.instance.isShiftPressed;
            final delta = isShift ? 10.0 : 1.0;

            if (event.logicalKey == LogicalKeyboardKey.delete) {
              _deleteSelectedShape();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _moveShape(shapeId, Offset(-delta, 0));
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _moveShape(shapeId, Offset(delta, 0));
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _moveShape(shapeId, Offset(0, -delta));
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _moveShape(shapeId, Offset(0, delta));
            }
          },
          child: RepaintBoundary(
            key: _previewBoundaryKey,
            child: _DesignerCanvas(
              template: template,
              documentData: _documentDataJson,
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
                  onChanged: (next) =>
                      _controller.updateState(() => _template = next),
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
    _controller.updateState(() {
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
    _controller.updateState(() {
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
    _controller.updateState(() {
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
      _controller.updateState(() {
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

  void _updateShape(DocumentPrintShape next) {
    final template = _template;
    if (template == null) {
      return;
    }
    final shapes = template.shapes
        .map((shape) => shape.id == next.id ? next : shape)
        .toList(growable: false);
    _controller.updateState(
      () => _template = template.copyWith(shapes: shapes),
    );
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
      onLoading: (loading) {
        if (mounted) {
          _controller.updateState(() => _uploadingBackground = loading);
        }
      },
      onSuccess: (filePath) {
        if (!mounted) {
          return;
        }
        _controller.updateState(() {
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
    _controller.updateState(
      () => _template = template.copyWith(shapes: shapes),
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
    _controller.updateState(
      () => _template = template.copyWith(shapes: shapes),
    );
  }

  void _deleteSelectedShape() {
    final template = _template;
    if (template == null || _selectedShapeIds.isEmpty) {
      return;
    }
    _controller.updateState(() {
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
    _controller.updateState(
      () => _template = template.copyWith(shapes: shapes),
    );
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
    _controller.updateState(
      () => _template = template.copyWith(shapes: shapes),
    );
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
    _controller.updateState(() {
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
    _controller.updateState(() {
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
    _controller.updateState(() {
      _template = template.copyWith(
        shapes: [...template.shapes, ...duplicates],
      );
      _selectedShapeIds = duplicates.map((shape) => shape.id).toSet();
      _selectedShapeId = duplicates.isEmpty ? null : duplicates.last.id;
    });
  }

  Future<Uint8List?> _capturePreviewPng() async {
    await SchedulerBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 32));
    await SchedulerBinding.instance.endOfFrame;
    final boundary =
        _pdfPreviewBoundaryKey.currentContext?.findRenderObject()
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
    _controller.updateState(() => _printingPdf = true);
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
}

class _DesignerCanvas extends StatefulWidget {
  const _DesignerCanvas({
    required this.template,
    required this.documentData,
    required this.editMode,
    required this.selectedShapeId,
    required this.selectedShapeIds,
    required this.zoom,
    required this.onSelectShape,
    required this.onMoveShape,
    required this.onResizeShape,
    required this.operation,
    required this.draftShape,
    required this.onDrawStart,
    required this.onDrawUpdate,
    required this.onDrawEnd,
    required this.onDrawTap,
  });

  final DocumentPrintTemplate template;
  final Map<String, dynamic> documentData;
  final bool editMode;
  final String? selectedShapeId;
  final Set<String> selectedShapeIds;
  final double zoom;
  final ValueChanged<String?> onSelectShape;
  final void Function(String shapeId, Offset delta) onMoveShape;
  final void Function(String shapeId, Offset delta) onResizeShape;
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
                        scale: scale,
                        editMode: widget.editMode,
                        selectedShapeId: widget.selectedShapeId,
                        selectedShapeIds: widget.selectedShapeIds,
                        onSelectShape: widget.onSelectShape,
                        onMoveShape: widget.onMoveShape,
                        onResizeShape: widget.onResizeShape,
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
    required this.scale,
    required this.editMode,
    required this.selectedShapeId,
    required this.selectedShapeIds,
    required this.onSelectShape,
    required this.onMoveShape,
    required this.onResizeShape,
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
  final double scale;
  final bool editMode;
  final String? selectedShapeId;
  final Set<String> selectedShapeIds;
  final ValueChanged<String?> onSelectShape;
  final void Function(String shapeId, Offset delta) onMoveShape;
  final void Function(String shapeId, Offset delta) onResizeShape;
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
                  draftShape: draftShape,
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
                          source: resolvePrintTemplateText(
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
  });

  final bool selected;
  final _DesignerOperation operation;
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
  const _DocumentImageShape({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final resolved = resolvePrintImageSource(source);
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
    this.showPageChrome = true,
    this.draftShape,
  });

  final DocumentPrintTemplate template;
  final Map<String, dynamic> documentData;
  final double scale;
  final bool showPageChrome;
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
      ..color = draft
          ? Color(shape.strokeColor).withValues(alpha: 0.75)
          : Color(shape.strokeColor)
      ..strokeWidth = math.max(1, shape.strokeWidth * scale);
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = Color(shape.fillColor).withValues(
        alpha: draft
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
      ..strokeWidth = 1;
    final headerFill = Paint()
      ..style = PaintingStyle.fill
      ..color = Color(shape.headerColor);

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
          TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12 * scale,
            color: Color(shape.headerTextColor),
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
          resolvePrintCellValue(row, column.key),
          _textAlignForColumn(column.align),
          TextStyle(fontSize: 11 * scale, color: Color(shape.strokeColor)),
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
              : formatPrintAmount(totals[column.key]!);
          _paintTableCell(
            canvas,
            cellRect,
            value,
            index == 0 ? TextAlign.left : _textAlignForColumn(column.align),
            TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11 * scale,
              color: Color(shape.headerTextColor),
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
